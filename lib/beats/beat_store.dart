import 'beat_model.dart';

class BeatStore {
  static final List<BeatModel> _beats = [
    BeatModel(
      id: "demo_1",
      title: "Smoothy Drill",
      producer: "Producer Sam",
      producerId: "producer_001",
      genre: "Drill",
      bpm: 140,
      price: 0,
      description: "Hard drill demo beat",
      coverArtPath: null,
      audioPath: "assets/audio/smoothy_drill.wav",
    ),
    BeatModel(
      id: "demo_2",
      title: "You & Me",
      producer: "Producer Sam",
      producerId: "producer_001",
      genre: "LoFi",
      bpm: 90,
      price: 0,
      description: "LoFi melodic demo beat",
      coverArtPath: null,
      audioPath: "assets/audio/you_and_me.wav",
    ),
  ];

  static List<BeatModel> get beats => _beats;

  static void addBeat(BeatModel beat) {
    _beats.insert(0, beat);
  }

  static List<BeatModel> getBeatsByProducer(String producerId) {
    return _beats
        .where((b) => b.producerId == producerId)
        .toList();
  }
}
