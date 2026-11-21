import '../models/air_quality_model.dart';
import '../models/current_weather_model.dart';
import '../models/forecast_model.dart';
import '../utils/weather_classifier.dart';

enum AlertSeverity {
  /// Worth knowing. Shown in the app only (never pushed as a notification).
  advisory,

  /// Take precautions. Shown in the app and sent as a notification.
  warning,

  /// Dangerous. Shown in the app and sent as a high-priority notification.
  severe,
}

class WeatherAlert {
  /// Stable id for the *kind* of alert, e.g. `heat`. Used to avoid sending the
  /// same notification repeatedly.
  final String id;
  final AlertSeverity severity;
  final String icon;
  final String title;
  final String message;

  const WeatherAlert({
    required this.id,
    required this.severity,
    required this.icon,
    required this.title,
    required this.message,
  });

  /// Only warnings and severe alerts are pushed as notifications.
  bool get shouldNotify => severity != AlertSeverity.advisory;
}

/// Turns current conditions (plus the near-term forecast) into a list of
/// weather alerts, most severe first. Pure function — no I/O.
class WeatherAlertEngine {
  WeatherAlertEngine._();

  /// How many forecast hours ahead to look for "heavy rain / storm soon".
  static const int lookAheadHours = 6;

  static List<WeatherAlert> evaluate({
    required CurrentWeatherModel weather,
    required AirQualityModel airQuality,
    ForecastModel? forecast,
    bool hasHail = false,
  }) {
    final alerts = <WeatherAlert>[];
    final code = weather.conditionCode;
    final wind = weather.windSpeed; // km/h

    final tornado = WeatherClassifier.isTornado(code);
    final cyclone = !tornado && WeatherClassifier.isCyclone(code, wind);
    final thunderstorm = WeatherClassifier.isThunderstorm(code);

    // ── Severe storms ──────────────────────────────────────────────────
    if (tornado) {
      alerts.add(const WeatherAlert(
        id: 'tornado',
        severity: AlertSeverity.severe,
        icon: '🌪️',
        title: 'Tornado warning',
        message:
            'Take shelter now in an interior room on the lowest floor, away from windows.',
      ));
    }
    if (cyclone) {
      alerts.add(const WeatherAlert(
        id: 'cyclone',
        severity: AlertSeverity.severe,
        icon: '🌀',
        title: 'Cyclone conditions',
        message:
            'Very strong winds and heavy rain. Stay indoors and avoid all travel.',
      ));
    }
    if (hasHail) {
      alerts.add(const WeatherAlert(
        id: 'hail',
        severity: AlertSeverity.severe,
        icon: '🧊',
        title: 'Hailstorm',
        message:
            'Hail is falling. Shelter indoors and move vehicles under cover.',
      ));
    }
    if (thunderstorm && !tornado && !cyclone) {
      alerts.add(const WeatherAlert(
        id: 'thunderstorm',
        severity: AlertSeverity.warning,
        icon: '⛈️',
        title: 'Thunderstorm',
        message:
            'Lightning in the area. Stay indoors and away from open ground and tall trees.',
      ));
    }

    // ── Rain / snow ────────────────────────────────────────────────────
    final heavyRainNow = WeatherClassifier.isHeavyRain(code);
    if (heavyRainNow && !cyclone) {
      alerts.add(const WeatherAlert(
        id: 'heavy_rain',
        severity: AlertSeverity.warning,
        icon: '🌧️',
        title: 'Heavy rain',
        message:
            'Expect waterlogging and slippery roads. Allow extra travel time.',
      ));
    } else if (!thunderstorm && !cyclone && forecast != null) {
      final soon = forecast.hourly
          .take(lookAheadHours)
          .any((h) =>
              WeatherClassifier.isHeavyRain(h.conditionCode) ||
              WeatherClassifier.isThunderstorm(h.conditionCode));
      if (soon) {
        alerts.add(const WeatherAlert(
          id: 'rain_soon',
          severity: AlertSeverity.advisory,
          icon: '☔',
          title: 'Heavy rain or storm expected soon',
          message: 'Heavy rain or thunderstorms are forecast in the next few hours.',
        ));
      }
    }
    if (WeatherClassifier.isHeavySnow(code)) {
      alerts.add(const WeatherAlert(
        id: 'heavy_snow',
        severity: AlertSeverity.warning,
        icon: '🌨️',
        title: 'Heavy snow',
        message: 'Roads may be icy and visibility poor. Avoid unnecessary travel.',
      ));
    }

    // ── Heat / cold ────────────────────────────────────────────────────
    // Thresholds use the *actual* temperature (as IMD does for heatwaves).
    // "Feels like" only escalates in extreme heat-index cases — otherwise
    // humid tropical cities would be flagged as a heatwave almost daily.
    if (weather.temp >= 45) {
      alerts.add(const WeatherAlert(
        id: 'heat',
        severity: AlertSeverity.severe,
        icon: '🔥',
        title: 'Extreme heat',
        message:
            'Dangerous heat. Stay indoors, drink water often and avoid the afternoon sun.',
      ));
    } else if (weather.temp >= 40) {
      alerts.add(const WeatherAlert(
        id: 'heat',
        severity: AlertSeverity.warning,
        icon: '🥵',
        title: 'Heatwave',
        message:
            'Very hot. Stay hydrated, wear light clothes and limit time outdoors.',
      ));
    } else if (weather.feelsLike >= 46) {
      alerts.add(const WeatherAlert(
        id: 'heat',
        severity: AlertSeverity.warning,
        icon: '🥵',
        title: 'Dangerous heat index',
        message:
            'Heat and humidity make it feel far hotter than the air temperature. Stay cool and hydrated.',
      ));
    }
    if (weather.temp <= -10) {
      alerts.add(const WeatherAlert(
        id: 'cold',
        severity: AlertSeverity.severe,
        icon: '🥶',
        title: 'Extreme cold',
        message:
            'Dangerously cold. Limit time outside and cover all exposed skin.',
      ));
    } else if (weather.temp <= 2) {
      alerts.add(const WeatherAlert(
        id: 'cold',
        severity: AlertSeverity.warning,
        icon: '🧊',
        title: 'Cold wave',
        message: 'Near-freezing temperatures. Dress in warm layers.',
      ));
    }

    // ── UV, air, wind, visibility ──────────────────────────────────────
    if (weather.uvIndex >= 11) {
      alerts.add(const WeatherAlert(
        id: 'uv',
        severity: AlertSeverity.severe,
        icon: '☀️',
        title: 'Extreme UV',
        message:
            'Skin can burn in minutes. Avoid the sun, cover up and use SPF 50+.',
      ));
    } else if (weather.uvIndex >= 8) {
      alerts.add(const WeatherAlert(
        id: 'uv',
        severity: AlertSeverity.warning,
        icon: '🧴',
        title: 'Very high UV',
        message: 'Use sunscreen, sunglasses and a hat, and seek shade at midday.',
      ));
    }

    if (airQuality.aqi500 > 300) {
      alerts.add(const WeatherAlert(
        id: 'aqi',
        severity: AlertSeverity.severe,
        icon: '☣️',
        title: 'Hazardous air quality',
        message: 'Stay indoors with windows closed and wear an N95 mask if you must go out.',
      ));
    } else if (airQuality.aqi500 > 150) {
      alerts.add(const WeatherAlert(
        id: 'aqi',
        severity: AlertSeverity.warning,
        icon: '😷',
        title: 'Poor air quality',
        message: 'Limit outdoor exercise and consider wearing a mask outdoors.',
      ));
    }

    if (!tornado && !cyclone) {
      if (wind >= 75) {
        alerts.add(const WeatherAlert(
          id: 'wind',
          severity: AlertSeverity.severe,
          icon: '💨',
          title: 'Damaging winds',
          message: 'Secure loose objects and stay away from trees and hoardings.',
        ));
      } else if (wind >= 50) {
        alerts.add(const WeatherAlert(
          id: 'wind',
          severity: AlertSeverity.warning,
          icon: '🌬️',
          title: 'Strong winds',
          message: 'Gusty conditions. Take care when driving or riding.',
        ));
      }
    }

    if (WeatherClassifier.isFog(code, weather.visibility)) {
      alerts.add(const WeatherAlert(
        id: 'fog',
        severity: AlertSeverity.warning,
        icon: '🌫️',
        title: 'Dense fog',
        message: 'Visibility is very low. Drive slowly and use fog lights.',
      ));
    }

    // Most severe first; keep insertion order within a severity.
    final indexed = alerts.asMap().entries.toList()
      ..sort((a, b) {
        final bySeverity =
            b.value.severity.index.compareTo(a.value.severity.index);
        return bySeverity != 0 ? bySeverity : a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }
}
