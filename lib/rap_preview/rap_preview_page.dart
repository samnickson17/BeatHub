import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'select_beat_page.dart';
import 'audio_mix_context.dart';

class _Recording {
  final String path;
  final String beatTitle;
  final String beatId;
  final String beatAudioPath;
  final DateTime createdAt;

  const _Recording({
    required this.path,
    required this.beatTitle,
    required this.beatId,
    required this.beatAudioPath,
    required this.createdAt,
  });

  factory _Recording.fromJson(Map<String, dynamic> j) => _Recording(
    path: j['path'] ?? '',
    beatTitle: j['beatTitle'] ?? 'Unknown Beat',
    beatId: j['beatId'] ?? '',
    beatAudioPath: j['beatAudioPath'] ?? '',
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class RapPreviewPage extends StatefulWidget {
  const RapPreviewPage({super.key});

  @override
  State<RapPreviewPage> createState() => _RapPreviewPageState();
}

class _RapPreviewPageState extends State<RapPreviewPage> {
  List<_Recording> _recordings = [];
  bool _isLoading = true;

  // Playback
  late final AudioPlayer _beatPlayer;
  late final AudioPlayer _voicePlayer;
  String? _playingPath;
  StreamSubscription? _playSub;

  @override
  void initState() {
    super.initState();
    _beatPlayer = AudioPlayer();
    _voicePlayer = AudioPlayer();
    if (!kIsWeb) {
      _beatPlayer.setAudioContext(mixingAudioContext);
      _voicePlayer.setAudioContext(mixingAudioContext);
    }
    _loadRecordings();
  }

  @override
  void dispose() {
    _playSub?.cancel();
    _beatPlayer.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('local_recordings') ?? [];
    final List<_Recording> loaded = [];
    for (final s in raw) {
      try {
        loaded.add(_Recording.fromJson(jsonDecode(s)));
      } catch (_) {}
    }
    if (mounted)
      setState(() {
        _recordings = loaded;
        _isLoading = false;
      });
  }

  Future<void> _togglePlay(_Recording rec) async {
    if (_playingPath == rec.path) {
      await _playSub?.cancel();
      _playSub = null;
      await _beatPlayer.stop();
      await _voicePlayer.stop();
      if (mounted) setState(() => _playingPath = null);
      return;
    }

    await _playSub?.cancel();
    _playSub = null;
    await _beatPlayer.stop();
    await _voicePlayer.stop();

    // Play beat
    final audioPath = rec.beatAudioPath;
    if (audioPath.startsWith('assets/')) {
      await _beatPlayer.play(
        AssetSource(audioPath.replaceFirst('assets/', '')),
      );
    } else if (audioPath.startsWith('http')) {
      await _beatPlayer.play(UrlSource(audioPath));
    } else if (audioPath.isNotEmpty) {
      await _beatPlayer.play(DeviceFileSource(audioPath));
    }

    // Play voice recording — blob URL on web, file path on native
    if (!kIsWeb && rec.path.isNotEmpty) {
      await _voicePlayer.play(DeviceFileSource(rec.path));
    } else if (kIsWeb && rec.path.isNotEmpty) {
      await _voicePlayer.play(UrlSource(rec.path));
    }

    if (mounted) setState(() => _playingPath = rec.path);

    _playSub = _voicePlayer.onPlayerComplete.listen((_) async {
      await _playSub?.cancel();
      _playSub = null;
      await _beatPlayer.stop();
      if (mounted) setState(() => _playingPath = null);
    });
  }

  Future<void> _deleteRecording(_Recording rec) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Recording?"),
        content: Text("Delete \"${rec.beatTitle}\" recording?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Stop if currently playing
    if (_playingPath == rec.path) {
      await _beatPlayer.stop();
      await _voicePlayer.stop();
      if (mounted) setState(() => _playingPath = null);
    }

    // Delete the file
    if (!kIsWeb) {
      try {
        final file = File(rec.path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    // Remove from prefs
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('local_recordings') ?? [];
    raw.removeWhere((s) {
      try {
        return (jsonDecode(s) as Map)['path'] == rec.path;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList('local_recordings', raw);

    if (mounted)
      setState(() => _recordings.removeWhere((r) => r.path == rec.path));
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Recordings"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.mic),
        label: const Text("New Recording"),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SelectBeatPage()),
          );
          _loadRecordings();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recordings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic_none, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "No recordings yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tap the button below to select a beat and start rapping!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: _recordings.length,
              itemBuilder: (context, index) {
                final rec = _recordings[index];
                final isPlaying = _playingPath == rec.path;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPlaying
                          ? Colors.deepPurple
                          : Colors.deepPurple.shade100,
                      child: Icon(
                        isPlaying ? Icons.stop : Icons.headphones,
                        color: isPlaying ? Colors.white : Colors.deepPurple,
                      ),
                    ),
                    title: Text(rec.beatTitle),
                    subtitle: Text(
                      _formatDate(rec.createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.stop_circle : Icons.play_circle,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () => _togglePlay(rec),
                          tooltip: isPlaying ? "Stop" : "Play Mix",
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteRecording(rec),
                          tooltip: "Delete",
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
