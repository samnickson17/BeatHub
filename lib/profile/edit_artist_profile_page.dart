import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'profile_store.dart';

class EditArtistProfilePage extends StatefulWidget {
  final ArtistProfile profile;

  const EditArtistProfilePage({
    super.key,
    required this.profile,
  });

  @override
  State<EditArtistProfilePage> createState() => _EditArtistProfilePageState();
}

class _EditArtistProfilePageState extends State<EditArtistProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio);
    _profileImagePath = widget.profile.profileImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _profileImagePath = result.files.single.path);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ProfileStore.saveProfile(
      widget.profile.copyWith(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        profileImagePath: _profileImagePath,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              OutlinedButton.icon(
                onPressed: _pickProfileImage,
                icon: const Icon(Icons.image),
                label: Text(
                  _profileImagePath == null ? "Add Profile Image" : "Change Profile Image",
                ),
              ),
              const SizedBox(height: 16),
              _field(_nameController, "Name"),
              _field(_usernameController, "Username"),
              _field(_bioController, "Bio", maxLines: 3, required: false),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text("Save"),
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
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: required
            ? (v) => v == null || v.trim().isEmpty ? "$label is required" : null
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
