import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../../models/customer/site_model.dart';
import '../../../services/http_service.dart';
import '../model/event_log_model.dart';
import '../model/pump_log_data.dart';
import '../repository/log_repos.dart';

class ValveLogScreen extends StatefulWidget {
  final int userId, controllerId, nodeControllerId;
  final MasterControllerModel masterData;
  const ValveLogScreen({
    super.key,
    required this.userId,
    required this.controllerId,
    this.nodeControllerId = 0,
    required this.masterData,
  });

  @override
  State<ValveLogScreen> createState() => _ValveLogScreenState();
}

class _ValveLogScreenState extends State<ValveLogScreen> {
  DateTime _pickerStartDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _pickerEndDate = DateTime.now();

  DateTime _tempStart = DateTime.now();
  DateTime _tempEnd = DateTime.now();

  bool isLoading = false;
  List<PumpLogData> pumpLogDataList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchValveLogs();
    });
  }

  Future<void> fetchValveLogs() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final formatter = DateFormat('yyyy-MM-dd');
      final body = {
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "nodeControllerId": widget.nodeControllerId,
        "fromDate": formatter.format(_pickerStartDate),
        "toDate": formatter.format(_pickerEndDate),
      };

      final bool isNode = widget.nodeControllerId != 0 &&
          widget.nodeControllerId != widget.controllerId;
      final res = await LogRepository(HttpService()).getUserPumpLog(body, isNode);

      if (res.statusCode == 200) {
        final response = jsonDecode(res.body);
        if (response['data'] != null) {
          final rawData = response['data'];
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
          pumpLogDataList = rawList
              .map((i) => PumpLogData.fromJson(Map<String, dynamic>.from(i as Map)))
              .toList();
        } else {
          pumpLogDataList = [];
        }
      } else {
        pumpLogDataList = [];
      }
    } catch (e) {
      debugPrint('Error fetching valve logs: $e');
      pumpLogDataList = [];
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    if (args.value is PickerDateRange) {
      final PickerDateRange range = args.value as PickerDateRange;
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
          title: const Text('Select Date Range'),
          content: SizedBox(
            width: 320,
            height: 320,
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColorDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                setState(() {
                  _pickerStartDate = _tempStart;
                  _pickerEndDate = _tempEnd;
                });
                await fetchValveLogs();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  String _getValveName(EventLog event) {
    try {
      final valves = widget.masterData.configObjects
          .where((e) => e.objectId == 13)
          .map((e) => e.name)
          .toList();
      final index = int.parse(event.onReason.split(' ')[0].substring(5)) - 1;
      if (index >= 0 && index < valves.length) {
        return valves[index];
      }
    } catch (_) {}
    return "Valve";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rangeText =
        '${DateFormat('dd/MM/yyyy').format(_pickerStartDate)} - ${DateFormat('dd/MM/yyyy').format(_pickerEndDate)}';

    // Flatten and group all valve events by date
    Map<String, List<Map<String, dynamic>>> groupedByDate = {};
    for (var logData in pumpLogDataList) {
      final dateStr = logData.date;
      final valveEvents = [
        ...logData.motor1.where((e) => e.isValve),
        ...logData.motor2.where((e) => e.isValve),
        ...logData.motor3.where((e) => e.isValve),
      ];
      if (valveEvents.isNotEmpty) {
        groupedByDate.putIfAbsent(dateStr, () => []);
        for (var event in valveEvents) {
          groupedByDate[dateStr]!.add({
            'valveName': _getValveName(event),
            'event': event,
          });
        }
      }
    }

    final dateKeys = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Valve Log',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showDatePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range, size: 16, color: theme.primaryColorDark),
                          const SizedBox(width: 6),
                          Text(
                            rangeText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColorDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: Icon(Icons.refresh, color: theme.primaryColorDark),
                    onPressed: fetchValveLogs,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Grouped Tables by Date
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : dateKeys.isEmpty
                      ? const Center(
                          child: Text(
                            'There is no valve log data for the selected range',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: dateKeys.length,
                          itemBuilder: (context, dateIndex) {
                            final dateStr = dateKeys[dateIndex];
                            final rows = groupedByDate[dateStr]!;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Section Header
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColorDark.withAlpha(20),
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey.shade200),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: theme.primaryColorDark),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Date: $dateStr',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: theme.primaryColorDark,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColorDark,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${rows.length} ${rows.length == 1 ? 'Cycle' : 'Cycles'}',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Table for this date
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(2.5),
                                      1: FlexColumnWidth(1.5),
                                      2: FlexColumnWidth(1.5),
                                      3: FlexColumnWidth(1.5),
                                    },
                                    border: TableBorder(
                                      horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
                                    ),
                                    children: [
                                      TableRow(
                                        decoration: BoxDecoration(
                                          color: theme.primaryColorLight.withAlpha(30),
                                        ),
                                        children: const [
                                          Padding(padding: EdgeInsets.all(12), child: Text('Valve Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Padding(padding: EdgeInsets.all(12), child: Text('ON Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Padding(padding: EdgeInsets.all(12), child: Text('OFF Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Padding(padding: EdgeInsets.all(12), child: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        ],
                                      ),
                                      ...rows.map((row) {
                                        final String valveName = row['valveName'];
                                        final EventLog event = row['event'];

                                        return TableRow(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.water_drop_outlined, size: 15, color: Colors.blue),
                                                  const SizedBox(width: 6),
                                                  Text(valveName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                            Padding(padding: const EdgeInsets.all(12), child: Text(event.onTime, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13))),
                                            Padding(padding: const EdgeInsets.all(12), child: Text(event.offTime, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13))),
                                            Padding(padding: const EdgeInsets.all(12), child: Text(event.duration, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
