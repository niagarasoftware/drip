import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A high-fidelity Overhead (Elevated) Tank painter: a cylindrical tank
/// with a cutaway water level, sitting on a riveted steel tower with cross
/// bracing, standing on a concrete plinth. An inlet pipe fills the tank
/// from below and an outlet pipe runs down the tower to grade.
///
/// [isOn]   – true while the pump is filling the tank: water pours in from
///            the inlet, bubbles/ripples animate, and the tank gets a soft
///            "active" glow.
/// [phase]  – 0..1 looping animation driver (ripples, flow, bubbles).
/// [fillLevel] – 0..1 how full the tank is (0 = empty, 1 = full). Defaults
///            to a comfortably-full 0.62 if not supplied.
class DetailedOverheadTankPainter extends CustomPainter {
  final bool isOn;
  final double phase;
  final bool showJoints;
  final double fillLevel;

  DetailedOverheadTankPainter({
    required this.isOn,
    this.phase = 0,
    this.showJoints = true,
    double? fillLevel,
  }) : fillLevel = (fillLevel ?? 0.62).clamp(0.03, 0.97);

  // ---------------------------------------------------------------- palette
  static const Color _tankLight = Color(0xFFF0F0F0); // Warm Grey / Concrete
  static const Color _tankMid = Color(0xFFD6D6D6);
  static const Color _tankDark = Color(0xFFBDBDBD);
  static const Color _tankPlatform = Color(0xFFAFAFAF);

  static const Color _steelLight = Color(0xFFECEFF1);
  static const Color _steelMid = Color(0xFF8FA0A8);
  static const Color _steelDark = Color(0xFF37464E);

  static const Color _concreteLight = Color(0xFFB6A98D);
  static const Color _concreteDark = Color(0xFF6E6252);

  static const Color _waterTop = Color(0xCC63C7F2);
  static const Color _waterMid = Color(0xCC1F8FD1);
  static const Color _waterDeep = Color(0xE60B4E80);
  static const Color _waterGlow = Color(0xFF7FE3FF);

  static const Color _pipeLight = Color(0xFF4FC3F7);
  static const Color _pipeMid = Color(0xFF0288D1);
  static const Color _pipeDark = Color(0xFF014B7A);

  static const Color _railingPost = Color(0xFF4E342E);
  static const Color _railingWire = Color(0xFF90A4AE);

  static const Color _edge = Color(0xFF262622);
  static const Color _cutFrame = Color(0xFF1B1B1B); // Black blocks frame

  // Shared geometry.
  Rect _tankRect(double w, double h) => Rect.fromLTWH(w * 0.20, h * 0.12, w * 0.60, h * 0.35);
  double _groundY(double h) => h * 0.95;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    _drawGround(canvas, w, h);
    _drawTower(canvas, w, h);
    _drawOutletPipe(canvas, w, h);
    if (isOn) _activeGlow(canvas, w, h);

    // Removed _drawTankShell as the section cut is now full width
    _drawWaterCutaway(canvas, w, h); // Draw full width interior + black frame
    _drawTankPlatforms(canvas, w, h); // Lips at top and bottom
    _drawRailings(canvas, w, h); // Railings at top and bottom

    _drawInletPipe(canvas, w, h);
    _drawVentAndLadder(canvas, w, h);
  }

  // -------------------------------------------------------------- helpers

  Paint _fill(Rect r, List<Color> colors,
      {List<double>? stops, Alignment begin = Alignment.centerLeft, Alignment end = Alignment.centerRight}) {
    return Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(colors: colors, stops: stops, begin: begin, end: end).createShader(r);
  }

  Paint _fillV(Rect r, List<Color> colors, {List<double>? stops}) {
    return Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(colors: colors, stops: stops, begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(r);
  }

  math.Random _seed(int n) => math.Random(n);

  // ------------------------------------------------------------------ ground

  void _drawGround(Canvas canvas, double w, double h) {
    final double groundY = _groundY(h);
    final Rect plinth = Rect.fromLTWH(w * 0.30, groundY - h * 0.045, w * 0.40, h * 0.045);
    canvas.drawRect(plinth, _fillV(plinth, const [_concreteLight, _concreteDark]));
    canvas.drawRect(plinth, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = _edge.withOpacity(0.5));

    final Rect groundLine = Rect.fromLTWH(0, groundY, w, h - groundY);
    canvas.drawRect(groundLine, Paint()..color = _concreteDark.withOpacity(0.35));
    canvas.drawLine(Offset(0, groundY), Offset(w, groundY), Paint()..color = _edge.withOpacity(0.5)..strokeWidth = 1.2);

    // Aggregate speckle on the plinth.
    final math.Random agg = _seed(41);
    canvas.save();
    canvas.clipRect(plinth);
    for (int i = 0; i < 60; i++) {
      final double x = plinth.left + agg.nextDouble() * plinth.width;
      final double y = plinth.top + agg.nextDouble() * plinth.height;
      canvas.drawCircle(Offset(x, y), 0.5 + agg.nextDouble() * 0.7,
          Paint()..color = (agg.nextBool() ? Colors.white : Colors.black).withOpacity(0.08));
    }
    canvas.restore();
  }

  // ------------------------------------------------------------------ tower

  void _drawTower(Canvas canvas, double w, double h) {
    final Rect tank = _tankRect(w, h);
    final double groundY = _groundY(h) - h * 0.045;
    final double towerTop = tank.bottom - h * 0.01;

    final double legSpreadTop = tank.width * 0.42;
    final double legSpreadBottom = tank.width * 0.62;
    final double cx = tank.center.dx;

    final Offset ltTop = Offset(cx - legSpreadTop, towerTop);
    final Offset rtTop = Offset(cx + legSpreadTop, towerTop);
    final Offset ltBot = Offset(cx - legSpreadBottom, groundY);
    final Offset rtBot = Offset(cx + legSpreadBottom, groundY);

    final Paint leg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = _steelMid;
    final Paint legHi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.35);

    canvas.drawLine(ltTop, ltBot, leg);
    canvas.drawLine(rtTop, rtBot, leg);
    canvas.drawLine(ltTop, ltBot, legHi);
    canvas.drawLine(rtTop, rtBot, legHi);

    // Cross bracing (X pattern) in tiers.
    final Paint brace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _steelDark.withOpacity(0.85);
    final int tiers = 4;
    for (int i = 0; i < tiers; i++) {
      final double t0 = i / tiers;
      final double t1 = (i + 1) / tiers;
      final Offset l0 = Offset.lerp(ltTop, ltBot, t0)!;
      final Offset l1 = Offset.lerp(ltTop, ltBot, t1)!;
      final Offset r0 = Offset.lerp(rtTop, rtBot, t0)!;
      final Offset r1 = Offset.lerp(rtTop, rtBot, t1)!;
      canvas.drawLine(l0, r1, brace);
      canvas.drawLine(r0, l1, brace);
      // Horizontal ring at each tier.
      canvas.drawLine(l0, r0, Paint()..color = _steelDark..strokeWidth = 1.4);
    }
    canvas.drawLine(ltBot, rtBot, Paint()..color = _steelDark..strokeWidth = 1.8);

    // A hint of the far pair of legs (depth) drawn thinner/behind.
    final double depthOffset = w * 0.05;
    final Paint legBack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = _steelDark.withOpacity(0.55);
    canvas.drawLine(Offset(ltTop.dx + depthOffset, ltTop.dy), Offset(ltBot.dx + depthOffset * 0.6, ltBot.dy), legBack);
    canvas.drawLine(Offset(rtTop.dx - depthOffset, rtTop.dy), Offset(rtBot.dx - depthOffset * 0.6, rtBot.dy), legBack);

    // Rivets on the legs.
    if (showJoints) {
      final Paint rivet = Paint()..color = _steelDark;
      for (int i = 0; i <= 8; i++) {
        final double t = i / 8;
        canvas.drawCircle(Offset.lerp(ltTop, ltBot, t)!, 1.1, rivet);
        canvas.drawCircle(Offset.lerp(rtTop, rtBot, t)!, 1.1, rivet);
      }
    }
  }

  void _activeGlow(Canvas canvas, double w, double h) {
    final double pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
    final Rect tank = _tankRect(w, h);
    canvas.drawOval(
      tank.inflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + 2 * pulse
        ..color = _waterGlow.withOpacity(0.25 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 4 * pulse),
    );
  }

  // ------------------------------------------------------------------ tank

  // Removed _drawTankShell as the section cut is now full width

  void _drawWaterCutaway(Canvas canvas, double w, double h) {
    final Rect tank = _tankRect(w, h);
    final double wallThickness = w * 0.035;

    // 1. Draw the "Black Blocks" frame around the full width
    final Paint framePaint = Paint()..color = _cutFrame;
    // Top wall thickness
    canvas.drawRect(Rect.fromLTWH(tank.left, tank.top, tank.width, wallThickness), framePaint);
    // Bottom wall thickness
    canvas.drawRect(Rect.fromLTWH(tank.left, tank.bottom - wallThickness, tank.width, wallThickness), framePaint);
    // Left side wall thickness
    canvas.drawRect(Rect.fromLTWH(tank.left, tank.top, wallThickness, tank.height), framePaint);
    // Right side wall thickness
    canvas.drawRect(Rect.fromLTWH(tank.right - wallThickness, tank.top, wallThickness, tank.height), framePaint);

    // 2. Draw the interior space
    final Rect interior = Rect.fromLTRB(
      tank.left + wallThickness,
      tank.top + wallThickness,
      tank.right - wallThickness,
      tank.bottom - wallThickness
    );
    canvas.drawRect(interior, Paint()..color = const Color(0xFF242424)); // Dark interior

    // 3. Draw the water level (Full Width)
    final double waterHeight = interior.height * fillLevel;
    final Rect waterRect = Rect.fromLTWH(
      interior.left,
      interior.bottom - waterHeight,
      interior.width,
      waterHeight
    );

    canvas.save();
    canvas.clipRect(interior);
    canvas.drawRect(waterRect, _fillV(waterRect, const [_waterTop, _waterMid, _waterDeep]));

    // Ripples and bubbles
    for (int layer = 0; layer < 2; layer++) {
      final Paint ripple = Paint()
        ..color = Colors.white.withOpacity(0.3 - layer * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final Path path = Path();
      final double amp = h * 0.003;
      final double freq = 6.0;
      final double speed = phase * 2 * math.pi;
      for (double x = waterRect.left; x <= waterRect.right; x += 2) {
        final double t = (x - waterRect.left) / waterRect.width;
        final double y = (interior.bottom - waterHeight) + amp * math.sin(t * freq * math.pi + speed);
        if (x == waterRect.left) path.moveTo(x, y); else path.lineTo(x, y);
      }
      canvas.drawPath(path, ripple);
    }

    if (isOn) {
      final math.Random rnd = _seed(12);
      for (int i = 0; i < 10; i++) {
        final double seedT = rnd.nextDouble();
        final double t = (phase + seedT) % 1.0;
        final double bx = waterRect.left + rnd.nextDouble() * waterRect.width;
        final double by = waterRect.bottom - t * waterRect.height;
        canvas.drawCircle(Offset(bx, by), 1.2, Paint()..color = Colors.white.withOpacity(0.4 * (1 - t)));
      }
    }
    canvas.restore();
  }

  void _drawTankPlatforms(Canvas canvas, double w, double h) {
    final Rect tank = _tankRect(w, h);
    final double lipH = h * 0.025;
    final double lipExtend = w * 0.06;

    final Paint platformPaint = Paint()..color = _tankPlatform;
    final Paint shadowPaint = Paint()..color = Colors.black26;

    // Bottom Platform (Walkway)
    final Rect bottomLip = Rect.fromLTWH(tank.left - lipExtend, tank.bottom - lipH * 0.5, tank.width + lipExtend * 2, lipH);
    canvas.drawRRect(RRect.fromRectAndRadius(bottomLip, Radius.circular(lipH * 0.4)), platformPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bottomLip, Radius.circular(lipH * 0.4)), Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _edge.withOpacity(0.4));
    
    // Top Platform (Rim)
    final Rect topLip = Rect.fromLTWH(tank.left - w * 0.02, tank.top - lipH * 0.5, tank.width + w * 0.04, lipH);
    canvas.drawRRect(RRect.fromRectAndRadius(topLip, Radius.circular(lipH * 0.4)), platformPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(topLip, Radius.circular(lipH * 0.4)), Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _edge.withOpacity(0.4));

    // Shallow dome top
    final Rect dome = Rect.fromLTWH(tank.left, tank.top - h * 0.04, tank.width, h * 0.08);
    canvas.drawArc(dome, math.pi, math.pi, false, platformPaint);
    canvas.drawArc(dome, math.pi, math.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _edge.withOpacity(0.4));
  }

  void _drawRailings(Canvas canvas, double w, double h) {
    final Rect tank = _tankRect(w, h);
    final double railH = h * 0.06;
    final double lipExtend = w * 0.06;

    // Helper for railings
    void drawRailSet(double xStart, double xEnd, double yBase) {
      final int posts = 6;
      final double step = (xEnd - xStart) / (posts - 1);
      
      final Paint postPaint = Paint()..color = _railingPost..strokeWidth = 1.5..strokeCap = StrokeCap.round;
      final Paint wirePaint = Paint()..color = _railingWire..strokeWidth = 0.6;

      // Vertical posts
      for (int i = 0; i < posts; i++) {
        final double x = xStart + i * step;
        canvas.drawLine(Offset(x, yBase), Offset(x, yBase - railH), postPaint);
      }
      
      // Horizontal wires (3 tiers)
      for (int i = 1; i <= 3; i++) {
        final double ry = yBase - (railH * (i / 3));
        canvas.drawLine(Offset(xStart, ry), Offset(xEnd, ry), wirePaint);
      }
    }

    // Bottom platform railings (wider)
    drawRailSet(tank.left - lipExtend + 4, tank.right + lipExtend - 4, tank.bottom - h * 0.01);
    
    // Top rim railings
    drawRailSet(tank.left - w * 0.01, tank.right + w * 0.01, tank.top - h * 0.01);
  }

  // ------------------------------------------------------------ inlet pipe

  void _drawInletPipe(Canvas canvas, double w, double h) {
    final Rect tank = _tankRect(w, h);
    // Small inlet pipe entering the roof from the side.
    final Rect inlet = Rect.fromLTWH(tank.left - w * 0.06, tank.top - tank.height * 0.24, w * 0.09, h * 0.035);
    canvas.drawRect(inlet, _fill(inlet, const [_pipeLight, _pipeMid, _pipeDark], stops: const [0, 0.4, 1]));
    canvas.drawRect(inlet, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _pipeDark);

    final Rect elbow = Rect.fromLTWH(tank.left - w * 0.02, tank.top - tank.height * 0.30, w * 0.05, h * 0.09);
    canvas.drawRRect(RRect.fromRectAndRadius(elbow, const Radius.circular(4)), _fillV(elbow, const [_pipeMid, _pipeDark]));

    // Pouring stream into the roof opening while filling.
    if (isOn) {
      final Rect stream = Rect.fromLTWH(tank.left + tank.width * 0.04, tank.top - tank.height * 0.10, w * 0.02, h * 0.10);
      canvas.drawRect(stream, _fillV(stream, const [Colors.white70, _waterTop, _waterMid]));
      final Paint streak = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 0.9;
      final math.Random rnd = _seed(13);
      for (int i = 0; i < 4; i++) {
        final double t = (phase * 1.6 + i / 4) % 1.0;
        final double x = stream.left + rnd.nextDouble() * stream.width;
        final double y = stream.top + t * stream.height;
        canvas.drawLine(Offset(x, y), Offset(x, y + stream.height * 0.08), streak);
      }
    }
  }

  // ----------------------------------------------------------- outlet pipe

  void _drawOutletPipe(Canvas canvas, double w, double h) {
    final Rect tank = _tankRect(w, h);
    final double groundY = _groundY(h) - h * 0.045;
    final Rect riser = Rect.fromLTWH(tank.center.dx - w * 0.02, tank.bottom - tank.height * 0.06, w * 0.04, groundY - (tank.bottom - tank.height * 0.06));
    canvas.drawRect(riser, _fill(riser, const [_pipeLight, _pipeMid, _pipeDark], stops: const [0, 0.4, 1]));
    canvas.drawRect(riser, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _pipeDark);

    // Shut-off valve wheel partway down.
    final Offset valveCenter = Offset(riser.center.dx, riser.top + riser.height * 0.55);
    canvas.drawCircle(valveCenter, w * 0.022, Paint()..color = _steelMid);
    canvas.drawCircle(valveCenter, w * 0.022, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = _steelDark);
    canvas.drawLine(valveCenter - Offset(w * 0.022, 0), valveCenter + Offset(w * 0.022, 0), Paint()..color = _steelDark..strokeWidth = 1.4);
  }

  void _drawVentAndLadder(Canvas canvas, double w, double h) {
    final Rect tank = _tankRect(w, h);

    // Small roof vent pipe.
    final Rect vent = Rect.fromLTWH(tank.center.dx + tank.width * 0.14, tank.top - h * 0.08, w * 0.015, h * 0.05);
    canvas.drawRect(vent, Paint()..color = _railingPost);
    canvas.drawRect(vent, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6..color = _edge);

    // Simple ladder up one tower leg.
    final double legX = tank.center.dx + tank.width * 0.42 * 0.6;
    final Paint rail = Paint()..color = _steelDark..strokeWidth = 1.2;
    final double topY = tank.bottom;
    final double botY = _groundY(h) - h * 0.045;
    canvas.drawLine(Offset(legX - 3, topY), Offset(legX - 3, botY), rail);
    canvas.drawLine(Offset(legX + 3, topY), Offset(legX + 3, botY), rail);
    final int rungs = 8;
    for (int i = 0; i <= rungs; i++) {
      final double y = topY + (botY - topY) * i / rungs;
      canvas.drawLine(Offset(legX - 3, y), Offset(legX + 3, y), Paint()..color = _steelDark..strokeWidth = 1.0);
    }
  }

  @override
  bool shouldRepaint(covariant DetailedOverheadTankPainter old) =>
      old.isOn != isOn || old.phase != phase || old.showJoints != showJoints || old.fillLevel != fillLevel;
}

/// Drop-in widget: keeps ripples, bubbles and flow cues animating.
class OverheadTankView extends StatefulWidget {
  final bool isOn;
  final bool showJoints;
  final double? fillLevel;
  final Size size;

  const OverheadTankView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    this.fillLevel,
    this.size = const Size(220, 220),
  });

  @override
  State<OverheadTankView> createState() => _OverheadTankViewState();
}

class _OverheadTankViewState extends State<OverheadTankView> with SingleTickerProviderStateMixin {
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
        painter: DetailedOverheadTankPainter(
          isOn: widget.isOn,
          phase: _c.value,
          showJoints: widget.showJoints,
          fillLevel: widget.fillLevel,
        ),
      ),
    );
  }
}