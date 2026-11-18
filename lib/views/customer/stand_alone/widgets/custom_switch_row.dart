import 'package:flutter/material.dart';

class CustomSwitchRow extends DataRow {
  CustomSwitchRow({
    required String iconPath,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) : super(
    cells: [
      DataCell(Center(
        child: Image.asset(iconPath, width: 30, height: 30),
      )),
      DataCell(Text(label,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ))),
      DataCell(Transform.scale(
        scale: 0.7,
        child: Switch(
          activeColor: Colors.teal,
          hoverColor: Colors.pink.shade100,
          value: value,
          onChanged: onChanged,
        ),
      )),
    ],
  );
}