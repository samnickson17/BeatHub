import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../beats/beat_store.dart';
import '../beats/beat_model.dart';
import 'rap_record_page.dart';

class SelectBeatPage extends StatefulWidget {
  const SelectBeatPage({super.key});

  @override
  State<SelectBeatPage> createState() => _SelectBeatPageState();
}

class _SelectBeatPageState extends State<SelectBeatPage> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingBeatId;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(BeatModel beat) async {
    final isPlaying = _playingBeatId == beat.id;
    if (isPlaying) {
      await _player.stop();
      if (mounted) {
        setState(() => _playingBeatId = null);
      }
      return;
    }

    await _player.stop();
    if (beat.audioPath.startsWith('assets/')) {
      await _player.play(
        AssetSource(beat.audioPath.replaceFirst('assets/', '')),
      );
    } else {
      await _player.play(DeviceFileSource(beat.audioPath));
    }

    if (mounted) {
      setState(() => _playingBeatId = beat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<BeatModel> beats = BeatStore.beats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Beat'),
        centerTitle: true,
      ),
      body: beats.isEmpty
          ? const Center(
              child: Text('No beats available for rap preview'),
            )
          : ListView.builder(
              itemCount: beats.length,
              itemBuilder: (context, index) {
                final beat = beats[index];
                final isPlaying = _playingBeatId == beat.id;

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(beat.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${beat.genre} - ${beat.bpm} BPM'),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: () => _togglePreview(beat),
                          icon: Icon(
                            isPlaying ? Icons.stop : Icons.play_arrow,
                            size: 18,
                          ),
                          label: Text(isPlaying ? 'Stop' : 'Listen'),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    isThreeLine: true,
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
