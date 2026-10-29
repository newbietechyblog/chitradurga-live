import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web address in the phone's browser.
Future<void> openInBrowser(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the link.')),
    );
  }
}
