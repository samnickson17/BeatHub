class UserProfile {
  final String userId;
  final String username;
  final String displayName;
  final String bio;
  final String role; // buyer | producer
  final String? profileImagePath;
  final bool profileCompleted;

  UserProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.role,
    this.profileImagePath,
    required this.profileCompleted,
  });

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? role,
    String? profileImagePath,
    bool? profileCompleted,
  }) {
    return UserProfile(
      userId: userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      profileCompleted:
          profileCompleted ?? this.profileCompleted,
    );
  }
}
