import '../models/forecast_model.dart';
import 'asky_engine.dart';
import 'weather_alert_engine.dart';
import 'weather_repository.dart';

/// Derives the "smart" parts of the app (Asky advice, alerts) from a
/// [WeatherData]. Shared by the home screen and the notification worker so
/// both always agree.
class WeatherInsights {
  WeatherInsights._();

  static AskyResult asky(WeatherData data) {
    final w = data.weather;
    return AskyEngine.getTips(AskyEngine.buildInput(
      conditionCode: w.conditionCode,
      temperature: w.temp,
      uvIndex: w.uvIndex,
      aqi: data.airQuality.aqi500,
      humidity: w.humidity,
      windKmh: w.windSpeed,
      isHail: data.hasHail,
      visibilityMeters: w.visibility,
      localHour: w.cityNow.hour,
    ));
  }

  static List<WeatherAlert> alerts(WeatherData data) =>
      WeatherAlertEngine.evaluate(
        weather: data.weather,
        airQuality: data.airQuality,
        forecast: data.forecast,
        hasHail: data.hasHail,
      );

  /// Today's entry from the forecast, if there is one.
  static ForecastDayModel? today(ForecastModel? forecast) =>
      (forecast == null || forecast.daily.isEmpty) ? null : forecast.daily.first;
}
