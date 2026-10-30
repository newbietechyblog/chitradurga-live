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

  /// Likes or unlikes a news story and returns the new state.
  Future<({bool liked, int likes})> toggleNewsLike({
    required Session session,
    required int postId,
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.appApi}/news/$postId/like'),
      headers: {'Authorization': session.authHeader},
    ).timeout(_timeout);
    final map = _check(res) as Map<String, dynamic>;
    return (
      liked: map['liked'] == true,
      likes: (map['likes'] as num?)?.toInt() ?? 0,
    );
  }

  /// Posts a comment on a news story. Returns WordPress's status: "approved", or "hold" when
  /// an editor needs to check it first.
  Future<String> postComment({
    required Session session,
    required int postId,
    required String text,
  }) async {
    final res = await _client
        .post(
          Uri.parse('${AppConfig.wpApi}/comments'),
          headers: {
            'Authorization': session.authHeader,
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode({'post': postId, 'content': text}),
        )
        .timeout(_timeout);
    final map = _check(res) as Map<String, dynamic>;
    return map['status'] as String? ?? 'approved';
  }

  /// Permanently deletes the signed-in account after the password is confirmed.
  Future<void> deleteAccount({required Session session, required String password}) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.appApi}/me/delete'),
      headers: {'Authorization': session.authHeader},
      body: {'password': password},
    ).timeout(_timeout);
    _check(res);
  }

  /// Sends a report to the editors. [type] is comment, submission or user.
  Future<String> report({
    required Session session,
    required String type,
    required int id,
    required String reason,
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConfig.appApi}/report'),
      headers: {'Authorization': session.authHeader},
      body: {'type': type, 'id': '$id', 'reason': reason},
    ).timeout(_timeout);
    final map = _check(res) as Map<String, dynamic>;
    return map['message'] as String? ?? 'Thank you. Our editors will review this.';
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
