import 'package:flutter/material.dart';
import '../../../core/models/official_alert_model.dart';
import '../../../core/widgets/weather_animation_background.dart';
import '../widgets/official_alert_card.dart';

/// Every field of one official alert, un-truncated.
class AlertDetailScreen extends StatelessWidget {
  final OfficialAlert alert;
  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AlertStyle.color(alert.severity);

    return Scaffold(
      appBar: AppBar(title: const Text('Weather alert')),
      body: WeatherAnimationBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + severity (full width, like the sections below)
                SizedBox(
                  width: double.infinity,
                  child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: color, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SeverityBadge(severity: alert.severity, large: true),
                        const SizedBox(height: 12),
                        SelectableText(
                          alert.title,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
                const SizedBox(height: 12),

                _Section(
                  icon: Icons.place_outlined,
                  title: 'Location',
                  body: alert.location,
                ),
                _Section(
                  icon: Icons.schedule,
                  title: 'Issued',
                  body: AlertFormat.issued(alert),
                ),
                _Section(
                  icon: Icons.timelapse,
                  title: 'Expected duration',
                  body: AlertFormat.duration(alert),
                ),
                _Section(
                  icon: Icons.notes,
                  title: 'Description',
                  body: alert.description.trim().isEmpty
                      ? 'The issuing authority did not publish a description.'
                      : alert.description.trim(),
                ),
                _Section(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Safety instructions',
                  body: alert.instructions.trim(),
                  note: alert.instructionsAreGeneral
                      ? 'General guidance for this type of hazard — the issuing '
                          'authority published no specific instructions. Always '
                          'follow instructions from local emergency services first.'
                      : null,
                ),
                _Section(
                  icon: Icons.verified_outlined,
                  title: 'Source',
                  body: alert.source,
                ),
                const SizedBox(height: 4),
                Text(
                  'Times are shown in your phone\'s local time.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? note;

  const _Section({
    required this.icon,
    required this.title,
    required this.body,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              body,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(height: 1.45, color: theme.textTheme.bodyLarge?.color),
            ),
            if (note != null) ...[
              const SizedBox(height: 8),
              Text(
                note!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
