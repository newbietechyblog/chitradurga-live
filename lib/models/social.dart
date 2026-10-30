import 'package:html_unescape/html_unescape.dart';

/// Likes and comment count for one news story.
class NewsSocial {
  final int likes;
  final bool liked;
  final int comments;

  const NewsSocial({required this.likes, required this.liked, required this.comments});

  factory NewsSocial.fromJson(Map<String, dynamic> json) => NewsSocial(
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        liked: json['liked'] == true,
        comments: (json['comments'] as num?)?.toInt() ?? 0,
      );
}

/// One approved comment on a news story. [html] is the comment text as WordPress stores it.
class NewsComment {
  final int id;
  final String author;
  final String avatar;
  final DateTime date;
  final String html;

  const NewsComment({
    required this.id,
    required this.author,
    required this.avatar,
    required this.date,
    required this.html,
  });

  factory NewsComment.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>?;
    final avatars = json['author_avatar_urls'] as Map<String, dynamic>?;
    return NewsComment(
      id: (json['id'] as num).toInt(),
      author: HtmlUnescape().convert(json['author_name'] as String? ?? 'Reader'),
      avatar: avatars?['96'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      html: content?['rendered'] as String? ?? '',
    );
  }
}
