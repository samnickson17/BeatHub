import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../beats/beat_model.dart';
import '../beats/beat_store.dart';

class UploadBeatPage extends StatefulWidget {
  const UploadBeatPage({super.key});

  @override
  State<UploadBeatPage> createState() => _UploadBeatPageState();
}

class _UploadBeatPageState extends State<UploadBeatPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  final _bpmController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ✅ REAL FILE PATHS
  String? _coverArtPath;
  String? _audioFilePath;

  // 🖼️ PICK COVER ART (IMAGE)
  Future<void> _pickCoverArt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _coverArtPath = result.files.single.path!;
      });
    }
  }

  // 🎵 PICK AUDIO FILE
  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioFilePath = result.files.single.path!;
      });
    }
  }

  void _submitBeat() {
    if (!_formKey.currentState!.validate()) return;

    if (_audioFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an audio file"),
        ),
      );
      return;
    }

    final int bpm = int.tryParse(_bpmController.text) ?? 0;
    final double price =
        double.tryParse(_priceController.text) ?? 0;

    final newBeat = BeatModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      producer: "Producer Sam",
      producerId: "producer_001",
      genre: _genreController.text,
      bpm: bpm,
      price: price,
      description: _descriptionController.text,
      coverArtPath: _coverArtPath,
      audioPath: _audioFilePath!,// ✅ REAL AUDIO PATH
    );

    BeatStore.addBeat(newBeat);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Beat uploaded successfully"),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Beat"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_titleController, "Beat Title"),
              _field(_genreController, "Genre"),
              _field(_bpmController, "BPM", isNumber: true),
              _field(_priceController, "Price (₹)", isNumber: true),
              _field(
                _descriptionController,
                "Description",
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // 🖼️ COVER ART
              OutlinedButton.icon(
                icon: const Icon(Icons.image),
                label: Text(
                  _coverArtPath == null
                      ? "Select Cover Art"
                      : "Cover Art Selected ✔",
                ),
                onPressed: _pickCoverArt,
              ),

              const SizedBox(height: 12),

              // 🎵 AUDIO FILE
              OutlinedButton.icon(
                icon: const Icon(Icons.music_note),
                label: Text(
                  _audioFilePath == null
                      ? "Select Audio File"
                      : "Audio File Selected ✔",
                ),
                onPressed: _pickAudioFile,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitBeat,
                  child: const Text("Upload Beat"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) =>
            value == null || value.isEmpty
                ? "$label is required"
                : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}