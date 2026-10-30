import 'package:flutter/material.dart';

import '../models/category.dart';
import '../widgets/category_feed.dart';

/// All stories in one news category, opened from the side menu or "More".
class CategoryScreen extends StatelessWidget {
  final NewsCategory category;

  const CategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: CategoryFeed(categoryId: category.id),
    );
  }
}
