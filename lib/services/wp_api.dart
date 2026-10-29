import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/post.dart';

/// Talks to the WordPress site. Every screen goes through this class.
class WpApi {
  final http.Client _client;

  WpApi([http.Client? client]) : _client = client ?? http.Client();

  Future<List<NewsPost>> fetchPosts({int page = 1, int? categoryId}) async {
    final params = <String, String>{
      '_embed': '1',
      'per_page': '${AppConfig.pageSize}',
      'page': '$page',
      if (categoryId != null && categoryId > 0) 'categories': '$categoryId',
    };
    final uri = Uri.parse('${AppConfig.wpApi}/posts').replace(queryParameters: params);

    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Could not load news (${response.statusCode})');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => NewsPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  void dispose() => _client.close();
}
