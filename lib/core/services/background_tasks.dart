import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../constants/app_constants.dart';
import 'notification_dispatcher.dart';
import 'notification_service.dart';
import 'weather_repository.dart';

const String _taskName = 'assuresky.weatherCheck';
const String _uniqueName = 'assuresky.weatherCheck.periodic';

/// Entry point for the Android background worker. Runs in its own isolate,
/// roughly hourly, even when the app is closed.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    try {
      await BackgroundTasks.runWeatherCheck();
    } catch (_) {
      // Never let a failed check trigger WorkManager's aggressive retry loop;
      // the next periodic run will try again.
    }
    return true;
  });
}

class BackgroundTasks {
  BackgroundTasks._();

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Schedules the hourly weather check (Android). WorkManager's minimum
  /// period is 15 minutes; hourly keeps battery and API usage low.
  static Future<void> register() async {
    if (!_supported) return;
    await Workmanager().initialize(backgroundCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _uniqueName,
      _taskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  /// One background check: load weather for the last known location and send
  /// any notifications that are due.
  static Future<void> runWeatherCheck() async {
    final prefs = await SharedPreferences.getInstance();
    // Pick up settings / location the app saved since this isolate started.
    await prefs.reload();

    final anyEnabled =
        (prefs.getBool(AppConstants.keyNotifWeatherAlerts) ?? true) ||
            (prefs.getBool(AppConstants.keyNotifDailyForecast) ?? true) ||
            (prefs.getBool(AppConstants.keyNotifAskyAdvice) ?? true) ||
            (prefs.getBool(AppConstants.keyNotifTrendingNews) ?? false);
    if (!anyEnabled) return;

    // The worker can't use GPS reliably in the background, so it uses the
    // location the app last saved (the last GPS fix, or the chosen city).
    final lat = prefs.getDouble(AppConstants.keySavedLat);
    final lon = prefs.getDouble(AppConstants.keySavedLon);
    if (lat == null || lon == null) return;
    final city = prefs.getString(AppConstants.keySavedCityName) ?? '';

    await NotificationService.init();
    final data = await WeatherRepository().getWeatherData(lat, lon);
    await NotificationDispatcher.process(data, cityName: city);
  }
}
