class BeatModel {
  final String id;
  final String title;
  final String producer;
  final String producerId;
  final String genre;
  final int bpm;
  final double price;
  final String description;
  final String? coverArtPath;

  BeatModel({
    required this.id,
    required this.title,
    required this.producer,
    required this.producerId,
    required this.genre,
    required this.bpm,
    required this.price,
    required this.description,
    this.coverArtPath,
  });
}
