import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Photo-matched Fertigation Dosing Tank painter.
///
/// Reproduces a brushed-stainless cylindrical mixing vessel: domed lid with a
/// flanged top nozzle, a large rounded viewing window showing green solution,
/// a centre agitator shaft with a 2-blade propeller, graduation ticks, a
/// side sight-glass gauge with metal end caps, a bottom collar and conical
/// hopper, a blue globe valve + flanged fertilizer inlet pipe on the left, a
/// blue globe valve + flanged agitator inlet pipe on top, a blue flanged
/// outlet pipe with stainless ball valve (blue lever) at the bottom, and a
/// rusty steel A-frame stand.
///
/// Geometry is authored on a 944 x 1132 reference grid (the photo's size).
/// Use a size with that aspect ratio (about 0.834), e.g. Size(300, 360).
///
/// [isOn]       – dosing active: propeller spins, liquid ripples, bubbles and
///                swirl currents appear, soft green halo around the vessel.
/// [phase]      – 0..1 looping animation driver.
/// [showJoints] – draw flange bolts and clamp details.

class DetailedFertilizerTankPainter extends CustomPainter {
  final bool isOn;
  final double phase;
  final bool showJoints;

  DetailedFertilizerTankPainter({
    required this.isOn,
    this.phase = 0,
    this.showJoints = true,
  });

  // ---------------------------------------------------------------- palette
  static const Color _edge = Color(0xFF1E272C);

  // Brushed stainless
  static const Color _ssDark = Color(0xFF80878A);
  static const Color _ssMid = Color(0xFFB9BEC0);
  static const Color _ssLight = Color(0xFFE2E5E6);

  // Blue painted pipework
  static const Color _blueLight = Color(0xFF6482C8);
  static const Color _blueMid = Color(0xFF3A57A0);
  static const Color _blueDark = Color(0xFF243B7C);

  // Solution
  static const Color _liqSurface = Color(0xFF80C878);
  static const Color _liqTop = Color(0xFF4F9F4B);
  static const Color _liqMid = Color(0xFF3D8B3F);
  static const Color _liqDeep = Color(0xFF2E7434);
  static const Color _chemGlow = Color(0xFF66E070);

  // Rusty frame
  static const Color _rust = Color(0xFF9B5A38);

  @override
  void paint(Canvas canvas, Size size) {
    final _Sc s = _Sc(size.width / 944, size.height / 1132);

    _drawGroundShadow(canvas, s);
    _drawInletAssembly(canvas, s); // left: fertilizer inlet
    if (isOn) _drawActiveGlow(canvas, s);
    _drawCone(canvas, s);
    _drawStand(canvas, s);
    _drawOutletAssembly(canvas, s); // bottom
    _drawBody(canvas, s);
    _drawCollar(canvas, s);
    _drawWindow(canvas, s);
    _drawSightGlass(canvas, s);
    _drawDomeAndNozzle(canvas, s);
    _drawAgitatorInletAssembly(canvas, s); // top: agitator inlet
  }

  // -------------------------------------------------------------- helpers

  Paint _fillH(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(colors: colors, stops: stops, begin: Alignment.centerLeft, end: Alignment.centerRight)
        .createShader(r);

  Paint _fillV(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(colors: colors, stops: stops, begin: Alignment.topCenter, end: Alignment.bottomCenter)
        .createShader(r);

  Paint _stroke(Color c, double w) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  Paint _steelH(Rect r) => _fillH(r, const [_ssDark, _ssLight, _ssMid, _ssDark], stops: const [0, 0.3, 0.65, 1]);
  Paint _steelV(Rect r) => _fillV(r, const [_ssLight, _ssMid, _ssDark], stops: const [0, 0.5, 1]);
  Paint _blueH(Rect r) => _fillH(r, const [_blueDark, _blueLight, _blueMid, _blueDark], stops: const [0, 0.3, 0.65, 1]);
  Paint _blueV(Rect r) => _fillV(r, const [_blueLight, _blueMid, _blueDark], stops: const [0, 0.45, 1]);

  void _speckle(Canvas canvas, Rect area, int seed, int n, Color c, double u) {
    final math.Random rnd = math.Random(seed);
    for (int i = 0; i < n; i++) {
      final double x = area.left + rnd.nextDouble() * area.width;
      final double y = area.top + rnd.nextDouble() * area.height;
      final double r = (1.5 + rnd.nextDouble() * 5) * u;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: r * 1.7, height: r),
        Paint()..color = c.withValues(alpha: 0.15 + 0.3 * rnd.nextDouble()),
      );
    }
  }

  void _bolt(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFC8CDCF));
    canvas.drawCircle(c, r, _stroke(Colors.black.withValues(alpha: 0.5), 0.8));
    canvas.drawCircle(c.translate(-r * 0.3, -r * 0.3), r * 0.35, Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  void _flange(Canvas canvas, _Sc s, double l, double t, double r, double b,
      {bool blue = true, bool horizontal = false}) {
    final Rect rect = s.rect(l, t, r, b);
    final double rad = math.min(s.u * 10, math.min(rect.width, rect.height) / 2);
    final RRect rr = RRect.fromRectAndRadius(rect, Radius.circular(rad));
    canvas.drawRRect(rr.shift(Offset(s.x(2), s.y(3))), Paint()..color = Colors.black.withValues(alpha: 0.18));
    canvas.drawRRect(rr, blue ? _blueH(rect) : _steelH(rect));
    canvas.drawRRect(rr, _stroke(Colors.black.withValues(alpha: 0.55), 1.1));
    if (showJoints) {
      for (final double f in [0.10, 0.28, 0.72, 0.90]) {
        final Offset c = horizontal
            ? Offset(rect.left + rect.width * f, rect.center.dy)
            : Offset(rect.center.dx, rect.top + rect.height * f);
        _bolt(canvas, c, s.u * (horizontal ? 3.4 : 4.2));
      }
    }
  }

  void _beam(Canvas canvas, _Sc s, List<Offset> pts, int seed) {
    final Path p = Path()..addPolygon(pts, true);
    final Rect b = p.getBounds();
    canvas.drawPath(p.shift(Offset(s.x(3), s.y(5))), Paint()..color = Colors.black.withValues(alpha: 0.16));
    canvas.drawPath(
      p,
      _fillH(b, const [Color(0xFF6C6862), Color(0xFFA6A198), Color(0xFF78736B)], stops: const [0, 0.4, 1]),
    );
    canvas.save();
    canvas.clipPath(p);
    final int n = ((b.width * b.height) / (s.u * s.u) / 180).clamp(8, 110).toInt();
    _speckle(canvas, b, seed, n, _rust, s.u);
    _speckle(canvas, b, seed + 11, (n / 2).toInt(), const Color(0xFF3C3934), s.u);
    canvas.restore();
    canvas.drawPath(p, _stroke(Colors.black.withValues(alpha: 0.5), 1.2));
    // top edge highlight
    canvas.drawLine(pts[0], pts[1], _stroke(Colors.white.withValues(alpha: 0.25), 1.2));
  }

  // ----------------------------------------------------------- ground shadow

  void _drawGroundShadow(Canvas canvas, _Sc s) {
    canvas.drawOval(
      Rect.fromCenter(center: s.o(500, 992), width: s.x(520), height: s.y(26)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * s.u),
    );
  }

  // ----------------------------------------- left: globe valve + fertilizer inlet

  void _drawInletAssembly(Canvas canvas, _Sc s) {
    // Blue pipe stub (ends hidden behind tank wall)
    final Rect pipe = s.rect(175, 407, 324, 467);
    canvas.drawRect(pipe, _blueV(pipe));
    _speckle(canvas, pipe, 5, 26, const Color(0xFFB7C3E6), s.u);
    _speckle(canvas, pipe, 9, 8, _rust, s.u);
    canvas.drawRect(pipe, _stroke(Colors.black.withValues(alpha: 0.45), 1.0));

    // Flange pair
    _flange(canvas, s, 236, 374, 262, 498);
    _flange(canvas, s, 258, 376, 285, 496);

    // Grey coupling
    final Rect coupling = s.rect(146, 402, 182, 474);
    final RRect rc = RRect.fromRectAndRadius(coupling, Radius.circular(s.u * 8));
    canvas.drawRRect(rc, _steelH(coupling));
    canvas.drawRRect(rc, _stroke(Colors.black.withValues(alpha: 0.55), 1.1));
    for (final double x in [156.0, 166.0, 174.0]) {
      canvas.drawLine(s.o(x, 406), s.o(x, 470), _stroke(Colors.black.withValues(alpha: 0.25), 1.2 * s.u));
    }

    // Yoke / bonnet with slots
    final Rect yoke = s.rect(112, 414, 150, 458);
    canvas.drawRRect(RRect.fromRectAndRadius(yoke, Radius.circular(s.u * 5)), _steelH(yoke));
    canvas.drawRRect(RRect.fromRectAndRadius(yoke, Radius.circular(s.u * 5)), _stroke(Colors.black.withValues(alpha: 0.5), 1.0));
    for (final double x in [122.0, 131.0, 140.0]) {
      canvas.drawLine(s.o(x, 419), s.o(x, 453), _stroke(Colors.black.withValues(alpha: 0.45), 2 * s.u));
    }

    // Stem
    canvas.drawLine(s.o(98, 434), s.o(114, 434), _stroke(_ssMid, 5 * s.u));

    // Hand wheel (seen edge-on in perspective)
    final Offset c = s.o(92, 434);
    final double rx = s.x(19), ry = s.y(57);
    final Rect wheel = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(wheel.shift(Offset(s.x(2), s.y(3))), _stroke(Colors.black.withValues(alpha: 0.18), 8 * s.u));
    canvas.drawOval(wheel, _stroke(_blueMid, 8 * s.u));
    canvas.drawOval(wheel, _stroke(Colors.white.withValues(alpha: 0.25), 2 * s.u));
    canvas.drawOval(wheel.deflate(4 * s.u), _stroke(Colors.black.withValues(alpha: 0.25), 1.2));
    for (final double a in [0.0, math.pi / 4, math.pi / 2, 3 * math.pi / 4]) {
      canvas.drawLine(
        Offset(c.dx - rx * 0.9 * math.cos(a), c.dy - ry * 0.9 * math.sin(a)),
        Offset(c.dx + rx * 0.9 * math.cos(a), c.dy + ry * 0.9 * math.sin(a)),
        _stroke(_blueMid, 4.5 * s.u),
      );
    }
    canvas.drawCircle(c, s.u * 7, Paint()..color = _ssMid);
    canvas.drawCircle(c, s.u * 7, _stroke(Colors.black.withValues(alpha: 0.5), 1));
  }

  // ------------------------------- top: globe valve + agitator inlet pipe

  void _drawAgitatorInletAssembly(Canvas canvas, _Sc s) {
    // Vertical blue pipe
    final Rect pipe = s.rect(474, 32, 526, 202);
    canvas.drawRect(pipe, _blueH(pipe));
    _speckle(canvas, pipe, 5, 26, const Color(0xFFB7C3E6), s.u);
    _speckle(canvas, pipe, 9, 8, _rust, s.u);
    canvas.drawRect(pipe, _stroke(Colors.black.withValues(alpha: 0.45), 1.0));

    // Grey stub + end flange at the top (inlet mouth facing top)
    final Rect stub = s.rect(484, 12, 516, 32);
    canvas.drawRRect(RRect.fromRectAndRadius(stub, Radius.circular(s.u * 5)), _steelH(stub));
    canvas.drawRRect(RRect.fromRectAndRadius(stub, Radius.circular(s.u * 5)), _stroke(Colors.black.withValues(alpha: 0.5), 1));
    _flange(canvas, s, 452, 24, 548, 40, horizontal: true);

    // Flange pair just above the lid nozzle
    _flange(canvas, s, 454, 172, 546, 186, horizontal: true);
    _flange(canvas, s, 454, 188, 546, 202, horizontal: true);

    // Globe valve body
    final Rect body = s.rect(458, 118, 542, 162);
    final RRect rb = RRect.fromRectAndRadius(body, Radius.circular(s.u * 10));
    canvas.drawRRect(rb, _steelH(body));
    canvas.drawRRect(rb, _stroke(Colors.black.withValues(alpha: 0.55), 1.1));
    for (final double y in [126.0, 134.0, 146.0, 154.0]) {
      canvas.drawLine(s.o(462, y), s.o(538, y), _stroke(Colors.black.withValues(alpha: 0.25), 1.2 * s.u));
    }

    // Yoke / bonnet (points UP) with slots
    final Rect yoke = s.rect(486, 78, 514, 118);
    canvas.drawRRect(RRect.fromRectAndRadius(yoke, Radius.circular(s.u * 5)), _steelH(yoke));
    canvas.drawRRect(RRect.fromRectAndRadius(yoke, Radius.circular(s.u * 5)), _stroke(Colors.black.withValues(alpha: 0.5), 1.0));
    for (final double y in [88.0, 98.0, 108.0]) {
      canvas.drawLine(s.o(490, y), s.o(510, y), _stroke(Colors.black.withValues(alpha: 0.45), 2 * s.u));
    }

    // Stem
    canvas.drawLine(s.o(500, 58), s.o(500, 80), _stroke(_ssMid, 5 * s.u));

    // Hand wheel (facing top - horizontal perspective wheel)
    final Offset c = s.o(500, 58);
    final double rx = s.x(40), ry = s.y(14);
    final Rect wheel = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(wheel.shift(Offset(s.x(2), s.y(3))), _stroke(Colors.black.withValues(alpha: 0.18), 8 * s.u));
    canvas.drawOval(wheel, _stroke(_blueMid, 8 * s.u));
    canvas.drawOval(wheel, _stroke(Colors.white.withValues(alpha: 0.25), 2 * s.u));
    canvas.drawOval(wheel.deflate(4 * s.u), _stroke(Colors.black.withValues(alpha: 0.25), 1.2));
    for (final double a in [0.0, math.pi / 4, math.pi / 2, 3 * math.pi / 4]) {
      canvas.drawLine(
        Offset(c.dx - rx * 0.9 * math.cos(a), c.dy - ry * 0.9 * math.sin(a)),
        Offset(c.dx + rx * 0.9 * math.cos(a), c.dy + ry * 0.9 * math.sin(a)),
        _stroke(_blueMid, 4.5 * s.u),
      );
    }
    canvas.drawCircle(c, s.u * 7, Paint()..color = _ssMid);
    canvas.drawCircle(c, s.u * 7, _stroke(Colors.black.withValues(alpha: 0.5), 1));
  }

  // ------------------------------------- bottom: outlet pipe + ball valve

  void _drawOutletAssembly(Canvas canvas, _Sc s) {
    // Vertical blue pipe
    final Rect pipe = s.rect(478, 866, 522, 964);
    canvas.drawRect(pipe, _blueH(pipe));
    _speckle(canvas, pipe, 21, 22, const Color(0xFFB7C3E6), s.u);
    _speckle(canvas, pipe, 23, 6, _rust, s.u);
    canvas.drawRect(pipe, _stroke(Colors.black.withValues(alpha: 0.45), 1.0));

    // Grey collar hiding the join with the cone tip
    final Rect collar = s.rect(466, 850, 534, 870);
    canvas.drawRRect(RRect.fromRectAndRadius(collar, Radius.circular(s.u * 8)), _steelH(collar));
    canvas.drawRRect(RRect.fromRectAndRadius(collar, Radius.circular(s.u * 8)), _stroke(Colors.black.withValues(alpha: 0.5), 1.1));

    // Flange pair
    _flange(canvas, s, 458, 876, 542, 888, horizontal: true);
    _flange(canvas, s, 458, 890, 542, 902, horizontal: true);

    // Ball valve body
    final Rect body = s.rect(466, 906, 534, 938);
    final RRect rb = RRect.fromRectAndRadius(body, Radius.circular(s.u * 12));
    canvas.drawRRect(rb, _steelH(body));
    canvas.drawRRect(rb, _stroke(Colors.black.withValues(alpha: 0.5), 1.1));

    // Bonnet + stem (pointing right)
    final Rect bonnet = s.rect(532, 911, 550, 929);
    canvas.drawRRect(RRect.fromRectAndRadius(bonnet, Radius.circular(s.u * 4)), _steelV(bonnet));
    canvas.drawRRect(RRect.fromRectAndRadius(bonnet, Radius.circular(s.u * 4)), _stroke(Colors.black.withValues(alpha: 0.5), 1));
    final Rect stem = s.rect(549, 917, 561, 923);
    canvas.drawRect(stem, _steelV(stem));

    // Blue lever
    canvas.drawLine(s.o(556, 921), s.o(640, 893), _stroke(Colors.black.withValues(alpha: 0.25), 6 * s.u));
    canvas.drawLine(s.o(556, 920), s.o(640, 892), _stroke(_blueMid, 4.5 * s.u)..strokeCap = StrokeCap.round);
    canvas.drawLine(s.o(560, 917), s.o(634, 892), _stroke(Colors.white.withValues(alpha: 0.35), 1.2 * s.u));
    canvas.drawCircle(s.o(556, 920), s.u * 6, Paint()..color = _ssMid);
    canvas.drawCircle(s.o(556, 920), s.u * 6, _stroke(Colors.black.withValues(alpha: 0.5), 1));

    // End flange: grey inner first, blue outer on top
    final Rect inner = s.rect(468, 966, 532, 980);
    canvas.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(s.u * 6)), _steelH(inner));
    canvas.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(s.u * 6)), _stroke(Colors.black.withValues(alpha: 0.5), 1));
    _flange(canvas, s, 456, 954, 544, 968, horizontal: true);
  }

  // ------------------------------------------------------------- active glow

  void _drawActiveGlow(Canvas canvas, _Sc s) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(s.rect(316, 300, 692, 726).inflate(6 * s.u), Radius.circular(s.u * 26)),
      Paint()
        ..color = _chemGlow.withValues(alpha: 0.28 + 0.06 * math.sin(phase * 2 * math.pi))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 26 * s.u),
    );
  }

  // -------------------------------------------------------------------- cone

  void _drawCone(Canvas canvas, _Sc s) {
    final Path cone = Path()
      ..moveTo(s.x(350), s.y(744))
      ..lineTo(s.x(656), s.y(744))
      ..cubicTo(s.x(640), s.y(790), s.x(568), s.y(842), s.x(516), s.y(857))
      ..quadraticBezierTo(s.x(500), s.y(863), s.x(484), s.y(857))
      ..cubicTo(s.x(432), s.y(842), s.x(366), s.y(790), s.x(350), s.y(744))
      ..close();
    final Rect b = cone.getBounds();
    canvas.drawPath(
      cone,
      _fillH(b, const [Color(0xFF7D8487), Color(0xFFC6CACC), Color(0xFFA3A8AB), Color(0xFF6C7376)], stops: const [0, 0.32, 0.65, 1]),
    );
    canvas.save();
    canvas.clipPath(cone);
    canvas.drawRect(
      b,
      _fillV(b, [Colors.black.withValues(alpha: 0.25), Colors.transparent, Colors.black.withValues(alpha: 0.12)], stops: const [0, 0.4, 1]),
    );
    canvas.restore();
    canvas.drawPath(cone, _stroke(Colors.black.withValues(alpha: 0.5), 1.2));
  }

  // ------------------------------------------------------------------- stand

  void _drawStand(Canvas canvas, _Sc s) {
    // Base plate as two feet (gap in the middle for the outlet pipe)
    for (final List<double> seg in [
      [262.0, 440.0],
      [560.0, 735.0],
    ]) {
      final Rect baseFront = s.rect(seg[0], 950, seg[1], 985);
      canvas.drawRect(baseFront.shift(Offset(s.x(2), s.y(4))), Paint()..color = Colors.black.withValues(alpha: 0.18));
      canvas.drawRect(baseFront, _fillV(baseFront, const [Color(0xFF8E8A82), Color(0xFF6D6963)]));
      canvas.save();
      canvas.clipRect(baseFront);
      _speckle(canvas, baseFront, 3 + seg[0].toInt(), 45, _rust, s.u);
      _speckle(canvas, baseFront, 4 + seg[0].toInt(), 15, const Color(0xFF3C3934), s.u);
      canvas.restore();
      canvas.drawRect(baseFront, _stroke(Colors.black.withValues(alpha: 0.55), 1.2));
      final Rect top = s.rect(seg[0], 944, seg[1], 952);
      canvas.drawRect(top, Paint()..color = const Color(0xFFB4B0A8));
      canvas.drawRect(top, _stroke(Colors.black.withValues(alpha: 0.4), 1));
    }

    // Upper rail: split around the outlet pipe
    canvas.drawRect(s.rect(300, 908, 462, 928), Paint()..color = const Color(0xFF4A4640));
    canvas.drawRect(s.rect(538, 908, 718, 928), Paint()..color = const Color(0xFF4A4640));
    _beam(canvas, s, [s.o(296, 926), s.o(462, 926), s.o(462, 946), s.o(296, 946)], 31);
    _beam(canvas, s, [s.o(538, 926), s.o(722, 926), s.o(722, 946), s.o(538, 946)], 32);

    // Uprights
    _beam(canvas, s, [s.o(408, 808), s.o(436, 808), s.o(436, 926), s.o(408, 926)], 41);
    _beam(canvas, s, [s.o(566, 808), s.o(594, 808), s.o(594, 926), s.o(566, 926)], 51);

    // Diagonal braces
    _beam(canvas, s, [s.o(338, 796), s.o(352, 784), s.o(424, 872), s.o(410, 886)], 61);
    _beam(canvas, s, [s.o(662, 806), s.o(650, 792), s.o(578, 876), s.o(592, 890)], 71);

    // Splayed legs
    _beam(canvas, s, [s.o(322, 750), s.o(358, 754), s.o(320, 943), s.o(276, 943)], 81);
    _beam(canvas, s, [s.o(652, 756), s.o(690, 750), s.o(724, 944), s.o(683, 944)], 91);

    if (showJoints) {
      for (final Offset o in [s.o(300, 966), s.o(430, 966), s.o(570, 966), s.o(708, 966)]) {
        _bolt(canvas, o, s.u * 5);
      }
    }
  }

  // -------------------------------------------------------------------- body

  void _drawBody(Canvas canvas, _Sc s) {
    final Rect body = s.rect(316, 296, 692, 726);
    final RRect rb = RRect.fromRectAndCorners(
      body,
      topLeft: Radius.circular(s.u * 24),
      topRight: Radius.circular(s.u * 24),
      bottomLeft: Radius.circular(s.u * 8),
      bottomRight: Radius.circular(s.u * 8),
    );
    canvas.drawRRect(
      rb,
      _fillH(
        body,
        const [Color(0xFF878E91), Color(0xFFC4C8CA), Color(0xFFDDE0E1), Color(0xFFBBC0C2), Color(0xFF9AA0A3), Color(0xFF6B7376)],
        stops: const [0, 0.08, 0.24, 0.55, 0.85, 1],
      ),
    );

    canvas.save();
    canvas.clipRRect(rb);
    // Brushed grain
    final math.Random rnd = math.Random(12);
    for (double x = body.left; x < body.right; x += 3 * s.x(1)) {
      final bool light = rnd.nextBool();
      canvas.drawLine(
        Offset(x, body.top),
        Offset(x, body.bottom),
        _stroke((light ? Colors.white : Colors.black).withValues(alpha: 0.035 + 0.03 * rnd.nextDouble()), 1),
      );
    }
    // Soft vertical highlight and top/bottom shading
    final Rect hl = s.rect(326, 320, 350, 700);
    canvas.drawRect(hl, _fillH(hl, [Colors.transparent, Colors.white.withValues(alpha: 0.22), Colors.transparent]));
    canvas.drawRect(
      body,
      _fillV(body, [Colors.black.withValues(alpha: 0.18), Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.10)], stops: const [0, 0.12, 0.85, 1]),
    );
    _speckle(canvas, body, 71, 26, const Color(0xFF3C4245), s.u);
    canvas.restore();

    canvas.drawRRect(rb, _stroke(Colors.black.withValues(alpha: 0.5), 1.3));
  }

  void _drawCollar(Canvas canvas, _Sc s) {
    final Rect collar = s.rect(306, 721, 694, 749);
    final RRect rr = RRect.fromRectAndRadius(collar, Radius.circular(s.u * 9));
    canvas.drawRRect(rr.shift(Offset(0, s.y(3))), Paint()..color = Colors.black.withValues(alpha: 0.2));
    canvas.drawRRect(rr, _fillV(collar, const [Color(0xFFE6E9EA), Color(0xFFB4B9BB), Color(0xFF8B9294)], stops: const [0, 0.5, 1]));
    canvas.drawRRect(rr, _stroke(Colors.black.withValues(alpha: 0.5), 1.2));
    canvas.drawLine(s.o(312, 734), s.o(688, 734), _stroke(Colors.black.withValues(alpha: 0.25), 1.2));
    canvas.drawLine(s.o(312, 726), s.o(688, 726), _stroke(Colors.white.withValues(alpha: 0.5), 1.2));
  }

  // ------------------------------------------------------------------ window

  void _drawWindow(Canvas canvas, _Sc s) {
    // Recessed frame
    final Rect outer = s.rect(360, 331, 632, 730);
    final RRect rOuter = RRect.fromRectAndRadius(outer, Radius.circular(s.u * 52));
    canvas.drawRRect(rOuter, _fillV(outer, const [Color(0xFFB3B8BA), Color(0xFF9EA4A7), Color(0xFFCBCFD1)]));
    canvas.drawRRect(rOuter, _stroke(Colors.black.withValues(alpha: 0.35), 1.2));
    canvas.drawRRect(rOuter.deflate(s.u * 3), _stroke(Colors.white.withValues(alpha: 0.4), 1.4));

    final Rect inner = s.rect(372, 345, 618, 713);
    final RRect rInner = RRect.fromRectAndRadius(inner, Radius.circular(s.u * 34));

    canvas.save();
    canvas.clipRRect(rInner);

    // Back wall (grey corrugated steel)
    canvas.drawRect(inner, _fillV(inner, const [Color(0xFF777C7E), Color(0xFF9DA1A2), Color(0xFF8A8F90)]));
    for (double x = inner.left; x < inner.right; x += 6 * s.x(1)) {
      canvas.drawLine(Offset(x, inner.top), Offset(x, inner.bottom), _stroke(Colors.black.withValues(alpha: 0.07), 1.4));
    }

    // Liquid
    final double liquidTop = s.y(462);
    final double amp = s.y(isOn ? 2.6 : 1.0);
    final Path liquid = Path()..moveTo(inner.left, liquidTop);
    for (double x = inner.left; x <= inner.right; x += 2) {
      final double nx = (x - inner.left) / inner.width;
      liquid.lineTo(x, liquidTop + math.sin(nx * 3 * math.pi + phase * 2 * math.pi) * amp);
    }
    liquid
      ..lineTo(inner.right, inner.bottom)
      ..lineTo(inner.left, inner.bottom)
      ..close();
    final Rect liquidRect = Rect.fromLTRB(inner.left, liquidTop - amp, inner.right, inner.bottom);
    canvas.drawPath(
      liquid,
      _fillV(liquidRect, const [_liqSurface, _liqTop, _liqMid, _liqDeep], stops: const [0, 0.05, 0.45, 1]),
    );
    // vertical banding + side vignette
    for (double x = inner.left; x < inner.right; x += 9 * s.x(1)) {
      canvas.drawLine(Offset(x, liquidTop + s.y(4)), Offset(x, inner.bottom), _stroke(Colors.white.withValues(alpha: 0.035), 3 * s.u));
    }
    canvas.drawRect(
      liquidRect,
      _fillH(liquidRect, [Colors.black.withValues(alpha: 0.25), Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.20)], stops: const [0, 0.1, 0.9, 1]),
    );
    canvas.drawPath(liquid, _stroke(Colors.white.withValues(alpha: 0.4), 1.4));
    canvas.drawLine(
      Offset(inner.left, liquidTop - s.y(2.5)),
      Offset(inner.right, liquidTop - s.y(2.5)),
      _stroke(Colors.black.withValues(alpha: 0.12), 1.2),
    );

    // Agitator shaft
    final Rect shaft = s.rect(490.5, 345, 497.5, 600);
    canvas.drawRect(shaft, _fillH(shaft, const [Color(0xFF6E7477), Color(0xFFE0E3E4), Color(0xFF7A8083)]));
    canvas.drawRect(shaft, _stroke(Colors.black.withValues(alpha: 0.35), 0.8));

    // Propeller (translucent green blades)
    final double spinA = isOn ? math.cos(phase * 4 * math.pi) : 1.0;
    final double spinB = isOn ? math.sin(phase * 4 * math.pi) : 1.0;
    void blade(Offset c, double rx, double ry, double rot, double sc) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      final Rect br = Rect.fromCenter(center: Offset.zero, width: rx * 2 * sc, height: ry * 2);
      canvas.drawOval(br.shift(Offset(0, ry * 0.25)), Paint()..color = Colors.black.withValues(alpha: 0.15));
      canvas.drawOval(br, _fillV(br, const [Color(0xFF88D082), Color(0xFF4D9C4A), Color(0xFF357F38)]));
      canvas.drawOval(br, _stroke(const Color(0xFF1F5A24).withValues(alpha: 0.6), 1.0));
      canvas.restore();
    }

    blade(s.o(458, 621), s.x(33), s.y(17), -0.10, 0.4 + 0.6 * spinA.abs());
    blade(s.o(538, 615), s.x(34), s.y(15), 0.08, 0.4 + 0.6 * spinB.abs());

    // Hub
    final Rect hub = s.rect(483, 592, 506, 622);
    canvas.drawRRect(RRect.fromRectAndRadius(hub, Radius.circular(s.u * 6)), _fillH(hub, const [Color(0xFF6E7477), Color(0xFFDDE0E1), Color(0xFF7A8083)]));
    canvas.drawRRect(RRect.fromRectAndRadius(hub, Radius.circular(s.u * 6)), _stroke(Colors.black.withValues(alpha: 0.5), 1));

    // Swirl + bubbles
    if (isOn) {
      final Paint swirl = _stroke(Colors.white.withValues(alpha: 0.25), 1.3 * s.u)..strokeCap = StrokeCap.round;
      for (int i = 0; i < 4; i++) {
        final double cy = s.y(500 + i * 50);
        final double rx = s.x(105 - i * 6);
        final double ry = s.y(7 + i * 2.0);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(inner.center.dx, cy), width: rx * 2, height: ry * 2),
          phase * 2 * math.pi + i * 1.2,
          math.pi * 1.2,
          false,
          swirl,
        );
      }
      final math.Random rnd = math.Random(37);
      for (int i = 0; i < 16; i++) {
        final double bx = inner.left + s.x(12) + rnd.nextDouble() * (inner.width - s.x(24));
        final int cycles = 1 + rnd.nextInt(3);
        final double prog = (phase * cycles + rnd.nextDouble()) % 1.0;
        final double by = inner.bottom - s.y(10) - prog * (inner.bottom - liquidTop - s.y(16));
        final double r = (1.6 + rnd.nextDouble() * 2.4) * s.u;
        canvas.drawCircle(Offset(bx, by), r, Paint()..color = Colors.white.withValues(alpha: 0.35));
        canvas.drawCircle(Offset(bx, by), r, _stroke(Colors.white.withValues(alpha: 0.7), 0.8));
      }
    }

    // Graduation ticks on the right edge
    for (final double y in [410.0, 465.0, 520.0, 575.0, 630.0]) {
      canvas.drawLine(s.o(592, y), s.o(618, y), _stroke(const Color(0xFF8E9497), 1.6 * s.u));
    }

    // Glass glare and inner shadow
    final Path glare = Path()
      ..moveTo(s.x(380), s.y(350))
      ..lineTo(s.x(400), s.y(350))
      ..lineTo(s.x(386), s.y(708))
      ..lineTo(s.x(378), s.y(708))
      ..close();
    canvas.drawPath(glare, Paint()..color = Colors.white.withValues(alpha: 0.10));
    canvas.drawRRect(rInner, _stroke(Colors.black.withValues(alpha: 0.35), 6 * s.u));

    canvas.restore();
    canvas.drawRRect(rInner, _stroke(Colors.black.withValues(alpha: 0.55), 1.4));
  }

  // -------------------------------------------------------------- sight glass

  void _drawSightGlass(Canvas canvas, _Sc s) {
    final Rect tube = s.rect(627, 372, 661, 690);
    final RRect rt = RRect.fromRectAndRadius(tube, Radius.circular(s.u * 6));

    canvas.drawRRect(rt.shift(Offset(s.x(2), s.y(2))), Paint()..color = Colors.black.withValues(alpha: 0.18));
    canvas.drawRRect(rt, _fillH(tube, const [Color(0xFF93A296), Color(0xFFE4EDE4), Color(0xFFA9B8AC)], stops: const [0, 0.4, 1]));

    // Green liquid column
    canvas.save();
    canvas.clipRRect(rt);
    final Rect fill = s.rect(627, 460, 661, 690);
    canvas.drawRect(fill, _fillV(fill, const [Color(0xFF8AD67A), Color(0xFF55AC4E), Color(0xFF3F9443)]));
    canvas.drawRect(fill, _fillH(fill, [Colors.black.withValues(alpha: 0.2), Colors.transparent, Colors.black.withValues(alpha: 0.18)], stops: const [0, 0.5, 1]));
    canvas.drawRect(s.rect(633, 376, 640, 686), Paint()..color = Colors.white.withValues(alpha: 0.35));
    canvas.drawLine(s.o(627, 460), s.o(661, 460), _stroke(Colors.white.withValues(alpha: 0.5), 1.2));
    canvas.restore();
    canvas.drawRRect(rt, _stroke(Colors.black.withValues(alpha: 0.5), 1.1));

    // End caps
    void cap(Rect r) {
      final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(s.u * 6));
      canvas.drawRRect(rr.shift(Offset(s.x(2), s.y(3))), Paint()..color = Colors.black.withValues(alpha: 0.2));
      canvas.drawRRect(rr, _steelH(r));
      canvas.drawRRect(rr, _stroke(Colors.black.withValues(alpha: 0.55), 1.2));
      canvas.drawLine(Offset(r.left + s.x(3), r.top + r.height * 0.5), Offset(r.right - s.x(3), r.top + r.height * 0.5), _stroke(Colors.black.withValues(alpha: 0.2), 1));
      if (showJoints) {
        _bolt(canvas, Offset(r.left + r.width * 0.22, r.center.dy), s.u * 3.6);
        _bolt(canvas, Offset(r.right - r.width * 0.22, r.center.dy), s.u * 3.6);
      }
    }

    cap(s.rect(612, 338, 673, 377));
    cap(s.rect(609, 686, 671, 725));
  }

  // --------------------------------------------------------- dome and nozzle

  void _drawDomeAndNozzle(Canvas canvas, _Sc s) {
    // Dome
    final Path dome = Path()
      ..moveTo(s.x(314), s.y(290))
      ..cubicTo(s.x(340), s.y(262), s.x(420), s.y(248), s.x(500), s.y(247))
      ..cubicTo(s.x(580), s.y(248), s.x(660), s.y(262), s.x(688), s.y(290))
      ..close();
    final Rect db = dome.getBounds();
    canvas.drawPath(dome, _fillH(db, const [Color(0xFF8B9295), Color(0xFFDADDDE), Color(0xFFB5BABC), Color(0xFF7A8184)], stops: const [0, 0.35, 0.7, 1]));
    canvas.save();
    canvas.clipPath(dome);
    canvas.drawRect(db, _fillV(db, [Colors.white.withValues(alpha: 0.28), Colors.transparent, Colors.black.withValues(alpha: 0.12)]));
    canvas.restore();
    canvas.drawPath(dome, _stroke(Colors.black.withValues(alpha: 0.5), 1.2));

    // Lid rim band
    final Rect rim = s.rect(308, 284, 694, 313);
    final RRect rr = RRect.fromRectAndRadius(rim, Radius.circular(s.u * 10));
    canvas.drawRRect(rr.shift(Offset(0, s.y(3))), Paint()..color = Colors.black.withValues(alpha: 0.22));
    canvas.drawRRect(rr, _fillV(rim, const [Color(0xFFDDE0E1), Color(0xFFA9AEB0), Color(0xFFCDD1D2)]));
    canvas.drawRRect(rr, _stroke(Colors.black.withValues(alpha: 0.5), 1.2));
    canvas.drawLine(s.o(314, 298), s.o(688, 298), _stroke(Colors.black.withValues(alpha: 0.3), 1.2));
    canvas.drawLine(s.o(314, 290), s.o(688, 290), _stroke(Colors.white.withValues(alpha: 0.5), 1.2));

    // Nozzle neck
    final Rect neck = s.rect(474, 222, 526, 252);
    canvas.drawRect(neck, _steelH(neck));
    canvas.drawRect(neck, _stroke(Colors.black.withValues(alpha: 0.4), 1));

    // Base ring
    final Rect ring = s.rect(462, 243, 538, 257);
    canvas.drawRRect(RRect.fromRectAndRadius(ring, Radius.circular(s.u * 4)), _steelH(ring));
    canvas.drawRRect(RRect.fromRectAndRadius(ring, Radius.circular(s.u * 4)), _stroke(Colors.black.withValues(alpha: 0.5), 1));

    // Top flange
    final Rect fl = s.rect(460, 197, 540, 224);
    final RRect rf = RRect.fromRectAndRadius(fl, Radius.circular(s.u * 6));
    canvas.drawRRect(rf, _fillV(fl, const [Color(0xFFEDEFF0), Color(0xFFB9BEC0), Color(0xFF8F9597)]));
    canvas.drawRRect(rf, _stroke(Colors.black.withValues(alpha: 0.55), 1.2));
    final Rect face = Rect.fromCenter(center: s.o(500, 199), width: s.x(78), height: s.y(11));
    canvas.drawOval(face, Paint()..color = const Color(0xFFDDE1E2));
    canvas.drawOval(face, _stroke(Colors.black.withValues(alpha: 0.4), 1));
    canvas.drawOval(Rect.fromCenter(center: s.o(500, 199), width: s.x(50), height: s.y(6.5)), Paint()..color = const Color(0xFF6B7174));
  }

  @override
  bool shouldRepaint(covariant DetailedFertilizerTankPainter oldDelegate) {
    return oldDelegate.isOn != isOn ||
        oldDelegate.phase != phase ||
        oldDelegate.showJoints != showJoints;
  }
}

/// Reference-grid scaler (944 x 1132 photo space -> canvas).
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

/// Stateful widget wrapper for DetailedFertilizerTankPainter.
/// Use a size with aspect ratio ~0.834 (e.g. 300 x 360).
class FertilizerTankView extends StatefulWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  const FertilizerTankView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    required this.size,
  });

  @override
  State<FertilizerTankView> createState() => _FertilizerTankViewState();
}

class _FertilizerTankViewState extends State<FertilizerTankView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        size: widget.size,
        painter: DetailedFertilizerTankPainter(
          isOn: widget.isOn,
          phase: _c.value,
          showJoints: widget.showJoints,
        ),
      ),
    );
  }
}