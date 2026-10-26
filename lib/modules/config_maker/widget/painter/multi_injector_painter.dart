import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'single_injector_channel_painter.dart';

/// Multi-Injector Fertilizer Dosing Skid.
///
/// (aluminium extrusion frame, grey PVC piping, yellow booster pump,
/// dynamic N injector channels, a pressure gauge on EACH channel + 1 on the suction
/// column.)
///
/// IMPORTANT: every channel is drawn by calling
/// [InjectorChannelArt.paint] from single_injector_channel_painter.dart, so a
/// channel on the skid is exactly the same drawing as
/// [DetailedSingleInjectorChannelPainter]. The skid just scales it, places it
/// on each channel axis and lines its shelf rails / manifold tees up with it.
///
/// Design the canvas at the skid's aspect ratio:
///   AspectRatio(aspectRatio: DetailedMultiInjectorPainter.aspectRatioFor(channelCount))
///
/// PORTS (in pixels of the canvas size, use these for overlays / hit-tests):
///   inletPort(size)          -> water inlet flange, left of the suction column
///   outletPort(size)         -> outlet flange, right of the frame
///   channelPort(size, i)     -> bottom injection port of channel i
///   channelTopPort(size, i)  -> top (inlet flange) port of channel i
///
/// [isOn]          – master switch: pump, glow, flow animation.
/// [phase]         – 0..1 looping animation driver.
/// [showJoints]    – draw flange bolts / screws.
/// [channelCount]  – number of injector channels to render (default 4).
/// [channelStates] – per channel ON/OFF (default all ON). An OFF channel
///                   shows a resting float and no bubbles.
/// [channelNames]  – optional names / labels for each channel/injector.
/// [fluidColors]   – optional per channel chemical colour.
class DetailedMultiInjectorPainter extends CustomPainter {
  final bool isOn;
  final double phase;
  final bool showJoints;
  final int channelCount;
  final List<bool>? channelStates;
  final List<String>? channelNames;
  final List<Color>? fluidColors;

  DetailedMultiInjectorPainter({
    required this.isOn,
    this.phase = 0,
    this.showJoints = true,
    this.channelCount = 4,
    this.channelStates,
    this.channelNames,
    this.fluidColors,
  });

  int get count {
    if (channelNames != null && channelNames!.isNotEmpty) {
      return math.max(1, channelNames!.length);
    }
    if (channelStates != null && channelStates!.isNotEmpty) {
      return math.max(1, channelStates!.length);
    }
    return math.max(1, channelCount);
  }

  bool isChannelActive(int i) {
    if (channelStates != null && i >= 0 && i < channelStates!.length) {
      return channelStates![i];
    }
    return true; // Default active (ON)
  }

  // ------------------------------------------------------------ geometry API
  static const double firstChannelX = 0.52;
  static const double channelSpacing = 0.32;

  static double designWidthFor(int count) {
    final int c = math.max(1, count);
    final double lastChX = firstChannelX + channelSpacing * (c - 1);
    final double returnX = lastChX + 0.13;
    final double postR = returnX + 0.07;
    return postR + 0.07;
  }

  static double aspectRatioFor(int count) => (1448 / 1085) * designWidthFor(count);

  static double get aspectRatio => aspectRatioFor(4);

  double get _lastChannelX => firstChannelX + channelSpacing * (count - 1);
  double get _returnX => _lastChannelX + 0.13;
  double get _postR => _returnX + 0.07;
  double get _designW => _postR + 0.07;

  /// The channel art spans (outletY - inletY) = 500 reference units, mapped to
  /// this fraction of the canvas height (top flange at 0.20 .. outlet 0.82).
  static const double _chTopFrac = 0.200;
  static const double _chSpanFrac = 0.620;

  // Frame / pipe x-positions (design units).
  static const double _postL = 0.385; // front-left post

  /// Design-unit x -> pixel x on a canvas of [s].
  static double _fx(Size s, double ux, [int count = 4]) =>
      s.width * ux / designWidthFor(count);

  static Offset inletPort(Size s, [int count = 4]) =>
      Offset(_fx(s, 0.04, count), s.height * 0.54);

  static Offset outletPort(Size s, [int count = 4]) {
    final int c = math.max(1, count);
    final double lastChX = firstChannelX + channelSpacing * (c - 1);
    final double returnX = lastChX + 0.13;
    return Offset(_fx(s, returnX + 0.08, count), s.height * 0.72);
  }

  static Offset channelPort(Size s, int i, [int count = 4]) =>
      Offset(_fx(s, firstChannelX + channelSpacing * i, count), s.height * (_chTopFrac + _chSpanFrac));

  static Offset channelTopPort(Size s, int i, [int count = 4]) =>
      Offset(_fx(s, firstChannelX + channelSpacing * i, count), s.height * _chTopFrac);

  // ---------------------------------------------------------------- palette
  static const Color _edge = InjectorChannelArt.edge;
  static const Color _redValve = Color(0xFFE53935);
  static const Color _chemGlow = InjectorChannelArt.chemGlow;
  static const Color _steelLight = InjectorChannelArt.steelLight;
  static const Color _steelMid = InjectorChannelArt.steelMid;
  static const Color _steelDark = InjectorChannelArt.steelDark;
  static const Color _brass = Color(0xFFFFB300);

  // Booster Pump Yellow & Black Palette
  Color get _bpCastHi => isOn ? const Color(0xFFFFFFE0) : const Color(0xFFFFF8E1);
  Color get _bpCastLight => isOn ? const Color(0xFFFFEE58) : const Color(0xFFFDD835);
  Color get _bpCastMid => isOn ? const Color(0xFFF57F17) : const Color(0xFFF57F17);
  Color get _bpCastDark => isOn ? const Color(0xFFE65100) : const Color(0xFFB76A00);
  Color get _bpCastDeep => isOn ? const Color(0xFF4E2600) : const Color(0xFF331800);
  Color get _bpSpec => Color.lerp(_bpCastLight, _bpCastHi, 0.7)!;

  static const Color _bpEdge = Color(0xFF211400);
  static const Color _bpBlackLight = Color(0xFF4E565C);
  static const Color _bpBlackMid = Color(0xFF282D32);
  static const Color _bpBlackDark = Color(0xFF161A1D);
  static const Color _bpBlackDeep = Color(0xFF090A0B);

  static const Color _bpSteelLight = Color(0xFFF4F7F8);
  static const Color _bpSteelMid = Color(0xFFA7B2B9);
  static const Color _bpSteelDark = Color(0xFF3F494F);

  static const List<Color> _alumCyl = InjectorChannelArt.alumCyl;
  static const List<double> _cylStops = InjectorChannelArt.cylStops;

  Size _size = Size.zero;
  double _w = 0; // pixels per design unit (horizontal)
  double _h = 0; // pixels of canvas height
  double _chK = 0; // pixels per channel-art reference unit

  // ---------------------------------------------------------------- helpers
  Rect _r(double x, double y, double ww, double hh) =>
      Rect.fromLTWH(_w * x, _h * y, _w * ww, _h * hh);

  double _cx(int i) => _w * (firstChannelX + channelSpacing * i);

  /// Channel-art reference y -> canvas pixel y.
  double _chY(double refY) =>
      _h * _chTopFrac + (refY - InjectorChannelArt.inletY) * _chK;

  Paint _gv(Rect r, List<Color> c, [List<double>? s]) => InjectorChannelArt.gv(r, c, s);
  Paint _gh(Rect r, List<Color> c, [List<double>? s]) => InjectorChannelArt.gh(r, c, s);
  Paint _stroke(Color c, double w) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  /// Horizontal PVC cylinder (lit from top).
  void _cylH(Canvas c, Rect r, {double radius = 2}) =>
      InjectorChannelArt.pvcH(c, r, radius: radius);

  /// Vertical PVC cylinder (lit from left).
  void _cylV(Canvas c, Rect r, {double radius = 2}) =>
      InjectorChannelArt.pvcV(c, r, radius: radius);

  void _alumH(Canvas c, Rect r) => InjectorChannelArt.alumH(c, r);
  void _alumV(Canvas c, Rect r) => InjectorChannelArt.alumV(c, r);

  void _alumPoly(Canvas c, List<Offset> pts) {
    final Path p = Path()..moveTo(pts.first.dx * _w, pts.first.dy * _h);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx * _w, o.dy * _h);
    }
    p.close();
    c.drawPath(p.shift(const Offset(1.5, 2.0)), Paint()..color = const Color(0x24000000));
    c.drawPath(p, _gv(p.getBounds(), _alumCyl, _cylStops));
    c.drawPath(p, InjectorChannelArt.stroke(const Color(0xFF6B7780), 0.9));
  }

  void _bolt(Canvas c, Offset o, double r) => InjectorChannelArt.bolt(c, o, r);

  // ------------------------------------------------------------------ paint
  @override
  void paint(Canvas canvas, Size size) {
    _size = size;
    _w = size.width / _designW;
    _h = size.height;
    _chK = _h * _chSpanFrac / (InjectorChannelArt.outletY - InjectorChannelArt.inletY);

    _drawFloorShadow(canvas);
    if (isOn) _drawActiveGlow(canvas);
    _drawBackFrame(canvas);
    _drawPipes(canvas);
    _drawPump(canvas);
    _drawFrontFrame(canvas);
    _drawChannels(canvas);
    _drawPorts(canvas);
    _drawChannelButtons(canvas);
  }

  void _drawFloorShadow(Canvas c) {
    c.drawOval(
      _r(0.0, 0.875, _postR + 0.09, 0.07),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _h * 0.02),
    );
  }

  // ------------------------------------------------------------- back frame
  void _drawBackFrame(Canvas c) {
    const double rl = _postL + 0.085; // rear-left post (perspective offset)
    final double rr = _returnX - 0.01; // rear-right post

    _alumV(c, _r(rl, 0.02, 0.024, 0.74)); // rear-left post
    _alumV(c, _r(rr, 0.015, 0.026, 0.20)); // rear-right post
    _alumH(c, _r(rl + 0.025, 0.118, rr - rl - 0.025, 0.018)); // back top rail
    _alumH(c, _r(rl + 0.015, 0.74, rr - rl - 0.015, 0.022)); // rear floor rail

    // perspective top rails
    _alumPoly(c, const [
      Offset(_postL + 0.003, 0.07), Offset(_postL + 0.107, 0.012),
      Offset(_postL + 0.112, 0.04), Offset(_postL + 0.045, 0.088),
    ]);
    _alumPoly(c, [
      Offset(rr, 0.012), Offset(_returnX + 0.093, 0.062),
      Offset(_returnX + 0.068, 0.092), Offset(rr, 0.045),
    ]);

    // right floor diagonal
    final Paint under = _stroke(const Color(0xFF6B7780), _w * 0.013);
    final Paint over = _stroke(const Color(0xFFD5DCE1), _w * 0.010);
    final Offset a = Offset(_w * (_returnX + 0.013), _h * 0.745);
    final Offset b = Offset(_w * (_returnX + 0.070), _h * 0.815);
    c.drawLine(a, b, under);
    c.drawLine(a, b, over);

    // pump skid rails (extended so the booster has its own frame bay)
    _alumH(c, _r(0.06, 0.735, 0.335, 0.028));
    _alumH(c, _r(0.03, 0.775, 0.375, 0.03));
  }

  // ------------------------------------------------------------------ pipes
  void _drawPipes(Canvas c) {
    // --- left suction column
    final Rect col = _r(0.047, 0.15, 0.043, 0.56);
    InjectorChannelArt.pvcRRect(
      c,
      RRect.fromRectAndCorners(col, bottomLeft: Radius.circular(_w * 0.03)),
      vertical: true,
    );
    _cylH(c, _r(0.065, 0.66, 0.05, 0.05)); // bend into pump
    _cylV(c, _r(0.044, 0.60, 0.049, 0.045), radius: 4); // union collar
    _cylV(c, _r(0.044, 0.165, 0.049, 0.04), radius: 4); // top tee collar

    // inlet stub (port)
    _cylH(c, _r(0.04, 0.54 - 0.023, 0.015, 0.046));

    // top-left pressure gauge on a stem
    _cylV(c, _r(0.060, 0.125, 0.012, 0.045));
    _gauge(c, Offset(_w * 0.066, _h * 0.10), _w * 0.026, _gaugeValue(9));

    // --- top-left horizontal pipe + union
    _cylH(c, _r(0.09, 0.198, 0.10, 0.05));
    _cylV(c, _r(0.186, 0.19, 0.049, 0.068), radius: 4);
    _cylH(c, _r(0.235, 0.19, 0.14, 0.027));
    _cylV(c, _r(0.355, 0.14, 0.03, 0.085)); // riser to manifold

    // red ball valve
    _cylV(c, _r(0.352, 0.148, 0.03, 0.045), radius: 4);
    final RRect lever = RRect.fromRectAndRadius(_r(0.338, 0.146, 0.045, 0.02), const Radius.circular(3));
    c.drawRRect(lever.shift(const Offset(1, 2)), Paint()..color = const Color(0x33000000));
    c.drawRRect(lever, _gv(lever.outerRect, const [Color(0xFFFF7A70), _redValve, Color(0xFFB71C1C)]));
    c.drawRRect(lever, _stroke(_edge, 0.9));

    // --- top manifold (runs behind the front-left post)
    const double manL = 0.375;
    final double manR = _returnX + 0.033;
    final Rect man = _r(manL, 0.125, manR - manL, 0.05);
    InjectorChannelArt.pvcRRect(
      c,
      RRect.fromRectAndCorners(man, topRight: Radius.circular(_w * 0.022)),
      vertical: false,
    );
    // manifold sections (couplings) halfway between the channels
    for (int i = 0; i < count - 1; i++) {
      final double x = firstChannelX + channelSpacing * (i + 0.5) - 0.006;
      _cylV(c, _r(x, 0.12, 0.012, 0.06), radius: 2);
    }

    // --- right vertical return pipe
    _cylV(c, _r(_returnX, 0.15, 0.033, 0.55));
    _cylV(c, _r(_returnX - 0.006, 0.42, 0.045, 0.03), radius: 3); // ring collar

    // --- bottom manifold (pump discharge)
    const double botL = 0.372;
    _cylH(c, _r(botL, 0.65, _returnX + 0.02 - botL, 0.046));
    final Offset elbow = Offset(_w * (_returnX + 0.0165), _h * 0.673);
    final double er = _w * 0.0185;
    InjectorChannelArt.pvcRRect(
      c,
      RRect.fromRectAndRadius(Rect.fromCircle(center: elbow, radius: er), Radius.circular(er)),
      vertical: true,
      shadow: false,
    );

    // --- outlet drop + stub (flange is drawn last, in _drawPorts)
    _cylV(c, _r(_returnX, 0.67, 0.033, 0.07));
    _cylH(c, _r(_returnX, 0.72 - 0.023, 0.07, 0.046));

    // --- branch tees from top manifold down to each channel's top flange
    for (int i = 0; i < count; i++) {
      final double xc = _cx(i);
      _cylV(c, Rect.fromLTWH(xc - _w * 0.016, _h * 0.165, _w * 0.032, _h * 0.04));
      _cylV(c, Rect.fromLTWH(xc - _w * 0.025, _h * 0.155, _w * 0.05, _h * 0.03), radius: 5);
      if (showJoints) {
        c.drawLine(Offset(xc - _w * 0.025, _h * 0.17), Offset(xc + _w * 0.025, _h * 0.17),
            Paint()..color = Colors.black45..strokeWidth = 0.8);
      }
    }
  }

  // ----------------------------------------------------------- booster pump
  Paint _bpCylH(Rect r) => _gv(
    r,
    [_bpCastMid, _bpCastLight, _bpSpec, _bpCastMid, _bpCastDark, _bpCastDeep, _bpCastDark],
    const [0.0, 0.1, 0.19, 0.4, 0.68, 0.9, 1.0],
  );

  Paint _bpCylV(Rect r) => _gh(
    r,
    [_bpCastDark, _bpCastMid, _bpCastLight, _bpSpec, _bpCastMid, _bpCastDark, _bpCastDeep],
    const [0.0, 0.08, 0.18, 0.27, 0.5, 0.78, 1.0],
  );

  Paint _bpCylHBlack(Rect r) => _gv(
    r,
    [_bpBlackLight, _bpBlackMid, const Color(0xFF626B73), _bpBlackMid, _bpBlackDark, _bpBlackDeep, _bpBlackDark],
    const [0.0, 0.1, 0.19, 0.4, 0.68, 0.9, 1.0],
  );

  Paint _bpSteel(Rect r, {bool horizontal = false}) => horizontal
      ? _gh(r, const [_bpSteelLight, _bpSteelMid, _bpSteelDark], const [0.0, 0.5, 1.0])
      : _gv(r, const [_bpSteelLight, _bpSteelMid, _bpSteelDark], const [0.0, 0.5, 1.0]);

  void _bpRim(Canvas cv, RRect rr, {double w = 7, double alpha = 0.38, double sigma = 3}) {
    cv.save();
    cv.clipRRect(rr);
    cv.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = Color.fromRGBO(20, 10, 0, alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
    );
    cv.restore();
  }

  void _bpSideShade(Canvas cv, RRect rr, {double a = 0.32, double edge = 0.12}) {
    cv.save();
    cv.clipRRect(rr);
    final Rect r = rr.outerRect;
    cv.drawRect(
      r,
      _gh(
        r,
        [
          Color.fromRGBO(15, 8, 0, a),
          const Color.fromRGBO(15, 8, 0, 0),
          const Color.fromRGBO(15, 8, 0, 0),
          Color.fromRGBO(15, 8, 0, a * 1.25),
        ],
        [0.0, edge, 1 - edge, 1.0],
      ),
    );
    cv.restore();
  }

  void _bpStreak(Canvas cv, Rect r, {required bool alongX, double alpha = 0.55, double sigma = 2.0}) {
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

  void _bpCastPart(Canvas cv, RRect rr, Paint fill, {double shadow = 4, bool sides = true}) {
    cv.drawRRect(rr.shift(Offset(0, shadow * 0.8)),
        Paint()..color = const Color(0x4D000000)..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow));
    cv.drawRRect(rr, fill);
    if (sides) _bpSideShade(cv, rr);
    _bpRim(cv, rr);
    cv.drawRRect(rr, _stroke(_bpEdge, 1.1));
  }

  void _bpBolt(Canvas cv, Offset p, double r) {
    final Rect rect = Rect.fromCircle(center: p, radius: r);
    cv.drawCircle(p + Offset(0, r * 0.4), r * 1.05, Paint()..color = const Color(0x66000000));
    cv.drawCircle(
      p,
      r,
      Paint()
        ..isAntiAlias = true
        ..shader = const LinearGradient(
          colors: [_bpSteelLight, _bpSteelMid, _bpSteelDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    cv.drawCircle(p, r * 0.44, Paint()..color = const Color(0xFF2E373C));
    cv.drawCircle(p + Offset(-r * 0.12, -r * 0.12), r * 0.2, Paint()..color = const Color(0x55FFFFFF));
  }

  void _drawPump(Canvas c) {
    if (isOn) _bpHalo(c);
    _bpSkidAndFeet(c);
    _bpMotor(c);
    _bpTerminalCap(c);
    _bpMiddleHousing(c);
    _bpJunctionBox(c);
    _bpConduit(c);
    _bpLantern(c);
    _bpVolute(c);
    _bpFlange(c);
  }

  void _bpHalo(Canvas c) {
    final double breathe = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
    final Rect haloR = Rect.fromCenter(
      center: Offset(_w * 0.21, _h * 0.64),
      width: _w * (0.34 + 0.02 * breathe),
      height: _h * (0.24 + 0.015 * breathe),
    );
    c.drawOval(
      haloR,
      Paint()
        ..color = const Color(0xFFFFD600).withValues(alpha: 0.22 * breathe)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  void _bpSkidAndFeet(Canvas c) {
    c.drawOval(
      _r(0.078, 0.754, 0.265, 0.020),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    final Rect plate = _r(0.082, 0.748, 0.252, 0.014);
    final RRect pr = RRect.fromRectAndRadius(plate, const Radius.circular(2));
    c.drawRRect(pr, _bpCylHBlack(plate));
    c.drawRRect(pr, _stroke(_bpEdge, 1.0));
    if (showJoints) {
      _bpBolt(c, Offset(_w * 0.100, plate.center.dy), 2.2);
      _bpBolt(c, Offset(_w * 0.165, plate.center.dy), 2.2);
      _bpBolt(c, Offset(_w * 0.235, plate.center.dy), 2.2);
      _bpBolt(c, Offset(_w * 0.315, plate.center.dy), 2.2);
    }

    final Rect footM = _r(0.105, 0.736, 0.070, 0.013);
    final RRect fmr = RRect.fromRectAndRadius(footM, const Radius.circular(2));
    c.drawRRect(fmr, _bpCylH(footM));
    c.drawRRect(fmr, _stroke(_bpEdge, 0.9));

    final Rect footV = _r(0.225, 0.736, 0.085, 0.013);
    final RRect fvr = RRect.fromRectAndRadius(footV, const Radius.circular(2));
    c.drawRRect(fvr, _bpCylH(footV));
    c.drawRRect(fvr, _stroke(_bpEdge, 0.9));
  }

  void _bpMotor(Canvas c) {
    final Rect shellR = _r(0.100, 0.580, 0.088, 0.158);
    final RRect shell = RRect.fromRectAndRadius(shellR, Radius.circular(_w * 0.008));
    _bpCastPart(c, shell, _bpCylH(shellR), shadow: 5);
    _bpStreak(c, _r(0.110, 0.583, 0.072, 0.008), alongX: true, alpha: 0.6);

    final Rect panel = _r(0.108, 0.598, 0.072, 0.122);
    c.save();
    c.clipRect(panel);
    c.drawRect(panel, Paint()..color = _bpBlackDeep);
    const int n = 10;
    final double step = panel.height / n;
    for (int i = 0; i < n; i++) {
      final Rect ridge = Rect.fromLTWH(panel.left, panel.top + i * step + 1.2, panel.width, step - 2.8);
      c.drawRect(
        ridge,
        _gv(ridge, [_bpSpec, _bpCastLight, _bpCastMid, _bpCastDark, _bpCastDeep],
            const [0.0, 0.16, 0.45, 0.8, 1.0]),
      );
      c.drawLine(Offset(ridge.left, ridge.top + 0.5), Offset(ridge.right, ridge.top + 0.5),
          Paint()..color = const Color(0x77FFFFFF)..strokeWidth = 0.8);
      final Rect gap = Rect.fromLTWH(panel.left, ridge.bottom, panel.width, 2.0);
      c.drawRect(gap, _gv(gap, const [Color(0xAA000000), Color(0x00000000)]));
    }
    c.drawRect(
      panel,
      _gv(panel, const [Color(0x2EFFFFFF), Color(0x00000000), Color(0x00000000), Color(0x59000000)],
          const [0.0, 0.25, 0.65, 1.0]),
    );
    c.drawRect(
      panel,
      _gh(panel, const [Color(0x70000000), Color(0x00000000), Color(0x00000000), Color(0x73000000)],
          const [0.0, 0.07, 0.93, 1.0]),
    );
    if (isOn) {
      final double t = (phase * 2) % 1.0;
      final double x = panel.left - 30 + t * (panel.width + 60);
      final Rect band = Rect.fromLTWH(x, panel.top, 30, panel.height);
      c.drawRect(
        band,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x00FFFFFF), Color(0x44FFFFFF), Color(0x00FFFFFF)],
          ).createShader(band),
      );
    }
    c.restore();
    c.drawRect(panel, _stroke(_bpEdge, 1.0));

    final Rect capR = _r(0.078, 0.568, 0.026, 0.170);
    final RRect cap = RRect.fromRectAndCorners(
      capR,
      topLeft: Radius.circular(_w * 0.012),
      bottomLeft: Radius.circular(_w * 0.012),
      topRight: Radius.circular(_w * 0.003),
      bottomRight: Radius.circular(_w * 0.003),
    );
    c.drawRRect(cap.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x59000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    c.drawRRect(
      cap,
      Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.6),
          radius: 1.25,
          colors: [_bpCastHi, _bpCastLight, _bpCastMid, _bpCastDark, _bpCastDeep],
          stops: const [0.0, 0.18, 0.45, 0.8, 1.0],
        ).createShader(capR),
    );
    _bpStreak(c, Rect.fromLTRB(capR.left + _w * 0.003, capR.top + _h * 0.02, capR.left + _w * 0.007, capR.bottom - _h * 0.02),
        alongX: false, alpha: 0.5, sigma: 2.0);
    _bpRim(c, cap, w: 8, alpha: 0.4, sigma: 4);

    final Rect innerR = Rect.fromLTRB(capR.left + _w * 0.004, capR.top + _h * 0.01, capR.right - _w * 0.003, capR.bottom - _h * 0.01);
    final RRect inner = RRect.fromRectAndCorners(
      innerR,
      topLeft: Radius.circular(_w * 0.009),
      bottomLeft: Radius.circular(_w * 0.009),
      topRight: Radius.circular(_w * 0.002),
      bottomRight: Radius.circular(_w * 0.002),
    );
    c.drawRRect(inner.shift(const Offset(0.8, 0.8)), _stroke(const Color(0x66000000), 1.1));
    c.drawRRect(inner.shift(const Offset(-0.6, -0.6)), _stroke(const Color(0x66FFFFFF), 0.9));
    c.drawRRect(cap, _stroke(_bpEdge, 1.2));
    if (showJoints) {
      _bpBolt(c, Offset(capR.right - _w * 0.006, capR.top + _h * 0.018), 2.0);
      _bpBolt(c, Offset(capR.right - _w * 0.006, capR.bottom - _h * 0.018), 2.0);
    }

    final Rect plateR = _r(0.125, 0.645, 0.045, 0.045);
    c.drawRRect(RRect.fromRectAndRadius(plateR, const Radius.circular(1.5)), Paint()..color = _bpSteelLight);
    c.drawRRect(RRect.fromRectAndRadius(plateR, const Radius.circular(1.5)), _stroke(_bpEdge, 0.7));
    for (int k = 0; k < 4; k++) {
      final double y = plateR.top + 4 + k * (plateR.height - 8) / 3;
      c.drawLine(Offset(plateR.left + 3, y), Offset(plateR.right - 3 - (k % 2) * 5, y),
          Paint()..color = Colors.black54..strokeWidth = 0.8);
    }
  }

  void _bpTerminalCap(Canvas c) {
    final Rect neck = _r(0.118, 0.552, 0.052, 0.030);
    c.drawRect(neck, _gv(neck, [_bpCastMid, _bpCastDark, _bpCastDeep]));
    c.drawRect(neck, _gh(neck, const [Color(0x66000000), Color(0x00000000), Color(0x55000000)], const [0.0, 0.5, 1.0]));
    c.drawRect(neck, _stroke(_bpEdge, 0.9));

    final Rect lipR = _r(0.112, 0.536, 0.064, 0.018);
    final RRect lip = RRect.fromRectAndRadius(lipR, const Radius.circular(3));
    _bpCastPart(c, lip, _bpCylH(lipR), shadow: 2);
    _bpStreak(c, _r(0.118, 0.538, 0.052, 0.004), alongX: true, alpha: 0.6, sigma: 1.2);

    final Rect top = _r(0.120, 0.540, 0.048, 0.008);
    final RRect tr = RRect.fromRectAndRadius(top, const Radius.circular(1.5));
    c.drawRRect(tr, _gv(top, [_bpCastDeep, _bpCastDark, _bpCastMid]));
  }

  void _bpMiddleHousing(Canvas c) {
    final Rect neck = _r(0.185, 0.550, 0.030, 0.028);
    c.drawRect(neck, _bpCylV(neck));
    c.drawRect(neck, _stroke(_bpEdge, 0.9));

    final Rect bodyR = _r(0.182, 0.570, 0.063, 0.170);
    final RRect body = RRect.fromRectAndRadius(bodyR, const Radius.circular(8));
    _bpCastPart(c, body, _bpCylH(bodyR), shadow: 5);

    c.save();
    c.clipRRect(body);
    final Rect lower = _r(0.182, 0.680, 0.063, 0.060);
    c.drawRect(lower, _gv(lower, [const Color(0x00FFFFFF), _bpCastLight.withValues(alpha: 0.28)]));
    c.restore();

    final Rect glossR = _r(0.191, 0.585, 0.045, 0.075);
    final RRect gloss = RRect.fromRectAndRadius(glossR, const Radius.circular(4));
    c.drawRRect(
      gloss,
      _gv(glossR, [
        const Color(0xFFFFFFFF),
        const Color(0xFFFFFDE7),
        Color.lerp(const Color(0xFFFFF176), _bpCastLight, 0.35)!.withValues(alpha: 0.9),
        _bpCastLight.withValues(alpha: 0.55),
      ], const [0.0, 0.35, 0.72, 1.0]),
    );

    c.save();
    c.clipRRect(gloss);
    final Path sheen = Path()
      ..moveTo(glossR.left + _w * 0.012, glossR.top)
      ..lineTo(glossR.left + _w * 0.024, glossR.top)
      ..lineTo(glossR.left + _w * 0.010, glossR.bottom)
      ..lineTo(glossR.left, glossR.bottom)
      ..close();
    c.drawPath(sheen, Paint()..color = const Color(0x55FFFFFF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2));
    c.restore();
    _bpRim(c, gloss, w: 4, alpha: 0.16, sigma: 1.5);
    c.drawRRect(gloss, _stroke(const Color(0x40000000), 0.8));

    c.drawLine(Offset(bodyR.left + 2, bodyR.top + _h * 0.11), Offset(bodyR.right - 2, bodyR.top + _h * 0.11),
        Paint()..color = const Color(0x66000000)..strokeWidth = 1.1);
    if (showJoints) {
      _bpBolt(c, Offset(bodyR.left + _w * 0.006, bodyR.bottom - _h * 0.012), 2.0);
      _bpBolt(c, Offset(bodyR.right - _w * 0.006, bodyR.bottom - _h * 0.012), 2.0);
    }
  }

  void _bpJunctionBox(Canvas c) {
    final Rect boxR = _r(0.175, 0.495, 0.070, 0.042);
    final RRect box = RRect.fromRectAndRadius(boxR, const Radius.circular(5));
    c.drawRRect(box.shift(const Offset(0, 3)), Paint()..color = const Color(0x66000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    c.drawRRect(
      box,
      _gv(boxR, const [_bpBlackLight, _bpBlackMid, _bpBlackDark, _bpBlackDeep], const [0.0, 0.3, 0.7, 1.0]),
    );
    _bpSideShade(c, box, a: 0.3);
    _bpRim(c, box, w: 6, alpha: 0.4, sigma: 2.5);

    final RRect bev = box.deflate(1.2);
    c.drawRRect(bev.shift(const Offset(-0.4, -0.4)), _stroke(const Color(0x40FFFFFF), 0.8));
    c.drawRRect(box, _stroke(_bpEdge, 1.1));

    c.drawLine(Offset(boxR.left + 3, boxR.top + _h * 0.012), Offset(boxR.right - 3, boxR.top + _h * 0.012),
        Paint()..color = const Color(0x88000000)..strokeWidth = 1.0);

    _bpStreak(c, Rect.fromLTRB(boxR.left + 5, boxR.top + 2, boxR.right - 5, boxR.top + 5), alongX: true, alpha: 0.4, sigma: 1.2);

    final Rect sticker = Rect.fromLTWH(boxR.right - _w * 0.020, boxR.top + _h * 0.010, _w * 0.014, _h * 0.012);
    c.drawRect(sticker, Paint()..color = const Color(0xFFFFD600));
    c.drawRect(sticker, _stroke(Colors.black87, 0.5));

    if (showJoints) {
      _bpBolt(c, Offset(boxR.left + 4, boxR.top + 4), 1.8);
      _bpBolt(c, Offset(boxR.right - 4, boxR.bottom - 4), 1.8);
    }
  }

  void _bpConduit(Canvas c) {
    final Path p = Path()
      ..moveTo(_w * 0.245, _h * 0.516)
      ..lineTo(_w * 0.268, _h * 0.516)
      ..cubicTo(_w * 0.282, _h * 0.516, _w * 0.288, _h * 0.528, _w * 0.288, _h * 0.548);

    c.drawPath(p.shift(const Offset(0, 2)), _stroke(const Color(0x55000000), 5.5)..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8));
    c.drawPath(p, _stroke(const Color(0xFF14181B), 6.5)..strokeCap = StrokeCap.round);
    c.drawPath(p, _stroke(const Color(0xFF3B444A), 5.0)..strokeCap = StrokeCap.round);
    c.drawPath(p, _stroke(const Color(0xFF7B868D), 3.5)..strokeCap = StrokeCap.round);
    c.drawPath(p.shift(const Offset(0, -0.7)), _stroke(const Color(0xFFBFC9CE), 1.8)..strokeCap = StrokeCap.round);

    final Rect fer = Rect.fromLTWH(_w * 0.283, _h * 0.542, _w * 0.010, _h * 0.010);
    final RRect fr = RRect.fromRectAndRadius(fer, const Radius.circular(1.0));
    c.drawRRect(fr, _bpSteel(fer, horizontal: true));
    c.drawRRect(fr, _stroke(const Color(0xFF1B2226), 0.8));
  }

  void _bpLantern(Canvas c) {
    final Rect lr = _r(0.245, 0.582, 0.030, 0.155);
    c.drawRect(lr, _bpCylH(lr));
    c.drawRect(
      lr,
      _gh(lr, const [Color(0x88000000), Color(0x00000000), Color(0x00000000), Color(0x77000000)],
          const [0.0, 0.2, 0.8, 1.0]),
    );
    c.drawRect(lr, _stroke(_bpEdge, 1.0));

    for (final Rect w in [
      _r(0.250, 0.600, 0.020, 0.042),
      _r(0.250, 0.655, 0.020, 0.042),
    ]) {
      final RRect rr = RRect.fromRectAndRadius(w, const Radius.circular(2));
      c.drawRRect(rr, _gv(w, const [Color(0xFF060500), Color(0xFF261D00), Color(0xFF4A3A00)],
          const [0.0, 0.55, 1.0]));
      c.save();
      c.clipRRect(rr);
      final Rect shaft = Rect.fromLTRB(w.left, w.top + w.height * 0.40, w.right, w.top + w.height * 0.60);
      c.drawRect(shaft, _gv(shaft, const [Color(0xCCA7B2B9), Color(0xCC3F494F)]));
      for (final double x in [w.left + 4, w.left + 10, w.left + 16]) {
        c.drawLine(Offset(x, w.top), Offset(x, w.bottom),
            Paint()..color = _bpCastDark.withValues(alpha: 0.5)..strokeWidth = 1.4);
      }
      c.restore();
      _bpRim(c, rr, w: 5, alpha: 0.7, sigma: 2.0);
      c.drawRRect(rr, _stroke(_bpEdge, 0.9));
    }

    final Rect rib = _r(0.250, 0.642, 0.020, 0.013);
    c.drawRect(rib, _gv(rib, [_bpCastLight, _bpCastMid, _bpCastDark]));

    final Rect collar = _r(0.245, 0.576, 0.008, 0.165);
    final RRect cr = RRect.fromRectAndRadius(collar, const Radius.circular(1.5));
    c.drawRRect(cr, _bpCylV(collar));
    c.drawRRect(cr, _stroke(_bpEdge, 0.9));
  }

  void _bpVolute(Canvas c) {
    final Rect nozR = _r(0.285, 0.540, 0.022, 0.028);
    final RRect noz = RRect.fromRectAndRadius(nozR, const Radius.circular(3));
    _bpCastPart(c, noz, _bpCylV(nozR), shadow: 2);

    final Rect ringR = _r(0.272, 0.565, 0.015, 0.178);
    final RRect ring = RRect.fromRectAndRadius(ringR, const Radius.circular(5));
    _bpCastPart(c, ring, _bpCylV(ringR), shadow: 3, sides: false);
    if (showJoints) {
      for (final double y in [0.585, 0.620, 0.655, 0.690, 0.725]) {
        c.drawLine(Offset(_w * 0.273, _h * y), Offset(_w * 0.285, _h * y),
            Paint()..color = const Color(0x66000000)..strokeWidth = 1.1);
      }
    }

    final Rect bodyR = _r(0.280, 0.558, 0.048, 0.188);
    final RRect body = RRect.fromRectAndCorners(
      bodyR,
      topLeft: Radius.circular(_w * 0.008),
      bottomLeft: Radius.circular(_w * 0.008),
      topRight: Radius.circular(_w * 0.020),
      bottomRight: Radius.circular(_w * 0.020),
    );
    c.drawRRect(body.shift(const Offset(3, 4)),
        Paint()..color = const Color(0x59000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.drawRRect(body, _bpCylV(bodyR));

    c.save();
    c.clipRRect(body);
    c.drawRect(
      bodyR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.5, -0.55),
          radius: 0.9,
          colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
        ).createShader(bodyR),
    );
    final Rect low = _r(0.280, 0.700, 0.048, 0.046);
    c.drawRect(low, _gv(low, [const Color(0x00FFFFFF), _bpCastLight.withValues(alpha: 0.28)]));
    c.restore();
    _bpRim(c, body, w: 8, alpha: 0.4, sigma: 3);

    _bpStreak(c, _r(0.292, 0.575, 0.005, 0.140), alongX: false, alpha: 0.5, sigma: 1.8);
    c.drawRRect(body, _stroke(_bpEdge, 1.2));
    if (showJoints) {
      _bpBolt(c, Offset(_w * 0.300, bodyR.top + _h * 0.015), 2.2);
      _bpBolt(c, Offset(_w * 0.300, bodyR.bottom - _h * 0.015), 2.2);
    }

    final Offset hub = Offset(bodyR.center.dx, bodyR.center.dy);
    final Rect label = Rect.fromCenter(center: hub, width: _w * 0.030, height: _h * 0.042);
    c.drawOval(label, _gv(label, const [Color(0xFFFFE082), Color(0xFFFFB300)]));
    c.drawOval(label, _stroke(_bpEdge, 0.9));
    final double baseAngle = isOn ? phase * 4 * math.pi : 0;
    for (int k = 0; k < 8; k++) {
      final double a = baseAngle + k * math.pi / 4;
      c.drawLine(
        hub + Offset(math.cos(a) * label.width * 0.34, math.sin(a) * label.height * 0.34),
        hub + Offset(math.cos(a) * label.width * 0.47, math.sin(a) * label.height * 0.47),
        Paint()..color = Colors.black87..strokeWidth = 1.4,
      );
    }
    c.drawCircle(hub, 2.5, Paint()..color = _bpEdge);

    c.drawRect(Rect.fromCenter(center: Offset(bodyR.center.dx, bodyR.bottom + 2), width: 5, height: 4),
        Paint()..color = _brass);
  }

  void _bpFlange(Canvas c) {
    final Rect stepR = _r(0.328, 0.590, 0.010, 0.130);
    final RRect step = RRect.fromRectAndRadius(stepR, const Radius.circular(4));
    _bpCastPart(c, step, _bpCylH(stepR), shadow: 3);

    final Rect pipeR = _r(0.338, 0.605, 0.012, 0.100);
    c.drawRect(pipeR.shift(const Offset(0, 3)), Paint()..color = const Color(0x4D000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    c.drawRect(pipeR, _bpCylH(pipeR));
    c.drawRect(pipeR, _stroke(_bpEdge, 1.0));

    final Offset backC = Offset(_w * 0.348, _h * 0.655);
    final Offset frontC = Offset(_w * 0.352, _h * 0.655);
    final Rect backR = Rect.fromCenter(center: backC, width: _w * 0.024, height: _h * 0.140);
    final Rect frontR = Rect.fromCenter(center: frontC, width: _w * 0.024, height: _h * 0.140);

    c.drawOval(backR.shift(const Offset(1, 3)), Paint()..color = const Color(0x66000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    c.drawOval(backR, _gh(backR, [_bpCastDark, _bpCastDeep]));
    c.drawOval(backR, _stroke(_bpEdge, 1.0));

    final Path band = Path()
      ..moveTo(_w * 0.348, backC.dy - _h * 0.070)
      ..lineTo(_w * 0.352, frontC.dy - _h * 0.070)
      ..lineTo(_w * 0.352, frontC.dy + _h * 0.070)
      ..lineTo(_w * 0.348, backC.dy + _h * 0.070)
      ..close();
    c.drawPath(band, _gv(band.getBounds(), [_bpCastMid, _bpCastDark, _bpCastDeep]));

    c.drawOval(
      frontR,
      Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.55),
          radius: 1.15,
          colors: [_bpCastHi, _bpCastLight, _bpCastMid, _bpCastDark, _bpCastDeep],
          stops: const [0.0, 0.2, 0.5, 0.82, 1.0],
        ).createShader(frontR),
    );

    c.save();
    c.clipPath(Path()..addOval(frontR));
    c.drawOval(
      frontR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0x59201000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    c.restore();
    c.drawOval(frontR, _stroke(_bpEdge, 1.1));

    final Rect bevel = frontR.deflate(2.5);
    c.drawOval(bevel.shift(const Offset(0.5, 0.5)), _stroke(const Color(0x59000000), 1.0));
    c.drawOval(bevel.shift(const Offset(-0.5, -0.5)), _stroke(const Color(0x66FFFFFF), 0.8));

    final Rect face = Rect.fromCenter(center: Offset(_w * 0.353, _h * 0.655), width: _w * 0.013, height: _h * 0.096);
    c.drawOval(
      face,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [_bpCastHi, _bpCastLight, _bpCastMid, _bpCastDark],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ).createShader(face),
    );
    c.drawOval(face, _stroke(_bpEdge, 0.8));

    if (showJoints) {
      for (int i = 0; i < 8; i++) {
        final double a = i * 2 * math.pi / 8 + math.pi / 8;
        final Offset holeC = frontC + Offset(math.cos(a) * _w * 0.009, math.sin(a) * _h * 0.056);
        final Rect hole = Rect.fromCenter(center: holeC, width: 3.5, height: 5.0);
        c.drawOval(hole.inflate(0.7), _stroke(const Color(0x66FFFFFF), 0.7));
        c.drawOval(hole, Paint()..shader = const LinearGradient(
          colors: [Color(0xFF000A03), Color(0xFF0B2A12)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(hole));
      }
    }

    c.drawArc(
      frontR.deflate(1.8),
      math.pi * 1.05,
      math.pi * 0.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x77FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
  }

  // ------------------------------------------------------------ front frame
  void _drawFrontFrame(Canvas c) {
    _alumV(c, _r(_postL, 0.075, 0.041, 0.745)); // front-left post
    _alumV(c, _r(_postR, 0.07, 0.037, 0.76)); // front-right post

    // Shelf rails sit at EXACTLY the heights of the background rails in the
    // single-channel artwork, so each channel looks mounted the same way.
    final double xl = _w * (_postL + 0.03);
    final double xr = _w * (_postR + 0.003);
    _alumH(c, Rect.fromLTRB(xl, _chY(InjectorChannelArt.upperRailTop), xr, _chY(InjectorChannelArt.upperRailBottom)));
    _alumH(c, Rect.fromLTRB(xl, _chY(InjectorChannelArt.lowerRailTop), xr, _chY(InjectorChannelArt.lowerRailBottom)));

    _alumH(c, _r(0.022, 0.81, _postR + 0.043 - 0.022, 0.043)); // base front rail

    // black end caps
    for (final Rect r in [
      _r(_postL - 0.002, 0.069, 0.039, 0.042),
      _r(_postR + 0.009, 0.06, 0.032, 0.042),
    ]) {
      final RRect rr = RRect.fromRectAndRadius(r, const Radius.circular(2));
      c.drawRRect(rr, _gv(r, const [Color(0xFF3A4247), Color(0xFF111111), Color(0xFF050505)]));
      c.drawLine(Offset(r.left + 2, r.top + 1.2), Offset(r.right - 2, r.top + 1.2),
          _stroke(const Color(0x55FFFFFF), 0.8));
    }

    // rubber feet
    final List<double> feetX = [0.045, 0.207];
    for (int i = 0; i < count; i++) {
      feetX.add(firstChannelX + channelSpacing * i);
    }
    feetX.add(_postR + 0.019);

    for (final double fx in feetX) {
      c.drawRect(_r(fx - 0.004, 0.855, 0.008, 0.025), _gh(_r(fx - 0.004, 0.855, 0.008, 0.025),
          const [Color(0xFF607D8B), Color(0xFFCFD8DC), Color(0xFF607D8B)]));
      final Rect foot = Rect.fromCenter(center: Offset(_w * fx, _h * 0.895), width: _w * 0.045, height: _h * 0.04);
      final RRect fr = RRect.fromRectAndRadius(foot, const Radius.circular(8));
      c.drawRRect(fr, _gv(foot, const [Color(0xFF4A4A4A), Color(0xFF111111), Color(0xFF050505)]));
      c.drawLine(Offset(foot.left + 5, foot.top + 2.5), Offset(foot.right - 5, foot.top + 2.5),
          _stroke(const Color(0x40FFFFFF), 1.0));
    }
  }

  // ----------------------------------------------------------------- gauges
  double _gaugeValue(int seed) {
    if (!isOn) return 0.04;
    return 0.58 + 0.02 * math.sin(phase * 2 * math.pi * 10 + seed);
  }

  void _gauge(Canvas c, Offset ctr, double r, double v) =>
      InjectorChannelArt.gauge(c, ctr, r, v);

  // --------------------------------------------------------------- channels
  /// Float offsets so the channels show slightly different flow rates.
  static const List<double> _floatOffsets = [0, -18, 10, -7];

  void _drawChannels(Canvas c) {
    for (int i = 0; i < count; i++) {
      final bool active = isOn && isChannelActive(i);
      final double dxFloat = i < _floatOffsets.length ? _floatOffsets[i] : ((i * 7) % 5 - 2) * 6.0;
      final Color fluid = (fluidColors != null && i < fluidColors!.length)
          ? fluidColors![i]
          : (i.isEven ? InjectorChannelArt.chemGreen : InjectorChannelArt.chemBlue);

      c.save();
      c.translate(
        _cx(i) - InjectorChannelArt.axisX * _chK,
        _h * _chTopFrac - InjectorChannelArt.inletY * _chK,
      );
      c.scale(_chK);
      // <<< the very same drawing as DetailedSingleInjectorChannelPainter >>>
      InjectorChannelArt.paint(
        c,
        isOn: active,
        phase: phase + i * 0.17,
        showJoints: showJoints,
        fluidColor: fluid,
        pressureValue: 0.56 + 0.02 * (i % 3),
        drawRails: false, // the skid draws continuous shelf rails instead
        drawGlow: false, // the skid has its own overall glow
        seed: i * 13 + 7,
        floatOffset: dxFloat,
      );
      c.restore();
    }
  }

  // ------------------------------------------------------------ channel buttons
  Rect _channelButtonRectAt(int i) {
    return Rect.fromCenter(
      center: Offset(_w * (firstChannelX + channelSpacing * i), _h * 0.935),
      width: _w * 0.27,
      height: _h * 0.115,
    );
  }

  static Rect channelButtonRect(Size s, int i, {int channelCount = 4}) {
    final double dw = designWidthFor(channelCount);
    final double w = s.width / dw;
    return Rect.fromCenter(
      center: Offset(w * (firstChannelX + channelSpacing * i), s.height * 0.935),
      width: w * 0.27,
      height: s.height * 0.115,
    );
  }

  static const Color _chOn = Color(0xFF16A34A);
  static const Color _chOnDark = Color(0xFF15803D);
  static const Color _chOff = Color(0xFF64748B);
  static const Color _chOffDark = Color(0xFF475569);

  void _drawChannelButtons(Canvas c) {
    for (int i = 0; i < count; i++) {
      final bool active = isChannelActive(i);
      final Rect btn = _channelButtonRectAt(i);
      final double bh = btn.height;
      final RRect body = RRect.fromRectAndRadius(btn, Radius.circular(bh / 2));

      // soft drop shadow (+ green glow when selected)
      c.drawRRect(
        body.shift(Offset(0, bh * 0.10)),
        Paint()
          ..color = (active ? _chOn : Colors.black).withValues(alpha: active ? 0.35 : 0.20)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, bh * 0.20),
      );

      // body: green = selected, grey = unselected
      c.drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: active
                ? const [Color(0xFF22C55E), _chOnDark]
                : const [_chOff, _chOffDark],
          ).createShader(btn),
      );

      // top gloss
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(btn.left + bh * 0.2, btn.top + bh * 0.07, btn.width - bh * 0.4, bh * 0.32),
          Radius.circular(bh * 0.16),
        ),
        Paint()..color = Colors.white.withValues(alpha: active ? 0.22 : 0.12),
      );

      // border
      c.drawRRect(
        body,
        _stroke(active ? const Color(0xFFBBF7D0) : const Color(0xFF94A3B8), 1.2),
      );

      // centered injector name
      final double fs = bh * 0.42;
      final String chLabel = (channelNames != null && i < channelNames!.length && channelNames![i].isNotEmpty)
          ? channelNames![i]
          : 'CH ${i + 1}';

      final TextPainter name = TextPainter(
        text: TextSpan(
          text: chLabel,
          style: TextStyle(
            color: Colors.white,
            fontSize: fs,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: btn.width - 8);

      name.paint(c, Offset(btn.center.dx - name.width / 2, btn.center.dy - name.height / 2));
    }
  }

  void _drawPorts(Canvas c) {
    final double pulse = isOn ? 0.5 + 0.5 * math.sin(phase * 2 * math.pi * 2) : 0.0;

    // ---------- OUTLET: pipe passes in front of the right post, then flange
    _cylH(c, _r(_postR - 0.004, 0.72 - 0.023, 0.022, 0.046));
    _verticalFlange(c, outletPort(_size, count), pulse);

    // ---------- INLET
    _verticalFlange(c, inletPort(_size, count), pulse);

    // Channel top / bottom flanges, bolts and glow rings are part of the
    // channel artwork itself, so nothing extra is drawn per channel here.
  }

  void _verticalFlange(Canvas c, Offset p, double pulse) {
    final Rect fl = Rect.fromCenter(center: p, width: _w * 0.011, height: _h * 0.066);
    final RRect rr = RRect.fromRectAndRadius(fl, const Radius.circular(1.5));
    c.drawRRect(rr.shift(const Offset(1, 2)), Paint()..color = const Color(0x33000000));
    c.drawRRect(rr, _gh(fl, const [_steelDark, _steelLight, _steelMid]));
    c.drawRRect(rr, _stroke(_edge, 1));
    if (showJoints) {
      _bolt(c, Offset(p.dx, fl.top + 4), 1.5);
      _bolt(c, Offset(p.dx, fl.bottom - 4), 1.5);
    }
    if (isOn) {
      c.drawCircle(p, _w * 0.018 * (1 + 0.25 * pulse),
          _stroke(_chemGlow.withValues(alpha: 0.55 * (1 - 0.4 * pulse)), 1.6));
    }
  }

  // ------------------------------------------------------------- active glow
  void _drawActiveGlow(Canvas c) {
    // Glow removed
  }

  @override
  bool shouldRepaint(covariant DetailedMultiInjectorPainter old) =>
      old.isOn != isOn ||
          old.phase != phase ||
          old.showJoints != showJoints ||
          old.channelCount != channelCount ||
          !listEquals(old.channelStates, channelStates) ||
          !listEquals(old.channelNames, channelNames) ||
          !listEquals(old.fluidColors, fluidColors);
}

/// Animated wrapper for [DetailedMultiInjectorPainter].
class MultiInjectorView extends StatefulWidget {
  final bool isOn;
  final bool showJoints;
  final Size size;
  final int channelCount;
  final List<bool>? channelStates;
  final List<String>? channelNames;
  final List<Color>? fluidColors;

  const MultiInjectorView({
    super.key,
    required this.isOn,
    this.showJoints = true,
    required this.size,
    this.channelCount = 4,
    this.channelStates,
    this.channelNames,
    this.fluidColors,
  });

  /// Size with the skid's native proportions for a given width.
  static Size sizeForWidth(double width, {int channelCount = 4}) =>
      Size(width, width / DetailedMultiInjectorPainter.aspectRatioFor(channelCount));

  static Size sizeForHeight(double height, {int channelCount = 4}) =>
      Size(height * DetailedMultiInjectorPainter.aspectRatioFor(channelCount), height);

  @override
  State<MultiInjectorView> createState() => _MultiInjectorViewState();
}

class _MultiInjectorViewState extends State<MultiInjectorView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    if (widget.isOn) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant MultiInjectorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isOn && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: widget.size,
          painter: DetailedMultiInjectorPainter(
            isOn: widget.isOn,
            phase: _controller.value,
            showJoints: widget.showJoints,
            channelCount: widget.channelCount,
            channelStates: widget.channelStates,
            channelNames: widget.channelNames,
            fluidColors: widget.fluidColors,
          ),
        ),
      ),
    );
  }
}
