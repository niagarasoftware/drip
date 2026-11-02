import 'dart:async';

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
  Timer? _autoRefreshTimer;
  bool _silentBusy = false;

  /// The day (and device) the currently displayed / requested voltage data belongs to.
  /// Used to detect a date change made by ANY calendar (this screen's or the parent's).
  DateTime? _loadedDate;

  int get effectiveNodeControllerId {
    if (widget.nodeControllerId != 0) return widget.nodeControllerId;
    if (widget.masterData.nodeList.isNotEmpty &&
        !AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId)) {
      return widget.masterData.nodeList.first.controllerId;
    }
    return 0;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Loads the provider's currently selected date. Safe to call from anywhere
  /// (initState, build, listeners) because the fetch is deferred until after the frame.
  void _loadVoltage() {
    _loadedDate = pumpControllerProvider.selectedDate; // set now so we never double-fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      pumpControllerProvider.getUserVoltageLog(
        userId: widget.userId,
        controllerId: widget.controllerId,
        nodeControllerId: effectiveNodeControllerId,
      );
    });
  }

  /// Refetch if the selected date was changed from somewhere else (e.g. the web calendar
  /// in the parent screen, which only updates provider.selectedDate).
  void _reloadIfDateChanged() {
    if (!mounted) return;
    final selected = pumpControllerProvider.selectedDate;
    if (_loadedDate == null || !_sameDay(_loadedDate!, selected)) {
      _loadVoltage();
    }
  }

  @override
  void initState() {
    super.initState();
    pumpControllerProvider = Provider.of(context, listen: false);
    pumpControllerProvider.addListener(_reloadIfDateChanged);
    _loadVoltage();

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _silentRefresh());
  }

  Future<void> _silentRefresh() async {
    if (!mounted || _silentBusy || !TickerMode.of(context)) return;
    final now = DateTime.now();
    final d = pumpControllerProvider.selectedDate;
    if (d.year != now.year || d.month != now.month || d.day != now.day) return;
    _silentBusy = true;
    try {
      await pumpControllerProvider.getUserVoltageLog(
        userId: widget.userId,
        controllerId: widget.controllerId,
        nodeControllerId: effectiveNodeControllerId,
        silent: true,
      );
    } finally {
      _silentBusy = false;
    }
  }

  @override
  void didUpdateWidget(covariant PumpVoltageLogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controllerId != oldWidget.controllerId ||
        widget.nodeControllerId != oldWidget.nodeControllerId) {
      _loadVoltage();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    pumpControllerProvider.removeListener(_reloadIfDateChanged);
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredData {
    if (selectedIndex == 0) {
      return pumpControllerProvider.voltageData;
    } else if (selectedIndex == 1) {
      return pumpControllerProvider.voltageData.map((data) {
        return {
          "hour": data['hour'],
          "currentR": data['currentR'],
          "currentY": data['currentY'],
          "currentB": data['currentB'],
        };
      }).toList();
    } else if (selectedIndex == 2) {
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

  /// Y-axis window fitted to the plotted data (voltage zoomed in, current from 0).
  ({double min, double max}) _axisRange(List<String> keys) {
    double? lo;
    double? hi;
    for (final row in pumpControllerProvider.voltageData) {
      for (final k in keys) {
        final x = PumpControllerProvider.parseReading(row[k]);
        if (x == null) continue;
        lo = lo == null ? x : (x < lo ? x : lo);
        hi = hi == null ? x : (x > hi ? x : hi);
      }
    }
    if (lo == null || hi == null) return (min: 0.0, max: selectedIndex == 0 ? 500.0 : 10.0);
    if (selectedIndex == 0) {
      final double pad = ((hi - lo) * 0.15) < 10 ? 10 : (hi - lo) * 0.15;
      double min = ((lo - pad) / 10).floorToDouble() * 10;
      if (min < 0) min = 0;
      return (min: min, max: ((hi + pad) / 10).ceilToDouble() * 10);
    }
    if (selectedIndex == 1) {
      final double top = hi <= 0 ? 1 : hi * 1.2;
      final double step = top <= 5 ? 1 : (top <= 20 ? 2 : 5);
      return (min: 0.0, max: (top / step).ceilToDouble() * step);
    }
    return (min: lo < 0 ? lo : 0.0, max: hi <= 0 ? 1.0 : hi * 1.1);
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

  Widget _buildLoader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: SizedBox(
          width: 100,
          height: 50,
          child: LoadingIndicator(
            colors: [Colors.redAccent, Colors.amberAccent, Colors.lightBlueAccent],
            indicatorType: Indicator.ballPulse,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    pumpControllerProvider = Provider.of(context);

    // Safety net: if the date changed and the listener hasn't caught it yet, catch it here.
    _reloadIfDateChanged();

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

    final String phasePrefix = selectedIndex == 0 ? 'voltage' : selectedIndex == 1 ? 'current' : selectedIndex == 2 ? 'powerFactor' : 'power';
    final axisRange = _axisRange([
      if (showR) '${phasePrefix}R',
      if (showY) '${phasePrefix}Y',
      if (showB) '${phasePrefix}B',
    ]);

    final bool hasData = pumpControllerProvider.voltageData.isNotEmpty;
    final bool hasMessage = pumpControllerProvider.voltageMessage.isNotEmpty;
    // Loader while a fetch is running, or before the first response has arrived.
    final bool showLoader = pumpControllerProvider.isVoltageLoading || (!hasData && !hasMessage);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: [...AppConstants.ecoGemAndPlusModelList, ...AppConstants.gemModelList].contains(widget.masterData.modelId) ? AppBar(
        title: const Text('Voltage log'),
      ) : PreferredSize(preferredSize: const Size(0, 0), child: Container()),
      body: SafeArea(
        child: Column(
          children: [
            // Calendar always stays visible, even while a date is loading.
            // (On web the parent screen owns the calendar; it only changes provider.selectedDate,
            // which _reloadIfDateChanged now picks up.)
            if (kIsWeb ? widget.showMobileCalendar : true)
              MobileCustomCalendar(
                focusedDay: pumpControllerProvider.focusedDay,
                calendarFormat: pumpControllerProvider.calendarFormat,
                selectedDate: pumpControllerProvider.selectedDate,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    pumpControllerProvider.selectedDate = selectedDay;
                    pumpControllerProvider.focusedDay = focusedDay;
                  });
                  _loadVoltage();
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
            if (!showLoader && hasData && !hasMessage)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomSegmentedControl(
                    segmentTitles: const {
                      0: "Voltage",
                      1: "Current",
                    },
                    groupValue: selectedIndex,
                    onChanged: (newValue) {
                      setState(() {
                        selectedIndex = newValue!;
                      });
                    }
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => pumpControllerProvider.getUserVoltageLog(
                  userId: widget.userId,
                  controllerId: widget.controllerId,
                  nodeControllerId: effectiveNodeControllerId,
                ),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      if (showLoader)
                        _buildLoader()
                      else if (hasMessage)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              pumpControllerProvider.voltageMessage,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      else ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: AppProperties.customBoxShadowLiteTheme,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SfCartesianChart(
                              key: ValueKey('voltage_chart_${pumpControllerProvider.selectedDate}_${filteredData.length}_$selectedIndex'),
                              primaryXAxis: const CategoryAxis(
                                labelRotation: 45,
                                majorGridLines: MajorGridLines(width: 0.5),
                              ),
                              primaryYAxis: NumericAxis(
                                minimum: axisRange.min,
                                maximum: axisRange.max,
                                labelFormat: selectedIndex == 0 ? '{value}V' : selectedIndex == 1 ? '{value}A' : selectedIndex == 2 ? '{value}' : '{value}kW',
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
                          _buildVoltageLogCard(showR, showY, showB),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
        // null (not 0) for a missing reading -> gap in the line instead of a false drop to zero
        return PumpControllerProvider.parseReading(data[key]);
      },
      name: name,
      markerSettings: const MarkerSettings(isVisible: true),
      color: color,
      splineType: SplineType.monotonic,
      emptyPointSettings: const EmptyPointSettings(mode: EmptyPointMode.gap),
      animationDuration: 0,
    );
  }

  Widget _buildVoltageLogCard(bool showR, bool showY, bool showB) {
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
                      child: const Text('Hours', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        child: const Text('Y', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  '${(selectedIndex == 0 ? entry['voltageR'] : selectedIndex == 1 ? entry['currentR'] : selectedIndex == 2 ? entry['powerFactorR'] : entry['powerR']) ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (showY)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${(selectedIndex == 0 ? entry['voltageY'] : selectedIndex == 1 ? entry['currentY'] : selectedIndex == 2 ? entry['powerFactorY'] : entry['powerY']) ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (showB)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${(selectedIndex == 0 ? entry['voltageB'] : selectedIndex == 1 ? entry['currentB'] : selectedIndex == 2 ? entry['powerFactorB'] : entry['powerB']) ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );
    }

    return rows;
  }
}