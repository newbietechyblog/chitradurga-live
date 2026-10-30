import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/wp_api.dart';
import 'ad_slot.dart';
import 'section_header.dart';
import 'site_footer.dart';
import 'story_cards.dart';

/// Below every article: related stories, most discussed stories, an ad space and the footer.
class ArticleMore extends StatefulWidget {
  final NewsPost post;

  const ArticleMore({super.key, required this.post});

  @override
  State<ArticleMore> createState() => _ArticleMoreState();
}

class _ArticleMoreState extends State<ArticleMore> {
  final _api = WpApi();
  List<NewsPost> _related = [];
  List<NewsPost> _top = [];

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
    final post = widget.post;
    final categoryId = post.categoryId;

    final relatedF = categoryId == null
        ? Future.value(<NewsPost>[])
        : _api
            .fetchRelatedPosts(categoryId: categoryId, excludeId: post.id)
            .catchError((_) => <NewsPost>[]);
    final topF = _api.fetchTopPosts(excludeId: post.id).catchError((_) => <NewsPost>[]);

    final related = await relatedF;
    final top = await topF;
    if (mounted) {
      setState(() {
        _related = related;
        _top = top;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_related.isNotEmpty) ...[
          const SectionHeader(title: 'Recommended for you'),
          for (final p in _related)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: StoryRow(post: p),
            ),
        ],
        if (_top.isNotEmpty) ...[
          const SectionHeader(title: 'Most discussed'),
          for (final p in _top)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: StoryRow(post: p),
            ),
        ],
        const AdSlot(),
        const SiteFooter(),
      ],
    );
  }
}
