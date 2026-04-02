import '../backend/backend_contracts.dart';
import 'user_profile_model.dart';

class ProfileStore {
  static UserProfile? _currentUser;

  // Profile records populated from Firebase — no hardcoded data.
  static final Map<String, UserProfile> _profiles = {};

  // Artist-profile view model (used by artist profile/edit pages).
  static final Map<String, ArtistProfile> _artistProfiles = {};

  static String get currentUserId => _currentUser?.userId ?? '';

  static UserProfile? get currentUser => _currentUser;

  static List<UserProfile> getAllProfiles() => _profiles.values.toList();

  static bool isProfileCompleted(String userId) {
    return _artistProfiles.containsKey(userId) ||
        (_profiles[userId]?.profileCompleted ?? false);
  }

  static bool isUsernameTaken(String username, {String? excludeUserId}) {
    final normalized = username.trim().toLowerCase();
    return _profiles.values.any(
      (profile) =>
          profile.userId != excludeUserId &&
          profile.username.trim().toLowerCase() == normalized,
    );
  }

  static ArtistProfile? getProfile(String userId) {
    final artist = _artistProfiles[userId];
    if (artist != null) return artist;

    final generic = _profiles[userId];
    if (generic == null) return null;
    return ArtistProfile(
      userId: generic.userId,
      name: generic.displayName,
      username: generic.username,
      bio: generic.bio,
      profileImagePath: generic.profileImagePath,
    );
  }

  static UserProfile? getUserProfile(String userId) => _profiles[userId];

  static void saveProfile(Object profile) {
    if (profile is ArtistProfile) {
      _saveArtistProfile(profile);
      return;
    }
    if (profile is UserProfile) {
      _saveUserProfile(profile);
      return;
    }
    throw ArgumentError("Unsupported profile type: ${profile.runtimeType}");
  }

  static void setCurrentUserFromSession(
    SessionUser session, {
    String? username,
    String? displayName,
  }) {
    final existing = _profiles[session.userId];
    final resolvedUsername = (username != null && username.trim().isNotEmpty)
        ? username.trim()
        : existing?.username ?? _usernameFromEmail(session.email);
    final resolvedName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : existing?.displayName ?? resolvedUsername;
    final resolvedRole =
        session.role == AppUserRole.producer ? "producer" : "buyer";

    final profile = UserProfile(
      userId: session.userId,
      username: resolvedUsername,
      displayName: resolvedName,
      bio: existing?.bio ?? "",
      role: resolvedRole,
      profileImagePath: existing?.profileImagePath,
      profileCompleted: existing?.profileCompleted ?? false,
    );
    _saveUserProfile(profile);
    _currentUser = _profiles[session.userId];
  }

  static void clearCurrentUser() {
    _currentUser = null;
  }

  static void _saveArtistProfile(ArtistProfile artist) {
    _artistProfiles[artist.userId] = artist;

    final existing = _profiles[artist.userId];
    final role = existing?.role ??
        ((_currentUser?.userId == artist.userId) ? _currentUser!.role : "buyer");

    final updated = UserProfile(
      userId: artist.userId,
      username: artist.username,
      displayName: artist.name,
      bio: artist.bio,
      role: role,
      profileImagePath: artist.profileImagePath,
      profileCompleted: true,
    );
    _profiles[artist.userId] = updated;

    if (_currentUser?.userId == artist.userId) {
      _currentUser = updated;
    }
  }

  static void _saveUserProfile(UserProfile profile) {
    _profiles[profile.userId] = profile;
    _artistProfiles[profile.userId] = ArtistProfile(
      userId: profile.userId,
      name: profile.displayName,
      username: profile.username,
      bio: profile.bio,
      profileImagePath: profile.profileImagePath,
    );

    if (_currentUser?.userId == profile.userId) {
      _currentUser = profile;
    }
  }

  static String _usernameFromEmail(String email) {
    final localPart = email.split('@').first.trim().toLowerCase();
    if (localPart.isNotEmpty) return localPart;
    return "user_${DateTime.now().millisecondsSinceEpoch}";
  }
}

// ---------------- MODEL ----------------

class ArtistProfile {
  final String userId;
  final String name;
  final String username;
  final String bio;
  final String? profileImagePath;

  ArtistProfile({
    required this.userId,
    required this.name,
    required this.username,
    required this.bio,
    this.profileImagePath,
  });

  ArtistProfile copyWith({
    String? name,
    String? username,
    String? bio,
    String? profileImagePath,
  }) {
    return ArtistProfile(
      userId: userId,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}
