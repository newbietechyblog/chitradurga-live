import 'package:flutter/material.dart';

import '../models/category.dart';

/// Horizontal row of category chips. Id 0 means "All".
class CategoryBar extends StatelessWidget {
  final List<NewsCategory> categories;
  final int selectedId;
  final ValueChanged<int> onSelected;

  const CategoryBar({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _chip(0, 'All'),
          for (final c in categories) _chip(c.id, c.name),
        ],
      ),
    );
  }

  Widget _chip(int id, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      child: ChoiceChip(
        label: Text(label),
        selected: id == selectedId,
        onSelected: (_) => onSelected(id),
      ),
    );
  }
}
