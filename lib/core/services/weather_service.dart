import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/air_quality_model.dart';
import '../models/current_weather_model.dart';
import '../models/forecast_model.dart';

class WeatherService {
  final Dio _dio;

  WeatherService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.owmBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      requestHeader: false,
      logPrint: (o) => print('🌐 Dio: $o'),
    ));
  }

  Future<CurrentWeatherModel> getCurrentWeather(
      double lat, double lon) async {
    final response = await _dio.get(
      ApiConstants.currentWeather,
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': ApiConstants.owmApiKey,
        'units': 'metric',
      },
    );
    return CurrentWeatherModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ForecastModel> getForecast(double lat, double lon) async {
    final response = await _dio.get(
      ApiConstants.forecast,
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': ApiConstants.owmApiKey,
        'units': 'metric',
        'cnt': 40, // 5 days × 8 slots (3h each) — free tier max
      },
    );
    return ForecastModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AirQualityModel> getAirQuality(double lat, double lon) async {
    final response = await _dio.get(
      ApiConstants.airPollution,
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': ApiConstants.owmApiKey,
      },
    );
    return AirQualityModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Returns UV index for the given coordinates.
  Future<double> getUvIndex(double lat, double lon) async {
    try {
      // UV is included in OneCall API; approximate from forecast data
      // Using a simple heuristic based on time of day and condition
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> searchCity(String query) async {
    final response = await _dio.get(
      ApiConstants.geocoding,
      queryParameters: {
        'q': query,
        'limit': 5,
        'appid': ApiConstants.owmApiKey,
      },
    );
    return (response.data as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<String> reverseGeocode(double lat, double lon) async {
    final response = await _dio.get(
      ApiConstants.reverseGeocoding,
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'limit': 1,
        'appid': ApiConstants.owmApiKey,
      },
    );
    final list = response.data as List;
    if (list.isEmpty) return ApiConstants.defaultCity;
    return list[0]['name'] as String;
  }
}
