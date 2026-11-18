import 'package:chat_bubbles/bubbles/bubble_special_one.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../StateManagement/customer_provider.dart';
import '../../../flavors.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../view_models/customer/sent_and_received_view_model.dart';

class SentAndReceived extends StatelessWidget {
  const SentAndReceived({
    super.key,
    required this.customerId,
    required this.controllerId,
    required this.isWide,
  });

  final int customerId, controllerId;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(Provider.of<CustomerProvider>(context).controllerId),
      create: (_) => SentAndReceivedViewModel(Repository(HttpService()))
        ..initIds(customerId: customerId, controllerId: controllerId, isWide: isWide)
        ..getSentAndReceivedData(DateFormat('yyyy-MM-dd').format(DateTime.now())),
      child: Consumer<SentAndReceivedViewModel>(
        builder: (context, viewModel, _) {
          final calendarWidget = _buildCalendar(context, viewModel);

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 350, height: 400, child: calendarWidget),
                VerticalDivider(color: Colors.grey.shade300),
                Expanded(child: _buildBody(context, viewModel)),
              ],
            );
          } else {
            return Scaffold(
              appBar: AppBar(title: const Text('Sent & Received')),
              body: Column(
                children: [
                  Container(color: Colors.white, child: calendarWidget),
                  Expanded(child: _buildBody(context, viewModel)),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, SentAndReceivedViewModel viewModel) {
    final CalendarFormat initialFormat =
    isWide ? CalendarFormat.month : CalendarFormat.week;

    return TableCalendar(
      firstDay: DateTime.utc(2020, 10, 16),
      lastDay: DateTime.utc(2050, 3, 14),
      focusedDay: viewModel.focusedDay,
      selectedDayPredicate: (day) => isSameDay(viewModel.selectedDay, day),
      enabledDayPredicate: (day) =>
      day.isBefore(DateTime.now()) || isSameDay(day, DateTime.now()),
      onDaySelected: (selectedDay, focusedDay) {
        viewModel.onDateChanged(selectedDay, focusedDay);
      },
      calendarFormat: initialFormat,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.week: 'Week',
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          shape: BoxShape.circle,
        ),
        disabledTextStyle: const TextStyle(color: Colors.grey),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  Widget _buildBody(BuildContext context, SentAndReceivedViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: LoadingIndicator(indicatorType: Indicator.ballPulse),
        ),
      );
    }

    if (viewModel.sentAndReceivedList.isEmpty) {
      return const Center(
        child: Text(
          'Message not found',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.normal),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: viewModel.sentAndReceivedList.length,
      itemBuilder: (context, index) {
        final message = viewModel.sentAndReceivedList[index];
        final isReceived = message.messageType == 'RECEIVED';

        return Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment:
            isReceived ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: () => _handleLongPress(context, viewModel, message),
                onTap: () {
                  if (viewModel.hasPayloadViewPermission) {
                    viewModel.getUserSoftwareOrHardwarePayload(
                      context,
                      message.sentAndReceivedId,
                      'Hardware payload',
                      message.message,
                    );
                  }
                },
                child: BubbleSpecialOne(
                  text: message.message,
                  isSender: isReceived,
                  color:
                  isReceived ? Colors.green.shade100 : Colors.blue.shade100,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: isReceived ? 0 : 25,
                  right: isReceived ? 25 : 0,
                  top: 2,
                ),
                child: Text(
                  isReceived
                      ? viewModel.convertTo12hrs(message.time)
                      : '${message.sentUser}(${message.sentMobileNumber}) - ${viewModel.convertTo12hrs(message.time)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLongPress(BuildContext context, SentAndReceivedViewModel viewModel, message) {
    if (!viewModel.hasPayloadViewPermission) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This content is protected.\nPlease enter your password to\nview the payload.',
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: viewModel.passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final enteredPassword = viewModel.passwordController.text;
                  if (enteredPassword ==
                      (F.name.toLowerCase().contains('oro')
                          ? 'Oro@321'
                          : F.name.toLowerCase().contains('smart')
                          ? 'LK@321'
                          : F.name.toLowerCase().contains('agritel')
                          ? 'Agritel@321'
                          : 'Oro@321')) {
                    viewModel.hasPayloadViewPermission = true;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Access granted. Showing payload...')),
                    );
                    viewModel.getUserSoftwareOrHardwarePayload(
                      context,
                      message.sentAndReceivedId,
                      'Hardware payload',
                      message.message,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect password.')),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    }
  }
}