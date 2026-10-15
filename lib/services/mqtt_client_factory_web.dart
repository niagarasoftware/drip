import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient createMqttClient({
  required String webUrl,
  required String mobileUrl,
  required String clientId,
  required int webPort,
  required int mobilePort,
}) {
  final client = MqttBrowserClient(webUrl, clientId);
  client.websocketProtocols = ['mqtt'];
  client.port = webPort;
  return client;
}