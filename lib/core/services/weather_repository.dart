import '../constants/app_constants.dart';
import '../models/air_quality_model.dart';
import '../models/current_weather_model.dart';
import '../models/forecast_model.dart';
import '../models/uv_model.dart';
import 'cache_service.dart';
import 'weather_service.dart';

/// Everything the home screen (and the alert engine) needs for one location.
class WeatherData {
  final CurrentWeatherModel weather;
  final AirQualityModel airQuality;

  /// Null when the forecast could not be loaded or parsed.
  final ForecastModel? forecast;

  /// Real UV data from Open-Meteo. Null when unavailable.
  final UvModel? uv;

  /// True when Open-Meteo reports thunderstorm-with-hail right now.
  final bool hasHail;

  /// True when the network failed and this came from the offline cache.
  final bool fromCache;
  final DateTime? cachedAt;

  const WeatherData({
    required this.weather,
    required this.airQuality,
    this.forecast,
    this.uv,
    this.hasHail = false,
    this.fromCache = false,
    this.cachedAt,
  });
}

/// A forecast plus whether it came from the offline cache.
class ForecastData {
  final ForecastModel forecast;
  final bool fromCache;
  final DateTime? cachedAt;
  const ForecastData(this.forecast, {this.fromCache = false, this.cachedAt});
}

class WeatherRepository {
  final WeatherService _service;
  final CacheService _cache;

  /// Last live forecast, so the Home and Forecast tabs don't each fetch it.
  /// Static because each screen creates its own [WeatherRepository].
  static _ForecastMemo? _memo;
  static const Duration _memoTtl = Duration(minutes: 2);

  WeatherRepository({WeatherService? service, CacheService? cache})
      : _service = service ?? WeatherService(),
        _cache = cache ?? CacheService();

  // ───────────────────────── current weather ─────────────────────────

  /// Loads current weather, air quality, UV and forecast for a location.
  /// Falls back to the offline cache if the network request fails.
  Future<WeatherData> getWeatherData(double lat, double lon) async {
    final weatherKey =
        CacheService.coordKey(AppConstants.cacheWeatherPrefix, lat, lon);
    final forecastKey =
        CacheService.coordKey(AppConstants.cacheForecastPrefix, lat, lon);

    try {
      // Current weather + air quality are required; forecast and UV are
      // "nice to have" and must never take the whole screen down.
      final results = await Future.wait<Object?>([
        _service.fetchCurrentJson(lat, lon),
        _service.fetchAirQualityJson(lat, lon),
        _tolerant(_service.fetchForecastJson(lat, lon)),
        _tolerant(_service.fetchUvJson(lat, lon)),
        _tolerant(_service.fetchDailyJson(lat, lon)),
      ]);

      final payload = <String, dynamic>{
        'weather': results[0],
        'air': results[1],
        'forecast': results[2],
        'uv': results[3],
        'daily': results[4],
      };

      final data = _build(payload, fromCache: false);

      await _cache.save(weatherKey, payload,
          prunePrefix: AppConstants.cacheWeatherPrefix);
      if (results[2] != null) {
        final forecastPayload = {
          'forecast': results[2],
          'uv': results[3],
          'daily': results[4],
        };
        await _cache.save(forecastKey, forecastPayload,
            prunePrefix: AppConstants.cacheForecastPrefix);
        if (data.forecast != null) {
          _memo = _ForecastMemo(forecastKey, ForecastData(data.forecast!));
        }
      }
      return data;
    } catch (_) {
      final cached = await _cache.load(weatherKey);
      if (cached != null) {
        try {
          return _build(
            Map<String, dynamic>.from(cached.data as Map),
            fromCache: true,
            cachedAt: cached.savedAt,
          );
        } catch (_) {
          // corrupt cache entry — surface the original network error below
        }
      }
      rethrow;
    }
  }

  // ───────────────────────────── forecast ────────────────────────────

  Future<ForecastData> getForecast(double lat, double lon) async {
    final key =
        CacheService.coordKey(AppConstants.cacheForecastPrefix, lat, lon);

    final memo = _memo;
    if (memo != null &&
        memo.key == key &&
        DateTime.now().difference(memo.at) < _memoTtl) {
      return memo.data;
    }

    try {
      final results = await Future.wait<Object?>([
        _service.fetchForecastJson(lat, lon),
        _tolerant(_service.fetchUvJson(lat, lon)),
        _tolerant(_service.fetchDailyJson(lat, lon)),
      ]);
      final forecastJson = results[0] as Map<String, dynamic>;
      final uvJson = results[1] as Map<String, dynamic>?;
      final dailyJson = results[2] as Map<String, dynamic>?;

      final data = ForecastData(_parseForecast(forecastJson, uvJson, dailyJson));
      await _cache.save(
          key, {'forecast': forecastJson, 'uv': uvJson, 'daily': dailyJson},
          prunePrefix: AppConstants.cacheForecastPrefix);
      _memo = _ForecastMemo(key, data);
      return data;
    } catch (_) {
      final cached = await _cache.load(key);
      if (cached != null) {
        try {
          final map = Map<String, dynamic>.from(cached.data as Map);
          return ForecastData(
            _parseForecast(
              Map<String, dynamic>.from(map['forecast'] as Map),
              map['uv'] == null
                  ? null
                  : Map<String, dynamic>.from(map['uv'] as Map),
              map['daily'] == null
                  ? null
                  : Map<String, dynamic>.from(map['daily'] as Map),
            ),
            fromCache: true,
            cachedAt: cached.savedAt,
          );
        } catch (_) {
          // fall through to rethrow
        }
      }
      rethrow;
    }
  }

  // ───────────────────────────── helpers ─────────────────────────────

  WeatherData _build(
    Map<String, dynamic> payload, {
    required bool fromCache,
    DateTime? cachedAt,
  }) {
    final uvJson = payload['uv'] == null
        ? null
        : Map<String, dynamic>.from(payload['uv'] as Map);
    final uv = _tryParse(() => UvModel.fromJson(uvJson!), uvJson != null);

    final weather = CurrentWeatherModel.fromJson(
            Map<String, dynamic>.from(payload['weather'] as Map))
        .copyWith(uvIndex: uv?.current);
    final airQuality = AirQualityModel.fromJson(
        Map<String, dynamic>.from(payload['air'] as Map));

    final forecastJson = payload['forecast'] == null
        ? null
        : Map<String, dynamic>.from(payload['forecast'] as Map);
    final dailyJson = payload['daily'] == null
        ? null
        : Map<String, dynamic>.from(payload['daily'] as Map);
    final forecast = _tryParse(
        () => _parseForecast(forecastJson!, uvJson, dailyJson),
        forecastJson != null);

    return WeatherData(
      weather: weather,
      airQuality: airQuality,
      forecast: forecast,
      uv: uv,
      hasHail: uv?.hasHail ?? false,
      fromCache: fromCache,
      cachedAt: cachedAt,
    );
  }

  ForecastModel _parseForecast(Map<String, dynamic> forecastJson,
      Map<String, dynamic>? uvJson, Map<String, dynamic>? dailyJson) {
    final uv = uvJson == null ? null : UvModel.fromJson(uvJson);
    return ForecastModel.fromJson(forecastJson).withUv(uv).withDaily(dailyJson);
  }

  T? _tryParse<T>(T Function() parse, bool condition) {
    if (!condition) return null;
    try {
      return parse();
    } catch (_) {
      return null;
    }
  }

  /// Awaits [future], returning null instead of throwing.
  Future<T?> _tolerant<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }
}

class _ForecastMemo {
  final String key;
  final ForecastData data;
  final DateTime at = DateTime.now();
  _ForecastMemo(this.key, this.data);
}
