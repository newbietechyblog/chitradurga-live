import 'package:flutter/material.dart';

import '../services/account_api.dart';
import 'article_actions.dart';

/// Asks for an optional reason, then sends the report to the editors.
/// [type] is comment, submission or user. Signed-out readers are asked to sign in first.
Future<void> reportContent(
  BuildContext context, {
  required String type,
  required int id,
}) async {
  final session = await ensureSignedIn(context);
  if (session == null || !context.mounted) return;

  final controller = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Report this'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        maxLength: 300,
        decoration: const InputDecoration(
          hintText: 'What is wrong with it? (optional)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Report'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (reason == null || !context.mounted) return;

  final api = AccountApi();
  try {
    final message = await api.report(session: session, type: type, id: id, reason: reason);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send your report. Try again.')),
      );
    }
  } finally {
    api.dispose();
  }
}
