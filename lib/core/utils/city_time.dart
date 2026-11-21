/// Helpers for showing times in the *searched city's* timezone instead of the
/// phone's timezone.
///
/// A "city time" is a UTC-flagged [DateTime] whose fields hold the wall-clock
/// time in the city (e.g. 14:30 in Tokyo is `DateTime.utc(.., 14, 30)`).
/// `DateFormat` prints those fields as-is, so no timezone conversion happens
/// at display time. Never compare a city time with a normal local [DateTime].
class CityTime {
  CityTime._();

  /// Converts a UTC epoch (seconds) to the wall-clock time in a city whose UTC
  /// offset is [offsetSeconds].
  static DateTime fromEpoch(int epochSeconds, int offsetSeconds) =>
      DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000, isUtc: true)
          .add(Duration(seconds: offsetSeconds));

  /// The current wall-clock time in a city whose UTC offset is [offsetSeconds].
  static DateTime now(int offsetSeconds) =>
      DateTime.now().toUtc().add(Duration(seconds: offsetSeconds));

  /// Converts a city wall-clock time back to its UTC epoch hour (hours since
  /// 1970-01-01T00:00Z). Used to look up hourly UV data.
  static int toEpochHour(DateTime cityTime, int offsetSeconds) =>
      ((cityTime.millisecondsSinceEpoch ~/ 1000) - offsetSeconds) ~/ 3600;
}
