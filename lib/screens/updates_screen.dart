import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../models/post.dart';
import '../models/reader_update.dart';
import '../services/wp_api.dart';
import '../widgets/chip_filter.dart';
import 'reader_update_screen.dart';

const _updateFilters = {
  'all': 'All',
  'news': 'Reader news',
  'story': 'Photo stories',
  'poster': 'Posters',
};

/// Posts written by readers and approved by editors, filterable by type.
class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final _api = WpApi();
  final _items = <ReaderUpdate>[];
  String _kind = 'all';
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int _requestId = 0;

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
    if (!reset && (_loading || !_hasMore)) return;

    final request = reset ? ++_requestId : _requestId;
    final page = reset ? 1 : _page;
    setState(() {
      _loading = true;
      if (reset) {
        _error = null;
        _hasMore = true;
      }
    });

    try {
      final items = await _api.fetchReaderUpdates(
        kind: _kind == 'all' ? null : _kind,
        page: page,
        perPage: 10,
      );
      if (!mounted || request != _requestId) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(items);
        _hasMore = items.length == 10;
        _page = page + 1;
      });
    } catch (_) {
      if (!mounted || request != _requestId) return;
      if (_items.isEmpty) {
        setState(() => _error = 'Could not load updates. Check your connection.');
      }
    } finally {
      if (mounted && request == _requestId) setState(() => _loading = false);
    }
  }

  void _selectKind(String kind) {
    if (kind == _kind) return;
    setState(() => _kind = kind);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader updates', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          ChipFilter(
            options: _updateFilters,
            selected: _kind,
            onSelected: _selectKind,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_items.isEmpty && _loading) {
      return ListView(
        children: const [
          SizedBox(height: 320, child: Center(child: CircularProgressIndicator())),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Text(
            _error ?? 'No reader updates here yet. Readers can share news, photo stories and posters from the Me tab.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length + 1,
      itemBuilder: (context, i) {
        if (i == _items.length) {
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
        final item = _items[i];
        return ReaderUpdateCard(
          update: item,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReaderUpdateScreen(update: item)),
          ),
        );
      },
    );
  }
}

/// A reader update in a list: photo, type, title and author line.
class ReaderUpdateCard extends StatelessWidget {
  final ReaderUpdate update;
  final VoidCallback onTap;

  const ReaderUpdateCard({super.key, required this.update, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final where = update.location.isNotEmpty ? ' · ${update.location}' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (update.image != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(imageUrl: update.image!, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    update.kindLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    update.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'By ${update.authorName}$where · ${timeAgo(update.date)}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
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
