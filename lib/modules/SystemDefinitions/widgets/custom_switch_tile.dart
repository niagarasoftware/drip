import 'package:flutter/material.dart';

import '../../../Constants/properties.dart';

class CustomSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showSubTitle;
  final bool value;
  final Function(bool) onChanged;
  final IconData? icon;
  final bool showCircleAvatar;
  final BorderRadius? borderRadius;

  const CustomSwitchTile({super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon,
    this.borderRadius,
    this.subtitle,
    this.showSubTitle = false,
    this.showCircleAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      subtitle: showSubTitle ? Text(subtitle ?? '') : null,
      contentPadding: showSubTitle ? const EdgeInsets.symmetric(horizontal: 10) : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      leading: showCircleAvatar ? Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppProperties.linearGradientLeading,
          ),
          child: CircleAvatar(backgroundColor: Colors.transparent, child: Icon(icon, color: Colors.white))) : null,
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: SizedBox(
        width: MediaQuery.of(context).size.width < 550 ? 80 : 100,
        child: Center(
          child: Switch(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}