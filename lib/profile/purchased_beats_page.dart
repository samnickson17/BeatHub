import 'package:flutter/material.dart';

import '../backend/local_backend.dart';
import '../data/purchased_beats.dart';
import '../search/artist_search_page.dart';
import '../utils/beat_download_helper.dart';
import 'purchased_beat_license_detail_page.dart';

class PurchasedBeatsPage extends StatefulWidget {
  const PurchasedBeatsPage({super.key});

  @override
  State<PurchasedBeatsPage> createState() => _PurchasedBeatsPageState();
}

class _PurchasedBeatsPageState extends State<PurchasedBeatsPage> {
  List<PurchasedBeat>? _purchases;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final uid = AppBackend.auth.currentUser?.userId ?? '';
      final list = await AppBackend.purchases.fetchPurchasesByBuyer(uid);
      if (mounted)
        setState(() {
          _purchases = list;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _purchases = [];
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchased Beats"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtistSearchPage()),
            ),
            icon: const Icon(Icons.search),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_purchases == null || _purchases!.isEmpty)
          ? const Center(
              child: Text(
                "No beats purchased yet",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _purchases!.length,
              itemBuilder: (context, index) {
                final item = _purchases![index];
                return Card(
                  child: ListTile(
                    leading:
                        item.beat.coverArtPath != null &&
                            item.beat.coverArtPath!.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              item.beat.coverArtPath!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.music_note),
                            ),
                          )
                        : const Icon(Icons.music_note, size: 40),
                    title: Text(item.beat.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${item.beat.genre} · ${item.license} License"),
                        Text(
                          "Rs ${item.pricePaid.toStringAsFixed(0)} — ${item.beat.producer}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => BeatDownloadHelper.downloadWithFeedback(
                        context: context,
                        beat: item.beat,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PurchasedBeatLicenseDetailPage(purchase: item),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
