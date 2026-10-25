import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/news_article_model.dart';

class NewsService {
  final Dio _dio;

  NewsService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.newsBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  /// Weather-related keywords used to both query NewsAPI and to filter
  /// the returned articles so only genuinely weather-related news is shown.
  static const List<String> _weatherKeywords = [
    'weather',
    'rain',
    'rainfall',
    'monsoon',
    'cyclone',
    'storm',
    'thunderstorm',
    'heatwave',
    'heat wave',
    'cold wave',
    'temperature',
    'forecast',
    'climate',
    'flood',
    'humidity',
    'snow',
    'snowfall',
    'drought',
    'imd',
    'meteorolog', // matches meteorology / meteorological
  ];

  Future<List<NewsArticleModel>> getWeatherNews() async {
    // Require the word "weather" AND restrict matching to the title/description
    // so articles that merely mention India (but aren't about weather) are
    // excluded by the API itself.
    final response = await _dio.get(
      '/everything',
      queryParameters: {
        'q':
            'weather AND (India OR monsoon OR rainfall OR cyclone OR heatwave OR IMD OR forecast)',
        'searchIn': 'title,description',
        'language': 'en',
        'sortBy': 'publishedAt',
        'pageSize': 40,
      },
      options: Options(headers: {'X-Api-Key': ApiConstants.newsApiKey}),
    );

    final articles = (response.data['articles'] as List)
        .map((e) => NewsArticleModel.fromJson(e as Map<String, dynamic>))
        .where((a) =>
            a.title.isNotEmpty &&
            a.title != '[Removed]' &&
            a.description.isNotEmpty &&
            _isWeatherRelated(a))
        .toList();

    return articles;
  }

  /// Returns true only if the article's title or description contains at
  /// least one weather-related keyword — a safety net on top of the API query.
  bool _isWeatherRelated(NewsArticleModel article) {
    final haystack = '${article.title} ${article.description}'.toLowerCase();
    return _weatherKeywords.any((kw) => haystack.contains(kw));
  }
}
