import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';

/// Stories the reader has saved on this phone. Nothing is sent to the website.
class SavedPosts {
  static const _key = 'saved_posts';

  static Future<List<SavedStory>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SavedStory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isSaved(int id) async {
    final items = await load();
    return items.any((s) => s.id == id);
  }

  /// Saves the story, or removes it if already saved. Returns true when it is now saved.
  static Future<bool> toggle(NewsPost post) async {
    final items = await load();
    final wasSaved = items.any((s) => s.id == post.id);
    if (wasSaved) {
      items.removeWhere((s) => s.id == post.id);
    } else {
      items.insert(0, SavedStory.fromPost(post));
    }
    await _write(items);
    return !wasSaved;
  }

  static Future<void> remove(int id) async {
    final items = await load();
    items.removeWhere((s) => s.id == id);
    await _write(items);
  }

  static Future<void> _write(List<SavedStory> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(items.map((s) => s.toJson()).toList()));
    } catch (_) {
      // Saving is a convenience; the app keeps working without it.
    }
  }
}

/// One saved story, stored with the details needed to show it again.
class SavedStory {
  final int id;
  final String title;
  final String link;
  final DateTime date;
  final String category;
  final String? image;

  const SavedStory({
    required this.id,
    required this.title,
    required this.link,
    required this.date,
    required this.category,
    this.image,
  });

  factory SavedStory.fromPost(NewsPost post) => SavedStory(
        id: post.id,
        title: post.title,
        link: post.link,
        date: post.date,
        category: post.category,
        image: post.imageUrl,
      );

  factory SavedStory.fromJson(Map<String, dynamic> json) => SavedStory(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        link: json['link'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        category: json['category'] as String? ?? '',
        image: json['image'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'link': link,
        'date': date.toIso8601String(),
        'category': category,
        'image': image,
      };

  NewsPost toPost() => NewsPost(
        id: id,
        title: title,
        link: link,
        date: date,
        category: category,
        imageUrl: image,
      );
}
