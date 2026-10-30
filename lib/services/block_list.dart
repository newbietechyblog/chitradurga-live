import 'package:shared_preferences/shared_preferences.dart';

/// People this reader has blocked. Their comments are hidden on this phone.
class BlockList {
  static const _key = 'blocked_user_ids';

  static Future<Set<int>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      return raw.map(int.tryParse).whereType<int>().toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> add(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = (prefs.getStringList(_key) ?? []).toSet()..add('$userId');
      await prefs.setStringList(_key, ids.toList());
    } catch (_) {
      // If saving fails, the block lasts only until the app closes.
    }
  }
}
