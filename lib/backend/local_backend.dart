import '../beats/beat_model.dart';
import '../beats/beat_store.dart';
import '../profile/profile_store.dart';
import 'backend_contracts.dart';
import 'firebase_backend.dart';

// ─────────────────────────────────────────────
// Local (mock) Auth — kept for offline testing
// ─────────────────────────────────────────────
class LocalAuthBackend implements AuthBackend {
  SessionUser? _currentUser;

  @override
  SessionUser? get currentUser => _currentUser;

  @override
  Future<SessionUser?> restoreSession() async => null;

  @override
  Future<SessionUser?> login({
    required String email,
    required String password,
  }) async {
    _currentUser = SessionUser(
      userId: 'buyer_001',
      email: email,
      role: AppUserRole.buyer,
      username: email.split('@').first,
    );
    ProfileStore.setCurrentUserFromSession(_currentUser!);
    return _currentUser;
  }

  @override
  Future<SessionUser> signup({
    required String email,
    required String password,
    required String username,
    required AppUserRole role,
  }) async {
    _currentUser = SessionUser(
      userId: '${role.name}_001',
      email: email,
      role: role,
      username: username,
    );
    ProfileStore.setCurrentUserFromSession(
      _currentUser!,
      username: username,
      displayName: username,
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    ProfileStore.clearCurrentUser();
  }
}

// ─────────────────────────────────────────────
// Local (mock) Beats — kept for offline testing
// ─────────────────────────────────────────────
class LocalBeatsBackend implements BeatsBackend {
  @override
  Future<void> addBeat(BeatModel beat) async {
    BeatStore.addBeat(beat);
  }

  @override
  Future<List<BeatModel>> fetchAllBeats() async {
    return BeatStore.beats;
  }

  @override
  Future<List<BeatModel>> fetchBeatsByProducer(String producerId) async {
    return BeatStore.getBeatsByProducer(producerId);
  }

  @override
  Future<void> updateBeat(BeatModel beat) async {
    BeatStore.updateBeat(beat);
  }

  @override
  Future<void> uploadBeatWithFiles({
    required BeatModel beat,
    required List<int> audioBytes,
    required String audioExtension,
    List<int>? coverArtBytes,
    String? coverArtExtension,
  }) async {
    // Local mock: just store with the local file paths
    final mockBeat = BeatModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: beat.title,
      producer: beat.producer,
      producerId: beat.producerId,
      genre: beat.genre,
      bpm: beat.bpm,
      basicLicensePrice: beat.basicLicensePrice,
      premiumLicensePrice: beat.premiumLicensePrice,
      exclusiveLicensePrice: beat.exclusiveLicensePrice,
      description: beat.description,
      audioPath: 'local_mock.$audioExtension',
      coverArtPath: null,
    );
    BeatStore.addBeat(mockBeat);
  }
}

// ─────────────────────────────────────────────
// AppBackend — single access point for the app
// Swap to Local* classes for offline testing
// ─────────────────────────────────────────────
class AppBackend {
  static final AuthBackend auth = FirebaseAuthBackend();
  static final BeatsBackend beats = FirebaseBeatsBackend();
}
