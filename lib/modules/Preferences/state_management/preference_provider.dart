import 'dart:convert';

import 'package:flutter/material.dart';

import '../model/preference_data_model.dart';
import '../../../services/http_service.dart';
import '../repository/preferences_repo.dart';

const actionForGeneral = "getUserPreferenceGeneral";
const actionForNotification = "getUserPreferenceNotification";
const actionForSetting = "getUserPreferenceSetting";
const actionForUserPassword = "checkUserUsingUserIdAndPassword";
const actionForCalibration = "getUserPreferenceCalibration";

class PreferenceProvider extends ChangeNotifier {
  final PreferenceRepository repository = PreferenceRepository(HttpService());


  bool notReceivingAck = false;
  bool sending = false;

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  void updateTabIndex(int newIndex) {
    _selectedTabIndex = newIndex;
    Future.delayed(Duration.zero, () {
      notifyListeners();
    });
  }

  GeneralData? generalData;
  GeneralData? get generalDataResult => generalData;

  List<IndividualPumpSetting>? individualPumpSetting;
  List<IndividualPumpSetting>? get individualPumpSettingData => individualPumpSetting;

  List<CommonPumpSetting>? commonPumpSettings;
  List<CommonPumpSetting>? get commonPumpSettingsData => commonPumpSettings;

  List<CommonPumpSetting>? calibrationSetting;
  List<CommonPumpSetting>? get calibrationSettingsData => calibrationSetting;

  List<SettingList>? defaultSetting;
  List<SettingList>? get defaultSettingData => defaultSetting;

  List<SettingList>? defaultCalibration;
  List<SettingList>? get defaultCalibrationData => defaultCalibration;

  SettingList? _standaloneSettings;
  SettingList? get standaloneSettings => _standaloneSettings;

  SettingList? _programSettings;
  SettingList? get programSettings => _programSettings;

  SettingList? _moistureSettings;
  SettingList? get moistureSettings => _moistureSettings;

  int passwordValidationCode = 0;

  void updateValidationCode() {
    passwordValidationCode = 0;
    notifyListeners();
  }

  String _mode = "Duration";

  String get mode => _mode;

  Future<void> getUserPreference({
    required int userId,
    required int controllerId,
    required int modelId,
  }) async {
    final userData = {
      "userId": userId,
      "controllerId": controllerId,
      "modelId": modelId,
    };

    try {
      final response = await repository.getUserPreferenceGeneral(userData);
      if(response.statusCode == 200) {
        final result = jsonDecode(response.body);
        generalData = GeneralData.fromJson(result['data'][0]);
      }
    } catch(error) {
      // print("Error parsing general data: $error");
      // print("Stack trace general data: $stackTrace");
    }
    try {
      final response = await repository.getUserPreferenceSetting(userData);
      if(response.statusCode == 200) {
        final result = jsonDecode(response.body);
        individualPumpSetting = List.from(result['data']['individualPumpSetting'].map((json) => IndividualPumpSetting.fromJson(json)));
        commonPumpSettings = List.from(result['data']['commonPumpSetting'].map((json) => CommonPumpSetting.fromJson(json)));
      }
    } catch(error) {
      // print("Error parsing setting data: $error");
      // print("Stack trace setting data: $stackTrace");
    }
    try {
      final response = await repository.getUserPreferenceCalibration(userData);
      if(response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print("result in the calibration :: $result");
        calibrationSetting = List.from(result['data'].map((json) => CommonPumpSetting.fromJson(json)));
      }
    } catch(error, stackTrace) {
      debugPrint("Error parsing setting data: $error");
      debugPrint("Stack trace setting data: $stackTrace");
    }
    notifyListeners();
  }

  Future<void> getStandAloneSettings({
    required int userId,
    required int controllerId,
    required int selectedIndex
  }) async {

    final userData = {
      "userId": userId,
      "controllerId": controllerId
    };

    try {
      final standAloneResponse = await repository.getUserPreferenceValveStandaloneSetting(userData);
      if(standAloneResponse.statusCode == 200) {
        // final result = standAloneSettingsSample;
        final result = jsonDecode(standAloneResponse.body);
        _standaloneSettings = SettingList.fromJson(Map<String, dynamic>.from(result['data']));
      }
      final response = await repository.getUserPreferenceValveSetting(userData);
      if(response.statusCode == 200) {
        // final result = programSettings;
        final result = jsonDecode(response.body);
        _programSettings = SettingList.fromJson(Map<String, dynamic>.from(result['data']['valveSetting']));
        _moistureSettings = SettingList.fromJson(Map<String, dynamic>.from(result['data']['moistureSetting']));
      }
      notifyListeners();

    } catch(error) {
      // print("Error parsing setting data: $error");
      // print("Stack trace setting data: $stackTrace");
    }
  }

  void getMode() {
    if(_standaloneSettings!.setting[4].value) {
      _mode = "Manual";
    } else {
      _mode = "Duration";
    }
    notifyListeners();
  }

  Future<void> checkPassword({required int userId, required String password}) async{
    try {
      final userData = {
        'userId': userId,
        "passkey": password
      };
      final response = await repository.checkPassword(userData);
      final result = jsonDecode(response.body);
      passwordValidationCode = result['code'];
    } catch(error) {
      // print("Error parsing setting data: $error");
      // print("Stack trace setting data: $stackTrace");
    }
    notifyListeners();
  }

  var temp = [];

  void updateControllerReaStatus({required String key, required int oroPumpIndex, required bool failed}) {
    if(key.contains("100")) {
      commonPumpSettings![oroPumpIndex].settingList[0].controllerReadStatus = "1";
      individualPumpSetting![oroPumpIndex].settingList[0].changed = false;
    }
    if(key.contains("200")) {
      commonPumpSettings![oroPumpIndex].settingList[1].controllerReadStatus = "1";
      individualPumpSetting![oroPumpIndex].settingList[1].changed = false;
    }
    int pumpIndex = 0;
    for (var individualPump in individualPumpSetting ?? []) {
      if (commonPumpSettings![oroPumpIndex].deviceId == individualPump.deviceId) {
        if(individualPump.output != null) {
          pumpIndex = individualPump.output;
        } else {
          pumpIndex++;
        }
        for (var individualPumpSetting in individualPump.settingList) {
          switch (individualPumpSetting.type) {
            case 203:
              if(key.contains("400-$pumpIndex")) {
                individualPumpSetting.controllerReadStatus= "1";
                individualPumpSetting.changed = false;
                // print("$key acknowledged");
              }
              break;
            case 202:
              temp.add(key);
              // print("temp variable ==> ${temp.toSet()}");
              if(temp.toSet().contains("300-$pumpIndex") && temp.toSet().contains("500-$pumpIndex")) {
                individualPumpSetting.controllerReadStatus = "1";
                individualPumpSetting.changed = false;
                // print("$key acknowledged");
              }
              break;
            case 205:
            if(key.contains("600-$pumpIndex")) {
                individualPumpSetting.controllerReadStatus = "1";
                individualPumpSetting.changed = false;
                // print("$key acknowledged");
              } {}
              break;
          }
        }
      }
    }
    if(passwordValidationCode == 200 && calibrationSetting!.isNotEmpty) {
      if(key.contains("900")) {
        calibrationSetting![oroPumpIndex].settingList[1].controllerReadStatus = "1";
        calibrationSetting![oroPumpIndex].settingList[0].changed = false;
      }
    }
    notifyListeners();
  }

  void clearData() {
    notReceivingAck = false;
    sending = false;
    _selectedTabIndex = 0;
    generalData = null;
    individualPumpSetting = null;
    commonPumpSettings = null;
    calibrationSetting = null;
    passwordValidationCode = 0;
  }

  void updateMode(String newMode) {
    _mode = newMode;
    notifyListeners();
  }
  void updateSettingValue(String title, String newValue) {
    final setting = standaloneSettings?.setting.firstWhere((e) => e.title == title);
    if (setting != null) {
      if (setting.value.toString().contains(',')) {
        final parts = setting.value.split(',');
        setting.value = '$newValue,${parts[1]}';
        setting.isChanged = true;
      } else {
        setting.value = newValue;
        setting.isChanged = true;
      }
      notifyListeners();
    }
  }

  void updateMoistureSettingValue(String title, String newValue, bool part1) {
    final setting = moistureSettings?.setting.firstWhere((e) => e.title == title);
    if (setting != null) {
      if(part1) {
        if (setting.value.toString().contains(',')) {
          if(part1) {
            setting.value = '$newValue,${setting.value.split(',')[1]}';
            setting.isChanged = true;
          } else {
            setting.value = '${setting.value.split(',')[0]},$newValue';
            setting.isChanged = true;
          }
          final parts = setting.value.split(',');
          setting.value = '$newValue,${parts[1]}';
          setting.isChanged = true;
        }
      }
      notifyListeners();
    }
  }

  void updateSwitchValue(String title, bool newValue) {
    final setting = standaloneSettings?.setting.firstWhere((e) => e.title == title);
    if (setting != null) {
      if (setting.value.toString().contains(',')) {
        final parts = setting.value.split(',');
        setting.value = '${parts[0]},${newValue ? "1" : "0"}';
        setting.isChanged = true;
      } else {
        setting.value = newValue;
        setting.isChanged = true;

       /* if(setting.serialNumber == 5) {
          if(setting.value) {
            _mode = "Manual";
          } else {
            _mode = "Duration";
          }
        }*/
      }
      notifyListeners();
    }
  }

  void updateMoistureSwitchValue(String title, bool newValue) {
    final setting = moistureSettings?.setting.firstWhere((e) => e.title == title);
    if (setting != null) {
      setting.value = newValue;
      setting.isChanged = true;
      notifyListeners();
    }
  }

  String getDuration(String value) {
    return value.toString().contains(',') ? value.split(',')[0] : value;
  }

   bool getSwitchState(String value) {
    return value.toString().contains(',') ? value.split(',')[1] == '1' : value == 'true';
  }

  void updateRadioValue(String title, int value) {
    final item = _moistureSettings!.setting.firstWhere((e) => e.title == title);
    item.value = value;
    notifyListeners();
  }

}