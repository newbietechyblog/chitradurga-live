import 'package:flutter/material.dart';

import '../config.dart';
import '../models/category.dart';
import '../models/post.dart';
import '../services/wp_api.dart';
import '../widgets/category_bar.dart';
import '../widgets/story_cards.dart';
import 'search_screen.dart';

/// News feed: category tabs, a lead story, then story rows.
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

  List<NewsCategory> _categories = [];
  int _categoryId = 0; // 0 means all categories
  int _page = 1;
  int _requestId = 0; // newer requests make older responses stale
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadCategories();
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

  Future<void> _loadCategories() async {
    try {
      final cats = await _api.fetchCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {
      // Category tabs are optional; the feed still works without them.
    }
  }

  void _selectCategory(int id) {
    if (id == _categoryId) return;
    setState(() => _categoryId = id);
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_loading || !_hasMore)) return;

    final request = reset ? ++_requestId : _requestId;
    final page = reset ? 1 : _page;
    final categoryId = _categoryId;

    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _error = null;
      }
    });

    try {
      final items = await _api.fetchPosts(page: page, categoryId: categoryId);
      if (!mounted || request != _requestId) return;
      setState(() {
        if (reset) _posts.clear();
        _posts.addAll(items);
        _hasMore = items.length == AppConfig.pageSize;
        _page = page + 1;
      });
    } catch (_) {
      if (!mounted || request != _requestId) return;
      if (_posts.isEmpty) {
        setState(() => _error = 'Could not load news. Check your connection.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not refresh. Pull down to try again.')),
        );
      }
    } finally {
      if (mounted && request == _requestId) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chitradurga Live', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_categories.isNotEmpty)
            CategoryBar(
              categories: _categories,
              selectedId: _categoryId,
              onSelected: _selectCategory,
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: _buildBody(),
            ),
          ),
        ],
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

    if (_posts.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Text('No stories here yet.', textAlign: TextAlign.center),
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
