/// Returns an emoji that best represents the weather condition code.
class WeatherIconHelper {
  static String emoji(int code, {bool isNight = false}) {
    if (code == 800) return isNight ? '🌙' : '☀️';
    if (code == 801) return '🌤️';
    if (code == 802) return '⛅';
    if (code >= 803 && code <= 804) return '☁️';
    if (code >= 200 && code <= 232) return '⛈️';
    if (code >= 300 && code <= 321) return '🌦️';
    if (code >= 500 && code <= 504) return '🌧️';
    if (code == 511) return '🌨️';
    if (code >= 520 && code <= 531) return '🌧️';
    if (code >= 600 && code <= 622) return '❄️';
    if (code >= 700 && code <= 741) return '🌫️';
    if (code >= 762 && code <= 771) return '💨';
    if (code == 781) return '🌪️';
    return '🌤️';
  }

  static String condition(int code) {
    if (code == 800) return 'Clear Sky';
    if (code == 801) return 'Few Clouds';
    if (code == 802) return 'Partly Cloudy';
    if (code == 803) return 'Mostly Cloudy';
    if (code == 804) return 'Overcast';
    if (code >= 200 && code <= 232) return 'Thunderstorm';
    if (code >= 300 && code <= 321) return 'Drizzle';
    if (code >= 500 && code <= 504) return 'Rain';
    if (code == 511) return 'Freezing Rain';
    if (code >= 520 && code <= 531) return 'Shower Rain';
    if (code >= 600 && code <= 602) return 'Snow';
    if (code >= 611 && code <= 622) return 'Sleet';
    if (code >= 700 && code <= 741) return 'Foggy';
    if (code >= 762 && code <= 771) return 'Windy';
    if (code == 781) return 'Tornado';
    return 'Unknown';
  }
}
