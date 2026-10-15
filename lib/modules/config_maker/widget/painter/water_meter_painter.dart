import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Modern water meter painter (vertical or horizontal, in-line, flanged) - no digital screen.
///
/// Visual features:
/// - Blue painted cast-iron body with cylindrical shading and flow arrow
/// - Steel flanges with bolt heads at the inlet and outlet
/// - Dark register head with spec print and a steel nameplate
/// - Two push buttons, status LED and optical port
///
/// [isOn]        true  -> status LED green
///               false -> status LED grey
/// [showJoints]  draws the bolted flanges; false shows plain pipe stubs
/// [orientation] Axis.vertical or Axis.horizontal
///
/// Live values are meant to be drawn by your own widget on top of the meter.
class DetailedWaterMeterPainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;
  final Axis orientation;

  DetailedWaterMeterPainter({
    required this.isOn,
    this.showJoints = true,
    this.orientation = Axis.vertical,
  });

  // Reference layout: 600 x 900 design units, centred on x = 300.
  static const double _refW = 600.0;
  static const double _refH = 900.0;

  // Palette
  static const Color _edge = Color(0xFF14181B);

  static const Color _blueDark = Color(0xFF0C3568);
  static const Color _blueMid = Color(0xFF2B73BD);
  static const Color _blueLight = Color(0xFF86BCEC);

  static const Color _steelDark = Color(0xFF454F59);
  static const Color _steelMid = Color(0xFF9AA5AE);
  static const Color _steelLight = Color(0xFFDCE1E4);

  static Offset topPort(Size s) => Offset(s.width * 0.5, 0);
  static Offset bottomPort(Size s) => Offset(s.width * 0.5, s.height);
  static Offset leftPort(Size s) => Offset(0, s.height * 0.5);
  static Offset rightPort(Size s) => Offset(s.width, s.height * 0.5);

  static Offset inletPort(Size s, {Axis orientation = Axis.vertical}) =>
      orientation == Axis.vertical ? topPort(s) : leftPort(s);

  static Offset outletPort(Size s, {Axis orientation = Axis.vertical}) =>
      orientation == Axis.vertical ? bottomPort(s) : rightPort(s);

  @override
  void paint(Canvas canvas, Size size) {
    final bool isHorizontal = orientation == Axis.horizontal;
    final double refWidth = isHorizontal ? _refH : _refW;
    final double refHeight = isHorizontal ? _refW : _refH;

    final double s = math.min(size.width / refWidth, size.height / refHeight);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    if (isHorizontal) {
      canvas.rotate(-math.pi / 2);
    }
    canvas.translate(-_refW * s / 2, -_refH * s / 2);

    final _Frame f = _Frame(s, 300 * s, 0);

    _drawShadow(canvas, f);
    _drawPipes(canvas, f);
    _drawBody(canvas, f);
    if (showJoints) {
      _drawFlange(canvas, f, 0, 62);
      _drawFlange(canvas, f, 838, 900);
    }
    _drawHead(canvas, f);
    _drawNameplate(canvas, f);
    _drawControls(canvas, f);

    canvas.restore();
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

  void _hexBolt(Canvas canvas, Offset c, double r) {
    final Path hex = Path();
    for (int i = 0; i < 6; i++) {
      final double a = math.pi / 6 + i * math.pi / 3;
      final Offset p = c + Offset(math.cos(a), math.sin(a)) * r;
      if (i == 0) {
        hex.moveTo(p.dx, p.dy);
      } else {
        hex.lineTo(p.dx, p.dy);
      }
    }
    hex.close();

    canvas.drawPath(
      hex,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFF2F3F4), Color(0xFF9A9EA2), Color(0xFF4F5357)],
          stops: [0.0, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, r * 0.12)
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF2B2F33),
    );
  }

  void _screw(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFD8DADC), Color(0xFF8A8E92), Color(0xFF45494D)],
          stops: [0.0, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.4, r * 0.12)
        ..color = const Color(0xFF1E2124),
    );
    canvas.drawLine(
      c + Offset(-r * 0.6, 0),
      c + Offset(r * 0.6, 0),
      Paint()
        ..color = const Color(0xFF1E2124)
        ..strokeWidth = math.max(0.4, r * 0.18),
    );
  }

  // ---------------------------------------------------------------------------
  // Body and fittings
  // ---------------------------------------------------------------------------

  void _drawShadow(Canvas canvas, _Frame f) {
    final Paint shadow = Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.5, f.len(16)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        f.rect(165, 135, 435, 765).shift(Offset(f.len(14), f.len(18))),
        Radius.circular(f.len(70)),
      ),
      shadow,
    );
  }

  void _drawPipes(Canvas canvas, _Frame f) {
    const List<Color> cols = [
      _steelDark,
      _steelMid,
      _steelLight,
      _steelMid,
      _steelDark,
    ];
    const List<double> stops = [0.0, 0.2, 0.45, 0.78, 1.0];

    // Plain pipe stubs to the very edge (visible when flanges are hidden)
    _cylinder(canvas, f.rect(235, 0, 365, 160), cols, stops, radius: 2);
    _cylinder(canvas, f.rect(235, 740, 365, 900), cols, stops, radius: 2);
  }

  void _drawBody(Canvas canvas, _Frame f) {
    const List<Color> cols = [
      _blueDark,
      _blueMid,
      _blueLight,
      _blueMid,
      _blueDark,
    ];
    const List<double> stops = [0.0, 0.22, 0.45, 0.78, 1.0];

    // Inlet / outlet necks
    _cylinder(canvas, f.rect(210, 62, 390, 170), cols, stops, radius: 4);
    _cylinder(canvas, f.rect(210, 730, 390, 838), cols, stops, radius: 4);

    // Main bulb
    final Rect bulb = f.rect(160, 135, 440, 765);
    _cylinder(canvas, bulb, cols, stops,
        radius: f.len(70), edgeWidth: math.max(0.8, f.len(3)));

    // Casting seam lines
    final Paint seam = Paint()
      ..color = const Color(0x40000000)
      ..strokeWidth = math.max(0.5, f.len(3));
    canvas.drawLine(f.p(212, 150), f.p(388, 150), seam);
    canvas.drawLine(f.p(212, 750), f.p(388, 750), seam);
    canvas.drawLine(
      f.p(212, 153),
      f.p(388, 153),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = math.max(0.4, f.len(2)),
    );

    // Raised flow arrow (pointing down) below the head
    final Path arrow = Path()
      ..moveTo(f.x(300), f.y(735))
      ..lineTo(f.x(332), f.y(698))
      ..lineTo(f.x(312), f.y(698))
      ..lineTo(f.x(312), f.y(668))
      ..lineTo(f.x(288), f.y(668))
      ..lineTo(f.x(288), f.y(698))
      ..lineTo(f.x(268), f.y(698))
      ..close();
    canvas.drawPath(
      arrow.shift(Offset(f.len(2), f.len(2.5))),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawPath(arrow, Paint()..color = _blueLight.withValues(alpha: 0.85));
    canvas.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, f.len(2))
        ..color = _blueDark.withValues(alpha: 0.8),
    );
  }

  void _drawFlange(Canvas canvas, _Frame f, double top, double bottom) {
    final Rect plate = f.rect(115, top, 485, bottom);
    _cylinder(
      canvas,
      plate,
      const [
        _steelDark,
        _steelMid,
        _steelLight,
        _steelMid,
        _steelDark,
      ],
      const [0.0, 0.18, 0.45, 0.8, 1.0],
      radius: f.len(5),
      edgeWidth: math.max(0.8, f.len(3)),
    );

    // Chamfer highlight along the face
    canvas.drawLine(
      f.p(122, top + 6),
      f.p(478, top + 6),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.40)
        ..strokeWidth = math.max(0.5, f.len(3)),
    );

    // Bolt heads
    final double cy = (top + bottom) / 2;
    for (final double bx in const [152, 232, 368, 448]) {
      _hexBolt(canvas, f.p(bx, cy), f.len(13));
    }
  }

  // ---------------------------------------------------------------------------
  // Register head
  // ---------------------------------------------------------------------------

  void _drawHead(Canvas canvas, _Frame f) {
    // Recessed bezel ring in the body
    final Rect bezel = f.rect(172, 245, 428, 652);
    final RRect bezelR = RRect.fromRectAndRadius(bezel, Radius.circular(f.len(40)));
    canvas.drawRRect(bezelR, Paint()..color = const Color(0xFF07254A));
    canvas.drawRRect(
      bezelR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, f.len(4))
        ..color = _blueLight.withValues(alpha: 0.55),
    );

    // Dark composite head
    final Rect head = f.rect(184, 257, 416, 640);
    final RRect headR = RRect.fromRectAndRadius(head, Radius.circular(f.len(32)));
    canvas.drawRRect(
      headR,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF454B52), Color(0xFF24282D), Color(0xFF14171A)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(head),
    );
    canvas.drawRRect(
      headR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, f.len(3))
        ..color = Colors.black.withValues(alpha: 0.8),
    );
    // Top-left edge highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        f.rect(188, 261, 412, 636),
        Radius.circular(f.len(28)),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, f.len(2))
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    // Corner screws
    final double sr = f.len(8);
    _screw(canvas, f.p(210, 283), sr);
    _screw(canvas, f.p(390, 283), sr);
    _screw(canvas, f.p(210, 614), sr);
    _screw(canvas, f.p(390, 614), sr);

    // Printed brand + spec
    _text(canvas, 'DN50  PN16', f.p(300, 368), f.len(14),
        const Color(0xFF9AA3AB), weight: FontWeight.w500, letterSpacing: f.len(1.5));

    // Thin divider
    canvas.drawLine(
      f.p(228, 392),
      f.p(372, 392),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = math.max(0.5, f.len(2)),
    );
  }

  void _drawNameplate(Canvas canvas, _Frame f) {
    final Rect plate = f.rect(226, 410, 374, 486);
    final RRect rr = RRect.fromRectAndRadius(plate, Radius.circular(f.len(6)));

    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9ECEE), Color(0xFFB4BBC1), Color(0xFF8F979E)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(plate),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, f.len(2.5))
        ..color = const Color(0xFF3A3F44),
    );

    _text(canvas, 'Q3 40  R400', f.p(300, 432), f.len(16),
        const Color(0xFF2A2F34), weight: FontWeight.w700, letterSpacing: f.len(1));
    _text(canvas, 'IP68  0-50\u00B0C', f.p(300, 458), f.len(14),
        const Color(0xFF3A4046), weight: FontWeight.w500, letterSpacing: f.len(0.8));

    // Rivets
    _screw(canvas, f.p(236, 420), f.len(4));
    _screw(canvas, f.p(364, 420), f.len(4));
    _screw(canvas, f.p(236, 476), f.len(4));
    _screw(canvas, f.p(364, 476), f.len(4));
  }

  void _drawControls(Canvas canvas, _Frame f) {
    // Two push buttons
    for (final double bx in const [250, 350]) {
      final Offset c = f.p(bx, 538);
      final double r = f.len(17);
      canvas.drawCircle(c + Offset(f.len(1.5), f.len(2.5)), r,
          Paint()..color = const Color(0x66000000));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.35, -0.35),
            colors: [Color(0xFF8A9198), Color(0xFF4A5057), Color(0xFF23272B)],
            stops: [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, f.len(2.5))
          ..color = Colors.black.withValues(alpha: 0.85),
      );
    }

    // Status LED between the buttons
    final Offset led = f.p(300, 538);
    final double lr = f.len(9);
    if (isOn) {
      canvas.drawCircle(
        led,
        lr * 1.9,
        Paint()
          ..color = const Color(0xFF00E676).withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.0, f.len(7))),
      );
    }
    canvas.drawCircle(
      led,
      lr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: isOn
              ? const [Color(0xFFB9FFD6), Color(0xFF00C853)]
              : const [Color(0xFF8A8A8A), Color(0xFF4A4A4A)],
        ).createShader(Rect.fromCircle(center: led, radius: lr)),
    );
    canvas.drawCircle(
      led,
      lr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, f.len(2))
        ..color = Colors.black,
    );

    // Optical (IR) port
    final Offset ir = f.p(300, 592);
    canvas.drawCircle(ir, f.len(15), Paint()..color = const Color(0xFF0A0B0C));
    canvas.drawCircle(
      ir,
      f.len(15),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, f.len(3))
        ..color = const Color(0xFF7A828A),
    );
    canvas.drawCircle(
      ir,
      f.len(7),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFF5B1B1B), Color(0xFF1A0707)],
        ).createShader(Rect.fromCircle(center: ir, radius: f.len(7))),
    );
  }

  @override
  bool shouldRepaint(covariant DetailedWaterMeterPainter old) =>
      old.isOn != isOn ||
      old.showJoints != showJoints ||
      old.orientation != orientation;
}

/// Maps reference-layout coordinates (600 x 900) to canvas coordinates.
class _Frame {
  final double s; // scale
  final double cx; // canvas centre x
  final double oy; // vertical offset

  const _Frame(this.s, this.cx, this.oy);

  double x(double px) => cx + (px - 300) * s;
  double y(double py) => oy + py * s;
  Offset p(double px, double py) => Offset(x(px), y(py));
  Rect rect(double l, double t, double r, double b) =>
      Rect.fromLTRB(x(l), y(t), x(r), y(b));
  double len(double v) => v * s;
}

/// Widget wrapper for [DetailedWaterMeterPainter].
///
/// Default size for vertical is 120 x 180 (2:3), and for horizontal is 180 x 120 (3:2).
class WaterMeterView extends StatelessWidget {
  final bool isOn;
  final bool showJoints;
  final Axis orientation;
  final Size? size;

  const WaterMeterView({
    super.key,
    required this.isOn,
    this.orientation = Axis.vertical,
    this.size,
    this.showJoints = true,
  });

  /// Top inlet port location
  static Offset topPort(Size s) => DetailedWaterMeterPainter.topPort(s);

  /// Bottom outlet port location
  static Offset bottomPort(Size s) => DetailedWaterMeterPainter.bottomPort(s);

  /// Left inlet port location
  static Offset leftPort(Size s) => DetailedWaterMeterPainter.leftPort(s);

  /// Right outlet port location
  static Offset rightPort(Size s) => DetailedWaterMeterPainter.rightPort(s);

  /// Inlet port location based on orientation
  static Offset inletPort(Size s, {Axis orientation = Axis.vertical}) =>
      DetailedWaterMeterPainter.inletPort(s, orientation: orientation);

  /// Outlet port location based on orientation
  static Offset outletPort(Size s, {Axis orientation = Axis.vertical}) =>
      DetailedWaterMeterPainter.outletPort(s, orientation: orientation);

  @override
  Widget build(BuildContext context) {
    final Size effectiveSize = size ??
        (orientation == Axis.horizontal
            ? const Size(180, 120)
            : const Size(120, 180));

    return CustomPaint(
      size: effectiveSize,
      painter: DetailedWaterMeterPainter(
        isOn: isOn,
        showJoints: showJoints,
        orientation: orientation,
      ),
    );
  }
}