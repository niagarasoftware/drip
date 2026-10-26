import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Manifold painter: inlet pipe → header → tee → drop pipe → elbow →
/// union → flanged Y-pattern valve → flanged outlet stub.
///
/// Static (no animation). Pipes are light silver-grey and the valves are
/// grey → dark gunmetal so both read clearly on a dark background.
class DetailedMultiValvePainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;
  final List<double>? valvePressures;
  final List<double>? lateralPressures;
  final int? valves;
  final List<String>? valveNames;
  final Set<int> sensorValves;
  final double valveGap;

  DetailedMultiValvePainter({
    required this.isOn,
    this.showJoints = true,
    this.valvePressures,
    this.lateralPressures,
    this.valves,
    this.valveNames,
    this.sensorValves = const {0, 1},
    this.valveGap = 0.70,
  });

  static const int valveCount = 10;
  static const double designAspect = 1.5;
  static const double recommendedAspect = 5.0;
  static Size preferredSize(double height) =>
      Size(height * recommendedAspect, height);

  static const double _firstValveU = 0.32;
  static const double _rightMarginU = 0.58;
  static const double _inletU = 0.08;
  static const double _hy = 0.230;
  static const double _yValve = 0.720;
  static const double _valveOffU = 0.150; // header axis → valve left edge
  static const double _valveHalfU = 0.135;
  // Valve art is designed with half-width 0.38 * scale.
  static const double _valveScaleU = _valveHalfU / 0.38;
  static const double _valveFlangeU = _valveScaleU * 0.06;

  static double _unit(Size s) => s.height;

  static Offset inletPort(Size s) {
    final u = _unit(s);
    return Offset(u * _inletU, (s.height - u) / 2 + u * _hy);
  }

  static const Color _edge = Color(0xFF0A0E12);
  static const Color _orangeLight = Color(0xFFFFA040);
  static const Color _orangeMid = Color(0xFFFF7A1A);
  static const Color _orangeDark = Color(0xFFD9540A);

  // Pipes: light silver-grey cylinder.
  static const List<Color> _pipe = [
    Color(0xFF6F7C87),
    Color(0xFFD0D8DF),
    Color(0xFF93A0AB),
    Color(0xFF55616B),
    Color(0xFF2E373E),
  ];
  static const List<double> _pipeStops = [0.0, 0.20, 0.48, 0.80, 1.0];

  // Fittings / collars / flanges: slightly brighter.
  static const List<Color> _fit = [
    Color(0xFF8A97A2),
    Color(0xFFE6ECF0),
    Color(0xFFA9B5BF),
    Color(0xFF65727D),
    Color(0xFF3A444C),
  ];

  double _h = 0;
  double _sw = 0;
  double _firstX = 0;
  double _gap = 0;
  int _n = valveCount;

  double get _pw => _h * 0.0375; // pipe diameter
  double _vx(int i) => _firstX + _gap * i;

  Offset _valveCenter(int i) => Offset(
    _vx(i) + _h * (_valveOffU + _valveHalfU),
    _h * _yValve,
  );

  // ── paint helpers ──────────────────────────────────────────
  static Paint _shade(Rect r, List<Color> cols, List<double> stops,
      {required bool vertical}) =>
      Paint()
        ..isAntiAlias = true
        ..shader = LinearGradient(
          colors: cols,
          stops: stops,
          begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
          end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
        ).createShader(r);

  static Paint _stroke(Color color, double width) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;

  /// Shaded tube. [horizontal] = axis runs left-right.
  void _tube(Canvas c, Rect r,
      {required bool horizontal,
        double radius = 2,
        List<Color>? colors}) {
    if (r.width <= 0 || r.height <= 0) return;
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(
        rr, _shade(r, colors ?? _pipe, _pipeStops, vertical: horizontal));

    final double t = horizontal ? r.height : r.width;
    final streak = horizontal
        ? Rect.fromLTWH(r.left + radius, r.top + t * 0.14,
        math.max(0.0, r.width - radius * 2), math.max(0.6, t * 0.07))
        : Rect.fromLTWH(r.left + t * 0.14, r.top + radius,
        math.max(0.6, t * 0.07), math.max(0.0, r.height - radius * 2));
    if (streak.width > 0 && streak.height > 0) {
      c.drawRRect(
        RRect.fromRectAndRadius(streak, Radius.circular(t * 0.04)),
        Paint()..color = Colors.white.withValues(alpha: 0.32),
      );
    }
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.75), 0.8));
  }

  /// Bolt passing through two mating flanges (side view).
  void _throughBolt(Canvas c, double x0, double x1, double y) {
    final t = _h * 0.008;
    final headH = _h * 0.018;
    final headW = _h * 0.008;
    _tube(c, Rect.fromLTRB(x0, y - t / 2, x1, y + t / 2),
        horizontal: true, radius: 1, colors: _fit);
    _tube(c, Rect.fromLTWH(x0 - headW / 2, y - headH / 2, headW, headH),
        horizontal: false, radius: 1, colors: _fit);
    _tube(c, Rect.fromLTWH(x1 - headW / 2, y - headH / 2, headW, headH),
        horizontal: false, radius: 1, colors: _fit);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _n = valves ?? valveCount;
    if (_n <= 0 || size.height <= 0 || size.width <= 0) return;

    _h = size.height;
    _sw = _h * designAspect;
    _firstX = _h * _firstValveU;
    _gap = _n > 1
        ? math.max(
      _h * valveGap,
      (size.width - _h * _rightMarginU - _firstX) / (_n - 1),
    )
        : 0;

    _drawInletPipe(canvas);

    // Drop pipes first so the header and tees sit on top of them.
    for (var i = 0; i < _n; i++) {
      _drawDropPipe(canvas, i);
    }
    _drawHeader(canvas);
    for (var i = 0; i < _n; i++) {
      _drawTee(canvas, i);
      _drawRiserAndCap(canvas, i);
    }
    for (var i = 0; i < _n; i++) {
      _drawValve(canvas, i);
      _drawLowerAssembly(canvas, i);
    }
  }

  double get _hdrStart => _vx(0) - _sw * 0.05;
  double get _hdrEnd => _vx(_n - 1) + _h * 0.16;

  // ── inlet ──────────────────────────────────────────────────
  void _drawInletPipe(Canvas c) {
    final cy = _h * _hy;
    final half = _h * 0.022;
    final x0 = _h * _inletU;

    _tube(c, Rect.fromLTRB(x0, cy - half, _hdrStart + 2, cy + half),
        horizontal: true, radius: 2);

    // Union nut mid-pipe.
    final mid = (x0 + _hdrStart) / 2;
    final union = Rect.fromCenter(
        center: Offset(mid, cy), width: _h * 0.034, height: _h * 0.064);
    _tube(c, union, horizontal: true, radius: 2, colors: _fit);
    if (showJoints) {
      for (var k = 1; k <= 2; k++) {
        final x = union.left + union.width * k / 3;
        c.drawLine(
          Offset(x, union.top + 2),
          Offset(x, union.bottom - 2),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.45)
            ..strokeWidth = 0.9,
        );
      }
    }

    // Inlet flange with bolt heads.
    final flange = Rect.fromCenter(
        center: Offset(x0, cy), width: _h * 0.016, height: _h * 0.105);
    _tube(c, flange, horizontal: false, radius: 2, colors: _fit);
    if (showJoints) {
      for (final dy in [-_h * 0.034, _h * 0.034]) {
        _tube(
          c,
          Rect.fromCenter(
              center: Offset(x0, cy + dy), width: _h * 0.026, height: _h * 0.012),
          horizontal: true,
          radius: 1.5,
          colors: _fit,
        );
      }
    }
  }

  // ── header ─────────────────────────────────────────────────
  void _drawHeader(Canvas c) {
    final cy = _h * _hy;
    final half = _h * 0.022;
    _tube(c, Rect.fromLTRB(_hdrStart, cy - half, _hdrEnd, cy + half),
        horizontal: true, radius: _h * 0.02);

    // Collar at the start and a capped end.
    _tube(
      c,
      Rect.fromCenter(
          center: Offset(_hdrStart, cy), width: _h * 0.016, height: _h * 0.058),
      horizontal: true,
      radius: 2,
      colors: _fit,
    );
    _tube(
      c,
      Rect.fromLTRB(
          _hdrEnd - _h * 0.010, cy - half * 1.35, _hdrEnd + _h * 0.012, cy + half * 1.35),
      horizontal: false,
      radius: _h * 0.010,
      colors: _fit,
    );
  }

  /// Cross-tee fitting where the riser and the drop pipe meet the header.
  void _drawTee(Canvas c, int i) {
    final xc = _vx(i);
    final cy = _h * _hy;
    final branchW = _pw * 1.40;

    // Branches (up and down).
    _tube(c, Rect.fromLTRB(xc - branchW / 2, cy - _h * 0.052, xc + branchW / 2, cy),
        horizontal: false, radius: 2, colors: _fit);
    _tube(c, Rect.fromLTRB(xc - branchW / 2, cy, xc + branchW / 2, cy + _h * 0.060),
        horizontal: false, radius: 2, colors: _fit);

    // Run body.
    _tube(
      c,
      Rect.fromCenter(center: Offset(xc, cy), width: _h * 0.072, height: _h * 0.062),
      horizontal: true,
      radius: _h * 0.012,
      colors: _fit,
    );

    if (showJoints) {
      final ring = Paint()
        ..color = Colors.black.withValues(alpha: 0.40)
        ..strokeWidth = 0.9;
      c.drawLine(Offset(xc - branchW / 2 + 1, cy + _h * 0.048),
          Offset(xc + branchW / 2 - 1, cy + _h * 0.048), ring);
      c.drawLine(Offset(xc - branchW / 2 + 1, cy - _h * 0.040),
          Offset(xc + branchW / 2 - 1, cy - _h * 0.040), ring);
    }
  }

  void _drawRiserAndCap(Canvas c, int i) {
    final xc = _vx(i);
    final cy = _h * _hy;

    _tube(c, Rect.fromLTRB(xc - _pw * 0.5, _h * 0.10, xc + _pw * 0.5, cy - _h * 0.03),
        horizontal: false, radius: 2);
    _tube(
      c,
      Rect.fromCenter(center: Offset(xc, _h * 0.098), width: _pw * 1.25, height: _h * 0.018),
      horizontal: false,
      radius: 2,
      colors: _fit,
    );

    // Orange vent plug.
    final cap = Rect.fromCenter(
      center: Offset(xc, _h * 0.072),
      width: _sw * 0.018,
      height: _h * 0.038,
    );
    final rr = RRect.fromRectAndRadius(cap, const Radius.circular(4));
    c.drawRRect(
        rr,
        _shade(cap, const [_orangeLight, _orangeMid, _orangeDark],
            const [0.0, 0.5, 1.0],
            vertical: false));
    c.drawRRect(rr, _stroke(_edge, 0.8));
    final dome = Rect.fromCenter(
      center: Offset(xc, cap.top),
      width: _sw * 0.018,
      height: _h * 0.015,
    );
    c.drawOval(dome,
        _shade(dome, const [_orangeLight, _orangeMid], const [0.0, 1.0], vertical: true));
    c.drawOval(dome, _stroke(_edge, 0.6));
    for (double dx = -_sw * 0.004; dx <= _sw * 0.004; dx += _sw * 0.003) {
      c.drawLine(
        Offset(xc + dx, cap.top + 3),
        Offset(xc + dx, cap.bottom - 2),
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 0.8,
      );
    }
  }

  // ── drop pipe → elbow → union → pipe flange ────────────────
  void _drawDropPipe(Canvas c, int i) {
    final xc = _vx(i);
    final cy = _h * _hy;
    final vy = _h * _yValve;
    final r = _pw * 0.5;
    final eR = _pw * 0.80; // elbow ball radius

    final valveLeft = _valveCenter(i).dx - _h * _valveHalfU;
    final flangeW = _h * 0.016;
    final runEnd = valveLeft - flangeW;

    // Vertical run.
    _tube(c, Rect.fromLTRB(xc - r, cy, xc + r, vy),
        horizontal: false, radius: 1.5);
    // Horizontal run.
    _tube(c, Rect.fromLTRB(xc, vy - r, runEnd + 1, vy + r),
        horizontal: true, radius: 1.5);

    // Elbow (spherical fitting with socket collars).
    final ec = Offset(xc, vy);
    final ball = Rect.fromCircle(center: ec, radius: eR);
    c.drawCircle(
      ec,
      eR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: [
            Color(0xFFEFF4F7),
            Color(0xFFB0BCC6),
            Color(0xFF5E6A75),
            Color(0xFF2E373E),
          ],
          stops: [0.0, 0.35, 0.75, 1.0],
        ).createShader(ball),
    );
    c.drawCircle(ec, eR, _stroke(_edge.withValues(alpha: 0.75), 0.8));

    _tube(
      c,
      Rect.fromCenter(
          center: Offset(xc, vy - eR - _h * 0.006),
          width: _pw * 1.30,
          height: _h * 0.016),
      horizontal: false,
      radius: 2,
      colors: _fit,
    );
    _tube(
      c,
      Rect.fromCenter(
          center: Offset(xc + eR + _h * 0.006, vy),
          width: _h * 0.016,
          height: _pw * 1.30),
      horizontal: true,
      radius: 2,
      colors: _fit,
    );

    // Union nut halfway along the horizontal run.
    final runStart = xc + eR + _h * 0.014;
    final midX = (runStart + runEnd) / 2;
    final union = Rect.fromCenter(
        center: Offset(midX, vy), width: _h * 0.030, height: _pw * 1.55);
    _tube(c, union, horizontal: true, radius: 2, colors: _fit);
    if (showJoints) {
      for (var k = 1; k <= 2; k++) {
        final x = union.left + union.width * k / 3;
        c.drawLine(
          Offset(x, union.top + 2),
          Offset(x, union.bottom - 2),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.45)
            ..strokeWidth = 0.9,
        );
      }
    }

    // Pipe flange that mates with the valve flange.
    _tube(c, Rect.fromLTRB(runEnd, vy - _pw, runEnd + flangeW, vy + _pw),
        horizontal: false, radius: 1.5, colors: _fit);
  }

  // ── valve ──────────────────────────────────────────────────
  void _drawValve(Canvas c, int i) {
    final vc = _valveCenter(i);
    c.save();
    c.translate(vc.dx, vc.dy);
    _ValveArt.paint(
      c,
      _h * _valveScaleU,
      showJoints: showJoints,
      isOn: isOn,
      flangeBolts: false,
    );
    c.restore();
  }

  // ── flange bolts, outlet stub and label ────────────────────
  void _drawLowerAssembly(Canvas c, int i) {
    final vc = _valveCenter(i);
    final vy = _h * _yValve;
    final r = _pw * 0.5;
    final flangeW = _h * 0.016;
    final valveLeft = vc.dx - _h * _valveHalfU;
    final valveRight = vc.dx + _h * _valveHalfU;
    final valveFlange = _h * _valveFlangeU;

    if (showJoints) {
      // Inlet side bolts.
      for (final dy in [-_h * 0.026, _h * 0.026]) {
        _throughBolt(c, valveLeft - flangeW, valveLeft + valveFlange, vy + dy);
      }
    }

    // Outlet: mating flange + short stub with an open end.
    _tube(c, Rect.fromLTRB(valveRight, vy - _pw, valveRight + flangeW, vy + _pw),
        horizontal: false, radius: 1.5, colors: _fit);
    final stubStart = valveRight + flangeW;
    final stubEnd = stubStart + _h * 0.065;
    _tube(c, Rect.fromLTRB(stubStart - 1, vy - r, stubEnd, vy + r),
        horizontal: true, radius: 1.5);
    _tube(
      c,
      Rect.fromCenter(
          center: Offset(stubEnd, vy), width: _h * 0.014, height: _pw * 1.30),
      horizontal: true,
      radius: 2,
      colors: _fit,
    );
    final bore = Rect.fromCenter(
        center: Offset(stubEnd + _h * 0.006, vy),
        width: _h * 0.009,
        height: _pw * 0.95);
    c.drawOval(bore, Paint()..color = const Color(0xFF0B0E11));
    c.drawOval(bore, _stroke(const Color(0xFFB8C2CA).withValues(alpha: 0.8), 0.8));

    if (showJoints) {
      for (final dy in [-_h * 0.026, _h * 0.026]) {
        _throughBolt(c, valveRight - valveFlange, valveRight + flangeW, vy + dy);
      }
    }

    // Name badge (dark-theme friendly).
    final name = (valveNames != null && i < valveNames!.length)
        ? valveNames![i]
        : 'V${i + 1}';
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: const Color(0xFFE2E8F0),
          fontSize: math.max(10.0, _h * 0.058),
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeW = math.max(tp.width + 10, _sw * 0.065);
    final badgeH = tp.height + 4;
    final labelY = math.min(_h * 0.935, _h - badgeH / 2 - 1);
    final rect = Rect.fromCenter(
      center: Offset(vc.dx, labelY),
      width: badgeW,
      height: badgeH,
    );
    final badge = RRect.fromRectAndRadius(rect, Radius.circular(_h * 0.014));
    c.drawRRect(badge, Paint()..color = const Color(0xFF1B2540));
    c.drawRRect(badge, _stroke(const Color(0xFF38BDF8), 1.0));
    tp.paint(
      c,
      Offset(
        rect.left + (badgeW - tp.width) / 2,
        rect.top + (badgeH - tp.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant DetailedMultiValvePainter old) =>
      old.isOn != isOn ||
          old.showJoints != showJoints ||
          old.valves != valves ||
          old.valveGap != valveGap ||
          !listEquals(old.valveNames, valveNames);
}

/// Widget wrapper for DetailedMultiValvePainter.
class MultiValveView extends StatelessWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;
  final int? valves;
  final List<String>? valveNames;
  final Set<int> sensorValves;
  final double valveGap;
  final List<double>? valvePressures;
  final List<double>? lateralPressures;

  const MultiValveView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    required this.size,
    this.valves,
    this.valveNames,
    this.sensorValves = const {0, 1},
    this.valveGap = 0.70,
    this.valvePressures,
    this.lateralPressures,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: size,
    painter: DetailedMultiValvePainter(
      isOn: isOn,
      showJoints: showJoints,
      valves: valves,
      valveNames: valveNames,
      sensorValves: sensorValves,
      valveGap: valveGap,
      valvePressures: valvePressures,
      lateralPressures: lateralPressures,
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Valve artwork (origin = valve centre, [s] = scale)
// ─────────────────────────────────────────────────────────────
class _ValveArt {
  _ValveArt._();

  static const Color _edge = Color(0xFF0A0E12);
  static const Color _rim = Color(0xFFD3DBE2);

  static const Color _orangeLight = Color(0xFFFFA040);
  static const Color _orangeMid = Color(0xFFFF7A1A);
  static const Color _orangeDark = Color(0xFFD9540A);

  static const List<Color> _metal = [
    Color(0xFF7F8B96),
    Color(0xFFBAC4CD),
    Color(0xFF7D8994),
    Color(0xFF444F58),
    Color(0xFF1E252B),
  ];
  static const List<double> _metalStops = [0.0, 0.16, 0.42, 0.76, 1.0];

  static const List<Color> _bodyCols = [
    Color(0xFFA6B1BB),
    Color(0xFF6D7983),
    Color(0xFF39434C),
    Color(0xFF171D22),
  ];
  static const List<double> _bodyStops = [0.0, 0.34, 0.70, 1.0];

  static Paint _shade(Rect r, List<Color> cols, List<double> stops,
      {required bool vertical}) =>
      Paint()
        ..isAntiAlias = true
        ..shader = LinearGradient(
          colors: cols,
          stops: stops,
          begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
          end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
        ).createShader(r);

  static Paint _line(Color color, double w) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = color;

  static void _cyl(Canvas c, Rect r, double radius,
      {required bool horizontal, required double lw}) {
    if (r.width <= 0 || r.height <= 0) return;
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, _shade(r, _metal, _metalStops, vertical: horizontal));

    final double t = horizontal ? r.height : r.width;
    final streak = horizontal
        ? Rect.fromLTWH(r.left + radius, r.top + t * 0.14,
        math.max(0.0, r.width - radius * 2), math.max(0.6, t * 0.07))
        : Rect.fromLTWH(r.left + t * 0.14, r.top + radius,
        math.max(0.6, t * 0.07), math.max(0.0, r.height - radius * 2));
    if (streak.width > 0 && streak.height > 0) {
      c.drawRRect(
        RRect.fromRectAndRadius(streak, Radius.circular(t * 0.04)),
        Paint()..color = Colors.white.withValues(alpha: 0.30),
      );
    }
    c.drawRRect(rr, _line(_edge.withValues(alpha: 0.75), lw));
  }

  static void _boltHead(Canvas c, Offset o, double r, double lw) {
    c.drawCircle(o, r, Paint()..color = const Color(0xFFDDE4EA));
    c.drawCircle(o, r, _line(_edge, lw));
    c.drawCircle(o, r * 0.38, Paint()..color = const Color(0xFF5C6873));
  }

  static void paint(
      Canvas c,
      double s, {
        required bool showJoints,
        required bool isOn,
        required bool flangeBolts,
      }) {
    final hw = s * 0.38;
    final lw = math.max(0.7, s * 0.008);

    final base = Offset(0, -s * 0.18);
    const angle = -0.62;
    final ca = math.cos(angle);
    final sa = math.sin(angle);
    Offset rotated(double x, double y) => Offset(
      base.dx + (x * ca - y * sa) * s,
      base.dy + (x * sa + y * ca) * s,
    );

    // Soft ground shadow.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.15),
        width: hw * 2.10,
        height: s * 0.07,
      ),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
    );

    // Mounting feet.
    for (final x in [-hw * 0.52, hw * 0.38]) {
      final p = Path()
        ..moveTo(x - s * 0.05, s * 0.08)
        ..lineTo(x - s * 0.065, s * 0.14)
        ..lineTo(x + s * 0.065, s * 0.14)
        ..lineTo(x + s * 0.05, s * 0.08)
        ..close();
      c.drawPath(
          p, _shade(p.getBounds(), _metal, _metalStops, vertical: true));
      c.drawPath(p, _line(_edge, lw));
    }

    // Horizontal barrel.
    _cyl(
      c,
      Rect.fromLTRB(-hw + s * 0.035, -s * 0.10, hw - s * 0.035, s * 0.10),
      s * 0.03,
      horizontal: true,
      lw: lw,
    );

    // Y chamber body.
    final body = Path()
      ..moveTo(-hw + s * 0.05, -s * 0.10)
      ..cubicTo(-s * 0.20, -s * 0.12, -s * 0.16, -s * 0.20, -s * 0.10, -s * 0.25)
      ..cubicTo(-s * 0.05, -s * 0.30, -s * 0.03, -s * 0.31, 0, -s * 0.32)
      ..cubicTo(s * 0.03, -s * 0.31, s * 0.05, -s * 0.30, s * 0.10, -s * 0.25)
      ..cubicTo(s * 0.16, -s * 0.20, s * 0.20, -s * 0.12, hw - s * 0.05, -s * 0.10)
      ..lineTo(hw - s * 0.05, s * 0.10)
      ..lineTo(-hw + s * 0.05, s * 0.10)
      ..close();
    final bb = body.getBounds();
    c.drawPath(body, _shade(bb, _bodyCols, _bodyStops, vertical: true));
    c.save();
    c.clipPath(body);
    c.drawRect(
      bb,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55],
        ).createShader(bb),
    );
    c.restore();
    c.drawPath(body, _line(_rim.withValues(alpha: 0.55), lw * 1.3));

    // Raised ribs (embossed: shadow + highlight).
    final rib = Path()
      ..moveTo(-s * 0.15, -s * 0.065)
      ..quadraticBezierTo(-s * 0.08, -s * 0.16, 0, -s * 0.27)
      ..quadraticBezierTo(s * 0.08, -s * 0.16, s * 0.15, -s * 0.065);
    c.drawPath(rib.shift(Offset(0, lw * 1.4)),
        _line(Colors.black.withValues(alpha: 0.45), lw * 1.6));
    c.drawPath(
        rib, _line(const Color(0xFFC7D0D8).withValues(alpha: 0.70), lw * 1.6));

    // Side inspection plug.
    final plug = Offset(-hw * 0.57, s * 0.02);
    c.drawCircle(plug, s * 0.03, Paint()..color = const Color(0xFF232B31));
    c.drawCircle(plug, s * 0.03, _line(const Color(0xFFB4BFC8), lw * 1.2));
    c.drawCircle(plug, s * 0.012, Paint()..color = const Color(0xFF7D8994));
    c.drawCircle(plug.translate(-s * 0.004, -s * 0.004), s * 0.005,
        Paint()..color = Colors.white.withValues(alpha: 0.5));

    // Flow direction arrow.
    final arrow = Path()
      ..moveTo(-s * 0.16, s * 0.045)
      ..lineTo(-s * 0.07, s * 0.045)
      ..moveTo(-s * 0.10, s * 0.022)
      ..lineTo(-s * 0.07, s * 0.045)
      ..lineTo(-s * 0.10, s * 0.068);
    c.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, s * 0.012)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFE3E9EE).withValues(alpha: 0.85),
    );

    // Union collars with ridges.
    final nw = s * 0.065;
    for (final rect in [
      Rect.fromLTWH(-hw + s * 0.035, -s * 0.138, nw, s * 0.276),
      Rect.fromLTWH(hw - s * 0.035 - nw, -s * 0.138, nw, s * 0.276),
    ]) {
      _cyl(c, rect, s * 0.012, horizontal: true, lw: lw);
      if (showJoints) {
        for (var k = 1; k <= 3; k++) {
          final x = rect.left + rect.width * k / 4;
          c.drawLine(Offset(x, rect.top + 2), Offset(x, rect.bottom - 2),
              Paint()
                ..color = Colors.black.withValues(alpha: 0.55)
                ..strokeWidth = lw);
          c.drawLine(Offset(x + lw, rect.top + 2),
              Offset(x + lw, rect.bottom - 2),
              Paint()
                ..color = Colors.white.withValues(alpha: 0.18)
                ..strokeWidth = lw * 0.8);
        }
      }
    }

    // Angled bonnet + actuator.
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle);

    _cyl(
      c,
      Rect.fromLTRB(-s * 0.18, -s * 0.045, s * 0.18, s * 0.012),
      s * 0.012,
      horizontal: true,
      lw: lw,
    );
    if (showJoints) {
      for (final bx in const [-0.14, -0.07, 0.0, 0.07, 0.14]) {
        _boltHead(c, Offset(s * bx, -s * 0.017), s * 0.011, lw * 0.8);
      }
    }

    _cyl(
      c,
      Rect.fromLTRB(-s * 0.155, -s * 0.195, s * 0.155, -s * 0.045),
      s * 0.05,
      horizontal: true,
      lw: lw,
    );
    for (final rx in const [-0.095, -0.03, 0.03, 0.095]) {
      c.drawLine(
        Offset(s * rx, -s * 0.172),
        Offset(s * rx, -s * 0.068),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..strokeWidth = lw * 1.2,
      );
      c.drawLine(
        Offset(s * rx + lw * 1.2, -s * 0.172),
        Offset(s * rx + lw * 1.2, -s * 0.068),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.16)
          ..strokeWidth = lw,
      );
    }

    _cyl(c, Rect.fromLTRB(-s * 0.065, -s * 0.28, s * 0.065, -s * 0.195),
        s * 0.01,
        horizontal: false, lw: lw);
    _cyl(c, Rect.fromLTRB(-s * 0.04, -s * 0.368, s * 0.04, -s * 0.28),
        s * 0.01,
        horizontal: false, lw: lw);

    final knob = Rect.fromLTWH(-s * 0.08, -s * 0.338, s * 0.045, s * 0.045);
    final knobR = RRect.fromRectAndRadius(knob, Radius.circular(s * 0.008));
    c.drawRRect(
      knobR,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_orangeLight, _orangeMid, _orangeDark],
        ).createShader(knob),
    );
    c.drawRRect(knobR, _line(_edge, lw));

    _cyl(c, Rect.fromLTRB(-s * 0.03, -s * 0.39, s * 0.03, -s * 0.368),
        s * 0.005,
        horizontal: true, lw: lw);
    final beacon = isOn ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    c.drawCircle(Offset(0, -s * 0.40), s * 0.018,
        Paint()..color = beacon.withValues(alpha: 0.25));
    c.drawCircle(Offset(0, -s * 0.40), s * 0.011, Paint()..color = beacon);
    c.restore();

    // Pilot control hose.
    final pilotIn = rotated(-0.03, -0.34);
    final pilotOut = rotated(0.03, -0.32);
    final bodyIn = Offset(-hw + s * 0.10, -s * 0.075);
    final bodyOut = Offset(hw - s * 0.10, -s * 0.075);
    final hoseW = math.max(1.6, s * 0.016);

    final loop = Path()
      ..moveTo(pilotIn.dx, pilotIn.dy)
      ..cubicTo(
        pilotIn.dx - s * 0.20, pilotIn.dy - s * 0.165,
        -hw - s * 0.01, -s * 0.475,
        -hw + s * 0.088, -s * 0.225,
      )
      ..cubicTo(
        -hw + s * 0.115, -s * 0.145,
        bodyIn.dx - s * 0.038, bodyIn.dy - s * 0.065,
        bodyIn.dx, bodyIn.dy,
      );
    final outletTube = Path()
      ..moveTo(pilotOut.dx, pilotOut.dy)
      ..cubicTo(
        pilotOut.dx + s * 0.155, pilotOut.dy + s * 0.05,
        bodyOut.dx + s * 0.07, bodyOut.dy - s * 0.145,
        bodyOut.dx, bodyOut.dy,
      );
    for (final tube in [loop, outletTube]) {
      c.drawPath(tube, _line(_edge, hoseW + lw * 1.6));
      c.drawPath(tube, _line(const Color(0xFF56636D), hoseW));
      c.drawPath(tube,
          _line(const Color(0xFFC3CDD5).withValues(alpha: 0.55), hoseW * 0.32));
    }
    for (final p in [pilotIn, pilotOut, bodyIn, bodyOut]) {
      final r = s * 0.017;
      c.drawCircle(p, r, Paint()..color = const Color(0xFF3A444D));
      c.drawCircle(p, r, _line(const Color(0xFFB8C2CA), lw));
      c.drawCircle(p, r * 0.4, Paint()..color = const Color(0xFF8E9AA5));
    }

    // End flanges.
    final fh = s * 0.188;
    final fw = s * 0.06;
    for (final side in const [-1, 1]) {
      final rim = side < 0
          ? Rect.fromLTWH(-hw, -fh, fw, fh * 2)
          : Rect.fromLTWH(hw - fw, -fh, fw, fh * 2);
      _cyl(c, rim, s * 0.015, horizontal: false, lw: lw);
      if (flangeBolts && showJoints) {
        for (final yy in [-fh * 0.68, fh * 0.68]) {
          final head = Rect.fromCenter(
            center: Offset(rim.center.dx, yy),
            width: fw * 1.3,
            height: s * 0.034,
          );
          _cyl(c, head, s * 0.006, horizontal: true, lw: lw * 0.8);
        }
      }
    }
  }
}