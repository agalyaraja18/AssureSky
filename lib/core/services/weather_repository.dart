import '../models/air_quality_model.dart';
import '../models/current_weather_model.dart';
import '../models/forecast_model.dart';
import 'weather_service.dart';

class WeatherData {
  final CurrentWeatherModel weather;
  final AirQualityModel airQuality;

  const WeatherData({required this.weather, required this.airQuality});
}

class WeatherRepository {
  final WeatherService _service;

  WeatherRepository() : _service = WeatherService();

  Future<WeatherData> getWeatherData(double lat, double lon) async {
    final results = await Future.wait([
      _service.getCurrentWeather(lat, lon),
      _service.getAirQuality(lat, lon),
    ]);

    final weather = results[0] as CurrentWeatherModel;
    final airQuality = results[1] as AirQualityModel;

    return WeatherData(weather: weather, airQuality: airQuality);
  }

  Future<ForecastModel> getForecast(double lat, double lon) =>
      _service.getForecast(lat, lon);

  Future<List<Map<String, dynamic>>> searchCity(String query) =>
      _service.searchCity(query);

  Future<String> reverseGeocode(double lat, double lon) =>
      _service.reverseGeocode(lat, lon);
}
