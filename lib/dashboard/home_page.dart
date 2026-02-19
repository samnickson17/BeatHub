import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../backend/local_backend.dart';
import '../beats/beat_model.dart';
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

  List<BeatModel> _beats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBeats();
  }

  Future<void> _loadBeats() async {
    setState(() => _isLoading = true);
    try {
      final beats = await AppBackend.beats.fetchAllBeats();
      if (mounted)
        setState(() {
          _beats = beats;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beats = _beats;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            leading: _CoverThumb(url: beat.coverArtPath),
            title: Text(
              beat.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${beat.genre} • ${beat.bpm} BPM\nby ${beat.producer}"),
                TextButton.icon(
                  onPressed: () async {
                    if (isPlaying) {
                      await _player.stop();
                      setState(() => _playingBeatId = null);
                    } else {
                      await _player.stop();
                      if (beat.audioPath.startsWith('assets/')) {
                        await _player.play(
                          AssetSource(
                            beat.audioPath.replaceFirst('assets/', ''),
                          ),
                        );
                      } else if (beat.audioPath.startsWith('http')) {
                        await _player.play(UrlSource(beat.audioPath));
                      } else {
                        await _player.play(DeviceFileSource(beat.audioPath));
                      }
                      setState(() => _playingBeatId = beat.id);
                    }
                  },
                  icon: Icon(
                    isPlaying ? Icons.stop : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(isPlaying ? 'Stop' : 'Listen'),
                ),
              ],
            ),
            trailing: Text(
              "₹${beat.price}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            isThreeLine: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BeatDetailPage(beat: beat)),
              );
            },
          ),
        );
      },
    );
  }
}

class _CoverThumb extends StatelessWidget {
  final String? url;
  const _CoverThumb({this.url});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          url!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: Colors.deepPurple.shade100,
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Icon(Icons.music_note, color: Colors.deepPurple),
  );
}
