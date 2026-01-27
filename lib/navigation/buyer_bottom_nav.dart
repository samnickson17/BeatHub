import 'package:flutter/material.dart';

// Existing pages
import '../dashboard/home_page.dart';
import '../beats/beat_list_page.dart';
import '../rap_preview/rap_preview_page.dart';
import '../search/artist_search_page.dart';
import '../profile/artist_profile_page.dart';

class BuyerBottomNav extends StatefulWidget {
  const BuyerBottomNav({super.key});

  @override
  State<BuyerBottomNav> createState() => _BuyerBottomNavState();
}

class _BuyerBottomNavState extends State<BuyerBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),           // 🏠
    BeatListPage(),       // 🎵
    RapPreviewPage(),     // 🎙️
    ArtistSearchPage(),   // 🔍
    ArtistProfilePage(),  // 👤 PROFILE (NEW)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
            icon: Icon(Icons.mic),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
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
