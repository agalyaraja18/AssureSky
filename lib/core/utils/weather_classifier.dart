/// One place that decides what kind of severe weather an OpenWeatherMap
/// condition code (plus wind / visibility / Open-Meteo hail flag) represents.
///
/// The theme resolver, the Asky advice engine and the alert engine all use
/// this, so a condition is classified identically everywhere.
class WeatherClassifier {
  WeatherClassifier._();

  /// Sustained wind (km/h) at which a rain/storm system is treated as a
  /// cyclone. 89 km/h is the IMD / WMO threshold for a "cyclonic storm".
  static const double cycloneWindKmh = 89;

  /// OpenWeatherMap thunderstorm group (200–232).
  static bool isThunderstorm(int code) => code >= 200 && code <= 232;

  /// Thunder *without* rain or drizzle — 210 light, 211, 212 heavy and 221
  /// ragged thunderstorm. These get the "Lightning" theme; thunder with rain
  /// (200–202) or drizzle (230–232) keeps the "Thunderstorm" theme.
  static bool isLightning(int code) =>
      code == 210 || code == 211 || code == 212 || code == 221;

  /// Mist (701).
  static bool isMist(int code) => code == 701;

  /// Haze (721), smoke (711), dust (731, 761), sand (751) and volcanic ash
  /// (762) — all "the air itself is murky".
  static bool isHaze(int code) =>
      code == 711 ||
      code == 721 ||
      code == 731 ||
      code == 751 ||
      code == 761 ||
      code == 762;

  /// OpenWeatherMap 781 (tornado) and the legacy 900 "tornado" code.
  static bool isTornado(int code) => code == 781 || code == 900;

  /// Legacy "tropical storm" / "hurricane" codes, or a rain/storm system with
  /// cyclone-force wind.
  static bool isCyclone(int code, double windKmh) {
    if (code == 901 || code == 902) return true;
    final stormy = isThunderstorm(code) ||
        (code >= 300 && code <= 321) ||
        (code >= 500 && code <= 531) ||
        code == 771;
    return stormy && windKmh >= cycloneWindKmh;
  }

  /// Fog (741) — or visibility under 1 km when nothing else (rain, snow, storm,
  /// tornado) explains it. Plain mist (701) and haze (721) are *not* fog unless
  /// visibility really is under 1 km.
  static bool isFog(int code, int visibilityMeters) {
    if (code == 741) return true;
    final precipitationOrStorm = (code >= 200 && code <= 622) || code == 781;
    return visibilityMeters < 1000 && !precipitationOrStorm;
  }

  /// Heavy rain codes: heavy intensity, extreme, freezing and heavy shower.
  static bool isHeavyRain(int code) =>
      code == 502 ||
      code == 503 ||
      code == 504 ||
      code == 511 ||
      code == 522 ||
      code == 531;

  /// Heavy snow / heavy shower snow.
  static bool isHeavySnow(int code) =>
      code == 602 || code == 621 || code == 622;
}
