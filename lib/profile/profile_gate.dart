import 'package:flutter/material.dart';
import 'profile_store.dart';
import 'create_artist_profile_page.dart';
import 'artist_profile_page.dart';

class ProfileGate extends StatelessWidget {
  const ProfileGate({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = ProfileStore.currentUserId;

    if (!ProfileStore.isProfileCompleted(userId)) {
      return const CreateArtistProfilePage();
    }

    return const ArtistProfilePage();
  }
}
