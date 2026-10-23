import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom interactive scrollbars for the canvas InteractiveViewer.
class AttractiveScrollbars extends StatefulWidget {
  final TransformationController tc;
  final double viewportWidth;
  final double viewportHeight;
  final double canvasWidth;
  final double canvasHeight;

  const AttractiveScrollbars({
    super.key,
    required this.tc,
    required this.viewportWidth,
    required this.viewportHeight,
    this.canvasWidth = 3000,
    this.canvasHeight = 2000,
  });

  @override
  State<AttractiveScrollbars> createState() => _AttractiveScrollbarsState();
}

class _AttractiveScrollbarsState extends State<AttractiveScrollbars> {
  bool _hoverH = false;
  bool _hoverV = false;
  bool _dragH = false;
  bool _dragV = false;

  double _startThumbLeft = 0.0;
  double _startDragX = 0.0;

  double _startThumbTop = 0.0;
  double _startDragY = 0.0;

  void _scrollToRatioX(double targetRatio, double scale, double minVisX, double spanX) {
    final double clampedRatio = targetRatio.clamp(0.0, 1.0);
    final double newVisLeft = minVisX + clampedRatio * spanX;
    final Matrix4 nextM = widget.tc.value.clone();
    nextM.storage[12] = -newVisLeft * scale;
    widget.tc.value = nextM;
  }

  void _scrollToRatioY(double targetRatio, double scale, double minVisY, double spanY) {
    final double clampedRatio = targetRatio.clamp(0.0, 1.0);
    final double newVisTop = minVisY + clampedRatio * spanY;
    final Matrix4 nextM = widget.tc.value.clone();
    nextM.storage[13] = -newVisTop * scale;
    widget.tc.value = nextM;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.tc,
      builder: (context, _) {
        final Matrix4 m = widget.tc.value;
        final double scale = m.getMaxScaleOnAxis();
        final double tx = m.storage[12];
        final double ty = m.storage[13];

        final double visW = widget.viewportWidth / scale;
        final double visH = widget.viewportHeight / scale;

        const double minVisX = -300.0;
        final double maxVisX = widget.canvasWidth + 300.0 - visW;
        final double spanX = math.max(1.0, maxVisX - minVisX);

        const double minVisY = -300.0;
        final double maxVisY = widget.canvasHeight + 300.0 - visH;
        final double spanY = math.max(1.0, maxVisY - minVisY);

        final double visLeft = (-tx / scale).clamp(minVisX, maxVisX);
        final double visTop = (-ty / scale).clamp(minVisY, maxVisY);

        final double ratioX = ((visLeft - minVisX) / spanX).clamp(0.0, 1.0);
        final double ratioY = ((visTop - minVisY) / spanY).clamp(0.0, 1.0);

        // Horizontal Track & Thumb
        const double padLeftH = 6.0;
        const double padRightH = 20.0;
        final double trackW = math.max(100.0, widget.viewportWidth - padLeftH - padRightH);
        final double totalSpanW = widget.canvasWidth + 600.0;
        final double thumbW = (trackW * (visW / totalSpanW)).clamp(40.0, trackW * 0.85);
        final double availTrackW = math.max(1.0, trackW - thumbW);
        final double thumbLeft = availTrackW * ratioX;

        // Vertical Track & Thumb
        const double padTopV = 6.0;
        const double padBottomV = 20.0;
        final double trackH = math.max(100.0, widget.viewportHeight - padTopV - padBottomV);
        final double totalSpanH = widget.canvasHeight + 600.0;
        final double thumbH = (trackH * (visH / totalSpanH)).clamp(40.0, trackH * 0.85);
        final double availTrackH = math.max(1.0, trackH - thumbH);
        final double thumbTop = availTrackH * ratioY;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── HORIZONTAL SCROLLBAR ──
            Positioned(
              left: padLeftH,
              bottom: 4,
              width: trackW,
              height: 12,
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoverH = true),
                onExit: (_) => setState(() => _hoverH = false),
                child: GestureDetector(
                  onTapDown: (details) {
                    final double localX = details.localPosition.dx;
                    final double targetRatio = (localX - thumbW / 2) / availTrackW;
                    _scrollToRatioX(targetRatio, scale, minVisX, spanX);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _hoverH || _dragH ? 0.90 : 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_hoverH || _dragH ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1))
                            .withValues(alpha: 0.7),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: thumbLeft,
                          top: 1,
                          bottom: 1,
                          width: thumbW,
                          child: GestureDetector(
                            onPanStart: (details) {
                              setState(() {
                                _dragH = true;
                                _startThumbLeft = thumbLeft;
                                _startDragX = details.globalPosition.dx;
                              });
                            },
                            onPanEnd: (_) => setState(() => _dragH = false),
                            onPanCancel: () => setState(() => _dragH = false),
                            onPanUpdate: (details) {
                              if (availTrackW <= 0) return;
                              final double dx = details.globalPosition.dx - _startDragX;
                              final double targetThumbLeft = _startThumbLeft + dx;
                              final double targetRatio = targetThumbLeft / availTrackW;
                              _scrollToRatioX(targetRatio, scale, minVisX, spanX);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: (_dragH || _hoverH)
                                      ? const [Color(0xFF06B6D4), Color(0xFF0284C7)]
                                      : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7)
                                        .withValues(alpha: _dragH || _hoverH ? 0.55 : 0.30),
                                    blurRadius: _dragH || _hoverH ? 8 : 4,
                                    spreadRadius: _dragH || _hoverH ? 1 : 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (int i = 0; i < 3; i++)
                                      Container(
                                        width: 2,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(horizontal: 1.2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── VERTICAL SCROLLBAR ──
            Positioned(
              right: 4,
              top: padTopV,
              width: 12,
              height: trackH,
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoverV = true),
                onExit: (_) => setState(() => _hoverV = false),
                child: GestureDetector(
                  onTapDown: (details) {
                    final double localY = details.localPosition.dy;
                    final double targetRatio = (localY - thumbH / 2) / availTrackH;
                    _scrollToRatioY(targetRatio, scale, minVisY, spanY);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _hoverV || _dragV ? 0.90 : 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_hoverV || _dragV ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1))
                            .withValues(alpha: 0.7),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: thumbTop,
                          left: 1,
                          right: 1,
                          height: thumbH,
                          child: GestureDetector(
                            onPanStart: (details) {
                              setState(() {
                                _dragV = true;
                                _startThumbTop = thumbTop;
                                _startDragY = details.globalPosition.dy;
                              });
                            },
                            onPanEnd: (_) => setState(() => _dragV = false),
                            onPanCancel: () => setState(() => _dragV = false),
                            onPanUpdate: (details) {
                              if (availTrackH <= 0) return;
                              final double dy = details.globalPosition.dy - _startDragY;
                              final double targetThumbTop = _startThumbTop + dy;
                              final double targetRatio = targetThumbTop / availTrackH;
                              _scrollToRatioY(targetRatio, scale, minVisY, spanY);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: (_dragV || _hoverV)
                                      ? const [Color(0xFF06B6D4), Color(0xFF0284C7)]
                                      : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7)
                                        .withValues(alpha: _dragV || _hoverV ? 0.55 : 0.30),
                                    blurRadius: _dragV || _hoverV ? 8 : 4,
                                    spreadRadius: _dragV || _hoverV ? 1 : 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (int i = 0; i < 3; i++)
                                      Container(
                                        width: 5,
                                        height: 2,
                                        margin: const EdgeInsets.symmetric(vertical: 1.2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
