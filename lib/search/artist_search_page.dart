import 'package:flutter/material.dart';
import '../beats/beat_store.dart';
import '../beats/beat_detail_page.dart';
import '../beats/beat_model.dart';

class ArtistSearchPage extends StatefulWidget {
  const ArtistSearchPage({super.key});

  @override
  State<ArtistSearchPage> createState() =>
      _ArtistSearchPageState();
}

class _ArtistSearchPageState extends State<ArtistSearchPage> {
  final TextEditingController _searchController =
      TextEditingController();

  List<BeatModel> _results = [];

  void _onSearchChanged(String query) {
    final allBeats = BeatStore.beats;

    setState(() {
      _results = allBeats.where((beat) {
        final q = query.toLowerCase();
        return beat.title.toLowerCase().contains(q) ||
            beat.genre.toLowerCase().contains(q) ||
            beat.producer.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Beats"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 SEARCH FIELD
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText:
                    "Search by title, genre, or producer",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Results",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text(
                        "No matching beats found",
                        style:
                            TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final beat = _results[index];

                        return ListTile(
                          leading:
                              const Icon(Icons.music_note),
                          title: Text(beat.title),
                          subtitle: Text(
                            "${beat.genre} • ${beat.bpm} BPM\nby ${beat.producer}",
                          ),
                          trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BeatDetailPage(
                                        beat: beat),
                              ),
                            );
                          },
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
