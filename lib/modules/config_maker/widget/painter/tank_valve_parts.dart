import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'main_valve_parts.dart';

/// Drawing parts for the TANK valves (single / multi tank).
///
/// A polished brass valve body with union nuts and tail collars.
///
/// Pipes, end flanges, gaskets and bolts are shared with [MainValveArt].
class TankValveArt {
  TankValveArt._();

  // ---------------------------------------------------------------- palette
  static const Color brassDark = Color(0xFF7A5A1E);
  static const Color brassMid = Color(0xFFC99B3A);
  static const Color brassLight = Color(0xFFF0D184);

  static Paint brassH(Rect r) => MainValveArt.fillH(
    r,
    const [brassDark, brassLight, brassMid, brassDark],
    stops: const [0, 0.28, 0.62, 1],
  );

  /// Distance from the valve centre to the outer end of its tail collars.
  static double halfHeight(double p) => p * 2.3 / 2 + p * 0.5 + p * 0.25;

  // ---------------------------------------------------------------- valve

  /// Brass valve centred at [c]; [p] is the pipe diameter.
  static void valve(
      Canvas canvas,
      Offset c,
      double p, {
        required bool active,
        bool joints = true,
        Color? inactiveHalo,
      }) {
    final double cx = c.dx;
    final double cy = c.dy;
    final double u = p / 40;
    final double ew = math.max(0.9, u);

    final double bodyW = p * 1.9;
    final double bodyH = p * 2.3;
    final double nutW = p * 1.55;
    final double nutH = p * 0.5;
    final double collarW = p * 1.2;
    final double collarH = p * 0.25;

    // Status halo
    if (active || inactiveHalo != null) {
      canvas.drawCircle(
        c,
        p * 1.7,
        Paint()
          ..color = (active ? MainValveArt.green.withValues(alpha: 0.30) : inactiveHalo!.withValues(alpha: 0.22))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p * 0.55),
      );
    }

    final double topEdge = cy - bodyH / 2;
    final double botEdge = cy + bodyH / 2;

    // Tail collars + union nuts (top and bottom)
    for (final bool top in [true, false]) {
      final double s = top ? -1 : 1;
      final double edge = top ? topEdge : botEdge;
      final double nutA = edge + s * p * 0.04;
      final double nutB = nutA + s * nutH;
      final double colA = nutB - s * p * 0.03;
      final double colB = colA + s * collarH;

      // Tail collar with thread rings
      final Rect collar = Rect.fromLTRB(cx - collarW / 2, math.min(colA, colB), cx + collarW / 2, math.max(colA, colB));
      final RRect rcol = RRect.fromRectAndRadius(collar, Radius.circular(p * 0.06));
      canvas.drawRRect(rcol.shift(Offset(u * 1.5, u * 2.2)), MainValveArt.shadow(0.18));
      canvas.drawRRect(rcol, brassH(collar));
      for (int i = 1; i <= 3; i++) {
        final double y = collar.top + collar.height * i / 4;
        canvas.drawLine(Offset(collar.left, y), Offset(collar.right, y), MainValveArt.stroke(Colors.black.withValues(alpha: 0.3), ew));
      }
      canvas.drawRRect(rcol, MainValveArt.stroke(Colors.black.withValues(alpha: 0.55), ew));

      // Hex union nut seen from the side (three faces)
      final Rect nut = Rect.fromLTRB(cx - nutW / 2, math.min(nutA, nutB), cx + nutW / 2, math.max(nutA, nutB));
      final RRect rn = RRect.fromRectAndRadius(nut, Radius.circular(p * 0.1));
      canvas.drawRRect(rn.shift(Offset(u * 1.5, u * 2.4)), MainValveArt.shadow(0.22));
      canvas.drawRRect(rn, brassH(nut));
      for (final double f in [1 / 3, 2 / 3]) {
        final double x = nut.left + nut.width * f;
        canvas.drawLine(Offset(x, nut.top + ew), Offset(x, nut.bottom - ew), MainValveArt.stroke(Colors.black.withValues(alpha: 0.4), ew * 1.2));
        canvas.drawLine(Offset(x + ew * 1.2, nut.top + ew), Offset(x + ew * 1.2, nut.bottom - ew), MainValveArt.stroke(Colors.white.withValues(alpha: 0.3), ew));
      }
      canvas.drawLine(
        Offset(nut.left + p * 0.08, nut.top + nut.height * 0.14),
        Offset(nut.right - p * 0.08, nut.top + nut.height * 0.14),
        MainValveArt.stroke(Colors.white.withValues(alpha: 0.35), ew),
      );
      canvas.drawRRect(rn, MainValveArt.stroke(Colors.black.withValues(alpha: 0.6), ew * 1.1));
    }

    // Brass body
    final Rect body = Rect.fromCenter(center: c, width: bodyW, height: bodyH);
    final RRect rb = RRect.fromRectAndRadius(body, Radius.circular(p * 0.4));
    canvas.drawRRect(rb.shift(Offset(u * 2.2, u * 3.2)), MainValveArt.shadow(0.24));
    canvas.drawRRect(rb, brassH(body));
    canvas.save();
    canvas.clipRRect(rb);
    final math.Random rnd = math.Random(8);
    for (double y = body.top; y < body.bottom; y += math.max(2.0, u * 2.2)) {
      canvas.drawLine(
        Offset(body.left, y),
        Offset(body.right, y),
        MainValveArt.stroke((rnd.nextBool() ? Colors.white : Colors.black).withValues(alpha: 0.035 + 0.03 * rnd.nextDouble()), 1),
      );
    }
    final Rect hl = Rect.fromLTRB(body.left + p * 0.1, body.top + p * 0.2, body.left + p * 0.3, body.bottom - p * 0.2);
    canvas.drawRect(hl, MainValveArt.fillH(hl, [Colors.transparent, Colors.white.withValues(alpha: 0.28), Colors.transparent]));
    MainValveArt.speckle(canvas, body, 23, 12, const Color(0xFF5A3F10), u);
    canvas.restore();
    canvas.drawRRect(rb, MainValveArt.stroke(Colors.black.withValues(alpha: 0.6), ew * 1.2));

    // Four hex cap screws at the body corners
    if (joints) {
      for (final double sx in [-1.0, 1.0]) {
        for (final double sy in [-1.0, 1.0]) {
          final Offset bc = Offset(cx + sx * p * 0.72, cy + sy * p * 0.98);
          final Path hex = MainValveArt.hexPath(bc, p * 0.1, math.pi / 6);
          canvas.drawPath(hex, MainValveArt.fillV(Rect.fromCircle(center: bc, radius: p * 0.1), const [MainValveArt.ssLight, MainValveArt.ssMid, MainValveArt.ssDark]));
          canvas.drawPath(hex, MainValveArt.stroke(Colors.black.withValues(alpha: 0.6), ew));
          canvas.drawCircle(bc, p * 0.035, Paint()..color = Colors.black.withValues(alpha: 0.55));
        }
      }
    }
  }
}