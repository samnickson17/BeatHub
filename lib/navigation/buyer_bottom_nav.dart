import 'package:flutter/material.dart';

import '../dashboard/home_page.dart';
import '../beats/beat_list_page.dart';
import '../rap_preview/rap_preview_page.dart';
import '../profile/purchased_beats_page.dart';
import '../profile/profile_gate.dart';

class BuyerBottomNav extends StatefulWidget {
  final int initialIndex;

  const BuyerBottomNav({super.key, this.initialIndex = 0});

  @override
  State<BuyerBottomNav> createState() => _BuyerBottomNavState();
}

class _BuyerBottomNavState extends State<BuyerBottomNav> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomePage(),
    BeatListPage(),
    RapPreviewPage(),
    PurchasedBeatsPage(),
    ProfileGate(), // ✅ FIX
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Discover"),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: "Beats"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Rap"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Purchases",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
