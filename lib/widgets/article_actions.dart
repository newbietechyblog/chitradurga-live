import 'package:flutter/material.dart';

import '../screens/sign_in_screen.dart';
import '../services/account_api.dart';
import '../services/links.dart';
import '../services/session.dart';
import '../services/wp_api.dart';

/// Returns the signed-in reader. If nobody is signed in, opens the sign-in screen first.
Future<Session?> ensureSignedIn(BuildContext context) async {
  final current = await Session.load();
  if (current != null) return current;
  if (!context.mounted) return null;
  final ok = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const SignInScreen()),
  );
  if (ok != true) return null;
  return Session.load();
}

/// The bar under an article: like with count, comments with count, and share.
class ArticleActions extends StatefulWidget {
  final int postId;
  final String title;
  final String link;
  final VoidCallback onComments;

  const ArticleActions({
    super.key,
    required this.postId,
    required this.title,
    required this.link,
    required this.onComments,
  });

  @override
  State<ArticleActions> createState() => _ArticleActionsState();
}

class _ArticleActionsState extends State<ArticleActions> {
  final _api = WpApi();
  final _account = AccountApi();
  int _likes = 0;
  bool _liked = false;
  int _comments = 0;

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
    try {
      final session = await Session.load();
      final social = await _api.fetchNewsSocial(widget.postId, authHeader: session?.authHeader);
      if (mounted) {
        setState(() {
          _likes = social.likes;
          _liked = social.liked;
          _comments = social.comments;
        });
      }
    } catch (_) {
      // The bar still works without counts.
    }
  }

  Future<void> _toggleLike() async {
    final session = await ensureSignedIn(context);
    if (session == null || !mounted) return;

    // Show the change straight away; put it back if saving fails.
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
    try {
      final result = await _account.toggleNewsLike(session: session, postId: widget.postId);
      if (mounted) {
        setState(() {
          _liked = result.liked;
          _likes = result.likes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _liked = !_liked;
          _likes += _liked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Could not save your like. Try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final accent = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: _toggleLike,
              icon: Icon(
                _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                color: _liked ? accent : muted,
                size: 20,
              ),
              label: Text(
                _likes > 0 ? '$_likes' : 'Like',
                style: TextStyle(
                  color: _liked ? accent : muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: widget.onComments,
              icon: Icon(Icons.chat_bubble_outline, color: muted, size: 19),
              label: Text(
                _comments > 0 ? '$_comments' : 'Comment',
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () => sharePost(widget.title, widget.link),
              icon: Icon(Icons.share_outlined, color: muted, size: 19),
              label: Text(
                'Share',
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
