import '../beats/beat_model.dart';
import '../data/purchased_beats.dart';

enum AppUserRole { buyer, producer }

class SessionUser {
  final String userId;
  final String email;
  final AppUserRole role;
  final String username;

  const SessionUser({
    required this.userId,
    required this.email,
    required this.role,
    this.username = '',
  });
}

abstract class AuthBackend {
  SessionUser? get currentUser;

  /// Restores session from Firebase if a user is still signed in.
  /// Returns null if no active session.
  Future<SessionUser?> restoreSession();

  /// Role is not passed — it is read from Firestore.
  Future<SessionUser?> login({required String email, required String password});

  Future<SessionUser> signup({
    required String email,
    required String password,
    required String username,
    required AppUserRole role,
  });

  Future<void> logout();
}

abstract class BeatsBackend {
  Future<List<BeatModel>> fetchAllBeats();
  Future<void> addBeat(BeatModel beat);
  Future<List<BeatModel>> fetchBeatsByProducer(String producerId);
  Future<void> updateBeat(BeatModel beat);

  /// Uploads audio + optional cover art bytes to storage, then saves to DB.
  /// Bytes are read at file-pick time (withData: true) to avoid dart:io file
  /// path issues on Android (content:// URIs).
  Future<void> uploadBeatWithFiles({
    required BeatModel beat,
    required List<int> audioBytes,
    required String audioExtension,
    List<int>? coverArtBytes,
    String? coverArtExtension,
  });
}

abstract class PurchasesBackend {
  /// Save a purchase to the database.
  Future<void> recordPurchase(PurchasedBeat purchase);

  /// Beats bought by this buyer.
  Future<List<PurchasedBeat>> fetchPurchasesByBuyer(String buyerUserId);

  /// Beats sold by this producer.
  Future<List<PurchasedBeat>> fetchPurchasesBySeller(String producerId);

  /// Total revenue for a producer.
  Future<double> fetchTotalRevenue(String producerId);
}

abstract class FollowBackend {
  Future<bool> isFollowing(String myUid, String targetUid);
  Future<void> follow(String myUid, String targetUid);
  Future<void> unfollow(String myUid, String targetUid);

  /// UIDs that [uid] is following.
  Future<List<String>> getFollowingIds(String uid);

  /// UIDs that follow [uid].
  Future<List<String>> getFollowerIds(String uid);

  /// Firestore user doc data for a uid.
  Future<Map<String, dynamic>?> getUserProfile(String uid);
}
