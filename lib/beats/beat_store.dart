import 'beat_model.dart';

class BeatStore {
  static final List<BeatModel> _beats = [];

  // ✅ Read-only access
  static List<BeatModel> get beats => _beats;

  // ✅ Add beat
  static void addBeat(BeatModel beat) {
    _beats.add(beat);
  }

  // (Optional for future)
  static List<BeatModel> getBeatsByProducer(String producerId) {
    return _beats
        .where((beat) => beat.producerId == producerId)
        .toList();
  }
}
