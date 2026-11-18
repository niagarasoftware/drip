import 'package:flutter/cupertino.dart';

class CustomerProvider with ChangeNotifier {
  int? _customerId;
  int? _controllerId;
  String? _deviceId;
  int? _communicationMode;

  int? get customerId => _customerId;
  int? get controllerId => _controllerId;
  String? get deviceId => _deviceId;
  int? get controllerCommMode => _communicationMode;


  void updateControllerInfo({required int controllerId, required String device,
    required int customerId, required int commMode}) {
    _controllerId = controllerId;
    _deviceId = device;
    _customerId = customerId;
    _communicationMode = commMode;
    notifyListeners();
  }

  void updateControllerCommunicationMode({required int cmmMode}) {
    _communicationMode = cmmMode;
    notifyListeners();
  }

  void clear() {
    _customerId = null;
    _controllerId = null;
    _deviceId = null;
    _communicationMode = null;
    notifyListeners();
  }
}