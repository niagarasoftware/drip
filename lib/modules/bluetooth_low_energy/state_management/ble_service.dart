import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:oro_drip_irrigation/modules/bluetooth_low_energy/utils/extra.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:path_provider/path_provider.dart';
import '../../../services/sftp_service.dart';
import '../utils/snackbar.dart';

enum BleNodeState {
  loading,
  bluetoothOff,
  locationOff,
  scanning,
  deviceFound,
  deviceNotFound,
  connecting,
  connected,
  disConnected,
  dashboard,
}

enum TraceMode{
  traceOn,
  traceOff
}

enum FileMode{
  connected,
  connecting,
  errorOnConnected,
  disConnected,
  idle,
  fileNameGetSuccess,
  fileNameNotGet,
  errorOnWhileGetFileName,
  tryAgainToGetFileName,
  downloadFileSuccess,
  downloadingFile,
  downloadFileFailed,
  uploadFileSuccess,
  uploadingFile,
  uploadFileFailed,
  sendingToHardware,
  crcPass,
  crcFail,
  firmwareUpdating,
  bootPass,
  bootFail,
}


enum ConnectMode{pumpWifiDefault, normal}

class BleProvider extends ChangeNotifier {
  BleNodeState bleNodeState = BleNodeState.bluetoothOff;
  TraceMode traceMode = TraceMode.traceOff;
  FileMode fileMode = FileMode.idle;

  /*scanning variables*/
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  ConnectMode bleConnectMode = ConnectMode.normal;

  /* connecting variables*/
  BluetoothDevice? device;
  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState bleConnectionState = BluetoothConnectionState.disconnected;
  bool forceStop = false;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;

  /* communicating variables*/
  BluetoothService? myService;
  BluetoothCharacteristic? sendToHardware;
  BluetoothCharacteristic? readFromHardware;
  List<int> sendToHardwareListeningValue = [];
  List<int> readFromHardwareListeningValue = [];
  late StreamSubscription<List<int>> sendToHardwareSubscription;
  late StreamSubscription<List<int>> readFromHardwareSubscription;
  Map<String, dynamic> nodeDataFromHw = {};
  String  readFromHardwareStringValue = '';
  int addingResult = 0;
  String addingStringResult = '';
  int totalNoOfLines = 0;
  int currentLine = 0;
  final List<String> traceData = [];
  final List<String> sentAndReceive = [];
  int developerOption = 0;

  /*controller variable*/
  ScrollController traceScrollController = ScrollController();
  TextEditingController frequency = TextEditingController();
  TextEditingController spreadFactor = TextEditingController();
  TextEditingController wifiSsid = TextEditingController();
  TextEditingController wifiPassword = TextEditingController();
  TextEditingController ec1Controller = TextEditingController();
  TextEditingController ec1FactorController = TextEditingController();
  TextEditingController ec1_Controller = TextEditingController();
  TextEditingController ec1_FactorController = TextEditingController();
  TextEditingController ec1__Controller = TextEditingController();
  TextEditingController ec1__FactorController = TextEditingController();
  TextEditingController ec2Controller = TextEditingController();
  TextEditingController ec2FactorController = TextEditingController();
  TextEditingController ec2_Controller = TextEditingController();
  TextEditingController ec2_FactorController = TextEditingController();
  TextEditingController ec2__Controller = TextEditingController();
  TextEditingController ec2__FactorController = TextEditingController();
  TextEditingController ph1Controller = TextEditingController();
  TextEditingController ph1FactorController = TextEditingController();
  TextEditingController ph1_Controller = TextEditingController();
  TextEditingController ph1_FactorController = TextEditingController();
  TextEditingController ph2Controller = TextEditingController();
  TextEditingController ph2FactorController = TextEditingController();
  TextEditingController ph2_Controller = TextEditingController();
  TextEditingController ph2_FactorController = TextEditingController();
  TextEditingController cumulativeController = TextEditingController();
  TextEditingController batteryController = TextEditingController();
  String calibrationEc1 = 'ec1';
  String calibrationEc2 = 'ec2';
  String calibrationPh1 = 'ph1';
  String calibrationPh2 = 'ph2';

  /* server variable*/
  Map<String, dynamic> nodeDataFromServer = {};
  String nodeFirmwareFileName = '';
  Map<String, dynamic> nodeData = {};
  List<String> loraModel = ['40', '41', '42'];
  int modelId = 0;

  void editNodeDataFromServer(data, nodeDataFromNodeStatus){
    nodeDataFromServer = data;
    nodeData = nodeDataFromNodeStatus;
    print("nodeDataFromServer : $nodeDataFromServer");
    print("nodeData : $nodeData");
    // if(AppConstants.ecoGemModelList.contains(nodeData['modelId'])){
    //   nodeDataFromServer['pathSetting']['downloadDirectory'] = "/home/ubuntu/FTP/download/EC25/";
    // }else if(AppConstants.pumpWithValveModelList.contains(nodeData['modelId'])){
    //   nodeDataFromServer['pathSetting']['downloadDirectory'] = "/home/ubuntu/FTP/download/PUMP_VALVE/";
    // }
    debugPrint("nodeDataFromServer : ${nodeDataFromServer['pathSetting']}");
    notifyListeners();
  }

  String connectionState(){
    if(bleConnectionState == BluetoothConnectionState.connected){
      return "Connected";
    }else if(bleConnectionState == BluetoothConnectionState.disconnected){
      return "DisConnected";
    }else{
      return "Connecting...";
    }
  }

  void autoScanAndFoundDevice({required String macAddressToConnect, required int modelIdToUpdate, required ConnectMode connectMode}) async{
    modelId = modelIdToUpdate;
    bleNodeState = BleNodeState.scanning;
    forceStop = false;
    bleConnectMode = connectMode;
    notifyListeners();
    startListeningDevice();
    startScan();
    outerLoop : for(var scanLoop = 0;scanLoop < 15;scanLoop++){
      if(forceStop){
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
      debugPrint("_isScanning :: $_isScanning");
      for(var result in _scanResults){
        var adv = result.advertisementData;
        String upComingMacAddress = result.device.remoteId.toString().split(':').join('');
        debugPrint("upComingMacAddress : $upComingMacAddress");
        bool filterByCondition = connectMode == ConnectMode.pumpWifiDefault;
        debugPrint("filterByCondition : $filterByCondition");
        if(macAddressToConnect == upComingMacAddress && (filterByCondition ? result.device.platformName.contains('WIFI_') : result.device.platformName.contains('NIA_'))){
          debugPrint("result.device.platformName : ${result.device.platformName}");
          debugPrint("device : ${result.device}");
          device = result.device;
          bleNodeState = BleNodeState.deviceFound;
          notifyListeners();
          debugPrint("device is found ...............................................");
          await Future.delayed(const Duration(seconds: 2));
          break outerLoop;
        }
      }
    }
    if(bleNodeState != BleNodeState.deviceFound){
      bleNodeState = BleNodeState.deviceNotFound;
      notifyListeners();
    }
    stopScan();
    clearListOfScanDevice();
    if(bleNodeState == BleNodeState.deviceFound){
      autoConnect();
    }
  }

  Future startScan() async {
    try {
      // `withServices` is required on iOS for privacy purposes, ignored on android.
      var withServices = [Guid("180f")]; // Battery Level Service
      _systemDevices = await FlutterBluePlus.systemDevices(withServices);
    } catch (e, backtrace) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
      debugPrint(e.toString());
      debugPrint("backtrace: $backtrace");
    }
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
        withServices: [
          // Guid("180f"), // battery
          // Guid("180a"), // device info
          // Guid("1800"), // generic access
          // Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e"), // Nordic UART
        ],
        webOptionalServices: [
          Guid("180f"), // battery
          Guid("180a"), // device info
          Guid("1800"), // generic access
          Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e"), // Nordic UART
        ],
      );
    } catch (e, backtrace) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
      debugPrint(e.toString());
      debugPrint("backtrace: $backtrace");
    }
  }

  Future stopScan() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e, backtrace) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e), success: false);
      debugPrint(e.toString());
      debugPrint("backtrace: $backtrace");
    }
  }

  void startListeningDevice(){
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
    });
  }

  void clearListOfScanDevice(){
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _scanResults.clear();
    _systemDevices.clear();
  }

  void autoConnect()async{
    bleNodeState = BleNodeState.connecting;
    notifyListeners();
    listeningConnectionState();
    for(var connectLoop = 0;connectLoop < 30;connectLoop++){
      await Future.delayed(const Duration(seconds: 1));
      debugPrint("connecting seconds :: ${connectLoop+1}");
      if(forceStop){
        debugPrint('force stop when connecting...........');
        return;
      }
      if(bleConnectionState == BluetoothConnectionState.connected){
        bleNodeState = BleNodeState.connected;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        bleNodeState = BleNodeState.dashboard;
        notifyListeners();
        break;
      }
    }
    if(bleNodeState != BleNodeState.connected && bleNodeState != BleNodeState.dashboard){
      bleNodeState = BleNodeState.disConnected;
      notifyListeners();
    }
  }

  void listeningConnectionState(){
    onConnect();
    _connectionStateSubscription = device!.connectionState.listen((state) async {
      bleConnectionState = state;
      notifyListeners();
      if (state == BluetoothConnectionState.connected) {

        _services = []; // must rediscover services
        _isDiscoveringServices = true;
        try {
          _services = await device!.discoverServices();
          onRequestMtuPressed();
          updateCharacteristic();
          gettingStatusAfterConnect();
          if (kDebugMode) {
            debugPrint('_services === $_services');
            debugPrint(
                '----------------------------------------MTU SIZE REQUEST TO MAXIMUM------------------');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error on discover repository: $e');
          }
        }
        _isDiscoveringServices = false;
      }
      else if(state == BluetoothConnectionState.disconnected && bleNodeState != BleNodeState.connecting){
        if (kDebugMode) {
          debugPrint("state ::: $state");
          debugPrint("bleNodeState.name ::: ${bleNodeState.name}");
        }
        clearBluetoothDeviceState();
        bleNodeState = BleNodeState.disConnected;
        notifyListeners();
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await device!.readRssi();
      }
    });

    _mtuSubscription = device!.mtu.listen((value) {
      _mtuSize = value;
    });

    _isConnectingSubscription = device!.isConnecting.listen((value) {
      _isConnecting = value;
    });

    _isDisconnectingSubscription = device!.isDisconnecting.listen((value) {
      _isDisconnecting = value;
    });
  }

  void gettingStatusAfterConnect() async {
    for (var i = 0; i < 200; i++) {
      if(bleConnectionState == BluetoothConnectionState.disconnected){
        break;
      }
      try {
        if(nodeDataFromHw.isNotEmpty){
          break;
        }
        await Future.delayed(const Duration(seconds: 2));
        if(bleNodeState == BleNodeState.disConnected){
          return;
        }
        if (kDebugMode) {
          debugPrint('after connect ${i + 1}');
          debugPrint('Requesting mac address.....');
        }
        requestingMac();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('requesting mac is stopped due to : ${e.toString()}');
        }
        break;
      }
    }
    notifyListeners();
  }

  void requestingMac()async{
    List<int> sendMac = [];
    for (var i in 'MAC\n'.split('')) {
      sendMac.add(i.codeUnitAt(0));
    }
    await sendToHardware!.write(sendMac,
    withoutResponse:
    sendToHardware!.properties.writeWithoutResponse);
  }

  void changingNodeToBootMode()async{
    List<int> checkBootFile = [];
    for (var bootCode
    in 'NIA_BLE_BOOT_SAMD21'.split('')) {
      checkBootFile.add(bootCode.codeUnitAt(0));
    }
    await sendToHardware!.write(
        checkBootFile,
        withoutResponse: sendToHardware!
            .properties.writeWithoutResponse);
  }

  void updateCharacteristic() {
    // Debug all services
    for (var s in _services) {
      debugPrint('service => $s');
    }
    print("modelId : ${modelId}");
    final isWlc = AppConstants.wlcModelList.contains(modelId);
    final isPumpWifi = AppConstants.pumpWifiDefault.contains(modelId);

    // Select service
    if (isWlc) {
      debugPrint("connect to wlc model....");
      myService = _services[2];
    } else if (isPumpWifi && bleConnectMode == ConnectMode.pumpWifiDefault) {
      debugPrint("connect to pumpWifiDefault model....");
      debugPrint("_services : ${_services.length}");
      myService = _services[2];
    } else {
      debugPrint("connect to node model....");
      myService = _services[1];
    }

    debugPrint("myService!.characteristics : ${myService!.characteristics}");

    for (BluetoothCharacteristic c in myService!.characteristics) {
      debugPrint("characteristic => ${c.uuid} == $c");

      final props = c.properties;

      // -------- READ CHARACTERISTIC CONDITION --------
      bool isReadCharacteristic = false;

      if (isWlc) {
        isReadCharacteristic =
            !props.writeWithoutResponse &&
                !props.write &&
                props.notify;
      } else if (isPumpWifi && bleConnectMode == ConnectMode.pumpWifiDefault) {
        isReadCharacteristic =
            props.writeWithoutResponse &&
                !props.write &&
                props.notify;
      } else {
        isReadCharacteristic =
            !props.writeWithoutResponse &&
                props.write &&
                props.notify;
      }

      if (isReadCharacteristic) {
        if (readFromHardware == null) {
          listeningReadFromHardwareSubscription(c);
        }
        debugPrint('readFromHardware == ${c.uuid}');
        readFromHardware = c;
      }

      // -------- WRITE CHARACTERISTIC CONDITION --------
      final isWriteCharacteristic =
          (props.writeWithoutResponse || isWlc || isPumpWifi) &&
              !props.notify;

      if (isWriteCharacteristic) {
        if (sendToHardware == null) {
          listeningSendToHardwareSubscription(c);
        }
        debugPrint('sendToHardware == ${c.uuid}');
        sendToHardware = c;
      }
    }
  }


  void listeningSendToHardwareSubscription(BluetoothCharacteristic? characteristic) {
    debugPrint('listeningSendingData called............................................................');
    if (characteristic != null) {
      sendToHardwareSubscription =
          characteristic.lastValueStream.listen((value) {
            String convertToString = String.fromCharCodes(value);
            if (kDebugMode) {
              debugPrint('AppToHardware =>  $convertToString');
            }
            if(fileMode != FileMode.sendingToHardware){
              sentAndReceive.add('AppToHardware =>  $convertToString');
            }
          });
    } else {
      debugPrint('sending characteristic is null');
    }
  }

  void listeningReadFromHardwareSubscription(BluetoothCharacteristic? characteristic) {
    debugPrint(
        'listeningReceivingData called............................................................');
    if (characteristic != null) {
      characteristic.setNotifyValue(true);
      readFromHardwareSubscription =
          characteristic.lastValueStream.listen((value) async {
            if (kDebugMode) {
              debugPrint('from hardware :: $value');
            }
            String convertToString = String.fromCharCodes(value);
            if (kDebugMode) {
              debugPrint("read :: $convertToString");
            }
            if(traceMode == TraceMode.traceOff){
              sentAndReceive.add("hardwareToApp = > $convertToString");
              if(convertToString == "PASS"){
                fileMode = FileMode.crcPass;
                notifyListeners();
              }else if(convertToString == "FAIL"){
                fileMode = FileMode.crcFail;
                notifyListeners();
              }else if(convertToString == "START"){
                timeOutForBootMessage();
                fileMode = FileMode.firmwareUpdating;
                notifyListeners();
              }else if(convertToString == "BOOTPASS"){
                fileMode = FileMode.bootPass;
                notifyListeners();
              }
              if (value.isNotEmpty) {
                readFromHardwareStringValue += String.fromCharCodes(value);
              }
              if(value.isNotEmpty && value[value.length - 1] == 125){
                if(readFromHardwareStringValue[0] == '{'){
                  if(readFromHardwareStringValue.contains('MID')){
                    nodeDataFromHw = jsonDecode(readFromHardwareStringValue);
                  }
                  readFromHardwareStringValue = '';
                }else{
                  readFromHardwareStringValue = '';
                }
              }
              if (nodeDataFromHw.containsKey('PIN')) {
                cumulativeController.text = nodeDataFromHw['PIN'];
              }
              if (nodeDataFromHw.containsKey('BC')) {
                batteryController.text = nodeDataFromHw['BC'];
              }

              if (nodeDataFromHw.containsKey('AD7')) {
                if (calibrationEc1 == 'ec1') {
                  ec1Controller.text = nodeDataFromHw['AD7'];
                }
                if (calibrationEc1 == 'ec_1') {
                  ec1_Controller.text = nodeDataFromHw['AD7'];
                }
                if (calibrationEc1 == 'ec__1') {
                  ec1__Controller.text = nodeDataFromHw['AD7'];
                }
              }
              if (nodeDataFromHw.containsKey('EC1_CAL')) {
                ec1FactorController.text = nodeDataFromHw['EC1_CAL'].split(',')[0];
                ec1_FactorController.text = nodeDataFromHw['EC1_CAL'].split(',')[1];
                ec1__FactorController.text = nodeDataFromHw['EC1_CAL'].split(',')[2];
              }
              if (nodeDataFromHw.containsKey('EC2_CAL')) {
                ec2FactorController.text = nodeDataFromHw['EC2_CAL'].split(',')[0];
                ec2_FactorController.text = nodeDataFromHw['EC2_CAL'].split(',')[1];
                ec2__FactorController.text = nodeDataFromHw['EC2_CAL'].split(',')[2];
              }
              if (nodeDataFromHw.containsKey('PH1_CAL')) {
                ph1FactorController.text = nodeDataFromHw['PH1_CAL'].split(',')[0];
                ph1_FactorController.text = nodeDataFromHw['PH1_CAL'].split(',')[1];
              }
              if (nodeDataFromHw.containsKey('PH2_CAL')) {
                ph2FactorController.text = nodeDataFromHw['PH2_CAL'].split(',')[0];
                ph2_FactorController.text = nodeDataFromHw['PH2_CAL'].split(',')[1];
              }
              if (nodeDataFromHw.containsKey('AD8')) {
                if (calibrationEc2 == 'ec2') {
                  ec2Controller.text = nodeDataFromHw['AD8'];
                }
                if (calibrationEc2 == 'ec_2') {
                  ec2_Controller.text = nodeDataFromHw['AD8'];
                }
                if (calibrationEc2 == 'ec__2') {
                  ec2__Controller.text = nodeDataFromHw['AD8'];
                }
              }
              if (nodeDataFromHw.containsKey('AD5')) {
                if (calibrationPh1 == 'ph1') {
                  ph1Controller.text = nodeDataFromHw['AD5'];
                }
                if (calibrationPh1 == 'ph_1') {
                  ph1_Controller.text = nodeDataFromHw['AD5'];
                }
              }
              if (nodeDataFromHw.containsKey('AD6')) {
                if (calibrationPh2 == 'ph2') {
                  ph2Controller.text = nodeDataFromHw['AD6'];
                }
                if (calibrationPh2 == 'ph_2') {
                  ph2_Controller.text = nodeDataFromHw['AD6'];
                }
              }

              if (nodeDataFromHw.containsKey('FRQ')) {
                frequency.text = '${int.parse(nodeDataFromHw['FRQ']) / 10}';
              }
              if (nodeDataFromHw.containsKey('SF')) {
                spreadFactor.text = nodeDataFromHw['SF'];
              }
              if (nodeDataFromHw.containsKey('WIFISSID')) {
                wifiSsid.text = nodeDataFromHw['WIFISSID'];
              }
              if (nodeDataFromHw.containsKey('WIFIPASS')) {
                wifiPassword.text = nodeDataFromHw['WIFIPASS'];
              }
              if (kDebugMode) {
                debugPrint("nodeDataFromHw : $nodeDataFromHw");
              }
              notifyListeners();
            }else if(traceMode == TraceMode.traceOn){
              traceData.add(convertToString);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (traceScrollController.hasClients) {
                  traceScrollController.animateTo(
                    traceScrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
              notifyListeners();
            }

          });
    } else {
      if (kDebugMode) {
        debugPrint('receiving characteristic is null');
      }
    }
  }

  void timeOutForBootMessage()async{
    int totalTimeOut = 100;
    for(var second = 0;second < totalTimeOut;second++){
      if(fileMode == FileMode.bootPass || fileMode == FileMode.bootFail){
        requestingMacUntilBootModeToApp();
        break;
      }
      await Future.delayed(const Duration(seconds: 1));
      if (kDebugMode) {
        debugPrint("waiting for boot pass ${second+1}");
      }
      if(second == (totalTimeOut - 1)){
        fileMode = FileMode.bootFail;
        notifyListeners();
        break;
      }
    }
  }

  void requestingMacUntilBootModeToApp()async{
    await Future.delayed(const Duration(seconds: 3));
    onDisconnect(clearAll: false);
    // for(var waitLoop = 0;waitLoop < 15;waitLoop++){
    //   if(nodeDataFromHw['BOOT'] == '30'){
    //     break;
    //   }
    //   await Future.delayed(const Duration(seconds: 2));
    //   requestingMac();
    //   debugPrint("userShouldWaitForBootModeToApp seconds : ${waitLoop + 1}");
    //   debugPrint("nodeDataFromHw : ${nodeDataFromHw}");
    // }
  }

  Future onConnect() async {
    try {
      await device!.connectAndUpdateStream();
      // Snackbar.show(ABC.c, "Connect: Success", success: true);
    } catch (e, backtrace) {
      if (e is FlutterBluePlusException && e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        // Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
        if (kDebugMode) {
          debugPrint(e.toString());
          debugPrint("backtrace: $backtrace");
        }

      }
    }
  }

  Future onCancel() async {
    try {
      await device!.disconnectAndUpdateStream(queue: false);
      // Snackbar.show(ABC.c, "Cancel: Success", success: true);
    } catch (e, backtrace) {
      // Snackbar.show(ABC.c, prettyException("Cancel Error:", e), success: false);
      if (kDebugMode) {
        debugPrint("$e");
        debugPrint("backtrace: $backtrace");
      }

    }
  }

  Future onDisconnect({required bool clearAll}) async {
    try {
      await device!.disconnectAndUpdateStream();
      clearBluetoothDeviceState();
      notifyListeners();
      // Snackbar.show(ABC.c, "Disconne
      // ct: Success", success: true);
    } catch (e, backtrace) {
      // Snackbar.show(ABC.c, prettyException("Disconnect Error:", e), success: false);
      if (kDebugMode) {
        debugPrint("$e backtrace: $backtrace");
      }
    }
  }

  Future onRequestMtuPressed() async {
    try {
      await device!.requestMtu(330, predelay: 0);
      // Snackbar.show(ABC.c, "Request Mtu: Success", success: true);
    } catch (e, backtrace) {
      // Snackbar.show(ABC.c, prettyException("Change Mtu Error:", e), success: false);
      if (kDebugMode) {
        debugPrint(e.toString());
        debugPrint("backtrace: $backtrace");
      }

    }
  }

  void clearBluetoothDeviceState(){
    nodeFirmwareFileName = '';
    nodeDataFromHw = {};
    traceData.clear();
    sentAndReceive.clear();
    fileMode = FileMode.idle;
    bleNodeState = BleNodeState.deviceNotFound;
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _systemDevices.clear();
    _scanResults.clear();
    sendToHardware = null;
    readFromHardware = null;
    sendToHardwareSubscription.cancel();
    readFromHardwareSubscription.cancel();
    device = null;
    _services.clear();
    _connectionStateSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    _mtuSubscription.cancel();
    notifyListeners();
  }

  Future<void> getFileName()async{
    try{
      SftpService sftpService = SftpService();
      fileMode = FileMode.connecting;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 2));
      int connectResponse =  await sftpService.connect();
      if(connectResponse == 200){
        fileMode = FileMode.connected;
        notifyListeners();
        if (kDebugMode) {
          debugPrint("nodeDataFromServer['pathSetting'] :: ${nodeDataFromServer['pathSetting']}");
        }
        String pathToFindOutFile = nodeDataFromServer['pathSetting']['downloadDirectory'];
        if (kDebugMode) {
          debugPrint("pathToFindOutFile : $pathToFindOutFile");
        }
        List<SftpName> listOfFile = await sftpService.listFilesInPath(pathToFindOutFile);
        for(var file in listOfFile){
          if(file.filename.contains('version')){
            nodeFirmwareFileName = file.filename;
          }
        }
        if(nodeFirmwareFileName.isNotEmpty){
          fileMode = FileMode.fileNameGetSuccess;
          notifyListeners();
        }else{
          fileMode = FileMode.fileNameNotGet;
          notifyListeners();
        }
        fileMode = FileMode.downloadingFile;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        int downloadResponse = await sftpService.downloadFile(remoteFilePath: '$pathToFindOutFile/$nodeFirmwareFileName');
        if(downloadResponse == 200){
          fileMode = FileMode.downloadFileSuccess;
        }else{
          fileMode = FileMode.downloadFileFailed;
        }
        sftpService.disconnect();
        notifyListeners();
      }else{
        fileMode = FileMode.errorOnConnected;
      }
      notifyListeners();
      
    }catch(e, backTrace){
      fileMode = FileMode.errorOnWhileGetFileName;
      if (kDebugMode) {
        debugPrint('Error on getting File Name :: ${e}');
      }
      rethrow;
    }
  }

  void uploadTraceFile({required String deviceId})async{
    SftpService sftpService = SftpService();
    fileMode = FileMode.connecting;
    notifyListeners();
    int connectResponse =  await sftpService.connect();
    if(connectResponse == 200){
      fileMode = FileMode.connected;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 1));
      fileMode = FileMode.uploadingFile;
      notifyListeners();
      String localFileNameForTrace = "trace_data";
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String filePath = '$appDocPath/$localFileNameForTrace.txt';
      final localFile = File(filePath);
      await localFile.writeAsString(traceData.join('\n'));
      int uploadResponse = await sftpService.uploadFile(localFileName: localFileNameForTrace, remoteFilePath: '${nodeDataFromServer['pathSetting']['uploadDirectory']}$deviceId.txt');
      if(uploadResponse == 200){
        fileMode = FileMode.uploadFileSuccess;
      }else{
        fileMode = FileMode.uploadFileFailed;
      }
      sftpService.disconnect();
      notifyListeners();
    }else{
      fileMode = FileMode.errorOnConnected;
    }
  }

  void sendBootFile()async{
    try {
      List<String> listOfLine = await fetchBootFileInLocal();
      int noOfLinesToSend = 8;
      for (var line = 0; line < listOfLine.length; line += noOfLinesToSend) {
        if(bleConnectionState == BluetoothConnectionState.disconnected){
          return;
        }
        List<int> dataList = [];
        var increasingLineCount = line + noOfLinesToSend;
        var slicingLoopFor8Line = increasingLineCount < listOfLine.length
            ? increasingLineCount
            : (increasingLineCount -
            (increasingLineCount - listOfLine.length));
        for (var count = line; count < slicingLoopFor8Line; count++) {
          var listOfSingleChar = listOfLine[count].split('');
          for (var takeTwo = 0;
          takeTwo < listOfSingleChar.length - 1;
          takeTwo += 2) {
            var doubleCharValue = int.parse(
                '${listOfSingleChar[takeTwo]}${listOfSingleChar[takeTwo + 1]}',
                radix: 16);
            dataList.add(doubleCharValue);
          }
        }

        List<int> writeData = [];
        for (var bytes = 0; bytes < dataList.length; bytes++) {
          addingResult += dataList[bytes];
          writeData.add(dataList[bytes]);
        }

        if (sendToHardware != null) {
          await sendToHardware!.write(writeData,
              withoutResponse:
              sendToHardware!.properties.writeWithoutResponse);
          await Future.delayed(const Duration(milliseconds: 10));
        }
        currentLine += 8;
        if (kDebugMode) {
          debugPrint("line ==================== $line");
          debugPrint("currentLine ==================== $currentLine");
        }

        notifyListeners();
      }
      sendCalculatedCrc(lengthOfFile: listOfLine.length);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('overAll Error => ${e.toString()}');
      }
      Snackbar.show(ABC.c, prettyException("Write Error:", e), success: false);
    }
    notifyListeners();
  }

  Future<List<String>> fetchBootFileInLocal()async{
    fileMode = FileMode.sendingToHardware;
    notifyListeners();
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String localFileName = 'bootFile.txt';
    String filePath = '$appDocPath/$localFileName';
    File file = File(filePath);
    String fileContent = await file.readAsString();
    if (kDebugMode) {
      debugPrint('noOfLine   => ${fileContent.split('\n').length}');
    }
    totalNoOfLines = 0;
    currentLine = 0;
    addingResult = 0;
    addingStringResult = '';
    List<String> listOfLine = fileContent.split('\n');
    totalNoOfLines = listOfLine.length;
    notifyListeners();
    return listOfLine;
  }

  void sendCalculatedCrc({required int lengthOfFile})async{
    try {
      await Future.delayed(Duration(seconds: 1));
      if (kDebugMode) {
        debugPrint('addingResult === > ${addingResult}');
        debugPrint('result is : ${addingResult.toRadixString(16).toUpperCase()}');
      }


      String result = addingResult.toRadixString(16).toUpperCase();
      var resultList = result.split('');
      if (resultList.length > 8) {
        // Dont delete..............................................
        // Example list
        // List<dynamic> resultList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        // Using sublist to get the last 8 elements
        // resultList = resultList.sublist(resultList.length - 8);
        // Now `resultList` contains only the last 8 elements
        // debugPrint(resultList); // Output: [3, 4, 5, 6, 7, 8, 9, 10]
        // .................................................................
        resultList = resultList.sublist(resultList.length - 8);
      } else {
        int loop = 8 - resultList.length;
        for (var len = 0; len < loop; len++) {
          resultList.insert(0, '0');
        }
      }
      List<int> crcList = [];
      for (var crc = 0; crc < resultList.length; crc += 2) {
        crcList.add(
            int.parse('${resultList[crc]}${resultList[crc + 1]}', radix: 16));
      }
      List<int> crcName = [];
      String crcNameStr = 'CRC:';
      for (var cName in 'CRC:'.split('')) {
        crcName.add(cName.codeUnitAt(0));
      }
      List<int> fileLengthName = [];
      String fileLengthStr = ',L:';
      for (var fName in ',L:'.split('')) {
        fileLengthName.add(fName.codeUnitAt(0));
      }
      int fileSize = ((lengthOfFile) * 16).toInt();
      if (kDebugMode) {
        debugPrint('fileSize => ${fileSize}');
      }
      String fileSizeString = fileSize.toRadixString(16).toUpperCase();
      var fileSizeStringList = fileSizeString.split('');
      if (fileSizeStringList.length > 8) {
        // Dont delete..............................................
        // Example list
        // List<dynamic> fileSizeStringList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        // Using sublist to get the last 8 elements
        // fileSizeStringList = fileSizeStringList.sublist(fileSizeStringList.length - 8);
        // Now `fileSizeStringList` contains only the last 8 elements
        // debugPrint(fileSizeStringList); // Output: [3, 4, 5, 6, 7, 8, 9, 10]
        // .................................................................
        fileSizeStringList =
            fileSizeStringList.sublist(fileSizeStringList.length - 8);
      } else {
        int loop = 8 - fileSizeStringList.length;
        for (var len = 0; len < loop; len++) {
          fileSizeStringList.insert(0, '0');
        }
      }
      if (kDebugMode) {
        debugPrint('fileSizeStringList => ${fileSizeStringList}');
      }
      List<int> crcFormatFileSizeStringList = [];
      for (var cfsf = 0; cfsf < fileSizeStringList.length; cfsf += 2) {
        crcFormatFileSizeStringList.add(int.parse(
            '${fileSizeStringList[cfsf]}${fileSizeStringList[cfsf + 1]}',
            radix: 16));
      }
      List<int> finalOutPutOfCrcAndFileSize = [
        ...crcName,
        ...crcList,
        ...fileLengthName,
        ...crcFormatFileSizeStringList
      ];
      await Future.delayed(const Duration(milliseconds: 100));
      if (kDebugMode) {
        debugPrint("finalOutPutOfCrcAndFileSize ==> $finalOutPutOfCrcAndFileSize");
      }
      await sendToHardware?.write(finalOutPutOfCrcAndFileSize,
          withoutResponse:
          sendToHardware!.properties.writeWithoutResponse);
      var beforeConversion = 'before conversion :: $crcNameStr$addingResult$fileLengthStr$fileSize';
      if (kDebugMode) {
        debugPrint("beforeConversion => $beforeConversion");
      }
      sentAndReceive.add(beforeConversion);
      for (var crc in finalOutPutOfCrcAndFileSize) {
        sentAndReceive.add('${crc.toRadixString(16).padLeft(2, '0')}');
      }
      sentAndReceive.add('file size ==> ${fileSize}');
      waitingForCrcPassOrCrcFail();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error on crc & others => ${e.toString()}');
      }
    }

    Snackbar.show(ABC.c, "Write: Success", success: true);
    if (sendToHardware!.properties.read) {
      await sendToHardware!.read();
    }
  }

  String sendThreeDigit(String val){
    List<String> value = val.split('');
    for(var i = 0;i < (3 - val.length);i++){
      value.insert(0, '0');
    }
    return value.join('');
  }

  void waitingForCrcPassOrCrcFail()async{
    int crcDelay = 8;
    for(var i = 0; i < crcDelay;i++){
      if (kDebugMode) {
        debugPrint("waiting for crc command :: ${i+1}");
      }
      await Future.delayed(const Duration(seconds: 1));
      if(fileMode == FileMode.crcPass || fileMode == FileMode.crcFail || fileMode == FileMode.firmwareUpdating){
        break;
      }
      if(i == (crcDelay - 1)){
        fileMode = FileMode.bootFail;
      }
    }
    notifyListeners();
  }

  void sendTraceCommand() async {
    if (sendToHardware != null) {
      if(traceMode == TraceMode.traceOn){
        traceMode = TraceMode.traceOff;
      }else{
        traceScrollController = ScrollController();
        traceMode = TraceMode.traceOn;
      }
      String on = "TRACE_ON";
      String off = "TRACE_OFF";
      List<int> checkBluetoothFile = [];
      for (var bleLine in (traceMode == TraceMode.traceOn ? on :off).split('')) {
        checkBluetoothFile.add(bleLine.codeUnitAt(0));
      }
      await sendToHardware?.write(checkBluetoothFile,
          withoutResponse:
          sendToHardware!.properties.writeWithoutResponse);
    }
    notifyListeners();
  }

  Future onRefresh() async{
    var payload = '\$:5:146:';
    List<int> listOfBytes = [];
    var sumOfAscii = 0;
    for (var i in payload.split('')) {
      var bytes = i.codeUnitAt(0);
      // listOfBytes.add(bytes);
      sumOfAscii += bytes;
    }
    payload += '${sendThreeDigit('${sumOfAscii % 256}')}:\r';
    for (var i in payload.split('')) {
      var bytes = i.codeUnitAt(0);
      listOfBytes.add(bytes);
    }

    if (kDebugMode) {
      debugPrint('listOfBytes : $listOfBytes');
      debugPrint('sumOfAscii : $sumOfAscii');
      debugPrint('crc : ${sumOfAscii % 256}');
      debugPrint('payload : $payload');
    }
    sendDataToHw(listOfBytes);
    return Future.delayed(const Duration(seconds: 1));
  }



  void sendDataToHw(List<int> dataToSend) async {
    if (sendToHardware == null) return;
    String pumpWifiDefaultServiceUuid = '49535343-FE7D-4AE5-8FA9-9FAFD205E455';
    // if(myService!.uuid.toString().toUpperCase() == pumpWifiDefaultServiceUuid){
    if(bleConnectMode == ConnectMode.pumpWifiDefault){
      const int chunkSize = 20;
      for (int i = 0; i < dataToSend.length; i += chunkSize) {
        final chunk = dataToSend.sublist(
          i,
          i + chunkSize > dataToSend.length ? dataToSend.length : i + chunkSize,
        );
        await sendToHardware!.write(
          chunk,
          withoutResponse: sendToHardware!.properties.writeWithoutResponse,
        );
      }
    }else{
      await sendToHardware?.write(dataToSend,
          withoutResponse:
          sendToHardware!.properties.writeWithoutResponse);
    }
    Snackbar.show(ABC.c, prettyException("Success", 'Successfully sent....'),
        success: true);
    notifyListeners();
  }
}