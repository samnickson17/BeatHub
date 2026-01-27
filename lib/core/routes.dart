import 'package:flutter/material.dart';

// Auth
import '../auth/login_page.dart';
import '../auth/signup_page.dart';

// Buyer
import '../dashboard/home_page.dart';
import '../navigation/buyer_bottom_nav.dart';

// Producer
import '../producer/producer_home_page.dart';
import '../producer/upload_beat_page.dart';
import '../producer/revenue_calculator.dart';
import '../navigation/producer_bottom_nav.dart';

// Beats
import '../beats/beat_list_page.dart';

// Admin
import '../admin/admin_dashboard.dart';

class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String signup = '/signup';

  // Buyer
  static const String buyerNav = '/buyer-nav';
  static const String home = '/home';

  // Producer
  static const String producerNav = '/producer-nav';
  static const String producerHome = '/producer-home';
  static const String uploadBeat = '/upload-beat';
  static const String revenue = '/revenue';

  // Common
  static const String beats = '/beats';

  // Admin
  static const String admin = '/admin';

  static Map<String, WidgetBuilder> routes = {
    // Auth
    login: (context) => const LoginPage(),
    signup: (context) => const SignupPage(),

    // Buyer
    buyerNav: (context) => const BuyerBottomNav(),
    home: (context) => const HomePage(),

    // Producer
    producerNav: (context) => const ProducerBottomNav(),
    producerHome: (context) => const ProducerHomePage(),
    uploadBeat: (context) => const UploadBeatPage(),
    revenue: (context) => const RevenueCalculatorPage(),

    // Beats
    beats: (context) => const BeatListPage(),

    // Admin
    admin: (context) => const AdminDashboard(),
  };
}
