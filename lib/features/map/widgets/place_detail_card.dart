import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/map_weather_model.dart';
import '../../../core/models/place_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_converter.dart';

/// Details of the tapped place, shown over the bottom of the map.
class PlaceDetailCard extends StatelessWidget {
  final PlaceModel place;
  final MapWeather? weather;
  final bool loading;
  final String tempUnit;
  final VoidCallback onClose;
  final VoidCallback onZoom;
  final VoidCallback onSetLocation;

  const PlaceDetailCard({
    super.key,
    required this.place,
    required this.weather,
    required this.loading,
    required this.tempUnit,
    required this.onClose,
    required this.onZoom,
    required this.onSetLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = weather;
    return Material(
      color: theme.cardColor,
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (place.subtitle.isNotEmpty)
                        Text(place.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (w == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Weather unavailable for this spot.',
                        style: theme.textTheme.bodyMedium),
              )
            else
              Row(
                children: [
                  Text(w.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(UnitConverter.formatTemp(w.tempC, tempUnit),
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(w.label, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(DateFormat('h:mm a').format(w.localNow),
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(DateFormat('EEE, d MMM').format(w.localNow),
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text('Humidity ${w.humidity}%',
                            style: theme.textTheme.bodySmall),
                        Text('Wind ${w.windKmh.round()} km/h',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onZoom,
                  icon: const Icon(Icons.zoom_in, size: 18),
                  label: const Text('Zoom here'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSetLocation,
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('Set as my location',
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
