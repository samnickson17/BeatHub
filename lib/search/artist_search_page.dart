import 'dart:io';

import 'package:flutter/material.dart';

import '../backend/backend_contracts.dart';
import '../backend/local_backend.dart';
import '../profile/artist_profile_page.dart';
import '../profile/other_profile_page.dart';
import '../profile/producer_profile_page.dart';
import '../profile/producer_profile_store.dart';
import '../profile/profile_store.dart';

class ArtistSearchPage extends StatefulWidget {
  const ArtistSearchPage({super.key});

  @override
  State<ArtistSearchPage> createState() => _ArtistSearchPageState();
}

class _ArtistSearchPageState extends State<ArtistSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<_AccountItem> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _currentUserId() {
    final role = AppBackend.auth.currentUser?.role;
    if (role == AppUserRole.producer) {
      return ProducerProfileStore.profile.userId;
    }
    return ProfileStore.currentUserId;
  }

  List<_AccountItem> _allAccounts() {
    final accounts = <_AccountItem>[];
    final artistProfile = ProfileStore.getProfile(ProfileStore.currentUserId);
    if (artistProfile != null) {
      accounts.add(
        _AccountItem(
          userId: artistProfile.userId,
          name: artistProfile.name,
          username: artistProfile.username,
          bio: artistProfile.bio,
          role: "artist",
          profileImagePath: artistProfile.profileImagePath,
        ),
      );
    }

    final producer = ProducerProfileStore.profile;
    accounts.add(
      _AccountItem(
        userId: producer.userId,
        name: producer.name,
        username: producer.username,
        bio: producer.bio,
        role: "producer",
        profileImagePath: producer.profileImagePath,
      ),
    );

    return accounts;
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final all = _allAccounts();
    setState(() {
      _results = all.where((account) {
        return account.name.toLowerCase().contains(q) ||
            account.username.toLowerCase().contains(q);
      }).toList();
    });
  }

  void _openProfile(_AccountItem account) {
    final currentUserId = _currentUserId();
    if (account.userId == currentUserId) {
      if (account.role == "producer") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProducerProfilePage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ArtistProfilePage()),
        );
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtherProfilePage(
          currentUserId: currentUserId,
          userId: account.userId,
          name: account.name,
          username: account.username,
          bio: account.bio,
          role: account.role,
          profileImagePath: account.profileImagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Accounts"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search by name or username",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Accounts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text(
                        "No matching accounts found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final account = _results[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: account.profileImagePath != null
                                ? FileImage(File(account.profileImagePath!))
                                : null,
                            child: account.profileImagePath == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(account.name),
                          subtitle: Text("@${account.username}"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _openProfile(account),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountItem {
  final String userId;
  final String name;
  final String username;
  final String bio;
  final String role;
  final String? profileImagePath;

  const _AccountItem({
    required this.userId,
    required this.name,
    required this.username,
    required this.bio,
    required this.role,
    this.profileImagePath,
  });
}
