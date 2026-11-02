import 'dart:collection';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

class ServiceRequestAdmin extends StatefulWidget {
   const ServiceRequestAdmin({super.key, 
     required this.userId,});
 final int userId;

  @override
  State<ServiceRequestAdmin> createState() => _ServiceRequestAdminState();
}

class _ServiceRequestAdminState extends State<ServiceRequestAdmin> {
  // Example JSON string
   DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredData = [];
  String searchQuery = '';
  String filterStatus = 'All';
  String filterRequestType = 'All';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
     filteredData = List.from(data);
  }
   Future<void> fetchData() async {
     try {
       final Repository repository = Repository(HttpService());
       var getUserDetails = await repository.getAllUserAllServiceRequestForAdmin({"userId": widget.userId});

       if (getUserDetails.statusCode == 200) {
         setState(() {
           var jsonData1 = jsonDecode(getUserDetails.body);
            if (jsonData1 is LinkedHashMap) {
             jsonData1 = Map<String, dynamic>.from(jsonData1);
           }
            if (jsonData1 is Map<String, dynamic> && jsonData1.containsKey('data')) {
             var dataList = jsonData1['data'];
              if (dataList is List) {
               data = List<Map<String, dynamic>>.from(dataList);
             } else {
               AppLog.log("Expected 'data' to be a list but found ${dataList.runtimeType}");
              }
           } else {
             AppLog.log("Unexpected JSON format or missing 'data' key");
           }

           filteredData = List.from(data);
         });
       } else {
         //_showSnackBar(response.body);
       }
     } catch (e, stackTrace) {
       AppLog.log('Error overAll getData => ${e.toString()}');
       AppLog.log('trace overAll getData  => $stackTrace');
     }
   }


  void updateFilters() {
    setState(() {
      filteredData = data.where((item) {
        final matchesSearchQuery = searchQuery.isEmpty ||
            item.values.any((value) =>
            value != null &&
                value.toString().toLowerCase().contains(searchQuery.toLowerCase()));
        final matchesStatus = filterStatus == 'All' ||
            item['status'].toString().toLowerCase() == filterStatus.toLowerCase();
        final matchesRequestType = filterRequestType == 'All' ||
            item['requestType']
                .toString()
                .toLowerCase()
                .contains(filterRequestType.toLowerCase());

        return matchesSearchQuery && matchesStatus && matchesRequestType;
      }).toList();
    });
  }

  Color getRowColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return Colors.green.withValues(alpha: 0.2); // Light green color
      case 'waiting':
        return Colors.red.withValues(alpha: 0.2); // Light red color
      case 'in-progress':
        return Colors.yellow.withValues(alpha: 0.2); // Light yellow color
      default:
        return Colors.transparent; // No color
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 30 ,right: 30 ,top: 8 ,bottom:8 ),
            child: TextField(
              onChanged: (value) {
                searchQuery = value;
                updateFilters();
              },
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Status:"),
              const SizedBox(width: 5,),
              DropdownButton<String>(
                value: filterStatus,
                items: ['All', 'Waiting', 'In-Progress', 'Closed']
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    filterStatus = value!;
                    updateFilters();
                  });
                },
                hint: const Text('Filter by Status'),
              ),
              const SizedBox(width: 10,),
              const Text("Request Type:"),
              const SizedBox(width: 5,),
              DropdownButton<String>(
                value: filterRequestType,
                items: ['All', 'Valve Issue', 'Other Issue', 'Hardware Issue', 'Software Issue']
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    filterRequestType = value!;
                    updateFilters();
                  });
                },
                hint: const Text('Filter by Request Type'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Total Records: ${filteredData.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ScrollPhysics(),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Request ID',style: TextStyle(fontWeight: FontWeight.bold),)),
                      DataColumn(label: Text('User Name',style: TextStyle(fontWeight: FontWeight.bold),)),
                      DataColumn(label: Text('Dealer Name',style: TextStyle(fontWeight: FontWeight.bold),)),
                      DataColumn(label: Text('Group Name',style: TextStyle(fontWeight: FontWeight.bold),)),
                      DataColumn(label: Text('Device Name',style: TextStyle(fontWeight: FontWeight.bold),)),
                      DataColumn(label: Text('Request Type',style: TextStyle(fontWeight: FontWeight.bold),)),
                      DataColumn(label: Text('Description',style: TextStyle(fontWeight: FontWeight.bold),)),
                      DataColumn(label: Text('Date',style: TextStyle(fontWeight: FontWeight.bold),)),
                      DataColumn(label: Text('Time',style: TextStyle(fontWeight: FontWeight.bold),)),
                      DataColumn(label: Text('Status',style: TextStyle(fontWeight: FontWeight.bold),)),
                      DataColumn(label: Text('Priority',style: TextStyle(fontWeight: FontWeight.bold),)),
                    ],
                    rows: filteredData
                        .map(
                          (item) => DataRow(
                        color: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                              return getRowColor(item['status'].toString());
                            }),
                        cells: [
                          DataCell(Text(item['requestId'].toString())),
                          DataCell(Text(item['userName'].toString())),
                          DataCell(Text(item['responsibleUserName'].toString())),
                          DataCell(Text(item['groupName'].toString())),
                          DataCell(Text(item['deviceName'].toString())),
                          DataCell(Text(item['requestType'].toString())),
                          DataCell(Text(item['requestDescription'].toString())),
                          DataCell(Text(item['requestDate'].toString())),
                          DataCell(Text(item['requestTime'].toString())),
                          DataCell(Text(item['status'].toString())),
                          DataCell(Text(item['priority'].toString())),
                        ],
                      ),
                    )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

