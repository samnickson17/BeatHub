import 'user_profile_model.dart';

class ProfileStore {
  // 🔐 Current logged-in user profile
  static UserProfile? currentUser;

  // 🌍 All profiles in app (dummy store for now)
  static final List<UserProfile> _allProfiles = [];

  /// Check if username already exists (Instagram-style)
  static bool isUsernameTaken(String username) {
    return _allProfiles.any(
      (profile) =>
          profile.username.toLowerCase() ==
          username.toLowerCase(),
    );
  }

  /// Save or update user profile
  static void saveProfile(UserProfile profile) {
    // Remove old profile if exists
    _allProfiles.removeWhere(
      (p) => p.userId == profile.userId,
    );

    _allProfiles.add(profile);
    currentUser = profile;
  }

  /// Get profile by username (for public profiles later)
  static UserProfile? getProfileByUsername(
      String username) {
    try {
      return _allProfiles.firstWhere(
        (profile) =>
            profile.username.toLowerCase() ==
            username.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Check if current user completed profile
  static bool isProfileCompleted() {
    return currentUser?.profileCompleted ?? false;
  }

  /// Debug helper (optional)
  static List<UserProfile> getAllProfiles() {
    return List.unmodifiable(_allProfiles);
  }
}
