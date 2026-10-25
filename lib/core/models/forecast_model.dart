class ForecastDayModel {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final String condition;
  final int conditionCode;
  final String iconCode;
  final double rainChance;

  const ForecastDayModel({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.condition,
    required this.conditionCode,
    required this.iconCode,
    required this.rainChance,
  });
}

class HourlyForecastModel {
  final DateTime time;
  final double temp;
  final String condition;
  final int conditionCode;
  final String iconCode;
  final double uvIndex;

  const HourlyForecastModel({
    required this.time,
    required this.temp,
    required this.condition,
    required this.conditionCode,
    required this.iconCode,
    required this.uvIndex,
  });
}

class ForecastModel {
  final List<ForecastDayModel> daily;
  final List<HourlyForecastModel> hourly;

  const ForecastModel({required this.daily, required this.hourly});

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    final List list = json['list'] as List;

    // Parse all raw 3-hour entries into data points for interpolation
    final rawEntries = list.map((item) {
      final weather = item['weather'][0];
      return _RawForecastPoint(
        dt: DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000),
        temp: (item['main']['temp'] as num).toDouble(),
        condition: weather['main'] as String,
        conditionCode: weather['id'] as int,
        iconCode: weather['icon'] as String,
      );
    }).toList();

    // Build hourly list by interpolating 3-hour data into hourly data.
    // Generates 24 entries starting from the current hour.
    final now = DateTime.now();
    final startHour = DateTime(now.year, now.month, now.day, now.hour);

    final hourly = <HourlyForecastModel>[];
    for (int i = 0; i < 24; i++) {
      final targetTime = startHour.add(Duration(hours: i));

      // Find nearest raw entries before and after the target time
      _RawForecastPoint? before;
      _RawForecastPoint? after;
      for (final entry in rawEntries) {
        if (!entry.dt.isAfter(targetTime)) {
          before = entry;
        } else {
          after ??= entry;
        }
      }
      before ??= rawEntries.first;
      after ??= rawEntries.last;

      // Linear interpolation for temperature
      double temp;
      if (identical(before, after)) {
        temp = before.temp;
      } else {
        final span = after.dt.difference(before.dt).inSeconds;
        if (span == 0) {
          temp = before.temp;
        } else {
          final ratio = targetTime.difference(before.dt).inSeconds / span;
          temp =
              before.temp + (after.temp - before.temp) * ratio.clamp(0.0, 1.0);
        }
      }

      // Use nearest entry for condition and icon
      final nearest = targetTime.difference(before.dt).abs() <=
              after.dt.difference(targetTime).abs()
          ? before
          : after;

      // Adjust icon day/night suffix based on the interpolated hour
      final h = targetTime.hour;
      final isDayTime = h >= 6 && h < 18;
      String iconCode = nearest.iconCode;
      if (iconCode.isNotEmpty) {
        final lastChar = iconCode[iconCode.length - 1];
        if (isDayTime && lastChar == 'n') {
          iconCode = '${iconCode.substring(0, iconCode.length - 1)}d';
        } else if (!isDayTime && lastChar == 'd') {
          iconCode = '${iconCode.substring(0, iconCode.length - 1)}n';
        }
      }

      hourly.add(HourlyForecastModel(
        time: targetTime,
        temp: temp,
        condition: nearest.condition,
        conditionCode: nearest.conditionCode,
        iconCode: iconCode,
        uvIndex: 0,
      ));
    }

    // Group by day to build daily list
    final Map<String, List<dynamic>> grouped = {};
    for (final item in list) {
      final dt = DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
      final key = '${dt.year}-${dt.month}-${dt.day}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final daily = grouped.entries.take(7).map((entry) {
      final items = entry.value;
      final temps = items.map((i) => (i['main']['temp'] as num).toDouble()).toList();
      final rainChances = items.map((i) {
        final pop = (i['pop'] as num?)?.toDouble() ?? 0.0;
        return pop * 100;
      }).toList();

      // Pick the midday entry for condition icon
      final midItem = items[items.length ~/ 2];
      final weather = midItem['weather'][0];
      final dt = DateTime.fromMillisecondsSinceEpoch((items[0]['dt'] as int) * 1000);

      return ForecastDayModel(
        date: dt,
        tempMax: temps.reduce((a, b) => a > b ? a : b),
        tempMin: temps.reduce((a, b) => a < b ? a : b),
        condition: weather['main'] as String,
        conditionCode: weather['id'] as int,
        iconCode: weather['icon'] as String,
        rainChance: rainChances.reduce((a, b) => a > b ? a : b),
      );
    }).toList();

    return ForecastModel(daily: daily, hourly: hourly);
  }
}

/// Helper class for raw 3-hour forecast data points during hourly interpolation.
class _RawForecastPoint {
  final DateTime dt;
  final double temp;
  final String condition;
  final int conditionCode;
  final String iconCode;

  const _RawForecastPoint({
    required this.dt,
    required this.temp,
    required this.condition,
    required this.conditionCode,
    required this.iconCode,
  });
}
