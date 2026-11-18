import 'package:flutter/material.dart';

class AirQualityCard extends StatelessWidget {
  final String co2;

  const AirQualityCard({super.key,required this.co2});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffDCE6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CO₂ Level: ${co2}ppm",
            style: const TextStyle(fontSize: 18),
          ),

          SizedBox(height: 20),

          const LinearProgressIndicator(
            value: 0.3,
          ),

          Spacer(),

          const Text(
            "\"Air quality is great! Perfect for outdoor activities.\"",
          ),
        ],
      ),
    );
  }
}