import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';

MqttClient createMqttClient(String server, String clientId) {
  final client = MqttServerClient(server, clientId);
  client.port = AppConstants.mqttMobilePort;
  return client;
}
