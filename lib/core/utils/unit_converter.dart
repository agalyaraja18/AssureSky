import '../constants/app_constants.dart';

class UnitConverter {
  // Temperature
  static double celsiusToFahrenheit(double c) => (c * 9 / 5) + 32;
  static double fahrenheitToCelsius(double f) => (f - 32) * 5 / 9;

  static String formatTemp(double celsius, String unit) {
    if (unit == AppConstants.tempFahrenheit) {
      return '${celsiusToFahrenheit(celsius).round()}${AppConstants.tempFahrenheit}';
    }
    return '${celsius.round()}${AppConstants.tempCelsius}';
  }

  static double convertTemp(double celsius, String unit) {
    if (unit == AppConstants.tempFahrenheit) return celsiusToFahrenheit(celsius);
    return celsius;
  }

  // Wind speed (input in km/h)
  static double kmhToMs(double kmh) => kmh / 3.6;
  static double kmhToMph(double kmh) => kmh * 0.621371;
  static double kmhToKnots(double kmh) => kmh * 0.539957;

  static String formatWind(double kmh, String unit) {
    switch (unit) {
      case AppConstants.windMs:
        return '${kmhToMs(kmh).toStringAsFixed(1)} ${AppConstants.windMs}';
      case AppConstants.windMph:
        return '${kmhToMph(kmh).toStringAsFixed(1)} ${AppConstants.windMph}';
      case AppConstants.windKnots:
        return '${kmhToKnots(kmh).toStringAsFixed(1)} ${AppConstants.windKnots}';
      default:
        return '${kmh.toStringAsFixed(1)} ${AppConstants.windKmh}';
    }
  }

  // Pressure (input in hPa)
  static double hpaToMb(double hpa) => hpa; // 1 hPa = 1 mb
  static double hpaToInhg(double hpa) => hpa * 0.02953;

  static String formatPressure(double hpa, String unit) {
    switch (unit) {
      case AppConstants.pressureHpa:
        return '${hpa.round()} ${AppConstants.pressureHpa}';
      case AppConstants.pressureInhg:
        return '${hpaToInhg(hpa).toStringAsFixed(2)} ${AppConstants.pressureInhg}';
      default:
        return '${hpaToMb(hpa).round()} ${AppConstants.pressureMb}';
    }
  }

  // Visibility (meters to km)
  static String formatVisibility(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  // UV Index label
  static String uvLabel(double uv) {
    if (uv < 3) return 'Low';
    if (uv < 6) return 'Moderate';
    if (uv < 8) return 'High';
    if (uv < 11) return 'Very High';
    return 'Extreme';
  }
}
