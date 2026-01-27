import 'package:flutter/material.dart';
import '../core/routes.dart';
import 'auth_validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController();

  String _selectedRole = "buyer";

  // 👁️ Password visibility control
  bool _obscurePassword = true;

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pushReplacementNamed(
      context,
      _selectedRole == "producer"
          ? AppRoutes.producerNav
          : AppRoutes.buyerNav,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
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
                  "BeatHub",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

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
                    labelText: "Login as",
                  ),
                ),

                const SizedBox(height: 30),

                // 🔘 LOGIN BUTTON
                ElevatedButton(
                  onPressed: _login,
                  child: const Text("Login"),
                ),

                // 📝 SIGNUP
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, AppRoutes.signup);
                  },
                  child: const Text(
                    "Don’t have an account? Sign up",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
