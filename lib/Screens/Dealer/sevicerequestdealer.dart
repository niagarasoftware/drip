import 'dart:convert';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/Preferences/widgets/custom_segmented_control.dart';
import '../../models/customer/site_model.dart';
import '../../models/servicerequestdealermodel.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/snack_bar.dart';
import '../../views/customer/widgets/alarm_list_items.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

class ServiceRequestsTable extends StatefulWidget {
  const ServiceRequestsTable({
    super.key,
    required this.userId,
  });
  final int userId;

  @override
  State<ServiceRequestsTable> createState() => _ServiceRequestsTableState();
}

class _ServiceRequestsTableState extends State<ServiceRequestsTable> {
  // Example JSON string
  ServiceDealerModel _serviceDealerModel = ServiceDealerModel();
  DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  int _selectedSegment = 0;
  Map<String, dynamic> _criticalAlarmData = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
    fetchAlarm();
  }

  Future<void> fetchData() async {
    try{
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getUserServiceRequestForDealer({
        "userId": widget.userId,
      });
      // AppLog.log("getUserDetails :: ${getUserDetails.body}");
      if (getUserDetails.statusCode == 200) {
        setState(() {
          var jsonData = jsonDecode(getUserDetails.body);
          _serviceDealerModel = ServiceDealerModel.fromJson(jsonData);
        });
      } else {
        //_showSnackBar(response.body);
      }
    }
    catch (e, stackTrace) {
      AppLog.log(' Error overAll getData => ${e.toString()}');
      AppLog.log(' trace overAll getData  => $stackTrace');
    }


  }

  Future<void> fetchAlarm() async{
    try{
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getUserCriticalAlarmForDealer({
        "userId": widget.userId,
      });
      AppLog.log("userId :: ${widget.userId}");
      // AppLog.log("getUserCriticalAlarmForDealer ==>  ${getUserDetails.body}");
      // final jsonData = jsonDecode(getUserDetails.body);
      if (getUserDetails.statusCode == 200) {
        setState(() {
          _criticalAlarmData = jsonDecode(getUserDetails.body);
        });
      } else {
        //_showSnackBar(response.body);
      }
    }
    catch (e, stackTrace) {
      AppLog.log(' Error overAll getData => ${e.toString()}');
      AppLog.log(' trace overAll getData  => $stackTrace');
    }
  }


  @override
  Widget build(BuildContext context) {

    // return AlarmListItems(alarm : alarmPayload, deviceID:deviceID, customerId: customerId, controllerId: controllerId, irrigationLine: [],);
   /* if(_selectedSegment == 0){
      if (_serviceDealerModel.data == null) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar:  AppBar(title: const Text('Service Request List')),
          body: const Center(
            child: Text(
              'Currently No Request available ',
              style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
            ),
          ),
        );
      } else if (_serviceDealerModel.data!.isEmpty) {
        return Scaffold(
          appBar:  AppBar(title: const Text('Service Request List')),
          body: const Center(
            child: Text(
              'Currently No Request available on Customer Account',
              style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
            ),
          ),
        );
      }
    }*/
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar:  AppBar(title: Text(_selectedSegment == 0 ? 'Service Request List' : 'Critical alarm list')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          spacing: 10,
          children: [
            CustomSegmentedControl(
                segmentTitles: const {
                  0: "Service Requests",
                  1: "Critical alarms",
                },
                groupValue: _selectedSegment,
                onChanged: (newValue) {
                  setState(() {
                    _selectedSegment = newValue!;
                  });
                }
            ),
            if(_selectedSegment == 0)
              Expanded(
                child: _serviceDealerModel.data == null ? const Center(
                  child: Text(
                    'Currently No Request available ',
                    style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                  ),
                ) : _serviceDealerModel.data!.isEmpty ? const Center(
                  child: Text(
                    'Currently No Request available on Customer Account',
                    style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                  ),
                ) : DataTable2(
                  minWidth: 1200,
                  showBottomBorder: true,
                  headingRowColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      return Theme.of(context).primaryColorDark; // default color
                    },
                  ),
                  headingRowHeight: 29,
                  dataRowHeight: 45,
                  columns: const [
                    DataColumn2(
                      fixedWidth: 50,
                      label: Text(
                        'SNo',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // DataColumn2(
                    //   fixedWidth: 120,
                    //   label: Text(
                    //     'Customer Name',softWrap: true,
                    //     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),
                    //   ),
                    // ),
                    DataColumn2(
                      fixedWidth: 150,
                      label: Text(
                        'Site Name',softWrap: true,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn2(
                      size: ColumnSize.L,
                      label: Text(
                        'Issue', softWrap: true,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn2(
                      size: ColumnSize.L,
                      label: Text(
                        'Description',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),

                    DataColumn2(
                      fixedWidth: 140,
                      label: Text(
                        'Request Date',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn2(
                      fixedWidth: 160,
                      label: Text(
                        'Estimated Date',softWrap: true,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn2(
                      fixedWidth: 165,
                      label: Text(
                        'Status',softWrap: true,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn2(
                      fixedWidth: 150,
                      label: Text(
                        'Update',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: List<DataRow>.generate(
                    _serviceDealerModel.data!.length,
                        (index) {
                      return DataRow(
                        color: _serviceDealerModel.data![index].status == 'Closed'
                            ? WidgetStateProperty.all(Colors.green.shade100)
                            : _serviceDealerModel.data![index].priority == 'High'
                            ? WidgetStateProperty.all(Colors.red.shade100)
                            : _serviceDealerModel.data![index].priority == 'Medium'
                            ? WidgetStateProperty.all(Colors.yellow.shade100)
                            : WidgetStateProperty.all(Colors.white),
                        cells: [
                          DataCell(Text(_serviceDealerModel.data![index].requestId.toString())),
                          // DataCell(Text(_serviceDealerModel.data![index].groupName ?? '')),
                          DataCell(Text(_serviceDealerModel.data![index].groupName ?? '')),
                          DataCell(Text(_serviceDealerModel.data![index].requestType ?? '')),
                          DataCell(SizedBox(
                            height: 60,
                            width: double.infinity,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Text(_serviceDealerModel.data![index].requestDescription ?? ''),
                            ),
                          ),),
                          DataCell(Text(DateFormat('yyyy-MM-dd').format(_serviceDealerModel.data![index].requestDate!).toString())),
                          DataCell(
                            InkWell(
                              child: Row(
                                children: [
                                  Text(DateFormat('yyyy-MM-dd').format(_serviceDealerModel.data![index].estimatedDate!).toString()),
                                  const Icon(Icons.date_range),
                                ],
                              ),
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _serviceDealerModel.data![index].estimatedDate ?? DateTime.now(),
                                  firstDate: DateTime(DateTime.now().year),
                                  lastDate: DateTime(2026),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    _serviceDealerModel.data![index].estimatedDate = pickedDate;
                                  });
                                }
                              },
                            ),
                          ),
                          DataCell(
                            DropdownButton<String>(
                              value: _serviceDealerModel.data![index].status,
                              items: <String>['Waiting', 'In-Progress', 'Closed'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _serviceDealerModel.data![index].status = newValue;
                                });
                              },
                            ),
                          ),
                          DataCell(
                            ElevatedButton(
                              onPressed: () {
                                updateData(
                                  widget.userId,
                                  _serviceDealerModel.data![index].controllerId!,
                                  _serviceDealerModel.data![index].requestTypeId!,
                                  _serviceDealerModel.data![index].responsibleUser!,
                                  dateFormat.format(_serviceDealerModel.data![index].estimatedDate!).toString(),
                                  _serviceDealerModel.data![index].status!,
                                  _serviceDealerModel.data![index].requestId!,
                                );
                                fetchData();
                              },
                              child: const Text('Update',  style: TextStyle(
                                color: Colors.white,
                              ),),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              )
            else
              CriticalAlarmList(criticalAlarmData: _criticalAlarmData, userId: widget.userId,)
          ],
        ),
      ),
    );
  }


  Future<void> updateData(
      int userid,
      int controllerId,
      int requestTypeId,
      int responsibleUser,
      String estimatedDate,
      String status,
      int requestId,
      ) async {
    // getUserServiceRequest => userId, controllerId
    // createUserServiceRequest => userId, controllerId, requestTypeId, requestDate, requestTime, responsibleUser, estimatedDate, siteLocation, createUser
    // updateUserServiceRequest => userId, controllerId, requestId, requestTypeId, responsibleUser, estimatedDate, status, closedDate, modifyUser
    AppLog.log("status--->$status");
    Map<String, dynamic> body = {
      "userId": userid,
      "controllerId": controllerId,
      "requestTypeId": requestTypeId,
      "requestId": requestId,
      "responsibleUser": responsibleUser,
      "estimatedDate": estimatedDate,
      "status": status,
      "closedDate":
      status == 'Closed' ? dateFormat.format(DateTime.now()) : null,
      "modifyUser": userid
    };
    AppLog.log("body call--->$body");
    final Repository repository = Repository(HttpService());
    var response = await repository.updateUserServiceRequest(body);
    final jsonData = json.decode(response.body);
    AppLog.log("response--->${response.body}");

    // AppLog.log("jsonData--->$jsonData");
    AppLog.log("response.statusCode--->${response.statusCode}");
    if (response.statusCode == 200) {
      setState(() {
        GlobalSnackBar.show(context, jsonData['message'], response.statusCode);
        fetchData();
      });
    } else {
      GlobalSnackBar.show(context, jsonData['message'], response.statusCode);
    }
  }
}

class CriticalAlarmList extends StatelessWidget {
  final Map<String, dynamic> criticalAlarmData;
  final int userId;
  const CriticalAlarmList({super.key, required this.criticalAlarmData, required this.userId});

  @override
  Widget build(BuildContext context) {
    if(criticalAlarmData.isEmpty) {
      return const Expanded(
          child: Center(
              child: CircularProgressIndicator()
          )
      );
    }
    if(criticalAlarmData['code'] != 200) {
      return Expanded(
          child: Center(
              child: Text('${criticalAlarmData['message']}')
          )
      );
    }
    return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for(int group = 0; group < criticalAlarmData['data'].length; group++)
                ...[
                  // Text("${criticalAlarmData['data'][group]}"),
                  Text(
                    "${criticalAlarmData['data'][group]['groupName']}",
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).primaryColorDark
                    ),
                  ),
                  for(int master = 0; master < criticalAlarmData['data'][group]['master'].length; master++)
                    ...[
                      Text(
                          '${criticalAlarmData['data'][group]['master'][master]['deviceName']}',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey, fontWeight: FontWeight.normal)
                      ),
                      Flexible(
                        child: AlarmListItems(
                            show: false,
                            alarm: List<String>.from(criticalAlarmData['data'][group]['master'][master]['criticalAlarm']),
                            deviceID: criticalAlarmData['data'][group]['master'][master]['deviceName'],
                            customerId: userId,
                            controllerId: criticalAlarmData['data'][group]['master'][master]['controllerId'],
                            irrigationLine: (criticalAlarmData['data'][group]['master'][master]['irrigationLine'] as List).map((item) => IrrigationLineModel.fromJson(item, [], [], [],[])).toList(),
                          isNarrow: !kIsWeb,
                          isOMS: false,
                        ),
                      )
                      // Text('${criticalAlarmData['data'][group]['master'][master]}'),
                    ]
                ],
              // Text('${criticalAlarmData['data']}')
            ],
          ),
        )
    );
  }
}


