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

import '../../../Widgets/custom_buttons.dart';
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
  DateTime _pickerStartDate =
  DateTime.now().subtract(const Duration(days: 29));

  DateTime _pickerEndDate = DateTime.now();

  DateTime _tempStart = DateTime.now();
  DateTime _tempEnd = DateTime.now();

  Map<String, dynamic> data = {};

  bool isLoading = false;
  bool isDownloading = false;

  static const int _pageSize = 10;
  int _page = 0;

  final ScrollController _horizontalScrollController =
  ScrollController();

  final ScrollController _verticalScrollController =
  ScrollController();

  static const double _columnGap = 20;

  static const List<MapEntry<String, double>> _columns = [
    MapEntry('Program', 90),
    MapEntry('Zone', 80),
    MapEntry('Set Time', 100),
    MapEntry('Run Time', 100),
    MapEntry('Set Flow', 90),
    MapEntry('Run Flow', 90),
    MapEntry('Start Time', 100),
    MapEntry('End Time', 100),
    MapEntry('Prs In', 80),
    MapEntry('Prs Out', 80),
    MapEntry('Well Level', 100),
    MapEntry('Percentage', 100),
    MapEntry('Ec', 70),
    MapEntry('pH', 70),
  ];

  double get _tableWidth =>
      _columns.fold(0.0, (sum, c) => sum + c.value) +
          (_columnGap * (_columns.length - 1)) +
          32;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) getData();
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
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
      final formattedDate1 =
      DateFormat('yyyy-MM-dd').format(_pickerStartDate);

      final formattedDate2 =
      DateFormat('yyyy-MM-dd').format(_pickerEndDate);

      final body = {
        "userId": widget.userData['customerId'],
        "controllerId": widget.userData['controllerId'],
        "logType": "IrrigationZoneCyclic",
        "fromDate": formattedDate1,
        "toDate": formattedDate2,
      };

      debugPrint('Zone Cyclic Request: $body');

      final response =
      await IrrigationRepository().getNovaLogDateWise(body);

      final Map<String, dynamic> jsonData =
      jsonDecode(response.body);

      debugPrint('Zone Cyclic Response: $jsonData');

      if (!mounted) return;

      if (jsonData['code'] == 200) {
        setState(() {
          data = jsonData['data'] is Map<String, dynamic>
              ? jsonData['data']
              : {};

          _page = 0;
        });
      } else {
        setState(() {
          data = {};
          _page = 0;
        });

        debugPrint('API Error: ${jsonData['message']}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in Zone Cyclic Log: $e');
      debugPrint('StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          data = {};
          _page = 0;
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
  // DATE PICKER
  // ------------------------------------------------------------

  void _onSelectionChanged(
      DateRangePickerSelectionChangedArgs args) {
    if (args.value is PickerDateRange) {
      final PickerDateRange range =
      args.value as PickerDateRange;

      _tempStart = range.startDate ?? DateTime.now();
      _tempEnd = range.endDate ?? _tempStart;
    } else if (args.value is DateTime) {
      _tempStart = args.value as DateTime;
      _tempEnd = _tempStart;
    }
  }

  void _showDatePicker() {
    _tempStart = _pickerStartDate;
    _tempEnd = _pickerEndDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Date Picker'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: SfDateRangePicker(
              onSelectionChanged: _onSelectionChanged,
              selectionMode: DateRangePickerSelectionMode.range,
              initialSelectedRange: PickerDateRange(
                _pickerStartDate,
                _pickerEndDate,
              ),
              maxDate: DateTime.now(),
              showNavigationArrow: true,
            ),
          ),
          actions: [
            CustomMaterialButton(
              title: 'Cancel',
              outlined: true,
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
            CustomMaterialButton(
              title: 'Submit',
              onPressed: () async {
                Navigator.pop(dialogContext);

                setState(() {
                  _pickerStartDate = _tempStart;
                  _pickerEndDate = _tempEnd;
                  _page = 0;
                });

                await getData();
              },
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // ZONE NUMBER
  // ------------------------------------------------------------

  int _getZoneNumber(dynamic zoneValue) {
    if (zoneValue == null) return 0;

    final match =
    RegExp(r'\d+').firstMatch(zoneValue.toString());

    if (match == null) return 0;

    return int.tryParse(match.group(0)!) ?? 0;
  }

  // ------------------------------------------------------------
  // DATE-WISE UNIQUE AND SORTED ZONES
  // ------------------------------------------------------------

  List<Map<String, dynamic>> _getUniqueSortedZones(
      Map<String, dynamic> dateData,
      ) {
    final List zoneList =
    dateData['zoneList'] is List
        ? dateData['zoneList']
        : [];

    final Map<int, Map<String, dynamic>> uniqueZones = {};

    for (final item in zoneList) {
      if (item is! Map) continue;

      final zone = Map<String, dynamic>.from(item);

      final int zoneNumber =
      _getZoneNumber(zone['zone']);

      if (zoneNumber == 0) continue;

      // Same date-la same zone number repeat aana
      // first entry mattum retain aagum.
      uniqueZones.putIfAbsent(
        zoneNumber,
            () => zone,
      );
    }

    final List<Map<String, dynamic>> sortedZones =
    uniqueZones.values.toList();

    sortedZones.sort((a, b) {
      return _getZoneNumber(a['zone'])
          .compareTo(_getZoneNumber(b['zone']));
    });

    return sortedZones;
  }

  // ------------------------------------------------------------
  // FLAT ROWS - UI AND EXPORT
  // ------------------------------------------------------------

  List<Map<String, dynamic>> _flatRows() {
    final List<Map<String, dynamic>> rows = [];

    final list = data['zoneCyclic'];

    if (list is! List) return rows;

    for (final date in list) {
      if (date is! Map) continue;

      final Map<String, dynamic> dateData =
      Map<String, dynamic>.from(date);

      final List<Map<String, dynamic>> zones =
      _getUniqueSortedZones(dateData);

      for (final zone in zones) {
        rows.add({
          'date': dateData,
          'zone': zone,
        });
      }
    }

    return rows;
  }

  // ------------------------------------------------------------
  // CYCLIC DURATION
  // ------------------------------------------------------------

  String getCyclicDuration({
    required Map<String, dynamic> data,
  }) {
    final DataConvert dataConvert = DataConvert();

    int totalSeconds = 0;

    final List<Map<String, dynamic>> zoneList =
    _getUniqueSortedZones(data);

    for (final zoneData in zoneList) {
      totalSeconds += dataConvert.parseTimeString(
        '${zoneData['duration'] ?? '00:00:00'}',
      );
    }

    return dataConvert.formatTime(totalSeconds);
  }

  // ------------------------------------------------------------
  // CYCLIC FLOW
  // ------------------------------------------------------------

  String getCyclicFlow({
    required Map<String, dynamic> data,
  }) {
    double totalFlow = 0;

    final List<Map<String, dynamic>> zoneList =
    _getUniqueSortedZones(data);

    for (final zoneData in zoneList) {
      totalFlow +=
          double.tryParse('${zoneData['flow'] ?? 0}') ?? 0;
    }

    return totalFlow.toString();
  }

  // ------------------------------------------------------------
  // CYCLIC TIME
  // ------------------------------------------------------------

  String getCyclicTime({
    required Map<String, dynamic> data,
  }) {
    final List<Map<String, dynamic>> zoneList =
    _getUniqueSortedZones(data);

    if (zoneList.isEmpty) return '-';

    return '${zoneList.first['onTime'] ?? '-'} to '
        '${zoneList.last['offTime'] ?? '-'}';
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
  // PDF EXPORT ROWS
  // ------------------------------------------------------------

  List<List<String>> _getExportRows() {
    final rows = _flatRows();

    final List<List<String>> result = [];

    result.add(
      _columns.map((column) => column.key).toList(),
    );

    for (final item in rows) {
      final Map<String, dynamic> z = item['zone'];

      result.add([
        '${z['program'] ?? '-'}',
        '${z['zone'] ?? '-'}',
        '${z['setTime'] ?? '-'}',
        '${z['duration'] ?? '-'}',
        '${z['setFlow'] ?? '-'}',
        '${z['flow'] ?? '-'}',
        '${z['onTime'] ?? '-'}',
        '${z['offTime'] ?? '-'}',
        '${z['pressureIn'] ?? '-'}',
        '${z['pressureOut'] ?? '-'}',
        '${z['wellLevel'] ?? '-'}',
        '${z['wellPercentage'] ?? '-'}',
        '${z['ec'] ?? '-'}',
        '${z['ph'] ?? '-'}',
      ]);
    }

    return result;
  }

  // ------------------------------------------------------------
  // EXCEL EXPORT ROWS
  // ------------------------------------------------------------

  List<List<String>> _getExcelExportRows() {
    final rows = _flatRows();

    final List<List<String>> result = [];

    result.add([
      'Date',
      ..._columns.map((column) => column.key),
    ]);

    for (final item in rows) {
      final Map<String, dynamic> z = item['zone'];
      final Map<String, dynamic> dateData = item['date'];

      result.add([
        '${dateData['date'] ?? '-'}',
        '${z['program'] ?? '-'}',
        '${z['zone'] ?? '-'}',
        '${z['setTime'] ?? '-'}',
        '${z['duration'] ?? '-'}',
        '${z['setFlow'] ?? '-'}',
        '${z['flow'] ?? '-'}',
        '${z['onTime'] ?? '-'}',
        '${z['offTime'] ?? '-'}',
        '${z['pressureIn'] ?? '-'}',
        '${z['pressureOut'] ?? '-'}',
        '${z['wellLevel'] ?? '-'}',
        '${z['wellPercentage'] ?? '-'}',
        '${z['ec'] ?? '-'}',
        '${z['ph'] ?? '-'}',
      ]);
    }

    return result;
  }

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
      final exportRows = _getExcelExportRows();

      if (exportRows.length <= 1) {
        _showExportMessage('No data available to download');
        return;
      }

      final xl.Excel excel = xl.Excel.createExcel();

      final xl.Sheet sheet = excel['Zone Cyclic Log'];

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
                'Zone Cyclic Log',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(_pickerStartDate)}'
                    ' - ${DateFormat('dd/MM/yyyy').format(_pickerEndDate)}',
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
                cellStyle: const pw.TextStyle(fontSize: 7),
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

  void _showExportMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rows = _flatRows();

    final int total = rows.length;

    final int totalPages =
    total == 0 ? 1 : (total / _pageSize).ceil();

    if (_page >= totalPages) {
      _page = totalPages - 1;
    }

    final int start = _page * _pageSize;

    final int end =
    (start + _pageSize) > total ? total : (start + _pageSize);

    final List<Map<String, dynamic>> pageRows =
    total == 0 ? [] : rows.sublist(start, end);

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
                  : pageRows.isEmpty
                  ? const Center(
                child: Text(
                  'There is no cyclic log data',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
                  : _buildTable(pageRows),
            ),
            _buildBottomBar(
              total,
              start,
              end,
              totalPages,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------

  Widget _buildTopBar() {
    final String range =
        '${DateFormat('dd/MM/yyyy').format(_pickerStartDate)} - '
        '${DateFormat('dd/MM/yyyy').format(_pickerEndDate)}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      color: Colors.white,
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            size: 18,
            color: Theme.of(context).primaryColorDark,
          ),
          const SizedBox(width: 6),
          Text(
            range,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).primaryColorDark,
            ),
            onPressed: getData,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TABLE
  // ------------------------------------------------------------

  Widget _buildTable(List<Map<String, dynamic>> pageRows) {
    final Color headBg =
    Theme.of(context).primaryColorLight.withOpacity(0.25);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ScrollbarTheme(
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
              width: _tableWidth,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    color: headBg,
                    child: Text(
                      'General',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    color: Colors.grey.shade50,
                    child: Row(
                      children: [
                        for (int i = 0; i < _columns.length; i++) ...[
                          SizedBox(
                            width: _columns[i].value,
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
                            const SizedBox(width: _columnGap),
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
                      scrollbarOrientation: ScrollbarOrientation.right,
                      child: ListView.builder(
                        controller: _verticalScrollController,
                        padding: EdgeInsets.zero,
                        itemCount: pageRows.length,
                        itemBuilder: (context, index) {
                          final Map<String, dynamic> currentDate =
                          pageRows[index]['date'];

                          final Map<String, dynamic> zone =
                          pageRows[index]['zone'];

                          final bool showDateHeader =
                              index == 0 ||
                                  pageRows[index - 1]['date']['date'] !=
                                      currentDate['date'];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDateHeader)
                                _dateGroupRow(currentDate),
                              _zoneRow(zone),
                            ],
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
      ),
    );
  }

  // ------------------------------------------------------------
  // DATE SUMMARY ROW
  // ------------------------------------------------------------

  Widget _dateGroupRow(Map<String, dynamic> date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      color: const Color(0xFFDCEDF1),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${date["date"] ?? "-"}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
          _summaryChip(
            'Cyclic Duration',
            getCyclicDuration(data: date),
          ),
          _summaryChip(
            'Cyclic Flow',
            getCyclicFlow(data: date),
          ),
          _summaryChip(
            'Cyclic Time',
            getCyclicTime(data: date),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY CHIP
  // ------------------------------------------------------------

  Widget _summaryChip(String title, String value) {
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

  Widget _zoneRow(Map<String, dynamic> z) {
    final values = <dynamic>[
      z['program'],
      z['zone'],
      z['setTime'],
      z['duration'],
      z['setFlow'],
      z['flow'],
      z['onTime'],
      z['offTime'],
      z['pressureIn'],
      z['pressureOut'],
      z['wellLevel'],
      z['wellPercentage'],
      z['ec'],
      z['ph'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
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
              width: _columns[i].value,
              child: Text(
                '${values[i] ?? "-"}',
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
              const SizedBox(width: _columnGap),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM BAR
  // ------------------------------------------------------------

  Widget _buildBottomBar(
      int total,
      int start,
      int end,
      int totalPages,
      ) {
    final Color barColor =
        Theme.of(context).primaryColorDark;

    Widget pageBtn(IconData icon, VoidCallback? onTap) {
      return InkWell(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 48,
          color: Colors.white,
          child: Icon(
            icon,
            color: onTap == null ? Colors.grey : Colors.black,
          ),
        ),
      );
    }

    return Container(
      color: barColor,
      padding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 8,
      ),
      child: Row(
        children: [
          pageBtn(
            Icons.keyboard_double_arrow_left,
            _page > 0
                ? () {
              setState(() {
                _page--;
              });
            }
                : null,
          ),
          Container(
            height: 48,
            constraints: const BoxConstraints(minWidth: 90),
            alignment: Alignment.center,
            color: Colors.transparent,
            child: Text(
              total == 0
                  ? '0 - 0 / 0'
                  : '${start + 1} - $end / $total',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          pageBtn(
            Icons.keyboard_double_arrow_right,
            _page < totalPages - 1
                ? () {
              setState(() {
                _page++;
              });
            }
                : null,
          ),
          const Spacer(),
          InkWell(
            onTap: _showDatePicker,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              color: Colors.white,
              child: const Text(
                'Select Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: isDownloading ? null : _showDownloadDialog,
            child: Container(
              width: 52,
              height: 48,
              color: Colors.white,
              child: isDownloading
                  ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(
                Icons.download,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}