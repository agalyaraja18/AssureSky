import '../utils/city_time.dart';
import '../utils/wmo_weather.dart';
import 'uv_model.dart';

class ForecastDayModel {
  /// City wall-clock date (see [CityTime]).
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
  /// City wall-clock time (see [CityTime]).
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

  HourlyForecastModel copyWith({double? uvIndex}) => HourlyForecastModel(
        time: time,
        temp: temp,
        condition: condition,
        conditionCode: conditionCode,
        iconCode: iconCode,
        uvIndex: uvIndex ?? this.uvIndex,
      );
}

class ForecastModel {
  final List<ForecastDayModel> daily;
  final List<HourlyForecastModel> hourly;

  /// The city's offset from UTC in seconds.
  final int utcOffsetSeconds;

  const ForecastModel({
    required this.daily,
    required this.hourly,
    this.utcOffsetSeconds = 0,
  });

  /// Returns a copy whose hourly entries carry the real UV index from
  /// Open-Meteo. Hours with no UV data keep their current value.
  ForecastModel withUv(UvModel? uv) {
    if (uv == null || uv.hourlyByEpochHour.isEmpty) return this;
    return ForecastModel(
      daily: daily,
      utcOffsetSeconds: utcOffsetSeconds,
      hourly: hourly.map((h) {
        final key = CityTime.toEpochHour(h.time, utcOffsetSeconds);
        final value = uv.hourlyByEpochHour[key];
        return value == null ? h : h.copyWith(uvIndex: value);
      }).toList(),
    );
  }

  /// Replaces the daily list with Open-Meteo's 7-day forecast. OpenWeatherMap's
  /// free 3-hour forecast only spans ~5 days (6 calendar days at most), so the
  /// 7-day list comes from here. Returns this model unchanged when the data is
  /// missing or incomplete.
  ForecastModel withDaily(Map<String, dynamic>? json) {
    final d = json?['daily'];
    if (d is! Map) return this;
    final times = d['time'];
    final codes = d['weather_code'];
    final highs = d['temperature_2m_max'];
    final lows = d['temperature_2m_min'];
    final rain = d['precipitation_probability_max'];
    if (times is! List || codes is! List || highs is! List || lows is! List) {
      return this;
    }

    final days = <ForecastDayModel>[];
    for (var i = 0; i < times.length; i++) {
      final date = DateTime.tryParse('${times[i]}');
      if (date == null ||
          i >= codes.length ||
          i >= highs.length ||
          i >= lows.length ||
          codes[i] is! num ||
          highs[i] is! num ||
          lows[i] is! num) {
        continue;
      }
      final owm = WmoWeather.owmCode((codes[i] as num).toInt());
      final pop = (rain is List && i < rain.length && rain[i] is num)
          ? (rain[i] as num).toDouble()
          : 0.0;
      days.add(ForecastDayModel(
        date: DateTime.utc(date.year, date.month, date.day, 12),
        tempMax: (highs[i] as num).toDouble(),
        tempMin: (lows[i] as num).toDouble(),
        condition: WmoWeather.owmMain(owm),
        conditionCode: owm,
        iconCode: owm == 800 ? '01d' : (owm >= 500 && owm < 600 ? '10d' : '03d'),
        rainChance: pop,
      ));
    }
    if (days.length < 5) return this; // not usable, keep the 5-day list

    return ForecastModel(
      daily: days,
      hourly: hourly,
      utcOffsetSeconds: utcOffsetSeconds,
    );
  }

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    final List list = json['list'] as List;
    final offset =
        ((json['city'] as Map<String, dynamic>?)?['timezone'] as num?)
                ?.toInt() ??
            0;

    DateTime cityTime(dynamic item) =>
        CityTime.fromEpoch((item['dt'] as num).toInt(), offset);

    // Parse all raw 3-hour entries into data points for interpolation
    final rawEntries = list.map((item) {
      final weather = item['weather'][0];
      return _RawForecastPoint(
        dt: cityTime(item),
        temp: (item['main']['temp'] as num).toDouble(),
        condition: weather['main'] as String,
        conditionCode: weather['id'] as int,
        iconCode: weather['icon'] as String,
      );
    }).toList();

    // Build hourly list by interpolating 3-hour data into hourly data.
    // Generates 24 entries starting from the current hour *in the city*.
    final now = CityTime.now(offset);
    final startHour = DateTime.utc(now.year, now.month, now.day, now.hour);

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
        uvIndex: 0, // merged in from Open-Meteo via withUv()
      ));
    }

    // Group by city-local day to build daily list
    final Map<String, List<dynamic>> grouped = {};
    for (final item in list) {
      final dt = cityTime(item);
      final key = '${dt.year}-${dt.month}-${dt.day}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final daily = grouped.entries.take(7).map((entry) {
      final items = entry.value;
      final temps =
          items.map((i) => (i['main']['temp'] as num).toDouble()).toList();
      final rainChances = items.map((i) {
        final pop = (i['pop'] as num?)?.toDouble() ?? 0.0;
        return pop * 100;
      }).toList();

      // Pick the midday entry for condition icon
      final midItem = items[items.length ~/ 2];
      final weather = midItem['weather'][0];
      final dt = cityTime(items[0]);

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

    return ForecastModel(
        daily: daily, hourly: hourly, utcOffsetSeconds: offset);
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
