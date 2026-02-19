import 'package:flutter/material.dart';

class FollowListPage extends StatelessWidget {
  final String title;
  final List<String> users;
  final String emptyText;

  const FollowListPage({
    super.key,
    required this.title,
    required this.users,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: users.isEmpty
          ? Center(
              child: Text(
                emptyText,
                style: const TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userId = users[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(_displayNameFromUserId(userId)),
                    subtitle: Text("@$userId"),
                  ),
                );
              },
            ),
    );
  }

  String _displayNameFromUserId(String userId) {
    return userId
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
