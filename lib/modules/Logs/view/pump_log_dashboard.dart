import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:oro_drip_irrigation/Constants/constants.dart';
import 'package:oro_drip_irrigation/models/customer/site_model.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:oro_drip_irrigation/modules/PumpController/state_management/pump_controller_provider.dart';
import 'package:oro_drip_irrigation/modules/Logs/model/event_log_model.dart';
import 'package:oro_drip_irrigation/modules/Logs/model/motor_data_hourly.dart';
import 'package:oro_drip_irrigation/modules/Logs/view/valve_log.dart';
import 'package:oro_drip_irrigation/modules/Preferences/widgets/custom_segmented_control.dart';
import 'pump_log_excel_builder.dart';
import 'pump_log_excel_download_stub.dart'
if (dart.library.html) 'pump_log_excel_download_web.dart';

// ---------------------------------------------------------------------------
class _BarSegment {
  final double ratio;
  final Color color;
  const _BarSegment(this.ratio, this.color);
}

// Design tokens
// ---------------------------------------------------------------------------
const Color _kBg = Color(0xFFF7F9FA);
const Color _kTeal = Color(0xFF006775);
const Color _kBorder = Color(0xFFE5E9EB);
const Color _kRed = Color(0xFFE53935);
const Color _kGreen = Color(0xFF2E9E57);
const Color _kInk = Color(0xFF1E293B);
const Color _kMuted = Color(0xFF8C98A4);
const Color _kToggleBg = Color(0xFFE3F1F3);

/// Single-page unified dashboard for Pump Log, Power Graph, and Voltage Log.
class PumpLogDashboardScreen extends StatefulWidget {
  final int userId;
  final int controllerId;
  final int nodeControllerId;
  final MasterControllerModel masterData;
  final List pumpList;
  final Map<String, dynamic> userData;

  const PumpLogDashboardScreen({
    super.key,
    required this.userId,
    required this.controllerId,
    this.nodeControllerId = 0,
    required this.masterData,
    this.pumpList = const [],
    this.userData = const {},
    required bool showMobileCalendar,
  });

  @override
  State<PumpLogDashboardScreen> createState() => _PumpLogDashboardScreenState();
}

class _PumpLogDashboardScreenState extends State<PumpLogDashboardScreen> with WidgetsBindingObserver {
  static const bool _showSingleDeviceHeader = true;

  /// How often live data is re-fetched while the dashboard is visible.
  static const Duration _kAutoRefreshInterval = Duration(seconds: 15);

  Timer? _autoRefreshTimer;
  bool _silentBusy = false;
  int _fetchGeneration = 0;

  late DateTime _selectedDate;
  late DateTime _weekStartDate;

  int _selectedPumpIndex = 0;
  int _activeNodeControllerId = 0;

  // Power Graph state
  int _powerPeriodIndex = 0; // 0: Daily, 1: Weekly, 2: Monthly
  int _selectedMotorIndex = 0;
  bool _userChangedMotor = false;

  // Voltage Log state
  int _voltageMetricIndex = 0; // 0: Voltage, 1: Current

  bool _isLoading = false;

  bool get isSinglePhaseModel {
    final int modelId = widget.masterData.modelId;
    return AppConstants.singlePhasePumpModel.contains(modelId) ||
        AppConstants.singlePhasePumpPlusModel.contains(modelId) ||
        AppConstants.singlePhaseShineModel.contains(modelId) ||
        AppConstants.singlePhaseElitePlusModel.contains(modelId) ||
        AppConstants.singlePhaseEcoGemModel.contains(modelId) ||
        AppConstants.singlePhaseEcoGemPlusModel.contains(modelId);
  }

  String get currentDeviceId {
    if (AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId)) {
      return widget.masterData.deviceId;
    }
    final devices = effectiveDeviceList;
    if (devices.isNotEmpty && _selectedPumpIndex < devices.length) {
      final item = devices[_selectedPumpIndex];
      final deviceId = item['deviceId']?.toString();
      if (deviceId != null && deviceId.isNotEmpty) return deviceId;
    }
    return widget.masterData.deviceId;
  }

  String get currentDeviceName {
    if (AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId)) {
      return widget.masterData.deviceName;
    }
    final devices = effectiveDeviceList;
    if (devices.isNotEmpty && _selectedPumpIndex < devices.length) {
      final item = devices[_selectedPumpIndex];
      final deviceName = item['deviceName']?.toString();
      if (deviceName != null && deviceName.isNotEmpty) return deviceName;
    }
    return widget.masterData.deviceName;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _alignWeekStartDate(_selectedDate);

    final devices = effectiveDeviceList;
    if (devices.isNotEmpty) {
      final isEcoGem = AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId);
      _activeNodeControllerId = isEcoGem ? 0 : (devices[0]['controllerId'] ?? widget.nodeControllerId);
    } else {
      _activeNodeControllerId = widget.nodeControllerId;
    }

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllData();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _silentRefresh(); // catch up immediately after coming back to the app
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_kAutoRefreshInterval, (_) => _silentRefresh());
  }

  bool _isTodaySelected() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  /// Background refresh: no spinner, no flicker, existing data stays on screen until
  /// the new data is ready. Skipped while a manual load is running or the tab is hidden.
  Future<void> _silentRefresh() async {
    if (!mounted || _isLoading || _silentBusy) return;
    if (!TickerMode.of(context)) return;

    final bool today = _isTodaySelected();
    // Weekly / monthly power totals always end at "now", so they stay live too.
    if (!today && _powerPeriodIndex == 0) return;

    _silentBusy = true;
    try {
      final provider = context.read<PumpControllerProvider>();
      provider.selectedDate = _selectedDate;
      await Future.wait([
        provider.getPumpControllerData(
          userId: widget.userId,
          controllerId: widget.controllerId,
          nodeControllerId: _activeNodeControllerId,
          selectedIndex: _powerPeriodIndex,
          silent: true,
        ),
        if (today)
          provider.getUserPumpLog(
            widget.userId,
            widget.controllerId,
            _activeNodeControllerId,
            widget.masterData,
            true,
          ),
        if (today)
          provider.getUserVoltageLog(
            userId: widget.userId,
            controllerId: widget.controllerId,
            nodeControllerId: _activeNodeControllerId,
            silent: true,
          ),
      ]);
    } catch (e) {
      log("Silent refresh error: $e");
    } finally {
      _silentBusy = false;
    }
  }

  @override
  void didUpdateWidget(covariant PumpLogDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = widget.controllerId != oldWidget.controllerId ||
        widget.masterData.controllerId != oldWidget.masterData.controllerId;
    final pumpListChanged = widget.pumpList != oldWidget.pumpList;

    if (controllerChanged || pumpListChanged) {
      _selectedPumpIndex = 0;
      final devices = effectiveDeviceList;
      if (devices.isNotEmpty) {
        final isEcoGem = AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId);
        _activeNodeControllerId = isEcoGem ? 0 : (devices[0]['controllerId'] ?? widget.nodeControllerId);
      } else {
        _activeNodeControllerId = widget.nodeControllerId;
      }
      _fetchAllData();
    }
  }

  void _alignWeekStartDate(DateTime date) {
    // Week starting on Sunday
    final int diff = date.weekday % 7;
    _weekStartDate = DateTime(date.year, date.month, date.day).subtract(Duration(days: diff));
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
    final int generation = ++_fetchGeneration;
    setState(() => _isLoading = true);

    final provider = context.read<PumpControllerProvider>();
    provider.selectedDate = _selectedDate;

    try {
      await Future.wait([
        provider.getPumpControllerData(
          userId: widget.userId,
          controllerId: widget.controllerId,
          nodeControllerId: _activeNodeControllerId,
          selectedIndex: _powerPeriodIndex,
        ),
        provider.getUserPumpLog(
          widget.userId,
          widget.controllerId,
          _activeNodeControllerId,
          widget.masterData,
        ),
        provider.getUserVoltageLog(
          userId: widget.userId,
          controllerId: widget.controllerId,
          nodeControllerId: _activeNodeControllerId,
        ),
      ]);

      if (mounted && generation == _fetchGeneration) {
        final effective = getEffectiveSegments(provider);
        if (!_userChangedMotor) {
          if (effective.containsKey(provider.selectedIndex)) {
            _selectedMotorIndex = provider.selectedIndex;
          } else if (effective.isNotEmpty) {
            _selectedMotorIndex = effective.keys.first;
          }
        } else if (!effective.containsKey(_selectedMotorIndex)) {
          if (effective.containsKey(provider.selectedIndex)) {
            _selectedMotorIndex = provider.selectedIndex;
          } else if (effective.isNotEmpty) {
            _selectedMotorIndex = effective.keys.first;
          }
        }
      }
    } catch (e) {
      log("Error fetching pump dashboard data: $e");
    } finally {
      // Only the most recent load may turn the spinner off.
      if (mounted && generation == _fetchGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _alignWeekStartDate(date);
    });
    _fetchAllData();
  }

  bool _isFuture(DateTime d) {
    final now = DateTime.now();
    return DateTime(d.year, d.month, d.day).isAfter(DateTime(now.year, now.month, now.day));
  }

  bool get _canGoNextWeek => !_isFuture(_weekStartDate.add(const Duration(days: 7)));

  void _changeWeek(int deltaWeeks) {
    final newStart = _weekStartDate.add(Duration(days: deltaWeeks * 7));
    if (_isFuture(newStart)) return;

    final today = DateTime.now();
    final newEnd = newStart.add(const Duration(days: 6));
    final todayInWeek = !_isFuture(newStart) &&
        !DateTime(today.year, today.month, today.day).isAfter(DateTime(newEnd.year, newEnd.month, newEnd.day));

    setState(() {
      _weekStartDate = newStart;
      _selectedDate = todayInWeek ? today : newStart;
    });
    _fetchAllData();
  }

  void _showNoLogSnack() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('No logs yet — this date is in the future.'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _goToPrevDay() {
    _onDateSelected(_selectedDate.subtract(const Duration(days: 1)));
  }

  void _goToNextDay() {
    final next = _selectedDate.add(const Duration(days: 1));
    if (!_isFuture(next)) {
      _onDateSelected(next);
    }
  }

  void _pickMonth() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _isFuture(_selectedDate) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      _onDateSelected(picked);
    }
  }

  Future<void> _exportReport(String format) async {
    final provider = context.read<PumpControllerProvider>();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final periodStr = _powerPeriodIndex == 1
        ? 'Weekly'
        : (_powerPeriodIndex == 2 ? 'Monthly' : 'Daily');

    final segments = getEffectiveSegments(provider);

    List<EventLog> motor1Events = [];
    List<EventLog> motor2Events = [];
    List<EventLog> motor3Events = [];

    if (provider.pumpLogData.isNotEmpty) {
      final logData = provider.pumpLogData[0];
      motor1Events = logData.motor1;
      motor2Events = logData.motor2;
      motor3Events = logData.motor3;
    }

    final exportData = PumpLogExportData(
      deviceName: currentDeviceName,
      deviceId: currentDeviceId,
      dateStr: dateStr,
      periodStr: periodStr,
      segments: segments,
      motor1Events: motor1Events,
      motor2Events: motor2Events,
      motor3Events: motor3Events,
      voltageData: provider.voltageData,
      motorData: provider.motorDataList.isNotEmpty ? provider.motorDataList[0] : null,
    );

    final String sanitizedDeviceName = currentDeviceName.replaceAll(RegExp(r'[^\w\s\-]'), '_');
    final String fileName = 'Pump_Log_${sanitizedDeviceName}_$dateStr';

    final label = format == 'pdf' ? 'PDF' : (format == 'csv' ? 'CSV' : 'Excel');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Generating $label report...'),
          duration: const Duration(seconds: 2),
        ),
      );

    bool success = false;
    if (format == 'pdf') {
      success = await generatePumpLogPDF(exportData, fileName);
    } else if (format == 'csv') {
      success = await generatePumpLogCSV(exportData, fileName);
    } else {
      success = await generatePumpLogExcel(exportData, fileName);
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '$label report downloaded successfully!'
                  : 'Failed to download $label report.',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: success ? _kTeal : _kRed,
          ),
        );
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================

  String _formatTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty || rawTime == '-' || rawTime == '0' || rawTime == 'null') {
      return '00:00';
    }
    final parts = rawTime.trim().split(':');
    if (parts.length >= 3) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    } else if (parts.length == 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return rawTime;
  }

  /// Parses "HH:MM" or "HH:MM:SS" into seconds.
  int _toSeconds(String t) {
    final p = t.split(':').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    if (p.length >= 3) return p[0] * 3600 + p[1] * 60 + p[2];
    if (p.length == 2) return p[0] * 3600 + p[1] * 60;
    return 0;
  }

  /// Safely parses a numeric string coming from the API ("1,234", "-", "", null).
  double? _parseNumber(String? v) {
    if (v == null) return null;
    final cleaned = v.trim().replaceAll(',', '');
    if (cleaned.isEmpty || cleaned == '-' || cleaned.toLowerCase() == 'null') return null;
    return double.tryParse(cleaned);
  }

  /// Flow rate resolution:
  ///  1. If the device gives a valid live flow rate (> 0) -> show it as real time.
  ///  2. Otherwise -> average flow rate = total flow (litres) / motor run time (seconds).
  /// Works the same for Daily / Weekly / Monthly because [totalFlow] and
  /// [motorRunTime] already belong to the selected period.
  ({String value, bool isAverage}) _resolveFlowRate({
    required String? liveFlowRate,
    required String totalFlow,
    required String motorRunTime,
  }) {
    final live = _parseNumber(liveFlowRate);
    if (live != null && live > 0) {
      return (value: live.toString(), isAverage: false);
    }

    final totalLitres = _parseNumber(totalFlow) ?? 0.0;
    final runSeconds = _toSeconds(motorRunTime);

    if (runSeconds <= 0 || totalLitres <= 0) {
      return (value: '0.0', isAverage: true);
    }

    final avg = totalLitres / runSeconds; // litres per second (Lps)
    return (value: avg.toStringAsFixed(2), isAverage: true);
  }

  String _pick(int key, String m1, String m2, String m3) => key == 1 ? m2 : (key == 2 ? m3 : m1);

  int _activeKeyFor(PumpControllerProvider provider, Map<int, String> segments) {
    if (segments.containsKey(_selectedMotorIndex)) return _selectedMotorIndex;
    if (segments.containsKey(provider.selectedIndex)) return provider.selectedIndex;
    return segments.isNotEmpty ? segments.keys.first : 0;
  }

  void _onMotorChanged(PumpControllerProvider provider, int newVal) {
    setState(() {
      _userChangedMotor = true;
      _selectedMotorIndex = newVal;
      provider.selectedIndex = newVal;
    });
  }

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(18)}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      padding: padding,
      child: child,
    );
  }

  Widget _cardTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _kTeal,
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 1.1,
      ),
    );
  }

  /// Light-teal pill toggle (Daily/Weekly/Monthly and Voltage/Current).
  Widget _buildToggle({
    required List<String> labels,
    required int selected,
    required ValueChanged<int> onChanged,
    double hPad = 14,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _kToggleBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isSel = i == selected;
          return InkWell(
            onTap: () => onChanged(i),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? _kInk : _kTeal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PumpControllerProvider>();

    return KeyedSubtree(
      key: ValueKey(widget.controllerId),
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Column(
                children: [
                  // Edge-to-edge calendar bar
                  _buildCalendarHeader(isWide),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchAllData,
                      color: _kTeal,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDeviceHeader(),
                            _buildPumpSegmentControl(provider),

                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: LinearProgressIndicator(
                                  color: _kTeal,
                                  backgroundColor: Color(0xFFE0F4F7),
                                ),
                              ),

                            _buildPowerGraphCard(provider, isWide),
                            const SizedBox(height: 12),

                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildPumpLogCard(provider)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildVoltageLogCard(provider)),
                                ],
                              )
                            else ...[
                              _buildPumpLogCard(provider),
                              const SizedBox(height: 12),
                              _buildVoltageLogCard(provider),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get effectiveDeviceList {
    if (AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId)) {
      return [
        {
          'deviceName': widget.masterData.deviceName,
          'deviceId': widget.masterData.deviceId,
          'controllerId': 0,
        }
      ];
    }
    if (widget.pumpList.isNotEmpty) {
      return widget.pumpList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (widget.masterData.nodeList.isNotEmpty) {
      final pumpNodes = widget.masterData.nodeList.where((n) {
        return AppConstants.pumpList.contains(n.modelId) ||
            n.categoryId == 1 ||
            n.categoryName.toLowerCase().contains('pump');
      }).toList();

      final nodesToUse = pumpNodes.isNotEmpty ? pumpNodes : widget.masterData.nodeList;
      return nodesToUse.map((n) => {
        'deviceName': n.deviceName.isNotEmpty ? n.deviceName : 'Node ${n.serialNumber}',
        'deviceId': n.deviceId,
        'controllerId': n.controllerId,
      }).toList();
    }
    return [
      {
        'deviceName': widget.masterData.deviceName,
        'deviceId': widget.masterData.deviceId,
        'controllerId': 0,
      }
    ];
  }

  Map<int, String> getEffectiveSegments(PumpControllerProvider provider) {
    final int apiPumps = provider.motorDataList.isNotEmpty ? provider.motorDataList[0].numberOfPumps : 1;

    if (provider.segments.length >= apiPumps && provider.segments.length > 1) {
      return provider.segments;
    }

    final pumpNames = provider.getPumpNames(widget.masterData, _activeNodeControllerId, widget.controllerId);

    final targetControllerId = _activeNodeControllerId != 0 ? _activeNodeControllerId : widget.controllerId;
    var targetPumps = widget.masterData.configObjects
        .where((e) => e.objectId == 5 && (e.controllerId == targetControllerId || targetControllerId == 0))
        .toList();

    if (targetPumps.isEmpty) {
      targetPumps = widget.masterData.configObjects.where((e) => e.objectId == 5).toList();
    }

    int effectiveCount = apiPumps;
    if (targetPumps.isNotEmpty && targetPumps.length > effectiveCount) {
      effectiveCount = targetPumps.length;
    }
    if (provider.segments.length > effectiveCount) {
      effectiveCount = provider.segments.length;
    }

    if (effectiveCount > 1) {
      final Map<int, String> segs = {};
      for (int i = 0; i < effectiveCount && i < 3; i++) {
        segs[i] = (pumpNames.length > i && pumpNames[i].isNotEmpty)
            ? pumpNames[i]
            : "Motor ${i + 1}";
      }
      return segs;
    }

    if (provider.segments.isNotEmpty) {
      return provider.segments;
    }

    return {0: pumpNames.isNotEmpty ? pumpNames[0] : "Motor 1"};
  }

  // ==========================================
  // CALENDAR BAR (edge to edge)
  // ==========================================
  Widget _buildCalendarHeader(bool isWide) {
    final monthLabel = DateFormat('MMMM yyyy').format(_weekStartDate.add(const Duration(days: 3)));
    final daysOfWeek = List.generate(7, (i) => _weekStartDate.add(Duration(days: i)));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: isWide
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMonthNavigator(monthLabel),
          _buildWeekDayStrip(daysOfWeek),
        ],
      )
          : Column(
        children: [
          _buildMonthNavigator(monthLabel),
          const SizedBox(height: 8),
          _buildWeekDayStrip(daysOfWeek),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator(String monthLabel) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black54, size: 20),
          onPressed: () => _changeWeek(-1),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          monthLabel,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kInk),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _pickMonth,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Month',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: _canGoNextWeek ? Colors.black54 : Colors.black26,
            size: 20,
          ),
          onPressed: _canGoNextWeek ? () => _changeWeek(1) : null,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 6),
        PopupMenuButton<String>(
          tooltip: 'Download Report',
          onSelected: (val) => _exportReport(val),
          offset: const Offset(0, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'excel',
              child: Row(
                children: [
                  Icon(Icons.table_chart_outlined, color: _kTeal, size: 18),
                  SizedBox(width: 8),
                  Text('Excel (.xlsx)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'csv',
              child: Row(
                children: [
                  Icon(Icons.description_outlined, color: _kTeal, size: 18),
                  SizedBox(width: 8),
                  Text('CSV (.csv)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, color: _kRed, size: 18),
                  SizedBox(width: 8),
                  Text('PDF (.pdf)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kTeal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Download',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.white, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDayStrip(List<DateTime> days) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: days.map((day) {
        final isSelected = day.year == _selectedDate.year &&
            day.month == _selectedDate.month &&
            day.day == _selectedDate.day;
        final dayName = DateFormat('E').format(day);
        final isFutureDay = _isFuture(day);

        return InkWell(
          onTap: isFutureDay ? _showNoLogSnack : () => _onDateSelected(day),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isFutureDay
                        ? const Color(0xFFCBD5E1)
                        : (isSelected ? _kInk : _kMuted),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected ? _kTeal : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isFutureDay ? const Color(0xFFCBD5E1) : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // DEVICE SELECTOR / MAC
  // ==========================================
  Widget _buildDeviceHeader() {
    final devices = effectiveDeviceList;
    if (devices.isEmpty) return const SizedBox.shrink();

    if (devices.length > 1) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(devices.length, (index) {
              final pumpItem = devices[index];
              final isSelected = _selectedPumpIndex == index;
              final name = pumpItem['deviceName'] ?? 'Device ${index + 1}';
              final deviceId = pumpItem['deviceId']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPumpIndex = index;
                      _activeNodeControllerId = pumpItem['controllerId'] ?? 0;
                    });
                    _fetchAllData();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _kTeal : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _kTeal : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.white.withAlpha(50) : const Color(0xFFE0F4F7),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : _kTeal,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$name',
                              style: TextStyle(
                                color: isSelected ? Colors.white : _kInk,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (deviceId.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'MAC: $deviceId',
                                style: TextStyle(
                                  color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    }

    if (!_showSingleDeviceHeader) return const SizedBox.shrink();

    final deviceName = currentDeviceName;
    final deviceId = currentDeviceId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _card(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0F4F7)),
              child: const Center(child: Icon(Icons.router_outlined, color: _kTeal, size: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kInk),
                  ),
                  if (deviceId.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'MAC: $deviceId',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: _kTeal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Only shown when the controller has more than one pump/motor.
  Widget _buildPumpSegmentControl(PumpControllerProvider provider) {
    final segments = getEffectiveSegments(provider);
    if (segments.length <= 1) return const SizedBox.shrink();

    final activeKey = _activeKeyFor(provider, segments);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CustomSegmentedControl(
            segmentTitles: segments,
            groupValue: activeKey,
            onChanged: (newValue) {
              if (newValue != null) _onMotorChanged(provider, newValue);
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CARD 1: POWER GRAPH (Redesigned Breakdown View)
  // ==========================================
  Widget _buildPowerGraphCard(PumpControllerProvider provider, bool isWide) {
    final MotorDataHourly? motorData =
    provider.motorDataList.isNotEmpty ? provider.motorDataList[0] : null;

    final segments = getEffectiveSegments(provider);
    final activeKey = _activeKeyFor(provider, segments);

    final String motorRunTime = motorData != null
        ? _pick(activeKey, motorData.motorRunTime1, motorData.motorRunTime2, motorData.motorRunTime3)
        : "00:00:00";
    final String motorIdleTime = motorData != null
        ? _pick(activeKey, motorData.motorIdleTime1, motorData.motorIdleTime2, motorData.motorIdleTime3)
        : "00:00:00";
    final String dryRunTripTime = motorData != null
        ? _pick(activeKey, motorData.dryRunTripTime1, motorData.dryRunTripTime2, motorData.dryRunTripTime3)
        : "00:00:00";
    final String cyclicTripTime = motorData != null
        ? _pick(activeKey, motorData.cyclicTripTime1, motorData.cyclicTripTime2, motorData.cyclicTripTime3)
        : "00:00:00";
    final String otherTripTime = motorData != null
        ? _pick(activeKey, motorData.otherTripTime1, motorData.otherTripTime2, motorData.otherTripTime3)
        : "00:00:00";
    final String totalFlowToday = motorData != null
        ? _pick(activeKey, motorData.totalFlowToday1, motorData.totalFlowToday2, motorData.totalFlowToday3)
        : "0";

    final String totalPowerOnTime = motorData?.totalPowerOnTime ?? "00:00:00";
    final String totalPowerOffTime = motorData?.totalPowerOffTime ?? "00:00:00";

    final int daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final int maxSeconds = _powerPeriodIndex == 1
        ? (7 * 24 * 3600)
        : (_powerPeriodIndex == 2
        ? (daysInMonth * 24 * 3600)
        : (24 * 3600));

    final double totalPowerRatio = (_toSeconds(totalPowerOnTime) / maxSeconds).clamp(0.0, 1.0);
    final double motorRatio = (_toSeconds(motorRunTime) / maxSeconds).clamp(0.0, 1.0);

    final String activeMotorName =
        segments[activeKey] ?? _pick(activeKey, "Motor 1", "Motor 2", "Motor 3");

    final leftColumn = _buildNewPowerGraphLeft(
      totalPowerOnTime: totalPowerOnTime,
      totalPowerOffTime: totalPowerOffTime,
      motorRunTime: motorRunTime,
      totalPowerRatio: totalPowerRatio,
      motorRatio: motorRatio,
      activeMotorName: activeMotorName,
      daysInMonth: daysInMonth,
    );

    final centerMetrics = _buildNewPowerGraphCenter(
      motorData: motorData,
      totalFlow: totalFlowToday,
      motorRunTime: motorRunTime,
    );

    final rightBreakdown = _buildNewPowerGraphRight(
      provider: provider,
      runTime: motorRunTime,
      idleTime: motorIdleTime,
      dryRunTime: dryRunTripTime,
      cyclicTime: cyclicTripTime,
      otherTime: otherTripTime,
      totalPowerOnTime: totalPowerOnTime,
      segments: segments,
      activeKey: activeKey,
      activeMotorName: activeMotorName,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF2F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: isWide
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: leftColumn),
          const SizedBox(width: 18),
          Expanded(flex: 8, child: centerMetrics),
          const SizedBox(width: 22),
          Expanded(flex: 7, child: rightBreakdown),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftColumn,
          const SizedBox(height: 20),
          centerMetrics,
          const SizedBox(height: 20),
          rightBreakdown,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LEFT COLUMN: Date, Daily/Weekly/Monthly, Date Picker bar, 24-hr Bars
  // ---------------------------------------------------------------------------
  Widget _buildNewPowerGraphLeft({
    required String totalPowerOnTime,
    required String totalPowerOffTime,
    required String motorRunTime,
    required double totalPowerRatio,
    required double motorRatio,
    required String activeMotorName,
    required int daysInMonth,
  }) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    final String daySubtitle = DateFormat('EEEE').format(_selectedDate);
    final String formattedDate = DateFormat ('EEEE, MMMM d').format(_selectedDate);

    final List<String> tickLabels = _powerPeriodIndex == 1
        ? const ['Day 1', 'Day 3', 'Day 5', 'Day 7']
        : (_powerPeriodIndex == 2
        ? ['Day 1', 'Day 10', 'Day 20', 'Day $daysInMonth']
        : const ['00:00', '08:00', '16:00', '24:00']);

    final String formattedDateBanner = _powerPeriodIndex == 1
        ? '${DateFormat('MMM d').format(_weekStartDate)} - ${DateFormat('MMM d, yyyy').format(_weekStartDate.add(const Duration(days: 6)))}'
        : (_powerPeriodIndex == 2
        ? DateFormat('MMMM yyyy').format(_selectedDate)
        : DateFormat('MMM d, yyyy').format(_selectedDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          daySubtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8C98A4),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formattedDate,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),

        _buildPillToggle(
          labels: const ['Daily', 'Weekly', 'Monthly'],
          selected: _powerPeriodIndex,
          onChanged: (i) {
            setState(() => _powerPeriodIndex = i);
            _fetchAllData();
          },
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDF2F4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _goToPrevDay,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.chevron_left, size: 20, color: Color(0xFF64748B)),
                ),
              ),
              InkWell(
                onTap: _pickMonth,
                child: Text(
                  formattedDateBanner,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              InkWell(
                onTap: _isFuture(_selectedDate.add(const Duration(days: 1))) ? null : _goToNextDay,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: _isFuture(_selectedDate.add(const Duration(days: 1)))
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDF2F4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _powerPeriodIndex == 1
                    ? 'Duration across the 7-day week'
                    : (_powerPeriodIndex == 2
                    ? 'Duration across the month'
                    : 'Duration across the 24-hour day'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8C98A4),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tickLabels
                    .map((t) => Text(t, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))))
                    .toList(),
              ),
              const SizedBox(height: 10),

              _buildDurationRowBar(
                ratio: motorRatio,
                label: '$activeMotorName run time  ${_formatTime(motorRunTime)} HH:MM',
                fillColor: const Color(0xFF22C55E),
                trackColor: const Color(0xFFE2E8F0), textColor: Colors.black,
              ),
              const SizedBox(height: 8),

              _buildDurationRowBar(
                ratio: totalPowerRatio,
                label: 'Total power  ${_formatTime(totalPowerOnTime)} HH:MM',
                fillColor: const Color(0xFF2563EB),
                trackColor: const Color(0xFFE2E8F0),
                textColor: Colors.black,
              ),
              const SizedBox(height: 8),

              _buildFullColorBar(
                label: 'Total power off Time· ${_formatTime(totalPowerOffTime)} HH:MM',
                bgColor: const Color(0xFFFFECEE),
                textColor: const Color(0xFFDC2626),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillToggle({
    required List<String> labels,
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isSel = i == selected;
          return InkWell(
            onTap: () => onChanged(i),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF1E293B) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDurationRowBar({
    required double ratio,
    required String label,
    required Color fillColor,
    Color trackColor = const Color(0xFFE2E8F0),
    Color textColor = Colors.black,
  }) {
    final clampedRatio = ratio.clamp(0.0, 1.0);
    return Container(
      height: 34,
      width: double.infinity,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (clampedRatio > 0)
            FractionallySizedBox(
              widthFactor: clampedRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          Positioned.fill(
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullColorBar({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      height: 34,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CENTER COLUMN: Metrics Grid
  // ---------------------------------------------------------------------------
  Widget _buildNewPowerGraphCenter({
    required MotorDataHourly? motorData,
    required String totalFlow,
    required String motorRunTime,
  }) {
    String clean(String? v) => (v != null && v != "-" && v.isNotEmpty) ? v : "0.0";

    final flow = _resolveFlowRate(
      liveFlowRate: motorData?.flowRate,
      totalFlow: totalFlow,
      motorRunTime: motorRunTime,
    );

    final String flowVal = (totalFlow.isNotEmpty && totalFlow != '-') ? totalFlow : "0";
    final bool hasNoFlowToday = _toSeconds(motorRunTime) == 0 || flowVal == "0";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Pressure',
                value: clean(motorData?.pressure),
                unit: 'bar',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: flow.isAverage ? 'Avg flow rate' : 'Flow rate',
                value: flow.value,
                unit: 'Lps',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Level',
                value: clean(motorData?.level),
                unit: 'feet',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildFlowTile(
                title: 'Cumulative flow',
                value: motorData?.overAllCumulativeFlow ?? "0",
                unit: 'Litres',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFlowTile(
                title: _powerPeriodIndex == 1
                    ? 'Total flow this week'
                    : (_powerPeriodIndex == 2 ? 'Total flow this month' : 'Total flow today'),
                value: flowVal,
                unit: 'Litres',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF2F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8C98A4), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowTile({
    required String title,
    required String value,
    required String unit,
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF2F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RIGHT COLUMN: Motor time breakdown, multi-colored bar, dot list
  // ---------------------------------------------------------------------------
  Widget _buildNewPowerGraphRight({
    required PumpControllerProvider provider,
    required String runTime,
    required String idleTime,
    required String dryRunTime,
    required String cyclicTime,
    required String otherTime,
    required String totalPowerOnTime,
    required Map<int, String> segments,
    required int activeKey,
    required String activeMotorName,
  }) {
    final int runSec = _toSeconds(runTime);
    final int idleSec = _toSeconds(idleTime);
    final int drySec = _toSeconds(dryRunTime);
    final int cyclicSec = _toSeconds(cyclicTime);
    final int otherSec = _toSeconds(otherTime);

    final int totalPowerSec = _toSeconds(totalPowerOnTime);
    final int sumCategorySec = runSec + idleSec + drySec + cyclicSec + otherSec;
    final int denominator = totalPowerSec > 0 ? totalPowerSec : (sumCategorySec > 0 ? sumCategorySec : 1);

    const colorRun = Color(0xFF22C55E); // Green
    const colorIdle = Color(0xFFF59E0B); // Orange / Amber
    const colorDry = Color(0xFFEF4444); // Red
    const colorCyclic = Color(0xFF3B82F6); // Blue
    const colorOther = Color(0xFF94A3B8); // Slate / Grey

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2),
                Text(
                  'Motor time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            if (segments.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isDense: true,
                    value: segments.containsKey(activeKey) ? activeKey : segments.keys.first,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    items: segments.entries
                        .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _onMotorChanged(provider, val);
                    },
                  ),
                ),
              )
            else
              Text(
                activeMotorName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
          ],
        ),
        const SizedBox(height: 12),

        _buildMultiSegmentBar(
          segments: [
            _BarSegment(runSec / denominator, colorRun),
            _BarSegment(idleSec / denominator, colorIdle),
            _BarSegment(cyclicSec / denominator, colorCyclic),
            _BarSegment(drySec / denominator, colorDry),
            _BarSegment(otherSec / denominator, colorOther),
          ],
        ),
        const SizedBox(height: 10),

        Text(
          'Share of ${_formatTime(totalPowerOnTime)} total power-on time (HH:MM)',
          style: const TextStyle(fontSize: 14, color: Color(0xFF000000), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),

        _buildBreakdownListItem('Motor run time', '${_formatTime(runTime)}  HH:MM', colorRun),
        _buildBreakdownListItem('Motor idle time', '${_formatTime(idleTime)}  HH:MM', colorIdle),
        _buildBreakdownListItem('Dry run trip time', '${_formatTime(dryRunTime)}  HH:MM', colorDry),
        _buildBreakdownListItem('Cyclic trip time', '${_formatTime(cyclicTime)}  HH:MM', colorCyclic),
        _buildBreakdownListItem('Other trip time', '${_formatTime(otherTime)}  HH:MM', colorOther, isLast: true),
      ],
    );
  }

  Widget _buildMultiSegmentBar({required List<_BarSegment> segments}) {
    return Container(
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: segments.map((s) {
          if (s.ratio <= 0) return const SizedBox.shrink();
          return Expanded(
            flex: (s.ratio * 1000).toInt().clamp(1, 1000),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: s.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBreakdownListItem(
      String label,
      String timeStr,
      Color dotColor, {
        bool isLast = false,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 2: PUMP LOG
  // ==========================================
  Widget _buildPumpLogCard(PumpControllerProvider provider) {
    final segments = getEffectiveSegments(provider);
    final activeKey = _activeKeyFor(provider, segments);

    List<EventLog> events = [];
    if (provider.pumpLogData.isNotEmpty) {
      final logData = provider.pumpLogData[0];
      events = activeKey == 1
          ? logData.motor2
          : activeKey == 2
          ? logData.motor3
          : logData.motor1;
    }

    final int dryRunTrips = events.where((e) => e.offReason.toLowerCase().contains('dry run')).length;

    // Total duration calculation for pump events
    Duration totalDuration = Duration.zero;
    for (final e in events) {
      try {
        totalDuration += Constants.parseTime(e.duration);
      } catch (_) {}
    }
    // ignore: unused_local_variable
    final formattedDuration = Constants.formatTime(totalDuration);

    final activeMotorName = segments[activeKey] ?? "Pump ${activeKey + 1}";

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('PUMP LOG'),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _buildSummaryBox('Entries', '${events.length}', _kInk)),
              const SizedBox(width: 8),
              Expanded(child: _buildSummaryBox('Dry run trips', '$dryRunTrips', _kRed)),
              const SizedBox(width: 8),

            ],
          ),
          const SizedBox(height: 16),

          _buildTimelineBar(events),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('08:00', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('16:00', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('24:00', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 12),

          if (events.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Text(
                provider.message.isNotEmpty
                    ? provider.message
                    : 'No pump events recorded for $activeMotorName on this date.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            )
          else if (AppConstants.pumpWithValveModelList.contains(widget.masterData.modelId) &&
              !AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId))
            ValveLog(
              events: events,
              masterData: widget.masterData,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFFF1F5F9), height: 1),
              itemBuilder: (context, index) => _buildEventItem(events[index], activeMotorName),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _kMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineBar(List<EventLog> events) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFE6EEEC),
        borderRadius: BorderRadius.circular(5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          const totalSeconds = 86400.0;

          return Stack(
            children: events.map((event) {
              final startSec = _toSeconds(event.onTime).toDouble();
              double endSec = 0;

              final cleanOff = event.offTime.trim();
              final hasOffTime = cleanOff.isNotEmpty && cleanOff != '-' && cleanOff != '00:00:00' && cleanOff != '0';

              if (hasOffTime) {
                endSec = _toSeconds(cleanOff).toDouble();
              } else {
                final durSec = _toSeconds(event.duration).toDouble();
                if (durSec > 0) {
                  endSec = startSec + durSec;
                } else {
                  final now = DateTime.now();
                  final isToday = _selectedDate.year == now.year &&
                      _selectedDate.month == now.month &&
                      _selectedDate.day == now.day;
                  if (isToday) {
                    endSec = (now.hour * 3600 + now.minute * 60 + now.second).toDouble();
                  } else {
                    endSec = startSec + 300;
                  }
                }
              }

              if (endSec < startSec) endSec = totalSeconds;

              final left = (startSec / totalSeconds * totalWidth).clamp(0.0, totalWidth);
              final width =
              ((endSec - startSec) / totalSeconds * totalWidth).clamp(2.0, totalWidth - left);
              final isDryRun = event.offReason.toLowerCase().contains('dry run');

              return Positioned(
                left: left,
                width: width,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: isDryRun
                      ? Align(
                    alignment: Alignment.centerRight,
                    child: Container(width: 2, color: _kRed),
                  )
                      : null,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _statusDot(Color color) {
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildEventItem(EventLog event, String motorName) {
    String formatReason(String reason) {
      if (reason.isEmpty) return reason;
      String formatted = reason;
      if (!motorName.toLowerCase().startsWith("motor")) {
        formatted = formatted.replaceAll(RegExp(r'motor[1-3]?', caseSensitive: false), motorName);
      }
      return Constants.capitalizeFirstLetter(formatted);
    }

    final cleanOff = event.offTime.trim();
    final hasOffTime = cleanOff.isNotEmpty && cleanOff != '-' && cleanOff != '00:00:00' && cleanOff != '0';
    final hasOnReason = event.onReason.trim().isNotEmpty;
    final hasOffReason = event.offReason.trim().isNotEmpty && event.offReason.trim() != '-';
    final isRunningNow = !hasOffTime && !hasOffReason;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.onTime,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _kTeal),
                ),
                if (hasOffTime) ...[
                  const Text('to', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                  Text(
                    event.offTime,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _kTeal),
                  ),
                ] else if (isRunningNow) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'RUNNING',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _kGreen),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasOnReason)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statusDot(_kGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatReason(event.onReason),
                          style: const TextStyle(fontSize: 12, color: _kInk),
                        ),
                      ),
                    ],
                  ),
                if (hasOnReason && hasOffReason) const SizedBox(height: 4),
                if (hasOffReason)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statusDot(_kRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatReason(event.offReason),
                          style: const TextStyle(fontSize: 12, color: _kInk),
                        ),
                      ),
                    ],
                  ),
                if (hasOnReason || hasOffReason) const SizedBox(height: 4),
                Text(
                  isRunningNow ? 'Duration: Running...' : 'Duration: ${event.duration}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isRunningNow ? _kGreen : _kMuted,
                    fontWeight: isRunningNow ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 3: VOLTAGE LOG
  // ==========================================
  SplineSeries<Map<String, dynamic>, num> _voltageSeries(
      List<Map<String, dynamic>> data,
      String key,
      String name,
      Color color,
      ) {
    return SplineSeries<Map<String, dynamic>, num>(
      dataSource: data,
      xValueMapper: (d, i) => PumpControllerProvider.parseReading(d['hour']) ?? i.toDouble(),
      // null (not 0) for a missing reading -> the line breaks instead of dropping to zero
      yValueMapper: (d, _) => PumpControllerProvider.parseReading(d[key]),
      name: name,
      color: color,
      width: 2,
      // monotonic spline never overshoots the real readings (no fake dips below 0 A)
      splineType: SplineType.monotonic,
      markerSettings: const MarkerSettings(isVisible: true, height: 4, width: 4),
      emptyPointSettings: const EmptyPointSettings(mode: EmptyPointMode.gap),
      // a 15 s refresh must not replay the draw animation every time
      animationDuration: 0,
    );
  }

  /// Y-axis window fitted to the data that is actually plotted.
  /// Voltage: zoomed to the readings (a 0-based axis flattens 390-420 V into a straight line).
  /// Current: starts at 0 and tops out just above the highest reading.
  ({double min, double max}) _voltageAxisRange(
      List<Map<String, dynamic>> data,
      List<String> keys,
      bool isVoltage,
      ) {
    double? lo;
    double? hi;
    for (final row in data) {
      for (final k in keys) {
        final v = PumpControllerProvider.parseReading(row[k]);
        if (v == null) continue;
        lo = lo == null ? v : (v < lo ? v : lo);
        hi = hi == null ? v : (v > hi ? v : hi);
      }
    }
    if (lo == null || hi == null) {
      return isVoltage ? (min: 0.0, max: 500.0) : (min: 0.0, max: 10.0);
    }
    if (isVoltage) {
      final double pad = ((hi - lo) * 0.15) < 10 ? 10 : (hi - lo) * 0.15;
      double min = ((lo - pad) / 10).floorToDouble() * 10;
      if (min < 0) min = 0;
      final double max = ((hi + pad) / 10).ceilToDouble() * 10;
      return (min: min, max: max);
    }
    final double top = hi <= 0 ? 1 : hi * 1.2;
    final double step = top <= 5 ? 1 : (top <= 20 ? 2 : 5);
    return (min: 0, max: (top / step).ceilToDouble() * step);
  }

  Widget _buildVoltageLogCard(PumpControllerProvider provider) {
    final List<Map<String, dynamic>> voltageData = List.from(provider.voltageData)
      ..sort((a, b) {
        final aHour = int.tryParse('${a['hour']}') ?? 0;
        final bHour = int.tryParse('${b['hour']}') ?? 0;
        return aHour.compareTo(bHour);
      });

    final bool hasEnergyData = voltageData.isNotEmpty && voltageData[0]['totalInstantEnergy'] != null;

    final List<String> toggleLabels = hasEnergyData
        ? const ['Voltage', 'Current',]
        : const ['Voltage', 'Current'];

    final int safeIndex = _voltageMetricIndex < toggleLabels.length ? _voltageMetricIndex : 0;

    bool showR = true;
    bool showY = true;
    bool showB = true;

    if (isSinglePhaseModel) {
      if (safeIndex == 0) {
        showR = false;
        showY = false;
        showB = true;
      } else if (safeIndex == 1) {
        final hasCurrentB = voltageData.any((d) => (double.tryParse('${d['currentB']}') ?? 0) > 0);
        final hasCurrentR = voltageData.any((d) => (double.tryParse('${d['currentR']}') ?? 0) > 0);
        if (hasCurrentB && !hasCurrentR) {
          showR = false;
          showY = false;
          showB = true;
        } else {
          showR = true;
          showY = false;
          showB = false;
        }
      } else {
        showR = true;
        showY = true;
        showB = true;
      }
    }

    final String prefix = safeIndex == 0
        ? 'voltage'
        : (safeIndex == 1
        ? 'current'
        : (safeIndex == 2 ? 'powerFactor' : 'power'));

    final String label = safeIndex == 0
        ? 'Voltage'
        : (safeIndex == 1
        ? 'Current'
        : (safeIndex == 2 ? 'Power Factor' : 'Power'));

    final String yUnitFormat = safeIndex == 0
        ? '{value}V'
        : (safeIndex == 1
        ? '{value}A'
        : (safeIndex == 2 ? '{value}' : '{value}kW'));

    final List<String> plottedKeys = [
      if (showR) '${prefix}R',
      if (showY) '${prefix}Y',
      if (showB) '${prefix}B',
    ];
    final axisRange = _voltageAxisRange(voltageData, plottedKeys, safeIndex == 0);
    final String unit = safeIndex == 0 ? ' V' : (safeIndex == 1 ? ' A' : '');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardTitle('VOLTAGE LOG'),
              _buildToggle(
                labels: toggleLabels,
                selected: safeIndex,
                hPad: 12,
                onChanged: (i) => setState(() => _voltageMetricIndex = i),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Center(
            child: Text(
              '$label Graph',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kInk),
            ),
          ),
          const SizedBox(height: 4),

          SizedBox(
            height: 230,
            child: voltageData.isEmpty
                ? Center(
              child: Text(
                provider.voltageMessage.isNotEmpty
                    ? provider.voltageMessage
                    : 'No voltage/current data recorded for this date.',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            )
                : SfCartesianChart(
              margin: EdgeInsets.zero,
              primaryXAxis: const NumericAxis(
                minimum: 0,
                maximum: 23,
                interval: 2,
                labelFormat: 'Hour {value}',
                labelRotation: -45,
                labelStyle: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                majorGridLines: MajorGridLines(width: 0.4, color: Color(0xFFE2E8F0)),
              ),
              primaryYAxis: NumericAxis(
                minimum: axisRange.min,
                maximum: axisRange.max,
                labelFormat: yUnitFormat,
                labelStyle: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                majorGridLines: const MajorGridLines(width: 0.4, color: Color(0xFFE2E8F0)),
              ),
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
                textStyle: TextStyle(fontSize: 11, color: Color(0xFF334155)),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                format: 'series.name\nHour point.x : point.y$unit',
              ),
              series: <CartesianSeries<Map<String, dynamic>, num>>[
                if (showR) _voltageSeries(voltageData, '${prefix}R', '$label R', _kRed),
                if (showY)
                  _voltageSeries(voltageData, '${prefix}Y', '$label Y', const Color(0xFFF9A825)),
                if (showB)
                  _voltageSeries(voltageData, '${prefix}B', '$label B', const Color(0xFF1E88E5)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (voltageData.isNotEmpty) _buildVoltageTable(voltageData, showR, showY, showB),
        ],
      ),
    );
  }

  String _cellText(dynamic v) {
    final d = PumpControllerProvider.parseReading(v);
    return d == null ? '-' : '$v';
  }

  Widget _buildVoltageTable(
      List<Map<String, dynamic>> voltageData,
      bool showR,
      bool showY,
      bool showB,
      ) {
    final bool hasEnergyData = voltageData.isNotEmpty && voltageData[0]['totalInstantEnergy'] != null;
    final int safeIndex = _voltageMetricIndex < (hasEnergyData ? 4 : 2) ? _voltageMetricIndex : 0;
    final String prefix = safeIndex == 0
        ? 'voltage'
        : (safeIndex == 1
        ? 'current'
        : (safeIndex == 2 ? 'powerFactor' : 'power'));

    Widget headerCell(String text, Color color, int flex) {
      return Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          color: color,
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kInk),
          ),
        ),
      );
    }

    Widget bodyCell(String text, int flex) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Column(
        children: [
          Row(
            children: [
              headerCell('Hours', const Color(0xFFB9D3D5), 5),
              if (showR) headerCell('R', const Color(0xFFFFB4AB), 4),
              if (showY) headerCell('Y', const Color(0xFFFFE69C), 4),
              if (showB) headerCell('B', const Color(0xFFA9DDF8), 4),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 190),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: voltageData.length,
              itemBuilder: (context, index) {
                final row = voltageData[index];
                return Row(
                  children: [
                    bodyCell('${row['hour']}', 5),
                    if (showR) bodyCell(_cellText(row['${prefix}R']), 4),
                    if (showY) bodyCell(_cellText(row['${prefix}Y']), 4),
                    if (showB) bodyCell(_cellText(row['${prefix}B']), 4),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}