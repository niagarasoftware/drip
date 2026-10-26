import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Realistic single hydraulic control valve (Y-pattern diaphragm valve).
///
/// Static painter (no animation) with a grey → dark metallic gradient,
/// rim lighting so it stays clearly visible on dark backgrounds, flanged
/// ends with bolt heads, a Y body, a bolted bonnet, a solenoid and a
/// pilot control hose.
///
/// [isOn] only changes the colour of the small status beacon on top.
class DetailedSingleValvePainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;

  DetailedSingleValvePainter({
    required this.isOn,
    this.showJoints = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Scale so the whole valve (flanges, hose, solenoid) fills the canvas.
    final double s = math.min(size.width / 0.86, size.height / 0.72);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + s * 0.19);
    _ValveArt.paint(canvas, s,
        showJoints: showJoints, isOn: isOn, flangeBolts: true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DetailedSingleValvePainter old) =>
      old.isOn != isOn || old.showJoints != showJoints;
}

/// Widget wrapper for [DetailedSingleValvePainter].
class SingleValveView extends StatelessWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  const SingleValveView({
    super.key,
    required this.isOn,
    this.size = const Size(110, 80),
    this.showJoints = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: DetailedSingleValvePainter(
        isOn: isOn,
        showJoints: showJoints,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared valve artwork (origin = valve centre, [s] = scale)
// ─────────────────────────────────────────────────────────────
class _ValveArt {
  _ValveArt._();

  static const Color _edge = Color(0xFF0A0E12);
  static const Color _rim = Color(0xFFD3DBE2);

  static const Color _orangeLight = Color(0xFFFFA040);
  static const Color _orangeMid = Color(0xFFFF7A1A);
  static const Color _orangeDark = Color(0xFFD9540A);

  // Cylindrical metal: bright top / left → dark bottom / right.
  static const List<Color> _metal = [
    Color(0xFF7F8B96),
    Color(0xFFBAC4CD),
    Color(0xFF7D8994),
    Color(0xFF444F58),
    Color(0xFF1E252B),
  ];
  static const List<double> _metalStops = [0.0, 0.16, 0.42, 0.76, 1.0];

  // Cast body: light grey → near black.
  static const List<Color> _bodyCols = [
    Color(0xFFA6B1BB),
    Color(0xFF6D7983),
    Color(0xFF39434C),
    Color(0xFF171D22),
  ];
  static const List<double> _bodyStops = [0.0, 0.34, 0.70, 1.0];

  static Paint _shade(Rect r, List<Color> cols, List<double> stops,
      {required bool vertical}) =>
      Paint()
        ..isAntiAlias = true
        ..shader = LinearGradient(
          colors: cols,
          stops: stops,
          begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
          end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
        ).createShader(r);

  static Paint _line(Color color, double w) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = color;

  /// Shaded cylinder. [horizontal] = axis runs left-right.
  static void _cyl(Canvas c, Rect r, double radius,
      {required bool horizontal, required double lw}) {
    if (r.width <= 0 || r.height <= 0) return;
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, _shade(r, _metal, _metalStops, vertical: horizontal));

    final double t = horizontal ? r.height : r.width;
    final streak = horizontal
        ? Rect.fromLTWH(r.left + radius, r.top + t * 0.14,
        math.max(0.0, r.width - radius * 2), math.max(0.6, t * 0.07))
        : Rect.fromLTWH(r.left + t * 0.14, r.top + radius,
        math.max(0.6, t * 0.07), math.max(0.0, r.height - radius * 2));
    if (streak.width > 0 && streak.height > 0) {
      c.drawRRect(
        RRect.fromRectAndRadius(streak, Radius.circular(t * 0.04)),
        Paint()..color = Colors.white.withValues(alpha: 0.30),
      );
    }
    c.drawRRect(rr, _line(_edge.withValues(alpha: 0.75), lw));
  }

  static void _boltHead(Canvas c, Offset o, double r, double lw) {
    c.drawCircle(o, r, Paint()..color = const Color(0xFFDDE4EA));
    c.drawCircle(o, r, _line(_edge, lw));
    c.drawCircle(o, r * 0.38, Paint()..color = const Color(0xFF5C6873));
  }

  static void paint(
      Canvas c,
      double s, {
        required bool showJoints,
        required bool isOn,
        required bool flangeBolts,
      }) {
    final hw = s * 0.38;
    final lw = math.max(0.7, s * 0.008);

    final base = Offset(0, -s * 0.18);
    const angle = -0.62;
    final ca = math.cos(angle);
    final sa = math.sin(angle);
    Offset rotated(double x, double y) => Offset(
      base.dx + (x * ca - y * sa) * s,
      base.dy + (x * sa + y * ca) * s,
    );

    // Soft ground shadow.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.15),
        width: hw * 2.10,
        height: s * 0.07,
      ),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
    );

    // Mounting feet.
    for (final x in [-hw * 0.52, hw * 0.38]) {
      final p = Path()
        ..moveTo(x - s * 0.05, s * 0.08)
        ..lineTo(x - s * 0.065, s * 0.14)
        ..lineTo(x + s * 0.065, s * 0.14)
        ..lineTo(x + s * 0.05, s * 0.08)
        ..close();
      c.drawPath(
          p, _shade(p.getBounds(), _metal, _metalStops, vertical: true));
      c.drawPath(p, _line(_edge, lw));
    }

    // Horizontal barrel.
    _cyl(
      c,
      Rect.fromLTRB(-hw + s * 0.035, -s * 0.10, hw - s * 0.035, s * 0.10),
      s * 0.03,
      horizontal: true,
      lw: lw,
    );

    // Y chamber body.
    final body = Path()
      ..moveTo(-hw + s * 0.05, -s * 0.10)
      ..cubicTo(-s * 0.20, -s * 0.12, -s * 0.16, -s * 0.20, -s * 0.10, -s * 0.25)
      ..cubicTo(-s * 0.05, -s * 0.30, -s * 0.03, -s * 0.31, 0, -s * 0.32)
      ..cubicTo(s * 0.03, -s * 0.31, s * 0.05, -s * 0.30, s * 0.10, -s * 0.25)
      ..cubicTo(s * 0.16, -s * 0.20, s * 0.20, -s * 0.12, hw - s * 0.05, -s * 0.10)
      ..lineTo(hw - s * 0.05, s * 0.10)
      ..lineTo(-hw + s * 0.05, s * 0.10)
      ..close();
    final bb = body.getBounds();
    c.drawPath(body, _shade(bb, _bodyCols, _bodyStops, vertical: true));
    c.save();
    c.clipPath(body);
    c.drawRect(
      bb,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55],
        ).createShader(bb),
    );
    c.restore();
    c.drawPath(body, _line(_rim.withValues(alpha: 0.55), lw * 1.3));

    // Raised ribs (embossed: shadow + highlight).
    final rib = Path()
      ..moveTo(-s * 0.15, -s * 0.065)
      ..quadraticBezierTo(-s * 0.08, -s * 0.16, 0, -s * 0.27)
      ..quadraticBezierTo(s * 0.08, -s * 0.16, s * 0.15, -s * 0.065);
    c.drawPath(rib.shift(Offset(0, lw * 1.4)),
        _line(Colors.black.withValues(alpha: 0.45), lw * 1.6));
    c.drawPath(
        rib, _line(const Color(0xFFC7D0D8).withValues(alpha: 0.70), lw * 1.6));

    // Side inspection plug.
    final plug = Offset(-hw * 0.57, s * 0.02);
    c.drawCircle(plug, s * 0.03, Paint()..color = const Color(0xFF232B31));
    c.drawCircle(plug, s * 0.03, _line(const Color(0xFFB4BFC8), lw * 1.2));
    c.drawCircle(plug, s * 0.012, Paint()..color = const Color(0xFF7D8994));
    c.drawCircle(plug.translate(-s * 0.004, -s * 0.004), s * 0.005,
        Paint()..color = Colors.white.withValues(alpha: 0.5));

    // Flow direction arrow.
    final arrow = Path()
      ..moveTo(-s * 0.16, s * 0.045)
      ..lineTo(-s * 0.07, s * 0.045)
      ..moveTo(-s * 0.10, s * 0.022)
      ..lineTo(-s * 0.07, s * 0.045)
      ..lineTo(-s * 0.10, s * 0.068);
    c.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, s * 0.012)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFE3E9EE).withValues(alpha: 0.85),
    );

    // Union collars with ridges.
    final nw = s * 0.065;
    for (final rect in [
      Rect.fromLTWH(-hw + s * 0.035, -s * 0.138, nw, s * 0.276),
      Rect.fromLTWH(hw - s * 0.035 - nw, -s * 0.138, nw, s * 0.276),
    ]) {
      _cyl(c, rect, s * 0.012, horizontal: true, lw: lw);
      if (showJoints) {
        for (var k = 1; k <= 3; k++) {
          final x = rect.left + rect.width * k / 4;
          c.drawLine(Offset(x, rect.top + 2), Offset(x, rect.bottom - 2),
              Paint()
                ..color = Colors.black.withValues(alpha: 0.55)
                ..strokeWidth = lw);
          c.drawLine(Offset(x + lw, rect.top + 2),
              Offset(x + lw, rect.bottom - 2),
              Paint()
                ..color = Colors.white.withValues(alpha: 0.18)
                ..strokeWidth = lw * 0.8);
        }
      }
    }

    // Angled bonnet + actuator.
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle);

    _cyl(
      c,
      Rect.fromLTRB(-s * 0.18, -s * 0.045, s * 0.18, s * 0.012),
      s * 0.012,
      horizontal: true,
      lw: lw,
    );
    if (showJoints) {
      for (final bx in const [-0.14, -0.07, 0.0, 0.07, 0.14]) {
        _boltHead(c, Offset(s * bx, -s * 0.017), s * 0.011, lw * 0.8);
      }
    }

    // Dome with ribs.
    _cyl(
      c,
      Rect.fromLTRB(-s * 0.155, -s * 0.195, s * 0.155, -s * 0.045),
      s * 0.05,
      horizontal: true,
      lw: lw,
    );
    for (final rx in const [-0.095, -0.03, 0.03, 0.095]) {
      c.drawLine(
        Offset(s * rx, -s * 0.172),
        Offset(s * rx, -s * 0.068),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..strokeWidth = lw * 1.2,
      );
      c.drawLine(
        Offset(s * rx + lw * 1.2, -s * 0.172),
        Offset(s * rx + lw * 1.2, -s * 0.068),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.16)
          ..strokeWidth = lw,
      );
    }

    // Stem sections.
    _cyl(c, Rect.fromLTRB(-s * 0.065, -s * 0.28, s * 0.065, -s * 0.195),
        s * 0.01,
        horizontal: false, lw: lw);
    _cyl(c, Rect.fromLTRB(-s * 0.04, -s * 0.368, s * 0.04, -s * 0.28),
        s * 0.01,
        horizontal: false, lw: lw);

    // Orange solenoid knob.
    final knob = Rect.fromLTWH(-s * 0.08, -s * 0.338, s * 0.045, s * 0.045);
    final knobR = RRect.fromRectAndRadius(knob, Radius.circular(s * 0.008));
    c.drawRRect(
      knobR,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_orangeLight, _orangeMid, _orangeDark],
        ).createShader(knob),
    );
    c.drawRRect(knobR, _line(_edge, lw));

    // Top cap + status beacon.
    _cyl(c, Rect.fromLTRB(-s * 0.03, -s * 0.39, s * 0.03, -s * 0.368),
        s * 0.005,
        horizontal: true, lw: lw);
    final beacon = isOn ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    c.drawCircle(Offset(0, -s * 0.40), s * 0.018,
        Paint()..color = beacon.withValues(alpha: 0.25));
    c.drawCircle(Offset(0, -s * 0.40), s * 0.011, Paint()..color = beacon);
    c.restore();

    // Pilot control hose.
    final pilotIn = rotated(-0.03, -0.34);
    final pilotOut = rotated(0.03, -0.32);
    final bodyIn = Offset(-hw + s * 0.10, -s * 0.075);
    final bodyOut = Offset(hw - s * 0.10, -s * 0.075);
    final hoseW = math.max(1.6, s * 0.016);

    final loop = Path()
      ..moveTo(pilotIn.dx, pilotIn.dy)
      ..cubicTo(
        pilotIn.dx - s * 0.20, pilotIn.dy - s * 0.165,
        -hw - s * 0.01, -s * 0.475,
        -hw + s * 0.088, -s * 0.225,
      )
      ..cubicTo(
        -hw + s * 0.115, -s * 0.145,
        bodyIn.dx - s * 0.038, bodyIn.dy - s * 0.065,
        bodyIn.dx, bodyIn.dy,
      );
    final outletTube = Path()
      ..moveTo(pilotOut.dx, pilotOut.dy)
      ..cubicTo(
        pilotOut.dx + s * 0.155, pilotOut.dy + s * 0.05,
        bodyOut.dx + s * 0.07, bodyOut.dy - s * 0.145,
        bodyOut.dx, bodyOut.dy,
      );
    for (final tube in [loop, outletTube]) {
      c.drawPath(tube, _line(_edge, hoseW + lw * 1.6));
      c.drawPath(tube, _line(const Color(0xFF56636D), hoseW));
      c.drawPath(tube,
          _line(const Color(0xFFC3CDD5).withValues(alpha: 0.55), hoseW * 0.32));
    }
    for (final p in [pilotIn, pilotOut, bodyIn, bodyOut]) {
      final r = s * 0.017;
      c.drawCircle(p, r, Paint()..color = const Color(0xFF3A444D));
      c.drawCircle(p, r, _line(const Color(0xFFB8C2CA), lw));
      c.drawCircle(p, r * 0.4, Paint()..color = const Color(0xFF8E9AA5));
    }

    // End flanges.
    final fh = s * 0.188;
    final fw = s * 0.06;
    for (final side in const [-1, 1]) {
      final rim = side < 0
          ? Rect.fromLTWH(-hw, -fh, fw, fh * 2)
          : Rect.fromLTWH(hw - fw, -fh, fw, fh * 2);
      _cyl(c, rim, s * 0.015, horizontal: false, lw: lw);
      if (flangeBolts && showJoints) {
        for (final yy in [-fh * 0.68, fh * 0.68]) {
          final head = Rect.fromCenter(
            center: Offset(rim.center.dx, yy),
            width: fw * 1.3,
            height: s * 0.034,
          );
          _cyl(c, head, s * 0.006, horizontal: true, lw: lw * 0.8);
        }
      }
    }
  }
}