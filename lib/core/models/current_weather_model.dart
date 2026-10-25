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
  final double windSpeed;
  final double uvIndex;
  final int pressure;
  final int visibility;
  final DateTime sunrise;
  final DateTime sunset;
  final String cityName;
  final String country;
  final DateTime dt;

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
  });

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final wind = json['wind'];
    final sys = json['sys'];

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
      windSpeed: ((wind['speed'] as num?) ?? 0).toDouble() * 3.6, // m/s → km/h
      uvIndex: 0, // fetched separately
      pressure: main['pressure'] as int,
      visibility: ((json['visibility'] as num?) ?? 10000).toInt(),
      sunrise: DateTime.fromMillisecondsSinceEpoch(
          (sys['sunrise'] as int) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch(
          (sys['sunset'] as int) * 1000),
      cityName: json['name'] as String,
      country: sys['country'] as String,
      dt: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
    );
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
    );
  }
}
