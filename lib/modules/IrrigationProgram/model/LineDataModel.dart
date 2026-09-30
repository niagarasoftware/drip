import 'package:flutter/foundation.dart';

import '../../config_maker/model/device_object_model.dart';

class ProgramFilterSite {
  final DeviceObjectModel? filterSite;
  final int? siteMode;
  final List<DeviceObjectModel>? filters;
  final DeviceObjectModel? pressureIn;
  final DeviceObjectModel? pressureOut;
  final DeviceObjectModel? backWashValve;

  ProgramFilterSite({
    required this.filterSite,
    required this.siteMode,
    required this.filters,
    required this.pressureIn,
    required this.pressureOut,
    required this.backWashValve,
  });

  factory ProgramFilterSite.fromJson(Map<String, dynamic> json) {
    return ProgramFilterSite(
      filterSite: (json.isNotEmpty) ? DeviceObjectModel.fromJson(Map<String, dynamic>.from(json)) : null,
      siteMode: json['siteMode'] as int?,
      filters: (json['filters'] as List?)?.where((e) => (e != null && e.isNotEmpty)).map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      pressureIn: (json['pressureIn'] != null && json['pressureIn'].isNotEmpty) ? DeviceObjectModel.fromJson(Map<String, dynamic>.from(json['pressureIn'])) : null,
      pressureOut: (json['pressureOut'] != null && json['pressureOut'].isNotEmpty) ? DeviceObjectModel.fromJson(Map<String, dynamic>.from(json['pressureOut'])) : null,
      backWashValve: (json['backWashValve'] != null && json['backWashValve'].isNotEmpty) ? DeviceObjectModel.fromJson(Map<String, dynamic>.from(json['backWashValve'])) : null,
    );
  }
}

class ProgramFertilizerSite {
  final DeviceObjectModel? fertilizerSite;
  final int? siteMode;
  final List<DeviceObjectModel>? channel;
  final List<DeviceObjectModel>? boosterPump;
  final List<DeviceObjectModel>? agitator;
  final List<DeviceObjectModel>? selector;
  final List<DeviceObjectModel>? ec;
  final List<DeviceObjectModel>? ph;

  ProgramFertilizerSite({
    required this.fertilizerSite,
    required this.siteMode,
    required this.channel,
    required this.boosterPump,
    required this.agitator,
    required this.selector,
    required this.ec,
    required this.ph,
  });

  factory ProgramFertilizerSite.fromJson(Map<String, dynamic> json) {
    return ProgramFertilizerSite(
      fertilizerSite: DeviceObjectModel.fromJson(json),
      siteMode: json['siteMode'],
      channel: (json['channel'] as List?)?.where((e) => (e != null && e.isNotEmpty)).map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      boosterPump: (json['boosterPump'] as List?)?.where((e) => (e != null && e.isNotEmpty)).map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      agitator: (json['agitator'] as List?)?.where((e) => (e != null && e.isNotEmpty)).map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      selector: (json['selector'] as List?)?.where((e) => (e != null && e.isNotEmpty)).map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      ec: (json['ec'] as List?)?.where((e) => (e != null && e.isNotEmpty)).map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      ph: (json['ph'] as List?)?.where((e) => (e != null && e.isNotEmpty)).map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fertilizerSite': fertilizerSite?.toJson(),
      'siteMode': siteMode,
      'channel': channel?.map((e) => e.toJson()).toList(),
      'boosterPump': boosterPump?.map((e) => e.toJson()).toList(),
      'agitator': agitator?.map((e) => e.toJson()).toList(),
      'selector': selector?.map((e) => e.toJson()).toList(),
      'ec': ec?.map((e) => e.toJson()).toList(),
      'ph': ph?.map((e) => e.toJson()).toList(),
    };
  }
}

class ProgramWaterSource {
  final DeviceObjectModel? waterSource;
  final DeviceObjectModel? sourceType;
  final DeviceObjectModel? level;
  final DeviceObjectModel? topFloat;
  final DeviceObjectModel? bottomFloat;
  final List<DeviceObjectModel>? inletPump;
  final List<DeviceObjectModel>? outletPump;
  final List<DeviceObjectModel>? valves;

  ProgramWaterSource({
    required this.waterSource,
    required this.sourceType,
    required this.level,
    required this.topFloat,
    required this.bottomFloat,
    required this.inletPump,
    required this.outletPump,
    required this.valves,
  });

  factory ProgramWaterSource.fromJson(Map<String, dynamic> json) {
    return ProgramWaterSource(
      waterSource: DeviceObjectModel.fromJson(json),
      sourceType: (json['sourceType'] != null && json['sourceType'].isNotEmpty ) ? DeviceObjectModel.fromJson(json['sourceType']) : null,
      level: (json['level'] != null && json['level'].isNotEmpty) ? DeviceObjectModel.fromJson(json['level']) : null,
      topFloat: (json['topFloat'] != null && json['topFloat'].isNotEmpty) ? DeviceObjectModel.fromJson(json['topFloat']) : null,
      bottomFloat: (json['bottomFloat'] != null && json['bottomFloat'].isNotEmpty) ? DeviceObjectModel.fromJson(json['bottomFloat']) : null,
      inletPump: (json['inletPump'] as List?)?.where((e) => (e != null && e.isNotEmpty)).map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      outletPump: (json['outletPump'] as List?)?.where((e) => (e != null && e.isNotEmpty)).map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      valves: (json['valves'] as List?)?.where((e) => (e != null && e.isNotEmpty)).map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

class ProgramPump {
  final DeviceObjectModel? waterSource;
  final DeviceObjectModel? level;
  final DeviceObjectModel? pressureIn;
  final DeviceObjectModel? pressureOut;
  final DeviceObjectModel? waterMeter;
  final int? pumpType;

  ProgramPump({
    required this.waterSource,
    required this.level,
    required this.pressureIn,
    required this.pressureOut,
    required this.waterMeter,
    required this.pumpType,
  });

  factory ProgramPump.fromJson(Map<String, dynamic> json) {
    return ProgramPump(
      waterSource: DeviceObjectModel.fromJson(json),
      level: json['level'] != null && json['level'].isNotEmpty ? DeviceObjectModel.fromJson(json['level']) : null,
      pressureIn: json['pressureIn'].isNotEmpty ? DeviceObjectModel.fromJson(json['pressureIn']) : null,
      pressureOut: json['pressureOut'].isNotEmpty ? DeviceObjectModel.fromJson(json['pressureOut']) : null,
      waterMeter: json['waterMeter'].isNotEmpty ? DeviceObjectModel.fromJson(json['waterMeter']) : null,
      pumpType: json['pumpType'] ?? 0,
    );
  }
}

class ProgramMoistureSensor {
  final DeviceObjectModel waterSource;
  final List<DeviceObjectModel> valves;

  ProgramMoistureSensor({
    required this.waterSource,
    required this.valves,
  });

  factory ProgramMoistureSensor.fromJson(Map<String, dynamic> json) {
    return ProgramMoistureSensor(
      waterSource: DeviceObjectModel.fromJson(json),
      valves: (json['valves'] as List).map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

class FertilizerSourceTank {
  final DeviceObjectModel tank;

  FertilizerSourceTank({
    required this.tank,
  });

  factory FertilizerSourceTank.fromJson(Map<String, dynamic> json) {
    return FertilizerSourceTank(
      tank: DeviceObjectModel.fromJson(json),
    );
  }
}

class ProgramIrrigationLine with DiagnosticableTreeMixin {
  final DeviceObjectModel irrigationLine;
  final List<DeviceObjectModel>? source;
  final List<DeviceObjectModel>? sourcePump;
  final List<DeviceObjectModel>? irrigationPump;
  final List<DeviceObjectModel>? aerator;
  final DeviceObjectModel? centralFiltration;
  final DeviceObjectModel? localFiltration;
  final DeviceObjectModel? centralFertilization;
  final DeviceObjectModel? localFertilization;
  final List<DeviceObjectModel>? valve;
  final List<DeviceObjectModel>? mainValve;
  final List<DeviceObjectModel>? fan;
  final List<DeviceObjectModel>? fogger;
  final List<DeviceObjectModel>? pesticides;
  final List<DeviceObjectModel>? heater;
  final List<DeviceObjectModel>? screen;
  final List<DeviceObjectModel>? vent;
  final DeviceObjectModel? powerSupply;
  final DeviceObjectModel? pressureSwitch;
  final DeviceObjectModel? waterMeter;
  final DeviceObjectModel? pressureIn;
  final DeviceObjectModel? pressureOut;
  final List<DeviceObjectModel>? moisture;
  final List<DeviceObjectModel>? temperature;
  final List<DeviceObjectModel>? soilTemperature;
  final List<DeviceObjectModel>? humidity;
  final List<DeviceObjectModel>? co2;
  final List<DeviceObjectModel>? light;

  ProgramIrrigationLine({
    required this.irrigationLine,
    this.source,
    this.sourcePump,
    this.irrigationPump,
    this.aerator,
    this.centralFiltration,
    this.localFiltration,
    this.centralFertilization,
    this.localFertilization,
    this.valve,
    this.mainValve,
    this.fan,
    this.fogger,
    this.pesticides,
    this.heater,
    this.screen,
    this.vent,
    this.powerSupply,
    this.pressureSwitch,
    this.waterMeter,
    this.pressureIn,
    this.pressureOut,
    this.moisture,
    this.temperature,
    this.soilTemperature,
    this.humidity,
    this.co2,
    this.light,
  });

/*  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<DeviceObjectModel>('irrigationLine', irrigationLine));
    properties.add(IterableProperty<DeviceObjectModel>('source', source));
    properties.add(IterableProperty<DeviceObjectModel>('sourcePump', sourcePump));
    properties.add(IterableProperty<DeviceObjectModel>('irrigationPump', irrigationPump));
    properties.add(DiagnosticsProperty<DeviceObjectModel?>('centralFiltration', centralFiltration));
    properties.add(DiagnosticsProperty<DeviceObjectModel?>('localFiltration', localFiltration));
    properties.add(DiagnosticsProperty<DeviceObjectModel?>('centralFertilization', centralFertilization));
    properties.add(DiagnosticsProperty<DeviceObjectModel?>('localFertilization', localFertilization));
    properties.add(IterableProperty<DeviceObjectModel>('valve', valve));
    properties.add(IterableProperty<DeviceObjectModel>('mainValve', mainValve));
    properties.add(IterableProperty<DeviceObjectModel>('fan', fan));
    properties.add(IterableProperty<DeviceObjectModel>('fogger', fogger));
    properties.add(IterableProperty<DeviceObjectModel>('pesticides', pesticides));
    properties.add(IterableProperty<DeviceObjectModel>('heater', heater));
    properties.add(IterableProperty<DeviceObjectModel>('screen', screen));
    properties.add(IterableProperty<DeviceObjectModel>('vent', vent));
    properties.add(DiagnosticsProperty<DeviceObjectModel?>('powerSupply', powerSupply));
    properties.add(DiagnosticsProperty<DeviceObjectModel?>('pressureSwitch', pressureSwitch));
    properties.add(DiagnosticsProperty<DeviceObjectModel?>('waterMeter', waterMeter));
    properties.add(DiagnosticsProperty<DeviceObjectModel?>('pressureIn', pressureIn));
    properties.add(DiagnosticsProperty<DeviceObjectModel?>('pressureOut', pressureOut));
    properties.add(IterableProperty<DeviceObjectModel>('moisture', moisture));
    properties.add(IterableProperty<DeviceObjectModel>('temperature', temperature));
    properties.add(IterableProperty<DeviceObjectModel>('soilTemperature', soilTemperature));
    properties.add(IterableProperty<DeviceObjectModel>('humidity', humidity));
    properties.add(IterableProperty<DeviceObjectModel>('co2', co2));
  }*/

  factory ProgramIrrigationLine.fromJson(Map<String, dynamic> json) {
    // print('irrigationPump in the model :: ${json['irrigationPump']}');
    return ProgramIrrigationLine(
      irrigationLine: DeviceObjectModel.fromJson(json),
      source: _parseList(json['source']),
      sourcePump: _parseList(json['sourcePump']),
      irrigationPump: _parseList(json['irrigationPump']),
      aerator: _parseList(json['aerator']),
      centralFiltration: _parseObject(json['centralFiltration']),
      localFiltration: _parseObject(json['localFiltration']),
      centralFertilization: _parseObject(json['centralFertilization']),
      localFertilization: _parseObject(json['localFertilization']),
      valve: _parseList(json['valve']),
      mainValve: [
        ..._parseList(json['mainValve'])!,
        if(json['flowControlValve'] != null)
          ..._parseList(json['flowControlValve'])!],
      fan: _parseList(json['fan']),
      fogger: _parseList(json['fogger']),
      pesticides: _parseList(json['pesticides']),
      heater: _parseList(json['heater']),
      screen: _parseList(json['screen']),
      vent: _parseList(json['vent']),
      powerSupply: _parseObject(json['powerSupply']),
      pressureSwitch: _parseObject(json['pressureSwitch']),
      waterMeter: _parseObject(json['waterMeter']),
      pressureIn: _parseObject(json['pressureIn']),
      pressureOut: _parseObject(json['pressureOut']),
      moisture: _parseList(json['moisture']),
      temperature: _parseList(json['temperature']),
      soilTemperature: _parseList(json['soilTemperature']),
      humidity: _parseList(json['humidity']),
      co2: _parseList(json['co2']),
      light: _parseList(json['light']),
    );
  }

  /// Parses a list of `DeviceObjectModel` objects.
  static List<DeviceObjectModel>? _parseList(dynamic jsonList) {
    if (jsonList == null && jsonList is! List) return null;
    return jsonList
        .where((e) => (e != null && e.isNotEmpty))
        .map((e) => DeviceObjectModel.fromJson(Map<String, dynamic>.from(e)))
        .whereType<DeviceObjectModel>()
        .toList();
  }

  /// Parses a single `DeviceObjectModel` object.
  static DeviceObjectModel? _parseObject(dynamic jsonObj) {
    if (jsonObj == null && jsonObj.isNotEmpty) return null;
    return jsonObj.isNotEmpty ? DeviceObjectModel.fromJson(Map<String, dynamic>.from(jsonObj)) : null;
  }
}