import 'dart:convert';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/drop_down_search_field.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../Constants/properties.dart';
import '../../../services/mqtt_service.dart';
import '../../../utils/environment.dart';
import '../../../utils/shared_preferences_helper.dart';
import '../model/device_model.dart';
import '../repository/config_maker_repository.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/custom_buttons.dart';
import '../../../Widgets/custom_drop_down_button.dart';
import '../../../Widgets/sized_image.dart';
import '../../../flavors.dart';
import 'config_base_page.dart';

class DeviceList extends StatefulWidget {
  List<DeviceModel> listOfDevices;
  DeviceList({
    super.key,
    required this.listOfDevices
  });

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  late ConfigMakerProvider configPvd;
  bool selectAllNode = false;
  late ThemeData themeData;
  late bool themeMode;
  String replaceDeviceId = '';
  MqttService mqttService = MqttService();
  String userRole = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
    //final token = await PreferenceHelper.getToken();
    //userRole = getUserRole();
    getUserRole();
  }

  void getUserRole() async {
    String? role = await PreferenceHelper.getUserRole();
    setState(() {
      userRole = role!;
    });
    print("userRole :: $userRole");
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    themeData = Theme.of(context);
    themeMode = themeData.brightness == Brightness.light;
  }

  @override
  Widget build(BuildContext context) {
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: true);
    double screenWidth = MediaQuery.of(context).size.width - 16;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: screenWidth > 500 ? 1000 : screenWidth,
          child: Column(
            children: [
              if([...AppConstants.pumpWithValveModelList, ...AppConstants.pumpModelList].contains(configPvd.masterData['modelId']))
                Column(
                  spacing: 15,
                  children: [
                    Image.asset(
                      'assets/Images/Png/${F.name.contains('oro') ? 'Oro' : 'SmartComm'}/category_${configPvd.masterData['categoryId']}.png',
                      width: 200,
                      height: 200,
                    ),
                    Text('${configPvd.masterData["modelDescription"]}'),
                    const SizedBox(height: 20,),
                  ],
                ),
              masterBox(
                  listOfDevices: widget.listOfDevices
              ),
              const SizedBox(height: 20,),

              if(![...AppConstants.pumpWithValveModelList, ...AppConstants.pumpModelList].contains(configPvd.masterData['modelId']))
                Expanded(
                child: DataTable2(
                    minWidth: 1050,
                    headingRowColor: WidgetStatePropertyAll(themeData.colorScheme.onSurface),
                    dataRowColor: const WidgetStatePropertyAll(Colors.white),
                    fixedLeftColumns: 2,
                    columns: [
                      DataColumn2(
                        fixedWidth: 80,
                        label: Text('SNO', style: themeData.textTheme.headlineLarge,),
                      ),
                      DataColumn2(
                        fixedWidth: 230,
                        label: Text('MODEL NAME', style: themeData.textTheme.headlineLarge,),
                      ),
                      DataColumn2(
                        fixedWidth: 180,
                        label: Text('DEVICE ID', style: themeData.textTheme.headlineLarge,),
                      ),
                      DataColumn2(
                        fixedWidth: 200,
                        label: Text('Extend', style: themeData.textTheme.headlineLarge,),
                      ),
                      DataColumn2(
                        fixedWidth: 150,
                        label: Text('INTERVAL', style: themeData.textTheme.headlineLarge,),
                      ),
                      const DataColumn2(
                        fixedWidth: 150,
                        label: Text(''),
                      ),
                    ],
                    rows: widget.listOfDevices
                        .where((node) => node.masterId == configPvd.masterData['controllerId'] && node.serialNumber != null)
                        .where((node) => configPvd.masterData['controllerId'] != node.controllerId)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      DeviceModel device = entry.value;
                      int index = entry.key;
                      return DataRow(
                          cells: [
                            DataCell(
                              Text('${index + 1}', style: themeData.textTheme.headlineSmall),
                            ),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(device.modelName, style: themeData.textTheme.headlineSmall),
                                  Text(device.modelDescription, style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black54, fontSize: 10)),
                                ],
                              ),
                            ),
                            DataCell(
                              SelectableText(device.deviceId, style: TextStyle(color: themeData.primaryColorDark),),
                            ),
                            DataCell(
                                (![44, 45, 46, 47,].contains(device.modelId) && configPvd.listOfDeviceModel.any((device) => device.categoryId == 10 && device.masterId != null) && device.interfaceTypeId == 1)
                                    ? CustomDropDownButton(
                                    value: getInitialExtendValue(device.extendControllerId),
                                    list: [
                                      '-',
                                      ...configPvd.listOfDeviceModel
                                          .where((device) => (device.masterId != null && device.categoryId == 10 && !AppConstants.extendLoraList.contains(device.modelId)))
                                          .map((device) => '${device.deviceName}\n${device.deviceId}')
                                    ],
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        device.extendControllerId = getExtendControllerId(newValue!);
                                      });
                                    }
                                )
                                    : Text('N/A', style: themeData.textTheme.headlineSmall,)
                            ),
                            DataCell(
                              CustomDropDownButton(
                                  value: getIntervalCodeToString(device.interfaceInterval!, 'Sec'),
                                  list: [5 , 10, 15, 20, 25].map((e) => getIntervalCodeToString(e, 'Sec')).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      device.interfaceInterval = getIntervalStringToCode(newValue!);
                                    });
                                  }
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red,),
                                    onPressed: (){
                                      bool configured = configPvd.listOfGeneratedObject.any((object) => object.controllerId == device.controllerId);
                                      int valveCount = configPvd.listOfGeneratedObject.where((object) => object.objectId == AppConstants.valveObjectId).length;
                                      int moistureCount = configPvd.listOfGeneratedObject.where((object) => object.objectId == AppConstants.moistureObjectId).length;

                                      if(configured){
                                        simpleDialogBox(context: context, title: 'Alert', message: '${device.deviceName} cannot be removed. Please detach all connected objects first.');
                                      }else if(
                                      AppConstants.pumpWithValveModelList.contains(configPvd.masterData['modelId'])
                                          &&
                                          ((AppConstants.senseModelList.contains(device.modelId) && moistureCount != 0) || (![...AppConstants.pumpWithValveModelList, ...AppConstants.senseModelList].contains(device.modelId) && valveCount > 2))){
                                        if(AppConstants.senseModelList.contains(device.modelId) && moistureCount != 0){
                                          simpleDialogBox(context: context, title: 'Alert', message: '${device.deviceName} cannot be removed. Because Moisture connected to ${device.deviceName}.');
                                        }else if(valveCount > 2){
                                          simpleDialogBox(context: context, title: 'Alert', message: '${device.deviceName} cannot be removed. Because valve connected to ${device.deviceName}');
                                        }
                                      }else{
                                        setState(() {
                                          device.masterId = null;
                                          if(device.categoryId == 10){
                                            for(var d in configPvd.listOfDeviceModel){
                                              if(d.extendControllerId!= null && d.extendControllerId == device.masterId){
                                                d.extendControllerId = null;
                                              }
                                            }
                                          }
                                        });
                                      }
                                    },
                                  ),
                                  if(["admin", "1"].contains(userRole) || F.title.contains('ORO'))
                                    editDeviceIdWidget(masterOrNode: 2, device: device)
                                  else
                                    IconButton(
                                        onPressed: (){
                                          showDialog(
                                              context: context,
                                              builder: (context){
                                                return AlertDialog(
                                                  content: DropDownSearchField(productStock: configPvd.productStock,oldDevice: device.toJson(), masterOrNode: 2, ),
                                                );
                                              }
                                          );
                                        },
                                        icon: const Icon(Icons.find_replace)
                                    )
                                ],
                              ),
                            ),
                          ]
                      );
                    }).toList()
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget editDeviceIdWidget({required int masterOrNode, DeviceModel? device}){
    return IconButton(
      icon: const Icon(Icons.edit_note_outlined,),
      onPressed: (){
        setState(() {
          replaceDeviceId = masterOrNode == 1 ? configPvd.masterData['deviceId'] : device!.deviceId;
        });
        showDialog(
            context: context,
            builder: (context){
              return AlertDialog(
                title: const Text('Replace Device ID'),
                content: TextFormField(
                  initialValue: replaceDeviceId,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder()
                  ),
                  onChanged: (value){
                    setState(() {
                      replaceDeviceId = value;
                    });
                  },
                ),
                actions: [
                  CustomMaterialButton(
                    title: 'Replace',
                    onPressed: ()async{
                      Navigator.pop(context);
                      loadingDialog();
                      int status = await changeDeviceId(
                        productId: masterOrNode == 1 ? configPvd.masterData['productId'] : device!.productId,
                        modelId: masterOrNode == 1 ? configPvd.masterData['modelId'] : device!.modelId,
                        controllerId : masterOrNode == 1 ? configPvd.masterData['controllerId'] : device!.controllerId,
                        deviceId: masterOrNode == 1 ? configPvd.masterData['deviceId'] : device!.deviceId,
                        masterOrNode: masterOrNode,
                      );
                      if(status == 200){
                        var oldTopic = '${Environment.mqttSubscribeTopic}/${configPvd.masterData['deviceId']}';
                        if(masterOrNode == 1){
                          configPvd.masterData['deviceId'] = replaceDeviceId;
                        }else{
                          device!.deviceId = replaceDeviceId;
                        }
                        setState(() {
                        });
                        mqttService.topicToSubscribe('${Environment.mqttSubscribeTopic}/${configPvd.masterData['deviceId']}');
                        mqttService.topicToUnSubscribe(oldTopic);
                        Navigator.pop(context);
                      }
                    },
                  )
                ],
              );
            }
        );
      },
    );
  }

  Future<int> changeDeviceId({required int productId, required int modelId, required int controllerId, required String deviceId, required int masterOrNode})async {
    try{
      var body = {
        // "productId": productId,
        // "modelId": modelId,
        "deviceId": replaceDeviceId,
        // "modifyUser": configPvd.masterData['customerId'],
      };
      var response = await ConfigMakerRepository().checkProduct(body);
      print("response +++ ${response.body}");
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      if(response.statusCode == 200 && jsonData["code"] == 200){
        print("jsonData : $jsonData");
        String message = '${jsonData['message']}';
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 100));
        simpleDialogBox(
            context: context,
            title: 'Alert',
            message: message,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Name'),
                  subtitle: Text('${jsonData['data'][0]['userName']}'),
                ),
                ListTile(
                  title: const Text('Mobile No'),
                  subtitle: Text('${jsonData['data'][0]['mobileNumber']}'),
                ),
              ],
            ),
            actionButton: [
              CustomMaterialButton(
                title: 'Cancel',
                onPressed: (){
                  Navigator.pop(context);
                },
              ),
              CustomMaterialButton(
                title: 'Replace',
                onPressed: ()async{
                  var newDeviceData = {
                    'deviceId' : jsonData['data'][0]['deviceId'],
                    'modelId' : jsonData['data'][0]['modelId'],
                  };
                  var oldDeviceData = {
                    'deviceId' : deviceId,
                    'modelId' : modelId,
                    'controllerId' : controllerId,
                  };
                  Navigator.pop(context);
                  loadingDialog();
                  int statusCode = await configPvd.replaceDevice(newDevice: newDeviceData, oldDevice: oldDeviceData, masterOrNode: masterOrNode);
                  if(statusCode == 200 ){
                    Navigator.pop(context);
                    simpleDialogBox(context: context, title: 'Success', message: 'Product updated successfully..');
                  }else{
                    Navigator.pop(context);
                    simpleDialogBox(context: context, title: 'Failed', message: 'Product not updated..');

                  }

                },
              ),
            ]
        );

        return jsonData['code'];
      }
      else{
        var newDeviceData = {
          'deviceId' : replaceDeviceId,
          'modelId' : null,
        };
        var oldDeviceData = {
          'deviceId' : deviceId,
          'modelId' : modelId,
          'controllerId' : controllerId,
        };
        int statusCode = await configPvd.replaceDevice(newDevice: newDeviceData, oldDevice: oldDeviceData, masterOrNode: masterOrNode);
        if(statusCode == 200 ){
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 100));
          simpleDialogBox(context: context, title: 'Success', message: 'Product updated successfully..');
        }else{
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 100));
          simpleDialogBox(context: context, title: 'Failed', message: 'Product not updated..');
        }
        return 404;
      }
    }catch (e, stackTrace){
      simpleDialogBox(context: context, title: 'Failed', message: e.toString());
      print('Error on converting to device model :: $e');
      print('stackTrace on converting to device model :: $stackTrace');
      return 404;
    }
  }

  void loadingDialog(){
    showDialog(
        context: context,
        useRootNavigator: true,
        builder: (context){
          return const PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                spacing: 20,
                children: [
                  SizedBox(
                    width: 30,
                      height: 30,
                      child: CircularProgressIndicator()
                  ),
                  Text('Please wait...')
                ],
              ),
            ),
          );
        }
    );
  }

  String getInitialExtendValue(int? extendControllerId){
    String value;
    if(extendControllerId != null){
      DeviceModel deviceModel = configPvd.listOfDeviceModel.firstWhere((device) => device.controllerId == extendControllerId);
      value = '${deviceModel.deviceName}\n${deviceModel.deviceId}';
    }else{
      value = '-';
    }
    print('getInitialExtendValue : $value');
    return value;
  }

  int? getExtendControllerId(String value){
    if(value == '-'){
      return null;
    }else{
      DeviceModel deviceModel = configPvd.listOfDeviceModel.firstWhere((device) => device.deviceId == value.split('\n')[1]);
      return deviceModel.controllerId;
    }
  }

  Widget masterBox(
      {
        required List<DeviceModel> listOfDevices
      }
      ){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      width:  double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          border: Border.all(width: 0.5, color: const Color(0xffC9C6C6)),
          boxShadow: AppProperties.customBoxShadowLiteTheme
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(0),
        leading: SizedImageMedium(imagePath: 'assets/Images/Png/${F.name.contains('oro') ? 'Oro' : 'SmartComm'}/category_${configPvd.masterData['categoryId']}.png'),
        title: Text('${configPvd.masterData['deviceName']}', style: themeData.textTheme.bodyLarge,),
        subtitle: Row(
          spacing: 20,
          children: [
            SelectableText('${configPvd.masterData['deviceId']}', style: themeData.textTheme.bodySmall,),
            if(["admin", "1"].contains(userRole) || F.title.contains('ORO'))
              editDeviceIdWidget(masterOrNode: 1)
            else
              IconButton(
                onPressed: (){
                  showDialog(
                      context: context,
                      builder: (context){
                        return AlertDialog(
                          content: DropDownSearchField(productStock: configPvd.productStock,oldDevice: configPvd.masterData, masterOrNode: 1, ),
                        );
                      }
                  );
                },
                icon: const Icon(Icons.find_replace)
            )
          ],
        ),
        trailing: ![...AppConstants.pumpWithValveModelList, ...AppConstants.pumpModelList].contains(configPvd.masterData['modelId']) ? IntrinsicWidth(
          child: CustomMaterialButton(
              onPressed: (){
                setState(() {
                  selectAllNode = false;
                });
                for(var device in listOfDevices){
                  if(device.serialNumber != null && device.masterId != null && configPvd.serialNumber < device.serialNumber!){
                    setState(() {
                      configPvd.serialNumber = device.serialNumber!;
                    });
                  }
                }
                print('configPvd.masterData ::: ${configPvd.masterData}');
                print('listOfDevices ::: $listOfDevices');

                List<DeviceModel> possibleNodeToConfigUnderMaster = listOfDevices.where((node) {
                  List<int> nodeUnderPumpWithValveModel = [15, 17, 23, 25, 42];
                  List<int> nodeNotUnderGemModel = [48, 49];
                  print("node => ${node.modelId} == ${node.modelDescription} == ${node.modelName}");
                  if(AppConstants.pumpWithValveModelList.contains(configPvd.masterData['modelId']) && nodeUnderPumpWithValveModel.contains(node.modelId)){
                    /* this condition filter node for pump with valve model * */
                    return true;
                  }else if(AppConstants.gemModelList.contains(configPvd.masterData['modelId']) && !nodeNotUnderGemModel.contains(node.modelId)){
                    /* this condition filter node for gem model */
                    return true;
                  }else if(AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId'])){
                    /* this condition filter node for eco gem */
                    return true;
                  }else if(AppConstants.omsGemList.contains(configPvd.masterData['modelId'])){
                    print('omssssss');
                    return true;
                  }else{
                    return false;
                  }
                }).toList();
                print('possibleNodeToConfigUnderMaster : $possibleNodeToConfigUnderMaster');
                bool isThereNodeToConfigure = possibleNodeToConfigUnderMaster.any((node) => node.masterId == null);
                if(isThereNodeToConfigure){
                  showDialog(
                      context: context,
                      builder: (context){
                        return StatefulBuilder(
                            builder: (context, stateSetter){
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(0)
                                ),
                                title: const Text('Choose Node for Configuration Under Master',),
                                content: SingleChildScrollView(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width >= 500 ? 500 : MediaQuery.of(context).size.width,
                                    child: DataTable(
                                      headingRowColor: WidgetStatePropertyAll(themeData.colorScheme.onSurface),
                                      dataRowColor: WidgetStatePropertyAll(themeData.colorScheme.onSurface),
                                      columns: [
                                        DataColumn(
                                            label: Checkbox(
                                                value: selectAllNode,
                                                onChanged: (value){
                                                  stateSetter((){
                                                    setState(() {
                                                      selectAllNode = !selectAllNode;
                                                      for(var device in configPvd.listOfDeviceModel){
                                                        List<int> nodeUnderPumpWithValveModel = [42];
                                                        List<int> ecPhModel = [64, 65];
                                                        List<int> nodeNotUnderGemModel = [48, 49, ...ecPhModel];
                                                        if(AppConstants.pumpWithValveModelList.contains(configPvd.masterData['modelId']) && nodeUnderPumpWithValveModel.contains(device.modelId)){
                                                          /* this condition filter node for pump with valve model */
                                                          device.select = selectAllNode;
                                                        }else if(AppConstants.gemModelList.contains(configPvd.masterData['modelId']) && !nodeNotUnderGemModel.contains(device.modelId)){
                                                          /* this condition filter node for pump with valve model */
                                                          device.select = selectAllNode;                                                        }
                                                        device.select = selectAllNode;
                                                      }
                                                    });
                                                  });
                                                }
                                            )
                                        ),
                                        DataColumn(
                                          label: Text('MODEL NAME', style: themeData.textTheme.headlineLarge,),
                                        ),
                                        DataColumn(
                                          label: Text('DEVICE ID',style: themeData.textTheme.headlineLarge,),
                                        )
                                      ],
                                      rows: listOfDevices
                                          .where((node) => node.masterId == null)
                                          .where((node) {
                                            List<int> nodeUnderPumpWithValveModel = [15, 17, 23, 25, 42];
                                            List<int> nodeUnderEcoGemModel = [36, 50, 42];
                                            List<int> nodeNotUnderGemModel = [48, 49];
                                            if(AppConstants.pumpWithValveModelList.contains(configPvd.masterData['modelId']) && nodeUnderPumpWithValveModel.contains(node.modelId)){
                                              /* this condition filter node for pump with valve model */
                                              return true;
                                            }else if(AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId']) && nodeUnderEcoGemModel.contains(node.modelId)){
                                              /* this condition filter node for pump with valve model */
                                              return true;
                                            }else if(AppConstants.gemModelList.contains(configPvd.masterData['modelId']) && !nodeNotUnderGemModel.contains(node.modelId)){
                                              /* this condition filter node for pump with valve model */
                                              return true;
                                            }else if(AppConstants.omsGemList.contains(configPvd.masterData['modelId'])){
                                              /* this condition filter node for pump with valve model */
                                              return true;
                                            }else{
                                              return false;
                                            }
                                          })
                                          .toList()
                                          .asMap()
                                          .entries.map((entry){
                                        DeviceModel device = entry.value;
                                        return DataRow(
                                            cells: [
                                              DataCell(
                                                Checkbox(
                                                  value: device.select,
                                                  onChanged: (value){
                                                    bool update = true;
                                                    if(AppConstants.pumpWithValveModelList.contains(configPvd.masterData['modelId'])){

                                                    }
                                                    stateSetter((){
                                                      setState(() {
                                                        device.select = value!;
                                                      });
                                                    });
                                                  },
                                                ),
                                              ),
                                              DataCell(
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      Text(device.deviceName, overflow: TextOverflow.ellipsis,maxLines: 1, style: const TextStyle(fontSize: 9),),
                                                      Text(device.modelDescription, style: TextStyle(fontWeight: FontWeight.normal, color: Theme.of(context).primaryColor, fontSize: 10)),
                                                    ],
                                                  )
                                              ),
                                              DataCell(
                                                  SelectableText(device.deviceId, style: TextStyle(fontWeight: FontWeight.normal, color: Theme.of(context).primaryColor, fontSize: 10))
                                              ),
                                            ]
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                actions: [
                                  CustomMaterialButton(
                                    onPressed: () {
                                      for (var node in configPvd.listOfDeviceModel) {
                                        stateSetter(() {
                                          setState(() {
                                            if (node.select) {
                                              configPvd.serialNumber += 1;
                                              node.masterId = configPvd.masterData['controllerId'];
                                              node.select = false;
                                              node.serialNumber = configPvd.serialNumber;
                                            }
                                          });
                                        });
                                      }
                                      stateSetter((){
                                        setState(() {
                                          configPvd.listOfDeviceModel.sort((a, b) {
                                            if (a.serialNumber == null && b.serialNumber == null) return 0;
                                            if (a.serialNumber == null) return 1; // nulls last
                                            if (b.serialNumber == null) return -1;
                                            return a.serialNumber!.compareTo(b.serialNumber!);
                                          });
                                        });
                                      });
                                      Navigator.pop(context);
                                    },
                                    title: 'Add',
                                  )
                                ],
                              );
                            }
                        );
                      }
                  );
                }else{
                  simpleDialogBox(context: context, title: 'Alert', message: 'There are no available nodes to configure at the moment');
                }
              },
              title: 'Add Nodes'
          ),
        ) : null,
      ),
    );
  }

  // void sendToMqttSetSerial(){
  //
  //   final Map<String, dynamic> setSerialPayload = {
  //     '2300' : {
  //       '2301' : configPvd.listOfDeviceModel.where((device) => device.masterId != null).map((device) => device.serialNumber).toList().join(','),
  //
  //     }
  //   };
  //   MqttManager().topicToPublishAndItsMessage('${Environment.mqttWebPublishTopic}/${configPvd.masterData['deviceId']}', jsonEncode(setSerialPayload));
  //   print("configMakerPayload ==> ${jsonEncode(setSerialPayload)}");
  //   // print("getOroPumpPayload ==> ${widget.configPvd.getOroPumpPayload()}");
  // }

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
      default:
        throw ArgumentError('Invalid ConfigMakerTabs value: $configMakerTabs');
    }
  }

  String getTabImage(ConfigMakerTabs configMakerTabs) {
    switch (configMakerTabs) {
      case ConfigMakerTabs.deviceList:
        return 'device_list_';
      case ConfigMakerTabs.productLimit:
        return 'product_limit_';
      case ConfigMakerTabs.connection:
        return 'connection_';
      case ConfigMakerTabs.siteConfigure:
        return 'site_configure_';
      default:
        throw ArgumentError('Invalid ConfigMakerTabs value: $configMakerTabs');
    }
  }
}

Color textColorInCell = const Color(0xff667085);
TextStyle textStyleInCell = TextStyle(color: textColorInCell, fontWeight: FontWeight.bold, fontSize: 13);