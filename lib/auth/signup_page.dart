import 'package:flutter/material.dart';
import '../backend/backend_contracts.dart';
import '../backend/local_backend.dart';
import '../core/routes.dart';
import 'auth_validator.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  String _selectedRole = "buyer";

  // 👁️ Password visibility control
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final role = _selectedRole == "producer"
        ? AppUserRole.producer
        : AppUserRole.buyer;

    setState(() => _isLoading = true);
    try {
      final user = await AppBackend.auth.signup(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        role: role,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        user.role == AppUserRole.producer
            ? AppRoutes.producerNav
            : AppRoutes.buyerNav,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e.toString())),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (raw.contains('network-request-failed')) {
      return 'No internet connection.';
    }
    return 'Sign up failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "assets/icon/app_icon.png",
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Create BeatHub Account",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // 👤 USERNAME (simple validation)
              TextFormField(
                controller: _usernameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Username is required";
                  }
                  return null;
                },
                decoration: const InputDecoration(labelText: "Username"),
              ),

              const SizedBox(height: 15),

              // 📧 EMAIL
              TextFormField(
                controller: _emailController,
                validator: AuthValidator.validateEmail,
                decoration: const InputDecoration(labelText: "Email"),
              ),

              const SizedBox(height: 15),

              // 🔐 PASSWORD WITH EYE ICON
              TextFormField(
                controller: _passwordController,
                validator: AuthValidator.validatePassword,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 👤 ROLE SELECT
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                items: const [
                  DropdownMenuItem(
                    value: "buyer",
                    child: Text("Buyer / Artist"),
                  ),
                  DropdownMenuItem(value: "producer", child: Text("Producer")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Sign up as"),
              ),

              const SizedBox(height: 30),

              // 🔘 SIGNUP BUTTON
              ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Sign Up"),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
