import 'package:flutter/material.dart';
import '../backend/local_backend.dart';
import '../core/routes.dart';
import 'artist_profile_page.dart';

class ProfileGate extends StatelessWidget {
  const ProfileGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppBackend.auth.currentUser;

    // No session — boot to login
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Profile always shows — user doc was created at signup
    return const ArtistProfilePage();
  }
}
