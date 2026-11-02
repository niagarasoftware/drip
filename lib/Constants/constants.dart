import 'package:flutter/foundation.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';

class Constants {
  static const String sNo = 'sNo';
  static const String objectId = 'objectId';
  static const String name = 'name';
  static const String connectionNo = 'connectionNo';
  static const String objectName = 'objectName';
  static const String location = 'location';
  static const String type = 'type';
  static const String pumpType = 'pumpType';
  static const String controllerId = 'controllerId';
  static const String count = 'count';
  static const String level = 'level';
  static const String pressure = 'pressure';
  static const String waterMeter = 'waterMeter';

  static dynamic payloadConversion(data) {
    // List<dynamic> configObject = List<dynamic>.from(data["configObject"]);
    List<dynamic> configObject = List<dynamic>.from(data["configObject"]);

    dynamic dataFormation = {};
    for(var globalKey in data.keys) {
      if(['filterSite', 'fertilizerSite', 'waterSource', 'pump', 'moistureSensor', 'irrigationLine'].contains(globalKey)){
        dataFormation[globalKey] = [];
        for(var site in data[globalKey]){
          dynamic siteFormation = site;
          for(var siteKey in site.keys){
            if(!['objectId', 'sNo', 'name', 'objectName', 'connectionNo', 'type', 'controllerId', 'count', 'siteMode', 'pumpType', 'connectedObject', 'location', 'assignedObject', 'weatherStation'].contains(siteKey)){
              siteFormation[siteKey] = siteFormation[siteKey] is List<dynamic>
                  ? (siteFormation[siteKey] as List<dynamic>).map((element) {
                if(element is double){
                  print("element : $element");
                  return configObject.firstWhere((object) => object['sNo'] == element);
                }else{
                  var object = configObject.firstWhere((object) => object['sNo'] == element['sNo']);
                  for(var key in element.keys){
                    if(!(object as Map<String, dynamic>).containsKey(key)){
                      object[key] = element[key];
                    }
                  }
                  return object;
                }
              }).toList()
                  : configObject.firstWhere((object) => object['sNo'] == siteFormation[siteKey], orElse: ()=> {});
            }
          }
          dataFormation[globalKey].add(site);
        }
      }
    }
    // print('dataFormation : ${jsonEncode(dataFormation)}');
    // print('-------------------------------------------');
    return dataFormation;
  }

  static String sendFourDigit(String val) {
    return val.padLeft(4, '0');
  }

  static String sendPayloadWithCrc(String payload) {
    String payloadStr = payload;

    List<int> bytes = payloadStr.codeUnits;

    int crc = 0xFFFF;

    for (int byte in bytes) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc = crc >> 1;
        }
      }
    }

    // Split into low and high bytes
    int crcLow = crc & 0xFF;
    int crcHigh = (crc >> 8) & 0xFF;

    // Format as 4-digit HEX
    String crcHex =
        crcHigh.toRadixString(16).padLeft(2, '0') +
            crcLow.toRadixString(16).padLeft(2, '0');

    String finalPayload = '*$payloadStr|$crcHex#';

    if (kDebugMode) {
      print('CRC16: $crcHex');
      print('Payload: $finalPayload');
    }
    return finalPayload;
  }

  static String? validatePayloadWithCrc(String incoming) {
    // Split payload and CRC part
    List<String> parts = incoming.split('|');
    if (parts.length != 2) {
      return null; // Invalid format
    }

    String payloadStr = parts[0];
    String receivedCrcHex = parts[1];

    // Compute CRC for payloadStr
    List<int> bytes = payloadStr.codeUnits;
    int crc = 0xFFFF;

    for (int byte in bytes) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc = crc >> 1;
        }
      }
    }

    int crcLow = crc & 0xFF;
    int crcHigh = (crc >> 8) & 0xFF;

    String calculatedCrcHex =
        crcHigh.toRadixString(16).padLeft(2, '0') +
            crcLow.toRadixString(16).padLeft(2, '0');

    // Compare case-insensitively
    if (calculatedCrcHex.toLowerCase() == receivedCrcHex.toLowerCase()) {
      return payloadStr; // Valid CRC, return payload
    } else {
      return null; // CRC mismatch
    }
  }

  static List<Map<String, dynamic>> dataConversionForScheduleView(Map<String, dynamic> payload) {
    List<Map<String, dynamic>> convertedListInside = [];

    print('payload in the data conversion :: $payload');
    if(payload.isNotEmpty) {
      for (int i = 0; i < payload["S_No"].length; i++) {
        Map<String, dynamic> resultDict = {};

        payload.forEach((key, value) {
          resultDict[key] = value[i];
        });

        convertedListInside.add(resultDict);
      }
    }

    print("in the conversion :: $convertedListInside");
    return convertedListInside;
  }

  static Duration parseTime(String timeString) {
    List<String> parts = timeString.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    int seconds = int.parse(parts[2]);
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  static String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitHours = twoDigits(duration.inHours.remainder(24));
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  }

  static String changeFormat(String value) {
    List<String> stringList = value.split(":");
    stringList.removeLast();
    String result = stringList.join(":");
    // print("result string ==> $result");
    return result;
  }

  static String getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  static String getMonthName(int month) {
    switch (month) {
      case DateTime.january:
        return 'January';
      case DateTime.february:
        return 'February';
      case DateTime.march:
        return 'March';
      case DateTime.april:
        return 'April';
      case DateTime.may:
        return 'May';
      case DateTime.june:
        return 'June';
      case DateTime.july:
        return 'July';
      case DateTime.august:
        return 'August';
      case DateTime.september:
        return 'September';
      case DateTime.october:
        return 'October';
      case DateTime.november:
        return 'November';
      case DateTime.december:
        return 'December';
      default:
        return '';
    }
  }

  static List<String> generateScale(Duration highestValue) {
    final int highestValueInMinutes = highestValue.inMinutes;
    const int segmentCount = 3;
    final List<String> scale = [];
    for (var i = 0; i <= segmentCount; i++) {
      final valueInMinutes = (highestValueInMinutes / segmentCount * i).toInt();
      final value = Duration(minutes: valueInMinutes);
      scale.add("${value.inHours.toString().padLeft(2, '0')}:${(value.inMinutes % 60).toString().padLeft(2, '0')}");
    }
    return scale;
  }

  static String capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  static String showHourAndMinuteOnly(String time, int modelId){
    List<String> list = time.split(':');
    return list.length > 1 ? '${list[0]}:${list[1]}${AppConstants.ecoGemModelList.contains(modelId) ? '' :':${list[2]}'}' : time;
  }
}
