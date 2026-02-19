class BeatModel {
  final String id;
  final String title;
  final String producer;
  final String producerId;
  final String genre;
  final int bpm;
  final double basicLicensePrice;
  final double premiumLicensePrice;
  final double exclusiveLicensePrice;
  final String description;
  final String audioPath;
  final String? coverArtPath;

  BeatModel({
    required this.id,
    required this.title,
    required this.producer,
    required this.producerId,
    required this.genre,
    required this.bpm,
    required this.basicLicensePrice,
    required this.premiumLicensePrice,
    required this.exclusiveLicensePrice,
    required this.description,
    required this.audioPath,
    this.coverArtPath,
  });

  // Backward-compatible default list price = Basic license.
  double get price => basicLicensePrice;

  double priceForLicense(String license) {
    switch (license) {
      case "Premium":
        return premiumLicensePrice;
      case "Exclusive":
        return exclusiveLicensePrice;
      case "Basic":
      default:
        return basicLicensePrice;
    }
  }

  // Create BeatModel from JSON (API response)
  factory BeatModel.fromJson(Map<String, dynamic> json) {
    return BeatModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      producer: json['producerName'] ?? json['producer'] ?? '',
      producerId: json['producerId'] ?? '',
      genre: json['genre'] ?? '',
      bpm: json['bpm'] ?? 0,
      basicLicensePrice: (json['price'] ?? json['basicLicensePrice'] ?? 0).toDouble(),
      premiumLicensePrice: json['premiumLicensePrice'] ?? json['price']?.toDouble() ?? 0.0,
      exclusiveLicensePrice: json['exclusiveLicensePrice'] ?? json['price']?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      audioPath: json['audioUrl'] ?? json['audioPath'] ?? '',
      coverArtPath: json['coverArtUrl'] ?? json['coverArtPath'],
    );
  }

  // Convert BeatModel to JSON (for API request)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'producerName': producer,
      'producerId': producerId,
      'genre': genre,
      'bpm': bpm,
      'price': basicLicensePrice,
      'audioUrl': audioPath,
      'coverArtUrl': coverArtPath,
      'description': description,
    };
  }
}
