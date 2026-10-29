import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../model/fertigation_card_model.dart';
import '../repository/irrigation_repository.dart';
import '../services/fertigation_card_mapper.dart';
import 'excel_download_stub.dart' if (dart.library.html) 'excel_download_web.dart';
import 'zone_log_pdf_builder.dart' if (dart.library.html) 'zone_log_exporter_web.dart';

import 'widgets/program_wise_view.dart';
import 'widgets/fertigation_table_view.dart';

class FertigationCardListPage extends StatefulWidget {
  final dynamic serverData;
  final Map<String, dynamic> userData;
  final List<dynamic> nameData;

  const FertigationCardListPage({
    super.key,
    required this.serverData,
    required this.userData,
    required this.nameData,
  });

  @override
  State<FertigationCardListPage> createState() =>
      _FertigationCardListPageState();
}

class _FertigationCardListPageState
    extends State<FertigationCardListPage> {
  bool _isLoading = false;
  String? _fetchError;
  bool _isTableView = false;

  dynamic dataSource = {};
  List<FertigationCardModel> allCards = [];

  String _selectedDateStr = '';

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _updateDateLabel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _requestId++;
    super.dispose();
  }

  void _updateDateLabel() {
    _selectedDateStr =
    '${DateFormat('dd/MM/yyyy').format(_fromDate)}'
        ' - '
        '${DateFormat('dd/MM/yyyy').format(_toDate)}';
  }

  void _debugDataStructure(
      String label,
      dynamic source,
      ) {
    debugPrint('========== $label ==========');
    debugPrint('TYPE: ${source.runtimeType}');

    if (source == null) {
      debugPrint('DATA IS NULL');
      return;
    }

    if (source is Map) {
      debugPrint('KEYS: ${source.keys.toList()}');

      final logs = source['log'];

      if (logs is List) {
        debugPrint('LOG COUNT: ${logs.length}');

        if (logs.isNotEmpty) {
          final firstLog = logs.first;

          debugPrint(
            'FIRST LOG TYPE: ${firstLog.runtimeType}',
          );

          if (firstLog is Map) {
            debugPrint(
              'FIRST LOG KEYS: ${firstLog.keys.toList()}',
            );

            debugPrint(
              'FIRST LOG DATE: ${firstLog['logDate']}',
            );

            final irrigation = firstLog['irrigation'];

            if (irrigation is Map) {
              debugPrint(
                'IRRIGATION KEYS: '
                    '${irrigation.keys.toList()}',
              );

              for (final key in [
                'Date',
                'ProgramS_No',
                'Status',
                'status',
                'ZoneS_No',
                'SequenceData',
                'IrrigationMethod',
                'IrrigationDuration_Quantity',
                'IrrigationDurationCompleted',
              ]) {
                final value = irrigation[key];

                debugPrint(
                  '$key => type=${value.runtimeType}, '
                      'value=$value',
                );
              }
            } else {
              debugPrint(
                'IRRIGATION DATA TYPE: '
                    '${irrigation.runtimeType}',
              );
            }
          }
        }
      } else {
        debugPrint(
          'LOG KEY TYPE: ${logs.runtimeType}',
        );
      }

      final defaults = source['default'];

      if (defaults is Map) {
        debugPrint(
          'DEFAULT KEYS: ${defaults.keys.toList()}',
        );

        final programs = defaults['program'];

        debugPrint(
          'PROGRAM CONFIG TYPE: '
              '${programs.runtimeType}',
        );

        if (programs is List) {
          debugPrint(
            'PROGRAM CONFIG COUNT: '
                '${programs.length}',
          );

          if (programs.isNotEmpty) {
            debugPrint(
              'FIRST PROGRAM CONFIG: '
                  '${programs.first}',
            );
          }
        }
      }
    } else if (source is List) {
      debugPrint('LIST COUNT: ${source.length}');

      if (source.isNotEmpty) {
        debugPrint(
          'FIRST ITEM TYPE: '
              '${source.first.runtimeType}',
        );

        if (source.first is Map) {
          debugPrint(
            'FIRST ITEM KEYS: '
                '${(source.first as Map).keys.toList()}',
          );
        }
      }
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    final currentRequest = ++_requestId;

    setState(() {
      _isLoading = true;
      _fetchError = null;
    });

    try {
      final formattedDate1 =
      DateFormat('yyyy-MM-dd').format(_fromDate);

      final formattedDate2 =
      DateFormat('yyyy-MM-dd').format(_toDate);


      final body = {
        "userId": widget.userData['customerId'],
        "controllerId": widget.userData['controllerId'],
        "logType": "Irrigation",
        "fromDate": formattedDate1,
        "toDate": formattedDate2,
        "parameters": [
          "Date",
          "Status",
          "ProgramS_No",
          "ProgramCategory",
          "ZoneS_No",
          "ZoneName",
          "ScheduledStartTime",
          "ActualStartTime",
          "ActualEndTime",
          "ActualStartReason",
          "ActualStopReason",
          "SequenceData",
          "ValveFlowrate",
          "IrrigationDurationCompleted",
          "ProgramName",
          "IrrigationMethod",
          "IrrigationDuration_Quantity",
          "IrrigationQuantityCompleted",
          "ProgramCategoryName",
          "Pretime",
          "PostTime",
          "CentralFilterName",
          "LocalFilterName",
          "CentralFilterOnDuration",
          "LocalFilterOnDuration",
          "CentralFertOnOff",
          "LocalFertOnOff",
          "HeadUnit",
          "PrePostMethod",
          "PreQty",
          "PostQty",
          "CentralPhSetValue",
          "CentralPhAverage",
          "CentralPhMaximum",
          "CentralPhMinimum",
          "CentralEcSetValue",
          "CentralEcAverage",
          "CentralEcMaximum",
          "CentralEcMinimum",
          "CentralFertChannelName",
          "CentralFertMethod",
          "CentralFertilizerChannelDuration",
          "CentralFertilizerChannelQuantity",
          "CentralFertilizerChannelDurationCompleted",
          "CentralFertilizerChannelQuantityCompleted",
          "LocalPhSetValue",
          "LocalPhAverage",
          "LocalPhMaximum",
          "LocalPhMinimum",
          "LocalEcSetValue",
          "LocalEcAverage",
          "LocalEcMaximum",
          "LocalEcMinimum",
          "LocalFertChannelName",
          "LocalFertMethod",
          "LocalFertilizerChannelDuration",
          "LocalFertilizerChannelQuantity",
          "LocalFertilizerChannelDurationCompleted",
          "LocalFertilizerChannelQuantityCompleted",
        ],
      };


      debugPrint(
        '========== FERTIGATION REQUEST ==========',
      );

      debugPrint('REQUEST BODY: $body');

      _debugDataStructure(
        'EXISTING SERVER DATA',
        widget.serverData,
      );

      debugPrint(
        'NAME DATA COUNT: ${widget.nameData.length}',
      );

      final response =
      await IrrigationRepository().getLogDateWise(body);

      if (!mounted || currentRequest != _requestId) {
        return;
      }

      debugPrint(
        'HTTP STATUS CODE: ${response.statusCode}',
      );

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw const FormatException(
          'API response is not a JSON object.',
        );
      }

      final jsonData =
      Map<String, dynamic>.from(decoded);

      debugPrint(
        'API RESPONSE KEYS: ${jsonData.keys.toList()}',
      );

      debugPrint('API CODE: ${jsonData['code']}');
      debugPrint('API MESSAGE: ${jsonData['message']}');

      if (response.statusCode != 200 ||
          jsonData['code'].toString() != '200') {
        throw Exception(
          'API Error: ${jsonData['message']} '
              '(HTTP ${response.statusCode})',
        );
      }

      final dynamic rawData = jsonData['data'];

      _debugDataStructure(
        'ACTUAL API DATA',
        rawData,
      );

      if (rawData == null) {
        throw const FormatException(
          'API returned null data.',
        );
      }

      debugPrint(
        '========== FERTIGATION MAPPER START ==========',
      );

      List<dynamic> activeNames = widget.nameData;
      if (activeNames.isEmpty) {
        try {
          final namesRes = await IrrigationRepository().getUserNames({
            "userId": widget.userData['customerId'],
            "controllerId": widget.userData['controllerId'],
          });
          if (namesRes.statusCode == 200) {
            final namesJson = jsonDecode(namesRes.body);
            if (namesJson['code'] == 200 &&
                namesJson['data'] != null &&
                namesJson['data']['configObject'] is List) {
              activeNames = namesJson['data']['configObject'];
            }
          }
        } catch (_) {}
      }

      final List<FertigationCardModel> mappedCards =
      FertigationCardMapper.mapLogData(
        rawData,
        activeNames,
      );

      debugPrint(
        'MAPPED CARDS COUNT: ${mappedCards.length}',
      );

      if (mappedCards.isNotEmpty) {
        final firstCard = mappedCards.first;

        debugPrint(
          'FIRST CARD PROGRAM: ${firstCard.programName}',
        );

        debugPrint(
          'FIRST CARD STATUS: ${firstCard.status}',
        );

        debugPrint(
          'FIRST CARD SEQUENCE: ${firstCard.sequenceName}',
        );

        debugPrint(
          'FIRST CARD DATE: ${firstCard.date}',
        );
      }

      debugPrint(
        '========== FERTIGATION MAPPER END ==========',
      );

      if (!mounted || currentRequest != _requestId) {
        return;
      }

      setState(() {
        dataSource = rawData;
        allCards = mappedCards;
        _fetchError = null;
      });
    } catch (e, stackTrace) {
      debugPrint(
        '========== FERTIGATION ERROR ==========',
      );

      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted || currentRequest != _requestId) {
        return;
      }

      setState(() {
        _fetchError = e.toString();
      });
    } finally {
      if (mounted && currentRequest == _requestId) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadExcel() async {
    if (allCards.isEmpty) return;

    final multiSheetData = _buildMultiSheetData(allCards);
    final fileName = 'Fertigation_Report_${DateFormat('yyyy-MM-dd').format(_toDate)}';

    final result = await generateExcel(multiSheetData, fileName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result ? 'Excel report downloaded successfully' : 'Failed to download Excel report',
          ),
          backgroundColor: result ? const Color(0xFF006573) : Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadPdf() async {
    if (allCards.isEmpty) return;

    final multiSheetData = _buildMultiSheetData(allCards);
    final fileName = 'Fertigation_Report_${DateFormat('yyyy-MM-dd').format(_toDate)}';

    final result = await generatePdf(multiSheetData, fileName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result ? 'PDF report downloaded successfully' : 'Failed to download PDF report',
          ),
          backgroundColor: result ? const Color(0xFF006573) : Colors.red,
        ),
      );
    }
  }

  Map<String, Map<String, dynamic>> _buildMultiSheetData(List<FertigationCardModel> cards) {
    final sheetNames = ['Program Wise', 'Sequence Wise', 'Line Wise', 'Status Wise'];
    final fixedColumns = ['Program', 'Sequence', 'Line', 'Status'];
    Map<String, Map<String, dynamic>> sheetsData = {};

    for (int i = 0; i < sheetNames.length; i++) {
      String sheetName = sheetNames[i];
      String fixedCol = fixedColumns[i];

      List<String> fixedColumnData = cards.map((c) {
        switch (fixedCol) {
          case 'Program':
            return c.programName;
          case 'Sequence':
            return c.sequenceName;
          case 'Line':
            return c.lineName;
          case 'Status':
            return c.status;
          default:
            return c.programName;
        }
      }).toList();

      List<String> generalColumn = [
        'Program',
        'Sequence',
        'Line',
        'Date',
        'Status',
        'Start Time',
        'Stop Time',
        'Start Reason',
        'Stop Reason',
      ];
      List<List<dynamic>> generalColumnData = cards.map((c) => [
        c.programName,
        c.sequenceName,
        c.lineName,
        c.date,
        c.status,
        c.startTime,
        c.stopTime,
        c.startReason,
        c.stopReason,
      ]).toList();

      List<String> waterColumn = ['Method', 'Planned', 'Actual'];
      List<List<dynamic>> waterColumnData = cards.map((c) => [
        c.waterMethod,
        c.waterPlanned,
        c.waterActual,
      ]).toList();

      List<String> prePostColumn = ['Method', 'Pre Time/Qty', 'Post Time/Qty'];
      List<List<dynamic>> prePostColumnData = cards.map((c) => [
        c.preMethod,
        c.preTimeQty,
        c.postTimeQty,
      ]).toList();

      List<String> centralEcPhColumn = ['Set', 'Min', 'Max', 'Avg', 'Set', 'Min', 'Max', 'Avg'];
      List<List<dynamic>> centralEcPhColumnData = cards.map((c) => [
        c.centralEcSet,
        c.centralEcMin,
        c.centralEcMax,
        c.centralEcAvg,
        c.centralPhSet,
        c.centralPhMin,
        c.centralPhMax,
        c.centralPhAvg,
      ]).toList();

      List<String> localEcPhColumn = ['Set', 'Min', 'Max', 'Avg', 'Set', 'Min', 'Max', 'Avg'];
      List<List<dynamic>> localEcPhColumnData = cards.map((c) => [
        c.localEcSet,
        c.localEcMin,
        c.localEcMax,
        c.localEcAvg,
        c.localPhSet,
        c.localPhMin,
        c.localPhMax,
        c.localPhAvg,
      ]).toList();

      sheetsData[sheetName] = {
        'fixedColumn': fixedCol,
        'fixedColumnData': fixedColumnData,
        'generalColumn': generalColumn,
        'generalColumnData': generalColumnData,
        'waterColumn': waterColumn,
        'waterColumnData': waterColumnData,
        'prePostColumn': prePostColumn,
        'prePostColumnData': prePostColumnData,
        'centralEcPhColumn': centralEcPhColumn,
        'centralEcPhColumnData': centralEcPhColumnData,
        'localEcPhColumn': localEcPhColumn,
        'localEcPhColumnData': localEcPhColumnData,
      };
    }

    return sheetsData;
  }

  void _showDatePickerDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        DateTime tempStart = _fromDate;
        DateTime tempEnd = _toDate;

        return AlertDialog(
          title: const Text(
            'Select Date Range',
            style: TextStyle(
              color: Color(0xFF006573),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 350,
            height: 350,
            child: SfDateRangePicker(
              selectionMode:
              DateRangePickerSelectionMode.range,
              initialSelectedRange: PickerDateRange(
                _fromDate,
                _toDate,
              ),
              onSelectionChanged:
                  (DateRangePickerSelectionChangedArgs args) {
                if (args.value is PickerDateRange) {
                  final range = args.value as PickerDateRange;

                  if (range.startDate != null) {
                    tempStart = range.startDate!;
                    tempEnd =
                        range.endDate ?? range.startDate!;
                  }
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF006573),
              ),
              onPressed: () {
                setState(() {
                  _fromDate = tempStart;
                  _toDate = tempEnd;
                  _updateDateLabel();
                });

                Navigator.pop(dialogContext);

                _fetchData();
              },
              child: const Text(
                'Apply',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load Fertigation Logs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(
              _fetchError ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF006573),
        ),
      );
    }

    if (_fetchError != null) {
      return _buildErrorView();
    }

    if (allCards.isEmpty) {
      return const Center(
        child: Text(
          'No Fertigation Records Found',
          style: TextStyle(
            color: Color(0xFF637D7A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    int running = allCards.where((c) => c.status.toLowerCase().contains('run')).length;
    int skipped = allCards.where((c) => c.status.toLowerCase().contains('skip')).length;
    int completed = allCards.where((c) => c.status.toLowerCase().contains('complet')).length;
    int pending = allCards.where((c) => c.status.toLowerCase().contains('pend')).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Overall Fertigation Status Summary at the top
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF006573).withValues(alpha: 0.2), width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fertigation Status Summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF006573)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF4F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statusCountItem('Running', running, Colors.orange),
                      _statusCountItem('Skipped', skipped, Colors.blueGrey),
                      _statusCountItem('Completed', completed, Colors.green),
                      _statusCountItem('Pending', pending, Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 2. Card View | Table View toggle
          Center(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Card View'),
                  icon: Icon(Icons.grid_view),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Table View'),
                  icon: Icon(Icons.table_chart),
                ),
              ],
              selected: {_isTableView},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isTableView = newSelection.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF006573);
                  }
                  return Colors.white;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return const Color(0xFF006573);
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 3. Selected report view
          _isTableView
              ? FertigationTableView(cards: allCards)
              : ProgramWiseView(cards: allCards),
        ],
      ),
    );
  }

  Widget _statusCountItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006573),
        title: const Text(
          'Fertilizer Log',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: Text(
                _selectedDateStr,
                style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          ),
          IconButton(
            icon: const Icon(
              Icons.date_range,
              color: Colors.white,
            ),
            tooltip: 'Select Date Range',
            onPressed: _showDatePickerDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.download,
              color: Colors.white,
            ),
            tooltip: 'Download Report',
            enabled: !_isLoading && allCards.isEmpty == false,
            onSelected: (value) {
              if (value == 'excel') _downloadExcel();
              if (value == 'pdf') _downloadPdf();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Color(0xFF006573)),
                    SizedBox(width: 8),
                    Text('Download Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Download PDF'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _fetchData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
