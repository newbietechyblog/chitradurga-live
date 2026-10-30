import 'package:flutter/material.dart';

import '../config.dart';
import '../models/post.dart';
import '../services/wp_api.dart';
import 'story_cards.dart';

/// A scrolling list of stories for one news category, with "Load more" at the bottom.
/// Used by the category tabs on the home page and by the category screen.
class CategoryFeed extends StatefulWidget {
  final int categoryId;

  const CategoryFeed({super.key, required this.categoryId});

  @override
  State<CategoryFeed> createState() => _CategoryFeedState();
}

class _CategoryFeedState extends State<CategoryFeed> {
  final _api = WpApi();
  final _posts = <NewsPost>[];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!reset && !_hasMore)) return;
    final page = reset ? 1 : _page;

    setState(() {
      _loading = true;
      if (reset) {
        _error = null;
        _hasMore = true;
      }
    });
    try {
      final items = await _api.fetchPosts(page: page, categoryId: widget.categoryId);
      if (!mounted) return;
      setState(() {
        if (reset) _posts.clear();
        _posts.addAll(items);
        _hasMore = items.length == AppConfig.pageSize;
        _page = page + 1;
      });
    } catch (_) {
      if (mounted && _posts.isEmpty) {
        setState(() => _error = 'Could not load stories. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_posts.isEmpty && _loading) {
      return ListView(
        children: const [
          SizedBox(height: 320, child: Center(child: CircularProgressIndicator())),
        ],
      );
    }
    if (_posts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Text(
            _error ?? 'No stories in this category yet.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _posts.length + 1,
      itemBuilder: (context, i) {
        if (i == _posts.length) {
          if (_loading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _hasMore
              ? Center(
                  child: TextButton(onPressed: () => _load(), child: const Text('Load more')),
                )
              : const SizedBox(height: 24);
        }
        return i == 0 ? LeadCard(post: _posts[i]) : StoryRow(post: _posts[i]);
      },
    );
  }
}
