import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../backend/local_backend.dart';
import 'beat_model.dart';
import 'beat_detail_page.dart';

class BeatListPage extends StatefulWidget {
  const BeatListPage({super.key});

  @override
  State<BeatListPage> createState() => _BeatListPageState();
}

class _BeatListPageState extends State<BeatListPage> {
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();
  String? _playingBeatId;
  String _selectedGenre = 'All';

  List<BeatModel> _beats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBeats();
  }

  Future<void> _loadBeats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final beats = await AppBackend.beats.fetchAllBeats();
      if (mounted) {
        setState(() {
          _beats = beats;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('❌ fetchAllBeats error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(BeatModel beat) async {
    final isPlaying = _playingBeatId == beat.id;
    if (isPlaying) {
      await _player.stop();
      if (mounted) setState(() => _playingBeatId = null);
      return;
    }
    await _player.stop();
    if (beat.audioPath.startsWith('assets/')) {
      await _player.play(
        AssetSource(beat.audioPath.replaceFirst('assets/', '')),
      );
    } else if (beat.audioPath.startsWith('http')) {
      await _player.play(UrlSource(beat.audioPath));
    } else {
      await _player.play(DeviceFileSource(beat.audioPath));
    }
    if (mounted) setState(() => _playingBeatId = beat.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load beats',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _loadBeats, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }
    final beats = _beats;
    final genres = <String>{'All', ...beats.map((b) => b.genre)}.toList();
    final query = _searchController.text.trim().toLowerCase();
    final filteredBeats = beats.where((beat) {
      final matchesGenre =
          _selectedGenre == 'All' || beat.genre == _selectedGenre;
      final matchesQuery =
          query.isEmpty ||
          beat.title.toLowerCase().contains(query) ||
          beat.producer.toLowerCase().contains(query);
      return matchesGenre && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Beats'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBeats),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by beat title or producer',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: DropdownButtonFormField<String>(
              initialValue: genres.contains(_selectedGenre)
                  ? _selectedGenre
                  : 'All',
              decoration: const InputDecoration(
                labelText: 'Filter by genre',
                border: OutlineInputBorder(),
              ),
              items: genres
                  .map(
                    (genre) => DropdownMenuItem<String>(
                      value: genre,
                      child: Text(genre),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedGenre = value);
              },
            ),
          ),
          Expanded(
            child: beats.isEmpty
                ? const Center(child: Text('No beats available'))
                : filteredBeats.isEmpty
                ? const Center(child: Text('No beats match this filter'))
                : ListView.builder(
                    itemCount: filteredBeats.length,
                    itemBuilder: (context, index) {
                      final beat = filteredBeats[index];
                      final isPlaying = _playingBeatId == beat.id;
                      return ListTile(
                        leading: _CoverThumb(url: beat.coverArtPath),
                        title: Text(beat.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${beat.genre} - ${beat.bpm} BPM'),
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed: () => _togglePreview(beat),
                              icon: Icon(
                                isPlaying ? Icons.stop : Icons.play_arrow,
                                size: 18,
                              ),
                              label: Text(isPlaying ? 'Stop' : 'Listen'),
                            ),
                          ],
                        ),
                        trailing: Text('Rs ${beat.price.toStringAsFixed(0)}'),
                        isThreeLine: true,
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
          ),
        ],
      ),
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
          errorBuilder: (_, _, _) => _placeholder(),
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
