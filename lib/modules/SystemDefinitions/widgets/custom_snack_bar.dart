import 'package:flutter/material.dart';

class CustomSnackBar extends SnackBar {
  CustomSnackBar({
    super.key,
    required String message,
    Color? color,
  }) : super(
    content: Text(message, style: const TextStyle(fontSize: 16),),
    behavior: SnackBarBehavior.floating,
    backgroundColor: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    duration: const Duration(milliseconds: 2000),
    action: SnackBarAction(
      label: 'Close',
      onPressed: () {},
    ),
  );
}