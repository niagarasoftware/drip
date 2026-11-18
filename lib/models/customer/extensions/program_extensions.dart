import '../site_model.dart';

extension ProgramListFinder on List<ProgramList> {

  ProgramList? findByProgramId(String programId) {
    final id = int.tryParse(programId);
    if (id == null) return null;
    try {
      return firstWhere((p) => p.serialNumber == id);
    } catch (_) {
      return null;
    }
  }

  String getProgramName(String programId) {
    final program = findByProgramId(programId);
    if (program == null) return "StandAlone - Manual";
    return program.programName.isNotEmpty
        ? program.programName
        : program.defaultProgramName;
  }

  String getSequenceName(String programId, String sequenceId) {
    final program = findByProgramId(programId);
    if (program == null) return '--';
    try {
      return program.sequence.firstWhere((seq) => seq.sNo == sequenceId).name;
    } catch (_) {
      return '--';
    }
  }
}

extension ConfigObjectFinder on List<ConfigObject> {

  ConfigObject? findBySerial(double serial) {
    try {
      return firstWhere((obj) => obj.sNo == serial);
    } catch (_) {
      return null;
    }
  }

  String getObjectName(double serial) {
    final obj = findBySerial(serial);
    if (obj == null) return serial.toInt().toString();
    return obj.name.isNotEmpty ? obj.name
        : serial.toInt().toString();
  }

}