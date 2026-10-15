import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Coordinate scaling helper for reference canvas (1000 x 600)
class _Sc {
  final double sx;
  final double sy;
  const _Sc(this.sx, this.sy);

  double x(double v) => v * sx;
  double y(double v) => v * sy;
  Offset pt(double vx, double vy) => Offset(vx * sx, vy * sy);
  Rect rect(double l, double t, double w, double h) =>
      Rect.fromLTWH(l * sx, t * sy, w * sx, h * sy);
  RRect rrect(double l, double t, double w, double h, double r) =>
      RRect.fromRectAndRadius(
          Rect.fromLTWH(l * sx, t * sy, w * sx, h * sy), Radius.circular(r * sx));
}

class _Flow {
  final List<Offset> pts; // reference coords, in the direction of the flow
  final Color color;
  const _Flow(this.pts, this.color);
}

/// Dual SAND filter station with red vessels and ONE supply pipeline.
///
/// Each filter has a 3-way valve on the single supply line:
///   FILTRATION: valve -> TOP-left nozzle. Water flows DOWN through sand and
///               gravel and leaves the BOTTOM-right nozzle as clean water.
///   BACKWASH  : valve -> BOTTOM-left nozzle. Water flows UP (opposite side),
///               lifts the sand bed, and the dirty water leaves the TOP-right
///               nozzle into the grey dirty-water line to waste.
///
/// Defaults: Filter 1 = filtration, Filter 2 = backwash.
class DetailedMultiFilterPainter extends CustomPainter {
  final bool isOn;
  final bool filter1IsBackwash;
  final bool filter2IsBackwash;
  final double phase;
  final bool showJoints;

  DetailedMultiFilterPainter({
    required this.isOn,
    this.filter1IsBackwash = false,
    this.filter2IsBackwash = true,
    this.phase = 0,
    this.showJoints = true,
  });

  // ---------------------------------------------------------------- palette
  static const Color _edge = Color(0xFF1E272C);

  // Red vessel paint
  static const Color _redLight = Color(0xFFEF5350);
  static const Color _redMid = Color(0xFFD32F2F);
  static const Color _redDark = Color(0xFF8E0000);
  static const Color _redAccent = Color(0xFFFF8A80);

  // Steel (hatch, vent, flanges)
  static const Color _steelDark = Color(0xFF546E7A);
  static const Color _steelMid = Color(0xFF90A4AE);
  static const Color _steelLight = Color(0xFFECEFF1);

  // Ordinary PVC water pipe palette (matching PipePainter)
  static const Color _pvcPipeEdge = Color(0xFF59636A);
  static const Color _pvcPipeBody = Color(0xFF98A4AC);
  static const Color _pvcPipeLight = Color(0xFFD3DBE0);

  // Dirty water (backwash drain) pipe palette
  static const Color _dirtyPipeEdge = Color(0xFF3E2723);
  static const Color _dirtyPipeBody = Color(0xFF6D4C41);
  static const Color _dirtyPipeLight = Color(0xFFA1887F);

  // General grey tones
  static const Color _greyDark = Color(0xFF37474F);

  // Media
  static const Color _sandTop = Color(0xFFE0D5C1);
  static const Color _sandMid = Color(0xFFC5B39B);
  static const Color _sandBot = Color(0xFF9E8B73);
  static const Color _gravel = Color(0xFF796B58);

  // Valves
  static const Color _valveRed = Color(0xFFE53935);
  static const Color _valveGreen = Color(0xFF43A047);
  static const Color _valveYellow = Color(0xFFFFB300);
  static const Color _valveBlack = Color(0xFF212121);

  // Water types
  static const Color _rawColor = Color(0xFF1976D2); // raw water
  static const Color _cleanColor = Color(0xFFE0F7FA); // filtered water
  static const Color _dirtyColor = Color(0xFF795548); // backwash waste

  // ------------------------------------------------------------ geometry
  static const double _cx1 = 280, _cx2 = 700; // tank centres
  static const double _half = 90; // tank half width
  static const double _bodyT = 220, _bodyH = 220;
  static const double _pw = 20; // pipe width

  // GREY 2nd line = DIRTY water pipeline (backwash waste) -> waste (left port)
  static const List<List<Offset>> _greyPipes = [
    [Offset(790, 270), Offset(870, 270), Offset(870, 130), Offset(20, 130)],
    [Offset(370, 270), Offset(450, 270), Offset(450, 130)],
  ];
  // Clean-water (cyan) pipes
  static const List<List<Offset>> _outletPipes = [
    [Offset(370, 390), Offset(450, 390), Offset(450, 521), Offset(1000, 521)],
    [Offset(790, 390), Offset(870, 390), Offset(870, 521)],
  ];
  // Raw-water (cyan): ONE supply line. At each filter the vertical branch runs
  // down to the BOTTOM-left nozzle, and a short stub at the 3-way valve (y=270)
  // goes to the TOP-left nozzle.
  static const List<List<Offset>> _inletPipes = [
    [Offset(20, 61), Offset(550, 61), Offset(550, 390), Offset(610, 390)],
    [Offset(120, 61), Offset(120, 390), Offset(190, 390)],
    [Offset(120, 270), Offset(190, 270)],
    [Offset(550, 270), Offset(610, 270)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final _Sc s = _Sc(size.width / 1000, size.height / 600);

    _drawGroundShadow(canvas, s);
    _drawSupportLegs(canvas, s);
    _drawPipes(canvas, s);
    _drawFlows(canvas, s); // under the tanks so pipe ends stay hidden
    _drawFilterTanks(canvas, s);
    _drawSandWindow(canvas, s, _cx1, filter1IsBackwash);
    _drawSandWindow(canvas, s, _cx2, filter2IsBackwash);
    _drawHatchAndVents(canvas, s);
    if (showJoints) _drawFlanges(canvas, s);
    _drawValves(canvas, s);
  }

  // -------------------------------------------------------------- helpers

  Paint _fillH(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(r);

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

  Paint _vesselH(Rect r) => _fillH(
      r, const [_redDark, _redLight, _redMid, _redDark],
      stops: const [0, 0.35, 0.7, 1]);

  Paint _steelH(Rect r) => _fillH(
      r, const [_steelDark, _steelLight, _steelMid, _steelDark],
      stops: const [0, 0.35, 0.7, 1]);

  /// Polyline with rounded elbows, in scaled canvas coordinates.
  Path _poly(List<Offset> p, _Sc s, {double r = 18}) {
    final Path path = Path()..moveTo(s.x(p.first.dx), s.y(p.first.dy));
    for (int i = 1; i < p.length - 1; i++) {
      final Offset a = p[i - 1], b = p[i], c = p[i + 1];
      final double d1 = (b - a).distance, d2 = (c - b).distance;
      final double rr = math.min(r, math.min(d1, d2) / 2);
      final Offset pa = b + (a - b) / d1 * rr;
      final Offset pc = b + (c - b) / d2 * rr;
      path.lineTo(s.x(pa.dx), s.y(pa.dy));
      path.quadraticBezierTo(s.x(b.dx), s.y(b.dy), s.x(pc.dx), s.y(pc.dy));
    }
    path.lineTo(s.x(p.last.dx), s.y(p.last.dy));
    return path;
  }

  // ------------------------------------------------------- ground shadow

  void _drawGroundShadow(Canvas canvas, _Sc s) {
    final Paint shadow = Paint()
      ..isAntiAlias = true
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.x(10));
    canvas.drawOval(s.rect(170, 540, 220, 30), shadow);
    canvas.drawOval(s.rect(590, 540, 220, 30), shadow);
  }

  // -------------------------------------------------------- support legs

  void _drawSupportLegs(Canvas canvas, _Sc s) {
    void legs(double cx) {
      for (final double lx in [cx - 65, cx + 47]) {
        final Rect leg = s.rect(lx, 440, 18, 105);
        canvas.drawRect(leg, _vesselH(leg));
        canvas.drawRect(leg, _stroke(_edge, s.x(1.2)));
        final Rect foot = s.rect(lx - 4, 540, 26, 8);
        canvas.drawRRect(s.rrect(lx - 4, 540, 26, 8, 2), _vesselH(foot));
        canvas.drawRRect(s.rrect(lx - 4, 540, 26, 8, 2), _stroke(_edge, s.x(1)));
      }
    }

    legs(_cx1);
    legs(_cx2);
  }

  // ---------------------------------------------------------- pipe bodies

  void _draw3DPipeGroup(
    Canvas canvas,
    _Sc s,
    List<List<Offset>> pipes, {
    required Color edgeColor,
    required Color bodyColor,
    required Color lightColor,
    bool isDirtyWater = false,
  }) {
    Paint line(Color c, double w) => Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.x(w)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.butt
      ..color = c;

    // 1. Soft contact shadow under the pipe
    for (final p in pipes) {
      final path = _poly(p, s);
      canvas.drawPath(
        path.shift(Offset(s.x(1.0), s.y(2.0))),
        line(const Color(0x35000000), _pw + 1.0),
      );
    }

    // 2. Dark outer edge / outline
    for (final p in pipes) {
      canvas.drawPath(_poly(p, s), line(_edge, _pw + 3.5));
    }

    // 3. Pipe body
    for (final p in pipes) {
      canvas.drawPath(_poly(p, s), line(bodyColor, _pw));
    }

    // 4. Inner shade / shadow (bottom-right)
    for (final p in pipes) {
      canvas.drawPath(
        _poly(p, s).shift(Offset(s.x(1.2), s.y(1.5))),
        line(edgeColor.withValues(alpha: 0.55), _pw * 0.42),
      );
    }

    // 5. Inner light highlight (top-left)
    for (final p in pipes) {
      canvas.drawPath(
        _poly(p, s).shift(Offset(s.x(-1.2), s.y(-1.5))),
        line(lightColor, _pw * 0.35),
      );
    }

    // 6. Specular glint streak (top-left)
    for (final p in pipes) {
      canvas.drawPath(
        _poly(p, s).shift(Offset(s.x(-1.8), s.y(-2.0))),
        line(Colors.white.withValues(alpha: 0.6), _pw * 0.12),
      );
    }

    // 7. Ribbed bands for dirty water pipe style
    if (isDirtyWater) {
      for (final p in pipes) {
        final Path path = _poly(p, s);
        final metrics = path.computeMetrics();
        for (final m in metrics) {
          const double step = 22.0;
          for (double d = 12.0; d < m.length - 12.0; d += step) {
            final t = m.getTangentForOffset(d);
            if (t != null) {
              final Offset pos = t.position;
              final Offset normal = Offset(-t.vector.dy, t.vector.dx);
              final Offset p1 = pos + normal * s.x(_pw * 0.52);
              final Offset p2 = pos - normal * s.x(_pw * 0.52);
              // Dark ribbed ring line
              canvas.drawLine(
                p1,
                p2,
                Paint()
                  ..color = edgeColor.withValues(alpha: 0.75)
                  ..strokeWidth = s.x(2.5)
                  ..strokeCap = StrokeCap.butt,
              );
              // Highlight edge on the ring
              canvas.drawLine(
                p1 - t.vector * s.x(1.0),
                p2 - t.vector * s.x(1.0),
                Paint()
                  ..color = lightColor.withValues(alpha: 0.6)
                  ..strokeWidth = s.x(1.0)
                  ..strokeCap = StrokeCap.butt,
              );
            }
          }
        }
      }
    }

    // 8. Coupling collars near end joints
    for (final p in pipes) {
      if (p.length >= 2) {
        _drawPipeCollar(canvas, s, p.first, p[1], edgeColor, bodyColor, lightColor);
        _drawPipeCollar(canvas, s, p.last, p[p.length - 2], edgeColor, bodyColor, lightColor);
      }
    }
  }

  void _drawPipeCollar(
    Canvas canvas,
    _Sc s,
    Offset from,
    Offset toward,
    Color edgeColor,
    Color bodyColor,
    Color lightColor,
  ) {
    final Offset v = toward - from;
    final double len = v.distance;
    if (len < 20) return;
    final Offset u = v / len;
    final Offset a = from + u * 4;
    final Offset b = from + u * 12;

    Paint line(Color c, double w) => Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.x(w)
      ..strokeCap = StrokeCap.butt
      ..color = c;

    final Path path = Path()
      ..moveTo(s.x(a.dx), s.y(a.dy))
      ..lineTo(s.x(b.dx), s.y(b.dy));

    canvas.drawPath(path, line(_edge, _pw + 6.0));
    canvas.drawPath(path, line(edgeColor, _pw + 4.5));
    canvas.drawPath(path, line(bodyColor, _pw + 2.5));
    canvas.drawPath(
      path.shift(Offset(s.x(-1.0), s.y(-1.2))),
      line(lightColor, _pw * 0.3),
    );
  }

  void _drawPipes(Canvas canvas, _Sc s) {
    // Dirty water pipe first (backwash drain), painted in dirty water brown palette with ribbed style
    _draw3DPipeGroup(
      canvas,
      s,
      _greyPipes,
      edgeColor: _dirtyPipeEdge,
      bodyColor: _dirtyPipeBody,
      lightColor: _dirtyPipeLight,
      isDirtyWater: true,
    );

    // Main supply (inlet) & filtered outlet pipes cross over, painted in ordinary PVC grey style (from PipePainter)
    _draw3DPipeGroup(
      canvas,
      s,
      _outletPipes,
      edgeColor: _pvcPipeEdge,
      bodyColor: _pvcPipeBody,
      lightColor: _pvcPipeLight,
    );
    _draw3DPipeGroup(
      canvas,
      s,
      _inletPipes,
      edgeColor: _pvcPipeEdge,
      bodyColor: _pvcPipeBody,
      lightColor: _pvcPipeLight,
    );
  }

  // ----------------------------------------------------- flow definitions

  List<_Flow> _flows() {
    final bool bw1 = filter1IsBackwash, bw2 = filter2IsBackwash;
    final List<_Flow> f = [];

    // RAW water (blue): the single supply line. The 3-way valve sends it to the
    // TOP-left nozzle (filtration) or to the BOTTOM-left nozzle (backwash).
    f.add(const _Flow([Offset(20, 61), Offset(120, 61)], _rawColor));
    f.add(_Flow(
        bw1
            ? const [Offset(120, 61), Offset(120, 390), Offset(190, 390)]
            : const [Offset(120, 61), Offset(120, 270), Offset(190, 270)],
        _rawColor));
    f.add(_Flow(
        bw2
            ? const [Offset(120, 61), Offset(550, 61), Offset(550, 390), Offset(610, 390)]
            : const [Offset(120, 61), Offset(550, 61), Offset(550, 270), Offset(610, 270)],
        _rawColor));

    // DIRTY water (brown): leaves the TOP-right nozzle into the grey line
    if (bw1) {
      f.add(const _Flow(
          [Offset(370, 270), Offset(450, 270), Offset(450, 130), Offset(20, 130)],
          _dirtyColor));
    }
    if (bw2) {
      f.add(const _Flow(
          [Offset(790, 270), Offset(870, 270), Offset(870, 130), Offset(20, 130)],
          _dirtyColor));
    }

    // CLEAN filtered water (white): only from a tank that is filtering (BOTTOM-right nozzle)
    if (!bw1) {
      f.add(const _Flow(
          [Offset(370, 390), Offset(450, 390), Offset(450, 521), Offset(1000, 521)],
          _cleanColor));
    }
    if (!bw2) {
      f.add(_Flow(
          bw1
              ? const [Offset(790, 390), Offset(870, 390), Offset(870, 521), Offset(1000, 521)]
              : const [Offset(790, 390), Offset(870, 390), Offset(870, 521)],
          _cleanColor));
    }
    return f;
  }

  void _drawFlows(Canvas canvas, _Sc s) {
    if (!isOn) return;
    final double spacing = s.x(34);
    final double shift = phase * spacing * 6; // integer loops => seamless

    for (final _Flow fl in _flows()) {
      final Path path = _poly(fl.pts, s);

      // water tint inside the pipe
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.x(_pw * 0.55)
          ..strokeJoin = StrokeJoin.round
          ..color = fl.color.withValues(alpha: 0.5),
      );

      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) continue;
      final m = metrics.first;
      for (double d = shift % spacing; d < m.length; d += spacing) {
        final t = m.getTangentForOffset(d);
        if (t == null) continue;
        canvas.drawCircle(t.position, s.x(3.6), Paint()..color = fl.color);
        canvas.drawCircle(t.position, s.x(1.4),
            Paint()..color = Colors.white.withValues(alpha: 0.75));
      }
    }
  }

  // ---------------------------------------------------- filter vessels

  void _drawFilterTanks(Canvas canvas, _Sc s) {
    void tank(double cx) {
      final double bodyL = cx - _half;
      const double bodyW = _half * 2;

      final Path top = Path()
        ..moveTo(s.x(bodyL), s.y(_bodyT))
        ..cubicTo(s.x(bodyL), s.y(_bodyT - 55), s.x(bodyL + bodyW),
            s.y(_bodyT - 55), s.x(bodyL + bodyW), s.y(_bodyT))
        ..close();
      canvas.drawPath(top, _vesselH(s.rect(bodyL, _bodyT - 55, bodyW, 55)));
      canvas.drawPath(top, _stroke(_edge, s.x(1.5)));

      final Rect body = s.rect(bodyL, _bodyT, bodyW, _bodyH);
      canvas.drawRect(body, _vesselH(body));

      final Rect hl = s.rect(bodyL + 30, _bodyT, 20, _bodyH);
      canvas.drawRect(
        hl,
        Paint()
          ..shader = LinearGradient(colors: [
            _redAccent.withValues(alpha: 0),
            _redAccent.withValues(alpha: 0.45),
            _redAccent.withValues(alpha: 0),
          ]).createShader(hl),
      );
      canvas.drawRect(body, _stroke(_edge, s.x(1.5)));

      final double bt = _bodyT + _bodyH;
      final Path bot = Path()
        ..moveTo(s.x(bodyL), s.y(bt))
        ..cubicTo(s.x(bodyL), s.y(bt + 45), s.x(bodyL + bodyW), s.y(bt + 45),
            s.x(bodyL + bodyW), s.y(bt))
        ..close();
      canvas.drawPath(bot, _vesselH(s.rect(bodyL, bt, bodyW, 45)));
      canvas.drawPath(bot, _stroke(_edge, s.x(1.5)));

      // weld seams
      canvas.drawLine(s.pt(bodyL, _bodyT), s.pt(bodyL + bodyW, _bodyT),
          _stroke(_edge, s.x(1.8)));
      canvas.drawLine(s.pt(bodyL, bt), s.pt(bodyL + bodyW, bt),
          _stroke(_edge, s.x(1.8)));
    }

    tank(_cx1);
    tank(_cx2);
  }

  // --------------------------- sand bed window (media + water + flow)

  void _drawSandWindow(Canvas canvas, _Sc s, double cx, bool bw) {
    const double wT = 262, wW = 90, wH = 152, wB = wT + wH;
    final double wL = cx - 45;
    final RRect frame = s.rrect(wL, wT, wW, wH, 16);
    canvas.drawRRect(frame, Paint()..color = _valveBlack);

    final double x0 = wL + 3;
    const double w0 = wW - 6;
    final double sandTop = bw ? 290 : 308; // bed expands in backwash
    const double gravTop = 364, gravBot = 382;

    canvas.save();
    canvas.clipRRect(s.rrect(x0, wT + 3, w0, wH - 6, 13));

    // water above the bed: raw (blue) or dirty (brown) in backwash
    final Rect upper = s.rect(x0, wT + 3, w0, sandTop - wT);
    canvas.drawRect(
      upper,
      _fillV(
        upper,
        bw
            ? const [Color(0xFFA1887F), Color(0xFF6D4C41)]
            : const [Color(0xFF64B5F6), Color(0xFF1976D2)],
      ),
    );

    // clean water chamber under the underdrain
    final Rect plenum = s.rect(x0, gravBot, w0, wB - 3 - gravBot);
    canvas.drawRect(
        plenum,
        _fillV(
            plenum,
            bw
                ? const [Color(0xFF64B5F6), Color(0xFF1976D2)]
                : const [Color(0xFFB2EBF2), Color(0xFF4DD0E1)]));

    // sand bed (top surface churns in backwash)
    final Path sand = Path()..moveTo(s.x(x0), s.y(sandTop));
    for (double x = 0; x <= w0; x += 4) {
      final double dy =
      (bw && isOn) ? math.sin(x / 9 + phase * math.pi * 4) * 3 : 0.0;
      sand.lineTo(s.x(x0 + x), s.y(sandTop + dy));
    }
    sand
      ..lineTo(s.x(x0 + w0), s.y(gravTop))
      ..lineTo(s.x(x0), s.y(gravTop))
      ..close();
    canvas.drawPath(
      sand,
      _fillV(s.rect(x0, sandTop - 4, w0, gravTop - sandTop + 4),
          const [_sandTop, _sandMid, _sandBot], stops: const [0, 0.5, 1]),
    );

    final math.Random rs = math.Random(cx.toInt());
    for (int i = 0; i < 45; i++) {
      final double px = x0 + 4 + rs.nextDouble() * (w0 - 8);
      final double py = sandTop + 4 + rs.nextDouble() * (gravTop - sandTop - 8);
      final double rad = 1.1 + rs.nextDouble() * 1.2;
      final double jig =
      (bw && isOn) ? math.sin(phase * math.pi * 4 + i) * 2.5 : 0.0;
      canvas.drawCircle(s.pt(px + jig, py + jig * 0.6), s.x(rad),
          Paint()..color = _gravel.withValues(alpha: 0.6));
    }

    // gravel support layer
    final Rect gravRect = s.rect(x0, gravTop, w0, gravBot - gravTop);
    canvas.drawRect(gravRect, Paint()..color = _gravel);
    for (int i = 0; i < 16; i++) {
      final double px = x0 + 4 + rs.nextDouble() * (w0 - 8);
      final double py = gravTop + 3 + rs.nextDouble() * (gravBot - gravTop - 6);
      canvas.drawCircle(
          s.pt(px, py),
          s.x(2.2 + rs.nextDouble() * 1.5),
          Paint()
            ..color = (i.isEven ? _sandBot : const Color(0xFF5D5043))
                .withValues(alpha: 0.9));
    }

    // underdrain lateral nozzle grid
    canvas.drawRect(s.rect(x0, gravBot, w0, 7), Paint()..color = _greyDark);
    for (int i = 1; i <= 7; i++) {
      final double gx = x0 + w0 * i / 8;
      canvas.drawLine(
          s.pt(gx, gravBot), s.pt(gx, gravBot + 7), _stroke(_steelLight, s.x(1)));
    }

    // air gap + water surface wave
    canvas.drawRect(s.rect(x0, wT + 3, w0, 8),
        Paint()..color = const Color(0xFF37474F).withValues(alpha: 0.7));
    if (isOn) {
      final Path wave = Path()..moveTo(s.x(x0), s.y(wT + 11));
      for (double x = 0; x <= w0; x += 4) {
        wave.lineTo(s.x(x0 + x),
            s.y(wT + 11 + math.sin(x / 10 + phase * math.pi * 2) * 1.8));
      }
      canvas.drawPath(
          wave, _stroke(Colors.white.withValues(alpha: 0.6), s.x(1.4)));
    }

    // moving particles show the flow direction
    if (isOn) {
      final math.Random rp = math.Random(cx.toInt() * 7 + 3);
      if (!bw) {
        // FILTRATION: raw water moves DOWN through the sand
        for (int i = 0; i < 7; i++) {
          final double px = x0 + 8 + rp.nextDouble() * (w0 - 16);
          final double t = (phase * 2 + i / 7) % 1.0;
          final double py = (wT + 16) + t * (gravTop - (wT + 16));
          canvas.drawCircle(s.pt(px, py), s.x(2.0),
              Paint()..color = const Color(0xFF0D47A1).withValues(alpha: 0.75));
        }
        // clean water collected below
        for (int i = 0; i < 4; i++) {
          final double px = x0 + 8 + rp.nextDouble() * (w0 - 16);
          final double t = (phase * 2 + i / 4) % 1.0;
          final double py = (gravBot + 10) + t * ((wB - 8) - (gravBot + 10));
          canvas.drawCircle(s.pt(px, py), s.x(2.3),
              Paint()..color = Colors.white.withValues(alpha: 0.9));
        }
      } else {
        // BACKWASH: water enters from the BOTTOM and rises
        for (int i = 0; i < 6; i++) {
          final double px = x0 + 8 + rp.nextDouble() * (w0 - 16);
          final double t = (phase * 2 + i / 6) % 1.0;
          final double py = (wB - 8) - t * ((wB - 8) - (gravBot + 2));
          canvas.drawCircle(s.pt(px, py), s.x(2.3),
              Paint()..color = Colors.white.withValues(alpha: 0.9));
        }
        // trapped dirt is lifted up and out through the top
        for (int i = 0; i < 12; i++) {
          final double px = x0 + 8 + rp.nextDouble() * (w0 - 16);
          final double t = (phase * 2 + i / 12) % 1.0;
          final double py = (gravTop - 4) - t * ((gravTop - 4) - (wT + 16));
          canvas.drawCircle(
            s.pt(px, py),
            s.x(2.0 + rp.nextDouble() * 1.5),
            Paint()
              ..color = (i.isEven ? const Color(0xFF4E342E) : Colors.amber)
                  .withValues(alpha: 1 - t * 0.4),
          );
        }
      }
    }

    // glass glare + scale ticks
    final Path glare = Path()
      ..moveTo(s.x(wL + 8), s.y(wT + 6))
      ..lineTo(s.x(wL + 35), s.y(wT + 6))
      ..lineTo(s.x(wL + 12), s.y(wB - 6))
      ..lineTo(s.x(wL + 6), s.y(wB - 6))
      ..close();
    canvas.drawPath(glare, Paint()..color = Colors.white.withValues(alpha: 0.14));
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(s.pt(x0, wT + 22 + i * 20), s.pt(x0 + 8, wT + 22 + i * 20),
          _stroke(Colors.white.withValues(alpha: 0.75), s.x(1)));
    }
    canvas.restore();

    canvas.drawRRect(frame, _stroke(_steelLight, s.x(2)));
  }

  // --------------------------------------- top hatch & air release vent

  void _drawHatchAndVents(Canvas canvas, _Sc s) {
    for (final double cx in [_cx1, _cx2]) {
      const double topY = 165;
      final Rect hatch = s.rect(cx - 24, topY + 2, 48, 14);
      canvas.drawRRect(s.rrect(cx - 24, topY + 2, 48, 14, 3), _steelH(hatch));
      canvas.drawRRect(s.rrect(cx - 24, topY + 2, 48, 14, 3), _stroke(_edge, s.x(1.2)));
      for (int i = -2; i <= 2; i++) {
        canvas.drawCircle(s.pt(cx + i * 9, topY + 9), s.x(1.5),
            Paint()..color = _valveYellow);
      }
      final Rect stem = s.rect(cx - 8, topY - 14, 16, 16);
      canvas.drawRect(stem, _steelH(stem));
      canvas.drawRect(stem, _stroke(_edge, s.x(1)));
      canvas.drawRRect(s.rrect(cx - 18, topY - 22, 36, 10, 2),
          Paint()..color = _valveRed);
      canvas.drawRRect(s.rrect(cx - 18, topY - 22, 36, 10, 2),
          _stroke(_edge, s.x(1)));
    }
  }

  // ------------------------------------------------------------- flanges

  void _drawFlanges(Canvas canvas, _Sc s) {
    void flange(double x, double y) {
      final Rect f = s.rect(x - 4, y - 14, 8, 28);
      canvas.drawRect(f, Paint()..color = _steelDark);
      canvas.drawRect(f, _stroke(_edge, s.x(0.8)));
      canvas.drawCircle(s.pt(x, y - 9), s.x(1.8), Paint()..color = _valveYellow);
      canvas.drawCircle(s.pt(x, y + 9), s.x(1.8), Paint()..color = _valveYellow);
    }

    flange(22, 61); // raw inlet
    flange(22, 130); // dirty water out
    flange(996, 521); // clean out

    for (final double cx in [_cx1, _cx2]) {
      flange(cx - _half, 270); // inlet nozzle
      flange(cx + _half, 270); // drain nozzle
      flange(cx + _half, 390); // outlet nozzle
      flange(cx - _half, 390); // backwash feed nozzle
    }
  }

  // -------------------------------------------------------------- valves

  void _drawValves(Canvas canvas, _Sc s) {
    void valve(double x, double y, bool open) {
      final Rect body = s.rect(x - 8, y - 16, 16, 32);
      final RRect rr = RRect.fromRectAndRadius(body, Radius.circular(s.x(4)));
      canvas.drawRRect(rr, Paint()..color = _valveBlack);
      canvas.drawRRect(rr, _stroke(_steelLight, s.x(1.2)));

      final Color c = open ? _valveGreen : _valveRed;
      // lever lies ALONG the pipe when open, ACROSS the pipe when closed
      final Offset tip = open ? Offset(x + 22, y) : Offset(x, y - 24);
      canvas.drawLine(
        s.pt(x, y),
        s.pt(tip.dx, tip.dy),
        Paint()
          ..color = c
          ..strokeWidth = s.x(5)
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(s.pt(x, y), s.x(5), Paint()..color = _valveYellow);
      canvas.drawCircle(s.pt(x, y), s.x(5), _stroke(_edge, s.x(1)));
    }

    // 3-way valve: lever points to the open port.
    //   FILTER   -> right (stub to the TOP-left nozzle)
    //   BACKWASH -> down  (pipe to the BOTTOM-left nozzle)
    void threeWay(double x, double y, bool backwash) {
      final RRect rr = s.rrect(x - 16, y - 16, 32, 32, 6);
      canvas.drawRRect(rr, Paint()..color = _valveBlack);
      canvas.drawRRect(rr, _stroke(_steelLight, s.x(1.3)));

      final Color c = backwash ? Colors.amber : _valveGreen;
      final Offset tip = backwash ? Offset(x, y + 26) : Offset(x + 26, y);
      canvas.drawLine(
        s.pt(x, y),
        s.pt(tip.dx, tip.dy),
        Paint()
          ..color = c
          ..strokeWidth = s.x(6)
          ..strokeCap = StrokeCap.round,
      );
      // closed port marker
      final Offset shut = backwash ? Offset(x + 20, y) : Offset(x, y + 20);
      canvas.drawCircle(s.pt(shut.dx, shut.dy), s.x(3), Paint()..color = _valveRed);
      canvas.drawCircle(s.pt(x, y), s.x(6), Paint()..color = _valveYellow);
      canvas.drawCircle(s.pt(x, y), s.x(6), _stroke(_edge, s.x(1)));
    }

    // Filter 1
    valve(400, 270, filter1IsBackwash);
    valve(400, 390, !filter1IsBackwash);
    // Filter 2
    valve(820, 270, filter2IsBackwash);
    valve(820, 390, !filter2IsBackwash);

    // One 3-way valve per filter on the single supply line
    threeWay(120, 270, filter1IsBackwash);
    threeWay(550, 270, filter2IsBackwash);
  }

  @override
  bool shouldRepaint(covariant DetailedMultiFilterPainter old) {
    return old.isOn != isOn ||
        old.filter1IsBackwash != filter1IsBackwash ||
        old.filter2IsBackwash != filter2IsBackwash ||
        old.phase != phase ||
        old.showJoints != showJoints;
  }
}

/// Stateful Widget wrapper for DetailedMultiFilterPainter.
class MultiFilterView extends StatefulWidget {
  final bool isOn;
  final bool filter1IsBackwash;
  final bool filter2IsBackwash;
  final bool showJoints;
  final Size size;

  const MultiFilterView({
    super.key,
    required this.isOn,
    this.filter1IsBackwash = false, // Filter 1: filtration
    this.filter2IsBackwash = true, // Filter 2: backwash
    this.showJoints = true,
    required this.size,
  });

  @override
  State<MultiFilterView> createState() => _MultiFilterViewState();
}

class _MultiFilterViewState extends State<MultiFilterView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 3));

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
      builder: (_, __) => CustomPaint(
        size: widget.size,
        painter: DetailedMultiFilterPainter(
          isOn: widget.isOn,
          filter1IsBackwash: widget.filter1IsBackwash,
          filter2IsBackwash: widget.filter2IsBackwash,
          phase: _c.value,
          showJoints: widget.showJoints,
        ),

      ),
    );
  }
}