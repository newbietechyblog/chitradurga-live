import 'package:flutter/material.dart';

import '../config.dart';
import '../models/category.dart';
import '../screens/category_screen.dart';
import '../screens/events_screen.dart';
import '../screens/helplines_screen.dart';
import '../screens/me_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/polls_screen.dart';
import '../screens/updates_screen.dart';
import '../services/links.dart';

/// Side menu: news categories, the other sections of the app, and website pages.
class AppDrawer extends StatelessWidget {
  final List<NewsCategory> categories;

  const AppDrawer({super.key, required this.categories});

  void _open(BuildContext context, Widget page) {
    Scaffold.maybeOf(context)?.closeDrawer();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _website(BuildContext context, String url) {
    Scaffold.maybeOf(context)?.closeDrawer();
    openInBrowser(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              color: theme.colorScheme.primary,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chitradurga Live',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Local news and information',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _heading('News categories'),
            for (final c in categories)
              ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(c.name),
                onTap: () => _open(context, CategoryScreen(category: c)),
              ),
            const Divider(),
            _heading('Explore'),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Reader updates'),
              onTap: () => _open(context, const UpdatesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.temple_hindu_outlined),
              title: const Text('Temples & events'),
              onTap: () => _open(context, EventsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.poll_outlined),
              title: const Text('Polls'),
              onTap: () => _open(context, PollsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Helplines & info'),
              onTap: () => _open(context, HelplinesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () => _open(context, const NotificationsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Me'),
              onTap: () => _open(context, MeScreen()),
            ),
            const Divider(),
            _heading('Website'),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Visit chitradurgalive.com'),
              onTap: () => _website(context, AppConfig.siteUrl),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Contact us'),
              onTap: () => _website(context, '${AppConfig.siteUrl}/contact'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy policy'),
              onTap: () => _website(context, '${AppConfig.siteUrl}/privacy-policy'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.grey),
      ),
    );
  }
}
