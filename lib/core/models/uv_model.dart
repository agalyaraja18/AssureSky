/// UV index data from Open-Meteo (free, no API key).
///
/// Requested with `timezone=GMT`, so every timestamp is UTC and can be matched
/// exactly against forecast hours in any city.
class UvModel {
  /// Current UV index (0–15+).
  final double current;

  /// Open-Meteo WMO weather code for "now". Codes 96 and 99 mean
  /// "thunderstorm with hail", which OpenWeatherMap has no code for.
  final int? weatherCode;

  /// Hourly UV index keyed by UTC epoch hour (hours since 1970-01-01T00:00Z).
  final Map<int, double> hourlyByEpochHour;

  const UvModel({
    required this.current,
    required this.weatherCode,
    required this.hourlyByEpochHour,
  });

  bool get hasHail => weatherCode == 96 || weatherCode == 99;

  factory UvModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>?;
    final hourly = json['hourly'] as Map<String, dynamic>?;

    final byHour = <int, double>{};
    if (hourly != null) {
      final times = (hourly['time'] as List?) ?? const [];
      final values = (hourly['uv_index'] as List?) ?? const [];
      for (int i = 0; i < times.length && i < values.length; i++) {
        final v = values[i];
        if (v is! num) continue;
        // "2026-05-18T14:00" is GMT; append Z so it parses as UTC.
        final t = DateTime.tryParse('${times[i]}Z');
        if (t == null) continue;
        byHour[t.millisecondsSinceEpoch ~/ 3600000] = v.toDouble();
      }
    }

    return UvModel(
      current: (current?['uv_index'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (current?['weather_code'] as num?)?.toInt(),
      hourlyByEpochHour: byHour,
    );
  }
}
