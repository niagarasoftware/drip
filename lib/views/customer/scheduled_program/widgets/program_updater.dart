import '../../../../models/customer/site_model.dart';

class ProgramUpdater {
  static void updateProgramsFromMqtt(
      List<String> spLive,
      List<ProgramList> scheduledPrograms,
      List<String> conditionPayloadList,
      ) {
    for (var sp in spLive) {
      final values = sp.split(",");
      if (values.length > 11) {
        final serialNumber = int.tryParse(values[0].trim());
        if (serialNumber == null) continue;

        final programIndex = scheduledPrograms.indexWhere(
              (program) => program.serialNumber == serialNumber,
        );
        if (programIndex == -1) continue;

        final program = scheduledPrograms[programIndex];

        // --- Program level update ---
        program
          ..startDate = values[3].trim()
          ..startTime = values[4].trim()
          ..endDate = values[5].trim()
          ..programStatusPercentage = int.tryParse(values[6].trim()) ?? 0
          ..startStopReason = int.tryParse(values[7].trim()) ?? 0
          ..pauseResumeReason = int.tryParse(values[8].trim()) ?? 0
          ..prgOnOff = values[10].trim()
          ..prgPauseResume = values[11].trim()
          ..status = 1;

        // --- Condition updates ---
        for (var payload in conditionPayloadList) {
          final parts = payload.split(",");
          if (parts.length > 4) {
            final conditionSerialNo = int.tryParse(parts[0].trim());
            final conditionStatus = int.tryParse(parts[2].trim()) ?? 0;
            final actualValue = parts[4].trim();

            if (conditionSerialNo == null) continue;

            // Find the condition by value.sNo
            final conditionIndex = program.conditions.indexWhere(
                  (c) => c.value.sNo == conditionSerialNo,
            );

            if (conditionIndex != -1) {
              final cond = program.conditions[conditionIndex];
              cond.conditionStatus = conditionStatus;
              cond.value.actualValue = actualValue;

            } else {
              // print("Condition with sNo=$conditionSerialNo not found in program $serialNumber");
            }
          }
        }
      }
    }
  }
}