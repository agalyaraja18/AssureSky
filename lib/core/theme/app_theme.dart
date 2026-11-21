import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/weather_classifier.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => _build(
        name: AppConstants.themeLight,
        bg: AppColors.lightBg,
        card: AppColors.lightCard,
        text: AppColors.lightText,
        subtext: AppColors.lightSubtext,
        brightness: Brightness.light,
      );

  static ThemeData get dark => _build(
        name: AppConstants.themeDark,
        bg: AppColors.darkBg,
        card: AppColors.darkCard,
        text: AppColors.darkText,
        subtext: AppColors.darkSubtext,
        brightness: Brightness.dark,
      );

  static ThemeData get cloudy => _build(
        name: AppConstants.themeCloudy,
        bg: AppColors.cloudyBg,
        card: AppColors.cloudyCard,
        text: AppColors.lightText,
        subtext: AppColors.lightSubtext,
        brightness: Brightness.light,
      );

  static ThemeData get sunny => _build(
        name: AppConstants.themeSunny,
        bg: AppColors.sunnyBg,
        card: AppColors.sunnyCard,
        text: AppColors.lightText,
        subtext: AppColors.lightSubtext,
        brightness: Brightness.light,
      );

  static ThemeData get rainy => _build(
        name: AppConstants.themeRainy,
        bg: AppColors.rainyBg,
        card: AppColors.rainyCard,
        text: Colors.white,
        subtext: Colors.white70,
        brightness: Brightness.dark,
      );

  static ThemeData get snowy => _build(
        name: AppConstants.themeSnowy,
        bg: AppColors.snowyBg,
        card: AppColors.snowyCard,
        text: AppColors.lightText,
        subtext: AppColors.lightSubtext,
        brightness: Brightness.light,
      );

  static ThemeData get windy => _build(
        name: AppConstants.themeWindy,
        bg: AppColors.windyBg,
        card: AppColors.windyCard,
        text: Colors.white,
        subtext: Colors.white70,
        brightness: Brightness.dark,
      );

  static ThemeData get thunderstorm => _build(
        name: AppConstants.themeThunderstorm,
        bg: AppColors.thunderstormBg,
        card: AppColors.thunderstormCard,
        text: Colors.white,
        subtext: Colors.white70,
        brightness: Brightness.dark,
      );

  static ThemeData get cyclone => _build(
        name: AppConstants.themeCyclone,
        bg: AppColors.cycloneBg,
        card: AppColors.cycloneCard,
        text: Colors.white,
        subtext: Colors.white70,
        brightness: Brightness.dark,
      );

  static ThemeData get tornado => _build(
        name: AppConstants.themeTornado,
        bg: AppColors.tornadoBg,
        card: AppColors.tornadoCard,
        text: Colors.white,
        subtext: Colors.white70,
        brightness: Brightness.dark,
      );

  static ThemeData get hail => _build(
        name: AppConstants.themeHail,
        bg: AppColors.hailBg,
        card: AppColors.hailCard,
        text: Colors.white,
        subtext: Colors.white70,
        brightness: Brightness.dark,
      );

  static ThemeData get foggy => _build(
        name: AppConstants.themeFoggy,
        bg: AppColors.foggyBg,
        card: AppColors.foggyCard,
        text: AppColors.lightText,
        subtext: AppColors.lightSubtext,
        brightness: Brightness.light,
      );

  static ThemeData get hot => _build(
        name: AppConstants.themeHot,
        bg: AppColors.hotBg,
        card: AppColors.hotCard,
        text: Colors.white,
        subtext: Colors.white70,
        brightness: Brightness.dark,
      );

  static ThemeData get cold => _build(
        name: AppConstants.themeCold,
        bg: AppColors.coldBg,
        card: AppColors.coldCard,
        text: Colors.white,
        subtext: Colors.white70,
        brightness: Brightness.dark,
      );

  static ThemeData get humid => _build(
        name: AppConstants.themeHumid,
        bg: AppColors.humidBg,
        card: AppColors.humidCard,
        text: AppColors.lightText,
        subtext: AppColors.lightSubtext,
        brightness: Brightness.light,
      );

  static ThemeData get breezy => _build(
        name: AppConstants.themeBreezy,
        bg: AppColors.breezyBg,
        card: AppColors.breezyCard,
        text: AppColors.lightText,
        subtext: AppColors.lightSubtext,
        brightness: Brightness.light,
      );

  static ThemeData get overcast => _build(
        name: AppConstants.themeOvercast,
        bg: AppColors.overcastBg,
        card: AppColors.overcastCard,
        text: AppColors.lightText,
        subtext: AppColors.lightSubtext,
        brightness: Brightness.light,
      );

  static ThemeData get haze => _build(
        name: AppConstants.themeHaze,
        bg: AppColors.hazeBg,
        card: AppColors.hazeCard,
        text: AppColors.lightText,
        subtext: AppColors.lightSubtext,
        brightness: Brightness.light,
      );

  static ThemeData get mist => _build(
        name: AppConstants.themeMist,
        bg: AppColors.mistBg,
        card: AppColors.mistCard,
        text: AppColors.lightText,
        subtext: AppColors.lightSubtext,
        brightness: Brightness.light,
      );

  static ThemeData get lightning => _build(
        name: AppConstants.themeLightning,
        bg: AppColors.lightningBg,
        card: AppColors.lightningCard,
        text: Colors.white,
        subtext: Colors.white70,
        brightness: Brightness.dark,
      );

  static ThemeData fromName(String name) {
    switch (name) {
      case AppConstants.themeHot:
        return hot;
      case AppConstants.themeCold:
        return cold;
      case AppConstants.themeHumid:
        return humid;
      case AppConstants.themeBreezy:
        return breezy;
      case AppConstants.themeOvercast:
        return overcast;
      case AppConstants.themeHaze:
        return haze;
      case AppConstants.themeMist:
        return mist;
      case AppConstants.themeLightning:
        return lightning;
      case AppConstants.themeThunderstorm:
        return thunderstorm;
      case AppConstants.themeCyclone:
        return cyclone;
      case AppConstants.themeTornado:
        return tornado;
      case AppConstants.themeHail:
        return hail;
      case AppConstants.themeFoggy:
        return foggy;
      case AppConstants.themeDark:
        return dark;
      case AppConstants.themeCloudy:
        return cloudy;
      case AppConstants.themeSunny:
        return sunny;
      case AppConstants.themeRainy:
        return rainy;
      case AppConstants.themeSnowy:
        return snowy;
      case AppConstants.themeWindy:
        return windy;
      default:
        return light;
    }
  }

  static Color bgColorFromName(String name) {
    switch (name) {
      case AppConstants.themeHot:
        return AppColors.hotBg;
      case AppConstants.themeCold:
        return AppColors.coldBg;
      case AppConstants.themeHumid:
        return AppColors.humidBg;
      case AppConstants.themeBreezy:
        return AppColors.breezyBg;
      case AppConstants.themeOvercast:
        return AppColors.overcastBg;
      case AppConstants.themeHaze:
        return AppColors.hazeBg;
      case AppConstants.themeMist:
        return AppColors.mistBg;
      case AppConstants.themeLightning:
        return AppColors.lightningBg;
      case AppConstants.themeThunderstorm:
        return AppColors.thunderstormBg;
      case AppConstants.themeCyclone:
        return AppColors.cycloneBg;
      case AppConstants.themeTornado:
        return AppColors.tornadoBg;
      case AppConstants.themeHail:
        return AppColors.hailBg;
      case AppConstants.themeFoggy:
        return AppColors.foggyBg;
      case AppConstants.themeDark:
        return AppColors.darkBg;
      case AppConstants.themeCloudy:
        return AppColors.cloudyBg;
      case AppConstants.themeSunny:
        return AppColors.sunnyBg;
      case AppConstants.themeRainy:
        return AppColors.rainyBg;
      case AppConstants.themeSnowy:
        return AppColors.snowyBg;
      case AppConstants.themeWindy:
        return AppColors.windyBg;
      default:
        return AppColors.lightBg;
    }
  }

  /// Picks the theme that matches the current conditions.
  ///
  /// [code] is the OpenWeatherMap condition code. [windKmh], [visibilityMeters]
  /// and [isHail] (from Open-Meteo, which OpenWeatherMap has no code for) let
  /// us detect cyclones, fog, hail and strong wind. Severe conditions win over
  /// ordinary ones.
  static String themeFromConditionCode(
    int code, {
    double windKmh = 0,
    int visibilityMeters = 10000,
    bool isHail = false,
    double tempC = 20,
    int humidity = 50,
  }) {
    // 1. Dangerous weather always wins.
    if (isHail) return AppConstants.themeHail;
    if (WeatherClassifier.isTornado(code)) return AppConstants.themeTornado;
    if (WeatherClassifier.isCyclone(code, windKmh)) {
      return AppConstants.themeCyclone;
    }

    // 2. Thunder: dry (no rain) → Lightning; with rain/drizzle → Thunderstorm.
    if (WeatherClassifier.isLightning(code)) return AppConstants.themeLightning;
    if (WeatherClassifier.isThunderstorm(code)) {
      return AppConstants.themeThunderstorm;
    }

    // 3. Reduced visibility, from densest to lightest.
    if (WeatherClassifier.isFog(code, visibilityMeters)) {
      return AppConstants.themeFoggy;
    }
    if (WeatherClassifier.isMist(code)) return AppConstants.themeMist;
    if (WeatherClassifier.isHaze(code)) return AppConstants.themeHaze;

    // 4. Strong wind.
    final precipitation = code >= 300 && code <= 622;
    if (code == 771 || (windKmh >= 50 && !precipitation)) {
      return AppConstants.themeWindy;
    }

    // 5. Precipitation.
    if (code >= 500 && code <= 531) return AppConstants.themeRainy;
    if (code >= 600 && code <= 622) return AppConstants.themeSnowy;
    if (code >= 300 && code <= 321) return AppConstants.themeRainy;

    // 6. Dry weather: temperature extremes, then muggy, then breezy.
    if (tempC >= 38) return AppConstants.themeHot;
    if (tempC <= 5) return AppConstants.themeCold;
    if (humidity >= 80 && tempC >= 27) return AppConstants.themeHumid;
    if (windKmh >= 30) return AppConstants.themeBreezy;

    // 7. Sky cover.
    if (code == 800) return AppConstants.themeSunny;
    if (code == 804) return AppConstants.themeOvercast;
    if (code >= 801 && code <= 803) return AppConstants.themeCloudy;
    if (code >= 700 && code <= 781) return AppConstants.themeCloudy;
    return AppConstants.themeLight;
  }

  static ThemeData _build({
    required String name,
    required Color bg,
    required Color card,
    required Color text,
    required Color subtext,
    required Brightness brightness,
  }) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: brightness,
        surface: card,
      ),
      cardColor: card,
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
            color: text, fontWeight: FontWeight.bold, fontSize: 48),
        headlineLarge: TextStyle(
            color: text, fontWeight: FontWeight.bold, fontSize: 28),
        headlineMedium: TextStyle(
            color: text, fontWeight: FontWeight.bold, fontSize: 22),
        titleLarge: TextStyle(
            color: text, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(
            color: text, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: TextStyle(color: text, fontSize: 16),
        bodyMedium: TextStyle(color: subtext, fontSize: 14),
        bodySmall: TextStyle(color: subtext, fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(
            color: text, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600);
          }
          return TextStyle(color: subtext, fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.accent);
          }
          return IconThemeData(color: subtext);
        }),
      ),
      dividerColor: subtext.withValues(alpha: 0.2),
      useMaterial3: true,
    );
  }
}
