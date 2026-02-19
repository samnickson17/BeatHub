import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = "BeatHub";

  // Backend URL - Connect to Express server
  static const String backendUrl = "http://localhost:5000";
  static const String apiAuthUrl = "$backendUrl/api/auth";
  static const String apiBeatsUrl = "$backendUrl/api/beats";

  // Padding
  static const double defaultPadding = 16.0;

  // Colors
  static const Color primaryColor = Colors.deepPurple;
  static const Color secondaryColor = Colors.black;
}
