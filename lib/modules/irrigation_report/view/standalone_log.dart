import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_date_range_picker/flutter_date_range_picker.dart';
import 'package:intl/intl.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:oro_drip_irrigation/Widgets/custom_buttons.dart';
import 'package:oro_drip_irrigation/modules/irrigation_report/view/scrollingTable.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../repository/irrigation_repository.dart';
import 'log_home.dart';
import 'package:excel/excel.dart';


class StandaloneLog extends StatefulWidget {
  final Map<String, dynamic> userData;
  const StandaloneLog({super.key, required this.userData});

  @override
  State<StandaloneLog> createState() => _StandaloneLogState();
}

class _StandaloneLogState extends State<StandaloneLog> {
  late LinkedScrollControllerGroup _scrollable1;
  late ScrollController _verticalScroll1;
  late ScrollController _verticalScroll2;
  late LinkedScrollControllerGroup _scrollable2;
  late ScrollController _horizontalScroll1;
  late ScrollController _horizontalScroll2;
  List<String> standaloneColumn = ['Program','Method','Start Time','Zone Name','Device Id','Others'];
  String _selectedDate = '';
  DateRange? selectedDateRange;
  DateRange? lastSelectedDateRange;
  List<dynamic> parameters = [
    'Date','ProgramCategory','SequenceData','ScheduledStartTime','S_No','ZoneName','IrrigationMethod','MacAddress'
  ];
  dynamic standaloneData = {
    'fixedColumnData' : [],
    'standaloneColumnData' : []
  };
  List<dynamic> configObject = [];
  int httpError = 0;
  int noOfRowsPerPage = 20;
  int totalPages = 0;
  int selectedPages = 1;
  final String _range = '';
  String _rangeCount = '';
  String _dateCount = '';

  @override
  void initState() {
    _scrollable1 = LinkedScrollControllerGroup();
    _verticalScroll1 = _scrollable1.addAndGet();
    _verticalScroll2 = _scrollable1.addAndGet();
    _scrollable2 = LinkedScrollControllerGroup();
    _horizontalScroll1 = _scrollable2.addAndGet();
    _horizontalScroll2 = _scrollable2.addAndGet();
    getUserName();
    getStandaloneData();

    super.initState();
  }
  String _formatNumber(int number) {
    // Add leading zero if the number is less than 10
    return number.toString().padLeft(2, '0');
  }


  void getUserName()async{
    try{
      var body = {
        "userId": widget.userData['customerId'],
        "controllerId": widget.userData['controllerId'],
      };
      var response = await IrrigationRepository().getUserNames(body);
      Map<String, dynamic> configData = jsonDecode(response.body);
      print("jsonData : $configData");
      configObject = configData['data']['configObject'];

    }catch(e,stackTrace){
      print('error in name = > ${e.toString()}');
      print('error in name stackTrace= > $stackTrace');
    }
  }

  void getStandaloneData()async{
    print('data request to the server.............');
    setState(() {
      standaloneData['fixedColumnData'] = [];
      standaloneData['standaloneColumnData'] = [];
    });
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy').format(now);
    _selectedDate = _selectedDate == '' ? '$formattedDate - $formattedDate' : _selectedDate;
    String dateString1 = _selectedDate.split(' - ')[0];
    String dateString2 = _selectedDate.split(' - ')[1];

    List<String> parts1 = dateString1.split('/');
    List<String> parts2 = dateString2.split('/');

    // Create DateTime objects
    DateTime date1 = DateTime(int.parse(parts1[2]), int.parse(parts1[1]), int.parse(parts1[0]));
    DateTime date2 = DateTime(int.parse(parts2[2]), int.parse(parts2[1]), int.parse(parts2[0]));

    // Format DateTime objects into desired format
    String formattedDate1 = "${date1.year}-${_formatNumber(date1.month)}-${_formatNumber(date1.day)}";
    String formattedDate2 = "${date2.year}-${_formatNumber(date2.month)}-${_formatNumber(date2.day)}";
    try{
      String? startMonth = selectedDateRange?.start.month.toString();
      print('startMonth : $startMonth');

      String? startday = selectedDateRange?.start.day.toString();
      String? endMonth = selectedDateRange?.end.month.toString();
      String? endday = selectedDateRange?.end.day.toString();
      var body = {
        "userId": widget.userData['customerId'],
        "controllerId": widget.userData['controllerId'],
        "logType" : "Standalone",
        "fromDate" : formattedDate1,
        "toDate" : formattedDate2,
        "parameters" : parameters,
      };
      var response = await IrrigationRepository().getLogDateWise(body);
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      // standaloneData = jsonData['data'];
      setState(() {
        print('jsonData : $jsonData');
        var standaloneDataFromHttp = jsonData['data']['log'];
        for(var date = 0;date < standaloneDataFromHttp.length;date++){
          for(var schedule = 0;schedule < standaloneDataFromHttp[date]['standalone']['Date'].length;schedule++){
            standaloneData['fixedColumnData'].add(standaloneDataFromHttp[date]['standalone']['Date'][schedule]);
            var list = [];
            list.add(standaloneDataFromHttp[date]['standalone']['ProgramCategory'][schedule]);
            var method = standaloneDataFromHttp[date]['standalone']['IrrigationMethod'][schedule];
            list.add(method == 1 ? 'Time' : method == 2 ? 'Flow' : 'TimeLess');
            list.add(standaloneDataFromHttp[date]['standalone']['ScheduledStartTime'][schedule]);
            list.add(standaloneDataFromHttp[date]['standalone']['ZoneName'][schedule]);
            list.add(standaloneDataFromHttp[date]['standalone']['MacAddress'][schedule]);
            var valveName = '';
            for(var valve in standaloneDataFromHttp[date]['standalone']['SequenceData'][schedule].split('_')){
              valveName += valveName.isNotEmpty ? '__' : '';
              var objectData = configObject.firstWhere(
                    (element) => element['sNo'].toString() == valve,
                orElse: () => null,
              );
              valveName += '${objectData != null ? objectData['name'] : valve}';
            }
            list.add(valveName);
            standaloneData['standaloneColumnData'].add(list);
          }
        }
      });
      setState(() {
        httpError = 0;
      });
      setState(() {
        totalPages = (standaloneData['fixedColumnData'].length ~/ noOfRowsPerPage);
        if ((totalPages * noOfRowsPerPage) < standaloneData['fixedColumnData'].length) {
          totalPages += 1;
        }
        selectedPages = 1;
      });
    }catch(e,stackTrace){
      setState(() {
        httpError = 1;
      });
      print('error in log = > ${e.toString()}');
      print('error in log stackTrace= > $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Material(
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20),bottomLeft: Radius.circular(20))
              ),
              margin: const EdgeInsets.only(left: 5,right: 5),
              child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                var width = constraints.maxWidth;
                return Row(
                  children: [
                    Column(
                      children: [
                        //Todo : first column
                        Container(
                          // color: Color(0xffF7F9FA),
                          decoration: BoxDecoration(
                              color: Theme.of(context).primaryColorDark
                          ),
                          padding: const EdgeInsets.only(left: 8),
                          width: 100,
                          height: 50,
                          alignment: Alignment.center,
                          child: const Text('Date',style: TextStyle(color: Colors.white),),
      
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _verticalScroll1,
                            child: Container(
                              child: Row(
                                children: [
                                  Column(
                                    children: [
                                      for(var i in filterDataByPages(data : standaloneData['fixedColumnData']))
                                        Container(
                                          color: const Color(0xffDCF3DD),
                                          padding: const EdgeInsets.only(left: 8),
                                          width: 100,
                                          height: 70,
                                          alignment: Alignment.center,
                                          child: Text('$i'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          color: Theme.of(context).primaryColorDark,
                          width: width-100,
                          height: 50,
                          child: SingleChildScrollView(
                            controller: _horizontalScroll1,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                getColumnDotLine(),
                                if(standaloneColumn.isNotEmpty)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Center(
                                        child: Text('Standalone',style: TextStyle(color: Colors.white),),
                                      ),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          for(var i = 0;i < standaloneColumn.length;i++)
                                            Container(
                                              color: Colors.orange.shade200,
                                              padding: const EdgeInsets.only(left: 8),
                                              width: standaloneColumn[i] == 'Others' ? 1000 : 100,
                                              height: 25,
                                              alignment: Alignment.centerLeft,
                                              child: Text(standaloneColumn[i],style: const TextStyle(color: Colors.black),),
                                            ),
      
                                        ],
                                      ),
                                    ],
                                  ),
                                getColumnDotLine(),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            width: width-100,
                            child: Scrollbar(
                              thumbVisibility: true,
                              controller: _horizontalScroll2,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _horizontalScroll2,
                                child: Container(
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    controller: _verticalScroll2,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      controller: _verticalScroll2,
                                      child: Row(
                                        children: [
                                          //TODO : Standalone DATA
                                          Column(
                                            children: [
                                              for(var i in filterDataByPages(data: standaloneData['standaloneColumnData']))
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      width: 0,
                                                      height: 70,
                                                      child: CustomPaint(
                                                        painter: VerticalDotBorder(),
                                                        size: const Size(10,50),
                                                      ),
                                                    ),
                                                    for(var j = 0;j < i.length;j++)
                                                      Container(
                                                        padding: const EdgeInsets.only(left: 8),
                                                        width: j == 5 ? 1000 : 100,
                                                        height: 70,
                                                        alignment: Alignment.centerLeft,
                                                        child: Text('${i[j] ?? '-'}',style: const TextStyle(fontSize: 12,fontWeight: FontWeight.normal),),
                                                      ),
                                                    SizedBox(
                                                      width: 0,
                                                      height: 70,
                                                      child: CustomPaint(
                                                        painter: VerticalDotBorder(),
                                                        size: const Size(0,50),
                                                      ),
                                                    )
                                                  ],
                                                )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },),
            ),
          ),
          Container(
            color: Theme.of(context).primaryColorDark,
            width: MediaQuery.of(context).size.width,
            height: 35,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: (){
                          setState(() {
                            if(selectedPages != 1){
                              selectedPages -= 1  ;
                            }
                          });
                        },
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(5),
                          child: const Icon(Icons.keyboard_double_arrow_left),
                        ),
                      ),
                      if(standaloneData['fixedColumnData'] != null)
                        Text(
                          '${
                              (selectedPages * noOfRowsPerPage) - 20} - ${((selectedPages * noOfRowsPerPage) < standaloneData['fixedColumnData'].length
                              ?  (selectedPages * noOfRowsPerPage)
                              : standaloneData['fixedColumnData'].length)} / ${standaloneData['fixedColumnData'].length}',style: const TextStyle(color: Colors.white),
                        ),
                      InkWell(
                        onTap: (){
                          setState(() {
                            if(selectedPages != totalPages){
                              selectedPages += 1;
                            }
                          });
                        },
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(5),
                          child: const Icon(Icons.keyboard_double_arrow_right),
                        ),
                      ),
                    ],
                  ),
                ),
                MaterialButton(
                    color: Colors.white,
                    child: const Text('Select Date'),
                    onPressed: (){
                      showDialog(context: context, builder: (context){
                        return AlertDialog(
                          title: const Text('Date Picker'),
                          content: StatefulBuilder(
                            builder: (BuildContext context, StateSetter stateSetter) {
                              return SizedBox(
                                width: 200,
                                height: 250,
                                child:SfDateRangePicker(
                                  onSelectionChanged:  _onSelectionChanged,
                                  selectionMode: DateRangePickerSelectionMode.range,
                                  initialSelectedRange: PickerDateRange(
                                      // DateTime.now().subtract(const Duration(days: 4)),
                                      // DateTime.now().add(const Duration(days: 3))
                                    DateTime.now(),
                                    DateTime.now()
                                  ),
      
                                ),
                              );
                            },
                          ),
                          actions: [
                            CustomMaterialButton(
                              title: 'Cancel',
                              outlined: true,
                            ),
                            CustomMaterialButton(
                              onPressed: (){
                                Navigator.pop(context);
                                getDialog(context);
                                getStandaloneData();
                                // setState(() {
                                //   _irrigationOptionWise = [['Date',true],['Program',false],['Line',false],['Valve',false],['Status',false]];
                                // });
                                if(mounted){
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        );
      
                      });
                    }
                ),
                InkWell(
                  onTap: (){
                    showDialog(
                        context: context,
                        builder: (context){
                          var fileName = 'file';
                          return AlertDialog(
                            title: const Text('Give Name For Your File'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  initialValue: fileName,
                                  onChanged: (value){
                                    fileName = value;
                                  },
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder()
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                  onPressed: (){
                                    generateExcelForStandAlone(standaloneData,fileName);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Click to download')
                              )
                            ],
                          );
                        }
                    );
      
      
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white
                    ),
                    child: const Icon(Icons.download),
                  ),
                )
              ],
            ),
            // child: FloatingActionButton(
            //   backgroundColor: Colors.white,
            //   onPressed: () {
            //     showDialog(context: context, builder: (context){
            //       return AlertDialog(
            //         title: Text('Date Picker'),
            //         content: StatefulBuilder(
            //           builder: (BuildContext context, StateSetter stateSetter) {
            //             return SizedBox(
            //               width: 200,
            //               height: 250,
            //               child:SfDateRangePicker(
            //                 onSelectionChanged:  _onSelectionChanged,
            //                 selectionMode: DateRangePickerSelectionMode.range,
            //                 initialSelectedRange: PickerDateRange(
            //                     DateTime.now().subtract(const Duration(days: 4)),
            //                     DateTime.now().add(const Duration(days: 3))),
            //               ),
            //             );
            //           },
            //         ),
            //         actions: [
            //           ElevatedButton(
            //               onPressed: (){
            //                 Navigator.pop(context);
            //               },
            //               child: Text('Cancel')
            //           ),
            //           ElevatedButton(
            //               onPressed: ()async{
            //                 Navigator.pop(context);
            //                 getDialog(context);
            //                 getData();
            //                 setState(() {
            //                   _irrigationOptionWise = [['Date',true],['Program',false],['Line',false],['Valve',false],['Status',false]];
            //                 });
            //                 if(mounted){
            //                   Navigator.pop(context);
            //                 }
            //               },
            //               child: Text('Ok')
            //           )
            //         ],
            //       );
            //
            //     });
            //   },
            //   child: Text('Select Date'),
            // ),
          )
      
        ],
      ),
    );
  }

  Future<void> generateExcelForStandAlone(Map<String, dynamic> data, String name) async {
    // Create a new workbook
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Logs'];
// final sheet = workbook.worksheets[0];
    // sheet.name = 'Logs';

    // Create header row
    List<String> headerRow = [
      'Date',
      ...standaloneColumn
    ];
    sheetObject.appendRow([for(var i in headerRow) TextCellValue(i)]);

    for (var i = 0; i < data['fixedColumnData'].length; i++) {
      List<String> eachRow = [data['fixedColumnData'][i]];
      List<String> columnDataKeys = [
        'standaloneColumnData',
      ];

      for (var columnData in columnDataKeys) {
        if (data[columnData][0] != null) {
          for (var j = 0; j < data[columnData][i].length; j++) {
            eachRow.add('${data[columnData][i][j]}');
          }
        }
      }

      for (int j = 0; j < eachRow.length; j++) {
        sheetObject.appendRow([for(var cell in eachRow) TextCellValue(cell)]);
      }
    }

    // Save the file
    var fileBytes = excel.encode();
    if (fileBytes != null) {
      try {
        String downloadsDirectoryPath = "/storage/emulated/0/Download";
        String filePath = "$downloadsDirectoryPath/$name.xlsx";
        File file = File(filePath);
        await file.create(recursive: true);
        await file.writeAsBytes(fileBytes);
        // Check if file exists
        if (await file.exists()) {
          // Scaffold.of(context).showSnackBar()
          // Navigator.pop(context);
          showDialog(context: context, builder: (context){
            return AlertDialog(
              title: Text('$name Download Successfully at'),
              content: Text(filePath),
              actions: [
                TextButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    child: const Text('Ok')
                )
              ],
            );
          });
          print("Excel file saved successfully at $filePath");
        } else {
          // Navigator.pop(context);
          showDialog(context: context, builder: (context){
            return AlertDialog(
              title: Text('$name Download failed..'),
              actions: [
                TextButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    child: const Text('Ok')
                )
              ],
            );
          });
          log("Failed to save the Excel file.");
        }
      } catch (e) {
        log("Error saving the Excel file: $e");
      }
    } else {
      log("Error encoding the Excel file.");
    }
  }

  List<dynamic> filterDataByPages({required data}){
    List<dynamic> slicingList = [];
    int from = (selectedPages * noOfRowsPerPage) - 20;
    int to = (selectedPages * noOfRowsPerPage);
    if(data.length < to){
      to = data.length;
    }
    for(var i = from;i < to;i++){
      slicingList.add(data[i]);
    }
    return slicingList;
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is PickerDateRange) {
        _selectedDate  = '${DateFormat('dd/MM/yyyy').format(args.value.startDate)} -'
            ' ${DateFormat('dd/MM/yyyy').format(args.value.endDate ?? args.value.startDate)}';

      } else if (args.value is DateTime) {
        _selectedDate = args.value.toString();
      } else if (args.value is List<DateTime>) {
        _dateCount = args.value.length.toString();
      } else {
        _rangeCount = args.value.length.toString();
      }
      print("range: $_range,rangecount:$_rangeCount,Select date:$_selectedDate");
    });
  }
}
