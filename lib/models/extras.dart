import 'package:html_unescape/html_unescape.dart';

/// A breaking-news item shown in the red banner at the top of the news feed.
class BreakingItem {
  final int id;
  final String title;
  final DateTime date;

  const BreakingItem({required this.id, required this.title, required this.date});

  factory BreakingItem.fromJson(Map<String, dynamic> json) => BreakingItem(
        id: (json['id'] as num).toInt(),
        title: HtmlUnescape().convert(json['title'] as String? ?? ''),
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );
}

/// One choice in a poll, with its vote count and share of the total.
class PollOption {
  final String label;
  final int votes;
  final int percent;

  const PollOption({required this.label, required this.votes, required this.percent});

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
        label: HtmlUnescape().convert(json['label'] as String? ?? ''),
        votes: (json['votes'] as num?)?.toInt() ?? 0,
        percent: (json['percent'] as num?)?.toInt() ?? 0,
      );
}

/// A poll created by an editor on the website.
class Poll {
  final int id;
  final String question;
  final List<PollOption> options;
  final int total;
  final int? myVote;

  const Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.total,
    required this.myVote,
  });

  factory Poll.fromJson(Map<String, dynamic> json) => Poll(
        id: (json['id'] as num).toInt(),
        question: HtmlUnescape().convert(json['question'] as String? ?? ''),
        options: (json['options'] as List? ?? [])
            .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num?)?.toInt() ?? 0,
        myVote: (json['myVote'] as num?)?.toInt(),
      );
}

/// A temple, festival, programme or other event from the calendar.
class CalendarEvent {
  final int id;
  final String title;
  final DateTime? date;
  final String time;
  final String category;
  final String place;
  final String phone;
  final String link;
  final String description;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.category,
    required this.place,
    required this.phone,
    required this.link,
    required this.description,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: (json['id'] as num).toInt(),
        title: HtmlUnescape().convert(json['title'] as String? ?? ''),
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        time: json['time'] as String? ?? '',
        category: json['category'] as String? ?? '',
        place: HtmlUnescape().convert(json['place'] as String? ?? ''),
        phone: json['phone'] as String? ?? '',
        link: json['link'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}

/// A helpline, public service or notice from the local info list.
class LocalInfo {
  final int id;
  final String title;
  final String body;
  final String category;
  final String phone;
  final String link;

  const LocalInfo({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.phone,
    required this.link,
  });

  factory LocalInfo.fromJson(Map<String, dynamic> json) => LocalInfo(
        id: (json['id'] as num).toInt(),
        title: HtmlUnescape().convert(json['title'] as String? ?? ''),
        body: json['body'] as String? ?? '',
        category: json['category'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        link: json['link'] as String? ?? '',
      );
}
