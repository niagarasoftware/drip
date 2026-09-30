import 'device_object_model.dart';

class IrrigationLineModel {
  DeviceObjectModel commonDetails;
  List<double> sourcePump;
  List<double> waterSource;
  List<double> irrigationPump;
  List<double> aerator;
  double centralFiltration;
  double localFiltration;
  double centralFertilization;
  double localFertilization;
  List<double> valve;
  List<double> flowControlValve;
  List<double> mainValve;
  List<double> light;
  List<double> gate;
  List<double> fan;
  List<double> fogger;
  List<double> mist;
  List<double> pesticides;
  List<double> heater;
  List<double> screen;
  List<double> vent;
  double powerSupply;
  double pressureSwitch;
  double waterMeter;
  double analogWaterMeter;
  double pressureIn;
  double pressureOut;
  List<double> moisture;
  List<double> temperature;
  List<double> soilTemperature;
  List<double> humidity;
  List<double> co2;
  List<int> weatherStation;

  IrrigationLineModel({
    required this.commonDetails,
    required this.waterSource,
    required this.sourcePump,
    required this.irrigationPump,
    required this.aerator,
    this.centralFiltration = 0.00,
    this.localFiltration = 0.00,
    this.centralFertilization = 0.00,
    this.localFertilization = 0.00,
    required this.valve,
    required this.flowControlValve,
    required this.mainValve,
    required this.light,
    required this.gate,
    required this.fan,
    required this.fogger,
    required this.mist,
    required this.pesticides,
    required this.heater,
    required this.screen,
    required this.vent,
    this.powerSupply = 0.00,
    this.pressureSwitch = 0.00,
    this.waterMeter = 0.00,
    this.analogWaterMeter = 0.00,
    this.pressureIn = 0.00,
    this.pressureOut = 0.00,
    required this.moisture,
    required this.temperature,
    required this.soilTemperature,
    required this.humidity,
    required this.co2,
    required this.weatherStation,
  });

  factory IrrigationLineModel.fromJson(Map<String, dynamic> data) {
    return IrrigationLineModel(
      commonDetails: DeviceObjectModel.fromJson(data),
      waterSource: _toDoubleList(data['waterSource']),
      sourcePump: _toDoubleList(data['sourcePump']),
      irrigationPump: _toDoubleList(data['irrigationPump']),
      aerator: _toDoubleList(data['aerator']),
      centralFiltration: intOrDoubleValidate(data['centralFiltration']),
      localFiltration: intOrDoubleValidate(data['localFiltration']),
      centralFertilization: intOrDoubleValidate(data['centralFertilization']),
      localFertilization: intOrDoubleValidate(data['localFertilization']),
      valve: _toDoubleList(data['valve']),
      flowControlValve: _toDoubleList(data['flowControlValve']),
      mainValve: _toDoubleList(data['mainValve']),
      light: _toDoubleList(data['light']),
      gate: _toDoubleList(data['gate']),
      fan: _toDoubleList(data['fan']),
      fogger: _toDoubleList(data['fogger']),
      mist: _toDoubleList(data['mist']),
      pesticides: _toDoubleList(data['pesticides']),
      heater: _toDoubleList(data['heater']),
      screen: _toDoubleList(data['screen']),
      vent: _toDoubleList(data['vent']),
      powerSupply: intOrDoubleValidate(data['powerSupply']),
      pressureSwitch: intOrDoubleValidate(data['pressureSwitch']),
      waterMeter: intOrDoubleValidate(data['waterMeter']),
      analogWaterMeter: intOrDoubleValidate(data['analogWaterMeter']),
      pressureIn: intOrDoubleValidate(data['pressureIn']),
      pressureOut: intOrDoubleValidate(data['pressureOut']),
      moisture: _toDoubleList(data['moisture']),
      temperature: _toDoubleList(data['temperature']),
      soilTemperature: _toDoubleList(data['soilTemperature']),
      humidity: _toDoubleList(data['humidity']),
      co2: _toDoubleList(data['co2']),
      weatherStation: _toIntList(data['weatherStation']),
    );
  }

  Map<String, dynamic> toJson() {
    var commonInfo = commonDetails.toJson();
    commonInfo.addAll({
      'waterSource': waterSource,
      'sourcePump': sourcePump,
      'irrigationPump': irrigationPump,
      'aerator': aerator,
      'centralFiltration': centralFiltration,
      'localFiltration': localFiltration,
      'centralFertilization': centralFertilization,
      'localFertilization': localFertilization,
      'valve': valve,
      'mainValve': mainValve,
      'flowControlValve': flowControlValve,
      'light': light,
      'gate': gate,
      'fan': fan,
      'fogger': fogger,
      'mist': mist,
      'pesticides': pesticides,
      'heater': heater,
      'screen': screen,
      'vent': vent,
      'powerSupply': powerSupply,
      'pressureSwitch': pressureSwitch,
      'waterMeter': waterMeter,
      'analogWaterMeter': analogWaterMeter,
      'pressureIn': pressureIn,
      'pressureOut': pressureOut,
      'moisture': moisture,
      'temperature': temperature,
      'soilTemperature': soilTemperature,
      'humidity': humidity,
      'co2': co2,
      'weatherStation': weatherStation,
    });
    return commonInfo;
  }

  void updateObjectIdIfDeletedInProductLimit(List<double> objectIdToBeDeleted) {
    final deletedSet = objectIdToBeDeleted.toSet();

    List<double> filterList(List<double> list) =>
        list.where((id) => !deletedSet.contains(id)).toList();

    sourcePump = filterList(sourcePump);
    irrigationPump = filterList(irrigationPump);
    valve = filterList(valve);
    mainValve = filterList(mainValve);
    light = filterList(light);
    gate = filterList(gate);
    fan = filterList(fan);
    fogger = filterList(fogger);
    mist = filterList(mist);
    pesticides = filterList(pesticides);
    heater = filterList(heater);
    screen = filterList(screen);
    vent = filterList(vent);
    moisture = filterList(moisture);
    temperature = filterList(temperature);
    soilTemperature = filterList(soilTemperature);
    humidity = filterList(humidity);
    co2 = filterList(co2);

    if (deletedSet.contains(centralFiltration)) centralFiltration = 0.0;
    if (deletedSet.contains(localFiltration)) localFiltration = 0.0;
    if (deletedSet.contains(centralFertilization)) centralFertilization = 0.0;
    if (deletedSet.contains(localFertilization)) localFertilization = 0.0;
    if (deletedSet.contains(powerSupply)) powerSupply = 0.0;
    if (deletedSet.contains(pressureSwitch)) pressureSwitch = 0.0;
    if (deletedSet.contains(waterMeter)) waterMeter = 0.0;
    if (deletedSet.contains(pressureIn)) pressureIn = 0.0;
    if (deletedSet.contains(pressureOut)) pressureOut = 0.0;
  }

  bool isLineModelParameterIsEmpty() {
    final objectLists = [
      waterSource, sourcePump, irrigationPump, aerator, valve,
      flowControlValve, mainValve, light, gate, fan, fogger,
      mist, pesticides, heater, screen, vent, moisture,
      temperature, soilTemperature, humidity, co2, weatherStation
    ];

    final scalarValues = [
      centralFiltration, localFiltration, centralFertilization,
      localFertilization, powerSupply, pressureSwitch, waterMeter,
      analogWaterMeter, pressureIn, pressureOut
    ];

    return objectLists.every((list) => list.isEmpty) &&
        scalarValues.every((value) => value == 0.0);
  }

  static List<double> _toDoubleList(dynamic list) {
    if (list is! List) return [];
    return list.map((e) => intOrDoubleValidate(e)).toList();
  }

  static List<int> _toIntList(dynamic list) {
    if (list is! List) return [];
    return list.map((e) => (e is num) ? e.toInt() : (int.tryParse(e.toString()) ?? 0)).toList();
  }
}

double intOrDoubleValidate(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

enum LineParameter {
  source, sourcePump, irrigationPump, aerator, centralFiltration,
  localFiltration, centralFertilization, localFertilization, valve,
  flowControlValve, mainValve, light, gate, fan, fogger, mist,
  pesticides, heater, screen, vent, powerSupply, pressureSwitch,
  waterMeter, analogWaterMeter, pressureIn, pressureOut, moisture,
  temperature, soilTemperature, humidity, co2
}
