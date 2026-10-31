import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import 'package:oro_drip_irrigation/Constants/data_convertion.dart';

import '../repository/irrigation_repository.dart';

class ZoneCyclicLog extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ZoneCyclicLog({
    super.key,
    required this.userData,
  });

  @override
  State<ZoneCyclicLog> createState() => _ZoneCyclicLogState();
}

class _ZoneCyclicLogState extends State<ZoneCyclicLog> {
  static const Color primary = Color(0xFF0B6873);
  static const Color background = Color(0xFFEEF4F5);
  static const Color borderColor = Color(0xFFD9E6E9);
  static const Color textColor = Color(0xFF1C2D35);

  // Common padding for all sensor rows
  static const EdgeInsets _sensorRowPadding =
  EdgeInsets.fromLTRB(2, 5, 2, 5);

  String _selectedDate = '';

  DateTime _pickerStartDate = DateTime.now();
  DateTime _pickerEndDate = DateTime.now();

  Map<String, dynamic> data = {};

  bool isLoading = false;
  bool _hasAppliedDateRange = false;
  bool _showHorizontalCalendar = false;

  DateTime _horizontalSelectedDate = DateTime.now();
  DateTime _horizontalWeekStart = _startOfWeek(DateTime.now());

  final Set<String> _collapsedPrograms = {};

  static DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday % 7));
  }

  String _formatNumber(int number) =>
      number.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) getData();
    });
  }

  // ------------------------------------------------------------
  // TIME FORMAT
  // ------------------------------------------------------------

  String _formatTimeWithAmPm(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '--';
    }

    final time = value.toString().trim();

    const formats = [
      'HH:mm:ss',
      'H:mm:ss',
      'HH:mm',
      'H:mm',
      'hh:mm:ss a',
      'h:mm:ss a',
      'hh:mm a',
      'h:mm a',
    ];

    for (final format in formats) {
      try {
        final parsed = DateFormat(format).parseStrict(time);
        return DateFormat('hh:mm:ss a').format(parsed);
      } catch (_) {}
    }

    return time;
  }

  DateTime? _parseClockTime(String value) {
    const formats = [
      'HH:mm:ss',
      'H:mm:ss',
      'HH:mm',
      'H:mm',
      'hh:mm:ss a',
      'h:mm:ss a',
      'hh:mm a',
      'h:mm a',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parseStrict(value.trim());
      } catch (_) {}
    }

    return null;
  }

  // ------------------------------------------------------------
  // DURATION HELPERS
  // ------------------------------------------------------------

  String _formatDurationValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '--';
    }

    final text = value.toString().trim();

    if (text.contains(':')) {
      try {
        final seconds = DataConvert().parseTimeString(text);
        return _formatDurationSeconds(seconds);
      } catch (_) {
        return text;
      }
    }

    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(text);

    if (match != null) {
      final number = double.tryParse(match.group(0)!);

      if (number != null) {
        final valueText = text.toLowerCase();
        int seconds = number.round();

        if (valueText.contains('hour') || valueText == 'h') {
          seconds *= 3600;
        } else if (valueText.contains('min') || valueText == 'm') {
          seconds *= 60;
        }

        return _formatDurationSeconds(seconds);
      }
    }

    return text;
  }

  String _formatDurationSeconds(int seconds) {
    if (seconds < 0) seconds = 0;

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    }

    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }

    return '${remainingSeconds}s';
  }

  dynamic _firstAvailableValue(
      Map<String, dynamic> zone,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = zone[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  String _getSetDuration(Map<String, dynamic> zone) {
    final value = _firstAvailableValue(zone, [
      'setDuration',
      'setTime',
      'targetDuration',
      'setRunTime',
      'scheduledDuration',
      'setSeconds',
      'setTimeSeconds',
    ]);

    return value == null ? '--' : _formatDurationValue(value);
  }

  String _getRunDuration(Map<String, dynamic> zone) {
    final value = _firstAvailableValue(zone, [
      'runDuration',
      'actualDuration',
      'actualRunTime',
      'runTime',
      'runningDuration',
      'actualSeconds',
      'runTimeSeconds',
      'duration',
    ]);

    return value == null ? '--' : _formatDurationValue(value);
  }

  String _getSetFlow(Map<String, dynamic> zone) {
    final value = _firstAvailableValue(zone, [
      'setFlow',
      'setFlowRate',
      'targetFlow',
      'setWaterFlow',
    ]);

    return value == null ? '--' : _formatFlowValue(value);
  }

  String _getRunFlow(Map<String, dynamic> zone) {
    final value = _firstAvailableValue(zone, [
      'flow',
      'runFlow',
      'actualFlow',
      'runFlowRate',
      'actualFlowRate',
    ]);

    return value == null ? '--' : _formatFlowValue(value);
  }

  String _formatFlowValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '--';
    }

    final number = double.tryParse(value.toString());

    if (number == null) return value.toString();

    return number.toStringAsFixed(
      number == number.roundToDouble() ? 0 : 2,
    );
  }

  // ------------------------------------------------------------
  // API
  // ------------------------------------------------------------

  Future<void> getData() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final now = DateTime.now();
      final today = DateFormat('dd/MM/yyyy').format(now);

      if (_selectedDate.isEmpty) {
        _selectedDate = '$today - $today';
      }

      final dateParts = _selectedDate.split(' - ');

      if (dateParts.length != 2) return;

      final startParts = dateParts[0].split('/');
      final endParts = dateParts[1].split('/');

      if (startParts.length != 3 || endParts.length != 3) return;

      final startDate = DateTime(
        int.parse(startParts[2]),
        int.parse(startParts[1]),
        int.parse(startParts[0]),
      );

      final endDate = DateTime(
        int.parse(endParts[2]),
        int.parse(endParts[1]),
        int.parse(endParts[0]),
      );

      final body = <String, dynamic>{
        'userId': widget.userData['customerId'],
        'controllerId': widget.userData['controllerId'],
        'logType': 'IrrigationZoneCyclic',
        'fromDate':
        '${startDate.year}-${_formatNumber(startDate.month)}-${_formatNumber(startDate.day)}',
        'toDate':
        '${endDate.year}-${_formatNumber(endDate.month)}-${_formatNumber(endDate.day)}',
      };

      final response =
      await IrrigationRepository().getNovaLogDateWise(body);

      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      if (decoded is Map<String, dynamic> && decoded['code'] == 200) {
        final result = decoded['data'];

        setState(() {
          data = result is Map<String, dynamic> ? result : {};
        });
      } else {
        setState(() => data = {});
      }
    } catch (e, stack) {
      debugPrint('Error loading cyclic log: $e');
      debugPrint('$stack');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ------------------------------------------------------------
  // DATE PICKER
  // ------------------------------------------------------------

  void _onSelectionChanged(
      DateRangePickerSelectionChangedArgs args,
      ) {
    if (args.value is PickerDateRange) {
      final range = args.value as PickerDateRange;
      final start = range.startDate ?? DateTime.now();
      final end = range.endDate ?? start;

      setState(() {
        _pickerStartDate = start;
        _pickerEndDate = end;
        _selectedDate =
        '${DateFormat('dd/MM/yyyy').format(start)} - '
            '${DateFormat('dd/MM/yyyy').format(end)}';
      });
    }
  }

  Future<void> _showDatePicker() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Select Date Range',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 340,
          height: 320,
          child: SfDateRangePicker(
            selectionMode: DateRangePickerSelectionMode.range,
            initialSelectedRange: PickerDateRange(
              _pickerStartDate,
              _pickerEndDate,
            ),
            onSelectionChanged: _onSelectionChanged,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _hasAppliedDateRange = true;
                _showHorizontalCalendar = false;
                _horizontalSelectedDate = _pickerStartDate;
                _horizontalWeekStart =
                    _startOfWeek(_pickerStartDate);
              });

              Navigator.pop(dialogContext);
              getData();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MAIN UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final raw = data['zoneCyclic'];
    final List logs = raw is List ? raw : [];

    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: const Color(0xFF07545E),
        foregroundColor: Colors.white,
        onPressed: () {
          if (_hasAppliedDateRange) {
            setState(() {
              _showHorizontalCalendar = !_showHorizontalCalendar;
            });
          } else {
            _showDatePicker();
          }
        },
        child: const Icon(
          Icons.calendar_month_rounded,
          size: 20,
        ),
      ),
      body: Column(
        children: [
          if (_showHorizontalCalendar) _buildHorizontalCalendar(),
          Expanded(
            child: isLoading && logs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : logs.isEmpty
                ? _buildEmptyState()
                : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  6,
                  6,
                  6,
                  56,
                ),
                child: Column(
                  children: [
                    for (final item in logs)
                      if (item is Map<String, dynamic>)
                        dateWiseBox(item),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 40,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 6),
          const Text(
            'There is no cyclic log data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedDate.isEmpty
                ? 'Select a date to view the log'
                : 'No data for $_selectedDate',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HORIZONTAL CALENDAR
  // ------------------------------------------------------------

  Widget _buildHorizontalCalendar() {
    final dates = List<DateTime>.generate(
      7,
          (index) => _horizontalWeekStart.add(Duration(days: index)),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    _horizontalWeekStart =
                        _horizontalWeekStart.subtract(
                          const Duration(days: 7),
                        );
                  });
                },
                icon: const Icon(Icons.chevron_left, size: 22),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_horizontalWeekStart),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _showDatePicker,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text(
                  'Month',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    _horizontalWeekStart =
                        _horizontalWeekStart.add(
                          const Duration(days: 7),
                        );
                  });
                },
                icon: const Icon(Icons.chevron_right, size: 22),
              ),
            ],
          ),
          Row(
            children: [
              for (final date in dates)
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('EEE').format(date),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              for (final date in dates)
                Expanded(child: _buildHorizontalDateItem(date)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDateItem(DateTime date) {
    final selected =
        date.year == _horizontalSelectedDate.year &&
            date.month == _horizontalSelectedDate.month &&
            date.day == _horizontalSelectedDate.day;

    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          final formatted = DateFormat('dd/MM/yyyy').format(date);

          setState(() {
            _horizontalSelectedDate = date;
            _pickerStartDate = date;
            _pickerEndDate = date;
            _selectedDate = '$formatted - $formatted';
            _showHorizontalCalendar = false;
          });

          getData();
        },
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : textColor,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DATE SUMMARY
  // ------------------------------------------------------------

  Widget dateWiseBox(Map<String, dynamic> log) {
    final date = log['date']?.toString() ?? '--';
    final duration = getCyclicDuration(log);
    final flow = getCyclicFlow(log);
    final time = getCyclicTime(log);

    final rawZones = log['zoneList'];
    final List zones = rawZones is List ? rawZones : [];

    DateTime? parsedDate;

    try {
      parsedDate = DateTime.parse(date);
    } catch (_) {}

    final displayDate = parsedDate == null
        ? date
        : DateFormat('dd MMM yyyy').format(parsedDate);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFD3E6E3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1D7C85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _dateSummaryMetric(
                    Icons.calendar_month_rounded,
                    'Date',
                    displayDate,
                    const Color(0xFFFFD58A),
                  ),
                ),
                Expanded(
                  child: _dateSummaryMetric(
                    Icons.timer_outlined,
                    'Duration',
                    duration,
                    const Color(0xFF9BEBC0),
                  ),
                ),
                Expanded(
                  child: _dateSummaryMetric(
                    Icons.water_drop_rounded,
                    'Total flow',
                    flow,
                    const Color(0xFFA9D8FF),
                  ),
                ),
                Expanded(
                  child: _dateSummaryMetric(
                    Icons.access_time_rounded,
                    'Time',
                    time,
                    const Color(0xFFFFD58A),
                  ),
                ),
              ],
            ),
          ),
          ..._buildProgramGroups(zones),
        ],
      ),
    );
  }

  Widget _dateSummaryMetric(
      IconData icon,
      String label,
      String value,
      Color iconColor,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFD8F0F0),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TOTAL DURATION, FLOW AND TIME
  // ------------------------------------------------------------

  String getCyclicDuration(Map<String, dynamic> log) {
    final converter = DataConvert();
    int totalSeconds = 0;

    final rawZones = log['zoneList'];
    final List zones = rawZones is List ? rawZones : [];

    for (final zone in zones) {
      if (zone is Map && zone['duration'] != null) {
        totalSeconds += converter.parseTimeString(
          zone['duration'].toString(),
        );
      }
    }

    return converter.formatTime(totalSeconds);
  }

  String getCyclicFlow(Map<String, dynamic> log) {
    double total = 0;

    final rawZones = log['zoneList'];
    final List zones = rawZones is List ? rawZones : [];

    for (final zone in zones) {
      if (zone is Map) {
        total += double.tryParse('${zone['flow'] ?? ''}') ?? 0;
      }
    }

    return total.toStringAsFixed(
      total == total.roundToDouble() ? 0 : 2,
    );
  }

  String getCyclicTime(Map<String, dynamic> log) {
    final rawZones = log['zoneList'];
    final List zones = rawZones is List ? rawZones : [];

    DateTime? firstStart;
    DateTime? lastEnd;

    for (final zone in zones) {
      if (zone is! Map) continue;

      final startValue = zone['onTime'];
      final endValue = zone['offTime'];

      if (startValue == null || endValue == null) continue;

      final startTime = _parseClockTime(startValue.toString());
      var endTime = _parseClockTime(endValue.toString());

      if (startTime == null || endTime == null) continue;

      if (endTime.isBefore(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      if (firstStart == null || startTime.isBefore(firstStart)) {
        firstStart = startTime;
      }

      if (lastEnd == null || endTime.isAfter(lastEnd)) {
        lastEnd = endTime;
      }
    }

    if (firstStart == null || lastEnd == null) return '--';

    return '${DateFormat('hh:mm:ss a').format(firstStart)} → '
        '${DateFormat('hh:mm:ss a').format(lastEnd)}';
  }

  // ------------------------------------------------------------
  // PROGRAM CARDS
  // ------------------------------------------------------------

  List<Widget> _buildProgramGroups(List zones) {
    final Map<String, List<Map<String, dynamic>>> programs = {};

    for (final zone in zones) {
      if (zone is Map<String, dynamic>) {
        final key = '${zone['program'] ?? '--'}';
        programs.putIfAbsent(key, () => []).add(zone);
      }
    }

    return [
      for (final entry in programs.entries)
        programBox(entry.key, entry.value),
    ];
  }

  Widget programBox(
      String program,
      List<Map<String, dynamic>> zones,
      ) {
    final collapsed = _collapsedPrograms.contains(program);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFF1D7C85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.layers_outlined,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Program $program',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${zones.length} ${zones.length == 1 ? 'Zone' : 'Zones'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2A8F95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                tooltip: collapsed ? 'Expand zones' : 'Collapse zones',
                onPressed: () {
                  setState(() {
                    if (collapsed) {
                      _collapsedPrograms.remove(program);
                    } else {
                      _collapsedPrograms.add(program);
                    }
                  });
                },
                icon: Icon(
                  collapsed
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  size: 22,
                  color: const Color(0xFF344B55),
                ),
              ),
            ],
          ),
          if (!collapsed) ...[
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;

                if (!wide) {
                  return Column(
                    children: [
                      for (int i = 0; i < zones.length; i++) ...[
                        if (i > 0) const SizedBox(height: 5),
                        zoneBox(zones[i]),
                      ],
                    ],
                  );
                }

                const gap = 8.0;
                final width = (constraints.maxWidth - gap) / 2;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final zone in zones)
                      SizedBox(
                        width: width,
                        child: zoneBox(zone),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ZONE CARD
  // ------------------------------------------------------------

  Widget zoneBox(Map<String, dynamic> zone) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB5D0CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildZoneHeader(zone),
          _buildTimeline(zone),
          Container(
            height: 1,
            color: const Color(0xFF8FB3AE),
          ),
          _buildSetRunTimeCards(zone),
          _buildSensorPanel(zone),
        ],
      ),
    );
  }

  Widget _buildZoneHeader(Map<String, dynamic> zone) {
    final setFlow = _getSetFlow(zone);
    final runFlow = _getRunFlow(zone);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 3),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF1D7C85),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zone',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4F7378),
                  ),
                ),
                Text(
                  _zoneNumber(zone['zone']),
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF17505A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 3,
              children: [
                _flowBadge(
                  'Set',
                  setFlow,
                  const Color(0xFFC9E0F5),
                  const Color(0xFF0C447C),
                ),
                _flowBadge(
                  'Run',
                  runFlow,
                  const Color(0xFFBFE6D6),
                  const Color(0xFF085041),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowBadge(
      String label,
      String value,
      Color backgroundColor,
      Color foregroundColor,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop_rounded,
            size: 11,
            color: foregroundColor,
          ),
          const SizedBox(width: 3),
          Text(
            '$label $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }

  String _zoneNumber(dynamic value) {
    final text = '${value ?? '01'}';
    final match = RegExp(r'\d+').firstMatch(text);
    final number = match?.group(0) ?? text;

    return number.padLeft(2, '0');
  }

  // ------------------------------------------------------------
  // TIMELINE
  // ------------------------------------------------------------

  Widget _buildTimeline(Map<String, dynamic> zone) {
    final start = _formatTimeWithAmPm(zone['onTime']);
    final end = _formatTimeWithAmPm(zone['offTime']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 3, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 13,
                      color: Color(0xFF17894F),
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF17894F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    start,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF17505A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF17894F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Expanded(
                    child: Divider(
                      color: Color(0xFF8FB3AE),
                      thickness: 1.2,
                      endIndent: 2,
                    ),
                  ),
                  const Icon(
                    Icons.water_drop_rounded,
                    size: 14,
                    color: Color(0xFF1D7C85),
                  ),
                  const Expanded(
                    child: Divider(
                      color: Color(0xFF8FB3AE),
                      thickness: 1.2,
                      indent: 2,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD03A40),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.stop_rounded,
                      size: 13,
                      color: Color(0xFFD03A40),
                    ),
                    SizedBox(width: 2),
                    Text(
                      'End',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD03A40),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    end,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF17505A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRunTimeCards(Map<String, dynamic> zone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 2),
      child: Row(
        children: [
          Expanded(
            child: _timeCard(
              'Set time',
              _getSetDuration(zone),
              const Color(0xFFDCE9E7),
              const Color(0xFF17505A),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _timeCard(
              'Run time',
              _getRunDuration(zone),
              const Color(0xFFBFE6D6),
              const Color(0xFF085041),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeCard(
      String label,
      String value,
      Color backgroundColor,
      Color foregroundColor,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: foregroundColor.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SENSOR MONITORING
  // ------------------------------------------------------------

  Widget _buildSensorPanel(Map<String, dynamic> zone) {
    final wellLevel =
        double.tryParse('${zone['wellLevel'] ?? 0}') ?? 0;

    final percentage = (double.tryParse(
      '${zone['wellPercentage'] ?? 0}',
    ) ??
        0)
        .clamp(0, 100)
        .toDouble();

    final pressureIn = '${zone['pressureIn'] ?? '0.00'}';
    final pressureOut = '${zone['pressureOut'] ?? '0.00'}';
    final ec = '${zone['ec'] ?? '0.00'}';
    final ph = '${zone['ph'] ?? '0.00'}';

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD0E0E3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // WELL
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 6, 4),
            child: SizedBox(
              width: 74,
              height: 74,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 7,
                      backgroundColor: const Color(0xFFC4E6E3),
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(
                        Color(0xFF008F8B),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'WELL',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF4F7378),
                        ),
                      ),
                      Text(
                        wellLevel.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF17505A),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF085041),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // WELL-TO-SENSOR SPACING
          const SizedBox(width: 20),

          // SENSOR AREA
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const dividerWidth = 2.0;
                const leftGap = 2.0;
                const rightGap = 20.0;

                final availableWidth = constraints.maxWidth;

                final columnWidth = (availableWidth -
                    leftGap -
                    rightGap -
                    dividerWidth) /
                    2;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LEFT SIDE: PRS IN AND EC
                    SizedBox(
                      width: columnWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sensorValueRow(
                            'PRS IN :',
                            pressureIn,
                            const Color(0xFF1685F8),
                          ),
                          _sensorValueRow(
                            'EC :',
                            ec,
                            const Color(0xFF8538E8),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: leftGap),

                    const SizedBox(width: rightGap),

                    // RIGHT SIDE: PRS OUT AND pH
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sensorValueRow(
                            'PRS OUT :',
                            pressureOut,
                            const Color(0xFF1685F8),
                          ),
                          _sensorValueRow(
                            'pH :',
                            ph,
                            const Color(0xFFE07B00),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SENSOR VALUE ROW - COMMON PADDING
  // ------------------------------------------------------------

  Widget _sensorValueRow(
      String label,
      String value,
      Color color,
      ) {
    return Padding(
      padding: _sensorRowPadding,
      child: Row(
        children: [
          Flexible(
            flex: 5,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 1),
          Flexible(
            flex: 4,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF17505A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}