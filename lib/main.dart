import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth/login_page.dart';
import 'backend/backend_contracts.dart';
import 'backend/local_backend.dart';
import 'core/routes.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'navigation/buyer_bottom_nav.dart';
import 'navigation/producer_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BeatHubApp());
}

class BeatHubApp extends StatelessWidget {
  const BeatHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routes: AppRoutes.routes,
      // Restore session on launch — skip login if Firebase user is still signed in
      home: FutureBuilder<SessionUser?>(
        future: AppBackend.auth.restoreSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snapshot.data;
          if (user != null) {
            return user.role == AppUserRole.producer
                ? const ProducerBottomNav()
                : const BuyerBottomNav();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
