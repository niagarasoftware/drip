import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../StateManagement/overall_use.dart';
import '../../modules/IrrigationProgram/view/program_library.dart';
import '../../services/communication_service.dart';
import '../../services/mqtt_service.dart';
import '../../services/sftp_service.dart';
import '../../utils/environment.dart';
import '../../utils/snack_bar.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

// Enum for log types
enum LogType {
  schedule(7),
  uart(8),
  uart0(9),
  uart4(10),
  mqtt(11);

  final int value;
  const LogType(this.value);
}

class ControllerLog extends StatefulWidget {
  final String deviceID;
  final String communicationType;

  const ControllerLog({super.key, required this.deviceID, required this.communicationType});

  @override
  _ControllerLogState createState() => _ControllerLogState();
}

class _ControllerLogState extends State<ControllerLog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OverAllUse overAllPvd;
  late MqttPayloadProvider mqttPayloadProvider;
  final MqttService manager = MqttService();
  LogType currentLogType = LogType.schedule;
  String logString = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    overAllPvd = Provider.of<OverAllUse>(context, listen: false);
    _tabController = TabController(length: 5, vsync: this);

    // MQTT subscriptions
    if(widget.communicationType == 'MQTT')
      {
        manager.topicToUnSubscribe('${Environment.mqttSubscribeTopic}/${widget.deviceID}');
        manager.topicToUnSubscribe('${Environment.mqttLogTopic}/${widget.deviceID}');
        manager.topicToSubscribe('${Environment.mqttLogTopic}/${widget.deviceID}');
      }

  }

  Future<String> getLogFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/log.txt';
  }

  Future<void> writeLog(String message) async {
    final path = await getLogFilePath();
    final file = File(path);
    await file.writeAsString('$message\n', mode: FileMode.append);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildScrollableText(String text) {

    final ScrollController scrollController = ScrollController();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (scrollController.hasClients) {
    //     scrollController.jumpTo(scrollController.position.maxScrollExtent);
    //   }
    // });
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child:  ScrollableTextWithSearch(text: text.isNotEmpty ? text : "Waiting...",)   //SelectableText(),
    );
  }


  @override
  Widget build(BuildContext context) {
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: true);
    status();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text('Controller Log'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Logs',
              onPressed: () => getlog(currentLogType.value),
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear All Logs',
              onPressed: () => _clearLog(),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            onTap: (index) {
              setState(() {
                currentLogType = LogType.values[index];
              });
            },
            tabs: const [
              Tab(text: 'Schedule'),
              Tab(text: 'UART'),
              Tab(text: 'UART-0'),
              Tab(text: 'UART-4'),
              Tab(text: 'Mqtt'),
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
      
                      _buildScrollableText(mqttPayloadProvider.sheduleLog),
                      _buildScrollableText(mqttPayloadProvider.uardLog),
                      _buildScrollableText(mqttPayloadProvider.uard0Log),
                      _buildScrollableText(mqttPayloadProvider.uard4Log),
                      _buildScrollableText(""),
                    ],
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildLogView(String text) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child :_buildScrollableText(text.isNotEmpty ? text : "Waiting..."),
        // child: ScrollableTextWithSearch(
        //   key: ValueKey(text), // Ensure widget rebuilds on text change
        //   text: text.isNotEmpty ? text : "Waiting...",
        // ),
      ),
    );
  }

  Future<void> uploadToFile(String type) async {
    final String dateString = DateFormat('yyyy-MM-dd').format(DateTime.now());

    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    AppLog.log(' mqttPayloadProvider.traceLog----->${ mqttPayloadProvider.traceLog}');
   List<String> traceData =  mqttPayloadProvider.traceLog;
   AppLog.log('traceData----->$traceData');
    SftpService sftpService = SftpService();
    int connectResponse =  await sftpService.connect();
    if(connectResponse == 200){
      await Future.delayed(const Duration(seconds: 1));
      String localFileNameForTrace = "gem_log";
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String filePath = '$appDocPath/$localFileNameForTrace.txt';
      final localFile = File(filePath);
      await localFile.writeAsString(traceData.join('\n'));
      int uploadResponse = await sftpService.uploadFile(localFileName: localFileNameForTrace, remoteFilePath: '/home/ubuntu/oro2024/OroGem/OroGemLogs/${widget.deviceID}_${type}_$dateString.txt');
      if(uploadResponse == 200){
        _showSnackBar("/home/ubuntu/oro2024/OroGem/OroGemLogs/${widget.deviceID}_${type}_$dateString.txt \n FTP upload success'...");
        AppLog.log('upload success');
      }else{
        _showSnackBar("FTP upload failed...");
        AppLog.log('upload failed');
      }
      sftpService.disconnect();
    }

  }

  Future<void> showBluetoothLoadingDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false, // prevents closing by tapping outside
      builder: (BuildContext context) {

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Consumer<MqttPayloadProvider>(
              builder: (context, provider, _) {
                final sizeInBytes = mqttPayloadProvider.traceLogSize;
                final totalSizeInBytes = mqttPayloadProvider.totalTraceLogSize;
                final totalSizeText = totalSizeInBytes > 1024
                    ? '${(totalSizeInBytes / 1024).toStringAsFixed(2)} KB'
                    : '$totalSizeInBytes bytes';
                final sizeText = sizeInBytes > 1024
                    ? '${(sizeInBytes / 1024).toStringAsFixed(2)} KB'
                    : '$sizeInBytes bytes';
                final percentage = totalSizeInBytes > 0
                    ? (sizeInBytes / totalSizeInBytes) * 100
                    : 0;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: percentage / 100),
                    const SizedBox(height: 16),
                    const Text("Fetching logs via Bluetooth..."),
                    Text(
                      'Loading logs... Size: $sizeText / $totalSizeText (${percentage.toStringAsFixed(1)}%)',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text("Close"),
                      style: ElevatedButton.styleFrom(
                         foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // dismiss dialog
                        provider.setTraceLoading(false); // stop loading manually
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }


  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: currentLogType != LogType.mqtt
          ? Wrap(
        spacing: 5,
        runSpacing: 5,
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildButton(
            label: 'Start',
            color: Colors.green,
            icon: Icons.play_arrow,
            onPressed: () {
              _showSnackBar("Start sending to Controller log...");
              getlog(currentLogType.value);
            },
          ),
          const SizedBox(width: 10),
          _buildButton(
            label: 'Stop',
            color: Colors.red,
            icon: Icons.stop,
            onPressed: () {
              _showSnackBar("Stop sending to Controller log...");
              getlog(LogType.mqtt.value);
            },
          ),
          const SizedBox(width: 10),
          _buildButton(
            label: 'Clear',
            color: Colors.grey,
            icon: Icons.clear,
            onPressed: () => _clearLog(),
          ),
          const SizedBox(width: 10),
          _buildButton(
            label: 'Today FTP',
            color: Colors.blue,
            icon: Icons.cloud_upload,
            onPressed: () {
              // if(widget.communicationType != "MQTT") {
                mqttPayloadProvider.setTraceLoading(true);

              _showSnackBar("Today log send FTP...");
              getlog(currentLogType.value + 5);
                showBluetoothLoadingDialog(context);

            },
          ), const SizedBox(width: 10),
          widget.communicationType != "MQTT" ? _buildButton(
            label: 'Today FTP upload',
            color: Colors.blue,
            icon: Icons.cloud_upload,
            onPressed: () {
               _showSnackBar("Today log send FTP...");
              uploadToFile('$currentLogType');
            },
          ) : Container(),
          const SizedBox(width: 10),
          _buildButton(
            label: 'Yesterday FTP',
            color: Colors.blue,
            icon: Icons.cloud_upload,
            onPressed: () {
                 mqttPayloadProvider.setTraceLoading(true);

              _showSnackBar("Yesterday log send FTP...");
              getlog(currentLogType.value + 10);
                 showBluetoothLoadingDialog(context);

            },
          ),


          const SizedBox(width: 10),
          widget.communicationType != "MQTT" ? _buildButton(
            label: 'Yesterday FTP Upload',
            color: Colors.blue,
            icon: Icons.cloud_upload,
            onPressed: () {
              _showSnackBar("Yesterday log send FTP...");
              uploadToFile('$currentLogType');
            },
          ) : Container()
        ],
      )
          : Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          _buildButton(
            label: 'Today Mqtt FTP',
            color: Colors.cyan,
            icon: Icons.cloud_upload,
            onPressed: () {
              _showSnackBar("Today Mqtt log send FTP...");
              getlog(16);
            },
          ),
          const SizedBox(width: 10),
          _buildButton(
            label: 'Yesterday Mqtt FTP',
            color: Colors.cyan,
            icon: Icons.cloud_upload,
            onPressed: () {
              _showSnackBar("Yesterday Mqtt log FTP...");
              getlog(21);
            },
          ),


          widget.communicationType != "MQTT" ? _buildButton(
            label: 'Yesterday FTP Upload BLE',
            color: Colors.blue,
            icon: Icons.cloud_upload,
            onPressed: () {
              _showSnackBar("Yesterday log send FTP...");
              uploadToFile('$currentLogType');

            },
          ) : Container(),
          const SizedBox(width: 10),
          widget.communicationType != "MQTT" ? _buildButton(
            label: 'Today FTP upload BLE',
            color: Colors.blue,
            icon: Icons.cloud_upload,
            onPressed: () {
              _showSnackBar("Today log send FTP... ");
              uploadToFile('$currentLogType');
            },
          ) : Container(),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 14)),
      onPressed: onPressed,
    );
  }

  void _clearLog() {
    _showSnackBar("Clear Controller log...");
    setState(() {
      switch (currentLogType) {
        case LogType.schedule:
          mqttPayloadProvider.sheduleLog = '';
          break;
        case LogType.uart:
          mqttPayloadProvider.uardLog = '';
          break;
        case LogType.uart0:
          mqttPayloadProvider.uard0Log = '';
          break;
        case LogType.uart4:
          mqttPayloadProvider.uard4Log = '';
          break;
        case LogType.mqtt:
          break;
      }
    });
  }

  Future<void> ftpStatusDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<MqttPayloadProvider>(
              builder: (context, mqttPayloadProvider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    logString.contains("LogFileDetailsUpdated - Success")
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 50)
                        : const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      logString.contains("LogFileDetailsUpdated - Success")
                          ? "Success"
                          : "Please wait...",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(logString, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        logString.contains("LogFileDetailsUpdated - Success") ? "Ok" : "Cancel",
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void status() {
    Map<String, dynamic>? ctrlData = mqttPayloadProvider.messageFromHw;
    if (ctrlData != null && ctrlData.isNotEmpty) {
      logString = ctrlData['Name'] ?? '';
    }
  }

  Future<void> getlog(int data) async {
    setState(() => isLoading = true);

    if(widget.communicationType == "MQTT") {
      try {
        manager.topicToUnSubscribe(
            '${Environment.mqttLogTopic}/${widget.deviceID}');
        manager.topicToSubscribe(
            '${Environment.mqttSubscribeTopic}/${widget.deviceID}');

        await Future.delayed(const Duration(seconds: 1));
        if (LogType.values.any((logType) => logType.value == data)) {
          String payloadCode = "5700";
          Map<String, dynamic> payload = {
            "5700": {"5701": "$data"},
          };

          if (manager.isConnected) {
            await validatePayloadSent(
              dialogContext: context,
              context: context,
              mqttPayloadProvider: mqttPayloadProvider,
              acknowledgedFunction: () {
                manager.topicToUnSubscribe(
                    '${Environment.mqttLogTopic}/${widget.deviceID}');
                manager.topicToSubscribe(
                    '${Environment.mqttLogTopic}/${widget.deviceID}');
              },
              payload: payload,
              payloadCode: payloadCode,
              deviceId: widget.deviceID,
            );
          } else {
            GlobalSnackBar.show(context, 'MQTT is Disconnected', 201);
          }
        } else {
          String payload = jsonEncode({
            "5700": {"5701": "$data"},
          });
          manager.topicToPublishAndItsMessage(
              payload, '${Environment.mqttPublishTopic}/${widget.deviceID}');
          await ftpStatusDialog(context);
        }
      } finally {
        setState(() => isLoading = false);
      }
    }
    else
    {
      //bluetooth
      try {
             String payLoadFinal = jsonEncode({
             "5700": {"5701": "$data"},
           });
            final result = await context.read<CommunicationService>().sendCommand(payload: payLoadFinal,
               serverMsg: '');
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
  }

  @override
  void dispose() {
    getlog(LogType.mqtt.value);
    _tabController.dispose();
    manager.topicToUnSubscribe('${Environment.mqttLogTopic}/${widget.deviceID}');
    super.dispose();
  }
}
class ScrollableTextWithSearch extends StatefulWidget {
  final String text;

  const ScrollableTextWithSearch({super.key, 
    required this.text,
  });

  @override
  _ScrollableTextWithSearchState createState() =>
      _ScrollableTextWithSearchState();
}

class _ScrollableTextWithSearchState extends State<ScrollableTextWithSearch> {
  String _searchQuery = '';  // Query text to match
  final ScrollController _scrollController = ScrollController();
  List<int> _matches = [];   // List of match positions
  final TextEditingController _searchController = TextEditingController();
  int _matchCount = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Handle search query change from the controller
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _matches = _findMatches(widget.text, _searchQuery);
    });
  }

  // Highlights the matched text and returns a list of TextSpan
  List<TextSpan> _highlightText(String text, List<int> matchPositions) {
    if (_searchQuery.isEmpty) return [TextSpan(text: text)];

    List<TextSpan> children = [];
    int start = 0;

    for (int pos in matchPositions) {
      if (start < pos) children.add(TextSpan(text: text.substring(start, pos)));
      children.add(TextSpan(
        text: text.substring(pos, pos + _searchQuery.length),
        style: const TextStyle(backgroundColor: Colors.yellow),
      ));
      start = pos + _searchQuery.length;
    }

    if (start < text.length) children.add(TextSpan(text: text.substring(start)));
    return children;
  }

  // Finds matches and returns a list of start positions of the matches
  List<int> _findMatches(String text, String query) {
    if (query.isEmpty) return [];
    List<int> matches = [];
    int start = 0;

    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();

    while (start < lowerText.length) {
      start = lowerText.indexOf(lowerQuery, start);
      if (start == -1) break;
      matches.add(start);
      start += lowerQuery.length;
    }

    return matches;
  }

  // Auto-scroll to bottom
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Detect new text and scroll
  @override
  void didUpdateWidget(covariant ScrollableTextWithSearch oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If new text is added, scroll to bottom
    if (widget.text.length > oldWidget.text.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _matches = _searchQuery.isEmpty ? [] : _findMatches(widget.text, _searchQuery);
    _matchCount = _matches.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _searchQuery = _searchController.text;
                    _matches = _findMatches(widget.text, _searchQuery);
                  });
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Matches found: $_matchCount', style: const TextStyle(fontSize: 16)),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectableText.rich(
                TextSpan(
                  children: _highlightText(widget.text, _matches),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


