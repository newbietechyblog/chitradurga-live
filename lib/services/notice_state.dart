import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which notifications the reader has already seen, so the bell can show a count.
class NoticeState {
  static const _key = 'seen_notice_keys';
  static const _maxKeep = 300;

  static Future<Set<String>> seen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_key) ?? []).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> markSeen(Iterable<String> keys) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_key) ?? [];
      final merged = [...existing, ...keys.where((k) => !existing.contains(k))];
      final trimmed = merged.length > _maxKeep ? merged.sublist(merged.length - _maxKeep) : merged;
      await prefs.setStringList(_key, trimmed);
    } catch (_) {
      // Losing the badge state is harmless; the list still works.
    }
  }
}
