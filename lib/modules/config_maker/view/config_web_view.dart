import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/valve_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/product_limit.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:oro_drip_irrigation/Widgets/sized_image.dart';
import 'package:oro_drip_irrigation/modules/constant/state_management/constant_provider.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:oro_drip_irrigation/utils/environment.dart';
import 'package:provider/provider.dart';
import '../../../Constants/constants.dart';
import '../../../Widgets/status_box.dart';
import '../../../flavors.dart';
import '../../Preferences/view/preference_main_screen.dart';
import '../../constant/view/constant_base_page.dart';
import '../model/channel_config_model.dart';
import '../model/device_model.dart';
import '../model/ec_model.dart';
import '../model/fertigation_model.dart';
import '../model/filtration_model.dart';
import '../model/irrigation_line_model.dart';
import '../model/moisture_model.dart';
import '../model/ph_model.dart';
import '../model/pressure_model.dart';
import '../model/pump_model.dart';
import '../model/source_model.dart';
import '../repository/config_maker_repository.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/custom_buttons.dart';
import '../../../Widgets/custom_side_tab.dart';
import '../../../Widgets/title_with_back_button.dart';
import '../../../utils/constants.dart';
import '../../../Constants/dialog_boxes.dart';
import 'config_base_page.dart';
import 'config_mobile_view.dart';
import 'connection.dart';
import 'device_list.dart';

class ConfigWebView extends StatefulWidget {
  List<DeviceModel> listOfDevices;
  ConfigWebView({super.key, required this.listOfDevices});

  @override
  State<ConfigWebView> createState() => _ConfigWebViewState();
}

class _ConfigWebViewState extends State<ConfigWebView> {
  late ConfigMakerProvider configPvd;
  late Future<List<DeviceModel>> listOfDevices;
  double sideNavigationWidth = 220;
  double sideNavigationBreakPointWidth = 60;
  double sideNavigationTabWidth = 200;
  double sideNavigationTabBreakPointWidth = 50;
  double webBreakPoint = 1000;
  late ThemeData themeData;
  late bool themeMode;
  bool clearOnHover = false;
  bool sendOnHover = false;
  List<Map<String, dynamic>> listOfPayload = [];
  PayloadSendState payloadSendState = PayloadSendState.idle;
  MqttService mqttService = MqttService();
  bool isDataSaved = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  HardwareAcknowledgementState payloadState = HardwareAcknowledgementState.notSent;
  bool isNewConfig = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
    mqttService.initializeMQTTClient();
    mqttService.connect();
    mqttService.topicToSubscribe('${Environment.mqttSubscribeTopic}/${configPvd.masterData['deviceId']}');
    // MqttManager().topicToPublishAndItsMessage('${Environment.mqttWebPublishTopic}/${configPvd.masterData['deviceId']}', jsonEncode(configMakerPayload));
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    themeData = Theme.of(context);
    themeMode = themeData.brightness == Brightness.light;
  }

  void _onPopInvokedWithResult(bool didPop, dynamic result) async {
    if (didPop) return; // If already popped, do nothing

    if (!isDataSaved) {
      bool? shouldLeave = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Alert"),
          content: const Text("Do you really want to leave?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Stay on page
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Allow popping the page
              },
              child: const Text("Leave"),
            ),
          ],
        ),
      );

      if (shouldLeave == true) {
        Navigator.of(context).pop(result);
      }
    } else {
      Navigator.of(context).pop(result);
    }
  }

  Widget getHardwareAcknowledgementWidget(HardwareAcknowledgementState state){
    if(state == HardwareAcknowledgementState.notSent){
      return const StatusBox(color:  Colors.black87,child: Text('Do you want to send payload..',),);
    }else if(state == HardwareAcknowledgementState.success){
      return const StatusBox(color:  Colors.green,child: Text('Success..',),);
    }else if(state == HardwareAcknowledgementState.failed){
      return const StatusBox(color:  Colors.red,child: Text('Failed..',),);
    }else if(state == HardwareAcknowledgementState.errorOnPayload){
      return const StatusBox(color:  Colors.red,child: Text('Payload error..',),);
    }else{
      return const SizedBox(
          width: double.infinity,
          height: 5,
          child: LinearProgressIndicator()
      );
    }
  }

  Map<String, dynamic> getConstantHardwarePayload(){
    var constPvd = Provider.of<ConstantProvider>(context, listen: false);
    var generalPayload = constPvd.getGeneralPayload();
    print("generalPayload : $generalPayload");
    var globalAlarmPayload = constPvd.getGlobalAlarmPayload();
    print("globalAlarmPayload : $globalAlarmPayload");
    var globalAlarmForEcoGem = constPvd.getEcoGemPayloadForGlobalAlarm();
    print("globalAlarmForEcoGem : $globalAlarmForEcoGem");
    var levelSensorPayload = constPvd.getObjectInConstantPayload(constPvd.level);
    print("levelSensorPayload : $levelSensorPayload");
    var pumpPayload = constPvd.getObjectInConstantPayload(constPvd.pump);
    print("pumpPayload : $pumpPayload");
    var channelPayload = constPvd.getObjectInConstantPayload(constPvd.channel);
    print("channelPayload : $channelPayload");
    var fertilizerSitePayload = constPvd.getFertilizerSitePayload();
    print("fertilizerSitePayload : $fertilizerSitePayload");
    var waterMeterPayload = constPvd.getObjectInConstantPayload(constPvd.waterMeter);
    print("waterMeterPayload : $waterMeterPayload");
    var mainValvePayload = constPvd.getObjectInConstantPayload(constPvd.mainValve);
    print("mainValvePayload : $mainValvePayload");
    var valvePayload = constPvd.getObjectInConstantPayload(constPvd.valve);
    print("valvePayload : $valvePayload");
    var normalCriticalPayload = AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId']) ? constPvd.getNormalCriticalAlarmForEcoGem() : constPvd.getNormalCriticalAlarm();
    print("normalCriticalPayload : $normalCriticalPayload");
    var filterPayload = constPvd.getFilterSitePayload();
    print("filterPayload : $filterPayload");
    print("constPvd.userData['modelId'] : ${constPvd.userData['modelId']}");
    bool isGem = AppConstants.gemModelList.contains(constPvd.userData['modelId']);
    bool isOms = AppConstants.omsGemList.contains(constPvd.userData['modelId']);
    var hardwarePayload = {
      "300" : {
        "301" : isOms ? '' : generalPayload,
        if(isGem)
          "302" : mainValvePayload,
        "303" : valvePayload,
        "304" : waterMeterPayload,
        "305" : channelPayload,
        if(isGem)
          "306" : fertilizerSitePayload,
        if(isGem)
          "307" : levelSensorPayload,
        "308" : normalCriticalPayload,
        "309" : pumpPayload,
        "310" : filterPayload,
      }
    };
    return hardwarePayload;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool themeMode = themeData.brightness == Brightness.light;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        backgroundColor: themeData.primaryColorDark.withOpacity(themeMode ? 1.0 : 0.2),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Row(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if(configPvd.selectedTab == ConfigMakerTabs.deviceList)
              ...[
                FilledButton.icon(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context){
                      return Scaffold(
                        appBar: AppBar(
                          title: const Text('Constant'),
                          actions: [
                            FilledButton.icon(
                              icon: const Icon(Icons.send),
                              onPressed: (){
                                setState(() {
                                  payloadState = HardwareAcknowledgementState.notSent;
                                  mqttService.acknowledgementPayload = null;
                                });
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context){
                                      return StatefulBuilder(
                                          builder: (context, stateSetter){
                                            return AlertDialog(
                                              title: Text('Send Payload', style: Theme.of(context).textTheme.labelLarge,),
                                              content: getHardwareAcknowledgementWidget(payloadState),
                                              actions: [
                                                if(payloadState != HardwareAcknowledgementState.sending && payloadState != HardwareAcknowledgementState.notSent)
                                                  CustomMaterialButton(),
                                                if(payloadState == HardwareAcknowledgementState.notSent)
                                                  CustomMaterialButton(title: 'Cancel',outlined: true,),
                                                if(payloadState == HardwareAcknowledgementState.notSent)
                                                  CustomMaterialButton(
                                                    onPressed: ()async{
                                                      sendToHttp();
                                                      var payload = jsonEncode(getConstantHardwarePayload());
                                                      int delayDuration = 50;
                                                      for(var delay = 0; delay < delayDuration; delay++){
                                                        if(delay == 0){
                                                          stateSetter((){
                                                            setState((){
                                                              mqttService.topicToPublishAndItsMessage(payload, '${Environment.mqttPublishTopic}/${configPvd.masterData['deviceId']}');
                                                              payloadState = HardwareAcknowledgementState.sending;
                                                            });
                                                          });
                                                        }
                                                        stateSetter((){
                                                          setState((){
                                                            if(mqttService.acknowledgementPayload != null){
                                                              if(validatePayloadFromHardware(mqttService.acknowledgementPayload, ['cC'], configPvd.masterData['deviceId']) && validatePayloadFromHardware(mqttService.acknowledgementPayload!, ['cM', '4201', 'PayloadCode'], '300')){
                                                                if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '200'){
                                                                  payloadState = HardwareAcknowledgementState.success;
                                                                }else if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '90'){
                                                                  payloadState = HardwareAcknowledgementState.programRunning;
                                                                }else if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '1'){
                                                                  payloadState = HardwareAcknowledgementState.hardwareUnknownError;
                                                                }else{
                                                                  payloadState = HardwareAcknowledgementState.errorOnPayload;
                                                                }
                                                                mqttService.acknowledgementPayload == null;
                                                              }
                                                            }
                                                          });
                                                        });
                                                        await Future.delayed(const Duration(seconds: 1));
                                                        if(delay == delayDuration-1){
                                                          stateSetter((){
                                                            setState((){
                                                              payloadState = HardwareAcknowledgementState.failed;
                                                            });
                                                          });
                                                        }
                                                        if(payloadState != HardwareAcknowledgementState.sending){
                                                          break;
                                                        }
                                                      }
                                                    },
                                                    title: 'Send',
                                                  ),
                                              ],
                                            );
                                          }
                                      );
                                    }
                                );
                              },
                              label: const Text('Click to send constant'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                textStyle: const TextStyle(fontSize: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          ],
                        ),
                        body: ConstantBasePage(userData: {
                          "userId": configPvd.masterData['userId'],
                          "customerId": configPvd.masterData['customerId'],
                          "controllerId": configPvd.masterData['controllerId'],
                          "deviceId": configPvd.masterData['deviceId'],
                          "modelId": configPvd.masterData['modelId'],
                          "deviceName": configPvd.masterData['deviceName'],
                          "categoryId": configPvd.masterData['categoryId'],
                          "categoryName": configPvd.masterData['categoryName'],
                        }),
                      );
                    }));
                  },
                  label: const Text('Go To Constant'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context){
                      return Scaffold(
                        appBar: AppBar(
                          title: const Text('Preference'),
                        ),
                        body: PreferenceMainScreen(
                          userId: configPvd.masterData['userId'],
                          customerId: configPvd.masterData['customerId'],
                          masterData: configPvd.masterData,
                          selectedIndex: 0,
                        ),
                      );
                    }));
                  },
                  label: const Text('Go To Preference'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            IconButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(configPvd.selectedTab == ConfigMakerTabs.deviceList ? Colors.grey.shade500 : Theme.of(context).primaryColor)
                ),
                onPressed: (){
                  if(configPvd.selectedTab != ConfigMakerTabs.deviceList){
                    setState(() {
                      if(configPvd.selectedTab == ConfigMakerTabs.productLimit){
                        configPvd.selectedTab = ConfigMakerTabs.deviceList;
                      }else if(configPvd.selectedTab == ConfigMakerTabs.connection){
                        configPvd.selectedTab = ConfigMakerTabs.productLimit;
                      }else if(configPvd.selectedTab == ConfigMakerTabs.siteConfigure){
                        configPvd.selectedTab = ConfigMakerTabs.connection;
                      }
                    });
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white)
            ),
            IconButton(
                alignment: Alignment.center,
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(configPvd.selectedTab == (AppConstants.pumpWithValveModelList.contains(configPvd.masterData["modelId"]) ?  ConfigMakerTabs.productLimit : ConfigMakerTabs.siteConfigure) ? Colors.grey.shade500 : Theme.of(context).primaryColor)
                ),
                onPressed: (){
                  if(configPvd.selectedTab != (AppConstants.pumpWithValveModelList.contains(configPvd.masterData["modelId"]) ?  ConfigMakerTabs.productLimit : ConfigMakerTabs.siteConfigure)){
                    setState(() {
                      if(configPvd.selectedTab == ConfigMakerTabs.deviceList){
                        configPvd.selectedTab = ConfigMakerTabs.productLimit;
                      }else if(configPvd.selectedTab == ConfigMakerTabs.productLimit){
                        configPvd.selectedTab = ConfigMakerTabs.connection;
                      }else if(configPvd.selectedTab == ConfigMakerTabs.connection){
                        configPvd.selectedTab = ConfigMakerTabs.siteConfigure;
                      }
                    });
                  }
                },
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white,)
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 50,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TitleWithBackButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      title: 'Config Maker',

                      // titleWidth: screenWidth * sideNavigationTabRatio,
                      titleWidth: sideNavigationTabWidth,
                    ),
                    Row(
                      spacing:20,
                      children: [
                        StreamBuilder(
                            stream: mqttService.mqttConnectionStream,
                            initialData: MqttConnectionState.disconnected,
                            builder: (context, snapShot){
                              return Row(
                                spacing: 10,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: mqttService.isConnected ? Colors.greenAccent : Colors.red,
                                    radius: 20,
                                    child: const Icon(Icons.computer, color: Colors.white,),
                                  ),
                                  Text('MQTT ${mqttService.mqttConnectionState.name}', style: const TextStyle(color: Colors.white),)

                                ],
                              );
                            }
                        ),
                        InkWell(
                          onHover: (value){
                            setState(() {
                              clearOnHover = value;
                            });
                          },
                          onTap: (){
                            showDialog(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(builder: (context, stateSetter) {
                                  return AlertDialog(
                                    title: const Text('Clear Config'),
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
                                            configPvd.clearData();
                                            setState(() {
                                              isNewConfig = true;
                                            });
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        child: Text('Ok', style: TextStyle(color: Colors.white),),
                                      ),
                                    ],
                                  );
                                });
                              },
                            );
                            // simpleDialogBox(
                            //     context: context,
                            //     title: "Alert",
                            //     message: "Do you want to clear config?",
                            //     actionButton:[
                            //       CustomMaterialButton(
                            //         onPressed: (){
                            //           configPvd.clearData();
                            //           Navigator.of(context).pop();
                            //         },
                            //       )
                            //     ]
                            // );
                          },
                          child:  Row(
                            spacing: 10,
                            children: [
                              CircleAvatar(
                                backgroundColor: clearOnHover ? themeData.primaryColorLight : themeData.primaryColorLight.withOpacity(0.5),
                                radius: 20,
                                child: SizedImageSmall(imagePath: '${AppConstants.svgObjectPath}clear.svg',color:  Colors.white,),
                              ),
                              const Text('Click To Clear Config', style: TextStyle(color: Colors.white),)
                            ],
                          ),
                        ),
                        InkWell(
                          onHover: (value){
                            setState(() {
                              sendOnHover = value;
                            });
                          },
                          onTap: (){
                            String? validationError = configPvd.validateGemConfiguration();
                            if (validationError != null) {
                              simpleDialogBox(
                                context: context,
                                title: 'Alert',
                                message: validationError,
                              );
                              return;
                            }
                            setState(() {
                              payloadSendState = PayloadSendState.idle;
                            });
                            sendToMqtt();
                            sendToHttp();
                          },
                          child:  Row(
                            spacing: 10,
                            children: [
                              CircleAvatar(
                                backgroundColor: sendOnHover ? themeData.primaryColorLight : themeData.primaryColorLight.withOpacity(0.5),
                                radius: 20,
                                child: SizedImageSmall(imagePath: '${AppConstants.svgObjectPath}send.svg',color:  Colors.white,),
                              ),
                              const Text('Click To Send Config', style: TextStyle(color: Colors.white),)
                            ],
                          ),
                        ),
                        const SizedBox(width: 10,)
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    sideNavigationWidget(screenWidth, screenHeight),
                    Expanded(
                      child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(10))
                          ),
                          child: configPvd.selectedTab == ConfigMakerTabs.deviceList
                              ? DeviceList(listOfDevices: widget.listOfDevices)
                              : configPvd.selectedTab == ConfigMakerTabs.productLimit
                              ? ProductLimit(listOfDevices: widget.listOfDevices,configPvd: configPvd,)
                              : configPvd.selectedTab == ConfigMakerTabs.connection
                              ? Connection(configPvd: configPvd,)
                              : SiteConfigure(configPvd: configPvd)
                          //     ? SiteConfigure(configPvd: configPvd)
                          //     : configPvd.selectedTab == ConfigMakerTabs.constant
                          //     ? ConstantBasePage(userData: {
                          //         "userId": configPvd.masterData['userId'],
                          //         "customerId": configPvd.masterData['customerId'],
                          //         "controllerId": configPvd.masterData['controllerId'],
                          //         "deviceId": configPvd.masterData['deviceId'],
                          //         "modelId": configPvd.masterData['modelId'],
                          //         "deviceName": configPvd.masterData['deviceName'],
                          //         "categoryId": configPvd.masterData['categoryId'],
                          //         "categoryName": configPvd.masterData['categoryName'],
                          //       })
                          //     : PreferenceMainScreen(
                          //         userId: configPvd.masterData['userId'],
                          //         customerId: configPvd.masterData['customerId'],
                          //         masterData: configPvd.masterData,
                          //         selectedIndex: 0,
                          // )
                      ),
                    )

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void sendToMqtt(){
    String? validationError = configPvd.validateGemConfiguration();
    if (validationError != null) return;
    configPvd.updateObjectDetails();
    setState(() {
      listOfPayload.clear();
      listOfPayload.addAll(configPvd.getOroPumpPayload());
      listOfPayload.addAll(configPvd.getPumpWithValvePayload());
      listOfPayload.addAll(configPvd.getWeatherMasterPayload());
    });

    if([...AppConstants.gemModelList, ...AppConstants.ecoGemModelList, ...AppConstants.omsGemList, ...AppConstants.aquacultureModelList].contains(configPvd.masterData['modelId'])){
      bool gem = AppConstants.gemModelList.contains(configPvd.masterData['modelId']);
      bool omsGem = AppConstants.omsGemList.contains(configPvd.masterData['modelId']);
      final Map<String, dynamic> configMakerPayload = {
        '100' : {
          '101' : configPvd.getDeviceListPayload(),
          '102' : configPvd.getObjectPayload(),
          if(gem && !omsGem)
            '103' : configPvd.getPumpPayload(),
          if(gem && !omsGem)
            '104' : configPvd.getFilterPayload(),
          if(gem && !omsGem)
            '105' : configPvd.getFertilizerPayload(),
          if(gem && !omsGem)
            '106' : configPvd.getFertilizerInjectorPayload(),
          if(gem && !omsGem)
            '107' : configPvd.getIrrigationLinePayload(),
          if(gem && !omsGem && configPvd.valveConfig.any((valve) => !valve.valveModelParameterIsEmpty()))
            '108' : configPvd.getValveConfigPayload(),
          if(gem && !omsGem && configPvd.moisture.any((moisture) => !moisture.isMoistureModelParameterIsEmpty()))
            '109' : configPvd.getMoisturePayload(),
        }
      };
      setState(() {
        var payloadTitle = AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId']) ? 'Eco Gem Config' : 'Gem Config';
        listOfPayload.insert(0,{
          'title' : '${configPvd.masterData['deviceId']}($payloadTitle)',
          'deviceId' : configPvd.masterData['deviceId'],
          'deviceIdToSend' : configPvd.masterData['deviceId'],
          'payload' : jsonEncode(configMakerPayload),
          'acknowledgementState' : HardwareAcknowledgementState.notSent,
          'selected' : true,
          'checkingCode' : '100',
          'hardwareType' : HardwareType.gem
        });
      });
    }
    debugPrint("listOfPayload ==> $listOfPayload");
    payloadAlertBox();
  }

  void payloadAlertBox(){
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context){
          return StatefulBuilder(
              builder: (context, stateSetter){
                return AlertDialog(
                  title: const Text('Configuration Payload'),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        for(var payload in listOfPayload)
                          CheckboxListTile(
                            enabled: (payloadSendState == PayloadSendState.idle || payloadSendState == PayloadSendState.stop),
                            title: Text('${payload['title']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(payload['deviceId']),
                                payloadAcknowledgementWidget(payload['acknowledgementState'] as HardwareAcknowledgementState),
                              ],
                            ),
                            value: payload['selected'],
                            onChanged: (value){
                              stateSetter((){
                                setState(() {
                                  payload['selected'] = value;
                                });
                              });
                            },
                          )
                      ],
                    ),
                  ),
                  actions: [
                    if(payloadSendState == PayloadSendState.idle || payloadSendState == PayloadSendState.start)
                      CustomMaterialButton( // only show cancel button when payloadState on idle and start
                        outlined: true,
                        title: 'Cancel',
                        onPressed: (){
                          stateSetter((){
                            setState(() {
                              payloadSendState = PayloadSendState.stop;
                            });
                            Navigator.pop(context);
                          });
                        },
                      ),

                    if(payloadSendState == PayloadSendState.idle) // only show send button when payloadState on idle
                      CustomMaterialButton(
                        onPressed: ()async{
                          payloadLoop : for(var payload in listOfPayload){
                            print("payload : ${payload}");
                            if(!payload['selected']){
                              continue payloadLoop;
                            }
                            bool mqttAttempt = true;
                            int delayDuration = 60;
                            delayLoop : for(var sec = 0;sec < delayDuration;sec++){
                              if(sec == 0){
                                payloadSendState = PayloadSendState.start;
                                payload['acknowledgementState'] = HardwareAcknowledgementState.sending;
                              }
                              if(sec == delayDuration - 1){
                                payload['acknowledgementState'] = HardwareAcknowledgementState.failed;
                              }
                              debugPrint("${payload['hardwareType']}\n sec ${sec + 1}   -- ${payload['deviceId']} \n ${mqttService.acknowledgementPayload }");
                              if(mqttService.isConnected && mqttAttempt == true){
                                mqttService.topicToPublishAndItsMessage(
                                  AppConstants.wlcModelList.contains(configPvd.masterData['modelId'])
                                      ? Constants.sendPayloadWithCrc(payload['payload'])
                                      : payload['payload'],
                                    '${Environment.mqttPublishTopic}/${configPvd.masterData['deviceId']}');
                                mqttAttempt = false;
                              }
                              stateSetter((){
                                setState(() {
                                  if(payload['hardwareType'] as HardwareType == HardwareType.gem){  // listening acknowledgement from gem
                                    if(mqttService.acknowledgementPayload != null){
                                      print("mqttService.acknowledgementPayload! : ${sec+1}");
                                      if(validatePayloadFromHardware(mqttService.acknowledgementPayload!, ['cC'], payload['deviceIdToSend']) && validatePayloadFromHardware(mqttService.acknowledgementPayload!, ['cM', '4201', 'PayloadCode'], payload['checkingCode'])){
                                        if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '200'){
                                          payload['acknowledgementState'] = HardwareAcknowledgementState.success;
                                        }else if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '90'){
                                          payload['acknowledgementState'] = HardwareAcknowledgementState.programRunning;
                                        }else if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '1'){
                                          payload['acknowledgementState'] = HardwareAcknowledgementState.hardwareUnknownError;
                                          debugPrint('successfully!! update status for ${payload['title']}  and its code : ${mqttService.acknowledgementPayload!['cM']['4201']['Code']} -- ${payload['acknowledgementState']}');
                                        }else{
                                          payload['acknowledgementState'] = HardwareAcknowledgementState.errorOnPayload;
                                        }
                                        mqttService.acknowledgementPayload = null;
                                      }
                                    }
                                  }
                                  else if([HardwareType.pump, HardwareType.pumpWithValve, HardwareType.weather].contains(payload['hardwareType'] as HardwareType)){
                                    if(mqttService.acknowledgementPayload != null){
                                      if(validatePayloadFromHardware(mqttService.acknowledgementPayload!, ['cC'], payload['deviceId']) && validatePayloadFromHardware(mqttService.acknowledgementPayload!, ['cM'], payload['checkingCode'])){
                                        payload['acknowledgementState'] = HardwareAcknowledgementState.success;
                                        mqttService.acknowledgementPayload = null;
                                      }
                                    }
                                  }
                                });
                              });
                              if((payload['acknowledgementState'] as HardwareAcknowledgementState) != HardwareAcknowledgementState.sending){
                                break delayLoop;
                              }
                              await Future.delayed(const Duration(milliseconds: 500));
                            }
                          }
                          if(payloadSendState == PayloadSendState.start){
                            stateSetter((){
                              setState(() {
                                payloadSendState = PayloadSendState.stop;
                                mqttService.acknowledgementPayload = null;
                              });
                            });
                          }
                        },
                        title: 'Send',
                      ),

                    if(payloadSendState == PayloadSendState.stop)
                      CustomMaterialButton(),
                  ],
                );
              }
          );
        }
    );
  }

  Widget payloadAcknowledgementWidget(HardwareAcknowledgementState state){
    late Color color;
    if(state == HardwareAcknowledgementState.notSent){
      color = Colors.grey;
      return statusBox(color, Text('not sent', style: TextStyle(color: color, fontSize: 12),));
    }else if(state == HardwareAcknowledgementState.failed){
      color = Colors.red;
      return statusBox(color, Text('failed...', style: TextStyle(color: color, fontSize: 12),));
    }else if(state == HardwareAcknowledgementState.success){
      color = Colors.green;
      return statusBox(color, Text('success...', style: TextStyle(color: color, fontSize: 12),));
    }else if(state == HardwareAcknowledgementState.programRunning){
      color = Colors.red;
      return statusBox(color, Text('Failed - Program Running...', style: TextStyle(color: color, fontSize: 12),));
    }else if(state == HardwareAcknowledgementState.errorOnPayload){
      color = Colors.red;
      return statusBox(color, Text('Error on payload...', style: TextStyle(color: color, fontSize: 12),));
    }else if(state == HardwareAcknowledgementState.hardwareUnknownError){
      color = Colors.red;
      return statusBox(color, Text('Unknown error...', style: TextStyle(color: color, fontSize: 12),));
    }else{
      return const SizedBox(
          width: double.infinity,
          height: 5,
          child: LinearProgressIndicator()
      );
    }
  }

  Widget statusBox(Color color, Widget child){
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(5)
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10 , vertical: 5),
      child: child,
    );
  }

  void sendToHttp()async{
    String? validationError = configPvd.validateGemConfiguration();
    if (validationError != null) return;
    var listOfSampleObjectModel = configPvd.listOfSampleObjectModel.map((object){
      return object.toJson();
    }).toList();
    var listOfObjectModelConnection = configPvd.listOfObjectModelConnection.map((object){
      return object.toJson();
    }).toList();
    var listOfGeneratedObject = configPvd.listOfGeneratedObject.map((object){
      return object.toJson(data: configPvd.configMakerDataFromHttp);
    }).toList();
    var filtration = configPvd.filtration.cast<FiltrationModel>().map((object){
      return object.toJson();
    }).toList();
    var fertilization = configPvd.fertilization.cast<FertilizationModel>().map((object){
      return object.toJson();
    }).toList();
    var source = configPvd.source.cast<SourceModel>().map((object){
      return object.toJson();
    }).toList();
    var pump = configPvd.pump.cast<PumpModel>().map((object){
      return object.toJson();
    }).toList();
    var moisture = configPvd.moisture.cast<MoistureModel>().map((object){
      return object.toJson();
    }).toList();
    var pressure = configPvd.pressureSensor.cast<PressureModel>().map((object){
      return object.toJson();
    }).toList();
    var valve = configPvd.valveConfig.cast<ValveConfigModel>().map((object){
      return object.toJson();
    }).toList();
    var channel = configPvd.channelConfig.cast<ChannelConfigModel>().map((object){
      return object.toJson();
    }).toList();
    var line = configPvd.line.cast<IrrigationLineModel>().map((object){
      return object.toJson();
    }).toList();
    var ecSensor = configPvd.ec.cast<EcModel>().map((object){
      return object.toJson();
    }).toList();
    var phSensor = configPvd.ph.cast<PhModel>().map((object){
      return object.toJson();
    }).toList();
    var body = {
      "userId" : configPvd.masterData['customerId'],
      "controllerId" : configPvd.masterData['controllerId'],
      'groupId' : configPvd.masterData['groupId'],
      "isNewConfig" : isNewConfig ? '1' : '0',
      "productLimit" : listOfSampleObjectModel,
      "connectionCount" : listOfObjectModelConnection,
      "configObject" : listOfGeneratedObject,
      "waterSource" : source,
      "pump" : pump,
      "filterSite" : filtration,
      "fertilizerSite" : fertilization,
      "moistureSensor" : moisture,
      "pressureSensor" : pressure,
      "valve" : valve,
      "fertilizerChannel" : channel,
      "irrigationLine" : line,
      "ecSensor" : ecSensor,
      "phSensor" : phSensor,
      "deviceList" : configPvd.listOfDeviceModel
          .where((device) => device.controllerId != configPvd.masterData['controllerId'])
          .map((device) {
        return {
          'productId' : device.productId,
          'controllerId' : device.controllerId,
          'masterId' : device.masterId,
          'referenceNumber' : configPvd.findOutReferenceNumber(device),
          'serialNumber' : device.serialNumber,
          'interfaceTypeId' : device.interfaceTypeId,
          'interfaceInterval' : device.masterId == null ? null : device.interfaceInterval,
          'extendControllerId' : device.extendControllerId,
        };
      }).toList(),
      "hardware" : listOfPayload.map((payload) {
        return {
          'title' : payload['title'],
          'payload' : payload['payload']
        };
      }).toList(),
      "controllerReadStatus" : '0',
      "serialNumber" : configPvd.serialNumber,
      "createUser" : configPvd.masterData['userId']
    };
    body['configObject'] = configPvd.listOfGeneratedObject.map((object){
      return object.toJson(data: body);
    }).toList();
    try{
      var response = await ConfigMakerRepository().createUserConfigMaker(body);
      debugPrint('response : ${response.body}');
    }catch(e){
      debugPrint('createUserConfigMaker error : $e');
    }
  }

  Widget sideNavigationWidget(screenWidth, screenHeight){
    return SizedBox(
      width: screenWidth  > webBreakPoint ? sideNavigationWidth : sideNavigationBreakPointWidth,
      height: screenHeight,
      child: Column(
        children: [
          const SizedBox(height: 50,),
          ...getSideNavigationTab(screenWidth)

        ],
      ),
    );
  }

  List<Widget> getSideNavigationTab(screenWidth){
    return [
      for(var i in ConfigMakerTabs.values)
        if(validateTab(i))
          CustomSideTab(
            width: screenWidth  > webBreakPoint ? sideNavigationTabWidth : sideNavigationTabBreakPointWidth,
            imagePath: '${AppConstants.svgObjectPath}${getTabImage(i)}.svg',
            title: getTabName(i),
            selected: i == configPvd.selectedTab,
            onTap: (){
              updateConfigMakerTabs(
                  context: context,
                  configPvd: configPvd,
                  setState: setState,
                  selectedTab: i
              );
            },
          )
    ];
  }

  bool validateTab(ConfigMakerTabs tab){
    bool display = false;
    if(AppConstants.pumpWithValveModelList.contains(configPvd.masterData['modelId']) || AppConstants.weatherGsmModelList.contains(configPvd.masterData['modelId'])){
      if([ConfigMakerTabs.deviceList.name, ConfigMakerTabs.productLimit.name].contains(tab.name)){
        display = true;
      }
    }
    // else if(AppConstants.omsGemList.contains(configPvd.masterData['modelId'])){
    //   if([ConfigMakerTabs.deviceList.name, ConfigMakerTabs.productLimit.name, ConfigMakerTabs.connection.name].contains(tab.name)){
    //     display = true;
    //   }
    // }
    else{
      display = true;
    }
    return display;
  }

  String getTabImage(ConfigMakerTabs configMakerTabs) {
    switch (configMakerTabs) {
      case ConfigMakerTabs.deviceList:
        return 'device_list';
      case ConfigMakerTabs.productLimit:
        return 'product_limit';
      case ConfigMakerTabs.connection:
        return 'connection';
      case ConfigMakerTabs.siteConfigure:
        return 'site_configure';
      default:
        throw ArgumentError('Invalid ConfigMakerTabs value: $configMakerTabs');
    }
  }

}

bool validatePayloadFromHardware(Map<String, dynamic>? payload, List<String> keys, String checkingValue){
  print("keys : $keys   checkingValue : $checkingValue");
  bool condition = false;
  dynamic checkingNestedData = payload;
  if(payload!.containsKey('cC')){
    for(var key in keys){
      if(checkingNestedData != null && checkingNestedData.containsKey(key)){
        checkingNestedData = checkingNestedData[key];
      }else{
        condition = false;
        break;
      }
    }
  }
  if(checkingNestedData is String){
    if(checkingNestedData.contains(checkingValue)){
      condition = true;
    }else if(checkingNestedData == checkingValue){
      condition = true;
    }
  }

  if(kDebugMode){
    print("checkingNestedData : $checkingNestedData \n checkingValue : $checkingValue \n condition : $condition");
  }
  return condition;
}

enum HardwareAcknowledgementState{notSent, sending, failed, success, errorOnPayload, hardwareUnknownError, programRunning}
enum PayloadSendState{idle, start, stop}
enum HardwareType{gem, pump, economic, pumpWithValve, weather}