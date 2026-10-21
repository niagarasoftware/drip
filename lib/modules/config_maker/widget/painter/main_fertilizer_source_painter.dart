import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Main Fertilizer Source – realistic stainless-steel mixing tank (static).
///
/// - Stainless cylinder tank with glass sight window, lid and manway
/// - Tubular steel stand with rubber-padded feet
/// - Pipe lines with tri-clamp couplings (no valves, no text, no animation)
///     TOP-LEFT     fresh water inlet
///     BOTTOM-LEFT  dirty drain
///     BOTTOM-RIGHT outlet to sub tanks
///
/// State is shown only through the liquid colour and a soft sheen inside the
/// active pipe:
///   [isOn]           nutrient green liquid
///   [isFlushing]     clear rinse-water look, fresh-water pipe active, spray
///   [isDraining]     murky dirty-water look, drain pipe active
///   [isDistributing] outlet pipe active
///   [level]          0..1 liquid level
///
/// Geometry is authored on a 1024 x 1024 grid; use a square size.
class DetailedMainFertilizerSourcePainter extends CustomPainter {
  final bool isOn;
  final bool isFlushing;
  final bool isDraining;
  final bool isDistributing;
  final double level;
  final bool showJoints;

  DetailedMainFertilizerSourcePainter({
    required this.isOn,
    bool isCleaning = false,
    bool? isFlushing,
    bool? isDraining,
    this.isDistributing = false,
    this.level = 0.75,
    this.showJoints = true,
  })  : isFlushing = isFlushing ?? isCleaning,
        isDraining = isDraining ?? isCleaning;

  // ------------------------------------------------------------- geometry
  static const double _cx = 512;
  static const double _tankL = 250, _tankR = 774;
  static const double _lidY = 215;
  static const double _tubeW = 26;
  static const double _freshX = 330;
  static const double _floorY = 858;

  // ------------------------------------------------------------------ ports
  /// Top-left water inlet port.
  static Offset waterInletPort(Size s) =>
      Offset(s.width * (20 / 1024), s.height * (90 / 1024));

  /// Bottom-left water outlet / drain port.
  static Offset waterOutletPort(Size s) =>
      Offset(s.width * (40 / 1024), s.height * (845 / 1024));

  /// Bottom-right fertilizer outlet port.
  static Offset fertOutletPort(Size s) =>
      Offset(s.width * (1000 / 1024), s.height * (845 / 1024));

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

  List<Color> _palette() {
    if (isDraining) {
      return const [Color(0xFFDDE6B8), Color(0xFFA3B86F), Color(0xFF72894C), Color(0xFF45572C)];
    }
    if (isFlushing) {
      return const [Color(0xFFE1F5FE), Color(0xFF64C8F5), Color(0xFF2B95D6), Color(0xFF16639F)];
    }
    return const [Color(0xFFA6E59A), Color(0xFF55BB52), Color(0xFF34933F), Color(0xFF1E6B2C)];
  }

  // ----------------------------------------------------------------- paint
  @override
  void paint(Canvas canvas, Size size) {
    final _G g = _G(size.width, size.height);
    _drawGroundShadow(canvas, g);
    _drawStand(canvas, g);
    _drawTank(canvas, g);
    _drawBandsAndLid(canvas, g);
    _drawPipes(canvas, g);
  }

  // --------------------------------------------------------------- helpers
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

  void _droplet(Canvas c, Offset o, double r, double a) {
    c.drawCircle(o, r, Paint()..color = Colors.white.withValues(alpha: 0.16 * a));
    c.drawCircle(o, r, _stroke(const Color(0xFF0B3A5A).withValues(alpha: 0.30 * a), 0.9));
    c.drawCircle(
      o.translate(-r * 0.35, -r * 0.35),
      r * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.85 * a),
    );
  }

  double _liqY(_G g) => g.y(688 - 380 * level.clamp(0.0, 1.0));

  // ---------------------------------------------------------- ground shadow
  void _drawGroundShadow(Canvas c, _G g) {
    c.drawOval(
      Rect.fromCenter(center: g.o(512, _floorY), width: g.x(900), height: g.y(60)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.26)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.s(18)),
    );
    // darker contact shadow under tank / stand
    c.drawOval(
      Rect.fromCenter(center: g.o(512, 846), width: g.x(560), height: g.y(34)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.s(10)),
    );
  }

  // ------------------------------------------------------------------ stand
  void _rod(Canvas c, _G g, Offset a, Offset b, double w) {
    final Path p = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
    c.drawPath(p.shift(Offset(g.s(2), g.s(4))), _strokeP(Colors.black.withValues(alpha: 0.18), g.s(w + 3)));
    c.drawPath(p, _strokeP(_edge.withValues(alpha: 0.8), g.s(w + 2.5)));
    c.drawPath(p, _strokeP(const Color(0xFFB0BABF), g.s(w)));
    c.drawPath(
      p.shift(Offset(-g.s(w * 0.15), -g.s(w * 0.22))),
      _strokeP(Colors.white.withValues(alpha: 0.6), g.s(w * 0.28), cap: StrokeCap.round),
    );
    c.drawPath(
      p.shift(Offset(g.s(w * 0.22), g.s(w * 0.24))),
      _strokeP(Colors.black.withValues(alpha: 0.16), g.s(w * 0.2)),
    );
  }

  void _leg(Canvas c, _G g, double x, double yTop, double yBot, double w, double footRx) {
    final Rect r = g.r(x - w / 2, yTop, x + w / 2, yBot);
    c.drawRect(r.shift(Offset(g.s(4), g.s(2))), Paint()..color = Colors.black.withValues(alpha: 0.14));
    c.drawRect(r, _fillH(r, _steel, stops: _steelStops));
    c.drawRect(r, _stroke(_edge.withValues(alpha: 0.55), 1));
    // top ambient occlusion from the tank above
    c.drawRect(
      Rect.fromLTRB(r.left, r.top, r.right, r.top + g.y(26)),
      _fillV(Rect.fromLTRB(r.left, r.top, r.right, r.top + g.y(26)),
          [Colors.black.withValues(alpha: 0.35), Colors.transparent]),
    );

    // rubber pad
    final Rect pad = Rect.fromCenter(center: g.o(x, yBot + 3), width: g.s(footRx * 2 + 6), height: g.s(footRx * 0.62));
    c.drawOval(pad, Paint()..color = const Color(0xFF1C1F22));
    // steel foot plate
    final Rect foot = Rect.fromCenter(center: g.o(x, yBot), width: g.s(footRx * 2), height: g.s(footRx * 0.55));
    c.drawOval(foot, _fillV(foot, const [Color(0xFFE6EBED), Color(0xFF8A949A)]));
    c.drawOval(foot, _stroke(_edge.withValues(alpha: 0.7), 1.1));
    if (showJoints) {
      _bolt(c, foot.center.translate(-g.s(footRx * 0.55), 0), g.s(2.2));
      _bolt(c, foot.center.translate(g.s(footRx * 0.55), 0), g.s(2.2));
    }
  }

  void _drawStand(Canvas c, _G g) {
    _leg(c, g, 390, 716, 812, 18, 26);
    _leg(c, g, 634, 716, 812, 18, 26);
    _rod(c, g, g.o(390, 772), g.o(634, 772), 12);
    _rod(c, g, g.o(300, 800), g.o(390, 772), 12);
    _rod(c, g, g.o(724, 800), g.o(634, 772), 12);
    _leg(c, g, 300, 700, 852, 24, 34);
    _leg(c, g, 724, 700, 852, 24, 34);
    _rod(c, g, g.o(300, 800), g.o(724, 800), 14);
    _rod(c, g, g.o(300, 830), g.o(390, 806), 10);
    _rod(c, g, g.o(724, 830), g.o(634, 806), 10);
  }

  // -------------------------------------------------------------- tank body
  void _drawTank(Canvas c, _G g) {
    final double lv = level.clamp(0.0, 1.0);
    final double liqY = _liqY(g);
    final List<Color> pal = _palette();

    final Path vis = Path()
      ..moveTo(g.x(262), g.y(248))
      ..arcTo(Rect.fromCenter(center: g.o(512, 248), width: g.x(500), height: g.y(56)), math.pi, -math.pi, false)
      ..lineTo(g.x(762), g.y(668))
      ..arcTo(Rect.fromCenter(center: g.o(512, 668), width: g.x(500), height: g.y(56)), 0, math.pi, false)
      ..close();

    c.save();
    c.clipPath(vis);

    // inside back wall (brushed steel seen through glass)
    final Rect bounds = g.r(250, 248, 774, 700);
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
    // soft shadow just under the top band
    final Rect under = g.r(250, 248, 774, 340);
    c.drawRect(under, _fillV(under, [Colors.black.withValues(alpha: 0.22), Colors.transparent]));
    // inside weld seam rings on the back wall
    for (final double y in [380.0, 520.0]) {
      c.drawArc(
        Rect.fromCenter(center: g.o(512, y), width: g.x(500), height: g.y(56)),
        0,
        math.pi,
        false,
        _stroke(Colors.black.withValues(alpha: 0.07), 1.4),
      );
    }

    if (lv > 0.01) _drawLiquid(c, g, liqY, pal);

    // fresh-water nozzle + static spray (flushing)
    _drawNozzle(c, g, liqY);

    // condensation on the inner glass
    final math.Random rnd = math.Random(42);
    for (int i = 0; i < 26; i++) {
      final double dx = g.x(290 + rnd.nextDouble() * 450);
      final double dy = g.y(290 + rnd.nextDouble() * 360);
      _droplet(c, Offset(dx, dy), (1.5 + math.pow(rnd.nextDouble(), 2) * 4.5) * g.u, 0.7);
    }

    // faint glass tint + reflections
    c.drawRect(bounds, Paint()..color = const Color(0xFFB7D9EA).withValues(alpha: 0.06));
    final Rect gl = g.r(298, 270, 314, 650);
    c.drawRRect(RRect.fromRectAndRadius(gl, Radius.circular(g.s(8))),
        _fillV(gl, [Colors.white.withValues(alpha: 0.36), Colors.white.withValues(alpha: 0.03)]));
    final Rect gr = g.r(716, 270, 726, 650);
    c.drawRRect(RRect.fromRectAndRadius(gr, Radius.circular(g.s(5))),
        _fillV(gr, [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.02)]));
    c.drawPath(
      Path()
        ..moveTo(g.x(420), g.y(270))
        ..lineTo(g.x(500), g.y(270))
        ..lineTo(g.x(380), g.y(660))
        ..lineTo(g.x(330), g.y(660))
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );

    c.restore();

    // steel frame strips of the cylinder
    final Rect sl = g.r(_tankL, 246, 276, 672);
    c.drawRect(sl, _fillH(sl, const [Color(0xFF6F787D), Color(0xFFE2E8EA), Color(0xFF9AA4A9)]));
    c.drawRect(sl, _stroke(_edge.withValues(alpha: 0.4), 1));
    final Rect sr = g.r(748, 246, _tankR, 672);
    c.drawRect(sr, _fillH(sr, const [Color(0xFF9AA4A9), Color(0xFFE2E8EA), Color(0xFF6F787D)]));
    c.drawRect(sr, _stroke(_edge.withValues(alpha: 0.4), 1));
    // rubber gasket lines where glass meets steel
    c.drawLine(g.o(276, 252), g.o(276, 668), _stroke(Colors.black.withValues(alpha: 0.45), 1.6));
    c.drawLine(g.o(748, 252), g.o(748, 668), _stroke(Colors.black.withValues(alpha: 0.45), 1.6));
  }

  void _drawLiquid(Canvas c, _G g, double liqY, List<Color> pal) {
    final double bottom = g.y(704);

    final Path body = Path()..moveTo(g.x(262), liqY);
    for (double x = 262; x <= 762; x += 4) {
      final double t = (x - _cx) / 250;
      final double arc = 28 * math.sqrt(math.max(0.0, 1 - t * t));
      body.lineTo(g.x(x), liqY + g.y(arc));
    }
    body
      ..lineTo(g.x(762), bottom)
      ..lineTo(g.x(262), bottom)
      ..close();

    final Rect lr = Rect.fromLTRB(g.x(262), liqY, g.x(762), bottom);
    c.drawPath(body, _fillV(lr, pal, stops: const [0, 0.08, 0.5, 1]));

    // refraction darkening at the sides
    c.drawRect(
      lr,
      _fillH(lr, [
        Colors.black.withValues(alpha: 0.30),
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: 0.30),
      ], stops: const [0, 0.16, 0.84, 1]),
    );

    // soft light shafts
    final Paint shaft = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (final double sx in [380.0, 600.0]) {
      c.drawPath(
        Path()
          ..moveTo(g.x(sx), liqY)
          ..lineTo(g.x(sx + 50), liqY)
          ..lineTo(g.x(sx - 30), bottom)
          ..lineTo(g.x(sx - 110), bottom)
          ..close(),
        shaft,
      );
    }

    // surface ellipse
    final Rect surf = Rect.fromCenter(center: Offset(g.x(_cx), liqY), width: g.x(500), height: g.y(56));
    c.drawOval(surf, _fillV(surf, [pal[0].withValues(alpha: 0.96), pal[1].withValues(alpha: 0.96)]));
    c.drawOval(
      Rect.fromCenter(center: Offset(g.x(_cx - 60), liqY - g.y(4)), width: g.x(260), height: g.y(22)),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    c.drawOval(surf, _stroke(Colors.white.withValues(alpha: 0.5), 1.6));

    // meniscus line along the front edge
    c.drawArc(surf, 0, math.pi, false, _stroke(Colors.white.withValues(alpha: 0.35), 1.4));

    // still bubbles / foam while mixing
    if (isOn) {
      final math.Random b = math.Random(7);
      for (int i = 0; i < 20; i++) {
        final double bx = g.x(300 + b.nextDouble() * 424);
        final double by = liqY + g.y(40) + b.nextDouble() * math.max(0.0, g.y(640) - liqY - g.y(60));
        _droplet(c, Offset(bx, by), (1.8 + b.nextDouble() * 3.2) * g.u, 0.9);
      }
      final math.Random f = math.Random(21);
      for (int i = 0; i < 16; i++) {
        final double fx = 290 + f.nextDouble() * 444;
        final double t = (fx - _cx) / 250;
        final double arc = 28 * math.sqrt(math.max(0.0, 1 - t * t));
        final double r = (3 + f.nextDouble() * 4.0) * g.u;
        final Offset o = Offset(g.x(fx), liqY + g.y(arc));
        c.drawCircle(o, r, Paint()..color = Colors.white.withValues(alpha: 0.45));
        c.drawCircle(o, r, _stroke(pal[0].withValues(alpha: 0.9), 0.8));
      }
    }
  }

  void _drawNozzle(Canvas c, _G g, double liqY) {
    final Offset n = g.o(_freshX, 284);

    if (isFlushing) {
      final Paint spray = _strokeP(const Color(0xFFE0F7FA).withValues(alpha: 0.75), g.s(2.6), cap: StrokeCap.round);
      final double leftB = g.x(282), rightB = g.x(742);
      for (int i = -4; i <= 4; i++) {
        final double a = i * 0.17;
        final double dx = math.sin(a), dy = math.cos(a);
        double t = (math.min(liqY, g.y(660)) - n.dy) / dy;
        if (dx > 0.001) t = math.min(t, (rightB - n.dx) / dx);
        if (dx < -0.001) t = math.min(t, (leftB - n.dx) / dx);
        if (t < g.s(10)) continue;
        c.drawLine(
          Offset(n.dx, n.dy + g.s(10)),
          Offset(n.dx + dx * t, n.dy + dy * t),
          spray,
        );
      }
    }

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
  void _drawBandsAndLid(Canvas c, _G g) {
    // top band
    final Path top = Path()
      ..moveTo(g.x(_tankL), g.y(_lidY))
      ..lineTo(g.x(_tankL), g.y(248))
      ..arcTo(Rect.fromCenter(center: g.o(512, 248), width: g.x(524), height: g.y(60)), math.pi, -math.pi, false)
      ..lineTo(g.x(_tankR), g.y(_lidY))
      ..arcTo(Rect.fromCenter(center: g.o(512, _lidY), width: g.x(524), height: g.y(60)), 0, -math.pi, false)
      ..close();
    final Rect tb = g.r(_tankL, 185, _tankR, 280);
    c.drawPath(top, _fillH(tb, _steel, stops: _steelStops));
    c.drawPath(top, _fillV(tb, [Colors.transparent, Colors.black.withValues(alpha: 0.18)]));
    c.drawPath(top, _stroke(_edge.withValues(alpha: 0.55), 1.3));
    c.drawArc(
      Rect.fromCenter(center: g.o(512, 248), width: g.x(524), height: g.y(60)),
      0,
      math.pi,
      false,
      _stroke(Colors.white.withValues(alpha: 0.55), 1.6),
    );
    // weld bead
    c.drawArc(
      Rect.fromCenter(center: g.o(512, 236), width: g.x(524), height: g.y(60)),
      0,
      math.pi,
      false,
      _stroke(Colors.black.withValues(alpha: 0.12), 1.6),
    );

    // bottom band
    final Path bot = Path()
      ..moveTo(g.x(_tankL), g.y(668))
      ..arcTo(Rect.fromCenter(center: g.o(512, 668), width: g.x(524), height: g.y(60)), math.pi, -math.pi, false)
      ..lineTo(g.x(_tankR), g.y(694))
      ..arcTo(Rect.fromCenter(center: g.o(512, 694), width: g.x(524), height: g.y(60)), 0, math.pi, false)
      ..close();
    final Rect bb = g.r(_tankL, 668, _tankR, 726);
    c.drawPath(bot, _fillH(bb, _steel, stops: _steelStops));
    c.drawPath(bot, _fillV(bb, [Colors.transparent, Colors.black.withValues(alpha: 0.24)]));
    c.drawPath(bot, _stroke(_edge.withValues(alpha: 0.6), 1.3));
    c.drawArc(
      Rect.fromCenter(center: g.o(512, 668), width: g.x(524), height: g.y(60)),
      0,
      math.pi,
      false,
      _stroke(Colors.white.withValues(alpha: 0.6), 1.6),
    );

    // lid
    final Rect lid = Rect.fromCenter(center: g.o(512, _lidY), width: g.x(524), height: g.y(60));
    c.drawOval(
      lid,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFF4F7F8), Color(0xFFCFD6DA), Color(0xFF9AA4A9)],
          stops: [0, 0.65, 1],
        ).createShader(lid),
    );
    // brushed concentric finish
    for (int i = 1; i <= 5; i++) {
      c.drawOval(
        Rect.fromCenter(center: g.o(512, _lidY), width: g.x(524 - i * 70), height: g.y(60 - i * 8)),
        _stroke(Colors.black.withValues(alpha: 0.035), 1.0),
      );
    }
    c.drawOval(lid, _stroke(_edge.withValues(alpha: 0.6), 1.4));
    final Rect ring = Rect.fromCenter(center: g.o(512, _lidY), width: g.x(470), height: g.y(48));
    c.drawOval(ring, _stroke(Colors.black.withValues(alpha: 0.18), 1.4));
    c.drawOval(ring.shift(Offset(0, g.s(1.4))), _stroke(Colors.white.withValues(alpha: 0.6), 1.2));
    if (showJoints) {
      for (int i = 0; i < 14; i++) {
        final double a = i * 2 * math.pi / 14;
        _bolt(c, g.o(512 + 244 * math.cos(a), _lidY + 25 * math.sin(a)), g.s(2.4));
      }
    }

    // manway
    c.drawOval(
      Rect.fromCenter(center: g.o(512, 212), width: g.x(98), height: g.y(24)),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    final Rect mb = g.r(468, 192, 556, 212);
    c.drawRect(mb, _fillH(mb, _steel, stops: _steelStops));
    c.drawOval(
      Rect.fromCenter(center: g.o(512, 212), width: g.x(88), height: g.y(20)),
      _fillV(g.r(468, 202, 556, 222), const [Color(0xFFB9C2C6), Color(0xFF7F898E)]),
    );
    final Rect mt = Rect.fromCenter(center: g.o(512, 192), width: g.x(88), height: g.y(20));
    c.drawOval(mt, _fillV(mt, const [Color(0xFFF7F9FA), Color(0xFFB5BEC3)]));
    c.drawOval(mt, _stroke(_edge.withValues(alpha: 0.6), 1.2));
    c.drawOval(
      Rect.fromCenter(center: g.o(512, 192), width: g.x(54), height: g.y(11)),
      _stroke(Colors.black.withValues(alpha: 0.25), 1.2),
    );
    if (showJoints) {
      for (int i = 0; i < 8; i++) {
        final double a = i * math.pi / 4;
        _bolt(c, g.o(512 + 36 * math.cos(a), 192 + 7 * math.sin(a)), g.s(1.8));
      }
    }
  }

  // ------------------------------------------------------------------- pipes
  /// Fresh water inlet – TOP LEFT.
  Path _freshPath(_G g) => Path()
    ..moveTo(g.x(20), g.y(90))
    ..lineTo(g.x(_freshX - 30), g.y(90))
    ..quadraticBezierTo(g.x(_freshX), g.y(90), g.x(_freshX), g.y(120))
    ..lineTo(g.x(_freshX), g.y(204));

  /// Dirty drain – BOTTOM LEFT.
  Path _drainPath(_G g) => Path()
    ..moveTo(g.x(252), g.y(690))
    ..lineTo(g.x(160), g.y(690))
    ..quadraticBezierTo(g.x(120), g.y(690), g.x(120), g.y(730))
    ..lineTo(g.x(120), g.y(815))
    ..quadraticBezierTo(g.x(120), g.y(845), g.x(90), g.y(845))
    ..lineTo(g.x(40), g.y(845));

  /// Outlet to sub tanks – BOTTOM RIGHT.
  Path _outletPath(_G g) => Path()
    ..moveTo(g.x(772), g.y(690))
    ..lineTo(g.x(864), g.y(690))
    ..quadraticBezierTo(g.x(904), g.y(690), g.x(904), g.y(730))
    ..lineTo(g.x(904), g.y(815))
    ..quadraticBezierTo(g.x(904), g.y(845), g.x(934), g.y(845))
    ..lineTo(g.x(1000), g.y(845));

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

  /// Soft tinted sheen inside an active pipe (static).
  void _active(Canvas c, _G g, Path p, Color col) {
    final double wp = g.s(_tubeW);
    c.drawPath(p, _strokeP(col.withValues(alpha: 0.38), wp * 0.5, cap: StrokeCap.round));
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

        // ferrules
        for (final double ox in [-8.0, 8.0]) {
          final Rect fr = Rect.fromLTRB((ox - 2.5) * s, -hh, (ox + 2.5) * s, hh);
          final RRect frr = RRect.fromRectAndRadius(fr, Radius.circular(1.5 * s));
          c.drawRRect(frr.shift(Offset(1.2 * s, 2 * s)), Paint()..color = Colors.black.withValues(alpha: 0.22));
          c.drawRRect(frr, _fillV(fr, _steel, stops: _steelStops));
          c.drawRRect(frr, _stroke(_edge.withValues(alpha: 0.7), 1));
        }
        // clamp band
        final double bh = (_tubeW / 2 + 4) * s;
        final Rect band = Rect.fromLTRB(-6 * s, -bh, 6 * s, bh);
        final RRect brr = RRect.fromRectAndRadius(band, Radius.circular(2 * s));
        c.drawRRect(brr, _fillV(band, _steel, stops: _steelStops));
        c.drawRRect(brr, _stroke(_edge.withValues(alpha: 0.75), 1));
        // wing nut
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

  void _lidFlange(Canvas c, _G g, double x) {
    final Rect r = Rect.fromCenter(center: g.o(x, 208), width: g.x(56), height: g.y(16));
    c.drawOval(r.shift(Offset(g.s(2), g.s(3))), Paint()..color = Colors.black.withValues(alpha: 0.22));
    c.drawOval(r, _fillV(r, const [Color(0xFFF7F9FA), Color(0xFF8A949A)]));
    c.drawOval(r, _stroke(_edge.withValues(alpha: 0.7), 1.1));
    if (showJoints) {
      _bolt(c, g.o(x - 20, 208), g.s(2.2));
      _bolt(c, g.o(x + 20, 208), g.s(2.2));
    }
  }

  void _wallFlange(Canvas c, _G g, double x) {
    final Rect r = g.r(x - 6, 670, x + 6, 710);
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(g.s(3)));
    c.drawRRect(rr, _fillV(r, _steel, stops: _steelStops));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.75), 1.1));
    if (showJoints) {
      _bolt(c, g.o(x, 678), g.s(2.2));
      _bolt(c, g.o(x, 702), g.s(2.2));
    }
  }

  void _drawPipes(Canvas c, _G g) {
    final Path fresh = _freshPath(g);
    final Path drain = _drainPath(g);
    final Path outlet = _outletPath(g);

    _wallFlange(c, g, 256);
    _wallFlange(c, g, 768);

    _tube(c, g, fresh);
    _tube(c, g, drain);
    _tube(c, g, outlet);

    final bool hasLiquid = level > 0.02;
    if (isFlushing) _active(c, g, fresh, const Color(0xFF64C8F5));
    if (isDraining && hasLiquid) _active(c, g, drain, const Color(0xFFA3B86F));
    if (isDistributing && hasLiquid) _active(c, g, outlet, const Color(0xFF55BB52));

    _clamps(c, g, fresh, const [0.14, 0.55]);
    _clamps(c, g, drain, const [0.22, 0.58, 0.86]);
    _clamps(c, g, outlet, const [0.22, 0.58, 0.86]);

    _endFlange(c, g, fresh, atStart: true);
    _endFlange(c, g, drain, atStart: false);
    _endFlange(c, g, outlet, atStart: false);

    _lidFlange(c, g, _freshX);
  }

  @override
  bool shouldRepaint(covariant DetailedMainFertilizerSourcePainter old) {
    return old.isOn != isOn ||
        old.isFlushing != isFlushing ||
        old.isDraining != isDraining ||
        old.isDistributing != isDistributing ||
        old.level != level ||
        old.showJoints != showJoints;
  }
}

/// 1024-grid helper.
class _G {
  final double u, v;
  _G(double w, double h)
      : u = w / 1024,
        v = h / 1024;
  double x(double p) => p * u;
  double y(double p) => p * v;
  double s(double p) => p * u;
  Offset o(double px, double py) => Offset(px * u, py * v);
  Rect r(double l, double t, double rr, double b) => Rect.fromLTRB(l * u, t * v, rr * u, b * v);
}

/// Static widget wrapper (no animation).
///
/// ```dart
/// MainFertilizerSourceView(
///   size: const Size(320, 320),
///   isOn: mixing,
///   isFlushing: flushing,
///   isDraining: draining,
///   isDistributing: distributing,
///   level: tankLevel, // 0..1
/// )
/// ```
class MainFertilizerSourceView extends StatelessWidget {
  final bool isOn;
  final bool isCleaning;
  final bool? isFlushing;
  final bool? isDraining;
  final bool isDistributing;
  final double level;
  final bool showJoints;
  final Size size;

  const MainFertilizerSourceView({
    super.key,
    required this.isOn,
    this.isCleaning = false,
    this.isFlushing,
    this.isDraining,
    this.isDistributing = false,
    this.level = 0.75,
    this.showJoints = true,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: size,
        painter: DetailedMainFertilizerSourcePainter(
          isOn: isOn,
          isCleaning: isCleaning,
          isFlushing: isFlushing,
          isDraining: isDraining,
          isDistributing: isDistributing,
          level: level,
          showJoints: showJoints,
        ),
      ),
    );
  }
}