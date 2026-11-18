import 'package:flutter/material.dart';

class CustomMaterialButton extends StatelessWidget {
  void Function()? onPressed;
  String? title;
  bool? outlined;
  Widget? child;
  Color? color;
  CustomMaterialButton({super.key, this.onPressed, this.title, this.outlined, this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      hoverColor: Theme.of(context).primaryColorLight,
      color: color ?? (outlined != null ? Colors.white70 : Theme.of(context).primaryColor),
      shape: RoundedRectangleBorder(
        side: outlined != null ? BorderSide(color: Theme.of(context).colorScheme.primary) : BorderSide.none,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      onPressed: onPressed ?? () {
        Navigator.of(context).pop(); // Dismiss the alert
      },
      child: child ?? Text(
        title ?? "OK",
        style: TextStyle(color: outlined != null ? Theme.of(context).colorScheme.primary : Colors.white),
      ),
    );
  }
}

