import 'package:flutter/material.dart';
import '../beats/beat_store.dart';
import '../beats/beat_detail_page.dart';
import 'upload_beat_page.dart';

class ProducerHomePage extends StatefulWidget {
  const ProducerHomePage({super.key});

  @override
  State<ProducerHomePage> createState() => _ProducerHomePageState();
}

class _ProducerHomePageState extends State<ProducerHomePage> {
  @override
  Widget build(BuildContext context) {
    final myBeats = BeatStore.beats;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Beats"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UploadBeatPage(),
                ),
              );
              setState(() {}); // 🔥 refresh list
            },
          ),
        ],
      ),
      body: myBeats.isEmpty
          ? const Center(
              child: Text("No beats uploaded yet"),
            )
          : ListView.builder(
              itemCount: myBeats.length,
              itemBuilder: (context, index) {
                final beat = myBeats[index];

                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(beat.title),
                  subtitle: Text(
                      "${beat.genre} • ₹${beat.price}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BeatDetailPage(beat: beat),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
