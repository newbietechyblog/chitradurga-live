import 'package:html_unescape/html_unescape.dart';

/// A news category (for example Chitradurga, Crime, Sports).
class NewsCategory {
  final int id;
  final String name;

  const NewsCategory({required this.id, required this.name});

  factory NewsCategory.fromJson(Map<String, dynamic> json) {
    return NewsCategory(
      id: json['id'] as int,
      name: HtmlUnescape().convert(json['name'] as String),
    );
  }
}
