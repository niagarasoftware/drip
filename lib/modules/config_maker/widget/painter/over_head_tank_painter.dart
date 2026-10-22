import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Overhead (elevated) tank – realistic stainless-steel glass-window tank on a
/// tall tubular steel tower. Same visual language as the Main Fertilizer
/// Source painter: brushed steel bands, glass sight window, lid + manway,
/// tri-clamp pipe couplings, rubber-padded feet.
///
/// Port positions (kept from the previous painter):
///   INLET   TOP-LEFT      pipe comes in from the left, drops onto the lid
///                         and pours into the tank through a nozzle.
///   OUTLET  BOTTOM-CENTRE pipe leaves the tank bottom and runs straight
///                         down the tower to grade.
///
/// [isOn]         pump filling: water pours from the inlet nozzle, ripples,
///                rising bubbles, flowing sheen in the inlet pipe, soft glow.
/// [isOutletOpen] water leaving through the outlet pipe (sheen + flow).
/// [phase]        0..1 looping animation driver.
/// [fillLevel]    0..1 water level (default 0.62).
///
/// Geometry is authored on a 1024 x 1280 grid (4:5). Use a 4:5 size,
/// e.g. Size(300, 375).
class DetailedOverheadTankPainter extends CustomPainter {
  final bool isOn;
  final bool isOutletOpen;
  final double phase;
  final bool showJoints;
  final double fillLevel;

  DetailedOverheadTankPainter({
    required this.isOn,
    this.isOutletOpen = false,
    this.phase = 0,
    this.showJoints = true,
    double? fillLevel,
  }) : fillLevel = (fillLevel ?? 0.62).clamp(0.03, 0.97);

  // ------------------------------------------------------------- geometry
  static const double _cx = 512;
  static const double _tankL = 140, _tankR = 884;
  static const double _lidY = 170; // lid ellipse centre
  static const double _topY = 210; // top of glass (ellipse centre)
  static const double _botY = 700; // bottom of glass (ellipse centre)
  static const double _baseY = 730; // bottom band lower ellipse centre
  static const double _tubeW = 26;
  static const double _inletX = 260;
  static const double _floorY = 1190;

  // ------------------------------------------------------------------ ports
  /// Top-left water inlet port.
  static Offset inletPort(Size s) => Offset(s.width * (20 / 1024), s.height * (80 / 1280));

  /// Bottom-centre outlet port (at grade).
  static Offset outletPort(Size s) => Offset(s.width * (512 / 1024), s.height * (1170 / 1280));

  // -------------------------------------------------------------- palette
  static const Color _edge = Color(0xFF263238);
  static const List<Color> _steel = [
    Color(0xFF7F898E),
    Color(0xFFE6EBED),
    Color(0xFFF7F9FA),
    Color(0xFFC3CBCF),
    Color(0xFF6C757A),
  ];
  static const List<double> _steelStops = [0, 0.22, 0.45, 0.78, 1];

  static const List<Color> _water = [
    Color(0xCC4DA3DF),
    Color(0xCC1A7BBF),
    Color(0xD90E5A93),
    Color(0xE6073860),
  ];
  static const Color _waterGlow = Color(0xFF00A2FF);

  // ----------------------------------------------------------------- paint
  @override
  void paint(Canvas canvas, Size size) {
    final _G g = _G(size.width, size.height);
    _drawGround(canvas, g);
    _drawStand(canvas, g);
    _drawLadder(canvas, g);
    if (isOn) _activeGlow(canvas, g);
    _drawTank(canvas, g);
    _drawBandsAndLid(canvas, g);
    _drawLegPlates(canvas, g);
    _drawPipes(canvas, g);
  }

  // --------------------------------------------------------------- helpers
  double _lerp(double a, double b, double t) => a + (b - a) * t;

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

  Paint _strokeP(Color c, double width, {StrokeCap cap = StrokeCap.butt}) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = cap
    ..strokeJoin = StrokeJoin.round
    ..color = c;

  void _bolt(Canvas c, Offset o, double r) {
    c.drawCircle(o, r, Paint()..color = const Color(0xFF3A4247));
    c.drawCircle(o.translate(-r * 0.3, -r * 0.3), r * 0.4, Paint()..color = Colors.white.withValues(alpha: 0.7));
  }

  double _liqY(_G g) => g.y(718 - 448 * fillLevel);

  // ----------------------------------------------------------------- ground
  void _drawGround(Canvas c, _G g) {
    c.drawOval(
      Rect.fromCenter(center: g.o(512, _floorY + 26), width: g.x(960), height: g.y(64)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.26)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.s(18)),
    );

    // concrete slab under the tower
    final Rect slab = g.r(110, _floorY + 2, 914, _floorY + 26);
    final RRect rr = RRect.fromRectAndRadius(slab, Radius.circular(g.s(4)));
    c.drawRRect(rr, _fillV(slab, const [Color(0xFFCFC9BA), Color(0xFF8E8676)]));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.5), 1));
    c.drawLine(slab.topLeft.translate(g.s(4), 1), slab.topRight.translate(-g.s(4), 1),
        _stroke(Colors.white.withValues(alpha: 0.45), 1.2));

    final math.Random agg = math.Random(41);
    c.save();
    c.clipRRect(rr);
    for (int i = 0; i < 90; i++) {
      final double x = slab.left + agg.nextDouble() * slab.width;
      final double y = slab.top + agg.nextDouble() * slab.height;
      c.drawCircle(Offset(x, y), (0.5 + agg.nextDouble() * 0.8) * g.u,
          Paint()..color = (agg.nextBool() ? Colors.white : Colors.black).withValues(alpha: 0.08));
    }
    c.restore();
  }

  // ------------------------------------------------------------------ stand
  void _rod(Canvas c, _G g, Offset a, Offset b, double w, {double dim = 0}) {
    final Path p = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
    c.drawPath(p.shift(Offset(g.s(2), g.s(4))), _strokeP(Colors.black.withValues(alpha: 0.18), g.s(w + 3)));
    c.drawPath(p, _strokeP(_edge.withValues(alpha: 0.8), g.s(w + 2.5)));
    c.drawPath(p, _strokeP(const Color(0xFFB0BABF), g.s(w)));
    if (dim > 0) c.drawPath(p, _strokeP(Colors.black.withValues(alpha: dim), g.s(w)));
    c.drawPath(
      p.shift(Offset(-g.s(w * 0.15), -g.s(w * 0.22))),
      _strokeP(Colors.white.withValues(alpha: 0.6 * (1 - dim)), g.s(w * 0.28), cap: StrokeCap.round),
    );
    c.drawPath(
      p.shift(Offset(g.s(w * 0.22), g.s(w * 0.24))),
      _strokeP(Colors.black.withValues(alpha: 0.16), g.s(w * 0.2)),
    );
  }

  void _foot(Canvas c, _G g, Offset p, double rx) {
    final Rect pad = Rect.fromCenter(center: p.translate(0, g.s(3)), width: g.s(rx * 2 + 6), height: g.s(rx * 0.62));
    c.drawOval(pad, Paint()..color = const Color(0xFF1C1F22));
    final Rect foot = Rect.fromCenter(center: p, width: g.s(rx * 2), height: g.s(rx * 0.55));
    c.drawOval(foot, _fillV(foot, const [Color(0xFFE6EBED), Color(0xFF8A949A)]));
    c.drawOval(foot, _stroke(_edge.withValues(alpha: 0.7), 1.1));
    if (showJoints) {
      _bolt(c, foot.center.translate(-g.s(rx * 0.55), 0), g.s(2.2));
      _bolt(c, foot.center.translate(g.s(rx * 0.55), 0), g.s(2.2));
    }
  }

  // Leg anchor points (t = 0 at the tank, 1 at grade).
  Offset _fl(_G g, double t) => g.o(_lerp(236, 186, t), _lerp(750, _floorY, t));
  Offset _fr(_G g, double t) => g.o(_lerp(788, 838, t), _lerp(750, _floorY, t));
  Offset _bl(_G g, double t) => g.o(_lerp(322, 290, t), _lerp(750, _floorY - 12, t));
  Offset _br(_G g, double t) => g.o(_lerp(702, 734, t), _lerp(750, _floorY - 12, t));

  void _drawStand(Canvas c, _G g) {
    const List<double> ts = [0.0, 0.27, 0.52, 0.76, 0.98];

    // back pair (depth) – dimmer and thinner
    _rod(c, g, _bl(g, 0), _bl(g, 1), 16, dim: 0.28);
    _rod(c, g, _br(g, 0), _br(g, 1), 16, dim: 0.28);
    for (int i = 1; i < ts.length; i++) {
      _rod(c, g, _bl(g, ts[i]), _br(g, ts[i]), 8, dim: 0.28);
    }
    _foot(c, g, _bl(g, 1), 24);
    _foot(c, g, _br(g, 1), 24);

    // X bracing between the front legs
    for (int i = 0; i < ts.length - 1; i++) {
      _rod(c, g, _fl(g, ts[i]), _fr(g, ts[i + 1]), 7);
      _rod(c, g, _fr(g, ts[i]), _fl(g, ts[i + 1]), 7);
    }
    // horizontal rings
    for (int i = 1; i < ts.length; i++) {
      _rod(c, g, _fl(g, ts[i]), _fr(g, ts[i]), 11);
    }

    // front legs
    _rod(c, g, _fl(g, 0), _fl(g, 1), 24);
    _rod(c, g, _fr(g, 0), _fr(g, 1), 24);
    _foot(c, g, _fl(g, 1), 36);
    _foot(c, g, _fr(g, 1), 36);

    if (showJoints) {
      for (int i = 1; i < ts.length - 1; i++) {
        _bolt(c, _fl(g, ts[i]), g.s(3));
        _bolt(c, _fr(g, ts[i]), g.s(3));
      }
    }
  }

  // ----------------------------------------------------------------- ladder
  void _drawLadder(Canvas c, _G g) {
    const double xl = 892, xr = 920;
    const double top = 772, bot = _floorY - 4;

    // brackets back to the right leg
    for (final double y in [840.0, 1040.0]) {
      final double t = (y - 750) / (_floorY - 750);
      _rod(c, g, g.o(_lerp(788, 838, t), y), g.o(xl, y), 6);
    }

    // rungs
    for (double y = top + 22; y < bot - 6; y += 30) {
      _rod(c, g, g.o(xl, y), g.o(xr, y), 4.5);
    }
    // rails
    _rod(c, g, g.o(xl, top), g.o(xl, bot), 8);
    _rod(c, g, g.o(xr, top), g.o(xr, bot), 8);
    // top handrail
    _rod(c, g, g.o(xl, top), g.o(xl - 6, top - 14), 6);
    _rod(c, g, g.o(xr, top), g.o(xr + 2, top - 14), 6);
  }

  // ------------------------------------------------------------------- glow
  void _activeGlow(Canvas c, _G g) {
    final double pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
    final RRect r = RRect.fromRectAndRadius(
      g.r(_tankL, 140, _tankR, 775).inflate(g.s(4)),
      Radius.circular(g.s(46)),
    );
    c.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.s(8 + 5 * pulse)
        ..color = _waterGlow.withValues(alpha: 0.30 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.s(18 + 8 * pulse)),
    );
  }

  // -------------------------------------------------------------- tank body
  void _drawTank(Canvas c, _G g) {
    final double liqY = _liqY(g);

    final Path vis = Path()
      ..moveTo(g.x(152), g.y(_topY))
      ..arcTo(Rect.fromCenter(center: g.o(512, _topY), width: g.x(720), height: g.y(80)), math.pi, -math.pi, false)
      ..lineTo(g.x(872), g.y(_botY))
      ..arcTo(Rect.fromCenter(center: g.o(512, _botY), width: g.x(720), height: g.y(80)), 0, math.pi, false)
      ..close();

    c.save();
    c.clipPath(vis);

    // inside back wall (brushed steel seen through the glass)
    final Rect bounds = g.r(140, _topY, 884, _botY + 44);
    c.drawRect(
      bounds,
      _fillH(bounds, const [
        Color(0xFF9FAAB0),
        Color(0xFFD3DCE0),
        Color(0xFFE9EFF1),
        Color(0xFFCBD5D9),
        Color(0xFF97A3A9),
      ], stops: const [0, 0.15, 0.5, 0.85, 1]),
    );
    final Rect under = g.r(140, _topY, 884, _topY + 100);
    c.drawRect(under, _fillV(under, [Colors.black.withValues(alpha: 0.22), Colors.transparent]));
    for (final double y in [370.0, 540.0]) {
      c.drawArc(
        Rect.fromCenter(center: g.o(512, y), width: g.x(720), height: g.y(80)),
        0,
        math.pi,
        false,
        _stroke(Colors.black.withValues(alpha: 0.07), 1.4),
      );
    }

    _drawLiquid(c, g, liqY);

    // inlet stub, nozzle and pouring stream
    _drawInletInside(c, g, liqY);

    // Glassy effect overlays over the clear window and water
    // 1. Crystal glass tint
    c.drawRect(bounds, Paint()..color = const Color(0xFFC6E7F8).withValues(alpha: 0.08));

    // 2. Left side specular curved highlight (cylinder glass refraction)
    final Rect gl = g.r(175, 215, 220, 705);
    c.drawRRect(
      RRect.fromRectAndRadius(gl, Radius.circular(g.s(12))),
      _fillH(gl, [
        Colors.white.withValues(alpha: 0.48),
        Colors.white.withValues(alpha: 0.12),
        Colors.transparent,
      ]),
    );

    // 3. Crisp vertical specular streak near left edge
    final Rect gl2 = g.r(226, 230, 232, 695);
    c.drawRRect(
      RRect.fromRectAndRadius(gl2, Radius.circular(g.s(3))),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // 4. Right side glass reflection
    final Rect gr = g.r(795, 215, 830, 705);
    c.drawRRect(
      RRect.fromRectAndRadius(gr, Radius.circular(g.s(10))),
      _fillH(gr, [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.12),
        Colors.white.withValues(alpha: 0.36),
      ]),
    );

    // 5. Top & bottom curved glass cylinder inner edge highlights
    final Rect topGlassArc = Rect.fromCenter(center: g.o(512, _topY + 6), width: g.x(716), height: g.y(76));
    c.drawArc(topGlassArc, 0, math.pi, false, _stroke(Colors.white.withValues(alpha: 0.45), 2.0));

    final Rect botGlassArc = Rect.fromCenter(center: g.o(512, _botY - 6), width: g.x(716), height: g.y(76));
    c.drawArc(botGlassArc, math.pi, math.pi, false, _stroke(Colors.white.withValues(alpha: 0.35), 1.8));

    c.restore();

    // steel frame strips of the cylinder
    final Rect sl = g.r(_tankL, _topY - 2, 166, _botY + 4);
    c.drawRect(sl, _fillH(sl, const [Color(0xFF6F787D), Color(0xFFE2E8EA), Color(0xFF9AA4A9)]));
    c.drawRect(sl, _stroke(_edge.withValues(alpha: 0.4), 1));
    final Rect sr = g.r(858, _topY - 2, _tankR, _botY + 4);
    c.drawRect(sr, _fillH(sr, const [Color(0xFF9AA4A9), Color(0xFFE2E8EA), Color(0xFF6F787D)]));
    c.drawRect(sr, _stroke(_edge.withValues(alpha: 0.4), 1));
    c.drawLine(g.o(166, _topY + 6), g.o(166, _botY), _stroke(Colors.black.withValues(alpha: 0.45), 1.6));
    c.drawLine(g.o(858, _topY + 6), g.o(858, _botY), _stroke(Colors.black.withValues(alpha: 0.45), 1.6));
  }

  void _drawLiquid(Canvas c, _G g, double liqY) {
    final double bottom = g.y(752);
    const List<Color> pal = _water;

    final Path body = Path()..moveTo(g.x(152), liqY);
    for (double x = 152; x <= 872; x += 4) {
      final double t = (x - _cx) / 360;
      final double arc = 40 * math.sqrt(math.max(0.0, 1 - t * t));
      body.lineTo(g.x(x), liqY + g.y(arc));
    }
    body
      ..lineTo(g.x(872), bottom)
      ..lineTo(g.x(152), bottom)
      ..close();

    final Rect lr = Rect.fromLTRB(g.x(152), liqY, g.x(872), bottom);
    c.drawPath(body, _fillV(lr, pal, stops: const [0, 0.08, 0.5, 1]));

    // refraction darkening at the sides
    c.drawRect(
      lr,
      _fillH(lr, [
        Colors.black.withValues(alpha: 0.22),
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: 0.22),
      ], stops: const [0, 0.16, 0.84, 1]),
    );

    // surface ellipse with glossy reflection
    final Rect surf = Rect.fromCenter(center: Offset(g.x(_cx), liqY), width: g.x(720), height: g.y(80));
    c.drawOval(surf, _fillV(surf, [pal[0].withValues(alpha: 0.90), pal[1].withValues(alpha: 0.85)]));
    final double sheenShift = 28 * math.sin(phase * 2 * math.pi);
    c.drawOval(
      Rect.fromCenter(center: Offset(g.x(_cx - 100 + sheenShift), liqY - g.y(5)), width: g.x(380), height: g.y(30)),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    c.drawOval(surf, _stroke(Colors.white.withValues(alpha: 0.6), 1.6));
    c.drawArc(surf, 0, math.pi, false, _stroke(Colors.white.withValues(alpha: 0.4), 1.4));

    // Meniscus highlights where water surface meets the glass wall
    c.drawCircle(Offset(g.x(152), liqY), g.s(3), Paint()..color = Colors.white.withValues(alpha: 0.7));
    c.drawCircle(Offset(g.x(872), liqY), g.s(3), Paint()..color = Colors.white.withValues(alpha: 0.7));
  }

  void _drawInletInside(Canvas c, _G g, double liqY) {
    final Offset n = g.o(_inletX, 290);

    // drop pipe coming through the lid
    final Rect stub = g.r(_inletX - 9, 226, _inletX + 9, 272);
    c.drawRect(stub, _fillH(stub, _steel, stops: _steelStops));
    c.drawRect(stub, _stroke(_edge.withValues(alpha: 0.6), 1));

    // pouring stream
    if (isOn) {
      final double y0 = n.dy + g.s(12);
      final double y1 = liqY;
      if (y1 - y0 > g.s(24)) {
        final double sw = g.s(15);
        final Rect sr = Rect.fromLTRB(n.dx - sw / 2, y0, n.dx + sw / 2, y1);
        c.drawRect(
          sr,
          _fillH(sr, [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.70),
            Colors.white.withValues(alpha: 0.12),
          ]),
        );
        final Paint streak = _strokeP(Colors.white.withValues(alpha: 0.85), g.s(1.6), cap: StrokeCap.round);
        for (int i = 0; i < 6; i++) {
          final double t = (phase * 1.8 + i / 6) % 1.0;
          final double sy = y0 + (y1 - y0) * t;
          final double dx = ((i % 3) - 1) * sw * 0.22;
          c.drawLine(Offset(n.dx + dx, sy), Offset(n.dx + dx, math.min(y1, sy + g.s(26))), streak);
        }
        // splash rings where the stream lands
        for (int k = 0; k < 3; k++) {
          final double t = (phase + k / 3) % 1.0;
          final double rr = g.s(10 + 70 * t);
          c.drawOval(
            Rect.fromCenter(center: Offset(n.dx, y1), width: rr * 2, height: rr * 0.55),
            _stroke(Colors.white.withValues(alpha: 0.55 * (1 - t)), 1.4),
          );
        }
      }
    }

    // nozzle head
    final Path head = Path()
      ..moveTo(n.dx - g.s(10), n.dy - g.s(22))
      ..lineTo(n.dx + g.s(10), n.dy - g.s(22))
      ..lineTo(n.dx + g.s(26), n.dy + g.s(4))
      ..quadraticBezierTo(n.dx, n.dy + g.s(14), n.dx - g.s(26), n.dy + g.s(4))
      ..close();
    c.drawPath(head, _fillH(head.getBounds(), _steel, stops: _steelStops));
    c.drawPath(head, _stroke(_edge.withValues(alpha: 0.7), 1.1));
    for (int i = -2; i <= 2; i++) {
      c.drawCircle(
        Offset(n.dx + i * g.s(8), n.dy + g.s(7) - i.abs() * g.s(1.3)),
        g.s(1.7),
        Paint()..color = const Color(0xFF263238),
      );
    }
  }

  // ------------------------------------------------------- bands, lid, cap
  double _bandBottomY(double x) {
    final double u = ((x - _cx) / 372).clamp(-1.0, 1.0);
    return _baseY + 42 * math.sqrt(1 - u * u);
  }

  void _drawBandsAndLid(Canvas c, _G g) {
    // top band
    final Rect topEll = Rect.fromCenter(center: g.o(512, _topY), width: g.x(744), height: g.y(84));
    final Rect lidEll = Rect.fromCenter(center: g.o(512, _lidY), width: g.x(744), height: g.y(84));
    final Path top = Path()
      ..moveTo(g.x(_tankL), g.y(_lidY))
      ..lineTo(g.x(_tankL), g.y(_topY))
      ..arcTo(topEll, math.pi, -math.pi, false)
      ..lineTo(g.x(_tankR), g.y(_lidY))
      ..arcTo(lidEll, 0, -math.pi, false)
      ..close();
    final Rect tb = g.r(_tankL, 125, _tankR, 260);
    c.drawPath(top, _fillH(tb, _steel, stops: _steelStops));
    c.drawPath(top, _fillV(tb, [Colors.transparent, Colors.black.withValues(alpha: 0.18)]));
    c.drawPath(top, _stroke(_edge.withValues(alpha: 0.55), 1.3));
    c.drawArc(topEll, 0, math.pi, false, _stroke(Colors.white.withValues(alpha: 0.55), 1.6));
    c.drawArc(
      Rect.fromCenter(center: g.o(512, _topY - 12), width: g.x(744), height: g.y(84)),
      0,
      math.pi,
      false,
      _stroke(Colors.black.withValues(alpha: 0.12), 1.6),
    );

    // bottom band
    final Rect botEll = Rect.fromCenter(center: g.o(512, _botY), width: g.x(744), height: g.y(84));
    final Rect baseEll = Rect.fromCenter(center: g.o(512, _baseY), width: g.x(744), height: g.y(84));
    final Path bot = Path()
      ..moveTo(g.x(_tankL), g.y(_botY))
      ..arcTo(botEll, math.pi, -math.pi, false)
      ..lineTo(g.x(_tankR), g.y(_baseY))
      ..arcTo(baseEll, 0, math.pi, false)
      ..close();
    final Rect bb = g.r(_tankL, _botY, _tankR, _baseY + 50);
    c.drawPath(bot, _fillH(bb, _steel, stops: _steelStops));
    c.drawPath(bot, _fillV(bb, [Colors.transparent, Colors.black.withValues(alpha: 0.24)]));
    c.drawPath(bot, _stroke(_edge.withValues(alpha: 0.6), 1.3));
    c.drawArc(botEll, 0, math.pi, false, _stroke(Colors.white.withValues(alpha: 0.6), 1.6));

    // lid
    c.drawOval(
      lidEll,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFF4F7F8), Color(0xFFCFD6DA), Color(0xFF9AA4A9)],
          stops: [0, 0.65, 1],
        ).createShader(lidEll),
    );
    for (int i = 1; i <= 5; i++) {
      c.drawOval(
        Rect.fromCenter(center: g.o(512, _lidY), width: g.x(744 - i * 100), height: g.y(84 - i * 11)),
        _stroke(Colors.black.withValues(alpha: 0.035), 1.0),
      );
    }
    c.drawOval(lidEll, _stroke(_edge.withValues(alpha: 0.6), 1.4));
    final Rect ring = Rect.fromCenter(center: g.o(512, _lidY), width: g.x(670), height: g.y(68));
    c.drawOval(ring, _stroke(Colors.black.withValues(alpha: 0.18), 1.4));
    c.drawOval(ring.shift(Offset(0, g.s(1.4))), _stroke(Colors.white.withValues(alpha: 0.6), 1.2));
    if (showJoints) {
      for (int i = 0; i < 18; i++) {
        final double a = i * 2 * math.pi / 18;
        _bolt(c, g.o(512 + 346 * math.cos(a), _lidY + 35 * math.sin(a)), g.s(2.6));
      }
    }

    _drawVent(c, g);
    _drawManway(c, g);
  }

  void _drawVent(Canvas c, _G g) {
    const double x = 690;
    // base flange
    final Rect fl = Rect.fromCenter(center: g.o(x, 180), width: g.x(34), height: g.y(10));
    c.drawOval(fl, _fillV(fl, const [Color(0xFFF7F9FA), Color(0xFF8A949A)]));
    c.drawOval(fl, _stroke(_edge.withValues(alpha: 0.7), 1));
    // tube
    final Rect tube = g.r(x - 8, 134, x + 8, 180);
    c.drawRect(tube, _fillH(tube, _steel, stops: _steelStops));
    c.drawRect(tube, _stroke(_edge.withValues(alpha: 0.6), 1));
    // mushroom cap
    final Rect cap = Rect.fromCenter(center: g.o(x, 134), width: g.x(46), height: g.y(14));
    c.drawOval(cap.shift(Offset(0, g.s(3))), Paint()..color = Colors.black.withValues(alpha: 0.2));
    c.drawOval(cap, _fillV(cap, const [Color(0xFFF7F9FA), Color(0xFFA9B3B8)]));
    c.drawOval(cap, _stroke(_edge.withValues(alpha: 0.65), 1.1));
  }

  void _drawManway(Canvas c, _G g) {
    c.drawOval(
      Rect.fromCenter(center: g.o(512, 170), width: g.x(122), height: g.y(30)),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    final Rect mb = g.r(459, 146, 565, 168);
    c.drawRect(mb, _fillH(mb, _steel, stops: _steelStops));
    c.drawOval(
      Rect.fromCenter(center: g.o(512, 168), width: g.x(106), height: g.y(24)),
      _fillV(g.r(459, 156, 565, 180), const [Color(0xFFB9C2C6), Color(0xFF7F898E)]),
    );
    final Rect mt = Rect.fromCenter(center: g.o(512, 146), width: g.x(106), height: g.y(24));
    c.drawOval(mt, _fillV(mt, const [Color(0xFFF7F9FA), Color(0xFFB5BEC3)]));
    c.drawOval(mt, _stroke(_edge.withValues(alpha: 0.6), 1.2));
    c.drawOval(
      Rect.fromCenter(center: g.o(512, 146), width: g.x(66), height: g.y(13)),
      _stroke(Colors.black.withValues(alpha: 0.25), 1.2),
    );
    if (showJoints) {
      for (int i = 0; i < 9; i++) {
        final double a = i * 2 * math.pi / 9;
        _bolt(c, g.o(512 + 44 * math.cos(a), 146 + 8.5 * math.sin(a)), g.s(2));
      }
    }
  }

  /// Small steel plates where each leg is fixed under the tank.
  void _drawLegPlates(Canvas c, _G g) {
    for (final double x in [236.0, 322.0, 702.0, 788.0]) {
      final double y = _bandBottomY(x) + 2;
      final Rect r = Rect.fromCenter(center: g.o(x, y), width: g.x(52), height: g.y(14));
      final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(g.s(3)));
      c.drawRRect(rr.shift(Offset(g.s(1.5), g.s(3))), Paint()..color = Colors.black.withValues(alpha: 0.22));
      c.drawRRect(rr, _fillV(r, _steel, stops: _steelStops));
      c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.75), 1.1));
      if (showJoints) {
        _bolt(c, r.center.translate(-g.s(16), 0), g.s(2));
        _bolt(c, r.center.translate(g.s(16), 0), g.s(2));
      }
    }
  }

  // ------------------------------------------------------------------- pipes
  /// Inlet – TOP LEFT: runs in from the left edge and drops onto the lid.
  Path _inletPath(_G g) => Path()
    ..moveTo(g.x(20), g.y(80))
    ..lineTo(g.x(_inletX - 30), g.y(80))
    ..quadraticBezierTo(g.x(_inletX), g.y(80), g.x(_inletX), g.y(110))
    ..lineTo(g.x(_inletX), g.y(160));

  /// Outlet – BOTTOM CENTRE: leaves the tank bottom and runs down to grade.
  Path _outletPath(_G g) => Path()
    ..moveTo(g.x(512), g.y(770))
    ..lineTo(g.x(512), g.y(1170));

  void _tube(Canvas c, _G g, Path p) {
    final double wp = g.s(_tubeW);
    c.drawPath(p.shift(Offset(g.s(2), g.s(5))), _strokeP(Colors.black.withValues(alpha: 0.22), wp + g.s(4)));
    c.drawPath(p, _strokeP(_edge, wp + g.s(3)));
    c.drawPath(p, _strokeP(const Color(0xFFAEB8BD), wp));
    c.drawPath(
      p.shift(Offset(-wp * 0.12, -wp * 0.15)),
      _strokeP(const Color(0xFFE8EDEF).withValues(alpha: 0.85), wp * 0.45),
    );
    c.drawPath(
      p.shift(Offset(-wp * 0.18, -wp * 0.22)),
      _strokeP(Colors.white.withValues(alpha: 0.95), wp * 0.13, cap: StrokeCap.round),
    );
    c.drawPath(
      p.shift(Offset(wp * 0.22, wp * 0.24)),
      _strokeP(Colors.black.withValues(alpha: 0.18), wp * 0.2),
    );
  }

  /// Soft tinted sheen inside an active pipe plus moving flow dashes.
  void _active(Canvas c, _G g, Path p, Color col) {
    final double wp = g.s(_tubeW);
    c.drawPath(p, _strokeP(col.withValues(alpha: 0.32), wp * 0.5, cap: StrokeCap.round));

    final double period = g.s(110);
    final double seg = g.s(42);
    for (final m in p.computeMetrics()) {
      for (double d = (phase * period) % period - period; d < m.length; d += period) {
        final double a = math.max(0.0, d);
        final double b = math.min(m.length, d + seg);
        if (b > a) {
          c.drawPath(m.extractPath(a, b), _strokeP(Colors.white.withValues(alpha: 0.55), wp * 0.28, cap: StrokeCap.round));
        }
      }
    }
  }

  void _clamps(Canvas c, _G g, Path p, List<double> fractions) {
    final double s = g.u;
    for (final m in p.computeMetrics()) {
      for (final double f in fractions) {
        final t = m.getTangentForOffset(m.length * f);
        if (t == null) continue;
        final double a = math.atan2(t.vector.dy, t.vector.dx);
        c.save();
        c.translate(t.position.dx, t.position.dy);
        c.rotate(a);
        final double hh = (_tubeW / 2 + 6) * s;

        for (final double ox in [-8.0, 8.0]) {
          final Rect fr = Rect.fromLTRB((ox - 2.5) * s, -hh, (ox + 2.5) * s, hh);
          final RRect frr = RRect.fromRectAndRadius(fr, Radius.circular(1.5 * s));
          c.drawRRect(frr.shift(Offset(1.2 * s, 2 * s)), Paint()..color = Colors.black.withValues(alpha: 0.22));
          c.drawRRect(frr, _fillV(fr, _steel, stops: _steelStops));
          c.drawRRect(frr, _stroke(_edge.withValues(alpha: 0.7), 1));
        }
        final double bh = (_tubeW / 2 + 4) * s;
        final Rect band = Rect.fromLTRB(-6 * s, -bh, 6 * s, bh);
        final RRect brr = RRect.fromRectAndRadius(band, Radius.circular(2 * s));
        c.drawRRect(brr, _fillV(band, _steel, stops: _steelStops));
        c.drawRRect(brr, _stroke(_edge.withValues(alpha: 0.75), 1));
        c.drawCircle(Offset(0, -bh - 1 * s), 4 * s, Paint()..color = const Color(0xFFCDD5D9));
        c.drawCircle(Offset(0, -bh - 1 * s), 4 * s, _stroke(_edge.withValues(alpha: 0.75), 1));
        c.restore();
      }
    }
  }

  void _endFlange(Canvas c, _G g, Path p, {required bool atStart}) {
    final double s = g.u;
    final m = p.computeMetrics().first;
    final t = m.getTangentForOffset(atStart ? 0 : m.length);
    if (t == null) return;
    final double a = math.atan2(t.vector.dy, t.vector.dx);
    c.save();
    c.translate(t.position.dx, t.position.dy);
    c.rotate(a);
    final Rect r = Rect.fromLTRB(-6 * s, -25 * s, 6 * s, 25 * s);
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(3 * s));
    c.drawRRect(rr.shift(Offset(1.5 * s, 2.5 * s)), Paint()..color = Colors.black.withValues(alpha: 0.22));
    c.drawRRect(rr, _fillV(r, _steel, stops: _steelStops));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.75), 1.1));
    if (showJoints) {
      _bolt(c, Offset(0, -17 * s), 2.2 * s);
      _bolt(c, Offset(0, 17 * s), 2.2 * s);
    }
    c.restore();
  }

  void _ovalFlange(Canvas c, _G g, double x, double y) {
    final Rect r = Rect.fromCenter(center: g.o(x, y), width: g.x(56), height: g.y(16));
    c.drawOval(r.shift(Offset(g.s(2), g.s(3))), Paint()..color = Colors.black.withValues(alpha: 0.22));
    c.drawOval(r, _fillV(r, const [Color(0xFFF7F9FA), Color(0xFF8A949A)]));
    c.drawOval(r, _stroke(_edge.withValues(alpha: 0.7), 1.1));
    if (showJoints) {
      _bolt(c, g.o(x - 20, y), g.s(2.2));
      _bolt(c, g.o(x + 20, y), g.s(2.2));
    }
  }

  void _drawPipes(Canvas c, _G g) {
    final Path inlet = _inletPath(g);
    final Path outlet = _outletPath(g);

    _tube(c, g, inlet);
    _tube(c, g, outlet);

    if (isOn) _active(c, g, inlet, const Color(0xFF63C7F2));
    if (isOutletOpen && fillLevel > 0.04) _active(c, g, outlet, const Color(0xFF1F8FD1));

    _clamps(c, g, inlet, const [0.28, 0.6]);
    _clamps(c, g, outlet, const [0.22, 0.5, 0.78]);

    _endFlange(c, g, inlet, atStart: true);
    _endFlange(c, g, outlet, atStart: false);

    _ovalFlange(c, g, _inletX, 164); // inlet meets the lid
    _ovalFlange(c, g, 512, 770); // outlet leaves the tank bottom
  }

  @override
  bool shouldRepaint(covariant DetailedOverheadTankPainter old) {
    return old.isOn != isOn ||
        old.isOutletOpen != isOutletOpen ||
        old.phase != phase ||
        old.showJoints != showJoints ||
        old.fillLevel != fillLevel;
  }
}

/// 1024 x 1280 grid helper.
class _G {
  final double u, v;
  _G(double w, double h)
      : u = w / 1024,
        v = h / 1280;
  double x(double p) => p * u;
  double y(double p) => p * v;
  double s(double p) => p * u;
  Offset o(double px, double py) => Offset(px * u, py * v);
  Rect r(double l, double t, double rr, double b) => Rect.fromLTRB(l * u, t * v, rr * u, b * v);
}

/// Drop-in widget: animates the pour, ripples, bubbles and pipe flow while
/// [isOn] (or [isOutletOpen]) is true.
///
/// ```dart
/// OverheadTankView(
///   size: const Size(300, 375), // keep 4:5
///   isOn: pumpRunning,
///   isOutletOpen: supplying,
///   fillLevel: tankLevel, // 0..1
/// )
/// ```
class OverheadTankView extends StatefulWidget {
  final bool isOn;
  final bool isOutletOpen;
  final bool showJoints;
  final double? fillLevel;
  final Size size;

  const OverheadTankView({
    super.key,
    required this.isOn,
    this.isOutletOpen = false,
    this.showJoints = true,
    this.fillLevel,
    this.size = const Size(300, 375),
  });

  @override
  State<OverheadTankView> createState() => _OverheadTankViewState();
}

class _OverheadTankViewState extends State<OverheadTankView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(seconds: 3));

  bool get _animate => widget.isOn || widget.isOutletOpen;

  @override
  void initState() {
    super.initState();
    if (_animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant OverheadTankView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!_animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: widget.size,
          painter: DetailedOverheadTankPainter(
            isOn: widget.isOn,
            isOutletOpen: widget.isOutletOpen,
            phase: _controller.value,
            showJoints: widget.showJoints,
            fillLevel: widget.fillLevel,
          ),
        ),
      ),
    );
  }
}