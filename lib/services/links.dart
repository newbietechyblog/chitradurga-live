import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'text_utils.dart';

/// Opens a web address in the phone's browser.
Future<void> openInBrowser(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the link.')),
    );
  }
}

/// Opens the phone dialer with the number filled in. The person still presses call.
Future<void> callNumber(BuildContext context, String phone) async {
  final number = dialable(phone);
  if (number.isEmpty) return;
  final ok = await launchUrl(Uri(scheme: 'tel', path: number));
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the phone dialer.')),
    );
  }
}

/// Shares a story with the phone's share sheet (WhatsApp, messages, etc.).
Future<void> sharePost(String title, String url) async {
  await Share.share('$title\n$url');
}
