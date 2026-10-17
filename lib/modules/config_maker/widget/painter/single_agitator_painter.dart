import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Photo-matched Single Agitator Assembly Painter & View Widget.
///
/// Features a clean single vertical agitator design with no side pipes and a compact stainless shaft sleeve:
///  * Blue vertical electric motor with cooling fins, left terminal box, lugged head,
///    and stainless top plug.
///  * Blue flange collar, stainless coupling housing with side inspection slot.
///  * Compact stainless shaft sleeve extending straight into the bottom outlet assembly.
///  * ONE single bottom outlet assembly: stainless ferrule rings, blue clamp rings,
///    and stainless neck with bottom flange.
///
/// Geometry is authored on a 360 x 590 reference grid (Aspect ratio: ~0.610).
class DetailedSingleAgitatorPainter extends CustomPainter {
  final bool isOn;
  final double phase;
  final bool showJoints;

  DetailedSingleAgitatorPainter({
    required this.isOn,
    this.phase = 0,
    this.showJoints = true,
  });

  // Reference canvas dimensions
  static const double refWidth = 360.0;
  static const double refHeight = 590.0;
  static const double aspectRatio = refWidth / refHeight;

  // Ports in design coordinates (scaled to canvas size)
  static Offset inletPort(Size s) => Offset(s.width * 0.5, s.height * (66 / refHeight));
  static Offset outletPort(Size s) => Offset(s.width * 0.5, s.height * (566 / refHeight));

  // ---------------------------------------------------------------- Palette
  static const Color _edge = Color(0xFF1E252B);

  // Brushed stainless steel (dark edge -> lit -> highlight -> shade -> reflection)
  static const Color _ss0 = Color(0xFF4A5359);
  static const Color _ss1 = Color(0xFF7D878E);
  static const Color _ss2 = Color(0xFFA8B1B7);
  static const Color _ss3 = Color(0xFFD6DCE0);
  static const Color _ss4 = Color(0xFFF6F8F9);

  // Electric-blue enamel
  static const Color _b0 = Color(0xFF071A52);
  static const Color _b1 = Color(0xFF123A9E);
  static const Color _b2 = Color(0xFF2A62D6);
  static const Color _b3 = Color(0xFF5B92F3);
  static const Color _b4 = Color(0xFFB6D0FF);

  static const List<Color> _steelColors = [_ss0, _ss2, _ss4, _ss3, _ss1, _ss2, _ss0];
  static const List<double> _steelStops = [0.0, 0.10, 0.30, 0.48, 0.74, 0.88, 1.0];

  static const List<Color> _blueColors = [_b0, _b1, _b3, _b2, _b1, _b0];
  static const List<double> _blueStops = [0.0, 0.12, 0.34, 0.55, 0.82, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    final _Sc s = _Sc(size.width / refWidth, size.height / refHeight);

    _drawGroundShadow(canvas, s);

    // Top: motor, housing and compact shaft sleeve
    _drawMotorDriveAssembly(canvas, s);

    // Single bottom outlet assembly directly under motor
    _drawBottomAssembly(canvas, s, 180.0);

    if (isOn) {
      _drawActiveAgitationEffects(canvas, s);
    }
  }

  // -------------------------------------------------------------- Helpers

  Paint _grad(Rect r, List<Color> colors, List<double>? stops, {required bool vertical}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(
      colors: colors,
      stops: stops,
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
    ).createShader(r);

  Paint _fillH(Rect r, List<Color> colors, {List<double>? stops}) =>
      _grad(r, colors, stops, vertical: false);

  Paint _stroke(Color c, double w) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  /// Steel shaded across X (vertical cylinders).
  Paint _steelH(Rect r) => _grad(r, _steelColors, _steelStops, vertical: false);

  Paint _blueH(Rect r) => _grad(r, _blueColors, _blueStops, vertical: false);

  void _softShadow(Canvas canvas, _Sc s, Rect r,
      {double dx = 4, double dy = 6, double blur = 5, double alpha = 0.18, double radius = 4}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.shift(Offset(dx * s.u, dy * s.u)), Radius.circular(radius * s.u)),
      Paint()
        ..color = Colors.black.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur * s.u),
    );
  }

  /// Fine vertical brushed-metal streaks.
  void _brushV(Canvas canvas, _Sc s, double l, double t, double r, double b) {
    int i = 0;
    for (double x = l + 1.2; x < r - 1.0; x += 1.7, i++) {
      final double k = ((i * 37) % 11) / 11.0;
      final Color c = (i.isEven ? Colors.white : Colors.black).withValues(alpha: 0.03 + 0.07 * k);
      canvas.drawLine(s.o(x, t), s.o(x, b), _stroke(c, s.u * 0.8));
    }
  }

  void _bolt(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFD4DADF));
    canvas.drawCircle(c, r, _stroke(Colors.black.withValues(alpha: 0.6), 0.8));
    canvas.drawCircle(
        c.translate(-r * 0.35, -r * 0.35), r * 0.35, Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  // -------------------------------------------------------------- Shadows

  void _drawGroundShadow(Canvas canvas, _Sc s) {
    final Path shadowPath = Path();
    shadowPath.addOval(s.rect(135, 572, 225, 588));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.u * 6),
    );
  }

  // -------------------------------------------------------------- Rings

  void _blueRing(Canvas canvas, _Sc s, double cx, double top, double bottom, double half,
      {int grooves = 0, double radius = 3.5}) {
    final Rect r = s.rect(cx - half, top, cx + half, bottom);
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(s.u * radius));
    canvas.drawRRect(rr, _blueH(r));

    // Upper highlight, lower shade
    canvas.drawLine(s.o(cx - half + 4, top + 2.2), s.o(cx + half - 4, top + 2.2),
        _stroke(_b4.withValues(alpha: 0.55), s.u * 1.5));
    canvas.drawLine(s.o(cx - half + 4, bottom - 2.0), s.o(cx + half - 4, bottom - 2.0),
        _stroke(Colors.black.withValues(alpha: 0.35), s.u * 1.6));

    for (int g = 1; g <= grooves; g++) {
      final double y = top + (bottom - top) * g / (grooves + 1);
      canvas.drawLine(s.o(cx - half + 2, y), s.o(cx + half - 2, y),
          _stroke(Colors.black.withValues(alpha: 0.45), s.u * 1.2));
      canvas.drawLine(s.o(cx - half + 2, y + 1.3), s.o(cx + half - 2, y + 1.3),
          _stroke(_b4.withValues(alpha: 0.30), s.u * 0.9));
    }

    canvas.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.55), 1.0));
  }

  void _steelRing(Canvas canvas, _Sc s, double cx, double top, double bottom, double half,
      {bool ridges = false}) {
    final Rect r = s.rect(cx - half, top, cx + half, bottom);
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(s.u * 3));
    canvas.drawRRect(rr, _steelH(r));

    if (ridges) {
      for (double y = top + 2.2; y < bottom - 1; y += 2.6) {
        canvas.drawLine(s.o(cx - half + 1.5, y), s.o(cx + half - 1.5, y),
            _stroke(Colors.black.withValues(alpha: 0.22), s.u * 0.9));
        canvas.drawLine(s.o(cx - half + 1.5, y + 1.1), s.o(cx + half - 1.5, y + 1.1),
            _stroke(Colors.white.withValues(alpha: 0.30), s.u * 0.7));
      }
    }

    canvas.drawLine(s.o(cx - half + 3, top + 1.8), s.o(cx + half - 3, top + 1.8),
        _stroke(Colors.white.withValues(alpha: 0.45), s.u * 1.2));
    canvas.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.5), 1.0));
  }

  void _drawBottomAssembly(Canvas canvas, _Sc s, double cx) {
    // Lower stainless neck
    final Rect neck = s.rect(cx - 25, 510, cx + 25, 566);
    canvas.drawRect(neck, _steelH(neck));
    _brushV(canvas, s, cx - 24, 510, cx + 24, 566);
    canvas.drawRect(neck, _stroke(_edge.withValues(alpha: 0.4), 1.0));

    // Bottom flange
    _steelRing(canvas, s, cx, 558, 572, 33);
    if (showJoints) {
      _bolt(canvas, s.o(cx - 22, 565), s.u * 2.4);
      _bolt(canvas, s.o(cx + 22, 565), s.u * 2.4);
      _bolt(canvas, s.o(cx, 565), s.u * 2.4);
    }

    // Blue clamp rings
    _blueRing(canvas, s, cx, 493, 512, 42, grooves: 1);
    _blueRing(canvas, s, cx, 463, 493, 42, grooves: 2);

    // Socket pin hole on main ring
    final Offset hole = s.o(cx - 17, 478);
    canvas.drawCircle(
      hole,
      s.u * 4.6,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFF020817), Color(0xFF0B1F57), _b3],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(Rect.fromCircle(center: hole, radius: s.u * 4.6)),
    );
    canvas.drawCircle(hole, s.u * 4.6, _stroke(_edge.withValues(alpha: 0.7), 0.9));
    canvas.drawCircle(hole.translate(-s.u * 1.2, -s.u * 1.2), s.u * 1.0,
        Paint()..color = Colors.white.withValues(alpha: 0.25));

    // Upper blue ring (narrower) + stainless ferrule
    _blueRing(canvas, s, cx, 451, 463, 30, radius: 3);
    _steelRing(canvas, s, cx, 437, 451, 33);
    _steelRing(canvas, s, cx, 425, 437, 31, ridges: true);
  }

  // -------------------------------------------------------------- Motor Assembly

  void _drawMotorDriveAssembly(Canvas canvas, _Sc s) {
    const double cx = 180.0;

    // --- Terminal box (behind motor, left side) ------------------------------
    final Rect box = s.rect(87, 157, 137, 250);
    final RRect boxR = RRect.fromRectAndRadius(box, Radius.circular(s.u * 8));
    _softShadow(canvas, s, box, dx: 3, dy: 6, blur: 5, alpha: 0.22, radius: 8);
    canvas.drawRRect(boxR, _blueH(box));

    final Rect panel = s.rect(92, 164, 129, 243);
    final RRect panelR = RRect.fromRectAndRadius(panel, Radius.circular(s.u * 5));
    canvas.drawRRect(panelR, _fillH(panel, const [_b1, _b2, _b3, _b2, _b1], stops: const [0, 0.25, 0.5, 0.78, 1]));
    canvas.drawRRect(panelR, _stroke(_b4.withValues(alpha: 0.45), 1.0));
    canvas.drawRRect(panelR.shift(Offset(s.u * 0.8, s.u * 0.8)), _stroke(Colors.black.withValues(alpha: 0.25), 1.0));

    // Latch tab
    final Rect latch = s.rect(88, 226, 111, 250);
    final RRect latchR = RRect.fromRectAndRadius(latch, Radius.circular(s.u * 4));
    canvas.drawRRect(latchR, _fillH(latch, const [_b1, _b3, _b2]));
    canvas.drawRRect(latchR, _stroke(_edge.withValues(alpha: 0.6), 1.0));
    canvas.drawLine(s.o(91, 231), s.o(108, 231), _stroke(_b4.withValues(alpha: 0.5), s.u * 1.3));
    canvas.drawRRect(boxR, _stroke(_edge.withValues(alpha: 0.6), 1.2));

    // --- Motor body with cooling fins ----------------------------------------
    final Rect motorRect = s.rect(cx - 49, 132, cx + 49, 271);
    final RRect motorR = RRect.fromRectAndRadius(motorRect, Radius.circular(s.u * 4));
    _softShadow(canvas, s, motorRect, dx: 5, dy: 6, blur: 6, alpha: 0.22, radius: 4);
    canvas.drawRRect(motorR, Paint()..color = _b0);

    for (int i = 0; i < 8; i++) {
      final double fx = cx - 40 + i * 11.4;
      final Rect fin = s.rect(fx - 3.8, 134, fx + 3.8, 269);
      canvas.drawRRect(
        RRect.fromRectAndRadius(fin, Radius.circular(s.u * 2)),
        _fillH(fin, const [_b1, _b3, _b2, _b1], stops: const [0.0, 0.30, 0.65, 1.0]),
      );
      canvas.drawLine(s.o(fx - 1.7, 138), s.o(fx - 1.7, 265),
          _stroke(_b4.withValues(alpha: 0.40), s.u * 1.0));
    }

    // Cylinder shading over fins
    canvas.drawRRect(
      motorR,
      _fillH(
        motorRect,
        const [Color(0x66000000), Color(0x00000000), Color(0x26FFFFFF), Color(0x00000000), Color(0x88000000)],
        stops: const [0.0, 0.16, 0.34, 0.55, 1.0],
      ),
    );

    // Shadow under head
    final Rect headShadow = s.rect(cx - 49, 132, cx + 49, 146);
    canvas.drawRect(
      headShadow,
      _grad(headShadow, [Colors.black.withValues(alpha: 0.45), Colors.black.withValues(alpha: 0.0)], null, vertical: true),
    );
    canvas.drawRRect(motorR, _stroke(_edge.withValues(alpha: 0.6), 1.2));

    // --- Motor head with lugs -------------------------------------------------
    final Rect head = s.rect(cx - 59, 84, cx + 59, 133);
    final RRect headR = RRect.fromRectAndRadius(head, Radius.circular(s.u * 9));
    _softShadow(canvas, s, head, dx: 4, dy: 5, blur: 5, alpha: 0.20, radius: 9);
    canvas.drawRRect(headR, _blueH(head));

    // Recessed centre
    final Rect recess = s.rect(cx - 31, 90, cx + 31, 133);
    canvas.drawRect(
      recess,
      _grad(recess, const [_b0, _b1, _b0], const [0.0, 0.55, 1.0], vertical: true),
    );

    // Lugs
    final Rect lugL = s.rect(cx - 59, 82, cx - 30, 133);
    final Rect lugR = s.rect(cx + 30, 82, cx + 59, 133);
    final RRect lugLR = RRect.fromRectAndRadius(lugL, Radius.circular(s.u * 8));
    final RRect lugRR = RRect.fromRectAndRadius(lugR, Radius.circular(s.u * 8));
    canvas.drawRRect(lugLR, _fillH(lugL, const [_b1, _b3, _b2, _b1], stops: const [0.0, 0.35, 0.70, 1.0]));
    canvas.drawRRect(lugRR, _fillH(lugR, const [_b2, _b3, _b2, _b0], stops: const [0.0, 0.30, 0.65, 1.0]));
    for (final Rect lr in [lugL, lugR]) {
      canvas.drawLine(s.o(lr.left / s.sx + 6, 87), s.o(lr.right / s.sx - 6, 87),
          _stroke(_b4.withValues(alpha: 0.65), s.u * 1.6));
      canvas.drawLine(s.o(lr.left / s.sx + 5, 129), s.o(lr.right / s.sx - 5, 129),
          _stroke(Colors.black.withValues(alpha: 0.35), s.u * 1.4));
    }
    if (showJoints) {
      _bolt(canvas, s.o(cx - 44, 108), s.u * 3.0);
      _bolt(canvas, s.o(cx + 44, 108), s.u * 3.0);
    }
    canvas.drawRRect(lugLR, _stroke(_edge.withValues(alpha: 0.6), 1.0));
    canvas.drawRRect(lugRR, _stroke(_edge.withValues(alpha: 0.6), 1.0));
    canvas.drawRRect(headR, _stroke(_edge.withValues(alpha: 0.55), 1.0));

    // --- Stainless top plug ---------------------------------------------------
    final Path plug = Path()
      ..moveTo(s.x(cx - 30), s.y(66))
      ..lineTo(s.x(cx + 30), s.y(66))
      ..lineTo(s.x(cx + 37), s.y(83))
      ..lineTo(s.x(cx - 37), s.y(83))
      ..close();
    final Rect plugRect = s.rect(cx - 37, 66, cx + 37, 83);
    canvas.drawPath(plug, _steelH(plugRect));
    final Rect plugTop = s.rect(cx - 30, 63.5, cx + 30, 69.5);
    canvas.drawOval(plugTop, _steelH(plugTop));
    canvas.drawOval(plugTop, _stroke(_edge.withValues(alpha: 0.5), 0.9));
    canvas.drawLine(s.o(cx - 28, 74), s.o(cx + 28, 74), _stroke(Colors.white.withValues(alpha: 0.35), s.u * 1.2));
    canvas.drawPath(plug, _stroke(_edge.withValues(alpha: 0.55), 1.0));

    // --- Blue flange collar below motor ---------------------------------------
    _softShadow(canvas, s, s.rect(cx - 62, 270, cx + 62, 291), dx: 3, dy: 5, blur: 4, alpha: 0.2, radius: 3);
    _blueRing(canvas, s, cx, 270, 291, 62, radius: 3);

    // --- Stainless coupling housing --------------------------------------------
    final Rect housing = s.rect(cx - 58, 291, cx + 58, 365);
    final RRect housingR = RRect.fromRectAndRadius(housing, Radius.circular(s.u * 6));
    _softShadow(canvas, s, housing, dx: 4, dy: 6, blur: 5, alpha: 0.22, radius: 6);
    canvas.drawRRect(housingR, _steelH(housing));
    _brushV(canvas, s, cx - 56, 294, cx + 56, 362);

    // Rolled edges top / bottom
    for (final double ey in [297.0, 359.0]) {
      canvas.drawLine(s.o(cx - 56, ey), s.o(cx + 56, ey), _stroke(_ss0.withValues(alpha: 0.35), s.u * 1.2));
      canvas.drawLine(s.o(cx - 56, ey + 1.4), s.o(cx + 56, ey + 1.4), _stroke(Colors.white.withValues(alpha: 0.25), s.u * 1.0));
    }
    canvas.drawRRect(housingR, _stroke(_edge.withValues(alpha: 0.55), 1.2));

    // Side inspection slot
    final Rect slot = s.rect(cx + 46, 299, cx + 54, 351);
    final RRect slotR = RRect.fromRectAndRadius(slot, Radius.circular(s.u * 3.5));
    canvas.drawRRect(slotR, _fillH(slot, const [Color(0xFF05080B), Color(0xFF2A333A), Color(0xFF0A0F13)]));
    final double phaseOffset = isOn ? math.sin(phase * math.pi * 2) * 1.0 : 0.0;
    final Rect innerShaft = s.rect(cx + 49 + phaseOffset, 302, cx + 51.6 + phaseOffset, 348);
    canvas.drawRect(innerShaft, Paint()..color = const Color(0xFFB0B8BC));
    canvas.drawRRect(slotR, _stroke(Colors.black.withValues(alpha: 0.9), 1.0));
    canvas.drawLine(s.o(cx + 55, 303), s.o(cx + 55, 347), _stroke(Colors.white.withValues(alpha: 0.45), s.u * 1.0));

    // --- Compact Single Stainless Shaft Sleeve ----------------------------------
    final Rect shaft = s.rect(cx - 38, 364, cx + 38, 425);
    _softShadow(canvas, s, shaft, dx: 4, dy: 3, blur: 4, alpha: 0.18, radius: 2);
    canvas.drawRect(shaft, _steelH(shaft));
    _brushV(canvas, s, cx - 37, 365, cx + 37, 424);
    canvas.drawRect(shaft, _stroke(_edge.withValues(alpha: 0.45), 1.0));

    // Ambient occlusion under housing
    final Rect shaftAo = s.rect(cx - 38, 365, cx + 38, 380);
    canvas.drawRect(
      shaftAo,
      _grad(shaftAo, [Colors.black.withValues(alpha: 0.45), Colors.black.withValues(alpha: 0.0)], null, vertical: true),
    );
  }

  // -------------------------------------------------------------- Active Effects

  void _drawActiveAgitationEffects(Canvas canvas, _Sc s) {
    const double cx = 180.0;

    // Soft blue glow around electric motor
    final Rect motorGlowRect = s.rect(cx - 66, 78, cx + 66, 280);
    canvas.drawRRect(
      RRect.fromRectAndRadius(motorGlowRect, Radius.circular(s.u * 20)),
      Paint()
        ..color = _b3.withValues(alpha: 0.22 + 0.10 * math.sin(phase * math.pi * 4))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.u * 12),
    );

    // Flow glow at single bottom outlet
    canvas.drawCircle(
      s.o(cx, 566),
      s.u * (7.0 + 2.0 * math.sin(phase * math.pi * 2)),
      Paint()
        ..color = const Color(0xFF64B5F6).withValues(alpha: 0.50)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.u * 5),
    );
  }

  @override
  bool shouldRepaint(covariant DetailedSingleAgitatorPainter oldDelegate) {
    return oldDelegate.isOn != isOn ||
        oldDelegate.phase != phase ||
        oldDelegate.showJoints != showJoints;
  }
}

/// Scaler helper mapping design coordinates (360 x 590) to current canvas size.
class _Sc {
  final double sx;
  final double sy;
  const _Sc(this.sx, this.sy);

  double x(double p) => p * sx;
  double y(double p) => p * sy;
  double get u => math.min(sx, sy);
  Offset o(double px, double py) => Offset(px * sx, py * sy);
  Rect rect(double l, double t, double r, double b) =>
      Rect.fromLTRB(l * sx, t * sy, r * sx, b * sy);
}

/// Stateful Widget Wrapper for Single Agitator Assembly.
class SingleAgitatorView extends StatefulWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  const SingleAgitatorView({
    super.key,
    required this.isOn,
    required this.showJoints,
    required this.size,
  });

  @override
  State<SingleAgitatorView> createState() => _SingleAgitatorViewState();
}

class _SingleAgitatorViewState extends State<SingleAgitatorView> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.size,
      painter: DetailedSingleAgitatorPainter(
        isOn: widget.isOn,
        phase: 0.0,
        showJoints: widget.showJoints,
      ),
    );
  }
}
