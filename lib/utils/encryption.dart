import 'dart:convert';
import 'package:crypto/crypto.dart';

class Encryption {
  static String hashString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}