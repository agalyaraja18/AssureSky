import 'package:flutter/material.dart';
import '../utils/date_formatter.dart';

/// A slim, rounded notice strip (offline mode, GPS unavailable, …).
class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const InfoBanner({
    super.key,
    required this.icon,
    required this.text,
    this.color = const Color(0xFFFF9800),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// "You're offline — showing data from 2:30 PM." Shown whenever the screen is
/// displaying cached data instead of a fresh network response.
class OfflineBanner extends StatelessWidget {
  final DateTime? cachedAt;
  const OfflineBanner({super.key, this.cachedAt});

  @override
  Widget build(BuildContext context) {
    final when = cachedAt == null ? '' : _describe(cachedAt!);
    return InfoBanner(
      icon: Icons.cloud_off,
      text: when.isEmpty
          ? 'You\'re offline — showing saved data.'
          : 'You\'re offline — showing data from $when.',
    );
  }

  /// "2:30 PM" for today, "Mon 2:30 PM" otherwise.
  static String _describe(DateTime t) {
    final now = DateTime.now();
    final sameDay =
        t.year == now.year && t.month == now.month && t.day == now.day;
    return sameDay
        ? DateFormatter.formatTime(t)
        : '${DateFormatter.formatDayName(t)} ${DateFormatter.formatTime(t)}';
  }
}
