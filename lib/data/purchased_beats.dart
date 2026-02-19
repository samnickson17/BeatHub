import '../beats/beat_model.dart';

class PurchasedBeat {
  final BeatModel beat;
  final String license;
  final String buyerUserId;
  final String buyerAccountName;
  final String buyerUsername;
  final String buyerEmail;
  final double pricePaid;
  final String transactionId;
  final DateTime purchasedAt;

  PurchasedBeat({
    required this.beat,
    required this.license,
    required this.buyerUserId,
    required this.buyerAccountName,
    required this.buyerUsername,
    required this.buyerEmail,
    required this.pricePaid,
    required this.transactionId,
    required this.purchasedAt,
  });
}

class PurchasedBeatsStore {
  static final List<PurchasedBeat> purchasedBeats = [];
}
