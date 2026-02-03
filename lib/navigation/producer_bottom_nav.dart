import 'package:flutter/material.dart';

// Pages
import '../producer/producer_home_page.dart';
import '../producer/upload_beat_page.dart';
import '../producer/revenue_calculator.dart';
import '../profile/producer_profile_page.dart';

class ProducerBottomNav extends StatefulWidget {
  const ProducerBottomNav({super.key});

  @override
  State<ProducerBottomNav> createState() =>
      _ProducerBottomNavState();
}

class _ProducerBottomNavState extends State<ProducerBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ProducerHomePage(),
    UploadBeatPage(),
    RevenueCalculatorPage(),
    ProducerProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: "Upload",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Revenue",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
