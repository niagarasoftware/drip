import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../services/bluetooth/bluetooth_classic_service.dart';
import '../../services/sftp_service.dart';
import '../../utils/snack_bar.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';


class FirmwareBLEPage extends StatefulWidget {
  const FirmwareBLEPage({super.key});

  @override
  _FirmwareBLEPageState createState() => _FirmwareBLEPageState();
}

class _FirmwareBLEPageState extends State<FirmwareBLEPage> {
  double downloadProgress = 0.0;
  double transferProgress = 0.0;
  String status = "Ready";
  int fileSize = 0;
  String fileChecksumSize = '';
  bool isDownloading = false;
  bool isDownloaded = false;
  bool isLoading = false;
  late MqttPayloadProvider mqttPayloadProvider;
  late final Uint8List firmwareBytes;
  String? selectedFile;
  final List<String> files = [
    'OrogemCode',
    'AutoStartFile',
    'MqttsCaFile',
    'MqttsClientCrtFile',
    'MqttsClientKeyFile',
    'ReverseSshpemfile',
    'SftpPemFile',
  ];

  @override
  void initState() {
    super.initState();
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: false);
  }

  Map<String, dynamic>? getFileInfo(String fileName) {
    final Map<String, Map<String, dynamic>> fileData = {
      'OrogemCode': {
        'code': 1,
        'path': '/home/ubuntu/oro2024/OroGem/OroGemApp_RaspberryPi_64bit/OroGem',
      },
      'AutoStartFile': {
        'code': 2,
        'path': '/home/ubuntu/oro2024/OroGem/OroGemApp_AutoStart_RaspberryPi_64bit/AutoStartF',
      },
      'MqttsCaFile': {
        'code': 3,
        'path': '/home/ubuntu/oro2024/OroGem/OroGemApp_AutoStart_RaspberryPi_64bit',
      },
      'MqttsClientCrtFile': {
        'code': 4,
        'path': '/home/ubuntu/oro2024/OroGem/OroGemApp_AutoStart_Tinker_64bit',
      },
      'MqttsClientKeyFile': {
        'code': 5,
        'path': '/home/ubuntu/oro2024/OroGem/OroGemApp_RaspberryPi_32bit',
      },
      'ReverseSshpemfile': {
        'code': 6,
        'path': '/home/ubuntu/oro2024/OroGem/OroGemApp_RaspberryPi_64bit',
      },
      'SftpPemFile': {
        'code': 7,
        'path': '/home/ubuntu/oro2024/OroGem/OroGemLogs',
      },
    };
    return fileData[fileName];
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
  }

  Future<void> _downloadToFile() async {
    if (selectedFile == null) return;

    setState(() {
      isDownloading = true;
      isDownloaded = false;
      downloadProgress = 0.0;
      status = "Downloading...";
    });

    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    List<String> traceData = mqttPayloadProvider.traceLog;
    SftpService sftpService = SftpService();
    int connectResponse = await sftpService.connect();

    if (connectResponse == 200) {
      await Future.delayed(const Duration(seconds: 1));

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String filePath = '${appDocDir.path}/$selectedFile.txt';

      // Save trace log to file
      final localFile = File(filePath);
      await localFile.writeAsString(traceData.join('\n'));

      final info = getFileInfo(selectedFile!);
      if (info == null) return;

      int downResponse = await sftpService.downloadFileWithProgress(
        remoteFilePath: info['path'],
        localFileName: '$selectedFile.txt',
        onProgress: (downloaded, total, percent) {
          setState(() {
            downloadProgress = percent / 100;
            status =
            "Downloading ${formatBytes(downloaded)} of ${formatBytes(total)} (${percent.toStringAsFixed(1)}%)";
          });
        },
      );

      if (downResponse == 200) {
        final downloadedFile = File(filePath);
        if (await downloadedFile.exists()) {
          final fileSize = await downloadedFile.length();
          setState(() {
            GlobalSnackBar.show(context, "Download complete (${formatBytes(fileSize)})", 200);
            status = "Download complete (${formatBytes(fileSize)})";
            isDownloaded = true;
            downloadProgress = 1.0;
          });
        }
      } else {
        GlobalSnackBar.show(context, "Download failed", 201);
        setState(() {
          status = "Download failed";
        });
      }

      sftpService.disconnect();
    } else {
      setState(() {
        GlobalSnackBar.show(context, "Download failed", 201);
        status = "Connection failed";
      });
    }

    setState(() {
      isDownloading = false;
    });
  }

  Future<void> _sendViaBle() async {
    if (selectedFile == null) return;
    await readBootFileStringWithSize();
    final BluetoothClassicService blueService = BluetoothClassicService();
    final info = getFileInfo(selectedFile!);
    String payLoadFinal = jsonEncode({
      "6900": {"6901": "${info?['code']},$fileChecksumSize,$fileSize"},
    });
    await blueService.write(payLoadFinal);
    sendFirmwareFromFile();
  }

  Future<void> sendFirmwareFromFile() async {
    final BluetoothClassicService blueService = BluetoothClassicService();
    const chunkSize = 1024;

    setState(() {
      isLoading = true;
      transferProgress = 0.0;
      status = "Sending firmware...";
    });

    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String filePath = '${appDocDir.path}/$selectedFile.txt';
      final Uint8List firmwareBytes = await File(filePath).readAsBytes();

      for (int offset = 0; offset < firmwareBytes.length; offset += chunkSize) {
        final chunk = firmwareBytes.sublist(
          offset,
          (offset + chunkSize > firmwareBytes.length)
              ? firmwareBytes.length
              : offset + chunkSize,
        );
        await blueService.writeFW(chunk);

        setState(() {
          transferProgress = (offset + chunk.length) / firmwareBytes.length;
          status =
          "Sending firmware ${((offset + chunk.length) / firmwareBytes.length * 100).toStringAsFixed(1)}%";
        });
      }

      setState(() {
        isLoading = false;
        transferProgress = 1.0;
        status = "Transfer complete ✅";
      });
    } catch (e) {
      setState(() => isLoading = false);
      AppLog.log('Error sending firmware: $e');
    }
  }

  Future<void> readBootFileStringWithSize() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String filePath = '${appDocDir.path}/$selectedFile.txt';
      File file = File(filePath);
      if (await file.exists()) {
        List<int> contentsBytes = await file.readAsBytes();
        fileSize = contentsBytes.length;
        final checksum = await calculateSHA256Checksum(filePath);
        fileChecksumSize = checksum ?? '';
      }
    } catch (e) {
      AppLog.log('Error reading file: $e');
    }
  }

  Future<String?> calculateSHA256Checksum(String filePath) async {
    File file = File(filePath);
    if (!await file.exists()) return null;
    List<int> bytes = await file.readAsBytes();
    firmwareBytes = Uint8List.fromList(bytes);
    return sha256.convert(bytes).toString();
  }

  void statushw() {
    Map<String, dynamic>? ctrlData = mqttPayloadProvider.messageFromHw;
    if (ctrlData != null && ctrlData.isNotEmpty) {
      status = ctrlData['Name'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    statushw();
    return Scaffold(
      appBar: AppBar(title: const Text("EXE Transfer via Bluetooth")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Status: $status"),
            const SizedBox(height: 20),

            /// Download GIF + progress
            if (isDownloading) ...[
              Center(
                child: Column(
                  children: [
                    Image.asset("assets/gif/download.gif", height: 120),
                    const SizedBox(height: 10),
                    Text(
                      status,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            /// BLE Transfer GIF + progress
            if (isLoading) ...[
              Center(
                child: Column(
                  children: [
                    Image.asset("assets/gif/sendfiles.gif", height: 120),
                    const SizedBox(height: 10),
                    Text(
                      status,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            DropdownButtonFormField<String>(
              initialValue: selectedFile,
              decoration: InputDecoration(
                labelText: 'Select File',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              icon: const Icon(Icons.arrow_drop_down),
              items: files.map((file) {
                return DropdownMenuItem<String>(
                  value: file,
                  child: Text(file),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedFile = value;
                });
              },
              validator: (value) => value == null ? 'Please select a file' : null,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
              onPressed: isDownloading ? null : _downloadToFile,
              child: const Text("Download"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
              onPressed: isLoading ? null : _sendViaBle,
              child: const Text("Send via Bluetooth"),
            ),
          ],
        ),
      ),
    );
  }
}
