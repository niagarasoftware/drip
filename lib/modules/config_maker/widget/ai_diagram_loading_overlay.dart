import 'dart:math' as math;
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';
import '../view/utils/config_maker_colors.dart';

const _cyan = Color(0xff38BDF8);
const _sky = Color(0xff0EA5E9);
const _indigo = Color(0xff6366F1);
const _purple = Color(0xffA855F7);

/// Loading overlay for AI site diagram generation.
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
    // small pause so the user sees the finished state + 100%
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
    final colors = ConfigMakerColors.of(context);
    final isLight = colors.isLight;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _opacity,
      curve: Curves.easeOut,
      child: Container(
        color: colors.canvasBg,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _progressAnim]),
          builder: (context, _) {
            final p = _progressAnim.value;
            final pulse = _pulse.value;

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _BackgroundPainter(pulse: pulse, isLight: isLight)),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildCard(p, pulse, colors),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(double p, double pulse, ConfigMakerColors colors) {
    final isLight = colors.isLight;
    final primaryAccent = isLight ? const Color(0xff0284C7) : _cyan;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: 0.96)
              : const Color(0xff161F30).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isLight
                ? const Color(0xff0284C7).withValues(alpha: 0.35)
                : _cyan.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff0284C7).withValues(alpha: isLight ? 0.12 : 0.22),
              blurRadius: 32,
              spreadRadius: 2,
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
                  const Color(0xff0284C7).withValues(alpha: isLight ? 0.12 : 0.2),
                  _indigo.withValues(alpha: isLight ? 0.12 : 0.2),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: math.sin(pulse * 2 * math.pi) * 0.25,
                    child: Transform.scale(
                      scale: 1 + 0.12 * math.sin(pulse * 4 * math.pi),
                      child: Icon(Icons.auto_awesome_rounded,
                          size: 14, color: primaryAccent),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SITE GENERATOR',
                    style: TextStyle(
                      color: primaryAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Generating Site Diagram',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
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
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Stage chips
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _stages.length; i++)
                  _StageChip(
                    label: _stages[i].$1,
                    done: p >= _stages[i].$2,
                    active: p < _stages[i].$2 &&
                        (i == 0 || p >= _stages[i - 1].$2),
                    pulse: pulse,
                    isLight: isLight,
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Progress label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Processing Layout',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(p * 100).toInt()}%',
                  style: TextStyle(
                    color: primaryAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar with shimmer
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.08)),
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
                              width: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.55),
                                  Colors.white.withValues(alpha: 0),
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
  final bool isLight;

  const _StageChip({
    required this.label,
    required this.done,
    required this.active,
    required this.pulse,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? (isLight ? const Color(0xff16A34A) : const Color(0xff4ADE80))
        : active
        ? (isLight ? const Color(0xff0284C7) : _cyan)
        : (isLight ? const Color(0xff94A3B8) : const Color(0xff64748B));
    final glow = active ? 0.12 + 0.1 * math.sin(pulse * 2 * math.pi) : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: done ? 0.14 : 0.06 + glow),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: done || active ? 0.7 : 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: done
                ? Icon(Icons.check_circle_rounded,
                key: const ValueKey('done'), size: 13, color: color)
                : Icon(Icons.circle,
                key: ValueKey('dot$active'),
                size: active ? 8 : 6,
                color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
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
  final bool isLight;
  _BackgroundPainter({required this.pulse, required this.isLight});

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
        ..color = isLight
            ? const Color(0xffCBD5E1).withValues(alpha: 0.75)
            : const Color(0xff334155).withValues(alpha: 0.55)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // soft blue glow behind the scene
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0),
          radius: 0.9,
          colors: [
            const Color(0xff0284C7).withValues(alpha: isLight ? 0.08 : 0.16),
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
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: isLight ? 0.08 : 0.55),
          ],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) =>
      old.pulse != pulse || old.isLight != isLight;
}
