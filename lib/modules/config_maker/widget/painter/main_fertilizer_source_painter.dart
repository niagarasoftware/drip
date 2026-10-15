import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Photo-matched Main Fertilizer Source painter.
///
/// Reproduces a 1000 L IBC tote: black polymer pallet base with yellow/black
/// hazard marks, frosted translucent tote with green fertilizer solution and
/// condensation droplets, galvanized tubular cage (top frame + 4 front bars +
/// 3 rails), black ribbed screw cap, blue/green inlet pipe on top-left, and a
/// green ball valve with red lever and grey adapter at bottom-right.
///
/// All geometry is authored on a 1024 x 1024 reference grid (taken from the
/// photo) and scaled to the canvas, so use a SQUARE [size] for exact proportions.
///
/// [isOn]       – dosing active: bubbles rise, surface ripples, green glow halo.
/// [phase]      – 0..1 looping animation driver.
/// [showJoints] – draw bolts / flange details.
class DetailedMainFertilizerSourcePainter extends CustomPainter {
  final bool isOn;
  final double phase;
  final bool showJoints;

  DetailedMainFertilizerSourcePainter({
    required this.isOn,
    this.phase = 0,
    this.showJoints = true,
  });

  // ---------------------------------------------------------------- palette
  static const Color _edge = Color(0xFF1C2833);

  // Galvanized steel
  static const Color _steelDark = Color(0xFF6B7478);
  static const Color _steelMid = Color(0xFFA9B1B5);
  static const Color _steelLight = Color(0xFFEEF2F3);

  // Pallet
  static const Color _palletTop = Color(0xFF3A3A3C);
  static const Color _palletMid = Color(0xFF1C1C1E);
  static const Color _palletDark = Color(0xFF0C0C0D);
  static const Color _hazardYellow = Color(0xFFF2C200);

  // Fertilizer solution
  static const Color _chemFoam = Color(0xFF8FD08A);
  static const Color _chemTop = Color(0xFF3E9A3E);
  static const Color _chemMid = Color(0xFF2B8030);
  static const Color _chemDeep = Color(0xFF1E6524);
  static const Color _chemGlow = Color(0xFF4CAF50);

  // Valve / pipes
  static const Color _leverRed = Color(0xFFD9342B);
  static const Color _leverRedDark = Color(0xFF9E1B15);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    _drawGroundShadow(canvas, w, h);
    _drawPallet(canvas, w, h);
    if (isOn) _drawActiveGlow(canvas, w, h);
    _drawToteAndLiquid(canvas, w, h);
    _drawInletPipe(canvas, w, h);
    _drawCap(canvas, w, h);
    _drawCage(canvas, w, h);
    _drawDischargeValve(canvas, w, h);
  }

  // -------------------------------------------------------------- helpers

  Paint _fillV(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(r);

  Paint _fillH(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(r);

  Paint _stroke(Color c, double width) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = c;

  // ----------------------------------------------------------- ground shadow

  void _drawGroundShadow(Canvas canvas, double w, double h) {
    final double u = w / 1024, v = h / 1024;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(512 * u, 902 * v), width: 860 * u, height: 60 * v),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * u),
    );
  }

  // ----------------------------------------------------------------- pallet

  void _drawPallet(Canvas canvas, double w, double h) {
    final double u = w / 1024, v = h / 1024;
    double X(double p) => p * u;
    double Y(double p) => p * v;

    // Feet (drawn first, slightly lighter than the deck underside)
    final List<List<double>> feet = [
      [100, 280],
      [435, 590],
      [718, 902],
    ];
    for (final f in feet) {
      final Rect r = Rect.fromLTRB(X(f[0]), Y(825), X(f[1]), Y(896));
      final RRect rr = RRect.fromRectAndCorners(
        r,
        bottomLeft: Radius.circular(X(22)),
        bottomRight: Radius.circular(X(22)),
      );
      canvas.drawRRect(rr, _fillH(r, const [_palletMid, _palletTop, _palletMid, _palletDark], stops: const [0, 0.3, 0.75, 1]));
      canvas.drawRRect(rr, _stroke(Colors.black.withValues(alpha: 0.6), 1.2));
    }

    // Main deck / bund body
    final Rect deck = Rect.fromLTRB(X(95), Y(752), X(905), Y(842));
    final RRect rDeck = RRect.fromRectAndCorners(
      deck,
      topLeft: Radius.circular(X(24)),
      topRight: Radius.circular(X(24)),
      bottomLeft: Radius.circular(X(10)),
      bottomRight: Radius.circular(X(10)),
    );
    canvas.drawRRect(rDeck, _fillV(deck, const [_palletTop, _palletMid, _palletDark], stops: const [0, 0.35, 1]));
    canvas.drawRRect(rDeck, _stroke(Colors.black.withValues(alpha: 0.7), 1.4));

    // Top lip highlight
    canvas.drawLine(
      Offset(X(120), Y(756)),
      Offset(X(880), Y(756)),
      _stroke(Colors.white.withValues(alpha: 0.12), 2),
    );

    // Dark sump recess where the tote sits
    canvas.drawRect(
      Rect.fromLTRB(X(128), Y(752), X(872), Y(782)),
      Paint()..color = const Color(0xFF0A0A0B),
    );

    // Front face panel shading + vertical moulding ribs
    final Paint rib = _stroke(Colors.white.withValues(alpha: 0.05), 1.5);
    for (double x = 130; x < 880; x += 60) {
      canvas.drawLine(Offset(X(x), Y(808)), Offset(X(x), Y(838)), rib);
    }

    // Hazard stripes (bottom-left / bottom-right of lip)
    _hazard(canvas, Rect.fromLTRB(X(138), Y(789), X(272), Y(802)), u);
    _hazard(canvas, Rect.fromLTRB(X(734), Y(789), X(872), Y(802)), u);

    // Hazard corner wedges
    final Paint yellow = Paint()..color = _hazardYellow;
    canvas.drawPath(
      Path()
        ..moveTo(X(104), Y(768))
        ..lineTo(X(133), Y(768))
        ..lineTo(X(133), Y(787))
        ..close(),
      yellow,
    );
    canvas.drawPath(
      Path()
        ..moveTo(X(896), Y(764))
        ..lineTo(X(868), Y(764))
        ..lineTo(X(868), Y(783))
        ..close(),
      yellow,
    );
  }

  void _hazard(Canvas canvas, Rect rim, double u) {
    canvas.save();
    canvas.clipRect(rim);
    canvas.drawRect(rim, Paint()..color = _hazardYellow);
    final Paint stripe = Paint()
      ..color = const Color(0xFF151515)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * u;
    for (double x = rim.left - rim.height; x < rim.right + rim.height; x += 16 * u) {
      canvas.drawLine(Offset(x, rim.bottom), Offset(x + rim.height, rim.top), stripe);
    }
    canvas.restore();
    canvas.drawRect(rim, _stroke(Colors.black.withValues(alpha: 0.5), 0.8));
  }

  // -------------------------------------------------------------- active glow

  void _drawActiveGlow(Canvas canvas, double w, double h) {
    final double u = w / 1024, v = h / 1024;
    final Rect tote = Rect.fromLTRB(135 * u, 145 * v, 868 * u, 762 * v);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tote.inflate(6 * u), Radius.circular(50 * u)),
      Paint()
        ..color = _chemGlow.withValues(alpha: 0.30 + 0.05 * math.sin(phase * 2 * math.pi))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 26 * u),
    );
  }

  // ------------------------------------------------------- tote and solution

  void _drawToteAndLiquid(Canvas canvas, double w, double h) {
    final double u = w / 1024, v = h / 1024;
    double X(double p) => p * u;
    double Y(double p) => p * v;

    final Rect tote = Rect.fromLTRB(X(135), Y(145), X(868), Y(762));
    final RRect rTote = RRect.fromRectAndCorners(
      tote,
      topLeft: Radius.circular(X(55)),
      topRight: Radius.circular(X(55)),
      bottomLeft: Radius.circular(X(14)),
      bottomRight: Radius.circular(X(14)),
    );

    canvas.save();
    canvas.clipRRect(rTote);

    // Frosted HDPE wall
    canvas.drawRect(
      tote,
      _fillH(tote, const [
        Color(0xFFC3CBC3),
        Color(0xFFE9EEE9),
        Color(0xFFF6F8F6),
        Color(0xFFEAEFEA),
        Color(0xFFC0C8C0),
      ], stops: const [0, 0.08, 0.5, 0.92, 1]),
    );

    // Top face (lighter, frosted) and soft edge where front wall begins
    final Rect topFace = Rect.fromLTRB(tote.left, tote.top, tote.right, Y(226));
    canvas.drawRect(
      topFace,
      _fillV(topFace, [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0.05)]),
    );
    canvas.drawLine(
      Offset(tote.left, Y(226)),
      Offset(tote.right, Y(226)),
      _stroke(Colors.black.withValues(alpha: 0.08), 2),
    );

    // Greenish tint of the headspace just above the liquid
    final double liquidTop = Y(362);
    final Rect head = Rect.fromLTRB(tote.left, Y(226), tote.right, liquidTop);
    canvas.drawRect(
      head,
      _fillV(head, [Colors.transparent, _chemFoam.withValues(alpha: 0.28)]),
    );

    // Frothy band just above the surface
    final Rect foam = Rect.fromLTRB(tote.left, liquidTop - Y(20), tote.right, liquidTop + Y(6));
    canvas.drawRect(
      foam,
      _fillV(foam, [Colors.transparent, const Color(0xFFCDEBC8).withValues(alpha: 0.55)]),
    );

    // Liquid body with animated surface
    final double amp = Y(isOn ? 2.4 : 0.9);
    final Path liquid = Path()..moveTo(tote.left, liquidTop);
    for (double x = tote.left; x <= tote.right; x += 3) {
      final double nx = (x - tote.left) / tote.width;
      liquid.lineTo(x, liquidTop + math.sin(nx * 4 * math.pi + phase * 2 * math.pi) * amp);
    }
    liquid
      ..lineTo(tote.right, tote.bottom)
      ..lineTo(tote.left, tote.bottom)
      ..close();

    final Rect liquidRect = Rect.fromLTRB(tote.left, liquidTop - amp, tote.right, tote.bottom);
    canvas.drawPath(
      liquid,
      _fillV(liquidRect, const [_chemFoam, _chemTop, _chemMid, _chemDeep], stops: const [0, 0.05, 0.45, 1]),
    );

    // Darker side vignette inside liquid
    canvas.drawRect(
      liquidRect,
      _fillH(liquidRect, [
        Colors.black.withValues(alpha: 0.28),
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: 0.28),
      ], stops: const [0, 0.12, 0.88, 1]),
    );

    // Surface highlight line
    canvas.drawPath(
      liquid,
      _stroke(Colors.white.withValues(alpha: 0.35), 1.2),
    );

    // Vertical glossy reflections
    final Rect glossL = Rect.fromLTWH(tote.left + X(14), tote.top + Y(80), X(16), tote.height - Y(120));
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossL, Radius.circular(X(8))),
      _fillV(glossL, [Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0.04)]),
    );
    final Rect glossR = Rect.fromLTWH(tote.right - X(26), tote.top + Y(80), X(10), tote.height - Y(130));
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossR, Radius.circular(X(5))),
      _fillV(glossR, [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.02)]),
    );

    // Condensation droplets on the front wall (static, seeded)
    final math.Random rnd = math.Random(42);
    for (int i = 0; i < 62; i++) {
      final double dx = tote.left + X(14) + rnd.nextDouble() * (tote.width - X(28));
      final bool above = i < 10;
      final double dy = above
          ? Y(235) + rnd.nextDouble() * (liquidTop - Y(245))
          : liquidTop + Y(10) + rnd.nextDouble() * (tote.bottom - liquidTop - Y(30));
      final double r = (1.8 + math.pow(rnd.nextDouble(), 2) * 5.5) * u;
      _drawDroplet(canvas, Offset(dx, dy), r, above ? 0.55 : 1.0);
    }

    // Rising bubbles when dosing
    if (isOn) {
      final math.Random b = math.Random(7);
      for (int i = 0; i < 12; i++) {
        final double bx = tote.left + X(30) + b.nextDouble() * (tote.width - X(60));
        final int cycles = 1 + b.nextInt(3);
        final double prog = (phase * cycles + b.nextDouble()) % 1.0;
        final double by = tote.bottom - Y(20) - prog * (tote.bottom - liquidTop - Y(30));
        final double r = (1.5 + b.nextDouble() * 2.5) * u;
        _drawDroplet(canvas, Offset(bx, by), r, 0.9);
      }
    }

    canvas.restore();

    // Tote outline
    canvas.drawRRect(rTote, _stroke(const Color(0xFF3B463B).withValues(alpha: 0.45), 1.6));
  }

  void _drawDroplet(Canvas canvas, Offset c, double r, double a) {
    canvas.drawCircle(c, r, Paint()..color = Colors.white.withValues(alpha: 0.14 * a));
    canvas.drawCircle(c, r, _stroke(const Color(0xFF0B3A10).withValues(alpha: 0.38 * a), 0.9));
    canvas.drawCircle(
      c.translate(-r * 0.35, -r * 0.35),
      r * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.85 * a),
    );
  }

  // --------------------------------------------------------------------- cap

  void _drawCap(Canvas canvas, double w, double h) {
    final double u = w / 1024, v = h / 1024;
    double X(double p) => p * u;
    double Y(double p) => p * v;

    // Neck ring under cap (frosted grey)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(X(500), Y(208)), width: X(172), height: Y(26)),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    // Cap side wall
    final Rect side = Rect.fromLTRB(X(421), Y(166), X(579), Y(206));
    final RRect rSide = RRect.fromRectAndRadius(side, Radius.circular(X(14)));
    canvas.drawRRect(
      rSide,
      _fillH(side, const [Color(0xFF0B0B0B), Color(0xFF3A3A3A), Color(0xFF1B1B1B), Color(0xFF070707)],
          stops: const [0, 0.3, 0.7, 1]),
    );
    for (double x = 428; x < 574; x += 7) {
      canvas.drawLine(
        Offset(X(x), Y(175)),
        Offset(X(x), Y(200)),
        _stroke(Colors.white.withValues(alpha: 0.10), 1.5 * u),
      );
    }
    canvas.drawRRect(rSide, _stroke(Colors.black, 1.2));

    // Top face
    final Rect top = Rect.fromCenter(center: Offset(X(500), Y(166)), width: X(158), height: Y(52));
    canvas.drawOval(top, _fillV(top, const [Color(0xFF4A4A4C), Color(0xFF1E1E20)]));
    canvas.drawOval(top, _stroke(Colors.black, 1.2));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(X(500), Y(166)), width: X(116), height: Y(36)),
      _stroke(Colors.white.withValues(alpha: 0.10), 1.2),
    );
    // small vent dot
    canvas.drawCircle(Offset(X(500), Y(149)), X(3), Paint()..color = const Color(0xFF3A78C8));
  }

  // -------------------------------------------------------------- inlet pipe

  void _drawInletPipe(Canvas canvas, double w, double h) {
    final double u = w / 1024, v = h / 1024;
    double X(double p) => p * u;
    double Y(double p) => p * v;

    // Green pipe + elbow
    final Path green = Path()
      ..moveTo(X(244), Y(138))
      ..lineTo(X(345), Y(138))
      ..quadraticBezierTo(X(386), Y(138), X(386), Y(178))
      ..lineTo(X(386), Y(204))
      ..lineTo(X(336), Y(204))
      ..lineTo(X(336), Y(190))
      ..lineTo(X(244), Y(190))
      ..close();
    final Rect gBounds = Rect.fromLTRB(X(244), Y(138), X(386), Y(204));
    canvas.drawPath(
      green,
      _fillV(gBounds, const [Color(0xFFA6E27F), Color(0xFF5FAE3F), Color(0xFF2F7A26)], stops: const [0, 0.4, 1]),
    );
    canvas.drawPath(green, _stroke(const Color(0xFF1B4A17).withValues(alpha: 0.7), 1.2));
    // pipe highlight
    canvas.drawLine(
      Offset(X(250), Y(147)),
      Offset(X(340), Y(147)),
      _stroke(Colors.white.withValues(alpha: 0.45), 2.2 * u),
    );
    // elbow flange on tote
    final Rect gFlange = Rect.fromLTWH(X(330), Y(198), X(62), Y(12));
    canvas.drawRRect(
      RRect.fromRectAndRadius(gFlange, Radius.circular(X(4))),
      _fillV(gFlange, const [Color(0xFF4CAF50), Color(0xFF1F5E22)]),
    );

    // Blue elbow
    final Path blue = Path()
      ..moveTo(X(150), Y(208))
      ..lineTo(X(150), Y(170))
      ..quadraticBezierTo(X(150), Y(132), X(188), Y(132))
      ..lineTo(X(215), Y(132))
      ..lineTo(X(215), Y(190))
      ..lineTo(X(205), Y(190))
      ..lineTo(X(205), Y(208))
      ..close();
    final Rect bBounds = Rect.fromLTRB(X(150), Y(132), X(215), Y(208));
    canvas.drawPath(
      blue,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF5B9BEA), Color(0xFF2A63B8), Color(0xFF1B447F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bBounds),
    );
    canvas.drawPath(blue, _stroke(const Color(0xFF0F2A55).withValues(alpha: 0.7), 1.2));

    // Blue collar / union nut
    final Rect collar = Rect.fromLTRB(X(210), Y(128), X(244), Y(194));
    canvas.drawRRect(
      RRect.fromRectAndRadius(collar, Radius.circular(X(4))),
      _fillH(collar, const [Color(0xFF1B447F), Color(0xFF4F8EE0), Color(0xFF1B447F)]),
    );
    for (double x = 219; x < 242; x += 8) {
      canvas.drawLine(Offset(X(x), Y(132)), Offset(X(x), Y(190)), _stroke(Colors.black.withValues(alpha: 0.25), 1.2 * u));
    }
    // Blue base flange
    final Rect bFlange = Rect.fromLTWH(X(142), Y(200), X(70), Y(11));
    canvas.drawRRect(
      RRect.fromRectAndRadius(bFlange, Radius.circular(X(4))),
      _fillV(bFlange, const [Color(0xFF3F7FD6), Color(0xFF16386B)]),
    );

    if (showJoints) {
      final Paint bolt = Paint()..color = _steelLight;
      canvas.drawCircle(Offset(X(342), Y(204)), X(1.8), bolt);
      canvas.drawCircle(Offset(X(380), Y(204)), X(1.8), bolt);
      canvas.drawCircle(Offset(X(152), Y(205)), X(1.8), bolt);
      canvas.drawCircle(Offset(X(203), Y(205)), X(1.8), bolt);
    }
  }

  // -------------------------------------------------------------- steel cage

  void _bar(Canvas canvas, Rect r, {required bool vertical, double shadow = 3, double u = 1}) {
    // soft cast shadow on the tote
    canvas.drawRect(
      r.shift(Offset(shadow * u, shadow * 0.6 * u)),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );
    const List<Color> c = [_steelDark, _steelLight, _steelMid, _steelDark];
    const List<double> s = [0, 0.32, 0.68, 1];
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular((vertical ? r.width : r.height) / 2));
    canvas.drawRRect(rr, vertical ? _fillH(r, c, stops: s) : _fillV(r, c, stops: s));
  }

  void _drawCage(Canvas canvas, double w, double h) {
    final double u = w / 1024, v = h / 1024;
    double X(double p) => p * u;
    double Y(double p) => p * v;

    // Side verticals (thinner, at the tote edges)
    for (final double x in [125.0, 875.0]) {
      _bar(canvas, Rect.fromLTRB(X(x - 3.5), Y(212), X(x + 3.5), Y(742)), vertical: true, u: u);
    }

    // Front verticals
    for (final double x in [190.0, 377.0, 622.0, 803.0]) {
      _bar(canvas, Rect.fromLTRB(X(x - 4.5), Y(220), X(x + 4.5), Y(782)), vertical: true, u: u);
    }

    // Horizontal rails
    for (final double y in [385.0, 525.0, 665.0]) {
      _bar(canvas, Rect.fromLTRB(X(112), Y(y - 5), X(888), Y(y + 5)), vertical: false, u: u);
    }

    // Top frame (back rail, curved corners, front rail)
    final Path frame = Path()
      ..moveTo(X(110), Y(213))
      ..cubicTo(X(110), Y(160), X(130), Y(122), X(182), Y(120))
      ..lineTo(X(818), Y(120))
      ..cubicTo(X(870), Y(122), X(890), Y(160), X(890), Y(213));
    final Rect fb = Rect.fromLTRB(X(108), Y(114), X(892), Y(222));

    // short verticals between back and front rails
    for (final double x in [382.0, 620.0]) {
      _bar(canvas, Rect.fromLTRB(X(x - 3.5), Y(122), X(x + 3.5), Y(212)), vertical: true, shadow: 0, u: u);
    }

    canvas.drawPath(frame.shift(Offset(X(2), Y(3))), _stroke(Colors.black.withValues(alpha: 0.18), X(8)));
    canvas.drawPath(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = X(8)
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [_steelLight, _steelMid, _steelDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(fb),
    );
    canvas.drawPath(frame, _stroke(Colors.white.withValues(alpha: 0.35), X(1.6)));

    // front top rail
    _bar(canvas, Rect.fromLTRB(X(108), Y(208), X(892), Y(218)), vertical: false, u: u);

    // Bottom steel rail sitting on the pallet
    _bar(canvas, Rect.fromLTRB(X(128), Y(788), X(872), Y(797)), vertical: false, shadow: 2, u: u);

    // Foot clamps at bottom of the front verticals
    for (final double x in [190.0, 377.0, 622.0]) {
      final Rect clamp = Rect.fromLTRB(X(x - 10), Y(766), X(x + 10), Y(786));
      canvas.drawRRect(
        RRect.fromRectAndRadius(clamp, Radius.circular(X(3))),
        _fillV(clamp, const [_steelLight, _steelMid, _steelDark]),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(clamp, Radius.circular(X(3))), _stroke(_edge.withValues(alpha: 0.7), 1));
      if (showJoints) {
        canvas.drawCircle(clamp.center, X(3), Paint()..color = _steelDark);
        canvas.drawCircle(clamp.center.translate(-X(0.8), -X(0.8)), X(1.2), Paint()..color = _steelLight);
      }
    }
  }

  // --------------------------------------------------------- discharge valve

  void _drawDischargeValve(Canvas canvas, double w, double h) {
    final double u = w / 1024, v = h / 1024;
    double X(double p) => p * u;
    double Y(double p) => p * v;

    // Grey adapter (tote outlet)
    final Rect adapter = Rect.fromLTRB(X(744), Y(708), X(804), Y(784));
    final RRect rAdapter = RRect.fromRectAndRadius(adapter, Radius.circular(X(26)));
    canvas.drawRRect(
      rAdapter,
      _fillH(adapter, const [Color(0xFFC4C7C9), Color(0xFF8A8E90), Color(0xFF4E5254)]),
    );
    canvas.drawRRect(rAdapter, _stroke(Colors.black.withValues(alpha: 0.6), 1.2));
    canvas.drawCircle(adapter.center, X(15), _stroke(Colors.black.withValues(alpha: 0.35), 1.5));
    canvas.drawCircle(adapter.center, X(9), Paint()..color = Colors.black.withValues(alpha: 0.18));

    // Valve stem
    final Rect stem = Rect.fromLTRB(X(806), Y(722), X(830), Y(744));
    canvas.drawRect(stem, _fillH(stem, const [Color(0xFF6E7477), Color(0xFFC9CDCF), Color(0xFF5B6164)]));

    // Green body
    final Rect body = Rect.fromLTRB(X(780), Y(738), X(864), Y(812));
    final RRect rBody = RRect.fromRectAndRadius(body, Radius.circular(X(22)));
    canvas.drawRRect(
      rBody,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8CE060), Color(0xFF4FA836), Color(0xFF2A741E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(body),
    );
    canvas.drawRRect(rBody, _stroke(const Color(0xFF16400F).withValues(alpha: 0.8), 1.2));

    // Outlet stub below
    final Rect stub = Rect.fromLTRB(X(806), Y(808), X(830), Y(838));
    canvas.drawRRect(
      RRect.fromRectAndRadius(stub, Radius.circular(X(4))),
      _fillH(stub, const [Color(0xFF5D6B61), Color(0xFFB8C4BA), Color(0xFF4A574E)]),
    );

    // Threaded green nut with dark outlet hole
    final Offset nc = Offset(X(828), Y(786));
    final Rect nutRect = Rect.fromCenter(center: nc, width: X(68), height: Y(68));
    canvas.drawOval(
      nutRect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF86DD5C), Color(0xFF4AA32F), Color(0xFF2D7A1F)],
          center: Alignment(-0.3, -0.3),
        ).createShader(nutRect),
    );
    canvas.drawOval(nutRect, _stroke(const Color(0xFF16400F), 1.2));
    canvas.drawCircle(nc, X(25), _stroke(const Color(0xFF16400F).withValues(alpha: 0.55), 1.6));
    canvas.drawCircle(nc, X(15), Paint()..color = const Color(0xFF141C12));
    canvas.drawArc(
      Rect.fromCircle(center: nc, radius: X(15)),
      math.pi * 0.9,
      math.pi * 0.6,
      false,
      _stroke(Colors.white.withValues(alpha: 0.35), 1.4),
    );

    // Red lever
    final Path lever = Path()
      ..moveTo(X(795), Y(712))
      ..lineTo(X(825), Y(700))
      ..lineTo(X(912), Y(692))
      ..lineTo(X(919), Y(700))
      ..lineTo(X(914), Y(708))
      ..lineTo(X(845), Y(720))
      ..lineTo(X(826), Y(732))
      ..lineTo(X(800), Y(728))
      ..close();
    final Rect lb = Rect.fromLTRB(X(795), Y(692), X(919), Y(732));
    canvas.drawPath(lever, _fillV(lb, const [Color(0xFFF0574C), _leverRed, _leverRedDark]));
    canvas.drawPath(lever, _stroke(Colors.black.withValues(alpha: 0.7), 1.0));
    canvas.drawLine(
      Offset(X(830), Y(702)),
      Offset(X(908), Y(695)),
      _stroke(Colors.white.withValues(alpha: 0.4), 1.6 * u),
    );

    if (showJoints) {
      final Paint bolt = Paint()..color = const Color(0xFF2B2E30);
      for (final Offset o in [
        Offset(X(756), Y(722)),
        Offset(X(792), Y(722)),
        Offset(X(756), Y(770)),
        Offset(X(792), Y(770)),
      ]) {
        canvas.drawCircle(o, X(2.6), bolt);
        canvas.drawCircle(o.translate(-X(0.6), -X(0.6)), X(1), Paint()..color = Colors.white.withValues(alpha: 0.6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant DetailedMainFertilizerSourcePainter oldDelegate) {
    return oldDelegate.isOn != isOn ||
        oldDelegate.phase != phase ||
        oldDelegate.showJoints != showJoints;
  }
}

/// Stateful widget wrapper for DetailedMainFertilizerSourcePainter.
/// Use a square [size] (e.g. 300 x 300) to keep the photo's proportions.
class MainFertilizerSourceView extends StatefulWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  const MainFertilizerSourceView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    required this.size,
  });

  @override
  State<MainFertilizerSourceView> createState() => _MainFertilizerSourceViewState();
}

class _MainFertilizerSourceViewState extends State<MainFertilizerSourceView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 8));

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
      builder: (context, child) => CustomPaint(
        size: widget.size,
        painter: DetailedMainFertilizerSourcePainter(
          isOn: widget.isOn,
          phase: _c.value,
          showJoints: widget.showJoints,
        ),
      ),
    );
  }
}