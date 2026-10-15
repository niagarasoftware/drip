import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'main_valve_parts.dart';

/// Single Main Valve painter (realistic).
///
/// A vertical blue painted pipe line with bolted end flanges and a flanged
/// stainless ball valve in the middle (spherical body, bonnet, packing nut,
/// blue lever with vinyl grip, gaskets and bolts).
///
/// [isOn] -> valve open: lever lies ALONG the pipe and a green halo shows.
/// Off    -> valve closed: lever lies ACROSS the pipe.
class DetailedSingleMainValvePainter extends CustomPainter {
  final bool isOn;
  final bool showJoints;

  DetailedSingleMainValvePainter({
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

    // 2. Ball valve with its flange pairs, gaskets and lever
    MainValveArt.valve(canvas, Offset(cx, cy), p, active: isOn, joints: showJoints);

    // 3. Bolted end flanges at the inlet (top) and outlet (bottom) ports
    MainValveArt.endFlange(canvas, Offset(cx, 0), p, top: true, joints: showJoints);
    MainValveArt.endFlange(canvas, Offset(cx, h), p, top: false, joints: showJoints);
  }

  @override
  bool shouldRepaint(covariant DetailedSingleMainValvePainter old) =>
      old.isOn != isOn || old.showJoints != showJoints;
}

/// Widget wrapper for [DetailedSingleMainValvePainter].
class SingleMainValveView extends StatelessWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  const SingleMainValveView({
    super.key,
    required this.isOn,
    this.size = const Size(160, 120),
    this.showJoints = true,
  });

  /// Inlet connection port location (top center)
  static Offset inletPort(Size s) => DetailedSingleMainValvePainter.inletPort(s);

  /// Outlet connection port location (bottom center)
  static Offset outletPort(Size s) => DetailedSingleMainValvePainter.outletPort(s);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: DetailedSingleMainValvePainter(
        isOn: isOn,
        showJoints: showJoints,
      ),
    );
  }
}
