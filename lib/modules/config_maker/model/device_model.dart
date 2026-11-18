class DeviceModel {
  final int controllerId;
  final int productId;
  String deviceId;
  final String deviceName;
  final int categoryId;
  final String categoryName;
  final int modelId;
  final String modelDescription;
  final String modelName;
  int interfaceTypeId;
  int? interfaceInterval;
  int? serialNumber;
  int? masterId;
  int? extendControllerId;
  final int noOfRelay;
  final int noOfLatch;
  final int noOfAnalogInput;
  final int noOfDigitalInput;
  final int noOfPulseInput;
  final int noOfMoistureInput;
  final int noOfI2CInput;
  final List<int> connectingObjectId;
  bool select;

  DeviceModel({
    required this.controllerId,
    required this.productId,
    required this.deviceId,
    required this.deviceName,
    required this.categoryId,
    required this.categoryName,
    required this.modelId,
    required this.modelDescription,
    required this.modelName,
    required this.interfaceTypeId,
    required this.interfaceInterval,
    required this.serialNumber,
    required this.masterId,
    required this.extendControllerId,
    required this.noOfRelay,
    required this.noOfLatch,
    required this.noOfAnalogInput,
    required this.noOfDigitalInput,
    required this.noOfPulseInput,
    required this.noOfMoistureInput,
    required this.noOfI2CInput,
    required this.connectingObjectId,
    required this.select,
  });

  factory DeviceModel.fromJson(data) {
    return DeviceModel(
      productId: data['productId'],
      controllerId: data['controllerId'],
      deviceId: data['deviceId'],
      deviceName: data['deviceName'],
      categoryId: data['categoryId'],
      categoryName: data['categoryName'],
      modelId: data['modelId'],
      modelDescription: data['modelDescription'],
      modelName: data['modelName'],
      interfaceTypeId: data['interfaceTypeId'],
      interfaceInterval: data['interfaceInterval'],
      serialNumber: data['serialNumber'],
      masterId: data['masterId'],
      extendControllerId: data['extendControllerId'],
      noOfRelay: data['noOfRelay'],
      noOfLatch: data['noOfLatch'],
      noOfAnalogInput: data['noOfAnalogInput'],
      noOfDigitalInput: data['noOfDigitalInput'],
      noOfPulseInput: data['noOfPulseInput'],
      noOfMoistureInput: data['noOfMoistureInput'],
      noOfI2CInput: data['noOfI2CInput'],
      connectingObjectId: data['connectingObjectId'],
      select: data['select'],
    );
  }

  dynamic toJson() {
    return {
      'productId': productId,
      'controllerId': controllerId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'modelId': modelId,
      'modelName': modelName,
      'interfaceTypeId': interfaceTypeId,
      'interfaceInterval': interfaceInterval,
      'serialNumber': serialNumber,
      'masterId': masterId,
      'extendControllerId': extendControllerId,
      'noOfRelay': noOfRelay,
      'noOfLatch': noOfLatch,
      'noOfAnalogInput': noOfAnalogInput,
      'noOfDigitalInput': noOfDigitalInput,
      'noOfPulseInput': noOfPulseInput,
      'noOfMoistureInput': noOfMoistureInput,
      'noOfI2CInput': noOfI2CInput,
      'connectingObjectId': connectingObjectId,
    };
  }

}