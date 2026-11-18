import 'package:flutter/material.dart';

import '../../../Constants/properties.dart';
import 'custom_drop_down.dart';

class CustomDropdownTile extends StatelessWidget {
  final dynamic content;
  final String title;
  final String? subtitle;
  final bool showSubTitle;
  final double width;
  final Widget? trailing;
  final BorderRadius? borderRadius;
  final Color? tileColor;
  final TextAlign? textAlign;
  final TextStyle? titleColor;
  final List<String> dropdownItems;
  final String selectedValue;
  final bool includeNoneOption;
  final void Function(String?) onChanged;
  final bool showCircleAvatar;

  const CustomDropdownTile({
    super.key,
    required this.title,
    this.trailing,
    this.borderRadius,
    this.content,
    this.tileColor,
    this.textAlign,
    this.titleColor,
    required this.dropdownItems,
    required this.selectedValue,
    required this.onChanged,
    this.includeNoneOption = true,
    this.showCircleAvatar = true,
    this.subtitle,
    this.showSubTitle = false,
    this.width = 130,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      subtitle: showSubTitle ? Text(subtitle ?? '') : null,
      contentPadding: showSubTitle ? const EdgeInsets.symmetric(horizontal: 10) : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      leading: showCircleAvatar
          ? Container(
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
              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
            ),
          ),
        ),
      ) : null,
      title: Text(title, style: titleColor ?? Theme.of(context).textTheme.bodyLarge, textAlign: textAlign),
      trailing: SizedBox(
        width: width,
        child: Center(
          child: CustomDropdownWidget(
            dropdownItems: dropdownItems,
            selectedValue: selectedValue,
            onChanged: onChanged,
            includeNoneOption: includeNoneOption,
          ),
        ),
      ),
      tileColor: tileColor,
    );
  }
}