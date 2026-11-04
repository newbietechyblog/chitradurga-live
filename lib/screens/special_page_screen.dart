import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/special.dart';
import '../services/links.dart';

/// Opens a special page inside the app, so its buttons and forms work.
/// Back goes to the previous page inside it first, then closes this screen.
class SpecialPageScreen extends StatefulWidget {
  final SpecialPage page;

  const SpecialPageScreen({super.key, required this.page});

  @override
  State<SpecialPageScreen> createState() => _SpecialPageScreenState();
}

class _SpecialPageScreenState extends State<SpecialPageScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (uri.scheme == 'http' || uri.scheme == 'https') {
              return NavigationDecision.navigate;
            }
            // Phone calls, email and other apps open outside the page.
            _openOutside(uri);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.page.url));
  }

  Future<void> _openOutside(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing on the phone can open this link; leave the page as it is.
    }
  }

  Future<void> _onBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.page.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          actions: [
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => sharePost(widget.page.title, widget.page.url),
            ),
            IconButton(
              tooltip: 'Open in browser',
              icon: const Icon(Icons.open_in_browser),
              onPressed: () => openInBrowser(context, widget.page.url),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_progress < 100)
              LinearProgressIndicator(value: _progress == 0 ? null : _progress / 100, minHeight: 2),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
