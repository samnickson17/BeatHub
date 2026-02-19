import '../beats/beat_model.dart';
import '../beats/beat_store.dart';
import '../profile/profile_store.dart';
import 'backend_contracts.dart';

class LocalAuthBackend implements AuthBackend {
  SessionUser? _currentUser;

  @override
  SessionUser? get currentUser => _currentUser;

  @override
  Future<SessionUser?> login({
    required String email,
    required String password,
    required AppUserRole role,
  }) async {
    _currentUser = SessionUser(
      userId: "${role.name}_001",
      email: email,
      role: role,
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
      userId: "${role.name}_001",
      email: email,
      role: role,
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

class LocalBeatsBackend implements BeatsBackend {
  @override
  Future<void> addBeat(BeatModel beat) async {
    BeatStore.addBeat(beat);
  }

  @override
  Future<List<BeatModel>> fetchAllBeats() async {
    return BeatStore.beats;
  }
}

class AppBackend {
  static final AuthBackend auth = LocalAuthBackend();
  static final BeatsBackend beats = LocalBeatsBackend();
}
