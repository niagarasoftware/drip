import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'tank_valve_parts.dart';
import 'main_valve_parts.dart';

/// Single Tank Valve painter (realistic).
///
/// A vertical blue painted pipe line with bolted end flanges and a flanged
/// cast-iron gate valve in the middle (graphite body, bolted bonnet, orange
/// handwheel, gaskets and bolts). See [TankValveArt].
///
/// [isOn] -> valve open: green status ring + green halo.
/// Off    -> valve closed: grey status ring, handwheel turned.
class DetailedSingleTankValvePainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;

  DetailedSingleTankValvePainter({
    required this.isOn,
    this.showJoints = true,
  });

  static Offset inletPort(Size s) => Offset(s.width * 0.5, 0);
  static Offset outletPort(Size s) => Offset(s.width * 0.5, s.height);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w * 0.5;
    final double cy = h * 0.5;

    // Pipe diameter: limited by width (lever reach) and height (valve stack)
    final double p = math.min(w * 0.2, h * 0.15);
    final double u = p / 40;
    final double endH = MainValveArt.endH(p);

    // 1. Blue pipe running through the valve
    final Rect pipe = Rect.fromLTRB(cx - p / 2, endH - 1, cx + p / 2, h - endH + 1);
    MainValveArt.pipe(canvas, pipe, blue: true, seed: 5, u: u);

    // 2. Gate valve with its flange pairs, gaskets and handwheel
    TankValveArt.valve(canvas, Offset(cx, cy), p, active: isOn, joints: showJoints);

    // 3. Bolted end flanges at the inlet (top) and outlet (bottom) ports
    MainValveArt.endFlange(canvas, Offset(cx, 0), p, top: true, joints: showJoints);
    MainValveArt.endFlange(canvas, Offset(cx, h), p, top: false, joints: showJoints);
  }

  @override
  bool shouldRepaint(covariant DetailedSingleTankValvePainter old) =>
      old.isOn != isOn || old.showJoints != showJoints;
}

class SingleTankValveView extends StatelessWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  const SingleTankValveView({
    super.key,
    required this.isOn,
    this.size = const Size(120, 120),
    this.showJoints = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: DetailedSingleTankValvePainter(
        isOn: isOn,
        showJoints: showJoints,
      ),
    );
  }
}