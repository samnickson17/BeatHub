import 'package:flutter/material.dart';
import '../beats/beat_model.dart';
import 'rap_record_page.dart';

class SelectBeatPage extends StatelessWidget {
  const SelectBeatPage({super.key});

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
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Beat"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: beats.length,
        itemBuilder: (context, index) {
          final beat = beats[index];

          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.music_note),
              title: Text(beat.title),
              subtitle: Text(
                  "${beat.genre} • ${beat.bpm} BPM"),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RapRecordPage(selectedBeat: beat),
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
