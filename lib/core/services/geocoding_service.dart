import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/place_model.dart';

/// Worldwide place search (every city, town and village — not just capitals),
/// backed by Open-Meteo's free geocoding API.
class GeocodingService {
  /// The API returns nothing useful for a single character.
  static const int minQueryLength = 2;

  final Dio _dio;

  GeocodingService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.openMeteoGeocodingBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ));

  Future<List<PlaceModel>> search(String query, {int count = 20}) async {
    final q = query.trim();
    if (q.length < minQueryLength) return const [];

    final response = await _dio.get(
      ApiConstants.openMeteoSearch,
      queryParameters: {
        'name': q,
        'count': count,
        'language': 'en',
        'format': 'json',
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) return const [];
    final results = data['results'];
    if (results is! List) return const []; // no matches → key is omitted

    return results
        .whereType<Map<String, dynamic>>()
        .where((r) => r['latitude'] is num && r['longitude'] is num)
        .map(PlaceModel.fromOpenMeteo)
        .where((p) => p.name.isNotEmpty)
        .toList();
  }
}
