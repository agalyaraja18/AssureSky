import 'package:flutter/material.dart';
import '../utils/weather_icon_helper.dart';

/// Weather icon for an OpenWeatherMap condition code.
///
/// Most conditions use an emoji. Mist, haze and fog share one fog emoji that
/// looks the same on every phone, so those three get their own drawn icons.
class WeatherIcon extends StatelessWidget {
  final int code;
  final double size;
  final bool isNight;

  const WeatherIcon(this.code, {super.key, required this.size, this.isNight = false});

  static bool hasCustomIcon(int code) => _kindFor(code) != null;

  static _Kind? _kindFor(int code) {
    if (code == 701) return _Kind.mist;
    if (code == 741) return _Kind.fog;
    if (code == 711 || code == 721 || code == 731 || code == 751 || code == 761 || code == 762) {
      return _Kind.haze;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kindFor(code);
    if (kind == null) {
      return Text(WeatherIconHelper.emoji(code, isNight: isNight),
          style: TextStyle(fontSize: size));
    }
    return Semantics(
      label: WeatherIconHelper.condition(code),
      child: SizedBox(
        width: size * 1.1,
        height: size * 1.1,
        child: CustomPaint(painter: _FogPainter(kind, isNight)),
      ),
    );
  }
}

enum _Kind { mist, haze, fog }

class _FogPainter extends CustomPainter {
  final _Kind kind;
  final bool night;
  const _FogPainter(this.kind, this.night);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);

    void bar(double y, double x0, double x1, Color c, double w) {
      canvas.drawLine(
        p(x0, y),
        p(x1, y),
        Paint()
          ..color = c
          ..strokeWidth = w * s
          ..strokeCap = StrokeCap.round,
      );
    }

    switch (kind) {
      case _Kind.fog:
        final cloud = Path()
          ..addOval(Rect.fromCircle(center: p(0.30, 0.40), radius: 0.15 * s))
          ..addOval(Rect.fromCircle(center: p(0.50, 0.31), radius: 0.20 * s))
          ..addOval(Rect.fromCircle(center: p(0.71, 0.40), radius: 0.15 * s))
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromLTRB(0.15 * s, 0.38 * s, 0.86 * s, 0.55 * s),
              Radius.circular(0.085 * s)));
        canvas.drawPath(cloud, Paint()..color = const Color(0xFFB8C4CC));
        const line = Color(0xFF8FA3AE);
        bar(0.68, 0.14, 0.78, line, 0.075);
        bar(0.81, 0.26, 0.90, line, 0.075);
        bar(0.94, 0.14, 0.68, line, 0.075);
        break;
      case _Kind.mist:
        const c = Color(0xFF7FB2D6);
        bar(0.18, 0.28, 0.80, c.withValues(alpha: 0.55), 0.06);
        bar(0.34, 0.12, 0.70, c.withValues(alpha: 0.8), 0.06);
        bar(0.50, 0.22, 0.88, c, 0.06);
        bar(0.66, 0.10, 0.62, c.withValues(alpha: 0.8), 0.06);
        bar(0.82, 0.30, 0.82, c.withValues(alpha: 0.55), 0.06);
        break;
      case _Kind.haze:
        final sun = night ? const Color(0xFFE6E2C8) : const Color(0xFFFFB02E);
        canvas.drawCircle(
            p(0.5, 0.40), 0.32 * s, Paint()..color = sun.withValues(alpha: 0.25));
        canvas.drawCircle(p(0.5, 0.40), 0.21 * s, Paint()..color = sun);
        const veil = Color(0xFFCDBFA6);
        bar(0.47, 0.12, 0.88, veil.withValues(alpha: 0.85), 0.075);
        bar(0.62, 0.20, 0.80, veil.withValues(alpha: 0.9), 0.075);
        bar(0.77, 0.10, 0.90, veil, 0.075);
        bar(0.92, 0.24, 0.76, veil.withValues(alpha: 0.8), 0.075);
        break;
    }
  }

  @override
  bool shouldRepaint(_FogPainter old) => old.kind != kind || old.night != night;
}
