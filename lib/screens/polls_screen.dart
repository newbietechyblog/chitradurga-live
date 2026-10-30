import 'package:flutter/material.dart';

import '../models/extras.dart';
import '../services/account_api.dart';
import '../services/session.dart';
import '../services/wp_api.dart';
import 'me_screen.dart';

/// Polls made by the editors. Signed-in readers can vote once per poll.
class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  final _api = WpApi();
  final _account = AccountApi();
  List<Poll> _polls = [];
  Session? _session;
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
    _account.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await Session.load();
      final polls = await _api.fetchPolls();
      if (mounted) {
        setState(() {
          _session = session;
          _polls = polls;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load polls. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _vote(Poll poll, int option) async {
    final session = _session;
    if (session == null) {
      final signedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const MeScreen()),
      );
      if (signedIn == true) _load();
      return;
    }
    try {
      final updated = await _account.vote(session: session, pollId: poll.id, option: option);
      if (mounted) {
        setState(() {
          final i = _polls.indexWhere((p) => p.id == poll.id);
          if (i >= 0) _polls[i] = updated;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not record your vote. Try again.')),
        );
      }
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
      itemBuilder: (context, i) => PollCard(
        poll: _polls[i],
        signedIn: _session != null,
        onVote: (option) => _vote(_polls[i], option),
      ),
    );
  }
}

/// One poll: a bar for each option. Tap an option to vote when you have not voted yet.
class PollCard extends StatelessWidget {
  final Poll poll;
  final bool signedIn;
  final ValueChanged<int> onVote;

  const PollCard({super.key, required this.poll, required this.signedIn, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final canVote = poll.myVote == null;

    final hint = !canVote
        ? 'You voted'
        : signedIn
            ? 'Tap an option to vote'
            : 'Sign in to vote';

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
            for (var i = 0; i < poll.options.length; i++) ...[
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: canVote ? () => onVote(i) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (poll.myVote == i) ...[
                            Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              poll.options[i].label,
                              style: TextStyle(
                                fontWeight: poll.myVote == i ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${poll.options[i].percent}%',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: poll.options[i].percent / 100,
                          minHeight: 10,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              '${poll.total} ${poll.total == 1 ? 'vote' : 'votes'} · $hint',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
