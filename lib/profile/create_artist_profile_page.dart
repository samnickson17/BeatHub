import 'package:flutter/material.dart';
import '../navigation/buyer_bottom_nav.dart';
import 'profile_store.dart';

class CreateArtistProfilePage extends StatefulWidget {
  const CreateArtistProfilePage({super.key});

  @override
  State<CreateArtistProfilePage> createState() =>
      _CreateArtistProfilePageState();
}

class _CreateArtistProfilePageState
    extends State<CreateArtistProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final profile = ArtistProfile(
      userId: ProfileStore.currentUserId,
      name: _nameController.text,
      username: _usernameController.text,
      bio: _bioController.text.trim(),
    );

    ProfileStore.saveProfile(profile);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const BuyerBottomNav(initialIndex: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: "Name"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _usernameController,
                decoration:
                    const InputDecoration(labelText: "Username"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: "Bio"),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text("Save Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

