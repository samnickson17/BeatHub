import 'dart:io';

import 'package:flutter/material.dart';

import '../backend/local_backend.dart';
import '../beats/beat_detail_page.dart';
import '../beats/beat_store.dart';
import '../core/routes.dart';
import '../producer/edit_beat_page.dart';
import '../producer/revenue_calculator.dart';
import 'edit_producer_profile_page.dart';
import 'follow_list_page.dart';
import 'follow_store.dart';
import 'producer_profile_store.dart';

class ProducerProfilePage extends StatefulWidget {
  const ProducerProfilePage({super.key});

  @override
  State<ProducerProfilePage> createState() => _ProducerProfilePageState();
}

class _ProducerProfilePageState extends State<ProducerProfilePage> {
  @override
  Widget build(BuildContext context) {
    final profile = ProducerProfileStore.profile;
    final producerId = profile.userId;
    final producerBeats = BeatStore.getBeatsByProducer(producerId);

    return Scaffold(
      appBar: AppBar(title: const Text("Producer Profile"), centerTitle: true),
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
                        ? const Icon(
                            Icons.person,
                            size: 45,
                            color: Colors.white,
                          )
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
                          builder: (_) =>
                              EditProducerProfilePage(profile: profile),
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
                  label: "Beats",
                  value: producerBeats.length.toString(),
                ),
                _statItem(
                  label: "Followers",
                  value: FollowStore.followersCount(producerId).toString(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowListPage(
                          title: "Followers",
                          users: FollowStore.followersList(producerId),
                          emptyText: "No followers yet",
                        ),
                      ),
                    );
                  },
                ),
                _statItem(
                  label: "Following",
                  value: FollowStore.followingCount(producerId).toString(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowListPage(
                          title: "Following",
                          users: FollowStore.followingList(producerId),
                          emptyText: "No following yet",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text("Revenue Calculator"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RevenueCalculatorPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "My Beats",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            producerBeats.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No beats uploaded yet"),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: producerBeats.length,
                    itemBuilder: (context, index) {
                      final beat = producerBeats[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(beat.title),
                          subtitle: Text("${beat.genre} - Rs ${beat.price}"),
                          trailing: TextButton(
                            onPressed: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditBeatPage(beat: beat),
                                ),
                              );
                              if (changed == true && context.mounted) {
                                setState(() {});
                              }
                            },
                            child: const Text("Edit"),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BeatDetailPage(beat: beat),
                              ),
                            );
                          },
                        ),
                      );
                    },
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
