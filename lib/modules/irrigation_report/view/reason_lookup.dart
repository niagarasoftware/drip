import 'dart:ui';

import 'package:flutter/material.dart';

/// Translates the numeric "Start Stop Reason" / "Pause Resume Reason" codes
/// coming from the device payload into their display string.
String programStartStopReason({required code}) {
  switch (code) {
    case (1):
      return 'Running As Per Schedule';
    case (2):
      return 'Turned On Manually';
    case (3):
      return 'Started By Condition';
    case (4):
      return 'TurnedOff Manually';
    case (5):
      return 'Program TurnedOff';
    case (6):
      return 'Zone TurnedOff';
    case (7):
      return 'Stopped By Condition';
    case (8):
      return 'Disabled By Condition';
    case (9):
      return 'StandAlone Program Started';
    case (10):
      return 'StandAlone Program Stopped';
    case (11):
      return 'StandAlone Program Stopped After SetValue';
    case (12):
      return 'Stand Alone Manual Started';
    case (13):
      return 'StandAlone Manual Stopped';
    case (14):
      return 'StandAlone Manual Stopped AfterSetValue';
    case (15):
      return 'Started By Day CountRtc';
    case (16):
      return 'Paused By User';
    case (17):
      return 'Manually Started Paused By User';
    case (18):
      return 'Program Deleted';
    case (19):
      return 'Program Ready';
    case (20):
      return 'Program Completed';
    case (21):
      return 'Resumed By User';
    case (22):
      return 'Paused By Condition';
    case (23):
      return 'Program Ready And Run By Condition';
    case (24):
      return 'Running As PerSchedule And Condition';
    case (25):
      return 'Started B yCondition Paused By User';
    case (26):
      return 'Resumed By Condition';
    case (27):
      return 'Bypassed Start ConditionManually';
    case (28):
      return 'Bypassed Stop ConditionManually';
    case (29):
      return 'Continue Manually';
    case (30):
      return '-';
    case (31):
      return 'Program Completed';
    case (32):
      return 'Waiting For Condition';
    case (33):
      return 'Started By Condition And Run As Per Schedule';
    default:
      return 'code : $code';
  }
}


dynamic getStatus(code){
  if (code == null) {
    return {'status': 'Running', 'color': Colors.orange};
  }

  String codeStr = code.toString().trim();
  
  // If it's a numeric code, map it via switch
  if (int.tryParse(codeStr) != null) {
    Color innerCircleColor = Colors.grey;
    String statusString = codeStr;
    switch (codeStr) {
      case "0":
        innerCircleColor = Colors.grey;
        statusString = "Pending";
        break;
      case "1":
        innerCircleColor = Colors.orange;
        statusString = "Running";
        break;
      case "2":
        innerCircleColor = Colors.green;
        statusString = "Completed";
        break;
      case "3":
        innerCircleColor = Colors.yellow.shade700;
        statusString = "Skipped";
        break;
      case "4":
        innerCircleColor = Colors.orangeAccent;
        statusString = "Day schedule pending";
        break;
      case "5":
        innerCircleColor = const Color(0xFF0D5D9A);
        statusString = "Day schedule running";
        break;
      case "6":
        innerCircleColor = Colors.yellowAccent;
        statusString = "Day schedule completed";
        break;
      case "7":
        innerCircleColor = Colors.red;
        statusString = "Day schedule skipped";
        break;
      case "8":
        innerCircleColor = Colors.redAccent;
        statusString = "Postponed partially";
        break;
      case "9":
        innerCircleColor = Colors.green;
        statusString = "Postponed fully";
        break;
      case "16":
        innerCircleColor = Colors.red;
        statusString = "Stopped";
        break;
      default:
        innerCircleColor = Colors.amber;
        statusString = codeStr;
        break;
    }
    return {'status' : statusString, 'color': innerCircleColor};
  }

  // If it's already a text status (e.g. "Completed", "Postponed partially", etc.), use it directly!
  Color color = Colors.blueGrey;
  String l = codeStr.toLowerCase();
  if (l.contains('complet') || l.contains('success')) {
    color = Colors.green;
  } else if (l.contains('run') || l.contains('progress') || l.contains('active')) {
    color = Colors.orange;
  } else if (l.contains('stop') || l.contains('skip') || l.contains('fail') || l.contains('error') || l.contains('abort')) {
    color = Colors.red;
  } else if (l.contains('postpon') || l.contains('pend') || l.contains('wait') || l.contains('pause')) {
    color = Colors.amber.shade800;
  }

  return {'status' : codeStr, 'color': color};
}
