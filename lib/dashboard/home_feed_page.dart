import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../backend/local_backend.dart';
import '../profile/public_profile_page.dart';
import '../profile/user_profile_model.dart';

class HomeFeedPage extends StatefulWidget {
  const HomeFeedPage({super.key});

  @override
  State<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  bool _isLoading = true;
  List<UserProfile> _followedProducers = [];
  List<UserProfile> _suggestedProducers = [];

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    } else {
      _search(q);
    }
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    try {
      final lower = query.toLowerCase();
      final end =
          lower.substring(0, lower.length - 1) +
          String.fromCharCode(lower.codeUnitAt(lower.length - 1) + 1);

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: end)
          .limit(20)
          .get();

      // Also search by username
      final snap2 = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: lower)
          .where('username', isLessThan: end)
          .limit(20)
          .get();

      final seen = <String>{};
      final results = <UserProfile>[];
      for (final doc in [...snap.docs, ...snap2.docs]) {
        if (seen.contains(doc.id)) continue;
        seen.add(doc.id);
        final data = {...doc.data(), 'uid': doc.id};
        results.add(_profileFromMap(data));
      }

      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final myUid = AppBackend.auth.currentUser?.userId ?? '';
      final followingIds = await AppBackend.follow.getFollowingIds(myUid);

      if (followingIds.isNotEmpty) {
        // Load profiles of followed users that are producers
        final profiles = await Future.wait(
          followingIds.map((uid) => AppBackend.follow.getUserProfile(uid)),
        );
        _followedProducers = profiles
            .whereType<Map<String, dynamic>>()
            .where((d) => (d['role'] ?? '') == 'producer')
            .map((d) => _profileFromMap(d))
            .toList();
        _suggestedProducers = [];
      } else {
        // Suggest producers from Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'producer')
            .limit(20)
            .get();
        _suggestedProducers = snapshot.docs.where((d) => d.id != myUid).map((
          d,
        ) {
          final data = {...d.data(), 'uid': d.id};
          return _profileFromMap(data);
        }).toList();
        _followedProducers = [];
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  UserProfile _profileFromMap(Map<String, dynamic> d) {
    return UserProfile(
      userId: d['uid'] ?? d['userId'] ?? '',
      username: d['username'] ?? '',
      displayName: d['displayName'] ?? d['username'] ?? '',
      bio: d['bio'] ?? '',
      role: d['role'] ?? 'producer',
      profileCompleted: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isQuerying = _searchCtrl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search producers or artists...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isQuerying
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          // Results / feed below
          Expanded(
            child: isQuerying
                ? _buildSearchResults()
                : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _followedProducers.isNotEmpty
                ? _buildFollowedFeed()
                : _buildSuggestedProducers(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text("No users found", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user.displayName),
            subtitle: Text("@${user.username} · ${user.role}"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfilePage(profile: user),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFollowedFeed() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _followedProducers.length,
      itemBuilder: (context, index) {
        final producer = _followedProducers[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Text(
                producer.displayName.isNotEmpty
                    ? producer.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(producer.displayName),
            subtitle: Text("@${producer.username} · Producer"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfilePage(profile: producer),
                ),
              );
              _load(); // refresh follow state
            },
          ),
        );
      },
    );
  }

  Widget _buildSuggestedProducers() {
    if (_suggestedProducers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            "No producers found yet.\nCheck back soon!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Suggested Producers",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._suggestedProducers.map(
          (producer) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Text(
                  producer.displayName.isNotEmpty
                      ? producer.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(producer.displayName),
              subtitle: Text("@${producer.username}"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicProfilePage(profile: producer),
                  ),
                );
                _load();
              },
            ),
          ),
        ),
      ],
    );
  }
}
