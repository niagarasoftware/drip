import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A high-fidelity Natural Source painter — RIVER edition:
/// rocky, mossy banks on either side, a flowing current with rapids/foam
/// near the rocks, drifting leaves, wispy reeds, dragonflies overhead, and
/// a submerged intake strainer on a pipe rising up out of frame — the
/// pump's suction point in a natural source.
///
/// Same public API as the pond edition, so it is a drop-in replacement:
/// [isOn]   – true while the pump is drawing water: bubbles and inward-flow
///            chevrons animate near the strainer, and the water gets a
///            soft "active" glow.
/// [phase]  – 0..1 looping animation driver (current, foam, leaves, flight).
class DetailedNaturalSourcePainter extends CustomPainter {
  final bool isOn;
  final double phase;
  final bool showJoints;

  DetailedNaturalSourcePainter({
    required this.isOn,
    this.phase = 0,
    this.showJoints = true,
  });

  // ---------------------------------------------------------------- palette
  static const Color _skyTop = Color(0xFFCBE8F6);
  static const Color _skyBottom = Color(0xFFEFF7EA);

  static const Color _mossLight = Color(0xFF8FB84A);
  static const Color _mossMid = Color(0xFF5D8F33);
  static const Color _mossDark = Color(0xFF355A1E);

  static const Color _rockLight = Color(0xFFB9AFA0);
  static const Color _rockMid = Color(0xFF8A8072);
  static const Color _rockDark = Color(0xFF5A5246);
  static const Color _soil = Color(0xFF5A4128);

  static const Color _waterTop = Color(0xCC79D6E8);
  static const Color _waterMid = Color(0xCC1E93B8);
  static const Color _waterDeep = Color(0xE60A4E6E);
  static const Color _waterGlow = Color(0xFF7FE3FF);
  static const Color _foam = Color(0xFFF3FBFD);

  static const Color _reed = Color(0xFF4C7A2E);
  static const Color _reedDark = Color(0xFF2F5A1C);
  static const Color _leaf = Color(0xFFB5651D);
  static const Color _leaf2 = Color(0xFFD98C2B);

  static const Color _steelLight = Color(0xFFECEFF1);
  static const Color _steelMid = Color(0xFF8FA0A8);
  static const Color _steelDark = Color(0xFF37464E);

  static const Color _edge = Color(0xFF262622);

  double _waterTopY(double h) => h * 0.26;
  double _waterBottomY(double h) => h * 0.95;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    _drawSky(canvas, w, h);
    _drawBanks(canvas, w, h);
    if (isOn) _activeGlow(canvas, w, h);
    _drawWater(canvas, w, h);
    _drawLeaves(canvas, w, h);
    _drawReeds(canvas, w, h);
    _drawIntakePipe(canvas, w, h);
    if (isOn) _drawDragonflies(canvas, w, h);
  }

  // -------------------------------------------------------------- helpers

  Paint _fillV(Rect r, List<Color> colors, {List<double>? stops}) {
    return Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(colors: colors, stops: stops, begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(r);
  }

  math.Random _seed(int n) => math.Random(n);

  // -------------------------------------------------------------------- sky

  void _drawSky(Canvas canvas, double w, double h) {
    final double waterTop = _waterTopY(h);
    final Rect sky = Rect.fromLTWH(0, 0, w, waterTop);
    canvas.drawRect(sky, _fillV(sky, const [_skyTop, _skyBottom]));

    canvas.drawCircle(
      Offset(w * 0.80, h * 0.07),
      w * 0.09,
      Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    final math.Random cRnd = _seed(3);
    for (int i = 0; i < 3; i++) {
      final double cx = w * (0.10 + cRnd.nextDouble() * 0.5);
      final double cy = h * (0.04 + cRnd.nextDouble() * 0.07);
      _drawCloud(canvas, Offset(cx, cy), w * (0.08 + cRnd.nextDouble() * 0.04));
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double size) {
    final Paint p = Paint()..color = Colors.white.withOpacity(0.75);
    canvas.drawCircle(center, size * 0.5, p);
    canvas.drawCircle(center + Offset(size * 0.5, size * 0.05), size * 0.38, p);
    canvas.drawCircle(center - Offset(size * 0.45, -size * 0.08), size * 0.32, p);
  }

  // ------------------------------------------------------------ rocky banks

  void _drawBanks(Canvas canvas, double w, double h) {
    final double waterTop = _waterTopY(h);

    // Soil base behind the moss, for depth.
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(w * 0.36, 0)
        ..lineTo(w * 0.12, waterTop + h * 0.10)
        ..lineTo(0, waterTop + h * 0.02)
        ..close(),
      Paint()..color = _soil.withOpacity(0.7),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w, 0)
        ..lineTo(w * 0.62, 0)
        ..lineTo(w * 0.86, waterTop + h * 0.08)
        ..lineTo(w, waterTop + h * 0.02)
        ..close(),
      Paint()..color = _soil.withOpacity(0.7),
    );

    // Mossy grass slope, left.
    final Path leftBank = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.30, 0)
      ..lineTo(w * 0.11, waterTop + h * 0.06)
      ..lineTo(0, waterTop)
      ..close();
    canvas.drawPath(leftBank, _fillV(leftBank.getBounds(), const [_mossLight, _mossMid, _mossDark]));

    // Mossy grass slope, right.
    final Path rightBank = Path()
      ..moveTo(w, 0)
      ..lineTo(w * 0.70, 0)
      ..lineTo(w * 0.90, waterTop + h * 0.04)
      ..lineTo(w, waterTop)
      ..close();
    canvas.drawPath(rightBank, _fillV(rightBank.getBounds(), const [_mossLight, _mossMid, _mossDark]));

    // Rocks lining the water's edge, both sides.
    final math.Random rockRnd = _seed(11);
    _drawRockCluster(canvas, Offset(w * 0.02, waterTop + h * 0.005), w * 0.16, rockRnd);
    _drawRockCluster(canvas, Offset(w * 0.80, waterTop - h * 0.005), w * 0.20, rockRnd);

    // A few loose boulders poking out of the current itself.
    _drawBoulder(canvas, Offset(w * 0.46, waterTop + h * 0.10), w * 0.045);
    _drawBoulder(canvas, Offset(w * 0.53, waterTop + h * 0.16), w * 0.03);

    // Grass tufts along the tops of the banks.
    final math.Random rnd = _seed(17);
    for (int i = 0; i < 46; i++) {
      final bool left = i.isEven;
      final double t = rnd.nextDouble();
      final double bx = left ? w * (0.01 + t * 0.27) : w * (0.72 + t * 0.27);
      final double by = h * (0.01 + rnd.nextDouble() * (waterTop / h + 0.01));
      _drawGrassTuft(canvas, Offset(bx, by), 4 + rnd.nextDouble() * 6, rnd);
    }
  }

  void _drawRockCluster(Canvas canvas, Offset origin, double spread, math.Random rnd) {
    for (int i = 0; i < 6; i++) {
      final double rx = origin.dx + rnd.nextDouble() * spread;
      final double ry = origin.dy + (rnd.nextDouble() - 0.5) * spread * 0.35;
      final double r = spread * (0.10 + rnd.nextDouble() * 0.10);
      _drawBoulder(canvas, Offset(rx, ry), r);
    }
  }

  void _drawBoulder(Canvas canvas, Offset center, double r) {
    final Rect rect = Rect.fromCenter(center: center, width: r * 2.2, height: r * 1.6);
    final RRect rr = RRect.fromRectAndRadius(rect, Radius.circular(r * 0.7));
    canvas.drawRRect(rr, _fillV(rect, const [_rockLight, _rockMid, _rockDark]));
    canvas.drawRRect(rr, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _rockDark.withOpacity(0.6));
    // A little moss cap on top.
    canvas.drawArc(
      Rect.fromCenter(center: center - Offset(0, r * 0.5), width: r * 1.6, height: r * 0.9),
      math.pi, math.pi, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.35..color = _mossMid.withOpacity(0.7),
    );
  }

  void _drawGrassTuft(Canvas canvas, Offset base, double size, math.Random rnd) {
    for (int i = 0; i < 4; i++) {
      final double height = size * (0.7 + rnd.nextDouble() * 0.8);
      final double curve = (rnd.nextDouble() - 0.5) * size * 1.5;
      final double width = 0.6 + rnd.nextDouble() * 1.4;

      final Paint blade = Paint()
        ..color = Color.lerp(_mossDark, _mossMid, rnd.nextDouble())!.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

      final Path path = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
            base.dx + curve * 0.3, base.dy - height * 0.6,
            base.dx + curve, base.dy - height
        );
      canvas.drawPath(path, blade);
    }
  }

  void _activeGlow(Canvas canvas, double w, double h) {
    final double pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
    final Rect water = Rect.fromLTRB(w * 0.02, _waterTopY(h), w * 0.98, _waterBottomY(h));
    canvas.drawRRect(
      RRect.fromRectAndRadius(water, const Radius.circular(8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + 2 * pulse
        ..color = _waterGlow.withOpacity(0.20 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + 5 * pulse),
    );
  }

  // --------------------------------------------------------------- water

  void _drawWater(Canvas canvas, double w, double h) {
    final Rect waterRect = Rect.fromLTRB(0, _waterTopY(h), w, _waterBottomY(h));

    canvas.save();
    canvas.clipRect(waterRect);

    canvas.drawRect(waterRect, _fillV(waterRect, const [_waterTop, _waterMid, _waterDeep], stops: const [0.0, 0.4, 1.0]));

    // Sun glints, angled — subtler than caustics since current keeps the
    // surface broken up.
    final Paint glint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (int i = 0; i < 5; i++) {
      final double t = (phase + i / 5) % 1.0;
      final double x = waterRect.left + t * waterRect.width;
      final Path shaft = Path()
        ..moveTo(x, waterRect.top)
        ..lineTo(x + waterRect.width * 0.04, waterRect.top)
        ..lineTo(x - waterRect.width * 0.10, waterRect.bottom)
        ..lineTo(x - waterRect.width * 0.14, waterRect.bottom)
        ..close();
      canvas.drawPath(shaft, glint);
    }

    // Flowing current: streaked, elongated chevrons drifting continuously
    // left-to-right (a river's downstream flow), unlike still-pond ripples.
    for (int layer = 0; layer < 4; layer++) {
      final Paint flow = Paint()
        ..color = Colors.white.withOpacity(0.22 - layer * 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 - layer * 0.2
        ..strokeCap = StrokeCap.round;
      final double yBase = waterRect.top + h * (0.06 + layer * 0.16);
      final double speed = (phase + layer * 0.17) % 1.0;
      for (int i = 0; i < 4; i++) {
        final double t = (speed + i / 4) % 1.0;
        final double startX = waterRect.left - waterRect.width * 0.15 + t * waterRect.width * 1.3;
        final double len = waterRect.width * (0.10 + layer * 0.015);
        final Path streak = Path()
          ..moveTo(startX, yBase)
          ..quadraticBezierTo(startX + len * 0.5, yBase + h * 0.01, startX + len, yBase - h * 0.005);
        canvas.drawPath(streak, flow);
      }
    }

    // Rapids / whitewater fanning out from the in-current boulders.
    final Paint foamPaint = Paint()
      ..color = _foam.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final List<Offset> boulderTips = [
      Offset(w * 0.46, waterRect.top + h * 0.10),
      Offset(w * 0.53, waterRect.top + h * 0.16),
    ];
    for (final Offset b in boulderTips) {
      for (int i = 0; i < 3; i++) {
        final double t = (phase + i / 3) % 1.0;
        final double spread = w * (0.02 + t * 0.05);
        final double fade = (1 - t);
        canvas.drawArc(
          Rect.fromCenter(center: b, width: spread * 2, height: spread * 1.1),
          math.pi * 0.9, math.pi * 1.1, false,
          foamPaint..color = _foam.withOpacity(0.5 * fade),
        );
      }
    }

    if (isOn) {
      final math.Random bubbleRnd = _seed(5);
      for (int i = 0; i < 10; i++) {
        final double seedT = bubbleRnd.nextDouble();
        final double t = (phase + seedT) % 1.0;
        final double bx = w * 0.72 + (bubbleRnd.nextDouble() - 0.5) * w * 0.10;
        final double by = waterRect.bottom - t * waterRect.height * 0.7;
        final double r = 1.0 + bubbleRnd.nextDouble() * 1.7;
        final double fade = (1 - t).clamp(0.0, 1.0);
        canvas.drawCircle(Offset(bx, by), r, Paint()..color = Colors.white.withOpacity(0.5 * fade));
      }
    }

    canvas.restore();

    canvas.drawLine(
      Offset(waterRect.left, waterRect.top),
      Offset(waterRect.right, waterRect.top),
      Paint()..color = Colors.white.withOpacity(0.38)..strokeWidth = 1.0,
    );
  }

  // -------------------------------------------------------- floating leaves

  void _drawLeaves(Canvas canvas, double w, double h) {
    final double waterTop = _waterTopY(h);
    final math.Random rnd = _seed(42);
    // Leaves drift downstream with the current instead of sitting fixed
    // like lily pads would.
    for (int i = 0; i < 5; i++) {
      final double seedT = rnd.nextDouble();
      final double t = (phase * 0.5 + seedT) % 1.0;
      final double lx = w * (-0.05 + t * 1.1);
      final double ly = waterTop + h * (0.05 + 0.09 * math.sin(seedT * 10));
      final double r = w * (0.015 + rnd.nextDouble() * 0.008);
      final double rotation = t * 2 * math.pi * 3 + seedT * 5;
      final Color leafColor = i.isEven ? _leaf : _leaf2;

      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(rotation);
      final Path leaf = Path()
        ..moveTo(0, -r)
        ..quadraticBezierTo(r, 0, 0, r)
        ..quadraticBezierTo(-r, 0, 0, -r)
        ..close();
      canvas.drawPath(leaf, Paint()..color = leafColor.withOpacity(0.9));
      canvas.drawLine(Offset(0, -r * 0.8), Offset(0, r * 0.8),
          Paint()..color = _reedDark.withOpacity(0.5)..strokeWidth = 0.6);
      canvas.restore();
    }
  }

  // ------------------------------------------------------------------ reeds

  void _drawReeds(Canvas canvas, double w, double h) {
    final double waterTop = _waterTopY(h);
    final math.Random rnd = _seed(23);
    final List<double> clusterX = [w * 0.05, w * 0.11, w * 0.91, w * 0.96];
    for (final double cx in clusterX) {
      final int stalks = 4 + rnd.nextInt(3);
      for (int i = 0; i < stalks; i++) {
        final double baseX = cx + (rnd.nextDouble() - 0.5) * w * 0.04;
        final double baseY = waterTop + h * (0.01 + rnd.nextDouble() * 0.03);
        final double stalkH = h * (0.14 + rnd.nextDouble() * 0.09);
        final double sway = math.sin(phase * 2 * math.pi + i) * w * 0.01;

        final Paint stalk = Paint()
          ..color = Color.lerp(_reed, _reedDark, rnd.nextDouble())!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;

        final Path path = Path()
          ..moveTo(baseX, baseY)
          ..quadraticBezierTo(baseX + sway, baseY - stalkH * 0.5, baseX + sway * 1.8, baseY - stalkH);
        canvas.drawPath(path, stalk);

        final double headX = baseX + sway * 1.8;
        final double headY = baseY - stalkH;
        final Rect headRect = Rect.fromCenter(center: Offset(headX, headY - 4), width: 4, height: 12);
        canvas.drawRRect(
            RRect.fromRectAndRadius(headRect, const Radius.circular(2)),
            Paint()..color = const Color(0xFF5D4037)
        );
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(headRect.left + 1, headRect.top + 2, 1.2, 5), const Radius.circular(0.5)),
            Paint()..color = Colors.white.withOpacity(0.1)
        );
      }
    }
  }

  // ----------------------------------------------------------- intake pipe

  void _drawIntakePipe(Canvas canvas, double w, double h) {
    final double waterTop = _waterTopY(h);
    // Riser coming down from off the top of the canvas into the water,
    // positioned toward the right so it reads distinct from the reeds.
    final Rect riser = Rect.fromLTWH(w * 0.66, 0, w * 0.06, h * 0.66);
    final Paint pipePaint = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        colors: [Color(0xFF4FC3F7), Color(0xFF0288D1), Color(0xFF014B7A)],
        stops: [0, 0.4, 1],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(riser);
    canvas.drawRect(riser, pipePaint);
    canvas.drawRect(riser, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = const Color(0xFF014B7A));

    // Pipe support post driven into the bank, holding it steady.
    final Rect post = Rect.fromLTWH(w * 0.635, waterTop - h * 0.02, w * 0.01, h * 0.10);
    canvas.drawRect(post, Paint()..color = _steelDark);

    // Foot-valve body underwater.
    final Rect valveBody = Rect.fromLTWH(w * 0.635, waterTop + h * 0.30, w * 0.13, h * 0.14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(valveBody, const Radius.circular(6)),
      _fillV(valveBody, const [_steelLight, _steelMid, _steelDark], stops: const [0, 0.5, 1]),
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

    // A float/buoy near the surface marking the intake, for character.
    final double bob = math.sin(phase * 2 * math.pi) * h * 0.006;
    final Offset buoyCenter = Offset(w * 0.60, waterTop + h * 0.035 + bob);
    canvas.drawCircle(buoyCenter, w * 0.018, Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(buoyCenter, w * 0.018, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = Colors.black26);
    canvas.drawLine(buoyCenter, Offset(valveBody.center.dx, valveBody.top), Paint()..color = Colors.black26..strokeWidth = 0.7);

    if (isOn) {
      final Paint chevron = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.55);
      for (int i = 0; i < 3; i++) {
        final double t = (phase + i / 3) % 1.0;
        final double r = w * (0.085 - t * 0.05);
        final Offset c = Offset(valveBody.center.dx, valveBody.center.dy);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi * 0.15, math.pi * 0.7, false, chevron);
      }
    }
  }

  // ------------------------------------------------------------ dragonflies

  void _drawDragonflies(Canvas canvas, double w, double h) {
    final Paint body = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = _edge.withOpacity(0.55);
    for (int i = 0; i < 2; i++) {
      final double t = (phase * 0.6 + i / 2) % 1.0;
      final double bx = w * (0.12 + t * 0.30) + math.sin(phase * 12 + i) * 4;
      final double by = h * (0.10 + i * 0.05) + math.cos(phase * 9 + i) * 3;
      final double flap = math.sin(phase * 20 + i) * 3;

      canvas.drawLine(Offset(bx - 4, by), Offset(bx + 4, by), body);
      final Paint wing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withOpacity(0.5);
      canvas.drawLine(Offset(bx - 1, by), Offset(bx - 4, by - 3 - flap), wing);
      canvas.drawLine(Offset(bx + 1, by), Offset(bx + 4, by - 3 - flap), wing);
    }
  }

  @override
  bool shouldRepaint(covariant DetailedNaturalSourcePainter old) =>
      old.isOn != isOn || old.phase != phase || old.showJoints != showJoints;
}

/// Drop-in widget: keeps current, foam, leaves, reeds and flow cues animating.
class NaturalSourceView extends StatefulWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  const NaturalSourceView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    this.size = const Size(240, 180),
  });

  @override
  State<NaturalSourceView> createState() => _NaturalSourceViewState();
}

class _NaturalSourceViewState extends State<NaturalSourceView> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 4));

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
        painter: DetailedNaturalSourcePainter(
          isOn: widget.isOn,
          phase: _c.value,
          showJoints: widget.showJoints,
        ),
      ),
    );
  }
}