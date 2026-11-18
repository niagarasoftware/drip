import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/customer/site_model.dart';
import '../model/event_log_model.dart';

class ValveLog extends StatelessWidget {
  final List<EventLog> events;
  final MasterControllerModel masterData;
  const ValveLog({super.key, required this.events, required this.masterData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupedEvents = _groupEvents(events);

    return Container(
      color: Colors.white,
      child: Column(
        children: groupedEvents.map((group) {
          return ExpansionTile(
            backgroundColor: Colors.white,
            childrenPadding: const EdgeInsets.symmetric(horizontal: 5),
            tilePadding: const EdgeInsets.symmetric(horizontal: 15),
            title: _buildHeader(group['header']!, theme),
            children: group['valves']!
                .map<Widget>((valve) => _buildValveLog(event: valve, theme: theme))
                .toList(),
            showTrailingIcon: false,
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _groupEvents(List<EventLog> events) {
    final headers = events.where((e) => !e.isValve).toList();
    final valves = events.where((e) => e.isValve).toList();

    final timeFormat = DateFormat.Hm();
    DateTime lastKnownTime = timeFormat.parse("00:00");

    DateTime safeParseTime(String timeStr) {
      try {
        return timeFormat.parse(timeStr.substring(0, 5));
      } catch (e) {
        return lastKnownTime;
      }
    }

    List<Map<String, dynamic>> result = [];

    for (var header in headers) {
      final onTime = safeParseTime(header.onTime);
      final offTime = safeParseTime(header.offTime);

      final groupValves = valves.where((v) {
        final valveOn = safeParseTime(v.onTime);
        final valveOff = safeParseTime(v.offTime);

        return valveOn.isBefore(offTime) && valveOff.isAfter(onTime);
      }).toList();

      if (groupValves.isNotEmpty) {
        final lastValve = groupValves.last;
        try {
          lastKnownTime = timeFormat.parse(lastValve.offTime.substring(0, 5));
        } catch (_) {}
      }

      result.add({'header': header, 'valves': groupValves});
    }

    return result;
  }

  Widget _buildHeader(EventLog event, ThemeData theme) {
    final String pump = masterData.configObjects
        .where((e) => e.objectId == 5)
        .map((ele) => ele.name)
        .toList()[0];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.primaryColorLight.withAlpha(50),
        // color: const Color(0xffE6F0FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.primaryColorLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        children: [
          _buildItemContainer(
            title: event.onReason.replaceAll("MOTOR1", pump.toUpperCase()),
            value: event.onTime,
            theme: theme,
            color: Colors.green,
          ),
          _buildItemContainer(
            title: event.offReason.replaceAll("MOTOR1", pump.toUpperCase()),
            value: event.offTime,
            theme: theme,
            color: Colors.red,
          ),
          _buildItemContainer(
            title: "Duration".toUpperCase(),
            value: event.duration,
            theme: theme,
            color: theme.primaryColorLight,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLineContainer({bool isLast = false}) {
    if (isLast) {
      return Container(
        width: 3,
        margin: const EdgeInsets.symmetric(horizontal: 10),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 10),
      child: Container(
        width: 3,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xffE0D3D3),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  Widget _buildItemContainer({
    required String title,
    required String value,
    required ThemeData theme,
    Color color = Colors.black,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.radio_button_checked,
                color: color,
                size: 20,
              ),
              Expanded(
                child: _buildTimeLineContainer(isLast: isLast),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: Colors.black54,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildValveLog({required EventLog event, required ThemeData theme}) {
    final valves = masterData.configObjects
        .where((e) => e.objectId == 13)
        .map((e) => e.name)
        .toList();
    final String valveName =
    valves[int.parse(event.onReason.split(' ')[0].substring(5)) - 1];
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            minVerticalPadding: 0,
            minTileHeight: 40,
            dense: false,
            title: Text(
              valveName,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.primaryColorDark,
                fontWeight: FontWeight.bold,
                fontSize: 16, // Adjusted to match the image
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: theme.primaryColorLight.withAlpha(20),
              radius: 20,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset('assets/png/valve_gray.png'),
              ),
            ),
            trailing: Text(
              "Duration",
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.primaryColorDark,
                fontWeight: FontWeight.bold,
                fontSize: 16, // Adjusted to match the image
              ),
            ),
            /*subtitle: Row(
              children: [
                _buildDurationContainer(
                  color: Colors.green,
                  value: "ON : ${event.onTime}",
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _buildDurationContainer(
                  color: Colors.red,
                  value: "OFF : ${event.offTime}",
                  theme: theme,
                ),
              ],
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Duration",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: Colors.grey.shade600, // Adjusted to match the image
                  ),
                ),
                const SizedBox(height: 4),
                _buildDurationContainer(
                  color: theme.primaryColorLight,
                  value: event.duration,
                  icon: Icons.schedule_rounded,
                  theme: theme,
                ),
              ],
            ),*/
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            minVerticalPadding: 0,
            minTileHeight: 30,
            dense: false,
            title: Row(
              children: [
                _buildDurationContainer(
                  color: Colors.green,
                  value: "ON : ${event.onTime}",
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _buildDurationContainer(
                  color: Colors.red,
                  value: "OFF : ${event.offTime}",
                  theme: theme,
                ),
              ],
            ),
            trailing: _buildDurationContainer(
              color: theme.primaryColorLight,
              value: event.duration,
              icon: Icons.schedule_rounded,
              theme: theme,
            ),
          ),
          Divider(
            thickness: 0.5,
            color: Colors.grey.shade300, // Adjusted to match the image
          ),
        ],
      ),
    );
  }

  Widget _buildDurationContainer({
    required Color color,
    required String value,
    IconData? icon,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Adjusted padding
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              color: color,
              size: 16, // Adjusted size to match the image
            ),
          if (icon != null) const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall!.copyWith(
              color: color,
              fontSize: 12, // Adjusted to match the image
            ),
          ),
        ],
      ),
    );
  }
}