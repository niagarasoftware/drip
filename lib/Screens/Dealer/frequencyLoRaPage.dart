import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../repository/repository.dart';
import '../../services/mqtt_service.dart';
import '../../services/http_service.dart';
import '../../utils/environment.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

class FrequencyPage extends StatefulWidget {
  final int userId;
  final int controllerId;
  final String deviceId;
  final bool plusTrue;
  final String loraValue;
  final String loara1Version;
  final String loara2Version;

  const FrequencyPage({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.deviceId,
    required this.plusTrue,
    required this.loraValue,
    required this.loara1Version,
    required this.loara2Version,
  });

  @override
  State<FrequencyPage> createState() => _FrequencyPageState();
}
class _FrequencyPageState extends State<FrequencyPage> {
  final TextEditingController frequency1Controller = TextEditingController();
  final TextEditingController sf1Controller = TextEditingController();
  final TextEditingController frequency2Controller = TextEditingController();
  final TextEditingController sf2Controller = TextEditingController();

  late MqttPayloadProvider mqttPayloadProvider;

  String loRa1VersionState = '';
  String loRa2VersionState = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    loRa1VersionState = widget.loara1Version;
    loRa2VersionState = widget.loara2Version;
    _initValues();
  }

  void _initValues() {
    if (widget.loraValue.isNotEmpty) {
      List<String> splitValues = widget.loraValue.split(',');
      if (splitValues.length >= 4) {
        frequency1Controller.text = splitValues[0];
        sf1Controller.text = splitValues[1];
        frequency2Controller.text = splitValues[2];
        sf2Controller.text = splitValues[3];
      }
    }
  }

  String formatNumber(String input) {
    if (input.isEmpty) {
      return '0,0';
    }
    if (!input.contains('.')) {
      input += '.0';
    }
    double number = double.parse(input);
    number *= 10;
    String result = number.toStringAsFixed(0);
    while (result.length < 4) {
      result = '0$result';
    }
    String firstPart = result.substring(0, 2);
    String secondPart = result.substring(2, 4);
    return '$firstPart,$secondPart';
  }

  String formatFrequencyFromDevice(String freq) => (int.parse(freq) / 10).toStringAsFixed(1);
  String formatFrequencyToDevice(String freq) => (double.parse(freq) * 10).toInt().toString();

  bool _isValidFrequency(String freq) => RegExp(r'^\d{1,3}(\.\d)?$').hasMatch(freq);

  void _showErrorDialog(String msg) => showDialog(
      context: context,
      builder: (_) => AlertDialog(title: const Text("Invalid Input"), content: Text(msg)));

  void _showSnackBar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _handleSend() async {
    AppLog.log('----_handleSend');

    String freq1 = frequency1Controller.text;
    String freq2 = frequency2Controller.text;
    String sf1 = sf1Controller.text.isEmpty ? '0' : sf1Controller.text;
    String sf2 = sf2Controller.text.isEmpty ? '0' : sf2Controller.text;

    if (!_isValidFrequency(freq1) || (widget.plusTrue && !_isValidFrequency(freq2))) {
      _showErrorDialog("Enter valid frequencies (000.0) and SF values (7–12).");
      return;
    }

    Map<String, dynamic> payLoadFinal = {
      "6500": {"6501": "${formatNumber(freq1)},$sf1,${formatNumber(freq2)},$sf2"}
    };
    AppLog.log('payLoadFinal----$payLoadFinal');

    Map<String, dynamic> body = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "loraFrequency": "$freq1,$sf1,$freq2,$sf2",
      "modifyUser": widget.userId
    };

    final Repository repository = Repository(HttpService());
    var response = await repository.updateUserDeviceFirmwareDetails(body);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      _showSnackBar(data["message"] ?? "Updated successfully");
    }

    String topic = "${Environment.mqttPublishTopic}/${widget.deviceId}";
    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), topic);

   }

  void _handleView(int loraIndex) {
    setState(() => _isLoading = true);

    String val = loraIndex == 1 ? "29" : "30";
    Map<String, dynamic> payLoadFinal = {"5700": {"5701": val}};
    String topic = "${Environment.mqttPublishTopic}/${widget.deviceId}";
    AppLog.log('payLoadFinal----$payLoadFinal');
    AppLog.log('topic----$topic');
    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), topic);

    Future.delayed(const Duration(seconds: 4), () {
      updateFromMqtt(loraIndex);
      setState(() => _isLoading = false);
    });
  }

  void updateFromMqtt(int loraIndex) {
    try {
      String value = loraIndex == 1
          ? mqttPayloadProvider.Loara1verssion
          : mqttPayloadProvider.Loara2verssion;

      List<String> parts = value.split(',');
      if (parts.length >= 3) {
        String version = parts[0];
        String frequency = parts[1];
        String sf = parts[2];

        setState(() {
          if (loraIndex == 1) {
            frequency1Controller.text = frequency;
            sf1Controller.text = sf;
            loRa1VersionState = version;
          } else {
            frequency2Controller.text = frequency;
            sf2Controller.text = sf;
            loRa2VersionState = version;
          }
        });
      }
    } catch (e) {
      AppLog.log("Error parsing MQTT payload: $e");
    }
  }

  Widget _buildCard({
    required String title,
    required TextEditingController freqCtrl,
    required TextEditingController sfCtrl,
    required int loraIndex,
  }) {
    AppLog.log("loRa1VersionState:$loRa1VersionState,$loRa2VersionState");
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: freqCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.wifi_tethering),
                labelText: "LoRa Frequency (000.0)",
                border: OutlineInputBorder(),
              ),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?'))],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sfCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.settings_input_antenna),
                labelText: "SF Value (7–12)",
                border: OutlineInputBorder(),
              ),

            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Device Version: ${loraIndex == 1 ? loRa1VersionState : loRa2VersionState}",
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                OutlinedButton(
                  onPressed: () => _handleView(loraIndex),
                  child: const Text("View"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenHeight > 800;
    return Scaffold(
      appBar: AppBar(title: const Text("LoRa Frequency Settings")),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all( isLargeScreen ? 40 :16),
            child: Column(
              children: [
                _buildCard(
                    title: "Frequency 1 Settings",
                    freqCtrl: frequency1Controller,
                    sfCtrl: sf1Controller,
                    loraIndex: 1),
                const SizedBox(height: 16),
                widget.plusTrue
                    ? _buildCard(
                    title: "Frequency 2 Settings",
                    freqCtrl: frequency2Controller,
                    sfCtrl: sf2Controller,
                    loraIndex: 2)
                    : const SizedBox(),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        )),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleSend,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Send"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}