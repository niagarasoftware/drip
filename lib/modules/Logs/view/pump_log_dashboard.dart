import 'dart:developer';
import 'dart:io';

import 'package:excel/excel.dart' as xls;
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
import 'package:oro_drip_irrigation/modules/Preferences/widgets/custom_segmented_control.dart';

// ---------------------------------------------------------------------------
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
    this.userData = const {}, required bool showMobileCalendar,
  });

  @override
  State<PumpLogDashboardScreen> createState() => _PumpLogDashboardScreenState();
}

class _PumpLogDashboardScreenState extends State<PumpLogDashboardScreen> {
  /// The target design has no device/MAC bar for a single device.
  /// Set to true if you want the MAC address bar back.
  static const bool _showSingleDeviceHeader = false;

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
    if (widget.pumpList.isNotEmpty && _selectedPumpIndex < widget.pumpList.length) {
      final item = widget.pumpList[_selectedPumpIndex];
      final deviceId = item['deviceId']?.toString();
      if (deviceId != null && deviceId.isNotEmpty) return deviceId;
    }
    return widget.masterData.deviceId;
  }

  String get currentDeviceName {
    if (AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId)) {
      return widget.masterData.deviceName;
    }
    if (widget.pumpList.isNotEmpty && _selectedPumpIndex < widget.pumpList.length) {
      final item = widget.pumpList[_selectedPumpIndex];
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

    if (widget.pumpList.isNotEmpty) {
      final isEcoGem = AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId);
      _activeNodeControllerId = isEcoGem ? 0 : (widget.pumpList[0]['controllerId'] ?? widget.nodeControllerId);
    } else {
      _activeNodeControllerId = widget.nodeControllerId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllData();
    });
  }

  @override
  void didUpdateWidget(covariant PumpLogDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pumpList != oldWidget.pumpList && widget.pumpList.isNotEmpty) {
      if (_selectedPumpIndex >= widget.pumpList.length) {
        _selectedPumpIndex = 0;
      }
      final isEcoGem = AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId);
      final newControllerId =
      isEcoGem ? 0 : (widget.pumpList[_selectedPumpIndex]['controllerId'] ?? widget.nodeControllerId);
      if (newControllerId != _activeNodeControllerId) {
        _activeNodeControllerId = newControllerId;
        _fetchAllData();
      }
    }
  }

  void _alignWeekStartDate(DateTime date) {
    // Week starting on Sunday
    final int diff = date.weekday % 7;
    _weekStartDate = DateTime(date.year, date.month, date.day).subtract(Duration(days: diff));
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
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

      if (mounted) {
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
      if (mounted) {
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
    if (_isFuture(newStart)) return; // never move into a week that is fully in the future

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

  void _pickMonth() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _isFuture(_selectedDate) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now, // future dates cannot be picked
    );
    if (picked != null) {
      _onDateSelected(picked);
    }
  }

  void _exportExcel() async {
    final provider = context.read<PumpControllerProvider>();
    if (provider.motorDataList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to export.')),
      );
      return;
    }

    final excel = xls.Excel.createExcel();
    final xls.Sheet sheet = excel['Sheet1'];

    sheet.appendRow([
      xls.TextCellValue('Date'),
      xls.TextCellValue('Total Power On Time'),
      xls.TextCellValue('Total Power Off Time'),
      xls.TextCellValue('Cumulative Flow'),
      xls.TextCellValue('Flow Rate'),
      xls.TextCellValue('Pressure'),
      xls.TextCellValue('Level'),
      xls.TextCellValue('Motor 1 Run Time'),
      xls.TextCellValue('Motor 1 Idle Time'),
      xls.TextCellValue('Motor 1 Dry Run Trip'),
      xls.TextCellValue('Motor 1 Cyclic Trip'),
      xls.TextCellValue('Motor 1 Other Trip'),
      xls.TextCellValue('Motor 1 Total Flow'),
    ]);

    for (final data in provider.motorDataList) {
      sheet.appendRow([
        xls.TextCellValue(data.date),
        xls.TextCellValue(data.totalPowerOnTime),
        xls.TextCellValue(data.totalPowerOffTime),
        xls.TextCellValue(data.overAllCumulativeFlow),
        xls.TextCellValue(data.flowRate),
        xls.TextCellValue(data.pressure),
        xls.TextCellValue(data.level),
        xls.TextCellValue(data.motorRunTime1),
        xls.TextCellValue(data.motorIdleTime1),
        xls.TextCellValue(data.dryRunTripTime1),
        xls.TextCellValue(data.cyclicTripTime1),
        xls.TextCellValue(data.otherTripTime1),
        xls.TextCellValue(data.totalFlowToday1),
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      try {
        if (!kIsWeb) {
          const downloadsDirectoryPath = "/storage/emulated/0/Download";
          final filePath =
              "$downloadsDirectoryPath/Power_Graph_${DateFormat('yyyyMMdd').format(_selectedDate)}.xlsx";
          final file = File(filePath);
          await file.create(recursive: true);
          await file.writeAsBytes(fileBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Report saved to $filePath')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report generated.')),
            );
          }
        }
      } catch (e) {
        log("Export error: $e");
      }
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================

  /// Parses "HH:MM" or "HH:MM:SS" into seconds.
  int _toSeconds(String t) {
    final p = t.split(':').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    if (p.length >= 3) return p[0] * 3600 + p[1] * 60 + p[2];
    if (p.length == 2) return p[0] * 3600 + p[1] * 60;
    return 0;
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

    return Scaffold(
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
    return [
      {
        'deviceName': widget.masterData.deviceName,
        'deviceId': widget.masterData.deviceId,
        'controllerId': 0,
      }
    ];
  }

  Map<int, String> getEffectiveSegments(PumpControllerProvider provider) {
    if (provider.segments.length > 1) {
      return provider.segments;
    }

    final targetControllerId = _activeNodeControllerId != 0 ? _activeNodeControllerId : widget.controllerId;
    var targetPumps = widget.masterData.configObjects
        .where((e) => e.objectId == 5 && (e.controllerId == targetControllerId || targetControllerId == 0))
        .toList();

    if (targetPumps.isEmpty) {
      targetPumps = widget.masterData.configObjects.where((e) => e.objectId == 5).toList();
    }

    if (targetPumps.length > 1) {
      final Map<int, String> segs = {};
      for (var pump in targetPumps) {
        final int key =
        (pump.connectionNo >= 1 && pump.connectionNo <= 3) ? pump.connectionNo - 1 : segs.length;
        segs[key] = pump.name.isNotEmpty
            ? pump.name
            : "Pump ${pump.connectionNo > 0 ? pump.connectionNo : segs.length + 1}";
      }
      if (segs.length > 1) {
        return segs;
      }
    }

    if (provider.segments.isNotEmpty) {
      return provider.segments;
    }

    final pumpNames = provider.getPumpNames(widget.masterData, _activeNodeControllerId, widget.controllerId);
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
  // CARD 1: POWER GRAPH
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

    const int daySeconds = 24 * 3600;
    final double totalPowerRatio = (_toSeconds(totalPowerOnTime) / daySeconds).clamp(0.0, 1.0);
    final double motorRatio = (_toSeconds(motorRunTime) / daySeconds).clamp(0.0, 1.0);

    final String activeMotorName =
        segments[activeKey] ?? _pick(activeKey, "Motor 1", "Motor 2", "Motor 3");

    final left = _buildPowerGraphLeftColumn(
      totalPowerOnTime: totalPowerOnTime,
      motorRunTime: motorRunTime,
      totalPowerRatio: totalPowerRatio,
      motorRatio: motorRatio,
      activeMotorName: activeMotorName,
    );
    final center = _buildPowerGraphCenterColumn(
      motorData: motorData,
      totalPowerOnTime: totalPowerOnTime,
      totalPowerOffTime: totalPowerOffTime,
    );
    final right = _buildPowerGraphRightTable(
      provider: provider,
      runTime: motorRunTime,
      idleTime: motorIdleTime,
      dryRunTime: dryRunTripTime,
      cyclicTime: cyclicTripTime,
      otherTime: otherTripTime,
      totalFlow: totalFlowToday,
      segments: segments,
      activeKey: activeKey,
      activeMotorName: activeMotorName,
    );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardTitle('POWER GRAPH'),
              InkWell(
                onTap: _exportExcel,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(color: _kTeal, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_downward, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: left),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: center),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: right),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: 20),
                center,
                const SizedBox(height: 20),
                right,
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPowerGraphLeftColumn({
    required String totalPowerOnTime,
    required String motorRunTime,
    required double totalPowerRatio,
    required double motorRatio,
    required String activeMotorName,
  }) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, MMMM d').format(_selectedDate),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kInk),
        ),
        const SizedBox(height: 2),
        Text(
          isToday ? 'Today' : DateFormat('yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        _buildToggle(
          labels: const ['Daily', 'Weekly', 'Monthly'],
          selected: _powerPeriodIndex,
          onChanged: (i) {
            setState(() => _powerPeriodIndex = i);
            _fetchAllData();
          },
        ),
        const SizedBox(height: 36),

        // Date banner
        Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFD4EDF2),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            DateFormat('MMM d yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F4C5C)),
          ),
        ),
        const SizedBox(height: 10),

        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('00:00', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            Text('08:00', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            Text('16:00', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            Text('24:00', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ],
        ),
        const SizedBox(height: 4),

        _buildProgressBar(
          ratio: totalPowerRatio,
          label: 'Total Power - ${Constants.changeFormat(totalPowerOnTime)}',
          barColor: const Color(0xFF14BFE8),
        ),
        const SizedBox(height: 4),
        _buildProgressBar(
          ratio: motorRatio,
          label: '$activeMotorName consumed ${Constants.changeFormat(motorRunTime)}',
          barColor: const Color(0xFFB8E3EE),
        ),
      ],
    );
  }

  Widget _buildProgressBar({
    required double ratio,
    required String label,
    required Color barColor,
  }) {
    return Container(
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio > 0 ? ratio : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kInk),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerGraphCenterColumn({
    required MotorDataHourly? motorData,
    required String totalPowerOnTime,
    required String totalPowerOffTime,
  }) {
    String clean(String? v) => (v != null && v != "-" && v.isNotEmpty) ? v : "0.0";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricItem('Cumulative flow', '${motorData?.overAllCumulativeFlow ?? "0"} Litres'),
        const SizedBox(height: 14),
        _buildMetricItem('Pressure', '${clean(motorData?.pressure)} bar'),
        const SizedBox(height: 14),
        _buildMetricItem('Flow rate', '${clean(motorData?.flowRate)} Lps'),
        const SizedBox(height: 14),
        _buildMetricItem('Level', '${clean(motorData?.level)} feet'),
        const SizedBox(height: 14),
        _buildMetricItem('Total power on time', '${Constants.changeFormat(totalPowerOnTime)} (HH:MM)'),
        const SizedBox(height: 14),
        _buildMetricItem('Total power off time', '${Constants.changeFormat(totalPowerOffTime)} (HH:MM)'),
      ],
    );
  }

  Widget _buildMetricItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: _kMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kInk),
        ),
      ],
    );
  }

  Widget _buildPowerGraphRightTable({
    required PumpControllerProvider provider,
    required String runTime,
    required String idleTime,
    required String dryRunTime,
    required String cyclicTime,
    required String otherTime,
    required String totalFlow,
    required Map<int, String> segments,
    required int activeKey,
    required String activeMotorName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: motor name (dropdown if several motors) + Unit
        SizedBox(
          height: 30,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: segments.length > 1
                    ? Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isDense: true,
                      value: segments.containsKey(activeKey) ? activeKey : segments.keys.first,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kInk),
                      items: segments.entries
                          .map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) _onMotorChanged(provider, val);
                      },
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  activeMotorName,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: _kMuted),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                flex: 2,
                child: Text(
                  'Unit',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, color: _kMuted),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFFE2E8F0), height: 1),

        _buildTableRow('Motor run time', Constants.changeFormat(runTime), 'HH:MM', _kTeal),
        _buildTableRow('Motor idle time', Constants.changeFormat(idleTime), 'HH:MM', _kRed, unitColor: _kRed),
        _buildTableRow('Dry run trip time', Constants.changeFormat(dryRunTime), 'HH:MM', _kTeal),
        _buildTableRow('Cyclic trip time', Constants.changeFormat(cyclicTime), 'HH:MM', _kTeal),
        _buildTableRow('Other trip time', Constants.changeFormat(otherTime), 'HH:MM', _kTeal),
        _buildTableRow('Total flow today', totalFlow, 'Litres', _kRed, unitColor: _kRed, showDivider: false),
      ],
    );
  }

  Widget _buildTableRow(
      String title,
      String value,
      String unit,
      Color valueColor, {
        Color unitColor = _kInk,
        bool showDivider = true,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: _kInk, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: valueColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              unit,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: unitColor),
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

    Duration totalDuration = Duration.zero;
    for (final e in events) {
      try {
        totalDuration += Constants.parseTime(e.duration);
      } catch (_) {}
    }
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
              Expanded(child: _buildSummaryBox('Listed duration', formattedDuration, _kInk)),
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
              double endSec = event.offTime.trim().isNotEmpty
                  ? _toSeconds(event.offTime).toDouble()
                  : startSec + _toSeconds(event.duration);

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

    final hasOffTime = event.offTime.trim().isNotEmpty;
    final hasOnReason = event.onReason.trim().isNotEmpty;
    final hasOffReason = event.offReason.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
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
                  'Duration: ${event.duration}',
                  style: const TextStyle(fontSize: 11, color: _kMuted),
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
      xValueMapper: (d, i) => double.tryParse('${d['hour']}') ?? i.toDouble(),
      yValueMapper: (d, _) => double.tryParse(d[key]?.toString() ?? '0.0') ?? 0.0,
      name: name,
      color: color,
      width: 2,
    );
  }

  Widget _buildVoltageLogCard(PumpControllerProvider provider) {
    bool showR = true;
    bool showY = true;
    bool showB = true;

    if (isSinglePhaseModel) {
      if (_voltageMetricIndex == 0) {
        showR = false;
        showY = false;
        showB = true;
      } else {
        showR = true;
        showY = false;
        showB = false;
      }
    }

    final bool isVoltage = _voltageMetricIndex == 0;
    final String prefix = isVoltage ? 'voltage' : 'current';
    final String label = isVoltage ? 'Voltage' : 'Current';
    final List<Map<String, dynamic>> voltageData = provider.voltageData;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardTitle('VOLTAGE LOG'),
              _buildToggle(
                labels: const ['Voltage', 'Current'],
                selected: _voltageMetricIndex,
                hPad: 16,
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
                ? const Center(
              child: Text(
                'No voltage/current data recorded for this date.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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
                minimum: 0,
                labelFormat: isVoltage ? '{value}V' : '{value}A',
                labelStyle: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                majorGridLines: const MajorGridLines(width: 0.4, color: Color(0xFFE2E8F0)),
              ),
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
                textStyle: TextStyle(fontSize: 11, color: Color(0xFF334155)),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
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

  Widget _buildVoltageTable(
      List<Map<String, dynamic>> voltageData,
      bool showR,
      bool showY,
      bool showB,
      ) {
    final String prefix = _voltageMetricIndex == 0 ? 'voltage' : 'current';

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
                    if (showR) bodyCell('${row['${prefix}R'] ?? "-"}', 4),
                    if (showY) bodyCell('${row['${prefix}Y'] ?? "-"}', 4),
                    if (showB) bodyCell('${row['${prefix}B'] ?? "-"}', 4),
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