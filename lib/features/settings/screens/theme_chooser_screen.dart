import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_bloc.dart';

class _ThemeOption {
  final String name;
  final String icon;
  final String description;
  final Color color;

  const _ThemeOption(
      {required this.name,
      required this.icon,
      required this.description,
      required this.color});
}

const _themes = [
  _ThemeOption(
      name: AppConstants.themeLight,
      icon: '🌤️',
      description: 'Sky blue — clear & breezy',
      color: AppColors.lightBg),
  _ThemeOption(
      name: AppConstants.themeDark,
      icon: '🌑',
      description: 'Starry dark night sky',
      color: AppColors.darkBg),
  _ThemeOption(
      name: AppConstants.themeCloudy,
      icon: '☁️',
      description: 'Drifting clouds overhead',
      color: AppColors.cloudyBg),
  _ThemeOption(
      name: AppConstants.themeSunny,
      icon: '☀️',
      description: 'Golden rays & sparkles',
      color: AppColors.sunnyBg),
  _ThemeOption(
      name: AppConstants.themeRainy,
      icon: '🌧️',
      description: 'Falling rain streaks',
      color: AppColors.rainyBg),
  _ThemeOption(
      name: AppConstants.themeSnowy,
      icon: '❄️',
      description: 'Drifting snowflakes',
      color: AppColors.snowyBg),
  _ThemeOption(
      name: AppConstants.themeWindy,
      icon: '💨',
      description: 'Sweeping wind streaks',
      color: AppColors.windyBg),
];

class ThemeChooserScreen extends StatelessWidget {
  const ThemeChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          appBar: AppBar(title: const Text('Theme')),
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Each theme has animated weather effects.\nAuto mode sets the theme from live weather.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _themes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = _themes[i];
                    final isSelected = themeState.themeName == t.name;
                    return GestureDetector(
                      onTap: () {
                        context
                            .read<ThemeBloc>()
                            .add(ThemeChanged(t.name));
                        Navigator.of(context).pop();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.1)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.accent, width: 2)
                              : Border.all(
                                  color: Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            // Animated mini-preview
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: _MiniThemePreview(
                                    themeName: t.name, bgColor: t.color),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('${t.icon}  ${t.name}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight:
                                                  FontWeight.w600)),
                                  Text(t.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: AppColors.accent),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Tiny animated preview tile shown in the list
// ─────────────────────────────────────────────
class _MiniThemePreview extends StatefulWidget {
  final String themeName;
  final Color bgColor;
  const _MiniThemePreview(
      {required this.themeName, required this.bgColor});

  @override
  State<_MiniThemePreview> createState() => _MiniThemePreviewState();
}

class _MiniThemePreviewState extends State<_MiniThemePreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _MiniPainter(
              themeName: widget.themeName,
              bgColor: widget.bgColor,
              progress: _ctrl.value,
              rng: _rng),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _MiniPainter extends CustomPainter {
  final String themeName;
  final Color bgColor;
  final double progress;
  final Random rng;

  _MiniPainter(
      {required this.themeName,
      required this.bgColor,
      required this.progress,
      required this.rng});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = bgColor);

    switch (themeName) {
      case AppConstants.themeRainy:
        _drawRain(canvas, size);
        break;
      case AppConstants.themeSnowy:
        _drawSnow(canvas, size);
        break;
      case AppConstants.themeSunny:
        _drawSun(canvas, size);
        break;
      case AppConstants.themeCloudy:
        _drawClouds(canvas, size);
        break;
      case AppConstants.themeWindy:
        _drawWind(canvas, size);
        break;
      case AppConstants.themeDark:
        _drawStars(canvas, size);
        break;
      default:
        _drawBubbles(canvas, size);
    }
  }

  void _drawRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 12; i++) {
      final x = (i / 12 + progress * 0.2) % 1.0 * size.width;
      final t = (progress + i * 0.08) % 1.0;
      final y = t * (size.height + 10) - 10;
      canvas.drawLine(Offset(x, y), Offset(x + 1, y + 6), paint);
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final x = (i / 8.0 + sin(progress * pi + i) * 0.05) * size.width;
      final t = (progress * 0.3 + i * 0.13) % 1.0;
      final y = t * (size.height + 4) - 4;
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  void _drawSun(Canvas canvas, Size size) {
    final cx = size.width * 0.7;
    final cy = size.height * 0.3;
    final pulse = 0.85 + sin(progress * pi * 2) * 0.15;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 8 * pulse, paint);
    final ray = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4 + progress * pi;
      canvas.drawLine(
        Offset(cx + cos(angle) * 10, cy + sin(angle) * 10),
        Offset(cx + cos(angle) * 16, cy + sin(angle) * 16),
        ray,
      );
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final t = (progress * 0.15) % 1.0;
    final cx = t * (size.width + 30) - 15;
    canvas.drawCircle(Offset(cx, size.height * 0.4), 10, paint);
    canvas.drawCircle(Offset(cx + 10, size.height * 0.35), 8, paint);
    canvas.drawCircle(Offset(cx - 8, size.height * 0.42), 7, paint);
  }

  void _drawWind(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final t = (progress * 0.8 + i * 0.2) % 1.0;
      final x = t * (size.width + 20) - 20;
      final y = size.height * (0.2 + i * 0.15);
      canvas.drawLine(Offset(x, y), Offset(x + 20, y), paint);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final x = (i * 37 % 56).toDouble();
      final y = (i * 23 % 56).toDouble() * 0.7;
      final alpha = (sin((progress + i * 0.15) * pi * 2) * 0.4 + 0.6) * 0.8;
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 1.2, paint);
    }
  }

  void _drawBubbles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = 0; i < 5; i++) {
      final t = (progress * 0.2 + i * 0.2) % 1.0;
      final x = (i * 11.5 % size.width);
      final y = size.height - t * (size.height + 10);
      canvas.drawCircle(Offset(x, y), 4 + i * 2.0, paint);
    }
  }

  @override
  bool shouldRepaint(_MiniPainter old) => true;
}
