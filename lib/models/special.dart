/// A special page (for example a festival page built on the website).
/// It opens inside the app. Set in WordPress under Settings → App Specials.
class SpecialPage {
  final String title;
  final String url;
  final String image;
  final DateTime? start;
  final DateTime? end;

  const SpecialPage({
    required this.title,
    required this.url,
    required this.image,
    this.start,
    this.end,
  });

  factory SpecialPage.fromJson(Map<String, dynamic> json) => SpecialPage(
        title: json['title'] as String? ?? '',
        url: json['url'] as String? ?? '',
        image: json['image'] as String? ?? '',
        start: DateTime.tryParse(json['start'] as String? ?? ''),
        end: DateTime.tryParse(json['end'] as String? ?? ''),
      );
}
