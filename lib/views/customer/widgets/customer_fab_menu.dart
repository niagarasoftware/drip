import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/views/customer/widgets/password_field.dart';
import 'package:provider/provider.dart';

import '../../../Screens/Map/oro_map/map_oro.dart';
import '../../../models/customer/site_model.dart';
import '../../../Screens/Dealer/ble_mobile_screen.dart';
import '../../../StateManagement/customer_provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../modules/IrrigationProgram/view/program_library.dart';
import '../../../modules/ScheduleView/view/schedule_view_screen.dart';
import '../../../modules/bluetooth_low_energy/state_management/ble_service.dart';
import '../../../modules/bluetooth_low_energy/view/node_connection_page.dart';
import '../../../services/bluetooth/bluetooth_ble_service.dart';
import '../../../services/communication_service.dart';
import '../../../utils/constants.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../input_output_connection_details.dart';
import '../node_list/node_list.dart';
import '../send_and_received/sent_and_received.dart';
import '../stand_alone/stand_alone_narrow.dart';
import 'ble_scan_tile.dart';
import 'bluetooth_scan_tile.dart';

class CustomerFabMenu extends StatelessWidget {
  final dynamic currentMaster;
  final dynamic loggedInUser;
  final CustomerScreenControllerViewModel vm;
  final void Function(String msg) callbackFunction;
  final List<bool> myPermissionFlags;

  const CustomerFabMenu({
    super.key,
    required this.currentMaster,
    required this.loggedInUser,
    required this.vm,
    required this.callbackFunction,
    required this.myPermissionFlags,
  });

  @override
  Widget build(BuildContext context) {

    final isGem = [...AppConstants.gemModelList, ...AppConstants.omsGemList].contains(currentMaster.modelId);
    final isGemNova = [...AppConstants.ecoGemModelList].contains(currentMaster.modelId);
    final isWlc = [...AppConstants.wlcModelList].contains(currentMaster.modelId);
    bool isOMS = [...AppConstants.omsGemList].contains(currentMaster.modelId);

    if (!isGem && !isGemNova && !isWlc) return const SizedBox.shrink();

    final commMode = Provider.of<CustomerProvider>(context).controllerCommMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if(!isWlc && !isOMS)...[
          FloatingActionButton(
            heroTag: null,
            onPressed: null,
            child: PopupMenuButton<String>(
              offset: const Offset(0, -180),
              color: Colors.white,
              onSelected: (value) => _handleMenuSelection(value, context),
              icon: const Icon(Icons.menu, color: Colors.black),
              surfaceTintColor: Theme.of(context).primaryColorLight,
              itemBuilder: (context) => [
                _buildPopupItem(
                    context, 'Node Status', Icons.format_list_numbered, 'Node Status'),
                if(isGem)...[
                  _buildPopupItem(context, 'I/O Connection', Icons.settings_input_component_outlined, 'I/O Connection details'),
                ],

                if(myPermissionFlags[0])...[
                  _buildPopupItem(context, 'Program', Icons.list_alt, 'Program'),
                ],

                if(isGem)...[
                  if(myPermissionFlags[2])...[
                    _buildPopupItem(context, 'ScheduleView', Icons.view_list_outlined, 'Scheduled program details'),
                  ],
                ],

                if(myPermissionFlags[1])...[
                  _buildPopupItem(context, 'Manual', Icons.touch_app_outlined, 'Manual'),
                ],

                _buildPopupItem(context, 'Sent & Received', Icons.question_answer_outlined, 'Sent & Received'),
                _buildPopupItem(context, 'GeoGraphy', Icons.map, 'GeoGraphy'),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        FloatingActionButton(
          heroTag: null,
          backgroundColor: (commMode == 2 &&
              !(vm.bluetoothClassicService.isConnected ||
                  vm.bluetoothBleService.isConnected))
              ? Colors.redAccent
              : null,
          onPressed: () => _showBottomSheet(context, currentMaster, vm,
              vm.mySiteList.data[vm.sIndex].customerId, loggedInUser.id),
          tooltip: 'Connectivity',
          child: commMode == 1
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                vm.wifiStrength == 0 ? Icons.wifi_off :
                vm.wifiStrength <= 20 ? Icons.network_wifi_1_bar_outlined :
                vm.wifiStrength <= 40 ? Icons.network_wifi_2_bar_outlined :
                vm.wifiStrength <= 80 ? Icons.network_wifi_3_bar_outlined :
                Icons.wifi,
                color: Colors.black,
              ),
              Text(
                '${vm.wifiStrength} %',
                style: const TextStyle(fontSize: 11.0, color: Colors.black54),
              ),
            ],
          )
              : Icon(
            (commMode == 2 &&
                (vm.bluetoothClassicService.isConnected ||
                    vm.bluetoothBleService.isConnected))
                ? Icons.bluetooth
                : Icons.bluetooth_disabled,
            color: Colors.black,
          ),
        ),

        if(isWlc)
          const SizedBox(height: 50,)
      ],
    );
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'Node Status':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NodeList(
              customerId: vm.mySiteList.data[vm.sIndex].customerId,
              nodes: currentMaster.nodeList,
              userId: loggedInUser.id,
              configObjects: currentMaster.configObjects,
              masterData: currentMaster, isWide: false,
            ),
          ),
        );
        break;

      case 'I/O Connection':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InputOutputConnectionDetails(
              masterInx: vm.mIndex,
              nodes: currentMaster.nodeList,
            ),
          ),
        );
        break;

      case 'Sent & Received':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SentAndReceived(
              customerId: vm.mySiteList.data[vm.sIndex].customerId,
              controllerId: currentMaster.controllerId,
              isWide: false,
            ),
          ),
        );
        break;

      case 'Program':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProgramLibraryScreenNew(
              customerId: vm.mySiteList.data[vm.sIndex].customerId,
              controllerId: currentMaster.controllerId,
              deviceId: currentMaster.deviceId,
              userId: loggedInUser.id,
              groupId: vm.mySiteList.data[vm.sIndex].groupId,
              categoryId: currentMaster.categoryId,
              modelId: currentMaster.modelId,
              deviceName: currentMaster.deviceName,
              categoryName: currentMaster.categoryName,
              callbackFunction: callbackFunction,
              nodeList: currentMaster.nodeList,
            ),
          ),
        );
        break;

      case 'ScheduleView':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleViewScreen(
              deviceId: currentMaster.deviceId,
              userId: loggedInUser.id,
              controllerId: currentMaster.controllerId,
              customerId: vm.mySiteList.data[vm.sIndex].customerId,
              groupId: vm.mySiteList.data[vm.sIndex].groupId,
            ),
          ),
        );
        break;

      case 'Manual':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StandAloneNarrow(
              siteId: vm.mySiteList.data[vm.sIndex].groupId,
              controllerId: currentMaster.controllerId,
              customerId: vm.mySiteList.data[vm.sIndex].customerId,
              deviceId: currentMaster.deviceId,
              callbackFunction: callbackFunction,
              userId: loggedInUser.id,
              masterData: currentMaster,
            ),
          ),
        );
        break;

      case 'GeoGraphy':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MapScreenOro(userId: loggedInUser.id, customerId: vm.mySiteList.data[vm.sIndex].customerId, controllerId: currentMaster.controllerId, imeiNo: currentMaster.deviceId, modelId: currentMaster.modelId,)
          ),
        );
        break;
    }
  }

  PopupMenuItem<String> _buildPopupItem(
      BuildContext context, String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context, MasterControllerModel currentMaster,
      CustomerScreenControllerViewModel vm, int customerId, int userId) {

    // Read the providers now: the sheet's own context may be gone by the
    // time the sheet has closed.
    final mqttProvider = context.read<MqttPayloadProvider>();
    final customerProvider = context.read<CustomerProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            final commMode = Provider.of<CustomerProvider>(context).controllerCommMode;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                children: [
                  const Text(
                    "Controller Communication Mode",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.wifi),
                    title: const Text("Wi-Fi / MQTT"),
                    trailing: commMode == 1 ?
                    Icon(Icons.check, color: Theme.of(context).primaryColorLight) : null,
                    onTap: () async {
                      await _stopBluetoothAndUseMqtt(
                        mqttProvider: mqttProvider,
                        customerProvider: customerProvider,
                        customerId: customerId,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: const Text("Bluetooth"),
                    trailing: commMode == 2 ?
                    Icon(Icons.check, color: Theme.of(context).primaryColorLight) : null,
                    onTap: () {
                      vm.updateCommunicationMode(2, customerId);
                    },
                  ),
                  if (commMode == 2) ...[
                    const Divider(),
                    if(currentMaster.modelId==3)...[
                      ListTile(
                        title: const Text('Scan & Connect the controller via Bluetooth',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Stay close to the controller near by 10 meters',
                            style: TextStyle(color: Colors.black45)),
                        trailing: const Icon(CupertinoIcons.arrow_right_circle),
                        onTap: (){
                          final Map<String, dynamic> data = {
                            'controllerId': currentMaster.controllerId,
                            'deviceId': currentMaster.deviceId,
                            'deviceName': currentMaster.deviceName,
                            'categoryId': currentMaster.categoryId,
                            'categoryName': currentMaster.categoryName,
                            'modelId': currentMaster.modelId,
                            'modelName': currentMaster.modelName,
                            'InterfaceType': currentMaster.interfaceTypeId,
                            'interface': currentMaster.interface,
                            'relayOutput': currentMaster.relayOutput,
                            'latchOutput': currentMaster.latchOutput,
                            'analogInput': currentMaster.analogInput,
                            'digitalInput': currentMaster.digitalInput,
                          };
                          Navigator.push(context, MaterialPageRoute(builder: (context) => NodeConnectionPage(
                            nodeData: data,
                            masterData: {
                              "userId" : userId,
                              "customerId" : customerId,
                              "controllerId" : currentMaster.controllerId
                            },
                            connectMode: ConnectMode.normal,
                          )));
                        },
                      ),
                    ]
                    else...[
                      if([75, ...AppConstants.wlcModelList].contains(currentMaster.modelId))...[
                        BleScanTile (vm: vm),
                        const SizedBox(height: 10),
                        Consumer<MqttPayloadProvider>(
                          builder: (context, provider, _) {

                            final devices = provider.pairedDevicesBle;

                            if (devices.isNotEmpty) {

                              vm.bluetoothBleService.stopScan();

                              return Column(
                                children: devices.map((d) {
                                  return ListTile(
                                    title: Text(d.device.advName ?? ''),
                                    subtitle: Text(d.device.remoteId.str),
                                    trailing: d.isConnected ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            showWifiDialog(context, vm.bluetoothBleService);
                                          },
                                          icon: const Icon(CupertinoIcons.dot_radiowaves_left_right),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => BLEMobileScreen(deviceID: currentMaster.deviceId,
                                                      communicationType: 'Bluetooth',userId: customerId, controllerId:
                                                      currentMaster.controllerId),
                                                ));
                                          },
                                          icon: const Icon(CupertinoIcons.exclamationmark_octagon),
                                        ),
                                      ],
                                    ) :
                                    d.isConnecting ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ) : TextButton(
                                      onPressed: () => vm.bluetoothBleService.connectToDevice(d),
                                      child: const Text("Connect"),
                                    ),
                                  );
                                }).toList(),
                              );
                            } else {
                              return const Center(
                                child: Text(
                                  'Stay close to the controller and tap refresh to try scanning again.',
                                  style: TextStyle(fontSize: 12, color: Colors.black38),
                                ),
                              );
                            }
                          },
                        ),
                      ]else...[
                        BluetoothScanTile(vm: vm),
                        const SizedBox(height: 10),
                        Consumer<MqttPayloadProvider>(
                          builder: (context, provider, _) {

                            final devices = provider.pairedDevicesClassic;

                            if (devices.isNotEmpty) {
                              vm.bluetoothClassicService.stopDiscovery();

                              return Column(
                                children: devices.map((d) {
                                  return ListTile(
                                    title: Text(d.device.name ?? ''),
                                    subtitle: Text(d.device.address),
                                    trailing: d.isConnected ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            requestAndShowWifiList(context, false);
                                          },
                                          icon: const Icon(CupertinoIcons.text_badge_checkmark),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => BLEMobileScreen(deviceID: currentMaster.deviceId,
                                                      communicationType: 'Bluetooth',userId: customerId, controllerId:
                                                      currentMaster.controllerId),
                                                ));
                                          },
                                          icon: const Icon(CupertinoIcons.exclamationmark_octagon),
                                        ),
                                      ],
                                    ):
                                    d.isConnecting ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ):
                                    TextButton(
                                      onPressed: d.isDisconnected ? () => vm.bluetoothClassicService.connectToDevice(d) : null,
                                      child: const Text('Connect'),
                                    ),
                                  );
                                }).toList(),
                              );
                            } else {
                              return const Center(
                                child: Text(
                                  'Stay close to the controller and tap refresh to try scanning again.',
                                  style: TextStyle(fontSize: 12, color: Colors.black38),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ]
                  ],
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => _stopBluetoothAndUseMqtt(
      mqttProvider: mqttProvider,
      customerProvider: customerProvider,
      customerId: customerId,
    ));
  }

  void requestAndShowWifiList(BuildContext context, bool visibleDg) {
    final commService = Provider.of<CommunicationService>(context, listen: false);
    String payLoadFinal = jsonEncode({"7200": {"7201": ''}});
    commService.sendCommand(serverMsg: '', payload: payLoadFinal);
    if(!visibleDg){
      showWifiListDialog(context);
    }
  }

  void showWifiListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final connectingNetwork = ValueNotifier<String?>(null);
        final provider = context.watch<MqttPayloadProvider>();
        final networks = provider.wifiList;
        final message = provider.wifiMessage;
        final wifiStatus = provider.wifiStatus;
        final interfaceType = provider.interfaceType;
        final ipAddress = provider.ipAddress;

        if (message != null && message.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (message == 'WWi-Fi is now ON' || message == 'Wi-Fi is now OFF') {
              context.read<MqttPayloadProvider>().clearWifiMessage();
              Future.delayed(const Duration(milliseconds: 1500), () {
                requestAndShowWifiList(context, true);
              });
            } else {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Changing controller network..."),
                    content: Text(message),
                    actions: [
                      TextButton(
                        onPressed: () {
                          context.read<MqttPayloadProvider>().clearWifiMessage();
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showWifiListDialog(context);
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  );
                },
              );
            }
          });
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.wifi),
                    title: const Text("Wi-Fi"),
                    subtitle: wifiStatus == '2'
                        ? const Text(
                      'Wi-Fi is enabled on the controller \n But No Internet connection',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    )
                        : Text(
                      wifiStatus == '1'
                          ? 'Wi-Fi is enabled on the controller'
                          : 'Wi-Fi is disabled on the controller',
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: provider.wifiStateChanging? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ) : Switch(
                        value: wifiStatus == '1' || wifiStatus == '2',
                        activeColor: Colors.blue,
                        onChanged: (bool value) async {
                          provider.updateWifiStatus('0', true);
                          final communicationService = context.read<CommunicationService>();
                          final livePayload = jsonEncode({
                            "6000": {
                              "6001": value ? '1,0,0' : '0,0,0',
                            }
                          });

                          await communicationService.sendCommand(serverMsg: '', payload: livePayload,);

                        },
                      ),
                    ),
                  ),
                  const Divider(height: 0),
                  (wifiStatus=='1'||wifiStatus=='2')? ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Available Networks"),
                    subtitle: const Text(
                      "Select a Wi-Fi network to change the controller's connection.",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        requestAndShowWifiList(context, true);
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ) :
                  const SizedBox(),
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: SizedBox(
                width: double.maxFinite,
                child: interfaceType=='ethernet'? ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Controller connected with ethernet'),
                  subtitle: Text('IpAddress : $ipAddress'),
                  trailing: const Icon(Icons.cast_connected),
                ):
                networks.isEmpty
                    ? const SizedBox(height: 20, child: Center(child: Text("No networks found.")))
                    : ValueListenableBuilder<String?>(
                  valueListenable: connectingNetwork,
                  builder: (dialogContext, connectingSsid, _) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: networks.length,
                      itemBuilder: (context, index) {
                        final net = networks[index];
                        final ssid = net["SSID"] ?? "Unknown";
                        final bool isSecured = (net["SECURITY"] != null);

                        return ListTile(
                          leading: Icon(
                            Icons.wifi,
                            color: net["SIGNAL"] >= 75
                                ? Colors.green
                                : (net["SIGNAL"] >= 50 ? Colors.orange : Colors.red),
                          ),
                          title: Text(ssid),
                          subtitle: Text("Signal: ${net["SIGNAL"]}%"),
                          trailing: connectingSsid == ssid
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : (net["IN-USE"] == "1"
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : null),
                          onTap: () async {
                            connectingNetwork.value = ssid;

                            final communicationService = context.read<CommunicationService>();

                            if (isSecured) {
                              final password = await showPasswordDialog(context, ssid);
                              if (password == null || password.isEmpty) return;

                              final payload = '2,$ssid,$password';
                              final livePayload = jsonEncode({"6000": {"6001": payload}});
                              await communicationService.sendCommand(serverMsg: '', payload: livePayload);
                            } else {
                              final payload = '2,$ssid,';
                              final livePayload = jsonEncode({"6000": {"6001": payload}});
                              await communicationService.sendCommand(serverMsg: '', payload: livePayload);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> showPasswordDialog(BuildContext context, String ssid) async {
    final TextEditingController passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter password for "$ssid"'),
        content: PasswordField(controller: passwordController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }


  void showWifiDialog(BuildContext context, BluetoothBleService bleService) {
    final ssidController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Configure WiFi"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ssidController,
                decoration: const InputDecoration(labelText: "SSID"),
              ),
              TextField(
                controller: passController,
                decoration: const InputDecoration(labelText: "Password"),
              ),
            ],
          ),
          actions: [


            TextButton(
              onPressed: () async {
                final ssid = ssidController.text.trim();
                final password = passController.text.trim();

                if (ssid.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("SSID and Password cannot be empty"),
                    ),
                  );
                  return;
                }

                final communicationService = context.read<CommunicationService>();
                final payload = '2,$ssid,$password';
                final livePayload = jsonEncode({"6000": {"6001": payload}});
                await communicationService.sendCommand(serverMsg: '', payload: livePayload);

                Navigator.pop(context);
              },
              child: const Text("Send"),
            )
          ],
        );
      },
    );
  }

  /// Stops Bluetooth completely and switches the controller to Wi-Fi / MQTT.
  /// Called when the connectivity sheet closes and from the Wi-Fi / MQTT tile.
  Future<void> _stopBluetoothAndUseMqtt({
    required MqttPayloadProvider mqttProvider,
    required CustomerProvider customerProvider,
    required int customerId,
  }) async {
    final classicService = vm.bluetoothClassicService;
    final bleService = vm.bluetoothBleService;

    // 1. Remove UI callbacks first so nothing can raise an alert afterwards.
    classicService.onDeviceFound = null;
    classicService.onNoDeviceFound = null;
    classicService.onConnectionError = null;
    classicService.onBluetoothDisabled = null;
    bleService.onDeviceFound = null;
    bleService.onNoDeviceFound = null;
    bleService.onConnectionError = null;
    bleService.onBluetoothDisabled = null;
    bleService.onPairingRequired = null;

    // 2. Stop scans, connects and connections.
    await classicService.hardStop();
    await bleService.disconnectAll();

    // 3. Clear the device lists so the next sheet starts clean.
    mqttProvider.updateClassicPairedDevices([]);
    mqttProvider.updateBlePairedDevices([]);

    // 4. Switch to Wi-Fi / MQTT (skip the API call if already in that mode).
    if (customerProvider.controllerCommMode != 1) {
      await vm.updateCommunicationMode(1, customerId);
    }
  }
}

/*
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/views/customer/widgets/password_field.dart';
import 'package:provider/provider.dart';

import '../../../Screens/Map/oro_map/map_oro.dart';
import '../../../models/customer/site_model.dart';
import '../../../Screens/Dealer/ble_mobile_screen.dart';
import '../../../StateManagement/customer_provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../modules/IrrigationProgram/view/program_library.dart';
import '../../../modules/ScheduleView/view/schedule_view_screen.dart';
import '../../../modules/bluetooth_low_energy/state_management/ble_service.dart';
import '../../../modules/bluetooth_low_energy/view/node_connection_page.dart';
import '../../../services/bluetooth/bluetooth_ble_service.dart';
import '../../../services/communication_service.dart';
import '../../../utils/constants.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../input_output_connection_details.dart';
import '../node_list/node_list.dart';
import '../send_and_received/sent_and_received.dart';
import '../stand_alone/stand_alone_narrow.dart';
import 'ble_scan_tile.dart';
import 'bluetooth_scan_tile.dart';

class CustomerFabMenu extends StatelessWidget {
  final dynamic currentMaster;
  final dynamic loggedInUser;
  final CustomerScreenControllerViewModel vm;
  final void Function(String msg) callbackFunction;
  final List<bool> myPermissionFlags;

  const CustomerFabMenu({
    super.key,
    required this.currentMaster,
    required this.loggedInUser,
    required this.vm,
    required this.callbackFunction,
    required this.myPermissionFlags,
  });

  @override
  Widget build(BuildContext context) {

    final isGem = [...AppConstants.gemModelList, ...AppConstants.omsGemList].contains(currentMaster.modelId);
    final isGemNova = [...AppConstants.ecoGemModelList].contains(currentMaster.modelId);
    final isWlc = [...AppConstants.wlcModelList].contains(currentMaster.modelId);
    bool isOMS = [...AppConstants.omsGemList].contains(currentMaster.modelId);

    if (!isGem && !isGemNova && !isWlc) return const SizedBox.shrink();

    final commMode = Provider.of<CustomerProvider>(context).controllerCommMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if(!isWlc && !isOMS)...[
            FloatingActionButton(
              heroTag: null,
              onPressed: null,
              child: PopupMenuButton<String>(
                offset: const Offset(0, -180),
                color: Colors.white,
                onSelected: (value) => _handleMenuSelection(value, context),
                icon: const Icon(Icons.menu, color: Colors.black),
                surfaceTintColor: Theme.of(context).primaryColorLight,
                itemBuilder: (context) => [
                  _buildPopupItem(
                      context, 'Node Status', Icons.format_list_numbered, 'Node Status'),
                  if(isGem)...[
                    _buildPopupItem(context, 'I/O Connection', Icons.settings_input_component_outlined, 'I/O Connection details'),
                  ],

                  if(myPermissionFlags[0])...[
                    _buildPopupItem(context, 'Program', Icons.list_alt, 'Program'),
                  ],

                  if(isGem)...[
                    if(myPermissionFlags[2])...[
                      _buildPopupItem(context, 'ScheduleView', Icons.view_list_outlined, 'Scheduled program details'),
                    ],
                  ],

                  if(myPermissionFlags[1])...[
                    _buildPopupItem(context, 'Manual', Icons.touch_app_outlined, 'Manual'),
                  ],

                  _buildPopupItem(context, 'Sent & Received', Icons.question_answer_outlined, 'Sent & Received'),
                  _buildPopupItem(context, 'GeoGraphy', Icons.map, 'GeoGraphy'),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        FloatingActionButton(
          heroTag: null,
          backgroundColor: (commMode == 2 &&
              !(vm.bluetoothClassicService.isConnected ||
                  vm.bluetoothBleService.isConnected))
              ? Colors.redAccent
              : null,
          onPressed: () => _showBottomSheet(context, currentMaster, vm,
              vm.mySiteList.data[vm.sIndex].customerId, loggedInUser.id),
          tooltip: 'Connectivity',
          child: commMode == 1
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                vm.wifiStrength == 0 ? Icons.wifi_off :
                vm.wifiStrength <= 20 ? Icons.network_wifi_1_bar_outlined :
                vm.wifiStrength <= 40 ? Icons.network_wifi_2_bar_outlined :
                vm.wifiStrength <= 80 ? Icons.network_wifi_3_bar_outlined :
                Icons.wifi,
                color: Colors.black,
              ),
              Text(
                '${vm.wifiStrength} %',
                style: const TextStyle(fontSize: 11.0, color: Colors.black54),
              ),
            ],
          )
              : Icon(
            (commMode == 2 &&
                (vm.bluetoothClassicService.isConnected ||
                    vm.bluetoothBleService.isConnected))
                ? Icons.bluetooth
                : Icons.bluetooth_disabled,
            color: Colors.black,
          ),
        ),
        */
/*FloatingActionButton(
          heroTag: null,
          backgroundColor: (commMode == 2 && !(vm.bluetoothClassicService.isConnected &&
              vm.bluetoothBleService.isConnected)) ? Colors.redAccent : null,
          onPressed: () => _showBottomSheet(context,currentMaster, vm,
              vm.mySiteList.data[vm.sIndex].customerId, loggedInUser.id),
          tooltip: 'Connectivity',
          child: commMode == 1 ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                vm.wifiStrength == 0 ? Icons.wifi_off :
                vm.wifiStrength <= 20 ? Icons.network_wifi_1_bar_outlined :
                vm.wifiStrength <= 40 ? Icons.network_wifi_2_bar_outlined :
                vm.wifiStrength <= 80 ? Icons.network_wifi_3_bar_outlined :
                Icons.wifi,
                color: Colors.black,
              ),
              Text(
                '${vm.wifiStrength} %',
                style: const TextStyle(
                    fontSize: 11.0, color: Colors.black54),
              ),
            ],
          ) :
          Icon((commMode == 2 && (vm.bluetoothClassicService.isConnected
              || vm.bluetoothBleService.isConnected)) ? Icons.bluetooth
              : Icons.bluetooth_disabled,
            color: Colors.black,
          ),
        ),*//*


        if(isWlc)
          const SizedBox(height: 50,)
      ],
    );
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'Node Status':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NodeList(
              customerId: vm.mySiteList.data[vm.sIndex].customerId,
              nodes: currentMaster.nodeList,
              userId: loggedInUser.id,
              configObjects: currentMaster.configObjects,
              masterData: currentMaster, isWide: false,
            ),
          ),
        );
        break;

      case 'I/O Connection':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InputOutputConnectionDetails(
              masterInx: vm.mIndex,
              nodes: currentMaster.nodeList,
            ),
          ),
        );
        break;

      case 'Sent & Received':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SentAndReceived(
              customerId: vm.mySiteList.data[vm.sIndex].customerId,
              controllerId: currentMaster.controllerId,
              isWide: false,
            ),
          ),
        );
        break;

      case 'Program':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProgramLibraryScreenNew(
              customerId: vm.mySiteList.data[vm.sIndex].customerId,
              controllerId: currentMaster.controllerId,
              deviceId: currentMaster.deviceId,
              userId: loggedInUser.id,
              groupId: vm.mySiteList.data[vm.sIndex].groupId,
              categoryId: currentMaster.categoryId,
              modelId: currentMaster.modelId,
              deviceName: currentMaster.deviceName,
              categoryName: currentMaster.categoryName,
              callbackFunction: callbackFunction,
              nodeList: currentMaster.nodeList,
            ),
          ),
        );
        break;

      case 'ScheduleView':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleViewScreen(
              deviceId: currentMaster.deviceId,
              userId: loggedInUser.id,
              controllerId: currentMaster.controllerId,
              customerId: vm.mySiteList.data[vm.sIndex].customerId,
              groupId: vm.mySiteList.data[vm.sIndex].groupId,
            ),
          ),
        );
        break;

      case 'Manual':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StandAloneNarrow(
              siteId: vm.mySiteList.data[vm.sIndex].groupId,
              controllerId: currentMaster.controllerId,
              customerId: vm.mySiteList.data[vm.sIndex].customerId,
              deviceId: currentMaster.deviceId,
              callbackFunction: callbackFunction,
              userId: loggedInUser.id,
              masterData: currentMaster,
            ),
          ),
        );
        break;

      case 'GeoGraphy':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MapScreenOro(userId: loggedInUser.id, customerId: vm.mySiteList.data[vm.sIndex].customerId, controllerId: currentMaster.controllerId, imeiNo: currentMaster.deviceId, modelId: currentMaster.modelId,)
          ),
        );
        break;
    }
  }

  PopupMenuItem<String> _buildPopupItem(
      BuildContext context, String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context, MasterControllerModel currentMaster,
      CustomerScreenControllerViewModel vm, int customerId, int userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            final commMode = Provider.of<CustomerProvider>(context).controllerCommMode;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                children: [
                  const Text(
                    "Controller Communication Mode",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.wifi),
                    title: const Text("Wi-Fi / MQTT"),
                    trailing: commMode == 1 ?
                    Icon(Icons.check, color: Theme.of(context).primaryColorLight) : null,
                    onTap: () async {
                      // Stop classic Bluetooth
                      await vm.bluetoothClassicService.resetBluetoothState();

                      // Stop BLE scan if in progress
                      if (vm.bluetoothBleService.isScanning) {
                        await vm.bluetoothBleService.stopScan();
                      }

                      // Disconnect BLE if connected
                      if (vm.bluetoothBleService.isConnected &&
                          vm.bluetoothBleService.connectedDevice != null) {
                        await vm.bluetoothBleService.disconnect(
                          vm.bluetoothBleService.connectedDevice!,
                        );
                      }

                      vm.updateCommunicationMode(1, customerId);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: const Text("Bluetooth"),
                    trailing: commMode == 2 ?
                    Icon(Icons.check, color: Theme.of(context).primaryColorLight) : null,
                    onTap: () {
                      vm.updateCommunicationMode(2, customerId);
                    },
                  ),
                  if (commMode == 2) ...[
                    const Divider(),
                    if(currentMaster.modelId==3)...[
                      ListTile(
                        title: const Text('Scan & Connect the controller via Bluetooth',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Stay close to the controller near by 10 meters',
                            style: TextStyle(color: Colors.black45)),
                        trailing: const Icon(CupertinoIcons.arrow_right_circle),
                        onTap: (){
                          final Map<String, dynamic> data = {
                            'controllerId': currentMaster.controllerId,
                            'deviceId': currentMaster.deviceId,
                            'deviceName': currentMaster.deviceName,
                            'categoryId': currentMaster.categoryId,
                            'categoryName': currentMaster.categoryName,
                            'modelId': currentMaster.modelId,
                            'modelName': currentMaster.modelName,
                            'InterfaceType': currentMaster.interfaceTypeId,
                            'interface': currentMaster.interface,
                            'relayOutput': currentMaster.relayOutput,
                            'latchOutput': currentMaster.latchOutput,
                            'analogInput': currentMaster.analogInput,
                            'digitalInput': currentMaster.digitalInput,
                          };
                          Navigator.push(context, MaterialPageRoute(builder: (context) => NodeConnectionPage(
                            nodeData: data,
                            masterData: {
                              "userId" : userId,
                              "customerId" : customerId,
                              "controllerId" : currentMaster.controllerId
                            },
                            connectMode: ConnectMode.normal,
                          )));
                        },
                      ),
                    ]
                    else...[
                      if([75, ...AppConstants.wlcModelList].contains(currentMaster.modelId))...[
                        BleScanTile (vm: vm),
                        const SizedBox(height: 10),
                        Consumer<MqttPayloadProvider>(
                          builder: (context, provider, _) {

                            final devices = provider.pairedDevicesBle;

                            if (devices.isNotEmpty) {

                              vm.bluetoothBleService.stopScan();

                              return Column(
                                children: devices.map((d) {
                                  return ListTile(
                                    title: Text(d.device.advName ?? ''),
                                    subtitle: Text(d.device.remoteId.str),
                                    trailing: d.isConnected ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            showWifiDialog(context, vm.bluetoothBleService);
                                          },
                                          icon: const Icon(CupertinoIcons.dot_radiowaves_left_right),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => BLEMobileScreen(deviceID: currentMaster.deviceId,
                                                      communicationType: 'Bluetooth',userId: customerId, controllerId:
                                                      currentMaster.controllerId),
                                                ));
                                          },
                                          icon: const Icon(CupertinoIcons.exclamationmark_octagon),
                                        ),
                                      ],
                                    ) :
                                    d.isConnecting ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ) : TextButton(
                                      onPressed: () => vm.bluetoothBleService.connectToDevice(d),
                                      child: const Text("Connect"),
                                    ),
                                  );
                                }).toList(),
                              );
                            } else {
                              return const Center(
                                child: Text(
                                  'Stay close to the controller and tap refresh to try scanning again.',
                                  style: TextStyle(fontSize: 12, color: Colors.black38),
                                ),
                              );
                            }
                          },
                        ),
                      ]else...[
                        BluetoothScanTile(vm: vm),
                        const SizedBox(height: 10),
                        Consumer<MqttPayloadProvider>(
                          builder: (context, provider, _) {

                            final devices = provider.pairedDevicesClassic;

                            if (devices.isNotEmpty) {
                              vm.bluetoothClassicService.stopDiscovery();

                              return Column(
                                children: devices.map((d) {
                                  return ListTile(
                                    title: Text(d.device.name ?? ''),
                                    subtitle: Text(d.device.address),
                                    trailing: d.isConnected ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            requestAndShowWifiList(context, false);
                                          },
                                          icon: const Icon(CupertinoIcons.text_badge_checkmark),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => BLEMobileScreen(deviceID: currentMaster.deviceId,
                                                      communicationType: 'Bluetooth',userId: customerId, controllerId:
                                                      currentMaster.controllerId),
                                                ));
                                          },
                                          icon: const Icon(CupertinoIcons.exclamationmark_octagon),
                                        ),
                                      ],
                                    ):
                                    d.isConnecting ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ):
                                    TextButton(
                                      onPressed: d.isDisconnected ? () => vm.bluetoothClassicService.connectToDevice(d) : null,
                                      child: const Text('Connect'),
                                    ),
                                  );
                                }).toList(),
                              );
                            } else {
                              return const Center(
                                child: Text(
                                  'Stay close to the controller and tap refresh to try scanning again.',
                                  style: TextStyle(fontSize: 12, color: Colors.black38),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ]
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void requestAndShowWifiList(BuildContext context, bool visibleDg) {
    final commService = Provider.of<CommunicationService>(context, listen: false);
    String payLoadFinal = jsonEncode({"7200": {"7201": ''}});
    commService.sendCommand(serverMsg: '', payload: payLoadFinal);
    if(!visibleDg){
      showWifiListDialog(context);
    }
  }

  void showWifiListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final connectingNetwork = ValueNotifier<String?>(null);
        final provider = context.watch<MqttPayloadProvider>();
        final networks = provider.wifiList;
        final message = provider.wifiMessage;
        final wifiStatus = provider.wifiStatus;
        final interfaceType = provider.interfaceType;
        final ipAddress = provider.ipAddress;

        if (message != null && message.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (message == 'WWi-Fi is now ON' || message == 'Wi-Fi is now OFF') {
              context.read<MqttPayloadProvider>().clearWifiMessage();
              Future.delayed(const Duration(milliseconds: 1500), () {
                requestAndShowWifiList(context, true);
              });
            } else {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Changing controller network..."),
                    content: Text(message),
                    actions: [
                      TextButton(
                        onPressed: () {
                          context.read<MqttPayloadProvider>().clearWifiMessage();
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showWifiListDialog(context);
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  );
                },
              );
            }
          });
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.wifi),
                    title: const Text("Wi-Fi"),
                    subtitle: wifiStatus == '2'
                        ? const Text(
                      'Wi-Fi is enabled on the controller \n But No Internet connection',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    )
                        : Text(
                      wifiStatus == '1'
                          ? 'Wi-Fi is enabled on the controller'
                          : 'Wi-Fi is disabled on the controller',
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: provider.wifiStateChanging? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ) : Switch(
                        value: wifiStatus == '1' || wifiStatus == '2',
                        activeColor: Colors.blue,
                        onChanged: (bool value) async {
                          provider.updateWifiStatus('0', true);
                          final communicationService = context.read<CommunicationService>();
                          final livePayload = jsonEncode({
                            "6000": {
                              "6001": value ? '1,0,0' : '0,0,0',
                            }
                          });

                          await communicationService.sendCommand(serverMsg: '', payload: livePayload,);

                        },
                      ),
                    ),
                  ),
                  const Divider(height: 0),
                  (wifiStatus=='1'||wifiStatus=='2')? ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Available Networks"),
                    subtitle: const Text(
                      "Select a Wi-Fi network to change the controller's connection.",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        requestAndShowWifiList(context, true);
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ) :
                  const SizedBox(),
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: SizedBox(
                width: double.maxFinite,
                child: interfaceType=='ethernet'? ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Controller connected with ethernet'),
                  subtitle: Text('IpAddress : $ipAddress'),
                  trailing: const Icon(Icons.cast_connected),
                ):
                networks.isEmpty
                    ? const SizedBox(height: 20, child: Center(child: Text("No networks found.")))
                    : ValueListenableBuilder<String?>(
                  valueListenable: connectingNetwork,
                  builder: (dialogContext, connectingSsid, _) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: networks.length,
                      itemBuilder: (context, index) {
                        final net = networks[index];
                        final ssid = net["SSID"] ?? "Unknown";
                        final bool isSecured = (net["SECURITY"] != null);

                        return ListTile(
                          leading: Icon(
                            Icons.wifi,
                            color: net["SIGNAL"] >= 75
                                ? Colors.green
                                : (net["SIGNAL"] >= 50 ? Colors.orange : Colors.red),
                          ),
                          title: Text(ssid),
                          subtitle: Text("Signal: ${net["SIGNAL"]}%"),
                          trailing: connectingSsid == ssid
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : (net["IN-USE"] == "1"
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : null),
                          onTap: () async {
                            connectingNetwork.value = ssid;

                            final communicationService = context.read<CommunicationService>();

                            if (isSecured) {
                              final password = await showPasswordDialog(context, ssid);
                              if (password == null || password.isEmpty) return;

                              final payload = '2,$ssid,$password';
                              final livePayload = jsonEncode({"6000": {"6001": payload}});
                              await communicationService.sendCommand(serverMsg: '', payload: livePayload);
                            } else {
                              final payload = '2,$ssid,';
                              final livePayload = jsonEncode({"6000": {"6001": payload}});
                              await communicationService.sendCommand(serverMsg: '', payload: livePayload);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> showPasswordDialog(BuildContext context, String ssid) async {
    final TextEditingController passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter password for "$ssid"'),
        content: PasswordField(controller: passwordController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }


  void showWifiDialog(BuildContext context, BluetoothBleService bleService) {
    final ssidController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Configure WiFi"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ssidController,
                decoration: const InputDecoration(labelText: "SSID"),
              ),
              TextField(
                controller: passController,
                decoration: const InputDecoration(labelText: "Password"),
              ),
            ],
          ),
          actions: [


            TextButton(
              onPressed: () async {
                final ssid = ssidController.text.trim();
                final password = passController.text.trim();

                if (ssid.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("SSID and Password cannot be empty"),
                    ),
                  );
                  return;
                }

                final communicationService = context.read<CommunicationService>();
                final payload = '2,$ssid,$password';
                final livePayload = jsonEncode({"6000": {"6001": payload}});
                await communicationService.sendCommand(serverMsg: '', payload: livePayload);

                Navigator.pop(context);
              },
              child: const Text("Send"),
            )
          ],
        );
      },
    );
  }
}*/
