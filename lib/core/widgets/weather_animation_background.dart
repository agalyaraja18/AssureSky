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
      case AppConstants.themeThunderstorm:
        return <_Particle>[
          ...List.generate(90, (_) => _RainDrop(_rng)),
          _Lightning(_rng, 0.0),
          _Lightning(_rng, 0.5),
        ];
      case AppConstants.themeCyclone:
        return <_Particle>[
          ...List.generate(150, (_) => _SpiralDot(_rng)),
          ...List.generate(45, (_) => _RainDrop(_rng)),
        ];
      case AppConstants.themeTornado:
        return <_Particle>[
          _Funnel(),
          ...List.generate(95, (_) => _TornadoDebris(_rng)),
          ...List.generate(22, (_) => _WindStreak(_rng)),
        ];
      case AppConstants.themeHail:
        return List.generate(65, (_) => _HailStone(_rng));
      case AppConstants.themeFoggy:
        return List.generate(8, (i) => _FogBank(_rng, i));
      case AppConstants.themeHot:
        return <_Particle>[
          _SunGlow(),
          ...List.generate(16, (_) => _HeatWave(_rng)),
          ...List.generate(14, (_) => _Sparkle(_rng)),
        ];
      case AppConstants.themeCold:
        return <_Particle>[
          ...List.generate(6, (i) => _FogBank(_rng, i, tint: const Color(0xFFE3F2FD))),
          ...List.generate(34, (_) => _FrostCrystal(_rng)),
        ];
      case AppConstants.themeHumid:
        return <_Particle>[
          ...List.generate(6, (i) => _FogBank(_rng, i, tint: const Color(0xFFFFFFFF))),
          ...List.generate(40, (_) => _Bead(_rng)),
        ];
      case AppConstants.themeBreezy:
        return <_Particle>[
          ...List.generate(11, (_) => _BreezeCurve(_rng)),
          ...List.generate(14, (_) => _Leaf(_rng)),
          ...List.generate(3, (_) => _Cloud(_rng)),
        ];
      case AppConstants.themeOvercast:
        return List.generate(
            9, (i) => _OvercastCloud(_rng, i, 9, const Color(0xFF546E7A)));
      case AppConstants.themeHaze:
        return <_Particle>[
          ...List.generate(5, (i) => _FogBank(_rng, i, tint: const Color(0xFFE9D8AE))),
          ...List.generate(70, (_) => _DustMote(_rng)),
        ];
      case AppConstants.themeMist:
        return List.generate(16, (i) => _MistWisp(_rng, i, 16));
      case AppConstants.themeLightning:
        return <_Particle>[
          ...List.generate(
              7, (i) => _OvercastCloud(_rng, i, 7, const Color(0xFF4B4887))),
          _Lightning(_rng, 0.0, cycles: 2),
          _Lightning(_rng, 0.33, cycles: 2),
          _Lightning(_rng, 0.66, cycles: 2),
        ];
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

// ─────────────────────────────────────────────
// ⚡ Lightning (Thunderstorm theme)
// ─────────────────────────────────────────────
/// A bolt that double-flashes once per animation cycle and briefly lights up
/// the whole screen. [offset] staggers the two bolts so they don't coincide.
class _Lightning extends _Particle {
  final double x;
  final double phase;
  final List<double> zigzag;

  /// How many times this bolt strikes per animation cycle (10 s).
  final int cycles;

  _Lightning(Random rng, double offset, {this.cycles = 1})
      : x = 0.15 + rng.nextDouble() * 0.7,
        phase = (offset + rng.nextDouble() * 0.2) % 1.0,
        zigzag = List.generate(8, (_) => (rng.nextDouble() - 0.5) * 0.12);

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * cycles + phase) % 1.0;

    // Two quick flashes: a strong one, then a weaker flicker.
    double flash = 0;
    if (t < 0.04) {
      flash = 1 - t / 0.04;
    } else if (t > 0.07 && t < 0.11) {
      flash = 0.7 * (1 - (t - 0.07) / 0.04);
    }
    if (flash <= 0) return;

    // Whole-screen flash
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: 0.2 * flash),
    );

    // Jagged bolt
    final path = Path();
    var px = x * size.width;
    var py = 0.0;
    path.moveTo(px, py);
    final step = size.height * 0.5 / zigzag.length;
    for (final z in zigzag) {
      px += z * size.width;
      py += step;
      path.lineTo(px, py);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35 * flash)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.95 * flash)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }
}

// ─────────────────────────────────────────────
// 🌀 Spiral dot (Cyclone theme)
// ─────────────────────────────────────────────
/// One dot on a rotating spiral arm. Inner dots orbit faster than outer ones,
/// so the whole field reads as a cyclone with a calm eye in the middle.
class _SpiralDot extends _Particle {
  final double r; // normalised distance from the eye, 0.1..1
  final double a0; // starting angle
  final double radius; // dot size
  final double opacity;

  _SpiralDot(Random rng)
      : r = 0.1 + pow(rng.nextDouble(), 0.8).toDouble() * 0.9,
        a0 = rng.nextDouble() * pi * 2,
        radius = 1.2 + rng.nextDouble() * 2.6,
        opacity = 0.2 + rng.nextDouble() * 0.45;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.32;
    final maxR = size.width * 0.78;

    // The "+ r * 5" twist bends the arms into a spiral.
    final angle = a0 + r * 5.0 - progress * pi * 2 * (1.8 - r);
    final dist = r * maxR;
    final x = cx + cos(angle) * dist;
    final y = cy + sin(angle) * dist * 0.55; // flatten into an ellipse

    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()..color = Colors.white.withValues(alpha: opacity * (1 - r * 0.5)),
    );
  }
}

// ─────────────────────────────────────────────
// 🌪️ Tornado funnel + debris (Tornado theme)
// ─────────────────────────────────────────────
class _Funnel extends _Particle {
  @override
  void draw(Canvas canvas, Size size, double progress) {
    final top = size.height * 0.12;
    final height = size.height * 0.62;
    final sway = sin(progress * pi * 2) * size.width * 0.03;
    final cx = size.width * 0.5;

    final path = Path()
      ..moveTo(cx - size.width * 0.42, top)
      ..quadraticBezierTo(cx - size.width * 0.12 + sway, top + height * 0.5,
          cx - size.width * 0.03 + sway * 1.6, top + height)
      ..lineTo(cx + size.width * 0.03 + sway * 1.6, top + height)
      ..quadraticBezierTo(cx + size.width * 0.12 + sway, top + height * 0.5,
          cx + size.width * 0.42, top)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
  }
}

class _TornadoDebris extends _Particle {
  final double h; // 0 = top of funnel, 1 = ground
  final double a0;
  final double speed;
  final double radius;
  final double opacity;
  final bool dark;

  _TornadoDebris(Random rng)
      : h = rng.nextDouble(),
        a0 = rng.nextDouble() * pi * 2,
        speed = 1.0 + rng.nextDouble() * 1.5,
        radius = 1.2 + rng.nextDouble() * 2.4,
        opacity = 0.25 + rng.nextDouble() * 0.5,
        dark = rng.nextBool();

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final top = size.height * 0.12;
    final height = size.height * 0.62;
    final sway = sin(progress * pi * 2) * size.width * 0.03;

    // Funnel is wide at the top and narrow at the ground.
    final spread = size.width * (0.40 * pow(1 - h, 1.3) + 0.035);
    final angle = a0 + progress * pi * 2 * speed;
    final x = size.width * 0.5 + sway * h * 1.6 + cos(angle) * spread;
    final y = top + h * height + sin(angle) * spread * 0.16;

    // Debris on the far side of the funnel is dimmer.
    final depth = (sin(angle) + 1) / 2;
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()
        ..color = (dark ? Colors.black : Colors.white)
            .withValues(alpha: opacity * (0.5 + depth * 0.5)),
    );
  }
}

// ─────────────────────────────────────────────
// 🧊 Hailstone (Hail theme)
// ─────────────────────────────────────────────
class _HailStone extends _Particle {
  final double x;
  final double phase;
  final double speed;
  final double radius;
  final double opacity;

  _HailStone(Random rng)
      : x = rng.nextDouble(),
        phase = rng.nextDouble(),
        speed = 1.2 + rng.nextDouble() * 1.2, // faster than rain
        radius = 2 + rng.nextDouble() * 3,
        opacity = 0.6 + rng.nextDouble() * 0.35;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final px = x * size.width + t * size.width * 0.05;
    final py = t * (size.height + radius * 2) - radius;

    canvas.drawCircle(
      Offset(px, py),
      radius,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    // Tiny highlight so the stones read as ice rather than snow.
    canvas.drawCircle(
      Offset(px - radius * 0.3, py - radius * 0.3),
      radius * 0.35,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }
}

// ─────────────────────────────────────────────
// 🌫️ Fog bank (Foggy theme)
// ─────────────────────────────────────────────
class _FogBank extends _Particle {
  final double y;
  final double phase;
  final double speed;
  final double width;
  final double height;
  final double opacity;
  final bool grey;

  /// When set, every bank uses this colour (Haze, Humid, Cold themes) instead
  /// of alternating white and grey.
  final Color? tint;

  _FogBank(Random rng, int index, {this.tint})
      : y = 0.08 + (index / 8) * 0.9 + rng.nextDouble() * 0.05,
        phase = rng.nextDouble(),
        speed = 0.04 + rng.nextDouble() * 0.06,
        width = 280 + rng.nextDouble() * 260,
        height = 70 + rng.nextDouble() * 70,
        opacity = 0.25 + rng.nextDouble() * 0.25,
        grey = index.isOdd;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final cx = t * (size.width + width) - width / 2;

    // Alternate white and grey banks so the fog has depth on a light theme —
    // unless a tint was requested.
    final color = tint ?? (grey ? const Color(0xFF8E99A0) : Colors.white);
    final dim = tint != null ? 1.0 : (grey ? 0.6 : 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, y * size.height),
        width: width,
        height: height,
      ),
      Paint()
        ..color = color.withValues(alpha: opacity * dim)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
    );
  }
}

// ─────────────────────────────────────────────
// 🔥 Sun glow + heat shimmer (Hot theme)
// ─────────────────────────────────────────────
class _SunGlow extends _Particle {
  @override
  void draw(Canvas canvas, Size size, double progress) {
    final pulse = 0.8 + sin(progress * pi * 2) * 0.2;
    final center = Offset(size.width * 0.82, size.height * 0.08);
    final radius = size.width * 0.75 * pulse;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE082).withValues(alpha: 0.55 * pulse),
          const Color(0xFFFFB74D).withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }
}

/// A wobbling line that rises up the screen, like air shimmering over hot
/// tarmac.
class _HeatWave extends _Particle {
  final double phase;
  final double speed;
  final double amplitude;
  final double opacity;

  _HeatWave(Random rng)
      : phase = rng.nextDouble(),
        speed = 0.35 + rng.nextDouble() * 0.4,
        amplitude = 4 + rng.nextDouble() * 8,
        opacity = 0.10 + rng.nextDouble() * 0.14;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final baseY = size.height * (1 - t);
    // Fade in at the bottom and out at the top.
    final fade = sin(t * pi);

    final path = Path();
    for (double x = 0; x <= size.width; x += 14) {
      final y =
          baseY + sin((x / size.width) * pi * 6 + progress * pi * 8) * amplitude;
      x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }
}

// ─────────────────────────────────────────────
// ❄️ Frost crystal (Cold theme)
// ─────────────────────────────────────────────
/// A small twinkling ice crystal (a plus and an x of fine lines).
class _FrostCrystal extends _Particle {
  final double x, y, phase, radius;

  _FrostCrystal(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        phase = rng.nextDouble(),
        radius = 3 + rng.nextDouble() * 6;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final twinkle = (sin((progress * 2 + phase) * pi * 2) + 1) / 2; // 0..1
    final alpha = 0.15 + twinkle * 0.7;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final c = Offset(x * size.width, y * size.height);
    final r = radius * (0.7 + twinkle * 0.5);
    final d = r * 0.7;

    canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), paint);
    canvas.drawLine(c.translate(0, -r), c.translate(0, r), paint);
    canvas.drawLine(c.translate(-d, -d), c.translate(d, d), paint);
    canvas.drawLine(c.translate(-d, d), c.translate(d, -d), paint);
  }
}

// ─────────────────────────────────────────────
// 💧 Condensation bead (Humid theme)
// ─────────────────────────────────────────────
/// A droplet that slowly slides down the "glass" leaving a faint trail.
class _Bead extends _Particle {
  final double x, phase, speed, radius, opacity;

  _Bead(Random rng)
      : x = rng.nextDouble(),
        phase = rng.nextDouble(),
        speed = 0.05 + rng.nextDouble() * 0.09,
        radius = 2 + rng.nextDouble() * 3.5,
        opacity = 0.35 + rng.nextDouble() * 0.3;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final px = x * size.width + sin(t * pi * 3) * 6;
    final py = t * (size.height + radius * 4) - radius * 2;

    // Trail above the bead
    canvas.drawLine(
      Offset(px, py - radius * 5),
      Offset(px, py),
      Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.35)
        ..strokeWidth = radius * 0.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(px, py), radius,
        Paint()..color = Colors.white.withValues(alpha: opacity));
    // Highlight
    canvas.drawCircle(Offset(px - radius * 0.3, py - radius * 0.3), radius * 0.35,
        Paint()..color = Colors.white.withValues(alpha: 0.9));
  }
}

// ─────────────────────────────────────────────
// 🍃 Breeze curve + leaf (Breezy theme)
// ─────────────────────────────────────────────
class _BreezeCurve extends _Particle {
  final double y, phase, speed, length, amplitude, opacity;

  _BreezeCurve(Random rng)
      : y = rng.nextDouble(),
        phase = rng.nextDouble(),
        speed = 0.2 + rng.nextDouble() * 0.25,
        length = 90 + rng.nextDouble() * 120,
        amplitude = 10 + rng.nextDouble() * 22,
        opacity = 0.3 + rng.nextDouble() * 0.3;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final x0 = t * (size.width + length) - length;
    final yy = y * size.height;

    final path = Path()
      ..moveTo(x0, yy)
      ..cubicTo(x0 + length * 0.3, yy - amplitude, x0 + length * 0.6,
          yy + amplitude, x0 + length, yy - amplitude * 0.3);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity * sin(t * pi))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }
}

class _Leaf extends _Particle {
  final double y0, phase, speed, size, drift;
  final Color color;

  _Leaf(Random rng)
      : y0 = rng.nextDouble() * 0.8,
        phase = rng.nextDouble(),
        speed = 0.1 + rng.nextDouble() * 0.12,
        size = 5 + rng.nextDouble() * 6,
        drift = 20 + rng.nextDouble() * 40,
        color = rng.nextBool() ? const Color(0xFF66BB6A) : const Color(0xFF9CCC65);

  @override
  void draw(Canvas canvas, Size canvasSize, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final px = t * (canvasSize.width + 40) - 20;
    final py = y0 * canvasSize.height + sin(t * pi * 4) * drift + t * 60;

    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(t * pi * 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size * 2, height: size),
      Paint()..color = color.withValues(alpha: 0.65),
    );
    canvas.restore();
  }
}

// ─────────────────────────────────────────────
// ☁️ Heavy cloud layer (Overcast + Lightning themes)
// ─────────────────────────────────────────────
/// A large, soft, slow cloud. Stacked so the top of the screen is covered by
/// thick cloud — as under a fully overcast sky.
class _OvercastCloud extends _Particle {
  final double y, phase, speed, width, height, opacity;
  final Color tint;

  _OvercastCloud(Random rng, int index, int count, this.tint)
      : y = 0.0 + (index / count) * 0.62 + rng.nextDouble() * 0.04,
        phase = rng.nextDouble(),
        speed = 0.02 + rng.nextDouble() * 0.03,
        width = 380 + rng.nextDouble() * 260,
        height = 120 + rng.nextDouble() * 80,
        opacity = 0.30 + rng.nextDouble() * 0.22;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final cx = t * (size.width + width) - width / 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, y * size.height),
        width: width,
        height: height,
      ),
      Paint()
        ..color = tint.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 38),
    );
  }
}

// ─────────────────────────────────────────────
// 🌫️ Dust mote (Haze theme)
// ─────────────────────────────────────────────
class _DustMote extends _Particle {
  final double x, y, phase, speed, radius, opacity;

  _DustMote(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        phase = rng.nextDouble(),
        speed = 0.04 + rng.nextDouble() * 0.08,
        radius = 0.8 + rng.nextDouble() * 1.8,
        opacity = 0.18 + rng.nextDouble() * 0.35;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final px = ((x + t) % 1.0) * size.width;
    final py = (y * size.height + sin((progress + phase) * pi * 4) * 14) %
        size.height;
    canvas.drawCircle(
      Offset(px, py),
      radius,
      Paint()..color = const Color(0xFFA67C37).withValues(alpha: opacity),
    );
  }
}

// ─────────────────────────────────────────────
// 🌁 Mist wisp (Mist theme)
// ─────────────────────────────────────────────
/// A thin, long, blurred streak of mist drifting sideways — much finer than the
/// big banks used for fog.
class _MistWisp extends _Particle {
  final double y, phase, speed, width, height, opacity;

  _MistWisp(Random rng, int index, int count)
      : y = 0.05 + (index / count) * 0.92 + rng.nextDouble() * 0.03,
        phase = rng.nextDouble(),
        speed = 0.05 + rng.nextDouble() * 0.08,
        width = 220 + rng.nextDouble() * 200,
        height = 10 + rng.nextDouble() * 14,
        opacity = 0.30 + rng.nextDouble() * 0.25;

  @override
  void draw(Canvas canvas, Size size, double progress) {
    final t = (progress * speed + phase) % 1.0;
    final cx = t * (size.width + width) - width / 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, y * size.height),
        width: width,
        height: height,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }
}
