// This file is only compiled on web via conditional import in article_webview.dart.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web implementation.
///
/// News sites universally block iframe embedding via X-Frame-Options / CSP,
/// so we cannot embed their pages. Instead we show a styled card that lets
/// the user open the article in a new browser tab — the natural behaviour
/// for a web-based app.
class ArticleWebView extends StatelessWidget {
  final String url;
  const ArticleWebView({super.key, required this.url});

  Future<void> _openInNewTab() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.open_in_new_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Article opens in a new tab',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'News websites prevent embedding in apps for security reasons. '
              'Tap below to read the full article in your browser.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _openInNewTab,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Read Full Article'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
