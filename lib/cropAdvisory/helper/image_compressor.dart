import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressHelper {
  static Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();

      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedFile =
      await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 100,
        minWidth: 200,
        minHeight: 200,
      );

      if (compressedFile == null) return null;

      return File(compressedFile.path);
    } catch (e) {
      print("Compress Error: $e");
      return null;
    }
  }
}