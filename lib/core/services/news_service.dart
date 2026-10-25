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

  Future<List<NewsArticleModel>> getWeatherNews() async {
    final response = await _dio.get(
      '/everything',
      queryParameters: {
        'q': 'weather India',
        'language': 'en',
        'sortBy': 'publishedAt',
        'pageSize': 20,
      },
      options: Options(headers: {'X-Api-Key': ApiConstants.newsApiKey}),
    );

    final articles = (response.data['articles'] as List)
        .map((e) => NewsArticleModel.fromJson(e as Map<String, dynamic>))
        .where((a) =>
            a.title.isNotEmpty &&
            a.title != '[Removed]' &&
            a.description.isNotEmpty)
        .toList();

    return articles;
  }
}
