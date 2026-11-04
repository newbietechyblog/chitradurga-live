/// A banner for one ad space in the app. Set in WordPress under Settings → App Ads.
class AppAd {
  final String image;
  final String link;

  const AppAd({required this.image, required this.link});

  factory AppAd.fromJson(Map<String, dynamic> json) => AppAd(
        image: json['image'] as String? ?? '',
        link: json['link'] as String? ?? '',
      );
}
