import 'package:html_unescape/html_unescape.dart';

/// A news story, photo story or poster written by a reader and approved by an editor.
class ReaderUpdate {
  final int id;
  final String title;
  final String body;
  final String kind;
  final String location;
  final String? image;
  final DateTime date;
  final String authorName;

  const ReaderUpdate({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.location,
    required this.image,
    required this.date,
    required this.authorName,
  });

  String get kindLabel => switch (kind) {
        'story' => 'Photo story',
        'poster' => 'Poster',
        _ => 'Reader news',
      };

  factory ReaderUpdate.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return ReaderUpdate(
      id: (json['id'] as num).toInt(),
      title: HtmlUnescape().convert(json['title'] as String? ?? ''),
      body: json['body'] as String? ?? '',
      kind: json['kind'] as String? ?? 'news',
      location: HtmlUnescape().convert(json['location'] as String? ?? ''),
      image: json['image'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      authorName: author?['name'] as String? ?? 'Reader',
    );
  }
}
