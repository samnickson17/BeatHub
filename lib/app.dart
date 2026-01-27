import 'package:flutter/material.dart';

// Core
import 'core/theme.dart';
import 'core/routes.dart';
import 'core/constants.dart';

class BeatHubApp extends StatelessWidget {
  const BeatHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,

      // Initial Screen
      initialRoute: AppRoutes.login,

      // Routes
      routes: AppRoutes.routes,

      // Fallback (safety)
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                "Page not found",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        );
      },
    );
  }
}
