import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Detailed EC (Electrical Conductivity) Sensor Painter.
///
/// Realistic inline sensor, drawn on a 500 x 800 reference frame:
/// - Cable with rubber strain-relief boot and stainless cable-gland nut
/// - Black ABS transmitter head with accent rings, LCD window and status LED
/// - Stainless hex process nut, O-ring and threaded fitting
/// - Probe: PVDF body, stainless electrode rings with black insulators, graphite tip
///
/// [isOn]        sensor powered: LCD backlit with the value, green LED, soft
///               sensing halo at the tip.
/// [showJoints]  draw housing screws and thread/facet details.
/// [showLabels]  show the small "EC" plate text (set false for no text).
class DetailedEcSensorPainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;
  final bool showLabels;
  final double? ecValue;

  DetailedEcSensorPainter({
    required this.isOn,
    this.showJoints = true,
    this.showLabels = true,
    this.ecValue,
  });

  static const double _refW = 500.0;
  static const double _refH = 800.0;

  static const Color _edge = Color(0xFF14181C);

  static const List<Color> _steel = [
    Color(0xFF3C444B),
    Color(0xFF8D979E),
    Color(0xFFE9EEF1),
    Color(0xFFB3BCC2),
    Color(0xFF565F66),
  ];
  static const List<double> _steelStops = [0.0, 0.22, 0.45, 0.75, 1.0];

  static const List<Color> _abs = [
    Color(0xFF0E1114),
    Color(0xFF232A31),
    Color(0xFF4A5560),
    Color(0xFF2A323A),
    Color(0xFF0C0F12),
  ];
  static const List<double> _absStops = [0.0, 0.2, 0.45, 0.75, 1.0];

  static const Color _acc = Color(0xFF00ACC1);
  static const Color _accD = Color(0xFF006064);
  static const Color _accL = Color(0xFF80DEEA);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width / _refW, size.height / _refH);
    final _Frame f = _Frame(s, size.width / 2, (size.height - _refH * s) / 2);

    _drawShadow(canvas, f);
    _drawProbe(canvas, f);
    _drawFitting(canvas, f);
    _drawHead(canvas, f);
    _drawDisplayAndLed(canvas, f);
    _drawGland(canvas, f);
  }

  // --------------------------------------------------------------- helpers
  Paint _fillH(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(colors: colors, stops: stops).createShader(r);

  Paint _fillV(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(r);

  Paint _stroke(Color c, double w) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  void _cyl(Canvas c, Rect rect, List<Color> colors, List<double> stops,
      {double radius = 2, double edge = 0.9}) {
    final RRect rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    c.drawRRect(rr, _fillH(rect, colors, stops: stops));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.85), edge));
  }

  void _text(
      Canvas c,
      String t,
      Offset center,
      double size,
      Color color, {
        FontWeight weight = FontWeight.w700,
        double spacing = 0,
        String? family,
        List<Shadow>? shadows,
      }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: weight,
          letterSpacing: spacing,
          fontFamily: family,
          height: 1.0,
          shadows: shadows,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// Hex nut seen from the side: three facets with chamfered edges.
  void _hex(Canvas c, _Frame f, double l, double t, double r, double b) {
    final double e = (r - l) * 0.21;
    final Rect all = f.r(l, t, r, b);
    final Rect left = f.r(l, t, l + e, b);
    final Rect mid = f.r(l + e, t, r - e, b);
    final Rect right = f.r(r - e, t, r, b);
    c.drawRect(left, _fillH(left, const [Color(0xFF3A4249), Color(0xFF69737B)]));
    c.drawRect(mid, _fillH(mid, const [Color(0xFFB4BDC3), Color(0xFFF2F5F7), Color(0xFFC3CBD0)]));
    c.drawRect(right, _fillH(right, const [Color(0xFF7C868E), Color(0xFF343B42)]));
    // chamfers
    c.drawRect(f.r(l, t, r, t + 5), Paint()..color = Colors.white.withValues(alpha: 0.35));
    c.drawRect(f.r(l, b - 5, r, b), Paint()..color = Colors.black.withValues(alpha: 0.28));
    // facet edges
    final Paint div = _stroke(_edge.withValues(alpha: 0.6), f.len(1));
    c.drawLine(Offset(left.right, all.top), Offset(left.right, all.bottom), div);
    c.drawLine(Offset(mid.right, all.top), Offset(mid.right, all.bottom), div);
    c.drawRect(all, _stroke(_edge.withValues(alpha: 0.9), f.len(1.2)));
  }

  void _threads(Canvas c, _Frame f, double l, double t, double r, double b) {
    c.save();
    c.clipRect(f.r(l, t, r, b));
    for (double y = t - 6; y < b; y += 6) {
      c.drawLine(f.p(l, y + 4), f.p(r, y + 1), _stroke(Colors.black.withValues(alpha: 0.45), f.len(1.6)));
      c.drawLine(f.p(l, y + 5.8), f.p(r, y + 2.8), _stroke(Colors.white.withValues(alpha: 0.35), f.len(1)));
    }
    c.restore();
  }

  void _screw(Canvas c, Offset o, double r) {
    c.drawCircle(o, r, _fillV(Rect.fromCircle(center: o, radius: r), const [Color(0xFFE3E8EB), Color(0xFF7B858C)]));
    c.drawCircle(o, r, _stroke(_edge, r * 0.2));
    c.drawLine(o.translate(-r * 0.6, 0), o.translate(r * 0.6, 0), _stroke(_edge, r * 0.22));
    c.drawLine(o.translate(0, -r * 0.6), o.translate(0, r * 0.6), _stroke(_edge, r * 0.22));
  }

  void _drawGlow(Canvas c, _Frame f, double cx, double cy) {
    final Rect g = Rect.fromCircle(center: f.p(cx, cy), radius: f.len(85));
    c.drawOval(
      g,
      Paint()
        ..shader = RadialGradient(
          colors: [_acc.withValues(alpha: 0.30), _acc.withValues(alpha: 0.10), Colors.transparent],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(g),
    );
  }

  // ----------------------------------------------------------------- shadow
  void _drawShadow(Canvas c, _Frame f) {
    final Path p = Path()
      ..addRRect(RRect.fromRectAndRadius(f.r(160, 206, 340, 470), Radius.circular(f.len(20))))
      ..addRect(f.r(190, 470, 310, 590))
      ..addRect(f.r(214, 590, 286, 780));
    c.drawPath(
      p.shift(Offset(f.len(14), f.len(18))),
      Paint()
        ..color = const Color(0x44000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.5, f.len(16))),
    );
  }

  // ------------------------------------------------------------------ probe
  void _drawProbe(Canvas c, _Frame f) {
    if (isOn) _drawGlow(c, f, 250, 755);

    // PVDF upper body
    _cyl(
      c,
      f.r(214, 586, 286, 656),
      const [Color(0xFF9EA4A8), Color(0xFFE6E9EB), Color(0xFFFFFFFF), Color(0xFFCFD4D7), Color(0xFF8F9599)],
      _steelStops,
      radius: f.len(4),
    );
    c.drawRect(
      f.r(214, 586, 286, 604),
      _fillV(f.r(214, 586, 286, 604), [Colors.black.withValues(alpha: 0.3), Colors.transparent]),
    );

    // electrode rings and black insulators
    const List<Color> insul = [Color(0xFF0A0C0E), Color(0xFF2A3036), Color(0xFF5B656E), Color(0xFF2A3036), Color(0xFF0A0C0E)];
    _cyl(c, f.r(214, 656, 286, 682), _steel, _steelStops, radius: f.len(3));
    _cyl(c, f.r(216, 682, 284, 692), insul, _steelStops, radius: f.len(2));
    _cyl(c, f.r(214, 692, 286, 718), _steel, _steelStops, radius: f.len(3));
    _cyl(c, f.r(216, 718, 284, 726), insul, _steelStops, radius: f.len(2));

    // rounded graphite tip
    final Path tip = Path()
      ..moveTo(f.x(216), f.y(726))
      ..lineTo(f.x(284), f.y(726))
      ..lineTo(f.x(284), f.y(748))
      ..cubicTo(f.x(284), f.y(768), f.x(268), f.y(778), f.x(250), f.y(778))
      ..cubicTo(f.x(232), f.y(778), f.x(216), f.y(768), f.x(216), f.y(748))
      ..close();
    c.drawPath(
      tip,
      _fillH(f.r(216, 726, 284, 778), const [Color(0xFF08090A), Color(0xFF2B3035), Color(0xFF66707A), Color(0xFF2B3035), Color(0xFF08090A)],
          stops: _absStops),
    );
    c.drawPath(tip, _stroke(_edge, f.len(1.2)));
    c.drawOval(
      f.r(228, 734, 244, 756),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  // ---------------------------------------------------------------- fitting
  void _drawFitting(Canvas c, _Frame f) {
    // threaded section
    _cyl(c, f.r(218, 526, 282, 590), _steel, _steelStops, radius: f.len(3));
    if (showJoints) _threads(c, f, 218, 530, 282, 586);
    c.drawRect(
      f.r(218, 526, 282, 546),
      _fillV(f.r(218, 526, 282, 546), [Colors.black.withValues(alpha: 0.35), Colors.transparent]),
    );

    // O-ring
    final Rect o = f.r(210, 518, 290, 528);
    c.drawRRect(
      RRect.fromRectAndRadius(o, Radius.circular(f.len(5))),
      _fillV(o, const [Color(0xFF3A3F44), Color(0xFF0B0D0F)]),
    );

    // hex process nut
    _hex(c, f, 188, 470, 312, 520);
    final Rect sh = f.r(188, 470, 312, 486);
    c.drawRect(sh, _fillV(sh, [Colors.black.withValues(alpha: 0.4), Colors.transparent]));
  }

  // ------------------------------------------------------------------- head
  void _drawHead(Canvas c, _Frame f) {
    final Rect r = f.r(160, 206, 340, 470);
    final RRect rr = RRect.fromRectAndCorners(
      r,
      topLeft: Radius.circular(f.len(22)),
      topRight: Radius.circular(f.len(22)),
      bottomLeft: Radius.circular(f.len(14)),
      bottomRight: Radius.circular(f.len(14)),
    );
    c.drawRRect(rr, _fillH(r, _abs, stops: _absStops));
    c.drawRRect(
      rr,
      _fillV(r, [
        Colors.white.withValues(alpha: 0.10),
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: 0.28),
      ], stops: const [0.0, 0.08, 0.8, 1.0]),
    );

    // glossy specular strips
    final Rect s1 = f.r(180, 232, 192, 450);
    c.drawRRect(
      RRect.fromRectAndRadius(s1, Radius.circular(f.len(6))),
      _fillV(s1, [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.02)]),
    );
    final Rect s2 = f.r(318, 240, 323, 440);
    c.drawRRect(
      RRect.fromRectAndRadius(s2, Radius.circular(f.len(3))),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // accent rings
    for (final List<double> b in const [
      [232.0, 246.0],
      [440.0, 452.0],
    ]) {
      final Rect br = f.r(160, b[0], 340, b[1]);
      c.drawRect(br, _fillH(br, [_accD, _acc, _accL, _acc, _accD], stops: _steelStops));
      c.drawRect(br, _stroke(_edge.withValues(alpha: 0.85), f.len(1)));
      c.drawLine(f.p(160, b[0] + 1.5), f.p(340, b[0] + 1.5), _stroke(Colors.white.withValues(alpha: 0.35), f.len(1)));
    }

    c.drawRRect(rr, _stroke(_edge, f.len(2)));

    if (showJoints) {
      for (final Offset o in [f.p(182, 262), f.p(318, 262), f.p(182, 424), f.p(318, 424)]) {
        _screw(c, o, f.len(6));
      }
    }

    // label plate
    final Rect pl = f.r(206, 366, 294, 394);
    final RRect plr = RRect.fromRectAndRadius(pl, Radius.circular(f.len(6)));
    c.drawRRect(plr, _fillH(pl, [_accD, _acc, _accL, _acc, _accD], stops: _steelStops));
    c.drawRRect(plr, _stroke(_edge, f.len(1.2)));
    if (showLabels) {
      _text(
        c,
        'EC',
        f.p(250, 380),
        f.len(20),
        Colors.white,
        weight: FontWeight.w800,
        spacing: 1.5,
        shadows: const [Shadow(color: Color(0x88000000), blurRadius: 2, offset: Offset(0, 1))],
      );
    }
  }

  // ----------------------------------------------------------- display, LED
  void _drawDisplayAndLed(Canvas c, _Frame f) {
    // bezel
    final RRect bez = RRect.fromRectAndRadius(f.r(186, 260, 314, 352), Radius.circular(f.len(10)));
    c.drawRRect(bez, _fillV(f.r(186, 260, 314, 352), const [Color(0xFF050607), Color(0xFF1A1F24)]));
    c.drawRRect(bez, _stroke(const Color(0xFF3A444C), f.len(1.5)));

    // glass
    final Rect gr = f.r(194, 268, 306, 344);
    final RRect grr = RRect.fromRectAndRadius(gr, Radius.circular(f.len(6)));
    if (isOn) {
      c.drawRRect(grr, _fillV(gr, const [Color(0xFF0B4A52), Color(0xFF08323A)]));
    } else {
      c.drawRRect(grr, _fillV(gr, const [Color(0xFF1D2428), Color(0xFF12171A)]));
    }

    final double? v = ecValue;
    final String num = isOn ? (v ?? 2.4).toStringAsFixed(1) : '--.-';
    final Color digit = isOn ? const Color(0xFF7FF3FF) : const Color(0xFF2E383D);
    _text(
      c,
      num,
      f.p(250, 303),
      f.len(42),
      digit,
      family: 'monospace',
      weight: FontWeight.w800,
      shadows: isOn ? [Shadow(color: digit.withValues(alpha: 0.8), blurRadius: f.len(8))] : null,
    );
    _text(
      c,
      'mS/cm',
      f.p(250, 334),
      f.len(15),
      isOn ? digit.withValues(alpha: 0.85) : const Color(0xFF2E383D),
      weight: FontWeight.w600,
      spacing: 0.8,
    );

    // glass reflection
    c.save();
    c.clipRRect(grr);
    c.drawPath(
      Path()
        ..moveTo(f.x(194), f.y(268))
        ..lineTo(f.x(262), f.y(268))
        ..lineTo(f.x(216), f.y(344))
        ..lineTo(f.x(194), f.y(344))
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    c.restore();
    c.drawLine(f.p(198, 270), f.p(302, 270), _stroke(Colors.white.withValues(alpha: 0.25), f.len(1.2)));
    c.drawRRect(grr, _stroke(Colors.black.withValues(alpha: 0.7), f.len(1.4)));

    // status LED
    final Offset led = f.p(250, 422);
    final double lr = f.len(12);
    c.drawCircle(led, lr, _fillV(Rect.fromCircle(center: led, radius: lr), const [Color(0xFFD9DFE3), Color(0xFF5A646B)]));
    c.drawCircle(led, lr, _stroke(_edge, f.len(1.2)));
    if (isOn) {
      c.drawCircle(
        led,
        lr * 1.5,
        Paint()
          ..color = const Color(0x6600E676)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.len(6)),
      );
    }
    final Rect lens = Rect.fromCircle(center: led, radius: lr * 0.66);
    c.drawCircle(
      led,
      lr * 0.66,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: isOn
              ? const [Color(0xFFB9F6CA), Color(0xFF00E676), Color(0xFF00963F)]
              : const [Color(0xFF6B7A80), Color(0xFF39454A), Color(0xFF232B2F)],
        ).createShader(lens),
    );
    c.drawCircle(led.translate(-lr * 0.2, -lr * 0.22), lr * 0.18, Paint()..color = Colors.white.withValues(alpha: 0.7));
  }

  // ---------------------------------------------- cable, boot, gland nut
  void _drawGland(Canvas c, _Frame f) {
    // cable (fades out at the top so it reads as "continues")
    final Path cable = Path()
      ..moveTo(f.x(250), f.y(104))
      ..cubicTo(f.x(250), f.y(70), f.x(258), f.y(40), f.x(268), f.y(0));
    final Rect fade = f.r(230, 0, 290, 110);
    Paint cp(Color col, double w) => Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.butt
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [col, col, col.withValues(alpha: 0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(fade);
    c.drawPath(cable, cp(const Color(0xFF05070A), f.len(24)));
    c.drawPath(cable, cp(const Color(0xFF1B2025), f.len(20)));
    c.drawPath(cable.shift(Offset(-f.len(4.5), 0)), cp(const Color(0x55FFFFFF), f.len(4)));

    // rubber strain-relief boot
    final Path boot = Path()
      ..moveTo(f.x(236), f.y(98))
      ..lineTo(f.x(264), f.y(98))
      ..quadraticBezierTo(f.x(268), f.y(135), f.x(284), f.y(164))
      ..lineTo(f.x(216), f.y(164))
      ..quadraticBezierTo(f.x(232), f.y(135), f.x(236), f.y(98))
      ..close();
    final Rect bb = f.r(216, 98, 284, 164);
    c.drawPath(
      boot,
      _fillH(bb, const [Color(0xFF0A0C0E), Color(0xFF262C32), Color(0xFF55606A), Color(0xFF262C32), Color(0xFF0A0C0E)],
          stops: _absStops),
    );
    for (final double y in [112.0, 126.0, 140.0, 154.0]) {
      final double t = (y - 98) / 66;
      final double half = 14 + 20 * t * t;
      final Path rib = Path()
        ..moveTo(f.x(250 - half), f.y(y))
        ..quadraticBezierTo(f.x(250), f.y(y + 5), f.x(250 + half), f.y(y));
      c.drawPath(rib, _stroke(Colors.black.withValues(alpha: 0.75), f.len(2)));
      c.drawPath(rib.shift(Offset(0, f.len(2))), _stroke(Colors.white.withValues(alpha: 0.12), f.len(1.2)));
    }
    c.drawPath(boot, _stroke(_edge, f.len(1.4)));

    // stainless gland nut
    _hex(c, f, 203, 164, 297, 208);
    c.drawRect(
      f.r(203, 198, 297, 208),
      _fillV(f.r(203, 198, 297, 208), [Colors.transparent, Colors.black.withValues(alpha: 0.35)]),
    );
  }

  @override
  bool shouldRepaint(covariant DetailedEcSensorPainter old) {
    return old.isOn != isOn ||
        old.showJoints != showJoints ||
        old.showLabels != showLabels ||
        old.ecValue != ecValue;
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