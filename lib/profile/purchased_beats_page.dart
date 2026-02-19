import 'package:flutter/material.dart';

import '../data/purchased_beats.dart';
import '../search/artist_search_page.dart';
import '../utils/beat_download_helper.dart';
import 'purchased_beat_license_detail_page.dart';

class PurchasedBeatsPage extends StatelessWidget {
  const PurchasedBeatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final purchases = PurchasedBeatsStore.purchasedBeats;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchased Beats"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArtistSearchPage()),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: purchases.isEmpty
          ? const Center(
              child: Text(
                "No beats purchased yet",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                final item = purchases[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(item.beat.title),
                    subtitle: Text(
                      "${item.beat.genre} - ${item.license} License",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        BeatDownloadHelper.downloadWithFeedback(
                          context: context,
                          beat: item.beat,
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PurchasedBeatLicenseDetailPage(purchase: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
