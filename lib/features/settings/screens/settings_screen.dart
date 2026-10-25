import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_bloc.dart';
import '../../home/bloc/home_bloc.dart';
import '../bloc/settings_bloc.dart';
import 'about_screen.dart';
import 'feedback_screen.dart';
import 'pressure_unit_screen.dart';
import 'search_location_screen.dart';
import 'temp_unit_screen.dart';
import 'theme_chooser_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        final themeState = context.watch<ThemeBloc>().state;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('Settings',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),

                // PREFERENCES
                _SectionHeader(label: 'PREFERENCES'),
                Card(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: '🎨',
                        label: 'Theme',
                        value: themeState.themeName,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                    value: context.read<ThemeBloc>(),
                                    child: const ThemeChooserScreen()))),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: '📍',
                        label: 'Location',
                        value: settings.cityName,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                  value: context.read<SettingsBloc>()),
                              BlocProvider.value(
                                  value: context.read<HomeBloc>()),
                            ],
                            child: const SearchLocationScreen(),
                          ),
                        )),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: '🌡️',
                        label: 'Temperature Unit',
                        value: settings.tempUnit,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                              value: context.read<SettingsBloc>(),
                              child: const TempUnitScreen()),
                        )),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: '💨',
                        label: 'Wind Speed',
                        value: settings.windUnit,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                              value: context.read<SettingsBloc>(),
                              child: const WindUnitScreen()),
                        )),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: '🔵',
                        label: 'Automatic Pressure',
                        value: settings.pressureUnit,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                              value: context.read<SettingsBloc>(),
                              child: const PressureUnitScreen()),
                        )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // NOTIFICATIONS
                _SectionHeader(label: 'NOTIFICATIONS'),
                Card(
                  child: Column(
                    children: [
                      _NotifTile(
                        icon: '🔔',
                        label: 'Weather Alerts',
                        value: settings.notifWeatherAlerts,
                        onChanged: (v) => context.read<SettingsBloc>().add(
                            NotificationToggled(
                                AppConstants.keyNotifWeatherAlerts, v)),
                      ),
                      _Divider(),
                      _NotifTile(
                        icon: '🌤️',
                        label: 'Asky Advice',
                        value: settings.notifAskyAdvice,
                        onChanged: (v) => context.read<SettingsBloc>().add(
                            NotificationToggled(
                                AppConstants.keyNotifAskyAdvice, v)),
                      ),
                      _Divider(),
                      _NotifTile(
                        icon: '📰',
                        label: 'Weather Trending News',
                        value: settings.notifTrendingNews,
                        onChanged: (v) => context.read<SettingsBloc>().add(
                            NotificationToggled(
                                AppConstants.keyNotifTrendingNews, v)),
                      ),
                      _Divider(),
                      _NotifTile(
                        icon: '📅',
                        label: 'Daily Forecast',
                        value: settings.notifDailyForecast,
                        onChanged: (v) => context.read<SettingsBloc>().add(
                            NotificationToggled(
                                AppConstants.keyNotifDailyForecast, v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ABOUT
                _SectionHeader(label: 'ABOUT'),
                Card(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: 'ℹ️',
                        label: 'About AssureSky',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AboutScreen())),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: '💬',
                        label: 'Feedback',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const FeedbackScreen())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'AssureSky v1.0.0 · Made with ❤',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppColors.accent,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _SettingsTile(
      {required this.icon,
      required this.label,
      this.value,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 20)),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(value!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.accent)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 20)),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.accent,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1,
        indent: 56,
        color: Theme.of(context).dividerColor);
  }
}
