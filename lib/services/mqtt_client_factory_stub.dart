import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient({
  required String webUrl,
  required String mobileUrl,
  required String clientId,
  required int webPort,
  required int mobilePort,
}) =>
    throw UnsupportedError('Unsupported platform');