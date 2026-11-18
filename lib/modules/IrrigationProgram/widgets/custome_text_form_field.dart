import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../Constants/properties.dart';

class CustomTextFormTile extends StatelessWidget {
  final String subtitle;
  final String hintText;
  final String? errorText;
  final String? initialValue;
  final TextEditingController? controller;
  final Function(String) onChanged;
  final IconData? icon;
  final BorderRadius? borderRadius;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Color? tileColor;
  final bool trailing;
  final String? trailingText;
  final String? subtitle2;

  const CustomTextFormTile({super.key,
    required this.subtitle,
    required this.hintText,
    this.controller,
    required this.onChanged,
    this.icon,
    this.borderRadius,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.initialValue,
    this.tileColor,
    this.trailing = false,
    this.trailingText,
    this.subtitle2
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, BoxConstraints constraints) {
          return  ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.zero,
            ),
            contentPadding: subtitle2 != null ? const EdgeInsets.symmetric(horizontal: 10) : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppProperties.linearGradientLeading,
                ),
                child: CircleAvatar(backgroundColor: Colors.transparent, child: Icon(icon, color: Colors.white))),
            title: Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            subtitle: subtitle2 != null ? Text(subtitle2 ?? "") : errorText != null ? Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12),) : null,
            trailing: SizedBox(
              width: constraints.maxWidth < 550 ? 80 : 80,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: initialValue,
                        textAlign: TextAlign.center,
                        controller: controller,
                        keyboardType: keyboardType,
                        inputFormatters: inputFormatters,
                        enableInteractiveSelection: false,
                        decoration: InputDecoration(
                          hintText: hintText,
                          contentPadding: const EdgeInsets.symmetric(vertical: 5),
                          // errorText: errorText
                        ),
                        onChanged: onChanged,
                      ),
                    ),
                    if (trailing) Text(trailingText ?? "", style: Theme.of(context).textTheme.bodyMedium,),
                  ],
                ),
              ),
            ),
            tileColor: tileColor,
          );
        }
    );
  }
}