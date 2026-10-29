import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';

/// A news article from the WordPress REST API.
class NewsPost {
  final int id;
  final String title;
  final String link;
  final DateTime date;
  final String category;
  final String? imageUrl;

  const NewsPost({
    required this.id,
    required this.title,
    required this.link,
    required this.date,
    required this.category,
    this.imageUrl,
  });

  factory NewsPost.fromJson(Map<String, dynamic> json) {
    final embedded = json['_embedded'] as Map<String, dynamic>?;

    // Featured image: prefer the medium-large size, fall back to the original.
    String? image;
    final media = _firstMap(embedded?['wp:featuredmedia']);
    if (media != null) {
      final sizes = (media['media_details'] as Map<String, dynamic>?)?['sizes'] as Map<String, dynamic>?;
      image = (sizes?['medium_large'] as Map<String, dynamic>?)?['source_url'] as String? ??
          media['source_url'] as String?;
    }

    // Category: first term of the first group (WordPress nests terms in lists).
    var category = '';
    final termGroups = embedded?['wp:term'] as List?;
    if (termGroups != null && termGroups.isNotEmpty) {
      final firstGroup = termGroups.first as List?;
      if (firstGroup != null && firstGroup.isNotEmpty) {
        category = (firstGroup.first as Map<String, dynamic>)['name'] as String? ?? '';
      }
    }

    final rawTitle = (json['title'] as Map<String, dynamic>)['rendered'] as String? ?? '';

    return NewsPost(
      id: json['id'] as int,
      title: HtmlUnescape().convert(rawTitle),
      link: json['link'] as String,
      date: DateTime.parse(json['date'] as String),
      category: HtmlUnescape().convert(category),
      imageUrl: image,
    );
  }

  static Map<String, dynamic>? _firstMap(Object? list) {
    if (list is List && list.isNotEmpty && list.first is Map<String, dynamic>) {
      return list.first as Map<String, dynamic>;
    }
    return null;
  }
}

/// Short relative time such as "5m ago" or "2h ago".
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM yyyy').format(date);
}
