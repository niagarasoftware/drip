import 'dart:math';

import 'package:flutter/cupertino.dart';

class CheckmarkPainter extends CustomPainter {
  final Color color;

  CheckmarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 // Adjust thickness
      ..strokeCap = StrokeCap.round; // Rounded stroke edges

    // Define the bounding rectangle for the arc
    double radius = size.width - 7;
    Rect arcRect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius,
    );

    // Draw partial circle (adjust start & sweep angle)
    canvas.drawArc(
      arcRect,
      0, // Start angle (top center)
      pi * 1.5, // Sweep angle (adjust to match image)
      false,
      outlinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}