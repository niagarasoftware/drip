import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/environment.dart';

enum SftpFlag{
  fileDownloadSuccessFully,
  fileDownloadFailed,
  fileUploadSuccessFully,
  fileUploadFailed
}

class SftpService {
  SSHClient? _sshClient;
  SftpClient? _sftpClient;

  Future<int> connect() async {
    try {
      // print("Environment.privateKeyPath : ${Environment.privateKeyPath}");
      // print("Environment.sftpIpAddress : ${Environment.sftpIpAddress}");
      // print("Environment.sftpPort : ${Environment.sftpPort}");
      final rawPem = await rootBundle.loadString(Environment.privateKeyPath);
      final pem = rawPem.replaceAll('\r\n', '\n').trim();
      // for(var line in pem.split('\n')){
      //   print(line);
      // }
      final privateKey = SSHKeyPair.fromPem(pem);
      // for(var line in pem.split('\n')){
      //   print(line);
      // }
      final socket = await SSHSocket.connect(
        Environment.sftpIpAddress,
        Environment.sftpPort,
      );
      _sshClient = SSHClient(
        socket,
        username: 'ubuntu',
        identities: [...privateKey],
      );
      _sftpClient = await _sshClient!.sftp();
      return 200;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('SFTP connect() error: $e');
        print('StackTrace: $stackTrace');
      }
      return 404;
    }
  }

  Future<List<SftpName>> listFilesInPath(String path) async {
    try {
      final items = await _sftpClient!.listdir(path);
      if (kDebugMode) {
        for (final item in items) {
          print(item.longname);
        }
      }
      return items;
    } catch (e) {
      if (kDebugMode) {
        print('listFilesInDirectory error: $e');
      }
      rethrow;
    }
  }

  Future<int> uploadFile({
    required String localFileName,
    required String remoteFilePath,
  }) async
  {
    try {
      print("remoteFilePath : $remoteFilePath");
      final remoteFile = await _sftpClient!.open(
        remoteFilePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String filePath = '$appDocPath/$localFileName.txt';
      final localFile = File(filePath);

      if (!await localFile.exists()) {
        throw Exception('Local file does not exist: $localFileName');
      }

      await remoteFile.write(localFile.openRead().cast()).done;

      if (kDebugMode) {
        print('File uploaded successfully.');
      }
      return 200;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('uploadFile() error: $e');
        print('StackTrace: $stackTrace');
      }
      return 404;
    }
  }

  Future<int> downloadFile({
    required String remoteFilePath,
    String localFileName = 'bootFile.txt',
  }) async
  {
    try {
      // Open the remote file for reading
      print("remoteFilePath : ${remoteFilePath}");
      final remoteFile = await _sftpClient!.open(remoteFilePath);
      final stream = remoteFile.read(); // Stream<Uint8List>

      // Collect the stream of Uint8List chunks into a single Uint8List
      final Uint8List content = await stream.fold<Uint8List>(
        Uint8List(0),
            (previous, element) {
          final buffer = Uint8List(previous.length + element.length);
          buffer.setRange(0, previous.length, previous);
          buffer.setRange(previous.length, buffer.length, element);
          return buffer;
        },
      );

      // Get the local path
      final appDocDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDocDir.path}/$localFileName';
      final localFile = File(localPath);

      // Write the complete binary file to disk
      await localFile.writeAsBytes(content);

      print('✅ File downloaded to: $localPath');
      print('📦 File size: ${content.length} bytes');
      return 200;
    } catch (e, stackTrace) {
      print('❌ Error in downloadFile(): $e');
      print('StackTrace: $stackTrace');
      return 404;
    }
  }

  Future<int> downloadFileOld({
    required String remoteFilePath,
    String localFileName = 'bootFile.txt',
  }) async
  {
    try {
      // Read remote file content
      final remoteFile = await _sftpClient!.open(remoteFilePath);
      final content = await remoteFile.readBytes();

      // Get local file path
      final appDocDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDocDir.path}/$localFileName';
      print('localPath---->$localPath');
      final localFile = File(localPath);

      // Write content to local file
      await localFile.writeAsBytes(content);

      if (kDebugMode) {
        print('File downloaded successfully to $localPath');
        print('File content: ${latin1.decode(content)}');
      }
      return 200;

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('downloadFile() error: $e');
        print('StackTrace: $stackTrace');
      }
      return 404;
    }
  }

  Future<int> downloadFileWithProgress({
    required String remoteFilePath,
    required String localFileName,
    required void Function(int downloaded, int total, double percent) onProgress,
  }) async {
    try {
      final remoteFile = await _sftpClient!.open(remoteFilePath);
      final attrs = await remoteFile.stat();
      final totalSize = attrs.size ?? 0;

      final appDocDir = await getApplicationDocumentsDirectory();
      final localFile = File('${appDocDir.path}/$localFileName').openWrite();

      int downloaded = 0;

      await for (final chunk in remoteFile.read()) {
        downloaded += chunk.length;
        localFile.add(chunk);

        // send downloaded size + total + percent
        onProgress(downloaded, totalSize, (downloaded / totalSize) * 100);
      }

      await localFile.close();
      return 200;
    } catch (e) {
      print('Download error: $e');
      return 404;
    }
  }


  Future<int> uploadFileWithProgress({
    required String localFileName,
    required String remoteFilePath,
    required void Function(double progress) onProgress,
  }) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      final file = File('${appDocDir.path}/$localFileName.txt');

      if (!await file.exists()) throw Exception("File not found");

      final totalSize = await file.length();
      int uploaded = 0;

      final remoteFile = await _sftpClient!.open(
        remoteFilePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );

      final stream = file.openRead(16 * 1024);
      await for (final chunk in stream) {
        uploaded += chunk.length;
        await remoteFile.write(Stream.value(Uint8List.fromList(chunk)));
        onProgress((uploaded / totalSize) * 100);
      }

      await remoteFile.close();
      return 200;
    } catch (e) {
      print('Upload error: $e');
      return 404;
    }
  }



  Future<void> disconnect() async {
    try {
      _sshClient?.close();
      await _sshClient?.done;
    } catch (e) {
      if (kDebugMode) {
        print('disconnect() error: $e');
      }
    } finally {
      _sshClient = null;
      _sftpClient = null;
    }
  }
}
