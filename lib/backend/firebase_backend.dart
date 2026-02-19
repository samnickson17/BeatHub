import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../beats/beat_model.dart';
import 'backend_contracts.dart';

// ─────────────────────────────────────────────
// Firebase Auth Backend
// ─────────────────────────────────────────────
class FirebaseAuthBackend implements AuthBackend {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  SessionUser? _currentUser;

  @override
  SessionUser? get currentUser => _currentUser;

  @override
  Future<SessionUser?> restoreSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      _currentUser = SessionUser(
        userId: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        role: data['role'] == 'producer'
            ? AppUserRole.producer
            : AppUserRole.buyer,
        username: data['username'] ?? '',
      );
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SessionUser?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception(
        'User profile not found. Please sign up again or contact support.',
      );
    }

    final data = doc.data()!;
    _currentUser = SessionUser(
      userId: uid,
      email: email,
      role: data['role'] == 'producer'
          ? AppUserRole.producer
          : AppUserRole.buyer,
      username: data['username'] ?? '',
    );

    return _currentUser;
  }

  @override
  Future<SessionUser> signup({
    required String email,
    required String password,
    required String username,
    required AppUserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final roleStr = role == AppUserRole.producer ? 'producer' : 'buyer';

    await _db.collection('users').doc(uid).set({
      'email': email,
      'username': username,
      'displayName': username,
      'role': roleStr,
      'bio': '',
      'genres': [],
      'avatarUrl': null,
      'followersCount': 0,
      'followingCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _currentUser = SessionUser(
      userId: uid,
      email: email,
      role: role,
      username: username,
    );

    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }
}

// ─────────────────────────────────────────────
// Firebase Beats Backend
// ─────────────────────────────────────────────
class FirebaseBeatsBackend implements BeatsBackend {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<BeatModel>> fetchAllBeats() async {
    final snapshot = await _db
        .collection('beats')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return BeatModel.fromJson(data);
    }).toList();
  }

  @override
  Future<void> addBeat(BeatModel beat) async {
    await _db.collection('beats').add({
      ...beat.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<BeatModel>> fetchBeatsByProducer(String producerId) async {
    final snapshot = await _db
        .collection('beats')
        .where('producerId', isEqualTo: producerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return BeatModel.fromJson(data);
    }).toList();
  }

  @override
  Future<void> updateBeat(BeatModel beat) async {
    await _db.collection('beats').doc(beat.id).update(beat.toJson());
  }
}
