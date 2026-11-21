import '../utils/weather_classifier.dart';

class AskyTip {
  final String icon; // emoji icon
  final String text;
  const AskyTip({required this.icon, required this.text});
}

class AskyResult {
  final String primaryAdvice;
  final List<AskyTip> tips;
  const AskyResult({required this.primaryAdvice, required this.tips});
}

class WeatherInput {
  final int conditionCode;
  final double temperature; // Celsius
  final double uvIndex;
  final int aqi; // 0–500 scale
  final int humidity;
  final String timeOfDay; // morning, afternoon, evening, night
  final double windKmh;
  final bool isHail;
  final int visibilityMeters;

  const WeatherInput({
    required this.conditionCode,
    required this.temperature,
    required this.uvIndex,
    required this.aqi,
    required this.humidity,
    required this.timeOfDay,
    this.windKmh = 0,
    this.isHail = false,
    this.visibilityMeters = 10000,
  });
}

class AskyEngine {
  static AskyResult getTips(WeatherInput input) {
    // Priority order: life-threatening (tornado/cyclone/hail/thunderstorm) >
    // AQI > Fog > Snow/other low-visibility > Rain > Drizzle > Hot&Sunny >
    // Warm&Sunny > Cold > Cloudy

    // Rule 0a: Tornado
    if (WeatherClassifier.isTornado(input.conditionCode)) {
      return const AskyResult(
        primaryAdvice:
            'Tornado conditions! Take shelter immediately and stay away from windows.',
        tips: [
          AskyTip(icon: '🏠', text: 'Go to the lowest floor, in an interior room'),
          AskyTip(icon: '🪟', text: 'Stay away from windows and glass'),
          AskyTip(icon: '🚗', text: 'Do not try to outrun it in a vehicle'),
          AskyTip(icon: '📻', text: 'Follow official local alerts and instructions'),
          AskyTip(icon: '🔋', text: 'Keep your phone charged and a torch ready'),
        ],
      );
    }

    // Rule 0b: Cyclone / hurricane-force storm
    if (WeatherClassifier.isCyclone(input.conditionCode, input.windKmh)) {
      return const AskyResult(
        primaryAdvice:
            'Cyclone-force winds and rain. Stay indoors and avoid all travel.',
        tips: [
          AskyTip(icon: '🏠', text: 'Stay indoors, away from windows'),
          AskyTip(icon: '🚫', text: 'Avoid the coast, rivers and low-lying areas'),
          AskyTip(icon: '🔦', text: 'Keep torches, water and essentials ready'),
          AskyTip(icon: '🔌', text: 'Unplug electronics to avoid surge damage'),
          AskyTip(icon: '📻', text: 'Follow official cyclone warnings'),
        ],
      );
    }

    // Rule 0c: Hail
    if (input.isHail) {
      return const AskyResult(
        primaryAdvice:
            'Hailstorm! Get under cover — hail can hurt people and damage cars.',
        tips: [
          AskyTip(icon: '🏠', text: 'Shelter indoors until it passes'),
          AskyTip(icon: '🚗', text: 'Move your vehicle under cover if you can'),
          AskyTip(icon: '🪟', text: 'Stay away from windows and skylights'),
          AskyTip(icon: '🧢', text: 'If caught outside, protect your head'),
          AskyTip(icon: '🌳', text: 'Do not shelter under trees'),
        ],
      );
    }

    // Rule 0d: Thunderstorm
    if (WeatherClassifier.isThunderstorm(input.conditionCode)) {
      return const AskyResult(
        primaryAdvice:
            'Thunderstorm in the area. Stay indoors and away from open ground.',
        tips: [
          AskyTip(icon: '🏠', text: 'Stay indoors until the storm passes'),
          AskyTip(icon: '⚡', text: 'Avoid open fields, hilltops and tall trees'),
          AskyTip(icon: '🔌', text: 'Unplug sensitive electronics'),
          AskyTip(icon: '🚿', text: 'Avoid showers and taps during lightning'),
          AskyTip(icon: '☂️', text: 'An umbrella will not protect you from lightning'),
        ],
      );
    }

    // Rule 1: Hazardous AQI (> 150)
    if (input.aqi > 150) {
      return const AskyResult(
        primaryAdvice:
            'Air quality is poor today. Limit outdoor exposure and protect yourself.',
        tips: [
          AskyTip(icon: '😷', text: 'Wear an N95 mask if going outdoors'),
          AskyTip(icon: '🏠', text: 'Keep windows and doors closed'),
          AskyTip(icon: '🚫', text: 'Avoid outdoor exercise or sports'),
          AskyTip(icon: '🌬️', text: 'Use an air purifier indoors if available'),
          AskyTip(icon: '💧', text: 'Drink plenty of water to flush toxins'),
        ],
      );
    }

    // Rule 2a: Fog / mist / haze / very low visibility
    if (WeatherClassifier.isFog(input.conditionCode, input.visibilityMeters)) {
      return const AskyResult(
        primaryAdvice:
            'Foggy with low visibility. Drive slowly and keep your lights on.',
        tips: [
          AskyTip(icon: '🚗', text: 'Use low-beam or fog lights, not high beams'),
          AskyTip(icon: '🐢', text: 'Slow down and keep a longer distance'),
          AskyTip(icon: '🚶', text: 'Wear bright clothing if walking near roads'),
          AskyTip(icon: '🏃', text: 'Postpone outdoor exercise if you can'),
          AskyTip(icon: '🕯️', text: 'Avoid unnecessary travel until it clears'),
        ],
      );
    }

    // Rule 2a-ii: Haze, smoke, dust, sand or ash in the air
    if (WeatherClassifier.isHaze(input.conditionCode)) {
      return const AskyResult(
        primaryAdvice:
            'Hazy air today. Limit time outdoors and protect your lungs.',
        tips: [
          AskyTip(icon: '😷', text: 'Wear a well-fitted N95 mask outdoors'),
          AskyTip(icon: '🏃', text: 'Skip strenuous outdoor exercise'),
          AskyTip(icon: '🏠', text: 'Keep windows closed; use an air purifier if you have one'),
          AskyTip(icon: '👁️', text: 'Rinse irritated eyes with clean water'),
          AskyTip(icon: '💧', text: 'Drink plenty of water'),
        ],
      );
    }

    // Rule 2a-iii: Mist
    if (WeatherClassifier.isMist(input.conditionCode)) {
      return const AskyResult(
        primaryAdvice:
            'Misty conditions with reduced visibility. Take care on the roads.',
        tips: [
          AskyTip(icon: '🚗', text: 'Use dipped headlights and slow down'),
          AskyTip(icon: '👟', text: 'Surfaces may be damp and slippery'),
          AskyTip(icon: '🧥', text: 'Carry a light jacket — mist feels cool and damp'),
          AskyTip(icon: '📸', text: 'Misty mornings make great photos'),
        ],
      );
    }

    // Rule 2b: Snowy or other low-visibility conditions (600–781)
    if (input.conditionCode >= 600 && input.conditionCode <= 781) {
      return const AskyResult(
        primaryAdvice:
            'Low visibility conditions today. Drive carefully and stay warm.',
        tips: [
          AskyTip(icon: '🚗', text: 'Drive carefully — reduced visibility'),
          AskyTip(icon: '👟', text: 'Wear non-slip footwear outdoors'),
          AskyTip(icon: '🧥', text: 'Warm layers are essential'),
          AskyTip(icon: '☕', text: 'Hot beverages will keep you warm'),
          AskyTip(icon: '🕯️', text: 'Avoid unnecessary travel in poor visibility'),
        ],
      );
    }

    // Rule 3: Rainy (500–531)
    if (input.conditionCode >= 500 && input.conditionCode <= 531) {
      return const AskyResult(
        primaryAdvice:
            'It\'s rainy today! Keep dry and allow extra time for travel.',
        tips: [
          AskyTip(icon: '☂️', text: 'Carry an umbrella before stepping out'),
          AskyTip(icon: '👞', text: 'Wear waterproof or closed footwear'),
          AskyTip(icon: '🚗', text: 'Allow extra travel time — roads may be slippery'),
          AskyTip(icon: '⚡', text: 'Avoid open areas during thunderstorms'),
          AskyTip(icon: '📱', text: 'Keep your phone in a waterproof bag'),
        ],
      );
    }

    // Rule 4: Drizzle (300–321)
    if (input.conditionCode >= 300 && input.conditionCode <= 321) {
      return const AskyResult(
        primaryAdvice: 'Light drizzle expected. A light jacket will do!',
        tips: [
          AskyTip(icon: '🌂', text: 'A light umbrella or raincoat is handy'),
          AskyTip(icon: '👟', text: 'Avoid puddles and slippery surfaces'),
          AskyTip(icon: '🌿', text: 'Great weather to enjoy the freshness outdoors'),
          AskyTip(icon: '☕', text: 'A warm cup of chai pairs well with this weather'),
        ],
      );
    }

    // Rule 5: Hot & Sunny (temp ≥ 35 and UV ≥ 6)
    if (input.temperature >= 35 && input.uvIndex >= 6) {
      return AskyResult(
        primaryAdvice:
            'It\'s hot & sunny today! Stay hydrated and protect your skin.',
        tips: [
          const AskyTip(icon: '💧', text: 'Drink at least 8–10 glasses of water'),
          const AskyTip(icon: '🧴', text: 'Apply Sunscreen (SPF 30+) before stepping out'),
          const AskyTip(icon: '👕', text: 'Wear light and cotton clothes'),
          AskyTip(
              icon: '☀️',
              text:
                  'Avoid Direct Sunlight between ${input.timeOfDay == "morning" ? "11AM–2PM" : "12PM–3PM"}'),
          const AskyTip(icon: '🕶️', text: 'Wear Sunglasses when going out'),
        ],
      );
    }

    // Rule 6: Warm & Sunny (temp 25–34)
    if (input.temperature >= 25 &&
        input.conditionCode >= 800 &&
        input.conditionCode <= 802) {
      return const AskyResult(
        primaryAdvice:
            'It\'s a lovely sunny day! Great time to head outdoors.',
        tips: [
          AskyTip(icon: '🌤️', text: 'Great day for outdoor activities'),
          AskyTip(icon: '💧', text: 'Stay hydrated throughout the day'),
          AskyTip(icon: '🧴', text: 'Apply sunscreen before going out'),
          AskyTip(icon: '🧢', text: 'Wear a hat to protect from the sun'),
          AskyTip(icon: '🌅', text: 'Ideal weather for an evening walk'),
        ],
      );
    }

    // Rule 7: Cold (temp < 15)
    if (input.temperature < 15) {
      return const AskyResult(
        primaryAdvice:
            'It\'s chilly today! Bundle up and stay warm.',
        tips: [
          AskyTip(icon: '🧥', text: 'Layer up with warm clothes'),
          AskyTip(icon: '🧤', text: 'Keep hands and ears covered'),
          AskyTip(icon: '☕', text: 'Hot beverages are highly recommended'),
          AskyTip(icon: '🏠', text: 'Minimise time outdoors if possible'),
          AskyTip(icon: '🩹', text: 'Moisturise skin to prevent dryness'),
        ],
      );
    }

    // Rule 8: Cloudy / Overcast (default)
    return const AskyResult(
      primaryAdvice:
          'Comfortable cloudy weather today. A great day for a walk!',
      tips: [
        AskyTip(icon: '🚶', text: 'Comfortable weather for outdoor activities'),
        AskyTip(icon: '🧥', text: 'Carry a light layer — it might get cooler'),
        AskyTip(icon: '💧', text: 'Stay hydrated even on cloudy days'),
        AskyTip(icon: '📸', text: 'Soft light makes it great for photography'),
        AskyTip(icon: '🌿', text: 'Ideal day for a park visit or nature walk'),
      ],
    );
  }

  static String _timeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 20) return 'evening';
    return 'night';
  }

  /// [localHour] is the current hour (0–23) *in the city being shown*. It
  /// defaults to the phone's hour for callers that don't know the city.
  static WeatherInput buildInput({
    required int conditionCode,
    required double temperature,
    required double uvIndex,
    required int aqi,
    required int humidity,
    double windKmh = 0,
    bool isHail = false,
    int visibilityMeters = 10000,
    int? localHour,
  }) {
    return WeatherInput(
      conditionCode: conditionCode,
      temperature: temperature,
      uvIndex: uvIndex,
      aqi: aqi,
      humidity: humidity,
      timeOfDay: _timeOfDay(localHour ?? DateTime.now().hour),
      windKmh: windKmh,
      isHail: isHail,
      visibilityMeters: visibilityMeters,
    );
  }
}
