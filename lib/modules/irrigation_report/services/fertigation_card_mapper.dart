import 'package:flutter/material.dart';
import '../model/fertigation_card_model.dart';
import '../view/reason_lookup.dart';

class FertigationCardMapper {
  static List<FertigationCardModel> mapLogData(dynamic dataSource, List<dynamic> nameData) {
    if (dataSource == null || dataSource is! Map || dataSource['log'] == null) {
      return [];
    }

    List logs = dataSource['log'];
    List<FertigationCardModel> cards = [];
    
    List<dynamic> programConfig = [];
    if (dataSource['default'] != null && dataSource['default']['program'] != null) {
      programConfig = dataSource['default']['program'];
    }

    List<dynamic> sequenceConfig = [];
    if (dataSource['default'] != null && dataSource['default']['sequence'] != null) {
      sequenceConfig = dataSource['default']['sequence'];
    }

    for (var logEntry in logs) {
      String rawLogDate = logEntry['logDate'] ?? '';
      var irrigation = logEntry['irrigation'];
      if (irrigation == null || irrigation is! Map || irrigation.isEmpty) continue;

      List recordDates = irrigation['Date'] ?? [];
      int baseLength = recordDates.isNotEmpty ? recordDates.length : 0;
      if (baseLength == 0) {
        for (var val in irrigation.values) {
          if (val is List && val.length > baseLength) {
            baseLength = val.length;
          }
        }
      }
      if (baseLength == 0) continue;

      List programSNos = irrigation['ProgramS_No'] ?? [];
      List zoneSNos = irrigation['ZoneS_No'] ?? [];
      List headUnits = irrigation['HeadUnit'] ?? [];
      List statuses = irrigation['Status'] ?? irrigation['status'] ?? [];
      List actualStartTimes = irrigation['ActualStartTime'] ?? [];
      List actualStopTimes = irrigation['ActualEndTime'] ?? [];
      List actualStartReasons = irrigation['ActualStartReason'] ?? [];
      List actualStopReasons = irrigation['ActualStopReason'] ?? [];
      List waterMethods = irrigation['IrrigationMethod'] ?? [];
      List waterPlannedList = irrigation['IrrigationDuration_Quantity'] ?? irrigation['IrrigationQuantity_Quantity'] ?? [];
      List waterActualList = irrigation['IrrigationDurationCompleted'] ?? irrigation['IrrigationQuantityCompleted'] ?? [];
      List prePostMethods = irrigation['PrePostMethod'] ?? [];
      List preTimes = irrigation['Pretime'] ?? irrigation['Pretime/PreQty'] ?? [];
      List postTimes = irrigation['PostTime'] ?? irrigation['PostTime/PostQty'] ?? [];
      List progressList = irrigation['Progress'] ?? [];
      List centralFertOnOff = irrigation['CentralFertOnOff'] ?? [];
      List localFertOnOff = irrigation['LocalFertilizerOnOff'] ?? irrigation['LocalFertOnOff'] ?? [];

      for (int i = 0; i < baseLength; i++) {
        String dateStr = (i < recordDates.length && recordDates[i] != null) ? recordDates[i].toString() : rawLogDate;

        int? pSNo;
        if (i < programSNos.length && programSNos[i] != null) {
          pSNo = int.tryParse(programSNos[i].toString());
        } else if (i < zoneSNos.length && zoneSNos[i] != null) {
          var parts = zoneSNos[i].toString().split('.');
          if (parts.isNotEmpty) {
            pSNo = int.tryParse(parts[0]);
          }
        }

        String progName = '';
        if (pSNo != null) {
          progName = _getProgramName(programConfig, pSNo);
        }
        if (progName.isEmpty && pSNo != null) {
          progName = 'Program $pSNo';
        }
        if (progName.isEmpty) {
          progName = '—';
        }

        var zVal = (i < zoneSNos.length && zoneSNos[i] != null) ? zoneSNos[i] : null;
        String seqName = '';
        if (zVal != null) {
          seqName = _getSequenceName(sequenceConfig, zVal);
        }
        if (seqName.isEmpty || seqName == '-') {
          seqName = zVal != null && zVal.toString().isNotEmpty ? 'Sequence $zVal' : '—';
        }

        String lineName = '—';
        List programCategories = irrigation['ProgramCategoryName'] ?? irrigation['ProgramCategory'] ?? irrigation['HeadUnit'] ?? [];
        if (i < programCategories.length && programCategories[i] != null) {
          lineName = programCategories[i].toString();
        }
        if (lineName == '—' || lineName.isEmpty) {
          if (i < headUnits.length && headUnits[i] != null) {
            lineName = headUnits[i].toString();
          }
        }

        var rawStatus = (i < statuses.length) ? statuses[i] : null;
        var statusMap = getStatus(rawStatus);
        String statusStr = statusMap['status'] ?? (rawStatus?.toString() ?? '—');
        Color statusColor = statusMap['color'] ?? Colors.grey;

        String startTime = (i < actualStartTimes.length && actualStartTimes[i] != null) ? actualStartTimes[i].toString() : '—';
        String stopTime = (i < actualStopTimes.length && actualStopTimes[i] != null) ? actualStopTimes[i].toString() : '—';

        String startReason = '—';
        if (i < actualStartReasons.length && actualStartReasons[i] != null) {
          int? code = int.tryParse(actualStartReasons[i].toString());
          startReason = code != null ? programStartStopReason(code: code) : actualStartReasons[i].toString();
        }

        String stopReason = '—';
        if (i < actualStopReasons.length && actualStopReasons[i] != null) {
          int? code = int.tryParse(actualStopReasons[i].toString());
          stopReason = code != null ? programStartStopReason(code: code) : actualStopReasons[i].toString();
        }

        String waterMethod = '—';
        if (i < waterMethods.length && waterMethods[i] != null) {
          int? mCode = int.tryParse(waterMethods[i].toString());
          waterMethod = mCode == 1 ? 'Time' : (mCode == 2 ? 'Quantity (L)' : waterMethods[i].toString());
        }
        String waterPlanned = (i < waterPlannedList.length && waterPlannedList[i] != null) ? waterPlannedList[i].toString() : '—';
        String waterActual = (i < waterActualList.length && waterActualList[i] != null) ? waterActualList[i].toString() : '—';

        String preMethod = '—';
        if (i < prePostMethods.length && prePostMethods[i] != null) {
          int? pmCode = int.tryParse(prePostMethods[i].toString());
          preMethod = pmCode == 1 ? 'Time' : (pmCode == 2 ? 'Quantity (L)' : prePostMethods[i].toString());
        }
        String preTimeQty = (i < preTimes.length && preTimes[i] != null) ? preTimes[i].toString() : '—';
        String postTimeQty = (i < postTimes.length && postTimes[i] != null) ? postTimes[i].toString() : '—';

        // 16 EC / pH fields (preserving 0, 0.0, 00:00:00, hiding only null/empty)
        String centralEcSet = _extractVal(irrigation['CentralEcSetValue'], i);
        String centralEcMin = _extractVal(irrigation['CentralEcMinimum'], i);
        String centralEcMax = _extractVal(irrigation['CentralEcMaximum'], i);
        String centralEcAvg = _extractVal(irrigation['CentralEcAverage'] ?? irrigation['CentralEc'], i);

        String centralPhSet = _extractVal(irrigation['CentralPhSetValue'], i);
        String centralPhMin = _extractVal(irrigation['CentralPhMinimum'], i);
        String centralPhMax = _extractVal(irrigation['CentralPhMaximum'], i);
        String centralPhAvg = _extractVal(irrigation['CentralPhAverage'] ?? irrigation['CentralPh'], i);

        String localEcSet = _extractVal(irrigation['LocalEcSetValue'], i);
        String localEcMin = _extractVal(irrigation['LocalEcMinimum'], i);
        String localEcMax = _extractVal(irrigation['LocalEcMaximum'], i);
        String localEcAvg = _extractVal(irrigation['LocalEcAverage'] ?? irrigation['LocalEc'], i);

        String localPhSet = _extractVal(irrigation['LocalPhSetValue'], i);
        String localPhMin = _extractVal(irrigation['LocalPhMinimum'], i);
        String localPhMax = _extractVal(irrigation['LocalPhMaximum'], i);
        String localPhAvg = _extractVal(irrigation['LocalPhAverage'] ?? irrigation['LocalPh'], i);

        String centralEc = centralEcAvg != '—' ? centralEcAvg : (centralEcSet != '—' ? centralEcSet : '—');
        String centralPh = centralPhAvg != '—' ? centralPhAvg : (centralPhSet != '—' ? centralPhSet : '—');

        String progress = (i < progressList.length && progressList[i] != null) ? progressList[i].toString() : '100%';
        double progressValue = 1.0;
        try {
          String cleanProg = progress.replaceAll('%', '').trim();
          progressValue = (double.tryParse(cleanProg) ?? 100.0) / 100.0;
          if (progressValue > 1.0) progressValue = 1.0;
          if (progressValue < 0.0) progressValue = 0.0;
        } catch (_) {}

        // Check if central fertigation is ON (default true if array missing)
        bool isCentralOn = true;
        if (i < centralFertOnOff.length && centralFertOnOff[i] != null) {
          isCentralOn = centralFertOnOff[i].toString() != '0';
        }

        List<FertigationChannelModel> centralChannels = [];
        if (isCentralOn) {
          var centralDuration = irrigation['CentralFertilizerChannelDuration'] ?? irrigation['CentralFertilizerChannelQuantity'];
          var centralCompleted = irrigation['CentralFertilizerChannelDurationCompleted'] ?? irrigation['CentralFertilizerChannelQuantityCompleted'];
          var centralNames = irrigation['CentralFertChannelName'];

          for (int ch = 1; ch <= 8; ch++) {
            int chIdx = ch - 1;
            String planned = '';
            String actual = '';
            String name = 'C-CH$ch';

            if (centralNames is List && i < centralNames.length && centralNames[i] != null) {
              var nameParts = centralNames[i].toString().split('_');
              if (chIdx < nameParts.length && nameParts[chIdx].isNotEmpty && nameParts[chIdx] != 'null') {
                name = nameParts[chIdx];
              }
            }

            if (centralDuration is List && i < centralDuration.length && centralDuration[i] != null) {
              var parts = centralDuration[i].toString().split('_');
              if (chIdx < parts.length) planned = parts[chIdx];
            } else if (centralDuration != null && ch == 1) {
              planned = centralDuration.toString();
            }

            if (centralCompleted is List && i < centralCompleted.length && centralCompleted[i] != null) {
              var parts = centralCompleted[i].toString().split('_');
              if (chIdx < parts.length) actual = parts[chIdx];
            } else if (centralCompleted != null && ch == 1) {
              actual = centralCompleted.toString();
            }

            bool isPlannedNull = planned.isEmpty || planned.toLowerCase() == 'null';
            bool isActualNull = actual.isEmpty || actual.toLowerCase() == 'null';

            if (!isPlannedNull || !isActualNull) {
              centralChannels.add(FertigationChannelModel(
                name: name,
                planned: isPlannedNull ? '—' : planned,
                actual: isActualNull ? '—' : actual,
                isCentral: true,
              ));
            }
          }
        }

        // Check if local fertigation is ON
        bool isLocalOn = true;
        if (i < localFertOnOff.length && localFertOnOff[i] != null) {
          isLocalOn = localFertOnOff[i].toString() != '0';
        }

        List<FertigationChannelModel> localChannels = [];
        if (isLocalOn) {
          var localDuration = irrigation['LocalFertilizerChannelDuration'] ?? irrigation['LocalFertilizerChannelQuantity'];
          var localCompleted = irrigation['LocalFertilizerChannelDurationCompleted'] ?? irrigation['LocalFertilizerChannelQuantityCompleted'];
          var localNames = irrigation['LocalFertChannelName'] ?? irrigation['LocalFertilizerChannelName'];

          for (int ch = 1; ch <= 8; ch++) {
            int chIdx = ch - 1;
            String planned = '';
            String actual = '';
            String name = 'L-CH$ch';

            if (localNames is List && i < localNames.length && localNames[i] != null) {
              var nameParts = localNames[i].toString().split('_');
              if (chIdx < nameParts.length && nameParts[chIdx].isNotEmpty && nameParts[chIdx] != 'null') {
                name = nameParts[chIdx];
              }
            }

            if (localDuration is List && i < localDuration.length && localDuration[i] != null) {
              var parts = localDuration[i].toString().split('_');
              if (chIdx < parts.length) planned = parts[chIdx];
            } else if (localDuration != null && ch == 1) {
              planned = localDuration.toString();
            }

            if (localCompleted is List && i < localCompleted.length && localCompleted[i] != null) {
              var parts = localCompleted[i].toString().split('_');
              if (chIdx < parts.length) actual = parts[chIdx];
            } else if (localCompleted != null && ch == 1) {
              actual = localCompleted.toString();
            }

            bool isPlannedNull = planned.isEmpty || planned.toLowerCase() == 'null';
            bool isActualNull = actual.isEmpty || actual.toLowerCase() == 'null';

            if (!isPlannedNull || !isActualNull) {
              localChannels.add(FertigationChannelModel(
                name: name,
                planned: isPlannedNull ? '—' : planned,
                actual: isActualNull ? '—' : actual,
                isCentral: false,
              ));
            }
          }
        }

        cards.add(FertigationCardModel(
          programName: progName,
          programSNo: pSNo ?? 1,
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
          centralEcSet: centralEcSet,
          centralEcMin: centralEcMin,
          centralEcMax: centralEcMax,
          centralEcAvg: centralEcAvg,
          centralPhSet: centralPhSet,
          centralPhMin: centralPhMin,
          centralPhMax: centralPhMax,
          centralPhAvg: centralPhAvg,
          localEcSet: localEcSet,
          localEcMin: localEcMin,
          localEcMax: localEcMax,
          localEcAvg: localEcAvg,
          localPhSet: localPhSet,
          localPhMin: localPhMin,
          localPhMax: localPhMax,
          localPhAvg: localPhAvg,
          progress: progress,
          progressValue: progressValue,
          centralChannels: centralChannels,
          localChannels: localChannels,
        ));
      }
    }

    return cards;
  }

  static String _extractVal(dynamic field, int i) {
    if (field == null) return '—';
    if (field is List) {
      if (i < field.length && field[i] != null) {
        String val = field[i].toString().trim();
        if (val.toLowerCase() == 'null' || val.isEmpty) return '—';
        return val;
      }
      return '—';
    }
    String val = field.toString().trim();
    if (val.toLowerCase() == 'null' || val.isEmpty) return '—';
    return val;
  }

  static String _getProgramName(List<dynamic> programList, int sNo) {
    for (var prog in programList) {
      int? progSNo = int.tryParse((prog['sNo'] ?? prog['programSNo'] ?? '').toString());
      if (progSNo != null && progSNo == sNo) {
        return (prog['name'] ?? prog['programName'] ?? '').toString();
      }
    }
    return '';
  }

  static String _getSequenceName(List<dynamic> sequenceList, dynamic sNo) {
    if (sNo == null) return '—';
    for (var seq in sequenceList) {
      if (seq['sNo'].toString() == sNo.toString() || seq['id'].toString() == sNo.toString()) {
        return (seq['name'] ?? '').toString();
      }
    }
    return sNo.toString();
  }
}
