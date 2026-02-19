import 'package:flutter/material.dart';
import '../backend/backend_contracts.dart';
import '../backend/local_backend.dart';
import '../core/routes.dart';
import 'auth_validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = "buyer";

  // 👁️ Password visibility control
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final role = _selectedRole == "producer"
        ? AppUserRole.producer
        : AppUserRole.buyer;

    await AppBackend.auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: role,
    );
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      _selectedRole == "producer" ? AppRoutes.producerNav : AppRoutes.buyerNav,
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
                  "BeatHub",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

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

                // 👤 ROLE SELECT (FIXED ALIGNMENT)
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
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
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 🔘 LOGIN BUTTON
                ElevatedButton(onPressed: _login, child: const Text("Login")),

                // 📝 SIGNUP
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.signup);
                  },
                  child: const Text("Don’t have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
