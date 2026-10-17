import 'package:flutter/material.dart';
import '../model/fertigation_card_model.dart';
import '../view/reason_lookup.dart';

class FertigationCardMapper {
  static List<FertigationCardModel> mapLogData(dynamic dataSource, List<dynamic> nameData) {
    if (dataSource == null || dataSource['log'] == null) {
      return [];
    }

    List<FertigationCardModel> cards = [];
    List logs = dataSource['log'];
    Map<int, String> programMap = {};
    if (dataSource['default'] != null && dataSource['default']['program'] != null) {
      for (var prog in dataSource['default']['program']) {
        if (prog['programSNo'] != null && prog['programName'] != null) {
          int sNo = int.tryParse(prog['programSNo'].toString()) ?? 0;
          programMap[sNo] = prog['programName'].toString();
        }
      }
    }

    Map<String, String> sequenceMap = {};
    if (dataSource['default'] != null && dataSource['default']['sequence'] != null) {
      for (var seq in dataSource['default']['sequence']) {
        if (seq['zoneSNo'] != null && seq['zoneName'] != null) {
          sequenceMap[seq['zoneSNo'].toString()] = seq['zoneName'].toString();
        }
      }
    }

    for (var logEntry in logs) {
      String rawLogDate = logEntry['logDate'] ?? '';
      var irrigation = logEntry['irrigation'];
      if (irrigation == null) continue;

      List recordDates = irrigation['Date'] ?? [];
      List programSNos = irrigation['ProgramS_No'] ?? [];
      List zoneSNos = irrigation['ZoneS_No'] ?? [];
      List headUnits = irrigation['HeadUnit'] ?? [];
      List statuses = irrigation['Status'] ?? [];
      List actualStartTimes = irrigation['ActualStartTime'] ?? [];
      List actualStopTimes = irrigation['ActualEndTime'] ?? [];
      List actualStartReasons = irrigation['ActualStartReason'] ?? [];
      List actualStopReasons = irrigation['ActualStopReason'] ?? [];
      List waterMethods = irrigation['IrrigationMethod'] ?? [];
      List waterPlannedList = irrigation['IrrigationDuration_Quantity'] ?? irrigation['IrrigationQuantity_Quantity'] ?? [];
      List waterActualList = irrigation['IrrigationDurationCompleted'] ?? irrigation['IrrigationQuantityCompleted'] ?? [];
      List prePostMethods = irrigation['PrePostMethod'] ?? [];
      List preTimes = irrigation['Pretime/PreQty'] ?? [];
      List postTimes = irrigation['PostTime/PostQty'] ?? [];
      List centralPhList = irrigation['CentralPhSetValue'] ?? irrigation['CentralPh'] ?? [];
      List centralEcList = irrigation['CentralEcSetValue'] ?? irrigation['CentralEc'] ?? [];
      List progressList = irrigation['Progress'] ?? [];

      int baseLength = [
        recordDates.length,
        programSNos.length,
        zoneSNos.length,
        headUnits.length,
        statuses.length,
        actualStartTimes.length,
        actualStopTimes.length,
      ].fold(0, (max, len) => len > max ? len : max);

      if (baseLength == 0) {
        baseLength = 1;
      }

      for (int i = 0; i < baseLength; i++) {
        String dateStr = (i < recordDates.length && recordDates[i] != null) ? recordDates.toString() : rawLogDate;

        int pSNo = 1;
        if (i < programSNos.length && programSNos[i] != null) {
          pSNo = programSNos[i] is int ? programSNos[i] : int.tryParse(programSNos[i].toString()) ?? 1;
        } else if (i < zoneSNos.length && zoneSNos[i] != null) {
          var parts = zoneSNos[i].toString().split('.');
          if (parts.isNotEmpty) {
            pSNo = int.tryParse(parts[0]) ?? 1;
          }
        }

        String progName = programMap[pSNo] ?? 'Program $pSNo';

        String zVal = (i < zoneSNos.length && zoneSNos[i] != null) ? zoneSNos[i].toString() : '';
        String seqName = sequenceMap[zVal] ?? (zVal.isNotEmpty ? 'Sequence $zVal' : 'Sequence 1');
        String lineName = (i < headUnits.length && headUnits[i] != null) ? headUnits[i].toString() : 'Head Unit 1';

        int statusCode = 1;
        if (i < statuses.length && statuses[i] != null) {
          statusCode = int.tryParse(statuses[i].toString()) ?? 1;
        }
        var statusMap = getStatus(statusCode);
        String statusStr = statusMap['status'] ?? 'Running';
        Color statusColor = statusMap['color'] ?? Colors.orange;

        String startTime = (i < actualStartTimes.length && actualStartTimes[i] != null) ? actualStartTimes[i].toString() : '-';
        String stopTime = (i < actualStopTimes.length && actualStopTimes[i] != null) ? actualStopTimes[i].toString() : '-';

        int startReasonCode = 1;
        if (i < actualStartReasons.length && actualStartReasons[i] != null) {
          startReasonCode = int.tryParse(actualStartReasons[i].toString()) ?? 1;
        }
        String startReason = programStartStopReason(code: startReasonCode);

        int stopReasonCode = 20;
        if (i < actualStopReasons.length && actualStopReasons[i] != null) {
          stopReasonCode = int.tryParse(actualStopReasons[i].toString()) ?? 20;
        }
        String stopReason = programStartStopReason(code: stopReasonCode);

        String waterMethod = (i < waterMethods.length && waterMethods[i] != null) ? waterMethods[i].toString() : 'Time';
        String waterPlanned = (i < waterPlannedList.length && waterPlannedList[i] != null) ? waterPlannedList[i].toString() : '00:30:00';
        String waterActual = (i < waterActualList.length && waterActualList[i] != null) ? waterActualList[i].toString() : '00:30:00';

        String preMethod = (i < prePostMethods.length && prePostMethods[i] != null) ? prePostMethods[i].toString() : 'None';
        String preTimeQty = (i < preTimes.length && preTimes[i] != null) ? preTimes[i].toString() : '0m';
        String postTimeQty = (i < postTimes.length && postTimes[i] != null) ? postTimes[i].toString() : '0m';

        String centralPh = (i < centralPhList.length && centralPhList[i] != null) ? centralPhList[i].toString() : '6.5';
        String centralEc = (i < centralEcList.length && centralEcList[i] != null) ? centralEcList[i].toString() : '1.2';

        String progress = (i < progressList.length && progressList[i] != null) ? progressList[i].toString() : '100%';
        double progressValue = 1.0;
        try {
          String cleanProg = progress.replaceAll('%', '').trim();
          progressValue = (double.tryParse(cleanProg) ?? 100.0) / 100.0;
          if (progressValue > 1.0) progressValue = 1.0;
          if (progressValue < 0.0) progressValue = 0.0;
        } catch (_) {}

        List<FertigationChannelModel> centralChannels = [];
        for (int ch = 1; ch <= 8; ch++) {
          var pVal = irrigation['CentralFertilizerChannelDuration'] ?? irrigation['CentralFertilizerChannelQuantity'];
          var aVal = irrigation['CentralFertilizerChannelDurationCompleted'] ?? irrigation['CentralFertilizerChannelQuantityCompleted'];

          String plannedStr = '00:10:00';
          String actualStr = '00:10:00';

          if (pVal is List && i < pVal.length && pVal[i] != null) {
            plannedStr = pVal[i].toString();
          } else if (pVal != null) {
            plannedStr = pVal.toString();
          }

          if (aVal is List && i < aVal.length && aVal[i] != null) {
            actualStr = aVal[i].toString();
          } else if (aVal != null) {
            actualStr = aVal.toString();
          }

          centralChannels.add(FertigationChannelModel(
            name: 'C-CH$ch',
            planned: plannedStr,
            actual: actualStr,
            isCentral: true,
          ));
        }

        List<FertigationChannelModel> localChannels = [];
        for (int ch = 1; ch <= 8; ch++) {
          var pVal = irrigation['LocalFertilizerChannelDuration'] ?? irrigation['LocalFertilizerChannelQuantity'];
          var aVal = irrigation['LocalFertilizerChannelDurationCompleted'] ?? irrigation['LocalFertilizerChannelQuantityCompleted'];

          String plannedStr = '00:05:00';
          String actualStr = '00:05:00';

          if (pVal is List && i < pVal.length && pVal[i] != null) {
            plannedStr = pVal[i].toString();
          }
          if (aVal is List && i < aVal.length && aVal[i] != null) {
            actualStr = aVal[i].toString();
          }

          localChannels.add(FertigationChannelModel(
            name: 'L-CH$ch',
            planned: plannedStr,
            actual: actualStr,
            isCentral: false,
          ));
        }

        cards.add(FertigationCardModel(
          programName: progName,
          programSNo: pSNo,
          sequenceName: seqName,
          lineName: lineName,
          status: statusStr,
          statusColor: statusColor,
          date: dateStr,
          startTime: startTime,
          stopTime: stopTime,
          startReason: startReason,
          stopReason: stopReason,
          waterMethod: waterMethod,
          waterPlanned: waterPlanned,
          waterActual: waterActual,
          preMethod: preMethod,
          preTimeQty: preTimeQty,
          postTimeQty: postTimeQty,
          centralEc: centralEc,
          centralPh: centralPh,
          progress: progress,
          progressValue: progressValue,
          centralChannels: centralChannels,
          localChannels: localChannels,
        ));
      }
    }

    if (cards.isEmpty) {
      cards.add(FertigationCardModel(
        programName: 'Program 1',
        programSNo: 1,
        sequenceName: 'Sequence 1 (Zone 1)',
        lineName: 'Head Unit 1',
        status: 'Completed',
        statusColor: Colors.green,
        date: DateTime.now().toString().split(' ')[0],
        startTime: '08:00:00',
        stopTime: '09:00:00',
        startReason: 'Turned On Manually',
        stopReason: 'Program Completed',
        waterMethod: 'Time',
        waterPlanned: '00:45:00',
        waterActual: '00:45:00',
        preMethod: 'Time',
        preTimeQty: '05:00',
        postTimeQty: '05:00',
        centralEc: '1.4',
        centralPh: '6.8',
        progress: '100%',
        progressValue: 1.0,
        centralChannels: [
          for (int c = 1; c <= 8; c++)
            FertigationChannelModel(name: 'C-CH$c', planned: '00:10:00', actual: '00:10:00', isCentral: true),
        ],
        localChannels: [
          for (int c = 1; c <= 8; c++)
            FertigationChannelModel(name: 'L-CH$c', planned: '00:05:00', actual: '00:05:00', isCentral: false),
        ],
      ));
    }

    return cards;
  }
}
