import 'package:flutter/material.dart';

/// Placeholder for sections that come in later updates.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String note;

  const ComingSoonScreen({super.key, required this.title, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(note, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
