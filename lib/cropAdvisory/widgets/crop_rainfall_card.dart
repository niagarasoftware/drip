import 'package:flutter/material.dart';

class CropRainfallCard extends StatelessWidget {
  final String rainfall;

  const CropRainfallCard({super.key,required this.rainfall});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff3B4A73),
        borderRadius: BorderRadius.circular(20),
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${rainfall} mm",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),

          SizedBox(height: 10),

          Text(
            "Rainfall: 0.2 in expected",
            style: TextStyle(color: Colors.white),
          ),

          Spacer(),

          Text(
            "Light rain expected\nin the evening.",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}