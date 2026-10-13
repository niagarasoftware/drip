import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SensorPeriodCard extends StatelessWidget {
  final String title;
  final String minValue;
  final String maxValue;
  final String averageValue;

  const SensorPeriodCard({
    super.key,
    required this.title,
    required this.minValue,
    required this.maxValue,
    required this.averageValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _value('Average', averageValue),
              // _value('Max', maxValue),
              // _value('Min', minValue),
              SizedBox(),

               Container(
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F5EA),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    ' View Log',
                    style: TextStyle(
                      color: Color(0xFF1D9505),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),


            ],
          ),
        ],
      ),
    );
  }

  Widget _value(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}