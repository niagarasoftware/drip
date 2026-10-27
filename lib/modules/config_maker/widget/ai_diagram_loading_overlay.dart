import 'dart:math' as math;
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';

const _cyan = Color(0xff38BDF8);
const _sky = Color(0xff0EA5E9);
const _indigo = Color(0xff6366F1);
const _purple = Color(0xffA855F7);
const _bg = Color(0xff0B0F19);

/// Loading overlay that "draws" the irrigation site diagram live:
/// water sources -> pumps -> manifold -> tank -> main pump -> field valves.
class AiDiagramLoadingOverlay extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration duration;

  const AiDiagramLoadingOverlay({
    super.key,
    this.onComplete,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<AiDiagramLoadingOverlay> createState() =>
      _AiDiagramLoadingOverlayState();
}

class _AiDiagramLoadingOverlayState extends State<AiDiagramLoadingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _progress;
  late final Animation<double> _progressAnim;
  double _opacity = 1.0;

  static const _stages = [
    ('Sources', 0.20),
    ('Pumps', 0.48),
    ('Tank', 0.74),
    ('Valves', 0.97),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _progress = AnimationController(vsync: this, duration: widget.duration);
    _progressAnim = CurvedAnimation(
      parent: _progress,
      curve: Curves.easeInOutCubic,
    );

    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
    _progress.forward();
  }

  Future<void> _finish() async {
    // small pause so the user sees the finished diagram + 100%
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _opacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) widget.onComplete?.call();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _progress.dispose();
    super.dispose();
  }

  String _statusMessage(double p) {
    if (p < 0.20) return 'Analyzing site hardware & component specs...';
    if (p < 0.48) return 'Mapping water sources, pumps & filtration...';
    if (p < 0.74) return 'Routing manifolds, tanks & pipelines...';
    if (p < 0.95) return 'Connecting field valves & irrigation zones...';
    return 'Finalizing your site diagram layout...';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _opacity,
      curve: Curves.easeOut,
      child: Container(
        color: _bg,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _progressAnim]),
          builder: (context, _) {
            final p = _progressAnim.value;
            final pulse = _pulse.value;

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _BackgroundPainter(pulse)),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      // Live drawing of the site diagram
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _ScenePainter(pulse: pulse, progress: p),
                          ),
                        ),
                      ),
                      _buildCard(p, pulse),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(double p, double pulse) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 30 * (1 - v)), child: child),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: const Color(0xff161F30).withOpacity(0.88),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _cyan.withOpacity(0.3), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff0284C7).withOpacity(0.22),
              blurRadius: 30,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xff0284C7).withOpacity(0.2),
                  _indigo.withOpacity(0.2),
                ]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cyan.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: math.sin(pulse * 2 * math.pi) * 0.25,
                    child: Transform.scale(
                      scale: 1 + 0.12 * math.sin(pulse * 4 * math.pi),
                      child: const Icon(Icons.auto_awesome_rounded,
                          size: 15, color: _cyan),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI SITE GENERATOR',
                    style: TextStyle(
                      color: _cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Generating Site Diagram',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                      begin: const Offset(0, 0.4), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                _statusMessage(p),
                key: ValueKey(_statusMessage(p)),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff94A3B8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stage chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < _stages.length; i++)
                  _StageChip(
                    label: _stages[i].$1,
                    done: p >= _stages[i].$2,
                    active: p < _stages[i].$2 &&
                        (i == 0 || p >= _stages[i - 1].$2),
                    pulse: pulse,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Processing Layout',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(p * 100).toInt()}%',
                  style: const TextStyle(
                    color: _cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar with shimmer
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(color: Colors.white.withOpacity(0.08)),
                    FractionallySizedBox(
                      widthFactor: p.clamp(0.02, 1.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [_sky, _indigo, _purple]),
                            ),
                          ),
                          Align(
                            alignment: Alignment(pulse * 4 - 2, 0),
                            child: Container(
                              width: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.55),
                                  Colors.white.withOpacity(0),
                                ]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  final double pulse;

  const _StageChip({
    required this.label,
    required this.done,
    required this.active,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? const Color(0xff4ADE80)
        : active
        ? _cyan
        : const Color(0xff64748B);
    final glow = active ? 0.12 + 0.1 * math.sin(pulse * 2 * math.pi) : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(done ? 0.14 : 0.06 + glow),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(done || active ? 0.7 : 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: done
                ? Icon(Icons.check_circle_rounded,
                key: const ValueKey('done'), size: 12, color: color)
                : Icon(Icons.circle,
                key: ValueKey('dot$active'),
                size: active ? 8 : 6,
                color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background: drifting dot grid, vignette
// ---------------------------------------------------------------------------
class _BackgroundPainter extends CustomPainter {
  final double pulse;
  _BackgroundPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    const step = 28.0;
    final shift = pulse * step; // seamless loop
    final pts = <Offset>[];
    for (double x = -step + shift; x < size.width + step; x += step) {
      for (double y = -step + shift; y < size.height + step; y += step) {
        pts.add(Offset(x, y));
      }
    }
    canvas.drawPoints(
      PointMode.points,
      pts,
      Paint()
        ..color = const Color(0xff334155).withOpacity(0.55)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // soft blue glow behind the scene
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 0.9,
          colors: [
            const Color(0xff0284C7).withOpacity(0.16),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.1,
          colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => old.pulse != pulse;
}

// ---------------------------------------------------------------------------
// Scene: the irrigation diagram being "drawn"
// ---------------------------------------------------------------------------
enum _NodeType { source, pump, tank, valve }

class _Node {
  final _NodeType type;
  final Offset pos; // normalized 0..1
  final double start; // progress when it appears
  const _Node(this.type, this.pos, this.start);
}

class _Pipe {
  final List<Offset> points; // normalized 0..1
  final double start;
  final double end;
  const _Pipe(this.points, this.start, this.end);
}

const _nodes = <_Node>[
  _Node(_NodeType.source, Offset(0.07, 0.22), 0.00),
  _Node(_NodeType.source, Offset(0.07, 0.72), 0.03),
  _Node(_NodeType.pump, Offset(0.32, 0.12), 0.18),
  _Node(_NodeType.pump, Offset(0.32, 0.37), 0.21),
  _Node(_NodeType.pump, Offset(0.32, 0.62), 0.24),
  _Node(_NodeType.pump, Offset(0.32, 0.87), 0.27),
  _Node(_NodeType.tank, Offset(0.60, 0.50), 0.48),
  _Node(_NodeType.pump, Offset(0.76, 0.50), 0.68),
  _Node(_NodeType.valve, Offset(0.95, 0.18), 0.86),
  _Node(_NodeType.valve, Offset(0.95, 0.50), 0.89),
  _Node(_NodeType.valve, Offset(0.95, 0.82), 0.92),
];

const _pipes = <_Pipe>[
  // sources -> pumps
  _Pipe([Offset(0.07, 0.22), Offset(0.20, 0.22), Offset(0.20, 0.12), Offset(0.32, 0.12)], 0.06, 0.20),
  _Pipe([Offset(0.20, 0.22), Offset(0.20, 0.37), Offset(0.32, 0.37)], 0.12, 0.22),
  _Pipe([Offset(0.07, 0.72), Offset(0.20, 0.72), Offset(0.20, 0.62), Offset(0.32, 0.62)], 0.08, 0.22),
  _Pipe([Offset(0.20, 0.72), Offset(0.20, 0.87), Offset(0.32, 0.87)], 0.14, 0.24),
  // pumps -> manifold
  _Pipe([Offset(0.32, 0.12), Offset(0.46, 0.12), Offset(0.46, 0.50)], 0.26, 0.40),
  _Pipe([Offset(0.32, 0.37), Offset(0.46, 0.37)], 0.30, 0.40),
  _Pipe([Offset(0.32, 0.62), Offset(0.46, 0.62)], 0.32, 0.42),
  _Pipe([Offset(0.32, 0.87), Offset(0.46, 0.87), Offset(0.46, 0.50)], 0.34, 0.48),
  // manifold -> tank -> main pump
  _Pipe([Offset(0.46, 0.50), Offset(0.60, 0.50)], 0.46, 0.58),
  _Pipe([Offset(0.60, 0.50), Offset(0.76, 0.50)], 0.58, 0.70),
  // main pump -> field valves
  _Pipe([Offset(0.76, 0.50), Offset(0.86, 0.50), Offset(0.86, 0.18), Offset(0.95, 0.18)], 0.74, 0.90),
  _Pipe([Offset(0.86, 0.50), Offset(0.95, 0.50)], 0.78, 0.92),
  _Pipe([Offset(0.86, 0.50), Offset(0.86, 0.82), Offset(0.95, 0.82)], 0.76, 0.94),
];

class _ScenePainter extends CustomPainter {
  final double pulse;
  final double progress;
  _ScenePainter({required this.pulse, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width * 0.045, size.height * 0.075).clamp(9.0, 20.0);
    final scene = Rect.fromLTWH(r * 1.5, r * 1.5, size.width - r * 3, size.height - r * 3);
    Offset map(Offset n) =>
        Offset(scene.left + n.dx * scene.width, scene.top + n.dy * scene.height);

    _drawScanner(canvas, size);
    _drawPipes(canvas, map, r);
    for (final n in _nodes) {
      _drawNode(canvas, n, map(n.pos), r);
    }
  }

  void _drawScanner(Canvas canvas, Size size) {
    final x = pulse * (size.width + 120) - 60;
    final rect = Rect.fromLTWH(x - 60, 0, 120, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(colors: [
          _cyan.withOpacity(0),
          _cyan.withOpacity(0.10),
          _cyan.withOpacity(0),
        ]).createShader(rect),
    );
  }

  void _drawPipes(Canvas canvas, Offset Function(Offset) map, double r) {
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = r * 0.42
      ..color = const Color(0xff94A3B8).withOpacity(0.55);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = r * 0.2
      ..color = const Color(0xff0C4A6E);
    final particle = Paint()
      ..color = _cyan
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.5);
    final head = Paint()
      ..color = _purple
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (final pipe in _pipes) {
      final raw = ((progress - pipe.start) / (pipe.end - pipe.start)).clamp(0.0, 1.0);
      if (raw <= 0) continue;

      final path = Path();
      final pts = pipe.points.map(map).toList();
      path.moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      final metric = path.computeMetrics().first;
      final drawn = metric.length * Curves.easeInOut.transform(raw);
      final sub = metric.extractPath(0, drawn);

      canvas.drawPath(sub, outer);
      canvas.drawPath(sub, inner);

      // flowing water particles
      if (drawn > 10) {
        for (var i = 0; i < 3; i++) {
          final d = ((pulse * 1.5 + i / 3) % 1.0) * drawn;
          final t = metric.getTangentForOffset(d);
          if (t != null) canvas.drawCircle(t.position, r * 0.13, particle);
        }
      }

      // glowing "drawing head"
      if (raw < 1) {
        final t = metric.getTangentForOffset(drawn);
        if (t != null) {
          canvas.drawCircle(t.position, r * 0.55, head);
          canvas.drawCircle(t.position, r * 0.16, Paint()..color = Colors.white);
        }
      }
    }
  }

  void _drawNode(Canvas canvas, _Node n, Offset c, double r) {
    final raw = ((progress - n.start) / 0.08).clamp(0.0, 1.0);
    if (raw <= 0) return;
    final scale = Curves.easeOutBack.transform(raw);

    // appear ring
    if (raw < 1) {
      canvas.drawCircle(
        c,
        r * (1.0 + raw * 1.6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _cyan.withOpacity((1 - raw) * 0.7),
      );
    }

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);

    switch (n.type) {
      case _NodeType.source:
        _drawSource(canvas, r);
        break;
      case _NodeType.pump:
        _drawPump(canvas, r);
        break;
      case _NodeType.tank:
        _drawTank(canvas, r);
        break;
      case _NodeType.valve:
        _drawValve(canvas, r);
        break;
    }
    canvas.restore();
  }

  void _glow(Canvas canvas, double radius, Color color) {
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _drawSource(Canvas canvas, double r) {
    _glow(canvas, r * 1.3, _sky);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: r * 2.3, height: r * 1.8),
      Radius.circular(r * 0.35),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xff0C4A6E));

    canvas.save();
    canvas.clipRRect(rrect);
    final wave = Path()..moveTo(-r * 1.2, r);
    for (double x = -r * 1.2; x <= r * 1.2; x += 2) {
      final y = math.sin((x / r) * 2.4 + pulse * 2 * math.pi * 2) * r * 0.1 - r * 0.05;
      wave.lineTo(x, y);
    }
    wave.lineTo(r * 1.2, r);
    wave.close();
    canvas.drawPath(wave, Paint()..color = _sky.withOpacity(0.85));
    canvas.restore();

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _cyan,
    );
  }

  void _drawPump(Canvas canvas, double r) {
    const green = Color(0xff22C55E);
    _glow(canvas, r * 1.3, green);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xff4ADE80), Color(0xff166534)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xff86EFAC),
    );

    // spinning impeller
    canvas.save();
    canvas.rotate(pulse * 2 * math.pi * 3);
    final blade = Paint()
      ..color = Colors.white
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final a = i * 2 * math.pi / 3;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(a), math.sin(a)) * r * 0.62,
        blade,
      );
    }
    canvas.restore();
    canvas.drawCircle(Offset.zero, r * 0.14, Paint()..color = const Color(0xff14532D));
  }

  void _drawTank(Canvas canvas, double r) {
    _glow(canvas, r * 1.4, _indigo);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: r * 2.2, height: r * 2.4),
      Radius.circular(r * 0.3),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xff1E1B4B));

    canvas.save();
    canvas.clipRRect(rrect);
    final fill = 0.15 + 0.8 * ((progress - 0.5) / 0.45).clamp(0.0, 1.0);
    final top = r * 1.2 - (r * 2.4 * fill);
    final wave = Path()..moveTo(-r * 1.2, r * 1.3);
    for (double x = -r * 1.2; x <= r * 1.2; x += 2) {
      wave.lineTo(x, top + math.sin((x / r) * 2.6 - pulse * 2 * math.pi * 2) * r * 0.1);
    }
    wave.lineTo(r * 1.2, r * 1.3);
    wave.close();
    canvas.drawPath(
      wave,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cyan, _indigo.withOpacity(0.9)],
        ).createShader(Rect.fromCenter(center: Offset.zero, width: r * 2.4, height: r * 2.6)),
    );
    canvas.restore();

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xffA5B4FC),
    );
  }

  void _drawValve(Canvas canvas, double r) {
    const amber = Color(0xffF59E0B);
    final breathe = 0.5 + 0.5 * math.sin(pulse * 2 * math.pi * 2);
    _glow(canvas, r * (1.1 + 0.3 * breathe), amber);
    canvas.drawCircle(Offset.zero, r * 0.85, Paint()..color = const Color(0xff1F2937));
    canvas.drawCircle(
      Offset.zero,
      r * 0.85,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = amber,
    );
    final s = r * 0.42;
    final bow = Path()
      ..moveTo(-s, -s)
      ..lineTo(s, s)
      ..lineTo(s, -s)
      ..lineTo(-s, s)
      ..close();
    canvas.drawPath(bow, Paint()..color = amber);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) =>
      old.pulse != pulse || old.progress != progress;
}