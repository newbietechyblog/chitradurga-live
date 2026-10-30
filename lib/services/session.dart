import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in reader. The password is never kept, only the app token,
/// which the reader can revoke from the website at any time.
class Session {
  final int id;
  final String username;
  final String name;
  final String avatar;
  final String token;

  const Session({
    required this.id,
    required this.username,
    required this.name,
    required this.avatar,
    required this.token,
  });

  /// Basic-auth header that WordPress accepts for application passwords.
  String get authHeader => 'Basic ${base64Encode(utf8.encode('$username:$token'))}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'avatar': avatar,
        'token': token,
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String? ?? '',
        name: json['name'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '',
        token: json['token'] as String? ?? '',
      );

  static const _key = 'reader_session';

  /// The saved reader, or null when nobody is signed in.
  static Future<Session?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
