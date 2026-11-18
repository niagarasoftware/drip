import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WindCard extends StatelessWidget {
  final double directionAngle;
  final IconData icon;
  final int statusCode;

  const WindCard({
    super.key,
    required this.directionAngle,
    required this.icon,
    required this.statusCode,
  });

  @override
  Widget build(BuildContext context) {
    final String direction = getDirection(directionAngle);

    return Container(
      width: double.infinity,
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================
          // HEADER
          // ==========================
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Wind Direction',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Status in header

            ],
          ),
          const SizedBox(height: 10),


          Row(
            children: [
              SizedBox(width: 48,),
              Text(
                statusCode == 255 ? 'Normal' : 'Alert',
                style: TextStyle(
                  color: _statusColor(statusCode),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),


          // ==========================
          // CURRENT DIRECTION TEXT
          // ==========================

          const SizedBox(height: 10),
          Text(
            '${directionAngle.toStringAsFixed(0)}° - $direction',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // ==========================
          // COMPASS
          // ==========================
          Center(
            child: _WindCompass(
              angle: directionAngle,
            ),
          ),

          const Spacer(),

          // ==========================
          // CURRENT DIRECTION CARD
          // ==========================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Direction',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Text(
                      '${directionAngle.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        direction,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATUS COLOR
// ============================================================

Color _statusColor(int code) {
  if (code == 255) {
    return Colors.green.shade700;
  }

  switch (code) {
    case 1:
      return Colors.red.shade700;

    case 2:
      return Colors.yellow.shade700;

    case 3:
      return Colors.orange.shade700;

    default:
      return Colors.grey.shade600;
  }
}

// ============================================================
// DIRECTION
// ============================================================

String getDirection(double directionAngle) {
  directionAngle = ((directionAngle % 360) + 360) % 360;

  if (directionAngle >= 337.5 || directionAngle < 22.5) {
    return 'North';
  } else if (directionAngle < 67.5) {
    return 'North-East';
  } else if (directionAngle < 112.5) {
    return 'East';
  } else if (directionAngle < 157.5) {
    return 'South-East';
  } else if (directionAngle < 202.5) {
    return 'South';
  } else if (directionAngle < 247.5) {
    return 'South-West';
  } else if (directionAngle < 292.5) {
    return 'West';
  } else {
    return 'North-West';
  }
}

// ============================================================
// COMPASS
// ============================================================

class _WindCompass extends StatelessWidget {
  final double angle;

  const _WindCompass({
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 125,
      height: 125,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/Images/Svg/winddirection.svg',
            width: 125,
            height: 125,
            fit: BoxFit.contain,
          ),

          // Degree
          Text(
            '${angle.toInt()}°',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Arrow
          Transform.rotate(
            angle: angle * math.pi / 180,
            child: Transform.translate(
              offset: const Offset(
                0,
                -30,
              ),
              child: const Icon(
                Icons.navigation,
                size: 22,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}