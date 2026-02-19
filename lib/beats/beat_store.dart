import 'beat_model.dart';

class BeatStore {
  static final List<BeatModel> _beats = [
    BeatModel(
      id: 'demo_1',
      title: 'Smoothy Drill',
      producer: 'Producer Sam',
      producerId: 'producer_001',
      genre: 'Drill',
      bpm: 140,
      basicLicensePrice: 299,
      premiumLicensePrice: 499,
      exclusiveLicensePrice: 899,
      description: 'Hard drill beat for rap artists',
      audioPath: 'assets/audio/smoothy_drill.wav',
      coverArtPath: null,
    ),
    BeatModel(
      id: 'demo_2',
      title: 'You & Me',
      producer: 'Producer Alex',
      producerId: 'producer_002',
      genre: 'LoFi',
      bpm: 90,
      basicLicensePrice: 199,
      premiumLicensePrice: 349,
      exclusiveLicensePrice: 699,
      description: 'Chill lofi vibe',
      audioPath: 'assets/audio/you_and_me.wav',
      coverArtPath: null,
    ),
  ];

  static List<BeatModel> get beats => List.unmodifiable(_beats);

  static void addBeat(BeatModel beat) {
    _beats.insert(0, beat);
  }

  static void updateBeat(BeatModel updatedBeat) {
    final index = _beats.indexWhere((beat) => beat.id == updatedBeat.id);
    if (index == -1) return;
    _beats[index] = updatedBeat;
  }

  static List<BeatModel> getBeatsByProducer(String producerId) {
    return _beats
        .where((beat) => beat.producerId == producerId)
        .toList();
  }
}
