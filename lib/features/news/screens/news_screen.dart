import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/news_article_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../home/bloc/home_bloc.dart';
import '../bloc/news_bloc.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late NewsBloc _newsBloc;

  @override
  void initState() {
    super.initState();
    _newsBloc = NewsBloc()..add(NewsLoadRequested());
  }

  @override
  void dispose() {
    _newsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeState = context.read<HomeBloc>().state;
    final cityName = homeState is HomeLoaded ? homeState.cityName : '';

    return BlocProvider.value(
      value: _newsBloc,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Weather News',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (cityName.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.location_on,
                            color: AppColors.accent, size: 16),
                        const SizedBox(width: 4),
                        Text(cityName,
                            style: theme.textTheme.titleMedium),
                      ]),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<NewsBloc, NewsState>(
                  builder: (context, state) {
                    if (state is NewsLoading || state is NewsInitial) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent));
                    }
                    if (state is NewsError) {
                      return _ErrorView(
                        message: state.message,
                        onRetry: () =>
                            _newsBloc.add(NewsLoadRequested()),
                      );
                    }
                    if (state is NewsLoaded) {
                      return _ArticleList(articles: state.articles);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleList extends StatelessWidget {
  final List<NewsArticleModel> articles;
  const _ArticleList({required this.articles});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async =>
          context.read<NewsBloc>().add(NewsRefreshRequested()),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Latest updates · ${articles.length} articles',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          ...articles.map((a) => _ArticleCard(article: a)),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final NewsArticleModel article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NewsDetailScreen(article: article))),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: article.urlToImage != null
                    ? CachedNetworkImage(
                        imageUrl: article.urlToImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _ImagePlaceholder(),
                      )
                    : _ImagePlaceholder(),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            article.sourceName,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormatter.relativeTime(
                              article.publishedAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Read →',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text('🌤️', style: TextStyle(fontSize: 28)),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📰', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
