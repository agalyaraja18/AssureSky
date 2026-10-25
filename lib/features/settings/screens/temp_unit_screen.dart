import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/settings_bloc.dart';

class TempUnitScreen extends StatelessWidget {
  const TempUnitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        return Scaffold(
          appBar: AppBar(title: const Text('Temperature Unit')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _UnitTile(
                icon: '🌡️',
                title: 'Celsius (°C)',
                subtitle: 'Metric temperature scale',
                value: AppConstants.tempCelsius,
                groupValue: settings.tempUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(TempUnitChanged(v!)),
              ),
              _UnitTile(
                icon: '🌡️',
                title: 'Fahrenheit (°F)',
                subtitle: 'Imperial temperature scale',
                value: AppConstants.tempFahrenheit,
                groupValue: settings.tempUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(TempUnitChanged(v!)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WindUnitScreen extends StatelessWidget {
  const WindUnitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        return Scaffold(
          appBar: AppBar(title: const Text('Wind Speed')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _UnitTile(
                icon: '💨',
                title: 'Meters per second (m/s)',
                subtitle: 'Metric scientific standard',
                value: AppConstants.windMs,
                groupValue: settings.windUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(WindUnitChanged(v!)),
              ),
              _UnitTile(
                icon: '💨',
                title: 'Kilometres per hour (km/h)',
                subtitle: 'Metric everyday speed',
                value: AppConstants.windKmh,
                groupValue: settings.windUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(WindUnitChanged(v!)),
              ),
              _UnitTile(
                icon: '💨',
                title: 'Miles per hour (mph)',
                subtitle: 'Imperial speed',
                value: AppConstants.windMph,
                groupValue: settings.windUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(WindUnitChanged(v!)),
              ),
              _UnitTile(
                icon: '⛵',
                title: 'Knots (kt / kn)',
                subtitle: 'Marine and aviation speed',
                value: AppConstants.windKnots,
                groupValue: settings.windUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(WindUnitChanged(v!)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UnitTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _UnitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.accent, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal)),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
