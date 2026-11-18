import 'package:flutter/material.dart';

class ConditionTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const ConditionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget verticalDivider() => Container(
      width: 0.5,
      height: 40,
      color: Colors.grey,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        verticalDivider(),
        Expanded(
          child: RadioListTile<String>(
            title: const Text("Sensor"),
            value: 'Sensor',
            groupValue: selectedType,
            onChanged: (value) => onTypeChanged(value!),
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
            activeColor: Theme.of(context).primaryColorLight,
          ),
        ),
        verticalDivider(),
        Expanded(
          child: RadioListTile<String>(
            title: const Text("Program"),
            value: 'Program',
            groupValue: selectedType,
            onChanged: (value) => onTypeChanged(value!),
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
            activeColor: Theme.of(context).primaryColorLight,
          ),
        ),
        verticalDivider(),
        Expanded(
          child: RadioListTile<String>(
            title: const Text("Combined"),
            value: 'Combined',
            groupValue: selectedType,
            onChanged: (value) => onTypeChanged(value!),
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
            activeColor: Theme.of(context).primaryColorLight,
          ),
        ),
        verticalDivider(),
      ],
    );
  }
}