import 'package:flutter/material.dart';
import '../backend/local_backend.dart';
import '../beats/beat_model.dart';
import '../beats/beat_detail_page.dart';
import 'upload_beat_page.dart';

class ProducerHomePage extends StatefulWidget {
  const ProducerHomePage({super.key});

  @override
  State<ProducerHomePage> createState() => _ProducerHomePageState();
}

class _ProducerHomePageState extends State<ProducerHomePage> {
  List<BeatModel> _myBeats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyBeats();
  }

  Future<void> _loadMyBeats() async {
    setState(() => _isLoading = true);
    try {
      final producerId = AppBackend.auth.currentUser?.userId ?? '';
      final beats = await AppBackend.beats.fetchBeatsByProducer(producerId);
      if (mounted)
        setState(() {
          _myBeats = beats;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final myBeats = _myBeats;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Beats"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMyBeats),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UploadBeatPage(closeOnSuccess: true),
                ),
              );
              _loadMyBeats();
            },
          ),
        ],
      ),
      body: myBeats.isEmpty
          ? const Center(child: Text("No beats uploaded yet"))
          : ListView.builder(
              itemCount: myBeats.length,
              itemBuilder: (context, index) {
                final beat = myBeats[index];

                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(beat.title),
                  subtitle: Text(
                    "${beat.genre} • Rs ${beat.price.toStringAsFixed(0)}",
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BeatDetailPage(beat: beat),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
