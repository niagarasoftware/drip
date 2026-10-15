import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient({
  required String webUrl,
  required String mobileUrl,
  required String clientId,
  required int webPort,
  required int mobilePort,
}) {
  final client = MqttServerClient(mobileUrl, clientId);
  client.port = mobilePort;
  return client;
}