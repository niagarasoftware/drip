import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;

  const CustomCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        return _buildCalendar(context, isMobile ? CalendarFormat.week : CalendarFormat.month);
      },
    );
  }

  Widget _buildCalendar(BuildContext context, CalendarFormat calendarFormat) {
    final theme = Theme.of(context);
    BoxDecoration boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.blueGrey.withOpacity(0.1),
    );

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.grey.withOpacity(0.3))],
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TableCalendar(
        focusedDay: focusedDay,
        firstDay: DateTime.utc(2020, 10, 16),
        lastDay: DateTime.utc(2100, 12, 31),
        calendarFormat: calendarFormat,
        rowHeight: 40,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(4),
          markerSize: 10,
          markerMargin: const EdgeInsets.all(2),
          markerDecoration: boxDecoration,
          outsideDecoration: boxDecoration,
          holidayDecoration: boxDecoration.copyWith(color: Colors.grey.withOpacity(0.1)),
          weekendDecoration: boxDecoration.copyWith(color: Colors.grey.withOpacity(0.1)),
          defaultDecoration: boxDecoration.copyWith(color: Colors.grey.withOpacity(0.1)),
          selectedDecoration: boxDecoration.copyWith(color: theme.primaryColor),
          todayTextStyle: const TextStyle(color: Colors.black),
          todayDecoration: boxDecoration.copyWith(
            color: theme.primaryColor.withOpacity(0.2),
            border: Border.all(color: theme.primaryColor),
          ),
        ),
        selectedDayPredicate: (day) {
          return isSameDay(selectedDay, day);
        },
        onDaySelected: onDaySelected,
      ),
    );
  }
}
