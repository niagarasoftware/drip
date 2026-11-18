import 'package:flutter/material.dart';

class CustomCheckBox extends StatelessWidget {
  final bool value;
  final void Function(bool?)? onChanged;
  const CustomCheckBox({super.key, required this.value,required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Checkbox(
          activeColor: Theme.of(context).primaryColorLight,
          value: value,
          onChanged: onChanged
      ),
    );
  }
}
