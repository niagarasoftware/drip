import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

import '../../services/sftp_service.dart';

class FileLogger {
  final List<String> traceData = [];

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/ftplog.txt');
  }

  static Future<void> writeToFile(String text) async {
    final file = await _localFile;
    await file.writeAsString('$text\n', mode: FileMode.append);
    AppLog.log('File written: $text');
  }

  static Future<String> readFromFile() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        return await file.readAsString();
      } else {
        return 'File not found';
      }
    } catch (e) {
      return 'Error reading file: $e';
    }
  }


   Future<void> uploadToFile(String text,String deviceId) async {
    SftpService sftpService = SftpService();
    int connectResponse =  await sftpService.connect();
    if(connectResponse == 200){
      await Future.delayed(const Duration(seconds: 1));
      String localFileNameForTrace = "gem_log";
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String filePath = '$appDocPath/$localFileNameForTrace.txt';
      final localFile = File(filePath);
      await localFile.writeAsString(traceData.join('\n$text'));
      int uploadResponse = await sftpService.uploadFile(localFileName: localFileNameForTrace, remoteFilePath: '/home/ubuntu/oro2024/OroGem/OroGemLogs$deviceId.txt');
      if(uploadResponse == 200){
        AppLog.log('success');
       }else{
        AppLog.log('failed');
       }
      sftpService.disconnect();
    }

  }
}
