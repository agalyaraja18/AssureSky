import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../models/news_article_model.dart';
import '../utils/weather_news_filter.dart';
import 'cache_service.dart';

/// Weather news plus whether it came from the offline cache.
class NewsResult {
  final List<NewsArticleModel> articles;
  final bool fromCache;
  final DateTime? cachedAt;
  const NewsResult(this.articles, {this.fromCache = false, this.cachedAt});
}

class NewsService {
  final Dio _dio;
  final CacheService _cache;

  NewsService({CacheService? cache})
      : _cache = cache ?? CacheService(),
        _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.newsBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  /// Fetches weather news, falling back to the last cached copy when the
  /// network fails. Throws only if there is no network *and* no cache.
  Future<NewsResult> getWeatherNews() async {
    try {
      // Require the word "weather" AND restrict matching to the title /
      // description so articles that merely mention a place are excluded.
      final response = await _dio.get(
        '/everything',
        queryParameters: {
          'q':
              'weather AND (monsoon OR rainfall OR cyclone OR heatwave OR storm OR hurricane OR typhoon OR flood OR forecast OR climate)',
          'searchIn': 'title,description',
          'language': 'en',
          'sortBy': 'publishedAt',
          'pageSize': 40,
        },
        options: Options(headers: {'X-Api-Key': ApiConstants.newsApiKey}),
      );

      final rawArticles = response.data['articles'] as List;
      await _cache.save(AppConstants.cacheNews, rawArticles);
      return NewsResult(_parse(rawArticles));
    } catch (_) {
      final cached = await _cache.load(AppConstants.cacheNews);
      if (cached != null) {
        try {
          return NewsResult(
            _parse(cached.data as List),
            fromCache: true,
            cachedAt: cached.savedAt,
          );
        } catch (_) {
          // corrupt cache — surface the original network error below
        }
      }
      rethrow;
    }
  }

  List<NewsArticleModel> _parse(List raw) => raw
      .map((e) => NewsArticleModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .where((a) =>
          a.title.isNotEmpty &&
          a.title != '[Removed]' &&
          a.description.isNotEmpty &&
          _isWeatherRelated(a))
      .toList();

  /// True only if the article's title or description contains at least one
  /// weather keyword — a safety net on top of the API query.
  bool _isWeatherRelated(NewsArticleModel article) =>
      WeatherNewsFilter.isWeatherNews(article.title, article.description);
}
