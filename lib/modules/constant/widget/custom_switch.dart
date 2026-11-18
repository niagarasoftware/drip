import 'package:flutter/material.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;
  final void Function(bool?)? onChanged;
  const CustomSwitch({super.key, required this.value,required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      activeColor: Theme.of(context).primaryColorLight,
      value: value,
      onChanged: onChanged,
      activeTrackColor: Theme.of(context).primaryColorLight,
      thumbIcon: WidgetStateProperty.all(Icon(Icons.circle, color: value ? Colors.white : Colors.grey, size: 25,)),
      trackOutlineWidth: WidgetStateProperty.all(0.0),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
