import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/air_quality_model.dart';
import '../../../core/models/current_weather_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/utils/weather_icon_helper.dart';
import '../../../core/widgets/weather_animation_background.dart';
import '../../settings/bloc/settings_bloc.dart';

class WeatherDetailsScreen extends StatelessWidget {
  final CurrentWeatherModel weather;
  final AirQualityModel airQuality;
  final String cityName;

  const WeatherDetailsScreen({
    super.key,
    required this.weather,
    required this.airQuality,
    required this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsBloc>().state;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Details'),
        leading: const BackButton(),
      ),
      body: WeatherAnimationBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              UnitConverter.formatTemp(
                                  weather.temp, settings.tempUnit),
                              style: theme.textTheme.displayLarge,
                            ),
                            Text(weather.condition,
                                style: theme.textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(
                              'Feels like ${UnitConverter.formatTemp(weather.feelsLike, settings.tempUnit)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.location_on,
                                  color: AppColors.accent, size: 14),
                              const SizedBox(width: 4),
                              Text('$cityName, ${weather.country}',
                                  style: theme.textTheme.bodyMedium),
                            ]),
                            Text(
                              '${DateFormatter.formatFullDate(weather.dt)} · '
                              '${DateFormatter.formatTime(weather.dt)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            WeatherIconHelper.emoji(weather.conditionCode),
                            style: const TextStyle(fontSize: 64),
                          ),
                          Text(weather.condition,
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2x2 stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _StatCard(
                    icon: '💧',
                    label: 'Humidity',
                    value: '${weather.humidity}%',
                  ),
                  _StatCard(
                    icon: '💨',
                    label: 'Wind Speed',
                    value: UnitConverter.formatWind(
                        weather.windSpeed, settings.windUnit),
                  ),
                  _StatCard(
                    icon: '🔵',
                    label: 'Auto Pressure',
                    value: UnitConverter.formatPressure(
                        weather.pressure.toDouble(), settings.pressureUnit),
                  ),
                  _StatCard(
                    icon: '👁️',
                    label: 'Visibility',
                    value: UnitConverter.formatVisibility(weather.visibility),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // UV & AQI row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: '☀️',
                      label: 'UV Index',
                      value:
                          '${weather.uvIndex.toStringAsFixed(1)} ${UnitConverter.uvLabel(weather.uvIndex)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: '🌿',
                      label: 'AQI',
                      value:
                          '${airQuality.aqi500} ${airQuality.shortQualityLabel}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Air Quality section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Air Quality',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          _AqiBadge(
                              label: airQuality.shortQualityLabel,
                              aqi: airQuality.aqi500),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '${airQuality.aqi500}',
                            style: theme.textTheme.headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(' /500', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _AqiProgressBar(aqi: airQuality.aqi500),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0 Good',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.green)),
                          Text('200 Unhealthy',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.orange)),
                          Text('500 Hazardous',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.red)),
                        ],
                      ),
                    ],
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

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(label, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AqiBadge extends StatelessWidget {
  final String label;
  final int aqi;
  const _AqiBadge({required this.label, required this.aqi});

  Color get _color {
    if (aqi <= 50) return AppColors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 200) return AppColors.orange;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: _color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _AqiProgressBar extends StatelessWidget {
  final int aqi;
  const _AqiProgressBar({required this.aqi});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 12,
        child: LinearProgressIndicator(
          value: (aqi / 500).clamp(0.0, 1.0),
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(_aqiColor(aqi)),
        ),
      ),
    );
  }

  Color _aqiColor(int aqi) {
    if (aqi <= 50) return AppColors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return AppColors.orange;
    if (aqi <= 200) return Colors.deepOrange;
    return AppColors.red;
  }
}
