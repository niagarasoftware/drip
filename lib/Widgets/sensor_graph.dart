// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:intl/intl.dart';
// import '../StateManagement/mqtt_payload_provider.dart';
// import '../services/http_service.dart';
//
// class SensorGraph extends StatelessWidget {
//   final List<SensorChart> list;
//   final String sensorName;
//   const SensorGraph({super.key, required this.list, required this.sensorName});
//
//   @override
//   Widget build(BuildContext context) {
//     return SfCartesianChart(
//       // backgroundColor: colorScheme.surface,
//       enableSideBySideSeriesPlacement: true,
//       borderWidth: 1.8,
//       plotAreaBorderColor: Colors.grey[900],
//       plotAreaBorderWidth: 0.6,
//       primaryXAxis: CategoryAxis(
//         title: AxisTitle(
//             text: 'Hours',
//             textStyle: TextStyle(
//                 color: Colors.black, fontWeight: FontWeight.bold)),
//         interval: 2,
//         minimum: 0,
//         maximum: 23, // Set interval to 1 to show every hour
//         labelRotation: 0, // Rotate labels for better readability
//         majorGridLines: MajorGridLines(width: 1),
//         autoScrollingMode: AutoScrollingMode.start,
//         labelStyle: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.bold,
//             color: Colors.teal),
//       ),
//       primaryYAxis: NumericAxis(
//         autoScrollingMode: AutoScrollingMode.end,
//         // title: AxisTitle(
//         //   text: 'report type',
//         //   textStyle: TextStyle(
//         //       fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
//         // ),
//         minimum: 0,
//         maximum: 220,
//         interval: 20,
//         labelStyle: TextStyle(
//             fontSize: 12, fontWeight: FontWeight.w700, color: Colors.teal),
//       ),
//       // title: ChartTitle(
//       //     text: 'Data',
//       //     textStyle: TextStyle(
//       //       fontWeight: FontWeight.w700,
//       //     )),
//       legend: Legend(isVisible: true),
//       // tooltipBehavior: TooltipBehavior(
//       //     enable: false,
//       //     header: selectedReportType,
//       //     duration: 0.2,
//       //     color: Colors.blue),
//       zoomPanBehavior: ZoomPanBehavior(
//
//         // enablePanning: true,
//         // enablePinching: true,
//         zoomMode: ZoomMode.xy,
//       ),
//       series: <CartesianSeries>[
//         LineSeries<SensorChart, String>(
//           dataSource: list,
//           xValueMapper: (SensorChart data, _) => data.hour,
//           yValueMapper: (SensorChart data, _) => data.value,
//           name: sensorName,
//           color: Colors.blueGrey, // Set the line color here
//           width: 1.0, // Set the line width here
//           dashArray: [0], // Set the line style (dashed) here
//           markerSettings: MarkerSettings(
//             isVisible: true,
//             color: Colors.white,
//             height: 3,
//             width: 3,
//             shape: DataMarkerType.circle,
//           ),
//         ),
//       ],
//     );
//   }
// }
//
//
//
// class SensorChart {
//   final String hour;
//   final double value;
//
//   SensorChart({required this.hour, required this.value});
// }
//
//
// class MyFutureBuilderForSensorGraph extends StatelessWidget {
//   final Future<dynamic> futureData;
//   final List<dynamic> listOfSerialNo;
//   final List<dynamic> listOfName;
//   final String sensorName;
//
//   const MyFutureBuilderForSensorGraph({super.key, required this.futureData, required this.listOfSerialNo, required this.sensorName, required this.listOfName});
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//         future: futureData,
//         builder: (context, snapshot){
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 20,),
//                 Text('Loading......')
//               ],
//             );
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (snapshot.hasData) {
//             var particularSensorData = snapshot.data!.where((sensor) => sensor['name'] == sensorName).toList();
//             particularSensorData = particularSensorData[0]['data'];
//             print('particularSensorData :: ${particularSensorData}');
//             List<List<SensorChart>> graphList = [];
//             print('listOfSerialNo :: $listOfSerialNo');
//             for(var sNo = 0;sNo < listOfSerialNo.length;sNo++){
//               graphList.add([]);
//               for(var hourKey in particularSensorData.keys){
//                 for(var hourKeyValue in particularSensorData[hourKey]){
//                   if(hourKeyValue['S_No'] == listOfSerialNo[sNo]){
//                     graphList[sNo].add(SensorChart(hour: hourKey, value: double.parse(hourKeyValue['Value'])));
//                   }
//                 }
//               }
//             }
//             print('graphList :: $graphList');
//             return SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   SizedBox(height: 50,),
//                   for(var sd = 0;sd < graphList.length;sd++)
//                     SensorGraph(list: graphList[sd], sensorName: listOfName[sd],)
//                 ],
//               ),
//             );
//           } else {
//             return const Center(child: Text('No data available.'));
//           }
//         }
//     );
//   }
// }
//
//
// Future<dynamic> getSensorHourlyLogs(userId, controllerId, MqttPayloadProvider payloadProvider) async {
//   if(payloadProvider.sensorLogData.isEmpty){
//     print('getSensorHourlyLogs called...................');
//     String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     Map<String, Object> body = {
//       "userId": userId,
//       "controllerId": controllerId,
//       "fromDate": date,
//       "toDate": date
//     };
//     final response = await HttpService().postRequest("getUserSensorHourlyLog", body);
//     if (response.statusCode == 200) {
//       var data = jsonDecode(response.body);
//       if (data["code"] == 200) {
//         try {
//           payloadProvider.editSensorLogData(data['data']);
//           return data['data'];
//         } catch (e) {
//           print('Error on sensorLogData: $e');
//         }
//       }
//     }
//   }else{
//     return payloadProvider.sensorLogData;
//   }
//   // var sampleData = {
//   //   "code": 200,
//   //   "message": "User sensor hourly log listed successfully",
//   //   "data": [
//   //     {
//   //       "name": "Level Sensor",
//   //       "data": {
//   //         "01:00": [
//   //           {
//   //             "S_No": 93,
//   //             "Id": "LS.3",
//   //             "Name": "SP Level Sensor 3",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 85,
//   //             "Id": "LV.1.1",
//   //             "Name": "Level Sensor 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 86,
//   //             "Id": "LV.1.2",
//   //             "Name": "Level Sensor 1.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 87,
//   //             "Id": "LV.2.1",
//   //             "Name": "Level Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 88,
//   //             "Id": "LV.2.2",
//   //             "Name": "Level Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "02:00": [
//   //           {
//   //             "S_No": 93,
//   //             "Id": "LS.3",
//   //             "Name": "SP Level Sensor 3",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 85,
//   //             "Id": "LV.1.1",
//   //             "Name": "Level Sensor 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 86,
//   //             "Id": "LV.1.2",
//   //             "Name": "Level Sensor 1.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 87,
//   //             "Id": "LV.2.1",
//   //             "Name": "Level Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 88,
//   //             "Id": "LV.2.2",
//   //             "Name": "Level Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "03:00": [
//   //           {
//   //             "S_No": 93,
//   //             "Id": "LS.3",
//   //             "Name": "SP Level Sensor 3",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 85,
//   //             "Id": "LV.1.1",
//   //             "Name": "Level Sensor 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 86,
//   //             "Id": "LV.1.2",
//   //             "Name": "Level Sensor 1.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 87,
//   //             "Id": "LV.2.1",
//   //             "Name": "Level Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 88,
//   //             "Id": "LV.2.2",
//   //             "Name": "Level Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "04:00": [
//   //           {
//   //             "S_No": 93,
//   //             "Id": "LS.3",
//   //             "Name": "SP Level Sensor 3",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 85,
//   //             "Id": "LV.1.1",
//   //             "Name": "Level Sensor 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 86,
//   //             "Id": "LV.1.2",
//   //             "Name": "Level Sensor 1.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 87,
//   //             "Id": "LV.2.1",
//   //             "Name": "Level Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 88,
//   //             "Id": "LV.2.2",
//   //             "Name": "Level Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "05:00": [
//   //           {
//   //             "S_No": 93,
//   //             "Id": "LS.3",
//   //             "Name": "SP Level Sensor 3",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 85,
//   //             "Id": "LV.1.1",
//   //             "Name": "Level Sensor 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 86,
//   //             "Id": "LV.1.2",
//   //             "Name": "Level Sensor 1.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 87,
//   //             "Id": "LV.2.1",
//   //             "Name": "Level Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 88,
//   //             "Id": "LV.2.2",
//   //             "Name": "Level Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "06:00": [
//   //           {
//   //             "S_No": 93,
//   //             "Id": "LS.3",
//   //             "Name": "SP Level Sensor 3",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 85,
//   //             "Id": "LV.1.1",
//   //             "Name": "Level Sensor 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 86,
//   //             "Id": "LV.1.2",
//   //             "Name": "Level Sensor 1.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 87,
//   //             "Id": "LV.2.1",
//   //             "Name": "Level Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 88,
//   //             "Id": "LV.2.2",
//   //             "Name": "Level Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "07:00": [
//   //           {
//   //             "S_No": 93,
//   //             "Id": "LS.3",
//   //             "Name": "SP Level Sensor 3",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 85,
//   //             "Id": "LV.1.1",
//   //             "Name": "Level Sensor 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 86,
//   //             "Id": "LV.1.2",
//   //             "Name": "Level Sensor 1.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 87,
//   //             "Id": "LV.2.1",
//   //             "Name": "Level Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 88,
//   //             "Id": "LV.2.2",
//   //             "Name": "Level Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "08:00": [
//   //           {
//   //             "S_No": 93,
//   //             "Id": "LS.3",
//   //             "Name": "SP Level Sensor 3",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 85,
//   //             "Id": "LV.1.1",
//   //             "Name": "Level Sensor 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 86,
//   //             "Id": "LV.1.2",
//   //             "Name": "Level Sensor 1.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 87,
//   //             "Id": "LV.2.1",
//   //             "Name": "Level Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 88,
//   //             "Id": "LV.2.2",
//   //             "Name": "Level Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "09:00": [
//   //           {
//   //             "S_No": 93,
//   //             "Id": "LS.3",
//   //             "Name": "SP Level Sensor 3",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 85,
//   //             "Id": "LV.1.1",
//   //             "Name": "Level Sensor 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 86,
//   //             "Id": "LV.1.2",
//   //             "Name": "Level Sensor 1.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 87,
//   //             "Id": "LV.2.1",
//   //             "Name": "Level Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 88,
//   //             "Id": "LV.2.2",
//   //             "Name": "Level Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "11:00": [
//   //           {
//   //             "S_No": 93,
//   //             "Id": "LS.3",
//   //             "Name": "SP Level Sensor 3",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 85,
//   //             "Id": "LV.1.1",
//   //             "Name": "Level Sensor 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 86,
//   //             "Id": "LV.1.2",
//   //             "Name": "Level Sensor 1.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 87,
//   //             "Id": "LV.2.1",
//   //             "Name": "Level Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 88,
//   //             "Id": "LV.2.2",
//   //             "Name": "Level Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "12:00": [
//   //           {
//   //             "S_No": 93,
//   //             "Id": "LS.3",
//   //             "Name": "SP Level Sensor 3",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 85,
//   //             "Id": "LV.1.1",
//   //             "Name": "Level Sensor 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 86,
//   //             "Id": "LV.1.2",
//   //             "Name": "Level Sensor 1.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 87,
//   //             "Id": "LV.2.1",
//   //             "Name": "Level Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 88,
//   //             "Id": "LV.2.2",
//   //             "Name": "Level Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ]
//   //       }
//   //     },
//   //     {
//   //       "name": "EC Sensor",
//   //       "data": {
//   //         "01:00": [
//   //           {
//   //             "S_No": 47,
//   //             "Id": "EC.1.1.1",
//   //             "Name": "EC Sensor CFESI 1.1",
//   //             "Value": "14",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "02:00": [
//   //           {
//   //             "S_No": 47,
//   //             "Id": "EC.1.1.1",
//   //             "Name": "EC Sensor CFESI 1.1",
//   //             "Value": "14",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "03:00": [
//   //           {
//   //             "S_No": 47,
//   //             "Id": "EC.1.1.1",
//   //             "Name": "EC Sensor CFESI 1.1",
//   //             "Value": "14",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "04:00": [
//   //           {
//   //             "S_No": 47,
//   //             "Id": "EC.1.1.1",
//   //             "Name": "EC Sensor CFESI 1.1",
//   //             "Value": "14",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "05:00": [
//   //           {
//   //             "S_No": 47,
//   //             "Id": "EC.1.1.1",
//   //             "Name": "EC Sensor CFESI 1.1",
//   //             "Value": "14",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "06:00": [
//   //           {
//   //             "S_No": 47,
//   //             "Id": "EC.1.1.1",
//   //             "Name": "EC Sensor CFESI 1.1",
//   //             "Value": "14",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "07:00": [
//   //           {
//   //             "S_No": 47,
//   //             "Id": "EC.1.1.1",
//   //             "Name": "EC Sensor CFESI 1.1",
//   //             "Value": "14",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "08:00": [
//   //           {
//   //             "S_No": 47,
//   //             "Id": "EC.1.1.1",
//   //             "Name": "EC Sensor CFESI 1.1",
//   //             "Value": "14",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "09:00": [
//   //           {
//   //             "S_No": 47,
//   //             "Id": "EC.1.1.1",
//   //             "Name": "EC Sensor CFESI 1.1",
//   //             "Value": "14",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "11:00": [
//   //           {
//   //             "S_No": 47,
//   //             "Id": "EC.1.1.1",
//   //             "Name": "EC Sensor CFESI 1.1",
//   //             "Value": "14",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "12:00": [
//   //           {
//   //             "S_No": 47,
//   //             "Id": "EC.1.1.1",
//   //             "Name": "EC Sensor CFESI 1.1",
//   //             "Value": "14",
//   //             "Valve": null
//   //           }
//   //         ]
//   //       }
//   //     },
//   //     {
//   //       "name": "PH Sensor",
//   //       "data": {
//   //         "01:00": [
//   //           {
//   //             "S_No": 49,
//   //             "Id": "PH.1.1.1",
//   //             "Name": "PH Sensor CFESI 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "02:00": [
//   //           {
//   //             "S_No": 49,
//   //             "Id": "PH.1.1.1",
//   //             "Name": "PH Sensor CFESI 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "03:00": [
//   //           {
//   //             "S_No": 49,
//   //             "Id": "PH.1.1.1",
//   //             "Name": "PH Sensor CFESI 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "04:00": [
//   //           {
//   //             "S_No": 49,
//   //             "Id": "PH.1.1.1",
//   //             "Name": "PH Sensor CFESI 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "05:00": [
//   //           {
//   //             "S_No": 49,
//   //             "Id": "PH.1.1.1",
//   //             "Name": "PH Sensor CFESI 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "06:00": [
//   //           {
//   //             "S_No": 49,
//   //             "Id": "PH.1.1.1",
//   //             "Name": "PH Sensor CFESI 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "07:00": [
//   //           {
//   //             "S_No": 49,
//   //             "Id": "PH.1.1.1",
//   //             "Name": "PH Sensor CFESI 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "08:00": [
//   //           {
//   //             "S_No": 49,
//   //             "Id": "PH.1.1.1",
//   //             "Name": "PH Sensor CFESI 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "09:00": [
//   //           {
//   //             "S_No": 49,
//   //             "Id": "PH.1.1.1",
//   //             "Name": "PH Sensor CFESI 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "11:00": [
//   //           {
//   //             "S_No": 49,
//   //             "Id": "PH.1.1.1",
//   //             "Name": "PH Sensor CFESI 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "12:00": [
//   //           {
//   //             "S_No": 49,
//   //             "Id": "PH.1.1.1",
//   //             "Name": "PH Sensor CFESI 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ]
//   //       }
//   //     },
//   //     {
//   //       "name": "Pressure Sensor",
//   //       "data": {
//   //         "01:00": [
//   //           {
//   //             "S_No": 56,
//   //             "Id": "FI.1.1",
//   //             "Name": "Pressure Sensor In CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 59,
//   //             "Id": "FI.1.2",
//   //             "Name": "Pressure Sensor In CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 57,
//   //             "Id": "FO.1.1",
//   //             "Name": "Pressure Sensor Out CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 58,
//   //             "Id": "FO.1.2",
//   //             "Name": "Pressure Sensor Out CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 89,
//   //             "Id": "LI.1",
//   //             "Name": "Press Sens In Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 92,
//   //             "Id": "LI.2",
//   //             "Name": "Press Sens In Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 90,
//   //             "Id": "LO.1",
//   //             "Name": "Press Sens Out Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 91,
//   //             "Id": "LO.2",
//   //             "Name": "Press Sens Out Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "02:00": [
//   //           {
//   //             "S_No": 56,
//   //             "Id": "FI.1.1",
//   //             "Name": "Pressure Sensor In CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 59,
//   //             "Id": "FI.1.2",
//   //             "Name": "Pressure Sensor In CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 57,
//   //             "Id": "FO.1.1",
//   //             "Name": "Pressure Sensor Out CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 58,
//   //             "Id": "FO.1.2",
//   //             "Name": "Pressure Sensor Out CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 89,
//   //             "Id": "LI.1",
//   //             "Name": "Press Sens In Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 92,
//   //             "Id": "LI.2",
//   //             "Name": "Press Sens In Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 90,
//   //             "Id": "LO.1",
//   //             "Name": "Press Sens Out Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 91,
//   //             "Id": "LO.2",
//   //             "Name": "Press Sens Out Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "03:00": [
//   //           {
//   //             "S_No": 56,
//   //             "Id": "FI.1.1",
//   //             "Name": "Pressure Sensor In CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 59,
//   //             "Id": "FI.1.2",
//   //             "Name": "Pressure Sensor In CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 57,
//   //             "Id": "FO.1.1",
//   //             "Name": "Pressure Sensor Out CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 58,
//   //             "Id": "FO.1.2",
//   //             "Name": "Pressure Sensor Out CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 89,
//   //             "Id": "LI.1",
//   //             "Name": "Press Sens In Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 92,
//   //             "Id": "LI.2",
//   //             "Name": "Press Sens In Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 90,
//   //             "Id": "LO.1",
//   //             "Name": "Press Sens Out Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 91,
//   //             "Id": "LO.2",
//   //             "Name": "Press Sens Out Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "04:00": [
//   //           {
//   //             "S_No": 56,
//   //             "Id": "FI.1.1",
//   //             "Name": "Pressure Sensor In CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 59,
//   //             "Id": "FI.1.2",
//   //             "Name": "Pressure Sensor In CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 57,
//   //             "Id": "FO.1.1",
//   //             "Name": "Pressure Sensor Out CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 58,
//   //             "Id": "FO.1.2",
//   //             "Name": "Pressure Sensor Out CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 89,
//   //             "Id": "LI.1",
//   //             "Name": "Press Sens In Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 92,
//   //             "Id": "LI.2",
//   //             "Name": "Press Sens In Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 90,
//   //             "Id": "LO.1",
//   //             "Name": "Press Sens Out Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 91,
//   //             "Id": "LO.2",
//   //             "Name": "Press Sens Out Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "05:00": [
//   //           {
//   //             "S_No": 56,
//   //             "Id": "FI.1.1",
//   //             "Name": "Pressure Sensor In CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 59,
//   //             "Id": "FI.1.2",
//   //             "Name": "Pressure Sensor In CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 57,
//   //             "Id": "FO.1.1",
//   //             "Name": "Pressure Sensor Out CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 58,
//   //             "Id": "FO.1.2",
//   //             "Name": "Pressure Sensor Out CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 89,
//   //             "Id": "LI.1",
//   //             "Name": "Press Sens In Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 92,
//   //             "Id": "LI.2",
//   //             "Name": "Press Sens In Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 90,
//   //             "Id": "LO.1",
//   //             "Name": "Press Sens Out Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 91,
//   //             "Id": "LO.2",
//   //             "Name": "Press Sens Out Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "06:00": [
//   //           {
//   //             "S_No": 56,
//   //             "Id": "FI.1.1",
//   //             "Name": "Pressure Sensor In CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 59,
//   //             "Id": "FI.1.2",
//   //             "Name": "Pressure Sensor In CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 57,
//   //             "Id": "FO.1.1",
//   //             "Name": "Pressure Sensor Out CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 58,
//   //             "Id": "FO.1.2",
//   //             "Name": "Pressure Sensor Out CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 89,
//   //             "Id": "LI.1",
//   //             "Name": "Press Sens In Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 92,
//   //             "Id": "LI.2",
//   //             "Name": "Press Sens In Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 90,
//   //             "Id": "LO.1",
//   //             "Name": "Press Sens Out Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 91,
//   //             "Id": "LO.2",
//   //             "Name": "Press Sens Out Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "07:00": [
//   //           {
//   //             "S_No": 56,
//   //             "Id": "FI.1.1",
//   //             "Name": "Pressure Sensor In CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 59,
//   //             "Id": "FI.1.2",
//   //             "Name": "Pressure Sensor In CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 57,
//   //             "Id": "FO.1.1",
//   //             "Name": "Pressure Sensor Out CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 58,
//   //             "Id": "FO.1.2",
//   //             "Name": "Pressure Sensor Out CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 89,
//   //             "Id": "LI.1",
//   //             "Name": "Press Sens In Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 92,
//   //             "Id": "LI.2",
//   //             "Name": "Press Sens In Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 90,
//   //             "Id": "LO.1",
//   //             "Name": "Press Sens Out Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 91,
//   //             "Id": "LO.2",
//   //             "Name": "Press Sens Out Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "08:00": [
//   //           {
//   //             "S_No": 56,
//   //             "Id": "FI.1.1",
//   //             "Name": "Pressure Sensor In CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 59,
//   //             "Id": "FI.1.2",
//   //             "Name": "Pressure Sensor In CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 57,
//   //             "Id": "FO.1.1",
//   //             "Name": "Pressure Sensor Out CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 58,
//   //             "Id": "FO.1.2",
//   //             "Name": "Pressure Sensor Out CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 89,
//   //             "Id": "LI.1",
//   //             "Name": "Press Sens In Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 92,
//   //             "Id": "LI.2",
//   //             "Name": "Press Sens In Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 90,
//   //             "Id": "LO.1",
//   //             "Name": "Press Sens Out Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 91,
//   //             "Id": "LO.2",
//   //             "Name": "Press Sens Out Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "09:00": [
//   //           {
//   //             "S_No": 56,
//   //             "Id": "FI.1.1",
//   //             "Name": "Pressure Sensor In CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 59,
//   //             "Id": "FI.1.2",
//   //             "Name": "Pressure Sensor In CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 57,
//   //             "Id": "FO.1.1",
//   //             "Name": "Pressure Sensor Out CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 58,
//   //             "Id": "FO.1.2",
//   //             "Name": "Pressure Sensor Out CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 89,
//   //             "Id": "LI.1",
//   //             "Name": "Press Sens In Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 92,
//   //             "Id": "LI.2",
//   //             "Name": "Press Sens In Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 90,
//   //             "Id": "LO.1",
//   //             "Name": "Press Sens Out Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 91,
//   //             "Id": "LO.2",
//   //             "Name": "Press Sens Out Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "11:00": [
//   //           {
//   //             "S_No": 56,
//   //             "Id": "FI.1.1",
//   //             "Name": "Pressure Sensor In CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 59,
//   //             "Id": "FI.1.2",
//   //             "Name": "Pressure Sensor In CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 57,
//   //             "Id": "FO.1.1",
//   //             "Name": "Pressure Sensor Out CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 58,
//   //             "Id": "FO.1.2",
//   //             "Name": "Pressure Sensor Out CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 89,
//   //             "Id": "LI.1",
//   //             "Name": "Press Sens In Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 92,
//   //             "Id": "LI.2",
//   //             "Name": "Press Sens In Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 90,
//   //             "Id": "LO.1",
//   //             "Name": "Press Sens Out Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 91,
//   //             "Id": "LO.2",
//   //             "Name": "Press Sens Out Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "12:00": [
//   //           {
//   //             "S_No": 56,
//   //             "Id": "FI.1.1",
//   //             "Name": "Pressure Sensor In CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 59,
//   //             "Id": "FI.1.2",
//   //             "Name": "Pressure Sensor In CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 57,
//   //             "Id": "FO.1.1",
//   //             "Name": "Pressure Sensor Out CFISI 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 58,
//   //             "Id": "FO.1.2",
//   //             "Name": "Pressure Sensor Out CFISI 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 89,
//   //             "Id": "LI.1",
//   //             "Name": "Press Sens In Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 92,
//   //             "Id": "LI.2",
//   //             "Name": "Press Sens In Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 90,
//   //             "Id": "LO.1",
//   //             "Name": "Press Sens Out Il 1.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 91,
//   //             "Id": "LO.2",
//   //             "Name": "Press Sens Out Il 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ]
//   //       }
//   //     },
//   //     {
//   //       "name": "Moisture Sensor",
//   //       "data": {
//   //         "01:00": [
//   //           {
//   //             "S_No": 74,
//   //             "Id": "SM.1.1",
//   //             "Name": "M1.1",
//   //             "Value": "0",
//   //             "Valve": "VL.1.1_VL.1.2_VL.1.3_VL.1.4_VL.1.5"
//   //           },
//   //           {
//   //             "S_No": 75,
//   //             "Id": "SM.1.2",
//   //             "Name": "M1.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 82,
//   //             "Id": "SM.2.1",
//   //             "Name": "Moisture Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 83,
//   //             "Id": "SM.2.2",
//   //             "Name": "Moisture Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           }
//   //         ],
//   //         "02:00": [
//   //           {
//   //             "S_No": 74,
//   //             "Id": "SM.1.1",
//   //             "Name": "M1.1",
//   //             "Value": "0",
//   //             "Valve": "VL.1.1_VL.1.2_VL.1.3_VL.1.4_VL.1.5"
//   //           },
//   //           {
//   //             "S_No": 75,
//   //             "Id": "SM.1.2",
//   //             "Name": "M1.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 82,
//   //             "Id": "SM.2.1",
//   //             "Name": "Moisture Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 83,
//   //             "Id": "SM.2.2",
//   //             "Name": "Moisture Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           }
//   //         ],
//   //         "03:00": [
//   //           {
//   //             "S_No": 74,
//   //             "Id": "SM.1.1",
//   //             "Name": "M1.1",
//   //             "Value": "0",
//   //             "Valve": "VL.1.1_VL.1.2_VL.1.3_VL.1.4_VL.1.5"
//   //           },
//   //           {
//   //             "S_No": 75,
//   //             "Id": "SM.1.2",
//   //             "Name": "M1.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 82,
//   //             "Id": "SM.2.1",
//   //             "Name": "Moisture Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 83,
//   //             "Id": "SM.2.2",
//   //             "Name": "Moisture Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           }
//   //         ],
//   //         "04:00": [
//   //           {
//   //             "S_No": 74,
//   //             "Id": "SM.1.1",
//   //             "Name": "M1.1",
//   //             "Value": "0",
//   //             "Valve": "VL.1.1_VL.1.2_VL.1.3_VL.1.4_VL.1.5"
//   //           },
//   //           {
//   //             "S_No": 75,
//   //             "Id": "SM.1.2",
//   //             "Name": "M1.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 82,
//   //             "Id": "SM.2.1",
//   //             "Name": "Moisture Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 83,
//   //             "Id": "SM.2.2",
//   //             "Name": "Moisture Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           }
//   //         ],
//   //         "05:00": [
//   //           {
//   //             "S_No": 74,
//   //             "Id": "SM.1.1",
//   //             "Name": "M1.1",
//   //             "Value": "0",
//   //             "Valve": "VL.1.1_VL.1.2_VL.1.3_VL.1.4_VL.1.5"
//   //           },
//   //           {
//   //             "S_No": 75,
//   //             "Id": "SM.1.2",
//   //             "Name": "M1.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 82,
//   //             "Id": "SM.2.1",
//   //             "Name": "Moisture Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 83,
//   //             "Id": "SM.2.2",
//   //             "Name": "Moisture Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           }
//   //         ],
//   //         "06:00": [
//   //           {
//   //             "S_No": 74,
//   //             "Id": "SM.1.1",
//   //             "Name": "M1.1",
//   //             "Value": "0",
//   //             "Valve": "VL.1.1_VL.1.2_VL.1.3_VL.1.4_VL.1.5"
//   //           },
//   //           {
//   //             "S_No": 75,
//   //             "Id": "SM.1.2",
//   //             "Name": "M1.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 82,
//   //             "Id": "SM.2.1",
//   //             "Name": "Moisture Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 83,
//   //             "Id": "SM.2.2",
//   //             "Name": "Moisture Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           }
//   //         ],
//   //         "07:00": [
//   //           {
//   //             "S_No": 74,
//   //             "Id": "SM.1.1",
//   //             "Name": "M1.1",
//   //             "Value": "0",
//   //             "Valve": "VL.1.1_VL.1.2_VL.1.3_VL.1.4_VL.1.5"
//   //           },
//   //           {
//   //             "S_No": 75,
//   //             "Id": "SM.1.2",
//   //             "Name": "M1.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 82,
//   //             "Id": "SM.2.1",
//   //             "Name": "Moisture Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 83,
//   //             "Id": "SM.2.2",
//   //             "Name": "Moisture Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           }
//   //         ],
//   //         "08:00": [
//   //           {
//   //             "S_No": 74,
//   //             "Id": "SM.1.1",
//   //             "Name": "M1.1",
//   //             "Value": "0",
//   //             "Valve": "VL.1.1_VL.1.2_VL.1.3_VL.1.4_VL.1.5"
//   //           },
//   //           {
//   //             "S_No": 75,
//   //             "Id": "SM.1.2",
//   //             "Name": "M1.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 82,
//   //             "Id": "SM.2.1",
//   //             "Name": "Moisture Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 83,
//   //             "Id": "SM.2.2",
//   //             "Name": "Moisture Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           }
//   //         ],
//   //         "09:00": [
//   //           {
//   //             "S_No": 74,
//   //             "Id": "SM.1.1",
//   //             "Name": "M1.1",
//   //             "Value": "0",
//   //             "Valve": "VL.1.1_VL.1.2_VL.1.3_VL.1.4_VL.1.5"
//   //           },
//   //           {
//   //             "S_No": 75,
//   //             "Id": "SM.1.2",
//   //             "Name": "M1.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 82,
//   //             "Id": "SM.2.1",
//   //             "Name": "Moisture Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 83,
//   //             "Id": "SM.2.2",
//   //             "Name": "Moisture Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           }
//   //         ],
//   //         "11:00": [
//   //           {
//   //             "S_No": 74,
//   //             "Id": "SM.1.1",
//   //             "Name": "M1.1",
//   //             "Value": "0",
//   //             "Valve": "VL.1.1_VL.1.2_VL.1.3_VL.1.4_VL.1.5"
//   //           },
//   //           {
//   //             "S_No": 75,
//   //             "Id": "SM.1.2",
//   //             "Name": "M1.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 82,
//   //             "Id": "SM.2.1",
//   //             "Name": "Moisture Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 83,
//   //             "Id": "SM.2.2",
//   //             "Name": "Moisture Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           }
//   //         ],
//   //         "12:00": [
//   //           {
//   //             "S_No": 74,
//   //             "Id": "SM.1.1",
//   //             "Name": "M1.1",
//   //             "Value": "0",
//   //             "Valve": "VL.1.1_VL.1.2_VL.1.3_VL.1.4_VL.1.5"
//   //           },
//   //           {
//   //             "S_No": 75,
//   //             "Id": "SM.1.2",
//   //             "Name": "M1.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 82,
//   //             "Id": "SM.2.1",
//   //             "Name": "Moisture Sensor 2.1",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           },
//   //           {
//   //             "S_No": 83,
//   //             "Id": "SM.2.2",
//   //             "Name": "Moisture Sensor 2.2",
//   //             "Value": "0",
//   //             "Valve": ""
//   //           }
//   //         ]
//   //       }
//   //     },
//   //     {
//   //       "name": "Water Meter",
//   //       "data": {
//   //         "01:00": [
//   //           {
//   //             "S_No": 78,
//   //             "Id": "LW.1",
//   //             "Name": "Water Meter IL 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 79,
//   //             "Id": "LW.2",
//   //             "Name": "Water Meter IL 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "02:00": [
//   //           {
//   //             "S_No": 78,
//   //             "Id": "LW.1",
//   //             "Name": "Water Meter IL 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 79,
//   //             "Id": "LW.2",
//   //             "Name": "Water Meter IL 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "03:00": [
//   //           {
//   //             "S_No": 78,
//   //             "Id": "LW.1",
//   //             "Name": "Water Meter IL 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 79,
//   //             "Id": "LW.2",
//   //             "Name": "Water Meter IL 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "04:00": [
//   //           {
//   //             "S_No": 78,
//   //             "Id": "LW.1",
//   //             "Name": "Water Meter IL 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 79,
//   //             "Id": "LW.2",
//   //             "Name": "Water Meter IL 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "05:00": [
//   //           {
//   //             "S_No": 78,
//   //             "Id": "LW.1",
//   //             "Name": "Water Meter IL 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 79,
//   //             "Id": "LW.2",
//   //             "Name": "Water Meter IL 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "06:00": [
//   //           {
//   //             "S_No": 78,
//   //             "Id": "LW.1",
//   //             "Name": "Water Meter IL 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 79,
//   //             "Id": "LW.2",
//   //             "Name": "Water Meter IL 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "07:00": [
//   //           {
//   //             "S_No": 78,
//   //             "Id": "LW.1",
//   //             "Name": "Water Meter IL 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 79,
//   //             "Id": "LW.2",
//   //             "Name": "Water Meter IL 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "08:00": [
//   //           {
//   //             "S_No": 78,
//   //             "Id": "LW.1",
//   //             "Name": "Water Meter IL 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 79,
//   //             "Id": "LW.2",
//   //             "Name": "Water Meter IL 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "09:00": [
//   //           {
//   //             "S_No": 78,
//   //             "Id": "LW.1",
//   //             "Name": "Water Meter IL 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 79,
//   //             "Id": "LW.2",
//   //             "Name": "Water Meter IL 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "11:00": [
//   //           {
//   //             "S_No": 78,
//   //             "Id": "LW.1",
//   //             "Name": "Water Meter IL 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 79,
//   //             "Id": "LW.2",
//   //             "Name": "Water Meter IL 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "12:00": [
//   //           {
//   //             "S_No": 78,
//   //             "Id": "LW.1",
//   //             "Name": "Water Meter IL 1.1",
//   //             "Value": "0.00",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 79,
//   //             "Id": "LW.2",
//   //             "Name": "Water Meter IL 2.1",
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ]
//   //       }
//   //     },
//   //     {
//   //       "name": "Power Supply",
//   //       "data": {
//   //         "01:00": [
//   //           {
//   //             "S_No": 80,
//   //             "Id": "PSP.1",
//   //             "Name": null,
//   //             "Value": "27",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 81,
//   //             "Id": "PSP.2",
//   //             "Name": null,
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "02:00": [
//   //           {
//   //             "S_No": 80,
//   //             "Id": "PSP.1",
//   //             "Name": null,
//   //             "Value": "27",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 81,
//   //             "Id": "PSP.2",
//   //             "Name": null,
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "03:00": [
//   //           {
//   //             "S_No": 80,
//   //             "Id": "PSP.1",
//   //             "Name": null,
//   //             "Value": "27",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 81,
//   //             "Id": "PSP.2",
//   //             "Name": null,
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "04:00": [
//   //           {
//   //             "S_No": 80,
//   //             "Id": "PSP.1",
//   //             "Name": null,
//   //             "Value": "27",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 81,
//   //             "Id": "PSP.2",
//   //             "Name": null,
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "05:00": [
//   //           {
//   //             "S_No": 80,
//   //             "Id": "PSP.1",
//   //             "Name": null,
//   //             "Value": "28",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 81,
//   //             "Id": "PSP.2",
//   //             "Name": null,
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "06:00": [
//   //           {
//   //             "S_No": 80,
//   //             "Id": "PSP.1",
//   //             "Name": null,
//   //             "Value": "27",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 81,
//   //             "Id": "PSP.2",
//   //             "Name": null,
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "07:00": [
//   //           {
//   //             "S_No": 80,
//   //             "Id": "PSP.1",
//   //             "Name": null,
//   //             "Value": "27",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 81,
//   //             "Id": "PSP.2",
//   //             "Name": null,
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "08:00": [
//   //           {
//   //             "S_No": 80,
//   //             "Id": "PSP.1",
//   //             "Name": null,
//   //             "Value": "26",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 81,
//   //             "Id": "PSP.2",
//   //             "Name": null,
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "09:00": [
//   //           {
//   //             "S_No": 80,
//   //             "Id": "PSP.1",
//   //             "Name": null,
//   //             "Value": "27",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 81,
//   //             "Id": "PSP.2",
//   //             "Name": null,
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "11:00": [
//   //           {
//   //             "S_No": 80,
//   //             "Id": "PSP.1",
//   //             "Name": null,
//   //             "Value": "26",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 81,
//   //             "Id": "PSP.2",
//   //             "Name": null,
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ],
//   //         "12:00": [
//   //           {
//   //             "S_No": 80,
//   //             "Id": "PSP.1",
//   //             "Name": null,
//   //             "Value": "26",
//   //             "Valve": null
//   //           },
//   //           {
//   //             "S_No": 81,
//   //             "Id": "PSP.2",
//   //             "Name": null,
//   //             "Value": "0",
//   //             "Valve": null
//   //           }
//   //         ]
//   //       }
//   //     }
//   //   ]
//   // };
//   // await Future.delayed(Duration(seconds: 3));
//   // return sampleData['data'];
// }