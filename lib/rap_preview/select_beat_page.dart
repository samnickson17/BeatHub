import 'package:flutter/material.dart';
import '../beats/beat_model.dart';
import 'rap_record_page.dart';

class SelectBeatPage extends StatelessWidget {
  const SelectBeatPage({super.key});

  List<BeatModel> get beats => [
        BeatModel(
          id: "1",
          title: "Smoothy Drill",
          producer: "Producer Sam",
          producerId: "producer_001",
          genre: "Drill",
          bpm: 140,
          price: 0,
          description: "Drill demo beat",
          coverArtPath: null,
          audioPath: "assets/audio/smoothy_drill.wav",
        ),
        BeatModel(
          id: "2",
          title: "You & Me",
          producer: "Producer Sam",
          producerId: "producer_001",
          genre: "LoFi",
          bpm: 90,
          price: 0,
          description: "LoFi demo beat",
          coverArtPath: null,
          audioPath: "assets/audio/you_and_me.wav",
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

          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(beat.title),
            subtitle: Text("${beat.genre} • ${beat.bpm} BPM"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RapRecordPage(selectedBeat: beat),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
