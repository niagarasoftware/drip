import 'dart:math' as math;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'tank_valve_parts.dart';
import 'main_valve_parts.dart';

/// Multi Outlet Tank Valve manifold painter (realistic, dynamic channel count).
///
/// One centre inlet pipe at the top (or left if horizontal) that feeds into a horizontal stainless
/// collector header with flanged end plates, and [states.length] vertical blue outlet lines
/// at the bottom (or right if horizontal), each with a flanged cast-iron gate valve (orange handwheel,
/// green status ring + halo when open; see [TankValveArt]) dropping to bolted
/// blue end flanges at the outlet ports.
class DetailedMultiOutletTankValvePainter extends CustomPainter {
  final List<bool> states; // status of each outlet valve channel
  final bool showJoints;
  final bool isHorizontal;

  DetailedMultiOutletTankValvePainter({
    required this.states,
    this.showJoints = true,
    this.isHorizontal = false,
  });

  /// Single common inlet port
  static Offset inletPort(Size s, {bool isHorizontal = false}) =>
      isHorizontal ? Offset(0, s.height * 0.5) : Offset(s.width * 0.5, 0);

  /// Outlets at the bottom (or right if horizontal) of each channel (0..count-1)
  static Offset outletPort(Size s, int index, {int totalChannels = 4, bool isHorizontal = false}) {
    final int count = math.max(1, totalChannels);
    if (isHorizontal) {
      final double step = s.height / count;
      final double cy = step * index + step / 2;
      return Offset(s.width, cy);
    } else {
      final double step = s.width / count;
      final double cx = step * index + step / 2;
      return Offset(cx, s.height);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (isHorizontal) {
      canvas.save();
      canvas.translate(size.width * 0.5, size.height * 0.5);
      canvas.rotate(-math.pi / 2);
      canvas.translate(-size.height * 0.5, -size.width * 0.5);
    }

    final double w = isHorizontal ? size.height : size.width;
    final double h = isHorizontal ? size.width : size.height;

    final int count = math.max(1, states.length);
    final double step = w / count;
    final List<double> channelX = List.generate(count, (i) => step * i + step / 2);

    final double p = math.min(step * 0.35, h * 0.1);
    final double u = p / 40;
    final double fh = p * 0.3;
    final double fw = p * 2.15;
    final double g = p * 0.05;
    final double endH = MainValveArt.endH(p);

    final double manifoldY = h * 0.32;
    final double mh = p * 1.35;
    final double neckH = p * 0.45;
    final double valveCy = h * 0.7;
    final double cxC = w * 0.5;

    final double hl = channelX.first - p * 1.3;
    final double hr = channelX.last + p * 1.3;

    // 1. Centre top inlet: steel pipe + steel flange + gasket + top end flange
    final double ySf1 = endH + g;
    final Rect inPipe = Rect.fromLTRB(cxC - p * 0.55, ySf1, cxC + p * 0.55, manifoldY + mh * 0.5);
    MainValveArt.pipe(canvas, inPipe, blue: false, seed: 41, u: u);
    MainValveArt.flangeH(canvas, Rect.fromLTRB(cxC - fw * 0.46, ySf1, cxC + fw * 0.46, ySf1 + fh), blue: false, joints: showJoints, u: u);
    MainValveArt.gasket(canvas, Rect.fromLTRB(cxC - fw * 0.48, ySf1 - g, cxC + fw * 0.48, ySf1));

    // 2. Horizontal stainless collector header
    final Rect header = Rect.fromLTRB(hl, manifoldY, hr, manifoldY + mh);
    MainValveArt.pipe(canvas, header, blue: false, seed: 61, u: u, horizontal: true);

    // Header end plates (flanged blind covers)
    MainValveArt.flangeV(canvas, Rect.fromLTRB(hl - fh, manifoldY - mh * 0.3, hl, manifoldY + mh * 1.3), blue: false, joints: showJoints, u: u);
    MainValveArt.flangeV(canvas, Rect.fromLTRB(hr, manifoldY - mh * 0.3, hr + fh, manifoldY + mh * 1.3), blue: false, joints: showJoints, u: u);

    // Centre inlet weld bead above the header
    canvas.drawLine(
      Offset(cxC - p * 0.55, manifoldY),
      Offset(cxC + p * 0.55, manifoldY),
      MainValveArt.stroke(Colors.black.withValues(alpha: 0.4), math.max(1.2, u * 2.2)),
    );

    // 3. Welded necks + flange pairs under the bottom of the header
    final double yNeckTop = manifoldY + mh;
    final double yNeckBottom = yNeckTop + neckH;
    final double yFlBottom = yNeckBottom + fh;
    final double yPipeFlTop = yFlBottom + g;

    for (int i = 0; i < count; i++) {
      final double cx = channelX[i];

      final Rect neck = Rect.fromLTRB(cx - p * 0.55, manifoldY + mh * 0.75, cx + p * 0.55, yNeckBottom);
      MainValveArt.pipe(canvas, neck, blue: false, seed: 71 + i, u: u);
      // weld bead where the neck meets the header
      canvas.drawLine(
        Offset(cx - p * 0.55, yNeckTop),
        Offset(cx + p * 0.55, yNeckTop),
        MainValveArt.stroke(Colors.black.withValues(alpha: 0.4), math.max(1.2, u * 2.2)),
      );

      MainValveArt.flangeH(
        canvas,
        Rect.fromLTRB(cx - fw * 0.46, yNeckBottom, cx + fw * 0.46, yFlBottom),
        blue: false,
        joints: showJoints,
        u: u,
      );
      MainValveArt.gasket(canvas, Rect.fromLTRB(cx - fw * 0.48, yFlBottom, cx + fw * 0.48, yPipeFlTop));
      MainValveArt.flangeH(
        canvas,
        Rect.fromLTRB(cx - fw / 2, yPipeFlTop, cx + fw / 2, yPipeFlTop + fh),
        blue: true,
        joints: showJoints,
        u: u,
      );
    }

    // 4. Blue outlet pipes (behind valves and flanges)
    for (int i = 0; i < count; i++) {
      final double cx = channelX[i];
      MainValveArt.pipe(
        canvas,
        Rect.fromLTRB(cx - p / 2, yPipeFlTop + fh * 0.5, cx + p / 2, h - endH + 1),
        blue: true,
        seed: 11 + i * 5,
        u: u,
      );
    }

    // 5. Gate valves (one per outlet channel)
    for (int i = 0; i < count; i++) {
      final bool active = i < states.length ? states[i] : false;
      TankValveArt.valve(canvas, Offset(channelX[i], valveCy), p, active: active, joints: showJoints);
    }

    // 6. Bolted end flanges: 1 inlet port (top/left) + [count] outlet ports (bottom/right)
    MainValveArt.endFlange(canvas, Offset(cxC, 0), p, top: true, joints: showJoints);
    for (int i = 0; i < count; i++) {
      MainValveArt.endFlange(canvas, Offset(channelX[i], h), p, top: false, joints: showJoints);
    }

    if (isHorizontal) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant DetailedMultiOutletTankValvePainter old) =>
      !listEquals(old.states, states) ||
      old.showJoints != showJoints ||
      old.isHorizontal != isHorizontal;
}

class MultiOutletTankValveView extends StatelessWidget {
  final bool isOn;
  final bool showJoints;
  final bool isHorizontal;
  final Size size;
  final int outletCount;

  const MultiOutletTankValveView({
    super.key,
    required this.isOn,
    this.size = const Size(180, 56),
    this.showJoints = true,
    this.isHorizontal = false,
    this.outletCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: DetailedMultiOutletTankValvePainter(
        states: List.filled(outletCount, isOn),
        showJoints: showJoints,
        isHorizontal: isHorizontal,
      ),
    );
  }
}
