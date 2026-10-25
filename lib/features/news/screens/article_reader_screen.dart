import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/article_webview.dart';

/// Full-screen in-app article reader backed by a WebView.
class ArticleReaderScreen extends StatelessWidget {
  final String url;
  final String title;

  const ArticleReaderScreen({
    super.key,
    required this.url,
    required this.title,
  });

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInBrowser,
            tooltip: 'Open in browser',
          ),
        ],
      ),
      body: ArticleWebView(url: url),
    );
  }
}
