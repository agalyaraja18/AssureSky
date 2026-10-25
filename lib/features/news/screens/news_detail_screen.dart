import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/news_article_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import 'article_reader_screen.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsArticleModel article;
  const NewsDetailScreen({super.key, required this.article});

  Future<void> _openUrl() async {
    final uri = Uri.parse(article.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather News'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openUrl,
            tooltip: 'Open in browser',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            if (article.urlToImage != null)
              CachedNetworkImage(
                imageUrl: article.urlToImage!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 220,
                  color: AppColors.accent.withValues(alpha: 0.1),
                  child: const Center(
                      child: Text('🌤️', style: TextStyle(fontSize: 60))),
                ),
              )
            else
              Container(
                height: 180,
                color: AppColors.accent.withValues(alpha: 0.1),
                child: const Center(
                    child: Text('🌤️', style: TextStyle(fontSize: 60))),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source & time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.sourceName,
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.relativeTime(article.publishedAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(article.title,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    article.description,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 8),

                  // Content (truncated by NewsAPI, show what we have)
                  if (article.content.isNotEmpty)
                    Text(
                      article.content.replaceAll(
                          RegExp(r'\[\+\d+ chars\]'), ''),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(height: 1.6),
                    ),

                  const SizedBox(height: 24),

                  // Read full article button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (kIsWeb) {
                          // On web, iframes are blocked by X-Frame-Options on
                          // most news sites — open directly in a new tab.
                          final uri = Uri.parse(article.url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        } else {
                          // On mobile, use the in-app WebView reader.
                          if (context.mounted) {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ArticleReaderScreen(
                                url: article.url,
                                title: article.title,
                              ),
                            ));
                          }
                        }
                      },
                      icon: Icon(
                          kIsWeb ? Icons.open_in_new_rounded : Icons.menu_book),
                      label: const Text('Read Full Article'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
