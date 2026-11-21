import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/map_weather_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_converter.dart';

/// Size of one marker on the map. Also used for overlap culling.
const Size weatherMarkerSize = Size(96, 58);

/// Small card on the map: weather icon + temperature, place name, local time.
class WeatherMarker extends StatelessWidget {
  final String name;
  final MapWeather? weather;
  final String tempUnit;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback onTap;

  const WeatherMarker({
    super.key,
    required this.name,
    required this.weather,
    required this.tempUnit,
    required this.onTap,
    this.isCurrent = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = weather;
    final highlight = isCurrent || isSelected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? AppColors.accent : Colors.black26,
            width: highlight ? 2 : 0.8,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(w?.emoji ?? '⏳', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 3),
                Text(
                  w == null ? '--' : UnitConverter.formatTemp(w.tempC, tempUnit),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold, height: 1.1),
                ),
              ],
            ),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600, height: 1.15),
            ),
            Text(
              w == null ? '' : DateFormat('h:mm a').format(w.localNow),
              style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10.5, height: 1.1, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
