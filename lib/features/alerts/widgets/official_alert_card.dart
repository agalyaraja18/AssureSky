import 'package:flutter/material.dart';
import '../../../core/models/official_alert_model.dart';
import '../../../core/utils/date_formatter.dart';

/// Colours and icons for each severity level.
class AlertStyle {
  AlertStyle._();

  static Color color(OfficialSeverity s) {
    switch (s) {
      case OfficialSeverity.extreme:
        return const Color(0xFFC62828); // deep red
      case OfficialSeverity.severe:
        return const Color(0xFFE64A19); // red-orange
      case OfficialSeverity.moderate:
        return const Color(0xFFF9A825); // amber
      case OfficialSeverity.minor:
        return const Color(0xFF1E88E5); // blue
    }
  }

  static IconData icon(OfficialSeverity s) {
    switch (s) {
      case OfficialSeverity.extreme:
        return Icons.crisis_alert;
      case OfficialSeverity.severe:
        return Icons.warning_amber_rounded;
      case OfficialSeverity.moderate:
        return Icons.error_outline;
      case OfficialSeverity.minor:
        return Icons.info_outline;
    }
  }

  /// Short region name for the filter chips and badges.
  static String region(String provider) {
    switch (provider) {
      case 'ndma':
        return 'India';
      case 'nws':
        return 'USA';
      case 'eccc':
        return 'Canada';
      case 'meteoalarm':
        return 'Europe';
      case 'gdacs':
        return 'Global';
      default:
        return provider;
    }
  }
}

/// Text helpers shared by the list card, the home card and the detail screen.
class AlertFormat {
  AlertFormat._();

  /// "Issued 20 Nov, 11:15 AM"
  static String issued(OfficialAlert a) => DateFormatter.formatAlertTime(a.issued);

  /// When the hazard starts and ends, in plain words.
  static String duration(OfficialAlert a, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final start = a.start;
    final end = a.end;

    String t(DateTime d) => DateFormatter.formatAlertTime(d);

    if (start != null && end != null) {
      final verb = start.isAfter(clock) ? 'Starts' : 'Started';
      return '$verb ${t(start)}  →  Ends ${t(end)}';
    }
    if (end != null) return 'Until ${t(end)}';
    if (start != null) {
      final verb = start.isAfter(clock) ? 'Starts' : 'Started';
      return '$verb ${t(start)}  →  End time not published';
    }
    return 'Ongoing — timing not published';
  }
}

/// One official alert, in the format: title · severity · location · issued ·
/// expected duration · description · safety instructions · source.
///
/// [compact] is used on the home dashboard; the full card is used in the Alerts
/// tab. Tapping opens the detail screen via [onTap].
class OfficialAlertCard extends StatelessWidget {
  final OfficialAlert alert;
  final bool compact;
  final VoidCallback? onTap;

  const OfficialAlertCard({
    super.key,
    required this.alert,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AlertStyle.color(alert.severity);

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.85), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Severity + region
              Row(
                children: [
                  SeverityBadge(severity: alert.severity),
                  const Spacer(),
                  Text(
                    AlertStyle.region(alert.provider),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Alert title
              Text(
                alert.title,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              AlertField(
                icon: Icons.place_outlined,
                label: 'Location',
                value: alert.location,
                maxLines: compact ? 1 : 2,
              ),
              if (!compact)
                AlertField(
                  icon: Icons.schedule,
                  label: 'Issued',
                  value: AlertFormat.issued(alert),
                ),
              AlertField(
                icon: Icons.timelapse,
                label: 'Duration',
                value: AlertFormat.duration(alert),
                maxLines: 2,
              ),

              if (alert.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                AlertField(
                  icon: Icons.notes,
                  label: 'Description',
                  value: alert.description.trim(),
                  maxLines: compact ? 2 : 3,
                ),
              ],

              if (!compact) ...[
                AlertField(
                  icon: Icons.health_and_safety_outlined,
                  label: alert.instructionsAreGeneral
                      ? 'Safety (general)'
                      : 'Safety',
                  value: alert.instructions.trim(),
                  maxLines: 3,
                ),
                AlertField(
                  icon: Icons.verified_outlined,
                  label: 'Source',
                  value: alert.source,
                  maxLines: 2,
                ),
              ],

              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View full alert →',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "● Severe" pill.
class SeverityBadge extends StatelessWidget {
  final OfficialSeverity severity;
  final bool large;
  const SeverityBadge({super.key, required this.severity, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = AlertStyle.color(severity);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 14 : 10, vertical: large ? 6 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AlertStyle.icon(severity), size: large ? 18 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            severity.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: large ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// A "label: value" row with a leading icon.
class AlertField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int? maxLines;

  const AlertField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ]),
              maxLines: maxLines,
              overflow: maxLines == null ? null : TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
