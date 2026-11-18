import 'dart:math';

import 'package:flutter/material.dart';



class WeatherMobileHeader extends StatelessWidget {
  final String city;
  final String temperature;
  final String feelsLike;
  final String time;
  final String sunrise;
  final String sunset;
  final String humidity;
  final String wind;
  final String pressure;

  const WeatherMobileHeader({
    super.key,
    required this.city,
    required this.temperature,
    required this.feelsLike,
    required this.time,
    required this.sunrise,
    required this.sunset,
    required this.humidity,
    required this.wind,
    required this.pressure,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B5E6E), Color(0xFF1E7F85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderTop(city: city),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LeftTemp(
                    temperature: temperature,
                    feelsLike: feelsLike,
                    sunrise: sunrise,
                    sunset: sunset,
                  ),
                  const Spacer(),
                  _CenterCondition(
                    time: time,
                  ),
                  const Spacer(),
                  _RightMetrics(
                    humidity: humidity,
                    wind: wind,
                    pressure: pressure,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: WaveClip(),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// HEADER TOP
// -----------------------------------------------------------------------------
class _HeaderTop extends StatelessWidget {
  final String city;

  const _HeaderTop({required this.city});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
  
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(city, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// LEFT TEMPERATURE
// -----------------------------------------------------------------------------
class _LeftTemp extends StatelessWidget {
  final String temperature;
  final String feelsLike;
  final String sunrise;
  final String sunset;

  const _LeftTemp({
    required this.temperature,
    required this.feelsLike,
    required this.sunrise,
    required this.sunset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$temperature °C",
          style: const TextStyle(
            fontSize: 48,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Feels like: $feelsLike °C",
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        _SunRow(title: "Sunrise", time: sunrise, icon: Icons.wb_sunny_outlined),
        const SizedBox(height: 10),
        _SunRow(title: "Sunset", time: sunset, icon: Icons.nightlight_round),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// CENTER ICON (DAY / NIGHT)
// -----------------------------------------------------------------------------
class _CenterCondition extends StatelessWidget {
  final String time;

  const _CenterCondition({
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TimeOfDayIcon(time: time),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// RIGHT METRICS
// -----------------------------------------------------------------------------
class _RightMetrics extends StatelessWidget {
  final String humidity;
  final String wind;
  final String pressure;

  const _RightMetrics({
    required this.humidity,
    required this.wind,
    required this.pressure,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Metric(icon: Icons.water, value: "$humidity %", label: "Humidity"),
        const SizedBox(height: 12),
        _Metric(icon: Icons.air, value: "$wind km/h", label: "Wind"),
        const SizedBox(height: 12),
        _Metric(icon: Icons.speed, value: "$pressure hPa", label: "Pressure"),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TIME BASED ICON
// -----------------------------------------------------------------------------
class TimeOfDayIcon extends StatelessWidget {
  final String time;

  const TimeOfDayIcon({super.key, required this.time});

  int get hour => int.parse(time.split(':')[0]);

  @override
  Widget build(BuildContext context) {
    if (hour >= 5 && hour < 12) {
      return _icon(Icons.brightness_6, Colors.orange);
    } else if (hour >= 12 && hour < 17) {
      return _icon(Icons.wb_sunny, Colors.yellow);
    } else if (hour >= 17 && hour < 20) {
      return _icon(Icons.brightness_6, Colors.deepOrange);
    } else {
      return _icon(Icons.nights_stay, Colors.deepPurple);
    }
  }

  Widget _icon(IconData icon, Color glow) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            glow.withOpacity(0.25),
            glow,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withOpacity(0.6),
            blurRadius: 25,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Icon(icon, size: 45, color: Colors.white),
    );
  }
}

// -----------------------------------------------------------------------------
// SMALL WIDGETS
// -----------------------------------------------------------------------------
class _SunRow extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;

  const _SunRow({
    required this.title,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(time,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}




class WaveClip extends StatefulWidget {
  const WaveClip({super.key});

  @override
  State<WaveClip> createState() => _WaveClipState();
}

class _WaveClipState extends State<WaveClip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // wave speed
    )..repeat(); // infinite loop
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return ClipPath(
          clipper: InfiniteWaveClipper(
            phase: _controller.value * 2 * pi,
            amplitude: 12,
            frequency: 1.5,
          ),
          child: Container(
            height: 40,
            color: Colors.teal.shade100,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class InfiniteWaveClipper extends CustomClipper<Path> {
  final double phase;
  final double amplitude;
  final double frequency;

  InfiniteWaveClipper({
    required this.phase,
    this.amplitude = 12,
    this.frequency = 1.5,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(0, height / 2);

    for (double x = 0; x <= width; x++) {
      // Subtract phase to move wave left → right
      final y = height / 2 + amplitude * sin((2 * pi * frequency * x / width) - phase);
      path.lineTo(x, y);
    }

    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(InfiniteWaveClipper oldClipper) => oldClipper.phase != phase;
}

