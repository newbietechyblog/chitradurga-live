import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/category.dart';
import '../models/extras.dart';
import '../models/notice.dart';
import '../models/post.dart';
import '../models/reader_update.dart';
import '../models/social.dart';

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
  Future<List<NewsPost>> fetchPosts({
    int page = 1,
    int? categoryId,
    String? search,
    int perPage = AppConfig.pageSize,
  }) async {
    final params = <String, String>{
      '_embed': '1',
      'per_page': '$perPage',
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

  /// Stories an editor marked as breaking in the last 48 hours.
  Future<List<BreakingItem>> fetchBreaking() async {
    final list = await _getJson(Uri.parse('${AppConfig.appApi}/breaking')) as List<dynamic>;
    return list.map((e) => BreakingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Polls, newest first, with live vote counts.
  Future<List<Poll>> fetchPolls() async {
    final list = await _getJson(Uri.parse('${AppConfig.appApi}/polls')) as List<dynamic>;
    return list.map((e) => Poll.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Upcoming events for the next [days] days. [category] is temple, festival, programme or other.
  Future<List<CalendarEvent>> fetchEvents({int days = 30, String? category}) async {
    final uri = Uri.parse('${AppConfig.appApi}/events').replace(queryParameters: {
      'days': '$days',
      if (category != null && category.isNotEmpty) 'category': category,
    });
    final list = await _getJson(uri) as List<dynamic>;
    return list.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Helplines, services or notices. [category] is helpline, service or notice.
  Future<List<LocalInfo>> fetchInfo({String? category}) async {
    final uri = Uri.parse('${AppConfig.appApi}/info').replace(queryParameters: {
      if (category != null && category.isNotEmpty) 'category': category,
    });
    final list = await _getJson(uri) as List<dynamic>;
    return list.map((e) => LocalInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Most discussed stories (by comments), optionally leaving out one story.
  Future<List<NewsPost>> fetchTopPosts({int count = 5, int? excludeId}) async {
    final uri = Uri.parse('${AppConfig.wpApi}/posts').replace(queryParameters: {
      '_embed': '1',
      'per_page': '$count',
      'orderby': 'comment_count',
      'order': 'desc',
      if (excludeId != null) 'exclude': '$excludeId',
    });
    final list = await _getJson(uri) as List<dynamic>;
    return list.map((e) => NewsPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Other stories in the same category.
  Future<List<NewsPost>> fetchRelatedPosts({
    required int categoryId,
    required int excludeId,
    int count = 5,
  }) async {
    final uri = Uri.parse('${AppConfig.wpApi}/posts').replace(queryParameters: {
      '_embed': '1',
      'per_page': '$count',
      'categories': '$categoryId',
      'exclude': '$excludeId',
    });
    final list = await _getJson(uri) as List<dynamic>;
    return list.map((e) => NewsPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Reader-written posts approved by editors. [kind] is news, story or poster; null means all.
  Future<List<ReaderUpdate>> fetchReaderUpdates({String? kind, int page = 1, int perPage = 10}) async {
    final uri = Uri.parse('${AppConfig.appApi}/submissions').replace(queryParameters: {
      'per_page': '$perPage',
      'page': '$page',
      if (kind != null) 'kind': kind,
    });
    final list = await _getJson(uri) as List<dynamic>;
    return list.map((e) => ReaderUpdate.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Breaking news, upcoming events and new polls, newest first.
  Future<List<AppNotice>> fetchNotices() async {
    final breaking = await fetchBreaking().catchError((_) => <BreakingItem>[]);
    final events = await fetchEvents(days: 14).catchError((_) => <CalendarEvent>[]);
    final polls = await fetchPolls().catchError((_) => <Poll>[]);
    final now = DateTime.now();

    final notices = [
      for (final b in breaking)
        AppNotice(
          key: 'b${b.id}',
          title: b.title,
          subtitle: 'Breaking news',
          date: b.date,
          kind: NoticeKind.breaking,
          id: b.id,
        ),
      for (final e in events)
        AppNotice(
          key: 'e${e.id}',
          title: e.title,
          subtitle: 'Upcoming event${e.place.isNotEmpty ? ' · ${e.place}' : ''}',
          date: e.date ?? now,
          kind: NoticeKind.event,
          id: e.id,
        ),
      for (final p in polls.take(5))
        AppNotice(
          key: 'p${p.id}',
          title: p.question,
          subtitle: 'New poll',
          date: p.date ?? now,
          kind: NoticeKind.poll,
          id: p.id,
        ),
    ];
    notices.sort((a, b) => b.date.compareTo(a.date));
    return notices;
  }

  /// Likes and comment count for a news story. Pass [authHeader] to learn whether you liked it.
  Future<NewsSocial> fetchNewsSocial(int id, {String? authHeader}) async {
    final response = await _client
        .get(
          Uri.parse('${AppConfig.appApi}/news/$id/social'),
          headers: {if (authHeader != null) 'Authorization': authHeader},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Request failed (${response.statusCode})');
    }
    return NewsSocial.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  /// Approved comments on a news story, newest first.
  Future<List<NewsComment>> fetchComments(int postId) async {
    final uri = Uri.parse('${AppConfig.wpApi}/comments').replace(queryParameters: {
      'post': '$postId',
      'per_page': '50',
      'order': 'desc',
    });
    final list = await _getJson(uri) as List<dynamic>;
    return list.map((e) => NewsComment.fromJson(e as Map<String, dynamic>)).toList();
  }

  void dispose() => _client.close();
}
