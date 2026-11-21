import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/map_weather_model.dart';
import '../models/place_model.dart';

/// Weather for many points at once (world map), using Open-Meteo's batch
/// endpoint (one request for dozens of places, no API key).
class MapWeatherService {
  /// Cached readings stay fresh this long.
  static const Duration ttl = Duration(minutes: 15);

  /// Maximum places per request, to keep the URL short.
  static const int batchSize = 50;

  static final Map<String, MapWeather> _memo = {};

  final Dio _dio;
  MapWeatherService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ));

  static String keyFor(double lat, double lon) =>
      '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';

  /// The cached reading for a point, if still fresh.
  static MapWeather? cached(double lat, double lon) {
    final w = _memo[keyFor(lat, lon)];
    if (w == null) return null;
    return DateTime.now().difference(w.fetchedAt) < ttl ? w : null;
  }

  /// Fetches weather for every place without a fresh cached reading and
  /// returns the places that were updated. Never throws; failed batches are
  /// skipped so the map keeps working with whatever data it has.
  Future<Map<String, MapWeather>> fetchFor(List<PlaceModel> places) async {
    final result = <String, MapWeather>{};
    final stale = <PlaceModel>[];
    for (final p in places) {
      final fresh = cached(p.lat, p.lon);
      if (fresh != null) {
        result[keyFor(p.lat, p.lon)] = fresh;
      } else {
        stale.add(p);
      }
    }
    for (var i = 0; i < stale.length; i += batchSize) {
      final chunk = stale.sublist(
          i, i + batchSize > stale.length ? stale.length : i + batchSize);
      try {
        final parsed = await _fetchBatch(chunk);
        for (var j = 0; j < chunk.length; j++) {
          final w = parsed[j];
          if (w == null) continue;
          final k = keyFor(chunk[j].lat, chunk[j].lon);
          _memo[k] = w;
          result[k] = w;
        }
      } catch (_) {
        // Offline or rate limited: leave these places without data.
      }
    }
    return result;
  }

  /// Weather for one arbitrary point (map tap). Null when unavailable.
  Future<MapWeather?> fetchPoint(double lat, double lon) async {
    final fresh = cached(lat, lon);
    if (fresh != null) return fresh;
    try {
      final parsed = await _fetchBatch([
        PlaceModel(name: '', lat: lat, lon: lon),
      ]);
      final w = parsed.first;
      if (w != null) _memo[keyFor(lat, lon)] = w;
      return w;
    } catch (_) {
      return null;
    }
  }

  Future<List<MapWeather?>> _fetchBatch(List<PlaceModel> chunk) async {
    final response = await _dio.get(
      '${ApiConstants.openMeteoBaseUrl}${ApiConstants.openMeteoForecast}',
      queryParameters: {
        'latitude': chunk.map((p) => p.lat.toStringAsFixed(3)).join(','),
        'longitude': chunk.map((p) => p.lon.toStringAsFixed(3)).join(','),
        'current':
            'temperature_2m,weather_code,is_day,relative_humidity_2m,wind_speed_10m',
        'timezone': 'auto',
      },
    );
    return MapWeather.parseBatch(response.data, chunk.length);
  }

  /// Names a tapped point using OpenWeatherMap reverse geocoding. Returns null
  /// when there is no key or no named place nearby.
  Future<PlaceModel?> reverseGeocode(double lat, double lon) async {
    if (ApiConstants.owmApiKey.isEmpty) return null;
    try {
      final response = await _dio.get(
        '${ApiConstants.owmBaseUrl}${ApiConstants.reverseGeocoding}',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'limit': 1,
          'appid': ApiConstants.owmApiKey,
        },
      );
      final data = response.data;
      if (data is! List || data.isEmpty || data.first is! Map) return null;
      final m = data.first as Map;
      final name = m['name'] as String? ?? '';
      if (name.isEmpty) return null;
      return PlaceModel(
        name: name,
        admin1: m['state'] as String? ?? '',
        countryCode: m['country'] as String? ?? '',
        country: m['country'] as String? ?? '',
        lat: lat,
        lon: lon,
      );
    } catch (_) {
      return null;
    }
  }
}
