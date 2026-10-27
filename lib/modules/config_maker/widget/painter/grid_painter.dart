import 'package:flutter/material.dart';

/// CustomPainter drawing the background grid lines on the site canvas.
class GridPainter extends CustomPainter {
  final bool isLight;
  const GridPainter({this.isLight = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isLight
              ? const Color(0xFFCBD5E1).withValues(alpha: 0.6)
              : const Color(0xFF20274B).withValues(alpha: 0.5))
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => oldDelegate.isLight != isLight;
}
