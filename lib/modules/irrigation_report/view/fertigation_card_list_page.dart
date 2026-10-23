
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../model/fertigation_card_model.dart';
import '../repository/irrigation_repository.dart';
import '../services/fertigation_card_mapper.dart';

import 'widgets/program_wise_view.dart';
import 'widgets/sequence_wise_view.dart';
import 'widgets/line_wise_view.dart';
import 'widgets/status_wise_view.dart';

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
    extends State<FertigationCardListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoading = false;
  String? _fetchError;

  dynamic dataSource = {};
  List<FertigationCardModel> allCards = [];

  String _selectedDateStr = '';

  DateTime _fromDate =
  DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

  int _requestId = 0;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 4,
      vsync: this,
    );

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
    _tabController.dispose();
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

      final List<FertigationCardModel> mappedCards =
      FertigationCardMapper.mapLogData(
        rawData,
        widget.nameData,
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

    return TabBarView(
      controller: _tabController,
      children: [
        ProgramWiseView(cards: allCards),
        SequenceWiseView(cards: allCards),
        LineWiseView(cards: allCards),
        StatusWiseView(cards: allCards),
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
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _fetchData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Program'),
            Tab(text: 'Sequence'),
            Tab(text: 'Line'),
            Tab(text: 'Status'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }
}
