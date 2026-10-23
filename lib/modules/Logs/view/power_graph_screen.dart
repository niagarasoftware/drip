import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';

import '../../../Constants/constants.dart';
import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';
import '../../Preferences/widgets/custom_segmented_control.dart';
import '../../PumpController/state_management/pump_controller_provider.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import '../model/motor_data_hourly.dart';
import '../widgets/custom_calendar_mobile.dart';
import '../widgets/custom_widgets.dart';

class PowerGraphScreen extends StatefulWidget {
  final int userId;
  final int controllerId;
  final int nodeControllerId;
  final MasterControllerModel masterData;
  const PowerGraphScreen({super.key, required this.userId, required this.controllerId, this.nodeControllerId = 0, required this.masterData});

  @override
  State<PowerGraphScreen> createState() => _PowerGraphScreenState();
}

class _PowerGraphScreenState extends State<PowerGraphScreen> {
  int selectedIndex = 0;
  late PumpControllerProvider pumpControllerProvider;

  @override
  void initState() {
    super.initState();
    pumpControllerProvider = Provider.of(context,listen: false);
    pumpControllerProvider.getPumpControllerData(userId: widget.userId, controllerId: widget.controllerId, nodeControllerId: widget.nodeControllerId);
  }

  @override
  void didUpdateWidget(covariant PowerGraphScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controllerId != oldWidget.controllerId ||
        widget.nodeControllerId != oldWidget.nodeControllerId) {
      pumpControllerProvider.getPumpControllerData(
        userId: widget.userId,
        controllerId: widget.controllerId,
        nodeControllerId: widget.nodeControllerId,
      );
    }
  }

  Future<void> showSnackBar({required String message}) async{
    ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message:  message));
  }

  Future<void> exportMotorDataToExcel(List<MotorDataHourly> motorDataList, name, context) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    sheet.appendRow([
      TextCellValue('Date'),
      // TextCellValue('Number of Pumps'),
      TextCellValue('Two Phase Power On Time'),
      TextCellValue('Overall Cumulative Flow'),
      TextCellValue('Flow Rate'),
      TextCellValue('Pressure'),
      TextCellValue('Level'),
      TextCellValue('Two Phase Last Power On Time'),
      TextCellValue('Three Phase Power On Time'),
      TextCellValue('Three Phase Last Power On Time'),
      TextCellValue('Power Off Time'),
      TextCellValue('Last Power On Time'),
      TextCellValue('Total Power On Time'),
      TextCellValue('Total Power Off Time'),
      TextCellValue('Motor Run Time 1'),
      TextCellValue('Motor Idle Time 1'),
      TextCellValue('Last Date Run Time 1'),
      TextCellValue('Last Date Run Flow 1'),
      TextCellValue('Dry Run Trip Time 1'),
      TextCellValue('Cyclic Trip Time 1'),
      TextCellValue('Other Trip Time 1'),
      TextCellValue('Total Flow Today 1'),
      TextCellValue('Motor Run Time 2'),
      TextCellValue('Motor Idle Time 2'),
      TextCellValue('Last Date Run Time 2'),
      TextCellValue('Last Date Run Flow 2'),
      TextCellValue('Dry Run Trip Time 2'),
      TextCellValue('Cyclic Trip Time 2'),
      TextCellValue('Other Trip Time 2'),
      TextCellValue('Total Flow Today 2'),
      TextCellValue('Motor Run Time 3'),
      TextCellValue('Motor Idle Time 3'),
      TextCellValue('Last Date Run Time 3'),
      TextCellValue('Last Date Run Flow 3'),
      TextCellValue('Dry Run Trip Time 3'),
      TextCellValue('Cyclic Trip Time 3'),
      TextCellValue('Other Trip Time 3'),
      TextCellValue('Total Flow Today 3'),
    ]);

    // Append rows of data
    for (var data in motorDataList) {
      sheet.appendRow([
        TextCellValue(data.date),
        // TextCellValue(data.numberOfPumps.toString()),
        TextCellValue(data.twoPhasePowerOnTime),
        TextCellValue(data.overAllCumulativeFlow),
        TextCellValue(data.flowRate),
        TextCellValue(data.pressure),
        TextCellValue(data.level),
        TextCellValue(data.twoPhaseLastPowerOnTime),
        TextCellValue(data.threePhasePowerOnTime),
        TextCellValue(data.threePhaseLastPowerOnTime),
        TextCellValue(data.powerOffTime),
        TextCellValue(data.lastPowerOnTime),
        TextCellValue(data.totalPowerOnTime),
        TextCellValue(data.totalPowerOffTime),
        TextCellValue(data.motorRunTime1),
        TextCellValue(data.motorIdleTime1),
        TextCellValue(data.lastDateRunTime1),
        TextCellValue(data.lastDateRunFlow1),
        TextCellValue(data.dryRunTripTime1),
        TextCellValue(data.cyclicTripTime1),
        TextCellValue(data.otherTripTime1),
        TextCellValue(data.totalFlowToday1),
        TextCellValue(data.motorRunTime2),
        TextCellValue(data.motorIdleTime2),
        TextCellValue(data.lastDateRunTime2),
        TextCellValue(data.lastDateRunFlow2),
        TextCellValue(data.dryRunTripTime2),
        TextCellValue(data.cyclicTripTime2),
        TextCellValue(data.otherTripTime2),
        TextCellValue(data.totalFlowToday2),
        TextCellValue(data.motorRunTime3),
        TextCellValue(data.motorIdleTime3),
        TextCellValue(data.lastDateRunTime3),
        TextCellValue(data.lastDateRunFlow3),
        TextCellValue(data.dryRunTripTime3),
        TextCellValue(data.cyclicTripTime3),
        TextCellValue(data.otherTripTime3),
        TextCellValue(data.totalFlowToday3),
      ]);
    }

    // Save the file
    var fileBytes = excel.encode();
    if (fileBytes != null) {
      try {
        String downloadsDirectoryPath = "/storage/emulated/0/Download";
        String filePath = "$downloadsDirectoryPath/$name.xlsx";
        File file = File(filePath);
        await file.create(recursive: true);
        await file.writeAsBytes(fileBytes);
        // Check if file exists
        if (await file.exists()) {
          // Scaffold.of(context).showSnackBar()
          Navigator.pop(context);
          showDialog(context: context, builder: (context){
            return AlertDialog(
              title: Text('$name Download Successfully at'),
              content: Text('$filePath'),
              actions: [
                TextButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    child: const Text('Ok')
                )
              ],
            );
          });

          showSnackBar(message: "Excel file saved successfully at $filePath");

          // print("Excel file saved successfully at $filePath");
        } else {
          Navigator.pop(context);
          showDialog(context: context, builder: (context){
            return AlertDialog(
              title: Text('$name Download failed..'),
              actions: [
                TextButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    child: const Text('Ok')
                )
              ],
            );
          });
          log("Failed to save the Excel file.");
        }
      } catch (e) {
        log("Error saving the Excel file: $e");
      }
    } else {
      log("Error encoding the Excel file.");
    }
  }

  @override
  Widget build(BuildContext context) {
    pumpControllerProvider = Provider.of(context);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    return Scaffold(
      // backgroundColor: const Color(0xffF9FEFF),
      appBar: [...AppConstants.ecoGemAndPlusModelList, ...AppConstants.gemModelList].contains(widget.masterData.modelId) ? AppBar(
        title: const Text('Power graph'),
      ) : PreferredSize(preferredSize: const Size(0, 0), child: Container()),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if(selectedIndex == 0 && !kIsWeb)
              MobileCustomCalendar(
                focusedDay: pumpControllerProvider.focusedDay,
                calendarFormat: pumpControllerProvider.calendarFormat,
                selectedDate: pumpControllerProvider.selectedDate,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    pumpControllerProvider.selectedDate = selectedDay;
                    pumpControllerProvider.focusedDay = focusedDay;
                  });
                  pumpControllerProvider.getPumpControllerData(userId: widget.userId, controllerId: widget.controllerId, nodeControllerId: widget.nodeControllerId);
                },
                onFormatChanged: (format) {
                  if (pumpControllerProvider.calendarFormat != format) {
                    setState(() {
                      pumpControllerProvider.calendarFormat = format;
                    });
                  }
                },
              )
            else
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  // boxShadow: AppProperties.customBoxShadowLiteTheme
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    selectedIndex == 0
                        ? "${Constants.getWeekdayName(DateTime.now().weekday)}, ${Constants.getMonthName(DateTime.now().month)} ${DateTime.now().day}"
                        : selectedIndex == 1
                        ? "Last 7 days"
                        : "Last 30 days",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    selectedIndex == 0
                        ? "Today"
                        : "${DateFormat('MMM d yyyy').format(pumpControllerProvider.dates.first)} - ${DateFormat('MMM d yyyy').format(pumpControllerProvider.dates.last)}",
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                  tileColor: Colors.white,
                  /*trailing: IconButton(
                    onPressed: (){
                      showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now()
                      ).then((pickedDateRange) {
                        if (pickedDateRange != null) {
                          setState(() {
                            pumpControllerProvider.dates.first = pickedDateRange.start;
                            pumpControllerProvider.dates.last = pickedDateRange.end;
                            pumpControllerProvider.dates = List.generate(pickedDateRange.end.difference(pickedDateRange.start).inDays, (index) => pickedDateRange.start.add(Duration(days: index)));
                          });
                        } else {
                          if (kDebugMode) {
                            print('Date range picker was canceled');
                          }
                        }
                      }).whenComplete(() {
                        pumpControllerProvider.getPumpControllerData(userId: widget.userId, controllerId: widget.controllerId, nodeControllerId: widget.nodeControllerId);
                      });
                    },
                    icon: const Icon(Icons.calendar_month, color: Colors.white,),
                    style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Theme.of(context).primaryColor)
                    ),
                  ),*/
                ),
              ),
            CustomSegmentedControl(
                segmentTitles: const {
                  0: "Daily",
                  1: "Weekly",
                  2: "Monthly",
                },
                groupValue: selectedIndex,
                onChanged: (newValue) {
                  setState(() {
                    selectedIndex = newValue!;
                  });
                  pumpControllerProvider.getPumpControllerData(
                      userId: widget.userId,
                      controllerId: widget.controllerId,
                      nodeControllerId: widget.nodeControllerId,
                      selectedIndex: newValue!
                  );
                }
            ),
            const SizedBox(height: 10),
            buildDailyDataView(),
          ],
        ),
      ),
      floatingActionButton: MaterialButton(
          onPressed: (){
            showDialog(
                context: context,
                builder: (dialogContext){
                  var fileName = 'Power graph';
                  return AlertDialog(
                    title: const Text('File name'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          initialValue: fileName,
                          onChanged: (value){
                            fileName = value;
                          },
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                          onPressed: () async{
                            await exportMotorDataToExcel(pumpControllerProvider.motorDataList,fileName,dialogContext);
                            Navigator.pop(context);
                          },
                          child: const Text('Click to download')
                      )
                    ],
                  );
                }
            );
          },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        padding: EdgeInsets.zero,
        minWidth: 40,
        height: 40,
        color: Theme.of(context).primaryColor,
        child: const Icon(Icons.download, color: Colors.white,),
      ),
    );
  }

  Widget buildDailyDataView() {
    final selectedCondition = selectedIndex == 0;
    return Expanded(
      child: pumpControllerProvider.motorDataList.isNotEmpty ? ListView.builder(
          itemCount: selectedCondition ? pumpControllerProvider.motorDataList.length : 1,
          itemBuilder: (BuildContext context, int index) {
            print("number of pumps :: ${pumpControllerProvider.motorDataList[index].numberOfPumps}");
            if(pumpControllerProvider.motorDataList[index].numberOfPumps != 0) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        // boxShadow: AppProperties.customBoxShadowLiteTheme
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(selectedCondition)
                          buildHeader(index),
                        const SizedBox(height: 10,),
                        buildScale(scale: Constants.generateScale(selectedCondition
                            ? const Duration(hours: 24)
                            : Constants.parseTime(pumpControllerProvider.motorDataList[index].totalPowerOnTime.toString()))
                        ),
                        const SizedBox(height: 10,),
                        buildAnimatedContainer(
                            color: const Color(0xff15C0E6),
                            value: Constants.parseTime(pumpControllerProvider.motorDataList[index].totalPowerOnTime.toString()),
                            motor: "Total Power -",
                            highestValue: selectedIndex == 0 ? const Duration(hours: 24) : Constants.parseTime(pumpControllerProvider.motorDataList[index].totalPowerOnTime.toString())
                        ),
                        const SizedBox(height: 10,),
                        buildMotorStatusContainers(index: index, numberOfPumps: pumpControllerProvider.motorDataList[index].numberOfPumps),
                        const SizedBox(height: 10,),
                        // buildLegend(),
                        // const SizedBox(height: 10,),
                        // DoughnutChart(
                        //   chartData: chartData,
                        //   totalPowerDuration: Constants.parseTime(motorDataList[index].totalPowerOnTime),
                        // ),
                        buildFooter(pumpControllerProvider.motorDataList[index]),
                        // if(motorDataList[index].numberOfPumps == 1)
                        //   buildMotorDetails(motorIndex: 0, dayIndex: index)
                        // else
                        buildPageView(dayIndex: index, numberOfPumps: pumpControllerProvider.motorDataList[index].numberOfPumps)
                      ],
                    ),
                  ),
                  const SizedBox(height: 70,)
                ],
              );
            } else {
              return Container();
            }
          }
      ) : const Center(
        child: Text("Data not found"),
      ),
    );
  }

  Widget buildMotorDetails({required int motorIndex, required int dayIndex,}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildItemContainer(
          title1: 'Motor run time',
          title2: "Motor idle time",
          value1: [
            pumpControllerProvider.motorDataList[dayIndex].motorRunTime1,
            pumpControllerProvider.motorDataList[dayIndex].motorRunTime2,
            pumpControllerProvider.motorDataList[dayIndex].motorRunTime3][motorIndex],
          value2: [
            pumpControllerProvider.motorDataList[dayIndex].motorIdleTime1,
            pumpControllerProvider.motorDataList[dayIndex].motorIdleTime2,
            pumpControllerProvider.motorDataList[dayIndex].motorIdleTime3][motorIndex],
        ),
        buildItemContainer(
          title1: 'Dry run trip time',
          title2: 'Cyclic trip time',
          value1: [
            pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime1,
            pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime2,
            pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime3][motorIndex],
          value2: [
            pumpControllerProvider.motorDataList[dayIndex].cyclicTripTime1,
            pumpControllerProvider.motorDataList[dayIndex].cyclicTripTime2,
            pumpControllerProvider.motorDataList[dayIndex].cyclicTripTime3][motorIndex],
        ),
        buildItemContainer(
          title1: 'Other trip time',
          title2: 'Total flow today',
          value1: [
            pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime1,
            pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime2,
            pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime3][motorIndex],
          value2: "${[
            pumpControllerProvider.motorDataList[dayIndex].totalFlowToday1,
            pumpControllerProvider.motorDataList[dayIndex].totalFlowToday2,
            pumpControllerProvider.motorDataList[dayIndex].totalFlowToday3][motorIndex]} Litres",
        ),
      ],
    );
  }

  Widget buildItemContainer2({
    required String title1,
    required String title2,
    required int index,
    required int numberOfPumps,
    List<String>? value1,
    List<String>? value2,
    required String unit1,
    required String unit2
  }) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
          // border: Border(
          //   top: BorderSide(color: Theme.of(context).primaryColor, width: 0.5),
          // )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: Text(title1, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.start)),
              for(var i = 0; i < numberOfPumps; i++)
                Expanded(flex: 2, child: Text(value1![i], style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              if(numberOfPumps != 3)
                Expanded(flex: 2, child: Text(unit1, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center))
            ],
          ),
          const SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: Text(title2, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.start)),
              for(var i = 0; i < numberOfPumps; i++)
                Expanded(flex: 2, child: Text(value2![i], style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              if(numberOfPumps != 3)
                Expanded(flex: 2, child: Text(unit2, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center))
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPageView({required int dayIndex, required int numberOfPumps}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: double.maxFinite,
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: Container()),
                        for(var i = 0; i < numberOfPumps; i++)
                          Expanded(flex: 2, child: Text("Motor ${i+1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        if(numberOfPumps != 3)
                          const Expanded(flex: 2, child: Text("Unit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ],
                    ),
                  )
              ),
              buildItemContainer2(
                  title1: 'Motor run time',
                  title2: "Motor idle time",
                  index: dayIndex,
                  numberOfPumps: numberOfPumps,
                  value1: [Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].motorRunTime1), Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].motorRunTime2), Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].motorRunTime3)],
                  value2: [Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].motorIdleTime1), Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].motorIdleTime2), Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].motorIdleTime3)],
                  unit1: "HH:MM",
                  unit2: "HH:MM"
              ),
              buildItemContainer2(
                  title1: 'Dry run trip time',
                  title2: 'Cyclic trip time',
                  index: dayIndex,
                  numberOfPumps: numberOfPumps,
                  value1: [Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime1), Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime2), Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime3)],
                  value2: [Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].cyclicTripTime1), Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].cyclicTripTime2), Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].cyclicTripTime3)],
                  unit1: "HH:MM",
                  unit2: "HH:MM"
              ),
              buildItemContainer2(
                  title1: 'Other trip time',
                  title2: 'Total flow today',
                  index: dayIndex,
                  numberOfPumps: numberOfPumps,
                  value1: [Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime1), Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime2), Constants.changeFormat(pumpControllerProvider.motorDataList[dayIndex].dryRunTripTime3)],
                  value2: [pumpControllerProvider.motorDataList[dayIndex].totalFlowToday1, pumpControllerProvider.motorDataList[dayIndex].totalFlowToday2, pumpControllerProvider.motorDataList[dayIndex].totalFlowToday3],
                  unit1: "HH:MM",
                  unit2: "Litres"
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget buildHeader(int index) {
    return Card(
        surfaceTintColor: const Color(0xffb6f6e5),
        color: const Color(0xffb4e3ed),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0)
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Text(
                DateFormat('MMM d yyyy').format(pumpControllerProvider.motorDataList[index].date != "" ? DateTime.parse(pumpControllerProvider.motorDataList[index].date) : DateTime.now()),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              )
          ),
        )
    );
  }

  Widget buildMotorStatusContainers({required int index, required int numberOfPumps}) {
    List<Widget> containers = [];
    for (var i = 0; i < numberOfPumps; i++) {
      // print(motorDataList[index].totalPowerOnTime);
      containers.add(
          Column(
            children: [
              buildAnimatedContainer(
                  color: [Colors.lightBlueAccent.shade100.withOpacity(0.6), Colors.lightGreenAccent.withOpacity(0.6), Colors.greenAccent.withOpacity(0.6)][i],
                  value: [Constants.parseTime(pumpControllerProvider.motorDataList[index].motorRunTime1), Constants.parseTime(pumpControllerProvider.motorDataList[index].motorRunTime2), Constants.parseTime(pumpControllerProvider.motorDataList[index].motorRunTime3)][i],
                  motor: "Motor ${i + 1} consumed",
                  highestValue: selectedIndex == 0 ? const Duration(hours: 24): Constants.parseTime(pumpControllerProvider.motorDataList[index].totalPowerOnTime)
              ),
              const SizedBox(height: 10,)
            ],
          )
      );
    }
    return Column(children: containers);
  }

  Widget buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            buildLegendItem(color: const Color(0xff15C0E6), label: "Power Status"),
            const SizedBox(width: 30,),
            buildLegendItem(color: const Color(0xff10E196), label: "Motor Status"),
          ],
        )
      ],
    );
  }

  Widget buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color)),
        const SizedBox(width: 10,),
        Text(label, style: const TextStyle(color: Color(0xff9291A5), fontSize: 14))
      ],
    );
  }

  Widget buildFooter(MotorDataHourly motorDataHourly) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildFooterItem("Cumulative flow", "Litres", motorDataHourly.overAllCumulativeFlow, "Pressure", motorDataHourly.pressure != "-" ? motorDataHourly.pressure : "", motorDataHourly.pressure != "-" ? "bar" : ""),
            const SizedBox(height: 7,),
            buildFooterItem("Flow rate", "Lps", motorDataHourly.flowRate, "Level", motorDataHourly.level != "-" ? motorDataHourly.level : "", motorDataHourly.level != "-" ? "feet" : ""),
            const SizedBox(height: 7,),
            buildFooterItem("Total power on time", "(HH:MM)", Constants.changeFormat(motorDataHourly.totalPowerOnTime), "Total power off time", Constants.changeFormat(motorDataHourly.totalPowerOffTime), "(HH:MM)"),
            if(motorDataHourly.totalInstantEnergy != null && selectedIndex == 0)
              const SizedBox(height: 7,),
            if(motorDataHourly.totalInstantEnergy != null && selectedIndex == 0)
              buildFooterItem("Instant energy", "kW", motorDataHourly.totalInstantEnergy ?? '', "Cumulative energy", motorDataHourly.cumulativeEnergy ?? '', "kW")
          ],
        )
    );
  }

  Widget buildFooterItem(String label1, String unit1, String value1, String label2, String value2, String unit2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Column(
            children: [
              Text(label1, style: const TextStyle(color: Color(0xff9291A5), fontSize: 14)),
              Text("$value1 $unit1", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(width: 10,),
        Expanded(
          child: Column(
            children: [
              Text(label2, style: const TextStyle(color: Color(0xff9291A5), fontSize: 14)),
              Text("$value2 $unit2", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
            ],
          ),
        )
      ],
    );
  }

  Widget buildItemContainer({
    required String title1,
    required String title2,
    required String value1,
    required String value2
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          buildItemRow(
              title1: title1,
              title2: title2,
              value1: value1,
              value2: value2
          )
        ],
      ),
    );
  }

  Widget buildItemRow({required String title1, required String title2, required String value1, required String value2}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildItem(title: title1, value: value1, color: Theme.of(context).primaryColor),
          buildItem(title: title2, value: value2, color: Colors.red)
        ],
      ),
    );
  }

  Widget buildItem({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Color(0xff9291A5), fontSize: 14)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}