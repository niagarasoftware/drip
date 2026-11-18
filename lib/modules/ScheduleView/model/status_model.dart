import 'package:flutter/cupertino.dart';

class StatusInfo {
  final Color color;
  final String statusString;
  final String reason;
  final int code;
  final IconData? icon;

  StatusInfo(this.color, this.statusString, this.icon, this.reason, this.code);
}