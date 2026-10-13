import 'package:flutter/material.dart';

class CustomMaterialButton extends StatelessWidget {
  final void Function()? onPressed;
  final String? title;
  final bool? outlined;
  final Widget? child;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  const CustomMaterialButton({
    super.key,
    this.onPressed,
    this.title,
    this.outlined,
    this.child,
    this.color,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).primaryColor;
    final isOutlined = outlined == true;

    return MaterialButton(
      elevation: isOutlined ? 0 : 2,
      highlightElevation: isOutlined ? 0 : 4,
      hoverElevation: isOutlined ? 0 : 3,
      focusElevation: 0,
      hoverColor: isOutlined
          ? primaryColor.withOpacity(0.08)
          : primaryColor.withOpacity(0.9),
      splashColor: isOutlined
          ? primaryColor.withOpacity(0.12)
          : Colors.white24,
      color: isOutlined ? Colors.transparent : primaryColor,
      shape: RoundedRectangleBorder(
        side: isOutlined
            ? BorderSide(color: primaryColor, width: 1.5)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onPressed: onPressed ?? () {
        Navigator.of(context).pop(); // Dismiss the alert
      },
      child: child ??
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: textColor ?? (isOutlined ? primaryColor : Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title ?? "OK",
                style: TextStyle(
                  color: textColor ?? (isOutlined ? primaryColor : Colors.white),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
    );
  }
}


