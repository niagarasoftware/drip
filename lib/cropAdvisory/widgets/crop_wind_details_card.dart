import 'package:flutter/material.dart';

class WindDetailsCard extends StatelessWidget {
  final String direction;

  final String speed;

  final String gust;

  const WindDetailsCard({super.key,required this.direction,required this.speed,required this.gust,});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
           Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Wind Speed"),
                    Text("$speed kph"),
                  ],
                ),

                const Divider(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Gusts"),
                    Text("$gust kph"),
                  ],
                ),

                const Divider(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Wind Direction"),
                    Text("$direction°NE"),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          const CircleAvatar(
            radius: 40,
            child: Text("260°"),
          ),
        ],
      ),
    );
  }
}