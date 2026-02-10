import 'package:flutter/material.dart';
import '../beats/beat_store.dart';
import '../beats/beat_detail_page.dart';
import '../producer/revenue_calculator.dart';
import 'follow_store.dart';
import '../core/routes.dart';

class ProducerProfilePage extends StatefulWidget {
  const ProducerProfilePage({super.key});

  @override
  State<ProducerProfilePage> createState() =>
      _ProducerProfilePageState();
}

class _ProducerProfilePageState
    extends State<ProducerProfilePage> {
  // 🔐 Dummy logged-in producer info
  final String producerId = "producer_001";
  final String producerName = "Producer Sam";
  final String username = "@producersam";

  @override
  Widget build(BuildContext context) {
    final producerBeats =
        BeatStore.getBeatsByProducer(producerId);

    final isFollowing =
        FollowStore.isFollowing(producerId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Producer Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 PROFILE HEADER
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(
                      Icons.person,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    producerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username,
                    style:
                        const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // ❤️ FOLLOW BUTTON
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (isFollowing) {
                          FollowStore.unfollow(producerId);
                        } else {
                          FollowStore.follow(producerId);
                        }
                      });
                    },
                    child: Text(
                      isFollowing ? "Unfollow" : "Follow",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📊 STATS
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _statItem(
                  label: "Beats",
                  value: producerBeats.length.toString(),
                ),
                _statItem(
                  label: "Followers",
                  value: FollowStore.followersCount(
                          producerId)
                      .toString(),
                ),
                _statItem(
                  label: "Following",
                  value: "85",
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 💰 REVENUE BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label:
                    const Text("Revenue Calculator"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const RevenueCalculatorPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "My Beats",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // 🎹 BEATS LIST
            producerBeats.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child:
                        Text("No beats uploaded yet"),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: producerBeats.length,
                    itemBuilder: (context, index) {
                      final beat =
                          producerBeats[index];

                      return Card(
                        margin: const EdgeInsets.only(
                            bottom: 10),
                        child: ListTile(
                          leading: const Icon(
                              Icons.music_note),
                          title: Text(beat.title),
                          subtitle: Text(
                            "${beat.genre} • ₹${beat.price}",
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BeatDetailPage(
                                        beat: beat),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 30),

            // 🚪 LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                onPressed: () {
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
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style:
              const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
