import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'beat_store.dart';

class BeatListPage extends StatefulWidget {
  const BeatListPage({super.key});

  @override
  State<BeatListPage> createState() => _BeatListPageState();
}

class _BeatListPageState extends State<BeatListPage> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingId;

  @override
  Widget build(BuildContext context) {
    final beats = BeatStore.beats;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Beats"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: beats.length,
        itemBuilder: (context, index) {
          final beat = beats[index];
          final isPlaying = _playingId == beat.id;

          return ListTile(
            leading: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed: () async {
                if (isPlaying) {
                  await _player.stop();
                  setState(() => _playingId = null);
                } else {
                  await _player.stop();
                  await _player.play(
                    AssetSource(beat.audioPath.replaceFirst("assets/", "")),
                  );
                  setState(() => _playingId = beat.id);
                }
              },
            ),
            title: Text(beat.title),
            subtitle: Text("${beat.genre} • ${beat.bpm} BPM"),
          );
        },
      ),
    );
  }
}
