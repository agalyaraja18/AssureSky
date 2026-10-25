import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/settings_bloc.dart';

class PressureUnitScreen extends StatelessWidget {
  const PressureUnitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        return Scaffold(
          appBar: AppBar(title: const Text('Automatic Pressure')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PressureTile(
                icon: '🔵',
                title: 'Hectopascals (hPa)',
                subtitle: 'Global meteorological standard',
                value: AppConstants.pressureHpa,
                groupValue: settings.pressureUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(PressureUnitChanged(v!)),
              ),
              _PressureTile(
                icon: '🔵',
                title: 'Millibars (mb)',
                subtitle: 'Equivalent to hectopascals',
                value: AppConstants.pressureMb,
                groupValue: settings.pressureUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(PressureUnitChanged(v!)),
              ),
              _PressureTile(
                icon: '🔵',
                title: 'Inches of mercury (inHg)',
                subtitle: 'Imperial pressure unit',
                value: AppConstants.pressureInhg,
                groupValue: settings.pressureUnit,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(PressureUnitChanged(v!)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PressureTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PressureTile({
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
