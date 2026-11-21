import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Raw network access for weather data.
///
/// Every method returns the decoded JSON map rather than a model, so the
/// repository can both parse it and store it in the offline cache.
class WeatherService {
  final Dio _owm;
  final Dio _openMeteo;

  WeatherService()
      : _owm = Dio(BaseOptions(
          baseUrl: ApiConstants.owmBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )),
        _openMeteo = Dio(BaseOptions(
          baseUrl: ApiConstants.openMeteoBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  // NOTE: deliberately no request-logging interceptor — it would print the
  // full URL, including the OpenWeatherMap API key, to the device log.

  Future<Map<String, dynamic>> fetchCurrentJson(double lat, double lon) async {
    final response = await _owm.get(
      ApiConstants.currentWeather,
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': ApiConstants.owmApiKey,
        'units': 'metric',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchForecastJson(double lat, double lon) async {
    final response = await _owm.get(
      ApiConstants.forecast,
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': ApiConstants.owmApiKey,
        'units': 'metric',
        'cnt': 40, // 5 days × 8 slots (3h each) — free tier max
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchAirQualityJson(
      double lat, double lon) async {
    final response = await _owm.get(
      ApiConstants.airPollution,
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': ApiConstants.owmApiKey,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Real UV index (current + hourly) and the WMO weather code (used to detect
  /// hail) from Open-Meteo. Free, no API key. `timezone=GMT` keeps every
  /// timestamp in UTC so it lines up with any city's forecast hours.
  /// Seven days of daily highs/lows, conditions and rain chance in the city's
  /// own timezone (OpenWeatherMap's free forecast only covers ~5 days).
  Future<Map<String, dynamic>> fetchDailyJson(double lat, double lon) async {
    final response = await _openMeteo.get(
      ApiConstants.openMeteoForecast,
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'forecast_days': 7,
        'timezone': 'auto',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchUvJson(double lat, double lon) async {
    final response = await _openMeteo.get(
      ApiConstants.openMeteoForecast,
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'current': 'uv_index,weather_code',
        'hourly': 'uv_index',
        'forecast_days': 3,
        'timezone': 'GMT',
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
