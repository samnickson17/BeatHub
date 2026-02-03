import 'package:flutter/material.dart';
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

  // 🖼️🎵 Dummy selected files
  String? _selectedCoverArt;
  String? _selectedAudioFile;

  void _pickCoverArt() {
    setState(() {
      _selectedCoverArt = "cover_art.jpg";
    });
  }

  void _pickAudioFile() {
    setState(() {
      _selectedAudioFile = "beat_audio.mp3";
    });
  }

  void _submitBeat() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAudioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an audio file"),
        ),
      );
      return;
    }

    final newBeat = BeatModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      producer: "Current Producer",
      producerId: "producer_001",
      genre: _genreController.text,
      bpm: int.parse(_bpmController.text),
      price: double.parse(_priceController.text),
      description: _descriptionController.text,
      coverArtPath: _selectedCoverArt,
      audioPath: _selectedAudioFile,
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
              _field(controller: _titleController, label: "Beat Title"),
              _field(controller: _genreController, label: "Genre"),
              _field(
                controller: _bpmController,
                label: "BPM",
                isNumber: true,
              ),
              _field(
                controller: _priceController,
                label: "Price (₹)",
                isNumber: true,
              ),
              _field(
                controller: _descriptionController,
                label: "Description",
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // 🖼️ COVER ART PICKER
              _fileButton(
                icon: Icons.image,
                label: "Select Cover Art",
                selectedFile: _selectedCoverArt,
                onTap: _pickCoverArt,
              ),

              // 🎵 AUDIO PICKER
              _fileButton(
                icon: Icons.music_note,
                label: "Select Audio File",
                selectedFile: _selectedAudioFile,
                onTap: _pickAudioFile,
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

  Widget _field({
    required TextEditingController controller,
    required String label,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "$label is required";
          }
          return null;
        },
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _fileButton({
    required IconData icon,
    required String label,
    required String? selectedFile,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Text(
          selectedFile == null
              ? label
              : "$label ✔ (${selectedFile})",
        ),
        onPressed: onTap,
      ),
    );
  }
}
