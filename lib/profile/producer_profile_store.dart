class ProducerProfileStore {
  static ProducerProfile _profile = const ProducerProfile(
    userId: "producer_001",
    name: "Producer Sam",
    username: "producersam",
    bio: "Beat producer",
  );

  static ProducerProfile get profile => _profile;

  static void saveProfile(ProducerProfile profile) {
    _profile = profile;
  }
}

class ProducerProfile {
  final String userId;
  final String name;
  final String username;
  final String bio;
  final String? profileImagePath;

  const ProducerProfile({
    required this.userId,
    required this.name,
    required this.username,
    required this.bio,
    this.profileImagePath,
  });

  ProducerProfile copyWith({
    String? name,
    String? username,
    String? bio,
    String? profileImagePath,
  }) {
    return ProducerProfile(
      userId: userId,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}
