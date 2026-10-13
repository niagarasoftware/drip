import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../../Widgets/custom_buttons.dart';
import '../../../models/customer/site_model.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import '../repository/irrigation_repository.dart';
import 'zone_log_exporter_stub.dart'
    if (dart.library.html) 'zone_log_exporter_web.dart';

class ZoneLogEntry {
  final int no;
  final String dateKey; // yyyy-MM-dd
  final String dateHeader; // dd/MM/yyyy (E)
  final String progName;
  final int progSNo;
  final String seqName;
  final String headUnit;
  final String pump;
  final String durationQty;
  final String qtyCompleted;
  final String durationCompleted;
  final int durationSeconds;
  final String durationStr;
  final bool hasRun;

  ZoneLogEntry({
    required this.no,
    required this.dateKey,
    required this.dateHeader,
    required this.progName,
    required this.progSNo,
    required this.seqName,
    required this.headUnit,
    required this.pump,
    required this.durationQty,
    required this.qtyCompleted,
    required this.durationCompleted,
    required this.durationSeconds,
    required this.durationStr,
    required this.hasRun,
  });

  // Getters for PDF/Excel exporter compatibility
  String get dateStr => dateHeader;
  String get programTitle => progName;
  String get sequenceTitle => seqName;
  String get duration => durationStr;
  String get startTime => durationQty;
  String get endTime => qtyCompleted;
  String get startReason => durationCompleted;
  String get endReason => '-';
}

class SequenceDayData {
  int durationQtySeconds;
  int durationCompletedSeconds;
  int quantityCompleted;
  bool hasRun;

  SequenceDayData({
    this.durationQtySeconds = 0,
    this.durationCompletedSeconds = 0,
    this.quantityCompleted = 0,
    this.hasRun = false,
  });

  String get durationQtyStr => durationQtySeconds > 0
      ? _formatSecondsToHMS(durationQtySeconds)
      : '00:00:00';
  String get qtyCompletedStr => quantityCompleted.toString();

  static String _formatSecondsToHMS(int totalSeconds) {
    if (totalSeconds <= 0) return "00:00:00";
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    String hStr = hours.toString().padLeft(2, '0');
    String mStr = minutes.toString().padLeft(2, '0');
    String sStr = seconds.toString().padLeft(2, '0');
    return "$hStr:$mStr:$sStr";
  }
}

class SequenceRowData {
  final String key;
  final String progName;
  final int progSNo;
  final String seqName;
  final Map<String, SequenceDayData> dayEntries; // dateKey -> SequenceDayData
  int totalDurationSeconds;
  int totalQuantity;

  SequenceRowData({
    required this.key,
    required this.progName,
    required this.progSNo,
    required this.seqName,
    required this.dayEntries,
    this.totalDurationSeconds = 0,
    this.totalQuantity = 0,
  });
}

class ZoneLog extends StatefulWidget {
  final Map<String, dynamic> userData;
  final MasterControllerModel? masterData;

  const ZoneLog({
    super.key,
    required this.userData,
    this.masterData,
  });

  @override
  State<ZoneLog> createState() => _ZoneLogState();
}

class _ZoneLogState extends State<ZoneLog> with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _horizontalScrollController = ScrollController();
  late final LinkedScrollControllerGroup _verticalScrollGroup;
  late final ScrollController _pinnedLeftVerticalController;
  late final ScrollController _verticalScrollController;
  late final ScrollController _pinnedTotalVerticalController;

  @override
  bool get wantKeepAlive => true;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 4));
  DateTime _toDate = DateTime.now();
  String _selectedProgramFilter = 'All Programs';

  bool _isLoading = false;
  List<SequenceRowData> _sequenceRows = [];
  List<DateTime> _dateColumns = [];
  List<String> _programDropdownOptions = ['All Programs'];
  int _selectedViewTab = 0; // 0 = Table View, 1 = Graph View
  String _selectedGraphMetric =
      'Duration'; // 'Duration' (Green) or 'Quantity' (Orange)
  String _graphChartType = 'Column'; // 'Column', 'Spline', 'Area'
  final Set<String> _expandedBreakdownKeys = {};


  @override
  void initState() {
    super.initState();
    _verticalScrollGroup = LinkedScrollControllerGroup();
    _pinnedLeftVerticalController = _verticalScrollGroup.addAndGet();
    _verticalScrollController = _verticalScrollGroup.addAndGet();
    _pinnedTotalVerticalController = _verticalScrollGroup.addAndGet();

    fetchZoneLogApi();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _pinnedLeftVerticalController.dispose();
    _verticalScrollController.dispose();
    _pinnedTotalVerticalController.dispose();
    super.dispose();
  }

  int _parseDurationSeconds(String start, String end) {
    if (start.isEmpty ||
        end.isEmpty ||
        start == '-' ||
        end == '-' ||
        start == '--' ||
        end == '--') {
      return 0;
    }
    try {
      var sParts = start.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      var eParts = end.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      int sSec = sParts[0] * 3600 +
          (sParts.length > 1 ? sParts[1] * 60 : 0) +
          (sParts.length > 2 ? sParts[2] : 0);
      int eSec = eParts[0] * 3600 +
          (eParts.length > 1 ? eParts[1] * 60 : 0) +
          (eParts.length > 2 ? eParts[2] : 0);
      int diff = eSec - sSec;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  int _parseDurationToSeconds(String dur) {
    if (dur.isEmpty || dur == '-' || dur == '--' || dur == '00:00:00') {
      return 0;
    }
    try {
      dur = dur.trim();
      var parts =
          dur.split(':').map((e) => int.tryParse(e.trim()) ?? 0).toList();
      if (parts.length == 3) {
        return parts[0] * 3600 + parts[1] * 60 + parts[2];
      } else if (parts.length == 2) {
        return parts[0] * 60 + parts[1];
      }
      return int.tryParse(dur) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return "0h 0m";
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    if (seconds > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    }
    return "${hours}h ${minutes}m";
  }

  Future<void> fetchZoneLogApi() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    String fromDateStr = DateFormat('yyyy-MM-dd').format(_fromDate);
    String toDateStr = DateFormat('yyyy-MM-dd').format(_toDate);

    Map<String, dynamic> body = {
      "userId": widget.userData['customerId'] ?? 1002,
      "controllerId": widget.userData['controllerId'] ?? 3382,
      "logType": "Irrigation",
      "fromDate": fromDateStr,
      "toDate": toDateStr,
      "parameters": [
        "Date",
        "ProgramS_No",
        "ZoneS_No",
        "HeadUnit",
        "Pump",
        "ActualStartTime",
        "ActualEndTime",
        "ActualStartReason",
        "ActualStopReason",
        "IrrigationDurationCompleted",
        "ProgramName",
        "IrrigationMethod",
        "IrrigationDuration_Quantity",
        "IrrigationQuantityCompleted"
      ]
    };

    debugPrint('====================================');
    debugPrint('ZONE LOG API REQUEST BODY: ${jsonEncode(body)}');
    debugPrint('====================================');

    try {
      var response = await IrrigationRepository().getLogDateWise(body);
      debugPrint('ZONE LOG API RESPONSE CODE: ${response.statusCode}');

      Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['code'] == 200 && jsonData['data'] != null) {
        _parseZoneApiResponse(jsonData['data']);
      } else {
        if (mounted) {
          setState(() {
            _sequenceRows = [];
            _dateColumns = [];
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error in Zone Log API: ${e.toString()}');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _sequenceRows = [];
          _dateColumns = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _parseZoneApiResponse(Map<String, dynamic> responseData) {
    // 1. Build Sequence & Program Names
    Map<String, String> sequenceNameMap = {};
    Map<int, String> programNameMap = {};
    Set<String> uniqueProgNames = {'All Programs'};
    List<Map<String, dynamic>> defaultSequenceList = [];

    if (responseData['default'] != null) {
      var defaultObj = responseData['default'];

      if (defaultObj['sequence'] != null && defaultObj['sequence'] is List) {
        for (var seq in defaultObj['sequence']) {
          if (seq is Map) {
            var sNo = seq['sNo'];
            String name =
                seq['name'] ?? seq['seqName'] ?? seq['sequenceName'] ?? '';
            if (sNo != null && name.isNotEmpty) {
              sequenceNameMap[sNo.toString()] = name;
              if (sNo is num) {
                sequenceNameMap[sNo.toInt().toString()] = name;
                sequenceNameMap[sNo.toDouble().toString()] = name;
              }
            }
            defaultSequenceList.add(Map<String, dynamic>.from(seq));
          }
        }
      }

      if (defaultObj['zone'] != null && defaultObj['zone'] is List) {
        for (var z in defaultObj['zone']) {
          if (z is Map) {
            var sNo = z['sNo'];
            String name = z['name'] ?? z['zoneName'] ?? '';
            if (sNo != null && name.isNotEmpty) {
              sequenceNameMap.putIfAbsent(sNo.toString(), () => name);
            }
          }
        }
      }

      if (defaultObj['program'] != null && defaultObj['program'] is List) {
        for (var p in defaultObj['program']) {
          if (p is Map) {
            int sNo = p['sNo'] is int
                ? p['sNo']
                : int.tryParse(p['sNo'].toString()) ?? 0;
            String name = p['name'] ?? 'Program $sNo';
            programNameMap[sNo] = name;
          }
        }
      }
    }

    // 2. Generate date columns list from _fromDate to _toDate
    List<DateTime> dates = [];
    DateTime cur = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
    DateTime end = DateTime(_toDate.year, _toDate.month, _toDate.day);
    while (!cur.isAfter(end)) {
      dates.add(cur);
      cur = cur.add(const Duration(days: 1));
    }

    // Pre-create SequenceRowData map for all default sequences in default order
    Map<String, SequenceRowData> rowsMap = {};

    for (var seq in defaultSequenceList) {
      String name = seq['name'] ?? seq['seqName'] ?? '';
      String loc = seq['locationName'] ?? '';
      int pSNo = 1;
      if (loc.startsWith("Program")) {
        pSNo = int.tryParse(loc.replaceAll("Program", "").trim()) ?? 1;
      } else if (seq['sNo'] != null) {
        var sParts = seq['sNo'].toString().split('.');
        if (sParts.isNotEmpty) pSNo = int.tryParse(sParts[0]) ?? 1;
      }
      String progName = programNameMap[pSNo] ?? 'Program $pSNo';
      String key = "${pSNo}_$name";
      uniqueProgNames.add(progName);

      rowsMap.putIfAbsent(
        key,
        () => SequenceRowData(
          key: key,
          progName: progName,
          progSNo: pSNo,
          seqName: name,
          dayEntries: {},
        ),
      );
    }

    List<ZoneLogEntry> allRawExportEntries = [];
    int itemGlobalNo = 1;

    // 3. Parse log entries and accumulate totals per sequence per date
    if (responseData['log'] != null && responseData['log'] is List) {
      List logs = responseData['log'];

      for (var logEntry in logs) {
        String rawLogDate = logEntry['logDate'] ?? '';
        if (rawLogDate.isEmpty) continue;

        DateTime parsedDate;
        try {
          parsedDate = DateFormat('yyyy-MM-dd').parse(rawLogDate);
        } catch (_) {
          parsedDate = DateTime.now();
        }

        var irrigation = logEntry['irrigation'];
        if (irrigation == null) continue;

        List recordDates = irrigation['Date'] ?? [];
        List programSNos = irrigation['ProgramS_No'] ?? [];
        List zoneSNos = irrigation['ZoneS_No'] ?? [];
        List headUnits = irrigation['HeadUnit'] ?? [];
        List pumps = irrigation['Pump'] ?? [];
        List durationQtys = irrigation['IrrigationDuration_Quantity'] ?? [];
        List durationCompleteds =
            irrigation['IrrigationDurationCompleted'] ?? [];
        List qtyCompleteds = irrigation['IrrigationQuantityCompleted'] ?? [];
        List actualStopTimes = irrigation['ActualEndTime'] ?? [];
        List actualStartTimes = irrigation['ActualStartTime'] ?? [];

        int baseLength = [
          recordDates.length,
          programSNos.length,
          zoneSNos.length,
          headUnits.length,
          pumps.length,
          durationQtys.length,
          durationCompleteds.length,
          qtyCompleteds.length,
          actualStopTimes.length,
          actualStartTimes.length,
        ].reduce((curr, next) => curr > next ? curr : next);

        for (int i = 0; i < baseLength; i++) {
          String itemDateStr = (i < recordDates.length &&
                  recordDates[i] != null &&
                  recordDates[i].toString().isNotEmpty)
              ? recordDates[i].toString()
              : rawLogDate;

          DateTime itemParsedDate;
          try {
            itemParsedDate = DateFormat('yyyy-MM-dd').parse(itemDateStr);
          } catch (_) {
            itemParsedDate = parsedDate;
          }
          String itemDateKey = DateFormat('yyyy-MM-dd').format(itemParsedDate);
          String itemDateHeader =
              DateFormat('dd/MM/yyyy (E)').format(itemParsedDate);

          int pSNo = 1;
          if (i < programSNos.length && programSNos[i] != null) {
            pSNo = programSNos[i] is int
                ? programSNos[i]
                : int.tryParse(programSNos[i].toString()) ?? 1;
          } else if (i < zoneSNos.length && zoneSNos[i] != null) {
            var zParts = zoneSNos[i].toString().split('.');
            if (zParts.isNotEmpty) {
              pSNo = int.tryParse(zParts[0]) ?? 1;
            }
          }

          String progName = programNameMap[pSNo] ?? 'Program $pSNo';

          var zVal = (i < zoneSNos.length) ? zoneSNos[i] : null;
          String seqName = '';
          if (zVal != null) {
            String zStr = zVal.toString().trim();
            if (sequenceNameMap.containsKey(zStr) &&
                sequenceNameMap[zStr]!.isNotEmpty) {
              seqName = sequenceNameMap[zStr]!;
            } else {
              double? zDouble = double.tryParse(zStr);
              if (zDouble != null) {
                if (sequenceNameMap.containsKey(zDouble.toString()) &&
                    sequenceNameMap[zDouble.toString()]!.isNotEmpty) {
                  seqName = sequenceNameMap[zDouble.toString()]!;
                } else {
                  int zInt = zDouble.toInt();
                  if (sequenceNameMap.containsKey(zInt.toString()) &&
                      sequenceNameMap[zInt.toString()]!.isNotEmpty) {
                    seqName = sequenceNameMap[zInt.toString()]!;
                  } else if (programNameMap.containsKey(zInt) &&
                      programNameMap[zInt]!.isNotEmpty) {
                    seqName = programNameMap[zInt]!;
                  }
                }
              }
            }
          }

          if (seqName.isEmpty &&
              sequenceNameMap.containsKey(pSNo.toString()) &&
              sequenceNameMap[pSNo.toString()]!.isNotEmpty) {
            seqName = sequenceNameMap[pSNo.toString()]!;
          }

          if (seqName.isEmpty) {
            seqName = (zVal != null && zVal.toString().isNotEmpty)
                ? "Sequence ${zVal.toString()}"
                : progName;
          }

          String headUnitStr = (i < headUnits.length &&
                  headUnits[i] != null &&
                  headUnits[i].toString().isNotEmpty)
              ? headUnits[i].toString()
              : '2.001';
          String pumpStr = (i < pumps.length &&
                  pumps[i] != null &&
                  pumps[i].toString().isNotEmpty)
              ? pumps[i].toString()
              : '5.002';

          uniqueProgNames.add(progName);

          String durationQtyStr = (i < durationQtys.length &&
                  durationQtys[i] != null &&
                  durationQtys[i].toString().isNotEmpty)
              ? durationQtys[i].toString().trim()
              : '-';

          String durationCompletedStr = (i < durationCompleteds.length &&
                  durationCompleteds[i] != null &&
                  durationCompleteds[i].toString().isNotEmpty)
              ? durationCompleteds[i].toString().trim()
              : '00:00:00';

          String qtyCompletedStr =
              (i < qtyCompleteds.length && qtyCompleteds[i] != null)
                  ? qtyCompleteds[i].toString().trim()
                  : '0';

          int durationQtySec = _parseDurationToSeconds(durationQtyStr);
          int durCompletedSec = _parseDurationToSeconds(durationCompletedStr);
          if (durCompletedSec == 0 &&
              i < actualStartTimes.length &&
              i < actualStopTimes.length &&
              actualStartTimes[i] != null &&
              actualStopTimes[i] != null) {
            durCompletedSec = _parseDurationSeconds(
                actualStartTimes[i].toString(), actualStopTimes[i].toString());
          }

          int qtyCompletedVal = int.tryParse(qtyCompletedStr) ?? 0;

          String rowKey = "${pSNo}_$seqName";
          SequenceRowData rowData = rowsMap.putIfAbsent(
            rowKey,
            () => SequenceRowData(
              key: rowKey,
              progName: progName,
              progSNo: pSNo,
              seqName: seqName,
              dayEntries: {},
            ),
          );

          SequenceDayData dayData = rowData.dayEntries.putIfAbsent(
            itemDateKey,
            () => SequenceDayData(),
          );

          dayData.durationQtySeconds += durationQtySec;
          dayData.durationCompletedSeconds += durCompletedSec;
          dayData.quantityCompleted += qtyCompletedVal;
          dayData.hasRun = true;

          // For raw export
          allRawExportEntries.add(
            ZoneLogEntry(
              no: itemGlobalNo++,
              dateKey: itemDateKey,
              dateHeader: itemDateHeader,
              progName: progName,
              progSNo: pSNo,
              seqName: seqName,
              headUnit: headUnitStr,
              pump: pumpStr,
              durationQty: durationQtyStr,
              qtyCompleted: qtyCompletedStr,
              durationCompleted: durationCompletedStr,
              durationSeconds: durCompletedSec,
              durationStr: _formatDuration(durCompletedSec),
              hasRun: true,
            ),
          );
        }
      }
    }

    // 4. Calculate total durations and quantities for each row
    List<SequenceRowData> rows = rowsMap.values.toList();
    for (var r in rows) {
      int sumSec = 0;
      int sumQty = 0;
      for (var d in r.dayEntries.values) {
        sumSec += d.durationQtySeconds;
        sumQty += d.quantityCompleted;
      }
      r.totalDurationSeconds = sumSec;
      r.totalQuantity = sumQty;
    }

    // 5. Sort rows by Program SNo, then Sequence Name
    rows.sort((a, b) {
      if (a.progSNo != b.progSNo) return a.progSNo.compareTo(b.progSNo);
      return a.seqName.compareTo(b.seqName);
    });

    if (mounted) {
      setState(() {
        _dateColumns = dates;
        _sequenceRows = rows;
        _programDropdownOptions = uniqueProgNames.toList();
      });
    }
  }

  List<SequenceRowData> _getFilteredSequenceRows() {
    if (_selectedProgramFilter == 'All Programs') {
      return _sequenceRows;
    }
    return _sequenceRows
        .where((r) => r.progName == _selectedProgramFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final primaryDark = Theme.of(context).primaryColorDark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Filter Card
              Center(child: _buildFilterCard(context)),
              const SizedBox(height: 10),
              // Date Navigation Banner
              _buildDateNavigationBanner(context, primaryDark),
              // Multi-Day Matrix Table or Graph View
              Expanded(
                child: _selectedViewTab == 0
                    ? _buildMultiDayMatrixTable(context)
                    : _buildZoneLogGraphView(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExcelExport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var filteredRows = _getFilteredSequenceRows();
    if (_dateColumns.isEmpty || filteredRows.isEmpty) {
      messenger.showSnackBar(
        CustomSnackBar(message: "No records available to export"),
      );
      return;
    }

    // Calculate daily total durations and quantities
    Map<String, int> dailyTotals = {};
    Map<String, int> dailyTotalQuantities = {};
    int grandTotalSeconds = 0;
    int grandTotalQuantity = 0;
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int daySum = 0;
      int dayQty = 0;
      for (var r in filteredRows) {
        if (r.dayEntries.containsKey(dKey)) {
          daySum += r.dayEntries[dKey]!.durationQtySeconds;
          dayQty += r.dayEntries[dKey]!.quantityCompleted;
        }
      }
      dailyTotals[dKey] = daySum;
      dailyTotalQuantities[dKey] = dayQty;
      grandTotalSeconds += daySum;
      grandTotalQuantity += dayQty;
    }

    String sanitizeName = (_selectedProgramFilter != 'All Programs'
            ? _selectedProgramFilter
            : 'ZoneLog_${DateFormat('yyyyMMdd').format(_fromDate)}_${DateFormat('yyyyMMdd').format(_toDate)}')
        .replaceAll(RegExp(r'[^\w\s\-]'), '_');
    String fileName =
        "${sanitizeName}_${DateFormat('yyyyMMdd').format(DateTime.now())}";

    String? res = await exportZoneLogMatrixToExcel(
      dateColumns: _dateColumns,
      rows: filteredRows,
      dailyTotals: dailyTotals,
      dailyTotalQuantities: dailyTotalQuantities,
      grandTotalSeconds: grandTotalSeconds,
      grandTotalQuantity: grandTotalQuantity,
      fileName: fileName,
    );

    if (res != null) {
      messenger.showSnackBar(
        CustomSnackBar(message: "Excel downloaded successfully: $res"),
      );
    } else {
      messenger.showSnackBar(
        CustomSnackBar(message: "Failed to export Excel"),
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTime tempStart = _fromDate;
    DateTime tempEnd = _toDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Date Picker',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter stateSetter) {
              return SizedBox(
                width: 250,
                height: 280,
                child: SfDateRangePicker(
                  selectionMode: DateRangePickerSelectionMode.range,
                  initialSelectedRange: PickerDateRange(_fromDate, _toDate),
                  onSelectionChanged:
                      (DateRangePickerSelectionChangedArgs args) {
                    if (args.value is PickerDateRange) {
                      final PickerDateRange range =
                          args.value as PickerDateRange;
                      if (range.startDate != null) {
                        tempStart = range.startDate!;
                        tempEnd = range.endDate ?? range.startDate!;
                      }
                    }
                  },
                ),
              );
            },
          ),
          actions: [
            CustomMaterialButton(
              title: 'Cancel',
              outlined: true,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CustomMaterialButton(
              title: 'OK',
              onPressed: () {
                setState(() {
                  _fromDate = tempStart;
                  _toDate = tempEnd;
                });
                Navigator.pop(context);
                fetchZoneLogApi();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 650;

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Date Range Selection
                Row(
                  children: [
                    const Text("Date Range",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDateRange(context),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${DateFormat('dd MMM yyyy').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)}",
                                  style: const TextStyle(fontSize: 11.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.calendar_today,
                                  size: 14, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Program Filter & Excel Button
                Row(
                  children: [
                    // Program Dropdown
                    Expanded(
                      child: Row(
                        children: [
                          const Text("Program",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              height: 36,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _programDropdownOptions
                                          .contains(_selectedProgramFilter)
                                      ? _selectedProgramFilter
                                      : 'All Programs',
                                  isDense: true,
                                  isExpanded: true,
                                  items: _programDropdownOptions
                                      .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 11.5))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedProgramFilter = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Excel Button
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 36),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _handleExcelExport(context),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.table_chart,
                              size: 13, color: Color(0xFF2E7D32)),
                          SizedBox(width: 3),
                          Text("Excel",
                              style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // Desktop / Tablet layout
          return Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Date Range Picker
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Date Range",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _selectDateRange(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${DateFormat('dd MMM yyyy').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)}",
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today,
                              size: 16, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Program Filter Dropdown
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Program",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _programDropdownOptions
                                .contains(_selectedProgramFilter)
                            ? _selectedProgramFilter
                            : 'All Programs',
                        isDense: true,
                        items: _programDropdownOptions
                            .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedProgramFilter = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Excel Export Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () => _handleExcelExport(context),
                    icon: const Icon(Icons.table_chart,
                        size: 14, color: Color(0xFF2E7D32)),
                    label: const Text("Excel",
                        style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateNavigationBanner(BuildContext context, Color primaryDark) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: const BoxDecoration(
        color: Color(0xFF00695C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              // Row(
              //   mainAxisSize: MainAxisSize.min,
              //   children: [
              //     const Icon(Icons.table_chart, size: 16, color: Colors.white),
              //     const SizedBox(width: 8),
              //     Text(
              //       "Zone Log (${DateFormat('dd MMM yyyy').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)})",
              //       style: const TextStyle(
              //         color: Colors.white,
              //         fontWeight: FontWeight.bold,
              //         fontSize: 13,
              //       ),
              //     ),
              //   ],
              // ),
              // Table View & Graph View Toggle Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        if (_selectedViewTab != 0) {
                          setState(() {
                            _selectedViewTab = 0;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _selectedViewTab == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _selectedViewTab == 0
                              ? const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.table_rows_outlined,
                              size: 14,
                              color: _selectedViewTab == 0
                                  ? const Color(0xFF00695C)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Table View",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: _selectedViewTab == 0
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _selectedViewTab == 0
                                    ? const Color(0xFF00695C)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: () {
                        if (_selectedViewTab != 1) {
                          setState(() {
                            _selectedViewTab = 1;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _selectedViewTab == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _selectedViewTab == 1
                              ? const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              size: 14,
                              color: _selectedViewTab == 1
                                  ? const Color(0xFF00695C)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Graph View",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: _selectedViewTab == 1
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _selectedViewTab == 1
                                    ? const Color(0xFF00695C)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMultiDayMatrixTable(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    var filteredRows = _getFilteredSequenceRows();

    if (_dateColumns.isEmpty || filteredRows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            "No data",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Calculate daily total durations and quantities
    Map<String, int> dailyTotals = {};
    Map<String, int> dailyTotalQuantities = {};
    int grandTotalSeconds = 0;
    int grandTotalQuantity = 0;
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int daySum = 0;
      int dayQty = 0;
      for (var r in filteredRows) {
        if (r.dayEntries.containsKey(dKey)) {
          daySum += r.dayEntries[dKey]!.durationQtySeconds;
          dayQty += r.dayEntries[dKey]!.quantityCompleted;
        }
      }
      dailyTotals[dKey] = daySum;
      dailyTotalQuantities[dKey] = dayQty;
      grandTotalSeconds += daySum;
      grandTotalQuantity += dayQty;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final bool isMobile = availableWidth < 650;

        if (isMobile) {
          return _buildMobileMatrixTable(
            context,
            filteredRows,
            dailyTotals,
            dailyTotalQuantities,
            grandTotalSeconds,
            grandTotalQuantity,
          );
        }

        // Base Column Widths (Program/Sequence, Date column, Total column)
        const double baseSeqWidth = 160;
        const double baseDateColWidth = 145;
        const double baseTotalWidth = 145;

        final double naturalTableWidth = baseSeqWidth +
            (_dateColumns.length * baseDateColWidth) +
            baseTotalWidth;

        final double scale =
            (availableWidth > naturalTableWidth && naturalTableWidth > 0)
                ? (availableWidth / naturalTableWidth)
                : 1.0;

        final double colSeqWidth = baseSeqWidth * scale;
        final double colDateWidth = baseDateColWidth * scale;
        final double colTotalWidth = baseTotalWidth * scale;
        final double dateAreaWidth = colDateWidth * _dateColumns.length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. PINNED LEFT PROGRAM / SEQUENCE COLUMN
              Container(
                width: colSeqWidth,
                height: constraints.maxHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Header: Program / Sequence
                    Container(
                      width: colSeqWidth,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00695C),
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                      ),
                      child: const Text(
                        "Program / Sequence",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Sub-Header: Program / Sequence
                    _buildSubHeaderCell("Program /\nSequence", colSeqWidth),

                    // Middle Data Rows (Synchronized vertically)
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                            PointerDeviceKind.stylus,
                          },
                        ),
                        child: SingleChildScrollView(
                          controller: _pinnedLeftVerticalController,
                          scrollDirection: Axis.vertical,
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            children: [
                              for (int rIdx = 0;
                                  rIdx < filteredRows.length;
                                  rIdx++)
                                _buildPinnedLeftSequenceDataRow(
                                  filteredRows[rIdx],
                                  rIdx,
                                  colSeqWidth,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Footer: Total Label
                    Container(
                      width: colSeqWidth,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        border: Border(
                          top: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                        ),
                      ),
                      child: const Text(
                        "Total",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. DATE COLUMNS AREA (Combined Duration / Quantity per date)
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: RawScrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 8.0,
                    radius: const Radius.circular(4),
                    thumbColor: const Color(0x9900695C),
                    trackColor: const Color(0xFFE2E8F0),
                    padding: const EdgeInsets.only(bottom: 2),
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: dateAreaWidth,
                        height: constraints.maxHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TOP HEADER ROW (Yellow Date Headers)
                            Row(
                              children: [
                                for (int dIdx = 0;
                                    dIdx < _dateColumns.length;
                                    dIdx++)
                                  Container(
                                    width: colDateWidth,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF5B800),
                                      border: Border(
                                        right: BorderSide(
                                            color: Color(0xFFE2E8F0), width: 1),
                                        bottom: BorderSide(
                                            color: Color(0xFFE2E8F0), width: 1),
                                      ),
                                    ),
                                    child: Text(
                                      DateFormat('dd/MM/yyyy (E)')
                                          .format(_dateColumns[dIdx]),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // SUB-HEADER ROW: Single "Duration / Quantity" per date
                            Row(
                              children: [
                                for (int dIdx = 0;
                                    dIdx < _dateColumns.length;
                                    dIdx++)
                                  _buildSubHeaderCell(
                                      "Duration /\nQuantity", colDateWidth),
                              ],
                            ),

                            // SCROLLABLE DATE DATA ROWS
                            Expanded(
                              child: ScrollConfiguration(
                                behavior:
                                    ScrollConfiguration.of(context).copyWith(
                                  dragDevices: {
                                    PointerDeviceKind.touch,
                                    PointerDeviceKind.mouse,
                                    PointerDeviceKind.trackpad,
                                    PointerDeviceKind.stylus,
                                  },
                                ),
                                child: RawScrollbar(
                                  controller: _verticalScrollController,
                                  thumbVisibility: true,
                                  trackVisibility: true,
                                  thickness: 6.0,
                                  radius: const Radius.circular(3),
                                  thumbColor: const Color(0xFF94A3B8),
                                  child: SingleChildScrollView(
                                    controller: _verticalScrollController,
                                    scrollDirection: Axis.vertical,
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      children: [
                                        for (int rIdx = 0;
                                            rIdx < filteredRows.length;
                                            rIdx++)
                                          _buildDateOnlySequenceDataRow(
                                            filteredRows[rIdx],
                                            rIdx,
                                            colDateWidth,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // FOOTER / DAILY TOTAL ROW
                            _buildDailyFooterTotalRow(
                              dailyTotals,
                              dailyTotalQuantities,
                              colDateWidth,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. PINNED RIGHT TOTAL COLUMN: Single "Total Duration / Quantity"
              Container(
                width: colTotalWidth,
                height: constraints.maxHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(-2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Header: Total
                    Container(
                      width: double.infinity,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF97316),
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                      ),
                      child: const Text(
                        "Total",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Sub-Header: Total Duration / Quantity
                    _buildSubHeaderCell("Duration /\nQuantity", colTotalWidth,
                        isTotalCol: true),

                    // Middle Data Rows (Synchronized vertically)
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                            PointerDeviceKind.stylus,
                          },
                        ),
                        child: SingleChildScrollView(
                          controller: _pinnedTotalVerticalController,
                          scrollDirection: Axis.vertical,
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            children: [
                              for (int rIdx = 0;
                                  rIdx < filteredRows.length;
                                  rIdx++)
                                _buildPinnedTotalDataRow(
                                  filteredRows[rIdx],
                                  rIdx,
                                  colTotalWidth,
                                  isPinned: true,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Footer: Grand Total (Duration / Quantity)
                    Container(
                      width: double.infinity,
                      height: 46,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        border: Border(
                          top: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                        ),
                      ),
                      child: Text(
                        "${_formatDuration(grandTotalSeconds)} /\n${grandTotalQuantity > 0 ? grandTotalQuantity : '-'}",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileMatrixTable(
    BuildContext context,
    List<SequenceRowData> filteredRows,
    Map<String, int> dailyTotals,
    Map<String, int> dailyTotalQuantities,
    int grandTotalSeconds,
    int grandTotalQuantity,
  ) {
    const double colSeqWidth = 145;
    const double colDateWidth = 140;
    const double colTotalWidth = 140;
    final double totalTableWidth =
        colSeqWidth + (colDateWidth * _dateColumns.length) + colTotalWidth;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: totalTableWidth,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP HEADER ROW
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: colSeqWidth,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00695C),
                          border: Border(
                            right:
                                BorderSide(color: Color(0xFFE2E8F0), width: 1),
                            bottom:
                                BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          ),
                        ),
                        child: const Text(
                          "Program / Sequence",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
                        Container(
                          width: colDateWidth,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5B800),
                            border: Border(
                              right: BorderSide(
                                  color: Color(0xFFE2E8F0), width: 1),
                              bottom: BorderSide(
                                  color: Color(0xFFE2E8F0), width: 1),
                            ),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy (E)')
                                .format(_dateColumns[dIdx]),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      Container(
                        width: colTotalWidth,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF97316),
                          border: Border(
                            bottom:
                                BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          ),
                        ),
                        child: const Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 2. SUB-HEADER ROW
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSubHeaderCell("Program /\nSequence", colSeqWidth),
                      for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
                        _buildSubHeaderCell(
                            "Duration /\nQuantity", colDateWidth),
                      _buildSubHeaderCell(
                          "Total\nDuration /\nQuantity", colTotalWidth,
                          isTotalCol: true),
                    ],
                  ),

                  // 3. DATA ROWS
                  for (int rIdx = 0; rIdx < filteredRows.length; rIdx++)
                    _buildMobileDataRow(
                      filteredRows[rIdx],
                      rIdx,
                      colSeqWidth,
                      colDateWidth,
                      colTotalWidth,
                    ),

                  // 4. FOOTER TOTAL ROW
                  _buildMobileFooterTotalRow(
                    dailyTotals,
                    dailyTotalQuantities,
                    grandTotalSeconds,
                    grandTotalQuantity,
                    colSeqWidth,
                    colDateWidth,
                    colTotalWidth,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDataRow(
    SequenceRowData row,
    int rowIndex,
    double colSeqWidth,
    double colDateWidth,
    double colTotalWidth,
  ) {
    Color rowBg = rowIndex % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPinnedLeftSequenceDataRow(row, rowIndex, colSeqWidth),
          for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
            _buildDateSequenceBlock(
              row,
              _dateColumns[dIdx],
              colDateWidth,
            ),
          _buildPinnedTotalDataRow(
            row,
            rowIndex,
            colTotalWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFooterTotalRow(
    Map<String, int> dailyTotals,
    Map<String, int> dailyTotalQuantities,
    int grandTotalSeconds,
    int grandTotalQuantity,
    double colSeqWidth,
    double colDateWidth,
    double colTotalWidth,
  ) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(
          top: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: colSeqWidth,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
              ),
            ),
            child: const Text(
              "Total",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF166534),
              ),
            ),
          ),
          for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
            Builder(builder: (context) {
              String dKey = DateFormat('yyyy-MM-dd').format(_dateColumns[dIdx]);
              int daySumSec = dailyTotals[dKey] ?? 0;
              int daySumQty = dailyTotalQuantities[dKey] ?? 0;
              String dayTotalFormatted = _formatDuration(daySumSec);
              String qtyStr = daySumQty > 0 ? daySumQty.toString() : '-';

              return Container(
                width: colDateWidth,
                height: 46,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
                  ),
                ),
                child: Text(
                  "$dayTotalFormatted /\n$qtyStr",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
              );
            }),
          Container(
            width: colTotalWidth,
            height: 46,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
            ),
            child: Text(
              "${_formatDuration(grandTotalSeconds)} /\n${grandTotalQuantity > 0 ? grandTotalQuantity : '-'}",
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeaderCell(String text, double width,
      {bool isTotalCol = false}) {
    return Container(
      width: width.isFinite ? width : null,
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isTotalCol ? const Color(0xFFFFF7ED) : const Color(0xFFE0F2F1),
        border: const Border(
          right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
          bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        maxLines: 2,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F766E),
        ),
      ),
    );
  }

  Widget _buildPinnedLeftSequenceDataRow(
    SequenceRowData row,
    int rowIndex,
    double colSeqWidth,
  ) {
    Color rowBg = rowIndex % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);

    return Container(
      width: colSeqWidth,
      height: 52,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (row.progName.isNotEmpty && row.progName != row.seqName) ...[
            Text(
              row.progName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
            ),
            child: Text(
              row.seqName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateOnlySequenceDataRow(
    SequenceRowData row,
    int rowIndex,
    double colDateWidth,
  ) {
    Color rowBg = rowIndex % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
            _buildDateSequenceBlock(
              row,
              _dateColumns[dIdx],
              colDateWidth,
            ),
        ],
      ),
    );
  }

  Widget _buildPinnedTotalDataRow(
    SequenceRowData row,
    int rowIndex,
    double colTotalWidth, {
    bool isPinned = false,
  }) {
    Color rowBg = rowIndex % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);

    int rowTotalSeconds = 0;
    int rowTotalQuantity = 0;
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      if (row.dayEntries.containsKey(dKey)) {
        rowTotalSeconds += row.dayEntries[dKey]!.durationQtySeconds;
        rowTotalQuantity += row.dayEntries[dKey]!.quantityCompleted;
      }
    }

    String formattedText =
        "${_formatDuration(rowTotalSeconds)} /\n${rowTotalQuantity > 0 ? rowTotalQuantity : '-'}";

    if (isPinned) {
      return Container(
        width: colTotalWidth,
        height: 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: rowBg,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: Text(
          formattedText,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF15803D),
          ),
        ),
      );
    }

    return Container(
      width: colTotalWidth,
      height: 52,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFFCBD5E1), width: 1),
          right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
      ),
      child: Text(
        formattedText,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF15803D),
        ),
      ),
    );
  }

  Widget _buildDateSequenceBlock(
    SequenceRowData row,
    DateTime date,
    double colDateWidth,
  ) {
    String dKey = DateFormat('yyyy-MM-dd').format(date);
    SequenceDayData? dayData = row.dayEntries[dKey];

    String cellText;
    bool isBold = false;
    if (dayData != null && dayData.hasRun) {
      String dur = dayData.durationQtyStr;
      String qty = dayData.quantityCompleted > 0
          ? dayData.quantityCompleted.toString()
          : '-';
      cellText = "$dur /\n$qty";
      isBold = dur != '00:00:00' || qty != '-';
    } else {
      cellText = "- /\n-";
    }

    return _buildDataTableCell(
      cellText,
      colDateWidth,
      isBold: isBold,
      maxLines: 2,
    );
  }

  Widget _buildDataTableCell(
    String text,
    double width, {
    bool isBold = false,
    int maxLines = 2,
  }) {
    return Container(
      width: width,
      height: 52,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: (text == '-' ||
                  text == '- /\n-' ||
                  text == '- / -' ||
                  text == '00:00:00 /\n-' ||
                  text == '00:00:00 / -')
              ? const Color(0xFF94A3B8)
              : const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildDailyFooterTotalRow(
    Map<String, int> dailyTotals,
    Map<String, int> dailyTotalQuantities,
    double colDateWidth,
  ) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(
          top: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
            Builder(builder: (context) {
              String dKey = DateFormat('yyyy-MM-dd').format(_dateColumns[dIdx]);
              int daySumSec = dailyTotals[dKey] ?? 0;
              int daySumQty = dailyTotalQuantities[dKey] ?? 0;
              String dayTotalFormatted = _formatDuration(daySumSec);
              String qtyStr = daySumQty > 0 ? daySumQty.toString() : '-';

              return Container(
                width: colDateWidth,
                height: 46,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
                  ),
                ),
                child: Text(
                  "$dayTotalFormatted /\n$qtyStr",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ==========================================
  // GRAPH VIEW IMPLEMENTATION
  // ==========================================
  Widget _buildZoneLogGraphView(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    var filteredRows = _getFilteredSequenceRows();

    if (_dateColumns.isEmpty || filteredRows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            "No data available for graph",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Totals calculation
    int grandTotalSeconds = 0;
    int grandTotalQuantity = 0;
    for (var r in filteredRows) {
      grandTotalSeconds += r.totalDurationSeconds;
      grandTotalQuantity += r.totalQuantity;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // 1. Metric Summary Cards
              _buildGraphSummaryCards(
                grandTotalSeconds: grandTotalSeconds,
                grandTotalQuantity: grandTotalQuantity,
                totalSequences: filteredRows.length,
                totalDays: _dateColumns.length,
              ),
              const SizedBox(height: 12),

              // 2. Chart Card with Mode / Type Selector
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Controls: Mode Selector & Type Selector
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Metric selector: Duration (mins) [Green] vs Quantity [Orange]
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMetricTab(
                                label: "Duration (mins)",
                                icon: Icons.timer_outlined,
                                activeColor: const Color(0xFF0D9488),
                                isSelected: _selectedGraphMetric == 'Duration',
                                onTap: () => setState(
                                    () => _selectedGraphMetric = 'Duration'),
                              ),
                              _buildMetricTab(
                                label: "Quantity",
                                icon: Icons.water_drop_outlined,
                                activeColor: const Color(0xFFF97316),
                                isSelected: _selectedGraphMetric == 'Quantity',
                                onTap: () => setState(
                                    () => _selectedGraphMetric = 'Quantity'),
                              ),
                            ],
                          ),
                        ),
                        // Chart type selector
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGraphTypeIcon(
                                icon: Icons.bar_chart,
                                tooltip: "Column Chart",
                                isSelected: _graphChartType == 'Column',
                                onTap: () =>
                                    setState(() => _graphChartType = 'Column'),
                              ),
                              _buildGraphTypeIcon(
                                icon: Icons.show_chart,
                                tooltip: "Line Chart",
                                isSelected: _graphChartType == 'Spline',
                                onTap: () =>
                                    setState(() => _graphChartType = 'Spline'),
                              ),
                              _buildGraphTypeIcon(
                                icon: Icons.area_chart,
                                tooltip: "Area Chart",
                                isSelected: _graphChartType == 'Area',
                                onTap: () =>
                                    setState(() => _graphChartType = 'Area'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // SfCartesianChart with horizontal scrolling for 1 month or constrained width
                    LayoutBuilder(
                      builder: (context, chartConstraints) {
                        const double minWidthPerDate = 45.0;
                        final double totalCalculatedWidth =
                            _dateColumns.length * minWidthPerDate;
                        final double chartWidth = math.max(
                            chartConstraints.maxWidth, totalCalculatedWidth);

                        return ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.trackpad,
                              PointerDeviceKind.stylus,
                            },
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: chartWidth,
                              height: 320,
                              child: _buildSfChart(filteredRows),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Sequence Breakdown Cards
              Text(
                "Sequence Breakdown (${filteredRows.length})",
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),

              for (var row in filteredRows)
                _buildSequenceBreakdownCard(
                    row, grandTotalSeconds, grandTotalQuantity),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGraphSummaryCards({
    required int grandTotalSeconds,
    required int grandTotalQuantity,
    required int totalSequences,
    required int totalDays,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;

      return isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: "Total Duration",
                        value: _formatDuration(grandTotalSeconds),
                        icon: Icons.timer_outlined,
                        color: const Color(0xFF00897B),
                        bgColor: const Color(0xFFE0F2F1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        title: "Total Quantity",
                        value: grandTotalQuantity > 0
                            ? "$grandTotalQuantity"
                            : "-",
                        icon: Icons.water_drop_outlined,
                        color: const Color(0xFFF97316),
                        bgColor: const Color(0xFFFFF7ED),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: "Sequences",
                        value: "$totalSequences",
                        icon: Icons.account_tree_outlined,
                        color: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFEFF6FF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        title: "Date Range",
                        value: "$totalDays Days",
                        icon: Icons.date_range_outlined,
                        color: const Color(0xFF7C3AED),
                        bgColor: const Color(0xFFF5F3FF),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: "Total Duration",
                    value: _formatDuration(grandTotalSeconds),
                    icon: Icons.timer_outlined,
                    color: const Color(0xFF00897B),
                    bgColor: const Color(0xFFE0F2F1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    title: "Total Quantity",
                    value: grandTotalQuantity > 0 ? "$grandTotalQuantity" : "-",
                    icon: Icons.water_drop_outlined,
                    color: const Color(0xFFF97316),
                    bgColor: const Color(0xFFFFF7ED),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    title: "Sequences",
                    value: "$totalSequences",
                    icon: Icons.account_tree_outlined,
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    title: "Date Range",
                    value: "$totalDays Days",
                    icon: Icons.date_range_outlined,
                    color: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFF5F3FF),
                  ),
                ),
              ],
            );
    });
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTab({
    required String label,
    required IconData icon,
    required Color activeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphTypeIcon({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color:
                isSelected ? const Color(0xFF00695C) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildSfChart(List<SequenceRowData> rows) {
    List<_ZoneChartPoint> dataPoints = [];

    // Always Date Wise
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      String label = DateFormat('dd/MM').format(d);
      int sumSec = 0;
      int sumQty = 0;
      for (var r in rows) {
        if (r.dayEntries.containsKey(dKey)) {
          sumSec += r.dayEntries[dKey]!.durationQtySeconds;
          sumQty += r.dayEntries[dKey]!.quantityCompleted;
        }
      }
      double durMinutes = sumSec / 60.0;
      dataPoints.add(_ZoneChartPoint(
        xLabel: label,
        durationMinutes: durMinutes,
        durationFormatted: _formatDuration(sumSec),
        quantity: sumQty.toDouble(),
      ));
    }

    final bool isDuration = _selectedGraphMetric == 'Duration';

    return SfCartesianChart(
      legend: const Legend(
        isVisible: true,
        toggleSeriesVisibility: false,
        position: LegendPosition.top,
        alignment: ChartAlignment.center,
        textStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        shared: false,
        builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
            int seriesIndex) {
          if (pointIndex < 0 || pointIndex >= dataPoints.length) {
            return const SizedBox();
          }
          final p = dataPoints[pointIndex];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.xLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDuration
                          ? Icons.timer_outlined
                          : Icons.water_drop_outlined,
                      size: 12,
                      color: isDuration
                          ? const Color(0xFF2DD4BF)
                          : const Color(0xFFFB923C),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDuration
                          ? "Duration: ${p.durationFormatted}"
                          : "Quantity: ${p.quantity > 0 ? p.quantity.toInt().toString() : '-'}",
                      style: TextStyle(
                        color: isDuration
                            ? const Color(0xFF2DD4BF)
                            : const Color(0xFFFB923C),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      primaryXAxis: CategoryAxis(
        labelRotation: dataPoints.length > 7 ? -45 : 0,
        labelStyle: const TextStyle(
          fontSize: 10.5,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(color: Color(0xFFCBD5E1)),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(
          text: isDuration ? "Duration (mins)" : "Quantity",
          textStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color:
                isDuration ? const Color(0xFF0F766E) : const Color(0xFFEA580C),
          ),
        ),
        axisLine: const AxisLine(color: Color(0xFFCBD5E1)),
        majorGridLines: const MajorGridLines(
          color: Color(0xFFF1F5F9),
          width: 1,
        ),
        labelStyle: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
      ),
      series: _buildChartSeries(dataPoints, isDuration),
    );
  }

  List<CartesianSeries<_ZoneChartPoint, String>> _buildChartSeries(
      List<_ZoneChartPoint> data, bool isDuration) {
    if (isDuration) {
      // Duration: Green / Teal
      if (_graphChartType == 'Spline') {
        return [
          SplineSeries<_ZoneChartPoint, String>(
            name: 'Duration (mins)',
            dataSource: data,
            xValueMapper: (_ZoneChartPoint p, _) => p.xLabel,
            yValueMapper: (_ZoneChartPoint p, _) => p.durationMinutes,
            color: const Color(0xFF0D9488),
            width: 3,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ];
      } else if (_graphChartType == 'Area') {
        return [
          SplineAreaSeries<_ZoneChartPoint, String>(
            name: 'Duration (mins)',
            dataSource: data,
            xValueMapper: (_ZoneChartPoint p, _) => p.xLabel,
            yValueMapper: (_ZoneChartPoint p, _) => p.durationMinutes,
            color: const Color(0xFF0D9488).withValues(alpha: 0.3),
            borderColor: const Color(0xFF0D9488),
            borderWidth: 2,
          ),
        ];
      }

      // Default: Column series in Green
      return [
        ColumnSeries<_ZoneChartPoint, String>(
          name: 'Duration (mins)',
          dataSource: data,
          xValueMapper: (_ZoneChartPoint p, _) => p.xLabel,
          yValueMapper: (_ZoneChartPoint p, _) => p.durationMinutes,
          color: const Color(0xFF0D9488),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          width: 0.4,
        ),
      ];
    } else {
      // Quantity: Orange
      if (_graphChartType == 'Spline') {
        return [
          SplineSeries<_ZoneChartPoint, String>(
            name: 'Quantity',
            dataSource: data,
            xValueMapper: (_ZoneChartPoint p, _) => p.xLabel,
            yValueMapper: (_ZoneChartPoint p, _) => p.quantity,
            color: const Color(0xFFF97316),
            width: 3,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ];
      } else if (_graphChartType == 'Area') {
        return [
          SplineAreaSeries<_ZoneChartPoint, String>(
            name: 'Quantity',
            dataSource: data,
            xValueMapper: (_ZoneChartPoint p, _) => p.xLabel,
            yValueMapper: (_ZoneChartPoint p, _) => p.quantity,
            color: const Color(0xFFF97316).withValues(alpha: 0.25),
            borderColor: const Color(0xFFF97316),
            borderWidth: 2,
          ),
        ];
      }

      // Default: Column series in Orange
      return [
        ColumnSeries<_ZoneChartPoint, String>(
          name: 'Quantity',
          dataSource: data,
          xValueMapper: (_ZoneChartPoint p, _) => p.xLabel,
          yValueMapper: (_ZoneChartPoint p, _) => p.quantity,
          color: const Color(0xFFF97316),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          width: 0.4,
        ),
      ];
    }
  }

  Widget _buildSequenceBreakdownCard(
      SequenceRowData row, int grandTotalSeconds, int grandTotalQuantity) {
    bool isExpanded = _expandedBreakdownKeys.contains(row.key);

    Widget toggleBtn = InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedBreakdownKeys.remove(row.key);
          } else {
            _expandedBreakdownKeys.add(row.key);
          }
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFFFEDD5), width: 1),
        ),
        child: Icon(
          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          size: 16,
          color: const Color(0xFFEA580C),
        ),
      ),
    );

    Widget durationBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 11, color: Color(0xFF0F766E)),
          const SizedBox(width: 3),
          Text(
            _formatDuration(row.totalDurationSeconds),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F766E),
            ),
          ),
        ],
      ),
    );

    Widget quantityBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop_outlined,
              size: 11, color: Color(0xFFEA580C)),
          const SizedBox(width: 3),
          Text(
            row.totalQuantity > 0 ? "${row.totalQuantity}" : "-",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 460;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNarrow) ...[
                // Mobile / Narrow: Row 1 = Sequence Badge + Program Name + Toggle
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFC8E6C9), width: 1),
                      ),
                      child: Text(
                        row.seqName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    if (row.progName.isNotEmpty &&
                        row.progName != row.seqName) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "(${row.progName})",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else ...[
                      const Spacer(),
                    ],
                    toggleBtn,
                  ],
                ),
                const SizedBox(height: 6),
                // Mobile / Narrow: Row 2 = Duration Badge & Quantity Badge
                Row(
                  children: [
                    durationBadge,
                    const SizedBox(width: 6),
                    quantityBadge,
                  ],
                ),
              ] else ...[
                // Wide / Tablet / Desktop: Single Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFFC8E6C9), width: 1),
                            ),
                            child: Text(
                              row.seqName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          if (row.progName.isNotEmpty &&
                              row.progName != row.seqName) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "(${row.progName})",
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        durationBadge,
                        const SizedBox(width: 6),
                        quantityBadge,
                        const SizedBox(width: 6),
                        toggleBtn,
                      ],
                    ),
                  ],
                ),
              ],


              // Expanded Date-wise Duration, Quantity & Total breakdown
              if (isExpanded) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(5)),
                          border: Border(
                            bottom:
                                BorderSide(color: Color(0xFFCBD5E1), width: 1),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Date",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Duration",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Quantity",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Date Rows
                      for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
                        Builder(builder: (context) {
                          DateTime d = _dateColumns[dIdx];
                          String dKey = DateFormat('yyyy-MM-dd').format(d);
                          SequenceDayData? dayData = row.dayEntries[dKey];

                          bool hasRun = dayData != null && dayData.hasRun;
                          int durSec = dayData?.durationQtySeconds ?? 0;
                          int qty = dayData?.quantityCompleted ?? 0;

                          String durStr = (hasRun && durSec > 0)
                              ? _formatDuration(durSec)
                              : (hasRun && dayData.durationQtyStr != '00:00:00'
                                  ? dayData.durationQtyStr
                                  : '-');
                          String qtyStr =
                              (hasRun && qty > 0) ? qty.toString() : '-';

                          Color rowBg = dIdx % 2 == 0
                              ? Colors.white
                              : const Color(0xFFF8FAFC);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            color: rowBg,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(d),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: hasRun
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: hasRun
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    durStr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: durStr != '-'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: durStr != '-'
                                          ? const Color(0xFF0F766E)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    qtyStr,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: qtyStr != '-'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: qtyStr != '-'
                                          ? const Color(0xFFEA580C)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      // Total Footer Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0FDF4),
                          borderRadius:
                              BorderRadius.vertical(bottom: Radius.circular(5)),
                          border: Border(
                            top: BorderSide(
                                color: Color(0xFFBBF7D0), width: 1.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 3,
                              child: Text(
                                "Total",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                _formatDuration(row.totalDurationSeconds),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                row.totalQuantity > 0
                                    ? "${row.totalQuantity}"
                                    : "-",
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ZoneChartPoint {
  final String xLabel;
  final double durationMinutes;
  final String durationFormatted;
  final double quantity;

  _ZoneChartPoint({
    required this.xLabel,
    required this.durationMinutes,
    required this.durationFormatted,
    required this.quantity,
  });
}
