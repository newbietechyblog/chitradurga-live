import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/category.dart';
import '../models/post.dart';

/// Talks to the WordPress site. Every screen goes through this class.
class WpApi {
  final http.Client _client;

  WpApi([http.Client? client]) : _client = client ?? http.Client();

  Future<dynamic> _getJson(Uri uri) async {
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Request failed (${response.statusCode})');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// News list. Pass [categoryId] to filter, or [search] to search titles and text.
  Future<List<NewsPost>> fetchPosts({int page = 1, int? categoryId, String? search}) async {
    final params = <String, String>{
      '_embed': '1',
      'per_page': '${AppConfig.pageSize}',
      'page': '$page',
      if (categoryId != null && categoryId > 0) 'categories': '$categoryId',
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('${AppConfig.wpApi}/posts').replace(queryParameters: params);

    final list = await _getJson(uri) as List<dynamic>;
    return list.map((e) => NewsPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// One full article, including the body.
  Future<NewsPost> fetchPost(int id) async {
    final uri = Uri.parse('${AppConfig.wpApi}/posts/$id').replace(queryParameters: {'_embed': '1'});
    final map = await _getJson(uri) as Map<String, dynamic>;
    return NewsPost.fromJson(map);
  }

  /// Categories that have at least one story, most used first.
  Future<List<NewsCategory>> fetchCategories() async {
    final uri = Uri.parse('${AppConfig.wpApi}/categories').replace(queryParameters: {
      'per_page': '50',
      'hide_empty': 'true',
      'orderby': 'count',
      'order': 'desc',
    });
    final list = await _getJson(uri) as List<dynamic>;
    return list.map((e) => NewsCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  void dispose() => _client.close();
}
