import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Realistic soil moisture sensor painter (vertical, probe pointing down).
///
/// Visual features:
/// - Black rubber cable with a ribbed, tapered strain-relief boot (top)
/// - Steel neck with hex cable-gland nut
/// - Black ABS sensor head with label plate, droplet icon and green brand band
/// - Status LED in a steel ring
/// - Steel mounting collar with screws
/// - Two stainless-steel probe rods with depth grooves, pointed tips and a
///   black plastic spacer bar
/// - Faint blue sensing field between the rods while active
///
/// [isOn]       true  -> LED green, sensing field visible
///              false -> LED grey, no sensing field
/// [showJoints] draws the cable-gland nut (top); false hides it
///
/// Ports: [topPort] is the cable entry (top edge), [bottomPort] is the probe
/// tips (bottom edge). Live values are meant to be drawn by your own widget.
class DetailedMoistureSensorPainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;

  DetailedMoistureSensorPainter({
    required this.isOn,
    this.showJoints = true,
  });

  // Reference layout: 500 x 900 design units, centred on x = 250.
  static const double _refW = 500.0;
  static const double _refH = 900.0;

  // Palette
  static const Color _edge = Color(0xFF14181B);

  static const Color _steelDark = Color(0xFF454F59);
  static const Color _steelMid = Color(0xFF9AA5AE);
  static const Color _steelLight = Color(0xFFE3E7EA);

  static const Color _blackDark = Color(0xFF07090B);
  static const Color _blackMid = Color(0xFF2A2F35);
  static const Color _blackLight = Color(0xFF59616B);

  static const Color _green = Color(0xFF3E9A47);

  static Offset topPort(Size s) => Offset(s.width * 0.5, 0);
  static Offset bottomPort(Size s) => Offset(s.width * 0.5, s.height);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width / _refW, size.height / _refH);
    final _Frame f = _Frame(s, size.width / 2, (size.height - _refH * s) / 2);

    _drawShadow(canvas, f);
    if (isOn) _drawSensingField(canvas, f);
    _drawRods(canvas, f);
    _drawSpacer(canvas, f);
    _drawCollar(canvas, f);
    _drawHead(canvas, f);
    _drawLabel(canvas, f);
    _drawLed(canvas, f);
    _drawNeckAndCable(canvas, f);
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
      Paint()
        ..shader = LinearGradient(colors: colors, stops: stops).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = edgeWidth
        ..color = _edge.withValues(alpha: 0.85),
    );
  }

  void _text(
      Canvas canvas,
      String text,
      Offset center,
      double fontSize,
      Color color, {
        FontWeight weight = FontWeight.w600,
        double letterSpacing = 0,
      }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _screw(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFF0F1F2), Color(0xFF9A9EA2), Color(0xFF55595D)],
          stops: [0.0, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.4, r * 0.12)
        ..color = const Color(0xFF2B2F33),
    );
    final Paint slot = Paint()
      ..color = _edge
      ..strokeWidth = math.max(0.4, r * 0.18);
    canvas.drawLine(c + Offset(-r * 0.6, -r * 0.2), c + Offset(r * 0.6, r * 0.2), slot);
  }

  // ---------------------------------------------------------------------------
  // Probe
  // ---------------------------------------------------------------------------

  void _drawShadow(Canvas canvas, _Frame f) {
    final Paint shadow = Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.5, f.len(14)));
    final Offset d = Offset(f.len(14), f.len(16));

    canvas.drawRRect(
      RRect.fromRectAndRadius(f.rect(160, 205, 340, 470).shift(d), Radius.circular(f.len(28))),
      shadow,
    );
    canvas.drawRect(f.rect(195, 500, 215, 880).shift(d), shadow);
    canvas.drawRect(f.rect(285, 500, 305, 880).shift(d), shadow);
  }

  void _drawSensingField(Canvas canvas, _Frame f) {
    final Rect field = f.rect(215, 555, 285, 870);
    canvas.drawRect(
      field,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF29B6F6).withValues(alpha: 0.30),
            const Color(0xFF29B6F6).withValues(alpha: 0.05),
          ],
        ).createShader(field),
    );

    // Faint field lines between the rods
    final Paint line = Paint()
      ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.35)
      ..strokeWidth = math.max(0.4, f.len(1.5));
    for (double y = 580; y < 860; y += 26) {
      canvas.drawLine(f.p(216, y), f.p(284, y), line);
    }
  }

  void _drawRods(Canvas canvas, _Frame f) {
    for (final double cx in const [205, 295]) {
      final double x1 = cx - 11;
      final double x2 = cx + 11;

      final Path rod = Path()
        ..moveTo(f.x(x1), f.y(500))
        ..lineTo(f.x(x1), f.y(850))
        ..lineTo(f.x(cx), f.y(900))
        ..lineTo(f.x(x2), f.y(850))
        ..lineTo(f.x(x2), f.y(500))
        ..close();

      final Rect box = f.rect(x1, 500, x2, 900);
      canvas.drawPath(
        rod,
        Paint()
          ..shader = const LinearGradient(
            colors: [_steelDark, _steelMid, _steelLight, _steelMid, _steelDark],
            stops: [0.0, 0.2, 0.42, 0.75, 1.0],
          ).createShader(box),
      );
      canvas.drawPath(
        rod,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.7, f.len(2.5))
          ..strokeJoin = StrokeJoin.round
          ..color = _edge.withValues(alpha: 0.85),
      );

      // Tip highlight
      canvas.drawLine(
        f.p(cx - 3, 856),
        f.p(cx - 1, 890),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = math.max(0.4, f.len(2)),
      );

      // Depth grooves
      for (final double gy in const [620, 700, 780]) {
        canvas.drawLine(
          f.p(x1 + 1, gy),
          f.p(x2 - 1, gy),
          Paint()
            ..color = const Color(0x77000000)
            ..strokeWidth = math.max(0.5, f.len(3)),
        );
        canvas.drawLine(
          f.p(x1 + 1, gy + 3.5),
          f.p(x2 - 1, gy + 3.5),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.4)
            ..strokeWidth = math.max(0.4, f.len(1.8)),
        );
      }
    }
  }

  void _drawSpacer(Canvas canvas, _Frame f) {
    _cylinder(
      canvas,
      f.rect(184, 524, 316, 556),
      const [_blackDark, _blackMid, _blackLight, _blackMid, _blackDark],
      const [0.0, 0.2, 0.45, 0.78, 1.0],
      radius: f.len(5),
      edgeWidth: math.max(0.7, f.len(2.5)),
    );
    // Top highlight
    canvas.drawLine(
      f.p(190, 529),
      f.p(310, 529),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = math.max(0.4, f.len(2)),
    );
  }

  void _drawCollar(Canvas canvas, _Frame f) {
    _cylinder(
      canvas,
      f.rect(148, 462, 352, 512),
      const [_steelDark, _steelMid, _steelLight, _steelMid, _steelDark],
      const [0.0, 0.18, 0.45, 0.8, 1.0],
      radius: f.len(7),
      edgeWidth: math.max(0.8, f.len(3)),
    );
    canvas.drawLine(
      f.p(155, 468),
      f.p(345, 468),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = math.max(0.5, f.len(3)),
    );
    canvas.drawLine(
      f.p(155, 506),
      f.p(345, 506),
      Paint()
        ..color = const Color(0x44000000)
        ..strokeWidth = math.max(0.5, f.len(3)),
    );
    _screw(canvas, f.p(172, 487), f.len(9));
    _screw(canvas, f.p(328, 487), f.len(9));
  }

  // ---------------------------------------------------------------------------
  // Head
  // ---------------------------------------------------------------------------

  void _drawHead(Canvas canvas, _Frame f) {
    _cylinder(
      canvas,
      f.rect(160, 205, 340, 470),
      const [_blackDark, _blackMid, _blackLight, _blackMid, _blackDark],
      const [0.0, 0.2, 0.42, 0.78, 1.0],
      radius: f.len(28),
      edgeWidth: math.max(0.8, f.len(3)),
    );

    // Soft top shine
    canvas.drawRRect(
      RRect.fromRectAndRadius(f.rect(170, 212, 330, 232), Radius.circular(f.len(10))),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    // Green brand band near the bottom
    final Rect band = f.rect(160, 436, 340, 454);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _green.withValues(alpha: 0.65),
            const Color(0xFF8FD89A),
            _green,
            _green.withValues(alpha: 0.65),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ).createShader(band),
    );
    canvas.drawRect(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.4, f.len(1.5))
        ..color = Colors.black.withValues(alpha: 0.6),
    );
  }

  void _drawLabel(Canvas canvas, _Frame f) {
    final Rect plate = f.rect(186, 282, 314, 422);
    final RRect rr = RRect.fromRectAndRadius(plate, Radius.circular(f.len(8)));

    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F5F3), Color(0xFFD9DCDA), Color(0xFFBFC3C2)],
          stops: [0.0, 0.6, 1.0],
        ).createShader(plate),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, f.len(2))
        ..color = const Color(0xFF3A3F44),
    );

    _text(canvas, 'SOILSENSE', f.p(250, 306), f.len(18), const Color(0xFF1B3A6B),
        weight: FontWeight.w800, letterSpacing: f.len(1.5));
    _text(canvas, 'VWC SENSOR', f.p(250, 330), f.len(11), const Color(0xFF3A3F44),
        weight: FontWeight.w600, letterSpacing: f.len(1.2));

    // Water droplet icon
    final Offset dc = f.p(250, 378);
    final double dr = f.len(15);
    final Path drop = Path()
      ..moveTo(dc.dx, dc.dy - dr * 2.0)
      ..lineTo(dc.dx + dr * 0.866, dc.dy - dr * 0.5)
      ..arcTo(Rect.fromCircle(center: dc, radius: dr), -math.pi / 6, 4 * math.pi / 3, false)
      ..close();
    canvas.drawPath(
      drop,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7CC8F5), Color(0xFF1E6FB8)],
        ).createShader(Rect.fromCircle(center: dc, radius: dr * 2.0)),
    );
    canvas.drawPath(
      drop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.4, f.len(1.5))
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF0E3F70),
    );
    canvas.drawCircle(
      dc + Offset(-dr * 0.35, dr * 0.1),
      dr * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    _text(canvas, 'IP68', f.p(250, 408), f.len(11), const Color(0xFF3A3F44),
        weight: FontWeight.w700, letterSpacing: f.len(1.5));
  }

  void _drawLed(Canvas canvas, _Frame f) {
    final Offset c = f.p(250, 254);
    final double ring = f.len(14);
    final double lamp = f.len(8.5);

    // Steel ring
    canvas.drawCircle(
      c,
      ring,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F2F3), Color(0xFF8E959B), Color(0xFF4D545A)],
        ).createShader(Rect.fromCircle(center: c, radius: ring)),
    );
    canvas.drawCircle(
      c,
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, f.len(2))
        ..color = _edge,
    );

    if (isOn) {
      canvas.drawCircle(
        c,
        ring * 1.8,
        Paint()
          ..color = const Color(0xFF00E676).withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.0, f.len(8))),
      );
    }

    canvas.drawCircle(
      c,
      lamp,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: isOn
              ? const [Color(0xFFB9FFD6), Color(0xFF00C853)]
              : const [Color(0xFF8A8A8A), Color(0xFF4A4A4A)],
        ).createShader(Rect.fromCircle(center: c, radius: lamp)),
    );
    canvas.drawCircle(
      c,
      lamp,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.4, f.len(1.5))
        ..color = Colors.black,
    );
  }

  // ---------------------------------------------------------------------------
  // Cable
  // ---------------------------------------------------------------------------

  void _drawNeckAndCable(Canvas canvas, _Frame f) {
    // Steel neck between boot and head
    _cylinder(
      canvas,
      f.rect(214, 165, 286, 212),
      const [_steelDark, _steelMid, _steelLight, _steelMid, _steelDark],
      const [0.0, 0.2, 0.45, 0.78, 1.0],
      radius: f.len(3),
    );

    // Hex cable-gland nut
    if (showJoints) {
      final Rect nut = f.rect(190, 172, 310, 206);
      _cylinder(
        canvas,
        nut,
        const [
          _steelDark,
          _steelMid,
          _steelLight,
          _steelMid,
          _steelLight,
          _steelMid,
          _steelDark,
        ],
        const [0.0, 0.12, 0.30, 0.50, 0.68, 0.88, 1.0],
        radius: f.len(5),
        edgeWidth: math.max(0.7, f.len(3)),
      );
      final Paint sep = Paint()
        ..color = const Color(0x55000000)
        ..strokeWidth = math.max(0.5, f.len(2.5));
      canvas.drawLine(f.p(226, 174), f.p(226, 204), sep);
      canvas.drawLine(f.p(274, 174), f.p(274, 204), sep);
    }

    // Tapered strain-relief boot
    final Path boot = Path()
      ..moveTo(f.x(232), f.y(90))
      ..lineTo(f.x(268), f.y(90))
      ..lineTo(f.x(292), f.y(172))
      ..lineTo(f.x(208), f.y(172))
      ..close();
    final Rect bootBox = f.rect(208, 90, 292, 172);
    canvas.drawPath(
      boot,
      Paint()
        ..shader = const LinearGradient(
          colors: [_blackDark, _blackMid, _blackLight, _blackMid, _blackDark],
          stops: [0.0, 0.2, 0.42, 0.78, 1.0],
        ).createShader(bootBox),
    );
    canvas.drawPath(
      boot,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, f.len(2.5))
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withValues(alpha: 0.9),
    );

    // Ribs
    for (final double ry in const [108, 126, 144, 162]) {
      final double half = 18 + (ry - 90) * (24 / 82);
      canvas.drawLine(
        f.p(250 - half, ry),
        f.p(250 + half, ry),
        Paint()
          ..color = const Color(0x66000000)
          ..strokeWidth = math.max(0.5, f.len(3)),
      );
      canvas.drawLine(
        f.p(250 - half + 1, ry + 3.5),
        f.p(250 + half - 1, ry + 3.5),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.16)
          ..strokeWidth = math.max(0.4, f.len(1.8)),
      );
    }

    // Cable (to the top edge)
    _cylinder(
      canvas,
      f.rect(232, 0, 268, 96),
      const [_blackDark, _blackMid, _blackLight, _blackMid, _blackDark],
      const [0.0, 0.22, 0.45, 0.78, 1.0],
      radius: f.len(2),
    );
  }

  @override
  bool shouldRepaint(covariant DetailedMoistureSensorPainter old) =>
      old.isOn != isOn || old.showJoints != showJoints;
}

/// Maps reference-layout coordinates (500 x 900) to canvas coordinates.
class _Frame {
  final double s; // scale
  final double cx; // canvas centre x
  final double oy; // vertical offset

  const _Frame(this.s, this.cx, this.oy);

  double x(double px) => cx + (px - 250) * s;
  double y(double py) => oy + py * s;
  Offset p(double px, double py) => Offset(x(px), y(py));
  Rect rect(double l, double t, double r, double b) =>
      Rect.fromLTRB(x(l), y(t), x(r), y(b));
  double len(double v) => v * s;
}

/// Widget wrapper for [DetailedMoistureSensorPainter].
///
/// The sensor is 5:9 (width:height), so the default size is 100 x 180.
class MoistureSensorView extends StatelessWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  const MoistureSensorView({
    super.key,
    required this.isOn,
    this.size = const Size(100, 180),
    this.showJoints = true,
  });

  /// Top port location (cable entry)
  static Offset topPort(Size s) => DetailedMoistureSensorPainter.topPort(s);

  /// Bottom port location (probe tips)
  static Offset bottomPort(Size s) => DetailedMoistureSensorPainter.bottomPort(s);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: DetailedMoistureSensorPainter(
        isOn: isOn,
        showJoints: showJoints,
      ),
    );
  }
}