import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/social.dart';
import '../services/account_api.dart';
import '../services/session.dart';
import '../services/text_utils.dart';
import '../services/wp_api.dart';
import 'article_actions.dart';

/// Comments under an article, with a box to write one. Signed-out readers see a sign-in button.
class ArticleComments extends StatefulWidget {
  final int postId;

  const ArticleComments({super.key, required this.postId});

  @override
  State<ArticleComments> createState() => _ArticleCommentsState();
}

class _ArticleCommentsState extends State<ArticleComments> {
  final _api = WpApi();
  final _account = AccountApi();
  final _controller = TextEditingController();
  List<NewsComment> _comments = [];
  Session? _session;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
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
      final comments = await _api.fetchComments(widget.postId);
      if (mounted) {
        setState(() {
          _session = session;
          _comments = comments;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load comments.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    final session = await ensureSignedIn(context);
    if (session != null && mounted) setState(() => _session = session);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a little more.')),
      );
      return;
    }
    final session = _session;
    if (session == null) return;

    setState(() => _sending = true);
    try {
      final status = await _account.postComment(
        session: session,
        postId: widget.postId,
        text: text,
      );
      _controller.clear();
      if (!mounted) return;
      if (status == 'approved') {
        await _load();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Your comment is posted.'
                : 'Thank you! Your comment will appear after it is checked.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not post your comment. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
          child: Text(
            'Comments (${_comments.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _session == null
              ? Row(
                  children: [
                    Expanded(
                      child: Text('Sign in to write a comment.', style: TextStyle(color: muted)),
                    ),
                    FilledButton(onPressed: _signIn, child: const Text('Sign in')),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          hintText: 'Write a comment',
                          counterText: '',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Post comment',
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.send, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        if (_loading && _comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No comments yet. Be the first to comment.', style: TextStyle(color: muted)),
          )
        else
          for (final c in _comments) _CommentTile(comment: c),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final NewsComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: comment.avatar.isNotEmpty ? NetworkImage(comment.avatar) : null,
            child: comment.avatar.isEmpty
                ? Icon(Icons.person, color: muted, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.author,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(timeAgo(comment.date), style: TextStyle(fontSize: 12, color: muted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(plainText(comment.html), style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
