import 'package:flutter/material.dart';

import '../services/account_api.dart';
import '../services/session.dart';

/// Sign in, or create a free reader account.
/// Pops with `true` once the reader is signed in.
class SignInScreen extends StatefulWidget {
  final bool startWithCreate;
  const SignInScreen({super.key, this.startWithCreate = false});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _api = AccountApi();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  late bool _creating = widget.startWithCreate;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final username = _username.text.trim();
    final password = _password.text;
    try {
      if (_creating) {
        await _api.register(
          username: username,
          email: _email.text.trim(),
          password: password,
          name: _name.text.trim(),
        );
      }
      final session = await _api.signIn(username: username, password: password);
      await session.save();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not connect. Check your internet and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_creating ? 'Create account' : 'Sign in',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_creating) ...[
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your name.' : null,
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _username,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  helperText: 'Letters and numbers, at least 3',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.length < 3) return 'Please enter at least 3 characters.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              if (_creating) ...[
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v ?? '').contains('@') ? null : 'Please enter a valid email address.',
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: _creating ? 'At least 8 characters' : null,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if ((v ?? '').isEmpty) return 'Please enter your password.';
                  if (_creating && v!.length < 8) return 'Use at least 8 characters.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_creating ? 'Create account' : 'Sign in'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _creating = !_creating;
                          _error = null;
                        }),
                child: Text(_creating
                    ? 'Already have an account? Sign in'
                    : 'New here? Create a free account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
