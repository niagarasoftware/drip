import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_date_range_picker/flutter_date_range_picker.dart';
import 'package:oro_drip_irrigation/Constants/data_convertion.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/preview_screen.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import '../../../Widgets/custom_buttons.dart';
import '../repository/irrigation_repository.dart';
import 'log_home.dart';


class FertilizerPumpRuntimeLog extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FertilizerPumpRuntimeLog({super.key, required this.userData});

  @override
  State<FertilizerPumpRuntimeLog> createState() => _FertilizerPumpRuntimeLogState();
}

class _FertilizerPumpRuntimeLogState extends State<FertilizerPumpRuntimeLog> {
  DateTime? selectedDate;
  String _selectedDate = '';
  String _dateCount = '';
  String _range = '';
  String _rangeCount = '';
  DateRange? selectedDateRange;

  Map<String, dynamic> data = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        // getData();
      }
    });
  }

  String _formatNumber(int number) {
    // Add leading zero if the number is less than 10
    return number.toString().padLeft(2, '0');
  }

  // void getData()async{
  //   print('data request to the server.............');
  //   DateTime now = DateTime.now();
  //   String formattedDate = DateFormat('dd/MM/yyyy').format(now);
  //   print('_selectedDate : $_selectedDate');
  //   _selectedDate = _selectedDate == '' ? '$formattedDate - $formattedDate' : _selectedDate;
  //   print('_selectedDate : $_selectedDate');
  //   String dateString1 = _selectedDate.split(' - ')[0];
  //   String dateString2 = _selectedDate.split(' - ')[1];
  //   print("dateString2 ==> $dateString2");
  //
  //   List<String> parts1 = dateString1.split('/');
  //   List<String> parts2 = dateString2.split('/');
  //
  //   // Create DateTime objects
  //   DateTime date1 = DateTime(int.parse(parts1[2]), int.parse(parts1[1]), int.parse(parts1[0]));
  //   DateTime date2 = DateTime(int.parse(parts2[2]), int.parse(parts2[1]), int.parse(parts2[0]));
  //
  //   // Format DateTime objects into desired format
  //   String formattedDate1 = "${date1.year}-${_formatNumber(date1.month)}-${_formatNumber(date1.day)}";
  //   String formattedDate2 = "${date2.year}-${_formatNumber(date2.month)}-${_formatNumber(date2.day)}";
  //
  //   try{
  //     String? startMonth = selectedDateRange?.start.month.toString();
  //     print('startMonth : $startMonth');
  //
  //     String? startday = selectedDateRange?.start.day.toString();
  //     String? endMonth = selectedDateRange?.end.month.toString();
  //     String? endday = selectedDateRange?.end.day.toString();
  //     var body = {
  //       "userId": widget.userData['customerId'],
  //       "controllerId": widget.userData['controllerId'],
  //       "logType" : "IrrigationMotorCyclic",
  //       "fromDate" : formattedDate1,
  //       "toDate" : formattedDate2,
  //     };
  //     var response = await IrrigationRepository().getNovaLogDateWise(body);
  //     Map<String, dynamic> jsonData = jsonDecode(response.body);
  //     print('jsonData $jsonData');
  //     if(jsonData['code'] == 200){
  //       setState(() {
  //         data = jsonData;
  //       });
  //     }
  //
  //   }catch(e,stackTrace){
  //     print('error in log = > ${e.toString()}');
  //     print('error in log stackTrace= > $stackTrace');
  //   }
  // }
  //
  // void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
  //   print('args : ${args}');
  //   setState(() {
  //     if (args.value is PickerDateRange) {
  //       _selectedDate  = '${DateFormat('dd/MM/yyyy').format(args.value.startDate)} -'
  //           ' ${DateFormat('dd/MM/yyyy').format(args.value.endDate ?? args.value.startDate)}';
  //
  //       print('_selectedDate : $_selectedDate');
  //     } else if (args.value is DateTime) {
  //       _selectedDate = args.value.toString();
  //     } else if (args.value is List<DateTime>) {
  //       _dateCount = args.value.length.toString();
  //     } else {
  //       _rangeCount = args.value.length.toString();
  //     }
  //     print("range: ${_range},rangecount:${_rangeCount},Select date:${_selectedDate}");
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: data.isEmpty ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: SingleChildScrollView(
            child: Column(
              spacing: 10,
              children: [
                const SizedBox(height: 1,),
                for(var i = 0; i < 3;i++)
                  Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    boxShadow: customBoxShadow
                  ),
                  child: Row(
                    spacing: 20,
                    children: [
                      Container(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        child: Image.asset(
                            'assets/Images/Png/objectId_${AppConstants.boosterObjectId}.png',
                          width: 70,
                          height: 100,
                        ),
                        padding: EdgeInsets.all(5),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            getTitleValue(title: 'Zone 001', value: 'FERT PUMP1'),
                            getTitleValue(title: 'Total Flow', value: '1368 Lts', valueColor: Colors.black45),
                            getTitleValue(title: 'Start Time', value: '10:53:15', valueColor: Colors.black45),
                            getTitleValue(title: 'End Time', value: '14:58:01', valueColor: Colors.black45),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ) : Center(
        child: Text('There is no data in $_selectedDate'),
      ),
    );
  }

  Widget getTitleValue({required String title, required String value, Color? titleColor, Color? valueColor, double? fontSize}){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize ?? 13, color: titleColor ?? Colors.black),),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize ?? 13, color: valueColor ?? Colors.black),),
      ],
    );
  }

  Widget getDivider({Color? color}){
    return SizedBox(
      height: 30,
      child: VerticalDivider(
        thickness: 1,
        color: color ?? Colors.black,
      ),
    );
  }

}
