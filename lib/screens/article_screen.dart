import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/post.dart';
import '../services/links.dart';
import '../services/saved_posts.dart';
import '../services/wp_api.dart';
import '../widgets/article_actions.dart';
import '../widgets/article_body.dart';
import '../widgets/article_comments.dart';
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
  final _commentsKey = GlobalKey();
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

  void _scrollToComments() {
    final target = _commentsKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _full ?? widget.post;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open on website',
            onPressed: () => openInBrowser(context, post.link),
          ),
        ],
      ),
      bottomNavigationBar: _ArticleBottomBar(post: post),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (post.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(imageUrl: post.imageUrl!, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 16),
          if (post.category.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  post.category,
                  style: const TextStyle(
                    color: Color(0xFFB71C1C),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 14),
          _AuthorRow(date: post.date),
          const Divider(height: 28),
          if (_loading && post.content == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          if (post.content != null) ArticleBody(html: post.content!),
          const SizedBox(height: 8),
          if (_full != null)
            ArticleActions(
              postId: post.id,
              title: post.title,
              link: post.link,
              onComments: _scrollToComments,
            ),
          if (_full != null) ArticleComments(key: _commentsKey, postId: post.id),
          if (_full != null) ArticleMore(post: _full!),
        ],
      ),
    );
  }
}

/// Byline under the headline: the newsroom name and when it was published.
class _AuthorRow extends StatelessWidget {
  final DateTime date;

  const _AuthorRow({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primary,
          child: const Text(
            'CL',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chitradurga Live',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                'Newsroom · ${timeAgo(date)}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fixed bar at the bottom of an article: Save, Copy link and Share.
class _ArticleBottomBar extends StatefulWidget {
  final NewsPost post;

  const _ArticleBottomBar({required this.post});

  @override
  State<_ArticleBottomBar> createState() => _ArticleBottomBarState();
}

class _ArticleBottomBarState extends State<_ArticleBottomBar> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    SavedPosts.isSaved(widget.post.id).then((value) {
      if (mounted) setState(() => _saved = value);
    });
  }

  Future<void> _toggleSave() async {
    final nowSaved = await SavedPosts.toggle(widget.post);
    if (!mounted) return;
    setState(() => _saved = nowSaved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowSaved
            ? 'Saved. Find it under Me → Saved stories.'
            : 'Removed from saved stories.'),
      ),
    );
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.post.link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _toggleSave,
                icon: Icon(
                  _saved ? Icons.bookmark : Icons.bookmark_border,
                  color: _saved ? accent : null,
                  size: 20,
                ),
                label: Text(_saved ? 'Saved' : 'Save'),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: _copyLink,
                icon: const Icon(Icons.link, size: 20),
                label: const Text('Copy link'),
              ),
            ),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => sharePost(widget.post.title, widget.post.link),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
