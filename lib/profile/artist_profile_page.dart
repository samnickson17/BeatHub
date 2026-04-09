import 'package:flutter/material.dart';

import '../backend/local_backend.dart';
import '../core/routes.dart';
import 'edit_artist_profile_page.dart';
import 'follow_list_page.dart';

class ArtistProfilePage extends StatefulWidget {
  const ArtistProfilePage({super.key});

  @override
  State<ArtistProfilePage> createState() => _ArtistProfilePageState();
}

class _ArtistProfilePageState extends State<ArtistProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _purchaseCount = 0;
  List<String> _followerIds = [];
  List<String> _followingIds = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final uid = AppBackend.auth.currentUser?.userId ?? '';
      final results = await Future.wait([
        AppBackend.follow.getUserProfile(uid),
        AppBackend.purchases.fetchPurchasesByBuyer(uid),
        AppBackend.follow.getFollowerIds(uid),
        AppBackend.follow.getFollowingIds(uid),
      ]);
      if (mounted) {
        setState(() {
          _userData = (results[0] as Map<String, dynamic>?) ?? {};
          _purchaseCount = (results[1] as List).length;
          _followerIds = List<String>.from(results[2] as List);
          _followingIds = List<String>.from(results[3] as List);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = AppBackend.auth.currentUser;
    final displayName = (_userData?['displayName'] ?? '').toString().trim();
    final username = (_userData?['username'] ?? '').toString().trim();
    final bio = (_userData?['bio'] ?? '').toString().trim();
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + name ──
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName.isNotEmpty ? displayName : 'No name set',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username.isNotEmpty ? '@$username' : email,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                    onPressed: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditArtistProfilePage(
                            displayName: displayName,
                            username: username,
                            bio: bio,
                            email: email,
                          ),
                        ),
                      );
                      if (changed == true && mounted) _loadProfile();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem(label: "Purchased", value: _purchaseCount.toString()),
                _statItem(
                  label: "Followers",
                  value: _followerIds.length.toString(),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FollowListPage(
                        title: "Followers",
                        users: _followerIds,
                        emptyText: "No followers yet",
                      ),
                    ),
                  ),
                ),
                _statItem(
                  label: "Following",
                  value: _followingIds.length.toString(),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FollowListPage(
                        title: "Following",
                        users: _followingIds,
                        emptyText: "Not following anyone yet",
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // ── Logout ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                ),
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

            const SizedBox(height: 16),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
