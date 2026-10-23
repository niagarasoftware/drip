import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Coordinate scaling helper for the reference canvas (1536 x 1024, 3:2).
class _Sc {
  final double sx;
  final double sy;
  const _Sc(this.sx, this.sy);

  double x(double v) => v * sx;
  double y(double v) => v * sy;
  Offset pt(double vx, double vy) => Offset(vx * sx, vy * sy);
  Rect rect(double l, double t, double w, double h) => Rect.fromLTWH(l * sx, t * sy, w * sx, h * sy);
  RRect rrect(double l, double t, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(l * sx, t * sy, w * sx, h * sy), Radius.circular(r * sx));
}

class _Pal {
  final Color edge, body, shade, light;
  const _Pal(this.edge, this.body, this.shade, this.light);
}

class _Pipe {
  final List<Offset> pts; // reference coords
  final double w; // pipe diameter
  final double r; // elbow radius
  final _Pal pal;
  const _Pipe(this.pts, this.w, this.r, this.pal);
}

class _Flow {
  final List<Offset> pts; // reference coords, in the direction of the flow
  final Color color;
  final int layer; // 0 = under main pipe, 1 = over main pipe, 2 = over vessels
  final double w;
  final double r;
  const _Flow(this.pts, this.color, this.layer, {this.w = 34, this.r = 34});
}

/// Dual Disc Filter station with top ordinary inlet pipe, common dirty water
/// backwash drain line, and grooved disc filter elements.
class DetailedMultiFilterPainter extends CustomPainter {
  final bool isOn;
  final bool filter1IsBackwash;
  final bool filter2IsBackwash;
  final double phase;
  final bool showJoints;
  final List<String>? filterNames;
  final int filterCount;

  DetailedMultiFilterPainter({
    required this.isOn,
    this.filter1IsBackwash = false,
    this.filter2IsBackwash = true,
    this.phase = 0,
    this.showJoints = true,
    this.filterNames,
    this.filterCount = 2,
  });

  // ---------------------------------------------------------------- palette
  static const Color _edge = Color(0xFF1E272C);

  static const _Pal _steelPal = _Pal(Color(0xFF424A50), Color(0xFF8A97A0), Color(0xFF5E6970), Color(0xFFE2E8EC));
  static const _Pal _bluePal = _Pal(Color(0xFF0A3550), Color(0xFF1E9BE0), Color(0xFF0D5C8F), Color(0xFF8BDCFF));
  static const _Pal _orangePal = _Pal(Color(0xFF7A3A0C), Color(0xFFE8731A), Color(0xFFA9490B), Color(0xFFFFB87A));

  static const Color _actBlue = Color(0xFF1E6FD9);
  static const Color _actBlueLight = Color(0xFF5AA5F5);
  static const Color _leverOrange = Color(0xFFF57C00);

  static const Color _rawColor = Color(0xFF1976D2);
  static const Color _cleanColor = Color(0xFFE0F7FA);
  static const Color _dirtyColor = Color(0xFF795548);

  // ------------------------------------------------------------ geometry
  static const double _cx1 = 522, _cx2 = 1083;
  static const double _half = 153;
  static const double _mainY = 122;
  static const double _collY = 834;

  // ------------------------------------------------------------------ ports
  /// Top-left raw water inlet port position (relative to canvas size).
  static Offset inletPort(Size s) => Offset(s.width * (24 / 1536), s.height * (122 / 1024));

  /// Bottom-right clean water outlet port position (relative to canvas size).
  static Offset outletPort(Size s) => Offset(s.width * (1512 / 1536), s.height * (834 / 1024));

  /// Left brown dirty water backwash port position (at the brown pipe edge).
  static Offset backwashPort(Size s) => Offset(s.width * (24 / 1536), s.height * (650 / 1024));

  // Pipes drawn behind the vessels (their ends are hidden by the vessel body).
  static const List<_Pipe> _backPipes = [
    // Stainless arch from filter-1 top-right nozzle up to the raw main
    _Pipe([Offset(552, 143), Offset(778, 143), Offset(778, 368), Offset(672, 368)], 34, 34, _steelPal),
    // Raw main continuation to filter-2 top-right nozzle
    _Pipe([Offset(1148, 122), Offset(1368, 122), Offset(1368, 370), Offset(1240, 370)], 34, 36, _steelPal),
    // Bottom-right nozzle pipes
    _Pipe([Offset(672, 565), Offset(762, 565), Offset(762, 834)], 34, 34, _steelPal),
    _Pipe([Offset(1232, 562), Offset(1315, 562), Offset(1315, 810)], 34, 34, _steelPal),
    // Top-left nozzle necks (valve -> vessel)
    _Pipe([Offset(330, 366), Offset(380, 366)], 32, 0, _steelPal),
    _Pipe([Offset(886, 366), Offset(942, 366)], 32, 0, _steelPal),
    // COMMON dirty water drain pipeline (filter 2 through filter 1 to left exit)
    _Pipe([Offset(852, 402), Offset(852, 650), Offset(-20, 650)], 38, 30, _orangePal),
    _Pipe([Offset(291, 402), Offset(291, 650)], 38, 0, _orangePal),
    _Pipe([Offset(291, 566), Offset(380, 566)], 26, 0, _orangePal),
    _Pipe([Offset(852, 566), Offset(942, 566)], 26, 0, _steelPal),
  ];

  static const _Pipe _mainPipe = _Pipe([Offset(-20, 122), Offset(1148, 122)], 50, 0, _bluePal);

  // Pipes drawn in front of the vessels / legs.
  static const List<_Pipe> _frontPipes = [
    _Pipe([Offset(1083, 716), Offset(1083, 834)], 36, 0, _steelPal),
    _Pipe([Offset(522, 716), Offset(522, 834), Offset(1210, 834)], 40, 34, _steelPal),
    // Blue clean water outlet collector extending directly to the right edge
    _Pipe([Offset(1200, 834), Offset(1560, 834)], 56, 0, _bluePal),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final _Sc s = _Sc(size.width / 1536, size.height / 1024);

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    _drawSlab(canvas, s);
    _drawPosts(canvas, s);
    for (final double cx in [_cx1, _cx2]) {
      _drawLegs(canvas, s, cx);
    }

    _drawDecorPipe(canvas, s);
    for (final _Pipe p in _backPipes) {
      _tube(canvas, s, p);
    }
    _drawFlows(canvas, s, 0);
    _tube(canvas, s, _mainPipe);
    _drawFlows(canvas, s, 1);

    for (final double cx in [_cx1, _cx2]) {
      _drawVessel(canvas, s, cx);
    }
    _drawTop(canvas, s, _cx1);
    _drawTop(canvas, s, _cx2);

    // Both filters rendered as Disc Filters with grooved disc cartridges
    _drawWindow(canvas, s, _cx1, filter1IsBackwash, false);
    _drawWindow(canvas, s, _cx2, filter2IsBackwash, true);

    for (final _Pipe p in _frontPipes) {
      _tube(canvas, s, p);
    }
    _drawFlows(canvas, s, 2);

    _drawHardware(canvas, s);

    // Render filter names by serial number on vessels
    final int effectiveCount = math.max(1, filterCount);
    for (int i = 0; i < effectiveCount; i++) {
      final double cx = effectiveCount <= 2
          ? (i == 0 ? _cx1 : _cx2)
          : (350.0 + i * (1300.0 - 350.0) / (effectiveCount - 1));

      final String fName = (filterNames != null && i < filterNames!.length && filterNames![i].isNotEmpty)
          ? filterNames![i]
          : 'Filter ${i + 1}';

      final tp = TextPainter(
        text: TextSpan(
          text: fName,
          style: TextStyle(
            color: Colors.white,
            fontSize: math.max(10.0, size.height * 0.038),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double badgeX = s.x(cx);
      final double badgeY = s.y(438.0);
      final Rect badgeRect = Rect.fromCenter(
        center: Offset(badgeX, badgeY),
        width: math.max(tp.width + 12, s.x(85)),
        height: tp.height + 4,
      );
      final RRect badgeRRect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(5));
      canvas.drawRRect(badgeRRect, Paint()..color = const Color(0xEE0F172A));
      canvas.drawRRect(
        badgeRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.x(1.2)
          ..color = const Color(0xFF38BDF8),
      );
      tp.paint(canvas, Offset(badgeX - tp.width / 2, badgeY - tp.height / 2));
    }

    canvas.restore();
  }

  // -------------------------------------------------------------- helpers

  Paint _fillH(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(colors: colors, stops: stops, begin: Alignment.centerLeft, end: Alignment.centerRight)
        .createShader(r);

  Paint _fillV(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(colors: colors, stops: stops, begin: Alignment.topCenter, end: Alignment.bottomCenter)
        .createShader(r);

  Paint _stroke(Color c, double w) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  /// Brushed stainless steel, lit from the upper left.
  Paint _steelBody(Rect r) => _fillH(
    r,
    const [
      Color(0xFF6B767D),
      Color(0xFF9CA7AE),
      Color(0xFFD9E0E4),
      Color(0xFFF3F6F7),
      Color(0xFFC6CED3),
      Color(0xFFA2ADB4),
      Color(0xFFD2D9DD),
      Color(0xFF727D85),
    ],
    stops: const [0, 0.08, 0.22, 0.38, 0.56, 0.78, 0.92, 1],
  );

  Paint _blackBody(Rect r) => _fillV(r, const [Color(0xFF4A5055), Color(0xFF15181A), Color(0xFF0B0C0D)], stops: const [0, 0.5, 1]);

  void _bolt(Canvas c, _Sc s, double x, double y, double r) {
    c.drawCircle(s.pt(x, y), s.x(r), Paint()..color = const Color(0xFF3A4247));
    c.drawCircle(s.pt(x - r * 0.3, y - r * 0.3), s.x(r * 0.4), Paint()..color = Colors.white.withValues(alpha: 0.7));
  }

  /// Polyline with rounded elbows, in scaled canvas coordinates.
  Path _poly(List<Offset> p, _Sc s, double r) {
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

  // ----------------------------------------------------------------- pipes

  void _tube(Canvas canvas, _Sc s, _Pipe p, {double dim = 0}) {
    final Path path = _poly(p.pts, s, p.r);
    final double w = p.w;
    Paint line(
      Color col,
      double ww, {
      StrokeCap cap = StrokeCap.round,
      MaskFilter? blur,
    }) =>
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.x(ww)
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = cap
          ..color = col
          ..maskFilter = blur;

    // Soft contact shadow
    canvas.drawPath(
      path.shift(Offset(0, s.x(w * 0.28))),
      line(
        const Color(0x38000000),
        w * 1.16,
        cap: StrokeCap.round,
        blur: MaskFilter.blur(BlurStyle.normal, s.x(math.max(1.4, w * 0.28))),
      ),
    );
    // Outer edge / outline
    canvas.drawPath(path, line(p.pal.edge, w, cap: StrokeCap.round));
    // Main tube body
    canvas.drawPath(path, line(p.pal.body, w * 0.76, cap: StrokeCap.round));
    // Shaded underside
    canvas.drawPath(
      path.shift(Offset(s.x(w * 0.12), s.x(w * 0.16))),
      line(p.pal.shade.withValues(alpha: 0.60), w * 0.38, cap: StrokeCap.round),
    );
    // Lit top side
    canvas.drawPath(
      path.shift(Offset(-s.x(w * 0.12), -s.x(w * 0.16))),
      line(p.pal.light, w * 0.35, cap: StrokeCap.round),
    );
    // Specular highlight glint
    canvas.drawPath(
      path.shift(Offset(-s.x(w * 0.16), -s.x(w * 0.20))),
      line(Colors.white.withValues(alpha: 0.65), w * 0.16, cap: StrokeCap.round),
    );
    if (dim > 0) canvas.drawPath(path, line(Colors.black.withValues(alpha: dim), w, cap: StrokeCap.round));
  }

  /// Second stainless pipe visible behind the carbon vessel's dome.
  void _drawDecorPipe(Canvas canvas, _Sc s) {
    _tube(
      canvas,
      s,
      const _Pipe([Offset(850, 143), Offset(1162, 143), Offset(1162, 238)], 28, 28, _steelPal),
      dim: 0.16,
    );
  }

  // ------------------------------------------------------------------ flows

  List<_Flow> _flows() {
    final bool bw1 = filter1IsBackwash, bw2 = filter2IsBackwash;
    final List<_Flow> f = [];

    // RAW water (blue): main header -> top of each filtering vessel
    if (!bw2) {
      f.add(const _Flow([Offset(-20, 122), Offset(1368, 122), Offset(1368, 370), Offset(1244, 370)], _rawColor, 1, w: 40, r: 36));
    } else if (!bw1) {
      f.add(const _Flow([Offset(-20, 122), Offset(_cx1, 122)], _rawColor, 1, w: 40));
    }
    if (!bw1) {
      f.add(const _Flow([Offset(_cx1, 122), Offset(_cx1, 170)], _rawColor, 1, w: 28));
      f.add(const _Flow([Offset(560, 143), Offset(778, 143), Offset(778, 368), Offset(680, 368)], _rawColor, 0));
    }
    if (!bw2) {
      f.add(const _Flow([Offset(_cx2, 122), Offset(_cx2, 170)], _rawColor, 1, w: 28));
    }

    // DIRTY water (brown): top-left nozzle -> 3-way valve -> COMMON dirty water drain pipeline -> left exit
    if (bw1) {
      f.add(const _Flow(
        [Offset(372, 366), Offset(291, 366), Offset(291, 650), Offset(-20, 650)],
        _dirtyColor,
        0,
        w: 38,
        r: 30,
      ));
    }
    if (bw2) {
      f.add(const _Flow(
        [Offset(912, 366), Offset(852, 366), Offset(852, 650), Offset(-20, 650)],
        _dirtyColor,
        0,
        w: 38,
        r: 30,
      ));
    }

    // CLEAN water (white): bottom nozzles -> collector -> blue outlet pipe
    if (!bw1) {
      f.add(const _Flow([Offset(_cx1, 720), Offset(_cx1, 834), Offset(1560, 834)], _cleanColor, 2, w: 36));
      f.add(const _Flow([Offset(680, 565), Offset(762, 565), Offset(762, 834)], _cleanColor, 2));
    }
    if (!bw2) {
      f.add(const _Flow([Offset(_cx2, 720), Offset(_cx2, 834), Offset(1560, 834)], _cleanColor, 2, w: 36));
      f.add(const _Flow([Offset(1232, 562), Offset(1315, 562), Offset(1315, 810)], _cleanColor, 2));
    }

    // BACKWASH feed: clean water from the collector rises into the vessel bottom
    if (bw1 && !bw2) {
      f.add(const _Flow([Offset(_cx2, 834), Offset(_cx1, 834), Offset(_cx1, 720)], _cleanColor, 2, w: 36));
    }
    if (bw2 && !bw1) {
      f.add(const _Flow([Offset(_cx1, 834), Offset(_cx2, 834), Offset(_cx2, 720)], _cleanColor, 2, w: 36));
    }
    return f;
  }

  void _drawFlows(Canvas canvas, _Sc s, int layer) {
    if (!isOn) return;
    final double spacing = s.x(34);
    final double shift = phase * spacing * 6; // integer loops => seamless

    for (final _Flow fl in _flows()) {
      if (fl.layer != layer) continue;
      final Path path = _poly(fl.pts, s, fl.r);

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.x(fl.w * 0.5)
          ..strokeJoin = StrokeJoin.round
          ..color = fl.color.withValues(alpha: 0.5),
      );

      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) continue;
      final m = metrics.first;
      for (double d = shift % spacing; d < m.length; d += spacing) {
        final t = m.getTangentForOffset(d);
        if (t == null) continue;
        canvas.drawCircle(t.position, s.x(3.8), Paint()..color = fl.color);
        canvas.drawCircle(t.position, s.x(1.5), Paint()..color = Colors.white.withValues(alpha: 0.75));
      }
    }
  }

  // ------------------------------------------------------------ concrete pad

  void _drawSlab(Canvas c, _Sc s) {
    final Path top = Path()
      ..moveTo(s.x(190), s.y(836))
      ..lineTo(s.x(1400), s.y(836))
      ..lineTo(s.x(1450), s.y(930))
      ..lineTo(s.x(140), s.y(930))
      ..close();
    c.drawPath(top, _fillV(s.rect(140, 836, 1310, 94), const [Color(0xFFD9D7D2), Color(0xFFC4C2BC)]));
    c.drawPath(top, _stroke(_edge.withValues(alpha: 0.25), s.x(1)));

    final Rect front = s.rect(140, 930, 1310, 45);
    c.drawRect(front, _fillV(front, const [Color(0xFFB8B6B0), Color(0xFF9C9A94)]));
    c.drawLine(s.pt(140, 930), s.pt(1450, 930), _stroke(Colors.white.withValues(alpha: 0.55), s.x(1.6)));
    c.drawRect(front, _stroke(_edge.withValues(alpha: 0.25), s.x(1)));

    // vessel contact shadows
    for (final double cx in [_cx1, _cx2]) {
      c.drawOval(
        s.rect(cx - 200, 876, 400, 34),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.26)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.x(12)),
      );
    }
  }

  // ----------------------------------------------------------- support posts

  void _post(Canvas c, _Sc s, double x0, double x1, double y0, double y1) {
    final Rect r = s.rect(x0, y0, x1 - x0, y1 - y0);
    c.drawRect(
      r,
      _fillH(r, const [Color(0xFF7C878E), Color(0xFFD5DCE0), Color(0xFFF4F6F7), Color(0xFF9AA5AC)], stops: const [0, 0.3, 0.55, 1]),
    );
    c.drawRect(r, _stroke(_edge.withValues(alpha: 0.5), s.x(1)));
  }

  void _basePlate(Canvas c, _Sc s, double cx, double y, double w, {Color color = const Color(0xFFB4BEC5)}) {
    final RRect rr = s.rrect(cx - w / 2, y, w, 18, 3);
    c.drawRRect(rr, _fillV(rr.outerRect, [color, Color.lerp(color, Colors.black, 0.4)!]));
    c.drawRRect(rr, _stroke(_edge.withValues(alpha: 0.7), s.x(1.1)));
    if (showJoints) {
      _bolt(c, s, cx - w / 2 + 9, y + 9, 3);
      _bolt(c, s, cx + w / 2 - 9, y + 9, 3);
    }
  }

  void _drawPosts(Canvas c, _Sc s) {
    _post(c, s, 245, 275, 150, 848);
    _basePlate(c, s, 260, 842, 76);
    _post(c, s, 815, 845, 150, 840);
    _basePlate(c, s, 830, 834, 80, color: const Color(0xFF5C666C));
    _post(c, s, 1262, 1283, 400, 812);
  }

  void _bracket(Canvas c, _Sc s, double x, double y) {
    final RRect plate = s.rrect(x - 34, y - 10, 68, 22, 4);
    c.drawRRect(plate, _fillV(plate.outerRect, const [Color(0xFFE6EBEE), Color(0xFF8C979E)]));
    c.drawRRect(plate, _stroke(_edge.withValues(alpha: 0.7), s.x(1.1)));
    if (showJoints) {
      _bolt(c, s, x - 22, y + 1, 3);
      _bolt(c, s, x + 22, y + 1, 3);
    }
  }

  // ------------------------------------------------------------------- legs

  void _drawLegs(Canvas c, _Sc s, double cx) {
    void leg(double x, double w, double top, double dim) {
      final Rect r = s.rect(x - w / 2, top, w, 885 - top);
      c.drawRect(r, _steelBody(r));
      if (dim > 0) c.drawRect(r, Paint()..color = Colors.black.withValues(alpha: dim));
      c.drawRect(r, _stroke(_edge.withValues(alpha: 0.5), s.x(1)));
    }

    leg(cx - 85, 22, 670, 0.30);
    leg(cx + 82, 22, 670, 0.30);
    leg(cx - 117, 42, 660, 0);
    leg(cx + 113, 44, 660, 0);

    for (final double x in [cx - 117, cx + 113]) {
      _basePlate(c, s, x, 878, 76);
    }
  }

  // ----------------------------------------------------------------- vessel

  void _drawVessel(Canvas c, _Sc s, double cx) {
    final double L = cx - _half, R = cx + _half;
    const double W = _half * 2;

    // bottom dished head
    final Path dish = Path()
      ..moveTo(s.x(L), s.y(646))
      ..cubicTo(s.x(L), s.y(700), s.x(cx - 70), s.y(724), s.x(cx - 20), s.y(724))
      ..lineTo(s.x(cx + 20), s.y(724))
      ..cubicTo(s.x(cx + 70), s.y(724), s.x(R), s.y(700), s.x(R), s.y(646))
      ..close();
    final Rect dr = s.rect(L, 646, W, 80);
    c.drawPath(dish, _steelBody(dr));
    c.drawPath(dish, _fillV(dr, [Colors.transparent, Colors.black.withValues(alpha: 0.30)]));
    c.drawPath(dish, _stroke(_edge.withValues(alpha: 0.55), s.x(1.3)));

    // cylinder
    final Rect cyl = s.rect(L, 288, W, 362);
    c.drawRect(cyl, _steelBody(cyl));
    final Rect under = s.rect(L, 288, W, 36);
    c.drawRect(under, _fillV(under, [Colors.black.withValues(alpha: 0.20), Colors.transparent]));

    // brushed grain
    final math.Random rg = math.Random(cx.toInt());
    for (int i = 0; i < 70; i++) {
      final double gx = L + 6 + rg.nextDouble() * (W - 12);
      c.drawLine(
        s.pt(gx, 292),
        s.pt(gx, 646),
        _stroke((rg.nextBool() ? Colors.white : Colors.black).withValues(alpha: 0.035), s.x(1)),
      );
    }
    c.drawLine(s.pt(L, 288), s.pt(L, 648), _stroke(_edge.withValues(alpha: 0.55), s.x(1.4)));
    c.drawLine(s.pt(R, 288), s.pt(R, 648), _stroke(_edge.withValues(alpha: 0.55), s.x(1.4)));

    // lower weld ring
    final Rect ring = s.rect(L, 634, W, 22);
    c.drawRect(ring, _fillV(ring, [Colors.black.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.10), Colors.black.withValues(alpha: 0.16)]));
    c.drawLine(s.pt(L, 634), s.pt(R, 634), _stroke(_edge.withValues(alpha: 0.5), s.x(1.4)));
    c.drawLine(s.pt(L, 656), s.pt(R, 656), _stroke(_edge.withValues(alpha: 0.55), s.x(1.4)));
    c.drawLine(s.pt(L, 657.5), s.pt(R, 657.5), _stroke(Colors.white.withValues(alpha: 0.5), s.x(1.2)));

    // domed head
    final Path dome = Path()
      ..moveTo(s.x(L + 3), s.y(268))
      ..cubicTo(s.x(L + 18), s.y(236), s.x(cx - 95), s.y(208), s.x(cx - 42), s.y(206))
      ..lineTo(s.x(cx + 42), s.y(206))
      ..cubicTo(s.x(cx + 95), s.y(208), s.x(R - 18), s.y(236), s.x(R - 3), s.y(268))
      ..close();
    final Rect domeR = s.rect(L, 204, W, 70);
    c.drawPath(dome, _steelBody(domeR));
    c.drawPath(
      dome,
      _fillV(domeR, [Colors.white.withValues(alpha: 0.22), Colors.transparent, Colors.black.withValues(alpha: 0.14)], stops: const [0, 0.5, 1]),
    );
    c.drawPath(dome, _stroke(_edge.withValues(alpha: 0.55), s.x(1.3)));

    // bolted head flange ring
    final RRect fr = s.rrect(L - 2, 258, W + 4, 32, 5);
    c.drawRRect(fr, _steelBody(fr.outerRect));
    c.drawRRect(fr, _fillV(fr.outerRect, [Colors.white.withValues(alpha: 0.28), Colors.transparent, Colors.black.withValues(alpha: 0.25)], stops: const [0, 0.4, 1]));
    c.drawRRect(fr, _stroke(_edge.withValues(alpha: 0.65), s.x(1.3)));
    c.drawLine(s.pt(L + 2, 283), s.pt(R - 2, 283), _stroke(Colors.black.withValues(alpha: 0.25), s.x(1.2)));
    if (showJoints) {
      for (int i = 0; i < 15; i++) {
        _bolt(c, s, L + 16 + (W - 32) * i / 14, 270, 3.0);
      }
    }

    // lifting lug on the dome
    c.drawCircle(s.pt(L + 38, 246), s.x(9), _stroke(const Color(0xFF59646B), s.x(3)));

    // vertical highlight streaks
    final Rect hl = s.rect(L + 26, 292, 22, 340);
    c.drawRect(
      hl,
      _fillH(hl, [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.20), Colors.white.withValues(alpha: 0)]),
    );
  }

  /// Neck flange, blue tee stub and pressure gauge on top of a vessel.
  void _drawTop(Canvas c, _Sc s, double cx) {
    // neck pipe
    final Rect neck = s.rect(cx - 22, 160, 44, 50);
    c.drawRect(neck, _steelBody(neck));
    c.drawRect(neck, _stroke(_edge.withValues(alpha: 0.55), s.x(1)));

    // stacked flanges
    for (final List<double> f in [
      [46, 188, 14],
      [40, 202, 12],
    ]) {
      final RRect r = s.rrect(cx - f[0], f[1] - 12, f[0] * 2, f[2], 4);
      c.drawRRect(r, _steelBody(r.outerRect));
      c.drawRRect(r, _stroke(_edge.withValues(alpha: 0.65), s.x(1.1)));
    }
    if (showJoints) {
      for (int i = -3; i <= 3; i++) {
        _bolt(c, s, cx + i * 12, 182, 2.4);
      }
    }

    // black collar + blue stub up to the raw main
    final Rect stub = s.rect(cx - 17, 140, 34, 26);
    c.drawRect(stub, _fillH(stub, const [Color(0xFF0B3C78), Color(0xFF3A8FEA), Color(0xFF0F4F9C)]));
    final RRect collar = s.rrect(cx - 23, 160, 46, 18, 4);
    c.drawRRect(collar, _blackBody(collar.outerRect));
    c.drawRRect(collar, _stroke(const Color(0xFFB8C2C8), s.x(1.2)));

    // pressure gauge
    final double gx = cx - 76;
    final double gy = cx < 800 ? 190 : 198;
    const double r = 23;

    final Rect stem = s.rect(gx - 5, gy + r - 4, 10, 26);
    c.drawRect(stem, _steelBody(stem));
    c.drawRect(stem, _stroke(_edge.withValues(alpha: 0.6), s.x(1)));
    final RRect nut = s.rrect(gx - 9, gy + r + 14, 18, 9, 2);
    c.drawRRect(nut, _steelBody(nut.outerRect));
    c.drawRRect(nut, _stroke(_edge.withValues(alpha: 0.6), s.x(1)));

    final Offset gc = s.pt(gx, gy);
    c.drawCircle(gc + Offset(s.x(1.5), s.x(2.5)), s.x(r), Paint()..color = Colors.black.withValues(alpha: 0.22));
    c.drawCircle(
      gc,
      s.x(r),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF4F7F8), Color(0xFF8C979E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: gc, radius: s.x(r))),
    );
    c.drawCircle(gc, s.x(r), _stroke(_edge.withValues(alpha: 0.7), s.x(1.2)));
    c.drawCircle(gc, s.x(r - 4), Paint()..color = const Color(0xFFFAFBFC));
    c.drawCircle(gc, s.x(r - 4), _stroke(const Color(0xFF59646B), s.x(0.8)));

    for (int i = 0; i <= 10; i++) {
      final double a = (135 + 270 * i / 10) * math.pi / 180;
      final Offset p0 = gc + Offset(math.cos(a), math.sin(a)) * s.x(r - 5);
      final Offset p1 = gc + Offset(math.cos(a), math.sin(a)) * s.x(r - 9);
      c.drawLine(p0, p1, _stroke(const Color(0xFF263238), s.x(1)));
    }
    final double na = (135 + 270 * (isOn ? 0.62 : 0.06)) * math.pi / 180;
    c.drawLine(
      gc,
      gc + Offset(math.cos(na), math.sin(na)) * s.x(r - 7),
      Paint()
        ..color = const Color(0xFFD32F2F)
        ..strokeWidth = s.x(1.8)
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(gc, s.x(2.4), Paint()..color = const Color(0xFF263238));
    c.drawOval(
      Rect.fromCenter(center: gc + Offset(-s.x(6), -s.x(8)), width: s.x(14), height: s.x(8)),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  // --------------------------- disc filter sight window ---------------------------

  void _drawWindow(Canvas canvas, _Sc s, double cx, bool bw, bool isFilter2) {
    const double wT = 428, wH = 182, wB = wT + wH, wW = 66;
    final double wL = cx - 33;

    // steel bezel
    final RRect bezel = s.rrect(cx - 41, wT - 7, 82, wH + 14, 18);
    canvas.drawRRect(bezel, _fillV(bezel.outerRect, const [Color(0xFFE6EBEE), Color(0xFF8C979E)]));
    canvas.drawRRect(bezel, _stroke(_edge.withValues(alpha: 0.7), s.x(1.2)));
    if (showJoints) {
      for (final double bx in [cx - 34, cx + 34]) {
        _bolt(canvas, s, bx, wT - 1, 2.2);
        _bolt(canvas, s, bx, wB + 1, 2.2);
      }
    }

    final RRect frame = s.rrect(wL, wT, wW, wH, 14);
    canvas.drawRRect(frame, Paint()..color = const Color(0xFF111416));

    final double x0 = wL + 3;
    const double w0 = wW - 6;

    canvas.save();
    canvas.clipRRect(s.rrect(x0, wT + 3, w0, wH - 6, 11));

    // Water background inside the disc housing
    final Rect chamber = s.rect(x0, wT + 3, w0, wH - 6);
    canvas.drawRect(
      chamber,
      _fillV(
        chamber,
        bw
            ? const [Color(0xCC6D4C41), Color(0xDD3E2723)]
            : const [Color(0xCC1E88E5), Color(0xDD0D47A1)],
      ),
    );

    // Central stainless core spine shaft
    final Rect spine = s.rect(cx - 5, wT + 8, 10, wH - 16);
    canvas.drawRect(spine, _steelBody(spine));
    canvas.drawRect(spine, _stroke(_edge.withValues(alpha: 0.6), s.x(0.8)));

    // Disc filter element stack (stacked grooved rings)
    const int discCount = 20;
    const double stackTop = wT + 16;
    const double stackH = wH - 32;
    const double discWidth = 46.0;
    final double discL = cx - discWidth / 2;

    // Color palettes for disc filter elements:
    // Filter 1: Precision blue grooved discs
    // Filter 2: High-capacity red/charcoal grooved discs
    final Color discBase = isFilter2 ? const Color(0xFF2C3539) : const Color(0xFF1565C0);
    final Color discLight = isFilter2 ? const Color(0xFFE53935) : const Color(0xFF42A5F5);
    final Color discShade = isFilter2 ? const Color(0xFF1A1F22) : const Color(0xFF0D47A1);

    for (int i = 0; i < discCount; i++) {
      // In backwash mode, discs decompress / loosen with animated gaps
      final double expand = (bw && isOn) ? math.sin(phase * math.pi * 4 + i * 0.4).abs() * 2.2 : 0.0;
      final double dy = stackTop + (stackH / discCount) * i + expand;
      final Rect discRect = s.rect(discL, dy, discWidth, 5.0);
      final RRect discR = RRect.fromRectAndRadius(discRect, Radius.circular(s.x(1.8)));

      canvas.drawRRect(discR, Paint()..color = discBase);
      canvas.drawRRect(
        discR,
        _fillV(discRect, [discLight.withValues(alpha: 0.85), discBase, discShade]),
      );

      // Grooved teeth/ridge lines on the edges of each disc element
      for (double gx = discL + 3; gx < discL + discWidth - 3; gx += 4.5) {
        canvas.drawLine(
          s.pt(gx, dy),
          s.pt(gx, dy + 4.5),
          _stroke(Colors.black.withValues(alpha: 0.25), s.x(0.7)),
        );
      }
      canvas.drawLine(
        s.pt(discL + 2, dy + 0.5),
        s.pt(discL + discWidth - 2, dy + 0.5),
        _stroke(Colors.white.withValues(alpha: 0.45), s.x(0.6)),
      );
    }

    // Top & bottom cartridge end caps
    for (final double capY in [wT + 12, wB - 18]) {
      final Rect cap = s.rect(cx - 25, capY, 50, 6);
      final RRect capR = RRect.fromRectAndRadius(cap, Radius.circular(s.x(2.0)));
      canvas.drawRRect(capR, _steelBody(cap));
      canvas.drawRRect(capR, _stroke(_edge, s.x(0.9)));
    }

    // Water flow animation through discs or backwash flushing jets
    if (isOn) {
      final math.Random rp = math.Random(cx.toInt() * 11 + 5);
      if (!bw) {
        // FILTRATION: Water flows from outside through grooved discs into spine
        for (int i = 0; i < 12; i++) {
          final double side = rp.nextBool() ? 1.0 : -1.0;
          final double t = (phase * 2.5 + i / 12) % 1.0;
          final double startX = cx + side * (w0 * 0.45);
          final double endX = cx + side * 6.0;
          final double px = startX + (endX - startX) * t;
          final double py = stackTop + rp.nextDouble() * stackH;
          canvas.drawCircle(s.pt(px, py), s.x(1.8), Paint()..color = Colors.white.withValues(alpha: 0.85));
        }
      } else {
        // BACKWASH: High-pressure water jets spray outward between loosened discs
        for (int i = 0; i < 14; i++) {
          final double side = i.isEven ? 1.0 : -1.0;
          final double t = (phase * 3.0 + i / 14) % 1.0;
          final double py = stackTop + (stackH / 14) * i;
          final double jetX = cx + side * (8.0 + t * 18.0);
          canvas.drawLine(
            s.pt(cx, py),
            s.pt(jetX, py),
            _stroke(Colors.white.withValues(alpha: 0.7 * (1 - t)), s.x(1.2)),
          );
          canvas.drawCircle(
            s.pt(jetX, py),
            s.x(2.0),
            Paint()..color = (i % 3 == 0 ? Colors.amber : const Color(0xFF795548)).withValues(alpha: 0.9),
          );
        }
      }
    }

    // Glass glare
    final Path glare = Path()
      ..moveTo(s.x(wL + 8), s.y(wT + 6))
      ..lineTo(s.x(wL + 30), s.y(wT + 6))
      ..lineTo(s.x(wL + 12), s.y(wB - 6))
      ..lineTo(s.x(wL + 6), s.y(wB - 6))
      ..close();
    canvas.drawPath(glare, Paint()..color = Colors.white.withValues(alpha: 0.14));
    canvas.restore();

    canvas.drawRRect(frame, _stroke(const Color(0xFFECEFF1), s.x(2)));
  }

  // ------------------------------------------------------------- hardware

  /// Black flange (edge-on) with silver rim.
  void _flange(Canvas c, _Sc s, double cx, double cy, double w, double h, {int bolts = 3}) {
    final RRect r = s.rrect(cx - w / 2, cy - h / 2, w, h, 3);
    c.drawRRect(r.shift(Offset(s.x(1.5), s.x(2.5))), Paint()..color = Colors.black.withValues(alpha: 0.22));
    c.drawRRect(r, _fillH(r.outerRect, const [Color(0xFF0D0F10), Color(0xFF4A5055), Color(0xFF0D0F10)]));
    c.drawRRect(r, _stroke(const Color(0xFFB8C2C8), s.x(1.4)));
    if (showJoints) {
      final bool tall = h >= w;
      for (int i = 0; i < bolts; i++) {
        final double f = bolts == 1 ? 0.5 : (i + 0.5) / bolts;
        final double bx = tall ? cx : cx - w / 2 + w * f;
        final double by = tall ? cy - h / 2 + h * f : cy;
        c.drawCircle(s.pt(bx, by), s.x(2.2), Paint()..color = const Color(0xFFC9D1D6));
      }
    }
  }

  /// Short steel collar from the vessel wall out to a nozzle flange.
  void _nozzle(Canvas c, _Sc s, double wallX, double flangeX, double y, {double h = 62}) {
    final double x0 = math.min(wallX, flangeX), x1 = math.max(wallX, flangeX);
    final Rect collar = s.rect(x0 - 2, y - 17, (x1 - x0) + 4, 34);
    c.drawRect(collar, _steelBody(collar));
    c.drawRect(collar, _stroke(_edge.withValues(alpha: 0.55), s.x(1)));
    _flange(c, s, flangeX, y, 28, h);
  }

  void _drawHardware(Canvas c, _Sc s) {
    // clamp brackets under the raw main
    _bracket(c, s, 260, 150);
    _bracket(c, s, 830, 150);

    // Flange joint where top ordinary inlet pipe drops down into the main header
    _flange(c, s, 80, _mainY, 28, 76);

    // main-line flanges
    _flange(c, s, 405, _mainY, 24, 92);
    _flange(c, s, 548, _mainY, 24, 76);
    _flange(c, s, 987, _mainY, 24, 92);
    _flange(c, s, 1140, _mainY, 24, 76);

    // blue actuated valves on the main
    _mainValve(c, s, 473);
    _mainValve(c, s, 1075);

    for (final double cx in [_cx1, _cx2]) {
      final double L = cx - _half, R = cx + _half;
      final bool bw = cx == _cx1 ? filter1IsBackwash : filter2IsBackwash;

      // side nozzles
      _nozzle(c, s, L + 2, L - 22, 366);
      _nozzle(c, s, L + 2, L - 30, 566, h: 66);
      _nozzle(c, s, R - 2, R + 22, cx == _cx1 ? 368 : 370);
      _nozzle(c, s, R - 2, R + 22, cx == _cx1 ? 565 : 562);

      // 3-way valve on the top-left nozzle + drain lever
      _threeWay(c, s, L - 78, 366);
      _drainLever(c, s, L - 78, 440, bw);

      // bottom drain valve
      _bottomValve(c, s, cx);
    }

    // Common dirty water pipeline collars / T-junction joints
    _collar(c, s, 291, 650, 44, 18);
    _collar(c, s, 852, 650, 44, 18);

    // collector joints
    _collar(c, s, 762, _collY, 18, 52);
    _collar(c, s, 830, _collY, 14, 48);
    _collar(c, s, 1150, _collY, 14, 48);
    _flange(c, s, 1205, _collY, 24, 76);

    // bottom-right pipe flanges
    _flange(c, s, 762, 782, 70, 16, bolts: 4);
    _flange(c, s, 1315, 774, 70, 16, bolts: 4);

    // blue tee collar
    final RRect gt = s.rrect(1288, 792, 54, 14, 3);
    c.drawRRect(gt, _fillV(gt.outerRect, const [Color(0xFF3A8FEA), Color(0xFF0F4F9C)]));
    c.drawRRect(gt, _stroke(_edge.withValues(alpha: 0.7), s.x(1)));

    // End flange at the mouth of blue main inlet header
    _flange(c, s, 24, _mainY, 24, 76);

    // End flange at the mouth of blue main outlet header
    _flange(c, s, 1512, _collY, 24, 76);
  }

  void _collar(Canvas c, _Sc s, double x, double y, double w, double h) {
    final RRect r = s.rrect(x - w / 2, y - h / 2, w, h, 3);
    c.drawRRect(r, _fillH(r.outerRect, const [Color(0xFF7C878E), Color(0xFFF3F6F7), Color(0xFF8C979E)]));
    c.drawRRect(r, _stroke(_edge.withValues(alpha: 0.6), s.x(1)));
  }

  void _mainValve(Canvas c, _Sc s, double x) {
    // body around the pipe
    final RRect body = s.rrect(x - 21, 94, 42, 56, 8);
    c.drawRRect(body, _blackBody(body.outerRect));
    c.drawRRect(body, _stroke(const Color(0xFF8C979E), s.x(1)));
    // neck
    final Rect neck = s.rect(x - 14, 66, 28, 32);
    c.drawRect(neck, _blackBody(neck));
    // collar
    final RRect ring = s.rrect(x - 26, 58, 52, 12, 4);
    c.drawRRect(ring, _blackBody(ring.outerRect));
    c.drawRRect(ring, _stroke(const Color(0xFF8C979E), s.x(1)));
    // actuator cap
    final RRect cap = s.rrect(x - 31, 28, 62, 34, 10);
    c.drawRRect(cap, _fillH(cap.outerRect, const [Color(0xFF0F4F9C), _actBlueLight, _actBlue, Color(0xFF0B3C78)], stops: const [0, 0.3, 0.7, 1]));
    c.drawRRect(cap, _stroke(const Color(0xFF0B2A52), s.x(1.2)));
    c.drawRRect(
      s.rrect(x - 26, 31, 52, 8, 4),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  void _threeWay(Canvas c, _Sc s, double x, double y) {
    // left cap port
    final RRect capL = s.rrect(x - 44, y - 14, 16, 28, 3);
    c.drawRRect(capL, _blackBody(capL.outerRect));
    c.drawRRect(capL, _stroke(const Color(0xFF8C979E), s.x(1)));

    // body
    final RRect body = s.rrect(x - 34, y - 22, 68, 44, 8);
    c.drawRRect(body.shift(Offset(s.x(1.5), s.x(3))), Paint()..color = Colors.black.withValues(alpha: 0.22));
    c.drawRRect(body, _blackBody(body.outerRect));
    c.drawRRect(body, _stroke(const Color(0xFF8C979E), s.x(1.1)));
    if (showJoints) {
      for (final double bx in [x - 24, x + 24]) {
        c.drawCircle(s.pt(bx, y - 14), s.x(2.2), Paint()..color = const Color(0xFFC9D1D6));
        c.drawCircle(s.pt(bx, y + 14), s.x(2.2), Paint()..color = const Color(0xFFC9D1D6));
      }
    }

    // neck + ring + blue actuator
    final Rect neck = s.rect(x - 15, y - 46, 30, 26);
    c.drawRect(neck, _blackBody(neck));
    final RRect ring = s.rrect(x - 24, y - 54, 48, 11, 4);
    c.drawRRect(ring, _blackBody(ring.outerRect));
    c.drawRRect(ring, _stroke(const Color(0xFF8C979E), s.x(1)));
    final RRect cap = s.rrect(x - 24, y - 84, 48, 32, 9);
    c.drawRRect(cap, _fillH(cap.outerRect, const [Color(0xFF0F4F9C), _actBlueLight, _actBlue, Color(0xFF0B3C78)], stops: const [0, 0.3, 0.7, 1]));
    c.drawRRect(cap, _stroke(const Color(0xFF0B2A52), s.x(1.2)));
    c.drawRRect(s.rrect(x - 19, y - 81, 38, 7, 3), Paint()..color = Colors.white.withValues(alpha: 0.28));

    // lower stub
    final Rect stub = s.rect(x - 13, y + 21, 26, 16);
    c.drawRect(stub, _blackBody(stub));
    c.drawRect(stub, _stroke(const Color(0xFF8C979E), s.x(0.9)));
  }

  /// Orange drain lever: ALONG the pipe when draining, ACROSS when closed.
  void _drainLever(Canvas c, _Sc s, double x, double y, bool open) {
    final RRect collar = s.rrect(x - 17, y - 22, 34, 12, 3);
    c.drawRRect(collar, _blackBody(collar.outerRect));
    c.drawRRect(collar, _stroke(const Color(0xFF8C979E), s.x(0.9)));
    final Paint lever = Paint()
      ..color = _leverOrange
      ..strokeWidth = s.x(8)
      ..strokeCap = StrokeCap.round;
    if (open) {
      c.drawLine(s.pt(x, y - 16), s.pt(x, y + 14), lever);
    } else {
      c.drawLine(s.pt(x - 16, y - 16), s.pt(x + 16, y - 16), lever);
    }
    c.drawCircle(s.pt(x, y - 16), s.x(4.5), Paint()..color = const Color(0xFF263238));
  }

  void _bottomValve(Canvas c, _Sc s, double cx) {
    // valve body
    final RRect body = s.rrect(cx - 24, 742, 48, 40, 8);
    c.drawRRect(body.shift(Offset(s.x(1.5), s.x(3))), Paint()..color = Colors.black.withValues(alpha: 0.22));
    c.drawRRect(body, _blackBody(body.outerRect));
    c.drawRRect(body, _stroke(const Color(0xFF8C979E), s.x(1.1)));
    // silver neck ring above the valve
    _collar(c, s, cx, 738, 40, 10);

    // lever: along the pipe when open, across when closed
    final Paint lever = Paint()
      ..color = _leverOrange
      ..strokeWidth = s.x(9)
      ..strokeCap = StrokeCap.round;
    final Offset pivot = s.pt(cx, 762);
    if (isOn) {
      c.drawLine(pivot, s.pt(cx, 806), lever);
    } else {
      c.drawLine(pivot, s.pt(cx + 40, 762), lever);
    }
    c.drawCircle(pivot, s.x(5), Paint()..color = const Color(0xFF263238));

    // lower flange
    _flange(c, s, cx, 806, 68, 16, bolts: 4);
  }

  @override
  bool shouldRepaint(covariant DetailedMultiFilterPainter old) {
    return old.isOn != isOn ||
        old.filter1IsBackwash != filter1IsBackwash ||
        old.filter2IsBackwash != filter2IsBackwash ||
        old.phase != phase ||
        old.showJoints != showJoints ||
        old.filterCount != filterCount ||
        !listEquals(old.filterNames, filterNames);
  }
}

/// Animated widget wrapper for [DetailedMultiFilterPainter].
///
/// Use a 3:2 size, e.g. `Size(600, 400)`.
class MultiFilterView extends StatefulWidget {
  final bool isOn;
  final bool filter1IsBackwash;
  final bool filter2IsBackwash;
  final bool showJoints;
  final Size size;
  final List<String>? filterNames;
  final int filterCount;

  const MultiFilterView({
    super.key,
    required this.isOn,
    this.filter1IsBackwash = false,
    this.filter2IsBackwash = true,
    this.showJoints = true,
    required this.size,
    this.filterNames,
    this.filterCount = 2,
  });

  @override
  State<MultiFilterView> createState() => _MultiFilterViewState();
}

class _MultiFilterViewState extends State<MultiFilterView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    if (widget.isOn) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant MultiFilterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isOn && _controller.isAnimating) {
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
          painter: DetailedMultiFilterPainter(
            isOn: widget.isOn,
            filter1IsBackwash: widget.filter1IsBackwash,
            filter2IsBackwash: widget.filter2IsBackwash,
            phase: _controller.value,
            showJoints: widget.showJoints,
            filterNames: widget.filterNames,
            filterCount: widget.filterCount,
          ),
        ),
      ),
    );
  }
}