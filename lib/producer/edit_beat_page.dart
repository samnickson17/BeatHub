import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../beats/beat_model.dart';
import '../beats/beat_store.dart';

class EditBeatPage extends StatefulWidget {
  final BeatModel beat;

  const EditBeatPage({
    super.key,
    required this.beat,
  });

  @override
  State<EditBeatPage> createState() => _EditBeatPageState();
}

class _EditBeatPageState extends State<EditBeatPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _genreController;
  late final TextEditingController _bpmController;
  late final TextEditingController _basicPriceController;
  late final TextEditingController _premiumPriceController;
  late final TextEditingController _exclusivePriceController;
  late final TextEditingController _descriptionController;

  String? _coverArtPath;
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.beat.title);
    _genreController = TextEditingController(text: widget.beat.genre);
    _bpmController = TextEditingController(text: widget.beat.bpm.toString());
    _basicPriceController = TextEditingController(
      text: widget.beat.basicLicensePrice.toStringAsFixed(0),
    );
    _premiumPriceController = TextEditingController(
      text: widget.beat.premiumLicensePrice.toStringAsFixed(0),
    );
    _exclusivePriceController = TextEditingController(
      text: widget.beat.exclusiveLicensePrice.toStringAsFixed(0),
    );
    _descriptionController = TextEditingController(text: widget.beat.description);
    _coverArtPath = widget.beat.coverArtPath;
    _audioFilePath = widget.beat.audioPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _bpmController.dispose();
    _basicPriceController.dispose();
    _premiumPriceController.dispose();
    _exclusivePriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverArt() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _coverArtPath = result.files.single.path!);
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _audioFilePath = result.files.single.path!);
    }
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    final basicPrice =
        double.tryParse(_basicPriceController.text.trim()) ?? widget.beat.basicLicensePrice;
    final premiumPrice =
        double.tryParse(_premiumPriceController.text.trim()) ?? widget.beat.premiumLicensePrice;
    final exclusivePrice = double.tryParse(_exclusivePriceController.text.trim()) ??
        widget.beat.exclusiveLicensePrice;

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

    final updatedBeat = BeatModel(
      id: widget.beat.id,
      title: _titleController.text.trim(),
      producer: widget.beat.producer,
      producerId: widget.beat.producerId,
      genre: _genreController.text.trim(),
      bpm: int.tryParse(_bpmController.text.trim()) ?? widget.beat.bpm,
      basicLicensePrice: basicPrice,
      premiumLicensePrice: premiumPrice,
      exclusiveLicensePrice: exclusivePrice,
      description: _descriptionController.text.trim(),
      audioPath: _audioFilePath ?? widget.beat.audioPath,
      coverArtPath: _coverArtPath,
    );

    BeatStore.updateBeat(updatedBeat);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Beat"),
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
              _field(_basicPriceController, "Basic License Price (Rs)", isNumber: true),
              _field(_premiumPriceController, "Premium License Price (Rs)", isNumber: true),
              _field(_exclusivePriceController, "Exclusive License Price (Rs)", isNumber: true),
              _field(_descriptionController, "Description", maxLines: 3),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.image),
                label: Text(
                  _coverArtPath == null ? "Select Cover Art" : "Cover Art Selected",
                ),
                onPressed: _pickCoverArt,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.music_note),
                label: Text(
                  _audioFilePath == null ? "Select Audio File" : "Audio File Selected",
                ),
                onPressed: _pickAudioFile,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text("Save Changes"),
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
