
import 'package:flutter/material.dart';

import '../model/fertigation_card_model.dart';
import '../view/reason_lookup.dart';

class FertigationCardMapper {
  static List<FertigationCardModel> mapLogData(
      dynamic dataSource,
      List<dynamic> nameData,
      ) {
    if (dataSource is! Map || dataSource['log'] is! List) {
      return [];
    }

    final List<FertigationCardModel> cards = [];

    final logs = dataSource['log'] as List;

    final defaults = dataSource['default'];

    final List<dynamic> programConfig =
    defaults is Map && defaults['program'] is List
        ? defaults['program'] as List
        : [];

    final List<dynamic> sequenceConfig =
    defaults is Map && defaults['sequence'] is List
        ? defaults['sequence'] as List
        : [];

    for (final logEntry in logs) {
      if (logEntry is! Map) continue;

      final rawLogDate =
          logEntry['logDate']?.toString() ?? '';

      final rawIrrigation = logEntry['irrigation'];

      if (rawIrrigation is! Map || rawIrrigation.isEmpty) {
        continue;
      }

      final irrigation =
      Map<String, dynamic>.from(rawIrrigation);

      final recordDates = _asList(irrigation['Date']);

      int baseLength = recordDates.length;

      if (baseLength == 0) {
        for (final value in irrigation.values) {
          if (value is List && value.length > baseLength) {
            baseLength = value.length;
          }
        }
      }

      if (baseLength == 0) continue;

      final programSNos =
      _asList(irrigation['ProgramS_No']);

      final zoneSNos =
      _asList(irrigation['ZoneS_No']);

      final headUnits =
      _asList(irrigation['HeadUnit']);

      final statuses = _asList(
        irrigation['Status'] ?? irrigation['status'],
      );

      final actualStartTimes =
      _asList(irrigation['ActualStartTime']);

      final actualStopTimes =
      _asList(irrigation['ActualEndTime']);

      final actualStartReasons =
      _asList(irrigation['ActualStartReason']);

      final actualStopReasons =
      _asList(irrigation['ActualStopReason']);

      final waterMethods =
      _asList(irrigation['IrrigationMethod']);

      final waterPlannedList = _asList(
        irrigation['IrrigationDuration_Quantity'] ??
            irrigation['IrrigationQuantity_Quantity'],
      );

      final waterActualList = _asList(
        irrigation['IrrigationDurationCompleted'] ??
            irrigation['IrrigationQuantityCompleted'],
      );

      final prePostMethods =
      _asList(irrigation['PrePostMethod']);

      final preTimes = _asList(
        irrigation['Pretime'] ??
            irrigation['Pretime/PreQty'],
      );

      final postTimes = _asList(
        irrigation['PostTime'] ??
            irrigation['PostTime/PostQty'],
      );

      final progressList =
      _asList(irrigation['Progress']);

      final centralFertOnOff =
      _asList(irrigation['CentralFertOnOff']);

      final localFertOnOff = _asList(
        irrigation['LocalFertilizerOnOff'] ??
            irrigation['LocalFertOnOff'],
      );

      for (int i = 0; i < baseLength; i++) {
        // IMPORTANT:
        // Hide irrigation-only records.
        // Show only actual fertilizer execution.
        if (!_hasActualFertilizerRun(irrigation, i)) {
          continue;
        }

        final dateStr = _valueAt(
          recordDates,
          i,
          fallback: rawLogDate,
        );

        int? pSNo;

        final programValue =
        _rawValueAt(programSNos, i);

        final zoneValue =
        _rawValueAt(zoneSNos, i);

        if (programValue != null) {
          pSNo = int.tryParse(programValue.toString());
        }

        if (pSNo == null && zoneValue != null) {
          final parts = zoneValue.toString().split('.');

          if (parts.isNotEmpty) {
            pSNo = int.tryParse(parts.first);
          }
        }

        String progName = '';

        if (pSNo != null) {
          progName = _getProgramName(
            programConfig,
            pSNo,
          );
        }

        if (progName.isEmpty && pSNo != null) {
          progName = 'Program $pSNo';
        }

        if (progName.isEmpty) {
          progName = '—';
        }

        String seqName = '';

        if (zoneValue != null) {
          seqName = _getSequenceName(
            sequenceConfig,
            zoneValue,
          );
        }

        if (seqName.isEmpty || seqName == '-') {
          seqName = zoneValue != null &&
              zoneValue.toString().isNotEmpty
              ? 'Sequence $zoneValue'
              : '—';
        }

        String lineName = '—';

        final headUnit = _rawValueAt(
          headUnits,
          i,
        );

        if (headUnit != null) {
          lineName = _getLineName(
            nameData,
            headUnit,
          );
        }

        if (lineName == '—' || lineName.isEmpty) {
          final programCategories = _asList(
            irrigation['ProgramCategoryName'] ??
                irrigation['ProgramCategory'],
          );

          final category = _rawValueAt(
            programCategories,
            i,
          );

          if (category != null) {
            lineName = _getLineName(
              nameData,
              category,
            );
          }
        }

        if (lineName.isEmpty) {
          lineName = '—';
        }

        final rawStatus =
        _rawValueAt(statuses, i);

        final statusMap = getStatus(rawStatus);

        final String statusStr =
            statusMap['status']?.toString() ??
                rawStatus?.toString() ??
                '—';

        final Color statusColor =
        statusMap['color'] is Color
            ? statusMap['color'] as Color
            : Colors.grey;

        final startTime = _valueAt(
          actualStartTimes,
          i,
        );

        final stopTime = _valueAt(
          actualStopTimes,
          i,
        );

        final startReason = _getReason(
          _rawValueAt(actualStartReasons, i),
        );

        final stopReason = _getReason(
          _rawValueAt(actualStopReasons, i),
        );

        final waterMethod = _getMethod(
          _rawValueAt(waterMethods, i),
        );

        final waterPlanned = _valueAt(
          waterPlannedList,
          i,
        );

        final waterActual = _valueAt(
          waterActualList,
          i,
        );

        final preMethod = _getMethod(
          _rawValueAt(prePostMethods, i),
        );

        final preTimeQty = _valueAt(
          preTimes,
          i,
        );

        final postTimeQty = _valueAt(
          postTimes,
          i,
        );

        // CENTRAL EC
        final centralEcSet = _extractVal(
          irrigation['CentralEcSetValue'],
          i,
        );

        final centralEcMin = _extractVal(
          irrigation['CentralEcMinimum'],
          i,
        );

        final centralEcMax = _extractVal(
          irrigation['CentralEcMaximum'],
          i,
        );

        final centralEcAvg = _extractVal(
          irrigation['CentralEcAverage'] ??
              irrigation['CentralEc'],
          i,
        );

        // CENTRAL PH
        final centralPhSet = _extractVal(
          irrigation['CentralPhSetValue'],
          i,
        );

        final centralPhMin = _extractVal(
          irrigation['CentralPhMinimum'],
          i,
        );

        final centralPhMax = _extractVal(
          irrigation['CentralPhMaximum'],
          i,
        );

        final centralPhAvg = _extractVal(
          irrigation['CentralPhAverage'] ??
              irrigation['CentralPh'],
          i,
        );

        // LOCAL EC
        final localEcSet = _extractVal(
          irrigation['LocalEcSetValue'],
          i,
        );

        final localEcMin = _extractVal(
          irrigation['LocalEcMinimum'],
          i,
        );

        final localEcMax = _extractVal(
          irrigation['LocalEcMaximum'],
          i,
        );

        final localEcAvg = _extractVal(
          irrigation['LocalEcAverage'] ??
              irrigation['LocalEc'],
          i,
        );

        // LOCAL PH
        final localPhSet = _extractVal(
          irrigation['LocalPhSetValue'],
          i,
        );

        final localPhMin = _extractVal(
          irrigation['LocalPhMinimum'],
          i,
        );

        final localPhMax = _extractVal(
          irrigation['LocalPhMaximum'],
          i,
        );

        final localPhAvg = _extractVal(
          irrigation['LocalPhAverage'] ??
              irrigation['LocalPh'],
          i,
        );

        final centralEc =
        centralEcAvg != '—'
            ? centralEcAvg
            : centralEcSet;

        final centralPh =
        centralPhAvg != '—'
            ? centralPhAvg
            : centralPhSet;

        final progress = _valueAt(
          progressList,
          i,
          fallback: '100%',
        );

        final parsedProgress = double.tryParse(
          progress.replaceAll('%', '').trim(),
        ) ??
            100.0;

        final progressValue =
        (parsedProgress / 100.0)
            .clamp(0.0, 1.0)
            .toDouble();

        final isCentralOn = _isEnabled(
          _rawValueAt(centralFertOnOff, i),
        );

        final isLocalOn = _isEnabled(
          _rawValueAt(localFertOnOff, i),
        );

        // Show only executed fertilizer channels.
        final centralChannels = isCentralOn
            ? _buildChannels(
          irrigation: irrigation,
          recordIndex: i,
          isCentral: true,
        )
            : <FertigationChannelModel>[];

        final localChannels = isLocalOn
            ? _buildChannels(
          irrigation: irrigation,
          recordIndex: i,
          isCentral: false,
        )
            : <FertigationChannelModel>[];

        // Record already passed the execution filter.
        // Keep the existing card structure unchanged.
        cards.add(
          FertigationCardModel(
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
          ),
        );
      }
    }

    return cards;
  }

  // --------------------------------------------------
  // ACTUAL FERTILIZER EXECUTION FILTER
  // --------------------------------------------------

  static bool _hasActualFertilizerRun(
      Map<String, dynamic> irrigation,
      int index,
      ) {
    const fields = [
      'CentralFertilizerChannelDurationCompleted',
      'CentralFertilizerChannelQuantityCompleted',
      'LocalFertilizerChannelDurationCompleted',
      'LocalFertilizerChannelQuantityCompleted',
    ];

    for (final fieldName in fields) {
      final values = irrigation[fieldName];

      if (values is! List ||
          index < 0 ||
          index >= values.length) {
        continue;
      }

      final recordValue = values[index];

      if (recordValue == null) continue;

      final channelValues =
      recordValue.toString().split('_');

      for (final value in channelValues) {
        if (_isPositiveValue(value)) {
          return true;
        }
      }
    }

    return false;
  }

  // --------------------------------------------------
  // CHECK POSITIVE DURATION OR QUANTITY
  // --------------------------------------------------

  static bool _isPositiveValue(String value) {
    final clean = value.trim().toLowerCase();

    if (clean.isEmpty ||
        clean == 'null' ||
        clean == '—' ||
        clean == '-') {
      return false;
    }

    if (clean.contains(':')) {
      final parts = clean.split(':');

      if (parts.length != 3) return false;

      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);
      final seconds = double.tryParse(parts[2]);

      if (hours == null ||
          minutes == null ||
          seconds == null ||
          hours < 0 ||
          minutes < 0 ||
          minutes >= 60 ||
          seconds < 0 ||
          seconds >= 60) {
        return false;
      }

      return hours > 0 ||
          minutes > 0 ||
          seconds > 0;
    }

    final quantity = double.tryParse(clean);

    return quantity != null &&
        quantity.isFinite &&
        quantity > 0;
  }

  // --------------------------------------------------
  // BUILD EXECUTED FERTILIZER CHANNELS
  // --------------------------------------------------

  static List<FertigationChannelModel> _buildChannels({
    required Map<String, dynamic> irrigation,
    required int recordIndex,
    required bool isCentral,
  }) {
    final prefix = isCentral
        ? 'CentralFertilizerChannel'
        : 'LocalFertilizerChannel';

    final durationPlanned = _channelParts(
      irrigation['${prefix}Duration'],
      recordIndex,
    );

    final quantityPlanned = _channelParts(
      irrigation['${prefix}Quantity'],
      recordIndex,
    );

    final durationActual = _channelParts(
      irrigation['${prefix}DurationCompleted'],
      recordIndex,
    );

    final quantityActual = _channelParts(
      irrigation['${prefix}QuantityCompleted'],
      recordIndex,
    );

    final names = _channelParts(
      isCentral
          ? irrigation['CentralFertChannelName']
          : irrigation['LocalFertChannelName'] ??
          irrigation['LocalFertilizerChannelName'],
      recordIndex,
    );

    final List<FertigationChannelModel> result = [];

    for (int ch = 0; ch < 8; ch++) {
      final duration = _partAt(durationActual, ch);
      final quantity = _partAt(quantityActual, ch);

      final hasDuration = _isPositiveValue(duration);
      final hasQuantity = _isPositiveValue(quantity);

      // Hide channels that did not execute.
      if (!hasDuration && !hasQuantity) {
        continue;
      }

      final planned = hasDuration
          ? _partAt(durationPlanned, ch)
          : _partAt(quantityPlanned, ch);

      final actual = hasDuration
          ? duration
          : quantity;

      final rawName = _partAt(names, ch);

      final name = rawName.isNotEmpty &&
          rawName.toLowerCase() != 'null'
          ? rawName
          : '${isCentral ? 'C' : 'L'}-CH${ch + 1}';

      result.add(
        FertigationChannelModel(
          name: name,
          planned: planned.isEmpty ? '—' : planned,
          actual: actual.isEmpty ? '—' : actual,
          isCentral: isCentral,
        ),
      );
    }

    return result;
  }

  static List<String> _channelParts(
      dynamic field,
      int index,
      ) {
    if (field is! List ||
        index < 0 ||
        index >= field.length ||
        field[index] == null) {
      return [];
    }

    return field[index]
        .toString()
        .split('_')
        .map((value) => value.trim())
        .toList();
  }

  static String _partAt(
      List<String> values,
      int index,
      ) {
    if (index < 0 || index >= values.length) {
      return '';
    }

    return values[index];
  }

  // --------------------------------------------------
  // GENERAL HELPERS
  // --------------------------------------------------

  static List<dynamic> _asList(dynamic value) {
    return value is List ? value : [];
  }

  static dynamic _rawValueAt(
      List<dynamic> values,
      int index,
      ) {
    if (index < 0 || index >= values.length) {
      return null;
    }

    return values[index];
  }

  static String _valueAt(
      List<dynamic> values,
      int index, {
        String fallback = '—',
      }) {
    final value = _rawValueAt(values, index);

    if (value == null) return fallback;

    final result = value.toString().trim();

    if (result.isEmpty ||
        result.toLowerCase() == 'null') {
      return fallback;
    }

    return result;
  }

  static String _extractVal(
      dynamic field,
      int index,
      ) {
    if (field == null) return '—';

    if (field is List) {
      return _valueAt(field, index);
    }

    final value = field.toString().trim();

    if (value.isEmpty ||
        value.toLowerCase() == 'null') {
      return '—';
    }

    return value;
  }

  static bool _isEnabled(dynamic value) {
    if (value == null) return true;

    final text = value.toString().trim().toLowerCase();

    return text != '0' && text != 'false';
  }

  static String _getMethod(dynamic value) {
    if (value == null) return '—';

    final code = int.tryParse(value.toString());

    if (code == 1) return 'Time';
    if (code == 2) return 'Quantity (L)';

    return value.toString();
  }

  static String _getReason(dynamic value) {
    if (value == null) return '—';

    final code = int.tryParse(value.toString());

    return code != null
        ? programStartStopReason(code: code)
        : value.toString();
  }

  // --------------------------------------------------
  // PROGRAM NAME
  // --------------------------------------------------

  static String _getProgramName(
      List<dynamic> programList,
      int sNo,
      ) {
    for (final program in programList) {
      if (program is! Map) continue;

      final number = int.tryParse(
        (program['sNo'] ??
            program['programSNo'] ??
            '')
            .toString(),
      );

      if (number == sNo) {
        return (program['name'] ??
            program['programName'] ??
            '')
            .toString();
      }
    }

    return '';
  }

  // --------------------------------------------------
  // SEQUENCE NAME
  // --------------------------------------------------

  static String _getSequenceName(
      List<dynamic> sequenceList,
      dynamic sNo,
      ) {
    if (sNo == null) return '—';

    final target = sNo.toString();

    for (final sequence in sequenceList) {
      if (sequence is! Map) continue;

      final sequenceNo =
      sequence['sNo']?.toString();

      final sequenceId =
      sequence['id']?.toString();

      if (sequenceNo == target ||
          sequenceId == target) {
        return (sequence['name'] ?? '').toString();
      }
    }

    return target;
  }

  // --------------------------------------------------
  // LINE NAME
  // --------------------------------------------------

  static String _getLineName(
      List<dynamic> nameData,
      dynamic sNo,
      ) {
    if (sNo == null) return '—';

    final target = sNo.toString().trim();

    if (target.isEmpty || target == '-') {
      return '—';
    }

    for (final item in nameData) {
      if (item is! Map) continue;

      final itemSNo = (
          item['sNo'] ??
              item['id'] ??
              item['serialNo'] ??
              ''
      ).toString();

      if (itemSNo == target) {
        final name = (
            item['name'] ??
                item['lineName'] ??
                item['headUnitName'] ??
                ''
        ).toString();

        if (name.isNotEmpty) {
          return name;
        }
      }
    }

    return target;
  }
}
