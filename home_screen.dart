import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/post.dart';
import '../services/wp_api.dart';

/// News feed: lead story on top, then a list of story rows.
/// Pull down to refresh, scroll down to load more.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = WpApi();
  final _scroll = ScrollController();
  final _posts = <NewsPost>[];

  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _api.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (!reset && !_hasMore) return;

    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _error = null;
      }
    });

    try {
      final items = await _api.fetchPosts(page: _page);
      if (!mounted) return;
      setState(() {
        if (reset) _posts.clear();
        _posts.addAll(items);
        _hasMore = items.length == AppConfig.pageSize;
        _page++;
      });
    } catch (_) {
      if (!mounted) return;
      if (_posts.isEmpty) {
        setState(() => _error = 'Could not load news. Check your connection.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not refresh. Pull down to try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chitradurga Live',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.account_circle_outlined), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_posts.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty && _error != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _load(reset: true),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      itemCount: _posts.length + 1,
      itemBuilder: (context, i) {
        if (i == _posts.length) {
          return _hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox(height: 24);
        }
        return i == 0 ? LeadCard(post: _posts[i]) : StoryRow(post: _posts[i]);
      },
    );
  }
}

/// Opens the article on the website in the phone's browser.
Future<void> openArticle(BuildContext context, NewsPost post) async {
  final ok = await launchUrl(Uri.parse(post.link), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the article.')),
    );
  }
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
        onTap: () => openArticle(context, post),
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
        onTap: () => openArticle(context, post),
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
