import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About AssureSky')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Logo + name
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('🌤️', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    Text('AssureSky',
                        style: theme.textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('v1.0.0',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.accent)),
                    const SizedBox(height: 4),
                    Text('Made with ❤',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                    Text(
                      'AssureSky is a smart weather app designed to help you plan your '
                      'day with confidence. It combines accurate weather data with '
                      'AI-powered advice through Asky — your personal weather advisor.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Features
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FEATURES',
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: AppColors.accent)),
                    const SizedBox(height: 16),
                    ..._features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['icon']!,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(f['text']!,
                                  style: theme.textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _features = [
  {
    'icon': '🌡️',
    'text':
        'Real-time temperature, humidity, wind, UV, pressure & AQI'
  },
  {
    'icon': '📅',
    'text': '7-day forecast and full 24-hour hourly breakdown'
  },
  {
    'icon': '🤖',
    'text': 'Asky AI advisor — smart tips based on current weather'
  },
  {
    'icon': '📰',
    'text': 'Live weather news from across India and the world'
  },
  {
    'icon': '🌅',
    'text': 'Sunrise & sunset times for your location'
  },
];
