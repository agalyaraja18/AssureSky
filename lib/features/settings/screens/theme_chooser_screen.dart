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
  _ThemeOption(
      name: AppConstants.themeThunderstorm,
      icon: '⛈️',
      description: 'Heavy rain & lightning flashes',
      color: AppColors.thunderstormBg),
  _ThemeOption(
      name: AppConstants.themeCyclone,
      icon: '🌀',
      description: 'Swirling storm around a calm eye',
      color: AppColors.cycloneBg),
  _ThemeOption(
      name: AppConstants.themeTornado,
      icon: '🌪️',
      description: 'Twisting funnel & flying debris',
      color: AppColors.tornadoBg),
  _ThemeOption(
      name: AppConstants.themeHail,
      icon: '🧊',
      description: 'Fast-falling hailstones',
      color: AppColors.hailBg),
  _ThemeOption(
      name: AppConstants.themeFoggy,
      icon: '🌫️',
      description: 'Soft drifting fog banks',
      color: AppColors.foggyBg),
  _ThemeOption(
      name: AppConstants.themeHot,
      icon: '🥵',
      description: 'Blazing sun & rising heat shimmer',
      color: AppColors.hotBg),
  _ThemeOption(
      name: AppConstants.themeCold,
      icon: '🥶',
      description: 'Frosty air & twinkling ice crystals',
      color: AppColors.coldBg),
  _ThemeOption(
      name: AppConstants.themeHumid,
      icon: '💦',
      description: 'Muggy air & sliding droplets',
      color: AppColors.humidBg),
  _ThemeOption(
      name: AppConstants.themeBreezy,
      icon: '🍃',
      description: 'Gentle breeze & drifting leaves',
      color: AppColors.breezyBg),
  _ThemeOption(
      name: AppConstants.themeOvercast,
      icon: '🌥️',
      description: 'Thick, heavy cloud cover',
      color: AppColors.overcastBg),
  _ThemeOption(
      name: AppConstants.themeHaze,
      icon: '😶‍🌫️',
      description: 'Dusty, murky air',
      color: AppColors.hazeBg),
  _ThemeOption(
      name: AppConstants.themeMist,
      icon: '🌁',
      description: 'Fine wisps of morning mist',
      color: AppColors.mistBg),
  _ThemeOption(
      name: AppConstants.themeLightning,
      icon: '🌩️',
      description: 'Dark clouds & striking lightning',
      color: AppColors.lightningBg),
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
      case AppConstants.themeThunderstorm:
        _drawRain(canvas, size);
        _drawLightning(canvas, size);
        break;
      case AppConstants.themeCyclone:
        _drawCyclone(canvas, size);
        break;
      case AppConstants.themeTornado:
        _drawTornado(canvas, size);
        break;
      case AppConstants.themeHail:
        _drawHail(canvas, size);
        break;
      case AppConstants.themeFoggy:
        _drawFog(canvas, size);
        break;
      case AppConstants.themeHot:
        _drawHot(canvas, size);
        break;
      case AppConstants.themeCold:
        _drawCold(canvas, size);
        break;
      case AppConstants.themeHumid:
        _drawHumid(canvas, size);
        break;
      case AppConstants.themeBreezy:
        _drawBreezy(canvas, size);
        break;
      case AppConstants.themeOvercast:
        _drawOvercast(canvas, size);
        break;
      case AppConstants.themeHaze:
        _drawHaze(canvas, size);
        break;
      case AppConstants.themeMist:
        _drawMist(canvas, size);
        break;
      case AppConstants.themeLightning:
        _drawOvercast(canvas, size, tint: const Color(0xFF4B4887));
        _drawLightning(canvas, size);
        break;
      default:
        _drawBubbles(canvas, size);
    }
  }

  void _drawHot(Canvas canvas, Size size) {
    final pulse = 0.85 + sin(progress * pi * 2) * 0.15;
    final c = Offset(size.width * 0.78, size.height * 0.2);
    canvas.drawCircle(
        c,
        size.width * 0.5 * pulse,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFE082).withValues(alpha: 0.8),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: c, radius: size.width * 0.5)));
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (int i = 0; i < 3; i++) {
      final t = (progress * 0.6 + i * 0.33) % 1.0;
      final base = size.height * (1 - t);
      final path = Path();
      for (double x = 0; x <= size.width; x += 5) {
        final y = base + sin(x / size.width * pi * 4 + progress * pi * 6) * 3;
        x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, line);
    }
  }

  void _drawCold(Canvas canvas, Size size) {
    for (int i = 0; i < 7; i++) {
      final twinkle = (sin((progress * 2 + i * 0.17) * pi * 2) + 1) / 2;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25 + twinkle * 0.7)
        ..strokeWidth = 1;
      final c = Offset((i * 23 % 52) + 2.0, (i * 31 % 50) + 3.0);
      final r = 2.5 + twinkle * 2.5;
      canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), paint);
      canvas.drawLine(c.translate(0, -r), c.translate(0, r), paint);
    }
  }

  void _drawHumid(Canvas canvas, Size size) {
    for (int i = 0; i < 6; i++) {
      final t = (progress * 0.4 + i * 0.17) % 1.0;
      final x = (i * 19 % 50) + 4.0;
      final y = t * (size.height + 6) - 3;
      canvas.drawLine(
          Offset(x, y - 7),
          Offset(x, y),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..strokeWidth = 1.5);
      canvas.drawCircle(Offset(x, y), 2.2,
          Paint()..color = Colors.white.withValues(alpha: 0.85));
    }
  }

  void _drawBreezy(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final t = (progress * 0.5 + i * 0.25) % 1.0;
      final x0 = t * (size.width + 24) - 24;
      final y = size.height * (0.2 + i * 0.2);
      final path = Path()
        ..moveTo(x0, y)
        ..cubicTo(x0 + 6, y - 5, x0 + 14, y + 5, x0 + 24, y - 2);
      canvas.drawPath(path, paint);
    }
    final t = (progress * 0.7) % 1.0;
    canvas.drawCircle(Offset(t * size.width, size.height * 0.7 + sin(t * pi * 4) * 6),
        2.5, Paint()..color = const Color(0xFF66BB6A));
  }

  void _drawOvercast(Canvas canvas, Size size,
      {Color tint = const Color(0xFF546E7A)}) {
    for (int i = 0; i < 4; i++) {
      final t = (progress * 0.15 + i * 0.25) % 1.0;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(t * (size.width + 40) - 20, size.height * (0.12 + i * 0.16)),
            width: 46,
            height: 18),
        Paint()
          ..color = tint.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
  }

  void _drawHaze(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.5),
          width: size.width,
          height: size.height * 0.5),
      Paint()
        ..color = const Color(0xFFE9D8AE).withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    for (int i = 0; i < 10; i++) {
      final x = ((i * 13 % 56) + progress * 14) % size.width;
      final y = (i * 29 % 54) + sin((progress + i * 0.1) * pi * 2) * 2;
      canvas.drawCircle(Offset(x, y), 1.1,
          Paint()..color = const Color(0xFFA67C37).withValues(alpha: 0.7));
    }
  }

  void _drawMist(Canvas canvas, Size size) {
    for (int i = 0; i < 4; i++) {
      final t = (progress * 0.3 + i * 0.25) % 1.0;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(t * (size.width + 40) - 20, size.height * (0.15 + i * 0.22)),
            width: 38,
            height: 5),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  void _drawLightning(Canvas canvas, Size size) {
    // Flash during the first 12% of each loop.
    if (progress > 0.12) return;
    final flash = 1 - progress / 0.12;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white.withValues(alpha: 0.25 * flash));
    final bolt = Path()
      ..moveTo(size.width * 0.6, 0)
      ..lineTo(size.width * 0.45, size.height * 0.4)
      ..lineTo(size.width * 0.58, size.height * 0.4)
      ..lineTo(size.width * 0.4, size.height * 0.85);
    canvas.drawPath(
        bolt,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.95 * flash)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round);
  }

  void _drawCyclone(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int i = 0; i < 28; i++) {
      final r = 0.12 + (i / 28) * 0.88;
      final angle = i * 0.9 + r * 5 - progress * pi * 2 * (1.8 - r);
      final dist = r * size.width * 0.5;
      paint.color = Colors.white.withValues(alpha: 0.75 * (1 - r * 0.5));
      canvas.drawCircle(
          Offset(cx + cos(angle) * dist, cy + sin(angle) * dist * 0.6),
          1.4,
          paint);
    }
  }

  void _drawTornado(Canvas canvas, Size size) {
    final funnel = Path()
      ..moveTo(size.width * 0.1, size.height * 0.1)
      ..lineTo(size.width * 0.9, size.height * 0.1)
      ..lineTo(size.width * 0.54, size.height * 0.92)
      ..lineTo(size.width * 0.46, size.height * 0.92)
      ..close();
    canvas.drawPath(
        funnel, Paint()..color = Colors.white.withValues(alpha: 0.18));
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 14; i++) {
      final h = i / 14;
      final spread = size.width * (0.4 * pow(1 - h, 1.3) + 0.04);
      final angle = i * 1.7 + progress * pi * 2 * (1 + (i % 3) * 0.5);
      paint.color = (i.isEven ? Colors.white : Colors.black)
          .withValues(alpha: 0.6);
      canvas.drawCircle(
          Offset(size.width / 2 + cos(angle) * spread,
              size.height * (0.1 + h * 0.82) + sin(angle) * spread * 0.15),
          1.3,
          paint);
    }
  }

  void _drawHail(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (int i = 0; i < 10; i++) {
      final x = (i * 17 % 56).toDouble();
      final t = (progress * 1.6 + i * 0.1) % 1.0;
      canvas.drawCircle(Offset(x, t * (size.height + 6) - 3), 2.4, paint);
    }
  }

  void _drawFog(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      final t = (progress * 0.4 + i * 0.33) % 1.0;
      final cx = t * (size.width + 40) - 20;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, size.height * (0.25 + i * 0.25)),
            width: 40,
            height: 14),
        Paint()
          ..color = (i.isEven ? Colors.white : const Color(0xFF8E99A0))
              .withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
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
