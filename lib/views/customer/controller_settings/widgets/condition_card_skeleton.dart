import 'package:flutter/material.dart';

Widget buildConditionCardSkeleton() {
  return Card(
    color: Colors.white,
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 18, width: 120, color: Colors.grey.shade50),
          const SizedBox(height: 8),
          Container(height: 14, width: 180, color: Colors.grey.shade50),
          const SizedBox(height: 8),
          Divider(height: 0, color: Colors.grey.shade100),

          const SizedBox(height: 10),
          Container(height: 25, width: double.infinity, color: Colors.grey.shade50),
          Divider(height: 0, color: Colors.grey.shade100),

          const SizedBox(height: 10),
          Container(height: 25, width: double.infinity, color: Colors.grey.shade50),

          const SizedBox(height: 10),
          Container(height: 25, width: double.infinity, color: Colors.grey.shade50),

          const SizedBox(height: 10),
          Container(height: 25, width: double.infinity, color: Colors.grey.shade50),

          const SizedBox(height: 15),
          Container(height: 25, width: double.infinity, color: Colors.grey.shade50),
        ],
      ),
    ),
  );
}