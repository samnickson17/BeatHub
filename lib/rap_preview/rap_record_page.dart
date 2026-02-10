import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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
  String? _recordedPath;

  Future<void> _startRap() async {
  if (!await _recorder.hasPermission()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Microphone permission denied")),
    );
    return;
  }

  // ▶ Play beat (ASSET AUDIO)
  await _beatPlayer.play(
    AssetSource(
      widget.selectedBeat.audioPath.replaceFirst("assets/", ""),
    ),
  );

  // 🎤 Start recording (TEMP PATH FOR WEB)
  final String path =
      "recorded_${DateTime.now().millisecondsSinceEpoch}.wav";

  await _recorder.start(
    const RecordConfig(),
    path: path,
  );

  setState(() {
    _isRecording = true;
  });
}

  Future<void> _stopRap() async {
    await _beatPlayer.stop();
    _recordedPath = await _recorder.stop();

    setState(() {
      _isRecording = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recording saved locally")),
    );
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
      appBar: AppBar(
        title: const Text("Rap Preview"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.mic, size: 80),
            const SizedBox(height: 10),

            Text(
              beat.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text("${beat.genre} • ${beat.bpm} BPM"),

            const Spacer(),

            ElevatedButton.icon(
              icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
              label: Text(_isRecording ? "Stop Rap" : "Start Rap"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isRecording ? _stopRap : _startRap,
            ),

            const SizedBox(height: 20),

            if (_recordedPath != null)
              const Text(
                "Recording completed ✔",
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
