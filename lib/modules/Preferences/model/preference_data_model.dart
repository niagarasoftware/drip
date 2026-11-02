import '../../../utils/constants.dart';

class GeneralData {
  String deviceId;
  String controllerReadStatus;
  int controllerId;
  int categoryId;

  GeneralData({
    required this.controllerReadStatus,
    required this.deviceId,
    required this.controllerId,
    required this.categoryId,
  });

  factory GeneralData.fromJson(Map<String, dynamic> json) {
    return GeneralData(
      controllerReadStatus: json['controllerReadStatus'] ?? '0',
      deviceId: json['deviceId'] ?? "0",
      controllerId: json['controllerId'] ?? 0,
      categoryId: json['categoryId'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      // 'loraKey': loraKey,
      // 'loraFrequency': loraFrequency,
      // 'spreadFactor': spreadFactor,
    };
  }
}

class RtcTimeSetting {
  int rtc;
  String onTime;
  String offTime;

  RtcTimeSetting({
    required this.rtc,
    required this.onTime,
    required this.offTime,
  });

  factory RtcTimeSetting.fromJson(Map<String, dynamic> json) {
    return RtcTimeSetting(
      rtc: json['rtc'] ?? 0,
      onTime: json['onTime'] == "" ? "00:00:00" : json['onTime'],
      offTime: json['offTime'] == "" ? "00:00:00" : json['offTime'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'rtc': rtc,
      'onTime': onTime,
      'offTime': offTime,
    };
  }
}

class WidgetSetting {
  String title;
  int serialNumber;
  int widgetTypeId;
  String iconCodePoint;
  String iconFontFamily;
  dynamic value;
  List<RtcTimeSetting>? rtcSettings;
  bool hidden;
  bool display;
  int payloadIndex;
  bool isChanged;

  WidgetSetting({
    required this.title,
    required this.widgetTypeId,
    required this.iconCodePoint,
    required this.iconFontFamily,
    this.value,
    this.rtcSettings,
    required this.hidden,
    required this.display,
    required this.payloadIndex,
    required this.isChanged,
    required this.serialNumber
  });

  factory WidgetSetting.fromJson(Map<String, dynamic> json, bool isNova, bool isAquaCulture, bool singlePhase) {
    final rtcData = json['value'];
    List<RtcTimeSetting>? rtcSettings;
    if (rtcData is List<dynamic> && json['title'].toString().toUpperCase() == "RTC TIMER") {
      rtcSettings = rtcData.map((rtcItem) {
        return RtcTimeSetting.fromJson(rtcItem);
      }).toList();
    }

    dynamic value;
    if (json['title'].toString().toUpperCase() == "2 PHASE"
        || json['title'].toString().toUpperCase() == "AUTO RESTART 2 PHASE"
        || (json['title'].toString().toUpperCase() == "AUTO RESTART" && json['sNo'] == 8)
        || (isNova && (
            json['title'].toString().toUpperCase() == "UPPER TANK LINEAR LEVEL SENSOR" ||
                json['title'].toString().toUpperCase() == "LOWER TANK LINEAR LEVEL SENSOR"
        ))
    )  {
      int noOfPumpLimit = isAquaCulture ? 4 : 3;
      value = json['value'] is bool ? List<bool>.filled(noOfPumpLimit, singlePhase ? true : false) : json['value'];
    } else {
      switch (json['widgetTypeId']) {
        case 1:
          value = json['value'] is String ? json['value'] : '0';
          break;
        case 2:
          value = json['value'] is bool ? json['value'] : false;
          break;
        case 3:
          value = (json['value'] is String && json['value'].isNotEmpty) ? json['value'] : '00:00:00';
          break;
        default:
          value = json['value'];
      }
    }

    return WidgetSetting(
      title: json['title'],
      serialNumber: json['sNo'] ?? 0,
      widgetTypeId: json['widgetTypeId'],
      iconCodePoint: json['iconCodePoint'],
      iconFontFamily: json['iconFontFamily'],
      value: value,
      rtcSettings: rtcSettings,
      hidden: json['hidden'],
      display: json['display'] ?? true,
      payloadIndex: json['payloadIndex'] ?? json['sNo'] ?? 0,
      isChanged: false,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'sNo': serialNumber,
      'hidden': hidden,
      'value': value,
    };

    if (title.toUpperCase() == 'RTC TIMER') {
      json['value'] = (rtcSettings?.map((item) => item.toJson()).toList())!;
    } else {
      json['value'] = value;
    }

    return json;
  }
}

class SettingList {
  int type;
  String name;
  bool changed;
  String controllerReadStatus;
  List<WidgetSetting> setting;

  SettingList({
    required this.type,
    required this.changed,
    required this.controllerReadStatus,
    required this.name,
    required this.setting,
  });

  factory SettingList.fromJson(Map<String, dynamic> json, {bool isNova = false, bool isAquaCulture = false, bool singlePhase = false}) {
    final settingsData = json['setting'] as List;

    final settings = settingsData.map((setting) {
      return WidgetSetting.fromJson(setting, isNova, isAquaCulture, singlePhase);
    }).toList();

    return SettingList(
      type: json['type'] is String ? int.parse(json['type']) : json['type'],
      changed: (json['changed'] ?? "0") == "1" ? true : false,
      controllerReadStatus: json['controllerReadStatus'] ?? "0",
      name: json['name'] ?? "no name",
      setting: settings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      "changed": "0",
      "controllerReadStatus": controllerReadStatus,
      "setting": setting.map((item) => item.toJson()).toList(),
    };
  }

  List gemPayload(pumpType) {
    List<String> result = [];

    if ([202, 602].contains(type)) {
      var value1 = setting.firstWhere((element) => element.serialNumber == 1).value;
      var value2 = setting.firstWhere((element) => element.serialNumber == 12).value == true ? 1 : 0;
      var value3 = setting.firstWhere((element) => element.serialNumber == 13).rtcSettings!.map((e) => e.onTime).toList().join('_');
      var value4 = setting.firstWhere((element) => element.serialNumber == 13).rtcSettings!.map((e) => e.offTime).toList().join('_');
      result.add("${value1 == "" ? "00:00:00" : value1}");
      result.add("$value2");
      result.add(value3);
      result.add(value4);
    } else if ([205, 605].contains(type)) {
      var value1 = pumpType != 2 ? (setting.firstWhere((element) => element.serialNumber == 1).value == true ? 1 : 0) : 0;
      var value2 = pumpType != 2 ? (setting.firstWhere((element) => element.serialNumber == 2).value == true ? 1 : 0) : 0;
      result.add("$value1");
      result.add("$value2");
    } else if ([207, 607].contains(type)) {
      var value1 = setting.firstWhere((element) => element.serialNumber == 1).value;
      var value2 = setting.firstWhere((element) => element.serialNumber == 2).value;
      var value3 = setting.firstWhere((element) => element.serialNumber == 3).value;
      var value4 = setting.firstWhere((element) => element.serialNumber == 4).value;
      if (value1 != null) result.add("${value1 != '' ? value1 : "0"}");
      if (value2 != null) result.add("${value2 != '' ? value2 : "0"}");
      if (value3 != null) result.add("${value3 != '' ? value3 : "0"}");
      if (value4 != null) result.add("${value4 != '' ? value4 : "0"}");
    }
    return result;
  }
}

class IndividualPumpSetting {
  double sNo;
  String name;
  int pumpType;
  int controllerId;
  dynamic deviceId;
  bool controlGem;
  int? output;
  List<SettingList> settingList;

  IndividualPumpSetting({
    required this.sNo,
    required this.name,
    required this.pumpType,
    required this.controllerId,
    required this.deviceId,
    required this.controlGem,
    required this.settingList,
    required this.output,
  });

  factory IndividualPumpSetting.fromJson(Map<String, dynamic> json) {
    final settingsDats = json['settingList'] as List<dynamic>;
    final settingsList = settingsDats.map((element) => SettingList.fromJson(element)).toList();
    return IndividualPumpSetting(
        sNo: json["sNo"],
        name: json["name"],
        pumpType: json["pumpType"],
        controllerId: json["controllerId"] ?? 0,
        deviceId: json["deviceId"],
        controlGem: json["controlGem"] ?? false,
        settingList: settingsList,
        output: json['connectionNo']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "sNo": sNo,
      "name": name,
      "type": pumpType,
      "deviceId": deviceId,
      "controlGem": controlGem,
      "settingList": settingList.map((e) => e.toJson()).toList(),
      "output": output
    };
  }

  String toGem() {
    // return '';
    return "$sNo";
  }

  String oDt() {
    var onDelayTimer = [];
    // var
    // settingList.forEach((element) {
    //   if(element.toGem() != null) {
    //     onDelayTimer.add(element.toGem());
    //   }
    // });
    for (var element in settingList) {
      onDelayTimer.addAll(element.gemPayload(pumpType));
    }
    // print(onDelayTimer);
    return onDelayTimer.join(',');
  }
}

class CommonPumpSetting {
  int controllerId;
  int categoryId;
  int modelId;
  String deviceName;
  String deviceId;
  int serialNumber;
  int referenceNumber;
  int interfaceTypeId;
  List<SettingList> settingList;

  CommonPumpSetting({
    required this.controllerId,
    required this.categoryId,
    required this.modelId,
    required this.deviceId,
    required this.deviceName,
    required this.serialNumber,
    required this.referenceNumber,
    required this.interfaceTypeId,
    required this.settingList
  });

  factory CommonPumpSetting.fromJson(Map<String, dynamic> json) {
    // print("json in the common settings ==> $json");
    final settingsDats = json['settingList'] as List<dynamic>;
    final settingsList = settingsDats.map((element) => SettingList.fromJson(
        element,
        isNova: AppConstants.ecoGemAndPlusModelList.contains(json['modelId']),
        isAquaCulture: AppConstants.aquaculturePumpModelList.contains(json['modelId']),
      singlePhase: [
        ...AppConstants.singlePhasePumpModel,
        ...AppConstants.singlePhasePumpPlusModel,
        ...AppConstants.singlePhaseShineModel,
        ...AppConstants.singlePhaseElitePlusModel,
        ...AppConstants.singlePhaseEcoGemModel,
        ...AppConstants.singlePhaseEcoGemPlusModel
      ].contains(json['modelId'])
    )).toList();
    return CommonPumpSetting(
        controllerId: json["controllerId"],
        categoryId: json["categoryId"] ?? 0,
        modelId: json["modelId"] ?? 0,
        deviceId: json["deviceId"],
        deviceName: json["deviceName"],
        serialNumber: json['serialNumber'] ?? 0,
        referenceNumber: json['referenceNumber'] ?? 0,
        interfaceTypeId: json['interfaceTypeId'] ?? 0,
        settingList: settingsList
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "controllerId": controllerId,
      "deviceId": deviceId,
      "modelId": modelId,
      "deviceName": deviceName,
      "serialNumber": serialNumber,
      "referenceNumber": referenceNumber,
      "interfaceTypeId": interfaceTypeId,
      "settingList": settingList.map((e) => e.toJson()).toList(),
    };
  }
}
