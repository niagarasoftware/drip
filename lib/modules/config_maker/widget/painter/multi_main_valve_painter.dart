import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'main_valve_parts.dart';

/// Multi Main Valve Bank / Manifold painter (realistic).
///
/// Uses the same flanged stainless ball valve as the tank valves: spherical
/// body, bonnet, blue lever with vinyl grip, gaskets and bolted flanges.
///
/// * 1 valve  -> a single blue line with a ball valve and bolted end flanges.
/// * 2+ valves -> a stainless inlet header at the top and a collector header at
///   the bottom, joined by blue channels (one ball valve each) through welded
///   necks and bolted flange pairs, with a centre inlet and centre outlet.
///
/// Valve open  (true):  lever along the pipe + green halo.
/// Valve closed (false): lever across the pipe + soft red halo.
class DetailedMultiMainValvePainter extends CustomPainter {
  final List<bool> valves;
  final bool showJoints;

  /// Pipe diameter in logical pixels (limited so the parts never overlap).
  final double? pipeThickness;
  final bool isHorizontal;

  DetailedMultiMainValvePainter({
    required this.valves,
    this.showJoints = true,
    this.pipeThickness,
    this.isHorizontal = false,
  });

  // Ports
  static Offset inletPort(Size s) => Offset(s.width * 0.5, 0);
  static Offset outletPort(Size s) => Offset(s.width * 0.5, s.height);

  static const Color _closedHalo = Color(0xFFE53935);

  /// Vertical budget in units of the pipe diameter [p].
  /// 11.44p is the minimum (no blue channel pipe visible); 14.5p leaves a
  /// clean, balanced blue run between each neck flange and the valve flange.
  static const double kHeightUnits = 14.5;

  /// Canvas height that fits pipe diameter [p] comfortably.
  static double recommendedHeight(double p) => p * kHeightUnits;

  @override
  void paint(Canvas canvas, Size size) {
    if (isHorizontal) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(-math.pi / 2);
      canvas.translate(-size.height / 2, -size.width / 2);
      _paintBody(canvas, Size(size.height, size.width));
      canvas.restore();
      return;
    }
    _paintBody(canvas, size);
  }

  void _paintBody(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final int n = valves.isEmpty ? 4 : valves.length;

    if (n == 1) {
      _paintSingle(canvas, size);
      return;
    }

    final double step = w / n;
    final List<double> channelX = List.generate(n, (i) => step * i + step / 2);

    // Pipe diameter: user value or default, capped by width and by the
    // height the whole stack needs.
    final double p = math.max(
      6.0,
      math.min(
        pipeThickness ?? step * 0.34,
        math.min(step * 0.40, h / kHeightUnits),
      ),
    );
    final double u = p / 40;
    final double fh = p * 0.3;
    final double g = p * 0.05;
    final double mh = p * 1.35; // header diameter
    final double neckH = p * 0.45;
    final double stack = neckH + fh + g + fh; // neck + flange pair
    final double endH = MainValveArt.endH(p);
    final double stub = p * 0.9; // visible steel stub between end flange and header

    // Headers hang from the edges, so spare height lengthens the blue channels
    final double yTop = endH + g + fh + stub; // top header top edge
    final double manifoldY = h - yTop - mh; // bottom header top edge
    final double valveCy = (yTop + mh + manifoldY) / 2;
    final double cxC = w * 0.5;

    final double headerLeft = math.max(fh + 2, channelX.first - p * 1.3);
    final double headerRight = math.min(w - fh - 2, channelX.last + p * 1.3);

    // 1. Centre inlet (top) and outlet (bottom) stubs
    _port(canvas, cxC, yTop + mh * 0.5, h, p, top: true);
    _port(canvas, cxC, manifoldY + mh * 0.5, h, p, top: false);

    // 2. Blue channel pipes (behind valves and flanges)
    final double topFar = yTop + mh + stack;
    final double botFar = manifoldY - stack;
    for (int i = 0; i < n; i++) {
      final double cx = channelX[i];
      MainValveArt.pipe(
        canvas,
        Rect.fromLTRB(cx - p / 2, topFar - fh * 0.5, cx + p / 2, botFar + fh * 0.5),
        blue: true,
        seed: 11 + i * 5,
        u: u,
      );
    }

    // 3. Horizontal stainless headers with flanged end plates
    for (final double y in [yTop, manifoldY]) {
      MainValveArt.pipe(
        canvas,
        Rect.fromLTRB(headerLeft, y, headerRight, y + mh),
        blue: false,
        seed: y > yTop ? 61 : 63,
        u: u,
        horizontal: true,
      );
      MainValveArt.flangeV(
        canvas,
        Rect.fromLTRB(headerLeft - fh, y - mh * 0.3, headerLeft, y + mh * 1.3),
        blue: false,
        joints: showJoints,
        u: u,
      );
      MainValveArt.flangeV(
        canvas,
        Rect.fromLTRB(headerRight, y - mh * 0.3, headerRight + fh, y + mh * 1.3),
        blue: false,
        joints: showJoints,
        u: u,
      );
    }

    // 4. Welded necks + flange pairs on both headers
    for (int i = 0; i < n; i++) {
      _neck(canvas, channelX[i], yTop + mh, p, down: true, seed: 71 + i);
      _neck(canvas, channelX[i], manifoldY, p, down: false, seed: 91 + i);
    }

    // 5. Ball valves (one per channel)
    for (int i = 0; i < n; i++) {
      final bool active = i < valves.length ? valves[i] : true;
      MainValveArt.valve(
        canvas,
        Offset(channelX[i], valveCy),
        p,
        active: active,
        joints: showJoints,
        inactiveHalo: _closedHalo,
      );
    }

    // 6. Bolted end flanges at the inlet and outlet ports
    MainValveArt.endFlange(canvas, Offset(cxC, 0), p, top: true, joints: showJoints);
    MainValveArt.endFlange(canvas, Offset(cxC, h), p, top: false, joints: showJoints);
  }

  /// One valve on a straight line (n == 1).
  void _paintSingle(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w * 0.5;
    final bool active = valves.isNotEmpty ? valves[0] : true;

    final double p = math.max(
      6.0,
      math.min(pipeThickness ?? w * 0.2, math.min(w * 0.2, h * 0.15)),
    );
    final double u = p / 40;
    final double endH = MainValveArt.endH(p);

    MainValveArt.pipe(
      canvas,
      Rect.fromLTRB(cx - p / 2, endH - 1, cx + p / 2, h - endH + 1),
      blue: true,
      seed: 5,
      u: u,
    );
    MainValveArt.valve(
      canvas,
      Offset(cx, h * 0.5),
      p,
      active: active,
      joints: showJoints,
      inactiveHalo: _closedHalo,
    );
    MainValveArt.endFlange(canvas, Offset(cx, 0), p, top: true, joints: showJoints);
    MainValveArt.endFlange(canvas, Offset(cx, h), p, top: false, joints: showJoints);
  }

  /// Steel pipe stub between a port flange and a header. [headerMidY] is the
  /// centre line of the header it joins; [canvasH] is the canvas height (the
  /// bottom port sits on the bottom edge).
  void _port(Canvas canvas, double cx, double headerMidY, double canvasH, double p,
      {required bool top}) {
    final double u = p / 40;
    final double fh = p * 0.3;
    final double fw = p * 2.15;
    final double g = p * 0.05;
    final double endH = MainValveArt.endH(p);

    // Distances from the canvas edge: blue end flange, gasket, steel flange
    final double e0 = top ? endH : canvasH - endH; // inner face of end flange
    final double s = top ? 1 : -1;
    final double g1 = e0 + s * g;
    final double f1 = g1 + s * fh;

    Rect span(double halfW, double y0, double y1) =>
        Rect.fromLTRB(cx - halfW, math.min(y0, y1), cx + halfW, math.max(y0, y1));

    MainValveArt.pipe(canvas, span(p * 0.55, f1 - s, headerMidY), blue: false, seed: top ? 41 : 43, u: u);
    MainValveArt.flangeH(canvas, span(fw * 0.46, g1, f1), blue: false, joints: showJoints, u: u);
    MainValveArt.gasket(canvas, span(fw * 0.48, e0, g1));
  }

  /// Welded neck on a header with a steel flange, gasket and blue pipe flange.
  /// [edgeY] is the header edge the neck leaves from; [down] picks the side.
  void _neck(Canvas canvas, double cx, double edgeY, double p,
      {required bool down, required int seed}) {
    final double u = p / 40;
    final double fh = p * 0.3;
    final double fw = p * 2.15;
    final double g = p * 0.05;
    final double neckH = p * 0.45;
    final double s = down ? 1 : -1;

    Rect span(double halfW, double y0, double y1) =>
        Rect.fromLTRB(cx - halfW, math.min(y0, y1), cx + halfW, math.max(y0, y1));

    final double inside = edgeY - s * p * 1.35 * 0.25;
    final double b = edgeY + s * neckH;
    MainValveArt.pipe(canvas, span(p * 0.55, inside, b), blue: false, seed: seed, u: u);

    // weld bead where the neck meets the header
    canvas.drawLine(
      Offset(cx - p * 0.55, edgeY),
      Offset(cx + p * 0.55, edgeY),
      MainValveArt.stroke(Colors.black.withValues(alpha: 0.4), math.max(1.2, u * 2.2)),
    );

    final double f1 = b + s * fh;
    final double g1 = f1 + s * g;
    final double p1 = g1 + s * fh;
    MainValveArt.flangeH(canvas, span(fw * 0.46, b, f1), blue: false, joints: showJoints, u: u);
    MainValveArt.gasket(canvas, span(fw * 0.48, f1, g1));
    MainValveArt.flangeH(canvas, span(fw / 2, g1, p1), blue: true, joints: showJoints, u: u);
  }

  @override
  bool shouldRepaint(covariant DetailedMultiMainValvePainter old) =>
      !listEquals(old.valves, valves) ||
          old.showJoints != showJoints ||
          old.pipeThickness != pipeThickness ||
          old.isHorizontal != isHorizontal;
}

/// Widget wrapper for [DetailedMultiMainValvePainter].
class MultiMainValveView extends StatelessWidget {
  final List<bool> states;
  final bool showJoints;
  final Size size;
  final double? pipeThickness;

  const MultiMainValveView({
    super.key,
    required this.states,
    this.size = const Size(220, 200),
    this.showJoints = true,
    this.pipeThickness,
  });

  /// Inlet connection port location (top center)
  static Offset inletPort(Size s) => DetailedMultiMainValvePainter.inletPort(s);

  /// Outlet connection port location (bottom center)
  static Offset outletPort(Size s) => DetailedMultiMainValvePainter.outletPort(s);

  MultiMainValveView.single({
    Key? key,
    required bool isOn,
    Size size = const Size(160, 180),
    bool showJoints = true,
    double? pipeThickness,
  }) : this(
    key: key,
    states: [isOn],
    size: size,
    showJoints: showJoints,
    pipeThickness: pipeThickness,
  );

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: DetailedMultiMainValvePainter(
        valves: states,
        showJoints: showJoints,
        pipeThickness: pipeThickness,
      ),
    );
  }
}

// Aliases for backwards compatibility
typedef DetailedMainValvePainter = DetailedMultiMainValvePainter;
typedef MainValveView = MultiMainValveView;