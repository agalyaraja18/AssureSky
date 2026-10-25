import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_constants.dart';
import '../theme/theme_bloc.dart';

// ─────────────────────────────────────────────
// Public wrapper widget
// ─────────────────────────────────────────────
/// Wraps [child] with an animated weather background that matches the current
/// [ThemeBloc] theme. All auto/manual theme logic lives in [ThemeBloc] and is
/// never touched here — this widget purely reads the theme name.
class WeatherAnimationBackground extends StatelessWidget {
  final Widget child;
  const WeatherAnimationBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Stack(
          children: [
            // Animated particle layer
            Positioned.fill(
              child: _AnimatedLayer(themeName: themeState.themeName),
            ),
            // App content on top
            child,
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Animated layer (owns the AnimationController)
// ─────────────────────────────────────────────
class _AnimatedLayer extends StatefulWidget {
  final String themeName;
  const _AnimatedLayer({required this.themeName});

  @override
  State<_AnimatedLayer> createState() => _AnimatedLayerState();
}

class _AnimatedLayerState extends State<_AnimatedLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _particles = _buildParticles(widget.themeName);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didUpdateWidget(_AnimatedLayer old) {
    super.didUpdateWidget(old);
    if (old.themeName != widget.themeName) {
      _particles = _buildParticles(widget.themeName);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Particle> _buildParticles(String theme) {
    switch (theme) {
      case AppConstants.themeRainy:
        return List.generate(80, (_) => _RainDrop(_rng));
      case AppConstants.themeSnowy:
        return List.generate(55, (_) => _Snowflake(_rng));
      case AppConstants.themeSunny:
        return List.generate(12, (_) => _SunRay(_rng))
          ..addAll(List.generate(25, (_) => _Sparkle(_rng)));
      case AppConstants.themeCloudy:
        return List.generate(6, (_) => _Cloud(_rng));
      case AppConstants.themeWindy:
        return List.generate(40, (_) => _WindStreak(_rng));
      case AppConstants.themeDark:
        return List.generate(70, (_) => _Star(_rng));
      default: // Light + fallback
        return List.generate(18, (_) => _Bubble(_rng));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _WeatherPainter(
            particles: _particles,
            progress: _controller.value,
            themeName: widget.themeName,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// CustomPainter
// ─────────────────────────────────────────────
class _WeatherPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final String themeName;

  _WeatherPainter({
    required this.particles,
    required this.progress,
    required this.themeName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      p.draw(canvas, size, progress);
    }
  }

  @override
  bool shouldRepaint(_WeatherPainter old) => true;
}

// ─────────────────────────────────────────────
// Base particle
// ─────────────────────────────────────────────
abstract class _Particle {
  void draw(Canvas canvas, Size size, double progress);
}

// ─────────────────────────────────────────────
// 🌧️ Rain Drop
// ─────────────────────────────────────────────
class _RainDrop extends _Particle {
  final double x;       // 0..1 normalised start x
  final double phase;   // offset so drops aren't synced
  final double speed;   // fall speed multiplier
  final double length;  // drop length in px
  final double opacity;

  _RainDrop(Random rng)
      : x = rng.nextDouble(),
        phase = rng.nextDouble(),
        speed = 0.6 + rng.nextDouble() * 0.8,
        length = 12 + rng.nextDouble() * 18,
        opacity = 0.25 + rng.nextDouble() * 0.35;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final px = x * size.width + t * size.width * 0.08; // slight diagonal
    final py = t * (size.height + length) - length;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(px, py),
      Offset(px + length * 0.15, py + length),
      paint,
    );
  }
}

// ─────────────────────────────────────────────
// ❄️ Snowflake
// ─────────────────────────────────────────────
class _Snowflake extends _Particle {
  final double x;
  final double phase;
  final double speed;
  final double size;
  final double swing;   // horizontal oscillation amplitude
  final double opacity;

  _Snowflake(Random rng)
      : x = rng.nextDouble(),
        phase = rng.nextDouble(),
        speed = 0.08 + rng.nextDouble() * 0.12,
        size = 4 + rng.nextDouble() * 8,
        swing = 0.02 + rng.nextDouble() * 0.04,
        opacity = 0.55 + rng.nextDouble() * 0.35;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final swingX = sin(t * pi * 6) * swing;
    final px = (x + swingX) * size.width;
    final py = t * (size.height + this.size * 2) - this.size;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Draw a 6-arm snowflake using lines
    canvas.save();
    canvas.translate(px, py);
    final armPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      canvas.save();
      canvas.rotate(i * pi / 3);
      canvas.drawLine(Offset.zero, Offset(0, -this.size / 2), armPaint);
      canvas.restore();
    }
    canvas.restore();
    canvas.drawCircle(Offset(px, py), this.size / 5, paint);
  }
}

// ─────────────────────────────────────────────
// ☀️ Sun Ray
// ─────────────────────────────────────────────
class _SunRay extends _Particle {
  final double angleOffset;
  final double lengthFactor; // 0..1

  _SunRay(Random rng)
      : angleOffset = rng.nextDouble() * pi * 2,
        lengthFactor = 0.5 + rng.nextDouble() * 0.5;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    // Pulsing sun in top-right
    final cx = size.width * 0.78;
    final cy = size.height * 0.12;
    final pulse = 0.85 + sin(progress * pi * 2) * 0.15;
    final maxLen = size.width * 0.18 * lengthFactor * pulse;
    final angle = angleOffset + progress * pi * 0.5;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx + cos(angle) * 28, cy + sin(angle) * 28),
      Offset(cx + cos(angle) * (28 + maxLen), cy + sin(angle) * (28 + maxLen)),
      paint,
    );
  }
}

// ─────────────────────────────────────────────
// ✨ Sparkle
// ─────────────────────────────────────────────
class _Sparkle extends _Particle {
  final double x, y;
  final double phase;
  final double size;

  _Sparkle(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        phase = rng.nextDouble(),
        size = 2 + rng.nextDouble() * 4;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final alpha = (sin((progress + phase) * pi * 2) * 0.5 + 0.5) * 0.5;
    if (alpha < 0.05) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final px = x * size.width;
    final py = y * size.height;
    canvas.drawCircle(Offset(px, py), this.size * alpha, paint);
  }
}

// ─────────────────────────────────────────────
// ☁️ Cloud
// ─────────────────────────────────────────────
class _Cloud extends _Particle {
  final double y;       // vertical position 0..1
  final double speed;
  final double phase;
  final double scale;
  final double opacity;

  _Cloud(Random rng)
      : y = rng.nextDouble() * 0.4,
        speed = 0.03 + rng.nextDouble() * 0.04,
        phase = rng.nextDouble(),
        scale = 0.5 + rng.nextDouble() * 0.8,
        opacity = 0.12 + rng.nextDouble() * 0.18;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final px = t * (size.width + 200) - 200;
    final py = y * size.height;
    final s = scale * 60.0;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Three overlapping circles forming a cloud shape
    canvas.drawCircle(Offset(px, py), s * 0.6, paint);
    canvas.drawCircle(Offset(px + s * 0.7, py + s * 0.1), s * 0.5, paint);
    canvas.drawCircle(Offset(px - s * 0.6, py + s * 0.15), s * 0.45, paint);
    canvas.drawCircle(Offset(px + s * 0.35, py - s * 0.25), s * 0.55, paint);

    // Bottom fill to make cloud look solid
    final rect = Rect.fromLTRB(px - s * 1.1, py, px + s * 1.2, py + s * 0.5);
    canvas.drawRect(rect, paint);
  }
}

// ─────────────────────────────────────────────
// 💨 Wind Streak
// ─────────────────────────────────────────────
class _WindStreak extends _Particle {
  final double y;
  final double phase;
  final double speed;
  final double length;
  final double opacity;
  final double thickness;

  _WindStreak(Random rng)
      : y = rng.nextDouble(),
        phase = rng.nextDouble(),
        speed = 0.4 + rng.nextDouble() * 0.6,
        length = 30 + rng.nextDouble() * 80,
        opacity = 0.1 + rng.nextDouble() * 0.2,
        thickness = 0.8 + rng.nextDouble() * 1.5;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final px = t * (size.width + length) - length;
    final py = y * size.height;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(px, py), Offset(px + length, py), paint);
  }
}

// ─────────────────────────────────────────────
// 🌑 Star (for Dark theme)
// ─────────────────────────────────────────────
class _Star extends _Particle {
  final double x, y;
  final double phase;
  final double size;

  _Star(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble() * 0.7, // stars in upper 70%
        phase = rng.nextDouble(),
        size = 0.8 + rng.nextDouble() * 2.2;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final alpha =
        (sin((progress + phase) * pi * 2) * 0.4 + 0.6) * 0.75;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(x * size.width, y * size.height),
      this.size,
      paint,
    );
  }
}

// ─────────────────────────────────────────────
// 🌤️ Bubble (Light / default theme)
// ─────────────────────────────────────────────
class _Bubble extends _Particle {
  final double x;
  final double phase;
  final double speed;
  final double size;
  final double swing;
  final double opacity;

  _Bubble(Random rng)
      : x = rng.nextDouble(),
        phase = rng.nextDouble(),
        speed = 0.05 + rng.nextDouble() * 0.08,
        size = 6 + rng.nextDouble() * 14,
        swing = 0.03 + rng.nextDouble() * 0.04,
        opacity = 0.08 + rng.nextDouble() * 0.14;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final swingX = sin(t * pi * 4) * swing;
    final px = (x + swingX) * size.width;
    final py = size.height - t * (size.height + this.size * 2);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(Offset(px, py), this.size, paint);
  }
}
