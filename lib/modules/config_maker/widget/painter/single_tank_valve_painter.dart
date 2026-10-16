import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'tank_valve_parts.dart';
import 'main_valve_parts.dart';

/// Single Tank Valve painter (realistic).
///
/// A vertical or horizontal blue painted pipe line with bolted end flanges and a flanged
/// cast-iron gate valve in the middle (graphite body, bolted bonnet, orange
/// handwheel, gaskets and bolts). See [TankValveArt].
///
/// [isOn] -> valve open: green status ring + green halo.
/// Off    -> valve closed: grey status ring, handwheel turned.
class DetailedSingleTankValvePainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;
  final bool isHorizontal;

  DetailedSingleTankValvePainter({
    required this.isOn,
    this.showJoints = true,
    this.isHorizontal = false,
  });

  static Offset inletPort(Size s, {bool isHorizontal = false}) =>
      isHorizontal ? Offset(0, s.height * 0.5) : Offset(s.width * 0.5, 0);
  static Offset outletPort(Size s, {bool isHorizontal = false}) =>
      isHorizontal ? Offset(s.width, s.height * 0.5) : Offset(s.width * 0.5, s.height);

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
    final double cx = w * 0.5;
    final double cy = h * 0.5;

    // Pipe diameter: limited by width and height
    final double p = math.min(w * 0.2, h * 0.15);
    final double u = p / 40;
    final double endH = MainValveArt.endH(p);

    // 1. Blue pipe running through the valve
    final Rect pipe = Rect.fromLTRB(cx - p / 2, endH - 1, cx + p / 2, h - endH + 1);
    MainValveArt.pipe(canvas, pipe, blue: true, seed: 5, u: u);

    // 2. Gate valve with its flange pairs, gaskets and handwheel
    TankValveArt.valve(canvas, Offset(cx, cy), p, active: isOn, joints: showJoints);

    // 3. Bolted end flanges at the inlet (top/left) and outlet (bottom/right) ports
    MainValveArt.endFlange(canvas, Offset(cx, 0), p, top: true, joints: showJoints);
    MainValveArt.endFlange(canvas, Offset(cx, h), p, top: false, joints: showJoints);

    if (isHorizontal) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant DetailedSingleTankValvePainter old) =>
      old.isOn != isOn || old.showJoints != showJoints || old.isHorizontal != isHorizontal;
}

class SingleTankValveView extends StatelessWidget {
  final bool isOn;
  final bool showJoints;
  final bool isHorizontal;
  final Size size;

  const SingleTankValveView({
    super.key,
    required this.isOn,
    this.size = const Size(56, 56),
    this.showJoints = true,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: DetailedSingleTankValvePainter(
        isOn: isOn,
        showJoints: showJoints,
        isHorizontal: isHorizontal,
      ),
    );
  }
}
