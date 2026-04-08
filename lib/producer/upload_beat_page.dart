import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../backend/local_backend.dart';
import '../beats/beat_model.dart';

class UploadBeatPage extends StatefulWidget {
  final bool closeOnSuccess;

  const UploadBeatPage({super.key, this.closeOnSuccess = false});

  @override
  State<UploadBeatPage> createState() => _UploadBeatPageState();
}

class _UploadBeatPageState extends State<UploadBeatPage> {
  final _formKey = GlobalKey<FormState>();

  static const List<String> _genres = [
    'Hip Hop', 'Drill', 'Trap', 'R&B', 'Afrobeats',
    'Pop', 'Lo-Fi', 'Dancehall', 'Amapiano', 'Other',
  ];

  final _titleController = TextEditingController();
  String? _selectedGenre;
  final _bpmController = TextEditingController();
  final _basicPriceController = TextEditingController();
  final _premiumPriceController = TextEditingController();
  final _exclusivePriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<int>? _coverArtBytes;
  String? _coverArtExt;
  String? _coverArtName;
  List<int>? _audioBytes;
  String? _audioExt;
  String? _audioFileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bpmController.dispose();
    _basicPriceController.dispose();
    _premiumPriceController.dispose();
    _exclusivePriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverArt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file != null && file.bytes != null) {
      setState(() {
        _coverArtBytes = file.bytes!;
        _coverArtExt = file.extension ?? 'jpg';
        _coverArtName = file.name;
      });
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    final file = result?.files.single;
    if (file != null && file.bytes != null) {
      setState(() {
        _audioBytes = file.bytes!;
        _audioExt = file.extension ?? 'mp3';
        _audioFileName = file.name;
      });
    }
  }

  Future<void> _submitBeat() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGenre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a genre")),
      );
      return;
    }

    if (_audioBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an audio file")),
      );
      return;
    }

    final bpm = int.tryParse(_bpmController.text) ?? 0;
    final basicPrice = double.tryParse(_basicPriceController.text) ?? 0;
    final premiumPrice = double.tryParse(_premiumPriceController.text) ?? 0;
    final exclusivePrice = double.tryParse(_exclusivePriceController.text) ?? 0;

    final distinctPrices = {basicPrice, premiumPrice, exclusivePrice};
    if (distinctPrices.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Basic, Premium, and Exclusive prices must be different",
          ),
        ),
      );
      return;
    }

    // Read logged-in producer identity from session
    final currentUser = AppBackend.auth.currentUser;
    final producerName = currentUser?.username.isNotEmpty == true
        ? currentUser!.username
        : currentUser?.email.split('@').first ?? 'Unknown Producer';
    final producerId = currentUser?.userId ?? 'unknown';

    final beatMeta = BeatModel(
      id: '', // ID set by Firestore/Storage
      title: _titleController.text.trim(),
      producer: producerName,
      producerId: producerId,
      genre: _selectedGenre!,
      bpm: bpm,
      basicLicensePrice: basicPrice,
      premiumLicensePrice: premiumPrice,
      exclusiveLicensePrice: exclusivePrice,
      description: _descriptionController.text.trim(),
      audioPath: '', // Will be replaced with Storage URL
      coverArtPath: null,
    );

    setState(() => _isUploading = true);
    try {
      await AppBackend.beats.uploadBeatWithFiles(
        beat: beatMeta,
        audioBytes: _audioBytes!,
        audioExtension: _audioExt ?? 'mp3',
        coverArtBytes: _coverArtBytes,
        coverArtExtension: _coverArtExt,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Beat uploaded successfully!")),
      );
      if (widget.closeOnSuccess && Navigator.canPop(context)) {
        Navigator.pop(context, true);
        return;
      }
      _titleController.clear();
      _bpmController.clear();
      _basicPriceController.clear();
      _premiumPriceController.clear();
      _exclusivePriceController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedGenre = null;
        _coverArtBytes = null;
        _coverArtExt = null;
        _coverArtName = null;
        _audioBytes = null;
        _audioExt = null;
        _audioFileName = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Upload failed: ${e.toString().replaceAll('Exception: ', '')}",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Beat"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_titleController, "Beat Title"),
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: DropdownButtonFormField<String>(
                  value: _selectedGenre,
                  decoration: const InputDecoration(labelText: "Genre"),
                  items: _genres
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedGenre = val),
                  validator: (val) =>
                      val == null ? "Please select a genre" : null,
                ),
              ),
              _field(_bpmController, "BPM", isNumber: true),
              _field(
                _basicPriceController,
                "Basic License Price (Rs)",
                isNumber: true,
              ),
              _field(
                _premiumPriceController,
                "Premium License Price (Rs)",
                isNumber: true,
              ),
              _field(
                _exclusivePriceController,
                "Exclusive License Price (Rs)",
                isNumber: true,
              ),
              _field(_descriptionController, "Description", maxLines: 3),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: Icon(
                  _coverArtBytes == null ? Icons.image : Icons.check_circle,
                  color: _coverArtBytes == null ? null : Colors.green,
                ),
                label: Text(
                  _coverArtBytes == null
                      ? "Select Cover Art (optional)"
                      : _coverArtName ?? "Cover Art Selected",
                ),
                onPressed: _pickCoverArt,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: Icon(
                  _audioBytes == null ? Icons.music_note : Icons.check_circle,
                  color: _audioBytes == null ? null : Colors.green,
                ),
                label: Text(
                  _audioBytes == null
                      ? "Select Audio File *"
                      : _audioFileName ?? "Audio File Selected",
                ),
                onPressed: _pickAudioFile,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitBeat,
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Upload Beat"),
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
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) =>
            value == null || value.trim().isEmpty ? "$label is required" : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
