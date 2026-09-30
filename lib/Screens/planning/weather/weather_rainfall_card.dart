import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/widgets/periodicCard.dart';

class RainfallCard extends StatelessWidget {
  final String title;
  final String rainfallValue;
  final String forecastText;
  final String description;
  final Color backgroundColor;
  final String min;
  final String max;
  final String other;
  final IconData icon;

  // Last 7 days
  final double last7DaysMin;
  final double last7DaysMax;
  final double last7DaysAverage;

  // Last 30 days
  final double last30DaysMin;
  final double last30DaysMax;
  final double last30DaysAverage;

  const RainfallCard({
    super.key,
    this.title = 'Rainfall',
    required this.rainfallValue,
    required this.forecastText,
    required this.description,
    required this.min,
    required this.max,
    required this.other,
    required this.icon,
    required this.last7DaysMin,
    required this.last7DaysMax,
    required this.last7DaysAverage,
    required this.last30DaysMin,
    required this.last30DaysMax,
    required this.last30DaysAverage,
    this.backgroundColor = const Color(0xFF3C4B6C),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 5),
        Text(
          '$rainfallValue mm',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(forecastText, style: const TextStyle(color: Colors.black)),
        const SizedBox(height: 5),
        Text(description, style: const TextStyle(color: Colors.black)),
        const SizedBox(height: 1),

        SensorPeriodCard(
          title: 'Current Day',
          minValue: min,
          maxValue: max,
          averageValue: other,
        ),
        const SizedBox(height: 10),

        SensorPeriodCard(
          title: 'Last 7 Days',
          minValue: last7DaysMin.toString(),
          maxValue: last7DaysMax.toString(),
          averageValue: last7DaysAverage.toString(),
        ),
        const SizedBox(height: 10),

        SensorPeriodCard(
          title: 'Last Month',
          minValue: last30DaysMin.toString(),
          maxValue: last30DaysMax.toString(),
          averageValue: last30DaysAverage.toString(),
        ),
      ],
    );
  }
}