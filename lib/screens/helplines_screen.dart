import 'package:flutter/material.dart';

import '../models/extras.dart';
import '../services/links.dart';
import '../services/text_utils.dart';
import '../services/wp_api.dart';
import '../widgets/chip_filter.dart';

/// Helpline numbers, public services and notices, with tap-to-call.
class HelplinesScreen extends StatefulWidget {
  const HelplinesScreen({super.key});

  @override
  State<HelplinesScreen> createState() => _HelplinesScreenState();
}

const _infoCategories = {
  'all': 'All',
  'helpline': 'Helplines',
  'service': 'Services',
  'notice': 'Notices',
};

class _HelplinesScreenState extends State<HelplinesScreen> {
  final _api = WpApi();
  List<LocalInfo> _items = [];
  String _category = 'all';
  bool _loading = true;
  String? _error;
  int _requestId = 0;

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

  void _select(String category) {
    if (category == _category) return;
    setState(() => _category = category);
    _load();
  }

  Future<void> _load() async {
    final request = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.fetchInfo(
        category: _category == 'all' ? null : _category,
      );
      if (mounted && request == _requestId) setState(() => _items = items);
    } catch (_) {
      if (mounted && request == _requestId) {
        setState(() => _error = 'Could not load this list. Check your connection.');
      }
    } finally {
      if (mounted && request == _requestId) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Helplines & Info', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          ChipFilter(
            options: _infoCategories,
            selected: _category,
            onSelected: _select,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Text('Nothing listed here yet.', textAlign: TextAlign.center),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (context, i) => InfoCard(item: _items[i]),
    );
  }
}

/// One helpline or service: name, short description, and call or website buttons.
class InfoCard extends StatelessWidget {
  final LocalInfo item;
  const InfoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = plainText(item.body);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
            ),
            if (item.phone.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.phone,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
              ),
            ],
            if (item.phone.isNotEmpty || item.link.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (item.phone.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => callNumber(context, item.phone),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                  if (item.link.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => openInBrowser(context, item.link),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Website'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
