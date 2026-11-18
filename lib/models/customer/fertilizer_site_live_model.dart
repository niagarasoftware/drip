class TimeValueModel {
  final String time;
  final double value;

  TimeValueModel({
    required this.time,
    required this.value,
  });
}

class FertilizerSiteLiveModel {
  final List<String> _parts;

  FertilizerSiteLiveModel.fromCsv(String csv)
      : _parts = csv.split(',').map((e) => e.trim()).toList();

  String _value(int index) =>
      index < _parts.length ? _parts[index] : "";

  // ---------------- BASIC FIELDS ----------------

  String get sNo => _value(0);
  String get fertilizerChannel => _value(1);
  String get programSNo => _value(2);
  String get zoneSNo => _value(3);
  String get pump => _value(4);
  String get pumpStatus => _value(5);
  String get valve => _value(6);
  String get valveStatus => _value(7);
  String get booster => _value(8);
  String get boosterStatus => _value(9);
  String get pressureIn => _value(10);
  String get pressureInValue => _value(11);
  String get pressureOut => _value(12);
  String get pressureOutValue => _value(13);
  String get waterMeter => _value(14);
  String get waterMeterValue => _value(15);
  String get prePostMethod => _value(16);
  String get preTimeQty => _value(17);
  String get postTimeQty => _value(18);
  String get irrigationMethod => _value(19);
  String get irrigationDurationQty => _value(20);
  String get irrigationDurationCompleted => _value(21);
  String get irrigationQuantityCompleted => _value(22);
  String get valveFlowrate => _value(23);
  String get ecData => _value(24);
  String get phData => _value(25);

  // ---------------- LIST SPLITTERS ----------------

  List<String> get pumpList =>
      pump.isEmpty ? [] : pump.split('_');

  List<String> get pumpStatusList =>
      pumpStatus.isEmpty ? [] : pumpStatus.split('_');

  List<String> get valveList =>
      valve.isEmpty ? [] : valve.split('_');

  List<String> get valveStatusList =>
      valveStatus.isEmpty ? [] : valveStatus.split('_');

  List<String> get fertilizerChannelList =>
      fertilizerChannel.isEmpty
          ? []
          : fertilizerChannel.split('_');

  // ---------------- EC & PH PARSING ----------------

  List<TimeValueModel> get ecDataList =>
      _parseTimeValueData(ecData);

  List<TimeValueModel> get phDataList =>
      _parseTimeValueData(phData);

  List<TimeValueModel> _parseTimeValueData(String raw) {
    if (raw.isEmpty) return [];

    return raw.split('_').map((pair) {
      final parts = pair.split(':');

      if (parts.length != 2) {
        return TimeValueModel(time: "", value: 0.0);
      }

      final formattedTime = _formatTime(parts[0]);
      final value = double.tryParse(parts[1]) ?? 0.0;

      return TimeValueModel(
        time: formattedTime,
        value: value,
      );
    }).toList();
  }

  // ---------------- TIME FORMATTER ----------------
  // Assumes HHmm format (example: 0830 → 08:30)

  String _formatTime(String rawTime) {
    final totalSeconds = int.tryParse(rawTime) ?? 0;

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    //final ss = seconds.toString().padLeft(2, '0');

    return "$hh:$mm";
  }
}

class FertilizerChannelLiveModel {
  final List<String> _parts;

  FertilizerChannelLiveModel.fromCsv(String csv) :
        _parts = csv.split(',').map((e) => e.trim()).toList();
  String _value(int index) => index < _parts.length ? _parts[index] : "";

  List<String> get durationList => fertilizerChannelDuration.isEmpty ? []
          : fertilizerChannelDuration.split('_');

  List<String> get durationCompletedList =>
      fertilizerChannelDurationCompleted.isEmpty ? []
          : fertilizerChannelDurationCompleted.split('_');

  List<String> get quantityList =>
      channelQuantity.isEmpty ? []
          : channelQuantity.split('_');

  List<String> get quantityCompletedList =>
      channelQuantityCompleted.isEmpty ? []
          : channelQuantityCompleted.split('_');

  List<String> get setFlowrateList =>
      setFlowrate.isEmpty ? []
          : setFlowrate.split('_');

  List<String> get actualFlowrateList =>
      actualFlowrate.isEmpty ? []
          : actualFlowrate.split('_');

  String get sNo => _value(0);
  String get frtMethod => _value(1);
  String get fertilizerChannelDuration => _value(2);
  String get fertilizerChannelDurationCompleted => _value(3);
  String get channelQuantity => _value(4);
  String get channelQuantityCompleted => _value(5);
  String get fertilizerChannelOnDuration => _value(6);
  String get fertilizerChannelOffDuration => _value(7);
  String get setFlowrate => _value(8);
  String get actualFlowrate => _value(9);
}

class ChannelDurationBarModel {
  final String channel;
  final double total;
  final double completed;

  ChannelDurationBarModel({
    required this.channel,
    required this.total,
    required this.completed,
  });
}