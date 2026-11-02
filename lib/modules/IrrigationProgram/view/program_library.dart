import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';

import 'package:provider/provider.dart';
import '../../../Constants/constants.dart';
import '../../../Widgets/HoursMinutesSeconds.dart';
import '../../../models/customer/site_model.dart';
import '../../../services/http_service.dart';
import '../../../utils/constants.dart';
import '../model/sequence_model.dart';
import '../repository/irrigation_program_repo.dart';
import '../state_management/irrigation_program_provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../StateManagement/overall_use.dart';
import '../widgets/custom_alert_dialog.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import '../../../utils/environment.dart';
import '../widgets/custom_drop_down_tile.dart';
import '../widgets/progress_dialog_ecogem.dart';
import 'irrigation_program_main.dart';

class ProgramLibraryScreenNew extends StatefulWidget {
  final int userId;
  final int controllerId;
  final int customerId;
  final int groupId;
  final int categoryId;
  final String deviceId;
  final int modelId;
  final String deviceName;
  final String categoryName;
  final void Function(String msg) callbackFunction;
  final List<NodeListModel> nodeList;

  const ProgramLibraryScreenNew({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.deviceId,
    required this.customerId,
    required this.groupId,
    required this.categoryId,
    required this.modelId,
    required this.deviceName,
    required this.categoryName,
    required this.callbackFunction,
    required this.nodeList,
  });

  @override
  State<ProgramLibraryScreenNew> createState() => _ProgramLibraryScreenNewState();
}

class _ProgramLibraryScreenNewState extends State<ProgramLibraryScreenNew> {
  // late OverAllUse overAllUse;
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _programNameFocusNode = FocusNode();
  late IrrigationProgramMainProvider irrigationProgramMainProvider;
  final PageController pageController = PageController();
  int currentIndex = 0;
  TextEditingController copyController = TextEditingController();
  String tempProgramName = '';
  String controllerReadStatus = "0";
  String controllerReadStatusForDayCount = "0";
  final IrrigationProgramRepository repository = IrrigationProgramRepository(HttpService());
  DayCountRtcModel dayCountRtcModel = DayCountRtcModel.fromJson({});
  ProgramQueueModel programQueueModel = ProgramQueueModel.fromJson({});
  bool isLoading = false;

  @override
  void initState() {
    // overAllUse = Provider.of<OverAllUse>(context, listen: false);
    irrigationProgramMainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    // MqttService().topicToSubscribe('${Environment.mqttSubscribeTopic}/${widget.deviceId}');
    irrigationProgramMainProvider.programLibraryData(widget.customerId, widget.controllerId);
    // print("init state called");
    // print("customerId :: ${widget.customerId}, ${widget.userId}");
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _programNameFocusNode.dispose();
    _textEditingController.dispose();
  }

  Future<void> getUserDayCountRtc() async {
    try {
      var userData = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
      };

      var getUserDayCountRtcResult = await repository.getDayCountRtc(userData);
      if (getUserDayCountRtcResult.statusCode == 200) {
        final responseJson = getUserDayCountRtcResult.body;
        final convertedJson = jsonDecode(responseJson);
        // print("convertedJson ::: $convertedJson");
        if(convertedJson['data']['dayCountRtc'] != null) {
          setState(() {
            dayCountRtcModel = DayCountRtcModel.fromJson(convertedJson['data']['dayCountRtc']);
            // if(AppConstants.ecoGemPlusModelList.contains(widget.modelId)) {
              programQueueModel = ProgramQueueModel.fromJson(convertedJson['data']['programQueue']);
            // }
          });
        }
      } else {
        log("HTTP Request failed or received an unexpected response.");
        throw Exception("HTTP Request failed or received an unexpected response.");
      }
    } catch (e, stackTrace) {
      log('Error in getUserDayCountRtc : $e');
      log('Stack Trace in getUserDayCountRtc: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    // overAllUse = Provider.of<OverAllUse>(context, listen: true);
    irrigationProgramMainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: true);
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.transparent,
    //   statusBarIconBrightness: Brightness.dark,
    // ));

    // print("build function called");
    return Scaffold(
      // backgroundColor: const Color(0xffF9FEFF),
      appBar: AppBar(
        // surfaceTintColor: Colors.white,
        title: const Text('Program Library',),
        centerTitle: false,
        automaticallyImplyLeading: true,
        leading: BackButton(
          onPressed: () {
            widget.callbackFunction('Program created');
            Navigator.pop(context);
          },
        ),
        actions: [
          if(AppConstants.ecoGemAndPlusModelList.contains(widget.modelId))
            FilledButton(
                onPressed: () async{
                  await getUserDayCountRtc();
                  showIrrigationSettings(context);
                },
                child: const Text("Day count RTC")
            )
        ],
      ),
      body: irrigationProgramMainProvider.programLibrary != null ?
      RefreshIndicator(
        onRefresh: () => irrigationProgramMainProvider.programLibraryData( widget.customerId,  widget.controllerId),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            double cardSize = 0.0;
            if(constraints.maxWidth < 800){
              cardSize = constraints.maxWidth -20;
            }else{
              cardSize = 400;
            }
            return Column(
              children: [
                if(irrigationProgramMainProvider.programLibrary!.program.any((element) => element.programName.isNotEmpty && element.active == "0") && constraints.maxWidth < 800)
                  Container(
                    // margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    // decoration: BoxDecoration(
                    //     borderRadius: BorderRadius.circular(50),
                    //     color: Theme.of(context).primaryColor.withOpacity(0.1)
                    // ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for(var i = 0; i < irrigationProgramMainProvider.filterList.length; i++)
                            AppProperties.buildSideBarMenuList(
                              context: context,
                              title: irrigationProgramMainProvider.filterList[i],
                              dataList: irrigationProgramMainProvider.filterList,
                              index: i,
                              selected: irrigationProgramMainProvider.selectedFilterType == i,
                              onTap: (index) {
                                irrigationProgramMainProvider.updateSelectedFilterType(index);
                              },
                              constraints: constraints,
                            ),
                        ],
                      ),
                    ),
                  ),
                if(irrigationProgramMainProvider.programLibrary!.program.any((element) => element.programName.isNotEmpty && element.active == "0") && constraints.maxWidth >= 800)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for(var i = 0; i < irrigationProgramMainProvider.filterList.length; i++)
                          MaterialButton(
                            onPressed: (){
                              irrigationProgramMainProvider.updateSelectedFilterType(i);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: irrigationProgramMainProvider.selectedFilterType == i ? Theme.of(context).primaryColor : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: Text(irrigationProgramMainProvider.filterList[i], style: TextStyle(color: irrigationProgramMainProvider.selectedFilterType == i ? Colors.white : Theme.of(context).primaryColor),),
                            ),
                          )
                      ],
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                      child: customizeGridView(
                          maxWith: cardSize + 20,
                          maxHeight: 280,
                          screenWidth: constraints.maxWidth,
                          listOfWidget: [
                            for(var index = 0; index < irrigationProgramMainProvider.programLibrary!.program.length; index++)
                              SizedBox(
                                width: cardSize,
                                child: Column(
                                  children: [
                                    buildProgramItem(
                                        programItem: irrigationProgramMainProvider.programLibrary!.program[index],
                                        programLibraryData: irrigationProgramMainProvider.programLibrary!.program,
                                        cardSize: cardSize,
                                        index: index,
                                        constraints: constraints
                                    ),
                                    const SizedBox(height: 20,),
                                  ],
                                ),
                              ),
                          ]
                      )
                  ),
                ),
              ],
            );
          },
        ),
      )
          : const Center(child: CircularProgressIndicator(),),
      floatingActionButton: MaterialButton(
        onPressed: () {
          if(AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) {
            irrigationProgramMainProvider.programLibrary!.programLimit = 4;
          }
          createProgram(context, irrigationProgramMainProvider);
        },
        color: Theme.of(context).primaryColor,
        elevation: 10,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)
        ),
        child: const Text("+  Create", style: TextStyle(color: Colors.white),),
      ),
    );
  }

  void showIrrigationSettings(BuildContext parentContext) {
    final theme = Theme.of(parentContext);
    final initialDayCountSnapshot = dayCountRtcModel.toJson();
    final initialQueueSnapshot = programQueueModel.toJson();

    showModalBottomSheet(
      context: parentContext,
      showDragHandle: true,
      isScrollControlled: false,
      scrollControlDisabledMaxHeightRatio: 0.7,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          // Helper: Time Picker Tile
          Widget timePickerTile({
            required String title,
            required String currentTime,
            required VoidCallback onTap,
          }) {
            return ListTile(
              title: Text(title),
              trailing: Text(Constants.showHourAndMinuteOnly(currentTime, widget.modelId)),
              leading: Icon(Icons.access_time, color: theme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              onTap: onTap,
            );
          }

          // Reusable Time Picker Dialog
          void showTimePicker(String initialTime, Function(String) onSelected) {
            showDialog(
              context: context,
              builder: (_) {
                final overAllPvd = context.read<OverAllUse>();
                return AlertDialog(
                  title: HoursMinutesSeconds(
                    initialTime: initialTime,
                    modelId: widget.modelId,
                    onPressed: () {
                      final time = '${overAllPvd.hrs.toString().padLeft(2, '0')}:'
                          '${overAllPvd.min.toString().padLeft(2, '0')}:'
                          '${overAllPvd.sec.toString().padLeft(2, '0')}';
                      onSelected(time);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            );
          }

          // Handle back button / swipe down

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Count RTC
                Text('Day Count RTC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Day Count RTC'),
                  value: dayCountRtcModel.dayCountRtc,
                  activeThumbColor: theme.primaryColor,
                  onChanged: (v) => setState(() => dayCountRtcModel.dayCountRtc = v),
                ),
                if (dayCountRtcModel.dayCountRtc) ...[
                  const SizedBox(height: 16),
                  timePickerTile(
                    title: 'RTC Time',
                    currentTime: dayCountRtcModel.dayCountRtcTime,
                    onTap: () => showTimePicker(dayCountRtcModel.dayCountRtcTime, (t) => setState(() => dayCountRtcModel.dayCountRtcTime = t)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Program runs daily at this time!', style: TextStyle(color: Colors.grey[600])),
                  ),
                ],

                const SizedBox(height: 20),

                // Program Queue (Only for supported models)
                if (AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) ...[
                  const Divider(),
                  Text('Program Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Enable Program Queue'),
                    value: programQueueModel.programQueue,
                    activeTrackColor: theme.primaryColor,
                    onChanged: (v) => setState(() => programQueueModel.programQueue = v),
                  ),

                  if (programQueueModel.programQueue) ...[
                    SwitchListTile(
                      title: const Text('Enable Queue Restart'),
                      value: programQueueModel.autoQueueRestart,
                      activeThumbColor: theme.primaryColor,
                      onChanged: (v) => setState(() => programQueueModel.autoQueueRestart = v),
                    ),
                    const SizedBox(height: 12),

                    // Queue Order (4 slots)
                    ...List.generate(4, (index) {
                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            title: DropdownButtonFormField<String>(
                              initialValue: programQueueModel.queueOrder[index] != '0' ? programQueueModel.queueOrder[index] : '0',
                              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                              items: [
                                const DropdownMenuItem(value: '0', child: Text('None')),
                                ...irrigationProgramMainProvider.programLibrary!.program.map(
                                      (p) => DropdownMenuItem(value: p.serialNumber.toString(), child: Text(p.programName)),
                                ),
                              ],
                              onChanged: (v) => setState(() => programQueueModel.queueOrder[index] = v ?? '0'),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          if (programQueueModel.autoQueueRestart)
                            timePickerTile(
                              title: 'Delay ${index + 1}→${index == 3 ? 1 : index + 2}',
                              currentTime: programQueueModel.queueOrderRestartTimes[index],
                              onTap: () => showTimePicker(
                                programQueueModel.queueOrderRestartTimes[index],
                                    (t) => setState(() => programQueueModel.queueOrderRestartTimes[index] = t),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),

                    // Queue Preview
                    const Text('Queue Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                  child: Text(
                    'Order: ${programQueueModel.queueOrder.map((s) => s == '0' ? "None" : irrigationProgramMainProvider.programLibrary!.program.firstWhere((p) => p.serialNumber.toString() == s).programName).join(" → ")}'
                        '${programQueueModel.autoQueueRestart ? " (restarts)" : ""}'
                        '${programQueueModel.skipDays ? ", skips every ${programQueueModel.noOfSkipDays} days" : ""}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],

                // Skip Days
                Text('Skip Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Skip Days'),
                  value: programQueueModel.skipDays,
                  activeThumbColor: theme.primaryColor,
                  onChanged: (v) => setState(() => programQueueModel.skipDays = v),
                ),
                if (programQueueModel.skipDays) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Number of Skip Days'),
                    subtitle: Text('${programQueueModel.noOfSkipDays} days'),
                    leading: Icon(Icons.calendar_today, color: theme.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey[300]!)),
                    onTap: () async {
                      final days = await showDialog<int>(
                        context: context,
                        builder: (_) => NumberPickerDialog(
                          initialValue: int.tryParse(programQueueModel.noOfSkipDays) ?? 1,
                          minValue: 1,
                          maxValue: 30,
                        ),
                      );
                      if (days != null) setState(() => programQueueModel.noOfSkipDays = days.toString());
                    },
                  ),
                ],

                const SizedBox(height: 20),

                // Drip & Agitator sections...
                // (Same as before — kept clean)

                // Drip Standalone
                Text('Drip Standalone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                SwitchListTile(
                  title: const Text('Drip Standalone Mode'),
                  value: programQueueModel.dripStandaloneMode,
                  activeThumbColor: theme.primaryColor,
                  onChanged: (v) => setState(() => programQueueModel.dripStandaloneMode = v),
                ),

                const Divider(height: 40),

                // Agitator
                Text('Agitator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                SwitchListTile(
                  title: const Text('Agitator ON/OFF'),
                  value: programQueueModel.agitatorOnOff,
                  activeTrackColor: theme.primaryColor,
                  onChanged: (v) => setState(() => programQueueModel.agitatorOnOff = v),
                ),

                if (programQueueModel.agitatorOnOff) ...[
                  const SizedBox(height: 16),
                  timePickerTile(title: 'Agitator RTC ON Time', currentTime: programQueueModel.agitatorRTCOnTime,
                      onTap: () => showTimePicker(programQueueModel.agitatorRTCOnTime, (t) => setState(() => programQueueModel.agitatorRTCOnTime = t))),
                  const SizedBox(height: 16),
                  timePickerTile(title: 'Agitator RTC OFF Time', currentTime: programQueueModel.agitatorRTCOffTime,
                      onTap: () => showTimePicker(programQueueModel.agitatorRTCOffTime, (t) => setState(() => programQueueModel.agitatorRTCOffTime = t))),
                  const SizedBox(height: 16),
                  timePickerTile(title: 'Agitator Cyclic ON Time', currentTime: programQueueModel.agitatorCycONTime,
                      onTap: () => showTimePicker(programQueueModel.agitatorCycONTime, (t) => setState(() => programQueueModel.agitatorCycONTime = t))),
                  const SizedBox(height: 16),
                  timePickerTile(title: 'Agitator Cyclic OFF Time', currentTime: programQueueModel.agitatorCycOffTime,
                      onTap: () => showTimePicker(programQueueModel.agitatorCycOffTime, (t) => setState(() => programQueueModel.agitatorCycOffTime = t))),
                ],

                const SizedBox(height: 30),

                // Submit Button
              ElevatedButton(
                onPressed: () async {
                  try {
                    final Map<String, dynamic> dayCountRtcToNova = {
                      "7000": {
                        "7001":
                        "${dayCountRtcModel.dayCountRtc ? 1 : 0},${DateFormat.Hm().format(DateTime.parse('2025-01-01 ${dayCountRtcModel.dayCountRtcTime}')).split(':').join(',')}"
                      }
                    };

                    final Map<String, dynamic> programQueueToNova = {
                      "8000": {
                        "8001":
                        "${programQueueModel.programQueue ? 1 : 0},"
                            "${programQueueModel.queueOrder.join(',')},"
                            "${programQueueModel.autoQueueRestart ? 1 : 0},"
                            "${programQueueModel.queueOrderRestartTimes.join(',').replaceAll(':', ',')},"
                            "${programQueueModel.skipDays ? 1 : 0},"
                            "${programQueueModel.noOfSkipDays},"
                            "${programQueueModel.runDays ? 1 : 0},"
                            "${programQueueModel.noOfRunDays},"
                            "${0},"
                            "${programQueueModel.dripStandaloneMode ? 1 : 0},"
                            "${programQueueModel.agitatorOnOff ? 1 : 0},"
                            "${programQueueModel.agitatorRTCOnTime.replaceAll(':', ',')},"
                            "${programQueueModel.agitatorRTCOffTime.replaceAll(':', ',')},"
                            "${programQueueModel.agitatorCycONTime.replaceAll(':', ',')},"
                            "${programQueueModel.agitatorCycOffTime.replaceAll(':', ',')}"
                        // "${programQueueModel.queueReset ? 1 : 0}"
                      }
                    };

                    final List<String> payloadList = [
                      if(initialDayCountSnapshot.toString() != dayCountRtcModel.toJson().toString())
                        jsonEncode(dayCountRtcToNova),
                      if(initialQueueSnapshot.toString() != programQueueModel.toJson().toString())
                        jsonEncode(programQueueToNova)
                    ];

                    final List<String> payloadList2 = [
                      jsonEncode(dayCountRtcToNova),
                      jsonEncode(programQueueToNova)
                    ];

                    final result = await showDialog<String>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => EcoGemProgressDialog(
                        payloads: payloadList.isEmpty ? payloadList2 : payloadList,
                        deviceId: widget.deviceId,
                        mqttService: MqttService(),
                      ),
                    );

                    if (result != null) setState(() => controllerReadStatus = result);

                    final response = await repository.createDayCountRtc({
                      "userId": widget.customerId,
                      "controllerId": widget.controllerId,
                      "dayCountRtc": {
                        "dayCountRtc": dayCountRtcModel.toJson(),
                        "programQueue": programQueueModel.toJson(),
                      },
                      "createUser": widget.userId,
                      "controllerReadStatus": controllerReadStatusForDayCount,
                    });
                    final message = jsonDecode(response.body)['message'];
                    ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: message));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Submit', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void createProgram(BuildContext context, IrrigationProgramMainProvider programProvider) {
    final programs = programProvider.programLibrary!.program;
    final nonEmptyPrograms = programs.where((element) => element.programName.isNotEmpty).length;
    final programLimit = programProvider.programLibrary!.programLimit;

    if (nonEmptyPrograms >= programLimit) {
      _showLimitExceededDialog(context);
      return;
    }

    final serialNumber = programs.any((element) => element.programName.isEmpty)
        ? programs.firstWhere((element) => element.programName.isEmpty).serialNumber
        : 0;

    Future navigateToIrrigationProgram() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IrrigationProgram(
          userId: widget.userId,
          controllerId: widget.controllerId,
          serialNumber: serialNumber,
          programType: irrigationProgramMainProvider.selectedProgramType,
          deviceId: widget.deviceId,
          fromDealer: false,
          customerId: widget.customerId,
          groupId: widget.groupId,
          categoryId: widget.categoryId,
          modelId: widget.modelId,
          deviceName: widget.deviceName,
          categoryName: widget.categoryName,
          nodeList: widget.nodeList,
        ),
      ),
    );

    if (programProvider.programLibrary!.defaultProgramTypes.length > 1) {
      showAdaptiveDialog(
        context: context,
        builder: (BuildContext dialogContext) => Consumer<IrrigationProgramMainProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              title: Text(
                "Select Program type",
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: provider.programLibrary!.defaultProgramTypes
                    .map(
                      (e) => RadioListTile(
                    title: Text(e),
                    value: e,
                    groupValue: provider.selectedProgramType,
                    onChanged: (newValue) => provider.updateProgramName(newValue, 'programType'),
                  ),
                )
                    .toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    navigateToIrrigationProgram();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        ),
      );
    }
    else {
      navigateToIrrigationProgram();
    }
  }

  void _showLimitExceededDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (BuildContext dialogContext) => CustomAlertDialog(
        title: "Alert",
        content: "The program limit is exceeded as defined in the Product limit!",
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget buildProgramItem({
    required Program programItem,
    required List<Program> programLibraryData,
    required cardSize,
    required int index,
    required BoxConstraints constraints,})
  {

    final scheduleByDays = programItem.schedule['selected'] == irrigationProgramMainProvider.scheduleTypes[1];
    final scheduleAsRunList = programItem.schedule['selected'] == irrigationProgramMainProvider.scheduleTypes[2];
    final ScrollController scrollController = ScrollController();

    final startDate = scheduleByDays
        ? programItem.schedule['scheduleAsRunList']['schedule']['startDate']
        : scheduleAsRunList
        ? programItem.schedule['scheduleByDays']['schedule']['startDate']
        : DateTime.now().toString();
    final endDate = scheduleByDays
        ? programItem.schedule['scheduleAsRunList']['schedule']['endDate']
        : scheduleAsRunList
        ? programItem.schedule['scheduleByDays']['schedule']['endDate']
        : DateTime.now().toString();

    final isForceToEndDate = scheduleByDays
        ? programItem.schedule['scheduleAsRunList']['schedule']['isForceToEndDate']
        : scheduleAsRunList
        ? programItem.schedule['scheduleByDays']['schedule']['isForceToEndDate']
        : false;

    final rtcType = scheduleByDays
        ? programItem.schedule['scheduleAsRunList']['rtc']
        : scheduleAsRunList
        ? programItem.schedule['scheduleByDays']['rtc']
        : "";
    int pageCount = rtcType.isNotEmpty ? rtcType.length : 0;

    final startDateOnly = DateFormat('MMM d').format(DateTime.parse(startDate));
    final endDateOnly = DateFormat('MMM d').format(DateTime.parse(endDate));
    String getWeekday(int weekday) {
      const daysInWeek = 7;
      List<String> weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      int adjustedWeekday = (weekday - 1 + daysInWeek) % daysInWeek;

      return weekdays[adjustedWeekday];
    }

    List<String> days = List.generate(
      scheduleByDays
          ? int.parse(programItem.schedule['scheduleAsRunList']['schedule']['noOfDays'].toString().isNotEmpty ? programItem.schedule['scheduleAsRunList']['schedule']['noOfDays'].toString() : "1")
          : scheduleAsRunList
          ? int.parse(programItem.schedule['scheduleByDays']['schedule']['runDays'].toString().isNotEmpty ? programItem.schedule['scheduleByDays']['schedule']['runDays'].toString() : '0') + int.parse(programItem.schedule['scheduleByDays']['schedule']['skipDays'].toString())
          : 0,
          (index) {
        DateTime currentDate = DateTime.parse(startDate).add(Duration(days: index));
        return getWeekday(currentDate.weekday);
      },
    );

    return InkWell(
      onTap: () => programItem.programName.isNotEmpty ? navigateToIrrigationProgram(programItem) : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: AppProperties.customBoxShadowLiteTheme,
            borderRadius: BorderRadius.circular(10)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text((scheduleByDays || scheduleAsRunList) ? "$startDateOnly - ${(isForceToEndDate ?? false) ? endDateOnly : "No end date"}" : "Manual start", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),),
                if(programItem.programName.isNotEmpty)
                  Row(
                    children: [
                      buildIconActionWidget(
                          icon: Icons.copy,
                          iconColor: Theme.of(context).primaryColor,
                          containerColor: const Color(0xffE0FFF7),
                          toolTip: "Copy",
                          onTap: () {
                            tempProgramName = "";
                            copyController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: copyController.text.length,
                            );
                            // Define a default Program object
                            final serialNumber = irrigationProgramMainProvider.programLibrary!.program.any((element) => element.programName.isEmpty)
                                ? irrigationProgramMainProvider.programLibrary!.program.firstWhere((element) => element.programName.isEmpty).serialNumber
                                : irrigationProgramMainProvider.programLibrary!.program.length+1;
                            final programType = programItem.programType;
                            String programName = "Program $serialNumber";
                            String defaultProgramName = programName;
                            copyController.text = programName;
                            programCopy(
                                program: programItem,
                                serialNumber: serialNumber,
                                programType: programType,
                                programName: programName,
                                defaultProgramName: defaultProgramName,
                                programLibraryData: programLibraryData,
                                context: context
                            );
                          }
                      ),
                      const SizedBox(width: 10,),
                      buildIconActionWidget(
                          icon: programItem.active == "1" ? Icons.remove_circle : Icons.add_circle,
                          iconColor: programItem.active == "1" ? const Color(0xfffd847c) : const Color(0xff10b637),
                          containerColor: programItem.active == "1" ? const Color(0xffFFDEDC) : const Color(0xffd2f3df),
                          toolTip: programItem.active == "1" ? "Inactive program" : "Active program",
                          onTap: () => showConfirmationDialog(programItem, programItem.active == "1" ? "inactive" : "active")
                      ),
                      const SizedBox(width: 10,),
                      if(programItem.active == "1")
                        buildIconActionWidget(
                            icon: Icons.edit,
                            iconColor: const Color(0xffFFB27D),
                            containerColor: const Color(0xffFFF0E5),
                            toolTip: "Edit",
                            onTap: () {
                              // print(index);
                              // print(programItem.programName);
                              // print(programItem.defaultProgramName);
                              showEditItemDialog(programItem, index, programLibraryData);
                            }
                        ),
                      if(programItem.active == "1")
                        const SizedBox(width: 10,),
                      buildIconActionWidget(
                        icon: programItem.active == "1" ? Icons.send : Icons.delete,
                        iconColor: programItem.active == "1" ? programItem.controllerReadStatus == "1" ? const Color(
                            0xff10b637) : const Color(0xfffbcd38) : const Color(0xfffd847c),
                        containerColor: programItem.active == "1" ? programItem.controllerReadStatus == "1" ? const Color(
                            0xffd2f3df) : const Color(0xffFFDEDC) : const Color(0xffFFDEDC),
                        toolTip: programItem.active == "1" ? "Send" : "Delete",
                        onTap: () async{
                          if(programItem.active == "1") {
                            var dataToMqtt = programItem.hardwareData;

                            try {
                              if(AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) {
                                final result = await showDialog<String>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return EcoGemProgressDialog(
                                      payloads: List<String>.from(dataToMqtt),
                                      deviceId: widget.deviceId,
                                      mqttService: MqttService(),
                                    );
                                  },
                                );

                                if (result != null) {
                                  setState(() {
                                    controllerReadStatus = result;
                                  });
                                }
                              } else  {
                                await validatePayloadSent(
                                    dialogContext: context,
                                    context: context,
                                    acknowledgedFunction: () {
                                      setState(() {
                                        controllerReadStatus = "1";
                                      });
                                      // showSnackBar(message: "${mqttPayloadProvider.messageFromHw['Name']} from controller", context: context);
                                    },
                                    payload: dataToMqtt,
                                    payloadCode: "2500",
                                    deviceId: widget.deviceId
                                ).whenComplete(() async {
                                  if(MqttService().acknowledgementPayload!['cM']['4201']['Code'] != "200") {
                                    setState(() {
                                      controllerReadStatus = "0";
                                    });
                                  }
                                });
                              }
                              await saveProgramDetails(programItem, dataToMqtt);
                              await Future.delayed(const Duration(seconds: 1), () async{
                                await irrigationProgramMainProvider.programLibraryData(widget.customerId,  widget.controllerId);
                              });
                            } catch (error) {
                              showSnackBar(message: 'Failed to update because of $error', context: context);
                              // print("Error: $error");
                              // print("stackTrace: $stackTrace");
                            }
                          } else {
                            showConfirmationDialog(programItem, "delete");
                          }
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => navigateToIrrigationProgram(programItem),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(programItem.programName.isNotEmpty ? programItem.programName : programItem.defaultProgramName,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 16),),
                      Text(programItem.programType, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: Text(programItem.sequence.length > 1 ? "${programItem.sequence.length} Zones" : "${programItem.sequence.length} Zone", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),),
                )
              ],
            ),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      programItem.programName.isNotEmpty
                          ? programItem.schedule['selected'].toString().toLowerCase().substring(0,1).toUpperCase() + programItem.schedule['selected'].toString().toLowerCase().substring(1) ?? "-"
                          : "Inactive program", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: programItem.programName.isNotEmpty ? Colors.black : Colors.grey),),
                    SizedBox(
                      height: 30,
                      width: cardSize - 180,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          scrollController.jumpTo(pageController.offset - details.primaryDelta! / 2);
                        },
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.antiAlias,
                          controller: scrollController,

                          child: Row(
                            children: [
                              if(programItem.schedule['selected'] == irrigationProgramMainProvider.scheduleTypes[1])
                                for(var index = 0; index < int.parse(programItem.schedule['scheduleAsRunList']['schedule']['noOfDays'].toString().isNotEmpty ? programItem.schedule['scheduleAsRunList']['schedule']['noOfDays'].toString() : "1"); index++)
                                  buildScheduleMethodOfDay(
                                    // method: programItem.schedule['scheduleAsRunList']['schedule']['type'][index] == irrigationProgramMainProvider.scheduleOptions[0]
                                    //     ? "N"
                                    //     : programItem.schedule['scheduleAsRunList']['schedule']['type'][index] == irrigationProgramMainProvider.scheduleOptions[1]
                                    //     ? "O"
                                    //     : programItem.schedule['scheduleAsRunList']['schedule']['type'][index] == irrigationProgramMainProvider.scheduleOptions[2]
                                    //     ? "W"
                                    //     : "F",
                                      method: days[index],
                                      color: programItem.schedule['scheduleAsRunList']['schedule']['type'][index] == irrigationProgramMainProvider.scheduleOptions[0]
                                          ? const Color(0xffFFEFE1)
                                          : programItem.schedule['scheduleAsRunList']['schedule']['type'][index] == irrigationProgramMainProvider.scheduleOptions[1]
                                          ? const Color(0xffE0FFF7)
                                          : programItem.schedule['scheduleAsRunList']['schedule']['type'][index] == irrigationProgramMainProvider.scheduleOptions[2]
                                          ? const Color(0xffE1F2FF)
                                          : const Color(0xffEEEBFF)
                                  )
                              else if(programItem.schedule['selected'] == irrigationProgramMainProvider.scheduleTypes[2])
                                for (var index = 0; index < (int.parse(programItem.schedule['scheduleByDays']['schedule']['runDays'].toString().isNotEmpty ? programItem.schedule['scheduleByDays']['schedule']['runDays'].toString() : '0')
                                    + int.parse(programItem.schedule['scheduleByDays']['schedule']['skipDays'].toString().isNotEmpty ? programItem.schedule['scheduleByDays']['schedule']['skipDays'].toString() : '0')); index++)
                                  buildScheduleMethodOfDay(
                                    method: days[index],
                                    color: index >= int.parse(programItem.schedule['scheduleByDays']['schedule']['runDays'].toString().isNotEmpty
                                        ? programItem.schedule['scheduleByDays']['schedule']['runDays'].toString() : "0") ? const Color(0xffFFEFE1) : const Color(0xffE1F2FF),
                                  )
                              else
                                buildScheduleMethodOfDay(
                                    method: "NOT SCHEDULED",
                                    color: Colors.grey.withValues(alpha: 0.2)
                                )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                Text(
                  programItem.schedule['selected'] == irrigationProgramMainProvider.scheduleTypes[1]
                      ? "${programItem.schedule['scheduleAsRunList']['schedule']['noOfDays'].toString() == "" ? '1' : programItem.schedule['scheduleAsRunList']['schedule']['noOfDays'].toString()} day cycle"
                      : programItem.schedule['selected'] == irrigationProgramMainProvider.scheduleTypes[2]
                      ? "Run days - ${programItem.schedule['scheduleByDays']['schedule']['runDays'].toString()} \nSkip days - ${programItem.schedule['scheduleByDays']['schedule']['skipDays'].toString()}"
                      : "-",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                )
              ],
            ),
            // SizedBox(height: 5,),
            const Divider(color: Color(0xffE5DADA),),
            SizedBox(
              height: 75,
              child: Column(
                children: [
                  SizedBox(
                    height: 65,
                    width: double.maxFinite,
                    child: (scheduleByDays || scheduleAsRunList)
                        ? GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        pageController.jumpTo(pageController.offset - details.primaryDelta! / 2);
                      },
                      child: PageView.builder(
                          controller: pageController,
                          itemCount: pageCount,
                          physics: const AlwaysScrollableScrollPhysics(),
                          onPageChanged: (int index) {
                            Future.delayed(const Duration(milliseconds: 500), () {
                              setState(() {
                                currentIndex = index;
                              });
                            });
                          },
                          itemBuilder: (context, index) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    buildRtcWidget(title: "RTC No", dataString: '${index+1}'),
                                    const SizedBox(width: 10,),
                                    buildRtcWidget(title: "Start time", dataString: rtcType['rtc${index+1}']['onTime']),
                                    const SizedBox(width: 10,),
                                    buildRtcWidget(title: "Cycle Interval", dataString: rtcType['rtc${index+1}']['interval']),
                                    const SizedBox(width: 10,),
                                    buildRtcWidget(title: "Cycles", dataString: rtcType['rtc${index+1}']['noOfCycles']),
                                    const SizedBox(width: 10,),
                                    if(rtcType['rtc${index+1}']['stopMethod'] == irrigationProgramMainProvider.stopMethods[1])
                                      buildRtcWidget(title: "Off time", dataString: rtcType['rtc${index+1}']['offTime']),
                                    if(rtcType['rtc${index+1}']['stopMethod'] == irrigationProgramMainProvider.stopMethods[2])
                                      buildRtcWidget(title: "Max time", dataString: rtcType['rtc${index+1}']['maxTime']),
                                  ],
                                ),
                              ),
                            );
                          }
                      ),
                    )
                        : Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)
                        ),
                        child: const Center(child: Text("RTC not available for this method", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500),))),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for(var i = 0; i < pageCount; i++)
                        InkWell(
                          onTap: () {
                            pageController.animateToPage(i, duration: const Duration(milliseconds: 500), curve: Curves.easeIn);
                          },
                          child: AnimatedContainer(
                            height: 8,
                            width: currentIndex == i ? 20 : 8,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                                color: pageCount > 1 ? currentIndex == i ? Theme.of(context).primaryColor : Colors.grey : Colors.white,
                                // shape: BoxShape.circle
                                borderRadius: BorderRadius.circular(10)
                            ),
                            duration: const Duration(milliseconds: 200),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void programCopy({
    required BuildContext context,
    required Program program,
    required int serialNumber,
    required String programType,
    required String programName,
    required String defaultProgramName,
    required List<Program> programLibraryData,
  }) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String tempProgramName = "";

    showAdaptiveDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter stateSetter) {
            return AlertDialog(
              title: const Text("Program copy!"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                        controller: copyController,
                        autofocus: true,
                        onChanged: (newValue) {
                          stateSetter(() {
                            tempProgramName = newValue;
                          });
                        },
                        inputFormatters: [LengthLimitingTextInputFormatter(20),  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Name cannot be empty";
                          }
                          if (programLibraryData.any((element) => element.programName == value)) {
                            return "Name already exists";
                          }
                          return null;
                        },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    tempProgramName = "";
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      createCopyOfProgram(
                        oldSerialNumber: program.serialNumber,
                        serialNumber: serialNumber,
                        programName: tempProgramName.isEmpty ? defaultProgramName : tempProgramName,
                        defaultProgramName: defaultProgramName,
                        programType: programType,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void createCopyOfProgram({required int oldSerialNumber, required int serialNumber, required String programName, required String defaultProgramName, required String programType}) {
    irrigationProgramMainProvider
        .userProgramCopy( widget.userId,  widget.controllerId, oldSerialNumber, serialNumber, programName, defaultProgramName, programType, widget.customerId)
        .then((String message) {
      ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: message));
    }).then((value) => irrigationProgramMainProvider.programLibraryData( widget.customerId,  widget.controllerId)
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: error));
    }));
  }

  void showConfirmationDialog(Program program,String toMove) {
    showAdaptiveDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return CustomAlertDialog(
              title: "Confirmation",
              content: 'Are you sure you want to ${toMove == "delete" ? "delete" : toMove == "active" ? "move to active" : "move to inactive"}?',
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () async{
                    if(toMove == "active" || toMove == "inactive") {
                      print("program.hardwareData : ${program.hardwareData}");
                      var dataToMqtt = program.hardwareData;
                      Map<String, dynamic> deleteProgramToHardware = {
                        "3800": {
                          "3801": "${program.serialNumber};"
                        }
                      };
                      try {
                        Navigator.of(dialogContext).pop();
                        if(AppConstants.ecoGemAndPlusModelList.contains(widget.modelId) && toMove == "active") {
                          final result = await showDialog<String>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return EcoGemProgressDialog(
                                payloads: List<String>.from(dataToMqtt),
                                deviceId: widget.deviceId,
                                mqttService: MqttService(),
                              );
                            },
                          );

                          if (result != null) {
                            setState(() {
                              controllerReadStatus = result;
                            });
                            deleteProgram(program, toMove);
                          }
                        }else{
                          await validatePayloadSent(
                              dialogContext: context,
                              context: context,
                              acknowledgedFunction: () {
                                setState(() {
                                  controllerReadStatus = "1";
                                });
                                deleteProgram(program, toMove);
                                // showSnackBar(message: "${mqttPayloadProvider.messageFromHw['Name']} from controller", context: context);
                              },
                              payload: toMove == "active" ? dataToMqtt : deleteProgramToHardware,
                              payloadCode: toMove == "active" ? "2500" : "3800",
                              deviceId: widget.deviceId
                          ).whenComplete(() async {
                            if(MqttService().acknowledgementPayload!['cM']['4201']['Code'] != "200") {
                              setState(() {
                                controllerReadStatus = "0";
                              });
                            }
                          });
                        }

                        // await saveProgramDetails(program, dataToMqtt);
                        await Future.delayed(const Duration(seconds: 1), () async{
                          await irrigationProgramMainProvider.programLibraryData( widget.customerId,  widget.controllerId,);
                        });
                        if(toMove != "inactive") {
                          if(irrigationProgramMainProvider.programLibrary!.program.any((element) => element.programName.isNotEmpty)) {
                            irrigationProgramMainProvider.updateSelectedFilterType(0);
                          }
                        }
                      } catch (error) {
                        showSnackBar(message: 'Failed to update because of $error', context: context);
                        // print("Error: $error");
                      }
                    } else {
                      deleteProgram(program, toMove);
                      if(irrigationProgramMainProvider.programLibrary!.program.any((element) => element.programName.isNotEmpty && element.active == "0")) {
                        irrigationProgramMainProvider.updateSelectedFilterType(0);
                      }
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Yes'),
                )
              ]);
        });
  }

  void deleteProgram(Program program, String active) {
    irrigationProgramMainProvider
        .userProgramReset(
         widget.userId,
         widget.controllerId,
        program.programId,
        widget.deviceId,
        program.serialNumber, program.defaultProgramName, program.programName, active, controllerReadStatus, widget.customerId)
        .then((String message) {
      ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: message));
    }).then((value) => irrigationProgramMainProvider.programLibraryData( widget.customerId,  widget.controllerId)
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: error));
    }));
  }

  void showEditItemDialog(Program program, int index, List<Program> programLibraryData) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    showAdaptiveDialog(
      context: context,
      builder: (BuildContext dialogContext) =>
          Consumer<IrrigationProgramMainProvider>(
              builder: (context, scheduleProvider, child) {
                return AlertDialog(
                  surfaceTintColor: Colors.white,
                  title: const Text('Edit Item'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          initialValue: program.programName.isNotEmpty
                              ? program.programName
                              : program.defaultProgramName,
                          focusNode: _programNameFocusNode,
                          // onChanged: (newValue) => program.programName = newValue,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(20),
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.]'))
                          ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Name cannot be empty";
                              } else if (programLibraryData.any((element) => element.programName == value)) {
                                return "Name already exists";
                              } else {
                                setState(() {
                                  program.programName = value;
                                });
                              }
                              return null;
                            },
                        ),
                        const SizedBox(height: 5),
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15)),
                          child: CustomDropdownTile(
                            showCircleAvatar: false,
                            width: 70,
                            title: 'Priority',
                            subtitle: 'Description',
                            showSubTitle: false,
                            content: Icons.priority_high,
                            dropdownItems: irrigationProgramMainProvider.priorityList.map((item) => item).toList(),
                            selectedValue: program.priority,
                            onChanged: (newValue) {
                              irrigationProgramMainProvider.updatePriority(newValue, index);
                              _programNameFocusNode.unfocus();
                            },
                            includeNoneOption: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async{
                        if (formKey.currentState!.validate()) {
                          Map<String, dynamic> dataToMqtt = {
                            "2800": {
                              "2801" : "${program.serialNumber},${program.priority == irrigationProgramMainProvider.priorityList[0] ? 1 : 0}"
                            },
                          };

                          try {
                            await validatePayloadSent(
                                dialogContext: context,
                                context: context,
                                acknowledgedFunction: () {
                                  setState(() {
                                    controllerReadStatus = "1";
                                  });
                                  // showSnackBar(message: "${mqttPayloadProvider.messageFromHw['Name']} from controller", context: context);
                                },
                                payload: dataToMqtt,
                                payloadCode: "2800",
                                deviceId: widget.deviceId
                            ).whenComplete(() {
                              if(MqttService().acknowledgementPayload!['cM']['4201']['Code'] != "200") {
                                setState(() {
                                  controllerReadStatus = "0";
                                });
                              }
                            });
                            await saveProgramDetails(program, dataToMqtt);
                            await Future.delayed(const Duration(seconds: 2), () async{
                              await irrigationProgramMainProvider.programLibraryData(widget.customerId,  widget.controllerId);
                            });
                          } catch (error) {
                            showSnackBar(message: 'Failed to update because of $error', context: dialogContext);
                            // print("Error: $error");
                          }
                          Navigator.pop(dialogContext);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                );
              }),
    );
  }

  Future<void> saveProgramDetails(Program program, hardwareData) async{
    irrigationProgramMainProvider
        .updateUserProgramDetails(
         widget.userId,
         widget.controllerId,
        program.serialNumber,
        program.programId,
        program.programName,
        program.priority,
        program.defaultProgramName,
        controllerReadStatus, hardwareData, widget.customerId)
        .then((value) => ScaffoldMessenger.of(context)
        .showSnackBar(CustomSnackBar(message: value)));
  }

  void navigateToIrrigationProgram(program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IrrigationProgram(
          userId:  widget.userId,
          controllerId:  widget.controllerId,
          serialNumber: program.serialNumber,
          programType: program.programType,
          deviceId:  widget.deviceId,
          fromDealer: false,
          // fromDealer: overAllUse.fromDealer,
          customerId:  widget.customerId,
          groupId:  widget.groupId,
          categoryId:  widget.categoryId,
          modelId: widget.modelId,
          deviceName: widget.deviceName,
          categoryName: widget.categoryName,
          nodeList: widget.nodeList,
        ),
      ),
    );
  }

  Widget buildScheduleMethodOfDay({required String method, Color? color}){
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
      decoration: BoxDecoration(
          color: color ?? const Color(0xffE9F8FA),
          borderRadius: BorderRadius.circular(5)
      ),
      child: Text(method, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),),
    );
  }

  Widget buildRtcWidget({required String title, required String dataString}) {
    return Expanded(
      child: Container(
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),),
            Text(dataString, style: const TextStyle(fontSize: 14, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w500),),
          ],
        ),
      ),
    );
  }

  Widget buildIconActionWidget({
    required IconData icon,
    required Color iconColor,
    required Color containerColor,
    void Function()? onTap,
    required String toolTip,
  }) {
    return Tooltip(
      message: toolTip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 4),
                blurRadius: 4,
                color: const Color(0xffCFCFCF).withValues(alpha: 0.25),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }

  Widget customizeGridView({required double maxWith,required double maxHeight,required double screenWidth,required List<Widget> listOfWidget}){
    var eachRowCount = (screenWidth)~/(maxWith);
    List<List<Widget>> gridWidgetRow = [];
    List<Widget> newWidgetList = [];
    for(var i = 0; i<listOfWidget.length; i++) {
      if(irrigationProgramMainProvider.selectedFilterType == 0) {
        if(irrigationProgramMainProvider.programLibrary!.program[i].programName.isNotEmpty && irrigationProgramMainProvider.programLibrary!.program[i].active == "1") {
          newWidgetList.add(listOfWidget[i]);
        }
      } else {
        if(irrigationProgramMainProvider.programLibrary!.program[i].programName.isNotEmpty && irrigationProgramMainProvider.programLibrary!.program[i].active == "0") {
          newWidgetList.add(listOfWidget[i]);
        }
      }
    }
    for(var i = 0;i < newWidgetList.length;i +=(newWidgetList.length - i) < eachRowCount ? (newWidgetList.length - i) : eachRowCount){
      List<Widget> rows = [];
      for(var j = 0;j < ((newWidgetList.length - i) < eachRowCount ? (newWidgetList.length - i) : eachRowCount);j++){
        rows.add(newWidgetList[i + j]);
      }
      gridWidgetRow.add(rows);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        for(var i = 0; i < gridWidgetRow.length; i++)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for(var widget = 0;widget < gridWidgetRow[i].length;widget++)
                    Container(
                        margin: EdgeInsets.symmetric(horizontal: (((screenWidth) - (eachRowCount * maxWith))/eachRowCount)/2.toInt().toDouble()),
                        width: maxWith,
                        height: maxHeight,
                        child: gridWidgetRow[i][widget]
                    )
                ],
              ),
              if(i == gridWidgetRow.length - 1)
                const SizedBox(height: 50,)
            ],
          ),
      ],
    );
  }
}

Future<void> validatePayloadSent({
  required BuildContext dialogContext,
  required BuildContext context,
  MqttPayloadProvider? mqttPayloadProvider,
  required void Function() acknowledgedFunction,
  void Function()? failedFunction,
  required payload,
  required String payloadCode,
  required String deviceId,
}) async {
  try {
    MqttService().acknowledgementPayload = null;

    await MqttService().topicToPublishAndItsMessage(jsonEncode(payload), '${Environment.mqttPublishTopic}/$deviceId');

    bool isAcknowledged = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Please wait..."),
              ],
            ),
          ),
        );
      },
    );

    await for (final message in MqttService().payloadController.timeout(
      const Duration(seconds: 30),
      onTimeout: (sink) => sink.close(),
    )) {
      if (message != null && message['cM']['4201'] != null && message['cM']['4201']['PayloadCode'] == payloadCode) {
        isAcknowledged = true;
        break;
      }
    }

    Navigator.of(context).pop();

    if (isAcknowledged) {
      final decodedPayload = MqttService().acknowledgementPayload!;
      if (decodedPayload['cM']['4201']['Code'] == "200" || decodedPayload['cM']['4201']['Code'] == "67") {
        acknowledgedFunction();
      } else {
        if(failedFunction != null) {
          failedFunction();
        }
        showSnackBar(message: "${decodedPayload['cM']['4201']['Name']}", context: context,);
      }
    } else {
      showAlertDialog(
        message: "Controller is not responding",
        context: context,
      );
      await Future.delayed(const Duration(seconds: 1));
      Navigator.of(context).pop();
    }
  } catch (error) {
    // print("stackTrace ::: $stackTrace");
    // print("error ::: $error");
    showAlertDialog(message: error.toString(), context: context);
    await Future.delayed(const Duration(seconds: 1));
    Navigator.of(context).pop();
  }
}

void showAlertDialog({required String message, Widget? child, required BuildContext context}) {
  showAdaptiveDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Alert"),
          content: child ?? Text(message),
          actions: [
            TextButton(
                onPressed: (){
                  Navigator.of(context).pop();
                },
                child: const Text("OK")
            )
          ],
        );
      }
  );
}

void showSnackBar({required String message, required BuildContext context}) {
  ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: message));
}

// Dialog for picking duration (minutes)
/*class DurationPickerDialog extends StatelessWidget {
  final int initialMinutes;

  const DurationPickerDialog({super.key, required this.initialMinutes});

  @override
  Widget build(BuildContext context) {
    int minutes = initialMinutes;
    return AlertDialog(
      title: const Text('Set Delay'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: minutes > 0
                    ? () => setState(() => minutes--)
                    : null,
                color: theme.primaryColor,
              ),
              Text('$minutes min'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: minutes < 1440 // Max 24 hours
                    ? () => setState(() => minutes++)
                    : null,
                color: theme.primaryColor,
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, minutes),
          child: const Text('OK'),
        ),
      ],
    );
  }
}*/

// Dialog for picking number of skip days
class NumberPickerDialog extends StatelessWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;

  const NumberPickerDialog({super.key,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int value = initialValue;
    return AlertDialog(
      title: const Text('Set Skip Days'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: value > minValue
                    ? () => setState(() => value--)
                    : null,
                color: theme.primaryColor,
              ),
              Text('$value days'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: value < maxValue
                    ? () => setState(() => value++)
                    : null,
                color: theme.primaryColor,
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, value),
          child: const Text('OK'),
        ),
      ],
    );
  }
}