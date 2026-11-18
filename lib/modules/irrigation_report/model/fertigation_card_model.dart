import 'package:flutter/material.dart';

class FertigationChannelModel {
  final String name; // e.g. "C-CH1", "L-CH1"
  final String planned; // e.g. "00:30:00" or "50 Lts"
  final String actual; // e.g. "00:30:00" or "50 Lts"
  final bool isCentral;

  const FertigationChannelModel({
    required this.name,
    required this.planned,
    required this.actual,
    required this.isCentral,
  });
}

class FertigationCardModel {
  final String programName;
  final int programSNo;
  final String sequenceName;
  final String lineName;
  final String status;
  final Color statusColor;
  final String date;
  final String startTime;
  final String stopTime;
  final String startReason;
  final String stopReason;
  final String waterMethod;
  final String waterPlanned;
  final String waterActual;
  final String preMethod;
  final String preTimeQty;
  final String postTimeQty;
  final String centralEc;
  final String centralPh;
  
  // Central EC / pH
  final String centralEcSet;
  final String centralEcMin;
  final String centralEcMax;
  final String centralEcAvg;
  final String centralPhSet;
  final String centralPhMin;
  final String centralPhMax;
  final String centralPhAvg;

  // Local EC / pH
  final String localEcSet;
  final String localEcMin;
  final String localEcMax;
  final String localEcAvg;
  final String localPhSet;
  final String localPhMin;
  final String localPhMax;
  final String localPhAvg;

  final String progress;
  final double progressValue; // 0.0 to 1.0
  final List<FertigationChannelModel> centralChannels;
  final List<FertigationChannelModel> localChannels;

  const FertigationCardModel({
    required this.programName,
    required this.programSNo,
    required this.sequenceName,
    required this.lineName,
    required this.status,
    required this.statusColor,
    required this.date,
    required this.startTime,
    required this.stopTime,
    required this.startReason,
    required this.stopReason,
    required this.waterMethod,
    required this.waterPlanned,
    required this.waterActual,
    required this.preMethod,
    required this.preTimeQty,
    required this.postTimeQty,
    required this.centralEc,
    required this.centralPh,
    required this.centralEcSet,
    required this.centralEcMin,
    required this.centralEcMax,
    required this.centralEcAvg,
    required this.centralPhSet,
    required this.centralPhMin,
    required this.centralPhMax,
    required this.centralPhAvg,
    required this.localEcSet,
    required this.localEcMin,
    required this.localEcMax,
    required this.localEcAvg,
    required this.localPhSet,
    required this.localPhMin,
    required this.localPhMax,
    required this.localPhAvg,
    required this.progress,
    required this.progressValue,
    required this.centralChannels,
    required this.localChannels,
  });
}
