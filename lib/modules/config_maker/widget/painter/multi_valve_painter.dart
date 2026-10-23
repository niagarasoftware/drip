import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Manifold painter with complete black Y-pattern valves.
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
  static const double _rightMarginU = 0.38;
  static const double _inletU = 0.08;
  static const double _hy = 0.230;
  static const double _yValve = 0.720;
  static const double _valveOffU = 0.110;
  static const double _valveHalfU = 0.135;

  static double _unit(Size s) => s.height;

  static Offset inletPort(Size s) {
    final u = _unit(s);
    return Offset(u * _inletU, (s.height - u) / 2 + u * _hy);
  }

  static const Color _edge = Color(0xFF1B2024);
  static const Color _steelLight = Color(0xFFECEFF1);
  static const Color _orangeLight = Color(0xFFFFA040);
  static const Color _orangeMid = Color(0xFFFF7A1A);
  static const Color _orangeDark = Color(0xFFD9540A);

  static const List<Color> _pvcCyl = [
    Color(0xFF6C7A86), Color(0xFFA9B6C0), Color(0xFF8795A1), Color(0xFF5A6670),
  ];
  static const List<Color> _pvcJoint = [
    Color(0xFFB4C0CA), Color(0xFFE6EBEF), Color(0xFFCBD4DB), Color(0xFF9AA7B2),
  ];
  static const List<Color> _blackCyl = [
    Color(0xFF0E1215), Color(0xFF3A464F), Color(0xFF222B31), Color(0xFF0A0D10),
  ];
  static const List<double> _cylStops = [0.0, 0.25, 0.65, 1.0];

  double _h = 0;
  double _sw = 0;
  double _firstX = 0;
  double _gap = 0;
  int _n = valveCount;

  double get _pw => _sw * 0.025;
  double _vx(int i) => _firstX + _gap * i;

  Offset _valveCenter(int i) => Offset(
    _vx(i) + _h * (_valveOffU + _valveHalfU),
    _h * _yValve,
  );

  Paint _grad(Rect r, List<Color> colors, Alignment b, Alignment e, [List<double>? stops]) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(colors: colors, stops: stops, begin: b, end: e).createShader(r);

  Paint _gv(Rect r, List<Color> colors, [List<double>? stops]) =>
      _grad(r, colors, Alignment.topCenter, Alignment.bottomCenter, stops);

  Paint _gh(Rect r, List<Color> colors, [List<double>? stops]) =>
      _grad(r, colors, Alignment.centerLeft, Alignment.centerRight, stops);

  Paint _stroke(Color color, double width) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;

  void _cylH(Canvas c, Rect r, {double radius = 2, List<Color>? colors}) {
    if (r.width <= 0 || r.height <= 0) return;
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, _gv(r, colors ?? _pvcCyl, _cylStops));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.7), 0.8));
  }

  void _cylV(Canvas c, Rect r, {double radius = 2, List<Color>? colors}) {
    if (r.width <= 0 || r.height <= 0) return;
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, _gh(r, colors ?? _pvcCyl, _cylStops));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.7), 0.8));
  }

  void _bolt(Canvas c, Offset o, double r) {
    c.drawCircle(o, r, Paint()..color = _steelLight);
    c.drawCircle(o, r, _stroke(_edge, 0.7));
    c.drawCircle(o, r * 0.35, Paint()..color = const Color(0xFF7FA6C9));
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

    canvas.save();
    canvas.translate(0, (size.height - _h) / 2);

    _drawInletPipe(canvas);
    _drawHeader(canvas);

    for (var i = 0; i < _n; i++) {
      _drawRiserAndCap(canvas, i);
      _drawDropStub(canvas, i);
    }
    for (var i = 0; i < _n; i++) {
      _drawValve(canvas, i);
      _drawLowerAssembly(canvas, i);
    }

    canvas.restore();
  }

  double get _hdrStart => _vx(0) - _sw * 0.05;
  double get _hdrEnd => _vx(_n - 1) + _h * 0.16;

  void _drawInletPipe(Canvas c) {
    final top = _h * (_hy - 0.022);
    final bottom = _h * (_hy + 0.022);
    final x0 = _h * _inletU;
    _cylH(c, Rect.fromLTRB(x0, top, _hdrStart + 2, bottom), radius: 2);
    _cylH(
      c,
      Rect.fromCenter(
        center: Offset((x0 + _hdrStart) / 2, _h * _hy),
        width: _sw * 0.022,
        height: _h * 0.052,
      ),
      radius: 2,
      colors: _pvcJoint,
    );
    final rim = Rect.fromCenter(
      center: Offset(x0, _h * _hy),
      width: _sw * 0.010,
      height: bottom - top,
    );
    c.drawOval(rim, _gh(rim, const [Colors.white, Color(0xFF9AA7B2)]));
    c.drawOval(rim, _stroke(_edge.withValues(alpha: 0.85), 0.8));
    final bore = Rect.fromCenter(
      center: Offset(x0 - rim.width * 0.05, _h * _hy),
      width: rim.width * 0.55,
      height: (bottom - top) * 0.72,
    );
    c.drawOval(bore, Paint()..color = const Color(0xFF111418));
  }

  void _drawHeader(Canvas c) {
    final top = _h * (_hy - 0.022);
    final bottom = _h * (_hy + 0.022);
    _cylH(
      c,
      Rect.fromLTRB(_hdrStart, top, _hdrEnd, bottom),
      radius: _h * 0.02,
    );

    for (var i = 0; i < _n; i++) {
      final xc = _vx(i);
      final cy = _h * _hy;
      final sleeve = Rect.fromCenter(
        center: Offset(xc, cy),
        width: _sw * 0.075,
        height: _h * 0.05,
      );
      _cylH(c, sleeve, radius: 2, colors: _pvcJoint);
      final arm = Rect.fromCenter(
        center: Offset(xc, cy),
        width: _pw * 1.2,
        height: _h * 0.08,
      );
      _cylV(c, arm, radius: 2, colors: _pvcJoint);
      if (showJoints) {
        final ring = Paint()..color = Colors.black38..strokeWidth = 0.8;
        c.drawLine(
          Offset(sleeve.left + _sw * 0.008, sleeve.top + 1),
          Offset(sleeve.left + _sw * 0.008, sleeve.bottom - 1),
          ring,
        );
        c.drawLine(
          Offset(sleeve.right - _sw * 0.008, sleeve.top + 1),
          Offset(sleeve.right - _sw * 0.008, sleeve.bottom - 1),
          ring,
        );
      }
    }
  }

  void _drawRiserAndCap(Canvas c, int i) {
    final xc = _vx(i);
    _cylV(
      c,
      Rect.fromLTRB(xc - _pw * 0.5, _h * 0.095, xc + _pw * 0.5, _h * 0.20),
      radius: 2,
    );
    _cylV(
      c,
      Rect.fromCenter(
        center: Offset(xc, _h * 0.15),
        width: _pw * 1.12,
        height: _h * 0.02,
      ),
      radius: 2,
      colors: _blackCyl,
    );
    _cylV(
      c,
      Rect.fromCenter(
        center: Offset(xc, _h * 0.095),
        width: _pw * 1.05,
        height: _h * 0.016,
      ),
      radius: 2,
      colors: _pvcJoint,
    );

    final cap = Rect.fromCenter(
      center: Offset(xc, _h * 0.072),
      width: _sw * 0.018,
      height: _h * 0.038,
    );
    final rr = RRect.fromRectAndRadius(cap, const Radius.circular(4));
    c.drawRRect(rr, _gh(cap, const [_orangeLight, _orangeMid, _orangeDark]));
    c.drawRRect(rr, _stroke(_edge, 0.8));
    final dome = Rect.fromCenter(
      center: Offset(xc, cap.top),
      width: _sw * 0.018,
      height: _h * 0.015,
    );
    c.drawOval(dome, _gv(dome, const [_orangeLight, _orangeMid]));
    c.drawOval(dome, _stroke(_edge, 0.6));
    for (double dx = -_sw * 0.004; dx <= _sw * 0.004; dx += _sw * 0.003) {
      c.drawLine(
        Offset(xc + dx, cap.top + 3),
        Offset(xc + dx, cap.bottom - 2),
        Paint()..color = Colors.black26..strokeWidth = 0.8,
      );
    }
  }

  void _drawDropStub(Canvas c, int i) {
    final xc = _vx(i);
    final vy = _h * _yValve;
    final flangeX = xc + _h * _valveOffU;
    _cylV(
      c,
      Rect.fromLTRB(xc - _pw * 0.5, _h * 0.31, xc + _pw * 0.5, vy),
    );
    _cylH(
      c,
      Rect.fromLTRB(xc, vy - _pw * 0.5, flangeX + _h * 0.01, vy + _pw * 0.5),
      radius: 1,
    );
    final cap = Rect.fromCenter(
      center: Offset(xc, _h * 0.292),
      width: _pw * 1.05,
      height: _h * 0.045,
    );
    final rr = RRect.fromRectAndRadius(cap, Radius.circular(_pw * 0.5));
    c.drawRRect(rr, _gh(cap, _pvcJoint, _cylStops));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.7), 0.8));
  }

  /// Black Y-pattern diaphragm valve.
  void _drawValve(Canvas c, int i) {
    final s = _h;
    final vc = _valveCenter(i);
    final hw = s * _valveHalfU;

    c.save();
    c.translate(vc.dx, vc.dy);

    const deep = Color(0xFF080B0D);
    const mid = Color(0xFF222B31);
    const light = Color(0xFF384650);

    final base = Offset(0, -s * 0.072);
    const angle = -0.62;
    final ca = math.cos(angle);
    final sa = math.sin(angle);
    Offset rotated(double x, double y) => Offset(
      base.dx + (x * ca - y * sa) * s,
      base.dy + (x * sa + y * ca) * s,
    );

    // Soft shadow under the valve.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.060),
        width: hw * 2.10,
        height: s * 0.028,
      ),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.012),
    );

    // Mounting feet.
    for (final x in [-hw * 0.52, hw * 0.38]) {
      final p = Path()
        ..moveTo(x - s * 0.020, s * 0.030)
        ..lineTo(x - s * 0.026, s * 0.055)
        ..lineTo(x + s * 0.026, s * 0.055)
        ..lineTo(x + s * 0.020, s * 0.030)
        ..close();
      c.drawPath(p, _gv(p.getBounds(), const [
        Color(0xFF263139), Color(0xFF0A0D10),
      ]));
      c.drawPath(p, _stroke(_edge, 0.7));
    }

    // Horizontal valve barrel.
    final barrel = Rect.fromLTRB(
      -hw + s * 0.014, -s * 0.045,
      hw - s * 0.014, s * 0.045,
    );
    _cylH(c, barrel, radius: s * 0.012, colors: _blackCyl);

    // Y chamber body.
    final body = Path()
      ..moveTo(-hw + s * 0.020, -s * 0.040)
      ..cubicTo(-s * 0.082, -s * 0.048, -s * 0.064, -s * 0.082, -s * 0.039, -s * 0.100)
      ..cubicTo(-s * 0.021, -s * 0.118, -s * 0.015, -s * 0.125, 0, -s * 0.128)
      ..cubicTo(s * 0.015, -s * 0.125, s * 0.021, -s * 0.118, s * 0.039, -s * 0.100)
      ..cubicTo(s * 0.064, -s * 0.082, s * 0.082, -s * 0.048, hw - s * 0.020, -s * 0.040)
      ..lineTo(hw - s * 0.020, s * 0.040)
      ..lineTo(-hw + s * 0.020, s * 0.040)
      ..close();
    c.drawPath(body, _gv(body.getBounds(), const [
      Color(0xFF35414A), Color(0xFF20282E), Color(0xFF0B0F12),
    ], const [0.0, 0.48, 1.0]));
    c.drawPath(body, _stroke(light.withValues(alpha: 0.62), 0.9));

    // Raised ribs on Y housing.
    final rib = Path()
      ..moveTo(-s * 0.060, -s * 0.026)
      ..quadraticBezierTo(-s * 0.034, -s * 0.066, 0, -s * 0.107)
      ..quadraticBezierTo(s * 0.034, -s * 0.066, s * 0.060, -s * 0.026);
    c.drawPath(rib, _stroke(light.withValues(alpha: 0.42), math.max(1.0, s * 0.005)));

    // Side inspection plug and flow arrow.
    final plug = Offset(-hw * 0.57, s * 0.008);
    c.drawCircle(plug, s * 0.012, Paint()..color = deep);
    c.drawCircle(plug, s * 0.012, _stroke(light, 0.8));
    c.drawCircle(plug, s * 0.005, Paint()..color = mid);

    final arrow = Path()
      ..moveTo(-s * 0.064, s * 0.018)
      ..lineTo(-s * 0.031, s * 0.018)
      ..moveTo(-s * 0.044, s * 0.009)
      ..lineTo(-s * 0.031, s * 0.018)
      ..lineTo(-s * 0.044, s * 0.027);
    c.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, s * 0.005)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = light.withValues(alpha: 0.8),
    );

    // Brand lettering.
    final brand = TextPainter(
      text: TextSpan(
        text: 'NIAGARA',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: math.max(5.0, s * 0.020),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    c.save();
    c.translate(s * 0.004, -s * 0.040);
    c.rotate(-0.52);
    brand.paint(c, Offset(-brand.width / 2, -brand.height / 2));
    c.restore();

    // Union collars.
    final nw = s * 0.026;
    for (final rect in [
      Rect.fromLTWH(-hw + s * 0.014, -s * 0.055, nw, s * 0.110),
      Rect.fromLTWH(hw - s * 0.014 - nw, -s * 0.055, nw, s * 0.110),
    ]) {
      _cylH(c, rect, radius: s * 0.005, colors: _blackCyl);
      if (showJoints) {
        for (var k = 1; k <= 4; k++) {
          final x = rect.left + rect.width * k / 5;
          c.drawLine(
            Offset(x, rect.top + 2),
            Offset(x, rect.bottom - 2),
            Paint()..color = const Color(0xFF050708)..strokeWidth = 0.9,
          );
        }
      }
    }

    // Angled bonnet and actuator.
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle);

    final plate = RRect.fromRectAndRadius(
      Rect.fromLTRB(-s * 0.075, -s * 0.018, s * 0.075, s * 0.005),
      Radius.circular(s * 0.005),
    );
    c.drawRRect(plate, _gv(plate.outerRect, _blackCyl));
    c.drawRRect(plate, _stroke(light.withValues(alpha: 0.85), 0.8));
    if (showJoints) {
      for (final bx in const [-0.060, -0.030, 0.0, 0.030, 0.060]) {
        _bolt(c, Offset(s * bx, -s * 0.006), s * 0.0045);
      }
    }

    final dome = Rect.fromLTRB(-s * 0.062, -s * 0.078, s * 0.062, -s * 0.018);
    _cylH(c, dome, radius: s * 0.020, colors: _blackCyl);
    for (final rx in const [-0.038, -0.012, 0.012, 0.038]) {
      c.drawLine(
        Offset(s * rx, -s * 0.072),
        Offset(s * rx, -s * 0.024),
        Paint()..color = Colors.white.withValues(alpha: 0.13)..strokeWidth = 1.0,
      );
    }

    _cylV(
      c,
      Rect.fromLTRB(-s * 0.026, -s * 0.112, s * 0.026, -s * 0.078),
      radius: s * 0.004,
      colors: _blackCyl,
    );
    _cylV(
      c,
      Rect.fromLTRB(-s * 0.016, -s * 0.147, s * 0.016, -s * 0.112),
      radius: s * 0.004,
      colors: _blackCyl,
    );

    final knob = Rect.fromLTWH(-s * 0.032, -s * 0.135, s * 0.018, s * 0.018);
    final knobR = RRect.fromRectAndRadius(knob, Radius.circular(s * 0.003));
    c.drawRRect(
      knobR,
      Paint()
        ..shader = const LinearGradient(
          colors: [_orangeLight, _orangeMid, _orangeDark],
        ).createShader(knob),
    );
    c.drawRRect(knobR, _stroke(_edge, 0.7));
    _cylH(
      c,
      Rect.fromLTRB(-s * 0.012, -s * 0.156, s * 0.012, -s * 0.147),
      radius: s * 0.002,
      colors: _blackCyl,
    );
    c.drawCircle(Offset(0, -s * 0.160), s * 0.0045,
        Paint()..color = const Color(0xFFD32F2F));
    c.restore();

    // Control hose.
    final pilotIn = rotated(-0.012, -0.136);
    final pilotOut = rotated(0.012, -0.128);
    final bodyIn = Offset(-hw + s * 0.040, -s * 0.030);
    final bodyOut = Offset(hw - s * 0.040, -s * 0.030);
    final hoseW = math.max(1.4, s * 0.0065);

    final loop = Path()
      ..moveTo(pilotIn.dx, pilotIn.dy)
      ..cubicTo(
        pilotIn.dx - s * 0.082, pilotIn.dy - s * 0.066,
        -hw - s * 0.004, -s * 0.190,
        -hw + s * 0.035, -s * 0.090,
      )
      ..cubicTo(
        -hw + s * 0.046, -s * 0.058,
        bodyIn.dx - s * 0.015, bodyIn.dy - s * 0.026,
        bodyIn.dx, bodyIn.dy,
      );
    final outletTube = Path()
      ..moveTo(pilotOut.dx, pilotOut.dy)
      ..cubicTo(
        pilotOut.dx + s * 0.062, pilotOut.dy + s * 0.020,
        bodyOut.dx + s * 0.028, bodyOut.dy - s * 0.058,
        bodyOut.dx, bodyOut.dy,
      );
    for (final tube in [loop, outletTube]) {
      c.drawPath(tube, _stroke(deep, hoseW + 1.0));
      c.drawPath(tube, _stroke(const Color(0xFF1E2830), hoseW));
      c.drawPath(tube, _stroke(const Color(0xFF65737D).withValues(alpha: 0.45), hoseW * 0.3));
    }
    for (final p in [pilotIn, pilotOut, bodyIn, bodyOut]) {
      c.drawCircle(p, s * 0.006, Paint()..color = deep);
      c.drawCircle(p, s * 0.006, _stroke(light, 0.7));
    }

    // End flanges (solid collars without side hole openings).
    final flangeHalfH = s * 0.075;
    final flangeW = s * 0.024;
    for (final side in const [-1, 1]) {
      final rim = side < 0
          ? Rect.fromLTWH(-hw, -flangeHalfH, flangeW, flangeHalfH * 2)
          : Rect.fromLTWH(hw - flangeW, -flangeHalfH, flangeW, flangeHalfH * 2);
      _cylV(c, rim, radius: s * 0.006, colors: _blackCyl);
    }

    c.restore();
  }

  void _drawLowerAssembly(Canvas c, int i) {
    final xc = _vx(i);
    final vy = _h * _yValve;
    final vc = _valveCenter(i);

    _cylV(
      c,
      Rect.fromCenter(
        center: Offset(xc, vy),
        width: _pw * 1.2,
        height: _pw * 1.2,
      ),
      radius: _pw * 0.4,
      colors: _pvcJoint,
    );
    final sx = xc + _pw * 0.6;
    _cylH(
      c,
      Rect.fromLTRB(sx, vy - _pw * 0.5, sx + _h * 0.015, vy + _pw * 0.5),
      radius: 1,
      colors: _pvcJoint,
    );

    final name = (valveNames != null && i < valveNames!.length)
        ? valveNames![i]
        : 'V${i + 1}';
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: const Color(0xFF0F172A),
          fontSize: math.max(10.0, _h * 0.058),
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeW = math.max(tp.width + 8, _sw * 0.065);
    final badgeH = tp.height + 3;
    final labelY = math.min(_h * 0.935, _h - badgeH / 2 - 1);
    final rect = Rect.fromCenter(
      center: Offset(vc.dx, labelY),
      width: badgeW,
      height: badgeH,
    );
    final badge = RRect.fromRectAndRadius(rect, Radius.circular(_h * 0.010));
    c.drawRRect(badge, Paint()..color = Colors.white);
    c.drawRRect(badge, _stroke(const Color(0xFF1976D2), 1.0));
    tp.paint(c, Offset(
      rect.left + (badgeW - tp.width) / 2,
      rect.top + (badgeH - tp.height) / 2,
    ));
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
