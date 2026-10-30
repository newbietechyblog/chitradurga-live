import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/extras.dart';
import '../services/links.dart';
import '../services/wp_api.dart';
import '../widgets/article_body.dart';
import '../widgets/chip_filter.dart';
import 'create_post_screen.dart';

/// Temples, festivals and programmes for the next 30 days.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

const _eventCategories = {
  'all': 'All',
  'temple': 'Temples',
  'festival': 'Festivals',
  'programme': 'Programmes',
  'other': 'Other',
};

class _EventsScreenState extends State<EventsScreen> {
  final _api = WpApi();
  List<CalendarEvent> _events = [];
  String _category = 'all';
  bool _loading = true;
  String? _error;
  int _requestId = 0;

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

  void _select(String category) {
    if (category == _category) return;
    setState(() => _category = category);
    _load();
  }

  Future<void> _load() async {
    final request = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await _api.fetchEvents(
        category: _category == 'all' ? null : _category,
      );
      if (mounted && request == _requestId) setState(() => _events = events);
    } catch (_) {
      if (mounted && request == _requestId) {
        setState(() => _error = 'Could not load events. Check your connection.');
      }
    } finally {
      if (mounted && request == _requestId) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temples & Events', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openComposer(context, type: 'event'),
        icon: const Icon(Icons.add),
        label: const Text('Add event'),
      ),
      body: Column(
        children: [
          ChipFilter(
            options: _eventCategories,
            selected: _category,
            onSelected: _select,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _events.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          ),
        ],
      );
    }
    if (_events.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No events listed for the next 30 days in this category.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _events.length,
      itemBuilder: (context, i) => EventCard(
        event: _events[i],
        onTap: () => _showDetails(_events[i]),
      ),
    );
  }

  void _showDetails(CalendarEvent event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EventDetails(event: event),
    );
  }
}

/// One event: date block on the left, title and place on the right.
class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = event.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      date != null ? DateFormat('d').format(date) : '--',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      date != null ? DateFormat('MMM').format(date).toUpperCase() : '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    if (event.time.isNotEmpty)
                      Text('🕒 ${event.time}', style: const TextStyle(fontSize: 13)),
                    if (event.place.isNotEmpty)
                      Text(
                        '📍 ${event.place}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _categoryLabel(event.category),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _categoryLabel(String key) => _eventCategories[key] ?? 'Event';

/// Bottom sheet with the full event: description, phone and website.
class EventDetails extends StatelessWidget {
  final CalendarEvent event;
  const EventDetails({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final date = event.date;
    final dateText = date != null ? DateFormat('EEEE, d MMMM yyyy').format(date) : '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_categoryLabel(event.category),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            Text(event.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25)),
            const SizedBox(height: 12),
            if (dateText.isNotEmpty) Text('📅 $dateText'),
            if (event.time.isNotEmpty) Text('🕒 ${event.time}'),
            if (event.place.isNotEmpty) Text('📍 ${event.place}'),
            const SizedBox(height: 16),
            if (event.description.isNotEmpty) ArticleBody(html: event.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (event.phone.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () => callNumber(context, event.phone),
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                if (event.link.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => openInBrowser(context, event.link),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('More details'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
