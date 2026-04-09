import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../beats/beat_model.dart';
import '../core/supabase_config.dart';
import '../data/purchased_beats.dart';
import '../profile/profile_store.dart';
import 'backend_contracts.dart';

const String _profilesTable = 'profiles';
const String _beatsTable = 'beats';
const String _purchasesTable = 'purchases';
const String _followsTable = 'follows';
const String _beatsBucket = 'beats';

class SupabaseAuthBackend implements AuthBackend {
  final SupabaseClient _client = Supabase.instance.client;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // google_sign_in_web requires clientId and rejects serverClientId.
    clientId: _googleClientIdForPlatform,
    serverClientId: _googleServerClientIdForPlatform,
  );

  static String? get _googleClientIdForPlatform {
    if (kIsWeb) {
      if (SupabaseConfig.googleWebClientId.isNotEmpty) {
        return SupabaseConfig.googleWebClientId;
      }
      if (SupabaseConfig.googleServerClientId.isNotEmpty) {
        return SupabaseConfig.googleServerClientId;
      }
      return null;
    }

    // Android expects serverClientId for ID token; no clientId needed.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return null;
    }

    return SupabaseConfig.googleClientId.isEmpty
        ? null
        : SupabaseConfig.googleClientId;
  }

  static String? get _googleServerClientIdForPlatform {
    if (kIsWeb) return null;
    return SupabaseConfig.googleServerClientId.isEmpty
        ? null
        : SupabaseConfig.googleServerClientId;
  }

  SessionUser? _currentUser;

  void _authDebug(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('[SupabaseAuth] $message');
    if (error != null) {
      debugPrint('[SupabaseAuth] error: $error');
    }
    if (stackTrace != null) {
      debugPrint('[SupabaseAuth] stack: $stackTrace');
    }
  }

  String _tokenState(String? token) {
    if (token == null) return 'null';
    if (token.isEmpty) return 'empty';
    return 'present(len=${token.length})';
  }

  String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return email;
    return '${email[0]}***${email.substring(at)}';
  }

  @override
  SessionUser? get currentUser => _currentUser;

  @override
  Future<SessionUser?> restoreSession() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    final profile = await _loadProfile(authUser.id);
    if (profile == null) return null;

    _currentUser = _sessionUserFromProfile(
      authUser: authUser,
      profile: profile,
    );
    ProfileStore.setCurrentUserFromSession(
      _currentUser!,
      username: _profileUsername(profile),
      displayName: _profileDisplayName(profile),
    );
    return _currentUser;
  }

  @override
  Future<SessionUser?> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final authUser = response.user;
    if (authUser == null) {
      throw Exception('Login failed. Please try again.');
    }

    final profile = await _loadProfile(authUser.id);
    if (profile == null) {
      throw Exception(
        'User profile not found. Please complete onboarding or contact support.',
      );
    }

    _currentUser = _sessionUserFromProfile(
      authUser: authUser,
      profile: profile,
    );
    ProfileStore.setCurrentUserFromSession(
      _currentUser!,
      username: _profileUsername(profile),
      displayName: _profileDisplayName(profile),
    );
    return _currentUser;
  }

  @override
  Future<SessionUser> signup({
    required String email,
    required String password,
    required String username,
    required AppUserRole role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final authUser = response.user;

    if (authUser == null) {
      throw Exception(
        'Sign up succeeded but no active session was returned. '
        'Disable email confirmation in Supabase Auth or complete verification first.',
      );
    }

    final roleStr = role == AppUserRole.producer ? 'producer' : 'buyer';
    await _upsertProfile(
      uid: authUser.id,
      email: email,
      username: username,
      displayName: username,
      role: roleStr,
      bio: '',
    );

    _currentUser = SessionUser(
      userId: authUser.id,
      email: email,
      role: role,
      username: username,
    );
    ProfileStore.setCurrentUserFromSession(
      _currentUser!,
      username: username,
      displayName: username,
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  @override
  Future<(SessionUser?, bool)> signInWithGoogle() async {
    try {
      _authDebug(
        'Google sign-in start; platform=${kIsWeb ? 'web' : defaultTargetPlatform.name}; '
        'clientIdSet=${_googleClientIdForPlatform != null}; '
        'serverClientIdSet=${_googleServerClientIdForPlatform != null}',
      );

      await _googleSignIn.signOut();
      _authDebug('Previous Google session cleared. Opening account picker.');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _authDebug('Google sign-in cancelled by user.');
        return (null, false);
      }

      _authDebug(
        'Google account selected: email=${_maskEmail(googleUser.email)} id=${googleUser.id}',
      );

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      _authDebug(
        'Google tokens received: idToken=${_tokenState(idToken)} '
        'accessToken=${_tokenState(accessToken)}',
      );

      if (idToken == null || idToken.isEmpty) {
        _authDebug('Google returned no ID token.');
        final requiredKey = kIsWeb
            ? 'SUPABASE_GOOGLE_WEB_CLIENT_ID'
            : 'SUPABASE_GOOGLE_SERVER_CLIENT_ID';
        throw Exception(
          'missing-google-auth-token: Google Sign-In did not return an ID token. '
          'Use $requiredKey (Web OAuth client ID).',
        );
      }

      _authDebug('Calling Supabase auth.signInWithIdToken...');
      final authResponse = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final authUser = authResponse.user;
      if (authUser == null) {
        _authDebug('Supabase returned null user after signInWithIdToken.');
        throw Exception('Google sign-in failed. No user session was returned.');
      }

      _authDebug('Supabase auth success: uid=${authUser.id}');

      final profile = await _loadProfile(authUser.id);

      if (profile == null) {
        _authDebug('No profile row found; onboarding required.');
        final partialUser = SessionUser(
          userId: authUser.id,
          email: authUser.email ?? '',
          role: AppUserRole.buyer,
          username: '',
        );
        return (partialUser, true);
      }

      final roleRaw = _profileRole(profile).trim();
      final username = _profileUsername(profile).trim();
      final needsOnboarding = roleRaw.isEmpty || username.isEmpty;

      _authDebug(
        'Profile loaded: role="$roleRaw" usernamePresent=${username.isNotEmpty}; '
        'needsOnboarding=$needsOnboarding',
      );

      if (needsOnboarding) {
        final partialUser = SessionUser(
          userId: authUser.id,
          email: authUser.email ?? '',
          role: roleRaw == 'producer'
              ? AppUserRole.producer
              : AppUserRole.buyer,
          username: username,
        );
        return (partialUser, true);
      }

      _currentUser = _sessionUserFromProfile(
        authUser: authUser,
        profile: profile,
      );
      ProfileStore.setCurrentUserFromSession(
        _currentUser!,
        username: _profileUsername(profile),
        displayName: _profileDisplayName(profile),
      );
      _authDebug('Google sign-in completed with existing profile.');
      return (_currentUser, false);
    } on AuthException catch (e, st) {
      _authDebug('Supabase AuthException during Google sign-in.', e, st);
      throw Exception('supabase-google-auth-error: ${e.message}');
    } catch (e, st) {
      _authDebug('Unhandled exception during Google sign-in.', e, st);
      rethrow;
    }
  }

  @override
  Future<SessionUser> completeGoogleSignup({
    required String uid,
    required String email,
    required String username,
    required AppUserRole role,
    String? displayName,
  }) async {
    final roleStr = role == AppUserRole.producer ? 'producer' : 'buyer';
    final resolvedName = (displayName ?? username).trim();

    await _upsertProfile(
      uid: uid,
      email: email,
      username: username.trim(),
      displayName: resolvedName,
      role: roleStr,
      bio: '',
    );

    _currentUser = SessionUser(
      userId: uid,
      email: email,
      role: role,
      username: username.trim(),
    );
    ProfileStore.setCurrentUserFromSession(
      _currentUser!,
      username: username.trim(),
      displayName: resolvedName,
    );
    return _currentUser!;
  }

  @override
  Future<void> updateCurrentUserProfile({
    required String displayName,
    required String username,
    required String bio,
  }) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw Exception('No active session');
    }

    await _client
        .from(_profilesTable)
        .update({
          'display_name': displayName.trim(),
          'username': username.trim(),
          'bio': bio.trim(),
        })
        .eq('id', authUser.id);

    final role = _currentUser?.role ?? AppUserRole.buyer;
    _currentUser = SessionUser(
      userId: authUser.id,
      email: authUser.email ?? '',
      role: role,
      username: username.trim(),
    );
    ProfileStore.setCurrentUserFromSession(
      _currentUser!,
      username: username.trim(),
      displayName: displayName.trim(),
    );
  }

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw Exception('No active session');
    }

    final sessionEmail = authUser.email ?? email;

    // Re-authenticate with current credentials before changing password.
    await _client.auth.signInWithPassword(
      email: sessionEmail,
      password: currentPassword,
    );

    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<Map<String, dynamic>?> _loadProfile(String uid) async {
    return await _client
        .from(_profilesTable)
        .select()
        .eq('id', uid)
        .maybeSingle();
  }

  Future<void> _upsertProfile({
    required String uid,
    required String email,
    required String username,
    required String displayName,
    required String role,
    required String bio,
  }) async {
    await _client.from(_profilesTable).upsert({
      'id': uid,
      'email': email,
      'username': username,
      'display_name': displayName,
      'role': role,
      'bio': bio,
      'genres': <String>[],
      'avatar_url': null,
      'followers_count': 0,
      'following_count': 0,
    }, onConflict: 'id');
  }

  SessionUser _sessionUserFromProfile({
    required User authUser,
    required Map<String, dynamic> profile,
  }) {
    return SessionUser(
      userId: authUser.id,
      email: authUser.email ?? _profileEmail(profile),
      role: _profileRole(profile) == 'producer'
          ? AppUserRole.producer
          : AppUserRole.buyer,
      username: _profileUsername(profile),
    );
  }

  String _profileEmail(Map<String, dynamic> profile) =>
      (profile['email'] ?? '').toString();

  String _profileRole(Map<String, dynamic> profile) =>
      (profile['role'] ?? '').toString();

  String _profileUsername(Map<String, dynamic> profile) =>
      (profile['username'] ?? '').toString();

  String _profileDisplayName(Map<String, dynamic> profile) {
    final display = (profile['display_name'] ?? '').toString();
    if (display.isNotEmpty) return display;
    return _profileUsername(profile);
  }
}

class SupabaseBeatsBackend implements BeatsBackend {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<BeatModel>> fetchAllBeats() async {
    final rows = await _client
        .from(_beatsTable)
        .select()
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((row) => _beatFromRow(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<void> addBeat(BeatModel beat) async {
    await _client.from(_beatsTable).insert(_beatInsertMap(beat));
  }

  @override
  Future<List<BeatModel>> fetchBeatsByProducer(String producerId) async {
    final rows = await _client
        .from(_beatsTable)
        .select()
        .eq('producer_id', producerId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((row) => _beatFromRow(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<void> updateBeat(BeatModel beat) async {
    await _client
        .from(_beatsTable)
        .update({
          'title': beat.title,
          'genre': beat.genre,
          'bpm': beat.bpm,
          'basic_license_price': beat.basicLicensePrice,
          'premium_license_price': beat.premiumLicensePrice,
          'exclusive_license_price': beat.exclusiveLicensePrice,
          'description': beat.description,
          'audio_url': beat.audioPath,
          'cover_art_url': beat.coverArtPath,
        })
        .eq('id', beat.id);
  }

  @override
  Future<void> uploadBeatWithFiles({
    required BeatModel beat,
    required List<int> audioBytes,
    required String audioExtension,
    List<int>? coverArtBytes,
    String? coverArtExtension,
  }) async {
    final uploadId = DateTime.now().microsecondsSinceEpoch.toString();
    final audioPath =
        '${beat.producerId}/$uploadId/audio.${audioExtension.toLowerCase()}';

    await _client.storage
        .from(_beatsBucket)
        .uploadBinary(
          audioPath,
          Uint8List.fromList(audioBytes),
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeForExtension(audioExtension),
          ),
        );
    final audioUrl = _client.storage.from(_beatsBucket).getPublicUrl(audioPath);

    String? coverUrl;
    if (coverArtBytes != null && coverArtExtension != null) {
      final coverPath =
          '${beat.producerId}/$uploadId/cover.${coverArtExtension.toLowerCase()}';
      await _client.storage
          .from(_beatsBucket)
          .uploadBinary(
            coverPath,
            Uint8List.fromList(coverArtBytes),
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentTypeForExtension(coverArtExtension),
            ),
          );
      coverUrl = _client.storage.from(_beatsBucket).getPublicUrl(coverPath);
    }

    await _client.from(_beatsTable).insert({
      'title': beat.title,
      'producer_id': beat.producerId,
      'producer_name': beat.producer,
      'genre': beat.genre,
      'bpm': beat.bpm,
      'basic_license_price': beat.basicLicensePrice,
      'premium_license_price': beat.premiumLicensePrice,
      'exclusive_license_price': beat.exclusiveLicensePrice,
      'description': beat.description,
      'audio_url': audioUrl,
      'cover_art_url': coverUrl,
    });
  }

  Map<String, dynamic> _beatInsertMap(BeatModel beat) {
    return {
      'title': beat.title,
      'producer_id': beat.producerId,
      'producer_name': beat.producer,
      'genre': beat.genre,
      'bpm': beat.bpm,
      'basic_license_price': beat.basicLicensePrice,
      'premium_license_price': beat.premiumLicensePrice,
      'exclusive_license_price': beat.exclusiveLicensePrice,
      'description': beat.description,
      'audio_url': beat.audioPath,
      'cover_art_url': beat.coverArtPath,
    };
  }

  BeatModel _beatFromRow(Map<String, dynamic> row) {
    double asDouble(dynamic v, [double fallback = 0]) =>
        v == null ? fallback : (v as num).toDouble();

    int asInt(dynamic v, [int fallback = 0]) =>
        v == null ? fallback : (v as num).toInt();

    return BeatModel(
      id: (row['id'] ?? '').toString(),
      title: (row['title'] ?? '').toString(),
      producer: (row['producer_name'] ?? '').toString(),
      producerId: (row['producer_id'] ?? '').toString(),
      genre: (row['genre'] ?? '').toString(),
      bpm: asInt(row['bpm']),
      basicLicensePrice: asDouble(row['basic_license_price']),
      premiumLicensePrice: asDouble(row['premium_license_price']),
      exclusiveLicensePrice: asDouble(row['exclusive_license_price']),
      description: (row['description'] ?? '').toString(),
      audioPath: (row['audio_url'] ?? '').toString(),
      coverArtPath: row['cover_art_url']?.toString(),
    );
  }

  String _contentTypeForExtension(String ext) {
    final lower = ext.toLowerCase();
    switch (lower) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'flac':
        return 'audio/flac';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

class SupabasePurchasesBackend implements PurchasesBackend {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<void> recordPurchase(PurchasedBeat purchase) async {
    await _client.from(_purchasesTable).insert(purchase.toMap());
  }

  @override
  Future<List<PurchasedBeat>> fetchPurchasesByBuyer(String buyerUserId) async {
    final rows = await _client
        .from(_purchasesTable)
        .select()
        .eq('buyer_user_id', buyerUserId)
        .order('purchased_at', ascending: false);

    return (rows as List<dynamic>)
        .map(
          (row) => PurchasedBeat.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  @override
  Future<List<PurchasedBeat>> fetchPurchasesBySeller(String producerId) async {
    final rows = await _client
        .from(_purchasesTable)
        .select()
        .eq('beat_producer_id', producerId)
        .order('purchased_at', ascending: false);

    return (rows as List<dynamic>)
        .map(
          (row) => PurchasedBeat.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  @override
  Future<double> fetchTotalRevenue(String producerId) async {
    final list = await fetchPurchasesBySeller(producerId);
    return list.fold<double>(0, (sum, p) => sum + p.pricePaid);
  }
}

class SupabaseFollowBackend implements FollowBackend {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<bool> isFollowing(String myUid, String targetUid) async {
    final row = await _client
        .from(_followsTable)
        .select('follower_id')
        .eq('follower_id', myUid)
        .eq('followed_id', targetUid)
        .maybeSingle();
    return row != null;
  }

  @override
  Future<void> follow(String myUid, String targetUid) async {
    if (myUid.isEmpty || targetUid.isEmpty || myUid == targetUid) return;

    try {
      await _client.rpc('follow_user', params: {'target_uid': targetUid});
      return;
    } catch (_) {
      // Fall back to direct table mutation when RPC is not installed yet.
    }

    await _client.from(_followsTable).upsert({
      'follower_id': myUid,
      'followed_id': targetUid,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'follower_id,followed_id');

    await _recalculateFollowCounts(myUid, targetUid);
  }

  @override
  Future<void> unfollow(String myUid, String targetUid) async {
    if (myUid.isEmpty || targetUid.isEmpty || myUid == targetUid) return;

    try {
      await _client.rpc('unfollow_user', params: {'target_uid': targetUid});
      return;
    } catch (_) {
      // Fall back to direct table mutation when RPC is not installed yet.
    }

    await _client
        .from(_followsTable)
        .delete()
        .eq('follower_id', myUid)
        .eq('followed_id', targetUid);

    await _recalculateFollowCounts(myUid, targetUid);
  }

  @override
  Future<List<String>> getFollowingIds(String uid) async {
    if (uid.isEmpty) return [];
    final rows = await _client
        .from(_followsTable)
        .select('followed_id')
        .eq('follower_id', uid);

    return (rows as List<dynamic>)
        .map((row) => (row as Map)['followed_id'].toString())
        .toList();
  }

  @override
  Future<List<String>> getFollowerIds(String uid) async {
    if (uid.isEmpty) return [];
    final rows = await _client
        .from(_followsTable)
        .select('follower_id')
        .eq('followed_id', uid);

    return (rows as List<dynamic>)
        .map((row) => (row as Map)['follower_id'].toString())
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    if (uid.isEmpty) return null;

    final row = await _client
        .from(_profilesTable)
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;

    return _normalizeProfileRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(
    String query, {
    int limit = 20,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final byDisplay = await _client
        .from(_profilesTable)
        .select()
        .ilike('display_name', '$q%')
        .limit(limit);

    final byUsername = await _client
        .from(_profilesTable)
        .select()
        .ilike('username', '$q%')
        .limit(limit);

    final merged = <String, Map<String, dynamic>>{};
    for (final row in [
      ...(byDisplay as List<dynamic>),
      ...(byUsername as List<dynamic>),
    ]) {
      final normalized = _normalizeProfileRow(
        Map<String, dynamic>.from(row as Map),
      );
      merged[normalized['uid'].toString()] = normalized;
      if (merged.length >= limit) break;
    }

    return merged.values.toList();
  }

  @override
  Future<List<Map<String, dynamic>>> listUsersByRole(
    String role, {
    int limit = 20,
    String? excludeUid,
  }) async {
    final rows = await _client
        .from(_profilesTable)
        .select()
        .eq('role', role)
        .limit(limit + 1);

    final out = <Map<String, dynamic>>[];
    for (final row in (rows as List<dynamic>)) {
      final normalized = _normalizeProfileRow(
        Map<String, dynamic>.from(row as Map),
      );
      if (excludeUid != null && normalized['uid'] == excludeUid) {
        continue;
      }
      out.add(normalized);
      if (out.length >= limit) break;
    }

    return out;
  }

  Map<String, dynamic> _normalizeProfileRow(Map<String, dynamic> row) {
    return {
      'uid': (row['id'] ?? '').toString(),
      'email': (row['email'] ?? '').toString(),
      'username': (row['username'] ?? '').toString(),
      'displayName': (row['display_name'] ?? row['username'] ?? '').toString(),
      'bio': (row['bio'] ?? '').toString(),
      'role': (row['role'] ?? 'buyer').toString(),
      'genres': row['genres'] ?? const <dynamic>[],
      'avatarUrl': row['avatar_url'],
      'followersCount': row['followers_count'] ?? 0,
      'followingCount': row['following_count'] ?? 0,
    };
  }

  Future<void> _recalculateFollowCounts(String myUid, String targetUid) async {
    final myFollowing = await _client
        .from(_followsTable)
        .select('followed_id')
        .eq('follower_id', myUid);
    final targetFollowers = await _client
        .from(_followsTable)
        .select('follower_id')
        .eq('followed_id', targetUid);

    await _client
        .from(_profilesTable)
        .update({'following_count': (myFollowing as List<dynamic>).length})
        .eq('id', myUid);
    await _client
        .from(_profilesTable)
        .update({'followers_count': (targetFollowers as List<dynamic>).length})
        .eq('id', targetUid);
  }
}
