import 'package:flutter/material.dart';

// Existing pages
import '../producer/producer_home_page.dart';
import '../beats/beat_list_page.dart';
import '../producer/upload_beat_page.dart';
import '../producer/revenue_calculator.dart';

class ProducerBottomNav extends StatefulWidget {
  const ProducerBottomNav({super.key});

  @override
  State<ProducerBottomNav> createState() =>
      _ProducerBottomNavState();
}

class _ProducerBottomNavState extends State<ProducerBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ProducerHomePage(),      // 🏠
    BeatListPage(),          // 🎵 My Beats
    UploadBeatPage(),        // ➕ Upload
    RevenueCalculatorPage(), // 📊 Revenue
    _ProducerProfilePlaceholder(), // 👤
  ];

  void _onTabTapped(int index) {
    // All tabs are valid for Producer
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
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "",
          ),
        ],
      ),
    );
  }
}

// ---------------- PLACEHOLDER ----------------

class _ProducerProfilePlaceholder extends StatelessWidget {
  const _ProducerProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Producer Profile (Coming Soon)",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
