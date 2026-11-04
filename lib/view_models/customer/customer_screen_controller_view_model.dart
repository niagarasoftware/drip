import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:provider/provider.dart';
import '../../models/customer/site_model.dart';
import '../../StateManagement/customer_provider.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../repository/repository.dart';
import '../../services/bluetooth/bluetooth_ble_service.dart';
import '../../services/bluetooth/bluetooth_classic_service.dart';
import '../../services/communication_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/constants.dart';
import '../../utils/network_utils.dart';

class CustomerScreenControllerViewModel extends ChangeNotifier {
  final Repository repository;
  final BuildContext context;
  final MqttService mqttService = MqttService();

  final BluetoothClassicService bluetoothClassicService = BluetoothClassicService();
  final BluetoothBleService bluetoothBleService = BluetoothBleService();

  late MqttPayloadProvider mqttProvider;
  StreamSubscription<MqttConnectionState>? mqttSubscription;

  bool _disposed = false;
  bool isLoading = false;
  bool programRunning = false;
  bool isChanged = true;
  bool _isConnecting = false;
  bool isNotCommunicate = false;

  int selectedIndex = 0;
  int unreadAlarmCount = 2;
  int sIndex = 0, mIndex = 0, lIndex = 0;
  int wifiStrength = 0;
  int powerSupply = 0;
  int reconnectAttempts = 0;

  String errorMsg = '';
  String fromWhere = '';
  String myCurrentSite = '';
  String myCurrentIrrLine = 'No Line Available';

  List<String> alarmDL = [];
  List<String> lineLiveMessage = [];
  List<String> pairedDevices = ['Device A', 'Device B', 'Device C'];

  late SiteModel mySiteList = SiteModel(data: []);

  bool onRefresh = false;
  bool mqttInitialized = false;

  CustomerScreenControllerViewModel(
      this.context,
      this.repository,
      this.mqttProvider,
      ) {
    fromWhere = 'init';
    _init();
  }

  // ---------------------- INIT FLOW ------------------------
  void _init() {

    mqttProvider.addListener(_onPayloadReceived);

    NetworkUtils.connectionStream.listen((connected) {
      if (_disposed) return;
      if (connected) {
        if (mqttService.isConnected) return;
        if (mqttInitialized) {
          restartMqttSession();
          return;
        }
        _initializeMqttConnection();
      }
    });

  }

  // ---------------------- MQTT HANDLING ------------------------

  void _initializeMqttConnection() {
    if (mqttInitialized) {
      debugPrint("🔵 MQTT already initialized, skipping...");
      return;
    }

    if (mySiteList.data.isEmpty) {
      debugPrint("MQTT init deferred: mySiteList empty");
      return;
    }
    final master = mySiteList.data[sIndex].master;
    if (master.isEmpty) {
      debugPrint("MQTT init deferred: master list empty");
      return;
    }

    mqttInitialized = true;
    debugPrint("🚀 Initializing MQTT...");

    mqttService.initializeMQTTClient(state: mqttProvider);
    mqttService.connect();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      bluetoothClassicService.initializeClassicService(state: mqttProvider);
      bluetoothBleService.initializeBleService(state: mqttProvider);
    }

    mqttSubscription?.cancel();
    mqttSubscription = mqttService.mqttConnectionStream.listen(_handleMqttState);
  }

  void _handleMqttState(MqttConnectionState state) {
    switch (state) {
      case MqttConnectionState.connected:
        Future.delayed(const Duration(seconds: 1), _subscribeToDeviceTopic);
        break;

      case MqttConnectionState.connecting:
        break;

      case MqttConnectionState.disconnected:
      default:
        _handleMqttReconnection();
    }
  }

  void _handleMqttReconnection() {
    if (_isConnecting || mqttService.isConnected) return;

    debugPrint("🔄 Trying to reconnect MQTT...");

    _isConnecting = true;

    final delay = Duration(seconds: 2 * (1 << reconnectAttempts).clamp(1, 32));

    Future.delayed(delay, () async {
      try {
        await mqttService.connect();
        reconnectAttempts = 0;
      } catch (_) {
        reconnectAttempts++;
      } finally {
        _isConnecting = false;
      }
    });
  }

  Future<void> _subscribeToDeviceTopic() async {
    if (mqttService.mqttConnectionState != MqttConnectionState.connected) {
      debugPrint("MQTT not yet connected.");
      return;
    }

    if (mySiteList.data.isEmpty) {
      debugPrint('Site data still loading...');
      return;
    }

    final deviceId = mySiteList.data[sIndex].master[mIndex].deviceId;
    if (deviceId.isEmpty) {
      debugPrint("Device ID missing");
      return;
    }

    final topic = '${AppConstants.subscribeTopic}/$deviceId';

    try {
      await mqttService.topicToSubscribe(topic);

      if (mqttService.isConnected) {
        Future.delayed(
          const Duration(seconds: 1),
              () => onRefreshClicked(),
        );
      }

    } catch (e) {
      debugPrint("MQTT Subscribe failed: $e");
    }
  }

  // ---------------------- PAYLOAD HANDLING ------------------------

  void _onPayloadReceived() {
    if (_disposed) return;

    final activeDeviceId = mqttProvider.activeDeviceId;
    if (mySiteList.data.isEmpty) return;

    final master = mySiteList.data[sIndex].master[mIndex];
    if (activeDeviceId != master.deviceId) return;

    lineLiveMessage = mqttProvider.lineLiveMessage;
    powerSupply = mqttProvider.powerSupply;
    alarmDL = mqttProvider.alarmDL;
    wifiStrength = mqttProvider.wifiStrength;

    isNotCommunicate = _isDeviceNotCommunicating(mqttProvider.liveDateAndTime);

    final isGem = [
      ...AppConstants.gemModelList,
      ...AppConstants.ecoGemModelList
    ].contains(master.modelId);

    if (isGem) {
      final decoded = jsonDecode(mqttProvider.receivedPayload);
      master.live = LiveMessage.fromJson(decoded);
    }

    updateLivePayload(
      wifiStrength,
      mqttProvider.liveDateAndTime,
      mqttProvider.currentSchedule,
      lineLiveMessage,
    );
  }

  bool _isDeviceNotCommunicating(String lastSyncTimeString) {
    try {
      final lastSync = DateTime.parse(lastSyncTimeString);
      return DateTime.now().difference(lastSync).inMinutes > 10;
    } catch (_) {
      return true;
    }
  }

  void updateLivePayload(
      int ws,
      String liveDateAndTime,
      List<String> cProgram,
      List<String> linePauseResume,
      ) {
    final master = mySiteList.data[sIndex].master[mIndex];

    final parts = liveDateAndTime.split(' ');
    if (parts.length == 2) {
      master.live?.cD = parts[0];
      master.live?.cT = parts[1];
    }

    wifiStrength = ws;
    programRunning = cProgram.isNotEmpty && cProgram[0].isNotEmpty;
    if (programRunning) mqttProvider.currentSchedule = cProgram;

    for (final entry in linePauseResume) {
      final parts = entry.split(',');
      if (parts.length == 2) {
        final serialNo = double.tryParse(parts[0]);
        final flag = int.tryParse(parts[1]);
        if (serialNo != null && flag != null) {
          for (var line in master.irrigationLine) {
            if (line.sNo == serialNo) {
              line.linePauseFlag = flag;
              break;
            }
          }
        }
      }
    }

    notifyListeners();
  }


  Future<void> getAllMySites(BuildContext context, int customerId,
      {bool preserveSelection = false}) async {
    setLoading(true);
    try {
      final response = await repository.fetchAllMySite({"userId": customerId});
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        debugPrint('My Site Data:${response.body}');

        if (jsonData["code"] == 200) {
          _handleFetchedSites(jsonData, 'customer', preserveSelection);
        } else {
          final sharedResponse =
          await repository.fetchSharedUserSite({"userId": customerId});
          if (sharedResponse.statusCode == 200) {
            final jsonShared = jsonDecode(sharedResponse.body);

            debugPrint('My Site Data Subuser:${sharedResponse.body}');

            if (jsonShared["code"] == 200) {
              _handleFetchedSites(jsonShared, 'subUser', preserveSelection);
            }
          }
        }
      }
    } catch (error) {
      errorMsg = 'Error fetching site list: $error';
      debugPrint(errorMsg);
    } finally {
      setLoading(false);
      if (!_disposed && !mqttInitialized && mySiteList.data.isNotEmpty) {
        _initializeMqttConnection();
      }
    }
  }

  void _handleFetchedSites(Map<String, dynamic> jsonData,
      String type, bool preserveSelection) {
    final newSiteList = SiteModel.fromJson(jsonData, type);

    if (preserveSelection && mySiteList.data.isNotEmpty) {
      mySiteList.data[sIndex].master[mIndex] =
      newSiteList.data[sIndex].master[mIndex];
    } else {
      mySiteList = newSiteList;
      updateSite(sIndex, mIndex, lIndex);
    }

    final master = mySiteList.data[sIndex].master[mIndex];
    mqttProvider.saveUnits(Unit.toJsonList(master.units));

    final live = master.live;
    mqttProvider.updateReceivedPayload(
      live != null ? jsonEncode(live) : _defaultPayload(),
      true,
    );

    wifiStrength = live?.cM['WifiStrength'] ?? 0;
  }

  String _defaultPayload() => '''
  {
    "cC": "00000000",
    "cM": {
      "WifiStrength": 0, "PowerSupply": 0
    },
    "cD": "0000-00-00",
    "cT": "00:00:00",
    "mC": "2400"
  }''';

  // ---------------------- UI ACTIONS ------------------------

  void setLoading(bool value) {
    isLoading = value;
    if (!_disposed) notifyListeners();
  }

  Future<void> siteOnChanged(String siteName) async {
    final index = mySiteList.data.indexWhere((site) => site.groupName == siteName);
    if (index != -1) {
      sIndex = index;
      mIndex = 0;
      lIndex = 0;
      fromWhere = 'site';
      updateSite(index, 0, 0);
    }
    await _notifyChangeDelay();
  }

  Future<void> masterOnChanged(int index) async {
    mIndex = index;
    lIndex = 0;
    fromWhere = 'master';
    updateMaster(sIndex, index, lIndex);
    await _notifyChangeDelay();
  }

  void lineOnChanged(int index) {
    if (mySiteList.data[sIndex].master[mIndex].irrigationLine.length > 1) {
      lIndex = index;
      fromWhere = 'line';
      updateMasterLine(sIndex, mIndex, index);
    }
  }

  void updateSite(int sIdx, int mIdx, int lIdx) {
    myCurrentSite = mySiteList.data[sIdx].groupName;
    updateMaster(sIdx, mIdx, lIdx);
  }

  void updateMaster(int sIdx, int mIdx, int lIdx) {

    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final master = mySiteList.data[sIdx].master[mIdx];

    customerProvider.updateControllerInfo(
      controllerId: master.controllerId,
      device: master.deviceId,
      customerId: mySiteList.data[sIdx].customerId,
      commMode:  master.communicationMode!,
    );

    if ([...AppConstants.gemModelList, ...AppConstants.ecoGemModelList,
      ...AppConstants.omsGemList].contains(master.modelId)) {
      updateMasterLine(sIdx, mIdx, lIdx);
      mqttProvider.saveUnits(Unit.toJsonList(master.units));
      mqttProvider.updateReceivedPayload(
        master.live != null ? jsonEncode(master.live) : _defaultPayload(),
        true,
      );
    }

    _subscribeToDeviceTopic();
    notifyListeners();
  }

  void updateMasterLine(int sIdx, int mIdx, int lIdx) {
    final master = mySiteList.data[sIdx].master[mIdx];
    if (master.irrigationLine.isNotEmpty) {
      myCurrentIrrLine = master.irrigationLine[lIdx].name;
      notifyListeners();
    }
  }

  Future<void> _notifyChangeDelay() async {
    isChanged = false;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    isChanged = true;
    notifyListeners();
  }

  // ---------------------- REFRESH & COMMANDS ------------------------

  Future<void> onRefreshClicked() async {
    if (!mqttService.isConnected) {
      debugPrint("MQTT not connected — attempting to connect and abort refresh to avoid publish while connecting.");
      _initializeMqttConnection();
      return;
    }

    final master = mySiteList.data[sIndex].master[mIndex];
    final isGem = [...AppConstants.gemModelList, ...AppConstants.ecoGemModelList].contains(master.modelId);
    final isOMSGem = [...AppConstants.omsGemList].contains(master.modelId);

    final payload = isGem
        ? jsonEncode({"3000": {"3001": ""}})
        : isOMSGem ? jsonEncode({"3000": {"3001": "1"}})
        : jsonEncode({"sentSms": "#live"});

    liveSyncCall(true);

    try {
      final result = await context.read<CommunicationService>().sendCommand(
        serverMsg: '',
        payload: payload,
      );
      debugPrint("MQTT publishing result:$result");
    } catch (e) {
      debugPrint("Command error: $e");
    } finally {
      await Future.delayed(const Duration(seconds: 1));
      liveSyncCall(false);
    }
  }

  Future<void> onFertilizerLiveSync() async {
    if (!mqttService.isConnected) {
      debugPrint("MQTT not connected — attempting to connect and abort refresh to avoid publish while connecting.");
      _initializeMqttConnection();
      return;
    }

    final master = mySiteList.data[sIndex].master[mIndex];
    final isGem = [...AppConstants.gemModelList, ...AppConstants.ecoGemModelList]
        .contains(master.modelId);

    final payload = isGem
        ? jsonEncode({"3000": {"3001": "0"}})
        : jsonEncode({"sentSms": "#live"});

    liveSyncCall(true);

    try {
      final result = await context.read<CommunicationService>().sendCommand(
        serverMsg: '',
        payload: payload,
      );
      debugPrint("MQTT publishing result:$result");
    } catch (e) {
      debugPrint("Command error: $e");
    } finally {
      await Future.delayed(const Duration(seconds: 1));
      liveSyncCall(false);
    }
  }

  Future<void> restartMqttSession() async {
    debugPrint("🔄 Restarting MQTT Session...");

    try {
      mqttSubscription?.cancel();
      try { mqttProvider.removeListener(_onPayloadReceived); } catch (_) {}

      await mqttService.disConnect();
    } catch (e) {
      debugPrint("Error while stopping old MQTT session: $e");
    }

    await Future.delayed(const Duration(milliseconds: 300));

    mqttSubscription = null;
    mqttInitialized = false;
    _isConnecting = false;
    reconnectAttempts = 0;

    _initializeMqttConnection();

    try {
      mqttProvider.removeListener(_onPayloadReceived);
    } catch (_) {}
    mqttProvider.addListener(_onPayloadReceived);
  }

  void liveSyncCall(status){
    if (_disposed) return;
    onRefresh = status;
    notifyListeners();
  }

  Future<void> linePauseOrResume(List<String> lineLiveMsg) async {
    final allPaused = lineLiveMsg.every((line) => line.split(',')[1] == '1');
    final payloadString = '${lineLiveMsg
        .map((msg) {
      final parts = msg.split(',');
      return '${parts[0]},${allPaused ? '0' : '1'}';
    }).join(';')};';

    final payload = jsonEncode({"4900": {"4901": payloadString}});
    await context.read<CommunicationService>().sendCommand(
      serverMsg: allPaused ? 'Resumed all line' : 'Paused all line',
      payload: payload,
    );
  }

  // ---------------------- MISC ------------------------

  void onItemTapped(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  Future<void> updateCommunicationMode(int communicationMode, int customerId) async {
    try {
      final body = {
        "userId": customerId,
        "controllerId": mySiteList.data[sIndex].master[mIndex].controllerId,
        "communicationMode": communicationMode,
        "modifyUser": customerId,
      };
      final response = await repository.updateControllerCommunicationMode(body);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
          customerProvider.updateControllerCommunicationMode(
              cmmMode: communicationMode);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    mqttProvider.removeListener(_onPayloadReceived);
    mqttSubscription?.cancel();
    mqttService.disConnect();
    super.dispose();
  }
}