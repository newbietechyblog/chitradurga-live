import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/reader_update.dart';
import '../widgets/ad_slot.dart';
import '../widgets/article_body.dart';
import '../widgets/report.dart';
import '../widgets/site_footer.dart';

/// One reader-written post, opened from the home page or the Reader updates list.
class ReaderUpdateScreen extends StatelessWidget {
  final ReaderUpdate update;

  const ReaderUpdateScreen({super.key, required this.update});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final where = update.location.isNotEmpty ? ' · ${update.location}' : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(update.kindLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Report',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => reportContent(context, type: 'submission', id: update.id),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (update.image != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(imageUrl: update.image!, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'By ${update.authorName}$where · ${timeAgo(update.date)}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                if (update.body.isNotEmpty) ArticleBody(html: update.body),
                const SizedBox(height: 8),
                Text(
                  'Written by a reader and checked by our editors before it was published.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const AdSlot(),
          const SiteFooter(),
        ],
      ),
    );
  }
}
