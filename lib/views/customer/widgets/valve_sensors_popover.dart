import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../models/customer/sensor_hourly_data_model.dart';
import '../../../models/customer/site_model.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/my_function.dart';

// ---------------------------------------------------------------------------
// Public widgets (same constructors as before, so callers don't change)
// ---------------------------------------------------------------------------

class MainValveSensorsPopover extends StatelessWidget {
  final MainValveModel valve;
  final int customerId, controllerId;

  /// 'inputPressure' - opens already scrolled to that section.
  final String? initialSection;

  const MainValveSensorsPopover({
    super.key,
    required this.valve,
    required this.customerId,
    required this.controllerId,
    this.initialSection,
  });

  @override
  Widget build(BuildContext context) {
    return _SensorPopoverBody(
      name: valve.name,
      lastRunningDT: valve.lastRunningDT,
      customerId: customerId,
      controllerId: controllerId,
      initialSection: initialSection,
      sections: [
        _SectionConfig(
          id: 'inputPressure',
          title: 'Input Pressure',
          unitParam: 'Pressure Sensor',
          sensors: valve.inputPressure,
          gaugeMax: 50,
          type: _GaugeType.pressure,
        ),
      ],
    );
  }
}

class ValveSensorsPopover extends StatelessWidget {
  final ValveModel valve;
  final int customerId, controllerId;

  /// 'moisture' | 'soilTemp' | 'inputPressure' | 'lateralPressure'
  final String? initialSection;

  const ValveSensorsPopover({
    super.key,
    required this.valve,
    required this.customerId,
    required this.controllerId,
    this.initialSection,
  });

  @override
  Widget build(BuildContext context) {
    return _SensorPopoverBody(
      name: valve.name,
      lastRunningDT: valve.lastRunningDT,
      customerId: customerId,
      controllerId: controllerId,
      initialSection: initialSection,
      sections: [
        _SectionConfig(
          id: 'moisture',
          title: 'Moisture',
          unitParam: 'Moisture Sensor',
          sensors: valve.moistureSensors,
          gaugeMax: 200,
          type: _GaugeType.moisture,
        ),
        _SectionConfig(
          id: 'soilTemp',
          title: 'Soil Temperature',
          unitParam: 'Temperature',
          sensors: valve.soilTemperature,
          gaugeMax: 60,
          type: _GaugeType.temperature,
        ),
        _SectionConfig(
          id: 'inputPressure',
          title: 'Input Pressure',
          unitParam: 'Pressure Sensor',
          sensors: valve.inputPressure,
          gaugeMax: 50,
          type: _GaugeType.pressure,
        ),
        _SectionConfig(
          id: 'lateralPressure',
          title: 'Lateral Pressure',
          unitParam: 'Pressure Sensor',
          sensors: valve.lateralPressure,
          gaugeMax: 50,
          type: _GaugeType.pressure,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared config + body (all fetch / scroll / calendar logic lives here once)
// ---------------------------------------------------------------------------

enum _GaugeType { moisture, temperature, pressure }

class _SectionConfig {
  final String id;
  final String title;
  final String unitParam;
  final List<dynamic> sensors;
  final double gaugeMax;
  final _GaugeType type;

  const _SectionConfig({
    required this.id,
    required this.title,
    required this.unitParam,
    required this.sensors,
    required this.gaugeMax,
    required this.type,
  });
}

class _SensorPopoverBody extends StatefulWidget {
  final String name;
  final String? lastRunningDT;
  final int customerId, controllerId;
  final String? initialSection;
  final List<_SectionConfig> sections;

  const _SensorPopoverBody({
    required this.name,
    required this.lastRunningDT,
    required this.customerId,
    required this.controllerId,
    required this.initialSection,
    required this.sections,
  });

  @override
  State<_SensorPopoverBody> createState() => _SensorPopoverBodyState();
}

class _SensorPopoverBodyState extends State<_SensorPopoverBody> {
  final ScrollController _scrollController = ScrollController();

  /// One key per section id, created once for the life of this State.
  late final Map<String, GlobalKey> _sectionKeys = {
    for (final s in widget.sections)
      s.id: GlobalKey(debugLabel: '${s.id}-$hashCode'),
  };

  DateTime selectedDate = DateTime.now();
  List<SensorHourlyDataModel> sensors = [];

  /// True only until the very first fetch finishes (full-screen spinner).
  bool isInitialLoading = true;

  /// True while a date-change fetch is running (thin overlay spinner).
  bool isRefreshing = false;

  /// Set when the last fetch failed, so the user sees an error + retry
  /// instead of a silently empty chart.
  String? errorMessage;

  /// Only the response matching the latest id is applied to state.
  int _requestId = 0;

  List<_SectionConfig> get _activeSections =>
      widget.sections.where((s) => s.sensors.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    _fetchSensorData(selectedDate).then((_) {
      if (widget.initialSection != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToSection(widget.initialSection!),
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(String section) {
    final ctx = _sectionKeys[section]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ------------------------------------------------------------------ build

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Last Run: ${_formatLastRunning(widget.lastRunningDT)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _activeSections;

    // Case 1: no sensors at all.
    if (sections.isEmpty) return _buildHeader();

    // Case 2: first load.
    if (isInitialLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 200),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    // Case 3: tree stays mounted; date changes only toggle isRefreshing.
    return Stack(
      children: [
        Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSharedCalendar(),
                if (errorMessage != null) _buildErrorBanner(),
                for (final s in sections)
                  _SensorSection(
                    key: _sectionKeys[s.id],
                    config: s,
                    sensorData: sensors,
                    dateKey: DateFormat('yyyy-MM-dd').format(selectedDate),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        if (isRefreshing)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black.withValues(alpha: 0.05),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: isRefreshing ? null : () => _onDateSelected(selectedDate),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// The ONLY calendar. It sits in the header and drives every section.
  /// TableCalendar adapts to the available width, so it can't overflow.
  Widget _buildSharedCalendar() {
    return IgnorePointer(
      ignoring: isRefreshing,
      child: Opacity(
        opacity: isRefreshing ? 0.5 : 1,
        child: TableCalendar(
          focusedDay: selectedDate,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          calendarFormat: CalendarFormat.week,
          availableCalendarFormats: const {CalendarFormat.week: 'Week'},
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          selectedDayPredicate: (day) => _isSameDate(day, selectedDate),
          onDaySelected: (selectedDay, focusedDay) =>
              _onDateSelected(selectedDay),
          enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).primaryColorLight,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(color: Colors.white),
            todayTextStyle: const TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ logic

  String _formatLastRunning(String? dt) {
    if (dt == null || dt.trim().isEmpty) return 'N/A';
    final trimmed = dt.trim();
    if (trimmed.startsWith('0000-00-00')) return '--:--';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(trimmed));
    } catch (_) {
      return '--:--';
    }
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onDateSelected(DateTime day) {
    if (isRefreshing) return;
    setState(() {
      selectedDate = day;
      isRefreshing = true;
      errorMessage = null;
    });
    _fetchSensorData(day);
  }

  Future<void> _fetchSensorData(DateTime date) async {
    final int myRequestId = ++_requestId;
    List<SensorHourlyDataModel> fetched = [];
    String? error;

    try {
      final day = DateFormat('yyyy-MM-dd').format(date);
      final body = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
        "fromDate": day,
        "toDate": day,
      };

      final response =
      await Repository(HttpService()).fetchSensorHourlyData(body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          fetched = (jsonData['data'] as List).map((item) {
            final dateStr = item['date'];
            final Map<String, List<SensorHourlyData>> hourlyDataMap = {};

            item.forEach((key, value) {
              if (key == 'date') return;
              if (value is String && value.isNotEmpty) {
                hourlyDataMap[key] = value
                    .split(';')
                    .map((e) => SensorHourlyData.fromCsv(e, key, dateStr))
                    .toList();
              } else {
                hourlyDataMap[key] = [];
              }
            });

            return SensorHourlyDataModel(
              date: item['date'],
              data: hourlyDataMap,
            );
          }).toList();
        } else {
          error = 'Unable to load data (code ${jsonData["code"]})';
        }
      } else {
        error = 'Unable to load data (HTTP ${response.statusCode})';
      }
    } catch (e) {
      debugPrint('Error fetching sensor hourly data: $e');
      error = 'Unable to load data. Check your connection.';
    }

    // Drop stale responses.
    if (!mounted || myRequestId != _requestId) return;

    setState(() {
      sensors = fetched;
      errorMessage = error;
      isInitialLoading = false;
      isRefreshing = false;
    });
  }
}

// ---------------------------------------------------------------------------
// One section: gauge + sensor chips + hourly chart
// ---------------------------------------------------------------------------

class _SensorSection extends StatefulWidget {
  final _SectionConfig config;
  final List<SensorHourlyDataModel> sensorData;

  /// yyyy-MM-dd; used in the chart key so zoom resets when the day changes.
  final String dateKey;

  const _SensorSection({
    super.key,
    required this.config,
    required this.sensorData,
    required this.dateKey,
  });

  @override
  State<_SensorSection> createState() => _SensorSectionState();
}

class _SensorSectionState extends State<_SensorSection> {
  late String selectedSNo;

  // Created once. Re-creating them inside build (MQTT rebuilds) would make
  // the trackball disappear while the user is touching the chart.
  late final TrackballBehavior _trackball;
  late final ZoomPanBehavior _zoomPan;

  // Small cache so we don't re-scan all data on every MQTT tick.
  List<SensorHourlyDataModel>? _cacheSource;
  String? _cacheSNo;
  List<SensorHourlyData> _cacheData = const [];

  @override
  void initState() {
    super.initState();
    selectedSNo = widget.config.sensors.first.sNo.toString();

    _trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      lineType: TrackballLineType.vertical,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        format: 'point.x : point.y',
      ),
    );

    _zoomPan = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );
  }

  Color _colorFor(double value) {
    switch (widget.config.type) {
      case _GaugeType.pressure:
        if (value <= 10) return Colors.red;
        if (value <= 20) return Colors.orange;
        return Colors.green;

      case _GaugeType.moisture:
        if (value <= 10) return Colors.blue;
        if (value <= 25) return Colors.lightBlueAccent;
        if (value <= 100) return Colors.orange;
        if (value <= 150) return Colors.redAccent;
        return Colors.red;

      case _GaugeType.temperature:
        if (value < 20) return Colors.blue;
        if (value < 35) return Colors.orange;
        return Colors.red;
    }
  }

  List<SensorHourlyData> _chartDataFor(String sNo) {
    if (!identical(_cacheSource, widget.sensorData) || _cacheSNo != sNo) {
      final result = <SensorHourlyData>[];
      for (final model in widget.sensorData) {
        model.data.forEach((_, list) {
          result.addAll(list.where((s) => s.sensorId == sNo));
        });
      }
      _cacheSource = widget.sensorData;
      _cacheSNo = sNo;
      _cacheData = result;
    }
    return _cacheData;
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;

    dynamic selected = cfg.sensors.first;
    for (final s in cfg.sensors) {
      if (s.sNo.toString() == selectedSNo) {
        selected = s;
        break;
      }
    }

    // Live MQTT value for the selected sensor.
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) =>
          provider.getSensorUpdatedValve(selected.sNo.toString()),
      builder: (_, status, __) {
        final statusParts = status?.split(',') ?? [];

        // Local value only - we no longer mutate the model inside build.
        final String liveValue = statusParts.length > 1
            ? statusParts[1]
            : selected.value.toString();

        final numericValue = double.tryParse(liveValue) ?? 0.0;
        final gaugeColor = _colorFor(numericValue);
        final unitText = MyFunction().getUnitByParameter(
          context,
          cfg.unitParam,
          liveValue,
        ) ??
            '';

        final chartData = _chartDataFor(selected.sNo.toString());

        // Show the latest ~12 points; pan left for older ones.
        const visibleCount = 12;
        final bool manyPoints = chartData.length > visibleCount;

        final series = <CartesianSeries<dynamic, String>>[
          LineSeries<SensorHourlyData, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data.hour,
            yValueMapper: (data, _) =>
            double.tryParse(data.value.toString()) ?? 0.0,
            markerSettings: const MarkerSettings(isVisible: true),
            color: Colors.blueAccent,
            name: selected.name,
            animationDuration: 0,
          ),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 10, bottom: 6),
                child: Text(
                  cfg.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),

              // Chip selector - only when there is more than one sensor.
              if (cfg.sensors.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: cfg.sensors.map<Widget>((s) {
                      final isSelected = s.sNo.toString() == selectedSNo;
                      return ChoiceChip(
                        label: Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Theme.of(context).primaryColor,
                        onSelected: (_) =>
                            setState(() => selectedSNo = s.sNo.toString()),
                      );
                    }).toList(),
                  ),
                ),

              // Gauge + name/value. No fixed wide widths, so no overflow.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: SfRadialGauge(
                        key: ValueKey('gauge-${selected.sNo}'),
                        axes: [
                          RadialAxis(
                            minimum: 0,
                            maximum: cfg.gaugeMax,
                            axisLineStyle: AxisLineStyle(
                              thickness: 0.12,
                              thicknessUnit: GaugeSizeUnit.factor,
                              color: Colors.grey.shade300,
                            ),
                            showTicks: false,
                            showLabels: false,
                            pointers: <GaugePointer>[
                              RangePointer(
                                value: numericValue.clamp(0.0, cfg.gaugeMax),
                                color: gaugeColor,
                                width: 0.12,
                                sizeUnit: GaugeSizeUnit.factor,
                              ),
                              NeedlePointer(
                                value: numericValue.clamp(0.0, cfg.gaugeMax),
                                needleEndWidth: 3,
                                needleColor: Colors.black54,
                              ),
                            ],
                            annotations: [
                              GaugeAnnotation(
                                widget: Text(
                                  unitText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: gaugeColor,
                                  ),
                                ),
                                angle: 90,
                                positionFactor: 0.8,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selected.name.toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unitText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: gaugeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Hourly chart: full width, touch shows hour + value.
              SizedBox(
                width: double.infinity,
                height: 220,
                child: chartData.isEmpty
                    ? const Center(child: Text('No data for this date'))
                    : SfCartesianChart(
                  // Date in key -> zoom resets when the day changes,
                  // but NOT on every MQTT rebuild.
                  key: ValueKey(
                    'chart-${selected.sNo}-${widget.dateKey}',
                  ),
                  trackballBehavior: _trackball,
                  zoomPanBehavior: _zoomPan,
                  primaryXAxis: CategoryAxis(
                    interval: 1,
                    labelRotation: 90,
                    majorGridLines: const MajorGridLines(width: 0),
                    initialVisibleMinimum: manyPoints
                        ? (chartData.length - visibleCount).toDouble()
                        : null,
                    initialVisibleMaximum: manyPoints
                        ? (chartData.length - 1).toDouble()
                        : null,
                  ),
                  series: series,
                ),
              ),
              const Divider(),
            ],
          ),
        );
      },
    );
  }
}