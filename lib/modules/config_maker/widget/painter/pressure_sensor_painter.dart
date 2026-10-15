import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Realistic pressure gauge painter, modelled on the reference photo.
///
/// Visual features:
/// - Small steel nub + bolted clamp bracket on top (top port)
/// - Chrome bezel with bevelled inner ring and glass reflection
/// - Off-white dial with Green / Yellow / Red zone arc (50% / 25% / 25%)
/// - 60-step tick scale with thick major ticks and heavy start/end ticks
/// - Round status LED ring above the pivot
/// - Tapered red needle with black counterweight tail, black hub, brass cap
/// - Brass body, brass neck, bolted steel hex nut and threaded male fitting
///   (bottom port)
///
/// [isOn] = true  -> needle at working pressure, LED green
/// [isOn] = false -> needle rests at 0, LED grey
/// [showJoints]   -> draws the bolted clamp (top) and hex nut (bottom)
class DetailedPressureSensorPainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;
  final double? pressure;

  DetailedPressureSensorPainter({
    required this.isOn,
    this.showJoints = true,
    this.pressure,
  });

  // Reference layout (pixels of the reference photo).
  // Object spans x: 165..845 (gauge) and y: 238..1320.
  static const double _refW = 680.0;
  static const double _refH = 1082.0;

  // Palette
  static const Color _edge = Color(0xFF23272A);

  static const Color _steelDark = Color(0xFF5E6266);
  static const Color _steelMid = Color(0xFFB4B8BB);
  static const Color _steelLight = Color(0xFFF1F2F3);

  static const Color _brassDark = Color(0xFF6F5014);
  static const Color _brassMid = Color(0xFFB8892F);
  static const Color _brassLight = Color(0xFFE8CE80);

  static const Color _zoneGreen = Color(0xFF5CAE4F);
  static const Color _zoneYellow = Color(0xFFE8B923);
  static const Color _zoneRed = Color(0xFFE0432A);

  // Scale geometry (shared by dial + needle)
  static const double _startAngle = math.pi * 0.75; // 135 deg
  static const double _totalAngle = math.pi * 1.5; // 270 deg sweep

  static Offset topPort(Size s) => Offset(s.width * 0.5, 0);
  static Offset bottomPort(Size s) => Offset(s.width * 0.5, s.height);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.height / _refH, size.width / _refW);
    final _Frame f = _Frame(s, size.width / 2, (size.height - _refH * s) / 2);

    final Offset c = f.p(500, 665); // gauge centre
    final double r = 340 * s; // gauge outer radius

    // Soft drop shadow of the whole gauge (down-right, like the photo)
    canvas.drawCircle(
      c + Offset(f.len(22), f.len(30)),
      r * 0.98,
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.5, f.len(22))),
    );

    _drawTopNub(canvas, f);
    _drawBottomFitting(canvas, f);
    _drawBezel(canvas, c, r);
    _drawDial(canvas, f, c, r);
    _drawNeedle(canvas, f, c, r);
    _drawGlass(canvas, c, r);

    if (showJoints) {
      _drawClamp(canvas, f);
      _drawHexNut(canvas, f);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _cylinder(
      Canvas canvas,
      Rect rect,
      List<Color> colors,
      List<double> stops, {
        double radius = 2,
        double edgeWidth = 0.8,
      }) {
    final RRect rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(
      rr,
      Paint()..shader = LinearGradient(colors: colors, stops: stops).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = edgeWidth
        ..color = _edge.withValues(alpha: 0.85),
    );
  }

  void _screw(Canvas canvas, Offset c, double r, double angle) {
    final Rect rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFF0F1F2), Color(0xFF9A9EA2), Color(0xFF55595D)],
          stops: [0.0, 0.65, 1.0],
        ).createShader(rect),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, r * 0.12)
        ..color = const Color(0xFF2B2F33),
    );
    if (r >= 1.2) {
      final Paint slot = Paint()
        ..color = _edge
        ..strokeWidth = math.max(0.5, r * 0.16)
        ..strokeCap = StrokeCap.butt;
      for (int k = 0; k < 2; k++) {
        final double a = angle + k * math.pi / 2;
        final Offset d = Offset(math.cos(a), math.sin(a)) * (r * 0.68);
        canvas.drawLine(c - d, c + d, slot);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Fittings
  // ---------------------------------------------------------------------------

  void _drawTopNub(Canvas canvas, _Frame f) {
    // Cylinder body
    _cylinder(
      canvas,
      f.rect(441, 247, 558, 272),
      const [_steelDark, _steelMid, _steelLight, _steelMid, _steelDark],
      const [0.0, 0.2, 0.45, 0.75, 1.0],
      radius: 1.5,
    );

    // Top face (ellipse) with inner ring
    final Rect top = f.rect(441, 238, 558, 258);
    canvas.drawOval(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFB9BDC0), Color(0xFF7C8084)],
        ).createShader(top),
    );
    canvas.drawOval(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = _edge.withValues(alpha: 0.8),
    );
    canvas.drawOval(
      f.rect(462, 241, 537, 255),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, f.len(3))
        ..color = const Color(0x55000000),
    );
  }

  void _drawClamp(Canvas canvas, _Frame f) {
    final Rect plate = f.rect(402, 262, 596, 332);
    final RRect rr = RRect.fromRectAndRadius(plate, Radius.circular(f.len(8)));

    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFC9CDD0), const Color(0xFF92969A).withValues(alpha: 1), const Color(0xFF6B6F73)],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(plate),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, f.len(3))
        ..color = _edge.withValues(alpha: 0.85),
    );
    // top bevel highlight
    canvas.drawLine(
      f.p(412, 268),
      f.p(586, 268),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = math.max(0.5, f.len(3)),
    );

    final double sr = f.len(21);
    _screw(canvas, f.p(433, 292), sr, 0.35);
    _screw(canvas, f.p(562, 292), sr, 0.35);
  }

  void _drawBottomFitting(Canvas canvas, _Frame f) {
    // Large brass body
    _cylinder(
      canvas,
      f.rect(398, 990, 600, 1105),
      const [_brassDark, _brassMid, _brassLight, _brassMid, _brassDark],
      const [0.0, 0.2, 0.42, 0.75, 1.0],
      radius: 3,
    );
    // Narrow brass neck
    _cylinder(
      canvas,
      f.rect(428, 1105, 575, 1152),
      const [_brassDark, _brassMid, _brassLight, _brassMid, _brassDark],
      const [0.0, 0.22, 0.45, 0.78, 1.0],
      radius: 2,
    );
    // Shadow where the neck meets the body
    canvas.drawLine(
      f.p(398, 1106),
      f.p(600, 1106),
      Paint()
        ..color = const Color(0x66000000)
        ..strokeWidth = math.max(0.6, f.len(5)),
    );

    // Threaded male fitting
    final Rect thread = f.rect(432, 1228, 572, 1320);
    _cylinder(
      canvas,
      thread,
      const [Color(0xFF4F5357), Color(0xFFA9ADB0), Color(0xFFE4E6E7), Color(0xFF9A9EA2), Color(0xFF4F5357)],
      const [0.0, 0.2, 0.42, 0.75, 1.0],
      radius: 2,
    );
    final double threadH = thread.height;
    final int threadCount = threadH < 8 ? 3 : 8;
    for (int i = 0; i < threadCount; i++) {
      final double y = thread.top + (i + 0.5) * (threadH / threadCount);
      canvas.drawLine(
        Offset(thread.left + 1, y),
        Offset(thread.right - 1, y),
        Paint()
          ..color = const Color(0x88000000)
          ..strokeWidth = math.max(0.4, f.len(2.5)),
      );
      canvas.drawLine(
        Offset(thread.left + 1, y + math.max(0.3, threadH / (threadCount * 2.5))),
        Offset(thread.right - 1, y + math.max(0.3, threadH / (threadCount * 2.5))),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = math.max(0.3, f.len(1.5)),
      );
    }
  }

  void _drawHexNut(Canvas canvas, _Frame f) {
    final Rect nut = f.rect(390, 1148, 610, 1230);
    _cylinder(
      canvas,
      nut,
      const [
        Color(0xFF5A5E62),
        Color(0xFFB8BCBF),
        Color(0xFFEFF0F1),
        Color(0xFFB0B4B7),
        Color(0xFF6A6E72),
      ],
      const [0.0, 0.18, 0.45, 0.78, 1.0],
      radius: f.len(10),
      edgeWidth: math.max(0.7, f.len(3)),
    );

    // Top bevel + bottom shadow
    canvas.drawRect(
      f.rect(396, 1151, 604, 1166),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );
    canvas.drawRect(
      f.rect(396, 1214, 604, 1227),
      Paint()..color = const Color(0x33000000),
    );

    // Hex face separators
    final Paint sep = Paint()
      ..color = const Color(0x44000000)
      ..strokeWidth = math.max(0.5, f.len(2.5));
    canvas.drawLine(f.p(455, 1152), f.p(455, 1226), sep);
    canvas.drawLine(f.p(545, 1152), f.p(545, 1226), sep);

    final double sr = f.len(19);
    _screw(canvas, f.p(432, 1195), sr, 0.5);
    _screw(canvas, f.p(558, 1195), sr, 0.5);
  }

  // ---------------------------------------------------------------------------
  // Gauge
  // ---------------------------------------------------------------------------

  void _drawBezel(Canvas canvas, Offset c, double r) {
    final Rect rect = Rect.fromCircle(center: c, radius: r);

    // Outer dark edge
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF34383B));

    // Polished chrome ring
    canvas.drawCircle(
      c,
      r * 0.985,
      Paint()
        ..shader = SweepGradient(
          colors: const [
            Color(0xFFDADDE0),
            Color(0xFF8A8E92),
            Color(0xFFF4F5F6),
            Color(0xFF6C7074),
            Color(0xFFC9CCCF),
            Color(0xFFF1F2F3),
            Color(0xFF8A8E92),
            Color(0xFFDADDE0),
          ],
          transform: GradientRotation(-math.pi * 0.8),
        ).createShader(rect),
    );

    // Highlight and groove
    canvas.drawCircle(
      c,
      r * 0.94,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, r * 0.012)
        ..color = const Color(0x66FFFFFF),
    );
    canvas.drawCircle(
      c,
      r * 0.915,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, r * 0.014)
        ..color = const Color(0xFF4A4E52),
    );

    // Inner bevel ring
    final Rect inner = Rect.fromCircle(center: c, radius: r * 0.90);
    canvas.drawCircle(
      c,
      r * 0.90,
      Paint()
        ..shader = SweepGradient(
          colors: const [
            Color(0xFF7B7F83),
            Color(0xFFE9EBEC),
            Color(0xFFA3A7AA),
            Color(0xFF6A6E72),
            Color(0xFF7B7F83),
          ],
          transform: GradientRotation(-math.pi * 0.6),
        ).createShader(inner),
    );
    canvas.drawCircle(
      c,
      r * 0.875,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, r * 0.012)
        ..color = const Color(0xFF3F4346),
    );
  }

  void _drawDial(Canvas canvas, _Frame f, Offset c, double r) {
    final double faceR = r * 0.87;
    final Rect faceRect = Rect.fromCircle(center: c, radius: faceR);

    canvas.save();
    canvas.clipPath(Path()..addOval(faceRect));

    // Off-white face
    canvas.drawCircle(
      c,
      faceR,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFBFBF9), Color(0xFFF2F2F0), Color(0xFFE3E3E1)],
          stops: [0.0, 0.8, 1.0],
        ).createShader(faceRect),
    );
    // Soft inner shadow near the bezel
    canvas.drawCircle(
      c,
      faceR * 0.99,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05
        ..color = const Color(0x24000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(0.8, r * 0.02)),
    );
    canvas.restore();

    // --- Zone arc: green 50% / yellow 25% / red 25% -------------------------
    final double arcR = r * 0.67;
    final Rect arcRect = Rect.fromCircle(center: c, radius: arcR);
    final double zoneW = r * 0.14;

    Paint zone(Color col) => Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = zoneW
      ..strokeCap = StrokeCap.butt
      ..color = col;

    canvas.drawArc(arcRect, _startAngle, _totalAngle * 0.50, false, zone(_zoneGreen));
    canvas.drawArc(arcRect, _startAngle + _totalAngle * 0.50, _totalAngle * 0.25, false, zone(_zoneYellow));
    canvas.drawArc(arcRect, _startAngle + _totalAngle * 0.75, _totalAngle * 0.25, false, zone(_zoneRed));

    // --- Ticks --------------------------------------------------------------
    const int steps = 60;
    const Set<int> majors = {15, 20, 30, 35, 40, 45};
    final bool isSmall = r < 25;

    for (int i = 0; i <= steps; i++) {
      final bool isEnd = i == 0 || i == steps;
      final bool isMajor = majors.contains(i);
      if (isSmall && !isEnd && !isMajor && (i % 5 != 0)) {
        continue;
      }
      final double a = _startAngle + (i / steps) * _totalAngle;

      double inner;
      double outer;
      double width;
      if (isEnd) {
        inner = r * 0.52;
        outer = r * 0.71;
        width = r * 0.045;
      } else if (isMajor) {
        inner = r * 0.54;
        outer = r * 0.73;
        width = r * 0.028;
      } else {
        inner = r * 0.61;
        outer = r * 0.72;
        width = r * 0.009;
      }

      final Offset dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        c + dir * inner,
        c + dir * outer,
        Paint()
          ..color = (isEnd || isMajor) ? const Color(0xFF151515) : const Color(0xFF262626)
          ..strokeWidth = math.max(0.5, width)
          ..strokeCap = StrokeCap.butt,
      );
    }

    // --- Status LED ring ----------------------------------------------------
    final Offset led = c + Offset(0, -f.len(150));
    final double ringR = f.len(26);
    final double dotR = f.len(17);

    if (isOn) {
      canvas.drawCircle(
        led,
        ringR * 1.15,
        Paint()
          ..color = const Color(0xFF00E676).withValues(alpha: 0.30)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.0, f.len(8))),
      );
    }
    canvas.drawCircle(led, ringR, Paint()..color = const Color(0xFFF8F8F6));
    canvas.drawCircle(
      led,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, f.len(5))
        ..color = const Color(0xFF151515),
    );
    final Rect dotRect = Rect.fromCircle(center: led, radius: dotR);
    canvas.drawCircle(
      led,
      dotR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: isOn
              ? const [Color(0xFF7BC47F), Color(0xFF3E9A47)]
              : const [Color(0xFFB8B8B8), Color(0xFF777777)],
        ).createShader(dotRect),
    );
  }

  void _drawNeedle(Canvas canvas, _Frame f, Offset c, double r) {
    final double pVal = pressure?.clamp(0.0, 1.0) ?? 0.585;
    final double angle = _startAngle + (isOn ? _totalAngle * pVal : 0.0);
    final Offset dir = Offset(math.cos(angle), math.sin(angle));
    final Offset nrm = Offset(-dir.dy, dir.dx);

    final Offset tip = c + dir * f.len(198);
    final Offset tailEnd = c - dir * f.len(80);

    // Needle: tapered red blade
    final double baseHalf = f.len(13);
    final Path blade = Path()
      ..moveTo((c + nrm * baseHalf).dx, (c + nrm * baseHalf).dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo((c - nrm * baseHalf).dx, (c - nrm * baseHalf).dy)
      ..close();

    // Counterweight tail: short black block
    final double tailHalf = f.len(17);
    final Path tail = Path()
      ..moveTo((c + nrm * f.len(15)).dx, (c + nrm * f.len(15)).dy)
      ..lineTo((tailEnd + nrm * tailHalf).dx, (tailEnd + nrm * tailHalf).dy)
      ..lineTo((tailEnd - nrm * tailHalf).dx, (tailEnd - nrm * tailHalf).dy)
      ..lineTo((c - nrm * f.len(15)).dx, (c - nrm * f.len(15)).dy)
      ..close();

    // Shadows
    final Offset sh = Offset(f.len(4), f.len(6));
    final Paint shadow = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(0.8, f.len(4)));
    canvas.drawPath(blade.shift(sh), shadow);
    canvas.drawPath(tail.shift(sh), shadow);

    // Tail (black, rounded corners)
    canvas.drawPath(tail, Paint()..color = const Color(0xFF111111));
    canvas.drawPath(
      tail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(0.6, f.len(5))
        ..color = const Color(0xFF111111),
    );

    // Blade (red) + lighter half for a bevelled look
    canvas.drawPath(blade, Paint()..color = const Color(0xFFE04A2B));
    final Path lit = Path()
      ..moveTo((c + nrm * baseHalf).dx, (c + nrm * baseHalf).dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(c.dx, c.dy)
      ..close();
    canvas.drawPath(lit, Paint()..color = const Color(0xFFF0694A));

    // Hub: black disc, red ring, brass cap
    canvas.drawCircle(c, f.len(40), Paint()..color = const Color(0xFF111111));
    canvas.drawCircle(c, f.len(29), Paint()..color = const Color(0xFFE04A2B));

    final Rect capRect = Rect.fromCircle(center: c, radius: f.len(21));
    canvas.drawCircle(
      c,
      f.len(21),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.35),
          colors: [Color(0xFFFFEFB8), Color(0xFFC9A04A), Color(0xFF7A5A18)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(capRect),
    );
    canvas.drawCircle(
      c,
      f.len(21),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, f.len(2.5))
        ..color = const Color(0xFF3A2A08),
    );
  }

  void _drawGlass(Canvas canvas, Offset c, double r) {
    final double glassR = r * 0.87;
    final Rect rect = Rect.fromCircle(center: c, radius: glassR);

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    // Diagonal sheen
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.10),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ).createShader(rect),
    );

    // Bottom-right crescent reflection
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: glassR * 0.93),
      math.pi * 0.05,
      math.pi * 0.40,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.03)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(0.8, r * 0.015)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DetailedPressureSensorPainter old) =>
      old.isOn != isOn ||
      old.showJoints != showJoints ||
      old.pressure != pressure;
}

/// Maps reference-photo pixel coordinates to canvas coordinates.
class _Frame {
  final double s; // scale
  final double cx; // canvas centre x
  final double oy; // vertical offset

  const _Frame(this.s, this.cx, this.oy);

  double x(double px) => cx + (px - 500) * s;
  double y(double py) => oy + (py - 238) * s;
  Offset p(double px, double py) => Offset(x(px), y(py));
  Rect rect(double l, double t, double r, double b) =>
      Rect.fromLTRB(x(l), y(t), x(r), y(b));
  double len(double v) => v * s;
}

/// Widget wrapper for [DetailedPressureSensorPainter].
class PressureSensorView extends StatelessWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;
  final double? pressure;

  const PressureSensorView({
    super.key,
    required this.isOn,
    this.size = const Size(50, 50),
    this.showJoints = true,
    this.pressure,
  });

  /// Top inlet port location
  static Offset topPort(Size s) => DetailedPressureSensorPainter.topPort(s);

  /// Bottom outlet port location
  static Offset bottomPort(Size s) => DetailedPressureSensorPainter.bottomPort(s);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: DetailedPressureSensorPainter(
        isOn: isOn,
        showJoints: showJoints,
        pressure: pressure,
      ),
    );
  }
}