import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

/// Shows article HTML: text with bold, italic, underline and tappable links,
/// headings, lists, quotes, code, photos and tables.
/// It is deliberately simple: scripts, iframes and website styling are not run.
class ArticleBody extends StatelessWidget {
  final String html;

  const ArticleBody({super.key, required this.html});

  static const _blockTags = {
    'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'figcaption', 'dt', 'dd', 'div',
  };
  static const _skipTags = {'script', 'style', 'iframe', 'noscript', 'button', 'form', 'input'};
  static const _ink = Color(0xFF15171C);
  static const _accent = Color(0xFFC62828);

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
      final text = _clean(node.data);
      if (text.isNotEmpty) out.add(_text([TextSpan(text: text)]));
      return;
    }
    if (node is! dom.Element) return;

    final tag = node.localName ?? '';
    if (_skipTags.contains(tag)) return;

    if (tag == 'img') {
      _addImage(node, out);
      return;
    }
    if (tag == 'table') {
      _addTable(node, out);
      return;
    }
    if (tag == 'blockquote') {
      _addQuote(node, out);
      return;
    }
    if (tag == 'pre') {
      _addCode(node, out);
      return;
    }
    if (tag == 'hr') {
      out.add(const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()));
      return;
    }

    if (_blockTags.contains(tag) && tag != 'div') {
      final spans = <InlineSpan>[];
      _inline(node, spans, const TextStyle());
      if (!_isBlank(spans)) {
        final isLi = tag == 'li';
        final isHeading = tag.startsWith('h');
        if (isLi) spans.insert(0, const TextSpan(text: '• '));
        out.add(_text(spans, heading: isHeading));
      }
      for (final img in node.querySelectorAll('img')) {
        _addImage(img, out);
      }
      return;
    }

    // Containers such as div, figure, ul, section: look inside them.
    for (final child in node.nodes) {
      _collect(child, out);
    }
  }

  /// Turns inline content (text, bold, italic, links, line breaks) into spans.
  void _inline(dom.Node node, List<InlineSpan> out, TextStyle style) {
    for (final child in node.nodes) {
      if (child is dom.Text) {
        final text = child.data.replaceAll(RegExp(r'\s+'), ' ');
        if (text.isNotEmpty) out.add(TextSpan(text: text, style: style));
        continue;
      }
      if (child is! dom.Element) continue;

      final tag = child.localName ?? '';
      if (_skipTags.contains(tag) || tag == 'img') continue;
      if (tag == 'br') {
        out.add(const TextSpan(text: '\n'));
        continue;
      }

      var s = style;
      switch (tag) {
        case 'strong':
        case 'b':
          s = s.copyWith(fontWeight: FontWeight.w700);
        case 'em':
        case 'i':
          s = s.copyWith(fontStyle: FontStyle.italic);
        case 'u':
          s = s.copyWith(decoration: TextDecoration.underline);
        case 'code':
          s = s.copyWith(fontFamily: 'monospace');
        case 'a':
          s = s.copyWith(color: _accent, decoration: TextDecoration.underline);
      }

      // Block elements inside inline text start on a new line.
      if (_blockTags.contains(tag) && out.isNotEmpty) {
        out.add(const TextSpan(text: '\n'));
      }

      final inner = <InlineSpan>[];
      _inline(child, inner, s);

      final href = tag == 'a' ? child.attributes['href'] : null;
      final isWebLink = href != null && href.startsWith('http');
      out.add(
        TextSpan(
          children: inner,
          style: s,
          recognizer: isWebLink
              ? (TapGestureRecognizer()
                ..onTap = () => launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication))
              : null,
        ),
      );
    }
  }

  Widget _text(List<InlineSpan> spans, {bool heading = false}) {
    return Padding(
      padding: EdgeInsets.only(top: heading ? 6 : 0, bottom: heading ? 10 : 12),
      child: Text.rich(
        TextSpan(
          children: spans,
          style: TextStyle(
            fontSize: heading ? 19 : 17,
            fontWeight: heading ? FontWeight.w700 : FontWeight.w400,
            height: 1.7,
            color: _ink,
          ),
        ),
      ),
    );
  }

  /// Blockquote: italic text with a red bar on the left.
  void _addQuote(dom.Element el, List<Widget> out) {
    final spans = <InlineSpan>[];
    _inline(el, spans, const TextStyle());
    if (_isBlank(spans)) return;

    out.add(
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF5F5),
          border: Border(left: BorderSide(color: _accent, width: 4)),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Text.rich(
          TextSpan(
            children: spans,
            style: const TextStyle(
              fontSize: 17,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: Color(0xFF3A3F4B),
            ),
          ),
        ),
      ),
    );
  }

  /// Preformatted code: monospace, kept as written, scrolls sideways if long.
  void _addCode(dom.Element el, List<Widget> out) {
    final code = el.text.replaceAll('\t', '    ').trimRight();
    if (code.trim().isEmpty) return;

    out.add(
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            code,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.5, color: _ink),
          ),
        ),
      ),
    );
  }

  /// Draws an HTML table as a bordered grid. Wide tables scroll sideways.
  void _addTable(dom.Element table, List<Widget> out) {
    final rowsData = <List<dom.Element>>[];
    for (final tr in table.querySelectorAll('tr')) {
      final cells = tr.children
          .where((c) => c.localName == 'td' || c.localName == 'th')
          .toList();
      if (cells.isNotEmpty) rowsData.add(cells);
    }
    if (rowsData.isEmpty) return;

    // Every row must have the same number of columns, so pad short rows.
    final columns = rowsData.map((r) => r.length).reduce((a, b) => a > b ? a : b);

    final rows = <TableRow>[];
    for (final cells in rowsData) {
      final isHeader = cells.every((c) => c.localName == 'th');
      rows.add(
        TableRow(
          decoration: isHeader ? BoxDecoration(color: Colors.grey.shade200) : null,
          children: [
            for (var i = 0; i < columns; i++)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  i < cells.length ? _clean(cells[i].text) : '',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: _ink,
                    fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    out.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: Colors.grey.shade400),
            children: rows,
          ),
        ),
      ),
    );
  }

  bool _isBlank(List<InlineSpan> spans) =>
      spans.map((s) => s.toPlainText()).join().trim().isEmpty;

  String _clean(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

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
