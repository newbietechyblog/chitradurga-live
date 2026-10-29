import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../screens/article_screen.dart';

/// Opens the in-app article reader.
Future<void> openPost(BuildContext context, NewsPost post) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ArticleScreen(post: post)),
  );
}

/// The top story: large photo with the headline over it.
class LeadCard extends StatelessWidget {
  final NewsPost post;
  const LeadCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => openPost(context, post),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: post.imageUrl != null
                  ? CachedNetworkImage(imageUrl: post.imageUrl!, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade800),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.category.isNotEmpty)
                    Text(
                      post.category,
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    post.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chitradurga Live · ${timeAgo(post.date)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A standard story: headline on the left, thumbnail on the right.
class StoryRow extends StatelessWidget {
  final NewsPost post;
  const StoryRow({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => openPost(context, post),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${post.category.isNotEmpty ? '${post.category} · ' : ''}${timeAgo(post.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.imageUrl != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    width: 110,
                    height: 82,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
