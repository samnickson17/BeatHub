import '../beats/beat_model.dart';

class PurchasedBeat {
  final String id;
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

  Map<String, dynamic> toMap() => {
    if (id.isNotEmpty) 'id': id,
    'beat_id': beat.id,
    'beat_title': beat.title,
    'beat_producer': beat.producer,
    'beat_producer_id': beat.producerId,
    'beat_genre': beat.genre,
    'beat_bpm': beat.bpm,
    'beat_basic_price': beat.basicLicensePrice,
    'beat_premium_price': beat.premiumLicensePrice,
    'beat_exclusive_price': beat.exclusiveLicensePrice,
    'beat_description': beat.description,
    'beat_audio_url': beat.audioPath,
    'beat_cover_art_url': beat.coverArtPath,
    'buyer_user_id': buyerUserId,
    'buyer_name': buyerAccountName,
    'buyer_username': buyerUsername,
    'buyer_email': buyerEmail,
    'license': license,
    'price_paid': pricePaid,
    'transaction_id': transactionId,
    'purchased_at': purchasedAt.toUtc().toIso8601String(),
  };

  factory PurchasedBeat.fromMap(Map<String, dynamic> d) {
    final beat = BeatModel(
      id: (d['beat_id'] ?? d['beatId'] ?? '').toString(),
      title: (d['beat_title'] ?? d['beatTitle'] ?? '').toString(),
      producer: (d['beat_producer'] ?? d['beatProducer'] ?? '').toString(),
      producerId: (d['beat_producer_id'] ?? d['beatProducerId'] ?? '')
          .toString(),
      genre: (d['beat_genre'] ?? d['beatGenre'] ?? '').toString(),
      bpm: ((d['beat_bpm'] ?? d['beatBpm'] ?? 0) as num).toInt(),
      basicLicensePrice:
          ((d['beat_basic_price'] ?? d['beatBasicPrice'] ?? 0) as num)
              .toDouble(),
      premiumLicensePrice:
          ((d['beat_premium_price'] ?? d['beatPremiumPrice'] ?? 0) as num)
              .toDouble(),
      exclusiveLicensePrice:
          ((d['beat_exclusive_price'] ?? d['beatExclusivePrice'] ?? 0) as num)
              .toDouble(),
      description: (d['beat_description'] ?? d['beatDescription'] ?? '')
          .toString(),
      audioPath: (d['beat_audio_url'] ?? d['beatAudioUrl'] ?? '').toString(),
      coverArtPath: (d['beat_cover_art_url'] ?? d['beatCoverArtUrl'])
          ?.toString(),
    );
    final rawPurchasedAt = d['purchased_at'] ?? d['purchasedAt'];
    final purchasedAt = rawPurchasedAt is String
        ? DateTime.tryParse(rawPurchasedAt)?.toLocal() ?? DateTime.now()
        : DateTime.now();

    return PurchasedBeat(
      id: (d['id'] ?? '').toString(),
      beat: beat,
      license: (d['license'] ?? '').toString(),
      buyerUserId: (d['buyer_user_id'] ?? d['buyerUserId'] ?? '').toString(),
      buyerAccountName: (d['buyer_name'] ?? d['buyerName'] ?? '').toString(),
      buyerUsername: (d['buyer_username'] ?? d['buyerUsername'] ?? '')
          .toString(),
      buyerEmail: (d['buyer_email'] ?? d['buyerEmail'] ?? '').toString(),
      pricePaid: ((d['price_paid'] ?? d['pricePaid'] ?? 0) as num).toDouble(),
      transactionId: (d['transaction_id'] ?? d['transactionId'] ?? '')
          .toString(),
      purchasedAt: purchasedAt,
    );
  }

  // Compatibility wrappers for older backends/files.
  Map<String, dynamic> toFirestore() => toMap();

  factory PurchasedBeat.fromFirestore(String docId, Map<String, dynamic> d) {
    return PurchasedBeat.fromMap({...d, 'id': docId});
  }
}
