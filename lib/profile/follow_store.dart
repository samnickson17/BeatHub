class FollowStore {
  // followerId -> set of followingIds
  static final Map<String, Set<String>> _followingMap = {};

  /// Follow a user
  static void follow(String followerId, String followingId) {
    if (followerId == followingId) return;

    _followingMap.putIfAbsent(followerId, () => {});
    _followingMap[followerId]!.add(followingId);
  }

  /// Unfollow a user
  static void unfollow(String followerId, String followingId) {
    _followingMap[followerId]?.remove(followingId);
  }

  /// Check if follower already follows user
  static bool isFollowing(
      String followerId, String followingId) {
    return _followingMap[followerId]
            ?.contains(followingId) ??
        false;
  }

  /// Followers count of a user
  static int followersCount(String userId) {
    int count = 0;
    for (final entry in _followingMap.entries) {
      if (entry.value.contains(userId)) {
        count++;
      }
    }
    return count;
  }

  /// Following count of a user
  static int followingCount(String userId) {
    return _followingMap[userId]?.length ?? 0;
  }
}
