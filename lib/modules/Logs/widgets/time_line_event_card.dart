import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../../../Constants/constants.dart';
import '../../../Constants/properties.dart';
import '../../ScheduleView/widgets/custom_timeline_widget.dart';
import '../model/event_log_model.dart';

class TimelineEventCard extends StatelessWidget {
  final EventLog event;

  const TimelineEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return TimeLine(
      itemGap: 0,
      padding: const EdgeInsets.symmetric(vertical: 0),
      indicatorSize: 80,
      gutterSpacing: 0,
      indicators: [
        buildTimeLineIndicators(context: context, event: event)
      ],
      children: [
        Card(
          margin: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).primaryColorLight,
              width: 0.5,
            ),
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10), topRight: Radius.circular(10)),
          ),
          elevation: 4,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shadowColor: Theme.of(context).primaryColorLight.withAlpha(100),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_checked, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Constants.capitalizeFirstLetter(event.onReason),
                          style: TextStyle(
                            // fontSize: 16,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_checked, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Constants.capitalizeFirstLetter(event.offReason),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(text: "Duration: ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w300, fontSize: 14)),
                          TextSpan(text: event.duration, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black),),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget buildTimeLineIndicators({context, required EventLog event}) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), topLeft: Radius.circular(10)),
      ),
      elevation: 4,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      margin: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
      shadowColor: Theme.of(context).primaryColorLight.withAlpha(100),
      child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppProperties.linearGradientLeading,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            border: Border(top: BorderSide(color: Theme.of(context).primaryColor, width: 0.5), bottom: BorderSide(color: Theme.of(context).primaryColor, width: 0.5), left: BorderSide(color: Theme.of(context).primaryColor, width: 0.5)),
            // boxShadow: AppProperties.customBoxShadowLiteTheme,
          ),
          // width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(event.onTime, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.white),),
              const Text("to", style: TextStyle(fontSize: 12,  color: Colors.white),),
              Text(event.offTime, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic,  color: Colors.white),),
            ],
          )
      ),
    );
  }
}