import 'package:flutter/material.dart';

class ArtistSearchPage extends StatelessWidget {
  const ArtistSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Beats"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search Field
            TextField(
              decoration: InputDecoration(
                hintText: "Search by genre, mood, or producer",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🎛️ Filters
            const Text(
              "Popular Filters",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text("Drill")),
                Chip(label: Text("Trap")),
                Chip(label: Text("LoFi")),
                Chip(label: Text("Chill")),
                Chip(label: Text("120–140 BPM")),
              ],
            ),

            const SizedBox(height: 30),

            // 🎵 Search Results (Dummy)
            const Text(
              "Suggested Beats",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.music_note),
                    title: Text("Drill Vibes"),
                    subtitle: Text("140 BPM • Drill"),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                  ListTile(
                    leading: Icon(Icons.music_note),
                    title: Text("LoFi Chill"),
                    subtitle: Text("90 BPM • LoFi"),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
