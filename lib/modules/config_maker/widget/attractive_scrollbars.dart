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
    this.canvasWidth = 2000,
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

  static const double _margin = 100.0;

  void _scrollToRatioX(double targetRatio, double maxTx, double spanTx) {
    final double clampedRatio = targetRatio.clamp(0.0, 1.0);
    final double targetTx = maxTx - clampedRatio * spanTx;
    final Matrix4 nextM = widget.tc.value.clone();
    nextM.storage[12] = targetTx;
    widget.tc.value = nextM;
  }

  void _scrollToRatioY(double targetRatio, double maxTy, double spanTy) {
    final double clampedRatio = targetRatio.clamp(0.0, 1.0);
    final double targetTy = maxTy - clampedRatio * spanTy;
    final Matrix4 nextM = widget.tc.value.clone();
    nextM.storage[13] = targetTy;
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

        final double vW = widget.viewportWidth;
        final double vH = widget.viewportHeight;

        final double contentW = widget.canvasWidth * scale;
        final double contentH = widget.canvasHeight * scale;

        // Translation bounds matching InteractiveViewer(boundaryMargin: EdgeInsets.all(100))
        final double minTx = math.min(0.0, vW - contentW) - _margin;
        const double maxTx = _margin;
        final double spanTx = math.max(0.0, maxTx - minTx);

        final double minTy = math.min(0.0, vH - contentH) - _margin;
        const double maxTy = _margin;
        final double spanTy = math.max(0.0, maxTy - minTy);

        final double currentTx = tx.clamp(minTx, maxTx);
        final double currentTy = ty.clamp(minTy, maxTy);

        final double ratioX = spanTx > 0 ? ((maxTx - currentTx) / spanTx).clamp(0.0, 1.0) : 0.0;
        final double ratioY = spanTy > 0 ? ((maxTy - currentTy) / spanTy).clamp(0.0, 1.0) : 0.0;

        // Horizontal Track & Thumb
        const double padLeftH = 6.0;
        const double padRightH = 20.0;
        final double trackW = math.max(100.0, vW - padLeftH - padRightH);
        final double visibleFractionX = (vW / (contentW + _margin * 2.0)).clamp(0.0, 1.0);
        final double thumbW = (trackW * visibleFractionX).clamp(
          math.min(30.0, trackW),
          math.max(30.0, trackW * 0.85),
        );
        final double availTrackW = math.max(1.0, trackW - thumbW);
        final double thumbLeft = availTrackW * ratioX;

        // Vertical Track & Thumb
        const double padTopV = 6.0;
        const double padBottomV = 20.0;
        final double trackH = math.max(100.0, vH - padTopV - padBottomV);
        final double visibleFractionY = (vH / (contentH + _margin * 2.0)).clamp(0.0, 1.0);
        final double thumbH = (trackH * visibleFractionY).clamp(
          math.min(30.0, trackH),
          math.max(30.0, trackH * 0.85),
        );
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
                    if (availTrackW <= 0) return;
                    final double localX = details.localPosition.dx;
                    final double targetRatio = (localX - thumbW / 2) / availTrackW;
                    _scrollToRatioX(targetRatio, maxTx, spanTx);
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
                              _scrollToRatioX(targetRatio, maxTx, spanTx);
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
                    if (availTrackH <= 0) return;
                    final double localY = details.localPosition.dy;
                    final double targetRatio = (localY - thumbH / 2) / availTrackH;
                    _scrollToRatioY(targetRatio, maxTy, spanTy);
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
                              _scrollToRatioY(targetRatio, maxTy, spanTy);
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
