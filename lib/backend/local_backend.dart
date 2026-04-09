import '../beats/beat_model.dart';
import '../beats/beat_store.dart';
import '../data/purchased_beats.dart';
import '../profile/profile_store.dart';
import 'backend_contracts.dart';
import 'supabase_backend.dart';

// ─────────────────────────────────────────────
// Local (mock) Auth — kept for offline testing
// ─────────────────────────────────────────────
class LocalAuthBackend implements AuthBackend {
  SessionUser? _currentUser;

  @override
  SessionUser? get currentUser => _currentUser;

  @override
  Future<SessionUser?> restoreSession() async => null;

  @override
  Future<SessionUser?> login({
    required String email,
    required String password,
  }) async {
    _currentUser = SessionUser(
      userId: 'buyer_001',
      email: email,
      role: AppUserRole.buyer,
      username: email.split('@').first,
    );
    ProfileStore.setCurrentUserFromSession(_currentUser!);
    return _currentUser;
  }

  @override
  Future<SessionUser> signup({
    required String email,
    required String password,
    required String username,
    required AppUserRole role,
  }) async {
    _currentUser = SessionUser(
      userId: '${role.name}_001',
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
    _currentUser = null;
    ProfileStore.clearCurrentUser();
  }

  @override
  Future<(SessionUser?, bool)> signInWithGoogle() async =>
      throw UnimplementedError('Google sign-in not available in local mode.');

  @override
  Future<SessionUser> completeGoogleSignup({
    required String uid,
    required String email,
    required String username,
    required AppUserRole role,
    String? displayName,
  }) async {
    _currentUser = SessionUser(
      userId: uid,
      email: email,
      role: role,
      username: username,
    );
    ProfileStore.setCurrentUserFromSession(
      _currentUser!,
      username: username,
      displayName: displayName ?? username,
    );
    return _currentUser!;
  }

  @override
  Future<void> updateCurrentUserProfile({
    required String displayName,
    required String username,
    required String bio,
  }) async {
    final current = _currentUser;
    if (current == null) {
      throw Exception('No active session');
    }
    ProfileStore.saveProfile(
      ArtistProfile(
        userId: current.userId,
        name: displayName,
        username: username,
        bio: bio,
      ),
    );
  }

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    // Local mode: no remote auth provider.
  }
}

// ─────────────────────────────────────────────
// Local (mock) Beats — kept for offline testing
// ─────────────────────────────────────────────
class LocalBeatsBackend implements BeatsBackend {
  @override
  Future<void> addBeat(BeatModel beat) async {
    BeatStore.addBeat(beat);
  }

  @override
  Future<List<BeatModel>> fetchAllBeats() async {
    return BeatStore.beats;
  }

  @override
  Future<List<BeatModel>> fetchBeatsByProducer(String producerId) async {
    return BeatStore.getBeatsByProducer(producerId);
  }

  @override
  Future<void> updateBeat(BeatModel beat) async {
    BeatStore.updateBeat(beat);
  }

  @override
  Future<void> uploadBeatWithFiles({
    required BeatModel beat,
    required List<int> audioBytes,
    required String audioExtension,
    List<int>? coverArtBytes,
    String? coverArtExtension,
  }) async {
    // Local mock: just store with the local file paths
    final mockBeat = BeatModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: beat.title,
      producer: beat.producer,
      producerId: beat.producerId,
      genre: beat.genre,
      bpm: beat.bpm,
      basicLicensePrice: beat.basicLicensePrice,
      premiumLicensePrice: beat.premiumLicensePrice,
      exclusiveLicensePrice: beat.exclusiveLicensePrice,
      description: beat.description,
      audioPath: 'local_mock.$audioExtension',
      coverArtPath: null,
    );
    BeatStore.addBeat(mockBeat);
  }
}

// ─────────────────────────────────────────────
// Local (mock) Purchases — kept for offline testing
// ─────────────────────────────────────────────
class LocalPurchasesBackend implements PurchasesBackend {
  final List<PurchasedBeat> _store = [];

  @override
  Future<void> recordPurchase(PurchasedBeat purchase) async {
    _store.add(purchase);
  }

  @override
  Future<List<PurchasedBeat>> fetchPurchasesByBuyer(String buyerUserId) async {
    return _store.where((p) => p.buyerUserId == buyerUserId).toList()
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
  }

  @override
  Future<List<PurchasedBeat>> fetchPurchasesBySeller(String producerId) async {
    return _store.where((p) => p.beat.producerId == producerId).toList()
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
  }

  @override
  Future<double> fetchTotalRevenue(String producerId) async {
    return _store
        .where((p) => p.beat.producerId == producerId)
        .fold<double>(0, (sum, p) => sum + p.pricePaid);
  }
}

// ─────────────────────────────────────────────
// Local (mock) Follow — kept for offline testing
// ─────────────────────────────────────────────
class LocalFollowBackend implements FollowBackend {
  final Map<String, Set<String>> _following = {};

  @override
  Future<bool> isFollowing(String myUid, String targetUid) async =>
      (_following[myUid] ?? {}).contains(targetUid);

  @override
  Future<void> follow(String myUid, String targetUid) async =>
      _following.putIfAbsent(myUid, () => {}).add(targetUid);

  @override
  Future<void> unfollow(String myUid, String targetUid) async =>
      _following[myUid]?.remove(targetUid);

  @override
  Future<List<String>> getFollowingIds(String uid) async =>
      (_following[uid] ?? {}).toList();

  @override
  Future<List<String>> getFollowerIds(String uid) async {
    final result = <String>[];
    _following.forEach((followerId, set) {
      if (set.contains(uid)) result.add(followerId);
    });
    return result;
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String uid) async => null;

  @override
  Future<List<Map<String, dynamic>>> searchUsers(
    String query, {
    int limit = 20,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final all = ProfileStore.getAllProfiles();
    final matched = all
        .where((p) {
          return p.username.toLowerCase().contains(q) ||
              p.displayName.toLowerCase().contains(q);
        })
        .take(limit);

    return matched
        .map(
          (p) => {
            'uid': p.userId,
            'username': p.username,
            'displayName': p.displayName,
            'bio': p.bio,
            'role': p.role,
          },
        )
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> listUsersByRole(
    String role, {
    int limit = 20,
    String? excludeUid,
  }) async {
    final matched = ProfileStore.getAllProfiles()
        .where((p) {
          if (excludeUid != null && p.userId == excludeUid) return false;
          return p.role == role;
        })
        .take(limit);

    return matched
        .map(
          (p) => {
            'uid': p.userId,
            'username': p.username,
            'displayName': p.displayName,
            'bio': p.bio,
            'role': p.role,
          },
        )
        .toList();
  }
}

// ─────────────────────────────────────────────
// AppBackend — single access point for the app
// Swap to Local* classes for offline testing
// ─────────────────────────────────────────────
class AppBackend {
  static final AuthBackend auth = SupabaseAuthBackend();
  static final BeatsBackend beats = SupabaseBeatsBackend();
  static final PurchasesBackend purchases = SupabasePurchasesBackend();
  static final FollowBackend follow = SupabaseFollowBackend();
}
