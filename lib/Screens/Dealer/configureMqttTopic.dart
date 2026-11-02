import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../flavors.dart';
import '../../repository/repository.dart';
import '../../services/communication_service.dart';
import '../../services/http_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/constants.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';


class ConfigureMqtt extends StatefulWidget {
  final deviceID, userId, controllerId,communicationType;

  const ConfigureMqtt(
      {super.key,
        required this.deviceID,
        required this.userId,
        required this.communicationType,
        required this.controllerId});

  @override
  _ConfigureMqttState createState() => _ConfigureMqttState();
}

class _ConfigureMqttState extends State<ConfigureMqtt> {
  late MqttPayloadProvider mqttPayloadProvider;
  List<Map<String, dynamic>> configs = [];
  int? selectedIndex;
  bool isLoading = true;
  String errorMessage = '';
  String? formattedConfig;

  // New fields
  String macAddress = '';
  String? selectedPlatform;
  String? selectedVersion;
  String? selectedDealer;

  final List<String> platforms = ['AWS', 'Azure'];
  final List<String> dealers = ['ORO', 'LK'];
  final List<String> versions = ['Version 1.0', 'Version 1.1'];
  final TextEditingController _macController = TextEditingController();
  final Repository repository = Repository(HttpService());
  String _lastPayload = '';

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: false);

    mqttPayloadProvider.addListener(_onPayloadChanged);
    fetchData();
    _macController.text = widget.deviceID;
    macAddress = widget.deviceID;
  }
  @override
  void dispose() {
    mqttPayloadProvider.removeListener(_onPayloadChanged);
    super.dispose();
  }

  void _onPayloadChanged() {
    final provider =
    Provider.of<MqttPayloadProvider>(context, listen: false);

    final payload = provider.receivedPayload;


    if (payload.isNotEmpty && payload != _lastPayload) {
      _lastPayload = payload;

      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(!payload.contains("6801") ? payload : ""),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> fetchData() async {
    AppLog.log('fetchData ');
    final url = Uri.parse('http://13.235.254.21:9000/getConfigs');

    try {
      final response =
      await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawConfigs = data['data'];
        configs = rawConfigs.cast<Map<String, dynamic>>();

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load configs: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e,';
        isLoading = false;
      });
    }
  }

  String formatConfig(Map<String, dynamic> config) {
    if (selectedVersion == 'Version 1.0') {
      return '${config['MQTT_IP'] ?? '-'},'
          '${config['MQTT_USER_NAME'] ?? '-'},'
          '${config['MQTT_PASSWORD'] ?? '-'},'
          '${config['MQTT_PORT'] ?? '-'},'
          '${config['HTTP_URL'] ?? '-'},'
          '${config['STATIC_IP'] ?? '-'},'
          '${config['SUBNET_MASK'] ?? '-'},'
          '${config['DEFAULT_GATEWAY'] ?? '-'},'
          '${config['DNS_SERVER'] ?? '-'},'
          '${config['FTP_IP'] ?? '-'},'
          '${config['FTP_USER_NAME'] ?? '-'},'
          '${config['FTP_PASSWORD'] ?? '-'},'
          '${config['FTP_PORT'] ?? '-'},'
          '${config['MQTT_FRONTEND_TOPIC'] ?? '-'},'
          '${config['MQTT_HARDWARE_TOPIC'] ?? '-'},'
          '${config['MQTT_SERVER_TOPIC'] ?? '-'}';
    } else {
      return '${config['MQTT_IP'] ?? '-'},'
          '${config['MQTT_USER_NAME'] ?? '-'},'
          '${config['MQTT_PASSWORD'] ?? '-'},'
          '${config['MQTT_PORT'] ?? '-'},'
          '${config['HTTP_URL'] ?? '-'},'
          '${config['STATIC_IP'] ?? '-'},'
          '${config['SUBNET_MASK'] ?? '-'},'
          '${config['DEFAULT_GATEWAY'] ?? '-'},'
          '${config['DNS_SERVER'] ?? '-'},'
          '${config['FTP_IP'] ?? '-'},'
          '${config['FTP_USER_NAME'] ?? '-'},'
          '${config['FTP_PASSWORD'] ?? '-'},'
          '${config['FTP_PORT'] ?? '-'},'
          '${config['MQTT_FRONTEND_TOPIC'] ?? '-'},'
          '${config['MQTT_HARDWARE_TOPIC'] ?? '-'},'
          '${config['MQTT_SERVER_TOPIC'] ?? '-'},'
          '${config['SFTP_IP'] ?? '-'},'
          '${config['SFTP_USER_NAME'] ?? '-'},'
          '${config['SFTP_PASSWORD'] ?? '-'},'
          '${config['SFTP_PORT'] ?? '-'},'
          '${config['MQTTS_PORT'] ?? '-'},'
          '${config['MQTTS_STATUS'] ?? '-'},'
          '${config['REVERSE_SSH_BROKER_NAME'] ?? '-'},'
          '${config['REVERSE_SSH_PORT'] ?? '-'}';
    }
  }

  Future<void> sendSelectedProject() async {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a project")),
      );
      return;
    }
    final selectedConfig = configs[selectedIndex!];
    final formatted = formatConfig(selectedConfig);
    if(widget.communicationType == "MQTT") {
      List checkTopic =
      getMqttTopic(selectedPlatform!, selectedVersion!, selectedDealer!);
      AppLog.log('checkTopic---->$checkTopic,$macAddress');
      String topic = checkTopic[0];
      String oldnewcheck = checkTopic[1];
      if (oldnewcheck == '1') {
        final payload = {
          "6100": [
            {"6101": formatted},
          ]
        };
        MqttService().topicToPublishAndItsMessage(
          jsonEncode(payload),
          "$topic${_macController.text}",
        );
        AppLog.log('payload $payload  \n $topic${_macController.text}');
      } else {
        final payload = {
          "6100": {"6101": formatted}
        };
        MqttService().topicToPublishAndItsMessage(
          jsonEncode(payload),
          "$topic${_macController.text}",
        );
        AppLog.log('payload $payload  \n $topic${_macController.text}');
      }
    }
    else
    {
      //bluetooth
      try {
        String payLoadFinal = jsonEncode({
          "6100": {"6101": formatted}
        });
        final result = await context.read<CommunicationService>().sendCommand(payload: payLoadFinal,
            serverMsg: '');
        debugPrint("Payload sent to Server$payLoadFinal");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Settings sent Ble")),
        );
        if (result['http'] == true) {
          debugPrint("Payload sent to Server ");
        }
        if (result['mqtt'] == true) {
          debugPrint("Payload sent to MQTT Box ");
        }
        if (result['bluetooth'] == true) {
          debugPrint("Payload sent via Bluetooth ");
        }

      } finally {
        setState(() => isLoading = false);
      }
    }
    var data = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "data": {
        "6100": [
          {"6101": formatted},
        ]
      },
      "messageStatus": "Settings update",
      "createUser": widget.userId,
      "hardware": {
        "6100": [
          {"6101": formatted},
        ]
      },
    };
    await repository.sendManualOperationToServer(data);
  }

  List<String> getMqttTopic(
      String selectedPlatform, String selectedVersion, String selecteddealer) {
    if (selecteddealer == 'ORO') {
      if (selectedPlatform == 'AWS') {
        AppLog.log('return ORO AWS');
         if(F.appFlavor == Flavor.agritel)
          {
            AppLog.log("agritel");
               return ['AgritelAppToFirmware/', '0'];
           }

        if (selectedVersion == 'Version 1.0') {
          return ['AppToFirmware/', '1'];
        } else {
          return ['OroAppToFirmware/', '0'];
        }
      }
    } else {
      if (selectedPlatform == 'AWS') {
        AppLog.log('return LK AWS');
        if (selectedVersion == 'Version 1.0') return ['AppsToFirmware/', '1'];
      } else {
        AppLog.log('return LK azure');
        if (selectedVersion == 'Version 1.0') {
          return ['AppsToFirmware/', '1'];
        } else {
          return ['AppToFirmware/', '0'];
        }
      }
    }
    AppLog.log('return else');
    return ['AppToFirmware/', '0'];
  }

  Future<void> viewsettings() async {
    if(widget.communicationType == "MQTT")
      {
    List checkTopic =
    getMqttTopic(selectedPlatform!, selectedVersion!, selectedDealer!);
    String topic = checkTopic[0];
    String oldnewcheck = checkTopic[1];
    if (oldnewcheck == '1') {
      final payload = {
        "5700": [
          {"5701": "22"},
        ]
      };
      MqttService().topicToPublishAndItsMessage(
        jsonEncode(payload),
        "$topic${_macController.text}",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("view settings sent")),
      );
    } else {
      final payload = {
        "5700": {"5701": "22"}
      };
      MqttService().topicToPublishAndItsMessage(
        jsonEncode(payload),
        "$topic${_macController.text}",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("view settings sent")),
      );
    }
    }
    else   {
      //bluetooth
      try {
        String payLoadFinal = jsonEncode({
          "5700": {"5701": "22"}
        });
        final result = await context.read<CommunicationService>().sendCommand(payload: payLoadFinal,
            serverMsg: '');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("view settings sent Ble")),
        );
        if (result['http'] == true) {
          debugPrint("Payload sent to Server");
        }
        if (result['mqtt'] == true) {
          debugPrint("Payload sent to MQTT Box");
        }
        if (result['bluetooth'] == true) {
          debugPrint("Payload sent via Bluetooth");
        }

      } finally {
        setState(() => isLoading = false);
      }
    }
    var data = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "data": {
        "5700": [
          {"5701": "22"},
        ]
      },
      "messageStatus": "View Settings",
      "createUser": widget.userId,
      "hardware": {
        "5700": [
          {"5701": "22"},
        ]
      },
    };
    await repository.sendManualOperationToServer(data);
  }

  Future<void> updateCode() async {
    if(widget.communicationType == "MQTT") {
      List checkTopic =
      getMqttTopic(selectedPlatform!, selectedVersion!, selectedDealer!);
      String topic = checkTopic[0];
      String oldnewcheck = checkTopic[1];
      final payload = oldnewcheck == '1'
          ? {"5700": [{"5701": "27"}]}
          : {"5700": {"5701": "28"}};

      MqttService().topicToPublishAndItsMessage(
        jsonEncode(payload),
        "$topic${_macController.text}",
      );

      var data = {
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "data": payload,
        "messageStatus": "updateCode",
        "createUser": widget.userId,
        "hardware": payload,
      };
      await repository.sendManualOperationToServer(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("update settings sent")),
      );
    } else {
      //bluetooth
      try {
        String payLoadFinal = jsonEncode({
          "5700": {"5701": "28"}
        });
        final result = await context.read<CommunicationService>().sendCommand(
            payload: payLoadFinal, serverMsg: 'updateCode');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("update settings sent Ble")),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> updateCodeonly() async {
    if(widget.communicationType == "MQTT") {
      List checkTopic =
      getMqttTopic(selectedPlatform!, selectedVersion!, selectedDealer!);
      String topic = checkTopic[0];
      String oldnewcheck = checkTopic[1];
      final payload = oldnewcheck == '1'
          ? {"5700": [{"5701": "3"}]}
          : {"5700": {"5701": "3"}};

      MqttService().topicToPublishAndItsMessage(
        jsonEncode(payload),
        "$topic${_macController.text}",
      );

      var data = {
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "data": payload,
        "messageStatus": "updateCode",
        "createUser": widget.userId,
        "hardware": payload,
      };
      await repository.sendManualOperationToServer(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("update settings sent")),
      );
    } else {
      //bluetooth
      try {
        String payLoadFinal = jsonEncode({
          "5700": {"5701": "3"}
        });
        final result = await context.read<CommunicationService>().sendCommand(
            payload: payLoadFinal, serverMsg: 'updateCode');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("update settings sent Ble")),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> Restart() async {
    if(widget.communicationType == "MQTT") {
      List checkTopic =
      getMqttTopic(selectedPlatform!, selectedVersion!, selectedDealer!);
      String topic = checkTopic[0];
      String oldnewcheck = checkTopic[1];
      final payload = oldnewcheck == '1'
          ? {"5700": [{"5701": "2"}]}
          : {"5700": {"5701": "2"}};

      MqttService().topicToPublishAndItsMessage(
        jsonEncode(payload),
        "$topic${_macController.text}",
      );

      var data = {
        "userId": widget.userId,
        "controllerId": widget.controllerId,
        "data": payload,
        "messageStatus": "Restart",
        "createUser": widget.userId,
        "hardware": payload,
      };
      await repository.sendManualOperationToServer(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restart settings sent")),
      );
    } else {
      //bluetooth
      try {
        String payLoadFinal = jsonEncode({
          "5700": {"5701": "2"}
        });
        final result = await context.read<CommunicationService>().sendCommand(
            payload: payLoadFinal, serverMsg: 'Restart');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restart settings sent Ble")),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Hardware'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(child: Text(errorMessage))
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MAC Address
              TextField(
                decoration: const InputDecoration(
                  labelText: 'MAC Address',
                  border: OutlineInputBorder(),
                ),
                controller: _macController,
                onChanged: (value) {
                  macAddress = value;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedDealer,
                decoration: const InputDecoration(
                  labelText: 'Select Current Dealer',
                  border: OutlineInputBorder(),
                ),
                items: dealers.map((dealers) {
                  return DropdownMenuItem<String>(
                    value: dealers,
                    child: Text(dealers),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    // value == 'ORO' ? F.appFlavor = Flavor.oroProduction : F.appFlavor = Flavor.smartComm;
                    selectedDealer = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Platform Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedPlatform,
                decoration: const InputDecoration(
                  labelText: 'Select Current Platform',
                  border: OutlineInputBorder(),
                ),
                items: platforms.map((platform) {
                  return DropdownMenuItem<String>(
                    value: platform,
                    child: Text(platform),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    // value == 'AWS'
                    //     ? F.appFlavor = Flavor.oroProduction
                    //     : F.appFlavor = Flavor.smartComm;

                    AppLog.log('flaVOR ${F.appFlavor}');
                    AppLog.log(AppConstants.mqttUrl);
                    selectedPlatform = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Version Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedVersion,
                decoration: const InputDecoration(
                  labelText: 'Select Current Version',
                  border: OutlineInputBorder(),
                ),
                items: versions.map((version) {
                  return DropdownMenuItem<String>(
                    value: version,
                    child: Text(version),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedVersion = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Project Config Selection
              DropdownButton<int>(
                value: selectedIndex,
                isExpanded: true,
                hint: const Text('Select Update Project'),
                items: List.generate(configs.length, (index) {
                  final config = configs[index];
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(
                        '${config['PROJECT_NAME']} - ${config['SERVER_NAME']}'),
                  );
                }),
                onChanged: (index) {
                  setState(() {
                    selectedIndex = index;
                    formattedConfig = index != null
                        ? formatConfig(configs[index])
                        : null;
                  });
                },
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 20),

        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 10,        // horizontal space between buttons
          runSpacing: 12,     // vertical space when wrapped
                 children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                  showDialog(
                  context: context,
                  builder: (BuildContext context) {
                  return AlertDialog(
                  title: const Text("Confirm Settings Update"),
                  content: const Text("Are you sure you want to update settings?"),
                  actions: [
                  TextButton(
                  onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  sendSelectedProject(); // Call your function
                  },
                  child: const Text("Yes"),
                  ),
                  ],
                  );
                  },
                  );
                  },
                    child: const Text('Settings Update'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                    ),
                    onPressed: ()  {
                  showDialog(
                  context: context,
                  builder: (BuildContext context) {
                  return AlertDialog(
                  title: const Text("Confirm Update"),
                  content: const Text("Are you sure you want to update HW Code?"),
                  actions: [
                  TextButton(
                  onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  updateCode(); // Call your function
                  },
                  child: const Text("Yes, Update"),
                  ),
                  ],
                  );
                  },
                  );
                  },
                    child: const Text('Update HW Code'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.brown,
                    ),
                    onPressed: viewsettings,
                    child: const Text('View Settings'),
                  ),
                   widget.communicationType != "MQTT" ? ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       foregroundColor: Colors.white,
                       backgroundColor: Colors.teal,
                     ),
                     onPressed: () {
                       showDialog(
                         context: context,
                         builder: (BuildContext context) {
                           return AlertDialog(
                             title: const Text("Confirm Settings Update"),
                             content: const Text("Are you sure you want to update settings?"),
                             actions: [
                               TextButton(
                                 onPressed: () {
                                   Navigator.of(context).pop(); // Close the dialog
                                 },
                                 child: const Text("Cancel"),
                               ),
                               ElevatedButton(
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.green,
                                   foregroundColor: Colors.white,
                                 ),
                                 onPressed: () {
                                   Navigator.of(context).pop(); // Close dialog
                                   updateCodeonly(); // Call your function
                                 },
                                 child: const Text("Yes"),
                               ),
                             ],
                           );
                         },
                       );
                     },
                     child: const Text(' Update '),
                   ) : Container(),
                   widget.communicationType != "MQTT" ?ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       foregroundColor: Colors.white,
                       backgroundColor: Colors.red,
                     ),
                     onPressed: ()  {
                       showDialog(
                         context: context,
                         builder: (BuildContext context) {
                           return AlertDialog(
                             title: const Text("Confirm Restart"),
                             content: const Text("Are you sure you want to Restart?"),
                             actions: [
                               TextButton(
                                 onPressed: () {
                                   Navigator.of(context).pop(); // Close the dialog
                                 },
                                 child: const Text("Cancel"),
                               ),
                               ElevatedButton(
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.green,
                                   foregroundColor: Colors.white,
                                 ),
                                 onPressed: () {
                                   Navigator.of(context).pop(); // Close dialog
                                   Restart(); // Call your function
                                 },
                                 child: const Text("Yes, Restart"),
                               ),
                             ],
                           );
                         },
                       );
                     },
                     child: const Text(' Restart '),
                   ) : Container(),
                ],
              ),
             // widget.communicationType == "MQTT" ? Padding(
             //    padding: const EdgeInsets.all(8.0),
             //    child: Text(mqttPayloadProvider.receivedPayload),
             //  ) : Container(),
const SizedBox(height: 10,),

              widget.communicationType != "MQTT" ?  SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  mqttPayloadProvider.receivedPayload,
                  style: const TextStyle(fontSize: 14),
                ),
              ) : Container(),

        ],
          ),
        ),
      ),
    );
  }
}
