import 'package:flutter/material.dart';

class CustomOutlineButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSelected;
  final String label;

  const CustomOutlineButton({
    super.key,
    required this.onPressed,
    required this.isSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
        foregroundColor: isSelected ? Colors.white : Colors.grey,
        side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
      ),
      child: Text(label),
    );
  }
}
