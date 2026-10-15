import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared drawing parts for the single / multi main valve painters.
///
/// Style matches the fertigation tank painter: brushed stainless, blue
/// painted pipework with speckled wear, flanges with bolts and gaskets.
///
/// The valve is a flanged stainless ball valve seen from the side of the line
/// with its stem pointing at the viewer:
///   * lever ALONG the pipe (vertical)   -> valve OPEN  (isOn)
///   * lever ACROSS the pipe (horizontal) -> valve CLOSED
class MainValveArt {
  MainValveArt._();

  // ---------------------------------------------------------------- palette
  static const Color edge = Color(0xFF1E272C);

  static const Color ssDark = Color(0xFF80878A);
  static const Color ssMid = Color(0xFFB9BEC0);
  static const Color ssLight = Color(0xFFE2E5E6);

  static const Color blueLight = Color(0xFF6482C8);
  static const Color blueMid = Color(0xFF3A57A0);
  static const Color blueDark = Color(0xFF243B7C);

  static const Color green = Color(0xFF00E676);
  static const Color rust = Color(0xFF9B5A38);

  // ---------------------------------------------------------------- paints
  static Paint fillH(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(colors: colors, stops: stops, begin: Alignment.centerLeft, end: Alignment.centerRight)
        .createShader(r);

  static Paint fillV(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..isAntiAlias = true
    ..shader = LinearGradient(colors: colors, stops: stops, begin: Alignment.topCenter, end: Alignment.bottomCenter)
        .createShader(r);

  static Paint stroke(Color c, double w) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  static Paint shadow([double a = 0.2]) => Paint()..color = Colors.black.withValues(alpha: a);

  /// Steel shaded across X (vertical cylinder).
  static Paint steelH(Rect r) =>
      fillH(r, const [ssDark, ssLight, ssMid, ssDark], stops: const [0, 0.3, 0.65, 1]);

  /// Steel shaded across Y (horizontal cylinder).
  static Paint steelV(Rect r) =>
      fillV(r, const [ssDark, ssLight, ssMid, ssDark], stops: const [0, 0.3, 0.65, 1]);

  static Paint blueH(Rect r) =>
      fillH(r, const [blueDark, blueLight, blueMid, blueDark], stops: const [0, 0.3, 0.65, 1]);

  static Paint blueV(Rect r) =>
      fillV(r, const [blueDark, blueLight, blueMid, blueDark], stops: const [0, 0.3, 0.65, 1]);

  // --------------------------------------------------------------- helpers

  static void speckle(Canvas canvas, Rect area, int seed, int n, Color c, double u) {
    final math.Random rnd = math.Random(seed);
    for (int i = 0; i < n; i++) {
      final double x = area.left + rnd.nextDouble() * area.width;
      final double y = area.top + rnd.nextDouble() * area.height;
      final double r = (1.5 + rnd.nextDouble() * 5) * u;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: r * 1.7, height: r),
        Paint()..color = c.withValues(alpha: 0.15 + 0.3 * rnd.nextDouble()),
      );
    }
  }

  static void bolt(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFC8CDCF));
    canvas.drawCircle(c, r, stroke(Colors.black.withValues(alpha: 0.5), 0.8));
    canvas.drawCircle(c.translate(-r * 0.3, -r * 0.3), r * 0.35, Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  static Path hexPath(Offset c, double r, double rot) {
    final Path path = Path();
    for (int i = 0; i < 6; i++) {
      final double a = rot + i * math.pi / 3;
      final double px = c.dx + r * math.cos(a);
      final double py = c.dy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  // ----------------------------------------------------------------- pipes

  /// A pipe segment. Vertical by default, [horizontal] for headers.
  static void pipe(
      Canvas canvas,
      Rect r, {
        required bool blue,
        required int seed,
        required double u,
        bool horizontal = false,
      }) {
    final Paint fill = horizontal ? (blue ? blueV(r) : steelV(r)) : (blue ? blueH(r) : steelH(r));
    canvas.drawRect(r, fill);

    canvas.save();
    canvas.clipRect(r);
    final int n = ((r.width * r.height) / (u * u) / 260).clamp(6, 60).toInt();
    if (blue) {
      speckle(canvas, r, seed, n, const Color(0xFFB7C3E6), u);
      speckle(canvas, r, seed + 7, (n / 3).toInt(), rust, u);
    } else {
      speckle(canvas, r, seed, (n / 2).toInt(), const Color(0xFF3C4245), u);
    }
    final Paint hl = stroke(Colors.white.withValues(alpha: 0.18), math.max(1.0, u * 1.6));
    if (horizontal) {
      final double y = r.top + r.height * 0.26;
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), hl);
    } else {
      final double x = r.left + r.width * 0.28;
      canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), hl);
    }
    canvas.restore();
    canvas.drawRect(r, stroke(Colors.black.withValues(alpha: 0.45), 1.0));
  }

  // --------------------------------------------------------------- flanges

  /// Flange seen edge-on on a vertical pipe (wide, short rectangle).
  static void flangeH(Canvas canvas, Rect r, {bool blue = true, bool joints = true, double u = 1}) {
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.3));
    canvas.drawRRect(rr.shift(Offset(u * 1.5, u * 2.2)), shadow(0.18));
    canvas.drawRRect(rr, blue ? blueH(r) : steelH(r));
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(r, fillV(r, [Colors.white.withValues(alpha: 0.22), Colors.transparent, Colors.black.withValues(alpha: 0.18)]));
    canvas.restore();
    canvas.drawRRect(rr, stroke(Colors.black.withValues(alpha: 0.55), 1.1));
    if (joints) {
      for (final double f in [0.12, 0.30, 0.70, 0.88]) {
        bolt(canvas, Offset(r.left + r.width * f, r.center.dy), r.height * 0.24);
      }
    }
  }

  /// Flange seen edge-on on a horizontal pipe (tall, narrow rectangle).
  static void flangeV(Canvas canvas, Rect r, {bool blue = false, bool joints = true, double u = 1}) {
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.3));
    canvas.drawRRect(rr.shift(Offset(u * 1.5, u * 2.2)), shadow(0.18));
    canvas.drawRRect(rr, blue ? blueV(r) : steelV(r));
    canvas.drawRRect(rr, stroke(Colors.black.withValues(alpha: 0.55), 1.1));
    if (joints) {
      for (final double f in [0.14, 0.34, 0.66, 0.86]) {
        bolt(canvas, Offset(r.center.dx, r.top + r.height * f), r.width * 0.24);
      }
    }
  }

  static void gasket(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = const Color(0xFF2A2D30));
    canvas.drawRect(r, stroke(Colors.black.withValues(alpha: 0.6), 0.8));
  }

  /// Height taken by an end flange (blue flange + raised grey face).
  static double endH(double p) => p * 0.3 * 1.22;

  /// Blue end flange with a raised steel face at the very edge of the canvas.
  /// [anchor] is the port point (centre x, outer edge y).
  static void endFlange(Canvas canvas, Offset anchor, double p, {required bool top, bool joints = true}) {
    final double fh = p * 0.3;
    final double fw = p * 2.15;
    final double face = fh * 0.22;
    final Rect faceR = top
        ? Rect.fromLTRB(anchor.dx - fw * 0.34, anchor.dy, anchor.dx + fw * 0.34, anchor.dy + face)
        : Rect.fromLTRB(anchor.dx - fw * 0.34, anchor.dy - face, anchor.dx + fw * 0.34, anchor.dy);
    final Rect fl = top
        ? Rect.fromLTRB(anchor.dx - fw / 2, anchor.dy + face, anchor.dx + fw / 2, anchor.dy + face + fh)
        : Rect.fromLTRB(anchor.dx - fw / 2, anchor.dy - face - fh, anchor.dx + fw / 2, anchor.dy - face);
    flangeH(canvas, fl, blue: true, joints: joints, u: p / 40);
    final RRect fr = RRect.fromRectAndRadius(faceR, Radius.circular(face * 0.4));
    canvas.drawRRect(fr, steelH(faceR));
    canvas.drawRRect(fr, stroke(Colors.black.withValues(alpha: 0.5), 0.9));
  }

  // ------------------------------------------------------------ ball valve

  /// Total half-height of the valve assembly from its centre to the outer
  /// face of its blue pipe flanges.
  static double valveHalfHeight(double p) => p * 1.05 + p * 0.3 * 0.85 + p * 0.05 + p * 0.3;

  /// Flanged stainless ball valve centred at [c]; [p] is the pipe diameter.
  ///
  /// If [inactiveHalo] is given, a soft halo of that colour is drawn while the
  /// valve is closed (e.g. red for main valves).
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

    final double endW = p * 1.45;
    final double bodyH = p * 2.1;
    final double ballR = p * 0.98;
    final double fh = p * 0.3;
    final double fw = p * 2.15;
    final double g = p * 0.05;

    // Status halo
    if (active || inactiveHalo != null) {
      canvas.drawCircle(
        c,
        p * 1.55,
        Paint()
          ..color = (active ? green.withValues(alpha: 0.30) : inactiveHalo!.withValues(alpha: 0.22))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p * 0.5),
      );
    }

    // End connectors (valve body ends)
    final Rect conn = Rect.fromCenter(center: c, width: endW, height: bodyH);
    final RRect rc = RRect.fromRectAndRadius(conn, Radius.circular(p * 0.18));
    canvas.drawRRect(rc.shift(Offset(u * 2, u * 3)), shadow(0.2));
    canvas.drawRRect(rc, steelH(conn));
    canvas.save();
    canvas.clipRRect(rc);
    final math.Random rnd = math.Random(3);
    for (double x = conn.left; x < conn.right; x += math.max(2.0, u * 2.4)) {
      canvas.drawLine(
        Offset(x, conn.top),
        Offset(x, conn.bottom),
        stroke((rnd.nextBool() ? Colors.white : Colors.black).withValues(alpha: 0.04 + 0.03 * rnd.nextDouble()), 1),
      );
    }
    speckle(canvas, conn, 17, 10, const Color(0xFF3C4245), u);
    canvas.restore();
    canvas.drawRRect(rc, stroke(Colors.black.withValues(alpha: 0.5), ew * 1.2));

    // Body / end-connector seams
    for (final double k in [-0.43, 0.43]) {
      final double y = cy + bodyH * k;
      canvas.drawLine(Offset(conn.left, y), Offset(conn.right, y), stroke(Colors.black.withValues(alpha: 0.45), ew * 1.4));
      canvas.drawLine(Offset(conn.left, y + ew * 1.5), Offset(conn.right, y + ew * 1.5), stroke(Colors.white.withValues(alpha: 0.35), ew));
    }

    // Spherical ball body
    final Rect ballRect = Rect.fromCircle(center: c, radius: ballR);
    canvas.drawCircle(c.translate(u * 2, u * 3), ballR, shadow(0.2));
    canvas.drawCircle(
      c,
      ballR,
      Paint()
        ..isAntiAlias = true
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 1.0,
          colors: [ssLight, ssMid, ssDark, Color(0xFF5E666A)],
          stops: [0.0, 0.35, 0.8, 1.0],
        ).createShader(ballRect),
    );
    canvas.drawCircle(c, ballR, stroke(Colors.black.withValues(alpha: 0.55), ew * 1.2));

    // Bonnet boss, packing nut
    final double bossR = p * 0.6;
    final Rect bossRect = Rect.fromCircle(center: c, radius: bossR);
    canvas.drawCircle(c.translate(u * 1, u * 1.6), bossR, shadow(0.2));
    canvas.drawCircle(
      c,
      bossR,
      Paint()
        ..isAntiAlias = true
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.35),
          radius: 1.0,
          colors: [Color(0xFFEFF1F2), ssMid, ssDark],
          stops: [0.0, 0.55, 1.0],
        ).createShader(bossRect),
    );
    canvas.drawCircle(c, bossR, stroke(Colors.black.withValues(alpha: 0.55), ew));
    canvas.drawCircle(c, bossR * 0.82, stroke(Colors.black.withValues(alpha: 0.25), ew));

    final Path nut = hexPath(c, p * 0.34, math.pi / 6);
    canvas.drawPath(nut, fillV(Rect.fromCircle(center: c, radius: p * 0.34), const [ssLight, ssMid, ssDark]));
    canvas.drawPath(nut, stroke(Colors.black.withValues(alpha: 0.55), ew));

    // Body-half bolts around the bonnet
    if (joints) {
      for (int i = 0; i < 4; i++) {
        final double a = math.pi / 4 + i * math.pi / 2;
        bolt(canvas, Offset(cx + math.cos(a) * p * 0.8, cy + math.sin(a) * p * 0.8), p * 0.07);
      }
    }

    // Flange pairs: steel valve flange + gasket + blue pipe flange
    final double topEdge = cy - bodyH / 2;
    final double botEdge = cy + bodyH / 2;

    final Rect vfTop = Rect.fromLTRB(cx - fw * 0.46, topEdge - fh * 0.85, cx + fw * 0.46, topEdge + fh * 0.15);
    final Rect gTop = Rect.fromLTRB(cx - fw * 0.48, vfTop.top - g, cx + fw * 0.48, vfTop.top);
    final Rect pfTop = Rect.fromLTRB(cx - fw / 2, gTop.top - fh, cx + fw / 2, gTop.top);

    final Rect vfBot = Rect.fromLTRB(cx - fw * 0.46, botEdge - fh * 0.15, cx + fw * 0.46, botEdge + fh * 0.85);
    final Rect gBot = Rect.fromLTRB(cx - fw * 0.48, vfBot.bottom, cx + fw * 0.48, vfBot.bottom + g);
    final Rect pfBot = Rect.fromLTRB(cx - fw / 2, gBot.bottom, cx + fw / 2, gBot.bottom + fh);

    flangeH(canvas, vfTop, blue: false, joints: joints, u: u);
    gasket(canvas, gTop);
    flangeH(canvas, pfTop, blue: true, joints: joints, u: u);

    flangeH(canvas, vfBot, blue: false, joints: joints, u: u);
    gasket(canvas, gBot);
    flangeH(canvas, pfBot, blue: true, joints: joints, u: u);

    // Lever handle: along the pipe = open, across the pipe = closed
    final double len = p * 1.35;
    final double tail = p * 0.4;
    final double th = p * 0.2;
    final double gh = p * 0.32;
    final double ang = active ? -math.pi / 2 : 0;

    final Rect bar = Rect.fromLTRB(-tail, -th / 2, len, th / 2);
    final RRect rbar = RRect.fromRectAndRadius(bar, Radius.circular(th * 0.5));

    canvas.save();
    canvas.translate(cx + u * 2.2, cy + u * 3.2);
    canvas.rotate(ang);
    canvas.drawRRect(rbar, shadow(0.28));
    canvas.restore();

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(ang);

    canvas.drawRRect(rbar, fillV(bar, const [blueLight, blueMid, blueDark], stops: const [0, 0.45, 1]));
    canvas.drawRRect(rbar, stroke(Colors.black.withValues(alpha: 0.55), ew));
    canvas.drawLine(
      Offset(-tail * 0.7, -th * 0.22),
      Offset(len * 0.5, -th * 0.22),
      stroke(Colors.white.withValues(alpha: 0.3), ew),
    );

    // Vinyl grip
    final Rect grip = Rect.fromLTRB(len * 0.45, -gh / 2, len, gh / 2);
    final RRect rg = RRect.fromRectAndRadius(grip, Radius.circular(gh * 0.4));
    canvas.drawRRect(rg, fillV(grip, const [Color(0xFF4A5F9A), Color(0xFF22305E), Color(0xFF141C38)]));
    canvas.drawRRect(rg, stroke(Colors.black.withValues(alpha: 0.6), ew));
    for (int i = 1; i <= 4; i++) {
      final double x = grip.left + grip.width * i / 5;
      canvas.drawLine(Offset(x, -gh * 0.4), Offset(x, gh * 0.4), stroke(Colors.black.withValues(alpha: 0.3), ew));
    }
    canvas.drawLine(
      Offset(grip.left + grip.width * 0.08, -gh * 0.26),
      Offset(grip.right - grip.width * 0.08, -gh * 0.26),
      stroke(Colors.white.withValues(alpha: 0.3), ew),
    );

    // Pivot washer + lock nut
    canvas.drawCircle(Offset.zero, p * 0.26, Paint()..color = ssMid);
    canvas.drawCircle(Offset.zero, p * 0.26, stroke(Colors.black.withValues(alpha: 0.55), ew));
    final Path lockNut = hexPath(Offset.zero, p * 0.17, 0);
    canvas.drawPath(lockNut, Paint()..color = ssLight);
    canvas.drawPath(lockNut, stroke(Colors.black.withValues(alpha: 0.55), ew));
    canvas.drawCircle(Offset.zero, p * 0.05, Paint()..color = ssDark);

    canvas.restore();
  }
}
