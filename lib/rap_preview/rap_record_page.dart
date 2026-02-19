import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../beats/beat_model.dart';

class RapRecordPage extends StatefulWidget {
  final BeatModel selectedBeat;

  const RapRecordPage({super.key, required this.selectedBeat});

  @override
  State<RapRecordPage> createState() => _RapRecordPageState();
}

class _RapRecordPageState extends State<RapRecordPage> {
  final AudioPlayer _beatPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isBusy = false;
  String? _recordedPath;

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
      if (widget.selectedBeat.audioPath.startsWith("assets/")) {
        await _beatPlayer.play(
          AssetSource(
            widget.selectedBeat.audioPath.replaceFirst("assets/", ""),
          ),
        );
      } else {
        await _beatPlayer.play(DeviceFileSource(widget.selectedBeat.audioPath));
      }

      final path = await _buildRecordingPath();
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _recordedPath = null;
        _isRecording = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not start rap preview")),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _stopRap() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    try {
      await _beatPlayer.stop();
      final recordedPath = await _recorder.stop();

      if (!mounted) return;
      setState(() {
        _recordedPath = recordedPath;
        _isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _recordedPath == null
                ? "Recording stopped"
                : "Recording saved locally",
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not stop recording")));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<String> _buildRecordingPath() async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    if (kIsWeb) {
      return "rap_preview_$stamp.m4a";
    }

    final tempDir = await getTemporaryDirectory();
    return "${tempDir.path}/rap_preview_$stamp.m4a";
  }

  @override
  void dispose() {
    _beatPlayer.dispose();
    _recorder.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beat = widget.selectedBeat;

    return Scaffold(
      appBar: AppBar(title: const Text("Rap Preview"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.mic, size: 80),
            const SizedBox(height: 10),
            Text(
              beat.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("${beat.genre} - ${beat.bpm} BPM"),
            const Spacer(),
            ElevatedButton.icon(
              icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
              label: Text(_isRecording ? "Stop Rap" : "Start Rap"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isBusy ? null : (_isRecording ? _stopRap : _startRap),
            ),
            const SizedBox(height: 20),
            if (_recordedPath != null)
              const Text(
                "Recording completed",
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
