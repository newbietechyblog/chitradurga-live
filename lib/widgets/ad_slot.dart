import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/app_ad.dart';
import '../services/links.dart';
import '../services/wp_api.dart';

/// A banner space in the app. The banner comes from WordPress (Settings → App Ads).
/// Shows nothing when no banner is set for this space, so readers never see an empty box.
///
/// [slot] names the space: 'home', 'article' or 'bottom'.
/// Leave [height] empty for a full-width banner that keeps its own shape.
/// Set [height] for a fixed strip; the image is cropped to fill it.
class AdSlot extends StatefulWidget {
  final String slot;
  final double? height;

  const AdSlot({super.key, this.slot = 'home', this.height});

  @override
  State<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends State<AdSlot> {
  /// Banners are shared by every space and refreshed every 10 minutes.
  static Map<String, AppAd>? _cache;
  static DateTime? _cachedAt;

  AppAd? _ad;

  @override
  void initState() {
    super.initState();
    _load();
  }

  static Future<Map<String, AppAd>> _all() async {
    final fresh = _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(minutes: 10);
    if (_cache != null && fresh) return _cache!;

    final api = WpApi();
    try {
      _cache = await api.fetchAppAds();
      _cachedAt = DateTime.now();
    } catch (_) {
      // Keep whatever we had; the app works without banners.
      _cache ??= <String, AppAd>{};
    } finally {
      api.dispose();
    }
    return _cache!;
  }

  Future<void> _load() async {
    final all = await _all();
    if (mounted) setState(() => _ad = all[widget.slot]);
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || ad.image.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final strip = widget.height != null;

    final banner = ClipRRect(
      borderRadius: BorderRadius.circular(strip ? 6 : 10),
      child: CachedNetworkImage(
        imageUrl: ad.image,
        width: double.infinity,
        height: widget.height,
        fit: strip ? BoxFit.cover : BoxFit.fitWidth,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      ),
    );

    return Padding(
      padding: strip
          ? const EdgeInsets.fromLTRB(8, 4, 8, 4)
          : const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!strip) ...[
            Text(
              'ADVERTISEMENT',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
          ],
          GestureDetector(
            onTap: ad.link.isEmpty ? null : () => openInBrowser(context, ad.link),
            child: banner,
          ),
        ],
      ),
    );
  }
}
