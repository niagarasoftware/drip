import 'package:flutter/material.dart';
import 'package:popover/popover.dart';

import '../../../models/customer/site_model.dart';
import 'alarm_list_items.dart';
import 'badge_button.dart';

class AlarmButton extends StatelessWidget {
  const AlarmButton({super.key, required this.alarmPayload,
    required this.deviceID, required this.customerId,
    required this.controllerId, required this.irrigationLine,
    required this.isNarrow, required this.isOMS});

  final List<String> alarmPayload;
  final String deviceID;
  final int customerId, controllerId;
  final List<IrrigationLineModel> irrigationLine;
  final bool isNarrow, isOMS;

  @override
  Widget build(BuildContext context) {
    // Safe check for alarm payload content
    final bool hasValidAlarms = alarmPayload.isNotEmpty &&
        alarmPayload.first.isNotEmpty;
    final int alarmCount = hasValidAlarms ? alarmPayload.length : 0;

    return Container(
      width: 45,
      height: 45,
      padding: isOMS ? const EdgeInsets.symmetric(vertical: 3.0) : null,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: BadgeButton(
        onPressed: (){
          showPopover(
            context: context,
            bodyBuilder: (context) => AlarmListItems(
                alarm: alarmPayload,
                deviceID: deviceID,
                customerId: customerId,
                controllerId: controllerId,
                irrigationLine: irrigationLine,
                isNarrow: isNarrow, isOMS: isOMS,
            ),
            onPop: () => print('Popover was popped!'),
            direction: isNarrow ? PopoverDirection.bottom : PopoverDirection.left,
            width: hasValidAlarms ? (isNarrow ? 400 : 600) : 150,
            height: isNarrow
                ? (hasValidAlarms ? (alarmPayload.length * 80) : 50)
                : (hasValidAlarms ? (alarmPayload.length * 45) + 20 : 50),
            arrowHeight: 15,
            arrowWidth: 30,
          );
        },
        icon: Icons.alarm,
        badgeNumber: alarmCount,
        isOMS: isOMS,
      ),
    );
  }
}