import 'package:flutter/material.dart';
import 'home_feed_page.dart';
import '../beats/beat_list_page.dart';
import '../rap_preview/rap_preview_page.dart';
import '../profile/artist_profile_page.dart';

class BuyerNav extends StatefulWidget {
  const BuyerNav({super.key});

  @override
  State<BuyerNav> createState() => _BuyerNavState();
}

class _BuyerNavState extends State<BuyerNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeFeedPage(),        // 🆕 FOLLOW-BASED HOME
    BeatListPage(),
    RapPreviewPage(),
    ArtistProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: "Beats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: "Rap",
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
