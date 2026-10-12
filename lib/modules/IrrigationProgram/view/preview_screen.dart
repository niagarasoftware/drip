import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../Constants/constants.dart';
import '../model/sequence_model.dart';
import '../../config_maker/model/device_object_model.dart';
import '../repository/irrigation_program_repo.dart';
import '../state_management/irrigation_program_provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../widgets/custom_alert_dialog.dart';
import '../widgets/custom_data_table.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import '../../../services/http_service.dart';
import '../../../utils/network_utils.dart';
import '../widgets/custom_sliding_button.dart';
import '../widgets/progress_dialog_ecogem.dart';
import 'program_library.dart';


final dateFormat = DateFormat('dd-MM-yyyy');

class PreviewScreen extends StatefulWidget {
  final int userId;
  final int customerId;
  final int controllerId;
  final int groupId;
  final int categoryId;
  final String deviceId;
  final int serialNumber;
  final bool toDashboard;
  final String? programType;
  final bool fromDealer;
  final int modelId;
  final String deviceName;
  final String categoryName;
  const PreviewScreen({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.deviceId,
    required this.serialNumber,
    required this.toDashboard,
    this.programType,
    required this.fromDealer,
    required this.customerId,
    required this.groupId,
    required this.categoryId,
    required this.modelId,
    required this.deviceName,
    required this.categoryName,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late IrrigationProgramMainProvider irrigationProvider;
  late MqttPayloadProvider mqttPayloadProvider;
  List<ChartData>? _chartDataList;
  List<ChartData>? get chartDataList => _chartDataList;
  final PageController pageController = PageController();

  @override
  void initState() {
    irrigationProvider =  Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    mqttPayloadProvider =  Provider.of<MqttPayloadProvider>(context, listen: false);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        irrigationProvider.waterAndFert(widget.modelId);
        _chartDataList = List<ChartData>.from(irrigationProvider.sequenceData.map((json) => ChartData.fromJson(json, irrigationProvider.constantSetting, json['valve'])));
        // irrigationProvider.sequenceData.forEach((element) {
        //   print(element['localDosing']);
        //   // print(element['localDosing'][0]['fertilizer']);
        // });

        // print(irrigationProvider.sequenceData[0]['localDosing'][0]['fertilizer'].where((e) => e['onOff'] == true).toList());
      });
    }
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    irrigationProvider =  Provider.of<IrrigationProgramMainProvider>(context, listen: true);
    final scheduleTypeCondition = irrigationProvider.sampleScheduleModel!.selected == irrigationProvider.scheduleTypes[1]
        ? irrigationProvider.sampleScheduleModel!.scheduleAsRunList
        : irrigationProvider.sampleScheduleModel!.scheduleByDays;
    final noScheduleCondition = irrigationProvider.selectedScheduleType != irrigationProvider.scheduleTypes[0] && irrigationProvider.selectedScheduleType != irrigationProvider.scheduleTypes[3];
    final rtcList = irrigationProvider.sampleScheduleModel!.selected == irrigationProvider.scheduleTypes[1]
        ? irrigationProvider.sampleScheduleModel!.scheduleAsRunList.rtc
        : irrigationProvider.sampleScheduleModel!.scheduleByDays.rtc;
    final scheduleAsRunListCondition = irrigationProvider.sampleScheduleModel!.selected == irrigationProvider.scheduleTypes[1];
    final scheduleByDaysCondition = irrigationProvider.sampleScheduleModel!.selected == irrigationProvider.scheduleTypes[2];
    final fertilizerCondition = (irrigationProvider.sequenceData.any((element) => element['applyFertilizerForCentral'] == true))
        || (irrigationProvider.sequenceData.any((element) => element['applyFertilizerForLocal'] == true));
    final applyCentralFert = irrigationProvider.sequenceData.any((element) => element['applyFertilizerForCentral'] == true);
    final applyLocalFert = irrigationProvider.sequenceData.any((element) => element['applyFertilizerForLocal'] == true);
    final allowStopMethodCondition = irrigationProvider.sampleScheduleModel!.defaultModel.allowStopMethod;
    final defaultOffTime = irrigationProvider.sampleScheduleModel!.defaultModel.rtcOffTime;
    final centralFertilizerSite = irrigationProvider.fertilizerSite!.where((site) {
      for (var i = 0; i < irrigationProvider.selectedObjects!.length; i++) {
        if (site.siteMode == 1 && irrigationProvider.selectedObjects![i].objectId == 3 && irrigationProvider.selectedObjects![i].sNo == site.fertilizerSite?.sNo) {
          return true;
        }
      }
      return false;
    });
    final localFilterSite = irrigationProvider.filterSite!.where((site) {
      for (var i = 0; i < irrigationProvider.selectedObjects!.length; i++) {
        if (site.siteMode == 2 && irrigationProvider.selectedObjects![i].objectId == 4 && irrigationProvider.selectedObjects![i].sNo == site.filterSite?.sNo) {
          return true;
        }
      }
      return false;
    });
    final localFilterCondition = localFilterSite.isNotEmpty;
    final filterCategoryCondition = irrigationProvider.selectedObjects!.any((e) => e.objectId == 4);
    final fertilizerCategoryCondition = irrigationProvider.selectedObjects!.any((e) => e.objectId == 3);
    final defaultMaxTime = irrigationProvider.sampleScheduleModel!.defaultModel.rtcMaxTime;
    // final List<ChartData> chartData2 = <ChartData>[
    //   ChartData(irrigationProvider.sequenceData, valves, preValue, postValue, waterValue)
    // ];
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Container(
            margin: MediaQuery.of(context).size.width > 1200 ? const EdgeInsets.all(10) : null,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10,),
                  MediaQuery.of(context).size.width > 1200
                      ? SizedBox(
                    height: irrigationProvider.sampleScheduleModel!.selected != irrigationProvider.scheduleTypes[3] ? 300 : 320,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 20, right: 20),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                boxShadow: customBoxShadow
                            ),
                            child: buildGraph(),
                          ),
                        ),
                        const SizedBox(width: 10,),
                        if(!noScheduleCondition)
                          Expanded(child: buildNoSchedule()),
                        if(noScheduleCondition)
                          Expanded(
                              child: buildRtcDetails(rtcList: rtcList, constraints: constraints, allowStopMethodCondition: allowStopMethodCondition, defaultOffTime: defaultOffTime, defaultMaxTime: defaultMaxTime)
                          ),
                      ],
                    ),
                  )
                      : Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.yellow.shade100
                        ),
                        child: RichText(
                          text: const TextSpan(
                            children: [
                              // WidgetSpan(
                              //   child: Icon(Icons.info, size: 18, color: Colors.orange,),
                              //   alignment: PlaceholderAlignment.middle,
                              // ),
                              TextSpan(
                                text: 'Note: ',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: ' Detailed scheduled program can be viewed in the dashboard by clicking ',
                                style: TextStyle(color: Colors.black, fontSize: 14),
                              ),
                              WidgetSpan(
                                child: Icon(Icons.calendar_month, size: 18),
                                alignment: PlaceholderAlignment.middle,
                              ),
                              TextSpan(
                                text: ' icon with "Schedule" title in the bottom navigation.',
                                style: TextStyle(color: Colors.black, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        height: 300,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            boxShadow: customBoxShadow
                        ),
                        child: buildGraph(),
                      ),
                      const SizedBox(width: 10,),
                      if(!noScheduleCondition)
                        buildNoSchedule(),
                      if(noScheduleCondition)
                        buildRtcDetails(rtcList: rtcList, constraints: constraints, allowStopMethodCondition: allowStopMethodCondition, defaultOffTime: defaultOffTime, defaultMaxTime: defaultMaxTime),
                    ],
                  ),
                  if(MediaQuery.of(context).size.width < 1200)
                    const SizedBox(height: 20,),
                  if(noScheduleCondition)
                    Container(
                      margin: MediaQuery.of(context).size.width > 1200
                          ? const EdgeInsets.only(top: 10, left: 10, right: 10)
                          : const EdgeInsets.symmetric(horizontal: 10),
                      // height: MediaQuery.of(context).size.width > 1200 ? 220 : 485,
                      child: MediaQuery.of(context).size.width > 1200 ?
                      Row(
                        children: [
                          if(noScheduleCondition)
                            Expanded(
                                child: buildGeneralDetails()
                            ),
                          const SizedBox(width: 10,),
                          if(irrigationProvider.sampleScheduleModel!.selected != irrigationProvider.scheduleTypes[0])
                            Expanded(
                                child: buildScheduleDetails(scheduleTypeCondition: scheduleTypeCondition)
                            ),
                        ],
                      ) :
                      Column(
                        children: [
                          if(noScheduleCondition)
                            buildGeneralDetails(),
                          const SizedBox(height: 10,),
                          if(irrigationProvider.sampleScheduleModel!.selected != irrigationProvider.scheduleTypes[0])
                            buildScheduleDetails(scheduleTypeCondition: scheduleTypeCondition),
                        ],
                      ),
                    ),
                  if((filterCategoryCondition || fertilizerCategoryCondition) && MediaQuery.of(context).size.width > 1200)
                    Container(
                      margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                      // height: (centralSelectorCondition || localFilterCondition) ? 220 : 120,
                      child: Row(
                        children: [
                          Expanded(
                              child: (filterCategoryCondition)
                                  ? buildFilterDetails(localFilterCondition: localFilterCondition) : Container()
                          ),
                          const SizedBox(width: 10,),
                          Expanded(
                              child: (fertilizerCategoryCondition && fertilizerCondition)
                                  ? buildFertilizerDetails(centralSelectorCondition: centralFertilizerSite.isNotEmpty) : Container()
                          ),
                        ],
                      ),
                    ),
                  if((filterCategoryCondition || fertilizerCategoryCondition) && MediaQuery.of(context).size.width < 1200)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      // height: ((centralSelectorCondition || localFilterCondition) && (fertilizerCategoryCondition && fertilizerCondition)) ? 360 : 235,
                      child: Column(
                        children: [
                          (filterCategoryCondition)
                              ? buildFilterDetails(localFilterCondition: localFilterCondition) : Container(),
                          const SizedBox(height: 10,),
                          (fertilizerCategoryCondition && fertilizerCondition)
                              ? buildFertilizerDetails(centralSelectorCondition: centralFertilizerSite.isNotEmpty) : Container(),
                        ],
                      ),
                    ),
                  if(irrigationProvider.sampleConditions?.defaultData.conditionLibrary.isNotEmpty ?? false)
                    Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: buildConditionDetails()
                    ),
                  const SizedBox(height: 10,),
                  Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: buildAlarmDetails()
                  ),
                  const SizedBox(height: 20,),
                  Container(
                    margin: MediaQuery.of(context).size.width > 1200 ? const EdgeInsets.all(20) : const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: customBoxShadow
                    ),
                    child: CustomDataTable(
                      rowsPerPage: fertilizerCondition
                          ? irrigationProvider.sequenceData.length >= 4
                          ? 4 : irrigationProvider.sequenceData.length
                          : MediaQuery.of(context).size.width > 1200 ? irrigationProvider.sequenceData.length >= 10 ? 10 : irrigationProvider.sequenceData.length : irrigationProvider.sequenceData.length >= 4
                          ? 4 : irrigationProvider.sequenceData.length,
                      headerText: 'Irrigation Details',
                      icon: Icons.water,
                      columnSpacing: MediaQuery.of(context).size.width > 800
                          ? constraints.maxWidth * (fertilizerCondition ? 0.09 : 0.16)
                          : constraints.maxWidth * (fertilizerCondition ? 0.05 : 0.1),
                      columns: [
                        buildDataColumn(label: "S.No", widthRatio: fertilizerCondition ? constraints.maxWidth * 0.03: null),
                        buildDataColumn(label: "Sequence", widthRatio: fertilizerCondition ? constraints.maxWidth * 0.1 : null),
                        buildDataColumn(label: "Valves", widthRatio: fertilizerCondition ? constraints.maxWidth * 0.1 : constraints.maxWidth * 0.15,),
                        buildDataColumn(label: "Dur/Qty", widthRatio: fertilizerCondition ? constraints.maxWidth * 0.05 : null),
                        if(fertilizerCondition)
                          buildDataColumn(label: "Before fert", widthRatio: fertilizerCondition ? constraints.maxWidth * 0.05 : null),
                        if(fertilizerCondition)
                          buildDataColumn(label: "After fert", widthRatio: constraints.maxWidth * 0.05),
                        buildDataColumn(label: "Condition", widthRatio: fertilizerCondition ? constraints.maxWidth * 0.1 : constraints.maxWidth * 0.17),
                      ],
                      dataList: irrigationProvider.sequenceData,
                      cellBuilders: [
                            (data, index) => buildDataCell(dataItem: data['sNo'].toString(), widthRatio: constraints.maxWidth * 0.03),
                            (data, index) => buildDataCell(dataItem: '${data['seqName']}', widthRatio: constraints.maxWidth * 0.1,),
                            (data, index) => buildDataCell(dataItem: '${data['valve'].map((e) => e['name']).toList().join(', ')}', widthRatio: constraints.maxWidth * 0.1, showToolTip: true, isFixedSize: true),
                            (data, index) => buildDataCell(dataItem: data['method'] == "Time" ? Constants.showHourAndMinuteOnly(data['timeValue'], widget.modelId) : data['quantityValue'], widthRatio: constraints.maxWidth * 0.05),
                        if(fertilizerCondition)
                              (data, index) => buildDataCell(dataItem: data['method'] == "Time" ? Constants.showHourAndMinuteOnly(data['preValue'], widget.modelId) : data['preValue'], widthRatio: constraints.maxWidth * 0.05),
                        if(fertilizerCondition)
                              (data, index) => buildDataCell(dataItem: data['method'] == "Time" ? Constants.showHourAndMinuteOnly(data['postValue'], widget.modelId) : data['postValue'], widthRatio: constraints.maxWidth * 0.05),
                            (data, index) => buildDataCell(dataItem: data['levelCondition'], widthRatio: constraints.maxWidth * 0.1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20,),
                  if(fertilizerCondition)
                    Container(
                      margin: MediaQuery.of(context).size.width > 1200 ? const EdgeInsets.all(20) : const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          boxShadow: customBoxShadow
                      ),
                      child: CustomDataTable(
                        rowsPerPage: irrigationProvider.sequenceData.length >= 4 ? 4 : irrigationProvider.sequenceData.length,
                        headerText: 'Fertigation Details',
                        icon: Icons.local_florist_outlined,
                        columnSpacing: MediaQuery.of(context).size.width > 800
                            ? constraints.maxWidth * ((applyLocalFert && applyCentralFert) ? 0.1 : 0.03)
                            : constraints.maxWidth * ((applyLocalFert && applyCentralFert) ? 0.05 : 0.05),
                        columns: [
                          buildDataColumn(label: "S.No",),
                          buildDataColumn(label: "Sequence",),
                          // buildDataColumn(label: "Valves", widthRatio: constraints.maxWidth * 0.1335),
                          if(applyCentralFert)
                            buildDataColumn(label: "Cen. fert. site"),
                          if(applyCentralFert)
                            buildDataColumn(label: "Cen. fert. Inj."),
                          if(applyCentralFert)
                            buildDataColumn(label: "Cen. fert. Dur/Qty."),
                          if(applyLocalFert)
                            buildDataColumn(label: "Loc. site"),
                          if(applyLocalFert)
                            buildDataColumn(label: "Loc. fert. Inj."),
                          if(applyLocalFert)
                            buildDataColumn(label: "Loc. fert. Dur/Qty."),
                          // buildDataColumn(label: "Recipe", widthRatio: constraints.maxWidth * 0.1),
                        ],
                        dataList: irrigationProvider.sequenceData,
                        cellBuilders: [
                              (data, index) => buildDataCell(dataItem: data['sNo'].toString(), widthRatio: 50),
                              (data, index) => buildDataCell(dataItem: '${data['seqName']}', widthRatio: fertilizerCondition ? constraints.maxWidth > 800 ?  180 : 100 : 300),
                          // (data) => buildDataCell(dataItem: '${data['valve'].map((e) => e['name']).toList().join(', ')}', widthRatio: constraints.maxWidth * 0.1335,),
                          if(applyCentralFert)
                                (data, index) => buildDataCell(
                                dataItem: data['centralDosing'].isEmpty ? 'Not Available' : "${data['centralDosing'][0]['name']}",
                                widthRatio: (MediaQuery.of(context).size.width > 800)
                                    ? (applyCentralFert && applyLocalFert) ? 150 : 290
                                    : MediaQuery.of(context).size.width < 800 ? 150 : 100,
                                isFixedSize: true,
                                showToolTip: true),
                          if(applyCentralFert)
                                (data, index) => buildDataCell(
                                dataItem: data['centralDosing'].isEmpty ? 'Not Available' : getItem(data['centralDosing'][0]['fertilizer'], 'name'),
                                color: Colors.black,
                                widthRatio: (MediaQuery.of(context).size.width > 800)
                                    ? (applyCentralFert && applyLocalFert) ? 150 : 290
                                    : MediaQuery.of(context).size.width < 800 ? 150 : 100,
                                isFixedSize: true,
                                showToolTip: true),
                          if(applyCentralFert)
                                (data, index) => buildDataCell(
                                dataItem: data['centralDosing'].isEmpty ? 'Not Available' : getItem(data['centralDosing'][0]['fertilizer'], 'method', check: true),
                                color: Colors.black,
                                widthRatio: (MediaQuery.of(context).size.width > 800)
                                    ? (applyCentralFert && applyLocalFert) ? 150 : 290
                                    : MediaQuery.of(context).size.width < 800 ? 150 : 100,
                                isFixedSize: true,
                                showToolTip: true),
                          if(applyLocalFert)
                                (data, index) => buildDataCell(
                                dataItem: data['localDosing'].isEmpty ? 'Not Available' : "${data['localDosing'].map((e) => e['name']).toList().join(', ')}",
                                widthRatio: (MediaQuery.of(context).size.width > 800)
                                    ? (applyCentralFert && applyLocalFert) ? 150 : 290
                                    : MediaQuery.of(context).size.width < 800 ? 150 : 100,
                                isFixedSize: true,
                                showToolTip: true),
                          if(applyLocalFert)
                                (data, index) => buildDataCell(
                                dataItem: data['localDosing'].isEmpty ? 'Not Available' : getItem(data['localDosing'][0]['fertilizer'], 'name'),
                                color: Colors.black,
                                widthRatio: (MediaQuery.of(context).size.width > 800)
                                    ? (applyCentralFert && applyLocalFert) ? 150 : 290
                                    : MediaQuery.of(context).size.width < 800 ? 150 : 100,
                                isFixedSize: true,
                                showToolTip: true),
                          if(applyLocalFert)
                                (data, index) => buildDataCell(
                                dataItem: data['localDosing'].isEmpty ? 'Not Available' : getItem(data['localDosing'][0]['fertilizer'], 'method', check: true),
                                color: Colors.black,
                                widthRatio: (MediaQuery.of(context).size.width > 800)
                                    ? (applyCentralFert && applyLocalFert) ? 150 : 290
                                    : MediaQuery.of(context).size.width < 800 ? 150 : 100,
                                isFixedSize: true,
                                showToolTip: true),
                          // (data) => buildDataCell(dataItem: data['levelCondition'], widthRatio: constraints.maxWidth * 0.1),
                        ],
                      ),
                    ),
                  if(fertilizerCondition)
                    const SizedBox(height: 20,),

                  SlidingSendButton(
                    onSend: (){
                      // print(irrigationProvider.dataToMqtt(widget.serialNumber == 0 ? irrigationProvider.serialNumberCreation : widget.serialNumber, widget.programType));
                      irrigationProvider.programLibraryData(widget.customerId, widget.controllerId);
                      sendFunction();
                    },
                  ),
                  const SizedBox(height: 80,)
                ],
              ),
            ),
          );
        }
    );
  }

  void sendFunction() async{
    bool isOnline = await NetworkUtils.checkNow();
    if (!isOnline) {
      if (mounted) {
        showAdaptiveDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: 'No Internet Connection',
              content: 'Internet connection is unavailable. Please check your network connection and try again.',
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    // print("widget.modelId :::::: ${widget.modelId}");
    final mainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    Map<String, dynamic> dataToMqtt = mainProvider.dataToMqtt(widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber, widget.programType);
    Map<String, dynamic> dataToMqttEcoGem = {};
    dynamic ecoGemWFPayload;
    List<String> ecoGemWFPayloadList = [];
    if(AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)){
      dataToMqttEcoGem = mainProvider.dataToMqttForEcoGem(widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber, widget.programType);
      ecoGemWFPayload = mainProvider.ecoGemPayloadForWF(widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber);
      ecoGemWFPayloadList.add(jsonEncode(dataToMqttEcoGem));
      for(int i = 0; i < ecoGemWFPayload.length; i++) {
        final payload = {
          "260${i + 1}": {
            "2501": ecoGemWFPayload[i]
          }
        };
        ecoGemWFPayloadList.add(jsonEncode(payload));
      }
    }

    Map<String, dynamic> userData = {
      "defaultProgramName": mainProvider.defaultProgramName,
      "userId": widget.customerId,
      "controllerId": widget.controllerId,
      "createUser": widget.userId,
      "serialNumber": widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber,
    };
    if(mainProvider.irrigationLine!.sequence.isNotEmpty) {
      var dataToSend = {
        "sequence": mainProvider.irrigationLine!.sequence,
        "schedule": mainProvider.sampleScheduleModel!.toJson(),
        "conditions": mainProvider.sampleConditions != null
            ? mainProvider.sampleConditions!.toJson()
            : [],
        "waterAndFert": mainProvider.sequenceData,
        "selection": {
          ...mainProvider.additionalData!.toJson(),
          "selected": mainProvider.selectedObjects!.map((e) => e.toJson()).toList(),
        },
        "alarm": mainProvider.newAlarmList!.toJson(),
        "programName": mainProvider.programName,
        "priority": mainProvider.priority,
        "delayBetweenZones": mainProvider.programDetails!.delayBetweenZones,
        "adjustPercentage": mainProvider.programDetails!.adjustPercentage,
        "cyclicOnTime": mainProvider.programDetails!.cyclicOnTime,
        "cyclicOffTime": mainProvider.programDetails!.cyclicOffTime,
        "isPressureEnabled": mainProvider.programDetails!.enablePressure ? '1' : '0',
        "pressure": mainProvider.programDetails!.pressureValue,
        "flowScanTime": mainProvider.programDetails!.flowScanTime,
        "incompleteRestart": mainProvider.isCompletionEnabled ? "1" : "0",
        "controllerReadStatus": '0',
        "programType": mainProvider.selectedProgramType,
        "hardware": AppConstants.ecoGemAndPlusModelList.contains(widget.modelId) ? ecoGemWFPayloadList : dataToMqtt
      };
      userData.addAll(dataToSend);
      try {
        if(AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) {
          final result = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return EcoGemProgressDialog(
                payloads: ecoGemWFPayloadList,
                deviceId: widget.deviceId,
                mqttService: MqttService(),
              );
            },
          );

          if (result != null) {
            setState(() {
              userData['controllerReadStatus'] = result;
            });
          }
        } else {
          await validatePayloadSent(
              dialogContext: context,
              context: context,
              mqttPayloadProvider: mqttPayloadProvider,
              acknowledgedFunction: () {
                setState(() {
                  userData['controllerReadStatus'] = "1";
                });
              },
              payload: dataToMqtt,
              payloadCode: "2500",
              deviceId: widget.deviceId
          );
        }
      } catch(error) {
        if (mounted) {
          showAdaptiveDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: 'Error',
                content: 'Failed to update program settings. Please try again.',
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        }
      }

      Future.delayed(const Duration(milliseconds: 300), () async {
        try {
          final IrrigationProgramRepository repository = IrrigationProgramRepository(HttpService());
          final createUserProgram = await repository.createUserProgram(userData);
          final response = jsonDecode(createUserProgram.body);
          if (createUserProgram.statusCode == 200) {
            await irrigationProvider.programLibraryData(widget.customerId, widget.controllerId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: response['message']));
              Navigator.of(context).pop();
            }
          } else {
            if (mounted) {
              showAdaptiveDialog(
                context: context,
                builder: (BuildContext context) {
                  return CustomAlertDialog(
                    title: 'Error',
                    content: response['message'] ?? 'Failed to update program',
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                },
              );
            }
          }
        } catch (e) {
          if (mounted) {
            showAdaptiveDialog(
              context: context,
              builder: (BuildContext context) {
                return CustomAlertDialog(
                  title: 'Network Error',
                  content: 'Unable to connect to server. Please check your network connection and try again.',
                  actions: [
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            );
          }
        }
      });
    }
    else {
      showAdaptiveDialog<Future>(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: 'Warning',
            content: "Select valves to be sequence for Irrigation Program",
            actions: [
              TextButton(child: const Text("OK"), onPressed: () => Navigator.of(context).pop(),),
            ],
          );
        },
      );
    }
  }

  Widget buildAlarmDetails(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text("Alarm details", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),),
        ),
        Wrap(
          children: [
            buildItemsCard(
                context: context,
                title: "Enabled alarms",
                child: buildIndividualRow(irrigationProvider.newAlarmList!.alarmList)
            ),
          ],
        ),
      ],
    );
  }

  String getItem(List data, String item, {bool check = false}) {
    List resultList = [];
    var result = '';
    // data['localDosing'].isEmpty ? '' : (data['localDosing'][0]['fertilizer'].map((fertilizer) => fertilizer['onOff'] == true ? fertilizer['name'] : '').where((e) => e != '').toList().join(', '))
    for (var element in data) {
      if(element['onOff'] == true) {
        resultList.add(
            check
                ? ((element[item] == "Time" || element[item] == "Pro.time") ? Constants.showHourAndMinuteOnly(element['timeValue'], widget.modelId)
                : element['quantityValue']) : element[item]
        );
        result = resultList.join(', ');
        // print("result ==> $result");
      }
    }
    return result == "" ? "Not selected" : result;
  }

  Widget buildGraph() {
    // print(chartDataList.map((e) => e.))
    double getMaxFlowRate(List<ChartData> dataList) {
      if(dataList.isNotEmpty) {
        return dataList.map((data) => data.flowRate).reduce((a, b) => a > b ? a : b);
      } else {
        return 0.0;
      }
    }

    bool isSingleMethod = chartDataList != null &&
        chartDataList!.isNotEmpty &&
        chartDataList!.every((e) => e.method == chartDataList!.first.method);

    double maxFlowRate = getMaxFlowRate(chartDataList ?? []);
    return chartDataList != null ?
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Irrigation & fert", style: TextStyle(color: Color(0xff9291A5), fontSize: 16)),
            ),
            Row(
              children: [
                Row(children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xff15C0E6))),
                  const SizedBox(width: 10,),
                  const Text("Water only", style: TextStyle(color: Color(0xff9291A5), fontSize: 14))
                ],),
                const SizedBox(width: 30,),
                Row(children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xff10E196))),
                  const SizedBox(width: 10,),
                  const Text("Water & Fert", style: TextStyle(color: Color(0xff9291A5), fontSize: 14))
                ],)
              ],
            )
          ],
        ),
        const Divider(color: Color(0xffE5E5EF), indent: 10, endIndent: 10,),
        Expanded(
          child: SfCartesianChart(
            enableAxisAnimation: true,
            plotAreaBackgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
            borderWidth: 0,
            plotAreaBorderWidth: 0,
            enableSideBySideSeriesPlacement: false,
            onTooltipRender: (TooltipArgs args) {
              String sequence = args.pointIndex != null && args.pointIndex! < chartDataList!.length
                  ? chartDataList![args.pointIndex!.toInt()].valves
                  : '';
              double? preValue = args.pointIndex != null && args.pointIndex! < chartDataList!.length
                  ? (chartDataList![args.pointIndex!.toInt()].preValueHigh.toDouble() - chartDataList![args.pointIndex!.toInt()].preValueLow.toDouble())
                  : null;
              double? postValue = args.pointIndex != null && args.pointIndex! < chartDataList!.length
                  ? (chartDataList![args.pointIndex!.toInt()].postValueHigh.toDouble() - chartDataList![args.pointIndex!.toInt()].postValueLow.toDouble())
                  : null;
              double? waterValue = args.pointIndex != null && args.pointIndex! < chartDataList!.length
                  ? (chartDataList![args.pointIndex!.toInt()].waterValueHigh.toDouble() - chartDataList![args.pointIndex!.toInt()].waterValueLow.toDouble())
                  : null;
              args.text = 'Sequence: $sequence, \nPre value: $preValue, \nPost value: $postValue, \nWater value: $waterValue';
            },
            tooltipBehavior: TooltipBehavior(
              enable: true,
              animationDuration: 300,
              canShowMarker: true,
              textStyle: const TextStyle(color: Colors.white),
              tooltipPosition: TooltipPosition.pointer,
              borderWidth: 2,
              color: Colors.black,
            ),
            primaryXAxis: CategoryAxis(
              isVisible: true,
              rangePadding: ChartRangePadding.round,
              labelPlacement: LabelPlacement.onTicks,
              minimum: -0.5,
             maximum: chartDataList!.length.toDouble() - 0.5,
              initialVisibleMinimum: -0.5,
              initialVisibleMaximum: chartDataList!.length < 6 ? chartDataList!.length.toDouble() - 0.5 : 6,
            ),
            primaryYAxis: NumericAxis(
              isVisible: true,
              minimum: 0,
              labelFormat: '{value}',
              axisLabelFormatter: (AxisLabelRenderDetails details) {
                if (isSingleMethod && chartDataList!.first.method == 1) {
                  num quantity = details.value;
                  if (quantity == 0) {
                    return ChartAxisLabel('0m', const TextStyle(color: Colors.black));
                  }

                  double timeInSeconds = quantity / maxFlowRate;
                  double timeInMinutes = quantity / 60;
                  // print("timeInSeconds ==> $timeInSeconds");
                  // print("timeInMinutes ==> $timeInMinutes");
                  return ChartAxisLabel('${timeInMinutes.toStringAsFixed(1)}m', const TextStyle(color: Colors.black));
                } else if (isSingleMethod) {
                  return ChartAxisLabel('${details.value}L', const TextStyle(color: Colors.black));
                } else {
                  return ChartAxisLabel('${details.value}L', const TextStyle(color: Colors.black));
                }
              },
            ),
            axes: isSingleMethod
                ? []
                : [
              NumericAxis(
                name: 'timeAxis',
                opposedPosition: true,
                minimum: 0,
                labelFormat: '{value}m',
                axisLabelFormatter: (AxisLabelRenderDetails details) {
                  num quantity = details.value;
                  // print("AxisLabelRenderDetails ==> value: ${details.value}, text: ${details.text}");
                  if (quantity == 0) {
                    return ChartAxisLabel('0m', const TextStyle(color: Colors.black));
                  }

                  double timeInSeconds = quantity / maxFlowRate;
                  double timeInMinutes = timeInSeconds / 60;

                  return ChartAxisLabel('${timeInMinutes.toStringAsFixed(1)}m', const TextStyle(color: Colors.black));
                },
              )
            ],
            zoomPanBehavior: ZoomPanBehavior(
              enablePanning: true,
            ),
            series: <CartesianSeries>[
              RangeColumnSeries<ChartData, String>(
                borderRadius: BorderRadius.zero,
                dataSource: chartDataList ?? [],
                width: chartDataList!.length <= 3 ? 0.2 : 0.4,
                color: const Color(0xff15C0E6),
                pointColorMapper: (ChartData data, _) {
                  if (data.postValueHigh == 0 || data.preValueHigh == 0) {
                    return const Color(0xff10E196);
                  } else {
                    return const Color(0xff15C0E6);
                  }
                },
                xValueMapper: (ChartData data, _) => "${data.sequenceName}",
                highValueMapper: (ChartData data, _) => data.preValueHigh,
                lowValueMapper: (ChartData data, _) => data.preValueLow,
              ),
              RangeColumnSeries<ChartData, String>(
                borderRadius: BorderRadius.zero,
                dataSource: chartDataList ?? [],
                width: chartDataList!.length <= 3 ? 0.2 : 0.4,
                color: const Color(0xff10E196),
                pointColorMapper: (ChartData data, _) {
                  if (data.postValueHigh == 0 || data.preValueHigh == 0) {
                    return const Color(0xff15C0E6);
                  } else {
                    return const Color(0xff10E196);
                  }
                },
                xValueMapper: (ChartData data, _) => "${data.sequenceName}",
                highValueMapper: (ChartData data, _) => data.waterValueHigh,
                lowValueMapper: (ChartData data, _) => data.waterValueLow,
              ),
              RangeColumnSeries<ChartData, String>(
                borderRadius: BorderRadius.zero,
                dataSource: chartDataList ?? [],
                width: chartDataList!.length <= 3 ? 0.2 : 0.4,
                color: const Color(0xff15C0E6),
                xValueMapper: (ChartData data, _) => data.sequenceName,
                highValueMapper: (ChartData data, _) => data.postValueHigh,
                lowValueMapper: (ChartData data, _) => data.postValueLow,
              ),
            ],
          ),
        ),
      ],
    ) :
    Container(child: const Center(child: Text("Check water and fert screen at glance"),),);
  }

  Widget buildGeneralDetails() {
    return buildCategory(
      categoryTitle: "General details",
      title1: "Irrigation pump",
      itemList1: irrigationProvider.isPumpStationMode ? "Auto pump selection is enabled" : irrigationProvider.selectedObjects!.where((e) => e.objectId == 5).toList(),
      title2: "Head units",
      itemList2: irrigationProvider.selectedObjects!.where((e) => e.objectId == 2).toList(),
      showRow: [3].contains(widget.modelId) ? false : true,
      show4thWidget: false,
      title3: "Main valve",
      itemList3: irrigationProvider.selectedObjects!.where((e) => e.objectId == 14).toList(),
      title4: "",
      itemList4: [],
    );
  }

  Widget buildNoSchedule() {
    final conditionForEcoGem = ([3].contains(widget.modelId));
    print("SEQUENCE JSON: ${jsonEncode(irrigationProvider.irrigationLine!.sequence)}");
    // print("SEQUENCE toList: ${jsonEncode(irrigationProvider.irrigationLine!.sequence.where((e) => e.objectId == 14).toList())}");

    final sequence = irrigationProvider.irrigationLine!.sequence;

    final mainValves = sequence
        .expand((e) => (e['mainValve'] ?? []) as List)
        .toList();

    print("MainValve JSON: ${jsonEncode(mainValves)}");

    return buildCategory(
        categoryTitle: "General details",
        title1: "Irrigation pump",
        itemList1: irrigationProvider.isPumpStationMode ? "Auto pump selection is enabled" : irrigationProvider.selectedObjects!.where((e) => e.objectId == 5).toList(),
        title2: conditionForEcoGem
            ? 'Schedule type'
            : "Head units",
        itemList2: conditionForEcoGem
            ? irrigationProvider.sampleScheduleModel!.selected
            : irrigationProvider.selectedObjects!.where((e) => e.objectId == 2).toList(),
        showRow: conditionForEcoGem ? false : true,
        show4thWidget: true,
        title3: "Main valve",
        itemList3: irrigationProvider.irrigationLine!.sequence
            .expand((e) => (e['mainValve'] ?? []) as List)
            .where((mv) => mv['objectId'] == 14)
            .toList(),
        title4: "Schedule type",
        itemList4: irrigationProvider.sampleScheduleModel!.selected,
        showWidget2: conditionForEcoGem ? false : irrigationProvider.sampleScheduleModel!.selected == irrigationProvider.scheduleTypes[3],
        showRow2: irrigationProvider.sampleScheduleModel!.selected == irrigationProvider.scheduleTypes[3],
        show2ndWidget: [irrigationProvider.scheduleTypes[0], irrigationProvider.scheduleTypes[3]].contains(irrigationProvider.sampleScheduleModel!.selected),
        title5: "On time",
        title6: "Interval",
        title7: "Cycles",
        itemList5: irrigationProvider.sampleScheduleModel!.dayCountSchedule.schedule["onTime"],
        itemList6: irrigationProvider.sampleScheduleModel!.dayCountSchedule.schedule["interval"],
        itemList7: irrigationProvider.sampleScheduleModel!.dayCountSchedule.schedule["shouldLimitCycles"]
            ? irrigationProvider.sampleScheduleModel!.dayCountSchedule.schedule["noOfCycles"] : "No cycle limitations"
    );
  }

  Widget buildFertilizerDetails({required bool centralSelectorCondition}) {
    return buildCategory(
        categoryTitle: "Fertigation details",
        title1: MediaQuery.of(context).size.width > 800 ? "Central fertilizer site" : "Cent. fert site",
        title2: centralSelectorCondition ? "Cent. fert selector" : "Local fert Site",
        itemList1: irrigationProvider.sampleIrrigationLine!.map((e) => centralSelectorCondition
            ? (e.centralFertilization != null ? [e.centralFertilization!] : [])
            : (e.localFertilization != null ? [e.localFertilization!] : [])).expand((list) => list).whereType<DeviceObjectModel>().toList().where((e) => irrigationProvider.selectedObjects!.any((ele) => ele.sNo == e.sNo)).toList(),
        itemList2: [3].contains(widget.modelId) ? [] : centralSelectorCondition
            ? irrigationProvider.fertilizerSite!.where((site) {
          // print("Central filter site ==> ${site.filterSite?.sNo}");
          for (var i = 0; i < irrigationProvider.selectedObjects!.length; i++) {
            if (site.siteMode == 1 && irrigationProvider.selectedObjects![i].objectId == 4 && irrigationProvider.selectedObjects![i].sNo == site.fertilizerSite?.sNo) {
              return true;
            }
          }
          return false;
        })
            .map((e) => e.selector != null ? List<DeviceObjectModel>.from(e.selector!) : [])
            .expand((list) => list)
            .whereType<DeviceObjectModel>()
            .toList().where((e) => irrigationProvider.selectedObjects!.any((ele) => ele.sNo == e.sNo)).toList()
            : irrigationProvider.sampleIrrigationLine!.map((e) => e.localFertilization != null ? [e.localFertilization!] : []).expand((list) => list).whereType<DeviceObjectModel>().toList().where((e) => irrigationProvider.selectedObjects!.any((ele) => ele.sNo == e.sNo)).toList(),
        showRow: [3].contains(widget.modelId) ? false : centralSelectorCondition,
        show4thWidget: [3].contains(widget.modelId) ? false : true,
        show2ndWidget: [3].contains(widget.modelId) ? false : irrigationProvider.sampleIrrigationLine!.map((e) => e.localFertilization != null ? [e.localFertilization!] : []).expand((list) => list).whereType<DeviceObjectModel>().toList().where((e) => irrigationProvider.selectedObjects!.any((ele) => ele.sNo == e.sNo)).toList().isNotEmpty,
        title3: "Local fertilizer site",
        title4: "Local fertilizer selector",
        itemList3: [3].contains(widget.modelId) ? [] : irrigationProvider.sampleIrrigationLine!.map((e) => e.localFertilization != null ? [e.localFertilization!] : []).expand((list) => list).whereType<DeviceObjectModel>().toList().where((e) => irrigationProvider.selectedObjects!.any((ele) => ele.sNo == e.sNo)).toList(),
        itemList4: [3].contains(widget.modelId) ? [] : irrigationProvider.fertilizerSite!.where((site) {
          // print("Central filter site ==> ${site.filterSite?.sNo}");
          for (var i = 0; i < irrigationProvider.selectedObjects!.length; i++) {
            if (site.siteMode == 2 && irrigationProvider.selectedObjects![i].objectId == 4 && irrigationProvider.selectedObjects![i].sNo == site.fertilizerSite?.sNo) {
              return true;
            }
          }
          return false;
        })
            .map((e) => e.selector != null ? List<DeviceObjectModel>.from(e.selector!) : [])
            .expand((list) => list)
            .whereType<DeviceObjectModel>()
            .toList().where((e) => irrigationProvider.selectedObjects!.any((ele) => ele.sNo == e.sNo)).toList(),
    );
  }

  Widget buildFilterDetails({required bool localFilterCondition}) {
    return buildCategory(
        categoryTitle: "Filter details",
        title1: "Central filter site",
        title2: "Central filters",
        itemList1: irrigationProvider.sampleIrrigationLine!.map((e) => e.centralFiltration != null ? [e.centralFiltration!] : []).expand((list) => list).whereType<DeviceObjectModel>().toList().where((e) => irrigationProvider.selectedObjects!.any((ele) => ele.sNo == e.sNo)).toList(),
        itemList2: irrigationProvider.filterSite!.where((site) {
          // print("Central filter site ==> ${site.filterSite?.sNo}");
          for (var i = 0; i < irrigationProvider.selectedObjects!.length; i++) {
            if (site.siteMode == 1 && irrigationProvider.selectedObjects![i].objectId == 4 && irrigationProvider.selectedObjects![i].sNo == site.filterSite?.sNo) {
              return true;
            }
          }
          return false;
        })
            .map((e) => e.filters != null ? List<DeviceObjectModel>.from(e.filters!) : [])
            .expand((list) => list)
            .whereType<DeviceObjectModel>()
            .toList().where((e) => irrigationProvider.selectedObjects!.any((ele) => ele.sNo == e.sNo)).toList(),
        showRow: localFilterCondition,
        show4thWidget: true,
        show2ndWidget: true,
        title3: "Local filter site",
        title4: "Local filters",
        itemList3: irrigationProvider.sampleIrrigationLine!.map((e) => e.localFiltration != null ? [e.localFiltration!] : []).expand((list) => list).whereType<DeviceObjectModel>().toList().where((e) => irrigationProvider.selectedObjects!.any((ele) => ele.sNo == e.sNo)).toList(),
        itemList4: irrigationProvider.filterSite!.where((site) {
          // print("Central filter site ==> ${site.filterSite?.sNo}");
          for (var i = 0; i < irrigationProvider.selectedObjects!.length; i++) {
            if (site.siteMode == 2 && irrigationProvider.selectedObjects![i].objectId == 4 && irrigationProvider.selectedObjects![i].sNo == site.filterSite?.sNo) {
              return true;
            }
          }
          return false;
        })
            .map((e) => e.filters != null ? List<DeviceObjectModel>.from(e.filters!) : [])
            .expand((list) => list)
            .whereType<DeviceObjectModel>()
            .toList().where((e) => irrigationProvider.selectedObjects!.any((ele) => ele.sNo == e.sNo)).toList()
    );
  }

  Widget buildConditionDetails() {
    return buildCategory(
        categoryTitle: "Condition details",
        title1: "Start by condition",
        title2: "Stop by condition",
        itemList1: '${(irrigationProvider.sampleConditions!.condition[0].value['name'] != null)
            ? irrigationProvider.sampleConditions!.condition[0].value['name']
            : 'Not selected'}',
        itemList2: '${(irrigationProvider.sampleConditions!.condition[1].value['name'] != null)
            ? irrigationProvider.sampleConditions!.condition[1].value['name']
            : 'Not selected'}',
        showRow: true,
        show4thWidget: true,
        show2ndWidget: true,
        title3: "Enable by condition",
        title4: "Disable by condition",
        itemList3: '${(irrigationProvider.sampleConditions!.condition[2].value['name'] != null)
            ? irrigationProvider.sampleConditions!.condition[2].value['name']
            : 'Not selected'}',
        itemList4: '${(irrigationProvider.sampleConditions!.condition[3].value['name'] != null)
            ? irrigationProvider.sampleConditions!.condition[3].value['name']
            : 'Not selected'}'
    );
  }

  Widget buildScheduleDetails({scheduleTypeCondition}) {
    final condition = irrigationProvider.sampleScheduleModel!.selected == irrigationProvider.scheduleTypes[1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text("Schedule details", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),),
        ),
        Row(
          children: [
            Expanded(
              child: buildItemsCard(context:context, title: "Schedule type", child: Text(irrigationProvider.sampleScheduleModel!.selected)),
            ),
            Expanded(
              child: buildItemsCard(context:context, title: "Start date", child: _buildScheduleDetailsItem(scheduleTypeCondition, "startDate")
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: buildItemsCard(
                  context: context,
                  title: condition ? "Number of days" : "Run days",
                  child: _buildScheduleDetailsItem(scheduleTypeCondition, condition ? "noOfDays" : "runDays", string: true)
              ),
            ),
            if(!condition)
              Expanded(
                child: buildItemsCard(
                    context: context,
                    title: "Skip days",
                    child: _buildScheduleDetailsItem(scheduleTypeCondition, "skipDays", string: true)
                ),
              ),
            Expanded(
              child: buildItemsCard(
                  context: context,
                  title: "End date",
                  child: _buildScheduleDetailsItem(scheduleTypeCondition, "endDate")
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildCategory({
    required String categoryTitle, required String title1,
    required String title2, required itemList1, required itemList2,
    required showRow, required show4thWidget, required String title3,
    required String title4, required itemList3, required itemList4, bool show2ndWidget = true, String? title5,
    String? title6, itemList5, itemList6, String? title7, itemList7, bool showRow2 = false, bool showWidget2 = false}) {
    print("title3$title3");
    print("itemList3$itemList3");
    print("itemList3${itemList3}");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(categoryTitle, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),),
        ),
        buildItemRow(title1: title1, title2: title2, itemList1: itemList1, itemList2: itemList2, showWidget: show2ndWidget),
        if(showRow)
          buildItemRow(title1: title3, title2: title4, itemList1: itemList3, itemList2: itemList4, showWidget: show4thWidget),
        if(showRow2)
          buildItemRow(title1: title5 ?? "", title2: title6 ?? "", itemList1: itemList5, itemList2: itemList6, title3: title7 ?? "", itemList3: itemList7, showWidget: show4thWidget, showWidget2: showWidget2),
      ],
    );
  }

  Widget buildItemRow({
    required String title1,
    required String title2,
    required itemList1,
    required itemList2,
    String? title3,
    itemList3,
    bool showWidget = true, bool showWidget2 = false}){
    return Row(
      children: [
        Expanded(
          child: buildItemsCard(
              context: context,
              title: title1,
              child: buildIndividualRow(itemList1)
          ),
        ),
        Expanded(
            child: showWidget
                ? buildItemsCard(
                context: context,
                title: title2,
                child: buildIndividualRow(itemList2)
            ) : Container()
        ),
        if(showWidget2)
          Expanded(
              child: buildItemsCard(
                  context: context,
                  title: title3 ?? "",
                  child: buildIndividualRow(itemList3)
              )
          ),
      ],
    );
  }

  Widget buildRtcDetails({required rtcList, required BoxConstraints constraints, required allowStopMethodCondition, required defaultOffTime, required defaultMaxTime}){
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
        margin: MediaQuery.of(context).size.width > 1200 ? const EdgeInsets.only(right: 20) : const EdgeInsets.symmetric(horizontal: 20),
        // padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: customBoxShadow
        ),
        child: CustomDataTable(
          rowsPerPage: rtcList.values.toList().length <= 3 ? rtcList.values.toList().length : 3,
          headerText: 'Schedule Details',
          icon: Icons.water,
          columnSpacing: screenWidth > 800 ? 0 : 20,
          dataRowMaxHeight: 45,
          columns: [
            buildDataColumn(label: "RTC No", widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null),
            buildDataColumn(label: "On time", widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null),
            buildDataColumn(label: "Interval", widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null),
            buildDataColumn(label: "No. of cycles", widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null),
            if(allowStopMethodCondition || defaultOffTime)
              buildDataColumn(label: "Off time", widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null),
            if(allowStopMethodCondition || defaultMaxTime)
              buildDataColumn(label: "Max time", widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null),
          ],
          dataList: rtcList.values.toList(),
          cellBuilders: [
                (data, index) => buildDataCell(dataItem: "RTC ${index+1}", widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null),
                (data, index) => buildDataCell(dataItem: Constants.showHourAndMinuteOnly(data["onTime"], widget.modelId), widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null,),
                (data, index) => buildDataCell(dataItem: Constants.showHourAndMinuteOnly(data["interval"], widget.modelId), widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null,),
                (data, index) => buildDataCell(dataItem: data["noOfCycles"], widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null),
            if(allowStopMethodCondition || defaultOffTime)
                  (data, index) => buildDataCell(dataItem: Constants.showHourAndMinuteOnly(data["offTime"], widget.modelId), widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null,),
            if(allowStopMethodCondition || defaultMaxTime)
                  (data, index) => buildDataCell(dataItem: Constants.showHourAndMinuteOnly(data["maxTime"], widget.modelId), widthRatio: screenWidth > 1200 ? constraints.maxWidth * 0.04 : null),
          ],
        )
    );
  }
// old code do not show main valve
  Widget buildIndividualRowold(item) {
    ScrollController scrollController = ScrollController();
    if(item is! String && item.isNotEmpty) {
      if(item is List<DeviceObjectModel>) {
        return SizedBox(
          height: 20,
          child: Scrollbar(
            controller: scrollController,
            child: ListView.builder(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: item.length,
              itemBuilder: (BuildContext context, int index) {
                return Row(
                  children: [
                    const SizedBox(width: 10),
                    Text(item[index].name ?? ""),
                    const SizedBox(width: 10),
                    if(item.length > 1)
                      VerticalDivider(color: Theme.of(context).primaryColorDark,),
                  ],
                );
              },
            ),
          ),
        );
      } else {
        if(item.any((element) => element.value == true)){
          return SizedBox(
            height: 20,
            child: Scrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: item.length,
                itemBuilder: (BuildContext context, int index) {
                  if (item[index].value == true) {
                    return Row(
                      children: [
                        const SizedBox(width: 10),
                        Text(item[index].name ?? ""),
                        const SizedBox(width: 10),
                        if(item.where((element) => element.value == true).map((e) => e.toJson()).toList().length > 1)
                          VerticalDivider(color: Theme.of(context).primaryColorDark,),
                      ],
                    );
                  }
                  return Container();
                },
              ),
            ),
          );
        } else {
          return const Text("Not Selected", style: TextStyle(color: Colors.red));
        }
      }
    } else {
      return Text(item.toString() != "[]" ? item.toString() : "Not available", style: TextStyle(color: item.toString() != "[]" ? Colors.black :item.toString().contains("Not selected")  ? Colors.red: Colors.grey));
    }
  }
}

Widget _buildHorizontalList(
    ScrollController controller, List<String> names) {
  return SizedBox(
    height: 20,
    child: Scrollbar(
      controller: controller,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        itemBuilder: (_, index) => Row(
          children: [
            const SizedBox(width: 10),
            Text(names[index]),
            if (names.length > 1)
              const SizedBox(
                height: 15,
                child: VerticalDivider(),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget buildIndividualRow(item) {
  ScrollController scrollController = ScrollController();

  if (item == null || item.toString() == "[]") {
    return const Text("Not available", style: TextStyle(color: Colors.grey));
  }

  // ✅ DeviceObjectModel list
  if (item is List<DeviceObjectModel>) {
    return _buildHorizontalList(
      scrollController,
      item.map((e) => e.name ?? "").toList(),
    );
  }

  // ✅ List<Map> (ex: mainValve from sequence)
  if (item is List && item.isNotEmpty && item.first is Map) {
    final names = item
        .where((e) => e['name'] != null)
        .map<String>((e) => e['name'].toString())
        .toList();

    return names.isNotEmpty
        ? _buildHorizontalList(scrollController, names)
        : const Text("Not Selected", style: TextStyle(color: Colors.red));
  }

  // ✅ String
  if (item is String) {
    return Text(item,
        style: TextStyle(
            color: item.contains("Not") ? Colors.red : Colors.black));
  }

  return const Text("Not available", style: TextStyle(color: Colors.grey));
}

Widget buildItemsCard({required BuildContext context, required String title, required Widget child, margin, padding}){

  return Container(
    margin: margin ?? const EdgeInsets.all(10),
    padding: padding ?? const EdgeInsets.all(10),
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: customBoxShadow
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // CircleAvatar(
            //   radius: 15,
            //   backgroundColor: cardColor,
            //   child: Text(
            //     (title.split(" ").first[0]+title.split(" ").last[0]).toUpperCase(),
            //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).primaryColor),
            //   ),
            // ),
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppProperties.linearGradientLeading
              ),
              child: Center(
                child: Text(
                  (title.split(" ").first[0]+title.split(" ").last[0]).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width > 1200 ? 20 : 10,),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w300, overflow: TextOverflow.ellipsis),))
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: child,
        )
      ],
    ),
  );
}

List<BoxShadow> customBoxShadow = [
  BoxShadow(
      offset: const Offset(0, 45),
      blurRadius: 112,
      color: Colors.black.withOpacity(0.06)
  ),
  BoxShadow(
      offset: const Offset(0, 22.78),
      blurRadius: 48.83,
      color: Colors.black.withOpacity(0.0405)
  ),
  BoxShadow(
      offset: const Offset(0, 9),
      blurRadius: 18.2,
      color: Colors.black.withOpacity(0.03)
  ),
  BoxShadow(
      offset: const Offset(0, 1.97),
      blurRadius: 6.47,
      color: Colors.black.withOpacity(0.0195)
  ),
];

DataCell buildDataCell({required dataItem, double? widthRatio, bool showToolTip = false, Color color = Colors.black, Widget? child, bool isFixedSize = false}) {
  return DataCell(
    child ?? SizedBox(
      width: isFixedSize ? widthRatio : null,
      child: showToolTip ?
      Tooltip(
        message: dataItem,
        child: Text(dataItem, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      )
          : Text(dataItem, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
    ),
  );
}

DataColumn buildDataColumn({required label, double? widthRatio, bool isFixedSize = false}) {
  return DataColumn(
      label: SizedBox(
          width: isFixedSize ? widthRatio : null,
          child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white),))
  );
}

dynamic dateFormatConversion(item) {
  return dateFormat.format(DateTime.parse(item));
}

Widget _buildScheduleDetailsItem(scheduleType, item, {string = false, TextAlign textAlign = TextAlign.start}) {
  return Text(
      string
          ? '${scheduleType.schedule[item]}'
          : "${dateFormatConversion(scheduleType.schedule[item])}");
}
