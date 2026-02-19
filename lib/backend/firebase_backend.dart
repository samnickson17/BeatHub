import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../beats/beat_model.dart';
import '../data/purchased_beats.dart';
import '../profile/profile_store.dart';
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
      ProfileStore.setCurrentUserFromSession(
        _currentUser!,
        username: data['username'],
        displayName: data['displayName'],
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
    ProfileStore.setCurrentUserFromSession(
      _currentUser!,
      username: data['username'],
      displayName: data['displayName'],
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
    ProfileStore.setCurrentUserFromSession(
      _currentUser!,
      username: username,
      displayName: username,
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
    // No compound index needed — filter only, sort in Dart
    final snapshot = await _db
        .collection('beats')
        .where('producerId', isEqualTo: producerId)
        .get();
    final beats = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return BeatModel.fromJson(data);
    }).toList();
    beats.sort((a, b) {
      final ta = snapshot.docs
          .firstWhere((d) => d.id == a.id)
          .data()['createdAt'];
      final tb = snapshot.docs
          .firstWhere((d) => d.id == b.id)
          .data()['createdAt'];
      if (ta == null || tb == null) return 0;
      return (tb as Timestamp).compareTo(ta as Timestamp);
    });
    return beats;
  }

  @override
  Future<void> updateBeat(BeatModel beat) async {
    await _db.collection('beats').doc(beat.id).update(beat.toJson());
  }

  @override
  Future<void> uploadBeatWithFiles({
    required BeatModel beat,
    required List<int> audioBytes,
    required String audioExtension,
    List<int>? coverArtBytes,
    String? coverArtExtension,
  }) async {
    final beatId = DateTime.now().millisecondsSinceEpoch.toString();
    final storage = FirebaseStorage.instance;

    // Upload audio
    final audioRef = storage.ref('beats/$beatId/audio.$audioExtension');
    await audioRef.putData(Uint8List.fromList(audioBytes));
    final audioUrl = await audioRef.getDownloadURL();

    // Upload cover art (optional)
    String? coverUrl;
    if (coverArtBytes != null && coverArtExtension != null) {
      final coverRef = storage.ref('beats/$beatId/cover.$coverArtExtension');
      await coverRef.putData(Uint8List.fromList(coverArtBytes));
      coverUrl = await coverRef.getDownloadURL();
    }

    await _db.collection('beats').doc(beatId).set({
      'title': beat.title,
      'producerId': beat.producerId,
      'producerName': beat.producer,
      'genre': beat.genre,
      'bpm': beat.bpm,
      'price': beat.basicLicensePrice,
      'basicLicensePrice': beat.basicLicensePrice,
      'premiumLicensePrice': beat.premiumLicensePrice,
      'exclusiveLicensePrice': beat.exclusiveLicensePrice,
      'description': beat.description,
      'audioUrl': audioUrl,
      'coverArtUrl': coverUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// ─────────────────────────────────────────────
// Firebase Purchases Backend
// ─────────────────────────────────────────────
class FirebasePurchasesBackend implements PurchasesBackend {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<void> recordPurchase(PurchasedBeat purchase) async {
    await _db.collection('purchases').add(purchase.toFirestore());
  }

  @override
  Future<List<PurchasedBeat>> fetchPurchasesByBuyer(String buyerUserId) async {
    final snapshot = await _db
        .collection('purchases')
        .where('buyerUserId', isEqualTo: buyerUserId)
        .get();
    final list = snapshot.docs
        .map((doc) => PurchasedBeat.fromFirestore(doc.id, doc.data()))
        .toList();
    list.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
    return list;
  }

  @override
  Future<List<PurchasedBeat>> fetchPurchasesBySeller(String producerId) async {
    final snapshot = await _db
        .collection('purchases')
        .where('beatProducerId', isEqualTo: producerId)
        .get();
    final list = snapshot.docs
        .map((doc) => PurchasedBeat.fromFirestore(doc.id, doc.data()))
        .toList();
    list.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
    return list;
  }

  @override
  Future<double> fetchTotalRevenue(String producerId) async {
    final list = await fetchPurchasesBySeller(producerId);
    return list.fold<double>(0, (sum, p) => sum + p.pricePaid);
  }
}

// ─────────────────────────────────────────────
// Firebase Follow Backend
// ─────────────────────────────────────────────
class FirebaseFollowBackend implements FollowBackend {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<bool> isFollowing(String myUid, String targetUid) async {
    final doc = await _db
        .collection('users')
        .doc(myUid)
        .collection('following')
        .doc(targetUid)
        .get();
    return doc.exists;
  }

  @override
  Future<void> follow(String myUid, String targetUid) async {
    final batch = _db.batch();
    final ts = FieldValue.serverTimestamp();
    batch.set(
      _db.collection('users').doc(myUid).collection('following').doc(targetUid),
      {'targetId': targetUid, 'createdAt': ts},
    );
    batch.set(
      _db.collection('users').doc(targetUid).collection('followers').doc(myUid),
      {'followerId': myUid, 'createdAt': ts},
    );
    batch.update(_db.collection('users').doc(myUid), {
      'followingCount': FieldValue.increment(1),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followersCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  @override
  Future<void> unfollow(String myUid, String targetUid) async {
    final batch = _db.batch();
    batch.delete(
      _db.collection('users').doc(myUid).collection('following').doc(targetUid),
    );
    batch.delete(
      _db.collection('users').doc(targetUid).collection('followers').doc(myUid),
    );
    batch.update(_db.collection('users').doc(myUid), {
      'followingCount': FieldValue.increment(-1),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followersCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  @override
  Future<List<String>> getFollowingIds(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .get();
    return snapshot.docs.map((d) => d.id).toList();
  }

  @override
  Future<List<String>> getFollowerIds(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('followers')
        .get();
    return snapshot.docs.map((d) => d.id).toList();
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return {...doc.data()!, 'uid': uid};
  }
}
