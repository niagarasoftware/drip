import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:oro_drip_irrigation/Constants/data_convertion.dart';

import '../repository/irrigation_repository.dart';

class MotorCyclicLog extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MotorCyclicLog({
    super.key,
    required this.userData,
  });

  @override
  State<MotorCyclicLog> createState() => _MotorCyclicLogState();
}

class _MotorCyclicLogState extends State<MotorCyclicLog> {
  static const Color teal = Color(0xFF087F8C);
  static const Color darkTeal = Color(0xFF104653);
  static const Color pageBackground = Color(0xFFF2F7F8);

  DateTime _pickerStartDate = DateTime.now();
  DateTime _pickerEndDate = DateTime.now();
  DateTime _calendarDate = DateTime.now();

  String _selectedDate = '';

  Map<String, dynamic> data = {};

  bool isLoading = false;
  bool _showHorizontalCalendar = false;

  @override
  void initState() {
    super.initState();

    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _selectedDate = '$today - $today';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        getData();
      }
    });
  }

  String _apiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _displayDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime get _selectedStartDate {
    final dates = _selectedDate.split(' - ');

    if (dates.isNotEmpty) {
      try {
        return DateFormat('dd/MM/yyyy').parse(dates.first.trim());
      } catch (_) {}
    }

    return _dateOnly(DateTime.now());
  }

  Future<void> getData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final dates = _selectedDate.split(' - ');

      final startDate = dates.length >= 2
          ? DateFormat('dd/MM/yyyy').parse(dates[0].trim())
          : _pickerStartDate;

      final endDate = dates.length >= 2
          ? DateFormat('dd/MM/yyyy').parse(dates[1].trim())
          : _pickerEndDate;

      final body = {
        'userId': widget.userData['customerId'],
        'controllerId': widget.userData['controllerId'],
        'logType': 'IrrigationMotorCyclic',
        'fromDate': _apiDate(startDate),
        'toDate': _apiDate(endDate),
      };

      final response =
      await IrrigationRepository().getNovaLogDateWise(body);

      final Map<String, dynamic> jsonData =
      jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        if (jsonData['code'] == 200) {
          data = jsonData;
        } else {
          data = {};
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Motor cyclic log error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          data = {};
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onSelectionChanged(
      DateRangePickerSelectionChangedArgs args,
      ) {
    if (args.value is! PickerDateRange) return;

    final range = args.value as PickerDateRange;
    final start = range.startDate;

    if (start == null) return;

    final end = range.endDate ?? start;

    setState(() {
      _pickerStartDate = _dateOnly(start);
      _pickerEndDate = _dateOnly(end);
      _calendarDate = _dateOnly(start);

      _selectedDate =
      '${_displayDate(start)} - ${_displayDate(end)}';
    });
  }

  Future<void> _showDatePicker() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Select Date Range',
                style: TextStyle(
                  color: darkTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 330,
                height: 330,
                child: SfDateRangePicker(
                  selectionMode: DateRangePickerSelectionMode.range,
                  initialSelectedRange: PickerDateRange(
                    _pickerStartDate,
                    _pickerEndDate,
                  ),
                  onSelectionChanged: (args) {
                    _onSelectionChanged(args);
                    setDialogState(() {});
                  },
                  selectionColor: teal,
                  startRangeSelectionColor: teal,
                  endRangeSelectionColor: teal,
                  rangeSelectionColor:
                  teal.withValues(alpha: 0.15),
                  todayHighlightColor: teal,
                  headerStyle: const DateRangePickerHeaderStyle(
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _showHorizontalCalendar = true;
                      _calendarDate = _dateOnly(_pickerStartDate);
                    });

                    Navigator.pop(dialogContext);
                    getData();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _selectCalendarDate(DateTime date) {
    final selected = _dateOnly(date);

    setState(() {
      _calendarDate = selected;
      _pickerStartDate = selected;
      _pickerEndDate = selected;

      _selectedDate =
      '${_displayDate(selected)} - ${_displayDate(selected)}';
    });

    // Date select pannumbodhu alert open aagadhu.
    // Selected date-oda data mattum load aagum.
    getData();
  }

  void _changeWeek(int days) {
    setState(() {
      _calendarDate =
          _dateOnly(_calendarDate.add(Duration(days: days)));
    });
  }

  Widget _buildHorizontalCalendar() {
    final selectedDate = _selectedStartDate;

    final weekStart = _calendarDate.subtract(
      Duration(days: _calendarDate.weekday - 1),
    );

    final monthText =
    DateFormat('MMMM yyyy').format(_calendarDate);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFD7E6E8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeWeek(-7),
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: teal,
                ),
              ),
              Expanded(
                child: Text(
                  monthText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: darkTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showDatePicker,
                style: TextButton.styleFrom(
                  foregroundColor: teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                ),
                label: const Text(
                  'Month',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeWeek(7),
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(7, (index) {
              final date = _dateOnly(
                weekStart.add(Duration(days: index)),
              );

              final isSelected =
                  _dateOnly(selectedDate) == date;

              final isToday =
                  _dateOnly(DateTime.now()) == date;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => _selectCalendarDate(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? teal
                            : isToday
                            ? const Color(0xFFE7F5F6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: isSelected
                              ? teal
                              : isToday
                              ? teal.withValues(alpha: 0.35)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('EEE')
                                .format(date)
                                .toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : Colors.black54,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            DateFormat('dd').format(date),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : darkTeal,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                  ? teal
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String formatNormalTime(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '--';
    }

    final input = value.toString().trim();

    final formats = <DateFormat>[
      DateFormat('HH:mm:ss'),
      DateFormat('HH:mm'),
      DateFormat('h:mm:ss a'),
      DateFormat('h:mm a'),
      DateFormat('hh:mm:ss a'),
      DateFormat('hh:mm a'),
    ];

    for (final format in formats) {
      try {
        final parsed = format.parseStrict(input);
        return DateFormat('hh:mm:ss a').format(parsed);
      } catch (_) {
        // Try another format.
      }
    }

    try {
      final parsed = DateTime.parse(input);
      return DateFormat('hh:mm:ss a').format(parsed);
    } catch (_) {
      return input;
    }
  }

  String formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return DateFormat('dd').format(_pickerStartDate);
    }

    try {
      final parsed = DateTime.parse(value.toString());
      return DateFormat('dd').format(parsed);
    } catch (_) {
      try {
        final parsed =
        DateFormat('dd/MM/yyyy').parse(value.toString());

        return DateFormat('dd').format(parsed);
      } catch (_) {
        return value.toString();
      }
    }
  }

  String formatMonth(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return DateFormat('MMM yyyy')
          .format(_pickerStartDate)
          .toUpperCase();
    }

    try {
      final parsed = DateTime.parse(value.toString());

      return DateFormat('MMM yyyy')
          .format(parsed)
          .toUpperCase();
    } catch (_) {
      try {
        final parsed =
        DateFormat('dd/MM/yyyy').parse(value.toString());

        return DateFormat('MMM yyyy')
            .format(parsed)
            .toUpperCase();
      } catch (_) {
        return '';
      }
    }
  }

  List<dynamic> get motorCyclicList {
    final result = data['data'];

    if (result is Map && result['motorCyclic'] is List) {
      return result['motorCyclic'] as List;
    }

    return [];
  }

  List<dynamic> getZones(Map<String, dynamic> programData) {
    final zones = programData['zoneList'];

    if (zones is List) {
      return zones;
    }

    return [];
  }

  int _totalDurationSeconds(
      Map<String, dynamic> programData,
      ) {
    final converter = DataConvert();
    int totalSeconds = 0;

    for (final zone in getZones(programData)) {
      if (zone is Map) {
        totalSeconds += converter.parseTimeString(
          (zone['duration'] ?? '00:00:00').toString(),
        );
      }
    }

    return totalSeconds;
  }

  String getCyclicDuration({
    required Map<String, dynamic> programData,
  }) {
    final converter = DataConvert();

    return converter.formatTime(
      _totalDurationSeconds(programData),
    );
  }

  double _totalFlow(Map<String, dynamic> programData) {
    double total = 0;

    for (final zone in getZones(programData)) {
      if (zone is Map) {
        total += double.tryParse(
          (zone['flow'] ?? '0').toString(),
        ) ??
            0;
      }
    }

    return total;
  }

  String getCyclicFlow({
    required Map<String, dynamic> programData,
  }) {
    final total = _totalFlow(programData);

    return total == total.roundToDouble()
        ? total.toInt().toString()
        : total.toStringAsFixed(2);
  }

  String getStartTime(Map<String, dynamic> programData) {
    final zones = getZones(programData);

    if (zones.isEmpty || zones.first is! Map) {
      return '--';
    }

    return formatNormalTime(zones.first['onTime']);
  }

  String getEndTime(Map<String, dynamic> programData) {
    final zones = getZones(programData);

    if (zones.isEmpty || zones.last is! Map) {
      return '--';
    }

    return formatNormalTime(zones.last['offTime']);
  }

  String getSummaryDate(Map<String, dynamic> programData) {
    final value = programData['date'];

    if (value != null) {
      return value.toString();
    }

    return _selectedDate.split(' - ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_showHorizontalCalendar) {
            setState(() {
              _showHorizontalCalendar = false;
            });
          } else {
            _showDatePicker();
          }
        },
        backgroundColor: teal,
        foregroundColor: Colors.white,
        tooltip: 'Show calendar',
        child: Icon(
          _showHorizontalCalendar
              ? Icons.calendar_month_rounded
              : Icons.date_range_rounded,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_showHorizontalCalendar)
              _buildHorizontalCalendar(),
            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: teal),
              )
                  : motorCyclicList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  10,
                  2,
                  10,
                  90,
                ),
                itemCount: motorCyclicList.length,
                itemBuilder: (context, index) {
                  final item = motorCyclicList[index];

                  if (item is! Map) {
                    return const SizedBox.shrink();
                  }

                  final programData =
                  Map<String, dynamic>.from(item);

                  return _buildDailyLog(programData);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 55,
              color: teal.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 12),
            const Text(
              'There is no cyclic log data',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkTeal,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDate,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showDatePicker,
              icon: const Icon(Icons.date_range_rounded),
              label: const Text('Select Date'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLog(
      Map<String, dynamic> programData,
      ) {
    final zones = getZones(programData);
    final dateValue = getSummaryDate(programData);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFD5E5E9),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryCard(programData, dateValue),
          const SizedBox(height: 6),
          _buildProgramCard(programData, zones),
        ],
      ),
    );
  }

  // Summary card height and text sizes increased.
  Widget _buildSummaryCard(
      Map<String, dynamic> programData,
      String dateValue,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF104653),
            Color(0xFF07858D),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 3,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDate(dateValue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMonth(dateValue),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD0E5E9),
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _summaryItem(
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFF65E6A4),
              title: 'DURATION',
              value: getCyclicDuration(
                programData: programData,
              ),
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _summaryItem(
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFF82C9FF),
              title: 'TOTAL FLOW',
              value: getCyclicFlow(
                programData: programData,
              ),
            ),
          ),
          _summaryDivider(),
          Expanded(
            flex: 2,
            child: _summaryItem(
              icon: Icons.access_time_rounded,
              iconColor: const Color(0xFFFFCB50),
              title: 'TIME',
              value:
              '${getStartTime(programData)} to ${getEndTime(programData)}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: Colors.white.withValues(alpha: 0.22),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 17,
            color: iconColor,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD0E5E9),
              fontSize: 10,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(
      Map<String, dynamic> programData,
      List<dynamic> zones,
      ) {
    final programNumber =
    (programData['program'] ?? '-').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD6E6E9),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: teal,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  programNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Program $programNumber',
                      style: const TextStyle(
                        color: Color(0xFF17465B),
                        fontSize: 15,
                        height: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${zones.length} ${zones.length == 1 ? 'Zone' : 'Zones'}',
                      style: const TextStyle(
                        color: teal,
                        fontSize: 10,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (zones.isEmpty)
            const Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'No zone details available',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 5.0;
                final itemWidth =
                    (constraints.maxWidth - spacing) / 2;

                return Wrap(
                  spacing: spacing,
                  runSpacing: 5,
                  children: zones.map((zone) {
                    if (zone is! Map) {
                      return const SizedBox.shrink();
                    }

                    return SizedBox(
                      width: itemWidth,
                      child: _buildZoneCard(
                        Map<String, dynamic>.from(zone),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(
      Map<String, dynamic> zoneData,
      ) {
    final zoneNumber =
    (zoneData['zone'] ?? '-').toString();

    final duration =
    (zoneData['duration'] ?? '00:00:00').toString();

    final flow = (zoneData['flow'] ?? '0').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD0E3E8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 5,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF104653),
                  Color(0xFF07858D),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ZONE',
                        style: TextStyle(
                          color: Color(0xFFD0E5E9),
                          fontSize: 7,
                          height: 1,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        zoneNumber.padLeft(3, '0'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 11,
                      color: Color(0xFF119B50),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'TIMING',
                      style: TextStyle(
                        color: Color(0xFF119B50),
                        fontSize: 8,
                        height: 1,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTimingCard(
                        title: 'ON',
                        time: formatNormalTime(
                          zoneData['onTime'],
                        ),
                        icon: Icons.play_circle_filled_rounded,
                        color: const Color(0xFF159B52),
                        background: const Color(0xFFE8F6ED),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTimingCard(
                        title: 'OFF',
                        time: formatNormalTime(
                          zoneData['offTime'],
                        ),
                        icon: Icons.stop_circle_rounded,
                        color: const Color(0xFFEF4943),
                        background: const Color(0xFFFFEEEE),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildZoneValueCard(
                        title: 'Duration',
                        value: duration,
                        icon: Icons.timer_outlined,
                        color: const Color(0xFF1688FF),
                        background: const Color(0xFFE8F3FF),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildZoneValueCard(
                        title: 'Flow',
                        value: flow,
                        icon: Icons.water_drop_outlined,
                        color: const Color(0xFF009B9B),
                        background: const Color(0xFFE7F7F5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingCard({
    required String title,
    required String time,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 2),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  height: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            time,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF173D60),
              fontSize: 9,
              height: 1.1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneValueCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF173D60),
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}