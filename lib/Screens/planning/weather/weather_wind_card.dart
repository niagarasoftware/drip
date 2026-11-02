
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_svg/svg.dart';

class WindCard extends StatelessWidget {
    final double directionAngle;
    final IconData icon;

  const WindCard({
    super.key,
      required this.directionAngle,
      required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _baseCard(
      title: "Wind Direction",
      icon: icon,
      child: Column(
        children: [

          _KeyValueRow("$directionAngle°", getDirection(directionAngle)) ,
          const SizedBox(width: 12),
          _WindCompass(angle: directionAngle),
        ],
      ),
    );
  }
}
String getDirection(double directionAngle) {
  directionAngle = directionAngle % 360;

  if (directionAngle >= 337.5 || directionAngle < 22.5) {
    return "North";
  } else if (directionAngle >= 22.5 && directionAngle < 67.5) {
    return "North-East";
  } else if (directionAngle >= 67.5 && directionAngle < 112.5) {
    return "East";
  } else if (directionAngle >= 112.5 && directionAngle < 157.5) {
    return "South-East";
  } else if (directionAngle >= 157.5 && directionAngle < 202.5) {
    return "South";
  } else if (directionAngle >= 202.5 && directionAngle < 247.5) {
    return "South-West";
  } else if (directionAngle >= 247.5 && directionAngle < 292.5) {
    return "West";
  } else {
    return "North-West";
  }
}

class _KeyValueRow extends StatelessWidget {
  final String keyText;
  final String value;

  const _KeyValueRow(this.keyText, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Text('$keyText - $value',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _WindCompass extends StatelessWidget {
  final double angle;
  const _WindCompass({required this.angle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background SVG
          SvgPicture.asset(
            'assets/Images/Svg/winddirection.svg',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),

          // ✅ Center text (degree value)
          Text(
            "${angle.toInt()}°",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
           // ✅ Arrow on edge, rotating around center
          Transform.rotate(
            angle: angle * math.pi / 180,
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: const Icon(
                Icons.navigation,
                size: 18,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _baseCard({required String title,required IconData icon, required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}
