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
import '../../../utils/constants.dart';
import '../../Logs/repository/log_repos.dart';
import '../../Logs/model/motor_data_hourly.dart';
import '../../../services/http_service.dart';

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
  num quantityCompleted;
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
  String get qtyCompletedStr => quantityCompleted > 0
      ? (quantityCompleted % 1 == 0
          ? quantityCompleted.toInt().toString()
          : quantityCompleted.toString())
      : '0';

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
  String valveName;
  final Map<String, SequenceDayData> dayEntries; // dateKey -> SequenceDayData
  int totalDurationSeconds;
  num totalQuantity;

  SequenceRowData({
    required this.key,
    required this.progName,
    required this.progSNo,
    required this.seqName,
    this.valveName = '',
    required this.dayEntries,
    this.totalDurationSeconds = 0,
    this.totalQuantity = 0,
  });
}

class CumulativeDayData {
  int durationSeconds;
  num quantity;
  bool hasRun;
  int powerOnSeconds;
  int powerOffSeconds;

  CumulativeDayData({
    this.durationSeconds = 0,
    this.quantity = 0,
    this.hasRun = false,
    this.powerOnSeconds = 0,
    this.powerOffSeconds = 0,
  });

  String get durationStr => durationSeconds > 0
      ? SequenceDayData._formatSecondsToHMS(durationSeconds)
      : '00:00:00';
  String get qtyStr => quantity > 0
      ? (quantity % 1 == 0 ? "${quantity.toInt()} L" : "$quantity L")
      : '-';
}

class CumulativeRowData {
  final String key;
  final String channelName;
  final String channelCategory;
  final double channelSNo;
  final Map<String, CumulativeDayData> dayEntries;
  int totalDurationSeconds;
  num totalQuantity;
  int totalPowerOnSeconds;
  int totalPowerOffSeconds;

  CumulativeRowData({
    required this.key,
    required this.channelName,
    required this.channelCategory,
    required this.channelSNo,
    required this.dayEntries,
    this.totalDurationSeconds = 0,
    this.totalQuantity = 0,
    this.totalPowerOnSeconds = 0,
    this.totalPowerOffSeconds = 0,
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
  final ScrollController _zoneGraphScrollController = ScrollController();
  final ScrollController _cumGraphScrollController = ScrollController();
  final ScrollController _seqDialogGraphScrollController = ScrollController();
  final ScrollController _chanDialogGraphScrollController = ScrollController();
  final ScrollController _pumpGraphScrollController = ScrollController();
  final ScrollController _pumpDialogGraphScrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 4));
  DateTime _toDate = DateTime.now();
  String _selectedProgramFilter = 'All Programs';

  bool _isLoading = false;
  List<SequenceRowData> _sequenceRows = [];
  List<DateTime> _dateColumns = [];
  List<String> _programDropdownOptions = ['All Programs'];
  // ignore: prefer_final_fields
  int _selectedViewTab = 0; // 0 = Table View, 1 = Graph View
  String _selectedGraphMetric =
      'Duration'; // 'Duration' (Green) or 'Quantity' (Orange)
  // ignore: prefer_final_fields
  String _graphChartType = 'Column'; // 'Column', 'Spline', 'Area'
  final Set<String> _expandedBreakdownKeys = {};
  int _selectedLogTypeTab = 0; // 0 = Zone Log, 1 = Cumulative Log
  List<CumulativeRowData> _cumulativeRows = [];

  // Pump Log State
  List<CumulativeRowData> _pumpRows = [];
  String _selectedPumpFilter = 'All Pumps';
  List<String> _pumpDropdownOptions = ['All Pumps'];
  bool _isPumpLoading = false;
  String _selectedPumpGraphMetric =
      'Runtime'; // 'Runtime', 'Total Power', 'Total Power Off'
  List<String> _cumulativeDropdownOptions = ['All Channels'];
  String _selectedCumulativeFilter = 'All Channels';
  final Map<String, String> _channelNameMap = {};
  final Map<String, String> _valveNameMap = {};
  final List<Map<String, dynamic>> _fertilizerChannelsFromConfig = [];

  @override
  void initState() {
    super.initState();
    _verticalScrollGroup = LinkedScrollControllerGroup();
    _pinnedLeftVerticalController = _verticalScrollGroup.addAndGet();
    _verticalScrollController = _verticalScrollGroup.addAndGet();
    _pinnedTotalVerticalController = _verticalScrollGroup.addAndGet();

    if (widget.masterData?.configObjects != null &&
        widget.masterData!.configObjects.isNotEmpty) {
      _populateConfigNames(widget.masterData!.configObjects);
    }

    fetchZoneLogApi();
    fetchPumpLogApi();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _pinnedLeftVerticalController.dispose();
    _verticalScrollController.dispose();
    _pinnedTotalVerticalController.dispose();
    _zoneGraphScrollController.dispose();
    _cumGraphScrollController.dispose();
    _seqDialogGraphScrollController.dispose();
    _chanDialogGraphScrollController.dispose();
    _pumpGraphScrollController.dispose();
    _pumpDialogGraphScrollController.dispose();
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
      var sList = start.trim().split('_');
      var eList = end.trim().split('_');
      int totalSec = 0;
      int count = math.min(sList.length, eList.length);
      for (int i = 0; i < count; i++) {
        String s = sList[i].trim();
        String e = eList[i].trim();
        if (s.isEmpty || e.isEmpty || s == '-' || e == '-') continue;
        var sParts =
            s.split(':').map((p) => int.tryParse(p.trim()) ?? 0).toList();
        var eParts =
            e.split(':').map((p) => int.tryParse(p.trim()) ?? 0).toList();
        if (sParts.isEmpty || eParts.isEmpty) continue;
        int sSec = sParts[0] * 3600 +
            (sParts.length > 1 ? sParts[1] * 60 : 0) +
            (sParts.length > 2 ? sParts[2] : 0);
        int eSec = eParts[0] * 3600 +
            (eParts.length > 1 ? eParts[1] * 60 : 0) +
            (eParts.length > 2 ? eParts[2] : 0);
        int diff = eSec - sSec;
        if (diff < 0 && sSec > 0 && eSec > 0) {
          diff += 86400; // overnight wrap-around across midnight
        }
        if (diff > 0) {
          totalSec += diff;
        }
      }
      return totalSec;
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
      if (dur.contains('_')) {
        int sum = 0;
        for (var part in dur.split('_')) {
          sum += _parseDurationToSeconds(part);
        }
        return sum;
      }
      var parts =
          dur.split(':').map((e) => int.tryParse(e.trim()) ?? 0).toList();
      if (parts.length == 3) {
        return parts[0] * 3600 + parts[1] * 60 + parts[2];
      } else if (parts.length == 2) {
        return parts[0] * 60 + parts[1];
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  num _parseQuantity(dynamic val) {
    if (val == null) return 0;
    String s = val.toString().trim();
    if (s.isEmpty || s == '-' || s == '--') return 0;
    if (s.contains('_')) {
      num sum = 0;
      for (var part in s.split('_')) {
        sum += (num.tryParse(part.trim()) ?? 0);
      }
      return sum;
    }
    return num.tryParse(s) ?? 0;
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

  void _registerConfigName(dynamic sNo, String name) {
    if (sNo == null || name.trim().isEmpty) return;
    String sStr = sNo.toString().trim();
    _valveNameMap[sStr] = name;
    num? n = num.tryParse(sStr);
    if (n != null) {
      _valveNameMap[n.toInt().toString()] = name;
      _valveNameMap[n.toDouble().toString()] = name;
      _valveNameMap[n.toStringAsFixed(3)] = name;
    }
  }

  String _resolveValveNames(dynamic rawSeqData) {
    if (rawSeqData == null) return '';
    if (rawSeqData is List) {
      List<String> allResolved = [];
      for (var item in rawSeqData) {
        String res = _resolveValveNames(item);
        if (res.isNotEmpty) {
          for (var p in res.split(RegExp(r',\s*'))) {
            String tp = p.trim();
            if (tp.isNotEmpty && !allResolved.contains(tp)) {
              allResolved.add(tp);
            }
          }
        }
      }
      return allResolved.join(', ');
    }
    String raw = rawSeqData.toString().trim();
    if (raw.isEmpty || raw == '-' || raw == '[]') return '';
    List<String> resolved = [];
    for (String part in raw.split(RegExp(r'[_,\s]+'))) {
      String key = part.trim();
      if (key.isEmpty) continue;
      String? name = _valveNameMap[key] ?? _channelNameMap[key];
      if (name == null) {
        var numVal = num.tryParse(key);
        if (numVal != null) {
          name = _valveNameMap[numVal.toInt().toString()] ??
              _valveNameMap[numVal.toDouble().toString()] ??
              _valveNameMap[numVal.toStringAsFixed(3)] ??
              _channelNameMap[numVal.toInt().toString()] ??
              _channelNameMap[numVal.toDouble().toString()] ??
              _channelNameMap[numVal.toStringAsFixed(3)];
        }
      }
      String finalName =
          (name != null && name.trim().isNotEmpty) ? name.trim() : key;
      if (!resolved.contains(finalName)) {
        resolved.add(finalName);
      }
    }
    return resolved.join(', ');
  }

  int _compareNatural(String? a, String? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a == b) return 0;

    final regex = RegExp(r'(\d+|\D+)');
    final matchesA =
        regex.allMatches(a.trim()).map((m) => m.group(0)!).toList();
    final matchesB =
        regex.allMatches(b.trim()).map((m) => m.group(0)!).toList();

    int len = math.min(matchesA.length, matchesB.length);
    for (int i = 0; i < len; i++) {
      final partA = matchesA[i];
      final partB = matchesB[i];

      final numA = BigInt.tryParse(partA);
      final numB = BigInt.tryParse(partB);

      if (numA != null && numB != null) {
        final cmp = numA.compareTo(numB);
        if (cmp != 0) return cmp;
        final lenCmp = partA.length.compareTo(partB.length);
        if (lenCmp != 0) return lenCmp;
      } else {
        final cmp = partA.toLowerCase().compareTo(partB.toLowerCase());
        if (cmp != 0) return cmp;
      }
    }
    return matchesA.length.compareTo(matchesB.length);
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
        "IrrigationQuantityCompleted",
        "SequenceData",
        "CentralFertChannelName",
        "CentralFertMethod",
        "CentralFertilizerChannelDuration",
        "CentralFertilizerChannelQuantity",
        "CentralFertilizerChannelDurationCompleted",
        "CentralFertilizerChannelQuantityCompleted",
        "CentralFertilizerChannel",
        "LocalFertilizerChannel",
        "LocalFertMethod",
        "LocalFertilizerChannelDuration",
        "LocalFertilizerChannelQuantity",
        "LocalFertilizerChannelDurationCompleted",
        "LocalFertilizerChannelQuantityCompleted",
        "LocalFertChannelName"
      ]
    };

    debugPrint('====================================');
    debugPrint('ZONE LOG API REQUEST BODY: ${jsonEncode(body)}');
    debugPrint('====================================');

    try {
      await _fetchConfigNames();
      var response = await IrrigationRepository().getLogDateWise(body);
      debugPrint('ZONE LOG API RESPONSE CODE: ${response.statusCode}');

      Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['code'] == 200 && jsonData['data'] != null) {
        _parseZoneApiResponse(jsonData['data']);
        _parseCumulativeApiResponse(jsonData['data']);
      } else {
        if (mounted) {
          setState(() {
            _sequenceRows = [];
            _cumulativeRows = [];
            _cumulativeDropdownOptions = ['All Channels'];
            _selectedCumulativeFilter = 'All Channels';
            _dateColumns = [];
          });
        }
      }
      fetchPumpLogApi();
    } catch (e, stackTrace) {
      debugPrint('Error in Zone Log API: ${e.toString()}');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _sequenceRows = [];
          _cumulativeRows = [];
          _cumulativeDropdownOptions = ['All Channels'];
          _selectedCumulativeFilter = 'All Channels';
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

      if (defaultObj['valve'] != null && defaultObj['valve'] is List) {
        for (var v in defaultObj['valve']) {
          if (v is Map) {
            _registerConfigName(
                v['sNo'], (v['name'] ?? v['valveName'] ?? '').toString());
          }
        }
      }
      if (defaultObj['valves'] != null && defaultObj['valves'] is List) {
        for (var v in defaultObj['valves']) {
          if (v is Map) {
            _registerConfigName(
                v['sNo'], (v['name'] ?? v['valveName'] ?? '').toString());
          }
        }
      }
      if (defaultObj['configObject'] != null &&
          defaultObj['configObject'] is List) {
        for (var v in defaultObj['configObject']) {
          if (v is Map) {
            _registerConfigName(v['sNo'], (v['name'] ?? '').toString());
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

      String defValve = '';
      if (seq['valve'] != null) defValve = _resolveValveNames(seq['valve']);
      if (defValve.isEmpty && seq['valves'] != null) {
        defValve = _resolveValveNames(seq['valves']);
      }
      if (defValve.isEmpty && seq['SequenceData'] != null) {
        defValve = _resolveValveNames(seq['SequenceData']);
      }
      if (defValve.isEmpty && seq['sequenceData'] != null) {
        defValve = _resolveValveNames(seq['sequenceData']);
      }

      rowsMap.putIfAbsent(
        key,
        () => SequenceRowData(
          key: key,
          progName: progName,
          progSNo: pSNo,
          seqName: name,
          valveName: defValve,
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
        List sequenceDatas = irrigation['SequenceData'] ?? [];
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

          int actualDurFromTimes = 0;
          if (i < actualStartTimes.length &&
              i < actualStopTimes.length &&
              actualStartTimes[i] != null &&
              actualStopTimes[i] != null) {
            actualDurFromTimes = _parseDurationSeconds(
                actualStartTimes[i].toString(), actualStopTimes[i].toString());
          }

          int durationQtySec = _parseDurationToSeconds(durationQtyStr);
          int durCompletedSec = _parseDurationToSeconds(durationCompletedStr);

          // Determine the effective duration:
          // Priority 1: If actual start and end times are available, use the calculated duration (e.g. 13:21:41 to 13:54:38 -> 32m 57s)
          // Priority 2: If durationCompleted is reported (> 1 second to avoid 1s dummy placeholder), use it
          // Priority 3: Fallback to planned/set duration
          int effectiveDurSec = 0;
          if (actualDurFromTimes > 0) {
            effectiveDurSec = actualDurFromTimes;
          } else if (durCompletedSec > 1) {
            effectiveDurSec = durCompletedSec;
          } else if (durCompletedSec > 0 && durationQtySec == 0) {
            effectiveDurSec = durCompletedSec;
          } else {
            effectiveDurSec = durationQtySec;
          }

          num qtyCompletedVal = _parseQuantity(qtyCompletedStr);
          if (qtyCompletedVal == 0 && !durationQtyStr.contains(':')) {
            qtyCompletedVal = _parseQuantity(durationQtyStr);
          }

          var seqDataVal =
              (i < sequenceDatas.length) ? sequenceDatas[i] : null;
          String valveName = _resolveValveNames(seqDataVal);

          String rowKey = "${pSNo}_$seqName";
          SequenceRowData rowData = rowsMap.putIfAbsent(
            rowKey,
            () => SequenceRowData(
              key: rowKey,
              progName: progName,
              progSNo: pSNo,
              seqName: seqName,
              valveName: valveName,
              dayEntries: {},
            ),
          );

          if (valveName.isNotEmpty) {
            if (rowData.valveName.isEmpty) {
              rowData.valveName = valveName;
            } else {
              List<String> currentList = [];
              for (var v in rowData.valveName.split(RegExp(r',\s*'))) {
                String tv = v.trim();
                if (tv.isNotEmpty && !currentList.contains(tv)) {
                  currentList.add(tv);
                }
              }
              for (var v in valveName.split(RegExp(r',\s*'))) {
                String tv = v.trim();
                if (tv.isNotEmpty && !currentList.contains(tv)) {
                  currentList.add(tv);
                }
              }
              rowData.valveName = currentList.join(', ');
            }
          }

          SequenceDayData dayData = rowData.dayEntries.putIfAbsent(
            itemDateKey,
            () => SequenceDayData(),
          );

          dayData.durationQtySeconds += effectiveDurSec;
          dayData.durationCompletedSeconds +=
              (actualDurFromTimes > 0 ? actualDurFromTimes : durCompletedSec);
          dayData.quantityCompleted += qtyCompletedVal;
          if (effectiveDurSec > 0 ||
              qtyCompletedVal > 0 ||
              durationQtySec > 0 ||
              durCompletedSec > 0) {
            dayData.hasRun = true;
          }

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
              qtyCompleted: qtyCompletedVal > 0
                  ? (qtyCompletedVal % 1 == 0
                      ? qtyCompletedVal.toInt().toString()
                      : qtyCompletedVal.toString())
                  : qtyCompletedStr,
              durationCompleted: durationCompletedStr,
              durationSeconds: effectiveDurSec,
              durationStr: _formatDuration(effectiveDurSec),
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
      num sumQty = 0;
      for (var d in r.dayEntries.values) {
        sumSec += d.durationQtySeconds;
        sumQty += d.quantityCompleted;
      }
      r.totalDurationSeconds = sumSec;
      r.totalQuantity = sumQty;
    }

    // 5. Sort rows by Program SNo, then Program Name, then Sequence Name (Natural Order), then Valve Name
    rows.sort((a, b) {
      if (a.progSNo != b.progSNo) return a.progSNo.compareTo(b.progSNo);
      int pCmp = _compareNatural(a.progName, b.progName);
      if (pCmp != 0) return pCmp;
      int sCmp = _compareNatural(a.seqName, b.seqName);
      if (sCmp != 0) return sCmp;
      return _compareNatural(a.valveName, b.valveName);
    });

    // Sort program dropdown options naturally with 'All Programs' always first
    var sortedProgs = uniqueProgNames.toList();
    sortedProgs.sort((a, b) {
      if (a == 'All Programs') return -1;
      if (b == 'All Programs') return 1;
      return _compareNatural(a, b);
    });

    if (mounted) {
      setState(() {
        _dateColumns = dates;
        _sequenceRows = rows;
        _programDropdownOptions = sortedProgs;
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

  List<CumulativeRowData> _getFilteredCumulativeRows() {
    if (_selectedCumulativeFilter == 'All Channels' ||
        _selectedCumulativeFilter == 'All' ||
        _selectedCumulativeFilter.isEmpty) {
      return _cumulativeRows;
    }
    return _cumulativeRows.where((r) {
      if (r.channelCategory == _selectedCumulativeFilter) return true;
      if (r.channelName == _selectedCumulativeFilter) return true;
      String fullName = "${r.channelCategory} - ${r.channelName}";
      if (fullName == _selectedCumulativeFilter) return true;
      return false;
    }).toList();
  }

  void _populateConfigNames(List<dynamic> objs) {
    _fertilizerChannelsFromConfig.clear();
    for (var item in objs) {
      if (item is Map) {
        var sNo = item['sNo'];
        String name = (item['name'] ?? '').toString();
        int objectId = item['objectId'] is int
            ? item['objectId']
            : int.tryParse(item['objectId']?.toString() ?? '') ?? 0;
        String objectName = (item['objectName'] ?? '').toString();

        if (sNo != null && name.isNotEmpty) {
          _registerConfigName(sNo, name);
          _channelNameMap[sNo.toString()] = name;
          var sNum = num.tryParse(sNo.toString());
          if (sNum != null) {
            _channelNameMap[sNum.toInt().toString()] = name;
            _channelNameMap[sNum.toDouble().toString()] = name;
            _channelNameMap[sNum.toStringAsFixed(3)] = name;
          }
        }

        if (objectId == AppConstants.channelObjectId ||
            objectName.toLowerCase().contains('channel')) {
          _fertilizerChannelsFromConfig.add(Map<String, dynamic>.from(item));
        }
      } else if (item is ConfigObject) {
        _registerConfigName(item.sNo, item.name);
        _channelNameMap[item.sNo.toString()] = item.name;
        _channelNameMap[item.sNo.toInt().toString()] = item.name;
        _channelNameMap[item.sNo.toStringAsFixed(3)] = item.name;
        if (item.objectId == AppConstants.channelObjectId ||
            item.objectName.toLowerCase().contains('channel')) {
          _fertilizerChannelsFromConfig.add({
            'objectId': item.objectId,
            'sNo': item.sNo,
            'name': item.name,
            'objectName': item.objectName,
          });
        }
      }
    }

    _fertilizerChannelsFromConfig.sort((a, b) {
      double sA = (a['sNo'] is num)
          ? (a['sNo'] as num).toDouble()
          : double.tryParse(a['sNo']?.toString() ?? '0') ?? 0;
      double sB = (b['sNo'] is num)
          ? (b['sNo'] as num).toDouble()
          : double.tryParse(b['sNo']?.toString() ?? '0') ?? 0;
      return sA.compareTo(sB);
    });
  }

  Future<void> _fetchConfigNames() async {
    try {
      var body = {
        "userId": widget.userData['customerId'] ?? 1002,
        "controllerId": widget.userData['controllerId'] ?? 3382,
      };
      var response = await IrrigationRepository().getUserNames(body);
      if (response.statusCode == 200) {
        Map<String, dynamic> configJson = jsonDecode(response.body);
        if (configJson['code'] == 200 && configJson['data'] != null) {
          var data = configJson['data'];
          if (data is Map) {
            if (data['configObject'] is List) {
              _populateConfigNames(data['configObject']);
            }
            if (data['valve'] is List) {
              for (var v in data['valve']) {
                if (v is Map) {
                  _registerConfigName(v['sNo'],
                      (v['name'] ?? v['valveName'] ?? '').toString());
                }
              }
            }
            if (data['valves'] is List) {
              for (var v in data['valves']) {
                if (v is Map) {
                  _registerConfigName(v['sNo'],
                      (v['name'] ?? v['valveName'] ?? '').toString());
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching config names: $e");
    }
  }

  void _parseCumulativeApiResponse(Map<String, dynamic> responseData) {
    Map<String, CumulativeRowData> rowsMap = {};

    // Parse log entries using CentralFertilizerChannel and LocalFertilizerChannel
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

        List centralDurations = [];
        if (irrigation['CentralFertilizerChannelDuration'] is List) {
          centralDurations = irrigation['CentralFertilizerChannelDuration'];
        } else if (irrigation['CentralFertilizerChannelDuration'] != null) {
          centralDurations = [irrigation['CentralFertilizerChannelDuration']];
        }

        List centralQuantities = [];
        if (irrigation['CentralFertilizerChannelQuantity'] is List) {
          centralQuantities = irrigation['CentralFertilizerChannelQuantity'];
        } else if (irrigation['CentralFertilizerChannelQuantity'] != null) {
          centralQuantities = [irrigation['CentralFertilizerChannelQuantity']];
        }

        List centralChannels = [];
        if (irrigation['CentralFertilizerChannel'] is List) {
          centralChannels = irrigation['CentralFertilizerChannel'];
        } else if (irrigation['CentralFertilizerChannel'] != null) {
          centralChannels = [irrigation['CentralFertilizerChannel']];
        }

        List centralNames = [];
        if (irrigation['CentralFertChannelName'] is List) {
          centralNames = irrigation['CentralFertChannelName'];
        } else if (irrigation['CentralFertChannelName'] != null) {
          centralNames = [irrigation['CentralFertChannelName']];
        }

        List centralDurationsCompleted = [];
        if (irrigation['CentralFertilizerChannelDurationCompleted'] is List) {
          centralDurationsCompleted =
              irrigation['CentralFertilizerChannelDurationCompleted'];
        } else if (irrigation['CentralFertilizerChannelDurationCompleted'] !=
            null) {
          centralDurationsCompleted = [
            irrigation['CentralFertilizerChannelDurationCompleted']
          ];
        }

        List centralQuantitiesCompleted = [];
        if (irrigation['CentralFertilizerChannelQuantityCompleted'] is List) {
          centralQuantitiesCompleted =
              irrigation['CentralFertilizerChannelQuantityCompleted'];
        } else if (irrigation['CentralFertilizerChannelQuantityCompleted'] !=
            null) {
          centralQuantitiesCompleted = [
            irrigation['CentralFertilizerChannelQuantityCompleted']
          ];
        }

        List localDurations = [];
        if (irrigation['LocalFertilizerChannelDuration'] is List) {
          localDurations = irrigation['LocalFertilizerChannelDuration'];
        } else if (irrigation['LocalFertilizerChannelDuration'] != null) {
          localDurations = [irrigation['LocalFertilizerChannelDuration']];
        }

        List localQuantities = [];
        if (irrigation['LocalFertilizerChannelQuantity'] is List) {
          localQuantities = irrigation['LocalFertilizerChannelQuantity'];
        } else if (irrigation['LocalFertilizerChannelQuantity'] != null) {
          localQuantities = [irrigation['LocalFertilizerChannelQuantity']];
        }

        List localChannels = [];
        if (irrigation['LocalFertilizerChannel'] is List) {
          localChannels = irrigation['LocalFertilizerChannel'];
        } else if (irrigation['LocalFertilizerChannel'] != null) {
          localChannels = [irrigation['LocalFertilizerChannel']];
        }

        List localNames = [];
        if (irrigation['LocalFertChannelName'] is List) {
          localNames = irrigation['LocalFertChannelName'];
        } else if (irrigation['LocalFertChannelName'] != null) {
          localNames = [irrigation['LocalFertChannelName']];
        }

        List localDurationsCompleted = [];
        if (irrigation['LocalFertilizerChannelDurationCompleted'] is List) {
          localDurationsCompleted =
              irrigation['LocalFertilizerChannelDurationCompleted'];
        } else if (irrigation['LocalFertilizerChannelDurationCompleted'] !=
            null) {
          localDurationsCompleted = [
            irrigation['LocalFertilizerChannelDurationCompleted']
          ];
        }

        List localQuantitiesCompleted = [];
        if (irrigation['LocalFertilizerChannelQuantityCompleted'] is List) {
          localQuantitiesCompleted =
              irrigation['LocalFertilizerChannelQuantityCompleted'];
        } else if (irrigation['LocalFertilizerChannelQuantityCompleted'] !=
            null) {
          localQuantitiesCompleted = [
            irrigation['LocalFertilizerChannelQuantityCompleted']
          ];
        }

        int baseLength = [
          recordDates.length,
          programSNos.length,
          centralChannels.length,
          centralDurations.length,
          centralQuantities.length,
          localChannels.length,
          localDurations.length,
          localQuantities.length,
        ].fold(0, (max, len) => len > max ? len : max);

        if (baseLength == 0) baseLength = 1;

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

          // Central Fertilizer
          dynamic cChanVal = (i < centralChannels.length)
              ? centralChannels[i]
              : (centralChannels.isNotEmpty ? centralChannels[0] : null);
          dynamic cDurVal = (i < centralDurations.length)
              ? centralDurations[i]
              : (centralDurations.isNotEmpty ? centralDurations[0] : null);
          dynamic cQtyVal = (i < centralQuantities.length)
              ? centralQuantities[i]
              : (centralQuantities.isNotEmpty ? centralQuantities[0] : null);
          dynamic cNameVal = (i < centralNames.length)
              ? centralNames[i]
              : (centralNames.isNotEmpty ? centralNames[0] : null);
          dynamic cDurCompVal = (i < centralDurationsCompleted.length)
              ? centralDurationsCompleted[i]
              : (centralDurationsCompleted.isNotEmpty
                  ? centralDurationsCompleted[0]
                  : null);
          dynamic cQtyCompVal = (i < centralQuantitiesCompleted.length)
              ? centralQuantitiesCompleted[i]
              : (centralQuantitiesCompleted.isNotEmpty
                  ? centralQuantitiesCompleted[0]
                  : null);

          _processFertilizerChannels(
            rowsMap: rowsMap,
            itemDateKey: itemDateKey,
            isCentral: true,
            chanVal: cChanVal,
            durVal: cDurVal,
            qtyVal: cQtyVal,
            nameVal: cNameVal,
            durCompletedVal: cDurCompVal,
            qtyCompletedVal: cQtyCompVal,
          );

          // Local Fertilizer
          dynamic lChanVal = (i < localChannels.length)
              ? localChannels[i]
              : (localChannels.isNotEmpty ? localChannels[0] : null);
          dynamic lDurVal = (i < localDurations.length)
              ? localDurations[i]
              : (localDurations.isNotEmpty ? localDurations[0] : null);
          dynamic lQtyVal = (i < localQuantities.length)
              ? localQuantities[i]
              : (localQuantities.isNotEmpty ? localQuantities[0] : null);
          dynamic lNameVal = (i < localNames.length)
              ? localNames[i]
              : (localNames.isNotEmpty ? localNames[0] : null);
          dynamic lDurCompVal = (i < localDurationsCompleted.length)
              ? localDurationsCompleted[i]
              : (localDurationsCompleted.isNotEmpty
                  ? localDurationsCompleted[0]
                  : null);
          dynamic lQtyCompVal = (i < localQuantitiesCompleted.length)
              ? localQuantitiesCompleted[i]
              : (localQuantitiesCompleted.isNotEmpty
                  ? localQuantitiesCompleted[0]
                  : null);

          _processFertilizerChannels(
            rowsMap: rowsMap,
            itemDateKey: itemDateKey,
            isCentral: false,
            chanVal: lChanVal,
            durVal: lDurVal,
            qtyVal: lQtyVal,
            nameVal: lNameVal,
            durCompletedVal: lDurCompVal,
            qtyCompletedVal: lQtyCompVal,
          );
        }
      }
    }

    // Calculate total duration and quantity per row
    List<CumulativeRowData> rows = rowsMap.values.toList();
    for (var r in rows) {
      int sumSec = 0;
      num sumQty = 0;
      for (var d in r.dayEntries.values) {
        sumSec += d.durationSeconds;
        sumQty += d.quantity;
      }
      r.totalDurationSeconds = sumSec;
      r.totalQuantity = sumQty;
    }

    // Sort rows: Central Fertilizer first, then Local Fertilizer, then by channelSNo
    rows.sort((a, b) {
      if (a.channelCategory != b.channelCategory) {
        return a.channelCategory.compareTo(b.channelCategory);
      }
      return a.channelSNo.compareTo(b.channelSNo);
    });

    // Build dropdown options for Cumulative Log
    Set<String> options = {'All Channels'};
    Set<String> categories = {};
    for (var r in rows) {
      if (r.channelCategory.isNotEmpty) {
        categories.add(r.channelCategory);
      }
    }
    if (categories.length > 1) {
      options.addAll(categories);
    }
    for (var r in rows) {
      if (categories.length > 1) {
        options.add("${r.channelCategory} - ${r.channelName}");
      } else {
        options.add(r.channelName);
      }
    }

    if (mounted) {
      setState(() {
        _cumulativeRows = rows;
        _cumulativeDropdownOptions = options.toList();
        if (!_cumulativeDropdownOptions.contains(_selectedCumulativeFilter)) {
          _selectedCumulativeFilter = 'All Channels';
        }
      });
    }
  }

  void _processFertilizerChannels({
    required Map<String, CumulativeRowData> rowsMap,
    required String itemDateKey,
    required bool isCentral,
    required dynamic chanVal,
    required dynamic durVal,
    required dynamic qtyVal,
    required dynamic nameVal,
    dynamic durCompletedVal,
    dynamic qtyCompletedVal,
  }) {
    List<String> extractParts(dynamic val) {
      List<String> parts = [];
      if (val != null) {
        if (val is List) {
          for (var e in val) {
            if (e != null) {
              String s = e.toString().trim();
              if (s.contains('_')) {
                parts.addAll(s.split('_'));
              } else if (s.isNotEmpty) {
                parts.add(s);
              }
            }
          }
        } else {
          String s = val.toString().trim();
          if (s.isNotEmpty) {
            parts = s.split('_');
          }
        }
      }
      return parts.map((e) => e.trim()).toList();
    }

    // 1. Extract channel sNos from chanVal (CentralFertilizerChannel or LocalFertilizerChannel)
    List<String> chParts = extractParts(chanVal);

    // 2. Extract durations from durVal
    List<String> dParts = extractParts(durVal);
    List<String> dCompParts = extractParts(durCompletedVal);

    // 3. Extract quantities from qtyVal
    List<String> qParts = extractParts(qtyVal);
    List<String> qCompParts = extractParts(qtyCompletedVal);

    // 4. Extract names if any
    List<String> nParts = extractParts(nameVal);

    if (chParts.isEmpty) return;

    for (int chIdx = 0; chIdx < chParts.length; chIdx++) {
      String explicitSNo = chParts[chIdx];
      if (explicitSNo.isEmpty || explicitSNo == '_') continue;

      double? parsedSNo = double.tryParse(explicitSNo);
      if (parsedSNo == null) continue;

      double sNoVal = parsedSNo;
      String sNoStr = sNoVal.toStringAsFixed(3);

      String d = chIdx < dParts.length ? dParts[chIdx] : '';
      String q = chIdx < qParts.length ? qParts[chIdx] : '';
      String dComp = chIdx < dCompParts.length ? dCompParts[chIdx] : '';
      String qComp = chIdx < qCompParts.length ? qCompParts[chIdx] : '';
      String explicitName = chIdx < nParts.length ? nParts[chIdx] : '';

      int durCompSec = _parseDurationToSeconds(dComp);
      int durPlanSec = _parseDurationToSeconds(d);
      int durSec = durCompSec > 0 ? durCompSec : durPlanSec;

      num qtyCompNum = _parseQuantity(qComp);
      num qtyPlanNum = _parseQuantity(q);
      num qtyValNum = qtyCompNum > 0 ? qtyCompNum : qtyPlanNum;

      // Determine display name (matching from configmaker / names)
      String channelName = '';
      if (explicitName.isNotEmpty && explicitName != '_') {
        channelName = explicitName;
      } else if (_channelNameMap.containsKey(sNoStr) &&
          _channelNameMap[sNoStr]!.isNotEmpty) {
        channelName = _channelNameMap[sNoStr]!;
      } else if (_channelNameMap.containsKey(sNoVal.toString()) &&
          _channelNameMap[sNoVal.toString()]!.isNotEmpty) {
        channelName = _channelNameMap[sNoVal.toString()]!;
      } else {
        int sInt = sNoVal.toInt();
        if (_channelNameMap.containsKey(sInt.toString()) &&
            _channelNameMap[sInt.toString()]!.isNotEmpty) {
          channelName = _channelNameMap[sInt.toString()]!;
        } else {
          // Look up in _fertilizerChannelsFromConfig
          Map<String, dynamic>? match;
          for (var c in _fertilizerChannelsFromConfig) {
            if (c['sNo'] != null) {
              String cSNo = c['sNo'].toString();
              if (cSNo == sNoStr ||
                  cSNo == sNoVal.toString() ||
                  double.tryParse(cSNo) == sNoVal) {
                match = c;
                break;
              }
            }
          }
          if (match != null &&
              match['name'] != null &&
              match['name'].toString().isNotEmpty) {
            channelName = match['name'].toString();
          } else {
            channelName = isCentral
                ? "Channel ${chIdx + 1}"
                : "Local Channel ${chIdx + 1}";
          }
        }
      }

      String category = isCentral ? "Central Fertilizer" : "Local Fertilizer";
      String rowKey = "${isCentral ? 'C' : 'L'}_$sNoStr";

      CumulativeRowData row = rowsMap.putIfAbsent(
        rowKey,
        () => CumulativeRowData(
          key: rowKey,
          channelName: channelName,
          channelCategory: category,
          channelSNo: sNoVal,
          dayEntries: {},
        ),
      );

      CumulativeDayData dayData = row.dayEntries.putIfAbsent(
        itemDateKey,
        () => CumulativeDayData(),
      );

      // Duplicate value sum for same day
      dayData.durationSeconds += durSec;
      dayData.quantity += qtyValNum;
      if (durSec > 0 || qtyValNum > 0) {
        dayData.hasRun = true;
      }
    }
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
              // Multi-Day Matrix Table, Graph View, or Cumulative Log View
              Expanded(
                child: _selectedLogTypeTab == 1
                    ? (_selectedViewTab == 0
                        ? _buildCumulativeLogMatrixTable(context)
                        : _buildCumulativeLogGraphView(context))
                    : (_selectedLogTypeTab == 2
                        ? (_selectedViewTab == 0
                            ? _buildPumpLogMatrixTable(context)
                            : _buildPumpLogGraphView(context))
                        : (_selectedViewTab == 0
                            ? _buildMultiDayMatrixTable(context)
                            : _buildZoneLogGraphView(context))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExcelExport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_selectedLogTypeTab == 2) {
      List<CumulativeRowData> activeRows = _getFilteredPumpRows();
      if (_dateColumns.isEmpty || activeRows.isEmpty) {
        messenger.showSnackBar(
          CustomSnackBar(message: "No records available to export"),
        );
        return;
      }

      Map<String, int> dailyRunTotals = {};
      Map<String, int> dailyPowerOnTotals = {};
      Map<String, int> dailyPowerOffTotals = {};
      int grandTotalRunSec = 0;
      int grandTotalPowerOnSec = 0;
      int grandTotalPowerOffSec = 0;

      for (var d in _dateColumns) {
        String dKey = DateFormat('yyyy-MM-dd').format(d);
        int dayRunSum = 0;
        int dayPowerOnSum = 0;
        int dayPowerOffSum = 0;

        for (var r in activeRows) {
          if (r.dayEntries.containsKey(dKey)) {
            final entry = r.dayEntries[dKey]!;
            dayRunSum += entry.durationSeconds;
            dayPowerOnSum += entry.powerOnSeconds;
            dayPowerOffSum += entry.powerOffSeconds;
          }
        }

        dailyRunTotals[dKey] = dayRunSum;
        dailyPowerOnTotals[dKey] = dayPowerOnSum;
        dailyPowerOffTotals[dKey] = dayPowerOffSum;
      }

      for (var r in activeRows) {
        grandTotalRunSec += r.totalDurationSeconds;
        grandTotalPowerOnSec += r.totalPowerOnSeconds;
        grandTotalPowerOffSec += r.totalPowerOffSeconds;
      }

      String fileName =
          "PUMPLog_${DateFormat('yyyyMMdd').format(_fromDate)}_${DateFormat('yyyyMMdd').format(_toDate)}_${DateFormat('yyyyMMdd').format(DateTime.now())}";

      String? res = await exportPumpLogMatrixToExcel(
        dateColumns: _dateColumns,
        rows: activeRows,
        dailyRunTotals: dailyRunTotals,
        dailyPowerOnTotals: dailyPowerOnTotals,
        dailyPowerOffTotals: dailyPowerOffTotals,
        grandTotalRunSeconds: grandTotalRunSec,
        grandTotalPowerOnSeconds: grandTotalPowerOnSec,
        grandTotalPowerOffSeconds: grandTotalPowerOffSec,
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
      return;
    }
    if (_selectedLogTypeTab == 1) {
      var activeRows = _getFilteredCumulativeRows();
      if (_dateColumns.isEmpty || activeRows.isEmpty) {
        messenger.showSnackBar(
          CustomSnackBar(message: "No records available to export"),
        );
        return;
      }

      Map<String, int> dailyTotals = {};
      Map<String, num> dailyTotalQuantities = {};
      int grandTotalSeconds = 0;
      num grandTotalQuantity = 0;
      for (var d in _dateColumns) {
        String dKey = DateFormat('yyyy-MM-dd').format(d);
        int daySum = 0;
        num dayQty = 0;
        for (var r in activeRows) {
          if (r.dayEntries.containsKey(dKey)) {
            daySum += (r.dayEntries[dKey]!.durationSeconds as num).toInt();
            dayQty += r.dayEntries[dKey]!.quantity;
          }
        }
        dailyTotals[dKey] = daySum;
        dailyTotalQuantities[dKey] = dayQty;
        grandTotalSeconds += daySum;
        grandTotalQuantity += dayQty;
      }

      List<SequenceRowData> exportRows = activeRows.map((c) {
        Map<String, SequenceDayData> dayEntries = {};
        c.dayEntries.forEach((k, v) {
          dayEntries[k] = SequenceDayData(
            durationQtySeconds: v.durationSeconds,
            quantityCompleted: v.quantity,
            hasRun: v.hasRun,
          );
        });
        return SequenceRowData(
          key: c.key,
          progName: c.channelCategory,
          progSNo: 1,
          seqName: c.channelName,
          dayEntries: dayEntries,
          totalDurationSeconds: c.totalDurationSeconds,
          totalQuantity: c.totalQuantity,
        );
      }).toList();

      String fileName =
          "CHANNELLog_${DateFormat('yyyyMMdd').format(_fromDate)}_${DateFormat('yyyyMMdd').format(_toDate)}_${DateFormat('yyyyMMdd').format(DateTime.now())}";

      String? res = await exportZoneLogMatrixToExcel(
        dateColumns: _dateColumns,
        rows: exportRows,
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
      return;
    }

    var filteredRows = _getFilteredSequenceRows();
    if (_dateColumns.isEmpty || filteredRows.isEmpty) {
      messenger.showSnackBar(
        CustomSnackBar(message: "No records available to export"),
      );
      return;
    }

    // Calculate daily total durations and quantities
    Map<String, int> dailyTotals = {};
    Map<String, num> dailyTotalQuantities = {};
    int grandTotalSeconds = 0;
    num grandTotalQuantity = 0;
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int daySum = 0;
      num dayQty = 0;
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

  Future<void> _handlePdfExport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_selectedLogTypeTab == 2) {
      List<CumulativeRowData> activeRows = _getFilteredPumpRows();
      if (_dateColumns.isEmpty || activeRows.isEmpty) {
        messenger.showSnackBar(
          CustomSnackBar(message: "No records available to export"),
        );
        return;
      }

      Map<String, int> dailyRunTotals = {};
      Map<String, int> dailyPowerOnTotals = {};
      Map<String, int> dailyPowerOffTotals = {};
      int grandTotalRunSec = 0;
      int grandTotalPowerOnSec = 0;
      int grandTotalPowerOffSec = 0;

      for (var d in _dateColumns) {
        String dKey = DateFormat('yyyy-MM-dd').format(d);
        int dayRunSum = 0;
        int dayPowerOnSum = 0;
        int dayPowerOffSum = 0;

        for (var r in activeRows) {
          if (r.dayEntries.containsKey(dKey)) {
            final entry = r.dayEntries[dKey]!;
            dayRunSum += entry.durationSeconds;
            dayPowerOnSum += entry.powerOnSeconds;
            dayPowerOffSum += entry.powerOffSeconds;
          }
        }

        dailyRunTotals[dKey] = dayRunSum;
        dailyPowerOnTotals[dKey] = dayPowerOnSum;
        dailyPowerOffTotals[dKey] = dayPowerOffSum;
      }

      for (var r in activeRows) {
        grandTotalRunSec += r.totalDurationSeconds;
        grandTotalPowerOnSec += r.totalPowerOnSeconds;
        grandTotalPowerOffSec += r.totalPowerOffSeconds;
      }

      String fileName =
          "PUMPLog_${DateFormat('yyyyMMdd').format(_fromDate)}_${DateFormat('yyyyMMdd').format(_toDate)}_${DateFormat('yyyyMMdd').format(DateTime.now())}";

      String? res = await exportPumpLogMatrixToPdf(
        dateColumns: _dateColumns,
        rows: activeRows,
        dailyRunTotals: dailyRunTotals,
        dailyPowerOnTotals: dailyPowerOnTotals,
        dailyPowerOffTotals: dailyPowerOffTotals,
        grandTotalRunSeconds: grandTotalRunSec,
        grandTotalPowerOnSeconds: grandTotalPowerOnSec,
        grandTotalPowerOffSeconds: grandTotalPowerOffSec,
        fileName: fileName,
      );

      if (res != null) {
        messenger.showSnackBar(
          CustomSnackBar(message: "PDF downloaded successfully: $res"),
        );
      } else {
        messenger.showSnackBar(
          CustomSnackBar(message: "Failed to export PDF"),
        );
      }
      return;
    }
    if (_selectedLogTypeTab == 1) {
      var activeRows = _getFilteredCumulativeRows();
      if (_dateColumns.isEmpty || activeRows.isEmpty) {
        messenger.showSnackBar(
          CustomSnackBar(message: "No records available to export"),
        );
        return;
      }

      Map<String, int> dailyTotals = {};
      Map<String, num> dailyTotalQuantities = {};
      int grandTotalSeconds = 0;
      num grandTotalQuantity = 0;
      for (var d in _dateColumns) {
        String dKey = DateFormat('yyyy-MM-dd').format(d);
        int daySum = 0;
        num dayQty = 0;
        for (var r in activeRows) {
          if (r.dayEntries.containsKey(dKey)) {
            daySum += (r.dayEntries[dKey]!.durationSeconds as num).toInt();
            dayQty += r.dayEntries[dKey]!.quantity;
          }
        }
        dailyTotals[dKey] = daySum;
        dailyTotalQuantities[dKey] = dayQty;
        grandTotalSeconds += daySum;
        grandTotalQuantity += dayQty;
      }

      List<SequenceRowData> exportRows = activeRows.map((c) {
        Map<String, SequenceDayData> dayEntries = {};
        c.dayEntries.forEach((k, v) {
          dayEntries[k] = SequenceDayData(
            durationQtySeconds: v.durationSeconds,
            quantityCompleted: v.quantity,
            hasRun: v.hasRun,
          );
        });
        return SequenceRowData(
          key: c.key,
          progName: c.channelCategory,
          progSNo: 1,
          seqName: c.channelName,
          dayEntries: dayEntries,
          totalDurationSeconds: c.totalDurationSeconds,
          totalQuantity: c.totalQuantity,
        );
      }).toList();

      String fileName =
          "CumulativeLog_${DateFormat('yyyyMMdd').format(_fromDate)}_${DateFormat('yyyyMMdd').format(_toDate)}";

      String? res = await exportZoneLogMatrixToPdf(
        dateColumns: _dateColumns,
        rows: exportRows,
        dailyTotals: dailyTotals,
        dailyTotalQuantities: dailyTotalQuantities,
        grandTotalSeconds: grandTotalSeconds,
        grandTotalQuantity: grandTotalQuantity,
        fileName: fileName,
      );

      if (res != null) {
        messenger.showSnackBar(
          CustomSnackBar(message: "PDF downloaded successfully: $res"),
        );
      } else {
        messenger.showSnackBar(
          CustomSnackBar(message: "Failed to export PDF"),
        );
      }
      return;
    }

    var filteredRows = _getFilteredSequenceRows();
    if (_dateColumns.isEmpty || filteredRows.isEmpty) {
      messenger.showSnackBar(
        CustomSnackBar(message: "No records available to export"),
      );
      return;
    }

    Map<String, int> dailyTotals = {};
    Map<String, num> dailyTotalQuantities = {};
    int grandTotalSeconds = 0;
    num grandTotalQuantity = 0;
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int daySum = 0;
      num dayQty = 0;
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

    String? res = await exportZoneLogMatrixToPdf(
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
        CustomSnackBar(message: "PDF downloaded successfully: $res"),
      );
    } else {
      messenger.showSnackBar(
        CustomSnackBar(message: "Failed to export PDF"),
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
                fetchPumpLogApi();
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
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                // Row 2: Program Filter (only for Zone Log tab) & Excel Button
                Row(
                  children: [
                    if (_selectedLogTypeTab == 0) ...[
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
                                  border: Border.all(
                                      color: const Color(0xFFCBD5E1)),
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
                    ] else if (_selectedLogTypeTab == 2) ...[
                      // Pump Dropdown
                      Expanded(
                        child: Row(
                          children: [
                            const Text("Pump",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                height: 36,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.white,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _pumpDropdownOptions
                                            .contains(_selectedPumpFilter)
                                        ? _selectedPumpFilter
                                        : 'All Pumps',
                                    isDense: true,
                                    isExpanded: true,
                                    items: _pumpDropdownOptions
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
                                          _selectedPumpFilter = val;
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
                    ] else
                      const Spacer(),
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
                    const SizedBox(width: 4),
                    // PDF Button
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 36),
                        side: const BorderSide(color: Color(0xFFC62828)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _handlePdfExport(context),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf,
                              size: 13, color: Color(0xFFC62828)),
                          SizedBox(width: 3),
                          Text("PDF",
                              style: TextStyle(
                                  color: Color(0xFFC62828),
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
              // Program Filter Dropdown (only for Zone Log tab)
              if (_selectedLogTypeTab == 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Program",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
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
                )
              else if (_selectedLogTypeTab == 2)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Pump",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
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
                          value:
                              _pumpDropdownOptions.contains(_selectedPumpFilter)
                                  ? _selectedPumpFilter
                                  : 'All Pumps',
                          isDense: true,
                          items: _pumpDropdownOptions
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPumpFilter = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),

              // Export Buttons
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
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      side: const BorderSide(color: Color(0xFFC62828)),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () => _handlePdfExport(context),
                    icon: const Icon(Icons.picture_as_pdf,
                        size: 14, color: Color(0xFFC62828)),
                    label: const Text("PDF",
                        style: TextStyle(
                            color: Color(0xFFC62828),
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
              // Left side: View tabs (Table View / Graph View)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.all(2),
                // ignore: prefer_const_constructors
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  // ignore: prefer_const_literals_to_create_immutables
                  children: [
                    // InkWell(
                    //   onTap: () {
                    //     if (_selectedViewTab != 0) {
                    //       setState(() {
                    //         _selectedViewTab = 0;
                    //       });
                    //     }
                    //   },
                    //   borderRadius: BorderRadius.circular(4),
                    //   child: Container(
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 10, vertical: 5),
                    //     decoration: BoxDecoration(
                    //       color: _selectedViewTab == 0
                    //           ? Colors.white
                    //           : Colors.transparent,
                    //       borderRadius: BorderRadius.circular(4),
                    //       boxShadow: _selectedViewTab == 0
                    //           ? const [
                    //               BoxShadow(
                    //                 color: Colors.black12,
                    //                 blurRadius: 2,
                    //                 offset: Offset(0, 1),
                    //               )
                    //             ]
                    //           : null,
                    //     ),
                    //     child: Row(
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: [
                    //         Icon(
                    //           Icons.table_rows_outlined,
                    //           size: 14,
                    //           color: _selectedViewTab == 0
                    //               ? const Color(0xFF00695C)
                    //               : Colors.white,
                    //         ),
                    //         const SizedBox(width: 5),
                    //         Text(
                    //           "Table View",
                    //           style: TextStyle(
                    //             fontSize: 11.5,
                    //             fontWeight: _selectedViewTab == 0
                    //                 ? FontWeight.bold
                    //                 : FontWeight.w500,
                    //             color: _selectedViewTab == 0
                    //                 ? const Color(0xFF00695C)
                    //                 : Colors.white,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: 2),
                    // InkWell(
                    //   onTap: () {
                    //     if (_selectedViewTab != 1) {
                    //       setState(() {
                    //         _selectedViewTab = 1;
                    //       });
                    //     }
                    //   },
                    //   borderRadius: BorderRadius.circular(4),
                    //   child: Container(
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 10, vertical: 5),
                    //     decoration: BoxDecoration(
                    //       color: _selectedViewTab == 1
                    //           ? Colors.white
                    //           : Colors.transparent,
                    //       borderRadius: BorderRadius.circular(4),
                    //       boxShadow: _selectedViewTab == 1
                    //           ? const [
                    //               BoxShadow(
                    //                 color: Colors.black12,
                    //                 blurRadius: 2,
                    //                 offset: Offset(0, 1),
                    //               )
                    //             ]
                    //           : null,
                    //     ),
                    //     child: Row(
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: [
                    //         Icon(
                    //           Icons.bar_chart_rounded,
                    //           size: 14,
                    //           color: _selectedViewTab == 1
                    //               ? const Color(0xFF00695C)
                    //               : Colors.white,
                    //         ),
                    //         const SizedBox(width: 5),
                    //         Text(
                    //           "Graph View",
                    //           style: TextStyle(
                    //             fontSize: 11.5,
                    //             fontWeight: _selectedViewTab == 1
                    //                 ? FontWeight.bold
                    //                 : FontWeight.w500,
                    //             color: _selectedViewTab == 1
                    //                 ? const Color(0xFF00695C)
                    //                 : Colors.white,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),

              // Zone Log & Cumulative Log Toggle Tabs (Right Corner)
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
                        if (_selectedLogTypeTab != 0) {
                          setState(() {
                            _selectedLogTypeTab = 0;
                          });
                          if (_verticalScrollController.hasClients) {
                            _verticalScrollController.jumpTo(0);
                          }
                          if (_horizontalScrollController.hasClients) {
                            _horizontalScrollController.jumpTo(0);
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _selectedLogTypeTab == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _selectedLogTypeTab == 0
                              ? const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          "Zone",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: _selectedLogTypeTab == 0
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _selectedLogTypeTab == 0
                                ? const Color(0xFF00695C)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: () {
                        if (_selectedLogTypeTab != 1) {
                          setState(() {
                            _selectedLogTypeTab = 1;
                            _selectedCumulativeFilter = 'All Channels';
                          });
                          if (_verticalScrollController.hasClients) {
                            _verticalScrollController.jumpTo(0);
                          }
                          if (_horizontalScrollController.hasClients) {
                            _horizontalScrollController.jumpTo(0);
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _selectedLogTypeTab == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _selectedLogTypeTab == 1
                              ? const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          "Channel",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: _selectedLogTypeTab == 1
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _selectedLogTypeTab == 1
                                ? const Color(0xFF00695C)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: () {
                        if (_selectedLogTypeTab != 2) {
                          setState(() {
                            _selectedLogTypeTab = 2;
                            _selectedPumpFilter = 'All Pumps';
                          });
                          if (_verticalScrollController.hasClients) {
                            _verticalScrollController.jumpTo(0);
                          }
                          if (_horizontalScrollController.hasClients) {
                            _horizontalScrollController.jumpTo(0);
                          }
                          fetchPumpLogApi();
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _selectedLogTypeTab == 2
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _selectedLogTypeTab == 2
                              ? const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          "Pump",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: _selectedLogTypeTab == 2
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _selectedLogTypeTab == 2
                                ? const Color(0xFF00695C)
                                : Colors.white,
                          ),
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

  Widget _buildCumulativeLogMatrixTable(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    var rows = _getFilteredCumulativeRows();

    if (_dateColumns.isEmpty || rows.isEmpty) {
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

    // Calculate daily total durations and quantities for cumulative channels
    Map<String, int> dailyTotals = {};
    Map<String, num> dailyTotalQuantities = {};
    int grandTotalSeconds = 0;
    num grandTotalQuantity = 0;
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int daySum = 0;
      num dayQty = 0;
      for (var r in rows) {
        if (r.dayEntries.containsKey(dKey)) {
          daySum += (r.dayEntries[dKey]!.durationSeconds as num).toInt();
          dayQty += r.dayEntries[dKey]!.quantity;
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
          return _buildMobileCumulativeMatrixTable(
            context,
            rows,
            dailyTotals,
            dailyTotalQuantities,
            grandTotalSeconds,
            grandTotalQuantity,
          );
        }

        // Base Column Widths
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
              // 1. PINNED LEFT CHANNEL COLUMN
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
                    // Top Header: Fertilizer Channel
                    Container(
                      width: colSeqWidth,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00695C),
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFCBD5E1), width: 1),
                        ),
                      ),
                      child: const Text(
                        "Fertilizer Channel",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Sub-Header
                    _buildSubHeaderCell("Fertilizer\nChannel", colSeqWidth),

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
                              for (int rIdx = 0; rIdx < rows.length; rIdx++)
                                _buildPinnedLeftCumulativeRow(
                                  rows[rIdx],
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
                          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          bottom:
                              BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
                    const SizedBox(height: 15),
                  ],
                ),
              ),

              // 2. DATE COLUMNS AREA
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
                            // TOP HEADER ROW (Gray Date Headers)
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
                                      color: Color(0xFFE2E8F0),
                                      border: Border(
                                        right: BorderSide(
                                            color: Color(0xFFCBD5E1), width: 1),
                                        bottom: BorderSide(
                                            color: Color(0xFFCBD5E1), width: 1),
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

                            // SUB-HEADER ROW: Duration / Quantity per date
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
                                            rIdx < rows.length;
                                            rIdx++)
                                          Container(
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: rIdx % 2 == 0
                                                  ? Colors.white
                                                  : const Color(0xFFF8FAFC),
                                              border: const Border(
                                                bottom: BorderSide(
                                                    color: Color(0xFFE2E8F0),
                                                    width: 1),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                for (int dIdx = 0;
                                                    dIdx < _dateColumns.length;
                                                    dIdx++)
                                                  _buildDateCumulativeBlock(
                                                    rows[rIdx],
                                                    _dateColumns[dIdx],
                                                    colDateWidth,
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // FOOTER / DAILY TOTAL ROW
                            _buildDailyCumulativeFooterTotalRow(
                              dailyTotals,
                              dailyTotalQuantities,
                              colDateWidth,
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. PINNED RIGHT TOTAL COLUMN
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
                        color: Color(0xFF00695C),
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFCBD5E1), width: 1),
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

                    // Sub-Header
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
                              for (int rIdx = 0; rIdx < rows.length; rIdx++)
                                _buildPinnedCumulativeTotalRow(
                                  rows[rIdx],
                                  rIdx,
                                  colTotalWidth,
                                  isPinned: true,
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
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          bottom:
                              BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                      ),
                      child: Text(
                        "${_formatDuration(grandTotalSeconds)} /\n${grandTotalQuantity > 0 ? (grandTotalQuantity % 1 == 0 ? '${grandTotalQuantity.toInt()} L' : '$grandTotalQuantity L') : '-'}",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 1100
                              ? 12.5
                              : 13.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileCumulativeMatrixTable(
    BuildContext context,
    List<CumulativeRowData> rows,
    Map<String, int> dailyTotals,
    Map<String, num> dailyTotalQuantities,
    int grandTotalSeconds,
    num grandTotalQuantity,
  ) {
    const double colSeqWidth = 140;
    const double colDateWidth = 130;
    const double colTotalWidth = 130;
    final double totalTableWidth =
        colSeqWidth + (_dateColumns.length * colDateWidth) + colTotalWidth;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(6),
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
                            bottom:
                                BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          ),
                        ),
                        child: const Text(
                          "Fertilizer Channel",
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
                            color: Color(0xFFE2E8F0),
                            border: Border(
                              right: BorderSide(
                                  color: Color(0xFFCBD5E1), width: 1),
                              bottom: BorderSide(
                                  color: Color(0xFFCBD5E1), width: 1),
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
                          color: Color(0xFF00695C),
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
                      _buildSubHeaderCell("Fertilizer\nChannel", colSeqWidth),
                      for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
                        _buildSubHeaderCell(
                            "Duration /\nQuantity", colDateWidth),
                      _buildSubHeaderCell(
                          "Total\nDuration /\nQuantity", colTotalWidth,
                          isTotalCol: true),
                    ],
                  ),

                  // 3. DATA ROWS
                  for (int rIdx = 0; rIdx < rows.length; rIdx++)
                    _buildMobileCumulativeDataRow(
                      rows[rIdx],
                      rIdx,
                      colSeqWidth,
                      colDateWidth,
                      colTotalWidth,
                    ),

                  // 4. FOOTER TOTAL ROW
                  _buildMobileCumulativeFooterTotalRow(
                    dailyTotals,
                    dailyTotalQuantities,
                    grandTotalSeconds,
                    grandTotalQuantity,
                    colSeqWidth,
                    colDateWidth,
                    colTotalWidth,
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCumulativeDataRow(
    CumulativeRowData row,
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
          _buildPinnedLeftCumulativeRow(row, rowIndex, colSeqWidth),
          for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
            _buildDateCumulativeBlock(
              row,
              _dateColumns[dIdx],
              colDateWidth,
            ),
          _buildPinnedCumulativeTotalRow(
            row,
            rowIndex,
            colTotalWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCumulativeFooterTotalRow(
    Map<String, int> dailyTotals,
    Map<String, num> dailyTotalQuantities,
    int grandTotalSeconds,
    num grandTotalQuantity,
    double colSeqWidth,
    double colDateWidth,
    double colTotalWidth,
  ) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
              num daySumQty = dailyTotalQuantities[dKey] ?? 0;
              String dayTotalFormatted = _formatDuration(daySumSec);
              String qtyStr = daySumQty > 0
                  ? (daySumQty % 1 == 0
                      ? "${daySumQty.toInt()} L"
                      : "$daySumQty L")
                  : '-';

              return Container(
                width: colDateWidth,
                height: 46,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Text(
                  "$dayTotalFormatted /\n$qtyStr",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.0,
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
              "${_formatDuration(grandTotalSeconds)} /\n${grandTotalQuantity > 0 ? (grandTotalQuantity % 1 == 0 ? '${grandTotalQuantity.toInt()} L' : '$grandTotalQuantity L') : '-'}",
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedLeftCumulativeRow(
    CumulativeRowData row,
    int rowIndex,
    double colWidth,
  ) {
    Color rowBg = rowIndex % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);

    return Container(
      width: colWidth,
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  row.channelCategory,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:
                        MediaQuery.of(context).size.width < 650 ? 11.0 : 12.0,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFC8E6C9), width: 1),
                  ),
                  child: Text(
                    row.channelName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize:
                          MediaQuery.of(context).size.width < 650 ? 10.5 : 11.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showIndividualChannelGraphDialog(context, row),
              borderRadius: BorderRadius.circular(4),
              child: Tooltip(
                message: "Open ${row.channelName} Graph",
                child: Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: const Color(0xFFB2DFDB), width: 1),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    size: 15,
                    color: Color(0xFF00695C),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCumulativeBlock(
    CumulativeRowData row,
    DateTime date,
    double colDateWidth,
  ) {
    String dKey = DateFormat('yyyy-MM-dd').format(date);
    CumulativeDayData? dayData = row.dayEntries[dKey];

    String cellText;
    bool isBold = false;
    if (dayData != null && dayData.hasRun) {
      String dur = dayData.durationStr;
      String qty = dayData.qtyStr;
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

  Widget _buildPinnedCumulativeTotalRow(
    CumulativeRowData row,
    int rowIndex,
    double colTotalWidth, {
    bool isPinned = false,
  }) {
    Color rowBg = rowIndex % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);

    String qtyStr = row.totalQuantity > 0
        ? (row.totalQuantity % 1 == 0
            ? "${row.totalQuantity.toInt()} L"
            : "${row.totalQuantity} L")
        : '-';
    String formattedText =
        "${_formatDuration(row.totalDurationSeconds)} /\n$qtyStr";

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showIndividualChannelGraphDialog(context, row),
          borderRadius: BorderRadius.circular(4),
          child: Tooltip(
            message: "Tap to view ${row.channelName} graph",
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                formattedText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 650
                      ? 12.0
                      : (MediaQuery.of(context).size.width < 1100
                          ? 12.5
                          : 13.0),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF15803D),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCumulativeFooterTotalRow(
    Map<String, int> dailyTotals,
    Map<String, num> dailyTotalQuantities,
    double colDateWidth,
  ) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
            Builder(builder: (context) {
              String dKey = DateFormat('yyyy-MM-dd').format(_dateColumns[dIdx]);
              int daySumSec = dailyTotals[dKey] ?? 0;
              num daySumQty = dailyTotalQuantities[dKey] ?? 0;
              String dayTotalFormatted = _formatDuration(daySumSec);
              String qtyStr = daySumQty > 0
                  ? (daySumQty % 1 == 0
                      ? "${daySumQty.toInt()} L"
                      : "$daySumQty L")
                  : '-';

              final double screenWidth = MediaQuery.of(context).size.width;
              final double fontSize =
                  screenWidth < 650 ? 12.0 : (screenWidth < 1100 ? 12.5 : 13.0);

              return Container(
                width: colDateWidth,
                height: 46,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Text(
                  "$dayTotalFormatted /\n$qtyStr",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF166534),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCumulativeLogGraphView(BuildContext context,
      [List<CumulativeRowData>? overrideRows,
      String title = "Fertilizer Channel Breakdown"]) {
    if (_isLoading || _isPumpLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    var filteredRows = overrideRows ?? _getFilteredCumulativeRows();

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
    num grandTotalQuantity = 0;
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
                grandTotalQuantity: grandTotalQuantity.toInt(),
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
                    // Controls: Metric Selector & Type Selector
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
                                activeColor: const Color(0xFF16A34A),
                                isSelected: _selectedGraphMetric == 'Quantity',
                                onTap: () => setState(
                                    () => _selectedGraphMetric = 'Quantity'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // SfCartesianChart with static Y-axis and horizontal scrolling for date range
                    SizedBox(
                      height: 320,
                      child: _buildCumulativeSfChart(
                        filteredRows,
                        overrideScrollController: _cumGraphScrollController,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Fertilizer Channel Breakdown Cards
              Text(
                "$title (${filteredRows.length})",
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),

              for (var row in filteredRows)
                _buildCumulativeChannelBreakdownCard(
                    row, grandTotalSeconds, grandTotalQuantity),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCumulativeSfChart(
    List<CumulativeRowData> rows, {
    String? overrideMetric,
    String? overrideChartType,
    ScrollController? overrideScrollController,
  }) {
    List<_ZoneChartPoint> dataPoints = [];

    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      String label = "${d.day}/${DateFormat('MMM').format(d).toLowerCase()}";
      int sumSec = 0;
      num sumQty = 0;
      for (var r in rows) {
        if (r.dayEntries.containsKey(dKey)) {
          sumSec += r.dayEntries[dKey]!.durationSeconds;
          sumQty += r.dayEntries[dKey]!.quantity;
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

    final String metric = overrideMetric ?? _selectedGraphMetric;
    final String chartType = overrideChartType ?? _graphChartType;
    final bool isDuration = metric == 'Duration';
    final ScrollController scrollController =
        overrideScrollController ?? _cumGraphScrollController;

    return _buildResponsiveStaticAxisChart(
      dataPoints: dataPoints,
      isDuration: isDuration,
      chartType: chartType,
      scrollController: scrollController,
    );
  }

  Widget _buildCumulativeChannelBreakdownCard(
      CumulativeRowData row, int grandTotalSeconds, num grandTotalQuantity) {
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
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
        ),
        child: Icon(
          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          size: 16,
          color: const Color(0xFF0F766E),
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

    String qtyStr = row.totalQuantity > 0
        ? (row.totalQuantity % 1 == 0
            ? "${row.totalQuantity.toInt()} L"
            : "${row.totalQuantity} L")
        : "-";

    Widget quantityBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop_outlined,
              size: 11, color: Color(0xFF166534)),
          const SizedBox(width: 3),
          Text(
            qtyStr,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF166534),
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
                // Mobile: Row 1 = Channel Name + Category + Toggle
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
                        row.channelName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    if (row.channelCategory.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "(${row.channelCategory})",
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
                // Mobile: Row 2 = Duration Badge & Quantity Badge
                Row(
                  children: [
                    durationBadge,
                    const SizedBox(width: 6),
                    quantityBadge,
                  ],
                ),
              ] else ...[
                // Wide: Single Row
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
                              row.channelName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          if (row.channelCategory.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "(${row.channelCategory})",
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
                                  color: Color(0xFF166534),
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
                          CumulativeDayData? dayData = row.dayEntries[dKey];

                          bool hasRun = dayData != null && dayData.hasRun;
                          int durSec = dayData?.durationSeconds ?? 0;
                          num qty = dayData?.quantity ?? 0;

                          String durStr = (hasRun && durSec > 0)
                              ? _formatDuration(durSec)
                              : (hasRun && dayData.durationStr != '00:00:00'
                                  ? dayData.durationStr
                                  : '-');
                          String dayQtyStr = (hasRun && qty > 0)
                              ? (qty % 1 == 0 ? "${qty.toInt()} L" : "$qty L")
                              : '-';

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
                                    dayQtyStr,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: dayQtyStr != '-'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: dayQtyStr != '-'
                                          ? const Color(0xFF166534)
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
                                qtyStr,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
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
    Map<String, num> dailyTotalQuantities = {};
    int grandTotalSeconds = 0;
    num grandTotalQuantity = 0;
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int daySum = 0;
      num dayQty = 0;
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
        const double baseSeqWidth = 170;
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
                    // Top Header: Program / Valve / Sequence
                    Container(
                      width: colSeqWidth,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00695C),
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFCBD5E1), width: 1),
                        ),
                      ),
                      child: const Text(
                        "Program / Valve / Sequence",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Sub-Header: Program / Valve / Sequence
                    _buildSubHeaderCell(
                        "Program /\nValve /\nSequence", colSeqWidth,
                        height: 48),

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
                          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          bottom:
                              BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
                    const SizedBox(height: 15),
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
                            // TOP HEADER ROW (Gray Date Headers)
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
                                      color: Color(0xFFE2E8F0),
                                      border: Border(
                                        right: BorderSide(
                                            color: Color(0xFFCBD5E1), width: 1),
                                        bottom: BorderSide(
                                            color: Color(0xFFCBD5E1), width: 1),
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
                                      "Duration /\nQuantity", colDateWidth,
                                      height: 48),
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
                            const SizedBox(height: 15),
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
                        color: Color(0xFF00695C),
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFCBD5E1), width: 1),
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
                        isTotalCol: true, height: 48),

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
                          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          bottom:
                              BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                      ),
                      child: Text(
                        "${_formatDuration(grandTotalSeconds)} /\n${grandTotalQuantity > 0 ? (grandTotalQuantity % 1 == 0 ? '${grandTotalQuantity.toInt()} L' : '$grandTotalQuantity L') : '-'}",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 1100
                              ? 12.5
                              : 13.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
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
    Map<String, num> dailyTotalQuantities,
    int grandTotalSeconds,
    num grandTotalQuantity,
  ) {
    const double colSeqWidth = 155;
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
                          "Program / Valve / Sequence",
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
                            color: Color(0xFFE2E8F0),
                            border: Border(
                              right: BorderSide(
                                  color: Color(0xFFCBD5E1), width: 1),
                              bottom: BorderSide(
                                  color: Color(0xFFCBD5E1), width: 1),
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
                          color: Color(0xFF00695C),
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
                      _buildSubHeaderCell(
                          "Program /\nValve /\nSequence", colSeqWidth,
                          height: 48),
                      for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
                        _buildSubHeaderCell(
                            "Duration /\nQuantity", colDateWidth,
                            height: 48),
                      _buildSubHeaderCell(
                          "Total\nDuration /\nQuantity", colTotalWidth,
                          isTotalCol: true, height: 48),
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
                  const SizedBox(height: 15),
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
    Map<String, num> dailyTotalQuantities,
    int grandTotalSeconds,
    num grandTotalQuantity,
    double colSeqWidth,
    double colDateWidth,
    double colTotalWidth,
  ) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
              num daySumQty = dailyTotalQuantities[dKey] ?? 0;
              String dayTotalFormatted = _formatDuration(daySumSec);
              String qtyStr = daySumQty > 0
                  ? (daySumQty % 1 == 0
                      ? "${daySumQty.toInt()} L"
                      : "$daySumQty L")
                  : '-';

              return Container(
                width: colDateWidth,
                height: 46,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Text(
                  "$dayTotalFormatted /\n$qtyStr",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.0,
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
              "${_formatDuration(grandTotalSeconds)} /\n${grandTotalQuantity > 0 ? (grandTotalQuantity % 1 == 0 ? '${grandTotalQuantity.toInt()} L' : '$grandTotalQuantity L') : '-'}",
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
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
      {bool isTotalCol = false, double? height}) {
    return Container(
      width: width.isFinite ? width : null,
      height: height ?? 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFE0F2F1),
        border: Border(
          right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
          bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        maxLines: 3,
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width < 650 ? 10.0 : 10.5,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F766E),
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
      height: 64,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
              message:
                  "${row.progName.isNotEmpty && row.progName != row.seqName ? '${row.progName} - ' : ''}${row.valveName.isNotEmpty ? '${row.valveName} - ' : ''}${row.seqName}",
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (row.progName.isNotEmpty &&
                      row.progName != row.seqName) ...[
                    Text(
                      row.progName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 650
                            ? 10.0
                            : 11.0,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 1),
                  ],
                  if (row.valveName.isNotEmpty) ...[
                    Text(
                      row.valveName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 650
                            ? 9.5
                            : 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(height: 1),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: const Color(0xFFC8E6C9), width: 1),
                    ),
                    child: Text(
                      row.seqName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 650
                            ? 9.5
                            : 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showIndividualSequenceGraphDialog(context, row),
              borderRadius: BorderRadius.circular(4),
              child: Tooltip(
                message: "Open ${row.seqName} Graph",
                child: Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: const Color(0xFFB2DFDB), width: 1),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    size: 15,
                    color: Color(0xFF00695C),
                  ),
                ),
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
      height: 64,
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
    num rowTotalQuantity = 0;
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      if (row.dayEntries.containsKey(dKey)) {
        rowTotalSeconds += row.dayEntries[dKey]!.durationQtySeconds;
        rowTotalQuantity += row.dayEntries[dKey]!.quantityCompleted;
      }
    }

    String qtyTotalStr = rowTotalQuantity > 0
        ? (rowTotalQuantity % 1 == 0
            ? "${rowTotalQuantity.toInt()} L"
            : "$rowTotalQuantity L")
        : '-';

    String formattedText =
        "${_formatDuration(rowTotalSeconds)} /\n$qtyTotalStr";

    if (isPinned) {
      return Container(
        width: colTotalWidth,
        height: 64,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: rowBg,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showIndividualSequenceGraphDialog(context, row),
            borderRadius: BorderRadius.circular(4),
            child: Tooltip(
              message: "Tap to view ${row.seqName} graph",
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  formattedText,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 650
                        ? 12.0
                        : (MediaQuery.of(context).size.width < 1100
                            ? 12.5
                            : 13.0),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: colTotalWidth,
      height: 64,
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
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width < 650
              ? 12.0
              : (MediaQuery.of(context).size.width < 1100 ? 12.5 : 13.0),
          fontWeight: FontWeight.bold,
          color: const Color(0xFF15803D),
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
          ? (dayData.quantityCompleted % 1 == 0
              ? "${dayData.quantityCompleted.toInt()} L"
              : "${dayData.quantityCompleted} L")
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
      height: 64,
    );
  }

  Widget _buildDataTableCell(
    String text,
    double width, {
    bool isBold = false,
    int maxLines = 2,
    double? height,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize =
        screenWidth < 650 ? 12.0 : (screenWidth < 1100 ? 12.5 : 13.0);

    return Container(
      width: width,
      height: height ?? 52,
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
          fontSize: fontSize,
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
    Map<String, num> dailyTotalQuantities,
    double colDateWidth,
  ) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
            Builder(builder: (context) {
              String dKey = DateFormat('yyyy-MM-dd').format(_dateColumns[dIdx]);
              int daySumSec = dailyTotals[dKey] ?? 0;
              num daySumQty = dailyTotalQuantities[dKey] ?? 0;
              String dayTotalFormatted = _formatDuration(daySumSec);
              String qtyStr = daySumQty > 0
                  ? (daySumQty % 1 == 0
                      ? "${daySumQty.toInt()} L"
                      : "$daySumQty L")
                  : '-';

              final double screenWidth = MediaQuery.of(context).size.width;
              final double fontSize =
                  screenWidth < 650 ? 12.0 : (screenWidth < 1100 ? 12.5 : 13.0);

              return Container(
                width: colDateWidth,
                height: 46,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Text(
                  "$dayTotalFormatted /\n$qtyStr",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF166534),
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
    num grandTotalQuantity = 0;
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
                                activeColor: const Color(0xFF16A34A),
                                isSelected: _selectedGraphMetric == 'Quantity',
                                onTap: () => setState(
                                    () => _selectedGraphMetric = 'Quantity'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // SfCartesianChart with static Y-axis and horizontal scrolling for date range
                    SizedBox(
                      height: 320,
                      child: _buildSfChart(
                        filteredRows,
                        overrideScrollController: _zoneGraphScrollController,
                      ),
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
    required num grandTotalQuantity,
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
                            ? (grandTotalQuantity % 1 == 0
                                ? "${grandTotalQuantity.toInt()} L"
                                : "$grandTotalQuantity L")
                            : "-",
                        icon: Icons.water_drop_outlined,
                        color: const Color(0xFF16A34A),
                        bgColor: const Color(0xFFF0FDF4),
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
                    value: grandTotalQuantity > 0
                        ? (grandTotalQuantity % 1 == 0
                            ? "${grandTotalQuantity.toInt()} L"
                            : "$grandTotalQuantity L")
                        : "-",
                    icon: Icons.water_drop_outlined,
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFF0FDF4),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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

  Widget _buildSummaryBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showIndividualSequenceGraphDialog(
    BuildContext context,
    SequenceRowData row,
  ) {
    String localMetric = _selectedGraphMetric;
    String localChartType = _graphChartType;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double dialogWidth = math.min(
              MediaQuery.of(context).size.width * 0.92,
              750.0,
            );

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: math.min(
                    MediaQuery.of(context).size.height * 0.85,
                    540.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              size: 20,
                              color: Color(0xFF00695C),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.progName.isNotEmpty &&
                                          row.progName != row.seqName
                                      ? "${row.progName} - ${row.seqName}"
                                      : row.seqName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 20, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 10),

                      // Metric Summary Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSummaryBadge(
                            icon: Icons.timer_outlined,
                            label: "Total Duration",
                            value: _formatDuration(row.totalDurationSeconds),
                            color: const Color(0xFF00897B),
                            bgColor: const Color(0xFFE0F2F1),
                          ),
                          _buildSummaryBadge(
                            icon: Icons.water_drop_outlined,
                            label: "Total Quantity",
                            value: row.totalQuantity > 0
                                ? (row.totalQuantity % 1 == 0
                                    ? "${row.totalQuantity.toInt()} L"
                                    : "${row.totalQuantity} L")
                                : "-",
                            color: const Color(0xFF166534),
                            bgColor: const Color(0xFFF0FDF4),
                          ),
                          _buildSummaryBadge(
                            icon: Icons.calendar_today_outlined,
                            label: "Total Days",
                            value: "${_dateColumns.length} Days",
                            color: const Color(0xFF475569),
                            bgColor: const Color(0xFFF1F5F9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Controls: Metric & Chart Type Selector
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
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
                                  isSelected: localMetric == 'Duration',
                                  onTap: () {
                                    setDialogState(
                                        () => localMetric = 'Duration');
                                  },
                                ),
                                _buildMetricTab(
                                  label: "Quantity",
                                  icon: Icons.water_drop_outlined,
                                  activeColor: const Color(0xFF16A34A),
                                  isSelected: localMetric == 'Quantity',
                                  onTap: () {
                                    setDialogState(
                                        () => localMetric = 'Quantity');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Chart Area: Static Y-axis and horizontal scrolling
                      Expanded(
                        child: _buildSfChart(
                          [row],
                          overrideMetric: localMetric,
                          overrideChartType: localChartType,
                          overrideScrollController:
                              _seqDialogGraphScrollController,
                        ),
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
  }

  void _showIndividualChannelGraphDialog(
    BuildContext context,
    CumulativeRowData row,
  ) {
    String localMetric = _selectedGraphMetric;
    String localChartType = _graphChartType;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double dialogWidth = math.min(
              MediaQuery.of(context).size.width * 0.92,
              750.0,
            );

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: math.min(
                    MediaQuery.of(context).size.height * 0.85,
                    540.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              size: 20,
                              color: Color(0xFF00695C),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${row.channelCategory} - ${row.channelName}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 20, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 10),

                      // Metric Summary Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSummaryBadge(
                            icon: Icons.timer_outlined,
                            label: "Total Duration",
                            value: _formatDuration(row.totalDurationSeconds),
                            color: const Color(0xFF00897B),
                            bgColor: const Color(0xFFE0F2F1),
                          ),
                          _buildSummaryBadge(
                            icon: Icons.water_drop_outlined,
                            label: "Total Quantity",
                            value: row.totalQuantity > 0
                                ? (row.totalQuantity % 1 == 0
                                    ? "${row.totalQuantity.toInt()} L"
                                    : "${row.totalQuantity} L")
                                : "-",
                            color: const Color(0xFF166534),
                            bgColor: const Color(0xFFF0FDF4),
                          ),
                          _buildSummaryBadge(
                            icon: Icons.calendar_today_outlined,
                            label: "Total Days",
                            value: "${_dateColumns.length} Days",
                            color: const Color(0xFF475569),
                            bgColor: const Color(0xFFF1F5F9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Controls: Metric & Chart Type Selector
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
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
                                  isSelected: localMetric == 'Duration',
                                  onTap: () {
                                    setDialogState(
                                        () => localMetric = 'Duration');
                                  },
                                ),
                                _buildMetricTab(
                                  label: "Quantity",
                                  icon: Icons.water_drop_outlined,
                                  activeColor: const Color(0xFF16A34A),
                                  isSelected: localMetric == 'Quantity',
                                  onTap: () {
                                    setDialogState(
                                        () => localMetric = 'Quantity');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Chart Area: Static Y-axis and horizontal scrolling
                      Expanded(
                        child: _buildCumulativeSfChart(
                          [row],
                          overrideMetric: localMetric,
                          overrideChartType: localChartType,
                          overrideScrollController:
                              _chanDialogGraphScrollController,
                        ),
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
  }

  void _showIndividualPumpGraphDialog(
    BuildContext context,
    CumulativeRowData row,
  ) {
    String localMetric = 'Runtime';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double dialogWidth = math.min(
              MediaQuery.of(context).size.width * 0.92,
              750.0,
            );

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: math.min(
                    MediaQuery.of(context).size.height * 0.85,
                    540.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              size: 20,
                              color: Color(0xFF00695C),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${row.channelCategory} - ${row.channelName}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 20, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 10),

                      // Metric Summary Badges: Runtime, Total Power, Total Power Off, Total Days
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSummaryBadge(
                            icon: Icons.timer_outlined,
                            label: "Total Runtime",
                            value: _formatDuration(row.totalDurationSeconds),
                            color: const Color(0xFF00897B),
                            bgColor: const Color(0xFFE0F2F1),
                          ),
                          _buildSummaryBadge(
                            icon: Icons.bolt_outlined,
                            label: "Total Power On",
                            value: _formatDuration(row.totalPowerOnSeconds),
                            color: const Color(0xFF1D4ED8),
                            bgColor: const Color(0xFFEFF6FF),
                          ),
                          _buildSummaryBadge(
                            icon: Icons.power_off_outlined,
                            label: "Total Power Off",
                            value: row.totalPowerOffSeconds > 0
                                ? _formatDuration(row.totalPowerOffSeconds)
                                : "0h 0m",
                            color: const Color(0xFFDC2626),
                            bgColor: const Color(0xFFFEF2F2),
                          ),
                          _buildSummaryBadge(
                            icon: Icons.calendar_today_outlined,
                            label: "Total Days",
                            value: "${_dateColumns.length} Days",
                            color: const Color(0xFF475569),
                            bgColor: const Color(0xFFF1F5F9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Controls: Metric Selector Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMetricTab(
                                label: "Runtime (mins)",
                                icon: Icons.timer_outlined,
                                activeColor: const Color(0xFF0D9488),
                                isSelected: localMetric == 'Runtime',
                                onTap: () {
                                  setDialogState(() => localMetric = 'Runtime');
                                },
                              ),
                              _buildMetricTab(
                                label: "Total Power On (mins)",
                                icon: Icons.bolt_outlined,
                                activeColor: const Color(0xFF1D4ED8),
                                isSelected: localMetric == 'Total Power On',
                                onTap: () {
                                  setDialogState(
                                      () => localMetric = 'Total Power On');
                                },
                              ),
                              _buildMetricTab(
                                label: "Total Power Off (mins)",
                                icon: Icons.power_off_outlined,
                                activeColor: const Color(0xFFDC2626),
                                isSelected: localMetric == 'Total Power Off',
                                onTap: () {
                                  setDialogState(
                                      () => localMetric = 'Total Power Off');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Chart Area: Static Y-axis and horizontal scrolling
                      Expanded(
                        child: _buildPumpSfChart(
                          [row],
                          overrideMetric: localMetric,
                          overrideScrollController:
                              _pumpDialogGraphScrollController,
                        ),
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
  }

  Widget _buildSfChart(
    List<SequenceRowData> rows, {
    String? overrideMetric,
    String? overrideChartType,
    ScrollController? overrideScrollController,
  }) {
    List<_ZoneChartPoint> dataPoints = [];

    // Always Date Wise
    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      String label = "${d.day}/${DateFormat('MMM').format(d).toLowerCase()}";
      int sumSec = 0;
      num sumQty = 0;
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

    final String metric = overrideMetric ?? _selectedGraphMetric;
    final String chartType = overrideChartType ?? _graphChartType;
    final bool isDuration = metric == 'Duration';
    final ScrollController scrollController =
        overrideScrollController ?? _zoneGraphScrollController;

    return _buildResponsiveStaticAxisChart(
      dataPoints: dataPoints,
      isDuration: isDuration,
      chartType: chartType,
      scrollController: scrollController,
    );
  }

  Widget _buildResponsiveStaticAxisChart({
    required List<_ZoneChartPoint> dataPoints,
    required bool isDuration,
    required String chartType,
    required ScrollController scrollController,
  }) {
    double rawMax = 0;
    for (var p in dataPoints) {
      double val = isDuration ? p.durationMinutes : p.quantity;
      if (val > rawMax) rawMax = val;
    }
    if (rawMax <= 0) rawMax = 10;
    double targetMax = rawMax * 1.15;
    double magnitude =
        math.pow(10, (math.log(targetMax) / math.ln10).floor()).toDouble();
    if (magnitude <= 0) magnitude = 1;
    double fraction = targetMax / magnitude;
    double niceStep;
    if (fraction <= 1.2) {
      niceStep = 0.2 * magnitude;
    } else if (fraction <= 2.5) {
      niceStep = 0.5 * magnitude;
    } else if (fraction <= 5.0) {
      niceStep = 1.0 * magnitude;
    } else {
      niceStep = 2.0 * magnitude;
    }
    double maxY = (targetMax / niceStep).ceil() * niceStep;
    double intervalY = niceStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Static Top Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isDuration
                    ? const Color(0xFF0D9488)
                    : const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isDuration ? "Duration (mins)" : "Quantity",
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 2. Chart Body: Static Left Y-Axis + Scrollable Right Plot Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double yAxisWidth = 56.0;
              final double availablePlotWidth =
                  math.max(0, constraints.maxWidth - yAxisWidth);
              const double minWidthPerDate = 45.0;
              final double calculatedPlotWidth =
                  dataPoints.length * minWidthPerDate;
              final double plotWidth =
                  math.max(availablePlotWidth, calculatedPlotWidth);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // STATIC LEFT Y-AXIS (Title, Numbers, Ticks)
                  SizedBox(
                    width: yAxisWidth,
                    child: SfCartesianChart(
                      margin: const EdgeInsets.only(bottom: 22),
                      plotAreaBorderWidth: 0,
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: maxY,
                        interval: intervalY,
                        title: AxisTitle(
                          text: isDuration ? "Duration (mins)" : "Quantity",
                          textStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDuration
                                ? const Color(0xFF0F766E)
                                : const Color(0xFF166534),
                          ),
                        ),
                        axisLine: const AxisLine(color: Color(0xFFCBD5E1)),
                        majorTickLines: const MajorTickLines(
                            size: 4, color: Color(0xFFCBD5E1)),
                        majorGridLines: const MajorGridLines(width: 0),
                        labelStyle: const TextStyle(
                            fontSize: 10, color: Color(0xFF64748B)),
                      ),
                      primaryXAxis: CategoryAxis(
                        isVisible: true,
                        labelRotation: dataPoints.length > 7 ? -45 : 0,
                        labelStyle: const TextStyle(
                            fontSize: 10.5, color: Colors.transparent),
                        axisLine: const AxisLine(width: 0),
                        majorTickLines: const MajorTickLines(size: 0),
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      series: <CartesianSeries<_ZoneChartPoint, String>>[
                        ColumnSeries<_ZoneChartPoint, String>(
                          dataSource:
                              dataPoints.isNotEmpty ? [dataPoints.first] : [],
                          xValueMapper: (_ZoneChartPoint p, _) => p.xLabel,
                          yValueMapper: (_ZoneChartPoint p, _) => 0,
                          color: Colors.transparent,
                          width: 0,
                        ),
                      ],
                    ),
                  ),

                  // SCROLLABLE RIGHT PLOT AREA & X-AXIS
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
                        controller: scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        thickness: 6.0,
                        radius: const Radius.circular(3),
                        thumbColor: const Color(0xFF00695C),
                        trackColor: const Color(0xFFE2E8F0),
                        padding: const EdgeInsets.only(bottom: 2),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: SizedBox(
                            width: plotWidth,
                            child: SfCartesianChart(
                              margin: const EdgeInsets.only(bottom: 22),
                              plotAreaBorderWidth: 0,
                              tooltipBehavior: TooltipBehavior(
                                enable: true,
                                shared: false,
                                builder: (dynamic data,
                                    dynamic point,
                                    dynamic series,
                                    int pointIndex,
                                    int seriesIndex) {
                                  if (pointIndex < 0 ||
                                      pointIndex >= dataPoints.length) {
                                    return const SizedBox();
                                  }
                                  final p = dataPoints[pointIndex];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                  : const Color(0xFF4ADE80),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isDuration
                                                  ? "Duration: ${p.durationFormatted}"
                                                  : "Quantity: ${p.quantity > 0 ? (p.quantity % 1 == 0 ? '${p.quantity.toInt()} L' : '${p.quantity} L') : '-'}",
                                              style: TextStyle(
                                                color: isDuration
                                                    ? const Color(0xFF2DD4BF)
                                                    : const Color(0xFF4ADE80),
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
                                axisLine:
                                    const AxisLine(color: Color(0xFFCBD5E1)),
                              ),
                              primaryYAxis: NumericAxis(
                                minimum: 0,
                                maximum: maxY,
                                interval: intervalY,
                                isVisible: true,
                                labelsExtent: 0,
                                labelStyle: const TextStyle(
                                    fontSize: 0, color: Colors.transparent),
                                title: const AxisTitle(text: ''),
                                axisLine: const AxisLine(
                                    color: Color(0xFFCBD5E1), width: 1),
                                majorTickLines: const MajorTickLines(size: 0),
                                majorGridLines: const MajorGridLines(
                                  color: Color(0xFFF1F5F9),
                                  width: 1,
                                ),
                              ),
                              series: _buildChartSeries(
                                  dataPoints, isDuration, chartType),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<CartesianSeries<_ZoneChartPoint, String>> _buildChartSeries(
      List<_ZoneChartPoint> data, bool isDuration,
      [String? overrideChartType]) {
    if (isDuration) {
      // Duration: Column series in Green / Teal
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
      // Quantity: Column series in Green
      return [
        ColumnSeries<_ZoneChartPoint, String>(
          name: 'Quantity',
          dataSource: data,
          xValueMapper: (_ZoneChartPoint p, _) => p.xLabel,
          yValueMapper: (_ZoneChartPoint p, _) => p.quantity,
          color: const Color(0xFF16A34A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          width: 0.4,
        ),
      ];
    }
  }

  Widget _buildSequenceBreakdownCard(
      SequenceRowData row, int grandTotalSeconds, num grandTotalQuantity) {
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
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
        ),
        child: Icon(
          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          size: 16,
          color: const Color(0xFF0F766E),
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
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop_outlined,
              size: 11, color: Color(0xFF166534)),
          const SizedBox(width: 3),
          Text(
            row.totalQuantity > 0
                ? (row.totalQuantity % 1 == 0
                    ? "${row.totalQuantity.toInt()} L"
                    : "${row.totalQuantity} L")
                : "-",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF166534),
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
                                  color: Color(0xFF166534),
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
                          num qty = dayData?.quantityCompleted ?? 0;

                          String durStr = (hasRun && durSec > 0)
                              ? _formatDuration(durSec)
                              : (hasRun && dayData.durationQtyStr != '00:00:00'
                                  ? dayData.durationQtyStr
                                  : '-');
                          String qtyStr = (hasRun && qty > 0)
                              ? (qty % 1 == 0 ? "${qty.toInt()} L" : "$qty L")
                              : '-';

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
                                          ? const Color(0xFF166534)
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
                                    ? "${row.totalQuantity} L"
                                    : "-",
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
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

  // ===========================================================================
  // PUMP LOG IMPLEMENTATION (Api, Filtering, Tables & Graph)
  // ===========================================================================

  List<CumulativeRowData> _getFilteredPumpRows() {
    if (_selectedPumpFilter == 'All Pumps') {
      return _pumpRows;
    }
    return _pumpRows
        .where((r) => r.channelCategory == _selectedPumpFilter)
        .toList();
  }

  List<String> _getPumpNames(MasterControllerModel? masterData,
      int nodeControllerId, int controllerId) {
    if (masterData != null) {
      final targetControllerId =
          nodeControllerId != 0 ? nodeControllerId : controllerId;

      var targetPumps = masterData.configObjects
          .where((e) =>
              e.objectId == 5 &&
              (e.controllerId == targetControllerId ||
                  ((nodeControllerId == 0 || nodeControllerId == controllerId) &&
                      (e.controllerId == 0 ||
                          e.controllerId == null ||
                          e.controllerId == controllerId))))
          .toList();

      if (targetPumps.isEmpty &&
          (nodeControllerId == 0 || nodeControllerId == controllerId)) {
        targetPumps = masterData.configObjects
            .where((e) => e.objectId == 5)
            .toList();
      }

      if (targetPumps.isNotEmpty) {
        targetPumps.sort((a, b) => a.sNo.compareTo(b.sNo));
        final List<String> names = [];
        for (var pump in targetPumps) {
          final name = pump.name.isNotEmpty
              ? pump.name
              : (targetPumps.length == 1 ? "Pump" : "Pump ${names.length + 1}");
          names.add(name);
        }
        return names;
      }

      if (nodeControllerId != 0) {
        final matchingNode = masterData.nodeList
            .where((n) => n.controllerId == nodeControllerId)
            .firstOrNull;
        if (matchingNode != null && matchingNode.deviceName.isNotEmpty) {
          return [matchingNode.deviceName];
        }
      }
    }
    return ["Pump"];
  }

  Future<void> fetchPumpLogApi() async {
    if (mounted) {
      setState(() {
        _isPumpLoading = true;
      });
    }

    try {
      final int userId =
          widget.userData['customerId'] ?? widget.userData['userId'] ?? 1002;
      final int controllerId = widget.masterData?.controllerId ??
          widget.userData['controllerId'] ??
          3382;

      final userData = {
        'userId': userId,
        'controllerId': controllerId,
      };

      List fetchedDevices = [];
      try {
        final result =
            await LogRepository(HttpService()).getUserNodePumpList(userData);
        if (result.statusCode == 200) {
          final resData = jsonDecode(result.body);
          if (resData['data'] is List && (resData['data'] as List).isNotEmpty) {
            fetchedDevices = resData['data'];
          }
        }
      } catch (e) {
        debugPrint("Error fetching pump device list: $e");
      }

      if (fetchedDevices.isEmpty && widget.masterData != null) {
        if (AppConstants.ecoGemAndPlusModelList
            .contains(widget.masterData!.modelId)) {
          fetchedDevices = [
            {
              'deviceName': widget.masterData!.deviceName,
              'deviceId': widget.masterData!.deviceId,
              'controllerId': 0,
            }
          ];
        } else if (widget.masterData!.nodeList.isNotEmpty) {
          final pumpNodes = widget.masterData!.nodeList.where((n) {
            return AppConstants.pumpList.contains(n.modelId) ||
                n.categoryId == 1 ||
                n.categoryName.toLowerCase().contains('pump');
          }).toList();
          final nodesToUse =
              pumpNodes.isNotEmpty ? pumpNodes : widget.masterData!.nodeList;
          fetchedDevices = nodesToUse
              .map((n) => {
                    'deviceName': n.deviceName.isNotEmpty
                        ? n.deviceName
                        : 'Node ${n.serialNumber}',
                    'deviceId': n.deviceId,
                    'controllerId': n.controllerId,
                  })
              .toList();
        } else {
          fetchedDevices = [
            {
              'deviceName': widget.masterData!.deviceName,
              'deviceId': widget.masterData!.deviceId,
              'controllerId': 0,
            }
          ];
        }
      }

      if (fetchedDevices.isEmpty) {
        fetchedDevices = [
          {
            'deviceName': 'Pump (L3R)',
            'deviceId': '',
            'controllerId': 0,
          }
        ];
      }

      // Ensure _dateColumns is populated
      if (_dateColumns.isEmpty) {
        List<DateTime> dates = [];
        DateTime cur = _fromDate;
        while (!cur.isAfter(_toDate)) {
          dates.add(cur);
          cur = cur.add(const Duration(days: 1));
        }
        _dateColumns = dates;
      }

      String fromDateStr = DateFormat('yyyy-MM-dd').format(_fromDate);
      String toDateStr = DateFormat('yyyy-MM-dd').format(_toDate);

      List<CumulativeRowData> pumpRows = [];
      Set<String> pumpFilterOptions = {'All Pumps'};

      for (var dev in fetchedDevices) {
        int nodeCtrlId = dev['controllerId'] ?? 0;
        if (nodeCtrlId == controllerId) {
          nodeCtrlId = 0;
        }

        String rawDevName = dev['deviceName']?.toString().trim() ?? 'Pump';
        String devId = dev['deviceId']?.toString().trim() ?? '';
        String shortMac =
            devId.length >= 4 ? devId.substring(devId.length - 4) : devId;
        String devDisplayName = fetchedDevices.length > 1 && shortMac.isNotEmpty
            ? "$rawDevName ($shortMac)"
            : rawDevName;

        pumpFilterOptions.add(devDisplayName);

        Map<String, dynamic> reqBody = {
          "userId": userId,
          "controllerId": controllerId,
          "nodeControllerId": nodeCtrlId,
          "fromDate": fromDateStr,
          "toDate": toDateStr,
          "needSum": false,
        };

        debugPrint('PUMP HOURLY API REQUEST: ${jsonEncode(reqBody)}');

        List<MotorDataHourly> hourlyList = [];
        try {
          final res = await LogRepository(HttpService())
              .getUserPumpHourlyLog(reqBody, nodeCtrlId != 0);
          if (res.statusCode == 200) {
            final resJson = jsonDecode(res.body);
            final rawData = resJson['data'];
            List rawList = [];
            if (rawData is List) {
              rawList = rawData;
            } else if (rawData is Map) {
              if (rawData['log'] is List) {
                rawList = rawData['log'];
              } else if (rawData['data'] is List) {
                rawList = rawData['data'];
              } else {
                rawList = [rawData];
              }
            }
            hourlyList = rawList
                .map((item) => MotorDataHourly.fromJson(
                    Map<String, dynamic>.from(item as Map)))
                .toList();
          }
        } catch (e) {
          debugPrint("Error fetching pump hourly log for $devDisplayName: $e");
        }

        final pumpNames = _getPumpNames(
          widget.masterData,
          nodeCtrlId,
          controllerId,
        );

        final int targetCtrlId = nodeCtrlId != 0 ? nodeCtrlId : controllerId;
        final bool hasConfiguredPumps = widget.masterData != null &&
            widget.masterData!.configObjects.any((e) =>
                e.objectId == 5 &&
                (e.controllerId == targetCtrlId ||
                    ((nodeCtrlId == 0 || nodeCtrlId == controllerId) &&
                        (e.controllerId == 0 ||
                            e.controllerId == null ||
                            e.controllerId == controllerId))));

        bool hasMotor3Run = hourlyList.any(
            (h) => _parseDurationToSeconds(h.motorRunTime3) > 0);
        bool hasMotor2Run = hourlyList.any(
            (h) => _parseDurationToSeconds(h.motorRunTime2) > 0);

        int numPumps = pumpNames.isNotEmpty ? pumpNames.length : 1;
        if (!hasConfiguredPumps) {
          for (var h in hourlyList) {
            if (h.numberOfPumps > numPumps) numPumps = h.numberOfPumps;
          }
        }
        if (hasMotor3Run && numPumps < 3) numPumps = 3;
        if (hasMotor2Run && numPumps < 2) numPumps = 2;
        numPumps = numPumps.clamp(1, 3);

        // Build entries map by date
        Map<String, MotorDataHourly> dateMap = {};
        for (var h in hourlyList) {
          if (h.date.isNotEmpty) {
            String rawDate = h.date.split(' ')[0].split('T')[0].trim();
            String? normalizedDate;
            try {
              if (rawDate.contains('-')) {
                var parts = rawDate.split('-');
                if (parts[0].length == 4) {
                  normalizedDate =
                      "${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}";
                } else if (parts[2].length == 4) {
                  normalizedDate =
                      "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
                }
              } else if (rawDate.contains('/')) {
                var parts = rawDate.split('/');
                if (parts[0].length == 4) {
                  normalizedDate =
                      "${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}";
                } else if (parts[2].length == 4) {
                  normalizedDate =
                      "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
                }
              }
            } catch (_) {}
            normalizedDate ??= rawDate;
            dateMap[normalizedDate] = h;
          }
        }

        if (hourlyList.isNotEmpty &&
            !dateMap.containsKey(fromDateStr) &&
            fromDateStr == toDateStr) {
          dateMap[fromDateStr] = hourlyList.first;
        }

        // 1. Pump row
        String p1Name = pumpNames.isNotEmpty && pumpNames[0] != "Pump"
            ? pumpNames[0]
            : (numPumps > 1
                ? "Pump 1"
                : (pumpNames.isNotEmpty ? pumpNames[0] : "Pump"));
        Map<String, CumulativeDayData> p1DayEntries = {};
        int p1TotalSec = 0;
        int p1TotalPowerOnSec = 0;
        int p1TotalPowerOffSec = 0;

        for (var d in _dateColumns) {
          String dKey = DateFormat('yyyy-MM-dd').format(d);
          int sec = 0;
          int powerOnSec = 0;
          int powerOffSec = 0;
          bool hasRecord = dateMap.containsKey(dKey);

          if (hasRecord) {
            final h = dateMap[dKey]!;
            sec = _parseDurationToSeconds(h.motorRunTime1);
            powerOnSec = _parseDurationToSeconds(h.totalPowerOnTime);
            powerOffSec = _parseDurationToSeconds(h.powerOffTime);
          }

          p1DayEntries[dKey] = CumulativeDayData(
            durationSeconds: sec,
            powerOnSeconds: powerOnSec,
            powerOffSeconds: powerOffSec,
            hasRun: hasRecord,
          );
          p1TotalSec += sec;
          p1TotalPowerOnSec += powerOnSec;
          p1TotalPowerOffSec += powerOffSec;
        }

        pumpRows.add(CumulativeRowData(
          key: "${devDisplayName}_pump1",
          channelCategory: devDisplayName,
          channelName: p1Name,
          channelSNo: 1,
          dayEntries: p1DayEntries,
          totalDurationSeconds: p1TotalSec,
          totalPowerOnSeconds: p1TotalPowerOnSec,
          totalPowerOffSeconds: p1TotalPowerOffSec,
        ));

        // 2. Pump 2 row
        if (numPumps >= 2) {
          String p2Name = pumpNames.length > 1 ? pumpNames[1] : "Pump 2";
          Map<String, CumulativeDayData> p2DayEntries = {};
          int p2TotalSec = 0;
          int p2TotalPowerOnSec = 0;
          int p2TotalPowerOffSec = 0;

          for (var d in _dateColumns) {
            String dKey = DateFormat('yyyy-MM-dd').format(d);
            int sec = 0;
            int powerOnSec = 0;
            int powerOffSec = 0;
            bool hasRecord = dateMap.containsKey(dKey);

            if (hasRecord) {
              final h = dateMap[dKey]!;
              sec = _parseDurationToSeconds(h.motorRunTime2);
              powerOnSec = _parseDurationToSeconds(h.totalPowerOnTime);
              powerOffSec = _parseDurationToSeconds(h.powerOffTime);
            }

            p2DayEntries[dKey] = CumulativeDayData(
              durationSeconds: sec,
              powerOnSeconds: powerOnSec,
              powerOffSeconds: powerOffSec,
              hasRun: hasRecord,
            );
            p2TotalSec += sec;
            p2TotalPowerOnSec += powerOnSec;
            p2TotalPowerOffSec += powerOffSec;
          }

          pumpRows.add(CumulativeRowData(
            key: "${devDisplayName}_pump2",
            channelCategory: devDisplayName,
            channelName: p2Name,
            channelSNo: 2,
            dayEntries: p2DayEntries,
            totalDurationSeconds: p2TotalSec,
            totalPowerOnSeconds: p2TotalPowerOnSec,
            totalPowerOffSeconds: p2TotalPowerOffSec,
          ));
        }

        // 3. Pump 3 row (if available)
        if (numPumps >= 3) {
          String p3Name = pumpNames.length > 2 ? pumpNames[2] : "Pump 3";
          Map<String, CumulativeDayData> p3DayEntries = {};
          int p3TotalSec = 0;
          int p3TotalPowerOnSec = 0;
          int p3TotalPowerOffSec = 0;

          for (var d in _dateColumns) {
            String dKey = DateFormat('yyyy-MM-dd').format(d);
            int sec = 0;
            int powerOnSec = 0;
            int powerOffSec = 0;
            bool hasRecord = dateMap.containsKey(dKey);

            if (hasRecord) {
              final h = dateMap[dKey]!;
              sec = _parseDurationToSeconds(h.motorRunTime3);
              powerOnSec = _parseDurationToSeconds(h.totalPowerOnTime);
              powerOffSec = _parseDurationToSeconds(h.powerOffTime);
            }

            p3DayEntries[dKey] = CumulativeDayData(
              durationSeconds: sec,
              powerOnSeconds: powerOnSec,
              powerOffSeconds: powerOffSec,
              hasRun: hasRecord,
            );
            p3TotalSec += sec;
            p3TotalPowerOnSec += powerOnSec;
            p3TotalPowerOffSec += powerOffSec;
          }

          pumpRows.add(CumulativeRowData(
            key: "${devDisplayName}_pump3",
            channelCategory: devDisplayName,
            channelName: p3Name,
            channelSNo: 3,
            dayEntries: p3DayEntries,
            totalDurationSeconds: p3TotalSec,
            totalPowerOnSeconds: p3TotalPowerOnSec,
            totalPowerOffSeconds: p3TotalPowerOffSec,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _pumpRows = pumpRows;
          _pumpDropdownOptions = pumpFilterOptions.toList();
          if (!_pumpDropdownOptions.contains(_selectedPumpFilter)) {
            _selectedPumpFilter = 'All Pumps';
          }
        });
      }
    } catch (e, stack) {
      debugPrint("Error in fetchPumpLogApi: $e\n$stack");
    } finally {
      if (mounted) {
        setState(() {
          _isPumpLoading = false;
        });
      }
    }
  }

  Widget _buildPumpLogGraphView(BuildContext context) {
    if (_isPumpLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    var filteredRows = _getFilteredPumpRows();

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
    int grandTotalRunSec = 0;
    int grandTotalPowerOnSec = 0;
    int grandTotalPowerOffSec = 0;

    for (var r in filteredRows) {
      grandTotalRunSec += r.totalDurationSeconds;
      grandTotalPowerOnSec += r.totalPowerOnSeconds;
      grandTotalPowerOffSec += r.totalPowerOffSeconds;
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
              _buildPumpGraphSummaryCards(
                grandTotalRunSeconds: grandTotalRunSec,
                grandTotalPowerOnSeconds: grandTotalPowerOnSec,
                grandTotalPowerOffSeconds: grandTotalPowerOffSec,
                totalPumps: filteredRows.length,
                totalDays: _dateColumns.length,
              ),
              const SizedBox(height: 12),

              // 2. Chart Card
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
                    // Controls: Metric Selector Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMetricTab(
                              label: "Runtime (mins)",
                              icon: Icons.timer_outlined,
                              activeColor: const Color(0xFF0D9488),
                              isSelected: _selectedPumpGraphMetric == 'Runtime',
                              onTap: () => setState(
                                  () => _selectedPumpGraphMetric = 'Runtime'),
                            ),
                            _buildMetricTab(
                              label: "Total Power On(mins)",
                              icon: Icons.bolt_outlined,
                              activeColor: const Color(0xFF1D4ED8),
                              isSelected:
                                  _selectedPumpGraphMetric == 'Total Power On',
                              onTap: () => setState(() =>
                                  _selectedPumpGraphMetric = 'Total Power On'),
                            ),
                            _buildMetricTab(
                              label: "Total Power Off (mins)",
                              icon: Icons.power_off_outlined,
                              activeColor: const Color(0xFFDC2626),
                              isSelected:
                                  _selectedPumpGraphMetric == 'Total Power Off',
                              onTap: () => setState(() =>
                                  _selectedPumpGraphMetric = 'Total Power Off'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // SfCartesianChart with static Y-axis and horizontal scrolling
                    SizedBox(
                      height: 320,
                      child: _buildPumpSfChart(
                        filteredRows,
                        overrideMetric: _selectedPumpGraphMetric,
                        overrideScrollController: _pumpGraphScrollController,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Pump Breakdown Cards
              Text(
                "Pump Breakdown (${filteredRows.length})",
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),

              for (var row in filteredRows) _buildPumpBreakdownCard(row),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPumpGraphSummaryCards({
    required int grandTotalRunSeconds,
    required int grandTotalPowerOnSeconds,
    required int grandTotalPowerOffSeconds,
    required int totalPumps,
    required int totalDays,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = (constraints.maxWidth - (3 * 8)) / 4;
        if (constraints.maxWidth < 650) {
          cardWidth = (constraints.maxWidth - 8) / 2;
        }

        Widget card(
            String title, String val, IconData icon, Color color, Color bg) {
          return Container(
            width: cardWidth,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        val,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            card(
              "Total Runtime",
              _formatDuration(grandTotalRunSeconds),
              Icons.timer_outlined,
              const Color(0xFF0F766E),
              const Color(0xFFE0F2F1),
            ),
            card(
              "Total Power On",
              _formatDuration(grandTotalPowerOnSeconds),
              Icons.bolt_outlined,
              const Color(0xFF1D4ED8),
              const Color(0xFFEFF6FF),
            ),
            card(
              "Total Power Off",
              grandTotalPowerOffSeconds > 0
                  ? _formatDuration(grandTotalPowerOffSeconds)
                  : "0h 0m",
              Icons.power_off_outlined,
              const Color(0xFFDC2626),
              const Color(0xFFFEF2F2),
            ),
            card(
              "Total Days",
              "$totalDays Days",
              Icons.calendar_today_outlined,
              const Color(0xFF475569),
              const Color(0xFFF1F5F9),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPumpBreakdownCard(CumulativeRowData row) {
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
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
        ),
        child: Icon(
          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          size: 16,
          color: const Color(0xFF0F766E),
        ),
      ),
    );

    Widget runBadge = Container(
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

    Widget powerOnBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_outlined, size: 11, color: Color(0xFF1D4ED8)),
          const SizedBox(width: 3),
          Text(
            _formatDuration(row.totalPowerOnSeconds),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );

    Widget powerOffBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.power_off_outlined,
              size: 11, color: Color(0xFFDC2626)),
          const SizedBox(width: 3),
          Text(
            row.totalPowerOffSeconds > 0
                ? _formatDuration(row.totalPowerOffSeconds)
                : "0h 0m",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
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
          final isNarrow = constraints.maxWidth < 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNarrow) ...[
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
                        row.channelName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    if (row.channelCategory.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "(${row.channelCategory})",
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
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    runBadge,
                    powerOnBadge,
                    powerOffBadge,
                  ],
                ),
              ] else ...[
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
                              row.channelName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          if (row.channelCategory.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "(${row.channelCategory})",
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
                        runBadge,
                        const SizedBox(width: 6),
                        powerOnBadge,
                        const SizedBox(width: 6),
                        powerOffBadge,
                        const SizedBox(width: 6),
                        toggleBtn,
                      ],
                    ),
                  ],
                ),
              ],
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
                                "Runtime",
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
                                "Total Power On",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Total Power Off",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
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
                          CumulativeDayData? dayData = row.dayEntries[dKey];

                          bool hasRun = dayData != null && dayData.hasRun;
                          int runSec = dayData?.durationSeconds ?? 0;
                          int powerOnSec = dayData?.powerOnSeconds ?? 0;
                          int powerOffSec = dayData?.powerOffSeconds ?? 0;
                          bool hasActivity =
                              runSec > 0 || powerOnSec > 0 || powerOffSec > 0;

                          String runStr = runSec > 0
                              ? SequenceDayData._formatSecondsToHMS(runSec)
                              : (hasActivity || hasRun ? "00:00:00" : "-");
                          String powerOnStr = powerOnSec > 0
                              ? SequenceDayData._formatSecondsToHMS(powerOnSec)
                              : (hasActivity || hasRun ? "00:00:00" : "-");
                          String powerOffStr = powerOffSec > 0
                              ? SequenceDayData._formatSecondsToHMS(
                                  powerOffOffSec(powerOffSec))
                              : (hasActivity || hasRun ? "00:00:00" : "-");

                          Color rowBg = dIdx % 2 == 0
                              ? Colors.white
                              : const Color(0xFFF8FAFC);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: rowBg,
                              border: Border(
                                bottom: BorderSide(
                                  color: dIdx == _dateColumns.length - 1
                                      ? Colors.transparent
                                      : const Color(0xFFE2E8F0),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    DateFormat('dd/MM/yyyy (EEE)').format(d),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    runStr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: runSec > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: runSec > 0
                                          ? const Color(0xFF0F766E)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    powerOnStr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: powerOnSec > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: powerOnSec > 0
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    powerOffStr,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: powerOffSec > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: powerOffSec > 0
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
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

  static int powerOffOffSec(int s) => s;

  Widget _buildPumpSfChart(
    List<CumulativeRowData> rows, {
    String? overrideMetric,
    ScrollController? overrideScrollController,
  }) {
    List<_PumpChartPoint> dataPoints = [];

    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      String label = "${d.day}/${DateFormat('MMM').format(d).toLowerCase()}";
      int sumRunSec = 0;
      int sumPowerOnSec = 0;
      int sumPowerOffSec = 0;

      if (rows.length == 1) {
        final r = rows.first;
        if (r.dayEntries.containsKey(dKey)) {
          final entry = r.dayEntries[dKey]!;
          sumRunSec = entry.durationSeconds;
          sumPowerOnSec = entry.powerOnSeconds;
          sumPowerOffSec = entry.powerOffSeconds;
        }
      } else {
        for (var r in rows) {
          if (r.dayEntries.containsKey(dKey)) {
            final entry = r.dayEntries[dKey]!;
            sumRunSec += entry.durationSeconds;
            sumPowerOnSec += entry.powerOnSeconds;
            sumPowerOffSec += entry.powerOffSeconds;
          }
        }
      }

      double runMinutes = sumRunSec / 60.0;
      double powerOnMinutes = sumPowerOnSec / 60.0;
      double powerOffMinutes = sumPowerOffSec / 60.0;

      dataPoints.add(_PumpChartPoint(
        xLabel: label,
        runTimeMinutes: runMinutes,
        runTimeFormatted: SequenceDayData._formatSecondsToHMS(sumRunSec),
        powerOnMinutes: powerOnMinutes,
        powerOnFormatted: SequenceDayData._formatSecondsToHMS(sumPowerOnSec),
        powerOffMinutes: powerOffMinutes,
        powerOffFormatted: SequenceDayData._formatSecondsToHMS(sumPowerOffSec),
      ));
    }

    final String metric = overrideMetric ?? _selectedPumpGraphMetric;
    final ScrollController scrollController =
        overrideScrollController ?? _pumpGraphScrollController;

    double rawMax = 0;
    for (var p in dataPoints) {
      if (metric == 'Runtime') {
        if (p.runTimeMinutes > rawMax) rawMax = p.runTimeMinutes;
      } else if (metric == 'Total Power On') {
        if (p.powerOnMinutes > rawMax) rawMax = p.powerOnMinutes;
      } else if (metric == 'Total Power Off') {
        if (p.powerOffMinutes > rawMax) rawMax = p.powerOffMinutes;
      } else {
        double m = math.max(
            p.runTimeMinutes, math.max(p.powerOnMinutes, p.powerOffMinutes));
        if (m > rawMax) rawMax = m;
      }
    }
    if (rawMax <= 0) rawMax = 10;
    double targetMax = rawMax * 1.15;
    double magnitude =
        math.pow(10, (math.log(targetMax) / math.ln10).floor()).toDouble();
    if (magnitude <= 0) magnitude = 1;
    double fraction = targetMax / magnitude;
    double niceStep;
    if (fraction <= 1.2) {
      niceStep = 0.2 * magnitude;
    } else if (fraction <= 2.5) {
      niceStep = 0.5 * magnitude;
    } else if (fraction <= 5.0) {
      niceStep = 1.0 * magnitude;
    } else {
      niceStep = 2.0 * magnitude;
    }
    double maxY = (targetMax / niceStep).ceil() * niceStep;
    double intervalY = niceStep;

    String yAxisTitle = "Time (mins)";
    Color yAxisColor = const Color(0xFF00695C);
    if (metric == 'Runtime') {
      yAxisTitle = "Runtime (mins)";
      yAxisColor = const Color(0xFF0D9488);
    } else if (metric == 'Total Power On') {
      yAxisTitle = "Total Power On (mins)";
      yAxisColor = const Color(0xFF1D4ED8);
    } else if (metric == 'Total Power Off') {
      yAxisTitle = "Total Power Off (mins)";
      yAxisColor = const Color(0xFFDC2626);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (metric == 'All' || metric == 'Runtime') ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Runtime (mins)",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
            if (metric == 'All') const SizedBox(width: 16),
            if (metric == 'All' || metric == 'Total Power On') ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Total Power On (mins)",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
            if (metric == 'All') const SizedBox(width: 16),
            if (metric == 'All' || metric == 'Total Power Off') ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Total Power Off (mins)",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),

        // Static Left Y-Axis + Scrollable Right Plot Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double yAxisWidth = 56.0;
              final double availablePlotWidth =
                  math.max(0, constraints.maxWidth - yAxisWidth);
              const double minWidthPerDate = 45.0;
              final double calculatedPlotWidth =
                  dataPoints.length * minWidthPerDate;
              final double plotWidth =
                  math.max(availablePlotWidth, calculatedPlotWidth);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // STATIC LEFT Y-AXIS
                  SizedBox(
                    width: yAxisWidth,
                    child: SfCartesianChart(
                      margin: const EdgeInsets.only(bottom: 22),
                      plotAreaBorderWidth: 0,
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: maxY,
                        interval: intervalY,
                        title: AxisTitle(
                          text: yAxisTitle,
                          textStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: yAxisColor,
                          ),
                        ),
                        axisLine: const AxisLine(color: Color(0xFFCBD5E1)),
                        majorTickLines: const MajorTickLines(
                            size: 4, color: Color(0xFFCBD5E1)),
                        majorGridLines: const MajorGridLines(width: 0),
                        labelStyle: const TextStyle(
                            fontSize: 10, color: Color(0xFF64748B)),
                      ),
                      primaryXAxis: CategoryAxis(
                        isVisible: true,
                        labelRotation: dataPoints.length > 7 ? -45 : 0,
                        labelStyle: const TextStyle(
                            fontSize: 10.5, color: Colors.transparent),
                        axisLine: const AxisLine(width: 0),
                        majorTickLines: const MajorTickLines(size: 0),
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      series: <CartesianSeries<_PumpChartPoint, String>>[
                        ColumnSeries<_PumpChartPoint, String>(
                          dataSource:
                              dataPoints.isNotEmpty ? [dataPoints.first] : [],
                          xValueMapper: (_PumpChartPoint p, _) => p.xLabel,
                          yValueMapper: (_PumpChartPoint p, _) => 0,
                          color: Colors.transparent,
                          width: 0,
                        ),
                      ],
                    ),
                  ),

                  // SCROLLABLE RIGHT PLOT AREA & X-AXIS
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
                        controller: scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        thickness: 6.0,
                        radius: const Radius.circular(3),
                        thumbColor: const Color(0xFF00695C),
                        trackColor: const Color(0xFFE2E8F0),
                        padding: const EdgeInsets.only(bottom: 2),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: SizedBox(
                            width: plotWidth,
                            child: SfCartesianChart(
                              margin: const EdgeInsets.only(bottom: 22),
                              plotAreaBorderWidth: 0,
                              tooltipBehavior: TooltipBehavior(
                                enable: true,
                                shared: true,
                                builder: (dynamic data,
                                    dynamic point,
                                    dynamic series,
                                    int pointIndex,
                                    int seriesIndex) {
                                  if (pointIndex < 0 ||
                                      pointIndex >= dataPoints.length) {
                                    return const SizedBox();
                                  }
                                  final p = dataPoints[pointIndex];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.xLabel,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        if (metric == 'All' ||
                                            metric == 'Runtime')
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.timer_outlined,
                                                  size: 12,
                                                  color: Color(0xFF2DD4BF)),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Runtime: ${p.runTimeFormatted}",
                                                style: const TextStyle(
                                                  color: Color(0xFF2DD4BF),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (metric == 'All' ||
                                            metric == 'Total Power On') ...[
                                          if (metric == 'All')
                                            const SizedBox(height: 3),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.bolt_outlined,
                                                  size: 12,
                                                  color: Color(0xFF60A5FA)),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Total Power On: ${p.powerOnFormatted}",
                                                style: const TextStyle(
                                                  color: Color(0xFF60A5FA),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (metric == 'All' ||
                                            metric == 'Total Power Off') ...[
                                          if (metric == 'All')
                                            const SizedBox(height: 3),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.power_off_outlined,
                                                  size: 12,
                                                  color: Color(0xFFF87171)),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Total Power Off: ${p.powerOffFormatted}",
                                                style: const TextStyle(
                                                  color: Color(0xFFF87171),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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
                                axisLine:
                                    const AxisLine(color: Color(0xFFCBD5E1)),
                              ),
                              primaryYAxis: NumericAxis(
                                minimum: 0,
                                maximum: maxY,
                                interval: intervalY,
                                isVisible: true,
                                labelsExtent: 0,
                                labelStyle: const TextStyle(
                                    fontSize: 0, color: Colors.transparent),
                                title: const AxisTitle(text: ''),
                                axisLine: const AxisLine(
                                    color: Color(0xFFCBD5E1), width: 1),
                                majorTickLines: const MajorTickLines(size: 0),
                                majorGridLines: const MajorGridLines(
                                  color: Color(0xFFF1F5F9),
                                  width: 1,
                                ),
                              ),
                              series: _buildPumpChartSeries(dataPoints, metric),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<CartesianSeries<_PumpChartPoint, String>> _buildPumpChartSeries(
    List<_PumpChartPoint> dataPoints,
    String metric,
  ) {
    List<CartesianSeries<_PumpChartPoint, String>> seriesList = [];

    if (metric == 'All' || metric == 'Runtime') {
      seriesList.add(
        ColumnSeries<_PumpChartPoint, String>(
          name: 'Runtime (mins)',
          dataSource: dataPoints,
          xValueMapper: (_PumpChartPoint p, _) => p.xLabel,
          yValueMapper: (_PumpChartPoint p, _) => p.runTimeMinutes,
          color: const Color(0xFF0D9488),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          spacing: 0.1,
        ),
      );
    }

    if (metric == 'All' || metric == 'Total Power On') {
      seriesList.add(
        ColumnSeries<_PumpChartPoint, String>(
          name: 'Total Power On (mins)',
          dataSource: dataPoints,
          xValueMapper: (_PumpChartPoint p, _) => p.xLabel,
          yValueMapper: (_PumpChartPoint p, _) => p.powerOnMinutes,
          color: const Color(0xFF1D4ED8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          spacing: 0.1,
        ),
      );
    }

    if (metric == 'All' || metric == 'Total Power Off') {
      seriesList.add(
        ColumnSeries<_PumpChartPoint, String>(
          name: 'Total Power Off (mins)',
          dataSource: dataPoints,
          xValueMapper: (_PumpChartPoint p, _) => p.xLabel,
          yValueMapper: (_PumpChartPoint p, _) => p.powerOffMinutes,
          color: const Color(0xFFDC2626),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          spacing: 0.1,
        ),
      );
    }

    return seriesList;
  }

  Widget _buildPinnedLeftPumpRow(
    CumulativeRowData row,
    int rowIndex,
    double colWidth,
  ) {
    Color rowBg = rowIndex % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);

    const Color pillBg = Color(0xFFE8F5E9);
    const Color pillBorder = Color(0xFFC8E6C9);
    const Color pillText = Color(0xFF2E7D32);

    return Container(
      width: colWidth,
      height: 72,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          right: BorderSide(color: Color(0xFFCBD5E1), width: 1),
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  row.channelCategory,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:
                        MediaQuery.of(context).size.width < 650 ? 11.0 : 12.0,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: pillBorder, width: 1),
                  ),
                  child: Text(
                    row.channelName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize:
                          MediaQuery.of(context).size.width < 650 ? 10.5 : 11.5,
                      fontWeight: FontWeight.bold,
                      color: pillText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showIndividualPumpGraphDialog(context, row),
              borderRadius: BorderRadius.circular(4),
              child: Tooltip(
                message:
                    "Open ${row.channelCategory} - ${row.channelName} Graph",
                child: Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF80CBC4),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    size: 16,
                    color: Color(0xFF00695C),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePumpBlock(
    CumulativeRowData row,
    DateTime date,
    double colDateWidth,
  ) {
    String dKey = DateFormat('yyyy-MM-dd').format(date);
    CumulativeDayData? dayData = row.dayEntries[dKey];

    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = screenWidth < 650 ? 12.0 : 13.0;

    final bool hasRecord = dayData != null && dayData.hasRun;
    final int runSec = dayData?.durationSeconds ?? 0;
    final int powerOnSec = dayData?.powerOnSeconds ?? 0;
    final int powerOffSec = dayData?.powerOffSeconds ?? 0;
    final bool hasActivity = runSec > 0 || powerOnSec > 0 || powerOffSec > 0;

    final String runStr = runSec > 0
        ? "${SequenceDayData._formatSecondsToHMS(runSec)} /"
        : (hasActivity ? "00:00:00 /" : (hasRecord ? "00:00:00 /" : "- /"));
    final String powerOnStr = powerOnSec > 0
        ? "${SequenceDayData._formatSecondsToHMS(powerOnSec)} /"
        : (hasActivity ? "00:00:00 /" : (hasRecord ? "00:00:00 /" : "- /"));
    final String powerOffStr = powerOffSec > 0
        ? SequenceDayData._formatSecondsToHMS(powerOffSec)
        : (hasActivity ? "00:00:00" : (hasRecord ? "00:00:00" : "-"));

    return Container(
      width: colDateWidth,
      height: 72,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Runtime
            Text(
              runStr,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.15,
                fontWeight: runSec > 0 ? FontWeight.bold : FontWeight.w500,
                color: runSec > 0
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 1),
            // 2. Total Power
            Text(
              powerOnStr,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.15,
                fontWeight: powerOnSec > 0 ? FontWeight.bold : FontWeight.w500,
                color: powerOnSec > 0
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 1),
            // 3. Total Power Off Time
            Text(
              powerOffStr,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.15,
                fontWeight: powerOffSec > 0 ? FontWeight.bold : FontWeight.w500,
                color: powerOffSec > 0
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedPumpTotalRow(
    CumulativeRowData row,
    int rowIndex,
    double colTotalWidth, {
    bool isPinned = false,
  }) {
    Color rowBg = rowIndex % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = screenWidth < 650 ? 12.0 : 13.0;

    final bool hasRun = row.totalDurationSeconds > 0;
    final bool hasPowerOn = row.totalPowerOnSeconds > 0;
    final bool hasPowerOff = row.totalPowerOffSeconds > 0;

    final String runStr =
        hasRun ? "${_formatDuration(row.totalDurationSeconds)} /" : "- /";
    final String powerOnStr =
        hasPowerOn ? "${_formatDuration(row.totalPowerOnSeconds)} /" : "- /";
    final String powerOffStr =
        hasPowerOff ? _formatDuration(row.totalPowerOffSeconds) : "-";

    return Container(
      width: colTotalWidth,
      height: 72,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showIndividualPumpGraphDialog(context, row),
          borderRadius: BorderRadius.circular(4),
          child: Tooltip(
            message: "Tap to view ${row.channelName} graph",
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    runStr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.15,
                      fontWeight: hasRun ? FontWeight.bold : FontWeight.w500,
                      color: hasRun
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    powerOnStr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.15,
                      fontWeight: hasPowerOn ? FontWeight.bold : FontWeight.w500,
                      color: hasPowerOn
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    powerOffStr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.15,
                      fontWeight: hasPowerOff ? FontWeight.bold : FontWeight.w500,
                      color: hasPowerOff
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyPumpFooterTotalRow(
    Map<String, int> dailyRunTotals,
    Map<String, int> dailyPowerOnTotals,
    Map<String, int> dailyPowerOffTotals,
    double colDateWidth,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = screenWidth < 650 ? 12.0 : 13.0;

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
            Builder(builder: (context) {
              String dKey = DateFormat('yyyy-MM-dd').format(_dateColumns[dIdx]);
              int runSec = dailyRunTotals[dKey] ?? 0;
              int powerOnSec = dailyPowerOnTotals[dKey] ?? 0;
              int powerOffSec = dailyPowerOffTotals[dKey] ?? 0;

              bool hasActivity =
                  runSec > 0 || powerOnSec > 0 || powerOffSec > 0;
              String runStr = runSec > 0
                  ? "${_formatDuration(runSec)} /"
                  : (hasActivity ? "0h 0m /" : "- /");
              String powerOnStr = powerOnSec > 0
                  ? "${_formatDuration(powerOnSec)} /"
                  : (hasActivity ? "0h 0m /" : "- /");
              String powerOffStr = powerOffSec > 0
                  ? _formatDuration(powerOffSec)
                  : (hasActivity ? "0h 0m" : "-");

              return Container(
                width: colDateWidth,
                height: 72,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        runStr,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 1.15,
                          fontWeight:
                              runSec > 0 ? FontWeight.bold : FontWeight.w500,
                          color: runSec > 0
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        powerOnStr,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 1.15,
                          fontWeight:
                              powerOnSec > 0 ? FontWeight.bold : FontWeight.w500,
                          color: powerOnSec > 0
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        powerOffStr,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 1.15,
                          fontWeight:
                              powerOffSec > 0 ? FontWeight.bold : FontWeight.w500,
                          color: powerOffSec > 0
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMobilePumpDataRow(
    CumulativeRowData row,
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
          _buildPinnedLeftPumpRow(row, rowIndex, colSeqWidth),
          for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
            _buildDatePumpBlock(
              row,
              _dateColumns[dIdx],
              colDateWidth,
            ),
          _buildPinnedPumpTotalRow(
            row,
            rowIndex,
            colTotalWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePumpFooterTotalRow(
    Map<String, int> dailyRunTotals,
    Map<String, int> dailyPowerOnTotals,
    Map<String, int> dailyPowerOffTotals,
    int grandTotalRunSec,
    int grandTotalPowerOnSec,
    int grandTotalPowerOffSec,
    double colSeqWidth,
    double colDateWidth,
    double colTotalWidth,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = screenWidth < 650 ? 12.0 : 13.0;

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: colSeqWidth,
            height: 72,
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
              int runSec = dailyRunTotals[dKey] ?? 0;
              int powerOnSec = dailyPowerOnTotals[dKey] ?? 0;
              int powerOffSec = dailyPowerOffTotals[dKey] ?? 0;

              bool hasActivity =
                  runSec > 0 || powerOnSec > 0 || powerOffSec > 0;
              String runStr = runSec > 0
                  ? "${_formatDuration(runSec)} /"
                  : (hasActivity ? "0h 0m /" : "- /");
              String powerOnStr = powerOnSec > 0
                  ? "${_formatDuration(powerOnSec)} /"
                  : (hasActivity ? "0h 0m /" : "- /");
              String powerOffStr = powerOffSec > 0
                  ? _formatDuration(powerOffSec)
                  : (hasActivity ? "0h 0m" : "-");

              return Container(
                width: colDateWidth,
                height: 72,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        runStr,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 1.15,
                          fontWeight:
                              runSec > 0 ? FontWeight.bold : FontWeight.w500,
                          color: runSec > 0
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        powerOnStr,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 1.15,
                          fontWeight:
                              powerOnSec > 0 ? FontWeight.bold : FontWeight.w500,
                          color: powerOnSec > 0
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        powerOffStr,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 1.15,
                          fontWeight:
                              powerOffSec > 0 ? FontWeight.bold : FontWeight.w500,
                          color: powerOffSec > 0
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          Container(
            width: colTotalWidth,
            height: 72,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
            ),
            child: Builder(builder: (context) {
              bool hasGrandActivity = grandTotalRunSec > 0 ||
                  grandTotalPowerOnSec > 0 ||
                  grandTotalPowerOffSec > 0;
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      grandTotalRunSec > 0
                          ? "${_formatDuration(grandTotalRunSec)} /"
                          : (hasGrandActivity ? "0h 0m /" : "- /"),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.15,
                        fontWeight: grandTotalRunSec > 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: grandTotalRunSec > 0
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      grandTotalPowerOnSec > 0
                          ? "${_formatDuration(grandTotalPowerOnSec)} /"
                          : (hasGrandActivity ? "0h 0m /" : "- /"),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.15,
                        fontWeight: grandTotalPowerOnSec > 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: grandTotalPowerOnSec > 0
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      grandTotalPowerOffSec > 0
                          ? _formatDuration(grandTotalPowerOffSec)
                          : (hasGrandActivity ? "0h 0m" : "-"),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.15,
                        fontWeight: grandTotalPowerOffSec > 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: grandTotalPowerOffSec > 0
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePumpMatrixTable(
    BuildContext context,
    List<CumulativeRowData> rows,
    Map<String, int> dailyRunTotals,
    Map<String, int> dailyPowerOnTotals,
    Map<String, int> dailyPowerOffTotals,
    int grandTotalRunSec,
    int grandTotalPowerOnSec,
    int grandTotalPowerOffSec,
  ) {
    const double colSeqWidth = 140;
    const double colDateWidth = 145;
    const double colTotalWidth = 145;
    final double totalTableWidth =
        colSeqWidth + (_dateColumns.length * colDateWidth) + colTotalWidth;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(6),
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
                            bottom:
                                BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          ),
                        ),
                        child: const Text(
                          "Pump Details",
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
                            color: Color(0xFFE2E8F0),
                            border: Border(
                              right: BorderSide(
                                  color: Color(0xFFCBD5E1), width: 1),
                              bottom: BorderSide(
                                  color: Color(0xFFCBD5E1), width: 1),
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
                          color: Color(0xFF00695C),
                          border: Border(
                            bottom:
                                BorderSide(color: Color(0xFFCBD5E1), width: 1),
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
                      _buildSubHeaderCell("Pump", colSeqWidth, height: 52),
                      for (int dIdx = 0; dIdx < _dateColumns.length; dIdx++)
                        _buildSubHeaderCell(
                            "Runtime /\nTotal Power On /\nTotal Power Off Time",
                            colDateWidth,
                            height: 52),
                      _buildSubHeaderCell(
                          "Runtime /\nTotal Power On/\nTotal Power Off Time",
                          colTotalWidth,
                          isTotalCol: true,
                          height: 52),
                    ],
                  ),

                  // 3. DATA ROWS
                  for (int rIdx = 0; rIdx < rows.length; rIdx++)
                    _buildMobilePumpDataRow(
                      rows[rIdx],
                      rIdx,
                      colSeqWidth,
                      colDateWidth,
                      colTotalWidth,
                    ),

                  // 4. FOOTER TOTAL ROW
                  _buildMobilePumpFooterTotalRow(
                    dailyRunTotals,
                    dailyPowerOnTotals,
                    dailyPowerOffTotals,
                    grandTotalRunSec,
                    grandTotalPowerOnSec,
                    grandTotalPowerOffSec,
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

  Widget _buildPumpLogMatrixTable(BuildContext context) {
    if (_isLoading || _isPumpLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    var rows = _getFilteredPumpRows();

    if (_dateColumns.isEmpty || rows.isEmpty) {
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

    // Calculate daily totals for Run time, Total Power, and Total Power Off Time
    Map<String, int> dailyRunTotals = {};
    Map<String, int> dailyPowerOnTotals = {};
    Map<String, int> dailyPowerOffTotals = {};
    int grandTotalRunSec = 0;
    int grandTotalPowerOnSec = 0;
    int grandTotalPowerOffSec = 0;

    for (var d in _dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int dayRunSum = 0;
      int dayPowerOnSum = 0;
      int dayPowerOffSum = 0;

      for (var r in rows) {
        if (r.dayEntries.containsKey(dKey)) {
          final entry = r.dayEntries[dKey]!;
          dayRunSum += entry.durationSeconds;
          dayPowerOnSum += entry.powerOnSeconds;
          dayPowerOffSum += entry.powerOffSeconds;
        }
      }

      dailyRunTotals[dKey] = dayRunSum;
      dailyPowerOnTotals[dKey] = dayPowerOnSum;
      dailyPowerOffTotals[dKey] = dayPowerOffSum;
    }

    for (var r in rows) {
      grandTotalRunSec += r.totalDurationSeconds;
      grandTotalPowerOnSec += r.totalPowerOnSeconds;
      grandTotalPowerOffSec += r.totalPowerOffSeconds;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final bool isMobile = availableWidth < 650;

        if (isMobile) {
          return _buildMobilePumpMatrixTable(
            context,
            rows,
            dailyRunTotals,
            dailyPowerOnTotals,
            dailyPowerOffTotals,
            grandTotalRunSec,
            grandTotalPowerOnSec,
            grandTotalPowerOffSec,
          );
        }

        // Base Column Widths
        const double baseSeqWidth = 160;
        const double baseDateColWidth = 160;
        const double baseTotalWidth = 160;

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
              // 1. PINNED LEFT PUMP COLUMN
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
                    Container(
                      width: colSeqWidth,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00695C),
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFCBD5E1), width: 1),
                        ),
                      ),
                      child: const Text(
                        "Pump Details",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    _buildSubHeaderCell("Pump", colSeqWidth, height: 52),
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
                              for (int rIdx = 0; rIdx < rows.length; rIdx++)
                                _buildPinnedLeftPumpRow(
                                  rows[rIdx],
                                  rIdx,
                                  colSeqWidth,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: colSeqWidth,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          bottom:
                              BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
                    const SizedBox(height: 15),
                  ],
                ),
              ),

              // 2. DATE COLUMNS AREA
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
                                      color: Color(0xFFE2E8F0),
                                      border: Border(
                                        right: BorderSide(
                                            color: Color(0xFFCBD5E1), width: 1),
                                        bottom: BorderSide(
                                            color: Color(0xFFCBD5E1), width: 1),
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
                            Row(
                              children: [
                                for (int dIdx = 0;
                                    dIdx < _dateColumns.length;
                                    dIdx++)
                                  _buildSubHeaderCell(
                                      "Runtime /\nTotal Power On /\nTotal Power Off Time",
                                      colDateWidth,
                                      height: 52),
                              ],
                            ),
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
                                            rIdx < rows.length;
                                            rIdx++)
                                          Container(
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: rIdx % 2 == 0
                                                  ? Colors.white
                                                  : const Color(0xFFF8FAFC),
                                              border: const Border(
                                                bottom: BorderSide(
                                                    color: Color(0xFFE2E8F0),
                                                    width: 1),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                for (int dIdx = 0;
                                                    dIdx < _dateColumns.length;
                                                    dIdx++)
                                                  _buildDatePumpBlock(
                                                    rows[rIdx],
                                                    _dateColumns[dIdx],
                                                    colDateWidth,
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _buildDailyPumpFooterTotalRow(
                              dailyRunTotals,
                              dailyPowerOnTotals,
                              dailyPowerOffTotals,
                              colDateWidth,
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. PINNED RIGHT TOTAL COLUMN
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
                    Container(
                      width: double.infinity,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00695C),
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFCBD5E1), width: 1),
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
                    _buildSubHeaderCell(
                        "Runtime /\nTotal Power On /\nTotal Power Off Time",
                        colTotalWidth,
                        isTotalCol: true,
                        height: 52),
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
                              for (int rIdx = 0; rIdx < rows.length; rIdx++)
                                _buildPinnedPumpTotalRow(
                                  rows[rIdx],
                                  rIdx,
                                  colTotalWidth,
                                  isPinned: true,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: colTotalWidth,
                      height: 72,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          bottom:
                              BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                      ),
                      child: Builder(builder: (context) {
                        bool hasGrandActivity = grandTotalRunSec > 0 ||
                            grandTotalPowerOnSec > 0 ||
                            grandTotalPowerOffSec > 0;
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                grandTotalRunSec > 0
                                    ? "${_formatDuration(grandTotalRunSec)} /"
                                    : (hasGrandActivity ? "0h 0m /" : "- /"),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width < 1100
                                          ? 12.5
                                          : 13.0,
                                  height: 1.15,
                                  fontWeight: FontWeight.bold,
                                  color: grandTotalRunSec > 0
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                grandTotalPowerOnSec > 0
                                    ? "${_formatDuration(grandTotalPowerOnSec)} /"
                                    : (hasGrandActivity ? "0h 0m /" : "- /"),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width < 1100
                                          ? 12.5
                                          : 13.0,
                                  height: 1.15,
                                  fontWeight: FontWeight.bold,
                                  color: grandTotalPowerOnSec > 0
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                grandTotalPowerOffSec > 0
                                    ? _formatDuration(grandTotalPowerOffSec)
                                    : (hasGrandActivity ? "0h 0m" : "-"),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width < 1100
                                          ? 12.5
                                          : 13.0,
                                  height: 1.15,
                                  fontWeight: FontWeight.bold,
                                  color: grandTotalPowerOffSec > 0
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

class _PumpChartPoint {
  final String xLabel;
  final double runTimeMinutes;
  final String runTimeFormatted;
  final double powerOnMinutes;
  final String powerOnFormatted;
  final double powerOffMinutes;
  final String powerOffFormatted;

  _PumpChartPoint({
    required this.xLabel,
    required this.runTimeMinutes,
    required this.runTimeFormatted,
    required this.powerOnMinutes,
    required this.powerOnFormatted,
    required this.powerOffMinutes,
    required this.powerOffFormatted,
  });
}
