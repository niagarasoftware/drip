import 'package:flutter/material.dart';
class CustomDropDownButton extends StatelessWidget {
  final String value;
  TextStyle? style;
  final List<String> list;
  final void Function(String?)? onChanged;
  CustomDropDownButton({
    super.key,
    required this.value,
    this.style,
    required this.list,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    print('value :: $value');
    return DropdownButton<String>(
      isExpanded: true,
      underline: Container(),
      value: value,
      style: style ?? Theme.of(context).textTheme.headlineSmall,
      items: list.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
