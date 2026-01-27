import 'package:flutter/material.dart';
import '../core/routes.dart';
import 'auth_validator.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController();
  final TextEditingController _usernameController =
      TextEditingController();

  String _selectedRole = "buyer";

  // 👁️ Password visibility control
  bool _obscurePassword = true;

  void _signup() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pushReplacementNamed(
        context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.music_note,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 10),
              const Text(
                "Create BeatHub Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
                decoration: const InputDecoration(
                  labelText: "Username",
                ),
              ),

              const SizedBox(height: 15),

              // 📧 EMAIL
              TextFormField(
                controller: _emailController,
                validator: AuthValidator.validateEmail,
                decoration: const InputDecoration(
                  labelText: "Email",
                ),
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
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(
                    value: "buyer",
                    child: Text("Buyer / Artist"),
                  ),
                  DropdownMenuItem(
                    value: "producer",
                    child: Text("Producer"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Sign up as",
                ),
              ),

              const SizedBox(height: 30),

              // 🔘 SIGNUP BUTTON
              ElevatedButton(
                onPressed: _signup,
                child: const Text("Sign Up"),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.login);
                },
                child: const Text(
                    "Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
