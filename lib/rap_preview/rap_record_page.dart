import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../beats/beat_model.dart';
import 'audio_mix_context.dart';
import 'web_voice_player_stub.dart'
    if (dart.library.html) 'web_voice_player_web.dart';

class RapRecordPage extends StatefulWidget {
  final BeatModel selectedBeat;

  const RapRecordPage({super.key, required this.selectedBeat});

  @override
  State<RapRecordPage> createState() => _RapRecordPageState();
}

class _RapRecordPageState extends State<RapRecordPage> {
  final AudioPlayer _beatPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  // Native second player for voice; created once and kept alive.
  final AudioPlayer _nativeVoicePlayer = AudioPlayer();

  // Web voice player (dart:html AudioElement on web, no-op stub on native)
  final WebVoicePlayer _webVoice = WebVoicePlayer();

  bool _isRecording = false;
  bool _isBusy = false;
  bool _isPreviewPlaying = false;
  String? _recordedPath;
  StreamSubscription? _previewSub;

  @override
  void initState() {
    super.initState();
    // Pre-configure audio context so both players can mix without
    // stealing each other's audio focus (Android) or session (iOS).
    if (!kIsWeb) {
      _beatPlayer.setAudioContext(mixingAudioContext);
      _nativeVoicePlayer.setAudioContext(mixingAudioContext);
    }
  }

  // ── Waveform / amplitude ──────────────────────────────────────────────────
  static const int _barCount = 28;
  final List<double> _barHeights = List.filled(_barCount, 0.05);
  StreamSubscription<Amplitude>? _ampSub;
  // Shift buffer so bars scroll left as new samples arrive
  final _rng = math.Random();

  void _startAmplitudeMonitor() {
    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amp) {
          // amp.current is dB: -160 (silence) → 0 (max)
          final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
          if (!mounted) return;
          setState(() {
            // Shift bars left, append new value with slight randomness for visual variety
            for (int i = 0; i < _barCount - 1; i++) {
              _barHeights[i] = _barHeights[i + 1];
            }
            final spread = normalized * 0.3;
            _barHeights[_barCount -
                1] = (normalized + (_rng.nextDouble() * spread - spread / 2))
                .clamp(0.05, 1.0);
          });
        });
  }

  void _stopAmplitudeMonitor() {
    _ampSub?.cancel();
    _ampSub = null;
    if (mounted) {
      setState(() {
        for (int i = 0; i < _barCount; i++) {
          _barHeights[i] = 0.05;
        }
      });
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _startRap() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    try {
      if (!await _recorder.hasPermission()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission denied")),
        );
        return;
      }

      await _beatPlayer.stop();
      await _beatPlayer.setVolume(1.0);
      final audioPath = widget.selectedBeat.audioPath;
      if (audioPath.startsWith("assets/")) {
        await _beatPlayer.play(
          AssetSource(audioPath.replaceFirst("assets/", "")),
        );
      } else if (audioPath.startsWith("http")) {
        await _beatPlayer.play(UrlSource(audioPath));
      } else {
        await _beatPlayer.play(DeviceFileSource(audioPath));
      }

      final path = await _buildRecordingPath();
      await _recorder.start(
        RecordConfig(
          encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
          numChannels: 1,
        ),
        path: path,
      );

      _startAmplitudeMonitor();

      if (!mounted) return;
      setState(() {
        _recordedPath = null;
        _isRecording = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not start rap preview: $e")),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _stopRap() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    try {
      await _beatPlayer.stop();
      _stopAmplitudeMonitor();
      final recordedPath = await _recorder.stop();

      if (recordedPath != null) {
        await _saveRecordingMetadata(recordedPath);
      }

      if (!mounted) return;
      setState(() {
        _recordedPath = recordedPath;
        _isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recordedPath == null
                ? "Recording stopped (no data)"
                : "Recording saved — tap Preview Mix!",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Could not stop recording: $e")));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _togglePreview() async {
    if (_recordedPath == null) return;

    if (_isPreviewPlaying) {
      await _stopPreview();
      return;
    }

    await _previewSub?.cancel();
    _previewSub = null;

    // ── Beat ─────────────────────────────────────────────────────────────
    await _beatPlayer.stop();
    await _beatPlayer.setVolume(1.0);
    final audioPath = widget.selectedBeat.audioPath;
    if (audioPath.startsWith("assets/")) {
      await _beatPlayer.play(
        AssetSource(audioPath.replaceFirst("assets/", "")),
      );
    } else if (audioPath.startsWith("http")) {
      await _beatPlayer.play(UrlSource(audioPath));
    } else {
      await _beatPlayer.play(DeviceFileSource(audioPath));
    }

    // ── Voice ────────────────────────────────────────────────────────────
    final recPath = _recordedPath!;
    if (kIsWeb) {
      // On web: use raw HTMLAudioElement so it plays in parallel with the beat
      _webVoice.play(recPath, onEnded: () async => _stopPreview());
    } else {
      await _nativeVoicePlayer.setVolume(1.0);
      await _nativeVoicePlayer.play(DeviceFileSource(recPath));
      _previewSub = _nativeVoicePlayer.onPlayerComplete.listen((_) async {
        await _previewSub?.cancel();
        _previewSub = null;
        await _beatPlayer.stop();
        if (mounted) setState(() => _isPreviewPlaying = false);
      });
    }

    if (mounted) setState(() => _isPreviewPlaying = true);
  }

  Future<void> _stopPreview() async {
    await _previewSub?.cancel();
    _previewSub = null;
    await _beatPlayer.stop();
    if (kIsWeb) {
      _webVoice.pause();
    } else {
      await _nativeVoicePlayer.stop();
    }
    if (mounted) setState(() => _isPreviewPlaying = false);
  }

  Future<void> _saveRecordingMetadata(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('local_recordings') ?? [];
    final entry = jsonEncode({
      'path': path,
      'beatTitle': widget.selectedBeat.title,
      'beatId': widget.selectedBeat.id,
      'beatAudioPath': widget.selectedBeat.audioPath,
      'createdAt': DateTime.now().toIso8601String(),
    });
    existing.insert(0, entry);
    await prefs.setStringList('local_recordings', existing);
  }

  Future<String> _buildRecordingPath() async {
    if (kIsWeb) return "";
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/rap_preview_$stamp.m4a";
  }

  @override
  void dispose() {
    _previewSub?.cancel();
    _ampSub?.cancel();
    _beatPlayer.dispose();
    _nativeVoicePlayer.dispose();
    _webVoice.dispose();
    _recorder.cancel();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final beat = widget.selectedBeat;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Rap Preview"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // ── Beat info ────────────────────────────────────────────────
            const Icon(Icons.mic, size: 72),
            const SizedBox(height: 8),
            Text(
              beat.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "${beat.genre} · ${beat.bpm} BPM",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 32),

            // ── Waveform visualizer ───────────────────────────────────────
            SizedBox(
              height: 80,
              child: _WaveformBars(
                barHeights: _barHeights,
                isActive: _isRecording,
                activeColor: theme.colorScheme.error,
                idleColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),

            if (_isRecording)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Recording...",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // ── Record button ──────────────────────────────────────────────
            ElevatedButton.icon(
              icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
              label: Text(_isRecording ? "Stop Rap" : "Start Rap"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: _isRecording ? Colors.red : null,
              ),
              onPressed: _isBusy ? null : (_isRecording ? _stopRap : _startRap),
            ),

            const SizedBox(height: 14),

            // ── Preview Mix button (visible after recording) ───────────────
            if (_recordedPath != null) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    "Recording saved!",
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(_isPreviewPlaying ? Icons.stop : Icons.headphones),
                label: Text(_isPreviewPlaying ? "Stop Preview" : "Preview Mix"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: Colors.deepPurple,
                ),
                onPressed: _isBusy ? null : _togglePreview,
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Waveform bar widget ───────────────────────────────────────────────────────
class _WaveformBars extends StatelessWidget {
  final List<double> barHeights;
  final bool isActive;
  final Color activeColor;
  final Color idleColor;

  const _WaveformBars({
    required this.barHeights,
    required this.isActive,
    required this.activeColor,
    required this.idleColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final barWidth = (constraints.maxWidth / barHeights.length) - 2;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < barHeights.length; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: barWidth.clamp(2.0, 20.0),
                height: constraints.maxHeight * barHeights[i].clamp(0.05, 1.0),
                decoration: BoxDecoration(
                  color: isActive ? activeColor : idleColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (i < barHeights.length - 1) const SizedBox(width: 2),
            ],
          ],
        );
      },
    );
  }
}
