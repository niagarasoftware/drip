import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

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
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  Timer? _timer;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();

    // Controller for continuous visual animations (rotation, pulses, scanner)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Controller for 5-second loading progress
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _progressController.forward();

    // Timer to handle 5 second completion and smooth fade out
    _timer = Timer(widget.duration, () {
      if (!mounted) return;
      setState(() {
        _opacity = 0.0;
      });

      // Wait for fade transition before invoking onComplete
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onComplete?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _getStatusMessage(double progress) {
    if (progress < 0.22) {
      return 'AI analyzing site hardware & component specs...';
    } else if (progress < 0.48) {
      return 'Mapping water sources, pumps & filtration units...';
    } else if (progress < 0.72) {
      return 'Routing fertigation skids & valve networks...';
    } else if (progress < 0.92) {
      return 'Optimizing pipeline connections & node coordinates...';
    } else {
      return 'Finalizing AI site diagram layout...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _opacity,
      curve: Curves.easeOut,
      child: Container(
        color: const Color(0xff0B0F19), // Deep dark sleek background
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _progressAnimation]),
          builder: (context, child) {
            final progress = _progressAnimation.value;
            final pulseValue = _pulseController.value;

            return Stack(
              children: [
                // Custom Painter for AI Network Graph & Scanner Effects
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AiDiagramPainter(
                      pulseValue: pulseValue,
                      progress: progress,
                    ),
                  ),
                ),

                // Center Info Content
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xff161F30).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xff38BDF8).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff0284C7).withOpacity(0.25),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // AI Badge Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xff0284C7).withOpacity(0.2),
                                const Color(0xff6366F1).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xff38BDF8).withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: Color(0xff38BDF8),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'AI SITE GENERATOR',
                                style: TextStyle(
                                  color: Color(0xff38BDF8),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Title
                        const Text(
                          'Generating Site Diagram',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Animated Status Message
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _getStatusMessage(progress),
                            key: ValueKey(_getStatusMessage(progress)),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xff94A3B8),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Progress Bar & Percentage
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                  '${(progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Color(0xff38BDF8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Progress Bar Track
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progress.clamp(0.02, 1.0),
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xff0EA5E9),
                                            Color(0xff6366F1),
                                            Color(0xffA855F7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xff38BDF8)
                                                .withOpacity(0.6),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Subtitle warning/wait notice
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xff38BDF8).withOpacity(0.8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Please wait while AI constructs your site diagram layout...',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

class _AiDiagramPainter extends CustomPainter {
  final double pulseValue;
  final double progress;

  _AiDiagramPainter({
    required this.pulseValue,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Draw grid background
    final gridPaint = Paint()
      ..color = const Color(0xff1E293B).withOpacity(0.5)
      ..strokeWidth = 0.8;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Scanner Beam passing vertically
    final scanY = (pulseValue * size.height * 1.2) - (size.height * 0.1);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xff38BDF8).withOpacity(0.0),
          const Color(0xff38BDF8).withOpacity(0.18),
          const Color(0xff38BDF8).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 30, size.width, 60));

    canvas.drawRect(Rect.fromLTWH(0, scanY - 30, size.width, 60), scanPaint);

    final scanLinePaint = Paint()
      ..color = const Color(0xff38BDF8).withOpacity(0.4)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanLinePaint);

    // 3. Central Pulsing / Radar Rings
    final radiusMax = math.min(size.width, size.height) * 0.35;

    // Expanding wave
    final rippleRadius = (pulseValue * radiusMax * 1.5) % (radiusMax * 1.5);
    final rippleOpacity =
        (1.0 - (rippleRadius / (radiusMax * 1.5))).clamp(0.0, 1.0) * 0.35;
    final ripplePaint = Paint()
      ..color = const Color(0xff38BDF8).withOpacity(rippleOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, rippleRadius, ripplePaint);

    // Rotating dashed outer ring
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pulseValue * 2 * math.pi);

    final ringPaint = Paint()
      ..color = const Color(0xff6366F1).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    const int dashes = 12;
    const double dashAngle = (2 * math.pi) / dashes;
    for (int i = 0; i < dashes; i++) {
      if (i % 2 == 0) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: radiusMax * 0.85),
          i * dashAngle,
          dashAngle * 0.6,
          false,
          ringPaint,
        );
      }
    }
    canvas.restore();

    // 4. Graph Network Nodes (AI Diagram Layout under construction)
    final nodeOffsets = [
      Offset(center.dx - 180, center.dy - 120), // Water Source
      Offset(center.dx - 80, center.dy - 130), // Pump 1
      Offset(center.dx + 40, center.dy - 120), // Filter Site
      Offset(center.dx + 160, center.dy - 100), // Fertigation Skid
      Offset(center.dx + 170, center.dy + 80), // Main Valve
      Offset(center.dx + 20, center.dy + 120), // Field Valves
      Offset(center.dx - 140, center.dy + 100), // Irrigation Line
    ];

    final nodeConnections = [
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 4],
      [4, 5],
      [5, 6],
      [1, 6],
    ];

    final activeNodeCount =
        (progress * (nodeOffsets.length + 1)).clamp(0, nodeOffsets.length).toInt();

    // Draw connection lines
    for (var conn in nodeConnections) {
      final idx1 = conn[0];
      final idx2 = conn[1];
      if (idx1 < activeNodeCount && idx2 < activeNodeCount) {
        final p1 = nodeOffsets[idx1];
        final p2 = nodeOffsets[idx2];

        final linePaint = Paint()
          ..color = const Color(0xff38BDF8).withOpacity(0.4)
          ..strokeWidth = 2.0;
        canvas.drawLine(p1, p2, linePaint);

        // Particle pulse along connection line
        final t = (pulseValue * 2 + idx1) % 1.0;
        final particlePos = Offset.lerp(p1, p2, t)!;
        final particlePaint = Paint()
          ..color = const Color(0xffA855F7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
        canvas.drawCircle(particlePos, 4.0, particlePaint);
      }
    }

    // Draw nodes
    for (int i = 0; i < nodeOffsets.length; i++) {
      final pos = nodeOffsets[i];
      final isActivated = i < activeNodeCount;

      final nodePaint = Paint()
        ..color = isActivated
            ? const Color(0xff0EA5E9)
            : const Color(0xff334155)
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = isActivated
            ? const Color(0xff0EA5E9).withOpacity(0.5)
            : Colors.transparent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

      canvas.drawCircle(pos, 10.0, glowPaint);
      canvas.drawCircle(pos, 7.0, nodePaint);

      final innerPaint = Paint()
        ..color = isActivated ? Colors.white : const Color(0xff64748B);
      canvas.drawCircle(pos, 2.5, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AiDiagramPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || oldDelegate.progress != progress;
  }
}
