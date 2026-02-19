import 'dart:io';

import 'package:flutter/material.dart';

import '../backend/local_backend.dart';
import '../core/routes.dart';
import '../data/purchased_beats.dart';
import 'edit_artist_profile_page.dart';
import 'follow_list_page.dart';
import 'follow_store.dart';
import 'profile_store.dart';
import 'purchased_beats_page.dart';

class ArtistProfilePage extends StatefulWidget {
  const ArtistProfilePage({super.key});

  @override
  State<ArtistProfilePage> createState() => _ArtistProfilePageState();
}

class _ArtistProfilePageState extends State<ArtistProfilePage> {
  @override
  Widget build(BuildContext context) {
    final profile = ProfileStore.getProfile(ProfileStore.currentUserId)!;
    final purchases = PurchasedBeatsStore.purchasedBeats;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Artist Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.deepPurple,
                    backgroundImage: profile.profileImagePath != null
                        ? FileImage(File(profile.profileImagePath!))
                        : null,
                    child: profile.profileImagePath == null
                        ? const Icon(Icons.person, size: 45, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "@${profile.username}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (profile.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditArtistProfilePage(profile: profile),
                        ),
                      );
                      if (changed == true && mounted) {
                        setState(() {});
                      }
                    },
                    child: const Text("Edit Profile"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem(
                  label: "Purchased",
                  value: purchases.length.toString(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PurchasedBeatsPage(),
                      ),
                    );
                  },
                ),
                _statItem(
                  label: "Followers",
                  value: FollowStore.followersCount(ProfileStore.currentUserId)
                      .toString(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowListPage(
                          title: "Followers",
                          users: FollowStore.followersList(
                            ProfileStore.currentUserId,
                          ),
                          emptyText: "No followers yet",
                        ),
                      ),
                    );
                  },
                ),
                _statItem(
                  label: "Following",
                  value: FollowStore.followingCount(ProfileStore.currentUserId)
                      .toString(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowListPage(
                          title: "Following",
                          users: FollowStore.followingList(
                            ProfileStore.currentUserId,
                          ),
                          emptyText: "No following yet",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                onPressed: () async {
                  await AppBackend.auth.logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
