import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../models/extras.dart';
import '../models/post.dart';
import '../services/wp_api.dart';
import 'story_cards.dart';

/// Red breaking-news line at the top of the home page.
/// It shows one headline at a time and changes to the next every few seconds.
/// Shows nothing when there is no breaking news.
class BreakingBanner extends StatefulWidget {
  const BreakingBanner({super.key});

  @override
  State<BreakingBanner> createState() => _BreakingBannerState();
}

class _BreakingBannerState extends State<BreakingBanner> {
  final _api = WpApi();
  List<BreakingItem> _items = [];
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await _api.fetchBreaking();
      if (!mounted) return;
      setState(() {
        _items = items.take(5).toList();
        _index = 0;
      });
      _startTimer();
    } catch (_) {
      // The banner is optional; the news feed works without it.
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_items.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _items.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final item = _items[_index];

    return Material(
      color: const Color(0xFFB71C1C),
      child: InkWell(
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
        child: SizedBox(
          height: 46,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Text(
                      item.title,
                      key: ValueKey(item.id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (_items.length > 1) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${_index + 1}/${_items.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
                const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
