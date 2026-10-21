import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Detailed Soil Temperature Sensor Painter (v2 - realistic digital soil thermometer).
///
/// Visual features:
/// - Ergonomic charcoal handle with soft highlights and a green "agri" grip band
/// - Lanyard ring on top + stainless collar and tapered neck (showJoints)
/// - Backlit digital display: big digits, mini gauge bar, colour follows temperature
///   (blue = cold, green = ideal, amber = warm, orange-red = hot)
/// - Power / unit buttons and a glowing status LED
/// - Long stainless steel probe with depth scale (cm), sensing rings and a sharp tip
/// - Soft glow around the probe tip that matches the temperature colour when active
class DetailedSoilTemperatureSensorPainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;
  final double? temperature;

  DetailedSoilTemperatureSensorPainter({
    required this.isOn,
    this.showJoints = true,
    this.temperature,
  });

  static const double _refW = 500.0;
  static const double _refH = 800.0;

  static const Color _edge = Color(0xFF111614);

  static const Color _steelDark = Color(0xFF55606A);
  static const Color _steelMid = Color(0xFFA9B4BD);
  static const Color _steelLight = Color(0xFFF4F8FB);

  static const Color _bodyDark = Color(0xFF121816);
  static const Color _bodyMid = Color(0xFF26302C);
  static const Color _bodyLight = Color(0xFF4B5A53);

  static const Color _greenDark = Color(0xFF1B5E20);
  static const Color _greenMid = Color(0xFF43A047);
  static const Color _greenLight = Color(0xFFA5D66B);

  static const List<Color> _steelColors = [_steelDark, _steelMid, _steelLight, _steelMid, _steelDark];
  static const List<double> _steelStops = [0.0, 0.25, 0.5, 0.75, 1.0];

  double get _temp => temperature ?? 28.5;

  Color get _accent {
    final double t = _temp;
    if (t < 15) return const Color(0xFF4FC3F7);
    if (t < 25) return const Color(0xFF69F0AE);
    if (t < 35) return const Color(0xFFFFB74D);
    return const Color(0xFFFF7043);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width / _refW, size.height / _refH);
    final _Frame f = _Frame(s, size.width / 2, (size.height - _refH * s) / 2);

    _drawShadow(canvas, f);
    if (isOn) _drawTipGlow(canvas, f);
    if (showJoints) _drawLanyard(canvas, f);
    _drawProbe(canvas, f);
    _drawHandle(canvas, f);
    _drawDisplay(canvas, f);
    _drawButtonsAndLed(canvas, f);
    if (showJoints) _drawCollar(canvas, f);
  }

  // ───────────────────────── Paths ─────────────────────────

  Path _handlePath(_Frame f) {
    return Path()
      ..moveTo(f.x(200), f.y(80))
      ..quadraticBezierTo(f.x(250), f.y(55), f.x(300), f.y(80))
      ..cubicTo(f.x(325), f.y(120), f.x(335), f.y(220), f.x(318), f.y(300))
      ..cubicTo(f.x(310), f.y(345), f.x(300), f.y(370), f.x(295), f.y(385))
      ..lineTo(f.x(205), f.y(385))
      ..cubicTo(f.x(200), f.y(370), f.x(190), f.y(345), f.x(182), f.y(300))
      ..cubicTo(f.x(165), f.y(220), f.x(175), f.y(120), f.x(200), f.y(80))
      ..close();
  }

  // ───────────────────────── Shadow & glow ─────────────────────────

  void _drawShadow(Canvas canvas, _Frame f) {
    final Path p = _handlePath(f)
      ..addRect(f.r(237, 385, 263, 740))
      ..addPath(
        Path()
          ..moveTo(f.x(237), f.y(740))
          ..lineTo(f.x(263), f.y(740))
          ..lineTo(f.x(250), f.y(780))
          ..close(),
        Offset.zero,
      );
    canvas.drawPath(
      p.shift(Offset(f.len(16), f.len(20))),
      Paint()
        ..color = const Color(0x45000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.5, f.len(16))),
    );
  }

  void _drawTipGlow(Canvas canvas, _Frame f) {
    final Offset tip = f.p(250, 745);
    final Rect glowR = Rect.fromCircle(center: tip, radius: f.len(95));
    canvas.drawOval(
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _accent.withValues(alpha: 0.55),
            _accent.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(glowR),
    );
  }

  // ───────────────────────── Lanyard ─────────────────────────

  void _drawLanyard(Canvas canvas, _Frame f) {
    final Offset c = f.p(250, 52);
    canvas.drawCircle(
      c,
      f.len(17),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = f.len(7)
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_steelLight, _steelMid, _steelDark],
        ).createShader(Rect.fromCircle(center: c, radius: f.len(20))),
    );
    canvas.drawCircle(
      c,
      f.len(20.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = f.len(1)
        ..color = _edge.withValues(alpha: 0.7),
    );
  }

  // ───────────────────────── Probe ─────────────────────────

  void _drawProbe(Canvas canvas, _Frame f) {
    final Rect rod = f.r(237, 385, 263, 740);

    // Rod
    final RRect rr = RRect.fromRectAndRadius(rod, Radius.circular(f.len(2)));
    canvas.drawRRect(
      rr,
      Paint()..shader = const LinearGradient(colors: _steelColors, stops: _steelStops).createShader(rod),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = f.len(1)
        ..color = _edge.withValues(alpha: 0.8),
    );

    // Specular highlight
    canvas.drawLine(
      f.p(243, 395),
      f.p(243, 735),
      Paint()
        ..strokeWidth = f.len(1.6)
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // Depth scale
    for (int i = 0; i <= 15; i++) {
      final double y = 470.0 + i * 20.0;
      final bool major = i % 5 == 0;
      canvas.drawLine(
        f.p(237, y),
        f.p(major ? 251 : 245, y),
        Paint()
          ..strokeWidth = f.len(major ? 1.6 : 1.1)
          ..color = const Color(0xFF2B3238),
      );
      if (major) {
        _text(canvas, '${5 + i ~/ 5 * 5}', f.p(257, y), f.len(9), const Color(0xFF2B3238), weight: FontWeight.w700);
      }
    }

    // Sensing rings near the tip
    for (final double y in [700.0, 707.0]) {
      canvas.drawRect(
        f.r(237, y, 263, y + 3.5),
        Paint()..color = const Color(0xFF2B3238).withValues(alpha: 0.85),
      );
    }

    // Pointed tip
    final Path tip = Path()
      ..moveTo(f.x(237), f.y(740))
      ..lineTo(f.x(263), f.y(740))
      ..lineTo(f.x(250), f.y(780))
      ..close();
    canvas.drawPath(
      tip,
      Paint()
        ..shader = const LinearGradient(
          colors: [_steelDark, _steelLight, _steelDark],
          stops: [0.0, 0.5, 1.0],
        ).createShader(f.r(237, 740, 263, 780)),
    );
    canvas.drawPath(
      tip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = f.len(1)
        ..strokeJoin = StrokeJoin.round
        ..color = _edge.withValues(alpha: 0.85),
    );
  }

  // ───────────────────────── Handle ─────────────────────────

  void _drawHandle(Canvas canvas, _Frame f) {
    final Path handle = _handlePath(f);
    final Rect bounds = f.r(165, 55, 335, 385);

    // Body
    canvas.drawPath(
      handle,
      Paint()
        ..shader = const LinearGradient(
          colors: [_bodyDark, _bodyMid, _bodyLight, _bodyMid, _bodyDark],
          stops: [0.0, 0.2, 0.45, 0.8, 1.0],
        ).createShader(bounds),
    );

    canvas.save();
    canvas.clipPath(handle);

    // Soft gloss on the left
    final Rect gloss = f.r(196, 85, 214, 320);
    canvas.drawRRect(
      RRect.fromRectAndRadius(gloss, Radius.circular(f.len(9))),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.02),
          ],
        ).createShader(gloss)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.len(3)),
    );

    // Green grip band
    final Rect band = f.r(160, 328, 340, 374);
    canvas.drawRect(
      band,
      Paint()
        ..shader = const LinearGradient(
          colors: [_greenDark, _greenMid, _greenLight, _greenMid, _greenDark],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(band),
    );
    canvas.drawLine(
      f.p(160, 328),
      f.p(340, 328),
      Paint()
        ..strokeWidth = f.len(1.2)
        ..color = _edge,
    );
    canvas.drawLine(
      f.p(160, 374),
      f.p(340, 374),
      Paint()
        ..strokeWidth = f.len(1.2)
        ..color = _edge,
    );
    _text(canvas, 'AGRO PROBE', f.p(250, 351), f.len(13), Colors.white,
        weight: FontWeight.w800, letterSpacing: 2.0);

    canvas.restore();

    // Outline
    canvas.drawPath(
      handle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = f.len(2)
        ..strokeJoin = StrokeJoin.round
        ..color = _edge,
    );
  }

  // ───────────────────────── Display ─────────────────────────

  void _drawDisplay(Canvas canvas, _Frame f) {
    final Rect bezel = f.r(184, 122, 316, 240);
    final RRect bezelRR = RRect.fromRectAndRadius(bezel, Radius.circular(f.len(12)));
    canvas.drawRRect(bezelRR, Paint()..color = const Color(0xFF070A09));
    canvas.drawRRect(
      bezelRR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = f.len(2)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_steelMid.withValues(alpha: 0.9), _steelDark],
        ).createShader(bezel),
    );

    // Screen
    final Rect scr = f.r(192, 130, 308, 232);
    final RRect scrRR = RRect.fromRectAndRadius(scr, Radius.circular(f.len(8)));
    final Color acc = _accent;

    canvas.drawRRect(
      scrRR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isOn
              ? [const Color(0xFF05100C), Color.lerp(const Color(0xFF05100C), acc, 0.22)!]
              : [const Color(0xFF0A0E0C), const Color(0xFF0D1210)],
        ).createShader(scr),
    );

    canvas.save();
    canvas.clipRRect(scrRR);

    final Color labelCol = isOn ? acc.withValues(alpha: 0.85) : const Color(0xFF3A4540);
    _text(canvas, 'SOIL TEMP', f.p(232, 143), f.len(10), labelCol, weight: FontWeight.w700, letterSpacing: 1.2);
    _text(canvas, '°C', f.p(292, 143), f.len(12), labelCol, weight: FontWeight.w800);

    final String value = isOn ? _temp.toStringAsFixed(1) : '--.-';
    final Color digitCol = isOn ? acc : const Color(0xFF3A4540);
    _text(canvas, value, f.p(250, 182), f.len(40), digitCol,
        weight: FontWeight.w700, glow: isOn ? f.len(7) : 0, tabular: true);

    // Mini gauge
    final RRect track = RRect.fromRectAndRadius(f.r(204, 212, 296, 219), Radius.circular(f.len(3.5)));
    canvas.drawRRect(track, Paint()..color = Colors.white.withValues(alpha: 0.08));
    if (isOn) {
      final double frac = (_temp / 50.0).clamp(0.02, 1.0);
      final Rect fill = f.r(204, 212, 204 + 92 * frac, 219);
      canvas.drawRRect(
        RRect.fromRectAndRadius(fill, Radius.circular(f.len(3.5))),
        Paint()
          ..shader = LinearGradient(
            colors: [const Color(0xFF4FC3F7), const Color(0xFF69F0AE), const Color(0xFFFFB74D), const Color(0xFFFF7043)],
          ).createShader(f.r(204, 212, 296, 219)),
      );
    }

    // Glass reflection
    canvas.drawPath(
      Path()
        ..moveTo(scr.left, scr.top)
        ..lineTo(scr.right, scr.top)
        ..lineTo(scr.left, scr.top + scr.height * 0.55)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    canvas.restore();
  }

  // ───────────────────────── Buttons & LED ─────────────────────────

  void _drawButtonsAndLed(Canvas canvas, _Frame f) {
    // Status LED
    final Offset ledC = f.p(250, 106);
    final double ledR = f.len(5.5);
    canvas.drawCircle(ledC, ledR + f.len(2), Paint()..color = const Color(0xFF070A09));
    final Color ledCol = isOn ? const Color(0xFF00E676) : const Color(0xFF6B7A74);
    if (isOn) {
      canvas.drawCircle(
        ledC,
        ledR * 2.2,
        Paint()
          ..color = const Color(0x8800E676)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.len(6)),
      );
    }
    canvas.drawCircle(ledC, ledR, Paint()..color = ledCol);
    canvas.drawCircle(
      ledC - Offset(ledR * 0.3, ledR * 0.3),
      ledR * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    // Buttons
    for (final double bx in [215.0, 285.0]) {
      final Offset c = f.p(bx, 281);
      final double r = f.len(15);
      final Rect rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(c + Offset(0, f.len(1.5)), r, Paint()..color = Colors.black.withValues(alpha: 0.5));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFF5B6A63), Color(0xFF232C28)],
          ).createShader(rect),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = f.len(1.3)
          ..color = _edge,
      );
    }

    // Power icon
    final Offset pc = f.p(215, 281);
    final Color iconCol = isOn ? const Color(0xFF00E676) : Colors.white70;
    final Paint ip = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = f.len(2)
      ..color = iconCol;
    canvas.drawArc(Rect.fromCircle(center: pc, radius: f.len(6.5)), -math.pi / 2 + 0.6, math.pi * 2 - 1.2, false, ip);
    canvas.drawLine(pc - Offset(0, f.len(8)), pc - Offset(0, f.len(1.5)), ip);

    // Unit icon
    _text(canvas, '°C', f.p(285, 281), f.len(12), Colors.white70, weight: FontWeight.w800);
  }

  // ───────────────────────── Collar ─────────────────────────

  void _drawCollar(Canvas canvas, _Frame f) {
    // Tapered neck
    final Path neck = Path()
      ..moveTo(f.x(222), f.y(407))
      ..lineTo(f.x(278), f.y(407))
      ..lineTo(f.x(265), f.y(432))
      ..lineTo(f.x(235), f.y(432))
      ..close();
    canvas.drawPath(
      neck,
      Paint()
        ..shader = const LinearGradient(colors: _steelColors, stops: _steelStops)
            .createShader(f.r(222, 407, 278, 432)),
    );
    canvas.drawPath(
      neck,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = f.len(1)
        ..strokeJoin = StrokeJoin.round
        ..color = _edge.withValues(alpha: 0.85),
    );

    // Stainless collar
    final Rect collar = f.r(208, 383, 292, 409);
    final RRect crr = RRect.fromRectAndRadius(collar, Radius.circular(f.len(4)));
    canvas.drawRRect(
      crr,
      Paint()..shader = const LinearGradient(colors: _steelColors, stops: _steelStops).createShader(collar),
    );
    canvas.drawRRect(
      crr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = f.len(1.2)
        ..color = _edge,
    );
    for (final double y in [391.0, 397.0, 403.0]) {
      canvas.drawLine(
        f.p(210, y),
        f.p(290, y),
        Paint()
          ..strokeWidth = f.len(1)
          ..color = const Color(0xFF2B3238).withValues(alpha: 0.6),
      );
    }
  }

  // ───────────────────────── Helpers ─────────────────────────

  void _text(
      Canvas canvas,
      String text,
      Offset center,
      double fontSize,
      Color color, {
        FontWeight weight = FontWeight.w600,
        double letterSpacing = 0,
        double glow = 0,
        bool tabular = false,
      }) {
    TextPainter build(TextStyle style) => TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final List<FontFeature> features = tabular ? const [FontFeature.tabularFigures()] : const [];

    if (glow > 0) {
      final TextPainter g = build(TextStyle(
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: 1.0,
        fontFeatures: features,
        foreground: Paint()
          ..color = color.withValues(alpha: 0.75)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow),
      ));
      g.paint(canvas, center - Offset(g.width / 2, g.height / 2));
    }

    final TextPainter tp = build(TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: 1.0,
      fontFeatures: features,
    ));
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant DetailedSoilTemperatureSensorPainter old) {
    return old.isOn != isOn || old.showJoints != showJoints || old.temperature != temperature;
  }
}

class _Frame {
  final double s;
  final double ox;
  final double oy;

  _Frame(this.s, this.ox, this.oy);

  double x(double px) => ox + (px - 250.0) * s;
  double y(double py) => oy + py * s;
  double len(double l) => l * s;
  Offset p(double px, double py) => Offset(x(px), y(py));
  Rect r(double l, double t, double r, double b) => Rect.fromLTRB(x(l), y(t), x(r), y(b));
}