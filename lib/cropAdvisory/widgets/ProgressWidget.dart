import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class ProgressWidget extends StatelessWidget {
  final int current;

  const ProgressWidget({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
            (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            decoration: BoxDecoration(
              color: index < current
                  ? const Color(0xff0E8797)
                  : const Color(0xffC8D0E0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
