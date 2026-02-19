import 'package:flutter/material.dart';

import '../backend/local_backend.dart';

class OtherProfilePage extends StatefulWidget {
  final String currentUserId;
  final String userId;
  final String name;
  final String username;
  final String bio;
  final String role;
  final String? profileImagePath;

  const OtherProfilePage({
    super.key,
    required this.currentUserId,
    required this.userId,
    required this.name,
    required this.username,
    required this.bio,
    required this.role,
    this.profileImagePath,
  });

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  bool _isFollowing = false;
  bool _followLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowState();
  }

  Future<void> _loadFollowState() async {
    final following = await AppBackend.follow.isFollowing(
      widget.currentUserId,
      widget.userId,
    );
    if (mounted)
      setState(() {
        _isFollowing = following;
        _followLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.role == "producer" ? "Producer Profile" : "Artist Profile",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.person, size: 45, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              widget.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "@${widget.username}",
              style: const TextStyle(color: Colors.grey),
            ),
            if (widget.bio.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.bio, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _followLoading
                  ? null
                  : () async {
                      setState(() => _followLoading = true);
                      try {
                        if (_isFollowing) {
                          await AppBackend.follow.unfollow(
                            widget.currentUserId,
                            widget.userId,
                          );
                        } else {
                          await AppBackend.follow.follow(
                            widget.currentUserId,
                            widget.userId,
                          );
                        }
                        if (mounted) {
                          setState(() {
                            _isFollowing = !_isFollowing;
                            _followLoading = false;
                          });
                        }
                      } catch (_) {
                        if (mounted) setState(() => _followLoading = false);
                      }
                    },
              child: _followLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isFollowing ? "Unfollow" : "Follow"),
            ),
          ],
        ),
      ),
    );
  }
}
