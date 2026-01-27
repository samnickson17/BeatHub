import '../beats/beat_model.dart';

class PurchasedBeat {
  final BeatModel beat;
  final String license;

  PurchasedBeat({
    required this.beat,
    required this.license,
  });
}

class PurchasedBeatsStore {
  static final List<PurchasedBeat> purchasedBeats = [];
}
