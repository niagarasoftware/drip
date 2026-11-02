import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/repository/irrigation_program_repo.dart';
import 'package:oro_drip_irrigation/modules/PumpController/state_management/pump_controller_provider.dart';
import 'package:oro_drip_irrigation/modules/ScheduleView/repository/schedule_view_repo.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../Constants/constants.dart';
import '../../../services/mqtt_service.dart';
import '../../Logs/widgets/custom_calendar_mobile.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import '../widgets/custom_timeline_widget.dart';
import '../../../flavors.dart';
import '../../../services/http_service.dart';
import '../../../utils/environment.dart';
import '../../IrrigationProgram/view/program_library.dart';
import '../model/status_model.dart';
import '../widgets/custom_outer_cirlce.dart';

class ScheduleViewScreen extends StatefulWidget {
  const ScheduleViewScreen({
    super.key,
    required this.deviceId,
    required this.userId,
    required this.controllerId,
    required this.customerId,
    required this.groupId,
  });

  final String deviceId;
  final int userId, controllerId, customerId, groupId;

  @override
  State<ScheduleViewScreen> createState() => _ScheduleViewScreenState();
}

class _ScheduleViewScreenState extends State<ScheduleViewScreen> {
  DateTime date = DateTime.now();
  final ScheduleViewRepository repository = ScheduleViewRepository(HttpService());
  List<Map<String, dynamic>> configObjects = [];
  bool isToday = false;
  DateTime _focusedDay = DateTime.now();
  DateTime today = DateTime.now();
  List<int> selectedStatusList = [];
  List<StatusInfo> statusList = [];
  Map<String, dynamic> defaultData = {};
  List headUnits = [];
  List selectedHeadUnits = [];
  List programs = [];
  List selectedPrograms = [];
  List<String> sentMessage = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // MqttManager().topicToSubscribe('${Environment.mqttSubscribeTopic}/${widget.deviceId}');
    _requestScheduleData();
  }

  /// Function to request schedule data
  Future<void> _requestScheduleData() async {
    MqttService().schedulePayload = null;
    await _getUserSequencePriority(widget.customerId, widget.controllerId);
    var userData = {
      "userId": widget.customerId,
      "controllerId": widget.controllerId,
      "groupId": widget.groupId,
      "categoryId": widget.groupId
    };
    print(userData);
    var getUserConfigMaker = await IrrigationProgramRepository(HttpService()).getUserConfigMaker(userData);
    Map<String, dynamic> response = jsonDecode(getUserConfigMaker.body);
    selectedHeadUnits.clear();
    selectedStatusList.clear();
    selectedPrograms.clear();
    if(mounted) {
      setState(() {
        configObjects = List.from(response['data']['configObject']);

        if(MqttService().schedulePayload != null && MqttService().schedulePayload!.isNotEmpty && !MqttService().schedulePayload![0].containsKey('message')) {
          final headUnitSnoList = MqttService().schedulePayload!.map((e) => e['HeadUnit'].toString()).toList().toSet();
          final programSnoList = MqttService().schedulePayload!.map((e) => e['ProgramS_No'].toString()).toList().toSet();
          final statusCodeList = MqttService().schedulePayload!.map((e) => e['Status']).toList().toSet();

          statusList = statusCodeList.map((code) => _getStatusInfo(code)).toSet().toList();
          programs = defaultData['program'].where((program) => programSnoList.contains(program['sNo'].toString())).toSet().toList();

          headUnits = configObjects.where((obj) => headUnitSnoList.contains(obj['sNo'].toString())).map((obj) => {'sNo': obj['sNo'], 'name': obj['name']}).toSet().toList();
          if(selectedHeadUnits.isEmpty) {
            selectedHeadUnits.add(headUnits[0]);
          }
        }

      });
    }
    Map<String, dynamic> data = {
      "2600": {"2601": "${DateFormat('yyyy-MM-dd').format(date)},${DateFormat('yyyy-MM-dd').format(date)}"}
    };
    DateTime selectedDateWithoutTime = DateTime(date.year, date.month, date.day);
    DateTime todayWithoutTime = DateTime(today.year, today.month, today.day);
    // print(selectedDateWithoutTime.isAfter(todayWithoutTime));
    // if (selectedDateWithoutTime.isAfter(todayWithoutTime)) {
    MqttService().topicToPublishAndItsMessage(jsonEncode(data), '${Environment.mqttPublishTopic}/${widget.deviceId}');
    // }
  }

  /// Function to get user log data
  Future<void> _getUserSequencePriority(userId, controllerId) async {
    try {
      Map<String, dynamic> userData = {
        "userId": userId,
        "controllerId": controllerId,
        "fromDate": DateFormat('yyyy-MM-dd').format(date),
        "toDate": DateFormat('yyyy-MM-dd').format(date),
        "logType": 'Irrigation',
        "parameters": [
          "S_No", "ScheduleOrder", "ScaleFactor", "SkipFlag", "Status", "ProgramStartStopReason", "ScheduledStartTime",
          "IrrigationMethod", "IrrigationDuration_Quantity", "IrrigationDurationCompleted", "IrrigationQuantityCompleted",
          "Pump", "SequenceData", "HeadUnit", "ProgramS_No", "ZoneS_No", "CentralFilterOnOff", "LocalFilterOnOff", "CentralFilterSite",
          "LocalFilterSite", "CentralFilterSelection", "LocalFilterSelection", "CentralFertOnOff", "LocalFertOnOff", "CentralFertilizerSite",
          "LocalFertilizerSite", "CentralFertChannelSelection", "LocalFertChannelSelection", 'RtcNumber', 'CycleNumber', "Date"
        ]
      };
      var getUserScheduleLog = await repository.getUserIrrigationLog(userData);
      if (getUserScheduleLog.statusCode == 200) {
        final responseJson = getUserScheduleLog.body;
        final convertedJson = jsonDecode(responseJson);
        // print("convertedJson in the getUserScheduleLog :: $convertedJson");
        if(convertedJson["code"] == 200) {
          defaultData = convertedJson['data']['default'];
          // print('convertedJson: ${convertedJson['data'][0]}');
          MqttService().schedulePayload = Constants.dataConversionForScheduleView(convertedJson['data']['log'][0]['irrigation']);
        } else {
          MqttService().schedulePayload = [{"message" : convertedJson['message']}];
        }
      }
    } catch (e) {
      // print('Error: $e');
      // print('stackTrace: $stackTrace');
    }
  }

  Future<void> sentToServer(String msg, dynamic payLoad, int userId, int controllerId, int customerId) async {
    Map<String, Object> body = {"userId": customerId, "controllerId": controllerId, "messageStatus": msg.isNotEmpty ? msg : 'Just sent without changes', "data": payLoad, "hardware": payLoad, "createUser": userId};
    final response = await repository.createUserSentAndReceivedMessageManually(body);
    if (response.statusCode == 200) {
      // print(response.body);
      // print("body ==> $body");
    } else {
      throw Exception('Failed to load data');
    }
  }

  final BoxDecoration boxDecoration = BoxDecoration(
    shape: BoxShape.rectangle,
    borderRadius: BorderRadius.circular(4),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width >= 700;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule View'),
        leadingWidth: isLargeScreen ? 250 : null,
        leading: Row(
          children: [
            const BackButton(),
            if(isLargeScreen)
              Image(
                image: F.appFlavor!.name.contains('oro')?const AssetImage("assets/png/oro_logo_white.png"):
                const AssetImage("assets/png/company_logo.png"),
                width: 110,
                fit: BoxFit.fitWidth,
              )
          ],
        ),
        actions: [
          Container(
            height: 35,
            decoration: BoxDecoration(
                color: isLargeScreen ? Colors.transparent: Theme.of(context).primaryColorLight,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), bottomLeft: Radius.circular(25))
            ),
            child: Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if(isLargeScreen)
                    FilledButton.icon(
                      onPressed: () {
                        if (i == 0) {
                          _showStatusListDialog(context);
                        } else if (i == 1) {
                          _requestScheduleData();
                        } else if (i == 2) {
                          _showInfoDialog(context);
                        }
                      },
                      icon: Icon([Icons.filter_alt_outlined, Icons.refresh_outlined, Icons.info_outline][i]),
                      label: Text(['Filter', 'Refresh', 'Info'][i]),
                    )
                  else
                    InkWell(
                      onTap: () {
                        if (i == 0) {
                          _showStatusListDialog(context);
                        } else if (i == 1) {
                          _requestScheduleData();
                        } else if (i == 2) {
                          _showInfoDialog(context);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon([Icons.filter_alt_outlined, Icons.refresh_outlined, Icons.info_outline][i]),
                      ),
                    ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          if(MediaQuery.of(context).size.width <= 700)
            MobileCustomCalendar(
              focusedDay: _focusedDay,
              calendarFormat: context.read<PumpControllerProvider>().calendarFormat,
              selectedDate: date,
              lastDay: DateTime(2100),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  date = selectedDay;
                  _focusedDay = focusedDay;
                });
                _requestScheduleData();
              },
              onFormatChanged: (format) {
                /* if (pumpControllerProvider.calendarFormat != format) {
                setState(() {
                  pumpControllerProvider.calendarFormat = format;
                });
              }*/
              },
            ),
          Expanded(
            child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Row(
                    children: [
                      if(MediaQuery.of(context).size.width >= 700)
                        Container(
                            width: 250,
                            color: theme.primaryColor,
                            child: Column(
                              children: [
                                Expanded(child: Container()),
                                _buildCalendar(constraints)
                              ],
                            )
                        ),
                      Expanded(
                        child: Center(
                            child: StreamBuilder<List<Map<String, dynamic>>?>(
                              stream: MqttService().schedulePayloadStream,
                              initialData: MqttService().schedulePayload,
                              builder: (context, snapshot) {
                                // show loading only if still waiting and there is no cached data
                                if (snapshot.connectionState == ConnectionState.waiting && (snapshot.data == null)) {
                                  return const CircularProgressIndicator();
                                }

                                // If no data at all
                                if (!snapshot.hasData || snapshot.data == null || (snapshot.data is List && snapshot.data!.isEmpty)) {
                                  return const Text('No data available');
                                }

                                final data = snapshot.data!;
                                // If the first element is a server message (error/info), show it
                                if (data.isNotEmpty && data[0].containsKey('message')) {
                                  return Center(child: Text("${data[0]['message']}"));
                                }

                                // --- Derive headUnits from incoming MQTT data if not already present ---
                                // Only run once (guard with headUnits.isEmpty) and only if configObjects is available
                                if (data.isNotEmpty && headUnits.isEmpty && configObjects.isNotEmpty) {
                                  final headUnitSnoList = data.map((e) => e['HeadUnit'].toString()).toSet();
                                  final derivedHeadUnits = configObjects
                                      .where((obj) => headUnitSnoList.contains(obj['sNo'].toString()))
                                      .map((obj) => {'sNo': obj['sNo'], 'name': obj['name']})
                                      .toList();

                                  if (derivedHeadUnits.isNotEmpty) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      setState(() {
                                        headUnits = derivedHeadUnits;
                                        if (selectedHeadUnits.isEmpty) {
                                          selectedHeadUnits.add(headUnits[0]);
                                        }
                                      });
                                    });
                                  }
                                }

                                // --- Also derive programs list if empty and defaultData has program list ---
                                if (data.isNotEmpty && programs.isEmpty && defaultData.isNotEmpty && defaultData['program'] != null) {
                                  final programSnoList = data.map((e) => e['ProgramS_No'].toString()).toSet();
                                  final derivedPrograms = List.from(defaultData['program'])
                                      .where((program) => programSnoList.contains(program['sNo'].toString()))
                                      .toList();
                                  if (derivedPrograms.isNotEmpty) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      setState(() {
                                        programs = derivedPrograms;
                                        // do not auto-select programs — keep current UX (or uncomment to auto-select)
                                        if (selectedPrograms.isEmpty) selectedPrograms.add(programs[0]);
                                      });
                                    });
                                  }
                                }

                                return _buildScheduleView(data, constraints);
                              },
                            )
                        ),
                      )
                    ],
                  );
                }
            ),
          ),
        ],
      ),
      floatingActionButton: FilledButton.icon(
        onPressed: () async {
          // var
          final convertedList = MqttService().schedulePayload!;
          var listToMqtt = [];
          for (var i = 0; i < convertedList.length; i++) {
            String scheduleMap = ""
                "${convertedList[i]["S_No"]},"
                "${convertedList[i]["ScheduleOrder"]},"
                "${convertedList[i]["ScaleFactor"]},"
                "${convertedList[i]["SkipFlag"]},"
                "${convertedList[i]["Date"]},"
                "${convertedList[i]["HeadUnit"]},"
                "${convertedList[i]["CentralFilterOnOff"]},"
                "${convertedList[i]["LocalFilterOnOff"]},"
                "${convertedList[i]["CentralFilterSelection"]},"
                "${convertedList[i]["LocalFilterSelection"]},"
                "${convertedList[i]["CentralFertOnOff"]},"
                "${convertedList[i]["LocalFertOnOff"]},"
                "${convertedList[i]["CentralFertChannelSelection"]},"
                "${convertedList[i]["LocalFertChannelSelection"]}"
                "";
            listToMqtt.add(scheduleMap);
          }
          var dataToHardware = {
            "2700": {
              "2701": "${listToMqtt.join(";").toString()};"
            }
          };
          try {
            validatePayloadSent(
                dialogContext: context,
                context: context,
                acknowledgedFunction: () async{
                  try {
                    await sentToServer(sentMessage.join('\n'), dataToHardware, widget.userId, widget.controllerId, widget.customerId);
                    _requestScheduleData();
                  } catch(error) {
                    // print("error ==> $error");
                    // print("stackTrace ==> $stackTrace");
                  }
                },
                payload: dataToHardware,
                payloadCode: "2700",
                deviceId: widget.deviceId
            );
          } catch (error) {
            ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: 'Failed to update because of $error'));
            // print("Error: $error");
          }
        },
        label: const Text('Send'),
        icon: const Icon(Icons.send),
      ),
    );
  }

  /// Widget for displaying the calendar
  Widget _buildCalendar(BoxConstraints constraints) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      child: TableCalendar(
        rowHeight: 40,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        focusedDay: _focusedDay,
        firstDay: DateTime.utc(2020, 10, 16),
        lastDay: DateTime.utc(2100, 12, 31),
        calendarFormat: CalendarFormat.month,
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(4),
          markerSize: 10,
          markerMargin: const EdgeInsets.all(2),
          markerDecoration: boxDecoration,
          outsideDecoration: boxDecoration,
          holidayDecoration: boxDecoration.copyWith(color: Colors.grey.withValues(alpha: 0.1),),
          weekendDecoration: boxDecoration.copyWith(color: Colors.grey.withValues(alpha: 0.1),),
          defaultDecoration: boxDecoration.copyWith(color: Colors.grey.withValues(alpha: 0.1),),
          selectedDecoration: boxDecoration.copyWith(color: theme.primaryColor),
          todayTextStyle: const TextStyle(color: Colors.black),
          todayDecoration: boxDecoration.copyWith(color: theme.primaryColor.withValues(alpha: 0.2), border: Border.all(color: theme.primaryColor)),
        ),
        selectedDayPredicate: (day) {
          return isSameDay(date, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            date = selectedDay;
            _focusedDay = focusedDay;
          });
          _requestScheduleData();
          // scheduleViewProvider.updateSelectedProgramCategory(0);
        },
      ),
    );
  }

  /// Widget for displaying the schedule view
  Widget _buildScheduleView(List<Map<String, dynamic>> data, BoxConstraints constraints) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth >= 700 ? 40 : 10),
          height: 35,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: headUnits.length,
            itemBuilder: (BuildContext context, int index) {
              return Row(
                children: [
                  _buildOutlineButton(headUnits[index], selectedHeadUnits, item: headUnits[index]),
                  const SizedBox(width: 10,)
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth >= 700 ? 20 : 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          height: 55,
          decoration: BoxDecoration(
            boxShadow: AppProperties.customBoxShadowLiteTheme,
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: programs.length,
            itemBuilder: (BuildContext context, int index) {
              return Row(
                children: [
                  _buildOutlineButton(programs[index], selectedPrograms),
                  const SizedBox(width: 10,)
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        /// Timeline and program list
        Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              // Treat empty selectedHeadUnits as "match all"
              final bool headUnitMatches = selectedHeadUnits.isNotEmpty
                  ? selectedHeadUnits.any((element) => element['sNo'].toString() == data[index]['HeadUnit'].toString())
                  : true;

              final bool programMatches = selectedPrograms.isNotEmpty
                  ? selectedPrograms.any((element) => element['sNo'].toString() == data[index]['ProgramS_No'].toString())
                  : true;

              final bool statusMatches = selectedStatusList.isNotEmpty
                  ? selectedStatusList.contains(data[index]['Status'])
                  : true;

              return Container(
                margin: constraints.maxWidth >= 700 ? const EdgeInsets.symmetric(horizontal: 20) : const EdgeInsets.only(left: 5, right: 10),
                child: Column(
                  children: [
                    if (headUnitMatches && programMatches && statusMatches)
                      TimeLine(
                        itemGap: 0,
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        indicators: [
                          _buildTimeLineIndicators(data[index], index, data.length)
                        ],
                        children: [
                          Container(
                              margin: constraints.maxWidth <= 700 ? const EdgeInsets.only(bottom: 6) : EdgeInsets.zero,
                              child: _buildScheduleCard(data[index], index, data.length, constraints)
                          )
                        ],
                      ),
                    if(index == data.length - 1)
                      const SizedBox(height: 50,)
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Widget for displaying the timeline indicators
  Widget _buildTimeLineIndicators(Map<String, dynamic> data, int index, int totalItems) {
    StatusInfo status = _getStatusInfo(data["Status"]);
    // print(scheduleViewProvider.programCategories);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: CheckmarkPainter(color: status.color),
          child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status.color,
              ),
              height: 20,
              width: 20,
              child: Icon(status.icon, color: Colors.white, size: 16,)
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            width: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: status.color,
            ),
          ),
        )
      ],
    );
  }

  int parseValue(dynamic value) {
    if (value == null) {
      return 0;
    }

    // Already int
    if (value is int) {
      return value;
    }

    // Double
    if (value is double) {
      return value.toInt();
    }

    // String
    if (value is String) {
      final trimmedValue = value.trim();

      // Time format: HH:mm:ss
      if (RegExp(r'^\d{1,2}:\d{2}:\d{2}$').hasMatch(trimmedValue)) {
        return durationToSeconds(trimmedValue);
      }

      // Normal numeric string
      return double.tryParse(trimmedValue)?.toInt() ?? 0;
    }

    return 0;
  }

  int durationToSeconds(String value) {
    final parts = value.split(':');

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;

    return (hours * 3600) + (minutes * 60) + seconds;
  }

  /// Widget for displaying the schedule card
  Widget _buildScheduleCard(Map<String, dynamic> data, int index, int totalItems, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final scheduleItem = data;
    final screenSize = MediaQuery.of(context).size.width;

    final String method = scheduleItem["IrrigationMethod"].toString();
    final String inputValue = scheduleItem["IrrigationDuration_Quantity"].toString();
    final String completedValue = method == "1"
        ? scheduleItem["IrrigationDurationCompleted"].toString()
        : scheduleItem["IrrigationQuantityCompleted"].toString();

    final String pumps = scheduleItem['Pump'];
    final String valves = scheduleItem['SequenceData'];
    final String startTime = scheduleItem["ScheduledStartTime"].toString();
    final StatusInfo status = _getStatusInfo(scheduleItem["Status"]);
    final StatusInfo reason = _getStatusInfo(scheduleItem["ProgramStartStopReason"]);
    DateTime scheduleDate = DateTime.parse(scheduleItem["Date"]);
    DateTime today = DateTime.now();

    DateTime scheduleDateWithoutTime = DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day);
    DateTime todayWithoutTime = DateTime(today.year, today.month, today.day);
    // Convert 24-hour format time to 12-hour format
    final String time12 = DateFormat("hh:mm:ss").format(DateFormat("HH:mm:ss").parse(startTime));

    // Calculate progress value
    print("inputValue:$inputValue");
    print("completedValue:$completedValue");
    final int input = parseValue(inputValue);
    final int completed = parseValue(completedValue);

    final double progressValue = method == "1"
        ? _calculateTimeProgress(inputValue, completedValue)
        : completed / input;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: status.color,
                      borderRadius: BorderRadius.circular(5)
                  ),
                  height: 5,
                  width: 20,
                  margin: const EdgeInsets.only(right: 10),
                ),
                Text(time12, style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
              ],
            ),
            if(MediaQuery.of(context).size.width <= 700)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text("Reason: ${reason.reason}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.primaryColor)),
              ),
          ],
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          surfaceTintColor: Colors.white,
          color: Colors.white,
          elevation: 5,
          child: Padding(
            padding: EdgeInsets.all(screenSize >= 700 ? 10 : 6),
            child: Row(
              spacing: screenSize >= 700 ? 20 : 10,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if(screenSize >= 700)
                  const SizedBox(width: 10),
                _buildScheduleOrderCircle('${scheduleItem["ScheduleOrder"]}', theme),
                if(screenSize >= 700)
                  const SizedBox(width: 10),
                _buildStatusSection(
                    status,
                    _buildProgressIndicator(completedValue, progressValue, theme),
                    scheduleItem
                ),
                Expanded(flex: screenSize >= 700 ? 2 : 1, child: _buildDetailsSection(completedValue, inputValue, reason, theme)),
                if(screenSize >= 700)...[
                  _buildDetailChip("Pumps", _getItemNames(pumps)),
                  _buildDetailChip("Valves", _getItemNames(valves)),
                  _buildDetailChip("Scale Factor", "${scheduleItem["ScaleFactor"]}"),
                  _buildRtcCycleInfo(scheduleItem, theme),
                ],
                _buildIconButton(
                    Icons.edit_note_outlined,
                    (
                        ([0, 1, 4, 5].contains(status.code))
                            || (scheduleDateWithoutTime.isAfter(todayWithoutTime) || scheduleDateWithoutTime.isAtSameMomentAs(todayWithoutTime)))? () {
                      _textController.text = scheduleItem["ScaleFactor"].toString();
                      _showEditSideSheet(scheduleItem, constraints, index);
                    } : (){
                      print('status.code:${status.code}');
                      print('scheduleDateWithoutTime.isAfter(todayWithoutTime):${scheduleDateWithoutTime.isAfter(todayWithoutTime)}');
                      print('scheduleDateWithoutTime.isAtSameMomentAs(todayWithoutTime):${scheduleDateWithoutTime.isAtSameMomentAs(todayWithoutTime)}');
                    }),
                if(screenSize >= 700)
                  const SizedBox(width: 20),
                _buildIconButton(
                    scheduleItem["SkipFlag"] == 0 ? Icons.skip_next : Icons.undo_sharp,
                    (
                        ([0, 1, 4, 5].contains(status.code))
                            && (scheduleDateWithoutTime.isAfter(todayWithoutTime) || scheduleDateWithoutTime.isAtSameMomentAs(todayWithoutTime))) ? () {
                      setState(() {
                        scheduleItem["SkipFlag"] = scheduleItem["SkipFlag"] == 0 ? 1 : 0;
                        if(scheduleItem["SkipFlag"] == 1) {
                          if(!sentMessage.contains("${scheduleItem["ProgramName"]} - ${scheduleItem["ZoneName"]} is skipped")) {
                            sentMessage.add("${scheduleItem["ProgramName"]} - ${scheduleItem["ZoneName"]} is skipped");
                          } else {
                            sentMessage.remove("${scheduleItem["ProgramName"]} - ${scheduleItem["ZoneName"]} is skipped");
                          }
                        } else {
                          if(!sentMessage.contains("${scheduleItem["ProgramName"]} - ${scheduleItem["ZoneName"]} is un skipped")) {
                            sentMessage.add("${scheduleItem["ProgramName"]} - ${scheduleItem["ZoneName"]} is un skipped");
                          } else {
                            sentMessage.remove("${scheduleItem["ProgramName"]} - ${scheduleItem["ZoneName"]} is un skipped");
                          }
                        }
                      });
                    } : null
                ),
                if(screenSize <= 700)
                  _buildMoreOptions(screenSize, index, scheduleItem),
                // const SizedBox(width: 20,),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Helper function to get the names of the pumps and valves
  String _getItemNames(String sNoList) {
    List<String> names = [];

    List<String> sNoItems = sNoList.split('_');

    for (int i = 0; i < sNoItems.length; i++) {
      final double valve = double.tryParse(sNoItems[i]) ?? 0;
      final List<String> valveNames = configObjects
          .where((element) => element['sNo'] == valve)
          .map((element) => element['name'] as String)
          .toList();

      names.addAll(valveNames);
    }

    return names.isNotEmpty ? names.join(', ') : "N/A";
  }

  String _getItemNameSingleString(String sNo) {
    print('call _getItemNameSingleString sNo:-->$sNo');
    final double? valve = double.tryParse(sNo);
    if (valve == null) return 'N/A';

    for (final element in configObjects) {
      print('element-->$element');
      if (element['sNo'] == valve) {
        return element['name'] as String;
      }
    }
    return 'N/A';
  }


  /// Helper function to get the program name
  String _getProgramName(dynamic sNo) {
    if(sNo is String) {
      sNo = int.parse(sNo);
    }
    for(int i = 0; i < defaultData['program'].length; i++) {
      if(defaultData['program'][i]['sNo'] == sNo) {
        return defaultData['program'][i]['name'];
      }
    }
    return '';
  }

  /// Helper function to get the zone name
  String _getZoneName(String sNo) {
    for(int i = 0; i < defaultData['sequence'].length; i++) {
      if(defaultData['sequence'][i]['sNo'] == sNo) {
        return defaultData['sequence'][i]['name'];
      }
    }
    return '';
  }

  /// Helper function to build icon buttons
  Widget _buildIconButton(IconData icon, Function()? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: PhysicalModel(
        color: onPressed != null ? const Color(0xffE4F5FF) : Colors.grey[200]!,
        shape: BoxShape.circle,
        elevation: 5,
        shadowColor: onPressed != null ? const Color(0xffA2DEFF) : Colors.grey,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: onPressed != null ? const Color(0xffA2DEFF) : Colors.grey, width: 1),
          ),
          child: Icon(icon, color: Colors.grey, size: 20,),
        ),
      ),
    );
  }

  /// Helper function to calculate time-based progress
  double _calculateTimeProgress(String input, String completed) {
    List<int> parseTime(String time) => time.split(':').map(int.parse).toList();

    var inputParts = parseTime(input);
    var completedParts = parseTime(completed);

    var inDuration = Duration(hours: inputParts[0], minutes: inputParts[1], seconds: inputParts[2]);
    var completedDuration = Duration(hours: completedParts[0], minutes: completedParts[1], seconds: completedParts[2]);

    return completedDuration.inMilliseconds / inDuration.inMilliseconds;
  }

  /// Widget for displaying the schedule order inside a circle
  Widget _buildScheduleOrderCircle(String order, ThemeData theme) {
    return Container(
      height: 30,
      width: 30,
      decoration: BoxDecoration(shape: BoxShape.circle, color: theme.primaryColor),
      child: Center(
        child: Text(order, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Widget for displaying status information
  Widget _buildStatusSection(StatusInfo status, Widget? childWidget, scheduleItem) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getProgramName(scheduleItem['ProgramS_No']), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
          Text(_getZoneName(scheduleItem['ZoneS_No']), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(status.statusString, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
          if(childWidget != null) ...[const SizedBox(height: 5), childWidget]
        ],
      ),
    );
  }

  /// Widget for displaying the progress indicator
  Widget _buildProgressIndicator(String completedValue, double progressValue, ThemeData theme) {
    return Tooltip(
      message: completedValue,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 0.3, color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: LinearProgressIndicator(
          value: progressValue.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Widget for displaying details (Completed, Actual, Reason, Pumps, Valves, etc.)
  Widget _buildDetailsSection(String completedValue, String inputValue, StatusInfo reason, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Completed: $completedValue", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
        Text("Actual: $inputValue", style: const TextStyle(fontSize: 12)),
        if(MediaQuery.of(context).size.width >= 700)
          Text("Reason: ${reason.reason}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.primaryColor)),
      ],
    );
  }

  /// Widget for displaying RTC and Cycle information
  Widget _buildRtcCycleInfo(Map<String, dynamic> scheduleItem, ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: ['Rtc', 'Cycle'].map((label) {
          return RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "${label.toUpperCase()} : ",
                  style: theme.textTheme.bodySmall!.copyWith(color: Colors.grey),
                ),
                TextSpan(
                  text: '${scheduleItem['${label}Number']}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Widget for "More" options button
  Widget _buildMoreOptions(double screenSize, int index, scheduleItem) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext dialogContext) {
            return Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoRow(
                    screenSize,
                    'assets/Images/Svg/objectId_5.svg',
                    _buildDetailChip("Pumps", _getItemNames(scheduleItem['Pump'])),
                  ),
                  _buildInfoRow(
                    screenSize,
                    'assets/Images/Svg/objectId_13.svg',
                    _buildDetailChip("Valves", _getItemNames(scheduleItem['SequenceData'])),
                  ),
                  _buildInfoRow(
                    screenSize,
                    null,
                    _buildRtcCycleInfo(scheduleItem, Theme.of(context)),
                    iconData: Icons.schedule,
                  ),
                ],
              ),
            );
          },
        );
      },
      child: const Icon(Icons.more_vert),
    );
  }

  Widget _buildInfoRow(double width, String? assetPath, Widget content, {IconData? iconData}) {
    return Container(
      width: width - 30,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorDark,
              shape: BoxShape.circle,
            ),
            child: assetPath != null
                ? SvgPicture.asset(assetPath)
                : Icon(iconData, color: Colors.white),
          ),
          const SizedBox(width: 12),
          content,
        ],
      ),
    );
  }

  /// Widget for displaying the detail chip
  Widget _buildDetailChip(String title, String names) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(names),
          Text(title, style: const TextStyle(color: Colors.grey),)
        ],
      ),
    );
  }

  /// Helper function to get the status information
  StatusInfo _getStatusInfo(dynamic code) {
    if(code is String){
      code = int.parse(code);
    }
    final Map<int, StatusInfo> statusMap = {
      0: StatusInfo(Colors.grey, "Pending", Icons.pending, "Unknown", code),
      1: StatusInfo(Colors.orange, "Running", Icons.run_circle, "Running As Per Schedule", code),
      2: StatusInfo(Colors.green, "Completed", Icons.done, "Turned On Manually", code),
      3: StatusInfo(Colors.yellow, "Skipped by user", Icons.skip_next, "Started By Condition", code),
      4: StatusInfo(Colors.orangeAccent, "Day schedule pending", Icons.pending_actions, "Turned Off Manually", code),
      5: StatusInfo(const Color(0xFF0D5D9A), "Day schedule running", Icons.run_circle_outlined, "Program Turned Off", code),
      6: StatusInfo(Colors.yellowAccent, "Day schedule completed", Icons.done_all_outlined, "Zone Turned Off", code),
      7: StatusInfo(Colors.red, "Day schedule skipped", Icons.incomplete_circle, "Stopped By Condition", code),
      8: StatusInfo(Colors.redAccent, "Postponed partially to tomorrow", Icons.repartition, "Disabled By Condition", code),
      9: StatusInfo(Colors.green, "Postponed fully to tomorrow", Icons.add_alert_outlined, "Stand Alone Program Started", code),
      10: StatusInfo(Colors.amberAccent, "RTC off time reached", Icons.timer_outlined, "Stand Alone Program Stopped", code),
      11: StatusInfo(Colors.amber, "RTC max time reached", Icons.share_arrival_time_rounded, "Stand Alone Program Stopped After Set Value", code),
      12: StatusInfo(Colors.amber, "Skipped By High Flow", Icons.speed_outlined, "Stand Alone Manual Started", code),
      13: StatusInfo(Colors.amber, "Skipped By Low Flow", Icons.speed_outlined, "Stand Alone Manual Stopped", code),
      14: StatusInfo(Colors.amber, "Skipped By No Flow", Icons.water_drop_outlined, "Stand Alone Manual Stopped After Set Value", code),
      15: StatusInfo(Colors.amber, "Skipped By Global limit", Icons.production_quantity_limits, "StartedByDayCountRtc", code),
      16: StatusInfo(Colors.amber, "Stopped manually", Icons.touch_app_outlined, "Paused By User", code),
      17: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Manually Started Paused By User", code),
      18: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Program Deleted", code),
      19: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Program Ready", code),
      20: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Program Completed", code),
      21: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Resumed By User", code),
      22: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Paused By Condition", code),
      23: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Program Ready And Run By Condition", code),
      24: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Running As Per Schedule And Condition", code),
      25: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Started By Condition Paused By User", code),
      26: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Started By Condition Paused By User", code),
      27: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Resumed ByCondition", code),
      28: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Bypassed Start Condition Manually", code),
      29: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Bypassed Stop ConditionManually", code),
      30: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Continue Manually", code),
      31: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, " - ", code),
      32: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Waiting For Condition", code),
      33: StatusInfo(Colors.amber, "Unknown status", Icons.device_unknown, "Started By Condition And Run As Per Schedule", code),
    };

    return statusMap[code] ?? StatusInfo(Colors.black, "Unknown", Icons.error, "Unsupported status code: $code", code);
  }

  /// Helper function to build the outline button
  Widget _buildOutlineButton(Map<String, dynamic> data, List selected, {Map<String, dynamic>? item}) {
    return OutlinedButton(
      onPressed: (){
        setState(() {
          if(item != null) {
            selected[0] = data;
          } else {
            if(selected.contains(data)) {
              selected.remove(data);
            } else {
              selected.add(data);
            }
          }
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: selected.contains(data) ? Theme.of(context).primaryColor : null,
        foregroundColor: selected.contains(data) ? Colors.white : Colors.grey,
      ),
      child: Text(data['name']),
    );
  }

  /// Helper function to show the status list dialog
  void _showStatusListDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (BuildContext context) {
        List<int> tempSelectionList = List.from(selectedStatusList);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter stateSetter) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < statusList.length; i++)
                    CheckboxListTile(
                      title: Text(statusList[i].statusString),
                      value: tempSelectionList.contains(statusList[i].code),
                      onChanged: (newValue) {
                        stateSetter(() {
                          if (tempSelectionList.contains(statusList[i].code)) {
                            tempSelectionList.remove(statusList[i].code);
                          } else {
                            tempSelectionList.add(statusList[i].code);
                          }
                        });
                      },
                    )
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
                OutlinedButton(
                  onPressed: () {
                    stateSetter(() {
                      setState(() {
                        selectedStatusList = List.from(tempSelectionList);
                      });
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Helper function to show the info dialog
  void _showInfoDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (BuildContext context) {

        return AlertDialog(
          title: Text('Color indications', style: TextStyle(color: Theme.of(context).primaryColor),),
          content: SizedBox(
            height: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 12; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getStatusInfo(i).color,
                            radius: 10,
                          ),
                          const SizedBox(width: 10,),
                          Text(i != 12 ? _getStatusInfo(i).statusString : "Auto skipped",
                            style: const TextStyle(fontWeight: FontWeight.w400),)
                        ],
                      ),
                    )
                  // ListTile(
                  //   title: Text(''),
                  //   leading: CircleAvatar(
                  //     backgroundColor: scheduleViewProvider.legend[i],
                  //     radius: 15,
                  //   ),
                  // )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showEditSiderrreSheet(scheduleItem, constraints, index) {
    showGeneralDialog(
      barrierLabel: "Side sheet",
      barrierDismissible: true,
      // barrierColor: const Color(0xff6600),
      transitionDuration: const Duration(milliseconds: 300),
      context: context,
      pageBuilder: (context, animation1, animation2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 15,
            color: Colors.transparent,
            borderRadius: BorderRadius.zero,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter stateSetter) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  // margin: EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                  ),
                  height: double.infinity,
                  width: constraints.maxWidth < 600 ? constraints.maxWidth * 0.7 : constraints.maxWidth * 0.2,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Scale Factor"),
                            IntrinsicWidth(
                              child: TextFormField(
                                style: TextStyle(color: Theme.of(context).primaryColor),
                                initialValue: scheduleItem["ScaleFactor"].toString(),
                                // controller: _textController,
                                decoration: const InputDecoration(
                                    suffixText: "%"
                                ),
                                onChanged: (newValue){},
                                onSaved: (newValue) {
                                  setState(() {
                                    var temp = scheduleItem["ScaleFactor"].toString();
                                    scheduleItem["ScaleFactor"] = newValue != '' ? newValue : scheduleItem["ScaleFactor"];
                                    if(scheduleItem["ScaleFactor"] != temp){
                                      if(!sentMessage.contains("${_getProgramName(scheduleItem['ProgramS_No'])} - ${_getZoneName(scheduleItem["ZoneS_No"])}'s scale factor $newValue changed from $temp")) {
                                        sentMessage.add("${_getProgramName(scheduleItem["ProgramS_No"])} - ${_getZoneName(scheduleItem["ZoneS_No"])}'s scale factor $newValue changed from $temp");
                                      } else {
                                        sentMessage.remove("${_getProgramName(scheduleItem["ProgramS_No"])} - ${_getZoneName(scheduleItem["ZoneS_No"])}'s scale factor $newValue changed from $temp");
                                      }
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Divider(thickness: 0.3, color: Theme.of(context).primaryColor,),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(animation1),
          child: child,
        );
      },
    );
  }





  void _showEditSideSheet(
      dynamic scheduleItem,
      BoxConstraints constraints,
      int index,
      )
  {
    print('scheduleItem: $scheduleItem, index: $index');

    String getStringValue(dynamic value) {
      if (value == null) {
        return "";
      }

      return value.toString().trim();
    }

    // Your API may contain either:
    // CentralFertilizerSiteName OR CentralFertilizerSite
    final String centralFertilizerSiteName =
    getStringValue(
      scheduleItem["CentralFertilizerSiteName"],
    ).isNotEmpty
        ? getStringValue(
      scheduleItem["CentralFertilizerSiteName"],
    )
        : getStringValue(
      scheduleItem["CentralFertilizerSite"],
    );

    final String localFertilizerSiteName =
    getStringValue(
      scheduleItem["LocalFertilizerSiteName"],
    ).isNotEmpty
        ? getStringValue(
      scheduleItem["LocalFertilizerSiteName"],
    )
        : getStringValue(
      scheduleItem["LocalFertilizerSite"],
    );

    final String centralFertChannelSelection =
    getStringValue(
      scheduleItem["CentralFertChannelSelection"],
    );

    final String localFertChannelSelection =
    getStringValue(
      scheduleItem["LocalFertChannelSelection"],
    );

    print(
      "centralFertilizerSiteName: $centralFertilizerSiteName",
    );

    print("centralFertChannelSelection:$centralFertChannelSelection");

    final centralFertilizerSiteNamewe =  _getItemNameSingleString(centralFertilizerSiteName);
    print("centralFerxcvdfvdfvfdtilizerSiteName:$centralFertilizerSiteNamewe");
    print(
      "localFertilizerSiteName: $localFertilizerSiteName",
    );

    print(
      "centralFertChannelSelection: "
          "$centralFertChannelSelection",
    );

    print(
      "localFertChannelSelection: "
          "$localFertChannelSelection",
    );

    // ============================================================
    // SHOW SIDE SHEET
    // ============================================================

    showGeneralDialog(
      barrierLabel: "Side sheet",
      barrierDismissible: true,
      transitionDuration: const Duration(
        milliseconds: 300,
      ),
      context: context,

      pageBuilder: (
          context,
          animation1,
          animation2,
          ) {
        return Align(
          alignment: Alignment.centerRight,

          child: Material(
            elevation: 15,
            color: Colors.transparent,

            child: StatefulBuilder(
              builder: (
                  BuildContext context,
                  StateSetter stateSetter,
                  ) {
                return Container(
                  padding: const EdgeInsets.all(15),

                  height: double.infinity,

                  width: constraints.maxWidth < 600
                      ? constraints.maxWidth * 0.7
                      : constraints.maxWidth * 0.2,

                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),

                  child: SingleChildScrollView(
                    child: Column(
                      children: [

                        // ==================================================
                        // SCALE FACTOR
                        // ==================================================

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                          children: [

                            const Text(
                              "Scale Factor",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            SizedBox(
                              width: 100,

                              child: TextFormField(
                                initialValue:
                                scheduleItem[
                                "ScaleFactor"]
                                    ?.toString() ??
                                    "0",

                                keyboardType:
                                TextInputType.number,

                                style: TextStyle(
                                  color: Theme.of(context)
                                      .primaryColor,
                                ),

                                decoration:
                                const InputDecoration(
                                  suffixText: "%",
                                ),

                                onChanged: (
                                    String newValue,
                                    ) {
                                  stateSetter(() {
                                    if (newValue
                                        .trim()
                                        .isNotEmpty) {
                                      scheduleItem[
                                      "ScaleFactor"] =
                                          newValue.trim();
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        Divider(
                          thickness: 0.3,
                          color:
                          Theme.of(context).primaryColor,
                        ),

                        // ==================================================
                        // CENTRAL FERTILIZER
                        // ==================================================

                        if (centralFertilizerSiteName
                            .isNotEmpty)
                          Column(
                            children: [

                              // CENTRAL FERTILIZER TITLE + SWITCH
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                                children: [
                                  Expanded(
                                    child: Text(_getItemNameSingleString(centralFertilizerSiteName), style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight.w500,
                                    ),
                                    ),
                                  ),

                                  Switch(
                                    value:
                                    scheduleItem["CentralFertOnOff"] == 1,

                                    onChanged: (
                                        bool value,
                                        ) {
                                      stateSetter(() {

                                        scheduleItem[
                                        "CentralFertOnOff"] =
                                        value ? 1 : 0;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // ==================================================
                              // CENTRAL FERTILIZER CHANNELS
                              // ==================================================

                              if (scheduleItem[
                              "CentralFertOnOff"] ==
                                  1 &&
                                  centralFertChannelSelection
                                      .isNotEmpty)
                                _buildChannelList(
                                  scheduleItem:
                                  scheduleItem,

                                  selectionKey:
                                  "CentralFertChannelSelection",

                                  nameKey:
                                  "CentralFertChannelName",

                                  stateSetter:
                                  stateSetter,
                                ),

                              Divider(
                                thickness: 0.3,
                                color:
                                Theme.of(context)
                                    .primaryColor,
                              ),
                            ],
                          ),

                        // ==================================================
                        // LOCAL FERTILIZER
                        // ==================================================

                        if (localFertilizerSiteName
                            .isNotEmpty)
                          Column(
                            children: [

                              // LOCAL FERTILIZER TITLE + SWITCH
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                                children: [

                                  Expanded(
                                    child: Text(
                                      localFertilizerSiteName,

                                      style:
                                      const TextStyle(
                                        fontWeight:
                                        FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  Switch(
                                    value:
                                    scheduleItem[
                                    "LocalFertOnOff"] ==
                                        1,

                                    onChanged: (
                                        bool value,
                                        ) {
                                      stateSetter(() {

                                        scheduleItem[
                                        "LocalFertOnOff"] =
                                        value ? 1 : 0;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // ==================================================
                              // LOCAL FERTILIZER CHANNELS
                              // ==================================================

                              if (scheduleItem[
                              "LocalFertOnOff"] ==
                                  1 &&
                                  localFertChannelSelection
                                      .isNotEmpty)
                                _buildChannelList(
                                  scheduleItem:
                                  scheduleItem,

                                  selectionKey:
                                  "LocalFertChannelSelection",

                                  nameKey:
                                  "LocalFertChannelName",

                                  stateSetter:
                                  stateSetter,
                                ),

                              Divider(
                                thickness: 0.3,
                                color:
                                Theme.of(context)
                                    .primaryColor,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },

      // ============================================================
      // SLIDE ANIMATION
      // ============================================================

      transitionBuilder: (
          context,
          animation1,
          animation2,
          child,
          ) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation1,
              curve: Curves.easeOut,
            ),
          ),

          child: child,
        );
      },
    );
  }


// ============================================================================
// CHANNEL LIST
// ============================================================================

  Widget _buildChannelList({
    required dynamic scheduleItem,
    required String selectionKey,
    required String nameKey,
    required StateSetter stateSetter,
  }) {
    // ============================================================
    // GET CHANNEL SELECTION
    // ============================================================

    final dynamic selectionValue =
    scheduleItem[selectionKey];

    // NULL CHECK
    if (selectionValue == null) {
      return const SizedBox.shrink();
    }

    final String selectionString =
    selectionValue.toString().trim();

    // EMPTY CHECK
    if (selectionString.isEmpty) {
      return const SizedBox.shrink();
    }

    // ============================================================
    // GET CHANNEL NAMES
    // ============================================================

    final dynamic nameValue =
    scheduleItem[nameKey];

    List<String> channelNames = [];

    if (nameValue != null) {

      if (nameValue is List) {
        channelNames = nameValue
            .map(
              (item) =>
          item?.toString().trim() ?? "",
        )
            .toList();
      } else {
        final String nameString =
        nameValue.toString().trim();

        if (nameString.isNotEmpty) {
          channelNames =
              nameString.split('_');
        }
      }
    }

    // ============================================================
    // SELECTION FORMAT
    //
    // Example:
    // 1_1_1_1_1_0_0_0
    // ============================================================

    final List<String> selections =
    selectionString.split('_');

    // ============================================================
    // IF CHANNEL NAMES ARE NOT AVAILABLE
    // ============================================================

    if (channelNames.isEmpty) {
      return Column(
        children: List.generate(
          selections.length,
              (channelIndex) {

            final bool isSelected =
                selections[channelIndex] == "1";

            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,

              title: Text(
                "Channel ${channelIndex + 1}",
              ),

              value: isSelected,

              onChanged: (
                  bool? value,
                  ) {
                stateSetter(() {

                  selections[channelIndex] =
                  value == true ? "1" : "0";

                  scheduleItem[selectionKey] =
                      selections.join('_');
                });
              },
            );
          },
        ),
      );
    }

    // ============================================================
    // CHANNEL NAME + SELECTION
    // ============================================================

    return Column(
      children: List.generate(
        channelNames.length,
            (channelIndex) {

          final bool isSelected =
              channelIndex < selections.length &&
                  selections[channelIndex] == "1";

          final String channelName =
          channelNames[channelIndex]
              .trim()
              .isNotEmpty
              ? channelNames[channelIndex]
              : "Channel ${channelIndex + 1}";

          return CheckboxListTile(
            dense: true,

            contentPadding:
            EdgeInsets.zero,

            title: Text(
              channelName,

              style: const TextStyle(
                fontSize: 14,
              ),
            ),

            value: isSelected,

            onChanged: (
                bool? value,
                ) {
              stateSetter(() {

                // Make sure selection list
                // has enough items
                while (selections.length <=
                    channelIndex) {
                  selections.add("0");
                }

                selections[channelIndex] =
                value == true ? "1" : "0";

                // Update original scheduleItem
                scheduleItem[selectionKey] =
                    selections.join('_');
              });
            },
          );
        },
      ),
    );
  }
}