enum NoticeKind { breaking, event, poll }

/// One item in the notifications list: breaking news, a new event, or a new poll.
class AppNotice {
  final String key;
  final String title;
  final String subtitle;
  final DateTime date;
  final NoticeKind kind;
  final int id;

  const AppNotice({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.kind,
    required this.id,
  });
}
