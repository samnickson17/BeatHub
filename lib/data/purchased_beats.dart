import 'package:cloud_firestore/cloud_firestore.dart';

import '../beats/beat_model.dart';

class PurchasedBeat {
  final String id; // Firestore document ID
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
    this.id = '',
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

  Map<String, dynamic> toFirestore() => {
    'beatId': beat.id,
    'beatTitle': beat.title,
    'beatProducer': beat.producer,
    'beatProducerId': beat.producerId,
    'beatGenre': beat.genre,
    'beatBpm': beat.bpm,
    'beatBasicPrice': beat.basicLicensePrice,
    'beatPremiumPrice': beat.premiumLicensePrice,
    'beatExclusivePrice': beat.exclusiveLicensePrice,
    'beatDescription': beat.description,
    'beatAudioUrl': beat.audioPath,
    'beatCoverArtUrl': beat.coverArtPath,
    'buyerUserId': buyerUserId,
    'buyerName': buyerAccountName,
    'buyerUsername': buyerUsername,
    'buyerEmail': buyerEmail,
    'license': license,
    'pricePaid': pricePaid,
    'transactionId': transactionId,
    'purchasedAt': FieldValue.serverTimestamp(),
  };

  factory PurchasedBeat.fromFirestore(String docId, Map<String, dynamic> d) {
    final beat = BeatModel(
      id: d['beatId'] ?? '',
      title: d['beatTitle'] ?? '',
      producer: d['beatProducer'] ?? '',
      producerId: d['beatProducerId'] ?? '',
      genre: d['beatGenre'] ?? '',
      bpm: (d['beatBpm'] ?? 0) as int,
      basicLicensePrice: (d['beatBasicPrice'] ?? 0).toDouble(),
      premiumLicensePrice: (d['beatPremiumPrice'] ?? 0).toDouble(),
      exclusiveLicensePrice: (d['beatExclusivePrice'] ?? 0).toDouble(),
      description: d['beatDescription'] ?? '',
      audioPath: d['beatAudioUrl'] ?? '',
      coverArtPath: d['beatCoverArtUrl'],
    );
    DateTime purchasedAt = DateTime.now();
    if (d['purchasedAt'] is Timestamp) {
      purchasedAt = (d['purchasedAt'] as Timestamp).toDate();
    }
    return PurchasedBeat(
      id: docId,
      beat: beat,
      license: d['license'] ?? '',
      buyerUserId: d['buyerUserId'] ?? '',
      buyerAccountName: d['buyerName'] ?? '',
      buyerUsername: d['buyerUsername'] ?? '',
      buyerEmail: d['buyerEmail'] ?? '',
      pricePaid: (d['pricePaid'] ?? 0).toDouble(),
      transactionId: d['transactionId'] ?? '',
      purchasedAt: purchasedAt,
    );
  }
}
