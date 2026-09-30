import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
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

  SequenceRowData({
    required this.key,
    required this.progName,
    required this.progSNo,
    required this.seqName,
    required this.dayEntries,
    this.totalDurationSeconds = 0,
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

    // 4. Calculate total durations for each row
    List<SequenceRowData> rows = rowsMap.values.toList();
    for (var r in rows) {
      int sumSec = 0;
      for (var d in r.dayEntries.values) {
        sumSec += d.durationQtySeconds;
      }
      r.totalDurationSeconds = sumSec;
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
              // Multi-Day Matrix Table (Fixed header, scrollable rows, fixed total footer)
              Expanded(
                child: _buildMultiDayMatrixTable(context),
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

    // Calculate daily total durations
    Map<String, int> dailyTotals = {};
    int grandTotalSeconds = 0;
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int daySum = 0;
      for (var r in filteredRows) {
        if (r.dayEntries.containsKey(dKey)) {
          daySum += r.dayEntries[dKey]!.durationQtySeconds;
        }
      }
      dailyTotals[dKey] = daySum;
      grandTotalSeconds += daySum;
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
      grandTotalSeconds: grandTotalSeconds,
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
                // Row 1: From Date & To Date side-by-side
                Row(
                  children: [
                    // From Date
                    Expanded(
                      child: Row(
                        children: [
                          const Text("From Date",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _fromDate,
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _fromDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
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
                                    Text(
                                        DateFormat('dd MMM yyyy')
                                            .format(_fromDate),
                                        style: const TextStyle(fontSize: 11.5)),
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // To Date
                    Expanded(
                      child: Row(
                        children: [
                          const Text("To Date",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _toDate,
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _toDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
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
                                    Text(
                                        DateFormat('dd MMM yyyy')
                                            .format(_toDate),
                                        style: const TextStyle(fontSize: 11.5)),
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Program Filter & Action Buttons
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
                    // Filter Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => fetchZoneLogApi(),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt_outlined,
                              size: 14, color: Colors.white),
                          SizedBox(width: 3),
                          Text("Filter",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Excel Button
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 0),
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
              // From Date Picker
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("From Date",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fromDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _fromDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Text(DateFormat('dd MMM yyyy').format(_fromDate),
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today,
                              size: 16, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // To Date Picker
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("To Date",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _toDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _toDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Text(DateFormat('dd MMM yyyy').format(_toDate),
                              style: const TextStyle(fontSize: 13)),
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

              // Filter Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      fetchZoneLogApi();
                    },
                    icon: const Icon(Icons.filter_alt_outlined,
                        size: 16, color: Colors.white),
                    label: const Text("Filter",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
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
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xFF00695C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      // child: Row(
      //   mainAxisAlignment: MainAxisAlignment.center,
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

    // Calculate daily total durations
    Map<String, int> dailyTotals = {};
    int grandTotalSeconds = 0;
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int daySum = 0;
      for (var r in filteredRows) {
        if (r.dayEntries.containsKey(dKey)) {
          daySum += r.dayEntries[dKey]!.durationQtySeconds;
        }
      }
      dailyTotals[dKey] = daySum;
      grandTotalSeconds += daySum;
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
            grandTotalSeconds,
          );
        }

        // Base Column Widths (Program/Sequence, Duration/Quantity, Quantity Completed, Total)
        const double baseSeqWidth = 160;
        const double baseDurationQtyWidth = 130;
        const double baseQtyCompletedWidth = 120;
        const double baseTotalWidth = 110;
        const double baseDateBlockWidth =
            baseDurationQtyWidth + baseQtyCompletedWidth; // 250

        final double naturalTableWidth = baseSeqWidth +
            (_dateColumns.length * baseDateBlockWidth) +
            baseTotalWidth;

        final double scale =
            (availableWidth > naturalTableWidth && naturalTableWidth > 0)
                ? (availableWidth / naturalTableWidth)
                : 1.0;

        final double colSeqWidth = baseSeqWidth * scale;
        final double colDurationQtyWidth = baseDurationQtyWidth * scale;
        final double colQtyCompletedWidth = baseQtyCompletedWidth * scale;
        final double colTotalWidth = baseTotalWidth * scale;
        final double dateBlockWidth =
            colDurationQtyWidth + colQtyCompletedWidth;
        final double dateAreaWidth = dateBlockWidth * _dateColumns.length;

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
              // 1. PINNED LEFT PROGRAM / SEQUENCE COLUMN (Fixed horizontally, Synchronized vertically)
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

                    // Middle Data Rows (Synchronized vertically with other columns)
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

              // 2. DATE COLUMNS AREA (Horizontally scrollable, Vertically scrollable rows)
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
                            // TOP HEADER ROW (Yellow/Gold Date Headers)
                            Row(
                              children: [
                                for (int dIdx = 0;
                                    dIdx < _dateColumns.length;
                                    dIdx++)
                                  Container(
                                    width: dateBlockWidth,
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

                            // SUB-HEADER ROW (Sub-columns per date: Duration/Qty & Qty Completed)
                            Row(
                              children: [
                                for (int dIdx = 0;
                                    dIdx < _dateColumns.length;
                                    dIdx++) ...[
                                  _buildSubHeaderCell(
                                      "Duration", colDurationQtyWidth),
                                  _buildSubHeaderCell(
                                      "Quantity", colQtyCompletedWidth),
                                ],
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
                                            colDurationQtyWidth,
                                            colQtyCompletedWidth,
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
                              dateBlockWidth,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. PINNED RIGHT TOTAL COLUMN (Fixed horizontally, Synchronized vertically)
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

                    // Sub-Header: Total Duration
                    _buildSubHeaderCell("Total\nDuration", colTotalWidth,
                        isTotalCol: true),

                    // Middle Data Rows (Synchronized vertically with middle table)
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
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Footer: Grand Total
                    Container(
                      width: colTotalWidth,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        border: Border(
                          top: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                        ),
                      ),
                      child: Text(
                        _formatDuration(grandTotalSeconds),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
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
    int grandTotalSeconds,
  ) {
    const double colSeqWidth = 145;
    const double colDurationQtyWidth = 115;
    const double colQtyCompletedWidth = 100;
    const double colTotalWidth = 105;
    const double dateBlockWidth = colDurationQtyWidth + colQtyCompletedWidth;
    final double totalTableWidth =
        colSeqWidth + (dateBlockWidth * _dateColumns.length) + colTotalWidth;

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
                          width: dateBlockWidth,
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
                      for (int dIdx = 0;
                          dIdx < _dateColumns.length;
                          dIdx++) ...[
                        _buildSubHeaderCell("Duration", colDurationQtyWidth),
                        _buildSubHeaderCell("Quantity", colQtyCompletedWidth),
                      ],
                      _buildSubHeaderCell("Total\nDuration", colTotalWidth,
                          isTotalCol: true),
                    ],
                  ),

                  // 3. DATA ROWS
                  for (int rIdx = 0; rIdx < filteredRows.length; rIdx++)
                    _buildMobileDataRow(
                      filteredRows[rIdx],
                      rIdx,
                      colSeqWidth,
                      colDurationQtyWidth,
                      colQtyCompletedWidth,
                      colTotalWidth,
                    ),

                  // 4. FOOTER TOTAL ROW
                  _buildMobileFooterTotalRow(
                    dailyTotals,
                    grandTotalSeconds,
                    colSeqWidth,
                    dateBlockWidth,
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
    double colDurationQtyWidth,
    double colQtyCompletedWidth,
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
              colDurationQtyWidth,
              colQtyCompletedWidth,
            ),
          _buildPinnedTotalDataRow(row, rowIndex, colTotalWidth),
        ],
      ),
    );
  }

  Widget _buildMobileFooterTotalRow(
    Map<String, int> dailyTotals,
    int grandTotalSeconds,
    double colSeqWidth,
    double dateBlockWidth,
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
              String dayTotalFormatted = _formatDuration(daySumSec);

              return Container(
                width: dateBlockWidth,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
                  ),
                ),
                child: Text(
                  dayTotalFormatted,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
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
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
            ),
            child: Text(
              _formatDuration(grandTotalSeconds),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
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
      width: width,
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
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
          fontSize: 10,
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
    double colDurationQtyWidth,
    double colQtyCompletedWidth,
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
          for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++) ...[
            _buildDateSequenceBlock(
              row,
              _dateColumns[dIdx],
              colDurationQtyWidth,
              colQtyCompletedWidth,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPinnedTotalDataRow(
    SequenceRowData row,
    int rowIndex,
    double colTotalWidth,
  ) {
    Color rowBg = rowIndex % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);

    int rowTotalSeconds = 0;
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      if (row.dayEntries.containsKey(dKey)) {
        rowTotalSeconds += row.dayEntries[dKey]!.durationQtySeconds;
      }
    }

    return Container(
      width: colTotalWidth,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          left: BorderSide(color: Color(0xFFCBD5E1), width: 1),
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Text(
        _formatDuration(rowTotalSeconds),
        textAlign: TextAlign.center,
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
    double colDurationQtyWidth,
    double colQtyCompletedWidth,
  ) {
    String dKey = DateFormat('yyyy-MM-dd').format(date);
    SequenceDayData? dayData = row.dayEntries[dKey];

    String durationQty = (dayData != null && dayData.hasRun)
        ? dayData.durationQtyStr
        : '00:00:00';
    String qtyCompleted =
        (dayData != null && dayData.hasRun) ? dayData.qtyCompletedStr : '0';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDataTableCell(
          durationQty,
          colDurationQtyWidth,
          isBold: durationQty != '-' && durationQty != '00:00:00',
        ),
        _buildDataTableCell(
          qtyCompleted,
          colQtyCompletedWidth,
          isBold: qtyCompleted != '0' && qtyCompleted != '-',
        ),
      ],
    );
  }

  Widget _buildDataTableCell(
    String text,
    double width, {
    bool isBold = false,
    int maxLines = 1,
  }) {
    return Container(
      width: width,
      height: 52,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
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
          fontSize: 10,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: (text == '-' || text == '00:00:00')
              ? const Color(0xFF94A3B8)
              : const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildDailyFooterTotalRow(
    Map<String, int> dailyTotals,
    double dateBlockWidth,
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
          for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++) ...[
            Builder(builder: (context) {
              String dKey = DateFormat('yyyy-MM-dd').format(_dateColumns[dIdx]);
              int daySumSec = dailyTotals[dKey] ?? 0;
              String dayTotalFormatted = _formatDuration(daySumSec);

              return Container(
                width: dateBlockWidth,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
                  ),
                ),
                child: Text(
                  dayTotalFormatted,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
