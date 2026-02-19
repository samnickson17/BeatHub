import '../beats/beat_model.dart';

enum AppUserRole { buyer, producer }

class SessionUser {
  final String userId;
  final String email;
  final AppUserRole role;

  const SessionUser({
    required this.userId,
    required this.email,
    required this.role,
  });
}

abstract class AuthBackend {
  SessionUser? get currentUser;

  Future<SessionUser?> login({
    required String email,
    required String password,
    required AppUserRole role,
  });

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
}
