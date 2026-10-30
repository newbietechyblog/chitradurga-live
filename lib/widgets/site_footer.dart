import 'package:flutter/material.dart';

import '../config.dart';
import '../services/links.dart';

/// Website footer shown at the bottom of the home page and every article.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      color: const Color(0xFF15171C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chitradurga Live',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Local news, temple events, polls and helplines for Chitradurga.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _link(context, 'Visit website', AppConfig.siteUrl),
              _link(context, 'Contact us', '${AppConfig.siteUrl}/contact'),
              _link(context, 'Privacy policy', '${AppConfig.siteUrl}/privacy-policy'),
              _link(context, 'Advertise with us', '${AppConfig.siteUrl}/advertise'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '© $year Chitradurga Live. All rights reserved.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _link(BuildContext context, String label, String url) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
      onPressed: () => openInBrowser(context, url),
      child: Text(label),
    );
  }
}
