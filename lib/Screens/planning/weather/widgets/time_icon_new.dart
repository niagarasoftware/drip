import 'package:flutter/material.dart';

class TimeIconNew extends StatelessWidget {
  final IconData icon;
  final RadialGradient gradient;
  final Color glowColor;

  const TimeIconNew({
    super.key,
    required this.icon,
    required this.gradient,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 40,
            color: Colors.white,
          ),
        ),

      ],
    );
  }
}