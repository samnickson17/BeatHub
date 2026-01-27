import 'package:flutter/material.dart';
import 'user_profile_model.dart';
import 'profile_store.dart';
import 'follow_store.dart';

class PublicProfilePage extends StatefulWidget {
  final UserProfile profile;

  const PublicProfilePage({
    super.key,
    required this.profile,
  });

  @override
  State<PublicProfilePage> createState() =>
      _PublicProfilePageState();
}

class _PublicProfilePageState
    extends State<PublicProfilePage> {
  late bool _isFollowing;

  @override
  void initState() {
    super.initState();
    final currentUser = ProfileStore.currentUser;
    if (currentUser != null) {
      _isFollowing = FollowStore.isFollowing(
        currentUser.userId,
        widget.profile.userId,
      );
    } else {
      _isFollowing = false;
    }
  }

  void _toggleFollow() {
    final currentUser = ProfileStore.currentUser;
    if (currentUser == null) return;

    setState(() {
      if (_isFollowing) {
        FollowStore.unfollow(
          currentUser.userId,
          widget.profile.userId,
        );
        _isFollowing = false;
      } else {
        FollowStore.follow(
          currentUser.userId,
          widget.profile.userId,
        );
        _isFollowing = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ProfileStore.currentUser;

    final followers =
        FollowStore.followersCount(widget.profile.userId);
    final following =
        FollowStore.followingCount(widget.profile.userId);

    return Scaffold(
      appBar: AppBar(
        title: Text("@${widget.profile.username}"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 👤 PROFILE HEADER
            CircleAvatar(
              radius: 45,
              child: Icon(
                Icons.person,
                size: 42,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.profile.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "@${widget.profile.username}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 6),

            Text(
              widget.profile.bio,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            // ➕ FOLLOW BUTTON (NOT FOR SELF)
            if (currentUser != null &&
                currentUser.userId !=
                    widget.profile.userId)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing
                        ? Colors.grey
                        : Colors.deepPurple,
                  ),
                  child: Text(
                    _isFollowing ? "Unfollow" : "Follow",
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 📊 STATS (REAL)
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  label: "Beats",
                  value: "0",
                ),
                _StatItem(
                  label: "Followers",
                  value: followers.toString(),
                ),
                _StatItem(
                  label: "Following",
                  value: following.toString(),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 🎵 BEATS SECTION
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.profile.role == "producer"
                    ? "Beats"
                    : "Purchased Beats",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: 0,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.grey.shade300,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 STAT WIDGET
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
