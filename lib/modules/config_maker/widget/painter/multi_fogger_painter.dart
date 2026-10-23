import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Top-down/elevation view painter for a Greenhouse Multi-Fogger System.
/// Styled after high-precision greenhouse misting / fogging equipment:
///  - Main horizontal header line with overhead suspension mounts/truss hooks.
///  - Common inlet pipe with socket coupling and open bore on the left.
///  - Supply pressure regulator & solenoid valve with wiring.
///  - Multiple drop channels with anti-drip check valves, solenoid controls,
///    and 4-way micro fogger nozzle heads.
///
/// PORTS (normalised to canvas size):
///   - inletPort(size) : centre of common inlet pipe (left end)
class DetailedMultiFoggerPainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;
  final int? foggers;
  final List<String>? foggerNames;

  DetailedMultiFoggerPainter({
    required this.isOn,
    this.showJoints = true,
    this.foggers,
    this.foggerNames,
  });

  /// Default number of fogger channels.
  static const int foggerCount = 6;

  /// Recommended aspect ratio (width / height)
  static const double recommendedAspect = 2.5;

  static Size preferredSize(double height) =>
      Size(height * recommendedAspect, height);

  // Layout constants (fractions of design-box height u)
  static const double _hy = 0.22; // main header centre line
  static const double _firstFoggerU = 0.32; // x of first fogger channel
  static const double _rightMarginU = 0.16; // room right of last fogger
  static const double _inletU = 0.11; // x of inlet opening centre

  static double _unit(Size s) => s.height;

  static Offset inletPort(Size s) {
    final double u = _unit(s);
    return Offset(u * _inletU, (s.height - u) / 2 + u * _hy);
  }

  // ---------------------------------------------------------------- Palette
  static const Color _edge = Color(0xFF1B2024);
  static const Color _steelLight = Color(0xFFECEFF1);
  static const Color _steelMid = Color(0xFF90A4AE);
  static const Color _steelDark = Color(0xFF455A64);

  static const Color _brassLight = Color(0xFFFFD54F);
  static const Color _brassMid = Color(0xFFFFB300);
  static const Color _brassDark = Color(0xFFE65100);

  static const Color _solenoidBody = Color(0xFF1E252A);
  static const Color _solenoidBlue = Color(0xFF0288D1);

  static const List<Color> _pvcCyl = [
    Color(0xFF546E7A),
    Color(0xFFB0BEC5),
    Color(0xFF78909C),
    Color(0xFF37474F),
  ];

  static const List<Color> _pvcJoint = [
    Color(0xFF90A4AE),
    Color(0xFFECEFF1),
    Color(0xFFCFD8DC),
    Color(0xFF78909C),
  ];

  static const List<double> _cylStops = [0.0, 0.25, 0.65, 1.0];

  double _w = 0;
  double _h = 0;
  double _firstX = 0;
  double _gap = 0;
  int _n = foggerCount;

  // ---------------------------------------------------------------- Helpers
  Paint _gv(Rect r, List<Color> c, [List<double>? s]) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(
      colors: c,
      stops: s,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(r);

  Paint _gh(Rect r, List<Color> c, [List<double>? s]) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(
      colors: c,
      stops: s,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(r);

  Paint _stroke(Color c, double w) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  void _cylH(Canvas c, Rect r, {double radius = 2, List<Color>? colors}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, _gv(r, colors ?? _pvcCyl, _cylStops));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.75), 0.8));
  }

  void _cylV(Canvas c, Rect r, {double radius = 2, List<Color>? colors}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, _gh(r, colors ?? _pvcCyl, _cylStops));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.75), 0.8));
  }

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
  }

  void _bolt(Canvas c, Offset o, double r) {
    c.drawCircle(o, r, Paint()..color = _steelLight);
    c.drawCircle(o, r, _stroke(_edge, 0.7));
    c.drawCircle(o, r * 0.35, Paint()..color = const Color(0xFF7FA6C9));
  }

  // ---------------------------------------------------------------- Paint
  @override
  void paint(Canvas canvas, Size size) {
    _n = foggers ?? foggerCount;
    if (_n <= 0) return;

    final double u = _unit(size);
    _w = size.width;
    _h = u;
    _firstX = u * _firstFoggerU;
    _gap = _n > 1
        ? math.max(
            u * 0.20,
            (size.width - u * _rightMarginU - _firstX) / (_n - 1),
          )
        : 0;

    canvas.save();
    canvas.translate(0, (size.height - u) / 2);

    // 1. Suspension truss mounts (greenhouse overhead structure)
    _drawTrussMounts(canvas);

    // 2. Main header line & inlet pipe
    _drawInletPipe(canvas);
    _drawHeader(canvas);

    // 3. Drop channels with anti-drip check valves & 4-way fogger heads
    for (int i = 0; i < _n; i++) {
      _drawDropChannel(canvas, i);
    }

    canvas.restore();
  }

  void _drawTrussMounts(Canvas c) {
    // Overhead suspension hangers connecting header pipe to greenhouse frame
    final Paint hangerPaint = _stroke(_steelDark, _h * 0.018);
    final Paint hookPaint = Paint()..color = _steelMid;

    for (int i = 0; i < _n; i++) {
      final double xc = _firstX + _gap * i;
      final double hy = _h * _hy;

      c.drawLine(Offset(xc, 0), Offset(xc, hy - _h * 0.035), hangerPaint);
      c.drawCircle(Offset(xc, 0), _h * 0.02, hookPaint);
      c.drawCircle(Offset(xc, 0), _h * 0.02, _stroke(_edge, 0.8));

      // Pipe mounting clamp
      final Rect clamp = Rect.fromCenter(
        center: Offset(xc, hy),
        width: _h * 0.045,
        height: _h * 0.08,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(clamp, Radius.circular(_h * 0.01)),
        Paint()..color = _steelDark,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(clamp, Radius.circular(_h * 0.01)),
        _stroke(_edge, 0.8),
      );
    }
  }

  void _drawInletPipe(Canvas c) {
    final double top = _h * (_hy - 0.030);
    final double bottom = _h * (_hy + 0.030);
    final double x0 = _h * _inletU;
    final double xEnd = _firstX - _h * 0.12;

    _cylH(c, Rect.fromLTRB(x0, top, xEnd, bottom), radius: 2);

    // Socket coupling
    _cylH(
      c,
      Rect.fromCenter(
        center: Offset((x0 + xEnd) / 2, _h * _hy),
        width: _h * 0.06,
        height: _h * 0.075,
      ),
      radius: 2,
      colors: _pvcJoint,
    );
  }

  void _drawInletOpening(Canvas c) {}

  void _drawHeader(Canvas c) {
    final double startX = _firstX - _h * 0.12;
    final double endX = math.min(_w - _h * 0.02, _firstX + _gap * (_n - 1) + _h * 0.12);

    // Main header tube
    _cylH(
      c,
      Rect.fromLTRB(startX, _h * (_hy - 0.030), endX, _h * (_hy + 0.030)),
      radius: _h * 0.025,
    );

    // Right end cap
    final Rect endCap = Rect.fromCenter(
      center: Offset(endX, _h * _hy),
      width: _h * 0.04,
      height: _h * 0.075,
    );
    _cylH(c, endCap, radius: 4, colors: _pvcJoint);

    if (showJoints) {
      _bolt(c, Offset(endX, _h * (_hy - 0.02)), _h * 0.008);
      _bolt(c, Offset(endX, _h * (_hy + 0.02)), _h * 0.008);
    }

    // Tee couplings for each fogger drop line
    for (int i = 0; i < _n; i++) {
      final double xc = _firstX + _gap * i;
      final double cy = _h * _hy;

      final Rect sleeve = Rect.fromCenter(
        center: Offset(xc, cy),
        width: _h * 0.08,
        height: _h * 0.07,
      );
      _cylH(c, sleeve, radius: 2, colors: _pvcJoint);

      final Rect dropArm = Rect.fromCenter(
        center: Offset(xc, cy + _h * 0.025),
        width: _h * 0.045,
        height: _h * 0.06,
      );
      _cylV(c, dropArm, radius: 2, colors: _pvcJoint);
    }
  }

  void _drawMainSolenoid(Canvas c) {}

  void _drawDropChannel(Canvas c, int i) {
    final double xc = _firstX + _gap * i;
    final double hy = _h * _hy;

    // 1. Vertical drop pipe from header tee down to anti-drip check valve
    final double pipeTop = hy + _h * 0.035;
    final double valveTop = hy + _h * 0.22;
    _cylV(c, Rect.fromLTRB(xc - _h * 0.018, pipeTop, xc + _h * 0.018, valveTop));

    // 2. Anti-drip check valve body (brass hex / cylinder)
    final double valveH = _h * 0.12;
    final Rect valveRect = Rect.fromLTWH(xc - _h * 0.03, valveTop, _h * 0.06, valveH);
    c.drawRRect(
      RRect.fromRectAndRadius(valveRect, Radius.circular(_h * 0.012)),
      _gh(valveRect, [_brassLight, _brassMid, _brassDark]),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(valveRect, Radius.circular(_h * 0.012)),
      _stroke(_edge, 0.9),
    );

    // Valve collar accent ring
    final Rect collar = Rect.fromLTWH(xc - _h * 0.032, valveTop + valveH * 0.3, _h * 0.064, _h * 0.02);
    c.drawRect(collar, Paint()..color = const Color(0xFF1565C0));
    c.drawRect(collar, _stroke(_edge, 0.6));

    // 3. Lower riser pipe connecting valve to fogger head
    final double lowerPipeTop = valveTop + valveH;
    final double foggerY = _h * 0.74;
    _cylV(c, Rect.fromLTRB(xc - _h * 0.016, lowerPipeTop, xc + _h * 0.016, foggerY));

    // 4. 4-Way Cross Fogger Nozzle Assembly
    _draw4WayFoggerHead(c, Offset(xc, foggerY));

    // Fogger Name / Serial No Badge
    final String fName = (foggerNames != null && i < foggerNames!.length)
        ? foggerNames![i]
        : 'F${i + 1}';

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: fName,
        style: TextStyle(
          color: Colors.white,
          fontSize: math.max(12.0, _h * 0.085),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double badgeW = math.max(tp.width + 12, _h * 0.085);
    final double badgeH = tp.height + 5;
    final double labelY = _h * 0.92;

    final Rect badgeRect = Rect.fromCenter(
      center: Offset(xc, labelY),
      width: badgeW,
      height: badgeH,
    );
    final RRect badgeRRect = RRect.fromRectAndRadius(
      badgeRect,
      Radius.circular(math.max(4.0, _h * 0.015)),
    );

    c.drawRRect(badgeRRect, Paint()..color = const Color(0xFF0F172A));
    c.drawRRect(badgeRRect, _stroke(const Color(0xFF0288D1), 1.2));

    tp.paint(
      c,
      Offset(
        badgeRect.left + (badgeW - tp.width) / 2,
        badgeRect.top + (badgeH - tp.height) / 2,
      ),
    );
  }

  void _draw4WayFoggerHead(Canvas c, Offset center) {
    final double r = _h * 0.048;

    // Outer shadow
    c.drawCircle(center + const Offset(0, 2), r + 1, Paint()..color = Colors.black26);

    // Central brass/chrome manifold hub
    final Rect hubBox = Rect.fromCircle(center: center, radius: r);
    c.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [_brassLight, _brassMid, _brassDark],
        ).createShader(hubBox),
    );
    c.drawCircle(center, r, _stroke(_edge, 1.0));

    // Inner anti-drip silicone core ring
    c.drawCircle(center, r * 0.55, Paint()..color = const Color(0xFF0288D1));
    c.drawCircle(center, r * 0.55, _stroke(_edge, 0.7));
    c.drawCircle(center, r * 0.25, Paint()..color = Colors.white);

    // 4 Stainless Micro Fogger Nozzle tips (pointing North, South, East, West / angled)
    final double nozzleLen = _h * 0.055;
    final double nozzleW = _h * 0.02;

    // Angle offsets for 4-way nozzle distribution (30 deg, 150 deg, 210 deg, 330 deg or 4-cross)
    final List<double> angles = [
      math.pi * 0.25, // Down-Right
      math.pi * 0.75, // Down-Left
      math.pi * 1.25, // Up-Left
      math.pi * 1.75, // Up-Right
    ];

    for (final angle in angles) {
      final double cosA = math.cos(angle);
      final double sinA = math.sin(angle);

      final Offset tip = center + Offset(cosA, sinA) * (r + nozzleLen);
      final Offset base = center + Offset(cosA, sinA) * r;

      // Nozzle barrel line
      c.drawLine(
        base,
        tip,
        Paint()
          ..color = _steelMid
          ..strokeWidth = nozzleW
          ..strokeCap = StrokeCap.butt,
      );
      c.drawLine(
        base,
        tip,
        _stroke(_edge, 0.7),
      );

      // Micro orifice tip (brass)
      c.drawCircle(tip, nozzleW * 0.7, Paint()..color = _brassMid);
      c.drawCircle(tip, nozzleW * 0.7, _stroke(_edge, 0.6));
      c.drawCircle(tip, nozzleW * 0.3, Paint()..color = const Color(0xFF0D47A1));
    }
  }

  @override
  bool shouldRepaint(covariant DetailedMultiFoggerPainter old) =>
      old.isOn != isOn ||
      old.showJoints != showJoints ||
      old.foggers != foggers ||
      !listEquals(old.foggerNames, foggerNames);
}

/// Widget Wrapper for DetailedMultiFoggerPainter.
class MultiFoggerView extends StatelessWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;
  final int? foggers;
  final List<String>? foggerNames;

  const MultiFoggerView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    required this.size,
    this.foggers,
    this.foggerNames,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: DetailedMultiFoggerPainter(
        isOn: isOn,
        showJoints: showJoints,
        foggers: foggers,
        foggerNames: foggerNames,
      ),
    );
  }
}
