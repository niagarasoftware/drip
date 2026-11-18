import 'dart:convert';
import 'package:flutter/material.dart';
import '../repository/irrigation_repository.dart';

class OmsLogEntry {
  final String sequence;
  final String irrigationMethodRaw;
  final String irrigationMethod;
  final String actual;
  final String planned;

  OmsLogEntry({
    required this.sequence,
    required this.irrigationMethodRaw,
    required this.irrigationMethod,
    required this.actual,
    required this.planned,
  });

  factory OmsLogEntry.fromRow(String row) {
    final parts = row.split(',');
    final methodCode = parts.length > 1 ? parts[1] : '';
    return OmsLogEntry(
      sequence: parts.isNotEmpty ? parts[0] : '',
      irrigationMethodRaw: methodCode,
      irrigationMethod: _methodLabel(methodCode),
      actual: parts.length > 2 ? parts[2] : '',
      planned: parts.length > 3 ? parts[3] : '',
    );
  }

  // Adjust labels here if your backend defines more/other method codes.
  static String _methodLabel(String code) {
    switch (code) {
      case '1':
        return 'Time';
      case '2':
        return 'Volume';
      default:
        return code.isEmpty ? '-' : code;
    }
  }
}

class OmsDeviceLog {
  final String deviceName;
  final String logDate;
  final List<OmsLogEntry> entries;

  OmsDeviceLog({
    required this.deviceName,
    required this.logDate,
    required this.entries,
  });

  factory OmsDeviceLog.fromJson(Map<String, dynamic> json) {
    final List<OmsLogEntry> entries = [];
    final List<dynamic> omsLogList = json['omsLog'] ?? [];

    for (final logString in omsLogList) {
      if (logString is! String || logString.trim().isEmpty) continue;
      final rows = logString.split(';');
      for (final row in rows) {
        if (row.trim().isEmpty) continue;
        entries.add(OmsLogEntry.fromRow(row));
      }
    }

    return OmsDeviceLog(
      deviceName: json['deviceName']?.toString() ?? '',
      logDate: json['logDate']?.toString() ?? '',
      entries: entries,
    );
  }
}

class OmsLog extends StatefulWidget {
  final int userId;
  final int controllerId;
  final int nodeControllerId;
  final DateTime? initialDate;
  final String logType;

  const OmsLog({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.nodeControllerId,
    this.initialDate,
    this.logType = 'AllNode',
  });

  @override
  State<OmsLog> createState() => _OmsLogState();
}

class _OmsLogState extends State<OmsLog> {
  final IrrigationRepository _repository = IrrigationRepository();

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  late DateTime _selectedDate;
  bool _isLoading = true;
  String? _errorMessage;
  List<OmsDeviceLog> _deviceLogs = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _fetchOmsLog();
  }

  String _apiDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  String _displayDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthNames[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null &&
        (picked.year != _selectedDate.year ||
            picked.month != _selectedDate.month ||
            picked.day != _selectedDate.day)) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchOmsLog();
    }
  }

  Future<void> _fetchOmsLog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateStr = _apiDate(_selectedDate);
      final body = {
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "nodeControllerId": widget.nodeControllerId,
        "fromDate": dateStr,
        "toDate": dateStr,
        "logType": widget.logType,
      };

      final response = await _repository.getOmsLog(body);
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic> && decoded['code'] == 200) {
        final List<dynamic> data = decoded['data'] ?? [];

        setState(() {
          _deviceLogs = data
              .whereType<Map<String, dynamic>>()
              .map((e) => OmsDeviceLog.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
      else {
        setState(() {
          _errorMessage = decoded is Map<String, dynamic>
              ? (decoded['message']?.toString() ?? 'Something went wrong')
              : 'Something went wrong';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load logs. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildDateSelector(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, size: 18, color: Colors.teal),
            const SizedBox(width: 10),
            Text(
              _displayDate(_selectedDate),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchOmsLog,
                child: const Text('Retry', style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      );
    }

    if (_deviceLogs.isEmpty) {
      return const Center(child: Text('No logs found for this range'));
    }

    return RefreshIndicator(
      onRefresh: _fetchOmsLog,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _deviceLogs.length,
        itemBuilder: (context, index) => _DeviceLogCard(device: _deviceLogs[index]),
      ),
    );
  }
}

class _DeviceLogCard extends StatelessWidget {
  final OmsDeviceLog device;

  const _DeviceLogCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop_outlined, size: 18, color: Colors.teal),
                    const SizedBox(width: 6),
                    Text(
                      device.deviceName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  device.logDate,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (device.entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No entries', style: TextStyle(color: Colors.grey)),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 38,
                  dataRowMinHeight: 34,
                  dataRowMaxHeight: 40,
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF0F2F5)),
                  columns: const [
                    DataColumn(label: Text('Sequence')),
                    DataColumn(label: Text('Irrigation Method')),
                    DataColumn(label: Text('Actual')),
                    DataColumn(label: Text('Planned')),
                  ],
                  rows: device.entries
                      .map((e) => DataRow(cells: [
                    DataCell(Text(e.sequence)),
                    DataCell(Text(e.irrigationMethod)),
                    DataCell(Text(e.actual)),
                    DataCell(Text(e.planned)),
                  ]))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}