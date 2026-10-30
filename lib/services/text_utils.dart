import 'package:html/parser.dart' as parser;

/// Strips HTML tags and tidies spacing, for short previews.
String plainText(String html) {
  final body = parser.parse(html).body;
  return (body?.text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Turns a stored number like "0837 2 123456, 98450 00000" into a dialable one.
String dialable(String phone) {
  final first = phone.split(RegExp(r'[,/]')).first.trim();
  return first.replaceAll(RegExp(r'[^0-9+]'), '');
}
