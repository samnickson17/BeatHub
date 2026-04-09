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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isMissingFileError(Object error) {
    final raw = error.toString();
    return raw.contains('ENOENT') ||
        raw.contains('No such file or directory') ||
        raw.contains('FileNotFoundException');
  }

  String _normalizeStoredPath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return trimmed;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'file') {
      try {
        return uri.toFilePath();
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  bool _isStreamablePath(String path) {
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('content://') ||
        path.startsWith('blob:') ||
        path.startsWith('data:');
  }

  Future<bool> _recordingPathExists(String path) async {
    final normalized = _normalizeStoredPath(path);
    if (normalized.isEmpty) return false;
    if (_isStreamablePath(normalized)) return true;
    try {
      return await File(normalized).exists();
    } catch (_) {
      return false;
    }
  }

  Source _voiceSourceForPath(String path) {
    final normalized = _normalizeStoredPath(path);
    if (_isStreamablePath(normalized)) {
      return UrlSource(normalized);
    }
    return DeviceFileSource(normalized);
  }

  Map<String, dynamic> _recordingToJson(_Recording rec) {
    return {
      'path': rec.path,
      'beatTitle': rec.beatTitle,
      'beatId': rec.beatId,
      'beatAudioPath': rec.beatAudioPath,
      'createdAt': rec.createdAt.toIso8601String(),
    };
  }

  Future<void> _removeByPath(String path) async {
    final normalizedTarget = _normalizeStoredPath(path);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('local_recordings') ?? [];
    raw.removeWhere((s) {
      try {
        final rawPath = (jsonDecode(s) as Map)['path'];
        final stored = _normalizeStoredPath(rawPath?.toString() ?? '');
        return stored == normalizedTarget;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList('local_recordings', raw);
    if (mounted) {
      setState(
        () => _recordings.removeWhere(
          (r) => _normalizeStoredPath(r.path) == normalizedTarget,
        ),
      );
    }
  }

  Future<void> _playBeatTrack(_Recording rec, {double volume = 0.55}) async {
    final audioPath = rec.beatAudioPath;
    await _beatPlayer.setVolume(volume);
    if (audioPath.startsWith('assets/')) {
      await _beatPlayer.play(
        AssetSource(audioPath.replaceFirst('assets/', '')),
      );
    } else if (audioPath.startsWith('http')) {
      await _beatPlayer.play(UrlSource(audioPath));
    } else if (audioPath.isNotEmpty) {
      await _beatPlayer.play(DeviceFileSource(audioPath));
    }
  }

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
    debugPrint('[RapPreview] Raw recordings in prefs: ${raw.length}');
    final List<_Recording> loaded = [];
    final List<String> keptRaw = [];
    for (final s in raw) {
      try {
        final rec = _Recording.fromJson(jsonDecode(s));
        final normalizedRec = _Recording(
          path: _normalizeStoredPath(rec.path),
          beatTitle: rec.beatTitle,
          beatId: rec.beatId,
          beatAudioPath: rec.beatAudioPath,
          createdAt: rec.createdAt,
        );
        if (!kIsWeb && normalizedRec.path.isNotEmpty) {
          final exists = await _recordingPathExists(normalizedRec.path);
          debugPrint(
            '[RapPreview] Path check: ${normalizedRec.path} -> exists=$exists',
          );
          if (!exists) continue;
        }
        loaded.add(normalizedRec);
        keptRaw.add(jsonEncode(_recordingToJson(normalizedRec)));
      } catch (_) {}
    }
    if (keptRaw.length != raw.length) {
      await prefs.setStringList('local_recordings', keptRaw);
    }
    if (mounted) {
      setState(() {
        _recordings = loaded;
        _isLoading = false;
      });
    }
    debugPrint('[RapPreview] Loaded recordings: ${loaded.length}');
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

    try {
      // Voice first (MIUI devices can mute 2nd player when beat starts first).
      if (!kIsWeb && rec.path.isNotEmpty) {
        final exists = await _recordingPathExists(rec.path);
        if (!exists) {
          await _removeByPath(rec.path);
          _showMessage('Recording file is missing and was removed from the list.');
          return;
        }
      }

      if (rec.path.isNotEmpty) {
        await _voicePlayer.setVolume(1.0);
        await _voicePlayer.play(_voiceSourceForPath(rec.path));
        debugPrint('[RapPreview] Voice play source: ${rec.path}');
      }

      await Future.delayed(const Duration(milliseconds: 80));
      await _playBeatTrack(rec, volume: 0.2);

      if (mounted) setState(() => _playingPath = rec.path);

      _playSub = _voicePlayer.onPlayerComplete.listen((_) async {
        await _playSub?.cancel();
        _playSub = null;
        await _beatPlayer.stop();
        if (mounted) setState(() => _playingPath = null);
      });
    } catch (e) {
      await _playSub?.cancel();
      _playSub = null;
      await _beatPlayer.stop();
      await _voicePlayer.stop();
      if (mounted) setState(() => _playingPath = null);

      if (_isMissingFileError(e)) {
        await _removeByPath(rec.path);
        _showMessage('Recording file is missing and was removed from the list.');
        return;
      }
      _showMessage('Could not play this remix: $e');
    }
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
        final file = File(_normalizeStoredPath(rec.path));
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    // Remove from prefs
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('local_recordings') ?? [];
    final normalizedTarget = _normalizeStoredPath(rec.path);
    raw.removeWhere((s) {
      try {
        final rawPath = (jsonDecode(s) as Map)['path'];
        final stored = _normalizeStoredPath(rawPath?.toString() ?? '');
        return stored == normalizedTarget;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList('local_recordings', raw);

    if (mounted) {
      setState(
        () => _recordings.removeWhere(
          (r) => _normalizeStoredPath(r.path) == normalizedTarget,
        ),
      );
    }
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
