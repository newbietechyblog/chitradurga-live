import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/extras.dart';
import '../models/notice.dart';
import '../models/post.dart';
import '../models/reader_update.dart';
import '../services/notice_state.dart';
import '../services/wp_api.dart';
import '../widgets/ad_slot.dart';
import '../widgets/app_drawer.dart';
import '../widgets/breaking_banner.dart';
import '../widgets/category_feed.dart';
import '../widgets/category_tabs.dart';
import '../widgets/section_header.dart';
import '../widgets/site_footer.dart';
import '../widgets/story_cards.dart';
import '../widgets/strip_card.dart';
import 'category_screen.dart';
import 'events_screen.dart';
import 'notifications_screen.dart';
import 'reader_update_screen.dart';
import 'search_screen.dart';
import 'updates_screen.dart';

/// Event groups shown on the home page, in order.
const _eventGroups = {
  'temple': 'Temples',
  'festival': 'Festivals',
  'programme': 'Programmes',
  'other': 'Other events',
};

const _exploreIcons = [
  Icons.newspaper,
  Icons.sports_cricket,
  Icons.theater_comedy,
  Icons.account_balance,
  Icons.agriculture,
  Icons.school,
  Icons.health_and_safety,
  Icons.movie_outlined,
  Icons.business_center_outlined,
];

const _explorePalette = [
  Color(0xFFC62828),
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFFEF6C00),
  Color(0xFF6A1B9A),
  Color(0xFF00838F),
  Color(0xFFAD1457),
  Color(0xFF4E342E),
  Color(0xFF283593),
];

/// Home page. The first tab, "For you", shows breaking news, trending stories,
/// explore tiles, news by category, reader updates, events and the footer.
/// Other tabs show the stories of one category.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _categorySections = 5;

  final _api = WpApi();
  bool _loading = true;
  String? _error;
  int _tab = 0; // 0 is "For you"; 1 and up are categories
  List<NewsCategory> _categories = [];
  List<NewsPost> _latest = [];
  List<NewsPost> _mostDiscussed = [];
  Map<int, List<NewsPost>> _byCategory = {};
  List<ReaderUpdate> _updates = [];
  List<CalendarEvent> _events = [];
  int _unread = 0;

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
      final categories = await _api.fetchCategories().catchError((_) => <NewsCategory>[]);
      final sections = categories.take(_categorySections).toList();

      final latestF = _api.fetchPosts(perPage: 15).catchError((_) => <NewsPost>[]);
      final topF = _api.fetchTopPosts().catchError((_) => <NewsPost>[]);
      final updatesF = _api.fetchReaderUpdates(perPage: 8).catchError((_) => <ReaderUpdate>[]);
      final eventsF = _api.fetchEvents(days: 30).catchError((_) => <CalendarEvent>[]);
      final sectionsF = Future.wait(
        sections.map(
          (c) => _api.fetchPosts(categoryId: c.id, perPage: 6).catchError((_) => <NewsPost>[]),
        ),
      );
      final noticesF = _api.fetchNotices().catchError((_) => <AppNotice>[]);
      final seenF = NoticeState.seen();

      final latest = await latestF;
      final top = await topF;
      final updates = await updatesF;
      final events = await eventsF;
      final sectionLists = await sectionsF;
      final notices = await noticesF;
      final seen = await seenF;
      if (!mounted) return;

      setState(() {
        _categories = categories;
        _latest = latest;
        _mostDiscussed = top;
        _updates = updates;
        _events = events;
        _byCategory = {
          for (var i = 0; i < sections.length; i++) sections[i].id: sectionLists[i],
        };
        _unread = notices.where((n) => !seen.contains(n.key)).length;
        if (latest.isEmpty && categories.isEmpty) {
          _error = 'Could not load the home page. Check your connection.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load the home page. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshUnread() async {
    final notices = await _api.fetchNotices().catchError((_) => <AppNotice>[]);
    final seen = await NoticeState.seen();
    if (mounted) setState(() => _unread = notices.where((n) => !seen.contains(n.key)).length);
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _refreshUnread();
  }

  void _openEvent(CalendarEvent event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EventDetails(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabLabels = ['For you', for (final c in _categories) c.name];
    final showingCategory = _tab > 0 && _tab <= _categories.length;

    return Scaffold(
      drawer: AppDrawer(categories: _categories),
      appBar: AppBar(
        title: const Text(
          'Chitradurga Live',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFC62828)),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: Badge(
              isLabelVisible: _unread > 0,
              label: Text('$_unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => _push(const SearchScreen()),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_categories.isNotEmpty)
            CategoryTabs(
              labels: tabLabels,
              selected: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
          Expanded(
            child: showingCategory
                ? CategoryFeed(
                    key: ValueKey(_categories[_tab - 1].id),
                    categoryId: _categories[_tab - 1].id,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _buildForYou(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYou() {
    if (_loading && _latest.isEmpty && _byCategory.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 320, child: Center(child: CircularProgressIndicator())),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: FilledButton(onPressed: _load, child: const Text('Try again')),
          ),
        ],
      );
    }

    final children = <Widget>[const BreakingBanner()];

    // Lead story
    if (_latest.isNotEmpty) {
      children.add(LeadCard(post: _latest.first));
    }

    // Trending: large cards in a row
    if (_latest.length > 1) {
      children.add(const SectionHeader(title: 'Trending'));
      children.add(
        _strip(
          [
            for (final p in _latest.skip(1).take(6))
              TrendCard(post: p, onTap: () => openPost(context, p)),
          ],
          height: 262,
        ),
      );
    }

    // Explore more: category tiles
    if (_categories.isNotEmpty) {
      children.add(const SectionHeader(title: 'Explore more'));
      children.add(_explore());
    }

    // Latest list
    if (_latest.length > 7) {
      children.add(const SectionHeader(title: 'Latest news'));
      for (final p in _latest.skip(7).take(5)) {
        children.add(_row(StoryRow(post: p)));
      }
    }

    // News by category
    for (final c in _categories) {
      final posts = _byCategory[c.id];
      if (posts == null || posts.isEmpty) continue;
      children.add(SectionHeader(title: c.name, onMore: () => _push(CategoryScreen(category: c))));
      children.add(
        _strip([
          for (final p in posts)
            StripCard(
              title: p.title,
              imageUrl: p.imageUrl,
              subtitle: timeAgo(p.date),
              onTap: () => openPost(context, p),
            ),
        ]),
      );
    }

    children.add(const AdSlot());

    // Most discussed
    if (_mostDiscussed.isNotEmpty) {
      children.add(const SectionHeader(title: 'Most discussed'));
      for (final p in _mostDiscussed) {
        children.add(_row(StoryRow(post: p)));
      }
    }

    // Reader updates
    if (_updates.isNotEmpty) {
      children.add(
        SectionHeader(title: 'Reader updates', onMore: () => _push(const UpdatesScreen())),
      );
      children.add(
        _strip([
          for (final u in _updates)
            StripCard(
              title: u.title,
              imageUrl: u.image,
              subtitle: '${u.kindLabel} · ${timeAgo(u.date)}',
              onTap: () => _push(ReaderUpdateScreen(update: u)),
            ),
        ]),
      );
    }

    children.add(const AdSlot());

    // Events by category
    for (final entry in _eventGroups.entries) {
      final items = _events.where((e) => e.category == entry.key).take(2).toList();
      if (items.isEmpty) continue;
      children.add(SectionHeader(title: entry.value, onMore: () => _push(EventsScreen())));
      for (final e in items) {
        children.add(_row(EventCard(event: e, onTap: () => _openEvent(e))));
      }
    }

    children.add(const SiteFooter());

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: children,
    );
  }

  /// Grid of category tiles. Tapping one opens that category's tab.
  Widget _explore() {
    final shown = _categories.take(9).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.05,
        children: [
          for (var i = 0; i < shown.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _tab = i + 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        _explorePalette[i % _explorePalette.length].withValues(alpha: 0.12),
                    child: Icon(
                      _exploreIcons[i % _exploreIcons.length],
                      color: _explorePalette[i % _explorePalette.length],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shown[i].name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Adds the standard side margin around a list row.
  Widget _row(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: child,
      );

  /// A horizontal row of cards.
  Widget _strip(List<Widget> items, {double height = 224}) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }
}
