import 'package:flutter/material.dart';

import '../backend/backend_contracts.dart';
import '../backend/firebase_backend.dart';
import '../backend/local_backend.dart';

class GoogleOnboardingPage extends StatefulWidget {
  final String uid;
  final String email;
  final String initialUsername;

  const GoogleOnboardingPage({
    super.key,
    required this.uid,
    required this.email,
    this.initialUsername = '',
  });

  @override
  State<GoogleOnboardingPage> createState() => _GoogleOnboardingPageState();
}

class _GoogleOnboardingPageState extends State<GoogleOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;

  String _selectedRole = 'buyer';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final emailPrefix = widget.email.split('@').first.trim();
    final defaultUsername = widget.initialUsername.trim().isEmpty
        ? emailPrefix
        : widget.initialUsername.trim();
    _usernameController = TextEditingController(text: defaultUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final backend = AppBackend.auth as FirebaseAuthBackend;
      final user = await backend.completeGoogleSignup(
        uid: widget.uid,
        email: widget.email,
        username: _usernameController.text.trim(),
        role: _selectedRole == 'producer'
            ? AppUserRole.producer
            : AppUserRole.buyer,
      );
      if (!mounted) return;
      Navigator.of(context).pop(user);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete profile: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    await AppBackend.auth.logout();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Google Sign-In')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose your username and role to finish setting up your account.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Username is required';
                    if (v.length < 3) return 'At least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'I am a…',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'buyer',
                      child: Text('Buyer / Artist'),
                    ),
                    DropdownMenuItem(
                      value: 'producer',
                      child: Text('Producer'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedRole = value);
                  },
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _cancel,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
