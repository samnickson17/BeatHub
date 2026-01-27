import 'package:flutter/material.dart';
import 'profile_store.dart';
import 'user_profile_model.dart';

class CompleteProfilePage extends StatefulWidget {
  final String userId;
  final String role;

  const CompleteProfilePage({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState
    extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController =
      TextEditingController();
  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _bioController =
      TextEditingController();

  bool _saving = false;

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();

    if (ProfileStore.isUsernameTaken(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username already taken"),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final profile = UserProfile(
      userId: widget.userId,
      username: username,
      displayName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      role: widget.role,
      profileImagePath: null,
      profileCompleted: true,
    );

    ProfileStore.saveProfile(profile);

    setState(() => _saving = false);

    // ✅ CLOSE THIS PAGE SAFELY
    Navigator.of(context).maybePop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile completed"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),

              Center(
                child: CircleAvatar(
                  radius: 45,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  prefixText: "@",
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Username required";
                  }
                  if (value.contains(" ")) {
                    return "No spaces allowed";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Display Name",
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Display name required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: "Bio",
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text("Save Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
