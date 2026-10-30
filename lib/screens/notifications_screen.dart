import 'package:flutter/material.dart';

import '../config.dart';
import '../models/notice.dart';
import '../models/post.dart';
import '../services/notice_state.dart';
import '../services/wp_api.dart';
import '../widgets/story_cards.dart';
import 'events_screen.dart';
import 'polls_screen.dart';

/// Breaking news, upcoming events and new polls. Items not yet seen are marked NEW.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = WpApi();
  List<AppNotice> _items = [];
  Set<String> _unseen = {};
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
      final items = await _api.fetchNotices();
      final seen = await NoticeState.seen();
      if (!mounted) return;
      setState(() {
        _items = items;
        _unseen = items.map((n) => n.key).where((k) => !seen.contains(k)).toSet();
      });
      // Everything on screen counts as seen from now on.
      await NoticeState.markSeen(items.map((n) => n.key));
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load notifications. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(AppNotice n) {
    switch (n.kind) {
      case NoticeKind.breaking:
        openPost(
          context,
          NewsPost(
            id: n.id,
            title: n.title,
            link: '${AppConfig.siteUrl}/?p=${n.id}',
            date: n.date,
            category: '',
          ),
        );
      case NoticeKind.event:
        Navigator.push(context, MaterialPageRoute(builder: (_) => EventsScreen()));
      case NoticeKind.poll:
        Navigator.push(context, MaterialPageRoute(builder: (_) => PollsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
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
            _error ?? 'No notifications right now.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final n = _items[i];
        final isNew = _unseen.contains(n.key);
        final scheme = Theme.of(context).colorScheme;
        final (icon, color) = switch (n.kind) {
          NoticeKind.breaking => (Icons.campaign_outlined, const Color(0xFFB71C1C)),
          NoticeKind.event => (Icons.temple_hindu_outlined, scheme.primary),
          NoticeKind.poll => (Icons.poll_outlined, scheme.primary),
        };

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => _open(n),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(n.subtitle),
            trailing: isNew
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
