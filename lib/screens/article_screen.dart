import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post.dart';
import '../services/links.dart';
import '../services/wp_api.dart';
import '../widgets/article_body.dart';
import '../widgets/article_more.dart';

/// Full article inside the app. Shows the list data at once, then loads the body.
class ArticleScreen extends StatefulWidget {
  final NewsPost post;
  const ArticleScreen({super.key, required this.post});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final _api = WpApi();
  NewsPost? _full;
  bool _loading = true;
  String? _error;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final full = await _api.fetchPost(widget.post.id);
      if (mounted) setState(() => _full = full);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load the full article.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _full ?? widget.post;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => sharePost(post.title, post.link),
          ),
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Copy link',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: post.link));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open on website',
            onPressed: () => openInBrowser(context, post.link),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (post.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(imageUrl: post.imageUrl!, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 14),
          if (post.category.isNotEmpty)
            Text(
              post.category,
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 6),
          Text(
            post.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            timeAgo(post.date),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (_loading && post.content == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_error != null)
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          if (post.content != null) ArticleBody(html: post.content!),
          const SizedBox(height: 16),
          if (_full != null) ArticleMore(post: _full!),
        ],
      ),
    );
  }
}
