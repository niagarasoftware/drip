import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/Logs/widgets/time_line_event_card.dart';

import '../model/event_log_model.dart';
class Timeline2 extends StatelessWidget {
  final List<EventLog> events;
  final String? motorName;

  const Timeline2({super.key, required this.events, this.motorName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...events.map((event) => TimelineEventCard(event: event, motorName: motorName))
      ],
    );
  }
}