import 'dart:convert';
import 'dart:io';

import 'package:beathub_final/backend/backend_contracts.dart';
import 'package:beathub_final/backend/local_backend.dart';
import 'package:beathub_final/beats/beat_model.dart';

Future<void> main(List<String> args) async {
  final host = InternetAddress.loopbackIPv4;
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? 8080 : 8080;
  final server = await HttpServer.bind(host, port);

  stdout.writeln('BeatHub API running on http://${host.address}:$port');

  await for (final request in server) {
    try {
      final path = request.uri.path;
      final method = request.method.toUpperCase();

      if (method == 'GET' && path == '/health') {
        await _sendJson(request, HttpStatus.ok, {'status': 'ok'});
        continue;
      }

      if (method == 'POST' && path == '/auth/login') {
        final body = await _readJsonBody(request);
        final email = (body['email'] ?? '').toString().trim();
        final password = (body['password'] ?? '').toString();

        if (email.isEmpty || password.isEmpty) {
          await _sendJson(request, HttpStatus.badRequest, {
            'error': 'email and password are required',
          });
          continue;
        }

        final user = await AppBackend.auth.login(
          email: email,
          password: password,
        );

        await _sendJson(request, HttpStatus.ok, {
          'userId': user?.userId,
          'email': user?.email,
          'role': user?.role.name,
        });
        continue;
      }

      if (method == 'POST' && path == '/auth/signup') {
        final body = await _readJsonBody(request);
        final email = (body['email'] ?? '').toString().trim();
        final password = (body['password'] ?? '').toString();
        final username = (body['username'] ?? '').toString().trim();
        final roleRaw = (body['role'] ?? 'buyer').toString().toLowerCase();
        final role = roleRaw == 'producer'
            ? AppUserRole.producer
            : AppUserRole.buyer;

        if (email.isEmpty || password.isEmpty || username.isEmpty) {
          await _sendJson(request, HttpStatus.badRequest, {
            'error': 'email, password, and username are required',
          });
          continue;
        }

        final user = await AppBackend.auth.signup(
          email: email,
          password: password,
          username: username,
          role: role,
        );

        await _sendJson(request, HttpStatus.ok, {
          'userId': user.userId,
          'email': user.email,
          'role': user.role.name,
        });
        continue;
      }

      if (method == 'POST' && path == '/auth/logout') {
        await AppBackend.auth.logout();
        await _sendJson(request, HttpStatus.ok, {'status': 'logged_out'});
        continue;
      }

      if (method == 'GET' && path == '/beats') {
        final beats = await AppBackend.beats.fetchAllBeats();
        await _sendJson(
          request,
          HttpStatus.ok,
          beats.map(_beatToJson).toList(),
        );
        continue;
      }

      if (method == 'POST' && path == '/beats/add') {
        final body = await _readJsonBody(request);
        final validationError = _validateBeatBody(body);
        if (validationError != null) {
          await _sendJson(request, HttpStatus.badRequest, {
            'error': validationError,
          });
          continue;
        }

        final beat = BeatModel(
          id: (body['id'] as String).trim(),
          title: (body['title'] as String).trim(),
          producer: (body['producer'] as String).trim(),
          producerId: (body['producerId'] as String).trim(),
          genre: (body['genre'] as String).trim(),
          bpm: (body['bpm'] as num).toInt(),
          basicLicensePrice: (body['basicLicensePrice'] as num).toDouble(),
          premiumLicensePrice: (body['premiumLicensePrice'] as num).toDouble(),
          exclusiveLicensePrice: (body['exclusiveLicensePrice'] as num)
              .toDouble(),
          description: (body['description'] as String).trim(),
          audioPath: (body['audioPath'] as String).trim(),
          coverArtPath: body['coverArtPath']?.toString(),
        );

        await AppBackend.beats.addBeat(beat);
        await _sendJson(request, HttpStatus.created, _beatToJson(beat));
        continue;
      }

      await _sendJson(request, HttpStatus.notFound, {
        'error': 'Route not found: $method $path',
      });
    } catch (e) {
      await _sendJson(request, HttpStatus.internalServerError, {
        'error': 'Server error',
        'details': e.toString(),
      });
    }
  }
}

Map<String, dynamic> _beatToJson(BeatModel beat) {
  return {
    'id': beat.id,
    'title': beat.title,
    'producer': beat.producer,
    'producerId': beat.producerId,
    'genre': beat.genre,
    'bpm': beat.bpm,
    'basicLicensePrice': beat.basicLicensePrice,
    'premiumLicensePrice': beat.premiumLicensePrice,
    'exclusiveLicensePrice': beat.exclusiveLicensePrice,
    'description': beat.description,
    'audioPath': beat.audioPath,
    'coverArtPath': beat.coverArtPath,
  };
}

String? _validateBeatBody(Map<String, dynamic> body) {
  const requiredStringFields = [
    'id',
    'title',
    'producer',
    'producerId',
    'genre',
    'description',
    'audioPath',
  ];
  for (final field in requiredStringFields) {
    final value = body[field];
    if (value is! String || value.trim().isEmpty) {
      return '$field is required';
    }
  }

  const requiredNumberFields = [
    'bpm',
    'basicLicensePrice',
    'premiumLicensePrice',
    'exclusiveLicensePrice',
  ];
  for (final field in requiredNumberFields) {
    if (body[field] is! num) return '$field must be a number';
  }

  return null;
}

Future<Map<String, dynamic>> _readJsonBody(HttpRequest request) async {
  final rawBody = await utf8.decoder.bind(request).join();
  if (rawBody.trim().isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(rawBody);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Request JSON must be an object');
  }
  return decoded;
}

Future<void> _sendJson(
  HttpRequest request,
  int statusCode,
  Object payload,
) async {
  request.response.statusCode = statusCode;
  request.response.headers.contentType = ContentType.json;
  request.response.headers.set('Access-Control-Allow-Origin', '*');
  request.response.write(jsonEncode(payload));
  await request.response.close();
}
