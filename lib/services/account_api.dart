import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/extras.dart';
import 'session.dart';

/// An error with a message that can be shown to the reader as it is.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Sign-in, posting and voting. These calls need the network.
class AccountApi {
  final http.Client _client;

  AccountApi([http.Client? client]) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 30);

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.appApi}/register'),
      body: {
        'username': username,
        'email': email,
        'password': password,
        'name': name,
        'website': '', // hidden field for bots; must stay empty
      },
    ).timeout(_timeout);
    _check(res);
  }

  Future<Session> signIn({required String username, required String password}) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.appApi}/login'),
      body: {'username': username, 'password': password},
    ).timeout(_timeout);
    final map = _check(res) as Map<String, dynamic>;
    final user = map['user'] as Map<String, dynamic>;
    return Session(
      id: (user['id'] as num).toInt(),
      username: user['username'] as String? ?? username,
      name: user['name'] as String? ?? '',
      avatar: user['avatar'] as String? ?? '',
      token: map['token'] as String,
    );
  }

  /// A news, photo story or poster. [kind] is news, story or poster.
  Future<void> createSubmission({
    required Session session,
    required String kind,
    required String title,
    required String body,
    String location = '',
    String? imagePath,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('${AppConfig.appApi}/submissions'))
      ..headers['Authorization'] = session.authHeader
      ..fields.addAll({
        'kind': kind,
        'title': title,
        'body': body,
        'location': location,
      });
    if (imagePath != null) {
      req.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }
    final streamed = await req.send().timeout(const Duration(seconds: 90));
    _check(await http.Response.fromStream(streamed));
  }

  /// A temple, festival or programme. Fields follow the events endpoint.
  Future<void> createEvent({
    required Session session,
    required Map<String, String> fields,
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.appApi}/events'),
      headers: {'Authorization': session.authHeader},
      body: fields,
    ).timeout(_timeout);
    _check(res);
  }

  /// Casts a vote and returns the poll with the new counts.
  Future<Poll> vote({required Session session, required int pollId, required int option}) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.appApi}/polls/$pollId/vote'),
      headers: {'Authorization': session.authHeader},
      body: {'option': '$option'},
    ).timeout(_timeout);
    return Poll.fromJson(_check(res) as Map<String, dynamic>);
  }

  /// Returns the decoded body, or throws [ApiException] with the server's message.
  dynamic _check(http.Response res) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      data = null;
    }
    if (res.statusCode >= 300) {
      final message = data is Map<String, dynamic> ? data['message'] as String? : null;
      throw ApiException(message ?? 'Something went wrong (${res.statusCode}). Please try again.');
    }
    return data;
  }

  void dispose() => _client.close();
}
