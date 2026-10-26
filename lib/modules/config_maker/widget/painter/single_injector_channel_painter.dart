import 'dart:math' as math;
import 'package:flutter/material.dart';

// =============================================================================
//  InjectorChannelArt
//  ---------------------------------------------------------------------------
//  The ONE source of truth for how an injector / rotameter channel looks.
//  - DetailedSingleInjectorChannelPainter draws it full size.
//  - DetailedMultiInjectorPainter calls [InjectorChannelArt.paint] once per
//    channel, so every channel on the skid is pixel-for-pixel the same drawing.
//  It also exposes the shared realistic building blocks (PVC pipe shading,
//  aluminium extrusion, chrome pressure gauge, hex nut, bolt) used by the skid.
//
//  Reference grid: 220 x 600. Channel centre line is x = 90.
// =============================================================================
class InjectorChannelArt {
  InjectorChannelArt._();

  // ------------------------------------------------------------- geometry
  static const double refWidth = 220.0;
  static const double refHeight = 600.0;

  /// x of the channel centre line.
  static const double axisX = 90.0;

  /// y of the top inlet flange / bottom outlet stub (port positions).
  static const double inletY = 40.0;
  static const double outletY = 540.0;

  /// Gauge position relative to the channel.
  static const double gaugeDx = 75.0;
  static const double gaugeY = 160.0;

  /// Background shelf rails (also used by the skid frame so they line up).
  static const double upperRailTop = 95.0;
  static const double upperRailBottom = 115.0;
  static const double lowerRailTop = 275.0;
  static const double lowerRailBottom = 298.0;

  // -------------------------------------------------------------- palette
  static const Color edge = Color(0xFF151D24);
  static const Color pvcDark = Color(0xFF263038);
  static const Color blueKnob = Color(0xFF1E6FE0);
  static const Color blueKnobDark = Color(0xFF0B3FA8);
  static const Color redFloat = Color(0xFFE53935);
  static const Color chemGreen = Color(0xFF00E676);
  static const Color chemBlue = Color(0xFF0288D1);
  static const Color chemGlow = Color(0xFF00E5FF);
  static const Color steelLight = Color(0xFFECEFF1);
  static const Color steelMid = Color(0xFF90A4AE);
  static const Color steelDark = Color(0xFF455A64);

  static const List<Color> pvcCyl = [
    Color(0xFF2B343B),
    Color(0xFF7C8A94),
    Color(0xFF55616A),
    Color(0xFF263038),
  ];
  static const List<Color> alumCyl = [
    Color(0xFFB8C2C9),
    Color(0xFFFFFFFF),
    Color(0xFFD5DCE1),
    Color(0xFF8E9BA4),
  ];
  static const List<double> cylStops = [0.0, 0.25, 0.65, 1.0];

  // -------------------------------------------------------------- paints
  static Paint gv(Rect r, List<Color> c, [List<double>? stops]) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(
      colors: c,
      stops: stops,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(r);

  static Paint gh(Rect r, List<Color> c, [List<double>? stops]) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(
      colors: c,
      stops: stops,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(r);

  static Paint stroke(Color c, double w) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  /// Outline width that stays sensible in both the 220x600 grid and pixels.
  static double _lw(Rect r) => (math.min(r.width, r.height) * 0.05).clamp(0.9, 1.6).toDouble();

  static void _contactShadow(Canvas c, RRect rr) {
    final double d = math.min(rr.width, rr.height);
    final double o = (d * 0.10).clamp(0.8, 3.0).toDouble();
    c.drawRRect(
      rr.shift(Offset(o * 0.6, o)).inflate(o * 0.4),
      Paint()..color = const Color(0x1C000000),
    );
    c.drawRRect(
      rr.shift(Offset(o * 0.3, o * 0.5)),
      Paint()..color = const Color(0x24000000),
    );
  }

  // ------------------------------------------------------- building blocks

  /// Shaded PVC pipe / fitting. [vertical] = lit from the left, otherwise
  /// lit from the top. Soft contact shadow, ambient-occlusion ends, specular
  /// streak and crisp outline give it a moulded-plastic look.
  static void pvcRRect(Canvas c, RRect rr, {required bool vertical, bool shadow = true}) {
    final Rect r = rr.outerRect;
    if (shadow) _contactShadow(c, rr);
    c.drawRRect(rr, vertical ? gh(r, pvcCyl, cylStops) : gv(r, pvcCyl, cylStops));

    c.save();
    c.clipRRect(rr);
    if (vertical) {
      c.drawRect(
        r,
        gv(r, const [Color(0x38000000), Color(0x00000000), Color(0x00000000), Color(0x48000000)],
            const [0.0, 0.12, 0.85, 1.0]),
      );
      final Rect s = Rect.fromLTWH(r.left + r.width * 0.16, r.top, r.width * 0.11, r.height);
      c.drawRect(s, gh(s, const [Color(0x00FFFFFF), Color(0x45FFFFFF), Color(0x00FFFFFF)]));
    } else {
      c.drawRect(
        r,
        gh(r, const [Color(0x38000000), Color(0x00000000), Color(0x00000000), Color(0x48000000)],
            const [0.0, 0.08, 0.9, 1.0]),
      );
      final Rect s = Rect.fromLTWH(r.left, r.top + r.height * 0.16, r.width, r.height * 0.11);
      c.drawRect(s, gv(s, const [Color(0x00FFFFFF), Color(0x45FFFFFF), Color(0x00FFFFFF)]));
    }
    c.restore();
    c.drawRRect(rr, stroke(edge.withValues(alpha: 0.78), _lw(r)));
  }

  static void pvcV(Canvas c, Rect r, {double radius = 2, bool shadow = true}) =>
      pvcRRect(c, RRect.fromRectAndRadius(r, Radius.circular(radius)), vertical: true, shadow: shadow);

  static void pvcH(Canvas c, Rect r, {double radius = 2, bool shadow = true}) =>
      pvcRRect(c, RRect.fromRectAndRadius(r, Radius.circular(radius)), vertical: false, shadow: shadow);

  /// Side view of a big hex union nut (flats, chamfered ends).
  static void hexNut(Canvas c, Rect r, {double radius = 4}) {
    pvcV(c, r, radius: radius);
    final double w = r.width;
    for (final double f in [1 / 3, 2 / 3]) {
      final double x = r.left + w * f;
      c.drawLine(Offset(x, r.top + 1.5), Offset(x, r.bottom - 1.5), stroke(const Color(0x59000000), 0.9));
      c.drawLine(Offset(x + 0.9, r.top + 1.5), Offset(x + 0.9, r.bottom - 1.5), stroke(const Color(0x33FFFFFF), 0.8));
    }
    final double band = math.min(3.0, r.height * 0.12);
    final Rect top = Rect.fromLTWH(r.left + 1, r.top + 1, r.width - 2, band);
    c.drawRect(top, gv(top, const [Color(0x40FFFFFF), Color(0x00FFFFFF)]));
    final Rect bot = Rect.fromLTWH(r.left + 1, r.bottom - 1 - band, r.width - 2, band);
    c.drawRect(bot, gv(bot, const [Color(0x00000000), Color(0x50000000)]));
  }

  /// Anodised aluminium extrusion running left-right with a T-slot groove.
  static void alumH(Canvas c, Rect r) {
    c.drawRect(r.shift(Offset(0, math.min(r.height * 0.14, 2.6))), Paint()..color = const Color(0x24000000));
    c.drawRect(r, gv(r, alumCyl, cylStops));
    final double gh2 = (r.height * 0.34).clamp(1.5, 7.0).toDouble();
    final Rect g = Rect.fromCenter(center: r.center, width: math.max(2.0, r.width - 4), height: gh2);
    c.drawRect(g, gv(g, const [Color(0x70000000), Color(0x28000000), Color(0x40FFFFFF)]));
    c.drawLine(Offset(r.left + 1, g.top), Offset(r.right - 1, g.top), stroke(const Color(0x59000000), 0.8));
    c.drawLine(Offset(r.left + 1, g.bottom), Offset(r.right - 1, g.bottom), stroke(const Color(0x70FFFFFF), 0.8));
    c.drawLine(Offset(r.left, r.top + 0.8), Offset(r.right, r.top + 0.8), stroke(const Color(0x99FFFFFF), 1.0));
    c.drawRect(r, stroke(const Color(0xFF6B7780), _lw(r)));
  }

  /// Anodised aluminium extrusion running up-down with a T-slot groove.
  static void alumV(Canvas c, Rect r) {
    c.drawRect(r.shift(Offset(math.min(r.width * 0.14, 2.6), 0)), Paint()..color = const Color(0x24000000));
    c.drawRect(r, gh(r, alumCyl, cylStops));
    final double gw = (r.width * 0.34).clamp(1.5, 7.0).toDouble();
    final Rect g = Rect.fromCenter(center: r.center, width: gw, height: math.max(2.0, r.height - 4));
    c.drawRect(g, gh(g, const [Color(0x70000000), Color(0x28000000), Color(0x40FFFFFF)]));
    c.drawLine(Offset(g.left, r.top + 1), Offset(g.left, r.bottom - 1), stroke(const Color(0x59000000), 0.8));
    c.drawLine(Offset(g.right, r.top + 1), Offset(g.right, r.bottom - 1), stroke(const Color(0x70FFFFFF), 0.8));
    c.drawLine(Offset(r.left + 0.8, r.top), Offset(r.left + 0.8, r.bottom), stroke(const Color(0x99FFFFFF), 1.0));
    c.drawRect(r, stroke(const Color(0xFF6B7780), _lw(r)));
  }

  /// Round socket-head bolt.
  static void bolt(Canvas c, Offset o, double r) {
    c.drawCircle(o + Offset(r * 0.25, r * 0.4), r * 1.05, Paint()..color = const Color(0x40000000));
    final Rect rect = Rect.fromCircle(center: o, radius: r);
    c.drawCircle(
      o,
      r,
      Paint()
        ..isAntiAlias = true
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: [Color(0xFFFFFFFF), Color(0xFFCFD8DC), Color(0xFF78909C)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
    c.drawCircle(o, r, stroke(edge, math.max(0.5, r * 0.22)));
    c.drawLine(
      o.translate(-r * 0.5, 0),
      o.translate(r * 0.5, 0),
      stroke(const Color(0x88263238), math.max(0.4, r * 0.2)),
    );
  }

  /// Chrome-bezel pressure gauge with white dial, red zone and glass.
  /// [v] is 0..1 of the sweep.
  static void gauge(Canvas c, Offset ctr, double r, double v) {
    final Rect o = Rect.fromCircle(center: ctr, radius: r);

    // drop shadow
    c.drawCircle(ctr + Offset(r * 0.07, r * 0.13), r * 1.03, Paint()..color = const Color(0x33000000));

    // chrome bezel
    c.drawCircle(
      ctr,
      r,
      Paint()
        ..isAntiAlias = true
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFF4F7F8),
            Color(0xFF8E9BA4),
            Color(0xFFFFFFFF),
            Color(0xFF69767F),
            Color(0xFFF4F7F8),
          ],
        ).createShader(o),
    );
    c.drawCircle(ctr, r, stroke(edge, math.max(0.9, r * 0.04)));

    // dark seat ring + white dial
    c.drawCircle(ctr, r * 0.87, Paint()..color = const Color(0xFF2A3339));
    final Rect dial = Rect.fromCircle(center: ctr, radius: r * 0.82);
    c.drawCircle(
      ctr,
      r * 0.82,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFFFFF), Color(0xFFEEF2F4)],
        ).createShader(dial),
    );

    // red zone
    c.drawArc(
      Rect.fromCircle(center: ctr, radius: r * 0.70),
      0.75 * math.pi + 16 / 20 * 1.5 * math.pi,
      4 / 20 * 1.5 * math.pi,
      false,
      stroke(const Color(0xCCD32F2F), math.max(1.0, r * 0.07)),
    );

    // ticks
    for (int k = 0; k <= 20; k++) {
      final double a = 0.75 * math.pi + k / 20 * 1.5 * math.pi;
      final bool major = k % 5 == 0;
      final double len = major ? 0.24 : 0.12;
      final Offset d = Offset(math.cos(a), math.sin(a));
      c.drawLine(
        ctr + d * (r * 0.78),
        ctr + d * (r * (0.78 - len)),
        Paint()
          ..color = k >= 16 ? const Color(0xFFD32F2F) : const Color(0xFF37474F)
          ..strokeWidth = major ? math.max(0.8, r * 0.05) : math.max(0.5, r * 0.028),
      );
    }

    // needle (with tail + shadow)
    final double na = 0.75 * math.pi + v.clamp(0.0, 1.0).toDouble() * 1.5 * math.pi;
    final Offset dir = Offset(math.cos(na), math.sin(na));
    final Paint needle = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = math.max(1.1, r * 0.06)
      ..strokeCap = StrokeCap.round;
    c.drawLine(ctr + Offset(r * 0.03, r * 0.05), ctr + dir * (r * 0.62) + Offset(r * 0.03, r * 0.05),
        Paint()..color = const Color(0x33000000)..strokeWidth = needle.strokeWidth..strokeCap = StrokeCap.round);
    c.drawLine(ctr - dir * (r * 0.16), ctr + dir * (r * 0.62), needle);

    // hub
    c.drawCircle(
      ctr,
      r * 0.11,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFFCFD8DC), Color(0xFF37474F)],
        ).createShader(Rect.fromCircle(center: ctr, radius: r * 0.11)),
    );
    c.drawCircle(ctr, r * 0.04, Paint()..color = edge);

    // glass
    c.drawCircle(
      ctr,
      r * 0.82,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.5, -0.6),
          radius: 0.9,
          colors: [Color(0x50FFFFFF), Color(0x00FFFFFF)],
        ).createShader(dial),
    );
    c.drawArc(
      Rect.fromCircle(center: ctr, radius: r * 0.7),
      -math.pi * 0.9,
      math.pi * 0.45,
      false,
      stroke(Colors.white.withValues(alpha: 0.6), math.max(1.0, r * 0.05)),
    );
  }

  // ------------------------------------------------------------ the channel

  /// Draws one complete injector channel in the 220 x 600 reference grid.
  /// Apply your own translate / scale on [canvas] first.
  ///
  /// [floatOffset] shifts the red float up (-) / down (+) so several channels
  /// can show slightly different flow rates.
  static void paint(
      Canvas canvas, {
        required bool isOn,
        double phase = 0.0,
        bool showJoints = true,
        Color? fluidColor,
        double pressureValue = 0.6,
        bool drawRails = true,
        bool drawGlow = true,
        int seed = 42,
        double floatOffset = 0.0,
      }) {
    _ChannelDraw(
      canvas,
      isOn: isOn,
      phase: phase,
      showJoints: showJoints,
      fluidColor: fluidColor,
      pressureValue: pressureValue,
      drawRails: drawRails,
      drawGlow: drawGlow,
      seed: seed,
      floatOffset: floatOffset,
    ).run();
  }
}

class _ChannelDraw {
  final Canvas c;
  final bool isOn;
  final double phase;
  final bool showJoints;
  final Color? fluidColor;
  final double pressureValue;
  final bool drawRails;
  final bool drawGlow;
  final int seed;
  final double floatOffset;

  _ChannelDraw(
      this.c, {
        required this.isOn,
        required this.phase,
        required this.showJoints,
        required this.fluidColor,
        required this.pressureValue,
        required this.drawRails,
        required this.drawGlow,
        required this.seed,
        required this.floatOffset,
      });

  static const double xc = InjectorChannelArt.axisX;

  void run() {
    if (drawGlow && isOn) _glow();
    if (drawRails) _rails();
    _gaugeBranch();
    _topPort();
    _rotameter();
    _bottom();
  }

  // ------------------------------------------------------------------ glow
  void _glow() {
    final Rect main = Rect.fromLTRB(10, 40, 210, 540);
    final double pulse = 0.18 + 0.08 * math.sin(phase * 2 * math.pi);
    c.drawRRect(
      RRect.fromRectAndRadius(main, const Radius.circular(16)),
      Paint()
        ..color = InjectorChannelArt.chemGlow.withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  // ----------------------------------------------------------------- rails
  void _rails() {
    InjectorChannelArt.alumH(
        c, Rect.fromLTRB(10, InjectorChannelArt.upperRailTop, 210, InjectorChannelArt.upperRailBottom));
    InjectorChannelArt.alumH(
        c, Rect.fromLTRB(10, InjectorChannelArt.lowerRailTop, 210, InjectorChannelArt.lowerRailBottom));
  }

  // ---------------------------------------------------- pressure gauge side
  void _gaugeBranch() {
    const double gx = xc + InjectorChannelArt.gaugeDx;
    const double gy = InjectorChannelArt.gaugeY;

    // side connector from the main union nut to the gauge valve
    InjectorChannelArt.pvcH(c, Rect.fromLTRB(118, 206, 152, 218), radius: 2);

    // stem + ball valve body + union ring
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(gx - 7, 185, gx + 7, 206));
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(gx - 18, 205, gx + 18, 245), radius: 4);
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(gx - 20, 211, gx + 20, 219), radius: 2, shadow: false);

    // black end cap
    final Rect cap = Rect.fromLTRB(gx - 23, 245, gx + 23, 260);
    final RRect capRR = RRect.fromRectAndRadius(cap, const Radius.circular(3));
    c.drawRRect(capRR.shift(const Offset(1.2, 2)), Paint()..color = const Color(0x30000000));
    c.drawRRect(capRR, InjectorChannelArt.gh(cap, const [Color(0xFF0E0F10), Color(0xFF4A545B), Color(0xFF0E0F10)]));
    c.drawLine(Offset(cap.left + 3, cap.top + 1.5), Offset(cap.right - 3, cap.top + 1.5),
        InjectorChannelArt.stroke(const Color(0x55FFFFFF), 0.9));
    c.drawRRect(capRR, InjectorChannelArt.stroke(InjectorChannelArt.edge, 1.0));

    // small black lever on the valve
    final RRect lever = RRect.fromRectAndRadius(Rect.fromLTRB(gx + 12, 226, gx + 44, 235), const Radius.circular(4));
    c.drawRRect(lever.shift(const Offset(1, 2)), Paint()..color = const Color(0x33000000));
    c.drawRRect(lever, InjectorChannelArt.gv(lever.outerRect, const [Color(0xFF3A444B), Color(0xFF0B0C0D)]));
    c.drawRRect(lever, InjectorChannelArt.stroke(const Color(0xFF000000), 0.8));
    InjectorChannelArt.bolt(c, const Offset(gx + 16, 230.5), 3.6);

    // gauge dial
    final double val = isOn ? (pressureValue + 0.02 * math.sin(phase * 20 * math.pi)) : 0.04;
    InjectorChannelArt.gauge(c, const Offset(gx, gy), 26.0, val);
  }

  // -------------------------------------------------------------- top port
  void _topPort() {

    // top flange plate + gasket
    final Rect gasket = Rect.fromLTRB(xc - 21, 54, xc + 21, 58);
    c.drawRect(gasket, Paint()..color = const Color(0xFF141A1E));

    final Rect fl = Rect.fromLTRB(xc - 28, 42, xc + 28, 55);
    final RRect flRR = RRect.fromRectAndRadius(fl, const Radius.circular(1.8));
    c.drawRRect(flRR.shift(const Offset(1.2, 2.2)), Paint()..color = const Color(0x33000000));
    c.drawRRect(flRR, InjectorChannelArt.gv(fl, const [InjectorChannelArt.steelLight, InjectorChannelArt.steelMid, InjectorChannelArt.steelDark]));
    c.drawLine(Offset(fl.left + 1.5, fl.top + 1.2), Offset(fl.right - 1.5, fl.top + 1.2),
        InjectorChannelArt.stroke(const Color(0xAAFFFFFF), 0.9));
    c.drawRRect(flRR, InjectorChannelArt.stroke(InjectorChannelArt.edge, 1.0));
    if (showJoints) {
      InjectorChannelArt.bolt(c, const Offset(xc - 22, 48.5), 2.4);
      InjectorChannelArt.bolt(c, const Offset(xc + 22, 48.5), 2.4);
      InjectorChannelArt.bolt(c, const Offset(xc, 48.5), 2.0);
    }

    // short neck joining the flange to the blue cap
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(xc - 9, 55, xc + 9, 66), radius: 2, shadow: false);

    // blue cap / knob
    final Rect cap = Rect.fromLTRB(xc - 15, 65, xc + 15, 95);
    final RRect capRR = RRect.fromRectAndRadius(cap, const Radius.circular(5));
    c.drawRRect(capRR.shift(const Offset(1.5, 2.5)), Paint()..color = const Color(0x38000000));
    c.drawRRect(
      capRR,
      InjectorChannelArt.gh(cap, const [InjectorChannelArt.blueKnobDark, InjectorChannelArt.blueKnob, Color(0xFF6AA8FF), InjectorChannelArt.blueKnobDark],
          const [0.0, 0.35, 0.55, 1.0]),
    );
    c.save();
    c.clipRRect(capRR);
    // grip ridges
    for (double x = xc - 11; x <= xc + 11.1; x += 5.5) {
      c.drawLine(Offset(x, 68), Offset(x, 92), InjectorChannelArt.stroke(const Color(0x30000000), 1.0));
      c.drawLine(Offset(x + 1.1, 68), Offset(x + 1.1, 92), InjectorChannelArt.stroke(const Color(0x25FFFFFF), 0.8));
    }
    // top bevel + bottom shade
    c.drawRect(
      Rect.fromLTRB(cap.left, cap.top, cap.right, cap.top + 8),
      InjectorChannelArt.gv(Rect.fromLTRB(cap.left, cap.top, cap.right, cap.top + 8),
          const [Color(0x55FFFFFF), Color(0x00FFFFFF)]),
    );
    c.drawRect(
      Rect.fromLTRB(cap.left, cap.bottom - 8, cap.right, cap.bottom),
      InjectorChannelArt.gv(Rect.fromLTRB(cap.left, cap.bottom - 8, cap.right, cap.bottom),
          const [Color(0x00000000), Color(0x55000000)]),
    );
    c.restore();
    c.drawRRect(capRR, InjectorChannelArt.stroke(InjectorChannelArt.edge, 1.1));

    if (isOn) {
      final double pulse = 0.5 + 0.5 * math.sin(phase * 4 * math.pi);
      c.drawCircle(
        const Offset(xc, 80),
        14 * (1 + 0.2 * pulse),
        InjectorChannelArt.stroke(InjectorChannelArt.chemGlow.withValues(alpha: 0.5 * (1 - 0.3 * pulse)), 2.0),
      );
    }

    // upper PVC stem, union collar, neck and big retention nut
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(xc - 16, 95, xc + 16, 135));
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(xc - 25, 135, xc + 25, 160), radius: 4);
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(xc - 19, 160, xc + 19, 185));
    InjectorChannelArt.hexNut(c, Rect.fromLTRB(xc - 33, 185, xc + 33, 218), radius: 5);

    if (showJoints) {
      for (final double y in [148.0, 201.0]) {
        c.drawLine(Offset(xc - 24, y), Offset(xc + 24, y), InjectorChannelArt.stroke(const Color(0x8A000000), 0.9));
        c.drawLine(Offset(xc - 24, y + 1), Offset(xc + 24, y + 1), InjectorChannelArt.stroke(const Color(0x28FFFFFF), 0.8));
      }
    }
  }

  // ------------------------------------------------------------- rotameter
  void _rotameter() {
    const double top = 218, bot = 388;

    final Rect glass = Rect.fromLTRB(xc - 19, top, xc + 19, bot);
    final RRect glassRR = RRect.fromRectAndRadius(glass, const Radius.circular(3));

    // shadow + glass body
    c.drawRRect(glassRR.shift(const Offset(2.5, 3)), Paint()..color = const Color(0x26000000));
    c.drawRRect(
      glassRR,
      InjectorChannelArt.gh(glass, const [Color(0xAAB0BEC5), Color(0xEEFFFFFF), Color(0x99CFD8DC)], const [0.0, 0.4, 1.0]),
    );

    // tapered bore
    final Path bore = Path()
      ..moveTo(xc - 15, 222)
      ..lineTo(xc + 15, 222)
      ..lineTo(xc + 12.5, 384)
      ..lineTo(xc - 12.5, 384)
      ..close();
    c.drawPath(bore, Paint()..color = const Color(0x1A455A64));

    final Color fc = fluidColor ?? InjectorChannelArt.chemGreen;
    if (isOn) {
      c.save();
      c.clipPath(bore);
      final Rect br = Rect.fromLTRB(xc - 16, 222, xc + 16, 384);
      c.drawRect(br, InjectorChannelArt.gv(br, [fc.withValues(alpha: 0.14), fc.withValues(alpha: 0.42)]));
      // upward shimmer band
      final double t = (phase * 2) % 1.0;
      final double sy = 384 - t * 170;
      final Rect sh = Rect.fromLTRB(xc - 16, sy - 9, xc + 16, sy + 9);
      c.drawRect(sh, InjectorChannelArt.gv(sh, const [Color(0x00FFFFFF), Color(0x38FFFFFF), Color(0x00FFFFFF)]));
      c.restore();
    }
    c.drawPath(bore, InjectorChannelArt.stroke(const Color(0x40263238), 0.9));

    // scale graduation ticks
    int k = 0;
    for (double y = 230; y < 375; y += 7.5, k++) {
      final double len = (k % 5 == 0) ? 10.0 : 6.0;
      c.drawLine(
        Offset(xc - 17, y),
        Offset(xc - 17 + len, y),
        Paint()
          ..color = const Color(0xCC1A1A1A)
          ..strokeWidth = 1.0,
      );
    }

    // white bottom stopper
    final Rect stopper = Rect.fromLTRB(xc - 10, 372, xc + 10, 386);
    final RRect stRR = RRect.fromRectAndRadius(stopper, const Radius.circular(2));
    c.drawRRect(stRR, InjectorChannelArt.gh(stopper, const [Color(0xFFB0BEC5), Color(0xFFFFFFFF), Color(0xFFCFD8DC)]));
    c.drawRRect(stRR, InjectorChannelArt.stroke(InjectorChannelArt.steelDark, 0.9));

    // bubbles
    if (isOn) {
      final math.Random rnd = math.Random(seed);
      final Paint bp = Paint()..color = Colors.white.withValues(alpha: 0.9);
      for (int b = 0; b < 7; b++) {
        final double bx = xc - 9 + rnd.nextDouble() * 18;
        final double speed = rnd.nextDouble() > 0.55 ? 2.0 : 1.0; // whole loops => seamless
        final double prog = (phase * speed + rnd.nextDouble()) % 1.0;
        final double by = 382 - prog * 150;
        if (by > 228 && by < 372) {
          c.drawCircle(Offset(bx, by), 1.5, bp);
          c.drawCircle(Offset(bx, by), 1.5, InjectorChannelArt.stroke(const Color(0x55263238), 0.5));
        }
      }
    }

    // red float
    final double floatY = isOn
        ? (300.0 + floatOffset + 4.0 * math.sin(phase * 4 * math.pi))
        : 360.0;
    _float(floatY);

    // border + end collars + glare
    c.drawRRect(glassRR, InjectorChannelArt.stroke(InjectorChannelArt.pvcDark, 1.3));
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(xc - 22, top - 1, xc + 22, top + 5), radius: 2, shadow: false);
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(xc - 22, bot - 5, xc + 22, bot + 1), radius: 2, shadow: false);

    final Path glare = Path()
      ..moveTo(glass.left + 2, glass.top + 6)
      ..lineTo(glass.left + 7, glass.top + 6)
      ..lineTo(glass.left + 5, glass.bottom - 6)
      ..lineTo(glass.left + 2, glass.bottom - 6)
      ..close();
    c.drawPath(glare, Paint()..color = Colors.white.withValues(alpha: 0.42));
    c.drawLine(
      Offset(glass.right - 3, glass.top + 8),
      Offset(glass.right - 3, glass.bottom - 8),
      InjectorChannelArt.stroke(const Color(0x33FFFFFF), 1.2),
    );
  }

  void _float(double cy) {
    const double hw1 = 10.5, hw2 = 6.0, h = 18.0;

    final Path body = Path()
      ..moveTo(xc - hw1, cy - h / 2)
      ..lineTo(xc + hw1, cy - h / 2)
      ..lineTo(xc + hw2, cy + h / 2)
      ..lineTo(xc - hw2, cy + h / 2)
      ..close();
    final Rect b = Rect.fromLTRB(xc - hw1, cy - h / 2, xc + hw1, cy + h / 2);

    c.drawPath(body.shift(const Offset(1.3, 1.8)), Paint()..color = const Color(0x45000000));
    c.drawPath(
      body,
      InjectorChannelArt.gh(b, const [Color(0xFF8E1B1B), Color(0xFFFF6F60), InjectorChannelArt.redFloat, Color(0xFFB71C1C)],
          const [0.0, 0.3, 0.62, 1.0]),
    );

    // grooves
    for (final double f in [0.35, 0.65]) {
      final double y = cy - h / 2 + h * f;
      final double half = hw1 + (hw2 - hw1) * f;
      c.drawLine(Offset(xc - half + 0.8, y), Offset(xc + half - 0.8, y), InjectorChannelArt.stroke(const Color(0x66000000), 0.8));
    }
    // top rim
    final Rect rim = Rect.fromLTRB(xc - hw1, cy - h / 2 - 1.6, xc + hw1, cy - h / 2 + 2.2);
    c.drawOval(rim, InjectorChannelArt.gh(rim, const [Color(0xFFFFB4AB), Color(0xFFFFEBEE), Color(0xFFE57373)]));
    c.drawOval(rim, InjectorChannelArt.stroke(const Color(0xFF7F1D1D), 0.8));
    // specular streak
    c.drawLine(Offset(xc - 4.5, cy - h / 2 + 3), Offset(xc - 3.2, cy + h / 2 - 3), InjectorChannelArt.stroke(const Color(0x77FFFFFF), 1.3));
    c.drawPath(body, InjectorChannelArt.stroke(const Color(0xCCFFFFFF), 0.8));
  }

  // ---------------------------------------------------------------- bottom
  void _bottom() {

    InjectorChannelArt.hexNut(c, Rect.fromLTRB(xc - 33, 388, xc + 33, 420), radius: 5);
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(xc - 23, 420, xc + 23, 460));
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(xc - 29, 460, xc + 29, 490), radius: 4);

    // black ball-valve lever
    final RRect lever = RRect.fromRectAndRadius(Rect.fromLTRB(xc + 4, 468, xc + 62, 481), const Radius.circular(5));
    c.drawRRect(lever.shift(const Offset(1.2, 2.4)), Paint()..color = const Color(0x40000000));
    c.drawRRect(lever, InjectorChannelArt.gv(lever.outerRect, const [Color(0xFF4A545B), Color(0xFF111111), Color(0xFF050505)]));
    c.drawLine(Offset(xc + 10, 470.5), Offset(xc + 58, 470.5), InjectorChannelArt.stroke(const Color(0x66FFFFFF), 0.9));
    c.drawRRect(lever, InjectorChannelArt.stroke(const Color(0xFF000000), 0.9));
    // pivot cap
    c.drawCircle(const Offset(xc, 474.5), 9.5, Paint()..color = const Color(0xFF0B0C0D));
    c.drawCircle(const Offset(xc, 474.5), 9.5, InjectorChannelArt.stroke(const Color(0xFF59646B), 1.0));
    InjectorChannelArt.bolt(c, const Offset(xc, 474.5), 4.6);

    // mounting clamp
    final Rect clamp = Rect.fromLTRB(xc - 30, 490, xc + 30, 518);
    final RRect clampRR = RRect.fromRectAndRadius(clamp, const Radius.circular(3));
    c.drawRRect(clampRR.shift(const Offset(1.4, 2.6)), Paint()..color = const Color(0x40000000));
    c.drawRRect(clampRR, InjectorChannelArt.gv(clamp, const [Color(0xFF3A4247), Color(0xFF15191C), Color(0xFF050606)]));
    c.drawLine(Offset(clamp.left + 3, clamp.top + 1.5), Offset(clamp.right - 3, clamp.top + 1.5),
        InjectorChannelArt.stroke(const Color(0x66FFFFFF), 0.9));
    c.drawLine(Offset(xc, clamp.top + 3), Offset(xc, clamp.bottom - 3), InjectorChannelArt.stroke(const Color(0x40000000), 1.0));
    c.drawRRect(clampRR, InjectorChannelArt.stroke(const Color(0xFF000000), 1.0));
    if (showJoints) {
      InjectorChannelArt.bolt(c, Offset(clamp.left + 7, clamp.center.dy), 3.0);
      InjectorChannelArt.bolt(c, Offset(clamp.right - 7, clamp.center.dy), 3.0);
    }

    // bottom outlet pipe stub
    InjectorChannelArt.pvcV(c, Rect.fromLTRB(xc - 18, 518, xc + 18, 550));
  }
}

// =============================================================================
//  Single injector painter
// =============================================================================

/// Standalone Single Injector / Rotameter Channel Painter.
///
/// Draws exactly one [InjectorChannelArt] channel (blue cap, PVC stem, union
/// nut, chrome pressure gauge on a side valve, tapered rotameter glass with
/// float + bubbles, ball valve with lever, clamp and outlet stub) on a
/// 220 x 600 reference grid, scaled uniformly and centred in the widget.
class DetailedSingleInjectorChannelPainter extends CustomPainter {
  final bool isOn;
  final double phase;
  final bool showJoints;
  final Color? fluidColor;
  final double pressureValue;

  DetailedSingleInjectorChannelPainter({
    required this.isOn,
    this.phase = 0.0,
    this.showJoints = true,
    this.fluidColor,
    this.pressureValue = 0.6,
  });

  // Reference canvas dimensions
  static const double refWidth = InjectorChannelArt.refWidth;
  static const double refHeight = InjectorChannelArt.refHeight;
  static const double aspectRatio = refWidth / refHeight;

  static ({double k, double ox, double oy}) _fit(Size s) {
    final double k = math.min(s.width / refWidth, s.height / refHeight);
    return (k: k, ox: (s.width - refWidth * k) / 2, oy: (s.height - refHeight * k) / 2);
  }

  static Offset _pt(Size s, double x, double y) {
    final f = _fit(s);
    return Offset(f.ox + x * f.k, f.oy + y * f.k);
  }

  // Ports in widget pixels
  static Offset inletPort(Size s) => _pt(s, InjectorChannelArt.axisX, InjectorChannelArt.inletY);
  static Offset outletPort(Size s) => _pt(s, InjectorChannelArt.axisX, InjectorChannelArt.outletY);
  static Offset gaugePort(Size s) =>
      _pt(s, InjectorChannelArt.axisX + InjectorChannelArt.gaugeDx, InjectorChannelArt.gaugeY);

  @override
  void paint(Canvas canvas, Size size) {
    final f = _fit(size);
    canvas.save();
    canvas.translate(f.ox, f.oy);
    canvas.scale(f.k);
    InjectorChannelArt.paint(
      canvas,
      isOn: isOn,
      phase: phase,
      showJoints: showJoints,
      fluidColor: fluidColor,
      pressureValue: pressureValue,
      drawRails: true,
      drawGlow: true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DetailedSingleInjectorChannelPainter old) =>
      old.isOn != isOn ||
          old.phase != phase ||
          old.showJoints != showJoints ||
          old.fluidColor != fluidColor ||
          old.pressureValue != pressureValue;
}

/// Stateful / View Wrapper Widget for [DetailedSingleInjectorChannelPainter].
class SingleInjectorChannelView extends StatefulWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;
  final Color? fluidColor;
  final double pressureValue;

  const SingleInjectorChannelView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    this.size = const Size(110, 300),
    this.fluidColor,
    this.pressureValue = 0.6,
  });

  /// Top inlet port location
  static Offset inletPort(Size s) => DetailedSingleInjectorChannelPainter.inletPort(s);

  /// Bottom outlet port location
  static Offset outletPort(Size s) => DetailedSingleInjectorChannelPainter.outletPort(s);

  /// Gauge port location
  static Offset gaugePort(Size s) => DetailedSingleInjectorChannelPainter.gaugePort(s);

  @override
  State<SingleInjectorChannelView> createState() => _SingleInjectorChannelViewState();
}

class _SingleInjectorChannelViewState extends State<SingleInjectorChannelView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isOn) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SingleInjectorChannelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn != oldWidget.isOn) {
      if (widget.isOn) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
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
        builder: (context, child) {
          return CustomPaint(
            size: widget.size,
            painter: DetailedSingleInjectorChannelPainter(
              isOn: widget.isOn,
              phase: _controller.value,
              showJoints: widget.showJoints,
              fluidColor: widget.fluidColor,
              pressureValue: widget.pressureValue,
            ),
          );
        },
      ),
    );
  }
}