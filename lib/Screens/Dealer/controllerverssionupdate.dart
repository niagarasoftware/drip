
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/Screens/Dealer/pumpTopicChange.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:oro_drip_irrigation/utils/environment.dart';
import 'package:provider/provider.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/shared_preferences_helper.dart';
import 'configureMqttTopic.dart';
import 'controllerlogfile.dart';
import 'frequencyLoRaPage.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

class ResetVerssion extends StatefulWidget {
  const ResetVerssion(
      {Key? key,
        required this.userId,
        required this.controllerId,
        required this.deviceID,
        required this.modeID,
      });
  final userId, controllerId, deviceID,modeID;

  @override
  _ResetVerssionState createState() => _ResetVerssionState();
}

class _ResetVerssionState extends State<ResetVerssion> {
  List<Map<String, dynamic>> mergedList = [];
  late MqttPayloadProvider mqttPayloadProvider;
  IconData iconData = Icons.start;
  Color iconcolor = Colors.transparent;
  String imeicheck = '';
  int checkrst = 0;
  int? selectindex;
  int checkupdatediable = 0;
  TextEditingController frequency1Controller = TextEditingController();
  TextEditingController frequency2Controller = TextEditingController();
  TextEditingController sf1Controller = TextEditingController();
  TextEditingController sf2Controller = TextEditingController();
  String? userRole;


  valAssing(List<dynamic> data) {
    mergedList = [];
    for (var device in data) {
      mergedList.add({
        'controllerId': device['controllerId'],
        'deviceId': device['deviceId'],
        'deviceName': device['deviceName'],
        'categoryId': device['categoryId'],
        'categoryName': device['categoryName'],
        'modelId': device['modelId'],
        'modelName': device['modelName'],
        'loraFrequency': device['loraFrequency'],
        'latestVersion': device['latestVersion'] ?? '',
        'currentVersion': device['currentVersion'] ?? '',
        'status': 'Status',
      });
    }
  }

  Future<void> fetchData() async {
    try{
      final Repository repository = Repository(HttpService());
      var response = await repository.getUserDeviceFirmwareDetails({"userId": widget.userId,"controllerId": widget.controllerId});
      if (response.statusCode == 200) {
        setState(() {
          AppLog.log("widget.userId:${widget.userId}");
          var jsondata = jsonDecode(response.body);
          AppLog.log('jsondata:$jsondata');
          valAssing(jsondata['data']);

          MqttService().connect();
        });
      } else {
        //_showSnackBar(response.body);
      }
    }
    catch (e, stackTrace) {
      AppLog.log(' Error overAll getData => ${e.toString()}');
      AppLog.log(' trace overAll getData  => ${stackTrace}');
    }


  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
     mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: false);
    fetchData();
    checkrole().then((role) {
      setState(() {
        userRole = role;
      });
    });
  }

  ResetAll(int index) async {
    sendHttp("2","Controller Restart");
    mergedList[index]["status"] = 'Started';
    iconData = Icons.restart_alt;
    iconcolor = Colors.blue;
    Map<String, dynamic> payLoadFinal = {
      "5700":
      {"5701": "2"},

    };
    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), "${Environment.mqttPublishTopic}/${mergedList[index]["deviceId"]}");

  }
  statusCheck(int index) async {
    Map<String, dynamic> payLoadFinal = {
      "5700":
      {"5701": "31"},

    };
    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), "${Environment.mqttPublishTopic}/${mergedList[index]["deviceId"]}");

  }

  Update(int index) async {


    sendHttp("3","Controller Version Update");
    mergedList[index]["status"] = 'Started';
    iconData = Icons.start;
    iconcolor = Colors.blue;
    Map<String, dynamic> payLoadFinal = {
      "5700":
      {"5701": "3"},
    };

    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), "${Environment.mqttPublishTopic}/${mergedList[index]["deviceId"]}");
    // GlobalSnackBar.show(context, mqttPayloadProvider.messageFromHw, 200);
    // MQTTManager().publish(payLoadFinal, 'OroGemLog/${overAllPvd.imeiNo}');
  }

  bool compareVersions(String version1, String version2) {
    // Extract the version part before the colon
    String cleanVersion1 = version1.split(':')[0];
    String cleanVersion2 = version2.split(':')[0];

    // Split and convert to integer lists
    List<int> version1Parts = cleanVersion1.split('.').map(int.parse).toList();
    List<int> version2Parts = cleanVersion2.split('.').map(int.parse).toList();

    int length = max(version1Parts.length, version2Parts.length);
    for (int i = 0; i < length; i++) {
      int v1 = i < version1Parts.length ? version1Parts[i] : 0;
      int v2 = i < version2Parts.length ? version2Parts[i] : 0;

      if (v1 > v2) {
        return true; // version1 is greater
      } else if (v1 < v2) {
        return false; // version1 is less
      }
    }

    return false; // versions are equal, so not greater
  }

  Future<String?> checkrole() async {
    String? role = await PreferenceHelper.getUserRole();
    return role;
  }

  @override
  Widget build(BuildContext context) {
    bool checkRole = false;
    checkrole().then((role) {
      if (role == 'admin') {
        checkRole = true;
      } else {
        checkRole = false;
      }
    });
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: true);
    status();
    double progressValue = double.parse(mqttPayloadProvider.proogressstatus.replaceAll('%', '')) / 100;

    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.teal.shade100,
        appBar: AppBar(
          title: const Text('Controller Info'),
        ),
        body: RefreshIndicator(
          onRefresh: fetchData,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: kIsWeb? 3:1,
                crossAxisSpacing: 5,
                mainAxisSpacing: 40,
                mainAxisExtent: 500,
              ),
              padding: const EdgeInsets.all(5),
              itemCount: mergedList.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        mergedList[index]['categoryName']!,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      //Settings icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(
                            width: 10,
                          ),

                          Tooltip(
                            message: "Controller Log",
                            child: IconButton(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.teal.shade100)),
                              onPressed: () {
                                setState(() {
                                  selectindex = index;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ControllerLog(
                                        deviceID: '${mergedList[index]['deviceId'
                                        ]!}', communicationType: 'MQTT',),
                                    ),
                                  );
                                });
                              },
                              icon: const Icon(Icons.arrow_circle_right_outlined),
                            ),
                          ),
                    if(![...AppConstants.ecoGemModelList,
                ...AppConstants.shine2V, ...AppConstants.shine4V, ...AppConstants.elite10V]
                    .contains(widget.modeID))...[   Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Tooltip(
                              message: "Config Hardware",
                              child: IconButton(
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        Colors.teal.shade100)),
                                onPressed: () {
                                  setState(() {
                                    AppLog.log('mergedList[index]:${mergedList[index]['modelId']}');
                                    selectindex = index;
                                    if (AppConstants.pumpList.contains(mergedList[index]['modelId'])) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PumpTopicChangePage(
                                            deviceID: '${mergedList[index]['deviceId'
                                            ]!}', userId: widget.userId, controllerId: widget.controllerId, modelId:mergedList[index]['modelId'],communicationType: "MQTT",),
                                        ),
                                      );
                                    }
                                    else{
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ConfigureMqtt(
                                            deviceID: '${mergedList[index]['deviceId'
                                            ]!}', userId: widget.userId, controllerId: widget.controllerId, communicationType: "MQTT",),
                                        ),
                                      ) ;

                                    }

                                  });
                                },
                                icon: const Icon(Icons.settings_outlined),
                              ),
                            ),
                          ) ,],
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Tooltip(
                              message: "LoRa Frequency Set ",
                              child: IconButton(
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        Colors.teal.shade100)),

                                onPressed: () {
                                  setState(() {
                                    selectindex = index;
                                  });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FrequencyPage(
                                        userId: widget.userId,
                                        controllerId:  widget.controllerId,
                                        // deviceId:  widget.deviceID,
                                        deviceId:  mergedList[index]['deviceId'] ?? widget.deviceID,
                                        plusTrue: true,
                                        loraValue: mergedList[index]['loraFrequency'] ?? '',
                                        loara1Version: mqttPayloadProvider.Loara1verssion,
                                        loara2Version: mqttPayloadProvider.Loara2verssion,
                                      ),
                                    ),
                                  );

                                },

                                icon: const Icon(Icons.settings_applications),
                              ),
                            ),
                          ),

                          userRole == 'admin' ?  Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Tooltip(
                              message: "LoRa Update ",
                              child: IconButton(
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        Colors.teal.shade100)),
                                onPressed: () {
                                  setState(() {
                                    selectindex = index;

                                    //Call Siva Ble update Lora class

                                  });
                                },
                                icon: const Icon(Icons.upgrade),
                              ),
                            ),
                          ): Container(),



                        ],
                      ),
                      Container(
                        height: 1,
                        color: Colors.black,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SelectableText(mergedList[index]['deviceId']!,
                        style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),

                      // const SizedBox(height: 10),
                      // Text(
                      //   'SiteName:${mergedList[index]['groupName'] ?? ''}',
                      //   style:
                      //   const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      // ),

                      const SizedBox(height: 10),
                      Text(
                        'Model:${mergedList[index]['modelName'] ?? ''}',
                        style:
                        const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Controller version:${mergedList[index]['currentVersion'] ?? ''}',
                        style:
                        const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                    if(![...AppConstants.ecoGemModelList,
                ...AppConstants.shine2V, ...AppConstants.shine4V, ...AppConstants.elite10V]
                    .contains(widget.modeID))...[ Text(
                        'Server version:${mergedList[index]['latestVersion']!}',
                        style:
                        const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),],
                      const SizedBox(height: 10),
                      imeicheck != mergedList[index]['deviceId']!
                          ? mergedList[index]['status'] != 'Status'
                          ? Container(
                        width: 200,
                        child: Icon(
                          iconData,
                          color: iconcolor,
                          size: 40.0,
                        ),
                      )
                          : Container()
                          : Container(),
                    if(![...AppConstants.ecoGemModelList,
                ...AppConstants.shine2V, ...AppConstants.shine4V, ...AppConstants.elite10V]
                    .contains(widget.modeID))...[  imeicheck != mergedList[index]['deviceId']!
                          ? Text(
                        '${mergedList[index]['status']}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      )
                          : const Text('Status'),],

                      mergedList[index]['status'] != 'Status'
                          ?  Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            IconButton(

                              onPressed: () {
                                setState(() {
                                  statusCheck(index);

                                  //Call Siva Ble update Lora class

                                });
                              },
                              icon: const Icon(Icons.refresh),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: progressValue,
                                minHeight: 8,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                            SizedBox(width: 12),
                            // Text('${(0.6 * 100).toStringAsFixed(0)}%'),
                            Text('${ mqttPayloadProvider.proogressstatus}'),
                          ],
                        ),
                      ) : Container(),

                      // Center(child: Text('${mqttPayloadProvider.messageFromHw ?? 'Status'} ',style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),)),
                      Container(
                        height: 1,
                        color: Colors.grey,
                      ),
                      if(![...AppConstants.ecoGemModelList,
                        ...AppConstants.shine2V, ...AppConstants.shine4V, ...AppConstants.elite10V]
                          .contains(widget.modeID))...[

                        Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              FilledButton(
                                style: ButtonStyle(
                                    backgroundColor: checkupdatediable == 0
                                        ? MaterialStateProperty.all(Colors.red)
                                        : MaterialStateProperty.all(Colors.grey)),
                                onPressed: () {
                                  selectindex = index;
                                  checkupdatediable == 0
                                      ? resetItem(index)
                                      : _showSnackBar("Please wait ....");
                                },
                                child: const Text('Restart'),
                              ),
                              const SizedBox(width: 10),
                              FilledButton(
                                style: ButtonStyle(
                                    backgroundColor: checkupdatediable == 0
                                        ? MaterialStateProperty.all(Colors.green)
                                        : MaterialStateProperty.all(Colors.grey)),
                                onPressed: () {
                                  selectindex = index;
                                  checkupdatediable == 0
                                      ? updateItem(index)
                                      : _showSnackBar("Please wait ....");
                                },
                                child: checkupdatediable == 0
                                    ? mergedList[index]['currentVersion'] !=
                                    mergedList[index]['latestVersion']
                                    ? const BlinkingText(
                                  text: 'Update!', // Provide text here
                                  style: TextStyle(color: Colors.white),
                                  blinkDuration:
                                  Duration(milliseconds: 500),
                                )
                                    : const Text("Update")
                                    : const Text("Update"),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  sendHttp(String val, String msgstatus) async {
    Map<String, dynamic> payLoadFinal = {
      "5700":
      {"5701": "$val"},

    };
    Map<String, dynamic> body = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "hardware": payLoadFinal,
      "messageStatus": msgstatus,
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
  }

  status() {
    if (selectindex != null) {
      Map<String, dynamic>? ctrldata = mqttPayloadProvider.messageFromHw;
      if ((ctrldata != null && ctrldata.isNotEmpty)) {
        var name = ctrldata['Name'];
        // String message = ctrldata['Message'];
        var code = ctrldata['Code'];
        // imeicheck = ctrldata['DeviceId'];
        if (name.contains('Started')) {
          mergedList[selectindex!]['status'] = 'Started';
          iconData = Icons.start;
          iconcolor = Colors.blue;
        }
        else  if (name.contains('Code Update Progress')) {
          mergedList[selectindex!]['status'] = 'Progress';
          iconData = Icons.start;
          iconcolor = Colors.blue;
        }
        else if (name.contains('Restarting')) {
          mergedList[selectindex!]['status'] = 'Restarting...';
          iconData = Icons.incomplete_circle;
          iconcolor = Colors.teal;
        } else if (name.contains('Turned')) {
          iconData = Icons.check_circle;
          mergedList[selectindex!]['status'] = checkrst == 0
              ? 'Last update:${ctrldata['Time']}'
              : 'Last Restart:${ctrldata['Time']}';
          iconcolor = Colors.green;
          checkupdatediable = 0;
          selectindex = null;
          // startDelay();
        } else if (name.contains('wrong')) {
          mergedList[selectindex!]['status'] = '${ctrldata['Message']}';
          iconData = Icons.error;
          iconcolor = Colors.red;
          checkupdatediable = 0;
          selectindex = null;
        }else if (name.contains('GitFailed')) {
          mergedList[selectindex!]['status'] = '${ctrldata['Message']}';
          iconData = Icons.error;
          iconcolor = Colors.red;
          checkupdatediable = 0;
          selectindex = null;
        }
        else {
          mergedList[selectindex!]['status'] = 'Status';
          iconcolor = Colors.transparent;
          // checkupdatediable = 0;
          // selectindex = null;
        }
      }
    }
  }


  void resetItem(int index) {
    setState(() {
      checkupdatediable = 1;
      _showDialogcheck(context, "Restart", index);
    });
  }

  void updateItem(int index) {
    setState(() {
      checkupdatediable = 1;
      _showDialogcheck(context, "Update", index);
    });
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
      result = '0' + result;
    }
    String firstPart = result.substring(0, 2);
    String secondPart = result.substring(2, 4);
    return '$firstPart,$secondPart';
  }

  viewLoaraSett(String val, ) async {

    Map<String, dynamic> payLoadFinal = {
      "5700":
      {"5701": val},
    };

    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), '${Environment.mqttPublishTopic}/${mergedList[selectindex ?? 0]["deviceId"]}');
    fetchData();
  }
  FrequnceAll() async {

    String firstfreequnce1 = formatNumber(frequency1Controller.text);
    String firstfreequnce2 = formatNumber(frequency2Controller.text);
    String sf1 = sf1Controller.text;
    String sf2 = sf2Controller.text;
    sf1 = sf1.isEmpty ? "0" : sf1;
    sf2 = sf2.isEmpty ? "0" : sf2;
    Map<String, dynamic> payLoadFinal = {
      "6500":
      {"6501": "$firstfreequnce1,$sf1,$firstfreequnce2,$sf2"},

    };
    Map<String, dynamic> body = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "loraFrequency":
      '${frequency1Controller.text},${sf1Controller.text},${frequency2Controller.text},${sf2Controller.text}',
      "modifyUser": widget.userId
    };

    final Repository repository = Repository(HttpService());
    var response = await repository.updateUserDeviceFirmwareDetails(body);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data["code"] == 200) {
        _showSnackBar(data["message"]);
      } else {
        _showSnackBar(data["message"]);
      }
    }
    if(kDebugMode) {
      AppLog.log("selectindex----$selectindex");

      AppLog.log("payLoadFinal----$payLoadFinal");
      AppLog.log("payLoadFinal----${Environment
          .mqttPublishTopic}/${mergedList[selectindex!]["deviceId"]}");
    }
    MqttService().topicToPublishAndItsMessage(jsonEncode(payLoadFinal), '${Environment.mqttPublishTopic}/${mergedList[selectindex ?? 0]["deviceId"]}');
    fetchData();
  }
  bool _isValidFrequency(String freq) {
    final regex = RegExp(r'^\d{1,3}\.\d$');
    return regex.hasMatch(freq);
  }
  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter valid frequencies.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDialogcheck(BuildContext context, String update, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: Text(
              "Are you sure you want to $update?\n First, stop. If you confirm that you want to stop, then update your controller by clicking the 'Sure' button."),
          actions: [
            TextButton(
              onPressed: () {
                update == "Update" ? Update(index) : ResetAll(index);
                Navigator.of(context).pop();
              },
              child: const Text('Sure'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  void _showFrequencyDialog(BuildContext context,int index,bool plusTrue) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String loravalue =  mergedList[index]['loraFrequency'] ?? '';

        if( loravalue.isNotEmpty)
        {
          List<String> splitValues = loravalue.split(',');
          frequency1Controller.text = splitValues[0];
          sf1Controller.text = splitValues[1];
          frequency2Controller.text = splitValues[2];
          sf2Controller.text = splitValues[3];
        }
        else
        {
          frequency1Controller.text = '';
          sf1Controller.text = '';
          frequency2Controller.text = '';
          sf2Controller.text = '';
        }
        return AlertDialog(
          title: const Text('LoRa Frequency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: frequency1Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration:  const InputDecoration(
                          hintText: 'Enter LoRa Frequency 1 (000.0)',
                          labelText: "LoRa Frequency 1 ",
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                              r'^\d{1,3}(\.\d{0,1})?$|^99(\.0)?$|^99\.9$')),
                        ],
                      ),
                      TextField(
                        controller: sf1Controller,

                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration:  const InputDecoration(
                          hintText: 'Enter SF value (7-12)',
                          labelText: "SF value ",
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                            r'^(0|1|2|7|8|9|10|11|12)$', // Regex to allow values between 7 and 12 (no decimal)
                          )),
                        ],
                      ),
                      const SizedBox(),
                      Row(children: [ const Spacer(),
                        TextButton(
                          onPressed: () {
                            viewLoaraSett('29');
                            Navigator.of(context).pop();
                          },
                          child: const Text('View'),
                        ),
                        TextButton(
                          onPressed: () {

                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            String freq1 = frequency1Controller.text;
                            String sf1 = sf1Controller.text;
                            bool isValidFreq1 = _isValidFrequency(freq1) && sf1.isNotEmpty;
                            if(isValidFreq1)
                            {
                              FrequnceAll();
                              Navigator.of(context).pop();
                            }
                            else {
                              _showErrorDialog(context);
                            }
                          },
                          child: const Text('Send'),
                        ),],),
                      Text("View to Lora Details:"),
                      Text(mqttPayloadProvider.Loara1verssion)

                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              plusTrue ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: frequency2Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration:  const InputDecoration(
                          hintText: 'Enter LoRa Frequency 2 (000.0)',
                          labelText: "LoRa Frequency 2",
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d{1,3}(\.\d{0,1})?$|^99(\.0)?$|^99\.9$')),
                        ],
                      ),
                      TextField(
                        controller: sf2Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration:  const InputDecoration(
                          hintText: 'Enter SF value (7-12)',
                          labelText: 'SF value ',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                            r'^(0|1|2|7|8|9|10|11|12)$', // Regex to allow values between 7 and 12 (no decimal)
                          )),
                        ],
                      ),
                      Text("View to Lora Details:"),
                      Text(mqttPayloadProvider.Loara2verssion)
                    ],
                  ),
                ),
              ) :  const SizedBox(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                viewLoaraSett('30');
                Navigator.of(context).pop();
              },
              child: const Text('View'),
            ),
            TextButton(
              onPressed: () {

                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String freq1 = frequency1Controller.text;
                String freq2 = frequency2Controller.text;
                String sf1 = sf1Controller.text;
                String sf2 = sf2Controller.text;

                bool isValidFreq1 = _isValidFrequency(freq1) && sf1.isNotEmpty;
                bool isValidFreq2 = _isValidFrequency(freq2) && sf2.isNotEmpty;

                if (plusTrue)
                {
                  if(isValidFreq1 && isValidFreq2)
                  {
                    FrequnceAll();
                    Navigator.of(context).pop();
                  }
                  else {
                    _showErrorDialog(context);
                  }
                } else {

                  if(isValidFreq1)
                  {
                    FrequnceAll();
                    Navigator.of(context).pop();
                  }
                  else {
                    _showErrorDialog(context);
                  }
                }


              },
              child: const Text('Send'),
            ),

          ],
        );
      },
    );
  }

}

class BlinkingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration blinkDuration;

  const BlinkingText({
    Key? key,
    required this.text,
    this.style = const TextStyle(fontSize: 20, color: Colors.red),
    this.blinkDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _BlinkingTextState createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.blinkDuration,
      reverseDuration: widget.blinkDuration,
    )..repeat(reverse: true);

    _opacityAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}