import 'package:flutter/material.dart';

import '../../../Constants/properties.dart';

class CustomTile extends StatelessWidget {
  final dynamic content;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final BorderRadius? borderRadius;
  final Color? tileColor;
  final TextAlign? textAlign;
  final TextStyle? titleColor;
  final bool showCircleAvatar;
  final bool showSubTitle;
  final EdgeInsets contentPadding;

  const CustomTile({
    super.key,
    required this.title,
    this.trailing,
    this.borderRadius,
    this.content,
    this.tileColor,
    this.textAlign,
    this.titleColor,
    this.leading,
    this.showCircleAvatar = true,
    this.showSubTitle = false,
    this.subtitle,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      subtitle: showSubTitle ? Text(subtitle ?? '') : null,
      contentPadding: showSubTitle ? const EdgeInsets.symmetric(horizontal: 10) : contentPadding,
      horizontalTitleGap: 30,
      leading: showCircleAvatar ? Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppProperties.linearGradientLeading,
        ),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: content is IconData
              ? Icon(content, color: Colors.white)
              : Text(
            content,
            style: TextStyle(
                color: Colors.white,
                fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize
            ),
          ),
        ),
      ) : null,
      title: Text(title, style: titleColor ?? Theme.of(context).textTheme.bodyLarge, textAlign: textAlign,),
      trailing: trailing,
      tileColor: tileColor,
    );
  }
}