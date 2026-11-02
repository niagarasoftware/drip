import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/environment.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

class PumpTopicChangePage extends StatefulWidget {
  final deviceID;
  final userId;
  final communicationType;
  final controllerId, modelId;

  const PumpTopicChangePage({
    super.key,
    required this.deviceID,
    required this.userId,
    required this.communicationType,
    required this.controllerId,
    required this.modelId,
  });

  @override
  State<PumpTopicChangePage> createState() => _PumpTopicChangePageState();
}

class _PumpTopicChangePageState extends State<PumpTopicChangePage> {
  bool isLoading = true;
  String errorMessage = '';
  late MqttPayloadProvider mqttPayloadProvider;

  // Controllers
   final TextEditingController mqttIpController = TextEditingController();
  final TextEditingController mqttUserController = TextEditingController();
  final TextEditingController mqttPassController = TextEditingController();
  final TextEditingController ftpIpController = TextEditingController();
  final TextEditingController ftpUserController = TextEditingController();
  final TextEditingController ftpPassController = TextEditingController();
  final TextEditingController pathController = TextEditingController();
  final TextEditingController mqttFrontendTopicController =
  TextEditingController();
  final TextEditingController mqttServerTopicController =
  TextEditingController();
  final TextEditingController mqttHardwareTopicController =
  TextEditingController();

  // Field validation states
  Map<String, bool> fieldValid = {
     "MQTT IP": true,
    "MQTT Username": true,
    "MQTT Password": true,
    "FTP IP": true,
    "FTP Username": true,
    "FTP Password": true,
    "Path": true,
    "MQTT Frontend Topic": true,
    "MQTT Server Topic": true,
    "MQTT Hardware Topic": true,
  };

  // Track send status for button color
  Map<String, bool> sentStatus = {
     "MQTT IP": false,
    "MQTT Username": false,
    "MQTT Password": false,
    "FTP IP": false,
    "FTP Username": false,
    "FTP Password": false,
    "Path": false,
    "MQTT Frontend Topic": false,
    "MQTT Server Topic": false,
    "MQTT Hardware Topic": false,
  };

  List<Map<String, dynamic>> configs = [];
  Map<String, dynamic>? selectedConfig;

  @override
  void initState() {
    super.initState();

    fetchData();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: false);
  }

  @override
  void dispose() {
     mqttIpController.dispose();
    mqttUserController.dispose();
    mqttPassController.dispose();
    ftpIpController.dispose();
    ftpUserController.dispose();
    ftpPassController.dispose();
    pathController.dispose();
    mqttFrontendTopicController.dispose();
    mqttServerTopicController.dispose();
    mqttHardwareTopicController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    final url = Uri.parse('http://13.235.254.21:9000/getConfigs');

    try {
      final response =
      await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawConfigs = data['data'];
        configs = rawConfigs.cast<Map<String, dynamic>>();

        if (configs.isNotEmpty) {
          selectedConfig = configs.first;
          populateFields(selectedConfig!);
        }

        if (!mounted) return;
        setState(() => isLoading = false);
      } else {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Failed to load configs: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e, stacktrace) {
      if (!mounted) return;
      setState(() {
        AppLog.log(e);
        AppLog.log(stacktrace);
        errorMessage = 'Error fetching data: $e';
        isLoading = false;
      });
    }
  }

  void populateFields(Map<String, dynamic>? config) {
    if (config == null) return;

     mqttIpController.text = formatIp(config['MQTT_IP'] ?? '');
    mqttUserController.text = config['MQTT_USER_NAME'] ?? '';
    mqttPassController.text = config['MQTT_PASSWORD'] ?? '';
    ftpIpController.text = config['FTP_IP'] ?? '';
    ftpUserController.text = config['FTP_USER_NAME'] ?? '';
    ftpPassController.text = config['FTP_PASSWORD'] ?? '';
    pathController.text = '-'; //config['PATH'] ?? '';
    mqttFrontendTopicController.text = trailRemoveSlash(config['MQTT_FRONTEND_TOPIC'] ?? '');
    mqttServerTopicController.text = trailRemoveSlash(config['MQTT_SERVER_TOPIC'] ?? '');
    mqttHardwareTopicController.text = trailRemoveSlash(config['MQTT_HARDWARE_TOPIC'] ?? '');

    // Reset validation and sent states
    fieldValid.updateAll((key, value) => true);
    sentStatus.updateAll((key, value) => false);
  }

  String trailRemoveSlash(String? value) {
    if (value == null) return '';
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  String formatIp(String ip) {
    AppLog.log('ip: $ip');
    return ip.split('.')
        .map((part) => part.padLeft(3, '0'))
        .join('.');
  }

  void sendField(String fieldName, TextEditingController controller) {
    setState(() {
      fieldValid[fieldName] = controller.text.isNotEmpty;
    });

    if (!fieldValid[fieldName]!) return;

    // Mark field as sent
    setState(() {
      sentStatus[fieldName] = true;
    });

    AppLog.log("Send $fieldName: ${controller.text}");
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("$fieldName Sent")));
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

   Future<void> sendAllFields(Map<String, dynamic>? config,String topic)  async {

     String Sendalldatatopic =
         "${trailRemoveSlash(config!['MQTT_FRONTEND_TOPIC'])},${trailRemoveSlash(config['MQTT_SERVER_TOPIC'])},${trailRemoveSlash(config['MQTT_HARDWARE_TOPIC'])}";

      String Sendalldataip = "${config['MQTT_USER_NAME']},${config['MQTT_PASSWORD']},${formatIp(config['MQTT_IP'])}";

      AppLog.log('Sendalldataip:   $Sendalldataip');

     Map<String, dynamic> payLoadFinalip = {
       "sentSms":"mqttcred,$Sendalldataip,"};

     Map<String, dynamic> payLoadFinaltopic = {
       "sentSms":"mqtttopic,$Sendalldatatopic,"};

     Map<String, dynamic> payLoadview = {
       "sentSms": "topicview"};

     Map<String, dynamic> payLoadReset = {
       "sentSms": "reset"};

     Map<String, dynamic> body = {
       "userId": widget.userId,
       "controllerId": widget.controllerId,
       "hardware": topic == 'topic' ? payLoadFinaltopic : topic == 'ip' ? payLoadFinalip : topic == 'reset' ? payLoadReset : payLoadview,
       "messageStatus": "Pump Topic Change",
       "createUser": widget.userId
     };


    final Repository repository = Repository(HttpService());
     var response = await repository.sendManualOperationToServer(body);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data["code"] == 200) {
        _showSnackBar(data["message"]);
      } else {
        _showSnackBar(data["message"]);
      }
    }
    AppLog.log('topic:------> ${topic == 'topic' ? payLoadFinaltopic : topic == 'ip' ? payLoadFinalip : topic == 'reset' ? payLoadReset : payLoadview}');

     MqttService().topicToPublishAndItsMessage(jsonEncode(topic == 'topic' ? payLoadFinaltopic : topic == 'ip' ? payLoadFinalip : topic == 'reset' ? payLoadReset : payLoadview),'${Environment.mqttPublishTopic}/${widget.deviceID}');


    // fetchData();
  }


  Widget buildTextFieldWithButton(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              readOnly: true,
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                sentStatus[label]! ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => sendField(label, controller),
              child: Text(sentStatus[label]! ? "Sent" : "Send"),
            ),
          ),
        ],
      ),
    );
  }

  void sendAllFieldsold(Map<String, dynamic>? config) {
    final fields = {
       "MQTT IP": mqttIpController.text,
      "MQTT Username": mqttUserController.text,
      "MQTT Password": mqttPassController.text,
      "FTP IP": ftpIpController.text,
      "FTP Username": ftpUserController.text,
      "FTP Password": ftpPassController.text,
      "Path": pathController.text,
      "MQTT Frontend Topic": mqttFrontendTopicController.text,
      "MQTT Server Topic": mqttServerTopicController.text,
      "MQTT Hardware Topic": mqttHardwareTopicController.text,
    };


     bool allValid = true;
    fields.forEach((key, value) {
      if (value.isEmpty) allValid = false;
    });

    if (!allValid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Some fields are empty")));
      return;
    }

    setState(() {
      sentStatus.updateAll((key, value) => true);
    });

    AppLog.log("Send All Fields: $fields");
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("All Fields Sent")));
  }

  @override
  Widget build(BuildContext context) {
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: true);

    int? modelId = widget.modelId;

    return Scaffold(
      appBar: AppBar(title: const Text("Pump Topic Change")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: selectedConfig,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Select Project",
                    border: OutlineInputBorder(),
                  ),
                  items: configs.map((config) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: config,
                      child: Text(
                          "${config['PROJECT_NAME'] ?? 'Unknown'} - ${config['SERVER_NAME'] ?? ''}"),
                    );
                  }).toList(),
                  onChanged: (config) {
                    setState(() {
                      selectedConfig = config;
                      populateFields(config!);
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Fields + Buttons logic
                if (modelId == 7 || modelId == 8 || modelId == 10) ...[

                  const SizedBox(height: 10),
                  TextField(  readOnly: true,
                    controller: mqttIpController,
                    decoration: const InputDecoration(
                        labelText: "MQTT IP",
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(  readOnly: true,
                    controller: mqttUserController,
                    decoration: const InputDecoration(
                        labelText: "MQTT Username",
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(  readOnly: true,
                    controller: mqttPassController,
                    decoration: const InputDecoration(
                        labelText: "MQTT Password",
                        border: OutlineInputBorder()),
                  ),
                  // const SizedBox(height: 10),
                  // TextField(  readOnly: true,
                  //   controller: ftpIpController,
                  //   decoration: const InputDecoration(
                  //       labelText: "FTP IP",
                  //       border: OutlineInputBorder()),
                  // ),
                  // const SizedBox(height: 10),
                  // TextField(  readOnly: true,
                  //
                  //   controller: ftpUserController,
                  //   decoration: const InputDecoration(
                  //       labelText: "FTP Username",
                  //       border: OutlineInputBorder()),
                  // ),
                  // const SizedBox(height: 10),
                  // TextField(  readOnly: true,
                  //   controller: ftpPassController,
                  //   decoration: const InputDecoration(
                  //       labelText: "FTP Password",
                  //       border: OutlineInputBorder()),
                  // ),
                  // const SizedBox(height: 10),
                  // TextField(  readOnly: true,
                  //   controller: pathController,
                  //   decoration: const InputDecoration(
                  //       labelText: "Path",
                  //       border: OutlineInputBorder()),
                  // ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white),
                    onPressed: () => sendAllFields(selectedConfig,'ip'),
                    child: const Text("Send IP"),
                  ),
                  const Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  const SizedBox(height: 10),
                  TextField(  readOnly: true,
                    controller: mqttFrontendTopicController,
                    decoration: const InputDecoration(
                        labelText: "MQTT Frontend Topic",
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(  readOnly: true,
                    controller: mqttServerTopicController,
                    decoration: const InputDecoration(
                        labelText: "MQTT Server Topic",
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(  readOnly: true,
                    controller: mqttHardwareTopicController,
                    decoration: const InputDecoration(
                        labelText: "MQTT Hardware Topic",
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white),
                    onPressed: () => sendAllFields(selectedConfig,'topic'),
                    child: const Text("Send Topic"),
                  ),
                  const Divider(
                    color: Colors.grey,
                    thickness: 1,
                  )
                ] else ...[

                  buildTextFieldWithButton(
                      "MQTT IP", mqttIpController),
                  buildTextFieldWithButton(
                      "MQTT Username", mqttUserController),
                  buildTextFieldWithButton(
                      "MQTT Password", mqttPassController),
                  buildTextFieldWithButton("FTP IP", ftpIpController),
                  buildTextFieldWithButton(
                      "FTP Username", ftpUserController),
                  buildTextFieldWithButton(
                      "FTP Password", ftpPassController),
                  buildTextFieldWithButton("Path", pathController),
                  buildTextFieldWithButton("MQTT Frontend Topic",
                      mqttFrontendTopicController),
                  buildTextFieldWithButton("MQTT Server Topic",
                      mqttServerTopicController),
                  buildTextFieldWithButton("MQTT Hardware Topic",
                      mqttHardwareTopicController),
                ],

                const SizedBox(height: 20),
                Row(
                  children: [
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white),
                      onPressed: () {
                      sendAllFields(selectedConfig,'view');
                        },
                      child: const Text("View Settings"),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      onPressed: () {
                        sendAllFields(selectedConfig,'reset');
                        },
                      child: const Text("Reset"),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                // Text(mqttPayloadProvider.receivedPayload),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

