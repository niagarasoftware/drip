import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Green motor + pump assembly on a dark skid and concrete plinth.
///
/// Realism pass: multi-stop metallic-paint gradients, key light from the
/// top-left, specular streaks, edge (rim) occlusion, contact shadows, bounce
/// light from the plinth, glossy reflection panel, tube-shaded conduit and a
/// speckled concrete base. Background is transparent.
///
/// [isOn]  - running state: saturated green, breathing halo and a light
///           shimmer sweeping across the cooling fins.
/// [phase] - radians; drives the halo pulse and shimmer.
class DetailedPumpPainter extends CustomPainter {
  final bool isOn;
  final double phase;
  final bool showJoints;

  DetailedPumpPainter({
    required this.isOn,
    this.phase = 0,
    this.showJoints = true,
  });

  // Virtual drawing space; everything is authored in these units and scaled.
  static const double _vw = 640;
  static const double _vh = 380;

  // ---------------------------------------------------------------- palette
  Color get _castHi => isOn ? const Color(0xFFD6FFD6) : const Color(0xFFE6ECE0);
  Color get _castLight => isOn ? const Color(0xFF6FDB70) : const Color(0xFFB9C6B2);
  Color get _castMid => isOn ? const Color(0xFF23A329) : const Color(0xFF7C8A6E);
  Color get _castDark => isOn ? const Color(0xFF127218) : const Color(0xFF4B5740);
  Color get _castDeep => isOn ? const Color(0xFF07400C) : const Color(0xFF262E1E);
  Color get _spec => Color.lerp(_castLight, _castHi, 0.65)!;

  static const Color _accentGlow = Color(0xFF4CFF8F);
  static const Color _edge = Color(0xFF042808);

  static const Color _steelLight = Color(0xFFF4F7F8);
  static const Color _steelMid = Color(0xFFA7B2B9);
  static const Color _steelDark = Color(0xFF3F494F);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width / _vw, size.height / _vh);
    canvas.save();
    canvas.translate((size.width - _vw * s) / 2, (size.height - _vh * s) / 2);
    canvas.scale(s);

    if (isOn) _halo(canvas);
    _plinth(canvas);
    _skid(canvas);
    _feet(canvas);
    _motor(canvas);
    _terminalCap(canvas);
    _middleHousing(canvas);
    _junctionBox(canvas);
    _lantern(canvas);
    _volute(canvas);
    _conduit(canvas);
    _neckAndFlange(canvas);

    canvas.restore();
  }

  // ------------------------------------------------------------- primitives

  Paint _lin(Rect r, List<Color> colors,
      {List<double>? stops, bool horizontal = false}) {
    return Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: colors,
        stops: stops,
        begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
        end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
      ).createShader(r);
  }

  Paint _stroke(Color c, [double w = 1.1]) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  Paint _blur(Color c, double sigma) => Paint()
    ..isAntiAlias = true
    ..color = c
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

  /// Horizontal-axis cylinder: key light high, bounce light at the bottom.
  Paint _cylH(Rect r) => _lin(
    r,
    [_castMid, _castLight, _spec, _castMid, _castDark, _castDeep, _castDark],
    stops: const [0.0, 0.1, 0.19, 0.4, 0.68, 0.9, 1.0],
  );

  /// Vertical-axis cylinder: key light from the left.
  Paint _cylV(Rect r) => _lin(
    r,
    [_castDark, _castMid, _castLight, _spec, _castMid, _castDark, _castDeep],
    stops: const [0.0, 0.08, 0.18, 0.27, 0.5, 0.78, 1.0],
    horizontal: true,
  );

  Paint _steel(Rect r, {bool horizontal = false}) => _lin(
    r,
    const [_steelLight, _steelMid, _steelDark],
    stops: const [0.0, 0.5, 1.0],
    horizontal: horizontal,
  );

  /// Darkens the inside of a shape's edge (ambient occlusion on the rim).
  void _rim(Canvas cv, RRect rr, {double w = 9, double alpha = 0.38, double sigma = 4}) {
    cv.save();
    cv.clipRRect(rr);
    cv.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = Color.fromRGBO(0, 18, 5, alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
    );
    cv.restore();
  }

  /// Darkens left and right ends of a shape.
  void _sideShade(Canvas cv, RRect rr, {double a = 0.32, double edge = 0.12}) {
    cv.save();
    cv.clipRRect(rr);
    final Rect r = rr.outerRect;
    cv.drawRect(
      r,
      _lin(
        r,
        [
          Color.fromRGBO(0, 15, 4, a),
          const Color.fromRGBO(0, 15, 4, 0),
          const Color.fromRGBO(0, 15, 4, 0),
          Color.fromRGBO(0, 15, 4, a * 1.25),
        ],
        stops: [0.0, edge, 1 - edge, 1.0],
        horizontal: true,
      ),
    );
    cv.restore();
  }

  /// Soft specular streak. [alongX] true = long axis horizontal.
  void _streak(Canvas cv, Rect r, {required bool alongX, double alpha = 0.55, double sigma = 2.0}) {
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(math.min(r.width, r.height) / 2));
    cv.drawRRect(
      rr,
      Paint()
        ..isAntiAlias = true
        ..shader = LinearGradient(
          colors: [
            const Color.fromRGBO(255, 255, 255, 0),
            Color.fromRGBO(255, 255, 255, alpha),
            Color.fromRGBO(255, 255, 255, alpha * 0.6),
            const Color.fromRGBO(255, 255, 255, 0),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
          begin: alongX ? Alignment.centerLeft : Alignment.topCenter,
          end: alongX ? Alignment.centerRight : Alignment.bottomCenter,
        ).createShader(r)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
    );
  }

  /// Painted cast part: drop shadow, gradient, rim occlusion, outline.
  void _castPart(Canvas cv, RRect rr, Paint fill, {double shadow = 5, bool sides = true}) {
    cv.drawRRect(rr.shift(Offset(0, shadow * 0.8)), _blur(const Color(0x4D000000), shadow));
    cv.drawRRect(rr, fill);
    if (sides) _sideShade(cv, rr);
    _rim(cv, rr);
    cv.drawRRect(rr, _stroke(_edge, 1.2));
  }

  void _bolt(Canvas cv, Offset p, double r) {
    final Rect rect = Rect.fromCircle(center: p, radius: r);
    cv.drawCircle(p + Offset(0, r * 0.4), r * 1.05, Paint()..color = const Color(0x66000000));
    cv.drawCircle(
      p,
      r,
      Paint()
        ..isAntiAlias = true
        ..shader = const LinearGradient(
          colors: [_steelLight, _steelMid, _steelDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    cv.drawCircle(p, r * 0.44, Paint()..color = const Color(0xFF2E373C));
    cv.drawCircle(p + Offset(-r * 0.12, -r * 0.12), r * 0.2, Paint()..color = const Color(0x55FFFFFF));
  }

  // ------------------------------------------------------------ environment

  void _halo(Canvas cv) {
    final double breathe = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(phase));
    cv.drawOval(
      Rect.fromCenter(
          center: const Offset(320, 190),
          width: 600 + 20 * breathe,
          height: 250 + 14 * breathe),
      _blur(_accentGlow.withValues(alpha: 0.20 * breathe), 34),
    );
  }

  void _plinth(Canvas cv) {
    const Rect top = Rect.fromLTRB(7, 317, 548, 325);
    const Rect front = Rect.fromLTRB(7, 325, 548, 368);

    cv.drawRect(front.shift(const Offset(0, 5)), _blur(const Color(0x40000000), 5));
    cv.drawRect(
      front,
      _lin(front, const [Color(0xFFDADADA), Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
          stops: const [0.0, 0.55, 1.0]),
    );
    cv.drawRect(
      top,
      _lin(top, const [Color(0xFFFAFAFA), Color(0xFFE2E2E2)]),
    );

    // Aggregate speckle (deterministic).
    final math.Random rnd = math.Random(7);
    for (int i = 0; i < 170; i++) {
      final double x = 10 + rnd.nextDouble() * 535;
      final bool onFront = rnd.nextDouble() > 0.15;
      final double y = onFront ? 327 + rnd.nextDouble() * 38 : 318 + rnd.nextDouble() * 6;
      cv.drawCircle(
        Offset(x, y),
        0.5 + rnd.nextDouble() * 0.9,
        Paint()..color = rnd.nextBool() ? const Color(0x22000000) : const Color(0x44FFFFFF),
      );
    }

    // End darkening and bottom contact line.
    cv.drawRect(
      front,
      _lin(
        front,
        const [Color(0x30000000), Color(0x00000000), Color(0x00000000), Color(0x38000000)],
        stops: const [0.0, 0.06, 0.94, 1.0],
        horizontal: true,
      ),
    );
    cv.drawLine(const Offset(7, 325), const Offset(548, 325),
        Paint()..color = const Color(0x44000000)..strokeWidth = 1.2);
    cv.drawLine(const Offset(8, 317.6), const Offset(547, 317.6),
        Paint()..color = const Color(0xCCFFFFFF)..strokeWidth = 1.1);
    cv.drawRect(const Rect.fromLTRB(7, 317, 548, 368), _stroke(const Color(0xFF9A9A9A), 0.9));

    // Skid shadow cast on the plinth.
    cv.drawRect(const Rect.fromLTRB(60, 322, 496, 334), _blur(const Color(0x55000000), 4));
  }

  void _skid(Canvas cv) {
    const Rect topStrip = Rect.fromLTRB(52, 295, 502, 302);
    const Rect front = Rect.fromLTRB(52, 302, 502, 323);

    cv.drawRect(front, _lin(front, const [Color(0xFF4A5258), Color(0xFF30363B), Color(0xFF1F2428)],
        stops: const [0.0, 0.5, 1.0]));
    cv.drawRect(topStrip, _lin(topStrip, const [Color(0xFFB4BDC2), Color(0xFF6B757B)]));
    cv.drawLine(const Offset(53, 302.6), const Offset(501, 302.6),
        Paint()..color = const Color(0x55FFFFFF)..strokeWidth = 1);
    // Soft sheen along the front.
    _streak(cv, const Rect.fromLTRB(70, 305, 480, 309), alongX: true, alpha: 0.18, sigma: 1.5);
    // Rounded end shading.
    cv.drawRect(
      const Rect.fromLTRB(52, 295, 502, 323),
      _lin(const Rect.fromLTRB(52, 295, 502, 323),
          const [Color(0x55000000), Color(0x00000000), Color(0x00000000), Color(0x55000000)],
          stops: const [0.0, 0.04, 0.96, 1.0], horizontal: true),
    );
    cv.drawRect(const Rect.fromLTRB(52, 295, 502, 323), _stroke(const Color(0xFF111518), 1.0));

    // Green bounce light thrown on the skid by the painted feet.
    for (final List<double> f in const [
      [88, 227],
      [305, 377],
      [415, 490],
    ]) {
      cv.drawRect(Rect.fromLTRB(f[0], 295, f[1], 300), _blur(_castMid.withValues(alpha: isOn ? 0.45 : 0.25), 3));
    }
    if (showJoints) _bolt(cv, const Offset(130, 299), 2.4);
  }

  void _foot(Canvas cv, double x0, double x1, double topY) {
    final Path foot = Path()
      ..moveTo(x0 + 8, topY)
      ..lineTo(x1 - 8, topY)
      ..lineTo(x1, 286)
      ..lineTo(x0, 286)
      ..close();
    final Rect b = foot.getBounds();
    cv.drawPath(foot.shift(const Offset(0, 3)), _blur(const Color(0x59000000), 3));
    cv.drawPath(
      foot,
      _lin(b, [_castDark, _castLight, _castMid, _castDeep], stops: const [0.0, 0.2, 0.55, 1.0], horizontal: true),
    );
    cv.drawPath(
      foot,
      _lin(b, const [Color(0x66000000), Color(0x00000000), Color(0x30000000)], stops: const [0.0, 0.5, 1.0]),
    );
    cv.drawPath(foot, _stroke(_edge));

    final Rect base = Rect.fromLTRB(x0 - 5, 285, x1 + 5, 295);
    final RRect br = RRect.fromRectAndRadius(base, const Radius.circular(1.5));
    cv.drawRRect(br, _cylH(base));
    cv.drawRRect(br, _stroke(_edge));
    cv.drawLine(Offset(x0 - 3, 286.2), Offset(x1 + 3, 286.2),
        Paint()..color = const Color(0x77FFFFFF)..strokeWidth = 0.9);
    if (showJoints) {
      _bolt(cv, Offset(x0 + 2, 290), 2.2);
      _bolt(cv, Offset(x1 - 2, 290), 2.2);
    }
  }

  void _feet(Canvas cv) {
    _foot(cv, 93, 160, 248);
    _foot(cv, 165, 222, 248);
    _foot(cv, 310, 372, 245);
    _foot(cv, 420, 485, 248);
  }

  // ------------------------------------------------------------------ motor

  void _motor(Canvas cv) {
    const Rect shellR = Rect.fromLTRB(95, 107, 266, 257);
    final RRect shell = RRect.fromRectAndRadius(shellR, const Radius.circular(6));
    _castPart(cv, shell, _cylH(shellR), shadow: 6);
    // Bright ledge above the fins.
    _streak(cv, const Rect.fromLTRB(112, 110, 258, 117), alongX: true, alpha: 0.6);

    // Finned panel.
    const Rect panel = Rect.fromLTRB(110, 127, 262, 237);
    cv.save();
    cv.clipRect(panel);
    cv.drawRect(panel, Paint()..color = _castDeep);
    const int n = 11;
    final double step = panel.height / n;
    for (int i = 0; i < n; i++) {
      final Rect ridge = Rect.fromLTWH(panel.left, panel.top + i * step + 1.4, panel.width, step - 3.4);
      cv.drawRect(
        ridge,
        _lin(ridge, [_spec, _castLight, _castMid, _castDark, _castDeep],
            stops: const [0.0, 0.16, 0.45, 0.8, 1.0]),
      );
      cv.drawLine(Offset(ridge.left, ridge.top + 0.5), Offset(ridge.right, ridge.top + 0.5),
          Paint()..color = const Color(0x77FFFFFF)..strokeWidth = 0.8);
      // Shadow cast into the groove below each ridge.
      final Rect gap = Rect.fromLTWH(panel.left, ridge.bottom, panel.width, 2.4);
      cv.drawRect(gap, _lin(gap, const [Color(0xAA000000), Color(0x00000000)]));
    }
    // Panel-wide lighting: lit from above, dark at the ends and bottom.
    cv.drawRect(
      panel,
      _lin(panel, const [Color(0x2EFFFFFF), Color(0x00000000), Color(0x00000000), Color(0x59000000)],
          stops: const [0.0, 0.25, 0.65, 1.0]),
    );
    cv.drawRect(
      panel,
      _lin(panel, const [Color(0x70000000), Color(0x00000000), Color(0x00000000), Color(0x73000000)],
          stops: const [0.0, 0.07, 0.93, 1.0], horizontal: true),
    );
    // Cast shadow from the ledge.
    cv.drawRect(const Rect.fromLTRB(110, 127, 262, 134),
        _lin(const Rect.fromLTRB(110, 127, 262, 134), const [Color(0x99000000), Color(0x00000000)]));
    if (isOn) _finShimmer(cv, panel);
    cv.restore();
    cv.drawRect(panel, _stroke(_edge, 1.0));

    // Rounded end cap.
    const Rect capR = Rect.fromLTRB(38, 95, 120, 257);
    final RRect cap = RRect.fromRectAndCorners(
      capR,
      topLeft: const Radius.circular(40),
      bottomLeft: const Radius.circular(40),
      topRight: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
    );
    cv.drawRRect(cap.shift(const Offset(0, 4)), _blur(const Color(0x59000000), 5));
    cv.drawRRect(
      cap,
      Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.6),
          radius: 1.25,
          colors: [_castHi, _castLight, _castMid, _castDark, _castDeep],
          stops: const [0.0, 0.18, 0.45, 0.8, 1.0],
        ).createShader(capR),
    );
    // Vertical key-light band down the curve and a top glint.
    _streak(cv, const Rect.fromLTRB(47, 122, 56, 232), alongX: false, alpha: 0.5, sigma: 2.4);
    _streak(cv, const Rect.fromLTRB(60, 100, 104, 106), alongX: true, alpha: 0.55);
    _rim(cv, cap, w: 12, alpha: 0.42, sigma: 5);

    // Bevelled inner ring.
    final RRect inner = RRect.fromRectAndCorners(
      const Rect.fromLTRB(48, 104, 112, 248),
      topLeft: const Radius.circular(32),
      bottomLeft: const Radius.circular(32),
      topRight: const Radius.circular(6),
      bottomRight: const Radius.circular(6),
    );
    cv.drawRRect(inner.shift(const Offset(0.9, 0.9)), _stroke(const Color(0x66000000), 1.3));
    cv.drawRRect(inner.shift(const Offset(-0.7, -0.7)), _stroke(const Color(0x66FFFFFF), 1.1));
    cv.drawRRect(cap, _stroke(_edge, 1.3));
    if (showJoints) {
      _bolt(cv, const Offset(100, 116), 2.6);
      _bolt(cv, const Offset(100, 238), 2.6);
    }
  }

  void _terminalCap(Canvas cv) {
    const Rect neck = Rect.fromLTRB(113, 80, 222, 112);
    cv.drawRect(neck, _lin(neck, [_castMid, _castDark, _castDeep]));
    cv.drawRect(
      neck,
      _lin(neck, const [Color(0x66000000), Color(0x00000000), Color(0x55000000)],
          stops: const [0.0, 0.5, 1.0], horizontal: true),
    );
    cv.drawRect(neck, _stroke(_edge, 1.0));
    // Occlusion under the lip.
    cv.drawRect(const Rect.fromLTRB(113, 80, 222, 90),
        _lin(const Rect.fromLTRB(113, 80, 222, 90), const [Color(0x99000000), Color(0x00000000)]));

    const Rect lipR = Rect.fromLTRB(107, 57, 228, 82);
    final RRect lip = RRect.fromRectAndRadius(lipR, const Radius.circular(6));
    _castPart(cv, lip, _cylH(lipR), shadow: 3);
    _streak(cv, const Rect.fromLTRB(116, 59, 220, 63), alongX: true, alpha: 0.7, sigma: 1.4);

    // Recessed top with inset shadow.
    const Rect top = Rect.fromLTRB(118, 63, 217, 72);
    final RRect tr = RRect.fromRectAndRadius(top, const Radius.circular(3));
    cv.drawRRect(tr, _lin(top, [_castDeep, _castDark, _castMid]));
    cv.drawLine(const Offset(119, 73), const Offset(216, 73),
        Paint()..color = const Color(0x77FFFFFF)..strokeWidth = 0.9);
    cv.drawLine(const Offset(109, 79.5), const Offset(226, 79.5),
        Paint()..color = const Color(0x66000000)..strokeWidth = 1.2);
  }

  // ---------------------------------------------------------- middle housing

  void _middleHousing(Canvas cv) {
    const Rect neck = Rect.fromLTRB(275, 70, 370, 102);
    cv.drawRect(neck, _cylV(neck));
    cv.drawRect(neck, _stroke(_edge, 1.0));

    const Rect bodyR = Rect.fromLTRB(265, 97, 378, 262);
    final RRect body = RRect.fromRectAndRadius(bodyR, const Radius.circular(16));
    _castPart(cv, body, _cylH(bodyR), shadow: 7);

    // Bounce light from the plinth near the bottom.
    cv.save();
    cv.clipRRect(body);
    const Rect lower = Rect.fromLTRB(265, 195, 378, 262);
    cv.drawRect(lower, _lin(lower, [const Color(0x00FFFFFF), _castLight.withValues(alpha: 0.28)]));
    cv.restore();

    // Glossy reflection panel.
    const Rect glossR = Rect.fromLTRB(283, 112, 362, 185);
    final RRect gloss = RRect.fromRectAndRadius(glossR, const Radius.circular(8));
    cv.drawRRect(
      gloss,
      _lin(glossR, [
        const Color(0xFFFFFFFF),
        const Color(0xF2F4FFF4),
        Color.lerp(const Color(0xFFD7F7D7), _castLight, 0.35)!.withValues(alpha: 0.9),
        _castLight.withValues(alpha: 0.55),
      ], stops: const [0.0, 0.35, 0.72, 1.0]),
    );
    // Diagonal sheen inside the gloss.
    cv.save();
    cv.clipRRect(gloss);
    final Path sheen = Path()
      ..moveTo(305, 112)
      ..lineTo(326, 112)
      ..lineTo(300, 185)
      ..lineTo(283, 185)
      ..close();
    cv.drawPath(sheen, Paint()..color = const Color(0x55FFFFFF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6));
    cv.restore();
    _rim(cv, gloss, w: 5, alpha: 0.16, sigma: 2);
    cv.drawRRect(gloss, _stroke(const Color(0x40000000), 0.8));

    // Seam below the gloss.
    cv.drawLine(const Offset(270, 192), const Offset(373, 192),
        Paint()..color = const Color(0x66000000)..strokeWidth = 1.2);
    cv.drawLine(const Offset(270, 193.4), const Offset(373, 193.4),
        Paint()..color = const Color(0x44FFFFFF)..strokeWidth = 1.0);
    if (showJoints) {
      _bolt(cv, const Offset(276, 246), 2.6);
      _bolt(cv, const Offset(367, 246), 2.6);
    }
  }

  void _junctionBox(Canvas cv) {
    const Rect boxR = Rect.fromLTRB(255, 12, 380, 75);
    final RRect box = RRect.fromRectAndRadius(boxR, const Radius.circular(8));
    cv.drawRRect(box.shift(const Offset(0, 5)), _blur(const Color(0x66000000), 5));
    cv.drawRRect(
      box,
      _lin(boxR, const [Color(0xFF78828A), Color(0xFF4A525A), Color(0xFF30373D), Color(0xFF1F2428)],
          stops: const [0.0, 0.3, 0.7, 1.0]),
    );
    _sideShade(cv, box, a: 0.3);
    _rim(cv, box, w: 8, alpha: 0.4, sigma: 3);

    // Bevel: lit top-left edge, dark bottom-right.
    final RRect bev = box.deflate(1.6);
    cv.drawRRect(bev.shift(const Offset(-0.5, -0.5)), _stroke(const Color(0x40FFFFFF), 1.0));
    cv.drawRRect(box, _stroke(const Color(0xFF111417), 1.3));

    // Lid seam.
    cv.drawLine(const Offset(258, 30), const Offset(377, 30),
        Paint()..color = const Color(0x88000000)..strokeWidth = 1.2);
    cv.drawLine(const Offset(258, 31.3), const Offset(377, 31.3),
        Paint()..color = const Color(0x33FFFFFF)..strokeWidth = 1.0);

    _streak(cv, const Rect.fromLTRB(264, 15, 370, 19), alongX: true, alpha: 0.45, sigma: 1.4);
    _streak(cv, const Rect.fromLTRB(257, 22, 260.5, 66), alongX: false, alpha: 0.35, sigma: 1.2);
    if (showJoints) {
      _bolt(cv, const Offset(268, 24), 3.0);
      _bolt(cv, const Offset(372, 43), 3.0);
    }
  }

  void _conduit(Canvas cv) {
    final Path p = Path()
      ..moveTo(380, 49)
      ..lineTo(432, 49)
      ..cubicTo(449, 49, 462, 57, 462, 82);

    cv.drawPath(p.shift(const Offset(0, 3.5)), _stroke(const Color(0x55000000), 7)..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2));
    cv.drawPath(p, _stroke(const Color(0xFF14181B), 8.2)..strokeCap = StrokeCap.round);
    cv.drawPath(p, _stroke(const Color(0xFF3B444A), 6.6)..strokeCap = StrokeCap.round);
    cv.drawPath(p, _stroke(const Color(0xFF7B868D), 4.8)..strokeCap = StrokeCap.round);
    cv.drawPath(p.shift(const Offset(0, -0.9)), _stroke(const Color(0xFFBFC9CE), 2.4)..strokeCap = StrokeCap.round);
    cv.drawPath(p.shift(const Offset(0, -1.4)), _stroke(const Color(0xAAFFFFFF), 0.9)..strokeCap = StrokeCap.round);

    // Ferrule where the conduit enters the casing.
    const Rect fer = Rect.fromLTRB(456, 78, 468, 85);
    final RRect fr = RRect.fromRectAndRadius(fer, const Radius.circular(1.5));
    cv.drawRRect(fr, _steel(fer, horizontal: true));
    cv.drawRRect(fr, _stroke(const Color(0xFF1B2226), 0.9));
  }

  // ---------------------------------------------------------------- lantern

  void _lantern(Canvas cv) {
    const Rect lr = Rect.fromLTRB(372, 110, 422, 245);
    cv.drawRect(lr, _cylH(lr));
    // Occlusion at both ends, where it meets the housing and the casing.
    cv.drawRect(
      lr,
      _lin(lr, const [Color(0x88000000), Color(0x00000000), Color(0x00000000), Color(0x77000000)],
          stops: const [0.0, 0.2, 0.8, 1.0], horizontal: true),
    );
    cv.drawRect(lr, _stroke(_edge, 1.1));

    for (final Rect w in const [
      Rect.fromLTRB(382, 130, 412, 176),
      Rect.fromLTRB(382, 182, 412, 224),
    ]) {
      final RRect rr = RRect.fromRectAndRadius(w, const Radius.circular(3));
      cv.drawRRect(rr, _lin(w, const [Color(0xFF010603), Color(0xFF0B2A12), Color(0xFF1B5A2A)],
          stops: const [0.0, 0.55, 1.0]));
      // Hints of the impeller / shaft inside.
      cv.save();
      cv.clipRRect(rr);
      for (final double x in const [390, 398, 406]) {
        cv.drawLine(Offset(x, w.top), Offset(x, w.bottom),
            Paint()..color = _castDark.withValues(alpha: 0.45)..strokeWidth = 1.6);
      }
      final Rect shaft = Rect.fromLTRB(w.left, w.top + w.height * 0.44, w.right, w.top + w.height * 0.56);
      cv.drawRect(shaft, _lin(shaft, const [Color(0x88A7B2B9), Color(0x883F494F)]));
      cv.restore();
      _rim(cv, rr, w: 7, alpha: 0.7, sigma: 2.5);
      cv.drawRRect(rr, _stroke(_edge, 1.0));
      // Lit lower lip of the opening.
      cv.drawLine(Offset(w.left + 2, w.bottom + 0.6), Offset(w.right - 2, w.bottom + 0.6),
          Paint()..color = const Color(0x55FFFFFF)..strokeWidth = 1.0);
    }

    // Centre rib between the windows.
    const Rect rib = Rect.fromLTRB(382, 176, 412, 182);
    cv.drawRect(rib, _lin(rib, [_castLight, _castMid, _castDark]));

    // Collar.
    const Rect collar = Rect.fromLTRB(372, 105, 384, 250);
    final RRect cr = RRect.fromRectAndRadius(collar, const Radius.circular(2));
    cv.drawRRect(cr, _cylV(collar));
    _rim(cv, cr, w: 5, alpha: 0.3, sigma: 2);
    cv.drawRRect(cr, _stroke(_edge, 1.0));
  }

  // ----------------------------------------------------------------- volute

  void _volute(Canvas cv) {
    // Top nozzle.
    const Rect nozR = Rect.fromLTRB(443, 78, 477, 96);
    final RRect noz = RRect.fromRectAndRadius(nozR, const Radius.circular(4));
    _castPart(cv, noz, _cylV(nozR), shadow: 2);

    // Left flange ring.
    const Rect ringR = Rect.fromLTRB(413, 100, 436, 255);
    final RRect ring = RRect.fromRectAndRadius(ringR, const Radius.circular(7));
    _castPart(cv, ring, _cylV(ringR), shadow: 4, sides: false);
    for (final double y in const [125, 150, 175, 200, 225]) {
      cv.drawLine(Offset(415, y), Offset(434, y), Paint()..color = const Color(0x66000000)..strokeWidth = 1.3);
      cv.drawLine(Offset(415, y + 1.4), Offset(434, y + 1.4), Paint()..color = const Color(0x44FFFFFF)..strokeWidth = 0.9);
    }

    // Main casing body.
    const Rect bodyR = Rect.fromLTRB(428, 92, 506, 263);
    final RRect body = RRect.fromRectAndCorners(
      bodyR,
      topLeft: const Radius.circular(14),
      bottomLeft: const Radius.circular(14),
      topRight: const Radius.circular(32),
      bottomRight: const Radius.circular(32),
    );
    cv.drawRRect(body.shift(const Offset(4, 6)), _blur(const Color(0x59000000), 7));
    cv.drawRRect(body, _cylV(bodyR));

    // Dome-like radial light over the casing.
    cv.save();
    cv.clipRRect(body);
    cv.drawRect(
      bodyR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.5, -0.55),
          radius: 0.9,
          colors: const [Color(0x40FFFFFF), Color(0x00FFFFFF)],
        ).createShader(bodyR),
    );
    // Bounce light at the bottom.
    const Rect low = Rect.fromLTRB(428, 225, 506, 263);
    cv.drawRect(low, _lin(low, [const Color(0x00FFFFFF), _castLight.withValues(alpha: 0.28)]));
    cv.restore();
    _rim(cv, body, w: 10, alpha: 0.4, sigma: 4);

    // Groove behind the ring and a band near the right.
    cv.drawLine(const Offset(446, 98), const Offset(446, 257),
        Paint()..color = const Color(0x77000000)..strokeWidth = 1.7);
    cv.drawLine(const Offset(448, 98), const Offset(448, 257),
        Paint()..color = const Color(0x4DFFFFFF)..strokeWidth = 1.0);
    cv.drawLine(const Offset(486, 106), const Offset(486, 249),
        Paint()..color = const Color(0x66000000)..strokeWidth = 1.5);
    cv.drawLine(const Offset(487.6, 106), const Offset(487.6, 249),
        Paint()..color = const Color(0x2EFFFFFF)..strokeWidth = 1.0);

    _streak(cv, const Rect.fromLTRB(452, 108, 459, 232), alongX: false, alpha: 0.5, sigma: 2.2);
    cv.drawRRect(body, _stroke(_edge, 1.3));
    if (showJoints) {
      _bolt(cv, const Offset(467, 108), 2.8);
      _bolt(cv, const Offset(467, 242), 2.8);
    }
  }

  // ----------------------------------------------------------- neck + flange

  void _neckAndFlange(Canvas cv) {
    // Step ring.
    const Rect stepR = Rect.fromLTRB(506, 122, 542, 238);
    final RRect step = RRect.fromRectAndRadius(stepR, const Radius.circular(9));
    _castPart(cv, step, _cylH(stepR), shadow: 5);
    _streak(cv, const Rect.fromLTRB(512, 126, 536, 130), alongX: true, alpha: 0.6, sigma: 1.4);

    // Pipe stub.
    const Rect pipeR = Rect.fromLTRB(540, 140, 606, 230);
    cv.drawRect(pipeR.shift(const Offset(0, 4)), _blur(const Color(0x4D000000), 5));
    cv.drawRect(pipeR, _cylH(pipeR));
    cv.drawRect(
      pipeR,
      _lin(pipeR, const [Color(0x66000000), Color(0x00000000)], stops: const [0.0, 0.3], horizontal: true),
    );
    _streak(cv, const Rect.fromLTRB(546, 146, 600, 152), alongX: true, alpha: 0.6, sigma: 1.8);
    cv.drawRect(pipeR, _stroke(_edge, 1.2));

    // Flange: dark back rim (thickness), bright front face.
    const Offset backC = Offset(595, 175);
    const Offset frontC = Offset(604, 175);
    final Rect backR = Rect.fromCenter(center: backC, width: 56, height: 140);
    final Rect frontR = Rect.fromCenter(center: frontC, width: 56, height: 140);

    cv.drawOval(backR.shift(const Offset(2, 5)), _blur(const Color(0x66000000), 5));
    cv.drawOval(backR, _lin(backR, [_castDark, _castDeep], horizontal: true));
    cv.drawOval(backR, _stroke(_edge, 1.2));

    // Thickness band joining the back and front ellipses.
    final Path band = Path()
      ..moveTo(595, 105)
      ..lineTo(604, 105)
      ..lineTo(604, 245)
      ..lineTo(595, 245)
      ..close();
    cv.drawPath(band, _lin(band.getBounds(), [_castMid, _castDark, _castDeep]));

    cv.drawOval(
      frontR,
      Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.55),
          radius: 1.15,
          colors: [_castHi, _castLight, _castMid, _castDark, _castDeep],
          stops: const [0.0, 0.2, 0.5, 0.82, 1.0],
        ).createShader(frontR),
    );
    // Edge occlusion on the flange face.
    cv.save();
    cv.clipPath(Path()..addOval(frontR));
    cv.drawOval(
      frontR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = const Color(0x59001205)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    cv.restore();
    cv.drawOval(frontR, _stroke(_edge, 1.3));

    // Bevel ring just inside the rim.
    final Rect bevel = frontR.deflate(4);
    cv.drawOval(bevel.shift(const Offset(0.7, 0.7)), _stroke(const Color(0x59000000), 1.2));
    cv.drawOval(bevel.shift(const Offset(-0.6, -0.6)), _stroke(const Color(0x66FFFFFF), 1.0));

    // Raised face with its own shading.
    final Rect face = Rect.fromCenter(center: const Offset(606, 175), width: 32, height: 96);
    cv.drawOval(face.shift(const Offset(1, 2)), _blur(const Color(0x59000000), 2));
    cv.drawOval(
      face,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [_castHi, _castLight, _castMid, _castDark],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ).createShader(face),
    );
    cv.drawOval(face, _stroke(_edge, 0.9));

    // Bolt holes with a lit lower lip for depth.
    for (int i = 0; i < 8; i++) {
      final double a = i * 2 * math.pi / 8 + math.pi / 8;
      final Offset c = frontC + Offset(math.cos(a) * 21, math.sin(a) * 57);
      final Rect hole = Rect.fromCenter(center: c, width: 5.4, height: 7.4);
      cv.drawOval(hole.inflate(0.9), _stroke(const Color(0x66FFFFFF), 0.9));
      cv.drawOval(hole, Paint()..shader = const LinearGradient(
        colors: [Color(0xFF000A03), Color(0xFF0B2A12)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(hole));
    }

    // Specular glint along the upper-left rim.
    cv.drawArc(
      frontR.deflate(2.5),
      math.pi * 1.05,
      math.pi * 0.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x77FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  // ---------------------------------------------------------- running state

  void _finShimmer(Canvas cv, Rect panel) {
    final double t = phase / (2 * math.pi);
    final double x = panel.left - 40 + t * (panel.width + 80);
    final Rect band = Rect.fromLTWH(x, panel.top, 40, panel.height);
    cv.drawRect(
      band,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00FFFFFF), Color(0x44FFFFFF), Color(0x00FFFFFF)],
        ).createShader(band),
    );
  }

  @override
  bool shouldRepaint(covariant DetailedPumpPainter old) =>
      old.isOn != isOn || old.phase != phase || old.showJoints != showJoints;
}

/// Drop-in widget: animates the halo and fin shimmer while running,
/// with a small "pop" scale when switching on.
class PumpAssemblyView extends StatefulWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;

  const PumpAssemblyView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    this.size = const Size(480, 285), // matches the 640 x 380 virtual canvas
  });

  @override
  State<PumpAssemblyView> createState() => _PumpAssemblyViewState();
}

class _PumpAssemblyViewState extends State<PumpAssemblyView> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.size,
      painter: DetailedPumpPainter(
        isOn: widget.isOn,
        phase: 0.0,
        showJoints: widget.showJoints,
      ),
    );
  }
}