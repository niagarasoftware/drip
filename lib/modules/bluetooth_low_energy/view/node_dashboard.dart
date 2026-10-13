import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:oro_drip_irrigation/Widgets/custom_buttons.dart';
import 'package:oro_drip_irrigation/modules/bluetooth_low_energy/view/ble_sent_and_receive.dart';
import 'package:oro_drip_irrigation/modules/bluetooth_low_energy/view/calibration.dart';
import 'package:oro_drip_irrigation/modules/bluetooth_low_energy/view/control_node.dart';
import 'package:oro_drip_irrigation/modules/bluetooth_low_energy/view/interface_setting.dart';
import 'package:oro_drip_irrigation/modules/bluetooth_low_energy/view/node_in_boot_mode.dart';
import 'package:oro_drip_irrigation/modules/bluetooth_low_energy/view/trace_screen.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid/responsive_grid.dart';
import '../../../flavors.dart';
import '../repository/ble_repository.dart';
import '../state_management/ble_service.dart';

class NodeDashboard extends StatefulWidget {
  final Map<String, dynamic> nodeData;
  final Map<String, dynamic> masterData;
  const NodeDashboard({super.key, required this.nodeData, required this.masterData});

  @override
  State<NodeDashboard> createState() => _NodeDashboardState();
}

class _NodeDashboardState extends State<NodeDashboard> {
  late BleProvider bleService;
  late int fileNameResponse;
  late Future<int> nodeBluetoothResponse;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    bleService = Provider.of<BleProvider>(context, listen: false);
    nodeBluetoothResponse = getData();
  }

  Future<int> getData()async{
    try{
      for(var i = 0; i < 30;i++){
        if(bleService.nodeDataFromHw.containsKey('MID')){
          // print("wait until get mac..");
          break;
        }else{
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      var body = {
        "userId": widget.masterData['customerId'],
        "controllerId": widget.masterData['controllerId'],
        "categoryId": widget.nodeData['categoryId'],
        "modelId": widget.nodeData['modelId'],
        "nodeControllerId": widget.nodeData['controllerId'],
        "deviceId": widget.nodeData['deviceId'],
        "hardwareModelId" : bleService.nodeDataFromHw['MID']
      };
      // print("body : $body");
      var nodeBluetoothResponse = await BleRepository().getNodeBluetoothSetting(body);
      Map<String, dynamic> nodeJsonData = jsonDecode(nodeBluetoothResponse.body);
      bleService.editNodeDataFromServer(nodeJsonData['data']['default'], widget.nodeData);
      return nodeJsonData['code'];
    }catch(e,stacktrace){
      // print('Error on getting constant data :: $e');
      // print('Stacktrace on getting constant data :: $stacktrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    bleService = Provider.of<BleProvider>(context, listen: true);
    return Material(
      child: Center(
        child: FutureBuilder<int>(
            future: nodeBluetoothResponse,
            builder: (context, snapshot){
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator()); // Loading state
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}'); // Error state
              } else if (snapshot.hasData) {
                if(bleService.nodeDataFromHw['BOOT'] == '31'){
                  return const NodeInBootMode();
                }
                return RefreshIndicator(
                  onRefresh: bleService.onRefresh,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20,),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ResponsiveGridList(
                              minSpacing: 20,
                              desiredItemWidth: 120,
                              children: [
                                if(bleService.bleConnectMode == ConnectMode.normal)
                                  gridItemWidget(
                                      imagePath: 'assets/Images/Svg/SmartComm/bootMode.svg',
                                      title: 'Update Firmware',
                                      onTap: (){
                                        userAcknowledgementForUpdatingFirmware();
                                      }
                                  ),
                                if(showControlAndView())
                                  gridItemWidget(
                                    imagePath: 'assets/Images/Svg/SmartComm/control.svg',
                                    title: 'View & Control',
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return const ControlNode();
                                      }));
                                    },
                                  ),
                                if(showInterfaceSetting())
                                  gridItemWidget(
                                      imagePath: 'assets/Images/Svg/SmartComm/interface_setting.svg',
                                      title: 'Interface Setting',
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context){
                                          return const InterfaceSetting();
                                        }));
                                      }
                                  ),
                                if(bleService.bleConnectMode == ConnectMode.normal)
                                  gridItemWidget(
                                    imagePath: 'assets/Images/Svg/SmartComm/trace_file.svg',
                                    title: 'Trace',
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return TraceScreen(nodeData: widget.nodeData,);
                                      }));
                                    },
                                  ),
                                if(showCalibration())
                                  gridItemWidget(
                                    imagePath: 'assets/Images/Svg/SmartComm/calibration.svg',
                                    title: 'Calibration',
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return Calibration(nodeData: widget.nodeData,);
                                      }));
                                    },
                                  ),
                                if(bleService.developerOption >= 10)
                                  gridItemWidget(
                                    imagePath: 'assets/Images/Svg/SmartComm/sent_and_receive.svg',
                                    title: 'Sent And Receive',
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return const BleSentAndReceive();
                                      }));
                                    },
                                  ),
                              ]
                          ),
                        ),
                      ),
                      // NodeInBootMode()
                    ],
                  ),
                );
              } else {
                return const Text('No data'); // Shouldn't reach here normally
              }
            }
        ),
      ),
    );
  }

  bool showCalibration(){
    bool show = true;
    if(bleService.nodeDataFromServer.isEmpty){
      show = false;
    }else if(bleService.nodeDataFromServer['hardwareLoraModel'].contains(bleService.nodeDataFromHw['MID'])){
      show = false;
    }else if(
    [
      ...AppConstants.pumpWithValveModelList,
      ...AppConstants.ecoGemModelList,
      // ...AppConstants.ecModel,
      // ...AppConstants.phModel,
    ].contains(bleService.nodeData['modelId'])
    ){
      show = false;
    }else if(bleService.bleConnectMode == ConnectMode.pumpWifiDefault){
      show = false;
    }
    return show;
  }

  bool showControlAndView(){
    bool show = true;
    if(bleService.nodeDataFromHw.keys.length < 4 || bleService.bleConnectMode == ConnectMode.pumpWifiDefault){
      show = false;
    }
    return show;
  }

  bool showInterfaceSetting(){
    bool show = true;
    if([
      ...AppConstants.smartPlusEcPhModel,
      ...AppConstants.ecModel,
      ...AppConstants.phModel,
    ].contains(bleService.nodeData['modelId'])){
      show = false;
    }
    return show;
  }

  void userAcknowledgementForUpdatingFirmware(){
    showDialog(
        barrierDismissible: false,
        context: context, builder: (context){
      return AlertDialog(
        title: Text('Do you want to update firmware', style: TextStyle(fontSize: 14),),
        actions: [
          CustomMaterialButton(
            outlined: true,
            title: 'No',
            onPressed: (){
              Navigator.pop(context);
            },
          ),
          CustomMaterialButton(
            title: 'Yes',
            onPressed: (){
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(builder: (context, stateSetter) {
                    return AlertDialog(
                      title: const Text('Password to Update Firmware'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff475467),
                            ),
                          ),
                          Form(
                            key: formKey,
                            child: TextFormField(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                } else if (value !=
                                    (F.title.toLowerCase().contains('oro')
                                        ? 'Oro@321'
                                        : F.title.toLowerCase().contains('smart')
                                        ? 'LK@321'
                                        : F.title.toLowerCase().contains('agritel')
                                        ? 'Agritel@321'
                                        : 'Oro@321')) {
                                  return 'Invalid password';
                                }
                                return null;
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                hintText: 'Password',
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff475467),
                                ),
                                prefixIcon: Icon(
                                  Icons.password,
                                  color: Theme.of(context).primaryColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                            onPressed: (){
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel')
                        ),
                        CustomMaterialButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              bleService.changingNodeToBootMode();
                              Navigator.pop(context);
                              userShouldWaitUntilRestart();
                            }
                          },
                          child: Text('Ok', style: TextStyle(color: Colors.white),),
                        ),
                      ],
                    );
                  });
                },
              );

            },
          )
        ],
      );
    }
    );
  }

  void nodeNotInBootMode(){
    showDialog(
        barrierDismissible: false,
        context: context, builder: (context){
      return AlertDialog(
        title: const Text('Device not changed to Boot Mode.', style: TextStyle(fontSize: 14),),
        actions: [
          CustomMaterialButton()
        ],
      );
    }
    );
  }

  void userShouldWaitUntilRestart()async{
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
    bool closeDialog = false;
    for(var waitLoop = 0;waitLoop < 15;waitLoop++){
      if(bleService.nodeDataFromHw['BOOT'] == '31'){
        closeDialog = true;
        break;
      }
      await Future.delayed(const Duration(seconds: 2));
      bleService.requestingMac();
      // print("userShouldWaitUntilRestart seconds : ${waitLoop + 1}");
      // print("nodeDataFromHw : ${bleService.nodeDataFromHw}");
      // print("nodeDataFromHw : ${bleService.nodeDataFromHw}");
    }
    if(closeDialog){
      Navigator.pop(context);
    }else{
      Navigator.pop(context);
      nodeNotInBootMode();
    }
  }

  Widget gridItemWidget({
    required String imagePath,
    required String title,
    required void Function() onTap
  }){
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.grey, blurRadius: 5),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SvgPicture.asset(
              imagePath,
              height: 80,
            ),
            Text(title, style: const TextStyle(fontSize: 14),textAlign: TextAlign.center,)
          ],
        ),
      ),
    );
  }
}