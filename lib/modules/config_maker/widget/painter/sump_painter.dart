import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A high-fidelity Sump / Collection Tank painter, drawn as an underground
/// cutaway: sand wraps the sides and bottom only (the top of the pit is
/// open / at grade), the pit walls are built from a concrete-block +
/// mortar pattern, and there's animated water with ripples + caustics,
/// an inlet elbow (left) and a suction riser with a slotted foot-valve
/// strainer (right — no dot grid).
///
/// [isOn]   – true while the pump is running: water pours in, bubbles rise,
///            and the whole pit gets a soft "active" glow so it reads at a
///            glance.
/// [phase]  – 0..1 looping animation driver (ripples, flow, bubbles).
class DetailedSumpPainter extends CustomPainter {
  final bool isOn;
  final double phase;
  final bool showJoints;

  DetailedSumpPainter({
    required this.isOn,
    this.phase = 0,
    this.showJoints = true,
  });

  // ---------------------------------------------------------------- palette
  static const Color _sandLight = Color(0xFFF2D2A9); // Light desert sand
  static const Color _sandBase = Color(0xFFD2B48C);  // Classic tan sand
  static const Color _sandDark = Color(0xFFB8860B);  // Deep golden sand

  static const Color _concreteLight = Color(0xFFCD5C5C); // Earthy Red
  static const Color _concreteMid = Color(0xFF8B4513);   // Saddle Brown
  static const Color _concreteDark = Color(0xFF5D4037);  // Deep Burnt Umber
  static const Color _concreteFloor = Color(0xFF4E342E); // Dark soil/concrete floor
  static const Color _mortar = Color(0xFF3E2723);     // Dark brown mortar

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

  // Pit geometry — shared across sand / structure / glow so everything lines
  // up. pitTop is where sand stops (nothing above this line).
  double _pitTop(double h) => h * 0.185;
  double _pitBottom(double h) => h * 0.925;
  double _pitLeft(double w) => w * 0.095;
  double _pitRight(double w) => w * 0.905;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    _drawSandSurround(canvas, w, h);
    _drawGroundShadowIntoPit(canvas, w, h);
    _drawConcreteStructure(canvas, w, h);
    if (isOn) _activeGlow(canvas, w, h);
    _drawWater(canvas, w, h);
    _drawInletPipe(canvas, w, h);
    _drawSuctionPipe(canvas, w, h);
    _drawRimHighlight(canvas, w, h);
  }

  // -------------------------------------------------------------- helpers

  Paint _fill(Rect r, List<Color> colors,
      {List<double>? stops, Alignment begin = Alignment.topCenter, Alignment end = Alignment.bottomCenter}) {
    return Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(colors: colors, stops: stops, begin: begin, end: end).createShader(r);
  }

  /// Deterministic speckle field — same seed every frame so the texture
  /// doesn't crawl/shimmer as the painter repaints for animation.
  math.Random _seed(int n) => math.Random(n);

  // ------------------------------------------------------------------ sand

  /// Sand now only wraps the LEFT side, RIGHT side and BOTTOM of the pit —
  /// nothing is drawn above `pitTop`, so the top of the structure reads as
  /// open / at grade instead of buried.
  void _drawSandSurround(Canvas canvas, double w, double h) {
    final double pitTop = _pitTop(h);
    final double pitLeft = _pitLeft(w);
    final double pitRight = _pitRight(w);

    final Rect sandRect = Rect.fromLTWH(0, pitTop, w, h - pitTop);

    canvas.save();
    canvas.clipRect(sandRect);

    canvas.drawRect(
      sandRect,
      _fill(sandRect, const [_sandLight, _sandBase, _sandDark], stops: const [0.0, 0.55, 1.0]),
    );

    // Sand grain speckle — small dots of varying warm tones.
    final math.Random rnd = _seed(11);
    final List<Color> speckle = [
      Colors.white.withOpacity(0.10),
      _sandDark.withOpacity(0.35),
      const Color(0xFF7A5A32).withOpacity(0.25),
    ];
    final int count = ((w * h) / 90).round();
    for (int i = 0; i < count; i++) {
      final double x = rnd.nextDouble() * w;
      final double y = pitTop + rnd.nextDouble() * (h - pitTop);
      // Skip specks that would land inside the pit interior.
      final bool insidePitX = x > pitLeft && x < pitRight;
      final bool insidePitY = y > pitTop && y < h * 0.92;
      if (insidePitX && insidePitY) continue;
      canvas.drawCircle(Offset(x, y), 0.6 + rnd.nextDouble() * 1.1, Paint()..color = speckle[i % speckle.length]);
    }

    // Small embedded pebbles for extra realism.
    final math.Random pebbleRnd = _seed(23);
    for (int i = 0; i < (count / 12).round(); i++) {
      final double x = pebbleRnd.nextDouble() * w;
      final double y = pitTop + pebbleRnd.nextDouble() * (h - pitTop);
      final bool insidePitX = x > pitLeft && x < pitRight;
      final bool insidePitY = y > pitTop && y < h * 0.92;
      if (insidePitX && insidePitY) continue;
      final double r = 1.2 + pebbleRnd.nextDouble() * 1.8;
      canvas.drawCircle(Offset(x, y), r, Paint()..color = const Color(0xFF8A6B42).withOpacity(0.55));
      canvas.drawCircle(Offset(x - r * 0.3, y - r * 0.3), r * 0.35, Paint()..color = Colors.white.withOpacity(0.25));
    }

    canvas.restore();
  }

  void _drawGroundShadowIntoPit(Canvas canvas, double w, double h) {
    // Soft dark halo where the sand meets the excavated pit, so the pit
    // reads as recessed rather than pasted on top.
    final Rect pit = Rect.fromLTRB(_pitLeft(w), _pitTop(h), _pitRight(w), _pitBottom(h));
    canvas.drawRRect(
      RRect.fromRectAndRadius(pit, const Radius.circular(4)),
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  // -------------------------------------------------------------- concrete

  void _drawConcreteStructure(Canvas canvas, double w, double h) {
    final Rect back = Rect.fromLTRB(w * 0.1, h * 0.2, w * 0.9, h * 0.9);

    final Path backPath = Path()..addRect(back);

    // Left wall (perspective face, catching more light).
    final Path leftWall = Path()
      ..moveTo(0, h * 0.05)
      ..lineTo(w * 0.1, h * 0.2)
      ..lineTo(w * 0.1, h * 0.9)
      ..lineTo(0, h * 0.97)
      ..close();

    // Right wall (perspective face, in shadow).
    final Path rightWall = Path()
      ..moveTo(w, h * 0.05)
      ..lineTo(w * 0.9, h * 0.2)
      ..lineTo(w * 0.9, h * 0.9)
      ..lineTo(w, h * 0.97)
      ..close();

    // Floor.
    final Path floor = Path()
      ..moveTo(0, h * 0.97)
      ..lineTo(w * 0.1, h * 0.9)
      ..lineTo(w * 0.9, h * 0.9)
      ..lineTo(w, h * 0.97)
      ..close();

    // Frame walls are now built from a block + mortar pattern instead of a
    // flat gradient. Each face gets its own random seed so the block tone
    // variation doesn't repeat identically across faces.
    _drawBlockWall(canvas, backPath, cols: 6, blockAspect: 0.42, seed: 51, lighter: true);
    _drawBlockWall(canvas, leftWall, cols: 3, blockAspect: 0.42, seed: 53, lighter: true);
    _drawBlockWall(canvas, rightWall, cols: 3, blockAspect: 0.42, seed: 57, lighter: false);

    // Floor stays a poured concrete slab (not blocks) with aggregate speckle.
    canvas.drawPath(floor, _fill(floor.getBounds(), const [_concreteDark, _concreteFloor]));
    final math.Random agg = _seed(31);
    canvas.save();
    canvas.clipPath(floor);
    final Rect fb = floor.getBounds();
    final int n = ((fb.width * fb.height) / 55).round().clamp(20, 900);
    for (int i = 0; i < n; i++) {
      final double x = fb.left + agg.nextDouble() * fb.width;
      final double y = fb.top + agg.nextDouble() * fb.height;
      final double v = agg.nextDouble();
      canvas.drawCircle(
        Offset(x, y),
        0.5 + agg.nextDouble() * 0.9,
        Paint()..color = (v > 0.5 ? Colors.white : Colors.black).withOpacity(0.06 + v * 0.05),
      );
    }
    canvas.restore();

    // Water-stain streaks below the inlet and along the back wall, common
    // on real sump/collection pits — drawn over the blocks for realism.
    final Paint stain = Paint()..color = const Color(0xFF3F5A66).withOpacity(0.16);
    canvas.save();
    canvas.clipPath(backPath);
    for (final double x in [0.30, 0.55, 0.68]) {
      final Path streak = Path()
        ..moveTo(w * x, h * 0.20)
        ..lineTo(w * (x + 0.015), h * 0.58)
        ..lineTo(w * (x - 0.01), h * 0.58)
        ..close();
      canvas.drawPath(streak, stain);
    }
    canvas.restore();

    // Outer outlines.
    final Paint line = Paint()
      ..color = _edge.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(backPath, line);
    canvas.drawPath(leftWall, line);
    canvas.drawPath(rightWall, line);
    canvas.drawPath(floor, line);
  }

  /// Draws a running-bond concrete-block wall clipped to [facePath]: a dark
  /// mortar base, individual blocks with slight tone variation and a soft
  /// bevel (light top/left edge, dark bottom/right edge), and mortar joints
  /// showing through the gaps between blocks.
  void _drawBlockWall(
      Canvas canvas,
      Path facePath, {
        required int cols,
        required double blockAspect,
        required int seed,
        required bool lighter,
      }) {
    final Rect b = facePath.getBounds();
    if (b.width <= 0 || b.height <= 0) return;

    canvas.save();
    canvas.clipPath(facePath);

    // Mortar base fill shows through the joints between blocks.
    canvas.drawRect(b, Paint()..color = _mortar);

    final double blockW = b.width / cols;
    final double blockH = blockW * blockAspect;
    final double mortarGap = math.max(1.0, blockW * 0.06);

    final math.Random rnd = _seed(seed);
    final List<Color> palette = lighter
        ? const [_concreteLight, _concreteMid]
        : const [_concreteMid, _concreteDark];

    int row = 0;
    for (double y = b.top; y < b.bottom + blockH; y += blockH) {
      final double rowOffset = (row.isEven) ? 0 : -blockW / 2;
      for (double x = b.left + rowOffset - blockW; x < b.right + blockW; x += blockW) {
        final Rect raw = Rect.fromLTWH(x, y, blockW, blockH);
        if (raw.right <= b.left || raw.left >= b.right) continue;
        final Rect block = Rect.fromLTWH(
          raw.left + mortarGap / 2,
          raw.top + mortarGap / 2,
          math.max(0.5, raw.width - mortarGap),
          math.max(0.5, raw.height - mortarGap),
        );

        final Color base = Color.lerp(palette[0], palette[1], rnd.nextDouble())!;
        canvas.drawRect(block, Paint()..color = base);

        // Fine aggregate speckle inside each block.
        final int specks = 4 + rnd.nextInt(4);
        for (int i = 0; i < specks; i++) {
          final double sx = block.left + rnd.nextDouble() * block.width;
          final double sy = block.top + rnd.nextDouble() * block.height;
          canvas.drawCircle(
            Offset(sx, sy),
            0.4 + rnd.nextDouble() * 0.6,
            Paint()..color = (rnd.nextBool() ? Colors.white : Colors.black).withOpacity(0.06),
          );
        }

        // Bevel: light along top/left, dark along bottom/right — sells the
        // individual block shape without needing a shadow pass.
        canvas.drawLine(block.topLeft, block.topRight,
            Paint()..color = Colors.white.withOpacity(0.22)..strokeWidth = 0.9);
        canvas.drawLine(block.topLeft, block.bottomLeft,
            Paint()..color = Colors.white.withOpacity(0.14)..strokeWidth = 0.9);
        canvas.drawLine(block.bottomLeft, block.bottomRight,
            Paint()..color = Colors.black.withOpacity(0.28)..strokeWidth = 0.9);
        canvas.drawLine(block.topRight, block.bottomRight,
            Paint()..color = Colors.black.withOpacity(0.22)..strokeWidth = 0.9);
      }
      row++;
    }

    canvas.restore();
  }

  void _drawRimHighlight(Canvas canvas, double w, double h) {
    // A crisp light edge along the top rim of the pit where the open top
    // meets the block wall.
    canvas.drawLine(
      Offset(_pitLeft(w), _pitTop(h)),
      Offset(_pitRight(w), _pitTop(h)),
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = 1.4,
    );
  }

  void _activeGlow(Canvas canvas, double w, double h) {
    final double pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
    final Rect pit = Rect.fromLTRB(w * 0.09, h * 0.18, w * 0.91, h * 0.93);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pit, const Radius.circular(6)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 + 2 * pulse
        ..color = _waterGlow.withOpacity(0.28 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 4 * pulse),
    );
  }

  // --------------------------------------------------------------- water

  void _drawWater(Canvas canvas, double w, double h) {
    final double waterLevel = h * 0.6;
    final Rect waterRect = Rect.fromLTRB(w * 0.105, waterLevel, w * 0.895, h * 0.895);

    canvas.save();
    canvas.clipRect(waterRect);

    canvas.drawRect(
      waterRect,
      _fill(waterRect, const [_waterTop, _waterMid, _waterDeep], stops: const [0.0, 0.35, 1.0]),
    );

    // Caustic light shafts — soft diagonal bands of brighter blue, the kind
    // of detail that instantly reads as "real water" rather than a flat fill.
    final Paint caustic = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (int i = 0; i < 4; i++) {
      final double t = (phase + i / 4) % 1.0;
      final double x = waterRect.left + t * waterRect.width;
      final Path shaft = Path()
        ..moveTo(x, waterRect.top)
        ..lineTo(x + waterRect.width * 0.09, waterRect.top)
        ..lineTo(x - waterRect.width * 0.05, waterRect.bottom)
        ..lineTo(x - waterRect.width * 0.14, waterRect.bottom)
        ..close();
      canvas.drawPath(shaft, caustic);
    }

    // Layered surface ripples: several sine-wave lines instead of dashes,
    // so the surface reads as continuous moving water.
    for (int layer = 0; layer < 3; layer++) {
      final Paint ripple = Paint()
        ..color = Colors.white.withOpacity(0.30 - layer * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 - layer * 0.3;
      final Path path = Path();
      final double amp = h * (0.006 + layer * 0.003);
      final double freq = 3.0 + layer * 1.5;
      final double speed = phase * 2 * math.pi * (layer.isEven ? 1 : -1);
      for (double x = waterRect.left; x <= waterRect.right; x += 3) {
        final double t = (x - waterRect.left) / waterRect.width;
        final double y = waterRect.top + layer * h * 0.012 + amp * math.sin(t * freq * math.pi + speed);
        if (x == waterRect.left) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, ripple);
    }

    // Rising bubbles while the pump is on — a strong, simple "it's active"
    // cue that's easy to notice even at a glance.
    if (isOn) {
      final math.Random bubbleRnd = _seed(5);
      for (int i = 0; i < 10; i++) {
        final double seedT = bubbleRnd.nextDouble();
        final double t = (phase + seedT) % 1.0;
        final double bx = waterRect.left + bubbleRnd.nextDouble() * waterRect.width;
        final double by = waterRect.bottom - t * waterRect.height;
        final double r = 1.0 + bubbleRnd.nextDouble() * 1.8;
        final double fade = (1 - t).clamp(0.0, 1.0);
        canvas.drawCircle(Offset(bx, by), r, Paint()..color = Colors.white.withOpacity(0.5 * fade));
      }
    }

    canvas.restore();

    // Waterline edge highlight.
    canvas.drawLine(
      Offset(waterRect.left, waterLevel),
      Offset(waterRect.right, waterLevel),
      Paint()..color = Colors.white.withOpacity(0.45)..strokeWidth = 1.2,
    );
  }

  // ------------------------------------------------------------ inlet pipe

  void _drawInletPipe(Canvas canvas, double w, double h) {
    final Rect horiz = Rect.fromLTWH(0, h * 0.15, w * 0.15, h * 0.09);
    canvas.drawRect(horiz, _fill(horiz, const [_pipeLight, _pipeMid, _pipeDark], stops: const [0, 0.4, 1]));
    canvas.drawRect(horiz, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _pipeDark);

    // Pipe support bracket into the sand wall.
    final Rect bracket = Rect.fromLTWH(w * 0.02, h * 0.155, w * 0.02, h * 0.10);
    canvas.drawRect(bracket, Paint()..color = _steelDark);

    // Elbow.
    final Rect elbowRect = Rect.fromLTWH(w * 0.1, h * 0.12, w * 0.12, h * 0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(elbowRect, const Radius.circular(8)),
      _fill(elbowRect, const [Color(0xFF37474F), Color(0xFF1B2529)]),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(elbowRect, const Radius.circular(8)),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = Colors.black45);

    // Discharge flange.
    final Rect flange = Rect.fromLTWH(w * 0.11, h * 0.27, w * 0.1, h * 0.03);
    canvas.drawRect(flange, _fill(flange, const [_steelLight, _steelMid, _steelDark]));
    canvas.drawRect(flange, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _steelDark);
    if (showJoints) _flangeBolts(canvas, flange);

    // Pouring stream, with motion-streaked edges instead of a flat block.
    if (isOn) {
      final Rect streamRect = Rect.fromLTWH(w * 0.13, h * 0.3, w * 0.06, h * 0.3);
      canvas.drawRect(
        streamRect,
        _fill(streamRect, const [Colors.white70, _waterTop, _waterMid], stops: const [0, 0.4, 1]),
      );
      final Paint streak = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1.0;
      final math.Random rnd = _seed(3);
      for (int i = 0; i < 5; i++) {
        final double t = (phase * 1.6 + i / 5) % 1.0;
        final double x = streamRect.left + rnd.nextDouble() * streamRect.width;
        final double y = streamRect.top + t * streamRect.height;
        canvas.drawLine(Offset(x, y), Offset(x, y + streamRect.height * 0.06), streak);
      }
      // Splash rings where the stream hits the water.
      final double splashY = h * 0.6;
      final double splashPulse = (phase * 3) % 1.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.16, splashY), width: w * 0.08 * (0.6 + splashPulse * 0.6), height: h * 0.012),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withOpacity(0.5 * (1 - splashPulse)),
      );
    }
  }

  // --------------------------------------------------------- suction pipe

  void _drawSuctionPipe(Canvas canvas, double w, double h) {
    // Vertical riser.
    final Rect riserRect = Rect.fromLTWH(w * 0.75, 0, w * 0.08, h * 0.78);
    canvas.drawRect(
      riserRect,
      _fill(riserRect, const [_pipeLight, _pipeMid, _pipeDark],
          stops: const [0, 0.4, 1], begin: Alignment.centerLeft, end: Alignment.centerRight),
    );
    canvas.drawRect(riserRect, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _pipeDark);

    // Upper flange.
    final Rect upperFlange = Rect.fromLTWH(w * 0.73, h * 0.1, w * 0.12, h * 0.04);
    canvas.drawRect(upperFlange, _fill(upperFlange, const [_steelLight, _steelMid, _steelDark]));
    canvas.drawRect(upperFlange, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _steelDark);
    if (showJoints) _flangeBolts(canvas, upperFlange);

    // Foot-valve body at the bottom, sitting just clear of the floor.
    final Rect valveBody = Rect.fromLTWH(w * 0.715, h * 0.70, w * 0.15, h * 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(valveBody, const Radius.circular(6)),
      _fill(valveBody, const [_steelLight, _steelMid, _steelDark], stops: const [0, 0.5, 1]),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(valveBody, const Radius.circular(6)),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = _steelDark);

    // Realistic slotted strainer: vertical louvre slots wrapping the lower
    // half of the valve body, like a real foot-valve/strainer basket.
    final Rect strainerArea = Rect.fromLTRB(
      valveBody.left + valveBody.width * 0.12,
      valveBody.top + valveBody.height * 0.30,
      valveBody.right - valveBody.width * 0.12,
      valveBody.bottom - valveBody.height * 0.10,
    );
    final Paint slot = Paint()..color = const Color(0xFF1B2226);
    final int slotCount = 5;
    final double slotW = strainerArea.width / (slotCount * 2 - 1);
    for (int i = 0; i < slotCount; i++) {
      final double x = strainerArea.left + i * slotW * 2;
      final RRect r = RRect.fromRectAndRadius(
        Rect.fromLTRB(x, strainerArea.top, x + slotW, strainerArea.bottom),
        Radius.circular(slotW * 0.4),
      );
      canvas.drawRRect(r, slot);
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = Colors.white.withOpacity(0.15),
      );
    }

    // A conical strainer tip below the body, tapering toward the floor —
    // reads clearly as "this is where water is drawn in".
    final Path tip = Path()
      ..moveTo(valveBody.left + valveBody.width * 0.15, valveBody.bottom)
      ..lineTo(valveBody.right - valveBody.width * 0.15, valveBody.bottom)
      ..lineTo(valveBody.center.dx, valveBody.bottom + h * 0.035)
      ..close();
    canvas.drawPath(tip, _fill(tip.getBounds(), const [_steelMid, _steelDark]));
    canvas.drawPath(tip, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _steelDark);

    // Inward-flow indicator: small chevrons pulled toward the strainer
    // while running, showing suction rather than just static geometry.
    if (isOn) {
      final Paint chevron = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.55);
      for (int i = 0; i < 3; i++) {
        final double t = (phase + i / 3) % 1.0;
        final double r = w * (0.10 - t * 0.06);
        final Offset c = Offset(valveBody.center.dx, valveBody.center.dy);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi * 0.15, math.pi * 0.7, false, chevron);
      }
    }
  }

  void _flangeBolts(Canvas canvas, Rect flange) {
    final Paint bolt = Paint()..color = _steelDark;
    final double y = flange.center.dy;
    for (final double fx in [0.12, 0.5, 0.88]) {
      canvas.drawCircle(Offset(flange.left + flange.width * fx, y), flange.height * 0.18, bolt);
    }
  }

  @override
  bool shouldRepaint(covariant DetailedSumpPainter old) =>
      old.isOn != isOn || old.phase != phase || old.showJoints != showJoints;
}

/// Drop-in widget: keeps ripples, bubbles and flow cues animating.
class SumpView extends StatefulWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  const SumpView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    this.size = const Size(220, 180),
  });

  @override
  State<SumpView> createState() => _SumpViewState();
}

class _SumpViewState extends State<SumpView> with SingleTickerProviderStateMixin {
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
        painter: DetailedSumpPainter(
          isOn: widget.isOn,
          phase: _c.value,
          showJoints: widget.showJoints,
        ),
      ),
    );
  }
}