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

  const WeatherInput({
    required this.conditionCode,
    required this.temperature,
    required this.uvIndex,
    required this.aqi,
    required this.humidity,
    required this.timeOfDay,
  });
}

class AskyEngine {
  static AskyResult getTips(WeatherInput input) {
    // Priority order: AQI > Snow/Fog > Rain > Hot&Sunny > Warm&Sunny > Cold > Cloudy

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

    // Rule 2: Snowy or Foggy (600–781)
    if (input.conditionCode >= 600 && input.conditionCode <= 781) {
      return const AskyResult(
        primaryAdvice:
            'Low visibility conditions today. Drive carefully and stay warm.',
        tips: [
          AskyTip(icon: '🚗', text: 'Drive carefully — reduced visibility'),
          AskyTip(icon: '👟', text: 'Wear non-slip footwear outdoors'),
          AskyTip(icon: '🧥', text: 'Warm layers are essential'),
          AskyTip(icon: '☕', text: 'Hot beverages will keep you warm'),
          AskyTip(icon: '🕯️', text: 'Avoid unnecessary travel in fog'),
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

  static String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 20) return 'evening';
    return 'night';
  }

  static WeatherInput buildInput({
    required int conditionCode,
    required double temperature,
    required double uvIndex,
    required int aqi,
    required int humidity,
  }) {
    return WeatherInput(
      conditionCode: conditionCode,
      temperature: temperature,
      uvIndex: uvIndex,
      aqi: aqi,
      humidity: humidity,
      timeOfDay: _getTimeOfDay(),
    );
  }
}
