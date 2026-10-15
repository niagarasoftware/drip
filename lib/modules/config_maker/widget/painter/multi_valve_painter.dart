import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pressure_sensor_painter.dart';

/// Top-down valve manifold painter, styled after the reference illustration
/// (no text, no leader lines / arrows):
///  - Single horizontal header with light grey sleeve couplings and a rounded
///    end cap. The common inlet is an open pipe end (white ring + black bore)
///    at the left end of the header.
///  - Per channel: orange air-release cap on a grey riser with a black band,
///    black diaphragm valve (bolt ring, end-on solenoid, red wire),
///    numbered-free sticker coupling and a wide lateral pipe ending in an
///    open black bore.
///  - OPTIONAL per channel: INPUT pressure sensor directly under the header
///    and LATERAL pressure sensor fitted on the lateral pipe. Only the valves
///    listed in [sensorValves] get them (default: valves 1 and 2).
///
/// AUTO-FIT LAYOUT
///   Everything is drawn in a design box of height
///   u = min(canvasHeight, canvasWidth / [recommendedAspect]).
///   Component sizes scale with u; the valves are spread over the full canvas
///   width, so a wider canvas gives longer pipe between the valves. The
///   drawing is centred vertically when the canvas is taller than needed.
///   Use [preferredSize] for the full-size layout.
///
/// SENSOR VALUES
///   [valvePressures] (input sensor) and [lateralPressures] (lateral sensor)
///   are optional normalised (0..1) values, one per valve. While [isOn] they
///   default to 0.62 / 0.46; when off the needles rest at 0.
///
/// [sensorValves] holds the 0-based indices of the valves that carry the
/// pressure sensors. Default {0, 1} = the first and second valve only.
/// Pass `{}` for no sensors, or e.g. `{0, 2, 5}` for any other combination.
///
/// [valves] sets the number of channels (default [valveCount] = 7).
///
/// PORTS (normalised to canvas size):
///   - inletPort(size)    : centre of the common inlet opening (left end)
class DetailedMultiValvePainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;
  final List<double>? valvePressures;
  final List<double>? lateralPressures;
  final int? valves;

  /// 0-based indices of the valves that have pressure sensors.
  final Set<int> sensorValves;

  DetailedMultiValvePainter({
    required this.isOn,
    this.showJoints = true,
    this.valvePressures,
    this.lateralPressures,
    this.valves,
    this.sensorValves = const {0, 1},
  });

  /// Default number of channels.
  static const int valveCount = 7;

  /// Width / height the component sizes were designed for.
  static const double designAspect = 1.5;

  /// Minimum canvas width / height for the full-size layout. Narrower
  /// canvases shrink the drawing uniformly instead of overlapping.
  static const double recommendedAspect = 2.2;

  /// Canvas size that gives the layout at full scale for a given height.
  static Size preferredSize(double height) =>
      Size(height * recommendedAspect, height);

  // Layout constants (fractions of u, the design-box height)
  static const double _firstValveU = 0.36; // x of valve 1
  static const double _rightMarginU = 0.18; // room right of the last valve
  static const double _inletU = 0.08; // x of the inlet opening centre

  // Vertical layout (fractions of u)
  static const double _hy = 0.258; // header centre line
  static const double _yGauge = 0.365; // input gauge centre
  static const double _yUnionTop = 0.465; // upper union centre
  static const double _yValve = 0.58; // valve bonnet centre

  /// Elbow bend direction per valve: 1 = right, -1 = left, 0 = straight down.
  static const List<int> _elbowDir = [0, 0, 0, 0, 0, 0, 0];

  static double _unit(Size s) => math.min(s.height, s.width / recommendedAspect);

  static Offset inletPort(Size s) {
    final double u = _unit(s);
    return Offset(u * _inletU, (s.height - u) / 2 + u * _hy);
  }

  // ---------------------------------------------------------------- Palette
  static const Color _edge = Color(0xFF1B2024);
  static const Color _steelLight = Color(0xFFECEFF1);

  static const Color _orangeLight = Color(0xFFFFA040);
  static const Color _orangeMid = Color(0xFFFF7A1A);
  static const Color _orangeDark = Color(0xFFD9540A);

  static const Color _valveDark = Color(0xFF0E1215);
  static const Color _valveBody = Color(0xFF1E252A);
  static const Color _valveLight = Color(0xFF3A464F);

  // Medium grey PVC (pipes)
  static const List<Color> _pvcCyl = [
    Color(0xFF6C7A86),
    Color(0xFFA9B6C0),
    Color(0xFF8795A1),
    Color(0xFF5A6670),
  ];
  // Light grey PVC (sleeves, couplings)
  static const List<Color> _pvcJoint = [
    Color(0xFFB4C0CA),
    Color(0xFFE6EBEF),
    Color(0xFFCBD4DB),
    Color(0xFF9AA7B2),
  ];
  static const List<Color> _blackCyl = [
    Color(0xFF0E1215),
    Color(0xFF3A464F),
    Color(0xFF222B31),
    Color(0xFF0A0D10),
  ];
  // Orange brass fitting (lateral gauge)
  static const List<Color> _orangeCyl = [
    Color(0xFFA33A08),
    Color(0xFFFFB066),
    Color(0xFFFF7A1A),
    Color(0xFF8C3206),
  ];
  static const List<double> _cylStops = [0.0, 0.25, 0.65, 1.0];

  double _w = 0; // canvas width            -> valve x positions / pipe lengths
  double _h = 0; // design-box height (u)   -> component sizes (vertical)
  double _sw = 0; // u * designAspect       -> component sizes (horizontal)
  double _firstX = 0; // x of valve 1
  double _gap = 0; // distance between valve centres
  int _n = valveCount;

  // ---------------------------------------------------------------- Helpers
  double get _pw => _sw * 0.04; // standard pipe width
  double _vx(int i) => _firstX + _gap * i;

  Paint _gv(Rect r, List<Color> c, [List<double>? s]) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(
        colors: c,
        stops: s,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter)
        .createShader(r);

  Paint _gh(Rect r, List<Color> c, [List<double>? s]) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(
        colors: c,
        stops: s,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight)
        .createShader(r);

  Paint _stroke(Color c, double w) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  /// Horizontal pipe (shaded top -> bottom)
  void _cylH(Canvas c, Rect r, {double radius = 2, List<Color>? colors}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, _gv(r, colors ?? _pvcCyl, _cylStops));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.7), 0.8));
  }

  /// Vertical pipe (shaded left -> right)
  void _cylV(Canvas c, Rect r, {double radius = 2, List<Color>? colors}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, _gh(r, colors ?? _pvcCyl, _cylStops));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.7), 0.8));
  }

  /// Flat, top-view pipe: dark outline + single flat fill, no highlight.
  void _flatPipe(Canvas c, Path p, double w,
      {Color fill = const Color(0xFF8795A1)}) {
    c.drawPath(
        p,
        _stroke(_edge.withValues(alpha: 0.85), w + 1.6)
          ..strokeCap = StrokeCap.butt
          ..strokeJoin = StrokeJoin.round);
    c.drawPath(
        p,
        _stroke(fill, w)
          ..strokeCap = StrokeCap.butt
          ..strokeJoin = StrokeJoin.round);
  }

  /// Ground entry for a pipe that bends sideways (collar across the pipe end).
  void _groundCollarSide(Canvas c, Offset end, double pipeW) {
    final Rect collar =
    Rect.fromCenter(center: end, width: _sw * 0.014, height: pipeW * 1.2);
    c.drawRect(collar, Paint()..color = const Color(0xFFB4C0CA));
    c.drawRect(collar, _stroke(_edge.withValues(alpha: 0.85), 0.9));
  }

  /// Open pipe end seen end-on: steel rim + black bore.
  void _openEnd(Canvas c, Offset ctr, double r) {
    final Rect box = Rect.fromCircle(center: ctr, radius: r);
    c.drawCircle(
      ctr + Offset(r * 0.08, r * 0.14),
      r,
      Paint()
        ..color = const Color(0x44000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.0, r * 0.15)),
    );
    c.drawCircle(
      ctr,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFC3CCD3), Color(0xFF7D8A95)],
        ).createShader(box),
    );
    c.drawCircle(ctr, r, _stroke(_edge.withValues(alpha: 0.85), 1.0));
    c.drawCircle(ctr, r * 0.74, Paint()..color = const Color(0xFF111418));
    c.drawCircle(ctr, r * 0.74, _stroke(const Color(0xFF3A444D), 0.9));
    // bore highlight
    c.drawArc(
      Rect.fromCircle(center: ctr, radius: r * 0.60),
      math.pi * 1.05,
      math.pi * 0.45,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, r * 0.06)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  void _bolt(Canvas c, Offset o, double r) {
    c.drawCircle(o, r, Paint()..color = _steelLight);
    c.drawCircle(o, r, _stroke(_edge, 0.7));
    c.drawCircle(o, r * 0.35, Paint()..color = const Color(0xFF7FA6C9));
  }

  // ---------------------------------------------------------------- Paint
  @override
  void paint(Canvas canvas, Size size) {
    _n = math.max(1, valves ?? valveCount);

    final double u = _unit(size);
    _w = size.width;
    _h = u;
    _sw = u * designAspect;
    _firstX = u * _firstValveU;
    _gap = math.max(
      u * 0.2,
      (size.width - u * _rightMarginU - _firstX) / math.max(1, _n - 1),
    );

    canvas.save();
    // centre the design box vertically when the canvas is taller than needed
    canvas.translate(0, (size.height - u) / 2);

    _drawInletPipe(canvas);
    _drawHeader(canvas);

    for (int i = 0; i < _n; i++) {
      _drawRiserAndCap(canvas, i);
      _drawDropStub(canvas, i);
    }
    for (int i = 0; i < _n; i++) {
      _drawValve(canvas, i);
      _drawLowerAssembly(canvas, i);
    }
    // Sensors last so nothing from a neighbouring valve paints over them.
    // Only the valves listed in [sensorValves] have them.
    for (int i = 0; i < _n; i++) {
      if (sensorValves.contains(i)) _drawPressureGauges(canvas, i);
    }

    _drawInletOpening(canvas);
    canvas.restore();
  }

  double get _hdrStart => _vx(0) - _sw * 0.07;
  double get _hdrEnd => math.min(_w - _h * 0.01, _vx(_n - 1) + _h * 0.16);

  // ------------------------------- Common inlet (straight, horizontal)
  void _drawInletPipe(Canvas c) {
    final double top = _h * (_hy - 0.032);
    final double bottom = _h * (_hy + 0.032);
    final double x0 = _h * _inletU;

    _cylH(c, Rect.fromLTRB(x0, top, _hdrStart + 2, bottom), radius: 2);

    // light-grey socket coupling on the inlet pipe
    _cylH(
      c,
      Rect.fromCenter(
          center: Offset((x0 + _hdrStart) / 2, _h * _hy),
          width: _sw * 0.03,
          height: _h * 0.075),
      radius: 2,
      colors: _pvcJoint,
    );
  }

  void _drawInletOpening(Canvas c) {
    _openEnd(c, Offset(_h * _inletU, _h * _hy), _h * 0.052);
  }

  // ----------------------------------------------- Common header + sleeves
  void _drawHeader(Canvas c) {
    // main header pipe with a rounded end cap
    _cylH(c, Rect.fromLTRB(_hdrStart, _h * (_hy - 0.032), _hdrEnd, _h * (_hy + 0.032)),
        radius: _h * 0.03);

    for (int i = 0; i < _n; i++) {
      final double xc = _vx(i);
      final double cy = _h * _hy;

      // horizontal socket sleeve
      final Rect sleeve = Rect.fromCenter(
          center: Offset(xc, cy), width: _sw * 0.105, height: _h * 0.07);
      _cylH(c, sleeve, radius: 2, colors: _pvcJoint);

      // cross vertical arm (up + down)
      final Rect arm = Rect.fromCenter(
          center: Offset(xc, cy), width: _sw * 0.04, height: _h * 0.115);
      _cylV(c, arm, radius: 3, colors: _pvcJoint);

      if (showJoints) {
        final Paint ring = Paint()
          ..color = Colors.black38
          ..strokeWidth = 0.8;
        c.drawLine(Offset(sleeve.left + _sw * 0.012, sleeve.top + 1),
            Offset(sleeve.left + _sw * 0.012, sleeve.bottom - 1), ring);
        c.drawLine(Offset(sleeve.right - _sw * 0.012, sleeve.top + 1),
            Offset(sleeve.right - _sw * 0.012, sleeve.bottom - 1), ring);
      }
    }
  }

  // ---------------------------- Vertical riser & orange air-release cap
  void _drawRiserAndCap(Canvas c, int i) {
    final double xc = _vx(i);

    // vertical riser up from the cross header
    _cylV(c, Rect.fromLTRB(xc - _pw * 0.5, _h * 0.095, xc + _pw * 0.5, _h * 0.20),
        radius: 2);
    // black band on the riser
    _cylV(
        c,
        Rect.fromCenter(
            center: Offset(xc, _h * 0.15), width: _pw * 1.12, height: _h * 0.026),
        radius: 2,
        colors: _blackCyl);

    // top connector / adapter ring at the top of the riser
    final Rect topConnector = Rect.fromCenter(
        center: Offset(xc, _h * 0.095), width: _pw * 1.05, height: _h * 0.02);
    _cylV(c, topConnector, radius: 2, colors: _pvcJoint);

    // vertical orange cap / air release valve knob
    final Rect cap = Rect.fromCenter(
        center: Offset(xc, _h * 0.068), width: _sw * 0.024, height: _h * 0.052);
    final RRect rr = RRect.fromRectAndRadius(cap, const Radius.circular(5));
    c.drawRRect(rr, _gh(cap, const [_orangeLight, _orangeMid, _orangeDark]));
    c.drawRRect(rr, _stroke(_edge, 0.8));

    // dome at the top of the orange cap
    final Rect dome = Rect.fromCenter(
        center: Offset(xc, cap.top), width: _sw * 0.024, height: _h * 0.02);
    c.drawOval(dome, _gv(dome, const [_orangeLight, _orangeMid]));
    c.drawOval(dome, _stroke(_edge, 0.6));

    // grip lines / ridges on the orange cap
    for (double dx = -_sw * 0.006; dx <= _sw * 0.006; dx += _sw * 0.004) {
      c.drawLine(Offset(xc + dx, cap.top + 4), Offset(xc + dx, cap.bottom - 3),
          Paint()
            ..color = Colors.black26
            ..strokeWidth = 0.8);
    }
  }

  // ---------------- Drop pipe from the cross to the valve (behind the gauge)
  void _drawDropStub(Canvas c, int i) {
    final double xc = _vx(i);

    _cylV(c, Rect.fromLTRB(xc - _pw * 0.5, _h * 0.31, xc + _pw * 0.5, _h * 0.47));

    // light rounded tee cap right under the cross
    final Rect cap = Rect.fromCenter(
        center: Offset(xc, _h * 0.292), width: _pw * 1.05, height: _h * 0.06);
    final RRect rr = RRect.fromRectAndRadius(cap, Radius.circular(_pw * 0.5));
    c.drawRRect(rr, _gh(cap, _pvcJoint, _cylStops));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.7), 0.8));
  }

  // ------------------------------------------------- Diaphragm control valve
  void _drawValve(Canvas c, int i) {
    final double xc = _vx(i);
    final Offset vc = Offset(xc, _h * _yValve);
    final double R = _h * 0.102; // Slightly bigger valve bonnet outer ring radius

    // upper union nut
    final Rect upperUnion = Rect.fromCenter(
        center: Offset(xc, _h * _yUnionTop), width: _sw * 0.062, height: _h * 0.054);
    _cylV(c, upperUnion, radius: 4, colors: _blackCyl);
    if (showJoints) {
      for (double y = upperUnion.top + 4; y < upperUnion.bottom - 2; y += 4) {
        c.drawLine(Offset(upperUnion.left + 2, y), Offset(upperUnion.right - 2, y),
            Paint()
              ..color = Colors.black54
              ..strokeWidth = 0.6);
      }
    }

    // body block (neck above, body below bonnet)
    _cylV(c, Rect.fromLTRB(xc - _sw * 0.028, vc.dy - _h * 0.095, xc + _sw * 0.028, vc.dy + _h * 0.115),
        radius: 3, colors: _blackCyl);

    // small flange tab on the right of the bonnet
    final Rect tab = Rect.fromCenter(
        center: vc + Offset(R * 0.97, R * 0.10), width: R * 0.28, height: R * 0.52);
    c.drawRRect(RRect.fromRectAndRadius(tab, Radius.circular(R * 0.06)),
        Paint()..color = _valveBody);
    c.drawRRect(RRect.fromRectAndRadius(tab, Radius.circular(R * 0.06)),
        _stroke(_edge, 1.0));

    // bonnet outer ring
    final Rect bonnetRect = Rect.fromCircle(center: vc, radius: R);
    c.drawCircle(
        vc,
        R,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.35),
            colors: [_valveLight, _valveBody, _valveDark],
            stops: [0.0, 0.55, 1.0],
          ).createShader(bonnetRect));
    c.drawCircle(vc, R, _stroke(_edge, 1.2));

    // inner raised dome rings
    c.drawCircle(vc, R * 0.80, _stroke(Colors.black87, 1.0));
    c.drawCircle(vc, R * 0.62, Paint()..color = _valveBody.withValues(alpha: 0.9));
    c.drawCircle(vc, R * 0.62, _stroke(Colors.black54, 1.0));

    // 8-bolt ring
    if (showJoints) {
      for (int k = 0; k < 8; k++) {
        final double a = k * 2 * math.pi / 8 + math.pi / 8;
        _bolt(c, vc + Offset(math.cos(a), math.sin(a)) * (R * 0.91), _h * 0.0105);
      }
    }

    // End-on solenoid: hub + thick shaft pointing lower-left with a cap
    final Offset shaftEnd = vc + Offset(-R * 0.44, R * 0.20);
    c.drawCircle(vc, R * 0.36, Paint()..color = const Color(0xFF05070A));
    c.drawCircle(vc, R * 0.36, _stroke(_valveLight.withValues(alpha: 0.7), 0.9));
    c.drawLine(
      vc + Offset(R * 0.04, R * 0.06),
      shaftEnd + Offset(R * 0.04, R * 0.06),
      Paint()
        ..color = const Color(0x55000000)
        ..strokeWidth = R * 0.38
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      vc,
      shaftEnd,
      Paint()
        ..color = _valveDark
        ..strokeWidth = R * 0.34
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(shaftEnd, R * 0.20, Paint()..color = _valveBody);
    c.drawCircle(shaftEnd, R * 0.20, _stroke(_valveLight, 0.9));
    c.drawCircle(shaftEnd, R * 0.095, Paint()..color = _valveDark);

    // Wire bracket (upper-left of valve)
    final Offset br = vc + Offset(-_sw * 0.014, -R * 0.98);
    final Rect bracket = Rect.fromCenter(center: br, width: _sw * 0.028, height: _h * 0.036);
    c.drawRRect(RRect.fromRectAndRadius(bracket, const Radius.circular(2)),
        Paint()..color = const Color(0xFF0E1215));
    c.drawRRect(RRect.fromRectAndRadius(bracket, const Radius.circular(2)),
        _stroke(_valveLight, 0.7));

    // Red + black wires from the solenoid, looping out left to the bracket
    final Offset sc = shaftEnd;
    final Path red = Path()
      ..moveTo(sc.dx - _sw * 0.006, sc.dy - _h * 0.012)
      ..cubicTo(sc.dx - _sw * 0.05, sc.dy - _h * 0.03, sc.dx - _sw * 0.052,
          br.dy - _h * 0.03, br.dx - _sw * 0.006, br.dy + _h * 0.005);
    final Path blk = Path()
      ..moveTo(sc.dx - _sw * 0.002, sc.dy - _h * 0.018)
      ..cubicTo(sc.dx - _sw * 0.035, sc.dy - _h * 0.045, sc.dx - _sw * 0.04,
          br.dy - _h * 0.02, br.dx - _sw * 0.002, br.dy + _h * 0.008);
    c.drawPath(blk, _stroke(Colors.black, 2.0));
    c.drawPath(red, _stroke(const Color(0xFFE53935), 2.2));
  }

  // -------- Lower union, sticker coupling, wide lateral pipe + open end
  void _drawLowerAssembly(Canvas c, int i) {
    final double xc = _vx(i);
    final double vy = _h * _yValve;
    final double pwL = _pw * 1.3; // lateral pipe is wider than the riser

    // lower union nut
    final Rect lowerUnion = Rect.fromCenter(
        center: Offset(xc, vy + _h * 0.135), width: _sw * 0.062, height: _h * 0.056);
    _cylV(c, lowerUnion, radius: 4, colors: _blackCyl);
    if (showJoints) {
      for (double y = lowerUnion.top + 4; y < lowerUnion.bottom - 2; y += 4) {
        c.drawLine(Offset(lowerUnion.left + 2, y), Offset(lowerUnion.right - 2, y),
            Paint()
              ..color = Colors.black54
              ..strokeWidth = 0.6);
      }
    }

    // light-grey coupling
    final Rect coupling = Rect.fromLTRB(
        xc - _sw * 0.0275, vy + _h * 0.162, xc + _sw * 0.0275, vy + _h * 0.235);
    _cylV(c, coupling, radius: 2, colors: _pvcJoint);

    // blue-outlined sticker (symbol only, no text)
    final Rect tag = Rect.fromCenter(
        center: Offset(xc, vy + _h * 0.20), width: _h * 0.040, height: _h * 0.038);
    c.drawRRect(RRect.fromRectAndRadius(tag, Radius.circular(_h * 0.006)),
        Paint()..color = Colors.white);
    c.drawRRect(RRect.fromRectAndRadius(tag, Radius.circular(_h * 0.006)),
        _stroke(const Color(0xFF1976D2), math.max(0.8, _h * 0.003)));
    c.drawRect(
      Rect.fromCenter(center: tag.center, width: tag.width * 0.42, height: tag.height * 0.16),
      Paint()..color = const Color(0xFF1976D2),
    );

    final int d = i < _elbowDir.length ? _elbowDir[i] : 0;

    if (d == 0) {
      // wide vertical lateral pipe
      _cylV(c, Rect.fromLTRB(xc - pwL / 2, vy + _h * 0.235, xc + pwL / 2, vy + _h * 0.35));
      // socket ring where the lateral meets the coupling
      _cylV(
          c,
          Rect.fromCenter(
              center: Offset(xc, vy + _h * 0.245), width: pwL * 1.12, height: _h * 0.018),
          radius: 2,
          colors: _pvcJoint);
      // open end, seen end-on
      _openEnd(c, Offset(xc, vy + _h * 0.365), pwL * 0.62);
    } else {
      _cylV(c, Rect.fromLTRB(xc - pwL / 2, vy + _h * 0.235, xc + pwL / 2, vy + _h * 0.30));
      final double endX = xc + d * _sw * 0.05;
      final double endY = vy + _h * 0.36;
      final Path elbow = Path()
        ..moveTo(xc, vy + _h * 0.29)
        ..lineTo(xc, vy + _h * 0.33)
        ..quadraticBezierTo(xc, endY, xc + d * _sw * 0.03, endY)
        ..lineTo(endX, endY);
      _flatPipe(c, elbow, pwL);
      _groundCollarSide(c, Offset(endX, endY), pwL);
    }
  }

  // ------------------------------------------------------ Pressure gauges
  double _needleValue(List<double>? list, int i, double fallback) {
    if (!isOn) return 0.0;
    if (list != null && i < list.length) return list[i].clamp(0.0, 1.0);
    return fallback;
  }

  /// Draws the INPUT and LATERAL pressure sensors for valve [i].
  /// Only called for valves listed in [sensorValves].
  void _drawPressureGauges(Canvas c, int i) {
    final double xc = _vx(i);

    // INPUT pressure sensor: using DetailedPressureSensorPainter from pressure_sensor_painter.dart
    final double inVal = _needleValue(valvePressures, i, 0.62);
    final double inSensorH = _h * 0.255;
    final double inSensorW = inSensorH * (680.0 / 1082.0);
    final double inLeft = xc - inSensorW / 2;
    final double inTop = (_h * _yGauge) - inSensorH * (427.0 / 1082.0);

    c.save();
    c.translate(inLeft, inTop);
    DetailedPressureSensorPainter(
      isOn: isOn && inVal > 0,
      showJoints: showJoints,
      pressure: inVal,
    ).paint(c, Size(inSensorW, inSensorH));
    c.restore();

    // LATERAL pressure sensor: fitted to the right of the lateral pipe
    final double pipeEdge = xc + _pw * 1.3 / 2;
    final double fit = _sw * 0.016;
    final double gy = _h * _yValve + _h * 0.278;

    final Rect nut =
    Rect.fromLTRB(pipeEdge - 1, gy - _h * 0.026, pipeEdge + fit + 1, gy + _h * 0.026);
    final RRect nr = RRect.fromRectAndRadius(nut, Radius.circular(_h * 0.008));
    c.drawRRect(nr, _gv(nut, _orangeCyl, _cylStops));
    c.drawRRect(nr, _stroke(_edge.withValues(alpha: 0.85), 0.8));

    final double latVal = _needleValue(lateralPressures, i, 0.46);
    final double latSensorH = _h * 0.235;
    final double latSensorW = latSensorH * (680.0 / 1082.0);
    final double latLeft = pipeEdge + fit;
    final double latTop = gy - latSensorH * (427.0 / 1082.0);

    c.save();
    c.translate(latLeft, latTop);
    DetailedPressureSensorPainter(
      isOn: isOn && latVal > 0,
      showJoints: showJoints,
      pressure: latVal,
    ).paint(c, Size(latSensorW, latSensorH));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant DetailedMultiValvePainter old) =>
      old.isOn != isOn ||
          old.showJoints != showJoints ||
          old.valves != valves ||
          !setEquals(old.sensorValves, sensorValves) ||
          !listEquals(old.valvePressures, valvePressures) ||
          !listEquals(old.lateralPressures, lateralPressures);
}

/// Widget Wrapper for DetailedMultiValvePainter.
///
/// For the full-size layout use
/// `DetailedMultiValvePainter.preferredSize(height)` (width = 2.2 x height).
/// Wider canvases lengthen the pipe between the valves; narrower ones shrink
/// the drawing uniformly.
class MultiValveView extends StatelessWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  /// Number of channels (default 7).
  final int? valves;

  /// 0-based indices of the valves that carry pressure sensors.
  /// Default {0, 1} = only the first and second valve.
  final Set<int> sensorValves;

  /// Normalised (0..1) needle positions, one per valve. Optional.
  /// [valvePressures] drives the input sensor under the header,
  /// [lateralPressures] drives the lateral sensor.
  final List<double>? valvePressures;
  final List<double>? lateralPressures;

  const MultiValveView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    required this.size,
    this.valves,
    this.sensorValves = const {0, 1},
    this.valvePressures,
    this.lateralPressures,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: DetailedMultiValvePainter(
        isOn: isOn,
        showJoints: showJoints,
        valves: valves,
        sensorValves: sensorValves,
        valvePressures: valvePressures,
        lateralPressures: lateralPressures,
      ),
    );
  }
}