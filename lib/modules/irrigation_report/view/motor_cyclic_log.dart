import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oro_drip_irrigation/Constants/data_convertion.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:excel/excel.dart' as xl;
import 'package:pdf/pdf.dart' as pdfcore;
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart' as fs;

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
  late DateTime _startDate;
  late DateTime _endDate;

  Map<String, dynamic> data = {};

  bool isLoading = true;
  bool isDownloading = false;

  static const int _pageSize = 10;
  int _page = 0;

  final ScrollController _horizontalScrollController =
  ScrollController();

  final ScrollController _verticalScrollController =
  ScrollController();

  static const double _columnGap = 12;
  static const double _horizontalPadding = 8;

  static const List<MapEntry<String, double>> _columns = [
    MapEntry('Program', 100),
    MapEntry('Zone', 90),
    MapEntry('On Time', 130),
    MapEntry('Off Time', 130),
    MapEntry('Duration', 120),
    MapEntry('Flow', 100),
  ];

  double get _minimumTableWidth {
    return _columns.fold(
      0.0,
          (sum, column) => sum + column.value,
    ) +
        (_columnGap * (_columns.length - 1)) +
        (_horizontalPadding * 2);
  }

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();

    _endDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    _startDate = _endDate.subtract(
      const Duration(days: 29),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        getData();
      }
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // DATE FORMAT
  // ------------------------------------------------------------

  String _formatApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatRecordDate(dynamic value) {
    if (value == null) return '-';

    final dateValue = value.toString().trim();

    if (dateValue.isEmpty) return '-';

    try {
      final parsedDate = DateTime.parse(dateValue);

      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (_) {
      if (dateValue.length >= 10) {
        final firstTenCharacters = dateValue.substring(0, 10);

        try {
          final parsedDate = DateTime.parse(firstTenCharacters);

          return DateFormat('yyyy-MM-dd').format(parsedDate);
        } catch (_) {
          return '-';
        }
      }
    }

    return '-';
  }

  // ------------------------------------------------------------
  // GET DATE FROM API RECORD
  // ------------------------------------------------------------

  String _getRecordDate(Map<String, dynamic> programData) {
    final possibleDateKeys = [
      'date',
      'logDate',
      'createdAt',
      'onDate',
      'startDate',
      'dateTime',
      'createdDate',
      'timestamp',
    ];

    for (final key in possibleDateKeys) {
      final value = programData[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        final formattedDate = _formatRecordDate(value);

        if (formattedDate != '-') {
          return formattedDate;
        }
      }
    }

    final zones = _getZones(programData);

    for (final zone in zones) {
      for (final key in possibleDateKeys) {
        final value = zone[key];

        if (value != null && value.toString().trim().isNotEmpty) {
          final formattedDate = _formatRecordDate(value);

          if (formattedDate != '-') {
            return formattedDate;
          }
        }
      }
    }

    return '-';
  }

  // ------------------------------------------------------------
  // API
  // ------------------------------------------------------------

  Future<void> getData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final body = {
        "userId": widget.userData['customerId'],
        "controllerId": widget.userData['controllerId'],
        "logType": "IrrigationMotorCyclic",
        "fromDate": _formatApiDate(_startDate),
        "toDate": _formatApiDate(_endDate),
      };

      debugPrint('Motor Cyclic Request: $body');

      final response =
      await IrrigationRepository().getNovaLogDateWise(body);

      final decoded = jsonDecode(response.body);

      debugPrint('Motor Cyclic Response: $decoded');

      if (!mounted) return;

      if (decoded is Map && decoded['code'] == 200) {
        final responseData = decoded['data'];

        setState(() {
          data = responseData is Map
              ? Map<String, dynamic>.from(responseData)
              : {};

          _page = 0;
        });
      } else {
        setState(() {
          data = {};
          _page = 0;
        });

        debugPrint(
          'Motor Cyclic API Error: '
              '${decoded is Map ? decoded['message'] : decoded}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error in Motor Cyclic Log: $e');
      debugPrint('StackTrace: $stackTrace');

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

  // ------------------------------------------------------------
  // DATA CHECK
  // ------------------------------------------------------------

  bool _hasLogData() {
    final motorCyclic = data['motorCyclic'];

    return motorCyclic is List && motorCyclic.isNotEmpty;
  }

  List<Map<String, dynamic>> _getPrograms() {
    final List result = data['motorCyclic'] is List
        ? data['motorCyclic']
        : [];

    return result
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _getZones(
      Map<String, dynamic> programData,
      ) {
    final List zoneList = programData['zoneList'] is List
        ? programData['zoneList']
        : [];

    return zoneList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ------------------------------------------------------------
  // GROUP PROGRAMS DATE-WISE
  // ------------------------------------------------------------

  Map<String, List<Map<String, dynamic>>> _getDateWisePrograms() {
    final programs = _getPrograms();

    final Map<String, List<Map<String, dynamic>>> groupedData = {};

    for (final program in programs) {
      final recordDate = _getRecordDate(program);

      groupedData.putIfAbsent(recordDate, () => []);

      groupedData[recordDate]!.add(program);
    }

    final sortedKeys = groupedData.keys.toList()
      ..sort((a, b) {
        if (a == '-') return 1;
        if (b == '-') return -1;

        return b.compareTo(a);
      });

    final Map<String, List<Map<String, dynamic>>> sortedData = {};

    for (final key in sortedKeys) {
      sortedData[key] = groupedData[key]!;
    }

    return sortedData;
  }

  // ------------------------------------------------------------
  // CYCLIC DURATION
  // ------------------------------------------------------------

  String getCyclicDuration({
    required Map<String, dynamic> programData,
  }) {
    final dataConvert = DataConvert();

    int totalSeconds = 0;

    final zones = _getZones(programData);

    for (final zone in zones) {
      totalSeconds += dataConvert.parseTimeString(
        (zone['duration'] ?? '00:00:00').toString(),
      );
    }

    return dataConvert.formatTime(totalSeconds);
  }

  // ------------------------------------------------------------
  // DATE-WISE TOTAL DURATION
  // ------------------------------------------------------------

  String _getDateWiseDuration(
      List<Map<String, dynamic>> programs,
      ) {
    final dataConvert = DataConvert();

    int totalSeconds = 0;

    for (final program in programs) {
      final zones = _getZones(program);

      for (final zone in zones) {
        totalSeconds += dataConvert.parseTimeString(
          (zone['duration'] ?? '00:00:00').toString(),
        );
      }
    }

    return dataConvert.formatTime(totalSeconds);
  }

  // ------------------------------------------------------------
  // CYCLIC FLOW
  // ------------------------------------------------------------

  String getCyclicFlow({
    required Map<String, dynamic> programData,
  }) {
    double totalFlow = 0;

    final zones = _getZones(programData);

    for (final zone in zones) {
      totalFlow +=
          double.tryParse((zone['flow'] ?? '0').toString()) ?? 0;
    }

    return totalFlow.toString();
  }

  // ------------------------------------------------------------
  // DATE-WISE TOTAL FLOW
  // ------------------------------------------------------------

  String _getDateWiseFlow(
      List<Map<String, dynamic>> programs,
      ) {
    double totalFlow = 0;

    for (final program in programs) {
      final zones = _getZones(program);

      for (final zone in zones) {
        totalFlow +=
            double.tryParse((zone['flow'] ?? '0').toString()) ?? 0;
      }
    }

    return totalFlow.toString();
  }

  // ------------------------------------------------------------
  // DATE-WISE START TIME
  // ------------------------------------------------------------

  String _getDateWiseStartTime(
      List<Map<String, dynamic>> programs,
      ) {
    for (final program in programs) {
      final zones = _getZones(program);

      for (final zone in zones) {
        final startTime = zone['onTime'];

        if (startTime != null &&
            startTime.toString().trim().isNotEmpty &&
            startTime.toString() != '-') {
          return startTime.toString();
        }
      }
    }

    return '-';
  }

  // ------------------------------------------------------------
  // DATE-WISE END TIME
  // ------------------------------------------------------------

  String _getDateWiseEndTime(
      List<Map<String, dynamic>> programs,
      ) {
    for (final program in programs.reversed) {
      final zones = _getZones(program);

      for (final zone in zones.reversed) {
        final endTime = zone['offTime'];

        if (endTime != null &&
            endTime.toString().trim().isNotEmpty &&
            endTime.toString() != '-') {
          return endTime.toString();
        }
      }
    }

    return '-';
  }

  // ------------------------------------------------------------
  // PAGINATION DATA
  // ------------------------------------------------------------

  Map<String, List<Map<String, dynamic>>> _getCurrentPageData() {
    final allData = _getDateWisePrograms();

    final keys = allData.keys.toList();

    final int totalPages =
    keys.isEmpty ? 1 : (keys.length / _pageSize).ceil();

    if (_page >= totalPages) {
      _page = totalPages - 1;
    }

    if (_page < 0) {
      _page = 0;
    }

    final int start = _page * _pageSize;

    final int end = (start + _pageSize).clamp(0, keys.length);

    final Map<String, List<Map<String, dynamic>>> pageData = {};

    for (final key in keys.sublist(start, end)) {
      pageData[key] = allData[key]!;
    }

    return pageData;
  }

  int get _totalDates => _getDateWisePrograms().length;

  int get _totalPages =>
      _totalDates == 0 ? 1 : (_totalDates / _pageSize).ceil();

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : !_hasLogData()
                  ? const Center(
                child: Text(
                  'There is no cyclic log data',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
                  : _buildTable(),
            ),

            if (!isLoading && _hasLogData()) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR - DATE RANGE + REFRESH
  // ------------------------------------------------------------

  Widget _buildTopBar() {
    final Color primary = Theme.of(context).primaryColorDark;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month,
            color: primary,
            size: 22,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: InkWell(
              onTap: _selectDateRange,
              child: Text(
                '${DateFormat('dd/MM/yyyy').format(_startDate)}'
                    ' - '
                    '${DateFormat('dd/MM/yyyy').format(_endDate)}',
                style: TextStyle(
                  color: primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Icons.refresh,
              color: primary,
              size: 28,
            ),
            onPressed: isLoading ? null : getData,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TABLE
  // ------------------------------------------------------------

  Widget _buildTable() {
    final Color headBg =
    Theme.of(context).primaryColorLight.withOpacity(0.25);

    final dateWisePrograms = _getCurrentPageData();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;

          final double tableWidth =
          availableWidth > _minimumTableWidth
              ? availableWidth
              : _minimumTableWidth;

          final double scale = tableWidth / _minimumTableWidth;

          final double columnGap = _columnGap * scale;

          final double horizontalPadding =
              _horizontalPadding * scale;

          double columnWidth(int index) {
            return _columns[index].value * scale;
          }

          return ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: WidgetStateProperty.all(
                Colors.grey.shade500,
              ),
              trackColor: WidgetStateProperty.all(
                Colors.grey.shade200,
              ),
              trackBorderColor: WidgetStateProperty.all(
                Colors.transparent,
              ),
              thickness: WidgetStateProperty.all(8),
              radius: const Radius.circular(10),
            ),
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 12,
                        ),
                        color: headBg,
                        child: Text(
                          'General',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColorDark,
                          ),
                        ),
                      ),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 12,
                        ),
                        color: Colors.grey.shade50,
                        child: Row(
                          children: [
                            for (int i = 0;
                            i < _columns.length;
                            i++) ...[
                              SizedBox(
                                width: columnWidth(i),
                                child: Text(
                                  _columns[i].key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              if (i != _columns.length - 1)
                                SizedBox(width: columnGap),
                            ],
                          ],
                        ),
                      ),

                      Expanded(
                        child: Scrollbar(
                          controller: _verticalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          interactive: true,
                          scrollbarOrientation:
                          ScrollbarOrientation.right,
                          child: ListView.builder(
                            controller: _verticalScrollController,
                            padding: EdgeInsets.zero,
                            itemCount: dateWisePrograms.length,
                            itemBuilder: (context, index) {
                              final date =
                              dateWisePrograms.keys.elementAt(index);

                              final programs =
                              dateWisePrograms[date]!;

                              return _dateWiseRows(
                                date,
                                programs,
                                scale,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // DATE-WISE SUMMARY AND PROGRAM ROWS
  // ------------------------------------------------------------

  Widget _dateWiseRows(
      String recordDate,
      List<Map<String, dynamic>> programs,
      double scale,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: _horizontalPadding * scale,
            vertical: 10 * scale,
          ),
          color: const Color(0xFFDCEDF1),
          child: Wrap(
            spacing: 10 * scale,
            runSpacing: 8 * scale,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                recordDate,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorDark,
                ),
              ),

              _summaryChip(
                'Cyclic Duration',
                _getDateWiseDuration(programs),
              ),

              _summaryChip(
                'Cyclic Flow',
                _getDateWiseFlow(programs),
              ),

              _summaryChip(
                'Start Time',
                _getDateWiseStartTime(programs),
              ),

              _summaryChip(
                'End Time',
                _getDateWiseEndTime(programs),
              ),
            ],
          ),
        ),

        for (final programData in programs)
          _programZoneRows(
            programData,
            scale,
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  // PROGRAM AND ZONE ROWS
  // ------------------------------------------------------------

  Widget _programZoneRows(
      Map<String, dynamic> programData,
      double scale,
      ) {
    final zones = _getZones(programData);

    final String program =
    (programData['program'] ?? '-').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final zone in zones)
          _zoneRow(
            program,
            zone,
            scale,
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SUMMARY CHIP - SAME STYLE AS ZONE CYCLIC LOG
  // ------------------------------------------------------------

  Widget _summaryChip(
      String title,
      String value,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
          children: [
            TextSpan(text: '$title: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ZONE ROW
  // ------------------------------------------------------------

  Widget _zoneRow(
      String program,
      Map<String, dynamic> zone,
      double scale,
      ) {
    final values = <dynamic>[
      program,
      zone['zone'],
      zone['onTime'],
      zone['offTime'],
      zone['duration'],
      zone['flow'],
    ];

    final double columnGap = _columnGap * scale;

    final double horizontalPadding =
        _horizontalPadding * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _columns.length; i++) ...[
            SizedBox(
              width: _columns[i].value * scale,
              child: Text(
                '${values[i] ?? '-'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight:
                  i < 2 ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            if (i != _columns.length - 1)
              SizedBox(width: columnGap),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM BAR - PAGINATION / SELECT DATE / DOWNLOAD
  // ------------------------------------------------------------

  Widget _buildBottomBar() {
    final int total = _totalDates;

    final int start = total == 0 ? 0 : (_page * _pageSize) + 1;

    final int end =
    ((_page + 1) * _pageSize).clamp(0, total);

    final Color primary = Theme.of(context).primaryColorDark;

    return Container(
      width: double.infinity,
      color: primary,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      child: Row(
        children: [
          Container(
            color: Colors.white,
            child: IconButton(
              tooltip: 'Previous',
              onPressed: _page > 0
                  ? () {
                setState(() {
                  _page--;
                });

                _verticalScrollController.jumpTo(0);
              }
                  : null,
              icon: const Icon(
                Icons.keyboard_double_arrow_left,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            '$start - $end / $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 10),

          Container(
            color: Colors.white,
            child: IconButton(
              tooltip: 'Next',
              onPressed: _page + 1 < _totalPages
                  ? () {
                setState(() {
                  _page++;
                });

                _verticalScrollController.jumpTo(0);
              }
                  : null,
              icon: const Icon(
                Icons.keyboard_double_arrow_right,
              ),
            ),
          ),

          const Spacer(),

          ElevatedButton(
            onPressed: _selectDateRange,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
            ),
            child: const Text(
              'Select Date',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Spacer(),

          Container(
            color: Colors.white,
            child: IconButton(
              tooltip: 'Download',
              onPressed:
              isDownloading ? null : _showDownloadDialog,
              icon: const Icon(
                Icons.download,
                color: Colors.black,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SELECT DATE RANGE - SYNCFUSION DATE RANGE PICKER
  // ------------------------------------------------------------

  Future<void> _selectDateRange() async {
    DateTime pickerStartDate = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );

    DateTime pickerEndDate = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
    );

    final DateTime today = DateTime.now();

    final DateTime maximumDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final bool? isSubmitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFE5EAEB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              child: SizedBox(
                width: 350,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    22,
                    22,
                    16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Date Picker',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF303638),
                          ),
                        ),
                      ),

                      Container(
                        color: const Color(0xFFF0EAF7),
                        child: SfDateRangePicker(
                          view: DateRangePickerView.month,
                          selectionMode:
                          DateRangePickerSelectionMode.range,
                          initialSelectedRange: PickerDateRange(
                            pickerStartDate,
                            pickerEndDate,
                          ),
                          initialDisplayDate: pickerEndDate,
                          minDate: DateTime(2000),
                          maxDate: maximumDate,
                          showNavigationArrow: true,
                          showTodayButton: false,
                          allowViewNavigation: false,
                          selectionColor:
                          const Color(0xFF007681),
                          startRangeSelectionColor:
                          const Color(0xFF007681),
                          endRangeSelectionColor:
                          const Color(0xFF007681),
                          rangeSelectionColor:
                          const Color(0xFFB2DFDB),
                          todayHighlightColor:
                          const Color(0xFF007681),
                          backgroundColor:
                          const Color(0xFFF0EAF7),
                          headerHeight: 45,
                          headerStyle:
                          const DateRangePickerHeaderStyle(
                            backgroundColor:
                            Color(0xFFF0EAF7),
                            textAlign: TextAlign.center,
                            textStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF303638),
                            ),
                          ),
                          monthViewSettings:
                          const DateRangePickerMonthViewSettings(
                            firstDayOfWeek: 7,
                            dayFormat: 'EEE',
                          ),
                          monthCellStyle:
                          const DateRangePickerMonthCellStyle(
                            textStyle: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF424242),
                            ),
                            todayTextStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF007681),
                            ),
                            disabledDatesTextStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          selectionTextStyle:
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          onSelectionChanged:
                              (DateRangePickerSelectionChangedArgs args) {
                            if (args.value is PickerDateRange) {
                              final PickerDateRange range =
                              args.value as PickerDateRange;

                              setDialogState(() {
                                if (range.startDate != null) {
                                  pickerStartDate = DateTime(
                                    range.startDate!.year,
                                    range.startDate!.month,
                                    range.startDate!.day,
                                  );
                                }

                                if (range.endDate != null) {
                                  pickerEndDate = DateTime(
                                    range.endDate!.year,
                                    range.endDate!.month,
                                    range.endDate!.day,
                                  );
                                } else {
                                  pickerEndDate = pickerStartDate;
                                }

                                if (pickerStartDate.isAfter(
                                  pickerEndDate,
                                )) {
                                  final DateTime temp =
                                      pickerStartDate;

                                  pickerStartDate = pickerEndDate;
                                  pickerEndDate = temp;
                                }
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, false);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                              const Color(0xFF007681),
                              side: const BorderSide(
                                color: Color(0xFF007681),
                              ),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 10,
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFF007681),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (isSubmitted != true || !mounted) return;

    setState(() {
      _startDate = DateTime(
        pickerStartDate.year,
        pickerStartDate.month,
        pickerStartDate.day,
      );

      _endDate = DateTime(
        pickerEndDate.year,
        pickerEndDate.month,
        pickerEndDate.day,
      );

      _page = 0;
    });

    _verticalScrollController.jumpTo(0);

    await getData();
  }

  // ------------------------------------------------------------
  // DOWNLOAD DIALOG
  // ------------------------------------------------------------

  Future<void> _showDownloadDialog() async {
    final TextEditingController fileNameController =
    TextEditingController(text: 'file');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Give Name For Your File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: fileNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final name = fileNameController.text.trim();

                if (name.isEmpty) return;

                Navigator.pop(dialogContext);

                await _downloadExcel(name);
              },
              child: const Text(
                'Download Excel',
                style: TextStyle(
                  color: Color(0xFF006D78),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D78),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                final name = fileNameController.text.trim();

                if (name.isEmpty) return;

                Navigator.pop(dialogContext);

                await _downloadPdf(name);
              },
              child: const Text(
                'Download PDF',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );

    fileNameController.dispose();
  }

  // ------------------------------------------------------------
  // EXPORT ROWS - DATE WISE
  // ------------------------------------------------------------

  List<List<String>> _getExportRows() {
    final List<List<String>> result = [];

    result.add([
      'Date',
      ..._columns.map((column) => column.key),
    ]);

    final dateWisePrograms = _getDateWisePrograms();

    for (final dateEntry in dateWisePrograms.entries) {
      final date = dateEntry.key;
      final programs = dateEntry.value;

      for (final programData in programs) {
        final program =
        (programData['program'] ?? '-').toString();

        final zones = _getZones(programData);

        for (final zone in zones) {
          result.add([
            date == '-'
                ? '-'
                : DateFormat('dd/MM/yyyy').format(
              DateTime.parse(date),
            ),
            program,
            '${zone['zone'] ?? '-'}',
            '${zone['onTime'] ?? '-'}',
            '${zone['offTime'] ?? '-'}',
            '${zone['duration'] ?? '-'}',
            '${zone['flow'] ?? '-'}',
          ]);
        }
      }
    }

    return result;
  }

  // ------------------------------------------------------------
  // CLEAN FILE NAME
  // ------------------------------------------------------------

  String _cleanFileName(String name) {
    final cleaned = name.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    return cleaned.isEmpty ? 'file' : cleaned;
  }

  // ------------------------------------------------------------
  // DOWNLOAD EXCEL
  // ------------------------------------------------------------

  Future<void> _downloadExcel(String fileName) async {
    if (isDownloading) return;

    setState(() {
      isDownloading = true;
    });

    try {
      final exportRows = _getExportRows();

      if (exportRows.length <= 1) {
        _showExportMessage('No data available to download');
        return;
      }

      final xl.Excel excel = xl.Excel.createExcel();

      final xl.Sheet sheet = excel['Motor Cyclic Log'];

      for (final row in exportRows) {
        sheet.appendRow(
          row.map((value) => xl.TextCellValue(value)).toList(),
        );
      }

      final List<int>? bytes = excel.encode();

      if (bytes == null) {
        _showExportMessage('Excel file creation failed');
        return;
      }

      await fs.FileSaver.instance.saveAs(
        name: _cleanFileName(fileName),
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: fs.MimeType.custom,
        customMimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      _showExportMessage('Excel downloaded successfully');
    } catch (e, stackTrace) {
      debugPrint('Excel Download Error: $e');
      debugPrint('Excel Download StackTrace: $stackTrace');

      _showExportMessage('Excel download failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // DOWNLOAD PDF
  // ------------------------------------------------------------

  Future<void> _downloadPdf(String fileName) async {
    if (isDownloading) return;

    setState(() {
      isDownloading = true;
    });

    try {
      final exportRows = _getExportRows();

      if (exportRows.length <= 1) {
        _showExportMessage('No data available to download');
        return;
      }

      final pw.Document pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: pdfcore.PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return [
              pw.Text(
                'Motor Cyclic Log',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 12),

              pw.Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(_startDate)}'
                    ' - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                style: const pw.TextStyle(fontSize: 10),
              ),

              pw.SizedBox(height: 12),

              pw.Table.fromTextArray(
                headers: exportRows.first,
                data: exportRows.skip(1).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: pdfcore.PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: pdfcore.PdfColors.teal,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(
                  color: pdfcore.PdfColors.grey400,
                  width: 0.5,
                ),
                cellPadding: const pw.EdgeInsets.all(5),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();

      await fs.FileSaver.instance.saveAs(
        name: _cleanFileName(fileName),
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'pdf',
        mimeType: fs.MimeType.pdf,
      );

      _showExportMessage('PDF downloaded successfully');
    } catch (e, stackTrace) {
      debugPrint('PDF Download Error: $e');
      debugPrint('PDF Download StackTrace: $stackTrace');

      _showExportMessage('PDF download failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // EXPORT MESSAGE
  // ------------------------------------------------------------

  void _showExportMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}