import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../beats/beat_store.dart';
import '../beats/beat_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _player = AudioPlayer();
  String? _playingBeatId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _player.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beats = BeatStore.beats;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Discover Beats"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Discover"),
            Tab(text: "Following"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBeatList(beats),

          // ❤️ FOLLOWING (dummy but safe)
          beats.isEmpty
              ? const Center(
                  child: Text(
                    "Follow producers to see their beats here",
                    textAlign: TextAlign.center,
                  ),
                )
              : _buildBeatList(beats),
        ],
      ),
    );
  }

  Widget _buildBeatList(List beats) {
    if (beats.isEmpty) {
      return const Center(
        child: Text(
          "No beats available yet.\nCheck back later!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: beats.length,
      itemBuilder: (context, index) {
        final beat = beats[index];
        final isPlaying = _playingBeatId == beat.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 32,
              ),
              onPressed: () async {
                if (isPlaying) {
                  await _player.stop();
                  setState(() => _playingBeatId = null);
                } else {
                  await _player.stop();
                  await _player.play(
                    AssetSource(
                      beat.audioPath.replaceFirst("assets/", ""),
                    ),
                  );
                  setState(() => _playingBeatId = beat.id);
                }
              },
            ),
            title: Text(
              beat.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${beat.genre} • ${beat.bpm} BPM\nby ${beat.producer}",
            ),
            trailing: Text(
              "₹${beat.price}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            isThreeLine: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BeatDetailPage(beat: beat),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
