import 'package:flutter/material.dart';
import '../beats/beat_store.dart';
import '../beats/beat_detail_page.dart';
import '../profile/profile_store.dart';
import '../profile/complete_profile_page.dart';
import '../beats/beat_model.dart';

class ArtistProfilePage extends StatefulWidget {
  const ArtistProfilePage({super.key});

  @override
  State<ArtistProfilePage> createState() =>
      _ArtistProfilePageState();
}

class _ArtistProfilePageState
    extends State<ArtistProfilePage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🔐 Open Complete Profile ONLY from profile tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ProfileStore.isProfileCompleted()) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CompleteProfilePage(
              userId: "demo_user_1",
              role: "buyer",
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ProfileStore.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No profile found")),
      );
    }

    // 🎵 FETCH BEATS
    List<BeatModel> beats = user.role == "producer"
        ? BeatStore.getBeatsByProducer(user.userId)
        : BeatStore.getAllBeats(); // dummy for buyer

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 👤 PROFILE HEADER
            CircleAvatar(
              radius: 45,
              child: Icon(
                Icons.person,
                size: 42,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "@${user.username}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 6),

            Text(
              user.bio,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // 📊 STATS
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  label: "Beats",
                  value: beats.length.toString(),
                ),
                const _StatItem(label: "Followers", value: "0"),
                const _StatItem(label: "Following", value: "0"),
              ],
            ),

            const SizedBox(height: 30),

            // 🎵 BEATS GRID
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                user.role == "producer"
                    ? "My Beats"
                    : "Purchased Beats",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            beats.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text("No beats yet"),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: beats.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final beat = beats[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BeatDetailPage(beat: beat),
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.music_note,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 40),

            // 🚪 LOGOUT
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(
                    context, "/login");
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

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
