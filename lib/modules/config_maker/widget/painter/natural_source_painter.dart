import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Simple, clear Natural Source painter (pond / lake).
///
/// Reads instantly as "natural water": green hills and trees, a calm pond with
/// ripples, cattails and rocks on the shore, and a blue intake pipe with a
/// strainer under the surface.
///
/// [isOn]  – pump is drawing: bubbles rise and inward arcs pulse at the strainer.
/// [phase] – 0..1 looping animation driver.
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
  static const Color _skyTop = Color(0xFF9ED8F2);
  static const Color _skyBottom = Color(0xFFE6F5FB);

  static const Color _hillFar = Color(0xFF9CCB6B);
  static const Color _hillNear = Color(0xFF6BAA45);
  static const Color _grassDark = Color(0xFF3F7D2C);

  static const Color _trunk = Color(0xFF6B4A2B);
  static const Color _canopy = Color(0xFF3E8E3A);
  static const Color _canopyLight = Color(0xFF58A94A);

  static const Color _waterTop = Color(0xFF6FD0E6);
  static const Color _waterMid = Color(0xFF2A9CC2);
  static const Color _waterDeep = Color(0xFF0E5F86);

  static const Color _rockLight = Color(0xFFC4BBAD);
  static const Color _rockDark = Color(0xFF7D7466);

  static const Color _reed = Color(0xFF3F7D2C);
  static const Color _cattail = Color(0xFF6D4C41);
  static const Color _pad = Color(0xFF4FA64A);

  static const Color _steelLight = Color(0xFFECEFF1);
  static const Color _steelMid = Color(0xFF8FA0A8);
  static const Color _steelDark = Color(0xFF37464E);

  double _waterTopY(double h) => h * 0.34;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    _drawSky(canvas, w, h);
    _drawHills(canvas, w, h);
    _drawTrees(canvas, w, h);
    _drawWater(canvas, w, h);
    _drawShore(canvas, w, h);
    _drawLilyPads(canvas, w, h);
    _drawCattails(canvas, w, h);
    _drawIntake(canvas, w, h);
  }

  // -------------------------------------------------------------------- sky

  void _drawSky(Canvas canvas, double w, double h) {
    final Rect sky = Rect.fromLTWH(0, 0, w, _waterTopY(h) + 2);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          colors: [_skyTop, _skyBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(sky),
    );

    // Two simple clouds.
    final Paint cloud = Paint()..color = Colors.white.withOpacity(0.85);
    _cloud(canvas, Offset(w * 0.20, h * 0.08), w * 0.07, cloud);
    _cloud(canvas, Offset(w * 0.82, h * 0.13), w * 0.055, cloud);
  }

  void _cloud(Canvas canvas, Offset c, double s, Paint p) {
    canvas.drawCircle(c, s, p);
    canvas.drawCircle(c + Offset(s * 1.1, s * 0.25), s * 0.75, p);
    canvas.drawCircle(c + Offset(-s * 1.0, s * 0.35), s * 0.65, p);
    canvas.drawRect(
      Rect.fromLTRB(c.dx - s * 1.0, c.dy + s * 0.35, c.dx + s * 1.1, c.dy + s * 0.95),
      p,
    );
  }

  // ------------------------------------------------------------------ hills

  void _drawHills(Canvas canvas, double w, double h) {
    final double wt = _waterTopY(h);

    final Path far = Path()
      ..moveTo(0, wt)
      ..lineTo(0, h * 0.20)
      ..quadraticBezierTo(w * 0.22, h * 0.10, w * 0.45, h * 0.21)
      ..quadraticBezierTo(w * 0.72, h * 0.30, w, h * 0.17)
      ..lineTo(w, wt)
      ..close();
    canvas.drawPath(far, Paint()..color = _hillFar);

    final Path near = Path()
      ..moveTo(0, wt)
      ..lineTo(0, h * 0.26)
      ..quadraticBezierTo(w * 0.30, h * 0.20, w * 0.58, h * 0.29)
      ..quadraticBezierTo(w * 0.82, h * 0.34, w, h * 0.27)
      ..lineTo(w, wt)
      ..close();
    canvas.drawPath(near, Paint()..color = _hillNear);
  }

  void _drawTrees(Canvas canvas, double w, double h) {
    _tree(canvas, Offset(w * 0.12, h * 0.31), h * 0.15);
    _tree(canvas, Offset(w * 0.25, h * 0.32), h * 0.11);
    _tree(canvas, Offset(w * 0.90, h * 0.30), h * 0.13);
  }

  void _tree(Canvas canvas, Offset base, double height) {
    final double tw = height * 0.12;
    canvas.drawRect(
      Rect.fromLTWH(base.dx - tw / 2, base.dy - height * 0.40, tw, height * 0.40),
      Paint()..color = _trunk,
    );
    final Offset c = base - Offset(0, height * 0.62);
    canvas.drawCircle(c, height * 0.34, Paint()..color = _canopy);
    canvas.drawCircle(c + Offset(-height * 0.10, -height * 0.10), height * 0.18,
        Paint()..color = _canopyLight);
  }

  // ------------------------------------------------------------------ water

  void _drawWater(Canvas canvas, double w, double h) {
    final Rect water = Rect.fromLTRB(0, _waterTopY(h), w, h);

    canvas.drawRect(
      water,
      Paint()
        ..shader = const LinearGradient(
          colors: [_waterTop, _waterMid, _waterDeep],
          stops: [0.0, 0.45, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(water),
    );

    canvas.save();
    canvas.clipRect(water);

    // Calm horizontal ripple lines, gently drifting.
    final Paint ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3;
    const List<double> rows = [0.10, 0.28, 0.46, 0.64, 0.82];
    for (int i = 0; i < rows.length; i++) {
      final double y = water.top + water.height * rows[i];
      final double drift = math.sin((phase + i * 0.2) * 2 * math.pi) * w * 0.012;
      final double x0 = w * (0.08 + (i.isEven ? 0.0 : 0.30)) + drift;
      final double len = w * (0.16 - i * 0.012);
      ripple.color = Colors.white.withOpacity(0.35 - i * 0.04);
      canvas.drawPath(
        Path()
          ..moveTo(x0, y)
          ..quadraticBezierTo(x0 + len * 0.25, y - 2.5, x0 + len * 0.5, y)
          ..quadraticBezierTo(x0 + len * 0.75, y + 2.5, x0 + len, y),
        ripple,
      );
      final double x1 = x0 + w * 0.46;
      canvas.drawPath(
        Path()
          ..moveTo(x1, y + 5)
          ..quadraticBezierTo(x1 + len * 0.25, y + 2.5, x1 + len * 0.5, y + 5)
          ..quadraticBezierTo(x1 + len * 0.75, y + 7.5, x1 + len, y + 5),
        ripple,
      );
    }

    // Soft light reflection near the surface.
    final Rect shine = Rect.fromLTWH(0, water.top, w, water.height * 0.14);
    canvas.drawRect(
      shine,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.30), Colors.white.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(shine),
    );

    canvas.restore();
  }

  // ------------------------------------------------------------------ shore

  void _drawShore(Canvas canvas, double w, double h) {
    final double wt = _waterTopY(h);

    // Narrow grassy lip along the far shoreline.
    final Path lip = Path()
      ..moveTo(0, wt - h * 0.01)
      ..quadraticBezierTo(w * 0.25, wt + h * 0.025, w * 0.5, wt + h * 0.005)
      ..quadraticBezierTo(w * 0.75, wt + h * 0.025, w, wt - h * 0.01)
      ..lineTo(w, wt - h * 0.03)
      ..lineTo(0, wt - h * 0.03)
      ..close();
    canvas.drawPath(lip, Paint()..color = _grassDark);

    // Rocks at the water's edge, left and right.
    _rock(canvas, Offset(w * 0.07, wt + h * 0.015), w * 0.045);
    _rock(canvas, Offset(w * 0.14, wt + h * 0.025), w * 0.03);
    _rock(canvas, Offset(w * 0.86, wt + h * 0.02), w * 0.04);
    _rock(canvas, Offset(w * 0.94, wt + h * 0.012), w * 0.05);
  }

  void _rock(Canvas canvas, Offset c, double r) {
    final Rect rect = Rect.fromCenter(center: c, width: r * 2.2, height: r * 1.5);
    final RRect rr = RRect.fromRectAndRadius(rect, Radius.circular(r * 0.7));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          colors: [_rockLight, _rockDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
  }

  // ------------------------------------------------------------- lily pads

  void _drawLilyPads(Canvas canvas, double w, double h) {
    final double wt = _waterTopY(h);
    final Paint pad = Paint()..color = _pad;
    final Paint flower = Paint()..color = const Color(0xFFFFB7D5);

    void padAt(Offset c, double r) {
      canvas.drawOval(Rect.fromCenter(center: c, width: r * 2, height: r * 0.8), pad);
    }

    padAt(Offset(w * 0.26, wt + h * 0.18), w * 0.035);
    padAt(Offset(w * 0.34, wt + h * 0.24), w * 0.026);
    final Offset f = Offset(w * 0.26, wt + h * 0.17);
    canvas.drawCircle(f, w * 0.009, flower);
  }

  // --------------------------------------------------------------- cattails

  void _drawCattails(Canvas canvas, double w, double h) {
    final double wt = _waterTopY(h);
    const List<double> xs = [0.03, 0.08, 0.92, 0.97];
    const List<double> hs = [0.22, 0.17, 0.19, 0.24];

    for (int i = 0; i < xs.length; i++) {
      final double bx = w * xs[i];
      final double by = wt + h * 0.05;
      final double sh = h * hs[i];
      final double sway = math.sin(phase * 2 * math.pi + i) * w * 0.008;
      final double tipX = bx + sway;
      final double tipY = by - sh;

      canvas.drawPath(
        Path()
          ..moveTo(bx, by)
          ..quadraticBezierTo(bx + sway * 0.5, by - sh * 0.5, tipX, tipY),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..color = _reed,
      );
      // Cattail head.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(tipX, tipY + 5), width: 4.5, height: 13),
          const Radius.circular(2.5),
        ),
        Paint()..color = _cattail,
      );
    }
  }

  // ----------------------------------------------------------------- intake

  void _drawIntake(Canvas canvas, double w, double h) {
    final double wt = _waterTopY(h);
    final double px = w * 0.60;
    final double pw = w * 0.07;

    // Riser pipe coming from the top of the tile.
    final double riserBottom = h * 0.70;
    final Rect riser = Rect.fromLTRB(px, 0, px + pw, riserBottom);
    canvas.drawRect(
      riser,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF0288D1), Color(0xFF014B7A)],
          stops: [0, 0.4, 1],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(riser),
    );
    canvas.drawRect(
      riser,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF014B7A),
    );

    // Strainer body (cylinder with slots).
    final Rect body = Rect.fromLTWH(px - pw * 0.45, riserBottom, pw * 1.9, h * 0.17);
    final RRect bodyR = RRect.fromRectAndRadius(body, const Radius.circular(6));
    canvas.drawRRect(
      bodyR,
      Paint()
        ..shader = const LinearGradient(
          colors: [_steelLight, _steelMid, _steelDark],
          stops: [0, 0.5, 1],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(body),
    );
    canvas.drawRRect(
      bodyR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = _steelDark,
    );

    final Paint slot = Paint()..color = const Color(0xFF1B2226);
    const int slots = 4;
    final double slotArea = body.width * 0.70;
    final double slotW = slotArea / (slots * 2 - 1);
    final double sx0 = body.left + body.width * 0.15;
    for (int i = 0; i < slots; i++) {
      final double x = sx0 + i * slotW * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x, body.top + body.height * 0.22, x + slotW, body.bottom - body.height * 0.18),
          Radius.circular(slotW * 0.4),
        ),
        slot,
      );
    }

    // Light water tint over the submerged part so it reads as underwater.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, wt, w, h));
    canvas.drawRect(
      Rect.fromLTRB(px - pw, wt, px + pw * 2.4, body.bottom + 4),
      Paint()..color = _waterMid.withOpacity(0.22),
    );
    canvas.restore();

    // Surface ripple rings where the pipe enters the water.
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.65);
    final double pcx = px + pw / 2;
    canvas.drawOval(Rect.fromCenter(center: Offset(pcx, wt + 3), width: pw * 2.0, height: pw * 0.5), ring);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(pcx, wt + 3), width: pw * 3.0, height: pw * 0.8),
        ring..color = Colors.white.withOpacity(0.30));

    if (isOn) _drawSuction(canvas, w, h, body);
  }

  void _drawSuction(Canvas canvas, double w, double h, Rect body) {
    // Bubbles rising from the strainer toward the surface.
    final math.Random rnd = math.Random(5);
    for (int i = 0; i < 8; i++) {
      final double t = (phase + rnd.nextDouble()) % 1.0;
      final double bx = body.center.dx + (rnd.nextDouble() - 0.5) * body.width * 1.6;
      final double by = body.top - t * (body.top - _waterTopY(h));
      final double r = 1.2 + rnd.nextDouble() * 1.8;
      canvas.drawCircle(Offset(bx, by), r, Paint()..color = Colors.white.withOpacity(0.6 * (1 - t)));
    }

    // Arcs pulling water inward toward the strainer.
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final double t = (phase + i / 3) % 1.0;
      final double r = w * (0.13 - t * 0.07);
      arc.color = Colors.white.withOpacity(0.55 * t);
      canvas.drawArc(Rect.fromCircle(center: body.center, radius: r), math.pi * 0.65, math.pi * 0.7, false, arc);
      canvas.drawArc(Rect.fromCircle(center: body.center, radius: r), -math.pi * 0.35, math.pi * 0.7, false, arc);
    }
  }

  @override
  bool shouldRepaint(covariant DetailedNaturalSourcePainter old) =>
      old.isOn != isOn || old.phase != phase || old.showJoints != showJoints;
}

/// Drop-in widget (same API as before).
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

class _NaturalSourceViewState extends State<NaturalSourceView> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.size,
      painter: DetailedNaturalSourcePainter(
        isOn: widget.isOn,
        phase: 0.0,
        showJoints: widget.showJoints,
      ),
    );
  }
}