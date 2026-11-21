class AppConstants {
  // SharedPreferences keys
  static const String keyThemeName = 'theme_name';
  static const String keyThemeManualOverride = 'theme_manual_override';
  static const String keySavedCityName = 'saved_city_name';
  static const String keySavedLat = 'saved_lat';
  static const String keySavedLon = 'saved_lon';

  /// true  → follow the device GPS (default).
  /// false → the user picked a city manually; keep showing it.
  static const String keyUseGps = 'use_gps';

  static const String keyTempUnit = 'temp_unit';
  static const String keyWindUnit = 'wind_unit';
  static const String keyPressureUnit = 'pressure_unit';
  static const String keyNotifWeatherAlerts = 'notif_weather_alerts';
  static const String keyNotifAskyAdvice = 'notif_asky_advice';
  static const String keyNotifTrendingNews = 'notif_trending_news';
  static const String keyNotifDailyForecast = 'notif_daily_forecast';

  // Notification de-duplication bookkeeping
  static const String keyNotifAlertLog = 'notif_alert_log';
  static const String keyLastDailyForecastDate = 'last_daily_forecast_date';
  static const String keyLastAskyAdviceDate = 'last_asky_advice_date';
  static const String keyLastTrendingNewsDate = 'last_trending_news_date';

  // Offline cache key prefixes (see CacheService)
  static const String cacheWeatherPrefix = 'cache_weather_';
  static const String cacheForecastPrefix = 'cache_forecast_';
  static const String cacheNews = 'cache_news';
  static const String cacheOfficialAlerts = 'cache_official_alerts';

  // Units
  static const String tempCelsius = '°C';
  static const String tempFahrenheit = '°F';

  static const String windKmh = 'km/h';
  static const String windMs = 'm/s';
  static const String windMph = 'mph';
  static const String windKnots = 'kn';

  static const String pressureMb = 'mb';
  static const String pressureHpa = 'hPa';
  static const String pressureInhg = 'inHg';

  // Theme names
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String themeCloudy = 'Cloudy';
  static const String themeSunny = 'Sunny';
  static const String themeRainy = 'Rainy';
  static const String themeSnowy = 'Snowy';
  static const String themeWindy = 'Windy';
  static const String themeThunderstorm = 'Thunderstorm';
  static const String themeCyclone = 'Cyclone';
  static const String themeTornado = 'Tornado';
  static const String themeHail = 'Hail';
  static const String themeFoggy = 'Foggy';
  static const String themeHot = 'Hot';
  static const String themeCold = 'Cold';
  static const String themeHumid = 'Humid';
  static const String themeBreezy = 'Breezy';
  static const String themeOvercast = 'Overcast';
  static const String themeHaze = 'Haze';
  static const String themeMist = 'Mist';
  static const String themeLightning = 'Lightning';
}
