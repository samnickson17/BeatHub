import 'beat_model.dart';

class BeatStore {
  // 🔊 All beats in app (dummy store for now)
  static final List<BeatModel> _beats = [];

  /// Add a new beat
  static void addBeat(BeatModel beat) {
    _beats.add(beat);
  }

  /// Get all beats
  static List<BeatModel> getAllBeats() {
    return List.unmodifiable(_beats);
  }

  /// Get beats by producer
  static List<BeatModel> getBeatsByProducer(
      String producerId) {
    return _beats
        .where((beat) => beat.producerId == producerId)
        .toList();
  }

  /// Clear store (debug / testing)
  static void clear() {
    _beats.clear();
  }
}
