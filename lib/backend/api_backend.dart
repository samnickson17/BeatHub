import 'dart:convert';
import 'package:http/http.dart' as http;
import '../beats/beat_model.dart';
import '../core/constants.dart';
import 'backend_contracts.dart';

class ApiAuthBackend implements AuthBackend {
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
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiAuthUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = SessionUser(
          userId: data['user']['id'],
          email: data['user']['email'],
          role: data['user']['role'] == 'producer'
              ? AppUserRole.producer
              : AppUserRole.buyer,
          username: data['user']['username'] ?? '',
        );
        return _currentUser;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  @override
  Future<SessionUser> signup({
    required String email,
    required String password,
    required String username,
    required AppUserRole role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiAuthUrl}/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
          'role': role.name,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _currentUser = SessionUser(
          userId: data['user']['id'],
          email: data['user']['email'],
          role: role,
        );
        return _currentUser!;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Signup failed');
      }
    } catch (e) {
      throw Exception('Failed to signup: $e');
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }
}

class ApiBeatsBackend implements BeatsBackend {
  @override
  Future<List<BeatModel>> fetchAllBeats() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.apiBeatsUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BeatModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch beats');
      }
    } catch (e) {
      throw Exception('Failed to fetch beats: $e');
    }
  }

  @override
  Future<void> addBeat(BeatModel beat) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.apiBeatsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(beat.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add beat');
      }
    } catch (e) {
      throw Exception('Failed to add beat: $e');
    }
  }

  @override
  Future<List<BeatModel>> fetchBeatsByProducer(String producerId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBeatsUrl}?producerId=$producerId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BeatModel.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch producer beats');
    } catch (e) {
      throw Exception('Failed to fetch producer beats: $e');
    }
  }

  @override
  Future<void> updateBeat(BeatModel beat) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiBeatsUrl}/${beat.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(beat.toJson()),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update beat');
      }
    } catch (e) {
      throw Exception('Failed to update beat: $e');
    }
  }

  @override
  Future<void> uploadBeatWithFiles({
    required BeatModel beat,
    required List<int> audioBytes,
    required String audioExtension,
    List<int>? coverArtBytes,
    String? coverArtExtension,
  }) async {
    // Not implemented for Express backend — use addBeat instead
    await addBeat(beat);
  }
}

class ApiBackend {
  static final AuthBackend auth = ApiAuthBackend();
  static final BeatsBackend beats = ApiBeatsBackend();

  // Print backend URL info
  static void printBackendInfo() {
    print('🔗 Connected to backend: ${AppConstants.backendUrl}');
    print('   - Auth API: ${AppConstants.apiAuthUrl}');
    print('   - Beats API: ${AppConstants.apiBeatsUrl}');
  }
}
