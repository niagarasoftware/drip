import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:loading_indicator/loading_indicator.dart';

import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';
import '../../Preferences/widgets/custom_segmented_control.dart';
import '../../PumpController/state_management/pump_controller_provider.dart';
import '../widgets/custom_calendar_mobile.dart';

class PumpVoltageLogScreen extends StatefulWidget {
  final int userId, controllerId, nodeControllerId;
  final MasterControllerModel masterData;
  final bool showMobileCalendar;
  const PumpVoltageLogScreen({super.key, required this.userId, required this.controllerId, this.nodeControllerId = 0, required this.masterData, this.showMobileCalendar = false});

  @override
  State<PumpVoltageLogScreen> createState() => _PumpVoltageLogScreenState();
}

class _PumpVoltageLogScreenState extends State<PumpVoltageLogScreen> {
  int selectedIndex = 0;
  late PumpControllerProvider pumpControllerProvider;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pumpControllerProvider = Provider.of(context,listen: false);
    if(mounted) {
      pumpControllerProvider.getUserVoltageLog(userId: widget.userId, controllerId: widget.controllerId, nodeControllerId: widget.nodeControllerId);
    }
  }

  @override
  void didUpdateWidget(covariant PumpVoltageLogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controllerId != oldWidget.controllerId ||
        widget.nodeControllerId != oldWidget.nodeControllerId) {
      pumpControllerProvider.getUserVoltageLog(
        userId: widget.userId,
        controllerId: widget.controllerId,
        nodeControllerId: widget.nodeControllerId,
      );
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredData {
    if (selectedIndex == 0) {
      return pumpControllerProvider.voltageData;
    } else if(selectedIndex == 1){
      return pumpControllerProvider.voltageData.map((data) {
        return {
          "hour": data['hour'],
          "currentR": data['currentR'],
          "currentY": data['currentY'],
          "currentB": data['currentB'],
        };
      }).toList();
    } else if(selectedIndex == 2){
      return pumpControllerProvider.voltageData.map((data) {
        return {
          "hour": data['hour'],
          "powerFactorR": data['powerFactorR'],
          "powerFactorY": data['powerFactorY'],
          "powerFactorB": data['powerFactorB'],
        };
      }).toList();
    } else {
      return pumpControllerProvider.voltageData.map((data) {
        return {
          "hour": data['hour'],
          "powerR": data['powerR'],
          "powerY": data['powerY'],
          "powerB": data['powerB'],
        };
      }).toList();
    }
  }

  bool get isSinglePhaseModel {
    int modelId = widget.masterData.modelId;
    return AppConstants.singlePhasePumpModel.contains(modelId) ||
           AppConstants.singlePhasePumpPlusModel.contains(modelId) ||
           AppConstants.singlePhaseShineModel.contains(modelId) ||
           AppConstants.singlePhaseElitePlusModel.contains(modelId) ||
           AppConstants.singlePhaseEcoGemModel.contains(modelId) ||
           AppConstants.singlePhaseEcoGemPlusModel.contains(modelId);
  }

  @override
  Widget build(BuildContext context) {
    pumpControllerProvider = Provider.of(context);
    
    bool showR = true;
    bool showY = true;
    bool showB = true;

    if (isSinglePhaseModel) {
      if (selectedIndex == 0) {
        showR = false;
        showY = false;
        showB = true;
      } else if (selectedIndex == 1) {
        showR = true;
        showY = false;
        showB = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: [...AppConstants.ecoGemAndPlusModelList, ...AppConstants.gemModelList].contains(widget.masterData.modelId) ? AppBar(
        title: const Text('Voltage log'),
      ) : PreferredSize(preferredSize: const Size(0, 0), child: Container()),
      body: SafeArea(
        child: (pumpControllerProvider.voltageData.isNotEmpty || pumpControllerProvider.message.isNotEmpty) ? Column(
          children: [
            if(kIsWeb ? widget.showMobileCalendar : true)
              MobileCustomCalendar(
                focusedDay: pumpControllerProvider.focusedDay,
                calendarFormat: pumpControllerProvider.calendarFormat,
                selectedDate: pumpControllerProvider.selectedDate,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    pumpControllerProvider.selectedDate = selectedDay;
                    pumpControllerProvider.focusedDay = focusedDay;
                  });
                  pumpControllerProvider.getUserVoltageLog(userId: widget.userId, controllerId: widget.controllerId, nodeControllerId: widget.nodeControllerId);
                },
                onFormatChanged: (format) {
                  if (pumpControllerProvider.calendarFormat != format) {
                    setState(() {
                      pumpControllerProvider.calendarFormat = format;
                    });
                  }
                },
              ),
            const SizedBox(height: 10),
            if (pumpControllerProvider.voltageData.isNotEmpty && pumpControllerProvider.message.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomSegmentedControl(
                    segmentTitles: pumpControllerProvider.voltageData[0]['totalInstantEnergy'] != null ? {
                      0: "Voltage",
                      1: "Current",
                      2: "Power Factor",
                      3: "Power",
                    } : {
                      0: "Voltage",
                      1: "Current",
                    },
                    groupValue: selectedIndex,
                    onChanged: (newValue) {
                      setState(() {
                        selectedIndex = newValue!;
                      });
                      // getUserPumpLog();
                    }
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => pumpControllerProvider.getUserVoltageLog(userId: widget.userId, controllerId: widget.controllerId, nodeControllerId: widget.nodeControllerId),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (pumpControllerProvider.message.isNotEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              pumpControllerProvider.message,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      else if (pumpControllerProvider.voltageData.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: AppProperties.customBoxShadowLiteTheme,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SfCartesianChart(
                            primaryXAxis: const CategoryAxis(
                              labelRotation: 45,
                              majorGridLines: MajorGridLines(width: 0.5),
                            ),
                            primaryYAxis: NumericAxis(
                              labelFormat: selectedIndex == 0 ? '{value}V' : selectedIndex == 1 ?'{value}A' : selectedIndex == 2 ? '{value}' : '{value}kW',
                              majorGridLines: const MajorGridLines(width: 0.5),
                            ),
                            title: ChartTitle(
                              text: selectedIndex == 0 ? 'Voltage Graph' : selectedIndex == 1 ? 'Current Graph' : selectedIndex == 2 ? "Power Factor" : "Power Graph",
                            ),
                            legend: const Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                            ),
                            tooltipBehavior: TooltipBehavior(
                              enable: true,
                              header: selectedIndex == 0 ? 'Voltage Info' : selectedIndex == 1 ? 'Current Info' : selectedIndex == 2 ? 'Power Factor Info' : 'Power Info',
                              format: 'point.x: point.y',
                            ),
                            series: <SplineSeries<Map<String, dynamic>, String>>[
                              if (showR)
                                _buildSplineSeries(
                                  dataSource: filteredData,
                                  color: Colors.red,
                                  phase: 'R',
                                  name: selectedIndex == 0 ? 'Voltage R' : selectedIndex == 1 ? 'Current R' : selectedIndex == 2 ? "Power Factor R" : "Power R",
                                ),
                              if (showY)
                                _buildSplineSeries(
                                  dataSource: filteredData,
                                  color: Colors.yellow,
                                  phase: 'Y',
                                  name: selectedIndex == 0 ? 'Voltage Y' : selectedIndex == 1 ? 'Current Y' : selectedIndex == 2 ? "Power Factor Y" : "Power Y",
                                ),
                              if (showB)
                                _buildSplineSeries(
                                  dataSource: filteredData,
                                  color: Colors.blue,
                                  phase: 'B',
                                  name: selectedIndex == 0 ? 'Voltage B' : selectedIndex == 1 ? 'Current B' : selectedIndex == 2 ? "Power Factor B" : "Power B",
                                ),
                            ],
                          ),
                        ),
                      if (pumpControllerProvider.message.isEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 1,
                          itemBuilder: (context, index) {
                            return _buildVoltageLogCard(pumpControllerProvider.voltageData[index], showR, showY, showB);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ) : const Center(child: SizedBox(
          width: 100,
          height: 50,
          child: LoadingIndicator(colors: [Colors.redAccent,
            Colors.amberAccent,
            Colors.lightBlueAccent,], indicatorType: Indicator.ballPulse,),
        ),),
      ),
    );
  }

  SplineSeries<Map<String, dynamic>, String> _buildSplineSeries({
    required List<Map<String, dynamic>> dataSource,
    required Color color,
    required String phase,
    required String name,
  }) {
    return SplineSeries<Map<String, dynamic>, String>(
      dataSource: dataSource,
      xValueMapper: (data, _) => 'Hour ${data['hour']}',
      yValueMapper: (data, _) {
        final key = selectedIndex == 0 ? 'voltage$phase' : selectedIndex == 1 ? 'current$phase' : selectedIndex == 2 ? 'powerFactor$phase' : 'power$phase';
        return double.tryParse(data[key] ?? '0.0') ?? 0.0;
      },
      name: name,
      markerSettings: const MarkerSettings(isVisible: true),
      color: color,
    );
  }

  Widget _buildVoltageLogCard(Map<String, dynamic> data, bool showR, bool showY, bool showB) {
    int activePhases = (showR ? 1 : 0) + (showY ? 1 : 0) + (showB ? 1 : 0);
    Map<int, TableColumnWidth> widths = { 0: const FlexColumnWidth(2) };
    for (int i = 0; i < activePhases; i++) {
      widths[i + 1] = const FlexColumnWidth(1);
    }
    
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      surfaceTintColor: Colors.white,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: widths,
              children: [
                TableRow(
                  children: [
                    Container(
                      color: Theme.of(context).primaryColor.withOpacity(0.4),
                      padding: const EdgeInsets.all(8.0),
                      child: const Text('Hours', style: TextStyle(fontWeight: FontWeight.bold,)),
                    ),
                    if (showR)
                      Container(
                        color: Colors.redAccent.shade100,
                        padding: const EdgeInsets.all(8.0),
                        child: const Text('R', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    if (showY)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.amberAccent.shade100,
                        child: const Text('Y', style: TextStyle(fontWeight: FontWeight.bold,)),
                      ),
                    if (showB)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.lightBlueAccent.shade100,
                        child: const Text('B', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                ..._buildDataRows(showR, showY, showB)
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<TableRow> _buildDataRows(bool showR, bool showY, bool showB) {
    List<TableRow> rows = [];

    for (var entry in pumpControllerProvider.voltageData) {
      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${entry['hour']}'),
            ),
            if (showR)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  selectedIndex == 0 ? entry['voltageR'] : selectedIndex == 1 ? entry['currentR'] : selectedIndex == 2 ? entry['powerFactorR'] : entry['powerR'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (showY)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  selectedIndex == 0 ? entry['voltageY'] : selectedIndex == 1 ? entry['currentY'] : selectedIndex == 2 ? entry['powerFactorY'] : entry['powerY'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (showB)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  selectedIndex == 0 ? entry['voltageB'] : selectedIndex == 1 ? entry['currentB'] : selectedIndex == 2 ? entry['powerFactorB'] : entry['powerB'],
                  style: const TextStyle(fontWeight: FontWeight.bold,),
                ),
              ),
          ],
        ),
      );
    }

    return rows;
  }
}
