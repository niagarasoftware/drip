import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/widgets/periodicCard.dart';

class CO2Card extends StatelessWidget {
  final IconData icon;
  final int co2Value;
  final int maxValue;
  final String title;
  final String message;

  // Current day values
  final String min;
  final String max;
  final String other;

  // Last 7 days
  final double last7DaysMin;
  final double last7DaysMax;
  final double last7DaysAverage;

  // Last 30 days
  final double last30DaysMin;
  final double last30DaysMax;
  final double last30DaysAverage;

  const CO2Card({
    super.key,
    required this.co2Value,
    this.maxValue = 2000,
    this.title = 'CO2 Sensor',
    required this.message,
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

        const SizedBox(height: 12),

        Text(
          'CO2 Level: $co2Value ppm',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),
        _co2Bar(value: co2Value),
        const SizedBox(height: 12),

        Text(message),

        const SizedBox(height: 10),

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

  Widget _co2Bar({required int value}) {
    final safeMaxValue = maxValue <= 0 ? 1 : maxValue;
    final percent = (value / safeMaxValue).clamp(0.0, 1.0).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.yellow, Colors.red],
                ),
              ),
            ),
            Positioned(
              left: (percent * barWidth - 6)
                  .clamp(0.0, (barWidth - 12).clamp(0.0, barWidth))
                  .toDouble(),
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}