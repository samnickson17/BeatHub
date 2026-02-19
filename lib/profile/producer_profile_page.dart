import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../backend/local_backend.dart';
import '../beats/beat_detail_page.dart';
import '../beats/beat_model.dart';
import '../core/routes.dart';
import '../producer/edit_beat_page.dart';
import '../producer/revenue_calculator.dart';
import 'edit_producer_profile_page.dart';
import 'follow_list_page.dart';
import 'producer_profile_store.dart';

class ProducerProfilePage extends StatefulWidget {
  const ProducerProfilePage({super.key});

  @override
  State<ProducerProfilePage> createState() => _ProducerProfilePageState();
}

class _ProducerProfilePageState extends State<ProducerProfilePage> {
  Map<String, dynamic>? _userData;
  List<BeatModel> _beats = [];
  List<String> _followerIds = [];
  List<String> _followingIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final uid = AppBackend.auth.currentUser?.userId ?? '';
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
        AppBackend.beats.fetchBeatsByProducer(uid),
        AppBackend.follow.getFollowerIds(uid),
        AppBackend.follow.getFollowingIds(uid),
      ]);
      if (mounted) {
        setState(() {
          _userData =
              (results[0] as DocumentSnapshot).data()
                  as Map<String, dynamic>? ??
              {};
          _beats = List<BeatModel>.from(results[1] as List);
          _followerIds = List<String>.from(results[2] as List);
          _followingIds = List<String>.from(results[3] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = (_userData?['displayName'] ?? _userData?['username'] ?? '')
        .toString();
    final username = (_userData?['username'] ?? '').toString();
    final bio = (_userData?['bio'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Producer Profile"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
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
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name.isNotEmpty ? name : 'No name set',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "@$username",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      bio,
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
                          builder: (_) => EditProducerProfilePage(
                            profile: ProducerProfileStore.profile,
                          ),
                        ),
                      );
                      if (changed == true && mounted) _load();
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
                _statItem(label: "Beats", value: _beats.length.toString()),
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
                        emptyText: "No following yet",
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text("Revenue & Insights"),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RevenueCalculatorPage(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "My Beats",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _beats.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No beats uploaded yet"),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _beats.length,
                    itemBuilder: (context, index) {
                      final beat = _beats[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading:
                              beat.coverArtPath != null &&
                                  beat.coverArtPath!.startsWith('http')
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    beat.coverArtPath!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.music_note),
                                  ),
                                )
                              : const Icon(Icons.music_note, size: 40),
                          title: Text(beat.title),
                          subtitle: Text(
                            "${beat.genre} · Rs ${beat.basicLicensePrice.toStringAsFixed(0)}",
                          ),
                          trailing: TextButton(
                            onPressed: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditBeatPage(beat: beat),
                                ),
                              );
                              if (changed == true && mounted) _load();
                            },
                            child: const Text("Edit"),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BeatDetailPage(beat: beat),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 30),
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
                    (r) => false,
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
