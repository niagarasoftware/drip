import 'package:flutter/material.dart';

class WeatherInfoCard extends StatelessWidget {
  final String humm;

  final String rain;

  final String wind;

  const WeatherInfoCard({super.key,required this.humm,required this.rain,required this.wind,});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child:  Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                "${humm}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Humidity"),
            ],
          ),

          Column(
            children: [
              Text(
                "${rain}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Rain Fall"),
            ],
          ),

          Column(
            children: [
              Text(
                "${wind}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Wind Speed"),
            ],
          ),
        ],
      ),
    );
  }
}