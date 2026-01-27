import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../beats/beat_model.dart';

class RapRecordPage extends StatefulWidget {
  final BeatModel selectedBeat;

  const RapRecordPage({
    super.key,
    required this.selectedBeat,
  });

  @override
  State<RapRecordPage> createState() => _RapRecordPageState();
}

class _RapRecordPageState extends State<RapRecordPage> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  String? _recordedPath;

  Future<void> _startRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Rap recording works only on Android device"),
        ),
      );
      return;
    }

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) return;

    final dir = await getTemporaryDirectory();
    final filePath = p.join(dir.path, "rap_preview.m4a");

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: filePath,
    );

    setState(() {
      _isRecording = true;
      _recordedPath = filePath;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();

    setState(() {
      _isRecording = false;
      _recordedPath = path;
    });
  }

  Future<void> _playRecording() async {
    if (_recordedPath == null) return;
    await _player.play(DeviceFileSource(_recordedPath!));
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rap Recording"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.mic, size: 60, color: Colors.deepPurple),
            const SizedBox(height: 10),

            Text(
              widget.selectedBeat.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${widget.selectedBeat.genre} • ${widget.selectedBeat.bpm} BPM",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(
                _isRecording ? "Stop Recording" : "Start Recording",
              ),
              onPressed:
              _isRecording ? _stopRecording : _startRecording,
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text("Play Preview"),
              onPressed:
              _recordedPath == null ? null : _playRecording,
            ),

            const SizedBox(height: 25),

            const Text(
              "This rap preview is temporary and cannot be downloaded.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
