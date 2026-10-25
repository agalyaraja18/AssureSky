import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  static String formatDayDate(DateTime dt) => DateFormat('EEE d MMM').format(dt);

  static String formatFullDate(DateTime dt) =>
      DateFormat('EEE, d MMM yyyy').format(dt);

  static String formatHour(DateTime dt) => DateFormat('h a').format(dt);

  static String formatHourWithDay(DateTime dt) =>
      DateFormat('EEE h a').format(dt);

  static String formatDayName(DateTime dt) => DateFormat('EEE').format(dt);

  static String relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    } else if (diff.inDays == 1) {
      return '1 day ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  static String formatMonthDay(DateTime dt) => DateFormat('MMM d').format(dt);
}
