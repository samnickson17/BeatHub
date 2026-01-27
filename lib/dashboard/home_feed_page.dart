import 'package:flutter/material.dart';
import '../profile/profile_store.dart';
import '../profile/follow_store.dart';
import '../profile/user_profile_model.dart';
import '../profile/public_profile_page.dart';

class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = ProfileStore.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text("No user logged in"),
      );
    }

    // Get followed users
    final followedProfiles = ProfileStore.getAllProfiles()
        .where((profile) =>
            FollowStore.isFollowing(
              currentUser.userId,
              profile.userId,
            ) &&
            profile.role == "producer")
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
      ),
      body: followedProfiles.isEmpty
          ? _buildSuggestedProducers(context)
          : _buildFollowedFeed(
              context, followedProfiles),
    );
  }

  // 🔹 FOLLOWED FEED
  Widget _buildFollowedFeed(
    BuildContext context,
    List<UserProfile> producers,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: producers.length,
      itemBuilder: (context, index) {
        final producer = producers[index];

        return Card(
          child: ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(producer.displayName),
            subtitle:
                Text("@${producer.username} • Producer"),
            trailing:
                const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfilePage(
                    profile: producer,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 🔹 SUGGESTED PRODUCERS
  Widget _buildSuggestedProducers(
      BuildContext context) {
    final producers = ProfileStore.getAllProfiles()
        .where((p) => p.role == "producer")
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Suggested Producers",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...producers.map(
          (producer) => Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(producer.displayName),
              subtitle:
                  Text("@${producer.username}"),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicProfilePage(
                      profile: producer,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (producers.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                "No producers available yet",
              ),
            ),
          ),
      ],
    );
  }
}
