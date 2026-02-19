import 'dart:io';

import 'package:flutter/material.dart';

import 'follow_store.dart';

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
  late bool _isFollowing;

  @override
  void initState() {
    super.initState();
    _isFollowing = FollowStore.isFollowing(widget.currentUserId, widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.role == "producer" ? "Producer Profile" : "Artist Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.deepPurple,
              backgroundImage: widget.profileImagePath != null
                  ? FileImage(File(widget.profileImagePath!))
                  : null,
              child: widget.profileImagePath == null
                  ? const Icon(Icons.person, size: 45, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              widget.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text("@${widget.username}", style: const TextStyle(color: Colors.grey)),
            if (widget.bio.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.bio, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_isFollowing) {
                    FollowStore.unfollow(widget.currentUserId, widget.userId);
                  } else {
                    FollowStore.follow(widget.currentUserId, widget.userId);
                  }
                  _isFollowing = !_isFollowing;
                });
              },
              child: Text(_isFollowing ? "Unfollow" : "Follow"),
            ),
          ],
        ),
      ),
    );
  }
}
