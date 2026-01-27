import 'package:flutter/material.dart';

class UploadBeatPage extends StatefulWidget {
  const UploadBeatPage({super.key});

  @override
  State<UploadBeatPage> createState() => _UploadBeatPageState();
}

class _UploadBeatPageState extends State<UploadBeatPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _bpmController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedLicense = "Basic";

  void _submitBeat() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Beat uploaded successfully (demo)"),
        ),
      );

      _formKey.currentState!.reset();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _bpmController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Beat"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Beat Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Beat Title",
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 16),

              // Genre
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: "Genre",
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 16),

              // BPM
              TextFormField(
                controller: _bpmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "BPM",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Required";
                  if (int.tryParse(value) == null) return "Enter valid BPM";
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Price (₹)",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Required";
                  if (double.tryParse(value) == null) return "Enter valid price";
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // License Type
              DropdownButtonFormField<String>(
                value: _selectedLicense,
                decoration: const InputDecoration(
                  labelText: "License Type",
                ),
                items: const [
                  DropdownMenuItem(value: "Basic", child: Text("Basic")),
                  DropdownMenuItem(value: "Premium", child: Text("Premium")),
                  DropdownMenuItem(value: "Exclusive", child: Text("Exclusive")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLicense = value!;
                  });
                },
              ),

              const SizedBox(height: 30),

              // Upload Button
              ElevatedButton(
                onPressed: _submitBeat,
                child: const Text("Upload Beat"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
