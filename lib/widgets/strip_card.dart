import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A small card for horizontal rows on the home page: photo on top, title below.
class StripCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String subtitle;
  final VoidCallback onTap;
  final double width;

  const StripCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.subtitle,
    required this.onTap,
    this.width = 170,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: imageUrl != null
                    ? CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.image_outlined, color: theme.colorScheme.outline),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
