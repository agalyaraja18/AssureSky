import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// What Asky (the cloud mascot) is doing right now.
enum MascotMood {
  morning,
  sleep,
  sunny,
  cloudy,
  rain,
  snow,
  fog,
  windy,
  storm,
  hail,
  cyclone,
  tornado,
  hot,
  cold,
  humid,
  breezy,

  /// Asky tab only: waves hello, then points down at the tips.
  guide,
}

/// Chooses Asky's activity.
///
/// * 6:00-6:59 in the morning: just woke up, coffee in hand.
/// * 19:00-5:59: sound asleep in bed.
/// * Otherwise: reacts to the weather, using the same classification as the
///   app themes so the mascot and the theme always agree.
///
/// [hour] is the wall-clock hour (0-23) in the city being shown.
MascotMood mascotMoodFor({
  required int code,
  required double tempC,
  required double windKmh,
  required int visibilityMeters,
  required int humidity,
  required int hour,
  bool isHail = false,
}) {
  if (hour >= 19 || hour < 6) return MascotMood.sleep;
  if (hour == 6) return MascotMood.morning;
  final theme = AppTheme.themeFromConditionCode(
    code,
    windKmh: windKmh,
    visibilityMeters: visibilityMeters,
    tempC: tempC,
    humidity: humidity,
    isHail: isHail,
  );
  return mascotMoodForTheme(theme);
}

/// Weather part of the mapping (theme name to activity).
MascotMood mascotMoodForTheme(String theme) {
  switch (theme) {
    case AppConstants.themeSunny:
      return MascotMood.sunny;
    case AppConstants.themeRainy:
      return MascotMood.rain;
    case AppConstants.themeSnowy:
      return MascotMood.snow;
    case AppConstants.themeFoggy:
    case AppConstants.themeMist:
    case AppConstants.themeHaze:
      return MascotMood.fog;
    case AppConstants.themeWindy:
      return MascotMood.windy;
    case AppConstants.themeThunderstorm:
    case AppConstants.themeLightning:
      return MascotMood.storm;
    case AppConstants.themeHail:
      return MascotMood.hail;
    case AppConstants.themeCyclone:
      return MascotMood.cyclone;
    case AppConstants.themeTornado:
      return MascotMood.tornado;
    case AppConstants.themeHot:
      return MascotMood.hot;
    case AppConstants.themeCold:
      return MascotMood.cold;
    case AppConstants.themeHumid:
      return MascotMood.humid;
    case AppConstants.themeBreezy:
      return MascotMood.breezy;
    default:
      return MascotMood.cloudy;
  }
}

const String _hi = 'Hi, I am your Asky. ';

const Map<MascotMood, List<String>> _messages = {
  MascotMood.morning: [
    'Hello, I am your Asky. Good morning, have a great day! ☕',
  ],
  MascotMood.sleep: [
    'Hello! I am your Asky. Shhhh... It\'s bed time. Good night, have sweet dreams!! 🌙',
  ],
  MascotMood.sunny: [
    '${_hi}It\'s sunny! Put on sunglasses and sunscreen 😎',
    '${_hi}Perfect day to be outside. Drink some water too!',
  ],
  MascotMood.rain: [
    '${_hi}It\'s raining! Take an umbrella and watch out for puddles ☔',
    '${_hi}Rain, rain, dance with me! Drive carefully today.',
  ],
  MascotMood.cloudy: [
    '${_hi}Cloudy skies today. A nice day to go out and play ☁️',
    '${_hi}Keep a light jacket with you, just in case.',
  ],
  MascotMood.snow: [
    '${_hi}Snow is falling! Wear a warm sweater and let\'s build a snowman ⛄',
    '${_hi}Roads can be slippery. Walk carefully!',
  ],
  MascotMood.fog: [
    '${_hi}It\'s foggy. Drive slowly and use low-beam lights 🌫️',
    '${_hi}I can barely see my own feet!',
  ],
  MascotMood.windy: [
    '${_hi}It\'s very windy. Wrap up in a scarf and hold on tight 🧣',
    '${_hi}Brrr! Secure loose things outside.',
  ],
  MascotMood.storm: [
    '${_hi}Thunderstorm! Stay indoors, away from windows ⚡',
    '${_hi}Unplug electronics and wait for the storm to pass.',
  ],
  MascotMood.hail: [
    'Hi, I am your Asky, It\'s hail today. Don\'t come out, stay safe at home. 🧊',
  ],
  MascotMood.guide: [''],
  MascotMood.cyclone: [
    '${_hi}A cyclone is near. Stay inside a strong house and follow official alerts 🌀',
    '${_hi}Keep food, water and a torch ready.',
  ],
  MascotMood.tornado: [
    '${_hi}Tornado danger! Go to the basement or the lowest inner room now 🌪️',
    '${_hi}Stay away from windows and cover your head.',
  ],
  MascotMood.hot: [
    '${_hi}It\'s hot! Drink water and stay cool 🥵',
    '${_hi}Avoid going out at noon. Shade is your friend.',
  ],
  MascotMood.cold: [
    '${_hi}It\'s freezing! Wrap up in a blanket and have something warm 🥶',
    '${_hi}Layer your clothes before going out.',
  ],
  MascotMood.humid: [
    '${_hi}It\'s humid today. Drink water and stay hydrated 💧',
    '${_hi}Wear light, breathable clothes.',
  ],
  MascotMood.breezy: [
    '${_hi}Nice breeze! Perfect weather to fly a kite 🪁',
    '${_hi}Enjoy the fresh air!',
  ],
};

/// Mascot and speech bubble. Tap the mascot to make it jump and hear another
/// line.
class WeatherMascotCard extends StatefulWidget {
  final MascotMood mood;
  const WeatherMascotCard({super.key, required this.mood});

  @override
  State<WeatherMascotCard> createState() => _WeatherMascotCardState();
}

class _WeatherMascotCardState extends State<WeatherMascotCard>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker;
  double _tapAt = -10;
  int _line = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _time.value = d.inMicroseconds / 1e6)
      ..start();
  }

  @override
  void didUpdateWidget(covariant WeatherMascotCard old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _line = 0;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  void _onTap() {
    final lines = _messages[widget.mood]!;
    setState(() {
      _tapAt = _time.value;
      _line = (_line + 1) % lines.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = _messages[widget.mood]!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _onTap,
          child: SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: _MascotPainter(
                  time: _time, mood: widget.mood, tapAt: _tapAt),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    lines[_line],
                    key: ValueKey('${widget.mood}-$_line'),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Positioned(
                left: -5,
                top: 28,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child:
                      Container(width: 12, height: 12, color: theme.cardColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Header for the Asky tab. The mascot is always the same: it stands on the
/// left, waves hello, then points down at the tips below.
class AskyGuideHeader extends StatefulWidget {
  const AskyGuideHeader({super.key});

  @override
  State<AskyGuideHeader> createState() => _AskyGuideHeaderState();
}

class _AskyGuideHeaderState extends State<AskyGuideHeader>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _time.value = d.inMicroseconds / 1e6)
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 140,
          height: 150,
          child: CustomPaint(
            painter: _MascotPainter(
                time: _time, mood: MascotMood.guide, tapAt: -10),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello! I'm Asky",
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                "I'm here to give you smart advice tips based on the weather",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Painting. Everything is drawn in a 200x200 design space.
// ---------------------------------------------------------------------------

const Color _outline = Color(0xFF7FB0D6);
const Color _ink = Color(0xFF2B3A55);
const Color _white = Color(0xFFF2F9FF);

enum _Eyes { normal, shades, closed, happy, squint, scared, sleepy }

enum _Mouth { openSmile, smile, chatter, tongue, scaredO, wavy }

double _ease(double x) {
  final v = x.clamp(0.0, 1.0);
  return v * v * (3 - 2 * v);
}

class _MascotPainter extends CustomPainter {
  final ValueNotifier<double> time;
  final MascotMood mood;
  final double tapAt;

  _MascotPainter({required this.time, required this.mood, required this.tapAt})
      : super(repaint: time);

  // Fluffy cloud body: an ellipse plus a ring of overlapping bumps.
  static final Path _body = () {
    var u = Path()
      ..addOval(Rect.fromCenter(
          center: const Offset(100, 104), width: 104, height: 70));
    const n = 12;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n + 0.2;
      final r = i.isEven ? 21.0 : 17.0;
      final c = Offset(100 + math.cos(a) * 47, 104 + math.sin(a) * 33);
      u = Path.combine(PathOperation.union, u,
          Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    }
    return u;
  }();

  late double _t;
  bool _jumping = false;
  double _jump = 0;

  @override
  void paint(Canvas canvas, Size size) {
    _t = time.value;
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);

    final jp = (_t - tapAt) / 0.7;
    _jumping = jp >= 0 && jp <= 1;
    _jump = _jumping ? -30 * math.sin(math.pi * jp) : 0.0;

    _background(canvas);
    switch (mood) {
      case MascotMood.sleep:
        _sleepScene(canvas);
        break;
      case MascotMood.storm:
        _tableScene(canvas);
        break;
      case MascotMood.cyclone:
        _houseScene(canvas);
        break;
      case MascotMood.tornado:
        _basementScene(canvas);
        break;
      case MascotMood.snow:
        _stand(canvas, dx: -14);
        _snowman(canvas);
        break;
      default:
        _stand(canvas);
    }
    _foreground(canvas);
    canvas.restore();
  }

  // -- placement -----------------------------------------------------------

  double get _shake {
    switch (mood) {
      case MascotMood.cold:
        return math.sin(_t * 55) * 1.7;
      case MascotMood.windy:
        return math.sin(_t * 50) * 1.3;
      case MascotMood.storm:
        return math.sin(_t * 55) * 2.2;
      case MascotMood.tornado:
        return math.sin(_t * 50) * 1.2;
      default:
        return 0;
    }
  }

  double get _lean {
    switch (mood) {
      case MascotMood.rain:
        return 0.09 * math.sin(_t * 4);
      case MascotMood.breezy:
        return 0.05 * math.sin(_t * 1.8);
      default:
        return 0;
    }
  }

  /// Draws the character standing on the ground at [anchorY], scaled by
  /// [scale] about its feet.
  void _stand(Canvas c,
      {double scale = 1, double anchorY = 182, double dx = 0}) {
    final dance = mood == MascotMood.rain ? -7 * math.sin(_t * 4).abs() : 0.0;
    if (mood != MascotMood.sleep) {
      c.drawOval(
        Rect.fromCenter(
            center: Offset(100 + dx, anchorY),
            width: (84 + _jump * 0.6) * scale,
            height: 9 * scale),
        Paint()..color = Colors.black.withValues(alpha: 0.12),
      );
    }
    c.save();
    c.translate(100 + dx + _shake * scale, anchorY);
    c.scale(scale);
    c.rotate(_lean);
    c.translate(-100, -182 + _jump + dance);
    _character(c);
    c.restore();
  }

  // -- scenes --------------------------------------------------------------

  void _tableScene(Canvas c) {
    const wood = Color(0xFF9C6B3F);
    const dark = Color(0xFF7A5230);
    for (final x in const [24.0, 167.0]) {
      c.drawRect(Rect.fromLTWH(x, 76, 9, 106), Paint()..color = dark);
    }
    _stand(c, scale: 0.72);
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(12, 62, 176, 14), const Radius.circular(6)),
        Paint()..color = wood);
    c.drawRect(const Rect.fromLTWH(18, 76, 164, 4),
        Paint()..color = dark.withValues(alpha: 0.5));
  }

  void _houseScene(Canvas c) {
    c.drawRect(const Rect.fromLTWH(30, 92, 140, 90),
        Paint()..color = const Color(0xFFFFF1D0));
    c.drawRect(const Rect.fromLTWH(30, 172, 140, 10),
        Paint()..color = const Color(0xFFD9B98A));
    // Window with the storm outside.
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(128, 102, 30, 30), const Radius.circular(4)),
        Paint()..color = const Color(0xFF8FA0B8));
    _stand(c, scale: 0.62);
    final wall = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF8A5A36);
    c.drawRect(const Rect.fromLTWH(30, 92, 140, 90), wall);
    final roof = Path()
      ..moveTo(14, 94)
      ..lineTo(100, 36)
      ..lineTo(186, 94)
      ..close();
    c.drawPath(roof, Paint()..color = const Color(0xFFD1503F));
    c.drawPath(roof, wall..color = const Color(0xFF9E3426));
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(128, 102, 30, 30), const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF8A5A36));
    c.drawLine(const Offset(143, 102), const Offset(143, 132),
        Paint()..color = const Color(0xFF8A5A36)..strokeWidth = 2);
  }

  void _basementScene(Canvas c) {
    // Soil, grass, basement cavity.
    c.drawRect(const Rect.fromLTWH(0, 114, 200, 86),
        Paint()..color = const Color(0xFF8B6B4A));
    c.drawRect(const Rect.fromLTWH(0, 110, 200, 8),
        Paint()..color = const Color(0xFF5FAE5B));
    // House on the surface.
    c.drawRect(const Rect.fromLTWH(26, 80, 84, 32),
        Paint()..color = const Color(0xFFFFE9C2));
    final roof = Path()
      ..moveTo(18, 82)
      ..lineTo(68, 50)
      ..lineTo(118, 82)
      ..close();
    c.drawPath(roof, Paint()..color = const Color(0xFFD1503F));
    c.drawRect(const Rect.fromLTWH(58, 92, 16, 20),
        Paint()..color = const Color(0xFF8A5A36));
    // Basement.
    final cav = RRect.fromRectAndRadius(
        const Rect.fromLTWH(38, 126, 124, 68), const Radius.circular(6));
    c.drawRRect(cav, Paint()..color = const Color(0xFFEBD9B4));
    c.drawCircle(const Offset(100, 132), 14,
        Paint()..color = const Color(0xFFFFE680).withValues(alpha: 0.5));
    c.drawLine(const Offset(100, 126), const Offset(100, 131),
        Paint()..color = _ink..strokeWidth = 1.5);
    c.drawCircle(const Offset(100, 133), 3.5,
        Paint()..color = const Color(0xFFFFD43B));
    c.save();
    c.clipRRect(cav);
    _stand(c, scale: 0.46, anchorY: 191);
    c.restore();
    c.drawRRect(
        cav,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF5E4630));
  }

  void _sleepScene(Canvas c) {
    // Headboard, pillow.
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(26, 50, 148, 124), const Radius.circular(18)),
        Paint()..color = const Color(0xFF8A5A36));
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(46, 98, 108, 46), const Radius.circular(20)),
        Paint()..color = const Color(0xFFF4F8FF));
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(46, 98, 108, 46), const Radius.circular(20)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFB8C7E0));
    _stand(c, scale: 0.72, anchorY: 152);
    // Blanket with a wavy top edge.
    final top = 112.0;
    final b = Path()..moveTo(14, top + 6);
    for (var i = 0; i < 4; i++) {
      final x0 = 14 + i * 43.0;
      b.quadraticBezierTo(x0 + 11, top - 8, x0 + 21.5, top);
      b.quadraticBezierTo(x0 + 32, top + 8, x0 + 43, top + 6);
    }
    b
      ..lineTo(186, 178)
      ..lineTo(14, 178)
      ..close();
    c.drawPath(b, Paint()..color = const Color(0xFF5C8DDB));
    c.save();
    c.clipPath(b);
    for (var y = 130.0; y < 178; y += 16) {
      c.drawLine(Offset(0, y), Offset(200, y),
          Paint()..color = Colors.white.withValues(alpha: 0.25)..strokeWidth = 5);
    }
    c.restore();
    c.drawPath(
        b,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF3F6BB5));
    // Footboard and legs.
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(10, 172, 180, 16), const Radius.circular(6)),
        Paint()..color = const Color(0xFF7A4B2A));
    for (final x in const [16.0, 174.0]) {
      c.drawRect(Rect.fromLTWH(x, 186, 10, 10),
          Paint()..color = const Color(0xFF7A4B2A));
    }
  }

  void _snowman(Canvas c) {
    final p = _t % 12;
    final s1 = _ease((p - 0.3) / 1.5);
    final s2 = _ease((p - 2.2) / 1.5);
    final s3 = _ease((p - 4.1) / 1.2);
    final face = p > 5.6;
    void ball(Offset o, double r, double s) {
      if (s <= 0) return;
      c.drawCircle(o + Offset(0, r * (1 - s)), r * s,
          Paint()..color = const Color(0xFFFFFFFF));
      c.drawCircle(
          o + Offset(0, r * (1 - s)),
          r * s,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = const Color(0xFF9CC4E4));
    }

    ball(const Offset(172, 166), 15, s1);
    ball(const Offset(172, 143), 11.5, s2);
    ball(const Offset(172, 126), 8.5, s3);
    if (face) {
      c.drawCircle(const Offset(169, 124), 1.3, Paint()..color = _ink);
      c.drawCircle(const Offset(175, 124), 1.3, Paint()..color = _ink);
      final nose = Path()
        ..moveTo(172, 126)
        ..lineTo(181, 128)
        ..lineTo(172, 129)
        ..close();
      c.drawPath(nose, Paint()..color = const Color(0xFFFF8A2B));
      for (final y in const [140.0, 147.0, 160.0]) {
        c.drawCircle(Offset(172, y), 1.4, Paint()..color = _ink);
      }
    }
  }

  // -- the character -------------------------------------------------------

  void _character(Canvas c) {
    final t = _t;
    final sleeping = mood == MascotMood.sleep;
    if (!sleeping) _legs(c);
    c.save();
    final bob = sleeping
        ? math.sin(t * 1.6) * 1.5
        : math.sin(t * 3.2) * (mood == MascotMood.rain ? 1 : 2.5);
    c.translate(0, bob);

    final front = mood == MascotMood.cold ||
        mood == MascotMood.windy ||
        mood == MascotMood.storm;
    final (ra, la) = _armAngles();
    final rh = const Offset(158, 108) +
        Offset(math.cos(_deg(ra)), math.sin(_deg(ra))) * 27;
    final lh = const Offset(42, 108) +
        Offset(-math.cos(_deg(la)), math.sin(_deg(la))) * 27;

    if (!front && !sleeping) _arms(c, rh, lh);
    _bodyShape(c);
    _face(c);
    _accessories(c);
    if (front) _arms(c, rh, lh);
    _props(c, rh, lh, ra);
    c.restore();
  }

  double _deg(double d) => d * math.pi / 180;

  (double, double) _armAngles() {
    final t = _t;
    var r = 40.0, l = 40.0;
    switch (mood) {
      case MascotMood.morning:
        r = 25 + 4 * math.sin(t * 2);
        l = -50 + 22 * math.sin(t * 8);
        break;
      case MascotMood.sunny:
        r = l = -60 + 8 * math.sin(t * 5);
        break;
      case MascotMood.cloudy:
        r = 80 - 35 * math.sin(t * 5).abs();
        l = -55 + 20 * math.sin(t * 7);
        break;
      case MascotMood.rain:
        r = -113;
        l = 40 + 30 * math.sin(t * 6);
        break;
      case MascotMood.hail:
        r = -113;
        l = 40 + 3 * math.sin(t * 2);
        break;
      case MascotMood.guide:
        final wave = _guideBlend();
        r = (-62 + 22 * math.sin(t * 9)) * (1 - wave) + (80 + 5 * math.sin(t * 6)) * wave;
        l = (-62 + 22 * math.sin(t * 9 + 1.2)) * (1 - wave) + (80 + 5 * math.sin(t * 6)) * wave;
        break;
      case MascotMood.snow:
        r = 15 + 10 * math.sin(t * 5);
        l = 50 + 10 * math.sin(t * 3);
        break;
      case MascotMood.fog:
        r = l = 40 + 4 * math.sin(t * 1.5);
        break;
      case MascotMood.windy:
      case MascotMood.cold:
        r = l = 115;
        break;
      case MascotMood.storm:
        r = l = -125;
        break;
      case MascotMood.cyclone:
        r = 35;
        l = -55 + 14 * math.sin(t * 6);
        break;
      case MascotMood.tornado:
        r = l = 35 + 3 * math.sin(t * 2);
        break;
      case MascotMood.hot:
        r = -80 + 25 * math.sin(t * 9);
        l = 40 + 3 * math.sin(t * 2);
        break;
      case MascotMood.humid:
        r = 60 + 110 * _drinkAmount();
        l = 40 + 3 * math.sin(t * 2);
        break;
      case MascotMood.breezy:
        r = -40 + 6 * math.sin(t * 2);
        l = 40;
        break;
      case MascotMood.sleep:
        break;
    }
    if (_jumping && mood != MascotMood.sleep) r = l = -65;
    return (r, l);
  }

  /// 0 while Asky waves hello, 1 while it points down at the tips.
  double _guideBlend() {
    final c = _t % 7;
    return _ease((c - 3) / 0.5) * (1 - _ease((c - 6.5) / 0.5));
  }

  double _drinkAmount() {
    final c = (_t % 6) / 6;
    return _ease(c / 0.12) * (1 - _ease((c - 0.55) / 0.15));
  }

  void _limb(Canvas c, Offset a, Offset b, {double w = 11}) {
    final p = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawLine(a, b, p..color = _outline..strokeWidth = w + 4);
    c.drawLine(a, b, p..color = _white..strokeWidth = w);
  }

  void _hand(Canvas c, Offset o) {
    c.drawCircle(o, 9, Paint()..color = _outline);
    c.drawCircle(o, 7, Paint()..color = _white);
  }

  void _legs(Canvas c) {
    final t = _t;
    var freq = 0.0, amp = 0.0;
    switch (mood) {
      case MascotMood.sunny:
      case MascotMood.cloudy:
      case MascotMood.breezy:
        freq = 5;
        amp = 6;
        break;
      case MascotMood.rain:
        freq = 8;
        amp = 9;
        break;
      case MascotMood.cold:
      case MascotMood.windy:
      case MascotMood.storm:
      case MascotMood.tornado:
        freq = 40;
        amp = 2;
        break;
      case MascotMood.morning:
        freq = 3;
        amp = 3;
        break;
      default:
        break;
    }
    for (var i = 0; i < 2; i++) {
      final x = i == 0 ? 82.0 : 118.0;
      var lift = 0.0;
      if (_jumping) {
        lift = 5;
      } else if (amp > 0) {
        lift = math.max(0, math.sin(t * freq + i * math.pi)) * amp;
      }
      final foot = 172 - lift;
      _limb(c, Offset(x, 146), Offset(x, foot), w: 10);
      final dir = i == 0 ? -1.0 : 1.0;
      final fr = Rect.fromCenter(
          center: Offset(x + dir * 3, foot + 4), width: 24, height: 12);
      c.drawOval(fr.inflate(2), Paint()..color = _outline);
      c.drawOval(fr, Paint()..color = _white);
    }
  }

  void _arms(Canvas c, Offset rh, Offset lh) {
    _limb(c, const Offset(158, 108), rh);
    _limb(c, const Offset(42, 108), lh);
    _hand(c, rh);
    _hand(c, lh);
  }

  void _bodyShape(Canvas c) {
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFD3EAF9)],
      ).createShader(const Rect.fromLTWH(0, 45, 200, 115));
    c.drawPath(_body, fill);
    c.drawPath(
      _body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round
        ..color = _outline,
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(74, 66), width: 30, height: 14),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  // -- face ----------------------------------------------------------------

  (_Eyes, _Mouth) get _faceKind {
    switch (mood) {
      case MascotMood.morning:
      case MascotMood.snow:
      case MascotMood.cloudy:
      case MascotMood.guide:
        return (_Eyes.normal, _Mouth.openSmile);
      case MascotMood.sunny:
        return (_Eyes.shades, _Mouth.openSmile);
      case MascotMood.rain:
      case MascotMood.breezy:
        return (_Eyes.happy, _Mouth.openSmile);
      case MascotMood.fog:
        return (_Eyes.sleepy, _Mouth.wavy);
      case MascotMood.windy:
      case MascotMood.cold:
        return (_Eyes.normal, _Mouth.chatter);
      case MascotMood.storm:
        return (_Eyes.scared, _Mouth.scaredO);
      case MascotMood.hot:
        return (_Eyes.squint, _Mouth.tongue);
      case MascotMood.sleep:
        return (_Eyes.closed, _Mouth.smile);
      case MascotMood.cyclone:
      case MascotMood.tornado:
      case MascotMood.humid:
      case MascotMood.hail:
        return (_Eyes.normal, _Mouth.smile);
    }
  }

  void _face(Canvas c) {
    final cheek = switch (mood) {
      MascotMood.cold || MascotMood.windy => const Color(0xFF7EC8F0),
      MascotMood.hot => const Color(0xFFFF6B6B),
      _ => const Color(0xFFFFA3B5),
    };
    for (final x in const [64.0, 136.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, 104), width: 20, height: 12),
          Paint()..color = cheek.withValues(alpha: 0.55));
    }
    final (e, m) = _faceKind;
    _eyes(c, e);
    _mouth(c, m);
  }

  void _eyes(Canvas c, _Eyes kind) {
    final t = _t;
    const xs = [78.0, 122.0];
    const y = 90.0;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _ink;
    final blink = (t % 4.2) < 0.14;

    switch (kind) {
      case _Eyes.shades:
        final lens = Paint()..color = const Color(0xFF1B2433);
        for (final x in xs) {
          c.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(center: Offset(x, y), width: 28, height: 20),
                  const Radius.circular(8)),
              lens);
          c.drawLine(
              Offset(x - 8, y - 5),
              Offset(x - 2, y - 7),
              Paint()
                ..color = Colors.white.withValues(alpha: 0.6)
                ..strokeWidth = 2.2
                ..strokeCap = StrokeCap.round);
        }
        c.drawLine(const Offset(92, 88), const Offset(108, 88),
            Paint()..color = const Color(0xFF1B2433)..strokeWidth = 3);
        return;
      case _Eyes.closed:
        for (final x in xs) {
          c.drawPath(
              Path()
                ..moveTo(x - 8, y)
                ..quadraticBezierTo(x, y + 8, x + 8, y),
              stroke);
        }
        return;
      case _Eyes.happy:
        for (final x in xs) {
          c.drawPath(
              Path()
                ..moveTo(x - 8, y + 3)
                ..quadraticBezierTo(x, y - 8, x + 8, y + 3),
              stroke);
        }
        return;
      case _Eyes.squint:
        for (var i = 0; i < 2; i++) {
          final x = xs[i];
          final d = i == 0 ? 1.0 : -1.0;
          c.drawPath(
              Path()
                ..moveTo(x - 7 * d, y - 6)
                ..lineTo(x + 5 * d, y)
                ..lineTo(x - 7 * d, y + 6),
              stroke);
        }
        return;
      case _Eyes.scared:
        for (final x in xs) {
          c.drawCircle(Offset(x, y), 11, Paint()..color = Colors.white);
          c.drawCircle(Offset(x, y), 11, stroke..strokeWidth = 2);
          c.drawCircle(
              Offset(x + math.sin(t * 40) * 1.5, y + math.cos(t * 33) * 1.5),
              3.2,
              Paint()..color = _ink);
        }
        return;
      case _Eyes.normal:
      case _Eyes.sleepy:
        if (blink && kind == _Eyes.normal) {
          for (final x in xs) {
            c.drawPath(
                Path()
                  ..moveTo(x - 8, y)
                  ..quadraticBezierTo(x, y + 8, x + 8, y),
                stroke);
          }
          return;
        }
        final look = math.sin(t * 0.9) * 1.6;
        for (final x in xs) {
          c.drawOval(
              Rect.fromCenter(
                  center: Offset(x + look, y), width: 13, height: 17),
              Paint()..color = _ink);
          c.drawCircle(Offset(x + look - 2, y - 3.5), 2.6,
              Paint()..color = Colors.white);
          c.drawCircle(Offset(x + look + 2.2, y + 3), 1.3,
              Paint()..color = Colors.white);
          if (kind == _Eyes.sleepy) {
            c.drawRect(Rect.fromLTWH(x + look - 8, y - 10, 16, 10),
                Paint()..color = const Color(0xFFEAF5FD));
            c.drawLine(Offset(x + look - 7, y), Offset(x + look + 7, y), stroke);
          }
        }
        return;
    }
  }

  void _mouth(Canvas c, _Mouth kind) {
    final t = _t;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _ink;
    const dark = Color(0xFF7A2E3E);
    const tongue = Color(0xFFFF8FA3);

    switch (kind) {
      case _Mouth.openSmile:
        final p = Path()
          ..moveTo(88, 106)
          ..quadraticBezierTo(100, 128, 112, 106)
          ..close();
        c.drawPath(p, Paint()..color = dark);
        c.save();
        c.clipPath(p);
        c.drawOval(
            Rect.fromCenter(
                center: const Offset(100, 118), width: 16, height: 10),
            Paint()..color = tongue);
        c.restore();
        break;
      case _Mouth.smile:
        c.drawPath(
            Path()
              ..moveTo(91, 108)
              ..quadraticBezierTo(100, 116, 109, 108),
            line);
        break;
      case _Mouth.chatter:
        final p = Path()..moveTo(88, 111);
        final jig = math.sin(t * 40) * 1.2;
        for (var i = 1; i <= 6; i++) {
          p.lineTo(88 + i * 4.0, 111 + (i.isOdd ? -3 : 3) + jig);
        }
        c.drawPath(p, line);
        break;
      case _Mouth.tongue:
        c.drawOval(
            Rect.fromCenter(
                center: const Offset(100, 112), width: 20, height: 16),
            Paint()..color = dark);
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(95, 112, 11, 15 + math.sin(t * 6) * 2),
                const Radius.circular(5)),
            Paint()..color = tongue);
        break;
      case _Mouth.scaredO:
        final w = 1 + math.sin(t * 30) * 0.06;
        c.drawOval(
            Rect.fromCenter(
                center: const Offset(100, 113), width: 13 * w, height: 19),
            Paint()..color = dark);
        break;
      case _Mouth.wavy:
        c.drawPath(
            Path()
              ..moveTo(90, 110)
              ..quadraticBezierTo(95, 107, 100, 110)
              ..quadraticBezierTo(105, 113, 110, 110),
            line);
        break;
    }
  }

  // -- clothes -------------------------------------------------------------

  void _accessories(Canvas c) {
    switch (mood) {
      case MascotMood.windy:
        final red = Paint()..color = const Color(0xFFE5484D);
        c.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(62, 128, 76, 14),
                const Radius.circular(7)),
            red);
        final flutter = math.sin(_t * 6) * 3;
        final tail = Path()
          ..moveTo(118, 136)
          ..lineTo(132, 136)
          ..lineTo(133 + flutter, 164)
          ..lineTo(119 + flutter, 164)
          ..close();
        c.drawPath(tail, red);
        final stripe = Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 2.5;
        for (var x = 72.0; x < 130; x += 14) {
          c.drawLine(Offset(x, 130), Offset(x, 140), stripe);
        }
        break;
      case MascotMood.snow:
        c.save();
        c.clipPath(_body);
        c.drawRect(const Rect.fromLTWH(0, 118, 200, 60),
            Paint()..color = const Color(0xFF43A5A0));
        final knit = Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..strokeWidth = 3;
        for (var y = 128.0; y < 170; y += 10) {
          c.drawLine(Offset(0, y), Offset(200, y), knit);
        }
        c.restore();
        c.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(66, 112, 68, 11),
                const Radius.circular(5.5)),
            Paint()..color = const Color(0xFF2F8581));
        break;
      case MascotMood.cold:
        final b = Path()
          ..moveTo(28, 110)
          ..quadraticBezierTo(100, 150, 172, 110)
          ..lineTo(178, 168)
          ..lineTo(22, 168)
          ..close();
        c.drawPath(b, Paint()..color = const Color(0xFFE9803A));
        c.save();
        c.clipPath(b);
        final plaid = Paint()
          ..color = const Color(0xFF9E3D1B).withValues(alpha: 0.55)
          ..strokeWidth = 5;
        for (var x = 20.0; x < 190; x += 20) {
          c.drawLine(Offset(x, 100), Offset(x, 170), plaid);
        }
        for (var y = 122.0; y < 170; y += 16) {
          c.drawLine(Offset(0, y), Offset(200, y), plaid);
        }
        c.restore();
        c.drawPath(
            b,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..color = const Color(0xFF9E3D1B));
        for (var x = 26.0; x < 176; x += 9) {
          c.drawLine(Offset(x, 168), Offset(x, 175),
              Paint()..color = const Color(0xFFC9622A)..strokeWidth = 3);
        }
        break;
      case MascotMood.sleep:
        final cap = Path()
          ..moveTo(66, 72)
          ..quadraticBezierTo(76, 32, 124, 26)
          ..quadraticBezierTo(112, 52, 134, 72)
          ..close();
        c.drawPath(cap, Paint()..color = const Color(0xFF5C6BC0));
        c.drawLine(
            const Offset(64, 72),
            const Offset(136, 72),
            Paint()
              ..color = const Color(0xFFF5F7FF)
              ..strokeWidth = 8
              ..strokeCap = StrokeCap.round);
        c.drawCircle(const Offset(124, 26), 7, Paint()..color = Colors.white);
        c.drawCircle(
            const Offset(124, 26),
            7,
            Paint()
              ..style = PaintingStyle.stroke
              ..color = const Color(0xFFB8C0E8));
        break;
      default:
        break;
    }
  }

  // -- things held in the hands --------------------------------------------

  void _props(Canvas c, Offset rh, Offset lh, double rightAngle) {
    final t = _t;
    switch (mood) {
      case MascotMood.morning:
        _mug(c, rh);
        break;
      case MascotMood.rain:
      case MascotMood.hail:
        _umbrella(c, rh);
        break;
      case MascotMood.cloudy:
        final b = math.sin(t * 5).abs();
        final y = 170 - (170 - (rh.dy + 14)) * b;
        final o = Offset(rh.dx + 6, y);
        c.drawCircle(o, 8, Paint()..color = const Color(0xFFFF6B6B));
        c.drawCircle(
            o,
            8,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = const Color(0xFFC94545));
        c.drawArc(Rect.fromCircle(center: o, radius: 5), 3.6, 1.4, false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..color = Colors.white.withValues(alpha: 0.8));
        break;
      case MascotMood.hot:
        c.save();
        c.translate(rh.dx, rh.dy);
        c.rotate(_deg(rightAngle));
        final fan = Path()
          ..moveTo(0, 0)
          ..arcTo(Rect.fromCircle(center: Offset.zero, radius: 30), -0.85, 1.7,
              false)
          ..close();
        c.drawPath(fan, Paint()..color = const Color(0xFFFFD1DC));
        c.drawPath(
            fan,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..color = const Color(0xFFE56B8A));
        for (var i = -2; i <= 2; i++) {
          final a = i * 0.34;
          c.drawLine(Offset.zero, Offset(math.cos(a), math.sin(a)) * 30,
              Paint()..color = const Color(0xFFE56B8A)..strokeWidth = 1);
        }
        c.restore();
        break;
      case MascotMood.humid:
        final d = _drinkAmount();
        c.save();
        c.translate(rh.dx, rh.dy + (d > 0.9 ? math.sin(t * 14) * 1.2 : 0));
        c.rotate(-1.4 * d);
        c.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -12, 14, 28),
                const Radius.circular(5)),
            Paint()..color = const Color(0xFFBFE3FA));
        c.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -2, 14, 18),
                const Radius.circular(5)),
            Paint()..color = const Color(0xFF59B3F0));
        c.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -12, 14, 28),
                const Radius.circular(5)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..color = const Color(0xFF3E8BC6));
        c.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -18, 8, 7),
                const Radius.circular(2)),
            Paint()..color = const Color(0xFF2F6FA3));
        c.restore();
        _hand(c, rh);
        break;
      case MascotMood.breezy:
        _kite(c, rh);
        break;
      default:
        break;
    }
  }

  void _mug(Canvas c, Offset rh) {
    final o = rh + const Offset(-1, -11);
    final body =
        RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 18, height: 16),
            const Radius.circular(3));
    c.drawArc(Rect.fromCircle(center: o + const Offset(9, 0), radius: 5), -1.6,
        3.2, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFB5651D));
    c.drawRRect(body, Paint()..color = const Color(0xFFFFFFFF));
    c.drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = const Color(0xFFB5651D));
    c.drawRect(Rect.fromCenter(center: o + const Offset(0, -6), width: 14, height: 3),
        Paint()..color = const Color(0xFF5B3A1E));
    _hand(c, rh);
    // Steam.
    for (var i = 0; i < 2; i++) {
      final base = o + Offset(-4.0 + i * 8, -10);
      final path = Path()..moveTo(base.dx, base.dy);
      for (var k = 1; k <= 3; k++) {
        path.quadraticBezierTo(
            base.dx + math.sin(_t * 3 + i + k) * 5, base.dy - k * 7 + 3,
            base.dx, base.dy - k * 7);
      }
      c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withValues(alpha: 0.75));
    }
  }

  void _umbrella(Canvas c, Offset hand) {
    const top = Offset(148, 44);
    c.drawLine(hand, top,
        Paint()
          ..color = const Color(0xFF5A4636)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    final canopy = Path()
      ..moveTo(104, 46)
      ..arcToPoint(const Offset(192, 46),
          radius: const Radius.elliptical(44, 30), clockwise: true)
      ..quadraticBezierTo(181, 38, 170, 46)
      ..quadraticBezierTo(159, 38, 148, 46)
      ..quadraticBezierTo(137, 38, 126, 46)
      ..quadraticBezierTo(115, 38, 104, 46)
      ..close();
    c.drawPath(canopy, Paint()..color = const Color(0xFFFF7A59));
    c.drawPath(
        canopy,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFC9482B));
    c.drawLine(const Offset(148, 46), const Offset(148, 17),
        Paint()..color = const Color(0xFFFFB199)..strokeWidth = 2.5);
    _hand(c, hand);
  }

  void _kite(Canvas c, Offset hand) {
    final t = _t;
    final k = Offset(150 + 8 * math.sin(t * 1.7), 36 + 4 * math.sin(t * 2.3));
    final tilt = 0.25 * math.sin(t * 1.7 + 1);
    final bottom = k + Offset(math.sin(tilt) * 18, math.cos(tilt) * 18);
    // Tail.
    final tail = Path()..moveTo(bottom.dx, bottom.dy);
    for (var i = 1; i <= 4; i++) {
      tail.quadraticBezierTo(bottom.dx + (i.isOdd ? 8 : -8) + math.sin(t * 4 + i) * 3,
          bottom.dy + i * 6 - 3, bottom.dx, bottom.dy + i * 6);
    }
    c.drawPath(
        tail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFFE5484D));
    // String.
    final mid = Offset((hand.dx + bottom.dx) / 2 - 6, (hand.dy + bottom.dy) / 2 + 12);
    c.drawPath(
        Path()
          ..moveTo(hand.dx, hand.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, bottom.dx, bottom.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF6B7A8F));
    // Kite body.
    c.save();
    c.translate(k.dx, k.dy);
    c.rotate(-tilt);
    final left = Path()
      ..moveTo(0, -18)
      ..lineTo(-12, 0)
      ..lineTo(0, 18)
      ..close();
    final right = Path()
      ..moveTo(0, -18)
      ..lineTo(12, 0)
      ..lineTo(0, 18)
      ..close();
    c.drawPath(left, Paint()..color = const Color(0xFFFFC93C));
    c.drawPath(right, Paint()..color = const Color(0xFFE5484D));
    c.drawLine(const Offset(-12, 0), const Offset(12, 0),
        Paint()..color = const Color(0xFF7A3B2E)..strokeWidth = 1.2);
    c.drawLine(const Offset(0, -18), const Offset(0, 18),
        Paint()..color = const Color(0xFF7A3B2E)..strokeWidth = 1.2);
    c.restore();
    _hand(c, hand);
  }

  // -- weather effects -----------------------------------------------------

  void _background(Canvas c) {
    final t = _t;
    switch (mood) {
      case MascotMood.rain:
      case MascotMood.storm:
        final p = Paint()
          ..color = const Color(0xFF5B9BD5).withValues(alpha: 0.75)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 26; i++) {
          final x = (i * 37.3) % 200;
          final y = ((t * 170 + i * 53) % 220) - 12;
          c.drawLine(Offset(x, y), Offset(x - 3, y + 10), p);
        }
        if (mood == MascotMood.storm) {
          final flash = math.pow(math.max(0, math.sin(t * 2.3)), 14).toDouble();
          if (flash > 0.02) {
            final bolt = Path()
              ..moveTo(36, 4)
              ..lineTo(18, 42)
              ..lineTo(30, 42)
              ..lineTo(22, 78)
              ..lineTo(48, 32)
              ..lineTo(34, 32)
              ..lineTo(44, 4)
              ..close();
            c.drawPath(
                bolt,
                Paint()
                  ..color = const Color(0xFFFFD43B).withValues(alpha: flash));
          }
        }
        break;
      case MascotMood.snow:
      case MascotMood.cold:
        for (var i = 0; i < 16; i++) {
          final x = (i * 29.0) % 200 + math.sin(t + i) * 6;
          final y = (t * 32 + i * 41) % 210;
          final o = Offset(x, y);
          c.drawCircle(o, 3, Paint()..color = const Color(0xFFE4F2FC));
          c.drawCircle(
              o,
              3,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = const Color(0xFF9CC4E4));
        }
        break;
      case MascotMood.sunny:
        _sun(c, const Offset(170, 28), 13, const Color(0xFFFFC93C));
        break;
      case MascotMood.hot:
        _sun(c, const Offset(30, 30), 17, const Color(0xFFFF9F1C));
        break;
      case MascotMood.morning:
        c.drawCircle(const Offset(34, 34), 26,
            Paint()..color = const Color(0xFFFFB347).withValues(alpha: 0.28));
        _sun(c, const Offset(34, 34), 11, const Color(0xFFFFA62B));
        break;
      case MascotMood.windy:
      case MascotMood.breezy:
        final p = Paint()
          ..color = const Color(0xFF9DBDD6)
              .withValues(alpha: mood == MascotMood.windy ? 0.7 : 0.45)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        final speed = mood == MascotMood.windy ? 130 : 60;
        for (var i = 0; i < 7; i++) {
          final x = ((t * speed + i * 47) % 260) - 30;
          final y = 20.0 + i * 24;
          c.drawLine(Offset(x, y), Offset(x + 28, y), p);
        }
        break;
      case MascotMood.cyclone:
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF7D8BA1).withValues(alpha: 0.75);
        for (var k = 0; k < 4; k++) {
          c.drawArc(Rect.fromCircle(center: const Offset(165, 34), radius: 10.0 + k * 9),
              t * 3 + k * 1.2, 4.2, false, p);
        }
        for (var i = 0; i < 5; i++) {
          final x = ((t * 150 + i * 61) % 260) - 30;
          c.drawLine(Offset(x, 70.0 + i * 24), Offset(x + 26, 70.0 + i * 24), p);
        }
        break;
      case MascotMood.tornado:
        for (var i = 0; i < 8; i++) {
          final y = 8.0 + i * 13;
          final w = 54.0 - i * 6.2;
          final cx = 166 + math.sin(t * 3 + i * 0.6) * (8 - i * 0.6);
          c.drawOval(
              Rect.fromCenter(center: Offset(cx, y), width: w, height: 11),
              Paint()..color = const Color(0xFF6E7B91).withValues(alpha: 0.85));
        }
        break;
      case MascotMood.humid:
        for (var i = 0; i < 9; i++) {
          final x = (i * 41.0) % 200;
          final y = 210 - ((t * 18 + i * 29) % 220);
          final d = Path()
            ..moveTo(x, y - 6)
            ..quadraticBezierTo(x + 4, y, x, y + 3)
            ..quadraticBezierTo(x - 4, y, x, y - 6);
          c.drawPath(d,
              Paint()..color = const Color(0xFF63B3ED).withValues(alpha: 0.4));
        }
        break;
      case MascotMood.sleep:
        final moon = Path.combine(
          PathOperation.difference,
          Path()
            ..addOval(Rect.fromCircle(center: const Offset(168, 26), radius: 14)),
          Path()
            ..addOval(Rect.fromCircle(center: const Offset(175, 21), radius: 12)),
        );
        c.drawPath(moon, Paint()..color = const Color(0xFFFFE08A));
        const stars = [
          Offset(24, 24),
          Offset(58, 12),
          Offset(14, 66),
          Offset(186, 70)
        ];
        for (var i = 0; i < stars.length; i++) {
          final a = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(t * 2 + i * 1.7));
          c.drawCircle(stars[i], 2.2,
              Paint()..color = const Color(0xFFFFD66B).withValues(alpha: a));
        }
        break;
      case MascotMood.hail:
        final stone = Paint()..color = Colors.white;
        final edge = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFF9CC4E4);
        for (var i = 0; i < 22; i++) {
          final x = (i * 43.7) % 200;
          final cycle = (t * 1.1 + i * 0.137) % 1;
          final y = cycle * 186 - 6;
          final r = 3.0 + (i % 3);
          c.drawCircle(Offset(x, y), r, stone);
          c.drawCircle(Offset(x, y), r, edge);
        }
        break;
      case MascotMood.guide:
        // Down arrows under the pointing hands.
        final blend = _guideBlend();
        if (blend > 0.05) {
          final ap = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFF00BCD4).withValues(alpha: blend);
          for (final x in const [24.0, 176.0]) {
            for (var k = 0; k < 2; k++) {
              final y = 150 + k * 12 + (math.sin(t * 6 + k) * 3);
              c.drawPath(
                  Path()
                    ..moveTo(x - 7, y)
                    ..lineTo(x, y + 7)
                    ..lineTo(x + 7, y),
                  ap);
            }
          }
        }
        break;
      case MascotMood.cloudy:
      case MascotMood.fog:
        break;
    }
  }

  void _sun(Canvas c, Offset o, double r, Color col) {
    final ray = Paint()
      ..color = col
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + _t * 0.6;
      c.drawLine(o + Offset(math.cos(a), math.sin(a)) * (r + 4),
          o + Offset(math.cos(a), math.sin(a)) * (r + 10), ray);
    }
    c.drawCircle(o, r, Paint()..color = col);
  }

  void _foreground(Canvas c) {
    final t = _t;
    if (mood == MascotMood.fog) {
      for (var i = 0; i < 3; i++) {
        final dx = math.sin(t * 0.6 + i * 1.6) * 24;
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(-30 + dx, 70.0 + i * 34, 260, 13),
              const Radius.circular(7)),
          Paint()..color = const Color(0xFFB8C4CC).withValues(alpha: 0.38),
        );
      }
    }
    if (mood == MascotMood.hot) {
      for (var i = 0; i < 3; i++) {
        final p = (t * 0.8 + i * 0.33) % 1;
        final o = Offset(60 + i * 40.0, 62 + p * 30);
        final a = (1 - p).clamp(0.0, 1.0);
        final drop = Path()
          ..moveTo(o.dx, o.dy - 8)
          ..quadraticBezierTo(o.dx + 6, o.dy, o.dx, o.dy + 4)
          ..quadraticBezierTo(o.dx - 6, o.dy, o.dx, o.dy - 8);
        c.drawPath(
            drop, Paint()..color = const Color(0xFF63B3ED).withValues(alpha: a));
      }
    }
    if (mood == MascotMood.sleep) {
      for (var i = 0; i < 3; i++) {
        final p = (t * 0.35 + i / 3) % 1;
        final tp = TextPainter(
          text: TextSpan(
            text: 'Z',
            style: TextStyle(
              fontSize: 11 + p * 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF7C8CE0).withValues(alpha: 1 - p),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, Offset(128 + p * 40, 60 - p * 44));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) =>
      old.mood != mood || old.tapAt != tapAt;
}
