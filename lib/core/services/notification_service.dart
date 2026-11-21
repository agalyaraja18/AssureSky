import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// A notification category. On Android each one is a separate channel that the
/// user can mute independently in system settings.
class NotificationChannelInfo {
  final String id;
  final String name;
  final String description;
  final Importance importance;
  const NotificationChannelInfo(
      this.id, this.name, this.description, this.importance);
}

/// Thin wrapper around `flutter_local_notifications`.
///
/// Safe to call on every platform: on web / desktop it does nothing.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const NotificationChannelInfo alertsChannel = NotificationChannelInfo(
    'weather_alerts',
    'Weather alerts',
    'Severe weather warnings such as storms, heatwaves and poor air quality',
    Importance.high,
  );
  static const NotificationChannelInfo dailyChannel = NotificationChannelInfo(
    'daily_forecast',
    'Daily forecast',
    'A morning summary of today\'s weather',
    Importance.defaultImportance,
  );
  static const NotificationChannelInfo askyChannel = NotificationChannelInfo(
    'asky_advice',
    'Asky advice',
    'Daily tips from Asky, your weather advisor',
    Importance.defaultImportance,
  );
  static const NotificationChannelInfo newsChannel = NotificationChannelInfo(
    'trending_news',
    'Weather news',
    'Trending weather news headlines',
    Importance.low,
  );

  // Stable ids so a newer notification replaces the older one of its kind.
  static const int dailyId = 2001;
  static const int askyId = 2002;
  static const int newsId = 2003;
  static const int testId = 9000;

  /// Alert notifications use ids from this base so each alert kind has its own.
  static const int alertBaseId = 1000;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Must be called once per isolate (the app, and the background worker).
  static Future<void> init() async {
    if (_initialized || !_supported) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_asky'),
      // Permission is requested explicitly via [requestPermission].
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Asks the OS for permission to show notifications (Android 13+ and iOS).
  /// Returns true when notifications are allowed.
  static Future<bool> requestPermission() async {
    if (!_supported) return false;
    await init();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(
            alert: true, badge: true, sound: true) ??
        false;
  }

  /// Whether the OS currently lets this app post notifications (the Android 13+
  /// runtime permission, the system "show notifications" switch, or iOS).
  static Future<bool> areEnabled() async {
    if (!_supported) return false;
    await init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final options = await ios?.checkPermissions();
    return options?.isEnabled ?? false;
  }

  /// Shows a notification. Returns false (and shows nothing) when the OS is
  /// blocking notifications, so callers don't record it as "already sent".
  static Future<bool> show({
    required int id,
    required NotificationChannelInfo channel,
    required String title,
    required String body,
  }) async {
    if (!_supported) return false;
    await init();
    if (!await areEnabled()) return false;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: channel.importance == Importance.high
            ? Priority.high
            : Priority.defaultPriority,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
    return true;
  }
}
