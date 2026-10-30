import 'package:flutter/material.dart';

import '../config.dart';
import '../models/extras.dart';
import '../models/post.dart';
import '../services/wp_api.dart';
import 'story_cards.dart';

/// Red strip at the top of the news feed, listing the latest breaking stories.
/// Shows nothing when there is no breaking news.
class BreakingBanner extends StatefulWidget {
  const BreakingBanner({super.key});

  @override
  State<BreakingBanner> createState() => _BreakingBannerState();
}

class _BreakingBannerState extends State<BreakingBanner> {
  final _api = WpApi();
  List<BreakingItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await _api.fetchBreaking();
      if (mounted) setState(() => _items = items.take(3).toList());
    } catch (_) {
      // The banner is optional; the news feed works without it.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFFB71C1C),
      child: Column(
        children: [
          for (final item in _items)
            InkWell(
              onTap: () => openPost(
                context,
                NewsPost(
                  id: item.id,
                  title: item.title,
                  link: '${AppConfig.siteUrl}/?p=${item.id}',
                  date: item.date,
                  category: '',
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BREAKING',
                        style: TextStyle(
                          color: Color(0xFFB71C1C),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
