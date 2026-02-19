import 'package:flutter/material.dart';

import '../backend/local_backend.dart';
import '../beats/beat_detail_page.dart';
import '../beats/beat_model.dart';
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
  List<BeatModel> _beats = [];
  bool _beatsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowData();
    _loadBeats();
  }

  Future<void> _loadBeats() async {
    try {
      final beats = await AppBackend.beats.fetchBeatsByProducer(
        widget.profile.userId,
      );
      if (mounted) setState(() => _beats = beats);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _beatsLoading = false);
    }
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
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _followersCount = (_followersCount - 1).clamp(0, 999999);
          });
        }
      } else {
        await AppBackend.follow.follow(myUid, widget.profile.userId);
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _followersCount++;
          });
        }
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
                _StatItem(label: "Beats", value: _beats.length.toString()),
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

            if (_beatsLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(),
              )
            else if (_beats.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "No beats uploaded yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _beats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final beat = _beats[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BeatDetailPage(beat: beat),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child:
                          beat.coverArtPath != null &&
                              beat.coverArtPath!.startsWith('http')
                          ? Image.network(
                              beat.coverArtPath!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _BeatTile(title: beat.title),
                            )
                          : _BeatTile(title: beat.title),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// 🔹 BEAT TILE (fallback when no cover art)
class _BeatTile extends StatelessWidget {
  final String title;
  const _BeatTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple.shade100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
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
