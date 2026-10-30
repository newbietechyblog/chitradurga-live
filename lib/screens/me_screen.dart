import 'package:flutter/material.dart';

import '../services/account_api.dart';
import '../services/session.dart';
import 'create_post_screen.dart';
import 'sign_in_screen.dart';

/// Your account: sign in, post, and sign out.
class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  Session? _session;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final session = await Session.load();
    if (mounted) {
      setState(() {
        _session = session;
        _loaded = true;
      });
    }
  }

  Future<void> _signIn({bool create = false}) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SignInScreen(startWithCreate: create)),
    );
    if (ok == true) _reload();
  }

  Future<void> _deleteAccount() async {
    final session = _session;
    if (session == null) return;

    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your sign-in and profile. Your posts and comments stay on the site, '
              'but are no longer linked to your name. This cannot be undone.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password to confirm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty || !mounted) return;

    final api = AccountApi();
    try {
      await api.deleteAccount(session: session, password: password);
      await Session.clear();
      if (mounted) {
        setState(() => _session = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account has been deleted.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete your account. Check your connection.')),
        );
      }
    } finally {
      api.dispose();
    }
  }

  Future<void> _signOut() async {
    await Session.clear();
    if (mounted) setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _session == null
              ? _signedOut(context)
              : _signedIn(context, _session!),
    );
  }

  Widget _signedOut(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Sign in to share what is happening in your area.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(
              'Post news, photo stories, posters and local events, vote in polls, and join the discussion.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _signIn(),
                child: const Text('Sign in'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _signIn(create: true),
                child: const Text('Create a free account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signedIn(BuildContext context, Session session) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage:
                      session.avatar.isNotEmpty ? NetworkImage(session.avatar) : null,
                  child: session.avatar.isEmpty
                      ? Text(
                          session.name.isNotEmpty ? session.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name.isNotEmpty ? session.name : session.username,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${session.username}',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Create a post'),
                subtitle: const Text('News, photo story, poster or local event'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openComposer(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: _signOut,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete my account', style: TextStyle(color: Colors.red)),
                onTap: _deleteAccount,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Posts from readers are checked by our editors before they appear in the app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}
