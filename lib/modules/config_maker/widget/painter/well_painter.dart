import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A high-fidelity Open Well painter, drawn as a vertical cutaway: a raised
/// stone parapet ring at grade, a circular brick/stone-lined shaft going
/// down, still-dark water at the bottom with ripples + caustics, and a
/// suction pipe with a slotted foot-valve strainer hanging into the water.
///
/// [isOn]   – true while the pump is running: bubbles rise near the
///            strainer, inward-flow chevrons pulse, and the shaft gets a
///            soft "active" glow.
/// [phase]  – 0..1 looping animation driver (ripples, bubbles, flow).
class DetailedWellPainter extends CustomPainter {
  final bool isOn;
  final double phase;
  final bool showJoints;

  DetailedWellPainter({
    required this.isOn,
    this.phase = 0,
    this.showJoints = true,
  });

  // ---------------------------------------------------------------- palette
  static const Color _grassLight = Color(0xFF8BC34A);
  static const Color _grassDark = Color(0xFF5A8F2E);
  static const Color _soil = Color(0xFF6D4C29);

  static const Color _stoneLight = Color(0xFFD8CBB0);
  static const Color _stoneMid = Color(0xFFAF9C78);
  static const Color _stoneDark = Color(0xFF7C6A4C);
  static const Color _mortar = Color(0xFF4A4033);

  static const Color _parapetLight = Color(0xFFE8DCC0);
  static const Color _parapetDark = Color(0xFF9C8A63);

  static const Color _waterTop = Color(0xCC63C7F2);
  static const Color _waterMid = Color(0xCC1F8FD1);
  static const Color _waterDeep = Color(0xE60B4E80);
  static const Color _waterGlow = Color(0xFF7FE3FF);

  static const Color _pipeLight = Color(0xFF4FC3F7);
  static const Color _pipeMid = Color(0xFF0288D1);
  static const Color _pipeDark = Color(0xFF014B7A);
  static const Color _steelLight = Color(0xFFECEFF1);
  static const Color _steelMid = Color(0xFF8FA0A8);
  static const Color _steelDark = Color(0xFF37464E);

  static const Color _edge = Color(0xFF262622);

  // Shared geometry — shaft interior lines everything up.
  double _shaftTop(double h) => h * 0.14;
  double _shaftBottom(double h) => h * 0.93;
  double _shaftLeft(double w) => w * 0.16;
  double _shaftRight(double w) => w * 0.84;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    _drawGroundSurround(canvas, w, h);
    _drawShadowIntoShaft(canvas, w, h);
    _drawStoneShaft(canvas, w, h);
    if (isOn) _activeGlow(canvas, w, h);
    _drawWater(canvas, w, h);
    _drawSuctionPipe(canvas, w, h);
    _drawParapet(canvas, w, h);
    _drawRimHighlight(canvas, w, h);
  }

  // -------------------------------------------------------------- helpers

  Paint _fill(Rect r, List<Color> colors,
      {List<double>? stops, Alignment begin = Alignment.topCenter, Alignment end = Alignment.bottomCenter}) {
    return Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(colors: colors, stops: stops, begin: begin, end: end).createShader(r);
  }

  math.Random _seed(int n) => math.Random(n);

  // ------------------------------------------------------------ ground/grass

  void _drawGroundSurround(Canvas canvas, double w, double h) {
    final double top = _shaftTop(h);
    final double shaftLeft = _shaftLeft(w);
    final double shaftRight = _shaftRight(w);

    final Rect groundRect = Rect.fromLTWH(0, top, w, h - top);

    canvas.save();
    canvas.clipRect(groundRect);

    canvas.drawRect(groundRect, _fill(groundRect, const [_grassDark, _soil, _soil], stops: const [0.0, 0.18, 1.0]));

    // Thin grass band right at grade.
    final Rect grassBand = Rect.fromLTWH(0, top, w, h * 0.045);
    canvas.drawRect(grassBand, _fill(grassBand, const [_grassLight, _grassDark]));

    // Soil speckle, skipping the shaft interior.
    final math.Random rnd = _seed(7);
    final List<Color> speckle = [
      Colors.white.withOpacity(0.06),
      _soil.withOpacity(0.4),
      const Color(0xFF4A331A).withOpacity(0.3),
    ];
    final int count = ((w * h) / 110).round();
    for (int i = 0; i < count; i++) {
      final double x = rnd.nextDouble() * w;
      final double y = top + rnd.nextDouble() * (h - top);
      final bool insideShaft = x > shaftLeft && x < shaftRight && y > top + h * 0.02 && y < h * 0.92;
      if (insideShaft) continue;
      canvas.drawCircle(Offset(x, y), 0.6 + rnd.nextDouble() * 1.0, Paint()..color = speckle[i % speckle.length]);
    }

    // A few tufts of grass poking along the edge of the parapet mound.
    final math.Random tuft = _seed(19);
    for (int i = 0; i < 14; i++) {
      final bool left = i.isEven;
      final double baseX = left
          ? shaftLeft * (0.15 + tuft.nextDouble() * 0.7)
          : shaftRight + (w - shaftRight) * (0.15 + tuft.nextDouble() * 0.7);
      final double baseY = top + h * 0.04 + tuft.nextDouble() * h * 0.03;
      _drawGrassTuft(canvas, Offset(baseX, baseY), 4 + tuft.nextDouble() * 3, tuft);
    }

    canvas.restore();
  }

  void _drawGrassTuft(Canvas canvas, Offset base, double size, math.Random rnd) {
    final Paint blade = Paint()
      ..color = _grassDark.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final double lean = (rnd.nextDouble() - 0.5) * size;
      canvas.drawLine(base, Offset(base.dx + lean, base.dy - size), blade);
    }
  }

  void _drawShadowIntoShaft(Canvas canvas, double w, double h) {
    final Rect shaft = Rect.fromLTRB(_shaftLeft(w), _shaftTop(h), _shaftRight(w), _shaftBottom(h));
    canvas.drawOval(
      Rect.fromLTRB(shaft.left - 6, shaft.top - 4, shaft.right + 6, shaft.top + h * 0.08),
      Paint()
        ..color = Colors.black.withOpacity(0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
  }

  // -------------------------------------------------------------- shaft wall

  void _drawStoneShaft(Canvas canvas, double w, double h) {
    final Rect shaft = Rect.fromLTRB(_shaftLeft(w), _shaftTop(h), _shaftRight(w), _shaftBottom(h));

    // Curved side walls (subtle inward taper reads as a cylindrical shaft).
    final Path leftWall = Path()
      ..moveTo(shaft.left, shaft.top)
      ..lineTo(shaft.left + w * 0.02, shaft.bottom)
      ..lineTo(shaft.left + w * 0.12, shaft.bottom)
      ..lineTo(shaft.left + w * 0.10, shaft.top)
      ..close();
    final Path rightWall = Path()
      ..moveTo(shaft.right, shaft.top)
      ..lineTo(shaft.right - w * 0.02, shaft.bottom)
      ..lineTo(shaft.right - w * 0.12, shaft.bottom)
      ..lineTo(shaft.right - w * 0.10, shaft.top)
      ..close();
    final Rect backWall = Rect.fromLTRB(shaft.left + w * 0.10, shaft.top, shaft.right - w * 0.10, shaft.bottom);

    _drawStoneCourses(canvas, backWall, rows: 9, seed: 81, lighter: true);
    _drawStoneCourses(canvas, leftWall.getBounds(), rows: 9, seed: 83, lighter: true, clip: leftWall);
    _drawStoneCourses(canvas, rightWall.getBounds(), rows: 9, seed: 87, lighter: false, clip: rightWall);

    // Damp/moss staining lower down the shaft, common near the waterline.
    final Paint moss = Paint()..color = const Color(0xFF3E5A3A).withOpacity(0.18);
    canvas.save();
    canvas.clipRect(shaft);
    for (final double x in [0.25, 0.5, 0.72]) {
      final Path streak = Path()
        ..moveTo(shaft.left + shaft.width * x, shaft.top + shaft.height * 0.35)
        ..lineTo(shaft.left + shaft.width * (x + 0.02), shaft.bottom)
        ..lineTo(shaft.left + shaft.width * (x - 0.015), shaft.bottom)
        ..close();
      canvas.drawPath(streak, moss);
    }
    canvas.restore();

    final Paint line = Paint()
      ..color = _edge.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(leftWall, line);
    canvas.drawPath(rightWall, line);
    canvas.drawRect(backWall, line);
  }

  /// Draws horizontal stone courses (rings of stone, as seen from inside a
  /// well shaft looking at the wall) with mortar joints and per-stone tone
  /// variation, similar in spirit to the sump's block-wall pattern.
  void _drawStoneCourses(Canvas canvas, Rect b, {required int rows, required int seed, required bool lighter, Path? clip}) {
    if (b.width <= 0 || b.height <= 0) return;
    canvas.save();
    canvas.clipPath(clip ?? (Path()..addRect(b)));
    canvas.drawRect(b, Paint()..color = _mortar);

    final double rowH = b.height / rows;
    final math.Random rnd = _seed(seed);
    final List<Color> palette = lighter ? const [_stoneLight, _stoneMid] : const [_stoneMid, _stoneDark];
    final double mortarGap = math.max(1.0, rowH * 0.12);

    int row = 0;
    for (double y = b.top; y < b.bottom; y += rowH) {
      final int stonesInRow = 3 + rnd.nextInt(2);
      final double stoneW = b.width / stonesInRow;
      final double jitter = (row.isEven) ? stoneW * 0.2 : -stoneW * 0.2;
      for (int i = -1; i <= stonesInRow; i++) {
        final double x = b.left + i * stoneW + jitter;
        final Rect raw = Rect.fromLTWH(x, y, stoneW, rowH);
        if (raw.right <= b.left || raw.left >= b.right) continue;
        final Rect stone = Rect.fromLTWH(
          raw.left + mortarGap / 2,
          raw.top + mortarGap / 2,
          math.max(0.5, raw.width - mortarGap),
          math.max(0.5, raw.height - mortarGap),
        );
        final Color base = Color.lerp(palette[0], palette[1], rnd.nextDouble())!;
        canvas.drawRect(stone, Paint()..color = base);

        final int specks = 3 + rnd.nextInt(3);
        for (int s = 0; s < specks; s++) {
          final double sx = stone.left + rnd.nextDouble() * stone.width;
          final double sy = stone.top + rnd.nextDouble() * stone.height;
          canvas.drawCircle(Offset(sx, sy), 0.4 + rnd.nextDouble() * 0.5,
              Paint()..color = (rnd.nextBool() ? Colors.white : Colors.black).withOpacity(0.07));
        }

        canvas.drawLine(stone.topLeft, stone.topRight, Paint()..color = Colors.white.withOpacity(0.18)..strokeWidth = 0.8);
        canvas.drawLine(stone.bottomLeft, stone.bottomRight, Paint()..color = Colors.black.withOpacity(0.26)..strokeWidth = 0.8);
      }
      row++;
    }
    canvas.restore();
  }

  void _drawParapet(Canvas canvas, double w, double h) {
    // Raised circular curb wall at grade — the visible "well mouth" ring.
    final Rect outer = Rect.fromLTRB(_shaftLeft(w) - w * 0.035, _shaftTop(h) - h * 0.075, _shaftRight(w) + w * 0.035, _shaftTop(h) + h * 0.02);
    canvas.drawOval(outer, _fill(outer, const [_parapetLight, _parapetDark]));
    canvas.drawOval(outer, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = _edge.withOpacity(0.55));

    // Inner hole of the parapet (opening down into the shaft).
    final Rect inner = Rect.fromLTRB(_shaftLeft(w), _shaftTop(h) - h * 0.01, _shaftRight(w), _shaftTop(h) + h * 0.015);
    canvas.drawOval(inner, Paint()..color = _mortar);
    canvas.drawOval(inner, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = _edge.withOpacity(0.6));
  }

  void _drawRimHighlight(Canvas canvas, double w, double h) {
    final Rect inner = Rect.fromLTRB(_shaftLeft(w), _shaftTop(h) - h * 0.01, _shaftRight(w), _shaftTop(h) + h * 0.015);
    canvas.drawArc(inner, math.pi * 1.05, math.pi * 0.85, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.3..color = Colors.white.withOpacity(0.4));
  }

  void _activeGlow(Canvas canvas, double w, double h) {
    final double pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
    final Rect shaft = Rect.fromLTRB(_shaftLeft(w) + w * 0.02, _shaftTop(h), _shaftRight(w) - w * 0.02, _shaftBottom(h));
    canvas.drawRRect(
      RRect.fromRectAndRadius(shaft, const Radius.circular(10)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + 2 * pulse
        ..color = _waterGlow.withOpacity(0.22 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 4 * pulse),
    );
  }

  // --------------------------------------------------------------- water

  void _drawWater(Canvas canvas, double w, double h) {
    final double waterLevel = h * 0.62;
    final Rect shaft = Rect.fromLTRB(_shaftLeft(w) + w * 0.03, _shaftTop(h), _shaftRight(w) - w * 0.03, _shaftBottom(h));
    final Rect waterRect = Rect.fromLTRB(shaft.left, waterLevel, shaft.right, shaft.bottom - h * 0.015);

    canvas.save();
    canvas.clipRect(waterRect);

    canvas.drawRect(waterRect, _fill(waterRect, const [_waterTop, _waterMid, _waterDeep], stops: const [0.0, 0.35, 1.0]));

    // Caustic shafts.
    final Paint caustic = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (int i = 0; i < 3; i++) {
      final double t = (phase + i / 3) % 1.0;
      final double x = waterRect.left + t * waterRect.width;
      final Path shaftPath = Path()
        ..moveTo(x, waterRect.top)
        ..lineTo(x + waterRect.width * 0.08, waterRect.top)
        ..lineTo(x - waterRect.width * 0.04, waterRect.bottom)
        ..lineTo(x - waterRect.width * 0.12, waterRect.bottom)
        ..close();
      canvas.drawPath(shaftPath, caustic);
    }

    // Ripples.
    for (int layer = 0; layer < 3; layer++) {
      final Paint ripple = Paint()
        ..color = Colors.white.withOpacity(0.28 - layer * 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3 - layer * 0.3;
      final Path path = Path();
      final double amp = h * (0.005 + layer * 0.0025);
      final double freq = 3.5 + layer * 1.4;
      final double speed = phase * 2 * math.pi * (layer.isEven ? 1 : -1);
      for (double x = waterRect.left; x <= waterRect.right; x += 3) {
        final double t = (x - waterRect.left) / waterRect.width;
        final double y = waterRect.top + layer * h * 0.01 + amp * math.sin(t * freq * math.pi + speed);
        if (x == waterRect.left) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, ripple);
    }

    if (isOn) {
      final math.Random bubbleRnd = _seed(5);
      for (int i = 0; i < 8; i++) {
        final double seedT = bubbleRnd.nextDouble();
        final double t = (phase + seedT) % 1.0;
        final double bx = waterRect.center.dx + (bubbleRnd.nextDouble() - 0.5) * waterRect.width * 0.5;
        final double by = waterRect.bottom - t * waterRect.height * 0.9;
        final double r = 0.9 + bubbleRnd.nextDouble() * 1.6;
        final double fade = (1 - t).clamp(0.0, 1.0);
        canvas.drawCircle(Offset(bx, by), r, Paint()..color = Colors.white.withOpacity(0.5 * fade));
      }
    }

    canvas.restore();

    canvas.drawLine(
      Offset(waterRect.left, waterLevel),
      Offset(waterRect.right, waterLevel),
      Paint()..color = Colors.white.withOpacity(0.42)..strokeWidth = 1.1,
    );
  }

  // --------------------------------------------------------- suction pipe

  void _drawSuctionPipe(Canvas canvas, double w, double h) {
    final double waterLevel = h * 0.62;

    // Vertical riser dropping from above the parapet down into the water.
    final Rect riserRect = Rect.fromLTWH(w * 0.56, 0, w * 0.07, h * 0.8);
    canvas.drawRect(
      riserRect,
      _fill(riserRect, const [_pipeLight, _pipeMid, _pipeDark], stops: const [0, 0.4, 1], begin: Alignment.centerLeft, end: Alignment.centerRight),
    );
    canvas.drawRect(riserRect, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _pipeDark);

    // Clamp bracket at the parapet.
    final Rect clamp = Rect.fromLTWH(w * 0.54, _shaftTop(h) - h * 0.02, w * 0.11, h * 0.03);
    canvas.drawRect(clamp, Paint()..color = _steelDark);

    // Upper flange, sitting just above grade.
    final Rect upperFlange = Rect.fromLTWH(w * 0.535, h * 0.06, w * 0.115, h * 0.035);
    canvas.drawRect(upperFlange, _fill(upperFlange, const [_steelLight, _steelMid, _steelDark]));
    canvas.drawRect(upperFlange, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _steelDark);
    if (showJoints) _flangeBolts(canvas, upperFlange);

    // Foot-valve body, hanging into the water.
    final Rect valveBody = Rect.fromLTWH(w * 0.525, waterLevel + h * 0.09, w * 0.135, h * 0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(valveBody, const Radius.circular(6)),
      _fill(valveBody, const [_steelLight, _steelMid, _steelDark], stops: const [0, 0.5, 1]),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(valveBody, const Radius.circular(6)),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = _steelDark);

    final Rect strainerArea = Rect.fromLTRB(
      valveBody.left + valveBody.width * 0.12,
      valveBody.top + valveBody.height * 0.28,
      valveBody.right - valveBody.width * 0.12,
      valveBody.bottom - valveBody.height * 0.10,
    );
    final Paint slot = Paint()..color = const Color(0xFF1B2226);
    final int slotCount = 4;
    final double slotW = strainerArea.width / (slotCount * 2 - 1);
    for (int i = 0; i < slotCount; i++) {
      final double x = strainerArea.left + i * slotW * 2;
      final RRect r = RRect.fromRectAndRadius(
        Rect.fromLTRB(x, strainerArea.top, x + slotW, strainerArea.bottom),
        Radius.circular(slotW * 0.4),
      );
      canvas.drawRRect(r, slot);
      canvas.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6..color = Colors.white.withOpacity(0.15));
    }

    final Path tip = Path()
      ..moveTo(valveBody.left + valveBody.width * 0.15, valveBody.bottom)
      ..lineTo(valveBody.right - valveBody.width * 0.15, valveBody.bottom)
      ..lineTo(valveBody.center.dx, valveBody.bottom + h * 0.03)
      ..close();
    canvas.drawPath(tip, _fill(tip.getBounds(), const [_steelMid, _steelDark]));
    canvas.drawPath(tip, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _steelDark);

    if (isOn) {
      final Paint chevron = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.55);
      for (int i = 0; i < 3; i++) {
        final double t = (phase + i / 3) % 1.0;
        final double r = w * (0.09 - t * 0.055);
        final Offset c = Offset(valveBody.center.dx, valveBody.center.dy);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi * 0.15, math.pi * 0.7, false, chevron);
      }
    }
  }

  void _flangeBolts(Canvas canvas, Rect flange) {
    final Paint bolt = Paint()..color = _steelDark;
    final double y = flange.center.dy;
    for (final double fx in [0.14, 0.5, 0.86]) {
      canvas.drawCircle(Offset(flange.left + flange.width * fx, y), flange.height * 0.2, bolt);
    }
  }

  @override
  bool shouldRepaint(covariant DetailedWellPainter old) =>
      old.isOn != isOn || old.phase != phase || old.showJoints != showJoints;
}

/// Drop-in widget: keeps ripples, bubbles and flow cues animating.
class WellView extends StatefulWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  const WellView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    this.size = const Size(220, 180),
  });

  @override
  State<WellView> createState() => _WellViewState();
}

class _WellViewState extends State<WellView> with SingleTickerProviderStateMixin {
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
        painter: DetailedWellPainter(
          isOn: widget.isOn,
          phase: _c.value,
          showJoints: widget.showJoints,
        ),
      ),
    );
  }
}