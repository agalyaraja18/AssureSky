import '../utils/city_time.dart';
import '../utils/wmo_weather.dart';

/// Current conditions for one point on the world map.
class MapWeather {
  final double tempC;
  final int weatherCode;
  final bool isDay;
  final int humidity;
  final double windKmh;
  final int utcOffsetSeconds;
  final DateTime fetchedAt;

  const MapWeather({
    required this.tempC,
    required this.weatherCode,
    required this.isDay,
    required this.humidity,
    required this.windKmh,
    required this.utcOffsetSeconds,
    required this.fetchedAt,
  });

  String get emoji => WmoWeather.emoji(weatherCode, isDay: isDay);
  String get label => WmoWeather.label(weatherCode);

  /// Wall-clock time at the place right now (UTC-flagged, see [CityTime]).
  DateTime get localNow => CityTime.now(utcOffsetSeconds);

  /// Parses one Open-Meteo forecast object (`current` + `utc_offset_seconds`).
  /// Returns null when the object has no usable current data.
  static MapWeather? fromOpenMeteo(Object? json, {DateTime? now}) {
    if (json is! Map) return null;
    final cur = json['current'];
    if (cur is! Map) return null;
    final temp = cur['temperature_2m'];
    final code = cur['weather_code'];
    if (temp is! num || code is! num) return null;
    return MapWeather(
      tempC: temp.toDouble(),
      weatherCode: code.toInt(),
      isDay: (cur['is_day'] as num? ?? 1) == 1,
      humidity: (cur['relative_humidity_2m'] as num? ?? 0).round(),
      windKmh: (cur['wind_speed_10m'] as num? ?? 0).toDouble(),
      utcOffsetSeconds: (json['utc_offset_seconds'] as num? ?? 0).toInt(),
      fetchedAt: now ?? DateTime.now(),
    );
  }

  /// Open-Meteo returns a JSON array for several locations and a single object
  /// for one location. Always returns one entry per requested location, with
  /// null for any that could not be parsed.
  static List<MapWeather?> parseBatch(Object? decoded, int expected,
      {DateTime? now}) {
    final items = decoded is List ? decoded : [decoded];
    return List<MapWeather?>.generate(expected, (i) {
      if (i >= items.length) return null;
      return fromOpenMeteo(items[i], now: now);
    });
  }
}
