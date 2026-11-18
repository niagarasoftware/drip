import 'package:flutter/material.dart';

import '../../../Constants/properties.dart';
import '../../IrrigationProgram/widgets/custom_native_time_picker.dart';

class CustomTimerTile extends StatelessWidget {
  final int modelId;
  final String subtitle;
  final bool showSubTitle;
  final String? subtitle2;
  final String initialValue;
  final Widget? leading;
  final Function(String) onChanged;
  final IconData? icon;
  final bool isSeconds;
  final bool isNative;
  final Color? tileColor;
  final BorderRadius? borderRadius;
  final bool is24HourMode;
  final bool isNewTimePicker;

  const CustomTimerTile({
    super.key,
    required this.subtitle,
    required this.initialValue,
    required this.onChanged,
    this.icon,
    this.borderRadius,
    required this.isSeconds,
    this.is24HourMode = false,
    this.tileColor,
    this.leading,
    this.isNative = false,
    this.showSubTitle = false,
    this.subtitle2,
    this.isNewTimePicker = false, required this.modelId
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, BoxConstraints constraints) {
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.zero,
            ),
            contentPadding: showSubTitle ? const EdgeInsets.symmetric(horizontal: 10) : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            leading: leading ??
                Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppProperties.linearGradientLeading,
                    ),
                    child: CircleAvatar(backgroundColor: Colors.transparent, child: Icon(icon, color: Colors.white))),
            title: Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            subtitle: showSubTitle ? Text(subtitle2 ?? '') : null,
            trailing: SizedBox(
              width: constraints.maxWidth < 550 ? 80 : 100,
              child: Center(
                child: CustomNativeTimePicker(
                  initialValue: initialValue,
                  is24HourMode: is24HourMode,
                  onChanged: onChanged,
                  isNewTimePicker: isNewTimePicker, modelId: modelId,
                ),
              ),
            ),
            tileColor: tileColor,
          );
        }
    );
  }
}