import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

/// Shows article HTML as text paragraphs and photos.
/// Kept simple on purpose: it doesn't depend on a third-party HTML engine.
class ArticleBody extends StatelessWidget {
  final String html;

  const ArticleBody({super.key, required this.html});

  static const _blockTags = {
    'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'blockquote', 'figcaption',
  };
  static const _skipTags = {'script', 'style', 'iframe', 'noscript'};

  @override
  Widget build(BuildContext context) {
    final body = parser.parse(html).body;
    final parts = <Widget>[];
    if (body != null) {
      for (final node in body.nodes) {
        _collect(node, parts);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts,
    );
  }

  void _collect(dom.Node node, List<Widget> out) {
    if (node is dom.Text) {
      final text = node.data.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isNotEmpty) out.add(_paragraph(text));
      return;
    }
    if (node is! dom.Element) return;

    final tag = node.localName ?? '';
    if (_skipTags.contains(tag)) return;

    if (tag == 'img') {
      _addImage(node, out);
      return;
    }

    if (_blockTags.contains(tag)) {
      final text = node.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isNotEmpty) {
        final prefix = tag == 'li' ? '• ' : '';
        out.add(_paragraph('$prefix$text', heading: tag.startsWith('h')));
      }
      for (final img in node.querySelectorAll('img')) {
        _addImage(img, out);
      }
      return;
    }

    // Containers such as div, figure, ul and section: look inside them.
    for (final child in node.nodes) {
      _collect(child, out);
    }
  }

  Widget _paragraph(String text, {bool heading = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: heading ? 19 : 17,
          fontWeight: heading ? FontWeight.w700 : FontWeight.w400,
          height: 1.7,
        ),
      ),
    );
  }

  void _addImage(dom.Element img, List<Widget> out) {
    final src = img.attributes['src'];
    if (src == null || !src.startsWith('http')) return;
    out.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(imageUrl: src, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
