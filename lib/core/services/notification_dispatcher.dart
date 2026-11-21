import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../utils/unit_converter.dart';
import '../utils/weather_icon_helper.dart';
import 'news_service.dart';
import 'notification_service.dart';
import 'weather_insights.dart';
import 'weather_repository.dart';

/// Decides *which* notifications to send for a fresh [WeatherData] and makes
/// sure none are repeated.
///
/// Called from two places so notifications work both ways:
///  • the app, every time weather loads while it is open, and
///  • the Android background worker, roughly hourly while the app is closed.
class NotificationDispatcher {
  NotificationDispatcher._();

  /// The same alert for the same city is not re-sent within this window.
  static const Duration alertCooldown = Duration(hours: 6);

  /// Earliest local hour at which each daily notification may be sent.
  static const int dailyForecastFromHour = 6;
  static const int askyAdviceFromHour = 8;
  static const int trendingNewsFromHour = 10;

  static Future<void> process(
    WeatherData data, {
    required String cityName,
    DateTime? now,
  }) async {
    // Never notify from stale offline data — it may no longer be true.
    if (data.fromCache) return;

    final prefs = await SharedPreferences.getInstance();
    // The app and the background worker run in separate isolates, each with
    // its own in-memory copy of SharedPreferences. Re-read from disk so we see
    // what the other side has already sent (otherwise: duplicate notifications).
    await prefs.reload();
    final clock = now ?? DateTime.now();
    final city = cityName.isEmpty ? data.weather.cityName : cityName;

    if (prefs.getBool(AppConstants.keyNotifWeatherAlerts) ?? true) {
      await _sendAlerts(prefs, data, city, clock);
    }
    if ((prefs.getBool(AppConstants.keyNotifDailyForecast) ?? true) &&
        clock.hour >= dailyForecastFromHour) {
      await _sendDailyForecast(prefs, data, city, clock);
    }
    if ((prefs.getBool(AppConstants.keyNotifAskyAdvice) ?? true) &&
        clock.hour >= askyAdviceFromHour) {
      await _sendAskyAdvice(prefs, data, city, clock);
    }
    if ((prefs.getBool(AppConstants.keyNotifTrendingNews) ?? false) &&
        clock.hour >= trendingNewsFromHour) {
      await _sendTrendingNews(prefs, clock);
    }
  }

  // ── Weather alerts ────────────────────────────────────────────────────

  static Future<void> _sendAlerts(SharedPreferences prefs, WeatherData data,
      String city, DateTime now) async {
    final alerts = WeatherInsights.alerts(data).where((a) => a.shouldNotify);
    if (alerts.isEmpty) return;

    final log = _readAlertLog(prefs);
    var changed = false;
    var slot = 0;

    for (final alert in alerts) {
      final key = '${city.toLowerCase()}|${alert.id}';
      final last = log[key];
      final due = last == null ||
          now.difference(DateTime.fromMillisecondsSinceEpoch(last)) >=
              alertCooldown;
      if (!due) continue;

      final shown = await NotificationService.show(
        id: NotificationService.alertBaseId + (slot++ % 20),
        channel: NotificationService.alertsChannel,
        title: '${alert.icon} ${alert.title} · $city',
        body: alert.message,
      );
      if (!shown) return; // blocked by the OS: try again on the next run
      log[key] = now.millisecondsSinceEpoch;
      changed = true;
    }

    if (changed) {
      // Drop entries older than a day so the log can't grow forever.
      log.removeWhere((_, t) =>
          now.difference(DateTime.fromMillisecondsSinceEpoch(t)) >
          const Duration(days: 1));
      await prefs.setString(AppConstants.keyNotifAlertLog, jsonEncode(log));
    }
  }

  static Map<String, int> _readAlertLog(SharedPreferences prefs) {
    final raw = prefs.getString(AppConstants.keyNotifAlertLog);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  // ── Daily forecast ────────────────────────────────────────────────────

  static Future<void> _sendDailyForecast(SharedPreferences prefs,
      WeatherData data, String city, DateTime now) async {
    if (_alreadySentToday(prefs, AppConstants.keyLastDailyForecastDate, now)) {
      return;
    }
    final w = data.weather;
    final unit =
        prefs.getString(AppConstants.keyTempUnit) ?? AppConstants.tempCelsius;
    final today = WeatherInsights.today(data.forecast);
    final high = today?.tempMax ?? w.tempMax;
    final low = today?.tempMin ?? w.tempMin;
    final rain = today?.rainChance;

    final parts = <String>[
      '${w.condition}, high ${UnitConverter.formatTemp(high, unit)} / low ${UnitConverter.formatTemp(low, unit)}',
      if (rain != null && rain >= 20) '${rain.round()}% chance of rain',
    ];

    final shown = await NotificationService.show(
      id: NotificationService.dailyId,
      channel: NotificationService.dailyChannel,
      title:
          '${WeatherIconHelper.emoji(w.conditionCode, isNight: w.isNight)} Today in $city',
      body: '${parts.join('. ')}.',
    );
    if (shown) {
      await _markSent(prefs, AppConstants.keyLastDailyForecastDate, now);
    }
  }

  // ── Asky advice ───────────────────────────────────────────────────────

  static Future<void> _sendAskyAdvice(SharedPreferences prefs,
      WeatherData data, String city, DateTime now) async {
    if (_alreadySentToday(prefs, AppConstants.keyLastAskyAdviceDate, now)) {
      return;
    }
    final asky = WeatherInsights.asky(data);
    final shown = await NotificationService.show(
      id: NotificationService.askyId,
      channel: NotificationService.askyChannel,
      title: '🌤️ Asky says',
      body: asky.primaryAdvice,
    );
    if (shown) await _markSent(prefs, AppConstants.keyLastAskyAdviceDate, now);
  }

  // ── Trending news ─────────────────────────────────────────────────────

  static Future<void> _sendTrendingNews(
      SharedPreferences prefs, DateTime now) async {
    if (_alreadySentToday(prefs, AppConstants.keyLastTrendingNewsDate, now)) {
      return;
    }
    try {
      final result = await NewsService().getWeatherNews();
      if (result.fromCache || result.articles.isEmpty) return;
      final top = result.articles.first;
      final shown = await NotificationService.show(
        id: NotificationService.newsId,
        channel: NotificationService.newsChannel,
        title: '📰 Weather news',
        body: top.title,
      );
      if (shown) {
        await _markSent(prefs, AppConstants.keyLastTrendingNewsDate, now);
      }
    } catch (_) {
      // No news today — try again on the next run.
    }
  }

  // ── once-per-day bookkeeping ──────────────────────────────────────────

  static String _dayStamp(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool _alreadySentToday(
          SharedPreferences prefs, String key, DateTime now) =>
      prefs.getString(key) == _dayStamp(now);

  static Future<void> _markSent(
          SharedPreferences prefs, String key, DateTime now) =>
      prefs.setString(key, _dayStamp(now));
}
