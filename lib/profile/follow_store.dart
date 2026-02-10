class FollowStore {
  static final Set<String> _followedProducers = {};

  static bool isFollowing(String producerId) {
    return _followedProducers.contains(producerId);
  }

  static void follow(String producerId) {
    _followedProducers.add(producerId);
  }

  static void unfollow(String producerId) {
    _followedProducers.remove(producerId);
  }

  static int followersCount(String producerId) {
    // Dummy base count + local follows
    return 120 + (_followedProducers.contains(producerId) ? 1 : 0);
  }
}
