import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

/// Shows article HTML the way the website does: paragraphs, headings,
/// numbered and bulleted lists (with nesting), bold, italic, underline,
/// highlights, strikethrough, tappable links, quotes, code, photos, tables
/// and YouTube videos. Scripts, iframes other than YouTube and website
/// styling are not run.
class ArticleBody extends StatelessWidget {
  final String html;

  const ArticleBody({super.key, required this.html});

  /// Elements that start a new line of text.
  static const _textBlocks = {'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'dt', 'dd'};

  /// Elements that break the line when they appear inside other text.
  static const _lineBreakers = {
    'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'div', 'figcaption', 'dt', 'dd',
    'section', 'article', 'header', 'footer', 'address', 'blockquote', 'pre', 'ul', 'ol',
  };

  static const _skipTags = {
    'script', 'style', 'noscript', 'button', 'form', 'input', 'select', 'textarea', 'svg', 'canvas',
  };

  static const _ink = Color(0xFF1A1D23);
  static const _muted = Color(0xFF5B616E);
  static const _accent = Color(0xFFB71C1C);

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
      if (text.isNotEmpty) out.add(_paragraph([TextSpan(text: text)]));
      return;
    }
    if (node is! dom.Element) return;

    final tag = node.localName ?? '';
    if (_skipTags.contains(tag)) return;

    switch (tag) {
      case 'img':
        _addImage(node, out);
        return;
      case 'iframe':
        _addVideo(node, out);
        return;
      case 'table':
        _addTable(node, out);
        return;
      case 'ul':
      case 'ol':
        _addList(node, out);
        return;
      case 'blockquote':
        _addQuote(node, out);
        return;
      case 'pre':
        _addCode(node, out);
        return;
      case 'hr':
        out.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1),
        ));
        return;
      case 'figcaption':
        _addCaption(node, out);
        return;
    }

    if (_textBlocks.contains(tag)) {
      final spans = <InlineSpan>[];
      _inline(node, spans, const TextStyle());
      if (!_isBlank(spans)) out.add(_paragraph(spans, level: _headingLevel(tag)));
      for (final img in node.querySelectorAll('img')) {
        _addImage(img, out);
      }
      return;
    }

    // Containers such as div, figure, section: look inside them.
    for (final child in node.nodes) {
      _collect(child, out);
    }
  }

  int _headingLevel(String tag) => switch (tag) {
        'h1' => 1,
        'h2' => 2,
        'h3' => 3,
        'h4' || 'h5' || 'h6' => 4,
        _ => 0,
      };

  /// A paragraph or heading. Spacing follows the website's reading rhythm.
  Widget _paragraph(List<InlineSpan> spans, {int level = 0}) {
    final style = switch (level) {
      1 => const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3),
      2 => const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 1.35),
      3 => const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.4),
      4 => const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.4),
      _ => const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.75),
    };
    final heading = level > 0;
    return Padding(
      padding: EdgeInsets.only(top: heading ? 16 : 0, bottom: heading ? 8 : 14),
      child: Text.rich(
        TextSpan(
          style: style.copyWith(color: _ink),
          children: spans,
        ),
      ),
    );
  }

  /// Turns inline content (text, bold, italic, links, line breaks) into spans.
  void _inline(
    dom.Node node,
    List<InlineSpan> out,
    TextStyle style, {
    bool skipLists = false,
  }) {
    for (final child in node.nodes) {
      if (child is dom.Text) {
        final text = child.data.replaceAll(RegExp(r'\s+'), ' ');
        if (text.isNotEmpty) out.add(TextSpan(text: text, style: style));
        continue;
      }
      if (child is! dom.Element) continue;

      final tag = child.localName ?? '';
      if (_skipTags.contains(tag) || tag == 'img' || tag == 'iframe') continue;
      if (skipLists && (tag == 'ul' || tag == 'ol')) continue;

      if (tag == 'br') {
        out.add(TextSpan(text: '\n', style: style));
        continue;
      }

      var s = style;
      switch (tag) {
        case 'strong':
        case 'b':
          s = s.copyWith(fontWeight: FontWeight.w700);
        case 'em':
        case 'i':
        case 'cite':
        case 'dfn':
          s = s.copyWith(fontStyle: FontStyle.italic);
        case 'u':
        case 'ins':
          s = s.copyWith(decoration: TextDecoration.underline);
        case 's':
        case 'del':
        case 'strike':
          s = s.copyWith(decoration: TextDecoration.lineThrough);
        case 'mark':
          s = s.copyWith(backgroundColor: const Color(0xFFFFF59D));
        case 'code':
        case 'kbd':
        case 'samp':
        case 'tt':
          s = s.copyWith(fontFamily: 'monospace', backgroundColor: const Color(0xFFF1F2F4));
        case 'small':
          s = s.copyWith(fontSize: 14);
        case 'sub':
        case 'sup':
          s = s.copyWith(fontSize: 12);
        case 'a':
          s = s.copyWith(color: _accent, decoration: TextDecoration.underline);
      }

      // A block element inside running text starts on a new line.
      if (_lineBreakers.contains(tag) && out.isNotEmpty) {
        out.add(TextSpan(text: '\n', style: style));
      }

      final inner = <InlineSpan>[];
      _inline(child, inner, s, skipLists: skipLists);

      final href = tag == 'a' ? child.attributes['href'] : null;
      final isWebLink = href != null && href.startsWith('http');
      final isQuote = tag == 'q';

      if (isQuote) out.add(TextSpan(text: '“', style: s));
      out.add(
        TextSpan(
          children: inner,
          style: s,
          recognizer: isWebLink
              ? (TapGestureRecognizer()..onTap = () => _open(href))
              : null,
        ),
      );
      if (isQuote) out.add(TextSpan(text: '”', style: s));
    }
  }

  /// Bulleted and numbered lists, including lists nested inside other lists.
  void _addList(dom.Element list, List<Widget> out, {int depth = 0}) {
    final ordered = list.localName == 'ol';
    var number = int.tryParse(list.attributes['start'] ?? '') ?? 1;

    for (final li in list.children.where((c) => c.localName == 'li')) {
      final marker = ordered ? '${number++}.' : (depth.isEven ? '•' : '◦');
      final spans = <InlineSpan>[];
      _inline(li, spans, const TextStyle(), skipLists: true);

      if (!_isBlank(spans)) {
        out.add(
          Padding(
            padding: EdgeInsets.only(left: 4.0 + depth * 18, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: ordered ? 30 : 18,
                  child: Text(
                    marker,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.75,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 17, height: 1.75, color: _ink),
                      children: spans,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      for (final img in li.children.where((c) => c.localName == 'img')) {
        _addImage(img, out);
      }
      for (final nested in li.children.where((c) => c.localName == 'ul' || c.localName == 'ol')) {
        _addList(nested, out, depth: depth + 1);
      }
    }
  }

  /// Blockquote: italic text with a red bar on the left.
  void _addQuote(dom.Element el, List<Widget> out) {
    final spans = <InlineSpan>[];
    _inline(el, spans, const TextStyle());
    if (_isBlank(spans)) return;

    out.add(
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6F6),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: 4, child: ColoredBox(color: _accent)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.65,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF3A3F4B),
                      ),
                      children: spans,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Caption under a photo.
  void _addCaption(dom.Element el, List<Widget> out) {
    final spans = <InlineSpan>[];
    _inline(el, spans, const TextStyle());
    if (_isBlank(spans)) return;
    out.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 16),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13, height: 1.5, color: _muted),
            children: spans,
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
        margin: const EdgeInsets.only(bottom: 16),
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

  /// YouTube embeds become a "Watch video" button that opens the video.
  void _addVideo(dom.Element frame, List<Widget> out) {
    final src = frame.attributes['src'] ?? '';
    final match = RegExp(r'(?:youtube(?:-nocookie)?\.com/embed/|youtu\.be/)([\w-]{6,})')
        .firstMatch(src);
    final watch = match != null
        ? 'https://www.youtube.com/watch?v=${match.group(1)}'
        : (src.startsWith('http') ? src : null);
    if (watch == null) return;

    out.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTap: () => _open(watch),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.play_circle_fill, color: _accent, size: 36),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Watch video',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _ink),
                  ),
                ),
                Icon(Icons.open_in_new, color: _muted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isBlank(List<InlineSpan> spans) =>
      spans.map((s) => s.toPlainText()).join().trim().isEmpty;

  String _clean(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

  Future<void> _open(String? url) async {
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Photo at its natural shape, full width. Small icons are skipped.
  void _addImage(dom.Element img, List<Widget> out) {
    final src = img.attributes['src'] ?? img.attributes['data-src'];
    if (src == null || !src.startsWith('http')) return;
    final width = int.tryParse(img.attributes['width'] ?? '');
    if (width != null && width < 80) return;

    out.add(
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: src,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            placeholder: (_, __) => Container(height: 200, color: const Color(0xFFEFF0F2)),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
