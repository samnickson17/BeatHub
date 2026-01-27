import 'package:flutter/material.dart';
import 'beat_model.dart';
import 'beat_detail_page.dart';

class BeatListPage extends StatelessWidget {
  const BeatListPage({super.key});

  // Dummy beats (now with producerId)
  List<BeatModel> get beats => [
        BeatModel(
          id: "1",
          title: "Drill Vibes",
          producer: "Producer Sam",
          producerId: "producer_1",
          genre: "Drill",
          bpm: 140,
          price: 29.99,
          description: "Hard drill beat for rap artists.",
          coverArtPath: null,
        ),
        BeatModel(
          id: "2",
          title: "LoFi Chill",
          producer: "Producer Alex",
          producerId: "producer_2",
          genre: "LoFi",
          bpm: 90,
          price: 19.99,
          description: "Smooth lofi beat for chill vibes.",
          coverArtPath: null,
        ),
        BeatModel(
          id: "3",
          title: "Trap Energy",
          producer: "Producer Nick",
          producerId: "producer_3",
          genre: "Trap",
          bpm: 150,
          price: 39.99,
          description: "High energy trap beat.",
          coverArtPath: null,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beats"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: beats.length,
        itemBuilder: (context, index) {
          final beat = beats[index];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.music_note, size: 32),
              title: Text(
                beat.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "${beat.genre} • ${beat.bpm} BPM\nBy ${beat.producer}",
              ),
              trailing: Text(
                "₹${beat.price}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              isThreeLine: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BeatDetailPage(beat: beat),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
