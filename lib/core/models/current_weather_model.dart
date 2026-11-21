import '../utils/city_time.dart';

class CurrentWeatherModel {
  final double temp;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final String condition;
  final int conditionCode;
  final String description;
  final String iconCode;
  final int humidity;

  /// Wind speed in km/h.
  final double windSpeed;
  final double uvIndex;
  final int pressure;
  final int visibility;

  /// Sunrise / sunset / observation time as *city wall-clock* times
  /// (see [CityTime]). They are in the searched city's timezone, not the
  /// phone's.
  final DateTime sunrise;
  final DateTime sunset;
  final String cityName;
  final String country;
  final DateTime dt;

  /// The city's offset from UTC in seconds (OpenWeatherMap `timezone`).
  final int utcOffsetSeconds;

  const CurrentWeatherModel({
    required this.temp,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
    required this.conditionCode,
    required this.description,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.pressure,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
    required this.cityName,
    required this.country,
    required this.dt,
    this.utcOffsetSeconds = 0,
  });

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final wind = json['wind'];
    final sys = json['sys'];
    final offset = (json['timezone'] as num?)?.toInt() ?? 0;

    return CurrentWeatherModel(
      temp: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      condition: weather['main'] as String,
      conditionCode: weather['id'] as int,
      description: weather['description'] as String,
      iconCode: weather['icon'] as String,
      humidity: main['humidity'] as int,
      windSpeed: ((wind?['speed'] as num?) ?? 0).toDouble() * 3.6, // m/s → km/h
      uvIndex: 0, // merged in from Open-Meteo (see copyWith)
      pressure: main['pressure'] as int,
      visibility: ((json['visibility'] as num?) ?? 10000).toInt(),
      sunrise: CityTime.fromEpoch((sys['sunrise'] as num).toInt(), offset),
      sunset: CityTime.fromEpoch((sys['sunset'] as num).toInt(), offset),
      cityName: json['name'] as String? ?? '',
      country: sys['country'] as String? ?? '',
      dt: CityTime.fromEpoch((json['dt'] as num).toInt(), offset),
      utcOffsetSeconds: offset,
    );
  }

  /// The current wall-clock time in this city.
  DateTime get cityNow => CityTime.now(utcOffsetSeconds);

  /// True when it is dark in the city right now. Compares time-of-day only, so
  /// it stays correct for slightly stale (cached) data.
  bool get isNight {
    int minutes(DateTime t) => t.hour * 60 + t.minute;
    final now = minutes(cityNow);
    final rise = minutes(sunrise);
    final set = minutes(sunset);
    if (rise == set) return false;
    return rise < set ? (now < rise || now >= set) : (now >= set && now < rise);
  }

  CurrentWeatherModel copyWith({double? uvIndex}) {
    return CurrentWeatherModel(
      temp: temp,
      feelsLike: feelsLike,
      tempMin: tempMin,
      tempMax: tempMax,
      condition: condition,
      conditionCode: conditionCode,
      description: description,
      iconCode: iconCode,
      humidity: humidity,
      windSpeed: windSpeed,
      uvIndex: uvIndex ?? this.uvIndex,
      pressure: pressure,
      visibility: visibility,
      sunrise: sunrise,
      sunset: sunset,
      cityName: cityName,
      country: country,
      dt: dt,
      utcOffsetSeconds: utcOffsetSeconds,
    );
  }
}
