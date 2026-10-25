import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
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

  static ThemeData fromName(String name) {
    switch (name) {
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

  /// Map OpenWeatherMap condition codes to theme names
  static String themeFromConditionCode(int code) {
    if (code == 800) return AppConstants.themeSunny;
    if (code >= 801 && code <= 804) return AppConstants.themeCloudy;
    if (code >= 500 && code <= 531) return AppConstants.themeRainy;
    if (code >= 600 && code <= 622) return AppConstants.themeSnowy;
    if (code >= 700 && code <= 781) return AppConstants.themeCloudy;
    if (code >= 200 && code <= 232) return AppConstants.themeRainy;
    if (code >= 300 && code <= 321) return AppConstants.themeRainy;
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
