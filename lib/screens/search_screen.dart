import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/wp_api.dart';
import '../widgets/story_cards.dart';

/// Search the news by word.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = WpApi();
  final _controller = TextEditingController();
  List<NewsPost> _results = [];
  bool _loading = false;
  String? _message = 'Type a word and press search.';

  @override
  void dispose() {
    _controller.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final items = await _api.fetchPosts(search: query);
      if (!mounted) return;
      setState(() {
        _results = items;
        _message = items.isEmpty ? 'No stories found for "$query".' : null;
      });
    } catch (_) {
      if (mounted) setState(() => _message = 'Search failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: const InputDecoration(
            hintText: 'Search news',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: _search,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_message != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_message!, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _results.length,
      itemBuilder: (context, i) => StoryRow(post: _results[i]),
    );
  }
}
