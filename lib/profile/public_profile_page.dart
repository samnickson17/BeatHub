import 'package:flutter/material.dart';

import '../backend/local_backend.dart';
import 'user_profile_model.dart';

class PublicProfilePage extends StatefulWidget {
  final UserProfile profile;

  const PublicProfilePage({super.key, required this.profile});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  bool _isFollowing = false;
  bool _followLoading = true;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFollowData();
  }

  Future<void> _loadFollowData() async {
    final myUid = AppBackend.auth.currentUser?.userId ?? '';
    final targetUid = widget.profile.userId;
    final results = await Future.wait([
      AppBackend.follow.isFollowing(myUid, targetUid),
      AppBackend.follow.getFollowerIds(targetUid),
      AppBackend.follow.getFollowingIds(targetUid),
    ]);
    if (mounted) {
      setState(() {
        _isFollowing = results[0] as bool;
        _followersCount = (results[1] as List).length;
        _followingCount = (results[2] as List).length;
        _followLoading = false;
      });
    }
  }

  void _toggleFollow() async {
    final myUid = AppBackend.auth.currentUser?.userId;
    if (myUid == null) return;
    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await AppBackend.follow.unfollow(myUid, widget.profile.userId);
        if (mounted)
          setState(() {
            _isFollowing = false;
            _followersCount = (_followersCount - 1).clamp(0, 999999);
          });
      } else {
        await AppBackend.follow.follow(myUid, widget.profile.userId);
        if (mounted)
          setState(() {
            _isFollowing = true;
            _followersCount++;
          });
      }
    } catch (_) {}
    if (mounted) setState(() => _followLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = AppBackend.auth.currentUser?.userId;

    final followers = _followersCount;
    final following = _followingCount;

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
              child: Icon(Icons.person, size: 42, color: Colors.grey.shade700),
            ),

            const SizedBox(height: 10),

            Text(
              widget.profile.displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Text(
              "@${widget.profile.username}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 6),

            Text(widget.profile.bio, textAlign: TextAlign.center),

            const SizedBox(height: 15),

            // ➕ FOLLOW BUTTON (NOT FOR SELF)
            if (myUid != null && myUid != widget.profile.userId)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _followLoading ? null : _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing
                        ? Colors.grey
                        : Colors.deepPurple,
                  ),
                  child: _followLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isFollowing ? "Unfollow" : "Follow"),
                ),
              ),

            const SizedBox(height: 20),

            // 📊 STATS (REAL)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: "Beats", value: "0"),
                _StatItem(label: "Followers", value: followers.toString()),
                _StatItem(label: "Following", value: following.toString()),
              ],
            ),

            const SizedBox(height: 30),

            // 🎵 BEATS SECTION
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.profile.role == "producer" ? "Beats" : "Purchased Beats",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 0,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return Container(color: Colors.grey.shade300);
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

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
