import 'package:flutter/material.dart';

import '../models/extras.dart';
import '../services/wp_api.dart';

/// Polls made by the editors. Results are live; voting opens with sign-in.
class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  final _api = WpApi();
  List<Poll> _polls = [];
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
      final polls = await _api.fetchPolls();
      if (mounted) setState(() => _polls = polls);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load polls. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polls', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _polls.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _polls.isEmpty) {
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
    if (_polls.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Text('No polls right now. Pull down to check again.', textAlign: TextAlign.center),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _polls.length,
      itemBuilder: (context, i) => PollCard(poll: _polls[i]),
    );
  }
}

/// One poll with a bar for each option showing its share of the votes.
class PollCard extends StatelessWidget {
  final Poll poll;
  const PollCard({super.key, required this.poll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.question,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
            ),
            const SizedBox(height: 14),
            for (final option in poll.options) ...[
              Row(
                children: [
                  Expanded(child: Text(option.label, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Text('${option.percent}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: option.percent / 100,
                  minHeight: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              '${poll.total} ${poll.total == 1 ? 'vote' : 'votes'}'
              '${poll.myVote != null ? ' · You voted' : ''}',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
