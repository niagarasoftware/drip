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
  State<FertigationCardListPage> createState() => _FertigationCardListPageState();
}

class _FertigationCardListPageState extends State<FertigationCardListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  dynamic dataSource = {};
  List<FertigationCardModel> allCards = [];
  String _selectedDateStr = '';
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedDateStr = '${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatNumber(int number) => number.toString().padLeft(2, '0');

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String formattedDate1 = "${_fromDate.year}-${_formatNumber(_fromDate.month)}-${_formatNumber(_fromDate.day)}";
      String formattedDate2 = "${_toDate.year}-${_formatNumber(_toDate.month)}-${_formatNumber(_toDate.day)}";

      var body = {
        "userId": widget.userData['customerId'],
        "controllerId": widget.userData['controllerId'],
        "logType": "Irrigation",
        "fromDate": formattedDate1,
        "toDate": formattedDate2,
      };

      var response = await IrrigationRepository().getLogDateWise(body);
      Map<String, dynamic> jsonData = jsonDecode(response.body);

      if (jsonData['code'] == 200) {
        dataSource = jsonData['data'];
        allCards = FertigationCardMapper.mapLogData(dataSource, widget.nameData);
      } else {
        allCards = FertigationCardMapper.mapLogData(null, widget.nameData);
      }
    } catch (e) {
      allCards = FertigationCardMapper.mapLogData(null, widget.nameData);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDatePickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        DateTime tempStart = _fromDate;
        DateTime tempEnd = _toDate;
        return AlertDialog(
          title: const Text('Select Date Range', style: TextStyle(color: Color(0xFF006573), fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 350,
            height: 350,
            child: SfDateRangePicker(
              selectionMode: DateRangePickerSelectionMode.range,
              initialSelectedRange: PickerDateRange(_fromDate, _toDate),
              onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                if (args.value is PickerDateRange) {
                  if (args.value.startDate != null) {
                    tempStart = args.value.startDate!;
                    tempEnd = args.value.endDate ?? args.value.startDate!;
                  }
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006573)),
              onPressed: () {
                setState(() {
                  _fromDate = tempStart;
                  _toDate = tempEnd;
                  _selectedDateStr = '${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}';
                });
                Navigator.pop(context);
                _fetchData();
              },
              child: const Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8), // Page background
      appBar: AppBar(
        backgroundColor: const Color(0xFF006573), // Primary teal
        title: const Text('Fertilizer Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _selectedDateStr,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            tooltip: 'Select Date Range',
            onPressed: _showDatePickerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _fetchData,
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
            Tab(text: 'Program-wise'),
            Tab(text: 'Sequence-wise'),
            Tab(text: 'Line-wise'),
            Tab(text: 'Status-wise'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF006573)))
          : TabBarView(
              controller: _tabController,
              children: [
                ProgramWiseView(cards: allCards),
                SequenceWiseView(cards: allCards),
                LineWiseView(cards: allCards),
                StatusWiseView(cards: allCards),
              ],
            ),
    );
  }
}
