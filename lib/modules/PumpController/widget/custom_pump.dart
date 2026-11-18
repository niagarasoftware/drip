import "dart:math";

import "package:flutter/material.dart";

Widget getTypesOfPump({
  required int mode,
  required AnimationController controller,
  required double animationValue,
}) {
  return AnimatedBuilder(
    animation: controller,
    builder: (BuildContext context, Widget? child) {
      return CustomPaint(
        painter: Pump(
          rotationAngle: [1].contains(mode) ? animationValue : 0,
          mode: mode,
        ),
        size: const Size(100, 80),
      );
    },
  );
}

class Pump extends CustomPainter {
  final double rotationAngle;
  final int mode;

  Pump({required this.rotationAngle, required this.mode});

  final List<Color> pipeColor = const [Color(0xff166890), Color(0xff45C9FA), Color(0xff166890)];
  final List<Color> bodyColor = const [Color(0xffC7BEBE), Colors.white, Color(0xffC7BEBE)];
  final List<Color> headColorOn = const [Color(0xff097E54), Color(0xff10E196), Color(0xff097E54)];
  final List<Color> headColorOff = const [Color(0xff540000), Color(0xffB90000), Color(0xff540000)];
  final List<Color> headColorFault = const [Color(0xffF66E21), Color(0xffFFA06B), Color(0xffF66E21)];
  final List<Color> headColorIdle = [Colors.grey, Colors.grey.shade300, Colors.grey];

  List<Color> getMotorColor() {
    switch (mode) {
      case 1:
        return headColorOn;
      case 2:
        return headColorFault;
      case 3:
        return headColorOff;
      default:
        return headColorIdle;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Motor Head
    Paint motorHead = Paint()
      ..style = PaintingStyle.fill
      ..shader = getLinearShaderHor(getMotorColor(), Rect.fromCenter(center: const Offset(50, 20), width: 45, height: 40));
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(center: const Offset(50, 20), width: 45, height: 40),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
        bottomLeft: const Radius.circular(5),
      ),
      motorHead,
    );

    // Horizontal Lines
    Paint line = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    double startingPosition = 26;
    double lineGap = 8;
    for (var i = 0; i < 7; i++) {
      canvas.drawLine(
        Offset(startingPosition + (i * lineGap), 5),
        Offset(startingPosition + (i * lineGap), 35),
        line,
      );
    }
    canvas.drawLine(const Offset(28, 5), const Offset(72, 5), line);
    canvas.drawLine(const Offset(28, 35), const Offset(72, 35), line);

    // Pump Body
    Paint neck = Paint()
      ..shader = getLinearShaderHor(bodyColor, Rect.fromCenter(center: const Offset(50, 45), width: 20, height: 10));
    canvas.drawRect(Rect.fromCenter(center: const Offset(50, 45), width: 20, height: 10), neck);

    Paint body = Paint()
      ..style = PaintingStyle.fill
      ..shader = getLinearShaderHor(bodyColor, Rect.fromCenter(center: const Offset(50, 64), width: 35, height: 28));
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(center: const Offset(50, 64), width: 35, height: 28),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
        bottomLeft: const Radius.circular(5),
      ),
      body,
    );

    // Pump Joints
    Paint joint = Paint()
      ..shader = getLinearShaderVert(bodyColor, Rect.fromCenter(center: const Offset(30, 64), width: 6, height: 15));
    canvas.drawRect(Rect.fromCenter(center: const Offset(30, 64), width: 6, height: 15), joint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(70, 64), width: 6, height: 15), joint);

    // Pump Shoulders
    Paint shoulder1 = Paint()
      ..shader = getLinearShaderVert(bodyColor, Rect.fromCenter(center: const Offset(24, 64), width: 6, height: 20));
    canvas.drawRect(Rect.fromCenter(center: const Offset(24, 64), width: 6, height: 20), shoulder1);
    canvas.drawRect(Rect.fromCenter(center: const Offset(75, 64), width: 6, height: 20), shoulder1);

    Paint shoulder2 = Paint()
      ..shader = getLinearShaderVert(pipeColor, Rect.fromCenter(center: const Offset(30, 64), width: 6, height: 15));
    canvas.drawRect(Rect.fromCenter(center: const Offset(20, 64), width: 6, height: 20), shoulder2);
    canvas.drawRect(Rect.fromCenter(center: const Offset(80, 64), width: 6, height: 20), shoulder2);

    // Pump Hands
    Paint hand = Paint()
      ..shader = getLinearShaderVert(pipeColor, Rect.fromCenter(center: const Offset(30, 64), width: 6, height: 15));
    canvas.drawRect(Rect.fromCenter(center: const Offset(10, 64), width: 18, height: 15), hand);
    canvas.drawRect(Rect.fromCenter(center: const Offset(90, 64), width: 18, height: 15), hand);

    // Rotating Blades
    Paint paint = Paint()..color = Colors.blueGrey;
    double centerX = 50;
    double centerY = 65;
    double radius = 8;
    double angle = (2 * pi) / 4; // Angle between each rectangle
    double rectangleWidth = 8;
    double rectangleHeight = 10;

    for (int i = 0; i < 4; i++) {
      double x = centerX + radius * cos(i * angle + rotationAngle / 2);
      double y = centerY + radius * sin(i * angle + rotationAngle / 2);
      double rotation = i * angle - pi / 2 + rotationAngle; // Rotate rectangles to fit the circle

      canvas.save(); // Save canvas state before rotation
      canvas.translate(x, y); // Translate to the position
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(-rectangleWidth / 2, -rectangleHeight / 2, rectangleWidth, rectangleHeight),
          bottomLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(80),
          topLeft: const Radius.circular(40),
          topRight: const Radius.circular(40),
        ),
        paint,
      );
      canvas.restore(); // Restore canvas state after rotation
    }

    // Small Circle at Center
    Paint smallCircle = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 4, smallCircle);
  }

  Shader getLinearShaderVert(List<Color> colors, Rect rect) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    ).createShader(rect);
  }

  Shader getLinearShaderHor(List<Color> colors, Rect rect) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: colors,
    ).createShader(rect);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}