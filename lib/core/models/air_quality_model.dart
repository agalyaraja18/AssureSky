class AirQualityModel {
  /// AQI on OpenWeatherMap scale: 1 (Good) to 5 (Very Poor)
  final int aqiIndex;

  /// Converted AQI on 0–500 scale for display
  final int aqi500;

  final double pm25;
  final double pm10;
  final double no2;
  final double o3;

  const AirQualityModel({
    required this.aqiIndex,
    required this.aqi500,
    required this.pm25,
    required this.pm10,
    required this.no2,
    required this.o3,
  });

  String get qualityLabel {
    if (aqi500 <= 50) return 'Good';
    if (aqi500 <= 100) return 'Moderate';
    if (aqi500 <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi500 <= 200) return 'Unhealthy';
    if (aqi500 <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  String get shortQualityLabel {
    if (aqi500 <= 50) return 'Good';
    if (aqi500 <= 100) return 'Moderate';
    if (aqi500 <= 200) return 'Unhealthy';
    return 'Hazardous';
  }

  factory AirQualityModel.fromJson(Map<String, dynamic> json) {
    final list = json['list'][0];
    final main = list['main'];
    final components = list['components'];
    final aqiIndex = main['aqi'] as int;

    // Map OWM AQI 1-5 to 0-500 scale
    const aqiMap = {1: 25, 2: 75, 3: 125, 4: 175, 5: 350};
    final aqi500 = aqiMap[aqiIndex] ?? 0;

    return AirQualityModel(
      aqiIndex: aqiIndex,
      aqi500: aqi500,
      pm25: (components['pm2_5'] as num).toDouble(),
      pm10: (components['pm10'] as num).toDouble(),
      no2: (components['no2'] as num).toDouble(),
      o3: (components['o3'] as num).toDouble(),
    );
  }
}
