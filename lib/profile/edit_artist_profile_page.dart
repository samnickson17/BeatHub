import 'package:flutter/material.dart';

import '../backend/local_backend.dart';

class EditArtistProfilePage extends StatefulWidget {
  final String displayName;
  final String username;
  final String bio;
  final String email;

  const EditArtistProfilePage({
    super.key,
    required this.displayName,
    required this.username,
    required this.bio,
    required this.email,
  });

  @override
  State<EditArtistProfilePage> createState() => _EditArtistProfilePageState();
}

class _EditArtistProfilePageState extends State<EditArtistProfilePage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.displayName);
    _usernameController = TextEditingController(text: widget.username);
    _bioController = TextEditingController(text: widget.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isSavingProfile = true);
    try {
      await AppBackend.auth.updateCurrentUserProfile(
        displayName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated!")));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to save: ${e.toString().replaceAll('Exception: ', '')}",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isChangingPassword = true);
    try {
      await AppBackend.auth.changePassword(
        email: widget.email,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().toLowerCase();
      String msg = 'Password change failed.';
      if (raw.contains('invalid login credentials') ||
          raw.contains('wrong-password') ||
          raw.contains('invalid-credential')) {
        msg = 'Current password is incorrect.';
      } else if (raw.contains('weak-password')) {
        msg = 'New password is too weak.';
      } else if (raw.contains('requires-recent-login')) {
        msg = 'Please log out and log back in before changing your password.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Profile Info ──
            const Text(
              "Profile Info",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Form(
              key: _profileFormKey,
              child: Column(
                children: [
                  _field(_nameController, "Display Name"),
                  _field(
                    _usernameController,
                    "Username",
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Username is required"
                        : null,
                  ),
                  _field(_bioController, "Bio", maxLines: 3, required: false),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    child: _isSavingProfile
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Save Profile"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
            const Divider(),
            const SizedBox(height: 16),

            // ── Change Password ──
            const Text(
              "Change Password",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  _passwordField(
                    controller: _currentPasswordController,
                    label: "Current Password",
                    obscure: _obscureCurrent,
                    onToggle: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    validator: (v) => v == null || v.isEmpty
                        ? "Enter your current password"
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _passwordField(
                    controller: _newPasswordController,
                    label: "New Password",
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter a new password";
                      if (v.length < 6) return "Min 6 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _passwordField(
                    controller: _confirmPasswordController,
                    label: "Confirm New Password",
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (v) => v != _newPasswordController.text
                        ? "Passwords do not match"
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isChangingPassword ? null : _changePassword,
                    child: _isChangingPassword
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Change Password"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator:
            validator ??
            (required
                ? (v) => v == null || v.trim().isEmpty
                      ? "$label is required"
                      : null
                : null),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
