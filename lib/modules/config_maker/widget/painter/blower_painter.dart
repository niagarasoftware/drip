import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Colour scheme for the blower. Every body part has its own colour; the
/// painter automatically derives highlight / shadow tones from each one, so
/// you only need to pick a single base colour per part.
class BlowerPalette {
  final Color housing; // ring casing
  final Color silencer; // lower body + outlet pipe
  final Color motor; // motor barrel
  final Color fanCover; // rear fan cover
  final Color terminalBox; // top junction box
  final Color base; // pedestal + base plate
  final Color accent; // hub + chamber ring

  const BlowerPalette({
    required this.housing,
    required this.silencer,
    required this.motor,
    required this.fanCover,
    required this.terminalBox,
    required this.base,
    required this.accent,
  });

  /// Royal-blue housing, graphite motor, amber terminal box.
  static const BlowerPalette industrialBlue = BlowerPalette(
    housing: Color(0xFF1E88E5),
    silencer: Color(0xFF1565C0),
    motor: Color(0xFF546E7A),
    fanCover: Color(0xFF37474F),
    terminalBox: Color(0xFFFFA000),
    base: Color(0xFF37474F),
    accent: Color(0xFFFF6F00),
  );

  /// Green housing with a dark motor.
  static const BlowerPalette forestGreen = BlowerPalette(
    housing: Color(0xFF2E9E5B),
    silencer: Color(0xFF1B7A43),
    motor: Color(0xFF4E5D63),
    fanCover: Color(0xFF2F3A3F),
    terminalBox: Color(0xFFFFB300),
    base: Color(0xFF2F3A3F),
    accent: Color(0xFFFFC107),
  );

  /// Red housing with a charcoal motor.
  static const BlowerPalette crimson = BlowerPalette(
    housing: Color(0xFFD32F2F),
    silencer: Color(0xFFB71C1C),
    motor: Color(0xFF455A64),
    fanCover: Color(0xFF263238),
    terminalBox: Color(0xFFECEFF1),
    base: Color(0xFF263238),
    accent: Color(0xFFFFB300),
  );

  /// Original silver aluminium look.
  static const BlowerPalette silver = BlowerPalette(
    housing: Color(0xFFA6B0B8),
    silencer: Color(0xFFA6B0B8),
    motor: Color(0xFFA6B0B8),
    fanCover: Color(0xFF8A949C),
    terminalBox: Color(0xFFA6B0B8),
    base: Color(0xFF8A949C),
    accent: Color(0xFFA6B0B8),
  );
}

/// Five-tone ramp (highlight -> deep shadow) derived from one base colour.
class _Ramp {
  final Color hi, light, mid, dark, deep;
  const _Ramp(this.hi, this.light, this.mid, this.dark, this.deep);

  factory _Ramp.from(Color c) {
    final HSLColor hsl = HSLColor.fromColor(c);
    final double l = hsl.lightness;
    final double s = hsl.saturation;
    Color at(double lightness, [double? sat]) => hsl
        .withLightness(lightness.clamp(0.0, 1.0))
        .withSaturation((sat ?? s).clamp(0.0, 1.0))
        .toColor();
    return _Ramp(
      at(l + 0.38, s * 0.7),
      at(l + 0.17),
      c,
      at(l * 0.68),
      at(l * 0.38),
    );
  }

  List<Color> get cylinder => [dark, mid, light, hi, light, mid, dark, deep];
}

/// Realistic industrial ring blower painter (single outlet, left side).
///
/// [isOn]       - running state (LED, glow, airflow)
/// [showJoints] - bolts / screws
/// [phase]      - impeller rotation angle in radians
/// [speed]      - 0..1 normalised spin speed; drives motion-blur trails,
///                glow and a slight vibration
/// [palette]    - body colours
class DetailedBlowerPainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;
  final double phase;
  final double speed;
  final BlowerPalette palette;

  final _Ramp _h, _s, _m, _fc, _t, _b, _acc;

  DetailedBlowerPainter({
    required this.isOn,
    this.showJoints = true,
    this.phase = 0.0,
    this.speed = 0.0,
    this.palette = BlowerPalette.industrialBlue,
  })  : _h = _Ramp.from(palette.housing),
        _s = _Ramp.from(palette.silencer),
        _m = _Ramp.from(palette.motor),
        _fc = _Ramp.from(palette.fanCover),
        _t = _Ramp.from(palette.terminalBox),
        _b = _Ramp.from(palette.base),
        _acc = _Ramp.from(palette.accent);

  static const double _refW = 800.0;
  static const double _refH = 750.0;

  static const Offset _cFront = Offset(250, 340);
  static const Offset _cBack = Offset(282, 324);
  static const double _casR = 200.0;

  // Neutral metal (bolts, impeller, pipe lip)
  static const Color _edge = Color(0xFF1E2328);
  static const Color _silverHi = Color(0xFFFAFCFD);
  static const Color _silverLight = Color(0xFFE2E7EC);
  static const Color _silverMid = Color(0xFFA6B0B8);
  static const Color _silverDark = Color(0xFF6B7680);
  static const Color _silverDeep = Color(0xFF3B434A);
  static const Color _steelDark = Color(0xFF2C333A);
  static const Color _steelBlack = Color(0xFF1B2025);
  static const Color _accentGreen = Color(0xFF00E676);
  static const Color _redArrow = Color(0xFFE53935);

  static const List<double> _cylStops = [0.0, 0.1, 0.22, 0.38, 0.55, 0.75, 0.9, 1.0];

  /// Outlet port (left pipe mouth) - the blower's only port.
  static Offset outletPort(Size s) => Offset(s.width * -0.01, s.height * 0.74);

  @Deprecated('This blower only has an outlet (left side).')
  static Offset inletPort(Size s) => outletPort(s);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width / _refW, size.height / _refH);
    final _Frame f = _Frame(s, size.width / 2, (size.height - _refH * s) / 2);

    _drawDropShadow(canvas, f);
    _drawBaseAndPedestal(canvas, f);

    // Slight vibration of the machine body while spinning fast
    canvas.save();
    if (speed > 0.05) {
      canvas.translate(
        math.sin(phase * 7.0) * f.len(0.7) * speed,
        math.cos(phase * 5.0) * f.len(0.5) * speed,
      );
    }
    _drawMotor(canvas, f);
    _drawTerminalBox(canvas, f);
    _drawSilencerAndOutlet(canvas, f);
    _drawHousingDepth(canvas, f);
    _drawLiftingEye(canvas, f);
    _drawHousingFace(canvas, f);
    _drawImpeller(canvas, f);
    _drawLabelsAndArrow(canvas, f);
    _drawStatusLed(canvas, f);
    if (speed > 0.05) _drawAirflow(canvas, f);
    if (showJoints) _drawJointsAndBolts(canvas, f);
    canvas.restore();
  }

  // ---------------------------------------------------------------------------

  void _stroke(Canvas c, RRect r, double w, Color col) => c.drawRRect(
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, w)
      ..color = col,
  );

  void _drawDropShadow(Canvas canvas, _Frame f) {
    canvas.drawOval(
      f.rect(60, 628, 730, 700),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(2.0, f.len(16))),
    );
  }

  void _drawBaseAndPedestal(Canvas canvas, _Frame f) {
    final Rect ped = f.rect(540, 430, 645, 618);
    final RRect pedR = RRect.fromRectAndRadius(ped, Radius.circular(f.len(6)));
    canvas.drawRRect(
      pedR,
      Paint()
        ..shader = LinearGradient(
          colors: [_b.deep, _b.mid, _b.light, _b.dark, _b.deep],
          stops: const [0.0, 0.25, 0.45, 0.8, 1.0],
        ).createShader(ped),
    );
    _stroke(canvas, pedR, f.len(2.5), _edge);
    canvas.drawRRect(
      RRect.fromRectAndRadius(f.rect(570, 470, 615, 575), Radius.circular(f.len(10))),
      Paint()..color = const Color(0xFF14181C),
    );

    final Rect plate = f.rect(115, 612, 665, 644);
    final RRect pr = RRect.fromRectAndRadius(plate, Radius.circular(f.len(5)));
    canvas.drawRRect(
      pr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_b.light, _b.mid, _b.dark, _b.deep],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(plate),
    );
    _stroke(canvas, pr, f.len(2.5), _edge);

    // Safety-yellow edge stripe on the base plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(f.rect(125, 633, 655, 638), Radius.circular(f.len(2))),
      Paint()..color = _acc.mid.withValues(alpha: 0.9),
    );

    for (final double x in const [160.0, 300.0, 520.0, 620.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(f.rect(x - 28, 644, x + 28, 660), Radius.circular(f.len(4))),
        Paint()..color = _steelBlack,
      );
    }
  }

  void _drawMotor(Canvas canvas, _Frame f) {
    final Rect body = f.rect(430, 209, 658, 439);
    final RRect br = RRect.fromRectAndRadius(body, Radius.circular(f.len(10)));
    canvas.drawRRect(
      br,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _m.cylinder,
          stops: _cylStops,
        ).createShader(body),
    );

    final Paint finDark = Paint()
      ..color = _m.deep.withValues(alpha: 0.7)
      ..strokeWidth = math.max(0.8, f.len(4.0));
    final Paint finLight = Paint()
      ..color = _m.hi.withValues(alpha: 0.5)
      ..strokeWidth = math.max(0.5, f.len(1.6));
    for (double y = 222; y <= 428; y += 14) {
      canvas.drawLine(f.p(432, y), f.p(656, y), finDark);
      canvas.drawLine(f.p(432, y + 2.5), f.p(656, y + 2.5), finLight);
    }
    _stroke(canvas, br, f.len(2.5), _edge);

    // Drive-end flange in housing colour
    final Rect fl = f.rect(440, 198, 470, 450);
    final RRect flR = RRect.fromRectAndRadius(fl, Radius.circular(f.len(5)));
    canvas.drawRRect(
      flR,
      Paint()
        ..shader = LinearGradient(colors: [_h.mid, _h.light, _h.dark]).createShader(fl),
    );
    _stroke(canvas, flR, f.len(2), _edge);

    // Rear fan cover
    final Rect cap = f.rect(650, 203, 738, 445);
    final RRect cr = RRect.fromRectAndRadius(cap, Radius.circular(f.len(26)));
    canvas.drawRRect(
      cr,
      Paint()
        ..shader = LinearGradient(
          colors: [_fc.mid, _fc.light, _fc.mid, _fc.dark, _fc.deep],
          stops: const [0.0, 0.25, 0.5, 0.8, 1.0],
        ).createShader(cap),
    );

    canvas.save();
    canvas.clipRRect(cr);
    final Paint slotPaint = Paint()..color = const Color(0xFF0E1114);
    final Paint slotRim = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.4, f.len(1.0));
    for (double y = 228; y <= 428; y += 15) {
      for (double x = 690; x <= 728; x += 12) {
        final RRect sr = RRect.fromRectAndRadius(
            f.rect(x, y, x + 7, y + 10), Radius.circular(f.len(2.5)));
        canvas.drawRRect(sr, slotPaint);
        canvas.drawRRect(sr.shift(Offset(f.len(0.8), f.len(0.8))), slotRim);
      }
    }
    for (double y = 232; y <= 424; y += 12) {
      canvas.drawLine(
        f.p(656, y),
        f.p(684, y),
        Paint()
          ..color = _fc.deep.withValues(alpha: 0.6)
          ..strokeWidth = math.max(0.6, f.len(2.5)),
      );
    }
    canvas.restore();
    _stroke(canvas, cr, f.len(2.5), _edge);
  }

  void _drawTerminalBox(Canvas canvas, _Frame f) {
    final Rect box = f.rect(520, 136, 622, 212);
    final RRect bx = RRect.fromRectAndRadius(box, Radius.circular(f.len(6)));
    canvas.drawRRect(
      bx,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_t.hi, _t.light, _t.mid, _t.dark],
          stops: const [0.0, 0.25, 0.7, 1.0],
        ).createShader(box),
    );
    _stroke(canvas, bx, f.len(2.5), _edge);

    final Rect lid = f.rect(514, 128, 628, 146);
    final RRect lr = RRect.fromRectAndRadius(lid, Radius.circular(f.len(5)));
    canvas.drawRRect(
      lr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_t.hi, _t.mid, _t.dark],
        ).createShader(lid),
    );
    _stroke(canvas, lr, f.len(2), _edge);

    final Rect gl = f.rect(622, 160, 646, 190);
    final RRect gr = RRect.fromRectAndRadius(gl, Radius.circular(f.len(3)));
    canvas.drawRRect(
      gr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_steelBlack, _silverDark, _steelBlack],
        ).createShader(gl),
    );
    _stroke(canvas, gr, f.len(1.5), _edge);
    for (final double x in const [630.0, 638.0]) {
      canvas.drawLine(
        f.p(x, 161),
        f.p(x, 189),
        Paint()
          ..color = _silverLight.withValues(alpha: 0.6)
          ..strokeWidth = math.max(0.4, f.len(1.0)),
      );
    }
  }

  void _drawSilencerAndOutlet(Canvas canvas, _Frame f) {
    final Rect sil = f.rect(110, 500, 450, 610);
    final RRect sr = RRect.fromRectAndRadius(sil, Radius.circular(f.len(14)));
    canvas.drawRRect(
      sr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _s.cylinder,
          stops: _cylStops,
        ).createShader(sil),
    );
    _stroke(canvas, sr, f.len(2.5), _edge);

    for (final double y in const [520.0, 600.0]) {
      canvas.drawLine(
        f.p(130, y),
        f.p(430, y),
        Paint()
          ..color = _s.deep.withValues(alpha: 0.4)
          ..strokeWidth = math.max(0.6, f.len(2.0)),
      );
    }

    // Outlet pipe (left)
    final Rect pipe = f.rect(40, 513, 118, 597);
    final RRect pipeR = RRect.fromRectAndRadius(pipe, Radius.circular(f.len(4)));
    canvas.drawRRect(
      pipeR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _s.cylinder,
          stops: _cylStops,
        ).createShader(pipe),
    );
    _stroke(canvas, pipeR, f.len(2.2), _edge);

    // Polished metal lip + dark opening
    final Rect lip = f.rect(28, 509, 56, 601);
    canvas.drawOval(
      lip,
      Paint()
        ..shader = const LinearGradient(
          colors: [_silverDeep, _silverLight, _silverMid],
        ).createShader(lip),
    );
    canvas.drawOval(
      lip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, f.len(2.2))
        ..color = _edge,
    );
    final Rect hole = f.rect(33, 518, 53, 592);
    canvas.drawOval(
      hole,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF3A444D), Color(0xFF0B0D10)],
        ).createShader(hole),
    );

    // Flange collar in accent colour
    final Rect fl = f.rect(98, 497, 122, 613);
    final RRect flR = RRect.fromRectAndRadius(fl, Radius.circular(f.len(5)));
    canvas.drawRRect(
      flR,
      Paint()
        ..shader = LinearGradient(colors: [_acc.light, _acc.hi, _acc.dark]).createShader(fl),
    );
    _stroke(canvas, flR, f.len(2.2), _edge);
  }

  void _drawHousingDepth(Canvas canvas, _Frame f) {
    final Offset d = _cBack - _cFront;
    final Offset dir = d / d.distance;
    final Offset n = Offset(-dir.dy, dir.dx) * _casR;

    final Path hull = Path()
      ..moveTo(f.x(_cFront.dx + n.dx), f.y(_cFront.dy + n.dy))
      ..lineTo(f.x(_cBack.dx + n.dx), f.y(_cBack.dy + n.dy))
      ..lineTo(f.x(_cBack.dx - n.dx), f.y(_cBack.dy - n.dy))
      ..lineTo(f.x(_cFront.dx - n.dx), f.y(_cFront.dy - n.dy))
      ..close();

    final Rect bounds = Rect.fromCircle(center: f.pp(_cBack), radius: f.len(_casR));
    final Paint wall = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_h.light, _h.mid, _h.dark, _h.deep],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(bounds);

    canvas.drawCircle(f.pp(_cBack), f.len(_casR), wall);
    canvas.drawPath(hull, wall);
    canvas.drawCircle(
      f.pp(_cBack),
      f.len(_casR),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, f.len(3.0))
        ..color = _edge,
    );
    canvas.drawCircle(
      f.pp(_cBack),
      f.len(_casR - 10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, f.len(1.5))
        ..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  void _drawLiftingEye(Canvas canvas, _Frame f) {
    final Offset base = f.p(262, 140);
    canvas.drawCircle(base, f.len(13), Paint()..color = _silverDark);
    canvas.drawCircle(
      base,
      f.len(13),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, f.len(2))
        ..color = _edge,
    );
    final Offset ringC = f.p(262, 124);
    canvas.drawCircle(
      ringC,
      f.len(13),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, f.len(6))
        ..color = _silverDeep,
    );
    canvas.drawCircle(
      ringC,
      f.len(13),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, f.len(2))
        ..color = _silverLight,
    );
  }

  void _drawHousingFace(Canvas canvas, _Frame f) {
    final Offset c = f.pp(_cFront);
    final double R = f.len(_casR);

    canvas.drawCircle(
      c,
      R,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          radius: 1.0,
          colors: [_h.hi, _h.light, _h.mid, _h.dark, _h.deep],
          stops: const [0.0, 0.3, 0.6, 0.88, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: R)),
    );
    canvas.drawCircle(
      c,
      R,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, f.len(3.0))
        ..color = _edge,
    );

    // Perimeter lugs
    for (int i = 0; i < 8; i++) {
      final double a = i * math.pi / 4 + math.pi / 8;
      final Offset lp = c + Offset(math.cos(a), math.sin(a)) * f.len(_casR - 6);
      canvas.drawCircle(lp, f.len(14), Paint()..color = _h.mid);
      canvas.drawCircle(
        lp,
        f.len(14),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, f.len(2))
          ..color = _edge,
      );
    }

    // Raised rim band
    canvas.drawCircle(
      c,
      f.len(180),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, f.len(7))
        ..shader = SweepGradient(
          colors: [_h.hi, _h.mid, _h.dark, _h.hi, _h.mid, _h.dark, _h.hi],
        ).createShader(Rect.fromCircle(center: c, radius: R)),
    );

    // Radial ribs
    final Paint ribDark = Paint()
      ..color = _h.deep.withValues(alpha: 0.75)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.8, f.len(5));
    final Paint ribHi = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.5, f.len(1.8));
    for (int i = 0; i < 24; i++) {
      final double a = i * math.pi / 12;
      final Offset dir = Offset(math.cos(a), math.sin(a));
      final Offset p1 = c + dir * f.len(156);
      final Offset p2 = c + dir * f.len(172);
      canvas.drawLine(p1, p2, ribDark);
      canvas.drawLine(p1 + Offset(f.len(1), f.len(1)), p2 + Offset(f.len(1), f.len(1)), ribHi);
    }

    // Inner bevel
    canvas.drawCircle(
      c,
      f.len(154),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, f.len(6))
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_h.deep, _h.hi],
        ).createShader(Rect.fromCircle(center: c, radius: f.len(154))),
    );
    // Accent ring around the chamber
    canvas.drawCircle(
      c,
      f.len(149),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, f.len(3.5))
        ..color = _acc.mid,
    );
  }

  Path _bladePath(Offset c, double a0, double innerR, double outerR) {
    final Offset p1 = c + Offset(math.cos(a0), math.sin(a0)) * innerR;
    final Offset p2 = c + Offset(math.cos(a0 + 0.55), math.sin(a0 + 0.55)) * outerR;
    final double mr = (innerR + outerR) * 0.5;
    final Offset ctrl = c + Offset(math.cos(a0 + 0.08), math.sin(a0 + 0.08)) * mr;
    return Path()
      ..moveTo(p1.dx, p1.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
  }

  void _drawImpeller(Canvas canvas, _Frame f) {
    final Offset c = f.pp(_cFront);
    final double chamberR = f.len(146);

    canvas.drawCircle(
      c,
      chamberR,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF424B54), Color(0xFF23292F), Color(0xFF0E1114)],
          stops: [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: chamberR)),
    );

    const int n = 24;
    final double innerR = f.len(58);
    final double outerR = f.len(140);
    final double rot = phase;

    final Paint shadowP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, f.len(8))
      ..color = const Color(0xAA000000);
    final Paint bladeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, f.len(6))
      ..color = Color.lerp(_silverMid, const Color(0xFFD6E4F0), speed)!
          .withValues(alpha: 1.0 - 0.3 * speed);
    final Paint edgeP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.5, f.len(1.8))
      ..color = Colors.white.withValues(alpha: 0.75 * (1.0 - 0.4 * speed));
    final Paint glowP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, f.len(8))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.len(4))
      ..color = _accentGreen.withValues(alpha: 0.4 * speed);

    // Motion-blur trails behind the vanes
    if (speed > 0.08) {
      final double step = 0.06 * speed;
      for (int k = 3; k >= 1; k--) {
        final Paint trail = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1.0, f.len(6))
          ..color = const Color(0xFFD6E4F0).withValues(alpha: 0.16 * speed * (4 - k) / 3);
        for (int i = 0; i < n; i++) {
          canvas.drawPath(
            _bladePath(c, i * 2 * math.pi / n + rot - k * step, innerR, outerR),
            trail,
          );
        }
      }
    }

    for (int i = 0; i < n; i++) {
      final Path blade = _bladePath(c, i * 2 * math.pi / n + rot, innerR, outerR);
      if (speed > 0.05) canvas.drawPath(blade, glowP);
      canvas.drawPath(blade.shift(Offset(f.len(1.5), f.len(2))), shadowP);
      canvas.drawPath(blade, bladeP);
      canvas.drawPath(blade.shift(Offset(-f.len(0.8), -f.len(0.8))), edgeP);
    }

    // Translucent "blur disc" at high speed
    if (speed > 0.4) {
      canvas.drawCircle(
        c,
        outerR,
        Paint()
          ..shader = SweepGradient(
            transform: GradientRotation(rot),
            colors: [
              Colors.white.withValues(alpha: 0.02),
              Colors.white.withValues(alpha: 0.12 * speed),
              Colors.white.withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: outerR)),
      );
    }

    // Outer impeller rim
    canvas.drawCircle(
      c,
      outerR + f.len(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, f.len(6))
        ..shader = const SweepGradient(
          colors: [_silverLight, _silverDark, _silverLight, _silverDark, _silverLight],
        ).createShader(Rect.fromCircle(center: c, radius: outerR)),
    );

    // Running shimmer ring
    if (speed > 0.05) {
      canvas.drawCircle(
        c,
        chamberR * 0.92,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, f.len(3.5))
          ..shader = SweepGradient(
            transform: GradientRotation(phase * 2),
            colors: [
              _accentGreen.withValues(alpha: 0.05),
              _accentGreen.withValues(alpha: 0.55 * speed),
              Colors.white.withValues(alpha: 0.75 * speed),
              _accentGreen.withValues(alpha: 0.05),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: chamberR)),
      );
    }

    // Hub in accent colour (rotates with a marker so the spin is visible)
    final double hubR = f.len(54);
    canvas.drawCircle(
      c,
      hubR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [_acc.hi, _acc.light, _acc.mid, _acc.dark],
        ).createShader(Rect.fromCircle(center: c, radius: hubR)),
    );
    canvas.drawCircle(
      c,
      hubR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, f.len(2.5))
        ..color = _edge,
    );
    for (final double r in const [44.0, 32.0]) {
      canvas.drawCircle(
        c,
        f.len(r),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.4, f.len(1.2))
          ..color = _acc.deep.withValues(alpha: 0.5),
      );
    }
    // Rotating hub marks
    for (int i = 0; i < 3; i++) {
      final double a = rot + i * 2 * math.pi / 3;
      final Offset dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        c + dir * f.len(22),
        c + dir * f.len(40),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(0.8, f.len(4))
          ..color = _acc.deep.withValues(alpha: 0.8),
      );
    }
    _hexBolt(canvas, c, f.len(16), angle: rot);
    canvas.drawCircle(c, f.len(5), Paint()..color = _steelBlack);
  }

  void _drawLabelsAndArrow(Canvas canvas, _Frame f) {
    final Path arrow = Path()
      ..moveTo(f.x(300), f.y(547))
      ..lineTo(f.x(235), f.y(547))
      ..lineTo(f.x(235), f.y(534))
      ..lineTo(f.x(195), f.y(555))
      ..lineTo(f.x(235), f.y(576))
      ..lineTo(f.x(235), f.y(563))
      ..lineTo(f.x(300), f.y(563))
      ..close();
    canvas.drawPath(
      arrow.shift(Offset(f.len(1.5), f.len(1.5))),
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawPath(arrow, Paint()..color = _redArrow);
    canvas.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, f.len(1.5))
        ..color = const Color(0xFF801010),
    );

    final RRect lr =
    RRect.fromRectAndRadius(f.rect(320, 548, 440, 598), Radius.circular(f.len(4)));
    canvas.drawRRect(lr, Paint()..color = const Color(0xFFF7F9FA));
    _stroke(canvas, lr, f.len(1.5), _silverDark);

    final Path tri = Path()
      ..moveTo(f.x(328), f.y(588))
      ..lineTo(f.x(341), f.y(562))
      ..lineTo(f.x(354), f.y(588))
      ..close();
    canvas.drawPath(tri, Paint()..color = const Color(0xFFFFA000));
    _text(canvas, '!', f.p(341, 582), f.len(13), Colors.black, weight: FontWeight.w900);
    _text(canvas, 'RING BLOWER', f.p(396, 566), f.len(9), const Color(0xFF1E2328),
        weight: FontWeight.w800);
    _text(canvas, '2.2 kW / 290 mbar', f.p(396, 582), f.len(7.5), const Color(0xFF455A64),
        weight: FontWeight.w600);

    final RRect pr =
    RRect.fromRectAndRadius(f.rect(500, 296, 622, 346), Radius.circular(f.len(3)));
    canvas.drawRRect(pr, Paint()..color = const Color(0xFFCFD8DC));
    _stroke(canvas, pr, f.len(1.2), _steelDark);
    _text(canvas, '3-PHASE INDUCTION MOTOR', f.p(561, 311), f.len(7.5),
        const Color(0xFF263238), weight: FontWeight.w700);
    _text(canvas, '50 Hz  2900 RPM  IP55', f.p(561, 328), f.len(7), const Color(0xFF37474F),
        weight: FontWeight.w500);
  }

  void _drawStatusLed(Canvas canvas, _Frame f) {
    final Offset p = f.p(540, 182);
    final double r = f.len(7);
    if (isOn) {
      canvas.drawCircle(
        p,
        r * 2.2,
        Paint()
          ..color = _accentGreen.withValues(alpha: 0.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.0, f.len(6))),
      );
    }
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: isOn
              ? const [Color(0xFFB9FFD6), Color(0xFF00C853), Color(0xFF007E33)]
              : const [Color(0xFFB0BEC5), Color(0xFF78909C), Color(0xFF37474F)],
        ).createShader(Rect.fromCircle(center: p, radius: r)),
    );
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, f.len(1.5))
        ..color = _edge,
    );
  }

  /// Air streaks leaving the outlet (left side).
  void _drawAirflow(Canvas canvas, _Frame f) {
    for (int i = 0; i < 3; i++) {
      final double t = ((phase / (2 * math.pi)) * 0.5 + i / 3) % 1.0;
      final double x = 30 - t * 30;
      final Paint p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.0, f.len(4))
        ..color = _accentGreen.withValues(alpha: (1 - t) * 0.7 * speed);
      for (final double dy in const [-18.0, 0.0, 18.0]) {
        canvas.drawLine(f.p(x, 555 + dy), f.p(x - 14, 555 + dy), p);
      }
    }
  }

  void _drawJointsAndBolts(Canvas canvas, _Frame f) {
    final Offset c = f.pp(_cFront);
    for (int i = 0; i < 8; i++) {
      final double a = i * math.pi / 4 + math.pi / 8;
      _hexBolt(canvas, c + Offset(math.cos(a), math.sin(a)) * f.len(_casR - 6), f.len(8));
    }

    for (final Offset o in const [Offset(522, 137), Offset(620, 137)]) {
      _screw(canvas, f.p(o.dx, o.dy), f.len(3.5));
    }
    _screw(canvas, f.p(532, 204), f.len(3.5));
    _screw(canvas, f.p(610, 204), f.len(3.5));

    for (final double y in const [506.0, 604.0]) {
      _hexBolt(canvas, f.p(110, y), f.len(5));
    }
    for (final double y in const [206.0, 442.0]) {
      _hexBolt(canvas, f.p(455, y), f.len(5.5));
    }
    _screw(canvas, f.p(668, 218), f.len(4));
    _screw(canvas, f.p(668, 430), f.len(4));

    for (final double x in const [160.0, 300.0, 520.0, 620.0]) {
      _hexBolt(canvas, f.p(x, 628), f.len(7));
    }
  }

  // ---------------------------------------------------------------------------
  // Primitives
  // ---------------------------------------------------------------------------

  void _screw(Canvas canvas, Offset p, double r) {
    canvas.drawCircle(p + Offset(r * 0.15, r * 0.15), r, Paint()..color = const Color(0x44000000));
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [_silverHi, _silverMid, _silverDark],
        ).createShader(Rect.fromCircle(center: p, radius: r)),
    );
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.4, r * 0.2)
        ..color = _edge,
    );
    final Paint slot = Paint()
      ..color = _silverDeep
      ..strokeWidth = math.max(0.5, r * 0.35);
    canvas.drawLine(p - Offset(r * 0.5, 0), p + Offset(r * 0.5, 0), slot);
    canvas.drawLine(p - Offset(0, r * 0.5), p + Offset(0, r * 0.5), slot);
  }

  void _hexBolt(Canvas canvas, Offset p, double r, {double angle = 0.0}) {
    canvas.drawCircle(p + Offset(r * 0.15, r * 0.2), r * 1.1, Paint()..color = const Color(0x55000000));

    final Path hex = Path();
    for (int i = 0; i < 6; i++) {
      final double a = i * math.pi / 3 - math.pi / 6 + angle;
      final Offset pt = p + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        hex.moveTo(pt.dx, pt.dy);
      } else {
        hex.lineTo(pt.dx, pt.dy);
      }
    }
    hex.close();

    canvas.drawPath(
      hex,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_silverHi, _silverLight, _silverMid, _silverDark],
        ).createShader(Rect.fromCircle(center: p, radius: r)),
    );
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, r * 0.25)
        ..color = _edge,
    );
    canvas.drawCircle(p, r * 0.45, Paint()..color = _silverDark);
  }

  void _text(
      Canvas canvas,
      String text,
      Offset center,
      double fontSize,
      Color color, {
        FontWeight weight = FontWeight.w600,
      }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant DetailedBlowerPainter old) =>
      old.isOn != isOn ||
          old.showJoints != showJoints ||
          old.phase != phase ||
          old.speed != speed ||
          old.palette != palette;
}

class _Frame {
  final double s;
  final double cx;
  final double oy;

  const _Frame(this.s, this.cx, this.oy);

  double x(double px) => cx + (px - 400) * s;
  double y(double py) => oy + py * s;
  Offset p(double px, double py) => Offset(x(px), y(py));
  Offset pp(Offset o) => Offset(x(o.dx), y(o.dy));
  Rect rect(double l, double t, double r, double b) => Rect.fromLTRB(x(l), y(t), x(r), y(b));
  double len(double v) => v * s;
}

/// Animated blower widget.
///
/// Set [isOn] and the impeller spins up smoothly, runs at [maxSpeed], and
/// coasts down to a stop when switched off - no AnimationController needed.
///
/// If you pass [phase], the widget does NOT animate by itself and uses your
/// angle instead (backwards compatible with the old API).
class BlowerView extends StatefulWidget {
  final bool isOn;
  final bool showJoints;
  final double? phase;
  final Size? size;
  final BlowerPalette palette;

  /// Full-speed rotation in radians per second (10 rad/s is about 1.6 rev/s).
  final double maxSpeed;

  const BlowerView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    this.phase,
    this.size,
    this.palette = BlowerPalette.industrialBlue,
    this.maxSpeed = 10.0,
  });

  static Offset outletPort(Size s) => DetailedBlowerPainter.outletPort(s);

  @Deprecated('This blower only has an outlet (left side).')
  static Offset inletPort(Size s) => DetailedBlowerPainter.outletPort(s);

  @override
  State<BlowerView> createState() => _BlowerViewState();
}

class _BlowerViewState extends State<BlowerView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _angle = 0.0;
  double _omega = 0.0; // current angular velocity (rad/s)

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant BlowerView old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  void _syncTicker() {
    if (widget.phase != null) {
      if (_ticker.isActive) _ticker.stop();
      return;
    }
    if ((widget.isOn || _omega > 0.0) && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final double dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;

    final double target = widget.isOn ? widget.maxSpeed : 0.0;
    final double tau = widget.isOn ? 0.7 : 1.6; // spin-up faster than coast-down
    _omega += (target - _omega) * (1 - math.exp(-dt / tau));
    _angle = (_angle + _omega * dt) % (2 * math.pi);

    if (!widget.isOn && _omega < 0.02) {
      _omega = 0.0;
      _ticker.stop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size effectiveSize = widget.size ?? const Size(160, 150);
    final bool external = widget.phase != null;
    final double speed =
    external ? (widget.isOn ? 0.6 : 0.0) : (_omega / widget.maxSpeed).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: CustomPaint(
        size: effectiveSize,
        painter: DetailedBlowerPainter(
          isOn: widget.isOn,
          showJoints: widget.showJoints,
          phase: external ? widget.phase! : _angle,
          speed: speed,
          palette: widget.palette,
        ),
      ),
    );
  }
}