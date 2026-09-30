import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_date_range_picker/flutter_date_range_picker.dart';
import 'package:oro_drip_irrigation/Constants/data_convertion.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import '../../../Widgets/custom_buttons.dart';
import '../repository/irrigation_repository.dart';
import 'log_home.dart';

class ZoneCyclicLog extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ZoneCyclicLog({super.key, required this.userData});

  @override
  State<ZoneCyclicLog> createState() => _ZoneCyclicLogState();
}

class _ZoneCyclicLogState extends State<ZoneCyclicLog> {
  DateTime? selectedDate;
  String _selectedDate = '';
  String _dateCount = '';
  final String _range = '';
  String _rangeCount = '';
  DateRange? selectedDateRange;

  DateTime _pickerStartDate = DateTime.now();
  DateTime _pickerEndDate = DateTime.now();

  Map<String, dynamic> data = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        getData();
      }
    });
  }

  String _formatNumber(int number) {
    // Add leading zero if the number is less than 10
    return number.toString().padLeft(2, '0');
  }

  void getData() async {
    debugPrint('data request to the server.............');
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy').format(now);
    debugPrint('_selectedDate : $_selectedDate');
    _selectedDate =
        _selectedDate == '' ? '$formattedDate - $formattedDate' : _selectedDate;
    debugPrint('_selectedDate : $_selectedDate');
    String dateString1 = _selectedDate.split(' - ')[0];
    String dateString2 = _selectedDate.split(' - ')[1];
    debugPrint("dateString2 ==> $dateString2");

    List<String> parts1 = dateString1.split('/');
    List<String> parts2 = dateString2.split('/');

    // Create DateTime objects
    DateTime date1 = DateTime(
        int.parse(parts1[2]), int.parse(parts1[1]), int.parse(parts1[0]));
    DateTime date2 = DateTime(
        int.parse(parts2[2]), int.parse(parts2[1]), int.parse(parts2[0]));

    // Format DateTime objects into desired format
    String formattedDate1 =
        "${date1.year}-${_formatNumber(date1.month)}-${_formatNumber(date1.day)}";
    String formattedDate2 =
        "${date2.year}-${_formatNumber(date2.month)}-${_formatNumber(date2.day)}";

    try {
      String? startMonth = selectedDateRange?.start.month.toString();
      debugPrint('startMonth : $startMonth');

      var body = {
        "userId": widget.userData['customerId'],
        "controllerId": widget.userData['controllerId'],
        "logType": "IrrigationZoneCyclic",
        "fromDate": formattedDate1,
        "toDate": formattedDate2,
      };
      var response = await IrrigationRepository().getNovaLogDateWise(body);
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      debugPrint('jsonData $jsonData');
      if (jsonData['code'] == 200) {
        setState(() {
          data = jsonData['data'];
        });
      }
    } catch (e, stackTrace) {
      debugPrint('error in log = > ${e.toString()}');
      debugPrint('error in log stackTrace= > $stackTrace');
    }
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    debugPrint('args : $args');
    setState(() {
      if (args.value is PickerDateRange) {
        final PickerDateRange range = args.value as PickerDateRange;
        final DateTime start = range.startDate ?? DateTime.now();
        // If the user has only tapped a single date, endDate will be
        // null. Fall back to start so it's treated as a one-day range
        // instead of silently reverting to today's date.
        final DateTime end = range.endDate ?? start;

        _pickerStartDate = start;
        _pickerEndDate = end;

        _selectedDate = '${DateFormat('dd/MM/yyyy').format(start)} -'
            ' ${DateFormat('dd/MM/yyyy').format(end)}';

        debugPrint('_selectedDate : $_selectedDate');
      } else if (args.value is DateTime) {
        final DateTime picked = args.value as DateTime;
        _pickerStartDate = picked;
        _pickerEndDate = picked;
        _selectedDate = picked.toString();
      } else if (args.value is List<DateTime>) {
        _dateCount = args.value.length.toString();
      } else {
        _rangeCount = args.value.length.toString();
      }
      debugPrint(
          "range: $_range,rangecount:$_rangeCount,Select date:$_selectedDate");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Date Picker'),
                  content: StatefulBuilder(
                    builder: (BuildContext context, StateSetter stateSetter) {
                      return SizedBox(
                        width: 200,
                        height: 250,
                        child: SfDateRangePicker(
                          onSelectionChanged: _onSelectionChanged,
                          selectionMode: DateRangePickerSelectionMode.range,
                          // Use the last-selected dates instead of hardcoding
                          // DateTime.now() every time the dialog is opened.
                          initialSelectedRange: PickerDateRange(
                            _pickerStartDate,
                            _pickerEndDate,
                          ),
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
                      onPressed: () async {
                        Navigator.pop(context);
                        getDialog(context);
                        getData();
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                );
              });
        },
        child: const Icon(Icons.date_range),
      ),
      body: data.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 10,
                    children: [
                      const SizedBox(
                        height: 1,
                      ),
                      for (var date in data["zoneCyclic"])
                        dateWiseBox(data: date),
                      const SizedBox(
                        height: 100,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Center(
              child: Text('There is no data in $_selectedDate'),
            ),
    );
  }

  Widget getTitleValue(
      {required String title,
      required String value,
      Color? titleColor,
      Color? valueColor,
      double? fontSize}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize ?? 13,
              color: titleColor ?? Colors.black),
        ),
        Text(
          value,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize ?? 13,
              color: valueColor ?? Colors.black),
        ),
      ],
    );
  }

  Widget dateWiseBox({
    required Map<String, dynamic> data,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        spacing: 8,
        children: [
          getTitleValue(
              title: 'Date',
              value: data["date"],
              titleColor: Colors.white,
              valueColor: Colors.white),
          getTitleValue(
              title: 'Cyclic duration',
              value: getCyclicDuration(data: data),
              titleColor: Colors.white,
              valueColor: Colors.white),
          getTitleValue(
              title: 'Cyclic flow',
              value: getCyclicFlow(data: data),
              titleColor: Colors.white,
              valueColor: Colors.white),
          getTitleValue(
              title: 'Cyclic time',
              value:
                  '${data["zoneList"][0]["onTime"]} to ${data["zoneList"][data["zoneList"].length - 1]["offTime"]}',
              titleColor: Colors.white,
              valueColor: Colors.white),
          Column(
            spacing: 10,
            children: [
              for (var zoneData in data["zoneList"]) zoneBox(zoneData: zoneData)
            ],
          ),
        ],
      ),
    );
  }

  String getCyclicDuration({
    required Map<String, dynamic> data,
  }) {
    DataConvert dataConvert = DataConvert();
    int totalSeconds = 0;
    for (var zoneData in data['zoneList']) {
      totalSeconds += dataConvert.parseTimeString(zoneData["duration"]);
    }
    return dataConvert.formatTime(totalSeconds);
  }

  String getCyclicFlow({required Map<String, dynamic> data}) {
    double totalFlow = 0;
    for (var zoneData in data['zoneList']) {
      totalFlow += double.parse(zoneData["flow"]);
    }
    return totalFlow.toString();
  }

  Widget zoneBox({
    required Map<String, dynamic> zoneData,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          height: 30,
          color: Theme.of(context).primaryColorDark,
          child: Row(
            children: [
              Expanded(
                  child: getTitleValue(
                      title: 'Program',
                      value: zoneData["program"],
                      titleColor: Colors.white,
                      valueColor: Colors.white)),
              getDivider(color: Colors.white),
              Expanded(
                  child: getTitleValue(
                      title: 'Zone',
                      value: zoneData["zone"],
                      titleColor: Colors.white,
                      valueColor: Colors.white)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5))),
          child: Column(
            spacing: 10,
            children: [
              Row(
                children: [
                  Expanded(
                      child: getTitleValue(
                          title: 'Set Time',
                          value: zoneData["setTime"],
                          fontSize: 12,
                          titleColor: Colors.black54)),
                  getDivider(),
                  Expanded(
                      child: getTitleValue(
                          title: 'Run Time',
                          value: zoneData["duration"],
                          fontSize: 12,
                          titleColor: Colors.black54))
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: getTitleValue(
                          title: 'Set Flow',
                          value: zoneData["setFlow"],
                          fontSize: 12,
                          titleColor: Colors.black54)),
                  getDivider(),
                  Expanded(
                      child: getTitleValue(
                          title: 'Run Flow',
                          value: zoneData["flow"],
                          fontSize: 12,
                          titleColor: Colors.black54))
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: getTitleValue(
                          title: 'Start Time',
                          value: zoneData["onTime"],
                          fontSize: 12,
                          titleColor: Colors.black54)),
                  getDivider(),
                  Expanded(
                      child: getTitleValue(
                          title: 'End Time',
                          value: zoneData["offTime"],
                          fontSize: 12,
                          titleColor: Colors.black54))
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: getTitleValue(
                          title: 'Prs In',
                          value: zoneData["pressureIn"],
                          fontSize: 12,
                          titleColor: Colors.black54)),
                  getDivider(),
                  Expanded(
                      child: getTitleValue(
                          title: 'Prs Out',
                          value: zoneData["pressureOut"],
                          fontSize: 12,
                          titleColor: Colors.black54))
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: getTitleValue(
                          title: 'Well Level',
                          value: zoneData["wellLevel"],
                          fontSize: 12,
                          titleColor: Colors.black54)),
                  getDivider(),
                  Expanded(
                      child: getTitleValue(
                          title: 'Percentage',
                          value: zoneData["wellPercentage"],
                          fontSize: 12,
                          titleColor: Colors.black54))
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: getTitleValue(
                          title: 'Ec',
                          value: zoneData["ec"],
                          fontSize: 12,
                          titleColor: Colors.black54)),
                  getDivider(),
                  Expanded(
                      child: getTitleValue(
                          title: 'pH',
                          value: zoneData["ph"],
                          fontSize: 12,
                          titleColor: Colors.black54))
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget getDivider({Color? color}) {
    return SizedBox(
      height: 30,
      child: VerticalDivider(
        thickness: 1,
        color: color ?? Colors.black,
      ),
    );
  }
}
