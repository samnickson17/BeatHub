import 'profile_store.dart';

class FollowStore {
  static final Map<String, Set<String>> _followingByUser = {};

  static bool isFollowing(String userOrTargetId, [String? targetUserId]) {
    if (targetUserId == null) {
      return (_followingByUser[ProfileStore.currentUserId] ?? {}).contains(
        userOrTargetId,
      );
    }
    return (_followingByUser[userOrTargetId] ?? {}).contains(targetUserId);
  }

  static void follow(String userOrTargetId, [String? targetUserId]) {
    if (targetUserId == null) {
      _followingByUser
          .putIfAbsent(ProfileStore.currentUserId, () => <String>{})
          .add(userOrTargetId);
      return;
    }
    _followingByUser
        .putIfAbsent(userOrTargetId, () => <String>{})
        .add(targetUserId);
  }

  static void unfollow(String userOrTargetId, [String? targetUserId]) {
    if (targetUserId == null) {
      _followingByUser[ProfileStore.currentUserId]?.remove(userOrTargetId);
      return;
    }
    _followingByUser[userOrTargetId]?.remove(targetUserId);
  }

  static int followersCount(String userId) {
    return followersList(userId).length;
  }

  static int followingCount(String userId) {
    return (_followingByUser[userId] ?? {}).length;
  }

  static List<String> followersList(String userId) {
    final followers = <String>[];
    _followingByUser.forEach((followerId, followingIds) {
      if (followingIds.contains(userId)) {
        followers.add(followerId);
      }
    });
    return followers;
  }

  static List<String> followingList(String userId) {
    return (_followingByUser[userId] ?? {}).toList();
  }
}
