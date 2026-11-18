import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';

import '../../../Constants/dialog_boxes.dart';
import '../state_management/ble_service.dart';
import 'node_not_get_live.dart';

class Calibration extends StatefulWidget {
  final Map<String, dynamic> nodeData;
  const Calibration({super.key, required this.nodeData});

  @override
  State<Calibration> createState() => _CalibrationState();
}

class _CalibrationState extends State<Calibration> {
  late BleProvider bleService;
  List<dynamic> ecSensorList = [];
  List<dynamic> phSensorList = [];
  List<dynamic> waterMeter = [];
  bool loading = false;
  String ec1 = '';
  String ec_1 = '';
  String ec2 = '';
  String ec_2 = '';
  String ph1 = '';
  String ph_1 = '';
  String ph2 = '';
  String ph_2 = '';

  final inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.black54),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.black54),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
  );

  @override
  void initState() {
    super.initState();
    bleService = Provider.of<BleProvider>(context, listen: false);
    ecSensorList = (bleService.nodeDataFromServer['configObject'] as List<dynamic>).where((e) => e['objectId'] == AppConstants.ecObjectId).toList();
    phSensorList = (bleService.nodeDataFromServer['configObject'] as List<dynamic>).where((e) => e['objectId'] == AppConstants.phObjectId).toList();
    waterMeter = (bleService.nodeDataFromServer['configObject'] as List<dynamic>).where((e) => e['objectId'] == AppConstants.waterMeterObjectId).toList();
  }

  void loadingDialog(String message)async{
    showDialog(
        barrierDismissible: false,
        context: context, builder: (context){
      return const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            spacing: 20,
            children: [
              CircularProgressIndicator(),
              Text('Please wait...')
            ],
          ),
        ),
      );
    }
    );
    await Future.delayed(const Duration(seconds: 2), (){
      Navigator.pop(context);
    });
    simpleDialogBox(context: context, title: 'Success', message: message);
  }

  @override
  Widget build(BuildContext context) {
    bleService = Provider.of<BleProvider>(context, listen: true);
    int keyCount = bleService.nodeDataFromHw.keys.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibration'),
      ),
      body: keyCount > 4
          ? SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 20,
            children: [
              if(waterMeter.isNotEmpty)
                cumulativeWidget(),
              batteryCalibration(),
              if(bleService.nodeDataFromHw["MID"] != "58")
                for(int ec = 0;ec < (["57", "58"].contains(bleService.nodeDataFromHw['MID']) ? 1 : ecSensorList.length);ec++)
                  ecSensorWidget(
                      sensorCount: ec,
                      sensorName: ecSensorList[ec]['name']
                  ),
              if(bleService.nodeDataFromHw["MID"] != "57")
                for(int ph = 0;ph < (["57", "58"].contains(bleService.nodeDataFromHw['MID']) ? 1 : phSensorList.length);ph++)
                  phSensorWidget(
                      sensorCount: ph,
                      sensorName: phSensorList[ph]['name']
                  ),
              const SizedBox(height: 50,)
            ],
          ),
        ),
      )
          : NodeNotGetLive(
          loading: loading,
          onPressed: ()async{
            setState(() {
              loading = true;
            });
            bleService.onRefresh();
            int delaySeconds = 5;
            for(var second = 0;second < delaySeconds;second++){
              if(bleService.nodeDataFromHw.containsKey('BAT')){
                break;
              }
              await Future.delayed(const Duration(seconds: 1));
              if(second == (delaySeconds - 1)){
                setState(() {
                  loading = false;
                });
              }
            }
          }
          ),
    );
  }

  Widget cumulativeWidget(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 8),
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5) ,topRight: Radius.circular(27.5), ),
              color: Theme.of(context).primaryColorLight
          ),
          child: Center(
            child: Text('${waterMeter[0]['name']}',style: const TextStyle(color: Colors.white, fontSize: 14),),
          ),
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
              border: Border.all(width: 0.5, color: Theme.of(context).primaryColorLight),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 4,
                    spreadRadius: 0,
                    color: const Color(0xff8B8282).withValues(alpha: 0.2)
                )
              ]
          ),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            child: Column(
              spacing: 20,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: bleService.cumulativeController,
                        keyboardType: TextInputType.number,
                        decoration: inputDecoration.copyWith(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              'assets/Images/Svg/objectId_${AppConstants.waterMeterObjectId}.svg',
                              height: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle, // or BoxShape.rectangle
                      ),
                      child: IconButton(
                        onPressed: () {
                          bleService.onRefresh();
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: ElevatedButton.icon(
                        onPressed: (){
                          var payload = '${bleService.nodeDataFromServer['calibrationSetting']['cumulative']}${bleService.cumulativeController.text}:';
                          var sumOfAscii = 0;
                          for(var i in payload.split('')){
                            var bytes = i.codeUnitAt(0);
                            sumOfAscii += bytes;
                          }
                          var addFirst = '';
                          for(var i = 0;i < (3-('${sumOfAscii % 256}'.length));i++){
                            addFirst += '0';
                          }
                          payload += '$addFirst${sumOfAscii % 256}:\r';
                          List<int> fullData = [];
                          for(var i in payload.split('')){
                            var bytes = i.codeUnitAt(0);
                            fullData.add(bytes);
                          }
                          if (kDebugMode) {
                            print('sumOfAscii : $sumOfAscii');
                            print('crc : ${sumOfAscii % 256}');
                            print('fullData : ${fullData}');
                            print('payload : ${payload}');
                          }

                          bleService.sendDataToHw(fullData);
                          loadingDialog('Cumulative setting sent successfully...');
                        },
                        icon: const Icon(Icons.send, color: Colors.white,),
                        label: const Text("Send", style: TextStyle(color: Colors.white),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorLight,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget batteryCalibration(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 8),
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5) ,topRight: Radius.circular(27.5), ),
              color: Theme.of(context).primaryColorLight
          ),
          child: const Center(
            child: Text('Battery Calibration',style: TextStyle(color: Colors.white, fontSize: 14),),
          ),
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
              border: Border.all(width: 0.5, color: Theme.of(context).primaryColorLight),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 4,
                    spreadRadius: 0,
                    color: const Color(0xff8B8282).withValues(alpha: 0.2)
                )
              ]
          ),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            child: Column(
              spacing: 20,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: bleService.batteryController,
                        keyboardType: TextInputType.number,
                        decoration: inputDecoration.copyWith(
                          prefixIcon: const Icon(Icons.battery_6_bar),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle, // or BoxShape.rectangle
                      ),
                      child: IconButton(
                        onPressed: () {
                          bleService.onRefresh();
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: ElevatedButton.icon(
                        onPressed: (){
                          var payload = '${bleService.nodeDataFromServer['settingCommand']['sendBatterySettingCommand']}${bleService.batteryController.text}:';
                          var sumOfAscii = 0;
                          for(var i in payload.split('')){
                            var bytes = i.codeUnitAt(0);
                            sumOfAscii += bytes;
                          }
                          var addFirst = '';
                          for(var i = 0;i < (3-('${sumOfAscii % 256}'.length));i++){
                            addFirst += '0';
                          }
                          payload += '$addFirst${sumOfAscii % 256}:\r';
                          List<int> fullData = [];
                          for(var i in payload.split('')){
                            var bytes = i.codeUnitAt(0);
                            fullData.add(bytes);
                          }
                          if (kDebugMode) {
                            print('sumOfAscii : $sumOfAscii');
                            print('crc : ${sumOfAscii % 256}');
                            print('fullData : ${fullData}');
                            print('payload : ${payload}');
                          }

                          bleService.sendDataToHw(fullData);
                          loadingDialog('Battery calibration setting sent successfully...');
                        },
                        icon: const Icon(Icons.send, color: Colors.white,),
                        label: const Text("Send", style: TextStyle(color: Colors.white),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorLight,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget ecSensorWidget({
    required int sensorCount,
    required String sensorName,
  }){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 8),
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5) ,topRight: Radius.circular(27.5), ),
              color: Theme.of(context).primaryColorLight
          ),
          child: Center(
            child: Text(sensorName,style: const TextStyle(color: Colors.white, fontSize: 14),),
          ),
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
              border: Border.all(width: 0.5, color: Theme.of(context).primaryColorLight),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 4,
                    spreadRadius: 0,
                    color: const Color(0xff8B8282).withValues(alpha: 0.2)
                )
              ]
          ),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 20,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calibration Factor 1',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6),
                          TextFormField(
                            controller: sensorCount == 0 ? bleService.ec1FactorController : bleService.ec2FactorController,
                            decoration: InputDecoration(
                              hintText: 'Enter value',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh, color: Colors.white),
                        onPressed: (){
                          bleService.onRefresh();
                          setState(() {
                            if(sensorCount == 0){
                              bleService.calibrationEc1 = 'ec${sensorCount+1}';
                              bleService.calibrationEc2 = '';
                            }else{
                              bleService.calibrationEc2 = 'ec${sensorCount+1}';
                              bleService.calibrationEc1 = '';
                            }
                          });
                          if(sensorCount == 0){
                            if (kDebugMode) {
                              print("blePvd.calibrationEc1 : ${bleService.calibrationEc1}");
                            }
                          }else{
                            if (kDebugMode) {
                              print("blePvd.calibrationEc2 : ${bleService.calibrationEc2}");
                            }

                          }
                          loadingDialog('Get @${sensorCount == 0 ? bleService.ec1FactorController.text : bleService.ec2FactorController.text} Command Send Successfully..');
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensor Value',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6),
                          TextFormField(
                            controller: sensorCount == 0 ? bleService.ec1Controller : bleService.ec2Controller,
                            decoration: InputDecoration(
                              hintText: 'Enter value',
                              suffix: Text('(${sensorCount == 0 ? bleService.nodeDataFromHw['EC1_1'] : bleService.nodeDataFromHw['EC2_1']})'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calibration Factor 2',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6),
                          TextFormField(
                            controller: sensorCount == 0 ? bleService.ec1_FactorController : bleService.ec2_FactorController,
                            decoration: InputDecoration(
                              hintText: 'Enter value',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh, color: Colors.white),
                        onPressed: (){
                          bleService.onRefresh();
                          setState(() {
                            if(sensorCount == 0){
                              bleService.calibrationEc1 = 'ec_${sensorCount+1}';
                              bleService.calibrationEc2 = '';

                            }else{
                              bleService.calibrationEc2 = 'ec_${sensorCount+1}';
                              bleService.calibrationEc1 = '';
                            }
                          });
                          if(sensorCount == 0){
                            if (kDebugMode) {
                              print("blePvd.calibrationEc1 : ${bleService.calibrationEc1}");
                            }
                          }else{
                            if (kDebugMode) {
                              print("blePvd.calibrationEc2 : ${bleService.calibrationEc2}");
                            }

                          }
                          loadingDialog('Get @ ${sensorCount == 0 ? bleService.ec1_FactorController.text : bleService.ec2_FactorController.text} Command Send Successfully..');
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensor Value',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6),
                          TextFormField(
                            controller: sensorCount == 0 ? bleService.ec1_Controller : bleService.ec2_Controller,
                            decoration: InputDecoration(
                              suffix: Text('(${sensorCount == 0 ? bleService.nodeDataFromHw['EC1_2'] : bleService.nodeDataFromHw['EC2_2']})'),
                              hintText: 'Enter value',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if(["57", "58"].contains(bleService.nodeDataFromHw['MID']))
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calibration Factor 3',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 6),
                            TextFormField(
                              controller: sensorCount == 0 ? bleService.ec1__FactorController : bleService.ec2__FactorController,
                              decoration: InputDecoration(
                                hintText: 'Enter value',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          onPressed: (){
                            bleService.onRefresh();
                            setState(() {
                              if(sensorCount == 0){
                                bleService.calibrationEc1 = 'ec__${sensorCount+1}';
                                bleService.calibrationEc2 = '';

                              }else{
                                bleService.calibrationEc2 = 'ec__${sensorCount+1}';
                                bleService.calibrationEc1 = '';
                              }
                            });
                            if(sensorCount == 0){
                              if (kDebugMode) {
                                print("blePvd.calibrationEc1 : ${bleService.calibrationEc1}");
                              }
                            }else{
                              if (kDebugMode) {
                                print("blePvd.calibrationEc2 : ${bleService.calibrationEc2}");
                              }

                            }
                            loadingDialog('Get @ ${sensorCount == 0 ? bleService.ec1__FactorController.text : bleService.ec2__FactorController.text} Command Send Successfully..');
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sensor Value',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 6),
                            TextFormField(
                              controller: sensorCount == 0 ? bleService.ec1__Controller : bleService.ec2__Controller,
                              decoration: InputDecoration(
                                suffix: Text('(${sensorCount == 0 ? bleService.nodeDataFromHw['EC1_3'] : bleService.nodeDataFromHw['EC2_3']})'),
                                hintText: 'Enter value',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: 100,
                    child: ElevatedButton.icon(
                      onPressed: (){
                        var one = sensorCount == 0 ? bleService.ec1Controller.text : bleService.ec2Controller.text;
                        var two = sensorCount == 0 ? bleService.ec1_Controller.text : bleService.ec2_Controller.text;
                        var three = sensorCount == 0 ? bleService.ec1__Controller.text : bleService.ec2__Controller.text;
                        var factor1 = sensorCount == 0 ? bleService.ec1FactorController.text : bleService.ec2FactorController.text;
                        var factor2 = sensorCount == 0 ? bleService.ec1_FactorController.text : bleService.ec2_FactorController.text;
                        var factor3 = sensorCount == 0 ? bleService.ec1__FactorController.text : bleService.ec2__FactorController.text;
                        setState(() {
                          if(sensorCount == 0){
                            ec1 = one;
                            ec_1 = two;
                          }else{
                            ec2 = one;
                            ec_2 = two;
                          }
                        });
                        var payload = '${bleService.nodeDataFromServer['calibrationSetting']['ec${sensorCount+1}Submit']}${checkEmptyValue(one)}:${checkEmptyValue(two)}:${checkEmptyValue(three)}:${checkEmptyValue(factor1)}:${checkEmptyValue(factor2)}:${checkEmptyValue(factor3)}:';
                        var sumOfAscii = 0;
                        for(var i in payload.split('')){
                          var bytes = i.codeUnitAt(0);
                          sumOfAscii += bytes;
                        }
                        var crcToByteLen = '${sumOfAscii % 256}';
                        var balance = '';
                        for(var i = 0;i < (3 - crcToByteLen.length);i++){
                          balance += '0';
                        }
                        payload += '$balance$crcToByteLen:\r';
                        List<int> fullData = [];
                        for(var i in payload.split('')){
                          var bytes = i.codeUnitAt(0);
                          fullData.add(bytes);
                        }
                        if (kDebugMode) {
                          print('sumOfAscii : $sumOfAscii');
                          print('crc : ${sumOfAscii % 256}');
                          print('fullData : ${fullData}');
                          print('payload : ${payload}');
                        }
                        bleService.sendDataToHw(fullData);
                        loadingDialog('Ec calibration setting sent successfully...');

                      },
                      icon: const Icon(Icons.send, color: Colors.white,),
                      label: const Text("Send", style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColorLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  String checkEmptyValue(String value){
    return value.isEmpty ? '0': value;
  }

  Widget phSensorWidget({
    required int sensorCount,
    required String sensorName,
  }){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 250,
          padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 8),
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5) ,topRight: Radius.circular(27.5), ),
              color: Theme.of(context).primaryColorLight
          ),
          child: Center(
            child: Text(sensorName,style: const TextStyle(color: Colors.white, fontSize: 14),),
          ),
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
              border: Border.all(width: 0.5, color: Theme.of(context).primaryColorLight),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 4,
                    spreadRadius: 0,
                    color: const Color(0xff8B8282).withValues(alpha: 0.2)
                )
              ]
          ),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 20,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calibration Factor 1',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6),
                          TextFormField(
                            controller: sensorCount == 0 ? bleService.ph1FactorController : bleService.ph2FactorController,
                            decoration: InputDecoration(
                              hintText: 'Enter value',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh, color: Colors.white),
                        onPressed: (){
                          bleService.onRefresh();
                          setState(() {
                            if(sensorCount == 0){
                              bleService.calibrationPh1 = 'ph${sensorCount+1}';
                              bleService.calibrationPh2 = '';
                            }else{
                              print("update ph 2");
                              bleService.calibrationPh2 = 'ph${sensorCount+1}';
                              bleService.calibrationPh1 = '';
                            }
                          });
                          if(sensorCount == 0){
                            if (kDebugMode) {
                              print("blePvd.calibrationPh1 : ${bleService.calibrationPh1}");
                            }
                          }else{
                            if (kDebugMode) {
                              print("blePvd.calibrationPh2 : ${bleService.calibrationPh2}");
                            }
                          }
                          loadingDialog('Get ${sensorCount == 0 ? bleService.ph1FactorController.text : bleService.ph2FactorController.text} Command Send Successfully..');
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensor Value',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6),
                          TextFormField(
                            controller: sensorCount == 0 ? bleService.ph1Controller : bleService.ph2Controller,
                            decoration: InputDecoration(
                              hintText: 'Enter value',
                              suffix: Text('(${sensorCount == 0 ? bleService.nodeDataFromHw['PH1_1'] : bleService.nodeDataFromHw['PH2_1']})'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calibration Factor 2',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6),
                          TextFormField(
                            controller: sensorCount == 0 ? bleService.ph1_FactorController : bleService.ph2_FactorController,
                            decoration: InputDecoration(
                              hintText: 'Enter value',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh, color: Colors.white),
                        onPressed: (){
                          bleService.onRefresh();
                          setState(() {
                            if(sensorCount == 0){
                              bleService.calibrationPh1 = 'ph_${sensorCount+1}';
                              bleService.calibrationPh2 = '';

                            }else{
                              bleService.calibrationPh2 = 'ph_${sensorCount+1}';
                              bleService.calibrationPh1 = '';
                            }
                          });
                          if(sensorCount == 0){
                            if (kDebugMode) {
                              print("blePvd.calibrationPh1 : ${bleService.calibrationPh1}");
                            }
                          }else{
                            if (kDebugMode) {
                              print("blePvd.calibrationPh2 : ${bleService.calibrationPh2}");
                            }

                          }
                          loadingDialog('Get @ ${sensorCount == 0 ? bleService.ph1_FactorController.text : bleService.ph2_FactorController.text} Command Send Successfully..');
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensor Value',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6),
                          TextFormField(
                            controller: sensorCount == 0 ? bleService.ph1_Controller : bleService.ph2_Controller,
                            decoration: InputDecoration(
                              suffix: Text('(${sensorCount == 0 ? bleService.nodeDataFromHw['PH1_2'] : bleService.nodeDataFromHw['PH2_2']})'),
                              hintText: 'Enter value',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: 100,
                    child: ElevatedButton.icon(
                      onPressed: (){
                        var one = sensorCount == 0 ? bleService.ph1Controller.text : bleService.ph2Controller.text;
                        var two = sensorCount == 0 ? bleService.ph1_Controller.text : bleService.ph2_Controller.text;
                        var three = sensorCount == 0 ? bleService.ph1_Controller.text : bleService.ph2_Controller.text;
                        var factor1 = sensorCount == 0 ? bleService.ph1FactorController.text : bleService.ph2FactorController.text;
                        var factor2 = sensorCount == 0 ? bleService.ph1_FactorController.text : bleService.ph2_FactorController.text;
                        setState(() {
                          if(sensorCount == 0){
                            ph1 = one;
                            ph_1 = two;
                          }else{
                            ph2 = one;
                            ph_2 = two;
                          }
                        });
                        var payload = '${bleService.nodeDataFromServer['calibrationSetting']['ph${sensorCount+1}Submit']}${checkEmptyValue(one)}:${checkEmptyValue(two)}:${checkEmptyValue(factor1)}:${checkEmptyValue(factor2)}:';
                        var sumOfAscii = 0;
                        for(var i in payload.split('')){
                          var bytes = i.codeUnitAt(0);
                          sumOfAscii += bytes;
                        }
                        var crcToByteLen = '${sumOfAscii % 256}';
                        var balance = '';
                        for(var i = 0;i < (3 - crcToByteLen.length);i++){
                          balance += '0';
                        }
                        payload += '$balance$crcToByteLen:\r';
                        List<int> fullData = [];
                        for(var i in payload.split('')){
                          var bytes = i.codeUnitAt(0);
                          fullData.add(bytes);
                        }
                        if (kDebugMode) {
                          print('sumOfAscii : $sumOfAscii');
                          print('crc : ${sumOfAscii % 256}');
                          print('fullData : ${fullData}');
                          print('payload : ${payload}');
                        }
                        bleService.sendDataToHw(fullData);
                        loadingDialog('Ph Calibration Setting Send Successfully..');
                      },
                      icon: const Icon(Icons.send, color: Colors.white,),
                      label: const Text("Send", style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColorLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

}