import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../backend/local_backend.dart';
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
  List<BeatModel> _beats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBeats();
  }

  Future<void> _loadBeats() async {
    try {
      final beats = await AppBackend.beats.fetchAllBeats();
      if (mounted) setState(() => _beats = beats);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

    try {
      await _player.stop();
      if (beat.audioPath.startsWith('assets/')) {
        await _player.play(
          AssetSource(beat.audioPath.replaceFirst('assets/', '')),
        );
      } else if (beat.audioPath.startsWith('http')) {
        await _player.play(UrlSource(beat.audioPath));
      } else {
        await _player.play(DeviceFileSource(beat.audioPath));
      }

      if (mounted) {
        setState(() => _playingBeatId = beat.id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not preview beat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Beat'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _beats.isEmpty
          ? const Center(child: Text('No beats available for rap preview'))
          : ListView.builder(
              itemCount: _beats.length,
              itemBuilder: (context, index) {
                final beat = _beats[index];
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
                          builder: (_) => RapRecordPage(selectedBeat: beat),
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
