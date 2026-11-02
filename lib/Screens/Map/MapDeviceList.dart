import 'dart:convert';

import 'package:flutter/material.dart';
 import 'package:provider/provider.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/snack_bar.dart';
import 'oro_map/SetSelectAreatorLocation.dart';
import 'googlemap_model.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';


class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen(
      {super.key,
        required this.userId,
        required this.customerId,
        required this.controllerId,
        required this.imeiNo});
  final int userId, customerId, controllerId;
  final String imeiNo;

  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {


  late MqttPayloadProvider mqttPayloadProvider;

  final MapConfigModel _mapConfigModel = MapConfigModel();

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchData();
      // mqttPayloadProvider.updateMapData(jsonString);
    });

  }


   Future<void> fetchData() async {
     try{
       final Repository repository = Repository(HttpService());
       var getUserDetails = await repository.getgeography({
         "userId": widget.customerId,
         "controllerId" :  widget.controllerId
       });
       AppLog.log('getUserDetails${getUserDetails.body}');
       // final jsonData = jsonDecode(getUserDetails.body);
       if (getUserDetails.statusCode == 200) {
         setState(() {
           var jsonData = jsonDecode(getUserDetails.body);
           AppLog.log('jsonData$jsonData');
            mqttPayloadProvider.updateMapData(jsonData);
         });
       } else {
         //_showSnackBar(response.body);
       }
     }
     catch (e, stackTrace) {
       mqttPayloadProvider.httpError = true;
       AppLog.log(' Error overAll getData => ${e.toString()}');
       AppLog.log(' trace overAll getData  => $stackTrace');
     }
    }



   @override
   Widget build(BuildContext context) {
     return Consumer<MqttPayloadProvider>(
       builder: (context, mqttProvider, _) {
         final deviceList = mqttProvider.mapModelInstance.data?.deviceList;

         AppLog.log("deviceList:->${deviceList.toString()}");

         if (deviceList == null || deviceList.isEmpty) {
           return Scaffold(
             appBar: AppBar(title: const Text('Map Device List')),
             body: const Center(child: Text('Map Device list is empty')),
           );
         }
          return Scaffold(
           appBar: AppBar(title: const Text('Map Device List'),automaticallyImplyLeading: true),
           body: SingleChildScrollView(
             child: Padding(
               padding: const EdgeInsets.all(10.0),
               child: Column(
                 children: [
                    Row(
                      children: [
                        ///MapScreenall
                        // TextButton.icon(
                        //   onPressed: () {
                        //     Navigator.of(context).push(MaterialPageRoute(
                        //       builder: (context) => MapScreenall(userId: widget.userId, customerId: widget.customerId, controllerId: widget.controllerId, imeiNo: widget.imeiNo,),
                        //     ));
                        //   },
                        //
                        //   icon: Icon(Icons.edit_location_alt,color: Colors.white,),
                        //   label: Text('all'),
                        // ),
                        const Spacer(),
                        TextButton.icon(
                         onPressed: () {
                           // Navigator.of(context).push(MaterialPageRoute(
                           //   builder: (context) => MapScreendevice(),
                           // ));
                         },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Theme.of(context).primaryColor,// text color
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                         icon: const Icon(Icons.edit_location_alt,color: Colors.white,),
                         label: const Text('Edit Node location'),),
                      ],
                    ),
                   Wrap(
                     spacing: 10.0,
                     runSpacing: 10.0,
                     children: List.generate(deviceList.length, (index) {
                       final device = deviceList[index];

                       return InkWell(
                         onTap: () {
                           Navigator.of(context).push(MaterialPageRoute(
                             builder: (context) => MapScreen(index: index),
                           ));
                         },
                         child: Card(
                           margin: const EdgeInsets.all(8.0),
                           elevation: 8,
                           shadowColor: Colors.blue,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(10.0),
                           ),
                           child: Padding(
                             padding: const EdgeInsets.all(16.0),
                             child: Row(
                               children: [
                                 IconButton(
                                   icon: Image.asset('assets/png/map.png'),
                                   onPressed: () {},
                                 ),
                                 Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       '${device.deviceName ?? "Unknown"} (${device.connectedObject?.length ?? 0})',
                                       style: const TextStyle(
                                         fontSize: 18.0,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                     const SizedBox(height: 8.0),
                                     Text('Device ID: ${device.deviceId ?? "-"}'),
                                     Text('Location: ${device.geography!.lat },${device.geography!.long }'),
                                     Text('Model: ${device.modelName ?? "-"}'),
                                     Text('Category: ${device.categoryName ?? "-"}'),
                                   ],
                                 ),
                                ],
                             ),
                           ),
                         ),
                       );
                     }),
                   ),
                 ],
               ),
             ),
           ),
           floatingActionButton: FloatingActionButton(
             backgroundColor: Theme.of(context).primaryColorDark,
             foregroundColor: Colors.white,
             onPressed: () async {
               setState(() {
                 updateMapLocation();
               });
             },
             tooltip: 'Send',
             child: const Icon(Icons.send),
           ),
         );
       },
     );
   }

   updateMapLocation() async {

     final Repository repository = Repository(HttpService());
var data = mqttPayloadProvider.mapModelInstance.data?.toJson();
           AppLog.log("send data -> $data ");
     Map<String, dynamic> body = {
       "userId": widget.customerId,
       "controllerId": widget.controllerId,
       "userGeography": data!['deviceList'],
       "createUser": widget.userId
     };
     AppLog.log(body);
     var getUserDetails = await repository.creategeography(body);
     var jsonDataResponse = jsonDecode(getUserDetails.body);
      AppLog.log(jsonDataResponse);
      GlobalSnackBar.show(context, jsonDataResponse['message'], 200);
   }
}
