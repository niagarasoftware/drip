import '../flavors.dart';

class Environment {
  static const String currentEnvironment = String.fromEnvironment('ENV', defaultValue: 'oroDevelopment');
  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  static Map<String, Map<String, dynamic>> config = <String, Map<String, dynamic>>{
    'oroDevelopment' : {
      'apiUrl': 'http://192.168.1.85:5000/api/v1',
      'userManualBaseUrl': 'http://192.168.1.85:5000',
      'apiKey': 'dev-api-key',
      'mqttWebUrl': 'ws://192.168.68.141',
      'mqttMobileUrl': '192.168.68.141',
      'publishTopic': 'AppToFirmware',
      'subscribeTopic': 'FirmwareToApp',
      'mqttWebPort': 9001,
      'mqttMobilePort': 1883,
      "mqttUserName" : '',
      "mqttPassword" : '',
    },
    'smartComm' : {
      'apiUrl': 'https://smartcomm-wms.com:5000/api/v1',
      'userManualBaseUrl': 'https://smartcomm-wms.com:5000',
      'apiKey': 'prod-api-key',
      'mqttWebUrl': 'wss://smartcomm-wms.com:9443/mqtt',
      // 'mqttWebUrl': 'ws://52.172.214.208:9001/mqtt',
      'mqttMobileUrl': '52.172.214.208',
      'publishTopic': 'AppToFirmware',
      'subscribeTopic': 'FirmwareToApp',
      'mqttWebPort': 9443,
      // 'mqttWebPort': 9001,
      'mqttMobilePort': 1883,
      'sftpIpAddress': '54.179.114.89',
      'sftpPort': 22,
      'privateKeyPath': 'assets/ssh/smartComm/id_rsa',
      "mqttUserName" : 'imsmqtt',
      "mqttPassword" : '2L9((WonMr',
    },
    'oroProduction': {
      'apiUrl': 'http://13.203.84.47:5000/api/v1',
      'userManualBaseUrl': 'http://13.203.84.47:5000',
      'apiKey': 'prod-api-key',
      'mqttWebUrl': 'ws://13.235.254.21/mqtt',
      //'mqttWebUrl': 'wss://irrigationcare.niagaraautomation.com/mqtt',
      'mqttMobileUrl': '13.235.254.21',
      'publishTopic': 'OroAppToFirmware',
      'subscribeTopic': 'FirmwareToOroApp',
      //'mqttWebPort': 9443,
      'mqttWebPort': 8083,
      'mqttMobilePort': 1883,
      "mqttUserName" : 'mqttuser',
      "mqttPassword" : 'Mqtt@456',
      'sftpIpAddress': '54.179.114.89',
      'sftpPort': 22,
      'privateKeyPath': 'assets/ssh/smartComm/id_rsa',
    },
    'agritel': {
      'apiUrl': 'http://13.235.254.21:8000/api/v1',
      'userManualBaseUrl': 'http://13.235.254.21:8000',
      'apiKey': 'dev-api-key',
      'mqttWebUrl': 'ws://13.235.254.21/mqtt',
      'mqttMobileUrl': '13.235.254.21',
      'publishTopic': 'AgritelAppToFirmware',
      'subscribeTopic': 'FirmwareToAgritelApp',
      'mqttWebPort': 8083,
      'mqttMobilePort': 1883,
      "mqttUserName" : 'niagara',
      "mqttPassword" : 'niagara123',
      'sftpIpAddress': '54.179.114.89',
      'sftpPort': 22,
      'privateKeyPath': 'assets/ssh/smartComm/id_rsa',
    },
  };

  static String get apiUrl => config[F.name]?['apiUrl'] ?? '';
  static String get apiKey => config[currentEnvironment]?['apiKey'] ?? '';
  static String get userManualBaseUrl => config[F.name]?['userManualBaseUrl'] ?? '';

  static String get mqttWebUrl => config[F.name]?['mqttWebUrl'] ?? '';
  static String get mqttMobileUrl => config[F.name]?['mqttMobileUrl'] ?? '';

  static int get mqttWebPort => config[F.name]?['mqttWebPort'] ?? 0;
  static int get mqttMobilePort => config[F.name]?['mqttMobilePort'] ?? 0;
  static String get mqttUserName => config[F.name]?['mqttUserName'] ?? '';
  static String get mqttPassword => config[F.name]?['mqttPassword'] ?? '';
  static String get mqttSubscribeTopic => config[F.name]?['subscribeTopic'] ?? '';
  static String get mqttPublishTopic => config[F.name]?['publishTopic'] ?? '';

  static String get mqttLogTopic => 'OroGemLog';

  static String get sftpIpAddress => config[F.name]?['sftpIpAddress'] ?? '';
  static int get sftpPort => config[F.name]?['sftpPort'] ?? 0;
  static String get privateKeyPath => config[F.name]?['privateKeyPath'] ?? '';
}