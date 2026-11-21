/// Maps WMO weather interpretation codes (used by Open-Meteo) to an emoji and
/// a short label.
class WmoWeather {
  WmoWeather._();

  static String label(int code) {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mostly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing drizzle';
      case 61:
        return 'Light rain';
      case 63:
        return 'Rain';
      case 65:
        return 'Heavy rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }

  /// Closest OpenWeatherMap condition id, so Open-Meteo days can use the same
  /// icons, text and logic as the rest of the app.
  static int owmCode(int wmo) {
    switch (wmo) {
      case 0:
        return 800;
      case 1:
        return 801;
      case 2:
        return 802;
      case 3:
        return 804;
      case 45:
      case 48:
        return 741;
      case 51:
      case 53:
      case 55:
        return 301;
      case 56:
      case 57:
        return 511;
      case 61:
        return 500;
      case 63:
        return 501;
      case 65:
        return 502;
      case 66:
      case 67:
        return 511;
      case 71:
        return 600;
      case 73:
      case 75:
      case 77:
        return 601;
      case 80:
      case 81:
        return 521;
      case 82:
        return 522;
      case 85:
      case 86:
        return 621;
      case 95:
      case 96:
      case 99:
        return 211;
      default:
        return 803;
    }
  }

  /// OpenWeatherMap "main" group name for [owmCode] (e.g. `Rain`, `Clouds`).
  static String owmMain(int owm) {
    if (owm == 800) return 'Clear';
    if (owm >= 801 && owm <= 804) return 'Clouds';
    if (owm >= 200 && owm < 300) return 'Thunderstorm';
    if (owm >= 300 && owm < 400) return 'Drizzle';
    if (owm >= 500 && owm < 600) return 'Rain';
    if (owm >= 600 && owm < 700) return 'Snow';
    if (owm == 741) return 'Fog';
    return 'Clouds';
  }

  static String emoji(int code, {bool isDay = true}) {
    switch (code) {
      case 0:
      case 1:
        return isDay ? '☀️' : '🌙';
      case 2:
        return isDay ? '⛅' : '☁️';
      case 3:
        return '☁️';
      case 45:
      case 48:
        return '🌫️';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return '🌦️';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return '🌧️';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return '❄️';
      case 95:
      case 96:
      case 99:
        return '⛈️';
      default:
        return '🌡️';
    }
  }
}
