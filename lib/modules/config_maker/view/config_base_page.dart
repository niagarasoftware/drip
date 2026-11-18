import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/device_model.dart';
import '../state_management/config_maker_provider.dart';
import 'config_mobile_view.dart';
import 'config_web_view.dart';

enum ConfigMakerTabs {deviceList, productLimit, connection, siteConfigure}

class ConfigBasePage extends StatefulWidget {
  final Map<String, dynamic> masterData;
  final bool fromDashboard;
  const ConfigBasePage({super.key, required this.masterData, required this.fromDashboard});

  @override
  State<ConfigBasePage> createState() => _ConfigBasePageState();
}

class _ConfigBasePageState extends State<ConfigBasePage> {
  late ConfigMakerProvider configPvd;
  late Future<List<DeviceModel>> listOfDevices;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    debugPrint("widget.masterData :: ${jsonEncode(widget.masterData)}");
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
    // Lk farm
    // listOfDevices = configPvd.fetchData({"userId":3,"customerId":4,"controllerId":1,"deviceId":"E8FB1C3501D1","deviceName":"xMm","categoryId":1,"categoryName":"xMm","modelId":1,"modelName":"xMm1000_R","groupId":1,"groupName":"LK Demo","connectingObjectId":["1","2","3","4","1","2","3","4"]});
    // listOfDevices = configPvd.fetchData({"userId":3,"customerId":4,"controllerId":8,"deviceId":"223344AAEEFF","deviceName":"xMp","categoryId":2,"categoryName":"xMp","modelId":9,"modelName":"xMp2000GOOO","groupId":1,"groupName":"LK Demo","connectingObjectId":["5","22","24","26","40"],});
    // listOfDevices = configPvd.fetchData({"userId":3,"customerId":4,"controllerId":13,"deviceId":"E8EB1B04DB38","deviceName":"xMp","categoryId":2,"categoryName":"xMp","modelId":9,"modelName":"xMp2000GOOO","groupId":1,"groupName":"LK Demo","connectingObjectId":["5","22","24","26","40"]});

    // Testing purpose
    // listOfDevices = configPvd.fetchData({"userId":3,"customerId":8,"controllerId":23,"deviceId":"2CCF6773D07D","deviceName":"xMm","categoryId":1,"categoryName":"xMm","modelId":4,"modelName":"xMm2000ROOL","groupId":4,"groupName":"TESTING PURPOSE","connectingObjectId":["1","2","3","4","-"]});
    // listOfDevices = configPvd.fetchData({"userId":3,"customerId":8,"controllerId":75,"deviceId":"AACCEEAAEEDD","deviceName":"xMp","categoryId":2,"categoryName":"xMp","modelId":48,"modelName":"xMp1000GO3O","groupId":4,"groupName":"TESTING PURPOSE","connectingObjectId":["5","13","22","24","26","40"]});
    // listOfDevices = configPvd.fetchData({"userId":3,"customerId":8,"controllerId":115,"deviceId":"866308064396","deviceName":"xMm","categoryId":1,"categoryName":"xMm","modelId":3,"modelName":"xMm1000ROOE","groupId":4,"groupName":"TESTING PURPOSE","connectingObjectId":["1","2","3","4","13","14","22","23","24","26","40","41"]});

    // New Site
    // listOfDevices = configPvd.fetchData({"userId":3,"customerId":6,"controllerId":9,"productId":9,"deviceId":"2CCF6773D07D","deviceName":"xMm","categoryId":1,"categoryName":"xMm","modelId":1,"modelName":"xMm1000ROOO","groupId":2,"groupName":"Testing site","connectingObjectId":["1","2","3","4","-"]});
    listOfDevices = configPvd.fetchData(widget.masterData, widget.fromDashboard);
  }

  @override
  Widget build(BuildContext context) {
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: true);
    double screenWidth = MediaQuery.of(context).size.width;
    return FutureBuilder<List<DeviceModel>>(
      future: listOfDevices,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          List<DeviceModel> listOfDevices = snapshot.data!;
          return screenWidth > 500 ?
          Material(
            child: ConfigWebView(
                listOfDevices: listOfDevices
            ),
          ) : ConfigMobileView(
              listOfDevices: listOfDevices
          );
        } else {
          return const Text('No data');
        }
      },
    );
  }
}

String getTabName(ConfigMakerTabs configMakerTabs) {
  switch (configMakerTabs) {
    case ConfigMakerTabs.deviceList:
      return 'Device List';
    case ConfigMakerTabs.productLimit:
      return 'Product Limit';
    case ConfigMakerTabs.connection:
      return 'Connection';
    case ConfigMakerTabs.siteConfigure:
      return 'Site Configure';
    }
}