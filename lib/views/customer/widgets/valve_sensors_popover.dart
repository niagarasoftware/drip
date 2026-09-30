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

class MainValveSensorsPopover extends StatefulWidget {
  final MainValveModel valve;
  final int customerId, controllerId;

  /// Optional: 'moisture' | 'soilTemp' | 'inputPressure' | 'lateralPressure'
  /// Pass this when the user tapped a specific badge, so the popover
  /// opens already scrolled to that section.
  final String? initialSection;

  const MainValveSensorsPopover({
    super.key,
    required this.valve,
    required this.customerId,
    required this.controllerId,
    this.initialSection,
  });

  @override
  State<MainValveSensorsPopover> createState() => _MainValveSensorsPopoverState();
}

class _MainValveSensorsPopoverState extends State<MainValveSensorsPopover> {
  final ScrollController _scrollController = ScrollController();

  // Keys are created once for the lifetime of this State and are never
  late final GlobalKey _inputPressureKey = GlobalKey(debugLabel: 'inputPressure-$hashCode');

  DateTime selectedDate = DateTime.now();
  List<SensorHourlyDataModel> sensors = [];

  /// True only until the very FIRST fetch finishes. While true we show a
  /// full-screen spinner because there is no sensor tree worth mounting
  /// yet (no data at all). After the first successful load this stays
  /// false for the rest of the popover's life.
  bool isInitialLoading = true;

  /// True while a *subsequent* (date-change) fetch is in flight. Used to
  /// draw a thin overlay spinner ON TOP of the already-mounted sensor
  /// tree — the tree itself is never removed/rebuilt because of this.
  bool isRefreshing = false;

  /// Guards against overlapping fetches: only the response whose id
  /// matches the latest `_requestId` is ever applied to state.
  int _requestId = 0;

  bool get _hasAnySensor {
    final valve = widget.valve;
    return valve.inputPressure.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _fetchSensorData(selectedDate, selectedDate, isInitial: true).then((_) {
      if (widget.initialSection != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection(widget.initialSection!));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(String section) {
    GlobalKey? key;
    switch (section) {
      case 'inputPressure':
        key = _inputPressureKey;
        break;
    }
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valve = widget.valve;

    final hasInputPressure = valve.inputPressure.isNotEmpty;
    final hasAnySensor = _hasAnySensor;

    // Shared header (always shown)
    Widget buildHeader() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valve.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Last Run: ${_formatLastRunning(valve.lastRunningDT)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // ---- Case 1: No sensors at all ----
    // This branch is stable for the popover's whole life (hasAnySensor
    // doesn't change), so it never gets swapped with the sensor tree.
    if (!hasAnySensor) {
      return buildHeader();
    }

    // ---- Case 2: First-ever load, nothing to show yet ----
    // This ONLY happens once, before the sensor tree (and its GlobalKeys)
    // has ever been mounted, so there is nothing to tear down here.
    if (isInitialLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(),
          const SizedBox(height: 200),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    // ---- Case 3: Sensor tree is mounted for the rest of this popover's
    // lifetime. Date changes only update `sensors` / `isRefreshing`
    // (see setState calls below) and never rebuild this branch away.
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
                buildHeader(),
                if (hasInputPressure)
                  _SensorSection(
                    key: _inputPressureKey,
                    title: 'Input Pressure',
                    sensors: valve.inputPressure,
                    unitParam: 'Pressure Sensor',
                    sensorData: sensors,
                    gaugeMax: 50,
                    gaugeType: _GaugeType.pressure,
                    selectedDate: selectedDate,
                    isBusy: isRefreshing,
                    onDateSelected: _onDateSelected,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Thin overlay spinner shown ON TOP of the already-mounted tree
        // while a date-change fetch is in flight. The tree underneath is
        // never removed, so charts/gauges/GlobalKeys/ScrollController are
        // never disposed and reinflated.
        if (isRefreshing)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
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

  String _formatLastRunning(String? dt) {
    if (dt == null || dt.trim().isEmpty) return 'N/A';

    // Backend placeholder for "no last run"
    final trimmed = dt.trim();
    if (trimmed.startsWith('0000-00-00')) return '--:--';

    try {
      final parsed = DateTime.parse(trimmed);
      return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
    } catch (_) {
      return '--:--'; // fall back for any other invalid format
    }
  }

  /// Called by the (single, shared) calendar when the user picks a new
  /// day. Collapses what used to be two separate setState calls into one,
  /// and — critically — never flips a flag that would cause the sensor
  /// subtree itself to be unmounted.
  void _onDateSelected(DateTime day) {
    if (isRefreshing) return; // ignore taps while a fetch is already running
    setState(() {
      selectedDate = day;
      isRefreshing = true;
    });
    _fetchSensorData(selectedDate, selectedDate);
  }

  Future<void> _fetchSensorData(DateTime fromDate, DateTime toDate, {bool isInitial = false}) async {
    final int myRequestId = ++_requestId;
    List<SensorHourlyDataModel> fetched = [];

    try {
      final from = DateFormat('yyyy-MM-dd').format(fromDate);
      final to = DateFormat('yyyy-MM-dd').format(toDate);

      final body = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
        "fromDate": from,
        "toDate": to,
      };

      final response = await Repository(HttpService()).fetchSensorHourlyData(body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          fetched = (jsonData['data'] as List).map((item) {
            final dateStr = item['date'];
            final Map<String, List<SensorHourlyData>> hourlyDataMap = {};

            item.forEach((key, value) {
              if (key == 'date') return;
              if (value is String && value.isNotEmpty) {
                final entries = value.split(';');
                hourlyDataMap[key] = entries.map((entry) => SensorHourlyData.fromCsv(entry, key, dateStr)).toList();
              } else {
                hourlyDataMap[key] = [];
              }
            });

            return SensorHourlyDataModel(date: item['date'], data: hourlyDataMap);
          }).toList();
        }
      }
    } catch (error) {
      debugPrint('Error fetching sensor hourly data: $error');
    }

    // Stale response guard: if the user picked another date while this
    // request was in flight, `_requestId` has moved on — drop this result
    // instead of applying outdated data over a newer request's data.
    if (!mounted || myRequestId != _requestId) return;

    setState(() {
      sensors = fetched;
      isInitialLoading = false;
      isRefreshing = false;
    });
  }

  bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Single shared calendar widget. Only one instance is ever built (in
  /// the popover header), instead of one per `_SensorSection`, so there is
  /// only ever one place that can trigger a date change.
  Widget buildSharedCalendar() {
    return TableCalendar(
      focusedDay: selectedDate,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      calendarFormat: CalendarFormat.week,
      availableCalendarFormats: const {CalendarFormat.week: 'Week'},
      selectedDayPredicate: (day) => _isSameDate(day, selectedDate),
      onDaySelected: isRefreshing ? null : (selectedDay, focusedDay) => _onDateSelected(selectedDay),
      enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColorLight, shape: BoxShape.circle),
        todayDecoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
        selectedTextStyle: const TextStyle(color: Colors.white),
        todayTextStyle: const TextStyle(color: Colors.black),
      ),
    );
  }
}


class ValveSensorsPopover extends StatefulWidget {
  final ValveModel valve;
  final int customerId, controllerId;

  /// Optional: 'moisture' | 'soilTemp' | 'inputPressure' | 'lateralPressure'
  /// Pass this when the user tapped a specific badge, so the popover
  /// opens already scrolled to that section.
  final String? initialSection;

  const ValveSensorsPopover({
    super.key,
    required this.valve,
    required this.customerId,
    required this.controllerId,
    this.initialSection,
  });

  @override
  State<ValveSensorsPopover> createState() => _ValveSensorsPopoverState();
}

class _ValveSensorsPopoverState extends State<ValveSensorsPopover> {
  final ScrollController _scrollController = ScrollController();

  // Keys are created once for the lifetime of this State and are never
  // reassigned, so they can never collide with themselves.
  late final GlobalKey _moistureKey = GlobalKey(debugLabel: 'moisture-$hashCode');
  late final GlobalKey _soilTempKey = GlobalKey(debugLabel: 'soilTemp-$hashCode');
  late final GlobalKey _inputPressureKey = GlobalKey(debugLabel: 'inputPressure-$hashCode');
  late final GlobalKey _lateralPressureKey = GlobalKey(debugLabel: 'lateralPressure-$hashCode');

  DateTime selectedDate = DateTime.now();
  List<SensorHourlyDataModel> sensors = [];

  /// True only until the very FIRST fetch finishes. While true we show a
  /// full-screen spinner because there is no sensor tree worth mounting
  /// yet (no data at all). After the first successful load this stays
  /// false for the rest of the popover's life.
  bool isInitialLoading = true;

  /// True while a *subsequent* (date-change) fetch is in flight. Used to
  /// draw a thin overlay spinner ON TOP of the already-mounted sensor
  /// tree — the tree itself is never removed/rebuilt because of this.
  bool isRefreshing = false;

  /// Guards against overlapping fetches: only the response whose id
  /// matches the latest `_requestId` is ever applied to state.
  int _requestId = 0;

  bool get _hasAnySensor {
    final valve = widget.valve;
    return valve.moistureSensors.isNotEmpty ||
        valve.soilTemperature.isNotEmpty ||
        valve.inputPressure.isNotEmpty ||
        valve.lateralPressure.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _fetchSensorData(selectedDate, selectedDate, isInitial: true).then((_) {
      if (widget.initialSection != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection(widget.initialSection!));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(String section) {
    GlobalKey? key;
    switch (section) {
      case 'moisture':
        key = _moistureKey;
        break;
      case 'soilTemp':
        key = _soilTempKey;
        break;
      case 'inputPressure':
        key = _inputPressureKey;
        break;
      case 'lateralPressure':
        key = _lateralPressureKey;
        break;
    }
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valve = widget.valve;

    final hasMoisture = valve.moistureSensors.isNotEmpty;
    final hasSoilTemp = valve.soilTemperature.isNotEmpty;
    final hasInputPressure = valve.inputPressure.isNotEmpty;
    final hasLateralPressure = valve.lateralPressure.isNotEmpty;
    final hasAnySensor = _hasAnySensor;

    // Shared header (always shown)
    Widget buildHeader() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valve.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Last Run: ${_formatLastRunning(valve.lastRunningDT)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // ---- Case 1: No sensors at all ----
    // This branch is stable for the popover's whole life (hasAnySensor
    // doesn't change), so it never gets swapped with the sensor tree.
    if (!hasAnySensor) {
      return buildHeader();
    }

    // ---- Case 2: First-ever load, nothing to show yet ----
    // This ONLY happens once, before the sensor tree (and its GlobalKeys)
    // has ever been mounted, so there is nothing to tear down here.
    if (isInitialLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(),
          const SizedBox(height: 200),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    // ---- Case 3: Sensor tree is mounted for the rest of this popover's
    // lifetime. Date changes only update `sensors` / `isRefreshing`
    // (see setState calls below) and never rebuild this branch away.
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
                buildHeader(),
                if (hasMoisture)
                  _SensorSection(
                    key: _moistureKey,
                    title: 'Moisture',
                    sensors: valve.moistureSensors,
                    unitParam: 'Moisture Sensor',
                    sensorData: sensors,
                    gaugeMax: 200,
                    gaugeType: _GaugeType.moisture,
                    selectedDate: selectedDate,
                    isBusy: isRefreshing,
                    onDateSelected: _onDateSelected,
                  ),
                if (hasSoilTemp)
                  _SensorSection(
                    key: _soilTempKey,
                    title: 'Soil Temperature',
                    sensors: valve.soilTemperature,
                    unitParam: 'Temperature',
                    sensorData: sensors,
                    gaugeMax: 60,
                    gaugeType: _GaugeType.temperature,
                    selectedDate: selectedDate,
                    isBusy: isRefreshing,
                    onDateSelected: _onDateSelected,
                  ),
                if (hasInputPressure)
                  _SensorSection(
                    key: _inputPressureKey,
                    title: 'Input Pressure',
                    sensors: valve.inputPressure,
                    unitParam: 'Pressure Sensor',
                    sensorData: sensors,
                    gaugeMax: 50,
                    gaugeType: _GaugeType.pressure,
                    selectedDate: selectedDate,
                    isBusy: isRefreshing,
                    onDateSelected: _onDateSelected,
                  ),
                if (hasLateralPressure)
                  _SensorSection(
                    key: _lateralPressureKey,
                    title: 'Lateral Pressure',
                    sensors: valve.lateralPressure,
                    unitParam: 'Pressure Sensor',
                    sensorData: sensors,
                    gaugeMax: 50,
                    gaugeType: _GaugeType.pressure,
                    selectedDate: selectedDate,
                    isBusy: isRefreshing,
                    onDateSelected: _onDateSelected,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Thin overlay spinner shown ON TOP of the already-mounted tree
        // while a date-change fetch is in flight. The tree underneath is
        // never removed, so charts/gauges/GlobalKeys/ScrollController are
        // never disposed and reinflated.
        if (isRefreshing)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
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

  String _formatLastRunning(String? dt) {
    if (dt == null || dt.trim().isEmpty) return 'N/A';

    // Backend placeholder for "no last run"
    final trimmed = dt.trim();
    if (trimmed.startsWith('0000-00-00')) return '--:--';

    try {
      final parsed = DateTime.parse(trimmed);
      return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
    } catch (_) {
      return '--:--'; // fall back for any other invalid format
    }
  }

  /// Called by the (single, shared) calendar when the user picks a new
  /// day. Collapses what used to be two separate setState calls into one,
  /// and — critically — never flips a flag that would cause the sensor
  /// subtree itself to be unmounted.
  void _onDateSelected(DateTime day) {
    if (isRefreshing) return; // ignore taps while a fetch is already running
    setState(() {
      selectedDate = day;
      isRefreshing = true;
    });
    _fetchSensorData(selectedDate, selectedDate);
  }

  Future<void> _fetchSensorData(DateTime fromDate, DateTime toDate, {bool isInitial = false}) async {
    final int myRequestId = ++_requestId;
    List<SensorHourlyDataModel> fetched = [];

    try {
      final from = DateFormat('yyyy-MM-dd').format(fromDate);
      final to = DateFormat('yyyy-MM-dd').format(toDate);

      final body = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
        "fromDate": from,
        "toDate": to,
      };

      final response = await Repository(HttpService()).fetchSensorHourlyData(body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          fetched = (jsonData['data'] as List).map((item) {
            final dateStr = item['date'];
            final Map<String, List<SensorHourlyData>> hourlyDataMap = {};

            item.forEach((key, value) {
              if (key == 'date') return;
              if (value is String && value.isNotEmpty) {
                final entries = value.split(';');
                hourlyDataMap[key] = entries.map((entry) => SensorHourlyData.fromCsv(entry, key, dateStr)).toList();
              } else {
                hourlyDataMap[key] = [];
              }
            });

            return SensorHourlyDataModel(date: item['date'], data: hourlyDataMap);
          }).toList();
        }
      }
    } catch (error) {
      debugPrint('Error fetching sensor hourly data: $error');
    }

    // Stale response guard: if the user picked another date while this
    // request was in flight, `_requestId` has moved on — drop this result
    // instead of applying outdated data over a newer request's data.
    if (!mounted || myRequestId != _requestId) return;

    setState(() {
      sensors = fetched;
      isInitialLoading = false;
      isRefreshing = false;
    });
  }

  bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Single shared calendar widget. Only one instance is ever built (in
  /// the popover header), instead of one per `_SensorSection`, so there is
  /// only ever one place that can trigger a date change.
  Widget buildSharedCalendar() {
    return TableCalendar(
      focusedDay: selectedDate,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      calendarFormat: CalendarFormat.week,
      availableCalendarFormats: const {CalendarFormat.week: 'Week'},
      selectedDayPredicate: (day) => _isSameDate(day, selectedDate),
      onDaySelected: isRefreshing ? null : (selectedDay, focusedDay) => _onDateSelected(selectedDay),
      enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColorLight, shape: BoxShape.circle),
        todayDecoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
        selectedTextStyle: const TextStyle(color: Colors.white),
        todayTextStyle: const TextStyle(color: Colors.black),
      ),
    );
  }
}

enum _GaugeType { moisture, temperature, pressure }

/// One section of the popover: a title, an optional chip selector when
/// there's more than one sensor of this type, a live gauge, a shared
/// calendar, and a chart.
///
/// Works generically across MoistureSensor / SoilTemperature / PressureSensor
/// models as long as each exposes `.sNo`, `.name`, and `.value`.
class _SensorSection extends StatefulWidget {
  final String title;
  final List<dynamic> sensors;
  final String unitParam;
  final List<SensorHourlyDataModel> sensorData;
  final double gaugeMax;
  final _GaugeType gaugeType;
  final DateTime selectedDate;
  final bool isBusy;
  final ValueChanged<DateTime> onDateSelected;

  const _SensorSection({
    super.key,
    required this.title,
    required this.sensors,
    required this.unitParam,
    required this.sensorData,
    required this.gaugeMax,
    required this.gaugeType,
    required this.selectedDate,
    required this.isBusy,
    required this.onDateSelected,
  });

  @override
  State<_SensorSection> createState() => _SensorSectionState();
}

class _SensorSectionState extends State<_SensorSection> {
  late String selectedSNo;

  @override
  void initState() {
    super.initState();
    selectedSNo = widget.sensors.first.sNo.toString();
  }

  Color _colorFor(double value) {
    switch (widget.gaugeType) {
      case _GaugeType.pressure:
        if (value <= 10) return Colors.red;
        if (value <= 20) return Colors.orange;
        return Colors.green;
      case _GaugeType.moisture:
      case _GaugeType.temperature:
        return Colors.black87;
    }
  }

  bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    dynamic selected = widget.sensors.first;
    for (final s in widget.sensors) {
      if (s.sNo.toString() == selectedSNo) {
        selected = s;
        break;
      }
    }

    // Live MQTT update for the currently selected sensor in this section.
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getSensorUpdatedValve(selected.sNo.toString()),
      builder: (_, status, __) {
        final statusParts = status?.split(',') ?? [];
        if (statusParts.length > 1) {
          selected.value = statusParts[1];
        }

        final chartData = _getSensorDataById(selected.sNo.toString(), widget.sensorData);
        final numericValue = double.tryParse(selected.value.toString()) ?? 0.0;
        final gaugeColor = _colorFor(numericValue);

        final series = <CartesianSeries<dynamic, String>>[
          LineSeries<SensorHourlyData, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data.hour,
            yValueMapper: (data, _) => double.tryParse(data.value.toString()) ?? 0.0,
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
                  widget.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
              ),

              // Chip selector — only when this valve has more than one
              // sensor of this type.
              if (widget.sensors.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.sensors.map<Widget>((s) {
                      final isSelected = s.sNo.toString() == selectedSNo;
                      return ChoiceChip(
                        label: Text(
                          s.name,
                          style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87),
                        ),
                        selected: isSelected,
                        selectedColor: Theme.of(context).primaryColor,
                        onSelected: (_) => setState(() => selectedSNo = s.sNo.toString()),
                      );
                    }).toList(),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
                child: Text(
                  selected.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),

              Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: SfRadialGauge(
                      key: ValueKey('gauge-${selected.sNo}'),
                      axes: [
                        RadialAxis(
                          minimum: 0,
                          maximum: widget.gaugeMax,
                          pointers: <GaugePointer>[
                            NeedlePointer(value: numericValue, needleEndWidth: 3, needleColor: Colors.black54),
                          ],
                          showFirstLabel: false,
                          axisLabelStyle: const GaugeTextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                          annotations: [
                            GaugeAnnotation(
                              widget: Text(
                                MyFunction().getUnitByParameter(context, widget.unitParam, selected.value.toString()) ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: gaugeColor),
                              ),
                              angle: 90,
                              positionFactor: 0.8,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(width: 1, height: 110, color: Colors.black12),
                  ),
                  // Read-only mini calendar preview for this section, kept
                  // in sync with the single shared date owned by the
                  // parent popover. Tapping it delegates to the parent via
                  // onDateSelected instead of each section owning its own
                  // TableCalendar/ScrollController-affecting state.
                  SizedBox(
                    width: 415,
                    height: 132,
                    child: IgnorePointer(
                      ignoring: widget.isBusy,
                      child: Opacity(
                        opacity: widget.isBusy ? 0.5 : 1,
                        child: TableCalendar(
                          focusedDay: widget.selectedDate,
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          calendarFormat: CalendarFormat.week,
                          availableCalendarFormats: const {CalendarFormat.week: 'Week'},
                          selectedDayPredicate: (day) => _isSameDate(day, widget.selectedDate),
                          onDaySelected: (selectedDay, focusedDay) => widget.onDateSelected(selectedDay),
                          enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
                          calendarStyle: CalendarStyle(
                            selectedDecoration: BoxDecoration(
                              color: Theme.of(context).primaryColorLight,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                            selectedTextStyle: const TextStyle(color: Colors.white),
                            todayTextStyle: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 550,
                height: 175,
                child: SfCartesianChart(
                  key: ValueKey('chart-${selected.sNo}'),
                  primaryXAxis: CategoryAxis(
                    title: AxisTitle(text: selected.name, textStyle: const TextStyle(fontSize: 12)),
                  ),
                  tooltipBehavior: TooltipBehavior(enable: true),
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

  List<SensorHourlyData> _getSensorDataById(String sensorId, List<SensorHourlyDataModel> sensorData) {
    final result = <SensorHourlyData>[];
    for (final model in sensorData) {
      model.data.forEach((hour, sensorList) {
        result.addAll(sensorList.where((sensor) => sensor.sensorId == sensorId));
      });
    }
    return result;
  }
}