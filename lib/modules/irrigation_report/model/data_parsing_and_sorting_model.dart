import 'package:flutter/material.dart';
import '../../../Constants/data_convertion.dart';
import '../view/reason_lookup.dart';
import 'general_parameter_model.dart';

String formatSingleTime(dynamic raw) {
  if (raw == null) return '-';
  var text = raw.toString().trim();
  if (text.isEmpty || text == '-') return '-';
  var parts = text.split(':');
  if (parts.length < 2) return text;
  int? hour = int.tryParse(parts[0]);
  int? minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return text;
  var second = parts.length > 2 ? parts[2] : null;
  var suffix = hour >= 12 ? 'PM' : 'AM';
  var hour12 = hour % 12;
  if (hour12 == 0) hour12 = 12;
  var minuteStr = minute.toString().padLeft(2, '0');
  return second != null
      ? '$hour12:$minuteStr:$second $suffix'
      : '$hour12:$minuteStr $suffix';
}

String formatMultiTime(dynamic val) {
  if (val == null || val.toString().trim().isEmpty || val.toString() == '-') {
    return '-';
  }
  return val.toString().split('_').map(formatSingleTime).join('\n');
}

String formatMultiReason(dynamic val) {
  if (val == null || val.toString().trim().isEmpty || val.toString() == '-') {
    return '-';
  }
  List<String> parts = val.toString().split('_');
  List<String> formatted = parts.map((part) {
    if (part == '-' || part.trim().isEmpty) return '-';
    int? code = int.tryParse(part.trim());
    if (code != null) {
      return programStartStopReason(code: code);
    }
    return part;
  }).toList();
  return formatted.join('\n');
}

Map<String, dynamic> mergeDefaultLogParameters(dynamic incoming) {
  Map<String, dynamic> defaults = {
    'general' : {
      'ProgramName' : ['Program',true,1],
      'Status' : ['Status',true,1],
      'ZoneS_No' : ['Sequence',true,1],
      'SequenceData' : ['Valves',true,1],
      'Date' : ['Date',true,1],
      'ProgramCategoryName' : ['Line',true,1],
      'ActualStartTime' : ['Actual Start Time',true,1],
      'ActualEndTime' : ['Actual End Time',true,1],
      'ActualStartReason' : ['Actual Start Reason',true,1],
      'ActualStopReason' : ['Actual Stop Reason',true,1],
      'Pump' : ['Pump',true,1],
      'ScheduledStartTime' : ['Start Time',false,1],
      'overAll' : ['over all',true,1],
    },
    'irrigation' : {
      'IrrigationMethod' : ['Method',true,2],
      'IrrigationDuration_Quantity' : ['Planned',true,2],
      'IrrigationDurationCompleted/IrrigationQuantityCompleted' : ['Actual',true,2],
      'overAll' : ['over all',true,1]
    },
    'prePost' : {
      'PrePostMethod' : ['Method',true,2],
      'Pretime/PreQty' : ['Pre',true,2],
      'PostTime/PostQty' : ['Post',true,2],
      'overAll' : ['over all',true,1]
    },
    'centralEcPh' : {
      'CentralPhSetValue' : ['Central Ph Avg',true,3],
      'CentralEcSetValue' : ['Central Ec Avg',true,3],
      'overAll' : ['over all',true,1]
    },
    '<C - CH1>' : {
      'CentralFertChannelName' : ['Channel1 Name',true,3],
      'CentralFertMethod' : ['Method',true,3],
      'CentralFertilizerChannelDuration/CentralFertilizerChannelQuantity' : ['Planned',true,3],
      'CentralFertilizerChannelDurationCompleted/CentralFertilizerChannelQuantityCompleted' : ['Actual',true,3],
      'overAll' : ['over all',true,1]
    },
    '<C - CH2>' : {
      'CentralFertChannelName' : ['Channel2 Name',true,3],
      'CentralFertMethod' : ['Method',true,3],
      'CentralFertilizerChannelDuration/CentralFertilizerChannelQuantity' : ['Planned',true,3],
      'CentralFertilizerChannelDurationCompleted/CentralFertilizerChannelQuantityCompleted' : ['Actual',true,3],
      'overAll' : ['over all',true,1]
    },
    '<C - CH3>' : {
      'CentralFertChannelName' : ['Channel3 Name',true,3],
      'CentralFertMethod' : ['Method',true,3],
      'CentralFertilizerChannelDuration/CentralFertilizerChannelQuantity' : ['Planned',true,3],
      'CentralFertilizerChannelDurationCompleted/CentralFertilizerChannelQuantityCompleted' : ['Actual',true,3],
      'overAll' : ['over all',true,1]
    },
    '<C - CH4>' : {
      'CentralFertChannelName' : ['Channel4 Name',true,3],
      'CentralFertMethod' : ['Method',true,3],
      'CentralFertilizerChannelDuration/CentralFertilizerChannelQuantity' : ['Planned',true,3],
      'CentralFertilizerChannelDurationCompleted/CentralFertilizerChannelQuantityCompleted' : ['Actual',true,3],
      'overAll' : ['over all',true,1]
    },
    '<C - CH5>' : {
      'CentralFertChannelName' : ['Channel5 Name',true,3],
      'CentralFertMethod' : ['Method',true,3],
      'CentralFertilizerChannelDuration/CentralFertilizerChannelQuantity' : ['Planned',true,3],
      'CentralFertilizerChannelDurationCompleted/CentralFertilizerChannelQuantityCompleted' : ['Actual',true,3],
      'overAll' : ['over all',true,1]
    },
    '<C - CH6>' : {
      'CentralFertChannelName' : ['Channel6 Name',true,3],
      'CentralFertMethod' : ['Method',true,3],
      'CentralFertilizerChannelDuration/CentralFertilizerChannelQuantity' : ['Planned',true,3],
      'CentralFertilizerChannelDurationCompleted/CentralFertilizerChannelQuantityCompleted' : ['Actual',true,3],
      'overAll' : ['over all',true,1]
    },
    '<C - CH7>' : {
      'CentralFertChannelName' : ['Channel7 Name',true,3],
      'CentralFertMethod' : ['Method',true,3],
      'CentralFertilizerChannelDuration/CentralFertilizerChannelQuantity' : ['Planned',true,3],
      'CentralFertilizerChannelDurationCompleted/CentralFertilizerChannelQuantityCompleted' : ['Actual',true,3],
      'overAll' : ['over all',true,1]
    },
    '<C - CH8>' : {
      'CentralFertChannelName' : ['Channel8 Name',true,3],
      'CentralFertMethod' : ['Method',true,3],
      'CentralFertilizerChannelDuration/CentralFertilizerChannelQuantity' : ['Planned',true,3],
      'CentralFertilizerChannelDurationCompleted/CentralFertilizerChannelQuantityCompleted' : ['Actual',true,3],
      'overAll' : ['over all',true,1]
    },
  };

  if (incoming == null) return defaults;

  Map<String, dynamic> merged = Map<String, dynamic>.from(incoming);
  defaults.forEach((category, paramMap) {
    if (!merged.containsKey(category) || merged[category] == null) {
      merged[category] = Map<String, dynamic>.from(paramMap);
    } else {
      Map<String, dynamic> categoryMap = Map<String, dynamic>.from(merged[category]);
      paramMap.forEach((key, val) {
        if (!categoryMap.containsKey(key)) {
          categoryMap[key] = val;
        }
      });
      merged[category] = categoryMap;
    }
  });

  if (merged['general'] is Map) {
    Map<String, dynamic> genMap = Map<String, dynamic>.from(merged['general']);
    if (genMap.containsKey('ProgramCategory') && genMap.containsKey('ProgramCategoryName')) {
      genMap.remove('ProgramCategory');
    }
    if (genMap.containsKey('SequenceData') && genMap.containsKey('ZoneName')) {
      genMap.remove('ZoneName');
    }
    if (genMap.containsKey('ZoneS_No') && genMap.containsKey('ZoneName')) {
      genMap.remove('ZoneName');
    }
    genMap.remove('ProgramStartStopReason');
    genMap.remove('ProgramPauseResumeReason');
    merged['general'] = _repositionActualTimeColumns(genMap);
  }

  return merged;
}

/// Older saved log configs were created before the "Actual Start/End Time" and
/// "Actual Start/Stop Reason" columns existed, so a plain key-merge just tacks
/// them onto the end of the general column list. This moves them back to sit
/// right where "Start Time" used to be, and hides "Start Time" from the data
/// rows (it stays in the map so it still shows up as a toggle in the column
/// settings list).
Map<String, dynamic> _repositionActualTimeColumns(Map<String, dynamic> generalMap) {
  const preferredOrder = [
    'ProgramName',
    'Status',
    'ProgramCategoryName',
    'ProgramCategory',
    'Date',
    'ZoneS_No',
    'ZoneName',
    'SequenceData',
    'ActualStartTime',
    'ActualEndTime',
    'ActualStartReason',
    'ActualStopReason',
    'Pump',
    'ScheduledStartTime',
    'overAll',
  ];

  Map<String, dynamic> reordered = {};

  for (final key in preferredOrder) {
    if (generalMap.containsKey(key)) {
      if (key == 'ScheduledStartTime') {
        var startTimeVal = generalMap[key] is List ? List.from(generalMap[key]) : generalMap[key];
        if (startTimeVal is List && startTimeVal.length > 1) {
          startTimeVal[1] = false;
        }
        reordered[key] = startTimeVal;
      } else {
        reordered[key] = generalMap[key];
      }
    }
  }

  generalMap.forEach((key, val) {
    if (!reordered.containsKey(key)) {
      reordered[key] = val;
    }
  });

  return reordered;
}

class IrrigationLogModel {
  List<GeneralParameterModel> generalParameterList = [];
  List<GeneralParameterModel> waterParameterList = [];
  List<GeneralParameterModel> prePostParameterList = [];
  List<GeneralParameterModel> filterParameterList = [];
  List<GeneralParameterModel> centralEcPhParameterList = [];
  List<GeneralParameterModel> centralChannel1ParameterList = [];
  List<GeneralParameterModel> centralChannel2ParameterList = [];
  List<GeneralParameterModel> centralChannel3ParameterList = [];
  List<GeneralParameterModel> centralChannel4ParameterList = [];
  List<GeneralParameterModel> centralChannel5ParameterList = [];
  List<GeneralParameterModel> centralChannel6ParameterList = [];
  List<GeneralParameterModel> centralChannel7ParameterList = [];
  List<GeneralParameterModel> centralChannel8ParameterList = [];
  List<GeneralParameterModel> localEcPhParameterList = [];
  List<GeneralParameterModel> localChannel1ParameterList = [];
  List<GeneralParameterModel> localChannel2ParameterList = [];
  List<GeneralParameterModel> localChannel3ParameterList = [];
  List<GeneralParameterModel> localChannel4ParameterList = [];
  List<GeneralParameterModel> localChannel5ParameterList = [];
  List<GeneralParameterModel> localChannel6ParameterList = [];
  List<GeneralParameterModel> localChannel7ParameterList = [];
  List<GeneralParameterModel> localChannel8ParameterList = [];
  List<dynamic> names = [];

  IrrigationLogModel();

  List<GeneralParameterModel> getListOfGeneralParameterModel({required name,required keyList,required data}){
    List<GeneralParameterModel> list = [];
    for(var i in keyList){
      list.add(
          GeneralParameterModel(
              payloadKey: '$i',
              uiKey: '${data[name]['$i'][0]}',
              show: data[name]['$i'][1]
          )
      );
    }
    return list;
  }

  void editParameter(Map<String,dynamic>data){
    if(data.isNotEmpty){
      generalParameterList = getListOfGeneralParameterModel(name: 'general', keyList: data['general'].keys.toList(), data: data);
      waterParameterList = getListOfGeneralParameterModel(name: 'irrigation', keyList: data['irrigation'].keys.toList(), data: data);
      prePostParameterList = getListOfGeneralParameterModel(name: 'prePost', keyList: data['prePost'].keys.toList(), data: data);
      filterParameterList = getListOfGeneralParameterModel(name: 'filter', keyList: data['filter'].keys.toList(), data: data);
      centralEcPhParameterList = getListOfGeneralParameterModel(name: 'centralEcPh', keyList: data['centralEcPh'].keys.toList(), data: data);
      centralChannel1ParameterList = getListOfGeneralParameterModel(name: '<C - CH1>', keyList: data['<C - CH1>'].keys.toList(), data: data);
      centralChannel2ParameterList = getListOfGeneralParameterModel(name: '<C - CH2>', keyList: data['<C - CH2>'].keys.toList(), data: data);
      centralChannel3ParameterList = getListOfGeneralParameterModel(name: '<C - CH3>', keyList: data['<C - CH3>'].keys.toList(), data: data);
      centralChannel4ParameterList = getListOfGeneralParameterModel(name: '<C - CH4>', keyList: data['<C - CH4>'].keys.toList(), data: data);
      centralChannel5ParameterList = getListOfGeneralParameterModel(name: '<C - CH5>', keyList: data['<C - CH5>'].keys.toList(), data: data);
      centralChannel6ParameterList = getListOfGeneralParameterModel(name: '<C - CH6>', keyList: data['<C - CH6>'].keys.toList(), data: data);
      centralChannel7ParameterList = getListOfGeneralParameterModel(name: '<C - CH7>', keyList: data['<C - CH7>'].keys.toList(), data: data);
      centralChannel8ParameterList = getListOfGeneralParameterModel(name: '<C - CH8>', keyList: data['<C - CH8>'].keys.toList(), data: data);
      localEcPhParameterList = getListOfGeneralParameterModel(name: 'localEcPh', keyList: data['localEcPh'].keys.toList(), data: data);
      localChannel1ParameterList = getListOfGeneralParameterModel(name: '<L - CH1>', keyList: data['<L - CH1>'].keys.toList(), data: data);
      localChannel2ParameterList = getListOfGeneralParameterModel(name: '<L - CH2>', keyList: data['<L - CH2>'].keys.toList(), data: data);
      localChannel3ParameterList = getListOfGeneralParameterModel(name: '<L - CH3>', keyList: data['<L - CH3>'].keys.toList(), data: data);
      localChannel4ParameterList = getListOfGeneralParameterModel(name: '<L - CH4>', keyList: data['<L - CH4>'].keys.toList(), data: data);
      localChannel5ParameterList = getListOfGeneralParameterModel(name: '<L - CH5>', keyList: data['<L - CH5>'].keys.toList(), data: data);
      localChannel6ParameterList = getListOfGeneralParameterModel(name: '<L - CH6>', keyList: data['<L - CH6>'].keys.toList(), data: data);
      localChannel7ParameterList = getListOfGeneralParameterModel(name: '<L - CH7>', keyList: data['<L - CH7>'].keys.toList(), data: data);
      localChannel8ParameterList = getListOfGeneralParameterModel(name: '<L - CH8>', keyList: data['<L - CH8>'].keys.toList(), data: data);
    }
  }

  void editName(List<dynamic> nameData){
    names = nameData;
  }

  dynamic toJson(){
    dynamic serverData = {
      'general' : {},
      'irrigation' : {},
      'filter' : {},
      'prePost' : {},
      'centralEcPh' : {},
      '<C - CH1>' : {},
      '<C - CH2>' : {},
      '<C - CH3>' : {},
      '<C - CH4>' : {},
      '<C - CH5>' : {},
      '<C - CH6>' : {},
      '<C - CH7>' : {},
      '<C - CH8>' : {},
      'localEcPh' : {},
      '<L - CH1>' : {},
      '<L - CH2>' : {},
      '<L - CH3>' : {},
      '<L - CH4>' : {},
      '<L - CH5>' : {},
      '<L - CH6>' : {},
      '<L - CH7>' : {},
      '<L - CH8>' : {},
    };

    for(var i in generalParameterList){
      serverData['general'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in waterParameterList){
      serverData['irrigation'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in filterParameterList){
      serverData['filter'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in prePostParameterList){
      serverData['prePost'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in centralEcPhParameterList){
      serverData['centralEcPh'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in centralChannel1ParameterList){
      serverData['<C - CH1>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in centralChannel2ParameterList){
      serverData['<C - CH2>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in centralChannel3ParameterList){
      serverData['<C - CH3>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in centralChannel4ParameterList){
      serverData['<C - CH4>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in centralChannel5ParameterList){
      serverData['<C - CH5>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in centralChannel6ParameterList){
      serverData['<C - CH6>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in centralChannel7ParameterList){
      serverData['<C - CH7>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in centralChannel8ParameterList){
      serverData['<C - CH8>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in localEcPhParameterList){
      serverData['localEcPh'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in localChannel1ParameterList){
      serverData['<L - CH1>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in localChannel2ParameterList){
      serverData['<L - CH2>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in localChannel3ParameterList){
      serverData['<L - CH3>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in localChannel4ParameterList){
      serverData['<L - CH4>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in localChannel5ParameterList){
      serverData['<L - CH5>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in localChannel6ParameterList){
      serverData['<L - CH6>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in localChannel7ParameterList){
      serverData['<L - CH7>'][i.payloadKey] = [i.uiKey,i.show];
    }
    for(var i in localChannel8ParameterList){
      serverData['<L - CH8>'][i.payloadKey] = [i.uiKey,i.show];
    }
    return serverData;
  }

  String calculateTime(double quantity, double flowRate) {
    // Convert flowRate from liters per hour (L/hr) to liters per second (L/s)
    double flowRatePerSecond = flowRate / 3600;

    // Calculate total time in seconds
    int totalSeconds = (quantity / flowRatePerSecond).round();

    // Convert to hours, minutes, and seconds
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '$hours:$minutes:$seconds';
  }

  String calculateTotalTime(List<String> times) {
    int totalHours = 0;
    int totalMinutes = 0;
    int totalSeconds = 0;

    // Loop through each time entry in the list
    for (var time in times) {
      var spitTime = time.split(':');
      totalHours += int.parse(spitTime[0]) ?? 0;
      totalMinutes += int.parse(spitTime[1]) ?? 0;
      totalSeconds += int.parse(spitTime[2]) ?? 0;
    }

    // Convert total seconds to minutes and seconds
    totalMinutes += totalSeconds ~/ 60;
    totalSeconds = totalSeconds % 60;

    // Convert total minutes to hours and minutes
    totalHours += totalMinutes ~/ 60;
    totalMinutes = totalMinutes % 60;
    return '$totalHours:$totalMinutes:$totalSeconds';
  }

  String getProgramName(List<dynamic> data, int sNo){
    var name = '';
    for(var program in data){
      if(program['sNo'] == sNo){
        name = program['name'];
      }
    }
    return name;
  }

  String getSequenceName(List<dynamic> data, dynamic sNo){
    var name = '';
    if (sNo == null) return '-';
    for(var sequence in data){
      if(sequence['sNo'].toString() == sNo.toString() || sequence['id'].toString() == sNo.toString()){
        name = sequence['name'] ?? '';
        break;
      }
    }
    return name.isEmpty ? sNo.toString() : name;
  }

  String getName(dynamic sNo){
    var name = '';
    debugPrint("$sNo = ${sNo.runtimeType}  | ${sNo.toString().length}");
    if(sNo is String && !sNo.toString().contains('_')){
      print("names : $names");
      for(var n in names){
        if(n['sNo'].toString() == sNo.toString()){
          name = n['name'];
        }
      }
    }else if(sNo is String && sNo.toString().contains('_')){
      name = (sNo.toString().split('_')).map((serialNo) => getName(serialNo)).join(', ');
    }else if(sNo is List){
      name = (sNo).map((serialNo) => getName(serialNo)).join(', ');
    }
    return name.isEmpty ? sNo : name;
  }

  Map<String,dynamic> editValveWise(dynamic dataSource,List<dynamic> noOfValve){
    var generalColumn = [...getColumn(generalParameterList)];
    var generalColumnData = [];
    var fixedColumnData = [];
    var waterColumn = [...getColumn(waterParameterList)];
    var waterColumnData = [];
    var prePostColumn = [...getColumn(prePostParameterList)];
    var prePostColumnData = [];
    var filterColumn = [...getColumn(filterParameterList)];
    var filterColumnData = [];
    var centralEcPhColumn = [...getColumn(centralEcPhParameterList)];
    var centralEcPhColumnData = [];
    var centralChannel1Column = [...getColumn(centralChannel1ParameterList)];
    var centralChannel1ColumnData = [];
    var centralChannel2Column = [...getColumn(centralChannel2ParameterList)];
    var centralChannel2ColumnData = [];
    var centralChannel3Column = [...getColumn(centralChannel3ParameterList)];
    var centralChannel3ColumnData = [];
    var centralChannel4Column = [...getColumn(centralChannel4ParameterList)];
    var centralChannel4ColumnData = [];
    var centralChannel5Column = [...getColumn(centralChannel5ParameterList)];
    var centralChannel5ColumnData = [];
    var centralChannel6Column = [...getColumn(centralChannel6ParameterList)];
    var centralChannel6ColumnData = [];
    var centralChannel7Column = [...getColumn(centralChannel7ParameterList)];
    var centralChannel7ColumnData = [];
    var centralChannel8Column = [...getColumn(centralChannel8ParameterList)];
    var centralChannel8ColumnData = [];
    var localEcPhColumn = [...getColumn(localEcPhParameterList)];
    var localEcPhColumnData = [];
    var localChannel1Column = [...getColumn(localChannel1ParameterList)];
    var localChannel1ColumnData = [];
    var localChannel2Column = [...getColumn(localChannel2ParameterList)];
    var localChannel2ColumnData = [];
    var localChannel3Column = [...getColumn(localChannel3ParameterList)];
    var localChannel3ColumnData = [];
    var localChannel4Column = [...getColumn(localChannel4ParameterList)];
    var localChannel4ColumnData = [];
    var localChannel5Column = [...getColumn(localChannel5ParameterList)];
    var localChannel5ColumnData = [];
    var localChannel6Column = [...getColumn(localChannel6ParameterList)];
    var localChannel6ColumnData = [];
    var localChannel7Column = [...getColumn(localChannel7ParameterList)];
    var localChannel7ColumnData = [];
    var localChannel8Column = [...getColumn(localChannel8ParameterList)];
    var localChannel8ColumnData = [];
    var graphData = [];
    var fixedColumn = 'Valve';
    generalColumn.removeWhere((item) => item == 'Valve' || item == 'Valves' || item == 'Sequence');
    for(var findValve in noOfValve){
      if(findValve['show'] == true){
        graphData.add({
          'name' : findValve['name'].toString().contains('.') ? getName(findValve['name']) : findValve['name'],
          'totalTime' : '00:00:00',
          'data' : []
        });
        var indexOfDataToAdd = graphData.length - 1;
        for(var date in dataSource['log']){
          if(date['irrigation'].isNotEmpty){
            for(var howManyValve = 0;howManyValve < date['irrigation']['SequenceData'].length;howManyValve++){
              if(date['irrigation']['SequenceData'][howManyValve].split('_').contains(findValve['name'])){
                fixedColumnData.add(getName(findValve['name']));
                var myList = [];
                var waterList = [];
                var prePostList = [];
                var centralEcPhList = [];
                var localEcPhList = [];
                var filterList = [];
                var addedUiKeys = <String>{};
                generalParameterLoop : for(var parameter in generalParameterList){
                  if(parameter.show == true && generalColumn.contains(parameter.uiKey) && !addedUiKeys.contains(parameter.uiKey)){
                    addedUiKeys.add(parameter.uiKey);
                    if(parameter.payloadKey == 'ProgramName') {
                      myList.add(getProgramName(dataSource['default']['program'], date['irrigation']['ProgramS_No'][howManyValve]));
                    }
                    else if(parameter.payloadKey == 'Status') {
                      myList.add(date['irrigation']['Status'][howManyValve]);
                    }
                    else if(parameter.payloadKey == 'SequenceData') {
                      myList.add(getName(date['irrigation']['SequenceData'][howManyValve]));
                    }
                    else if(parameter.payloadKey == 'ZoneS_No' || parameter.payloadKey == 'ZoneName') {
                      if(date['irrigation']['ZoneName'] != null && howManyValve < date['irrigation']['ZoneName'].length && date['irrigation']['ZoneName'][howManyValve] != null && date['irrigation']['ZoneName'][howManyValve].toString().isNotEmpty && date['irrigation']['ZoneName'][howManyValve].toString() != '-'){
                        myList.add(date['irrigation']['ZoneName'][howManyValve]);
                      }else if(date['irrigation']['ZoneS_No'] != null && howManyValve < date['irrigation']['ZoneS_No'].length && date['irrigation']['ZoneS_No'][howManyValve] != null){
                        myList.add(getSequenceName(dataSource['default']?['sequence'] ?? [], date['irrigation']['ZoneS_No'][howManyValve]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'Date') {
                      myList.add(date['irrigation']['Date'][howManyValve]);
                    }
                    else if(parameter.payloadKey == 'ProgramCategoryName' || parameter.payloadKey == 'ProgramCategory') {
                      if(date['irrigation']['ProgramCategoryName'] != null && howManyValve < date['irrigation']['ProgramCategoryName'].length){
                        myList.add(getName(date['irrigation']['ProgramCategoryName'][howManyValve]));
                      }else if(date['irrigation']['ProgramCategory'] != null && howManyValve < date['irrigation']['ProgramCategory'].length){
                        myList.add(getName(date['irrigation']['ProgramCategory'][howManyValve]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'HeadUnit') {
                      myList.add(getName(date['irrigation']['HeadUnit'][howManyValve]));
                    }
                    else if(parameter.payloadKey == 'ScheduledStartTime') {
                      myList.add(formatSingleTime(date['irrigation']['ScheduledStartTime'][howManyValve]));
                    }
                    else if(parameter.payloadKey == 'ActualStartTime') {
                      if(date['irrigation']['ActualStartTime'] != null && howManyValve < date['irrigation']['ActualStartTime'].length){
                        myList.add(formatMultiTime(date['irrigation']['ActualStartTime'][howManyValve]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualEndTime') {
                      if(date['irrigation']['ActualEndTime'] != null && howManyValve < date['irrigation']['ActualEndTime'].length){
                        myList.add(formatMultiTime(date['irrigation']['ActualEndTime'][howManyValve]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualStartReason') {
                      if(date['irrigation']['ActualStartReason'] != null && howManyValve < date['irrigation']['ActualStartReason'].length){
                        myList.add(formatMultiReason(date['irrigation']['ActualStartReason'][howManyValve]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualStopReason') {
                      if(date['irrigation']['ActualStopReason'] != null && howManyValve < date['irrigation']['ActualStopReason'].length){
                        myList.add(formatMultiReason(date['irrigation']['ActualStopReason'][howManyValve]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'Pump') {
                      myList.add(getName(date['irrigation']['Pump'][howManyValve]));
                    }
                    else if(parameter.payloadKey == 'PumpCtAverage') {
                      if(howManyValve < date['irrigation']['PumpCtAverage'].length){
                        myList.add(date['irrigation']['PumpCtAverage'][howManyValve]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PumpCtMaximum') {
                      if(howManyValve < date['irrigation']['PumpCtMaximum'].length){
                        myList.add(date['irrigation']['PumpCtMaximum'][howManyValve]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PumpCtMinimum') {
                      if(howManyValve < date['irrigation']['PumpCtMinimum'].length){
                        myList.add(date['irrigation']['PumpCtMinimum'][howManyValve]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureAverage') {
                      if(howManyValve < date['irrigation']['PressureAverage'].length){
                        myList.add(date['irrigation']['PressureAverage'][howManyValve]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureMaximum') {
                      if(howManyValve < date['irrigation']['PressureMaximum'].length){
                        myList.add(date['irrigation']['PressureMaximum'][howManyValve]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureMinimum') {
                      if(howManyValve < date['irrigation']['PressureMinimum'].length){
                        myList.add(date['irrigation']['PressureMinimum'][howManyValve]);
                      }else{
                        myList.add('-');
                      }
                    }
                  }
                }
                waterParameterLoop : for(var parameter in waterParameterList){
                  if(parameter.payloadKey == 'IrrigationMethod') {
                    if(parameter.show == true){
                      waterList.add(date['irrigation']['IrrigationMethod'][howManyValve] == 1 ? 'Time' : 'Quantity (L)');
                    }
                  }
                  if(parameter.payloadKey == 'IrrigationDuration_Quantity') {
                    // calculateTime
                    graphData[indexOfDataToAdd]['totalTime'] = calculateTotalTime([graphData[indexOfDataToAdd]['totalTime'],date['irrigation']['IrrigationDurationCompleted'][howManyValve]]);
                    graphData[indexOfDataToAdd]['data'].add(
                        getGraphData(
                            method: date['irrigation']['IrrigationMethod'][howManyValve],
                            planned: date['irrigation']['IrrigationDuration_Quantity'][howManyValve],
                            actualDuration: date['irrigation']['IrrigationDurationCompleted'][howManyValve],
                            actualLiters: date['irrigation']['IrrigationQuantityCompleted'][howManyValve],
                            flowRate: date['irrigation']['ValveFlowrate'][howManyValve],
                            name: '${date['irrigation']['Date'][howManyValve]}\n${date['irrigation']['ScheduledStartTime'][howManyValve]}'
                        )
                    );
                    if(parameter.show == true){
                      waterList.add(date['irrigation']['IrrigationDuration_Quantity'][howManyValve]);
                    }
                  }
                  if(parameter.payloadKey == 'IrrigationDurationCompleted/IrrigationQuantityCompleted') {
                    if(parameter.show == true){
                      var time = date['irrigation'][parameter.payloadKey.split('/')[0]][howManyValve];
                      var quantity = date['irrigation'][parameter.payloadKey.split('/')[1]][howManyValve];
                      waterList.add('$time HMS\n$quantity L');
                    }
                  }
                }
                prePostParameterLoop : for(var parameter in prePostParameterList){
                  if(parameter.payloadKey == 'PrePostMethod') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation']['PrePostMethod'][howManyValve] == 1 ? 'Time' : 'Quantity (L)');
                    }
                  }
                  if(parameter.payloadKey == 'Pretime/PreQty') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation'][date['irrigation']['PrePostMethod'][howManyValve] == 1 ? 'Pretime' : 'PreQty'][howManyValve]);
                    }
                  }
                  if(parameter.payloadKey == 'PostTime/PostQty') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation'][date['irrigation']['PrePostMethod'][howManyValve] == 1 ? 'PostTime' : 'PostQty'][howManyValve]);
                    }
                  }
                }
                filterParameterLoop : for(var parameter in filterParameterList){
                  if(parameter.payloadKey == 'CentralFilterName') {
                    if(parameter.show == true){
                      var filterName = howManyValve < date['irrigation']['CentralFilterName'].length ? date['irrigation']['CentralFilterName'][howManyValve] : '';
                      var filterDuration = howManyValve < date['irrigation']['CentralFilterOnDuration'].length ? date['irrigation']['CentralFilterOnDuration'][howManyValve] : '';
                      var listOfFilterName = (filterName == null || filterName.isEmpty) ? [] : filterName.split('_');
                      var listOfFilterDuration = (filterDuration == null || filterDuration.isEmpty) ? [] : filterDuration.split('_');
                      var listOfNameAndDuration = [];
                      for(var name = 0;name < listOfFilterName.length;name++){
                        if(listOfFilterDuration.length > name){
                          listOfNameAndDuration.add('${listOfFilterName[name]} - ${listOfFilterDuration[name]}');
                        }else{
                          listOfNameAndDuration.add('${listOfFilterName[name]} - N/A');
                        }
                      }
                      filterList.add(listOfNameAndDuration.join('\n'));
                    }
                  }
                  if(parameter.payloadKey == 'LocalFilterName') {
                    if(parameter.show == true){
                      var filterName = howManyValve < date['irrigation']['LocalFilterName'].length ? date['irrigation']['LocalFilterName'][howManyValve] : '';
                      var filterDuration = howManyValve < date['irrigation']['LocalFilterOnDuration'].length ? date['irrigation']['LocalFilterOnDuration'][howManyValve] : '';
                      var listOfFilterName = (filterName == null || filterName.isEmpty) ? [] : filterName.split('_');
                      var listOfFilterDuration = (filterDuration == null || filterDuration.isEmpty) ? [] : filterDuration.split('_');
                      var listOfNameAndDuration = [];
                      for(var name = 0;name < listOfFilterName.length;name++){
                        if(listOfFilterDuration.length > name){
                          listOfNameAndDuration.add('${listOfFilterName[name]} - ${listOfFilterDuration[name]}');
                        }else{
                          listOfNameAndDuration.add('${listOfFilterName[name]} - N/A');
                        }
                      }
                      filterList.add(listOfNameAndDuration.join('\n'));
                    }
                  }
                }
                centralEcPhParameterLoop : for(var parameter in centralEcPhParameterList){
                  if(parameter.payloadKey == 'CentralEcSetValue') {
                    if(parameter.show == true){
                      centralEcPhList.add(date['irrigation']['CentralEcSetValue'][howManyValve]);
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcAverage'] == null || date['irrigation']['CentralEcAverage'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcAverage'][howManyValve]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcMaximum'] == null || date['irrigation']['CentralEcMaximum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcMaximum'][howManyValve]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcMinimum'] == null || date['irrigation']['CentralEcMinimum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcMinimum'][howManyValve]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhSetValue') {
                    if(parameter.show == true){
                      centralEcPhList.add(date['irrigation']['CentralPhSetValue'][howManyValve]);
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhAverage'] == null || date['irrigation']['CentralPhAverage'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhAverage'][howManyValve]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhMaximum'] == null || date['irrigation']['CentralPhMaximum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhMaximum'][howManyValve]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhMinimum'] == null || date['irrigation']['CentralPhMinimum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhMinimum'][howManyValve]);
                      }
                    }
                  }
                }
                localEcPhParameterLoop : for(var parameter in localEcPhParameterList){
                  if(parameter.payloadKey == 'LocalEcSetValue') {
                    if(parameter.show == true){
                      localEcPhList.add(date['irrigation']['LocalEcSetValue'][howManyValve]);
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcAverage'] == null || date['irrigation']['LocalEcAverage'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcAverage'][howManyValve]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcMaximum'] == null || date['irrigation']['LocalEcMaximum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcMaximum'][howManyValve]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcMinimum'] == null || date['irrigation']['LocalEcMinimum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcMinimum'][howManyValve]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhSetValue') {
                    if(parameter.show == true){
                      localEcPhList.add(date['irrigation']['LocalPhSetValue'][howManyValve]);
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhAverage'] == null || date['irrigation']['LocalPhAverage'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhAverage'][howManyValve]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhMaximum'] == null || date['irrigation']['LocalPhMaximum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhMaximum'][howManyValve]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhMinimum'] == null || date['irrigation']['LocalPhMinimum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhMinimum'][howManyValve]);
                      }
                    }
                  }
                }
                generalColumnData.add(myList);
                waterColumnData.add(waterList);
                prePostColumnData.add(prePostList);
                filterColumnData.add(filterList);
                centralEcPhColumnData.add(centralEcPhList);
                centralChannel1ColumnData.add(getChannelData(channelNo: 0, channelParameterList: centralChannel1ParameterList, date: date, howMany: howManyValve, central: true));
                centralChannel2ColumnData.add(getChannelData(channelNo: 1, channelParameterList: centralChannel2ParameterList, date: date, howMany: howManyValve, central: true));
                centralChannel3ColumnData.add(getChannelData(channelNo: 2, channelParameterList: centralChannel3ParameterList, date: date, howMany: howManyValve, central: true));
                centralChannel4ColumnData.add(getChannelData(channelNo: 3, channelParameterList: centralChannel4ParameterList, date: date, howMany: howManyValve, central: true));
                centralChannel5ColumnData.add(getChannelData(channelNo: 4, channelParameterList: centralChannel5ParameterList, date: date, howMany: howManyValve, central: true));
                centralChannel6ColumnData.add(getChannelData(channelNo: 5, channelParameterList: centralChannel6ParameterList, date: date, howMany: howManyValve, central: true));
                centralChannel7ColumnData.add(getChannelData(channelNo: 6, channelParameterList: centralChannel7ParameterList, date: date, howMany: howManyValve, central: true));
                centralChannel8ColumnData.add(getChannelData(channelNo: 7, channelParameterList: centralChannel8ParameterList, date: date, howMany: howManyValve, central: true));
                localEcPhColumnData.add(localEcPhList);
                localChannel1ColumnData.add(getChannelData(channelNo: 0, channelParameterList: localChannel1ParameterList, date: date, howMany: howManyValve, central: false));
                localChannel2ColumnData.add(getChannelData(channelNo: 1, channelParameterList: localChannel2ParameterList, date: date, howMany: howManyValve, central: false));
                localChannel3ColumnData.add(getChannelData(channelNo: 2, channelParameterList: localChannel3ParameterList, date: date, howMany: howManyValve, central: false));
                localChannel4ColumnData.add(getChannelData(channelNo: 3, channelParameterList: localChannel4ParameterList, date: date, howMany: howManyValve, central: false));
                localChannel5ColumnData.add(getChannelData(channelNo: 4, channelParameterList: localChannel5ParameterList, date: date, howMany: howManyValve, central: false));
                localChannel6ColumnData.add(getChannelData(channelNo: 5, channelParameterList: localChannel6ParameterList, date: date, howMany: howManyValve, central: false));
                localChannel7ColumnData.add(getChannelData(channelNo: 6, channelParameterList: localChannel7ParameterList, date: date, howMany: howManyValve, central: false));
                localChannel8ColumnData.add(getChannelData(channelNo: 7, channelParameterList: localChannel8ParameterList, date: date, howMany: howManyValve, central: false));
              }
            }
          }
        }
      }
    }

    return {
      'fixedColumn' : fixedColumn,
      'fixedColumnData': fixedColumnData,
      'generalColumn' : generalColumn,
      'generalColumnData' : generalColumnData,
      'waterColumn' : waterColumn,
      'waterColumnData' : waterColumnData,
      'prePostColumn' : prePostColumn,
      'prePostColumnData' : prePostColumnData,
      'filterColumn' : filterColumn,
      'filterColumnData' : filterColumnData,
      'centralEcPhColumn' : centralEcPhColumn,
      'centralEcPhColumnData' : centralEcPhColumnData,
      'centralChannel1Column' : centralChannel1Column,
      'centralChannel1ColumnData' : centralChannel1ColumnData,
      'centralChannel2Column' : centralChannel2Column,
      'centralChannel2ColumnData' : centralChannel2ColumnData,
      'centralChannel3Column' : centralChannel3Column,
      'centralChannel3ColumnData' : centralChannel3ColumnData,
      'centralChannel4Column' : centralChannel4Column,
      'centralChannel4ColumnData' : centralChannel4ColumnData,
      'centralChannel5Column' : centralChannel5Column,
      'centralChannel5ColumnData' : centralChannel5ColumnData,
      'centralChannel6Column' : centralChannel6Column,
      'centralChannel6ColumnData' : centralChannel6ColumnData,
      'centralChannel7Column' : centralChannel7Column,
      'centralChannel7ColumnData' : centralChannel7ColumnData,
      'centralChannel8Column' : centralChannel8Column,
      'centralChannel8ColumnData' : centralChannel8ColumnData,
      'localEcPhColumn' : localEcPhColumn,
      'localEcPhColumnData' : localEcPhColumnData,
      'localChannel1Column' : localChannel1Column,
      'localChannel1ColumnData' : localChannel1ColumnData,
      'localChannel2Column' : localChannel2Column,
      'localChannel2ColumnData' : localChannel2ColumnData,
      'localChannel3Column' : localChannel3Column,
      'localChannel3ColumnData' : localChannel3ColumnData,
      'localChannel4Column' : localChannel4Column,
      'localChannel4ColumnData' : localChannel4ColumnData,
      'localChannel5Column' : localChannel5Column,
      'localChannel5ColumnData' : localChannel5ColumnData,
      'localChannel6Column' : localChannel6Column,
      'localChannel6ColumnData' : localChannel6ColumnData,
      'localChannel7Column' : localChannel7Column,
      'localChannel7ColumnData' : localChannel7ColumnData,
      'localChannel8Column' : localChannel8Column,
      'localChannel8ColumnData' : localChannel8ColumnData,
      'graphData' : graphData
    };
  }

  Map<String,dynamic> editLineWise(dynamic dataSource,List<dynamic> noOfLine){
    var generalColumn = [...getColumn(generalParameterList)];
    var generalColumnData = [];
    var fixedColumnData = [];
    var waterColumn = [...getColumn(waterParameterList)];
    var waterColumnData = [];
    var prePostColumn = [...getColumn(prePostParameterList)];
    var prePostColumnData = [];
    var filterColumn = [...getColumn(filterParameterList)];
    var filterColumnData = [];
    var centralEcPhColumn = [...getColumn(centralEcPhParameterList)];
    var centralEcPhColumnData = [];
    var centralChannel1Column = [...getColumn(centralChannel1ParameterList)];
    var centralChannel1ColumnData = [];
    var centralChannel2Column = [...getColumn(centralChannel2ParameterList)];
    var centralChannel2ColumnData = [];
    var centralChannel3Column = [...getColumn(centralChannel3ParameterList)];
    var centralChannel3ColumnData = [];
    var centralChannel4Column = [...getColumn(centralChannel4ParameterList)];
    var centralChannel4ColumnData = [];
    var centralChannel5Column = [...getColumn(centralChannel5ParameterList)];
    var centralChannel5ColumnData = [];
    var centralChannel6Column = [...getColumn(centralChannel6ParameterList)];
    var centralChannel6ColumnData = [];
    var centralChannel7Column = [...getColumn(centralChannel7ParameterList)];
    var centralChannel7ColumnData = [];
    var centralChannel8Column = [...getColumn(centralChannel8ParameterList)];
    var centralChannel8ColumnData = [];
    var localEcPhColumn = [...getColumn(localEcPhParameterList)];
    var localEcPhColumnData = [];
    var localChannel1Column = [...getColumn(localChannel1ParameterList)];
    var localChannel1ColumnData = [];
    var localChannel2Column = [...getColumn(localChannel2ParameterList)];
    var localChannel2ColumnData = [];
    var localChannel3Column = [...getColumn(localChannel3ParameterList)];
    var localChannel3ColumnData = [];
    var localChannel4Column = [...getColumn(localChannel4ParameterList)];
    var localChannel4ColumnData = [];
    var localChannel5Column = [...getColumn(localChannel5ParameterList)];
    var localChannel5ColumnData = [];
    var localChannel6Column = [...getColumn(localChannel6ParameterList)];
    var localChannel6ColumnData = [];
    var localChannel7Column = [...getColumn(localChannel7ParameterList)];
    var localChannel7ColumnData = [];
    var localChannel8Column = [...getColumn(localChannel8ParameterList)];
    var localChannel8ColumnData = [];
    var graphData = [];
    var fixedColumn = 'Line';
    generalColumn.removeWhere((item) => item == 'Line');
    for(var findLine in noOfLine){
      if(findLine['show'] == true){
        graphData.add({
          'name' : findLine['name'].toString().contains('.') ? getName(findLine['name']) : findLine['name'],
          'totalTime' : '00:00:00',
          'data' : []
        });
        var indexOfDataToAdd = graphData.length - 1;
        for(var date in dataSource['log']){
          if(date['irrigation'].isNotEmpty){
            for(var howManyLine = 0;howManyLine < date['irrigation']['ProgramCategory'].length;howManyLine++){
              if(date['irrigation']['ProgramCategory'][howManyLine].contains(findLine['name'])){
                fixedColumnData.add(getName(findLine['lineName']));
                var myList = [];
                var waterList = [];
                var prePostList = [];
                var centralEcPhList = [];
                var localEcPhList = [];
                var filterList = [];
                var addedUiKeys = <String>{};
                generalParameterLoop : for(var parameter in generalParameterList){
                  if(parameter.show == true && generalColumn.contains(parameter.uiKey) && !addedUiKeys.contains(parameter.uiKey)){
                    addedUiKeys.add(parameter.uiKey);
                    if(parameter.payloadKey == 'ProgramName') {
                      myList.add(getProgramName(dataSource['default']['program'], date['irrigation']['ProgramS_No'][howManyLine]));
                    }
                    else if(parameter.payloadKey == 'Status') {
                      myList.add(date['irrigation']['Status'][howManyLine]);
                    }
                    else if(parameter.payloadKey == 'SequenceData') {
                      myList.add(getName(date['irrigation']['SequenceData'][howManyLine]));
                    }
                    else if(parameter.payloadKey == 'ZoneS_No' || parameter.payloadKey == 'ZoneName') {
                      if(date['irrigation']['ZoneName'] != null && howManyLine < date['irrigation']['ZoneName'].length && date['irrigation']['ZoneName'][howManyLine] != null && date['irrigation']['ZoneName'][howManyLine].toString().isNotEmpty && date['irrigation']['ZoneName'][howManyLine].toString() != '-'){
                        myList.add(date['irrigation']['ZoneName'][howManyLine]);
                      }else if(date['irrigation']['ZoneS_No'] != null && howManyLine < date['irrigation']['ZoneS_No'].length && date['irrigation']['ZoneS_No'][howManyLine] != null){
                        myList.add(getSequenceName(dataSource['default']?['sequence'] ?? [], date['irrigation']['ZoneS_No'][howManyLine]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'Date') {
                      myList.add(date['irrigation']['Date'][howManyLine]);
                    }
                    else if(parameter.payloadKey == 'ProgramCategoryName' || parameter.payloadKey == 'ProgramCategory') {
                      if(date['irrigation']['ProgramCategoryName'] != null && howManyLine < date['irrigation']['ProgramCategoryName'].length){
                        myList.add(getName(date['irrigation']['ProgramCategoryName'][howManyLine]));
                      }else if(date['irrigation']['ProgramCategory'] != null && howManyLine < date['irrigation']['ProgramCategory'].length){
                        myList.add(getName(date['irrigation']['ProgramCategory'][howManyLine]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'HeadUnit') {
                      myList.add(getName(date['irrigation']['HeadUnit'][howManyLine]));
                    }
                    else if(parameter.payloadKey == 'ScheduledStartTime') {
                      myList.add(formatSingleTime(date['irrigation']['ScheduledStartTime'][howManyLine]));
                    }
                    else if(parameter.payloadKey == 'ActualStartTime') {
                      if(date['irrigation']['ActualStartTime'] != null && howManyLine < date['irrigation']['ActualStartTime'].length){
                        myList.add(formatMultiTime(date['irrigation']['ActualStartTime'][howManyLine]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualEndTime') {
                      if(date['irrigation']['ActualEndTime'] != null && howManyLine < date['irrigation']['ActualEndTime'].length){
                        myList.add(formatMultiTime(date['irrigation']['ActualEndTime'][howManyLine]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualStartReason') {
                      if(date['irrigation']['ActualStartReason'] != null && howManyLine < date['irrigation']['ActualStartReason'].length){
                        myList.add(formatMultiReason(date['irrigation']['ActualStartReason'][howManyLine]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualStopReason') {
                      if(date['irrigation']['ActualStopReason'] != null && howManyLine < date['irrigation']['ActualStopReason'].length){
                        myList.add(formatMultiReason(date['irrigation']['ActualStopReason'][howManyLine]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'Pump') {
                      myList.add(getName(date['irrigation']['Pump'][howManyLine]));
                    }
                    else if(parameter.payloadKey == 'PumpCtAverage') {
                      if(howManyLine < date['irrigation']['PumpCtAverage'].length){
                        myList.add(date['irrigation']['PumpCtAverage'][howManyLine]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PumpCtMaximum') {
                      if(howManyLine < date['irrigation']['PumpCtMaximum'].length){
                        myList.add(date['irrigation']['PumpCtMaximum'][howManyLine]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PumpCtMinimum') {
                      if(howManyLine < date['irrigation']['PumpCtMinimum'].length){
                        myList.add(date['irrigation']['PumpCtMinimum'][howManyLine]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureAverage') {
                      if(howManyLine < date['irrigation']['PressureAverage'].length){
                        myList.add(date['irrigation']['PressureAverage'][howManyLine]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureMaximum') {
                      if(howManyLine < date['irrigation']['PressureMaximum'].length){
                        myList.add(date['irrigation']['PressureMaximum'][howManyLine]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureMinimum') {
                      if(howManyLine < date['irrigation']['PressureMinimum'].length){
                        myList.add(date['irrigation']['PressureMinimum'][howManyLine]);
                      }else{
                        myList.add('-');
                      }
                    }
                  }
                }
                waterParameterLoop : for(var parameter in waterParameterList){
                  if(parameter.payloadKey == 'IrrigationMethod') {
                    if(parameter.show == true){
                      waterList.add(date['irrigation']['IrrigationMethod'][howManyLine] == 1 ? 'Time' : 'Quantity (L)');
                    }
                  }
                  if(parameter.payloadKey == 'IrrigationDuration_Quantity') {
                    graphData[indexOfDataToAdd]['totalTime'] = calculateTotalTime([graphData[indexOfDataToAdd]['totalTime'],date['irrigation']['IrrigationDurationCompleted'][howManyLine]]);
                    graphData[indexOfDataToAdd]['data'].add(
                        getGraphData(
                            method: date['irrigation']['IrrigationMethod'][howManyLine],
                            planned: date['irrigation']['IrrigationDuration_Quantity'][howManyLine],
                            actualDuration: date['irrigation']['IrrigationDurationCompleted'][howManyLine],
                            actualLiters: date['irrigation']['IrrigationQuantityCompleted'][howManyLine],
                            flowRate: date['irrigation']['ValveFlowrate'][howManyLine],
                            name: '${date['irrigation']['Date'][howManyLine]}\n${date['irrigation']['ScheduledStartTime'][howManyLine]}'
                        )
                    );
                    if(parameter.show == true){
                      waterList.add(date['irrigation']['IrrigationDuration_Quantity'][howManyLine]);
                    }
                  }
                  if(parameter.payloadKey == 'IrrigationDurationCompleted/IrrigationQuantityCompleted') {
                    if(parameter.show == true){
                      var time = date['irrigation'][parameter.payloadKey.split('/')[0]][howManyLine];
                      var quantity = date['irrigation'][parameter.payloadKey.split('/')[1]][howManyLine];
                      waterList.add('$time HMS\n$quantity L');
                    }
                  }
                }
                prePostParameterLoop : for(var parameter in prePostParameterList){
                  if(parameter.payloadKey == 'PrePostMethod') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation']['PrePostMethod'][howManyLine] == 1 ? 'Time' : 'Quantity (L)');
                    }
                  }
                  if(parameter.payloadKey == 'Pretime/PreQty') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation'][date['irrigation']['PrePostMethod'][howManyLine] == 1 ? 'Pretime' : 'PreQty'][howManyLine]);
                    }
                  }
                  if(parameter.payloadKey == 'PostTime/PostQty') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation'][date['irrigation']['PrePostMethod'][howManyLine] == 1 ? 'PostTime' : 'PostQty'][howManyLine]);
                    }
                  }
                }
                filterParameterLoop : for(var parameter in filterParameterList){
                  if(parameter.payloadKey == 'CentralFilterName') {
                    if(parameter.show == true){
                      var filterName = howManyLine < date['irrigation']['CentralFilterName'].length ? date['irrigation']['CentralFilterName'][howManyLine] : '';
                      var filterDuration = howManyLine < date['irrigation']['CentralFilterOnDuration'].length ? date['irrigation']['CentralFilterOnDuration'][howManyLine] : '';
                      var listOfFilterName = (filterName == null || filterName.isEmpty) ? [] : filterName.split('_');
                      var listOfFilterDuration = (filterDuration == null || filterDuration.isEmpty) ? [] : filterDuration.split('_');
                      var listOfNameAndDuration = [];
                      for(var name = 0;name < listOfFilterName.length;name++){
                        if(listOfFilterDuration.length > name){
                          listOfNameAndDuration.add('${listOfFilterName[name]} - ${listOfFilterDuration[name]}');
                        }else{
                          listOfNameAndDuration.add('${listOfFilterName[name]} - N/A');
                        }
                      }
                      filterList.add(listOfNameAndDuration.join('\n'));
                    }
                  }
                  if(parameter.payloadKey == 'LocalFilterName') {
                    if(parameter.show == true){
                      var filterName = howManyLine < date['irrigation']['LocalFilterName'].length ? date['irrigation']['LocalFilterName'][howManyLine] : '';
                      var filterDuration = howManyLine < date['irrigation']['LocalFilterOnDuration'].length ? date['irrigation']['LocalFilterOnDuration'][howManyLine] : '';
                      var listOfFilterName = (filterName == null || filterName.isEmpty) ? [] : filterName.split('_');
                      var listOfFilterDuration = (filterDuration == null || filterDuration.isEmpty) ? [] : filterDuration.split('_');
                      var listOfNameAndDuration = [];
                      for(var name = 0;name < listOfFilterName.length;name++){
                        if(listOfFilterDuration.length > name){
                          listOfNameAndDuration.add('${listOfFilterName[name]} - ${listOfFilterDuration[name]}');
                        }else{
                          listOfNameAndDuration.add('${listOfFilterName[name]} - N/A');
                        }
                      }
                      filterList.add(listOfNameAndDuration.join('\n'));
                    }
                  }
                }
                centralEcPhParameterLoop : for(var parameter in centralEcPhParameterList){
                  if(parameter.payloadKey == 'CentralEcSetValue') {
                    if(parameter.show == true){
                      centralEcPhList.add(date['irrigation']['CentralEcSetValue'][howManyLine]);
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcAverage'] == null || date['irrigation']['CentralEcAverage'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcAverage'][howManyLine]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcMaximum'] == null || date['irrigation']['CentralEcMaximum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcMaximum'][howManyLine]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcMinimum'] == null || date['irrigation']['CentralEcMinimum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcMinimum'][howManyLine]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhSetValue') {
                    if(parameter.show == true){
                      centralEcPhList.add(date['irrigation']['CentralPhSetValue'][howManyLine]);
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhAverage'] == null || date['irrigation']['CentralPhAverage'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhAverage'][howManyLine]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhMaximum'] == null || date['irrigation']['CentralPhMaximum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhMaximum'][howManyLine]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhMinimum'] == null || date['irrigation']['CentralPhMinimum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhMinimum'][howManyLine]);
                      }
                    }
                  }
                }
                localEcPhParameterLoop : for(var parameter in localEcPhParameterList){
                  if(parameter.payloadKey == 'LocalEcSetValue') {
                    if(parameter.show == true){
                      localEcPhList.add(date['irrigation']['LocalEcSetValue'][howManyLine]);
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcAverage'] == null || date['irrigation']['LocalEcAverage'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcAverage'][howManyLine]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcMaximum'] == null || date['irrigation']['LocalEcMaximum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcMaximum'][howManyLine]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcMinimum'] == null || date['irrigation']['LocalEcMinimum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcMinimum'][howManyLine]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhSetValue') {
                    if(parameter.show == true){
                      localEcPhList.add(date['irrigation']['LocalPhSetValue'][howManyLine]);
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhAverage'] == null || date['irrigation']['LocalPhAverage'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhAverage'][howManyLine]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhMaximum'] == null || date['irrigation']['LocalPhMaximum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhMaximum'][howManyLine]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhMinimum'] == null || date['irrigation']['LocalPhMinimum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhMinimum'][howManyLine]);
                      }
                    }
                  }
                }
                generalColumnData.add(myList);
                waterColumnData.add(waterList);
                prePostColumnData.add(prePostList);
                filterColumnData.add(filterList);
                centralEcPhColumnData.add(centralEcPhList);
                centralChannel1ColumnData.add(getChannelData(channelNo: 0, channelParameterList: centralChannel1ParameterList, date: date, howMany: howManyLine, central: true));
                centralChannel2ColumnData.add(getChannelData(channelNo: 1, channelParameterList: centralChannel2ParameterList, date: date, howMany: howManyLine, central: true));
                centralChannel3ColumnData.add(getChannelData(channelNo: 2, channelParameterList: centralChannel3ParameterList, date: date, howMany: howManyLine, central: true));
                centralChannel4ColumnData.add(getChannelData(channelNo: 3, channelParameterList: centralChannel4ParameterList, date: date, howMany: howManyLine, central: true));
                centralChannel5ColumnData.add(getChannelData(channelNo: 4, channelParameterList: centralChannel5ParameterList, date: date, howMany: howManyLine, central: true));
                centralChannel6ColumnData.add(getChannelData(channelNo: 5, channelParameterList: centralChannel6ParameterList, date: date, howMany: howManyLine, central: true));
                centralChannel7ColumnData.add(getChannelData(channelNo: 6, channelParameterList: centralChannel7ParameterList, date: date, howMany: howManyLine, central: true));
                centralChannel8ColumnData.add(getChannelData(channelNo: 7, channelParameterList: centralChannel8ParameterList, date: date, howMany: howManyLine, central: true));
                localEcPhColumnData.add(localEcPhList);
                localChannel1ColumnData.add(getChannelData(channelNo: 0, channelParameterList: localChannel1ParameterList, date: date, howMany: howManyLine, central: false));
                localChannel2ColumnData.add(getChannelData(channelNo: 1, channelParameterList: localChannel2ParameterList, date: date, howMany: howManyLine, central: false));
                localChannel3ColumnData.add(getChannelData(channelNo: 2, channelParameterList: localChannel3ParameterList, date: date, howMany: howManyLine, central: false));
                localChannel4ColumnData.add(getChannelData(channelNo: 3, channelParameterList: localChannel4ParameterList, date: date, howMany: howManyLine, central: false));
                localChannel5ColumnData.add(getChannelData(channelNo: 4, channelParameterList: localChannel5ParameterList, date: date, howMany: howManyLine, central: false));
                localChannel6ColumnData.add(getChannelData(channelNo: 5, channelParameterList: localChannel6ParameterList, date: date, howMany: howManyLine, central: false));
                localChannel7ColumnData.add(getChannelData(channelNo: 6, channelParameterList: localChannel7ParameterList, date: date, howMany: howManyLine, central: false));
                localChannel8ColumnData.add(getChannelData(channelNo: 7, channelParameterList: localChannel8ParameterList, date: date, howMany: howManyLine, central: false));

              }

            }
          }

        }
      }
    }
    return {
      'fixedColumn' : fixedColumn,
      'fixedColumnData': fixedColumnData,
      'generalColumn' : generalColumn,
      'generalColumnData' : generalColumnData,
      'waterColumn' : waterColumn,
      'waterColumnData' : waterColumnData,
      'prePostColumn' : prePostColumn,
      'prePostColumnData' : prePostColumnData,
      'filterColumn' : filterColumn,
      'filterColumnData' : filterColumnData,
      'centralEcPhColumn' : centralEcPhColumn,
      'centralEcPhColumnData' : centralEcPhColumnData,
      'centralChannel1Column' : centralChannel1Column,
      'centralChannel1ColumnData' : centralChannel1ColumnData,
      'centralChannel2Column' : centralChannel2Column,
      'centralChannel2ColumnData' : centralChannel2ColumnData,
      'centralChannel3Column' : centralChannel3Column,
      'centralChannel3ColumnData' : centralChannel3ColumnData,
      'centralChannel4Column' : centralChannel4Column,
      'centralChannel4ColumnData' : centralChannel4ColumnData,
      'centralChannel5Column' : centralChannel5Column,
      'centralChannel5ColumnData' : centralChannel5ColumnData,
      'centralChannel6Column' : centralChannel6Column,
      'centralChannel6ColumnData' : centralChannel6ColumnData,
      'centralChannel7Column' : centralChannel7Column,
      'centralChannel7ColumnData' : centralChannel7ColumnData,
      'centralChannel8Column' : centralChannel8Column,
      'centralChannel8ColumnData' : centralChannel8ColumnData,
      'localEcPhColumn' : localEcPhColumn,
      'localEcPhColumnData' : localEcPhColumnData,
      'localChannel1Column' : localChannel1Column,
      'localChannel1ColumnData' : localChannel1ColumnData,
      'localChannel2Column' : localChannel2Column,
      'localChannel2ColumnData' : localChannel2ColumnData,
      'localChannel3Column' : localChannel3Column,
      'localChannel3ColumnData' : localChannel3ColumnData,
      'localChannel4Column' : localChannel4Column,
      'localChannel4ColumnData' : localChannel4ColumnData,
      'localChannel5Column' : localChannel5Column,
      'localChannel5ColumnData' : localChannel5ColumnData,
      'localChannel6Column' : localChannel6Column,
      'localChannel6ColumnData' : localChannel6ColumnData,
      'localChannel7Column' : localChannel7Column,
      'localChannel7ColumnData' : localChannel7ColumnData,
      'localChannel8Column' : localChannel8Column,
      'localChannel8ColumnData' : localChannel8ColumnData,
      'graphData' : graphData
    };

  }

  Map<String,dynamic> editProgramWise(dynamic dataSource,List<dynamic> noOfProgram){
    var generalColumn = [...getColumn(generalParameterList)];
    var generalColumnData = [];
    var fixedColumnData = [];
    var waterColumn = [...getColumn(waterParameterList)];
    var waterColumnData = [];
    var prePostColumn = [...getColumn(prePostParameterList)];
    var prePostColumnData = [];
    var filterColumn = [...getColumn(filterParameterList)];
    var filterColumnData = [];
    var centralEcPhColumn = [...getColumn(centralEcPhParameterList)];
    var centralEcPhColumnData = [];
    var centralChannel1Column = [...getColumn(centralChannel1ParameterList)];
    var centralChannel1ColumnData = [];
    var centralChannel2Column = [...getColumn(centralChannel2ParameterList)];
    var centralChannel2ColumnData = [];
    var centralChannel3Column = [...getColumn(centralChannel3ParameterList)];
    var centralChannel3ColumnData = [];
    var centralChannel4Column = [...getColumn(centralChannel4ParameterList)];
    var centralChannel4ColumnData = [];
    var centralChannel5Column = [...getColumn(centralChannel5ParameterList)];
    var centralChannel5ColumnData = [];
    var centralChannel6Column = [...getColumn(centralChannel6ParameterList)];
    var centralChannel6ColumnData = [];
    var centralChannel7Column = [...getColumn(centralChannel7ParameterList)];
    var centralChannel7ColumnData = [];
    var centralChannel8Column = [...getColumn(centralChannel8ParameterList)];
    var centralChannel8ColumnData = [];
    var localEcPhColumn = [...getColumn(localEcPhParameterList)];
    var localEcPhColumnData = [];
    var localChannel1Column = [...getColumn(localChannel1ParameterList)];
    var localChannel1ColumnData = [];
    var localChannel2Column = [...getColumn(localChannel2ParameterList)];
    var localChannel2ColumnData = [];
    var localChannel3Column = [...getColumn(localChannel3ParameterList)];
    var localChannel3ColumnData = [];
    var localChannel4Column = [...getColumn(localChannel4ParameterList)];
    var localChannel4ColumnData = [];
    var localChannel5Column = [...getColumn(localChannel5ParameterList)];
    var localChannel5ColumnData = [];
    var localChannel6Column = [...getColumn(localChannel6ParameterList)];
    var localChannel6ColumnData = [];
    var localChannel7Column = [...getColumn(localChannel7ParameterList)];
    var localChannel7ColumnData = [];
    var localChannel8Column = [...getColumn(localChannel8ParameterList)];
    var localChannel8ColumnData = [];
    var graphData = [];

    var fixedColumn = 'Program';
    generalColumn.removeWhere((item) => item == 'Program');
    for(var findProgram in noOfProgram){
      if(findProgram['show'] == true){
        graphData.add({
          'name' : 'Program ${findProgram['name']}',
          'totalTime' : '00:00:00',
          'data' : []
        });
        var indexOfDataToAdd = graphData.length - 1;
        for(var date in dataSource['log']){
          if(date['irrigation'].isNotEmpty){
            for(var howManyProgram = 0;howManyProgram < date['irrigation']['ProgramS_No'].length;howManyProgram++){
              if(date['irrigation']['ProgramS_No'][howManyProgram] == findProgram['name']){
                fixedColumnData.add(getProgramName(dataSource['default']['program'], date['irrigation']['ProgramS_No'][howManyProgram]));
                var myList = [];
                var waterList = [];
                var prePostList = [];
                var centralEcPhList = [];
                var localEcPhList = [];
                var filterList = [];
                var addedUiKeys = <String>{};
                generalParameterLoop : for(var parameter in generalParameterList){
                  if(parameter.show == true && generalColumn.contains(parameter.uiKey) && !addedUiKeys.contains(parameter.uiKey)){
                    addedUiKeys.add(parameter.uiKey);
                    if(parameter.payloadKey == 'ProgramName') {
                      myList.add(getProgramName(dataSource['default']['program'], date['irrigation']['ProgramS_No'][howManyProgram]));
                    }
                    else if(parameter.payloadKey == 'Status') {
                      myList.add(date['irrigation']['Status'][howManyProgram]);
                    }
                    else if(parameter.payloadKey == 'SequenceData') {
                      myList.add(getName(date['irrigation']['SequenceData'][howManyProgram]));
                    }
                    else if(parameter.payloadKey == 'ZoneS_No' || parameter.payloadKey == 'ZoneName') {
                      if(date['irrigation']['ZoneName'] != null && howManyProgram < date['irrigation']['ZoneName'].length && date['irrigation']['ZoneName'][howManyProgram] != null && date['irrigation']['ZoneName'][howManyProgram].toString().isNotEmpty && date['irrigation']['ZoneName'][howManyProgram].toString() != '-'){
                        myList.add(date['irrigation']['ZoneName'][howManyProgram]);
                      }else if(date['irrigation']['ZoneS_No'] != null && howManyProgram < date['irrigation']['ZoneS_No'].length && date['irrigation']['ZoneS_No'][howManyProgram] != null){
                        myList.add(getSequenceName(dataSource['default']?['sequence'] ?? [], date['irrigation']['ZoneS_No'][howManyProgram]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'Date') {
                      myList.add(date['irrigation']['Date'][howManyProgram]);
                    }
                    else if(parameter.payloadKey == 'ProgramCategoryName' || parameter.payloadKey == 'ProgramCategory') {
                      if(date['irrigation']['ProgramCategoryName'] != null && howManyProgram < date['irrigation']['ProgramCategoryName'].length){
                        myList.add(getName(date['irrigation']['ProgramCategoryName'][howManyProgram]));
                      }else if(date['irrigation']['ProgramCategory'] != null && howManyProgram < date['irrigation']['ProgramCategory'].length){
                        myList.add(getName(date['irrigation']['ProgramCategory'][howManyProgram]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'HeadUnit') {
                      myList.add(getName(date['irrigation']['HeadUnit'][howManyProgram]));
                    }
                    else if(parameter.payloadKey == 'ScheduledStartTime') {
                      myList.add(formatSingleTime(date['irrigation']['ScheduledStartTime'][howManyProgram]));
                    }
                    else if(parameter.payloadKey == 'ActualStartTime') {
                      if(date['irrigation']['ActualStartTime'] != null && howManyProgram < date['irrigation']['ActualStartTime'].length){
                        myList.add(formatMultiTime(date['irrigation']['ActualStartTime'][howManyProgram]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualEndTime') {
                      if(date['irrigation']['ActualEndTime'] != null && howManyProgram < date['irrigation']['ActualEndTime'].length){
                        myList.add(formatMultiTime(date['irrigation']['ActualEndTime'][howManyProgram]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualStartReason') {
                      if(date['irrigation']['ActualStartReason'] != null && howManyProgram < date['irrigation']['ActualStartReason'].length){
                        myList.add(formatMultiReason(date['irrigation']['ActualStartReason'][howManyProgram]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualStopReason') {
                      if(date['irrigation']['ActualStopReason'] != null && howManyProgram < date['irrigation']['ActualStopReason'].length){
                        myList.add(formatMultiReason(date['irrigation']['ActualStopReason'][howManyProgram]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'Pump') {
                      myList.add(getName(date['irrigation']['Pump'][howManyProgram]));
                    }
                    else if(parameter.payloadKey == 'PumpCtAverage') {
                      if(howManyProgram < date['irrigation']['PumpCtAverage'].length){
                        myList.add(date['irrigation']['PumpCtAverage'][howManyProgram]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PumpCtMaximum') {
                      if(howManyProgram < date['irrigation']['PumpCtMaximum'].length){
                        myList.add(date['irrigation']['PumpCtMaximum'][howManyProgram]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PumpCtMinimum') {
                      if(howManyProgram < date['irrigation']['PumpCtMinimum'].length){
                        myList.add(date['irrigation']['PumpCtMinimum'][howManyProgram]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureAverage') {
                      if(howManyProgram < date['irrigation']['PressureAverage'].length){
                        myList.add(date['irrigation']['PressureAverage'][howManyProgram]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureMaximum') {
                      if(howManyProgram < date['irrigation']['PressureMaximum'].length){
                        myList.add(date['irrigation']['PressureMaximum'][howManyProgram]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureMinimum') {
                      if(howManyProgram < date['irrigation']['PressureMinimum'].length){
                        myList.add(date['irrigation']['PressureMinimum'][howManyProgram]);
                      }else{
                        myList.add('-');
                      }
                    }
                  }
                }
                waterParameterLoop : for(var parameter in waterParameterList){
                  if(parameter.payloadKey == 'IrrigationMethod') {
                    if(parameter.show == true){
                      waterList.add(date['irrigation']['IrrigationMethod'][howManyProgram] == 1 ? 'Time' : 'Quantity (L)');
                    }
                  }
                  if(parameter.payloadKey == 'IrrigationDuration_Quantity') {
                    graphData[indexOfDataToAdd]['totalTime'] = calculateTotalTime([graphData[indexOfDataToAdd]['totalTime'],date['irrigation']['IrrigationDurationCompleted'][howManyProgram]]);
                    graphData[indexOfDataToAdd]['data'].add(
                        getGraphData(
                            preValue: date['irrigation']['Pretime'][howManyProgram],
                            postValue: date['irrigation']['PostTime'][howManyProgram],
                            method: date['irrigation']['IrrigationMethod'][howManyProgram],
                            planned: date['irrigation']['IrrigationDuration_Quantity'][howManyProgram],
                            actualDuration: date['irrigation']['IrrigationDurationCompleted'][howManyProgram],
                            actualLiters: date['irrigation']['IrrigationQuantityCompleted'][howManyProgram],
                            flowRate: date['irrigation']['ValveFlowrate'][howManyProgram],
                            name: '${date['irrigation']['Date'][howManyProgram]}\n${date['irrigation']['ScheduledStartTime'][howManyProgram]}'
                        )
                    );
                    if(parameter.show == true){
                      waterList.add(date['irrigation']['IrrigationDuration_Quantity'][howManyProgram]);
                    }
                  }
                  if(parameter.payloadKey == 'IrrigationDurationCompleted/IrrigationQuantityCompleted') {
                    if(parameter.show == true){
                      var time = date['irrigation'][parameter.payloadKey.split('/')[0]][howManyProgram];
                      var quantity = date['irrigation'][parameter.payloadKey.split('/')[1]][howManyProgram];
                      waterList.add('$time HMS\n$quantity L');
                    }
                  }
                }
                prePostParameterLoop : for(var parameter in prePostParameterList){
                  if(parameter.payloadKey == 'PrePostMethod') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation']['PrePostMethod'][howManyProgram] == 1 ? 'Time' : 'Quantity (L)');
                    }
                  }
                  if(parameter.payloadKey == 'Pretime/PreQty') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation'][date['irrigation']['PrePostMethod'][howManyProgram] == 1 ? 'Pretime' : 'PreQty'][howManyProgram]);
                    }
                  }
                  if(parameter.payloadKey == 'PostTime/PostQty') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation'][date['irrigation']['PrePostMethod'][howManyProgram] == 1 ? 'PostTime' : 'PostQty'][howManyProgram]);
                    }
                  }
                }
                filterParameterLoop : for(var parameter in filterParameterList){
                  if(parameter.payloadKey == 'CentralFilterName') {
                    if(parameter.show == true){
                      var filterName = howManyProgram < date['irrigation']['CentralFilterName'].length ? date['irrigation']['CentralFilterName'][howManyProgram] : '';
                      var filterDuration = howManyProgram < date['irrigation']['CentralFilterOnDuration'].length ? date['irrigation']['CentralFilterOnDuration'][howManyProgram] : '';
                      var listOfFilterName = (filterName == null || filterName.isEmpty) ? [] : filterName.split('_');
                      var listOfFilterDuration = (filterDuration == null || filterDuration.isEmpty) ? [] : filterDuration.split('_');
                      var listOfNameAndDuration = [];
                      for(var name = 0;name < listOfFilterName.length;name++){
                        if(listOfFilterDuration.length > name){
                          listOfNameAndDuration.add('${listOfFilterName[name]} - ${listOfFilterDuration[name]}');
                        }else{
                          listOfNameAndDuration.add('${listOfFilterName[name]} - N/A');
                        }
                      }
                      filterList.add(listOfNameAndDuration.join('\n'));
                    }
                  }
                  if(parameter.payloadKey == 'LocalFilterName') {
                    if(parameter.show == true){
                      var filterName = howManyProgram < date['irrigation']['LocalFilterName'].length ? date['irrigation']['LocalFilterName'][howManyProgram] : '';
                      var filterDuration = howManyProgram < date['irrigation']['LocalFilterOnDuration'].length ? date['irrigation']['LocalFilterOnDuration'][howManyProgram] : '';
                      var listOfFilterName = (filterName == null || filterName.isEmpty) ? [] : filterName.split('_');
                      var listOfFilterDuration = (filterDuration == null || filterDuration.isEmpty) ? [] : filterDuration.split('_');
                      var listOfNameAndDuration = [];
                      for(var name = 0;name < listOfFilterName.length;name++){
                        if(listOfFilterDuration.length > name){
                          listOfNameAndDuration.add('${listOfFilterName[name]} - ${listOfFilterDuration[name]}');
                        }else{
                          listOfNameAndDuration.add('${listOfFilterName[name]} - N/A');
                        }
                      }
                      filterList.add(listOfNameAndDuration.join('\n'));
                    }
                  }
                }
                centralEcPhParameterLoop : for(var parameter in centralEcPhParameterList){
                  if(parameter.payloadKey == 'CentralEcSetValue') {
                    if(parameter.show == true){
                      centralEcPhList.add(date['irrigation']['CentralEcSetValue'][howManyProgram]);
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcAverage'] == null || date['irrigation']['CentralEcAverage'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcAverage'][howManyProgram]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcMaximum'] == null || date['irrigation']['CentralEcMaximum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcMaximum'][howManyProgram]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcMinimum'] == null || date['irrigation']['CentralEcMinimum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcMinimum'][howManyProgram]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhSetValue') {
                    if(parameter.show == true){
                      centralEcPhList.add(date['irrigation']['CentralPhSetValue'][howManyProgram]);
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhAverage'] == null || date['irrigation']['CentralPhAverage'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhAverage'][howManyProgram]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhMaximum'] == null || date['irrigation']['CentralPhMaximum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhMaximum'][howManyProgram]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhMinimum'] == null || date['irrigation']['CentralPhMinimum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhMinimum'][howManyProgram]);
                      }
                    }
                  }
                }
                localEcPhParameterLoop : for(var parameter in localEcPhParameterList){
                  if(parameter.payloadKey == 'LocalEcSetValue') {
                    if(parameter.show == true){
                      localEcPhList.add(date['irrigation']['LocalEcSetValue'][howManyProgram]);
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcAverage'] == null || date['irrigation']['LocalEcAverage'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcAverage'][howManyProgram]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcMaximum'] == null || date['irrigation']['LocalEcMaximum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcMaximum'][howManyProgram]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcMinimum'] == null || date['irrigation']['LocalEcMinimum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcMinimum'][howManyProgram]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhSetValue') {
                    if(parameter.show == true){
                      localEcPhList.add(date['irrigation']['LocalPhSetValue'][howManyProgram]);
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhAverage'] == null || date['irrigation']['LocalPhAverage'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhAverage'][howManyProgram]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhMaximum'] == null || date['irrigation']['LocalPhMaximum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhMaximum'][howManyProgram]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhMinimum'] == null || date['irrigation']['LocalPhMinimum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhMinimum'][howManyProgram]);
                      }
                    }
                  }
                }
                generalColumnData.add(myList);
                waterColumnData.add(waterList);
                prePostColumnData.add(prePostList);
                filterColumnData.add(filterList);
                centralEcPhColumnData.add(centralEcPhList);
                centralChannel1ColumnData.add(getChannelData(channelNo: 0, channelParameterList: centralChannel1ParameterList, date: date, howMany: howManyProgram, central: true));
                centralChannel2ColumnData.add(getChannelData(channelNo: 1, channelParameterList: centralChannel2ParameterList, date: date, howMany: howManyProgram, central: true));
                centralChannel3ColumnData.add(getChannelData(channelNo: 2, channelParameterList: centralChannel3ParameterList, date: date, howMany: howManyProgram, central: true));
                centralChannel4ColumnData.add(getChannelData(channelNo: 3, channelParameterList: centralChannel4ParameterList, date: date, howMany: howManyProgram, central: true));
                centralChannel5ColumnData.add(getChannelData(channelNo: 4, channelParameterList: centralChannel5ParameterList, date: date, howMany: howManyProgram, central: true));
                centralChannel6ColumnData.add(getChannelData(channelNo: 5, channelParameterList: centralChannel6ParameterList, date: date, howMany: howManyProgram, central: true));
                centralChannel7ColumnData.add(getChannelData(channelNo: 6, channelParameterList: centralChannel7ParameterList, date: date, howMany: howManyProgram, central: true));
                centralChannel8ColumnData.add(getChannelData(channelNo: 7, channelParameterList: centralChannel8ParameterList, date: date, howMany: howManyProgram, central: true));
                localEcPhColumnData.add(localEcPhList);
                localChannel1ColumnData.add(getChannelData(channelNo: 0, channelParameterList: localChannel1ParameterList, date: date, howMany: howManyProgram, central: false));
                localChannel2ColumnData.add(getChannelData(channelNo: 1, channelParameterList: localChannel2ParameterList, date: date, howMany: howManyProgram, central: false));
                localChannel3ColumnData.add(getChannelData(channelNo: 2, channelParameterList: localChannel3ParameterList, date: date, howMany: howManyProgram, central: false));
                localChannel4ColumnData.add(getChannelData(channelNo: 3, channelParameterList: localChannel4ParameterList, date: date, howMany: howManyProgram, central: false));
                localChannel5ColumnData.add(getChannelData(channelNo: 4, channelParameterList: localChannel5ParameterList, date: date, howMany: howManyProgram, central: false));
                localChannel6ColumnData.add(getChannelData(channelNo: 5, channelParameterList: localChannel6ParameterList, date: date, howMany: howManyProgram, central: false));
                localChannel7ColumnData.add(getChannelData(channelNo: 6, channelParameterList: localChannel7ParameterList, date: date, howMany: howManyProgram, central: false));
                localChannel8ColumnData.add(getChannelData(channelNo: 7, channelParameterList: localChannel8ParameterList, date: date, howMany: howManyProgram, central: false));
              }
            }
          }
        }
      }
    }
    return {
      'fixedColumn' : fixedColumn,
      'fixedColumnData': fixedColumnData,
      'generalColumn' : generalColumn,
      'generalColumnData' : generalColumnData,
      'waterColumn' : waterColumn,
      'waterColumnData' : waterColumnData,
      'prePostColumn' : prePostColumn,
      'prePostColumnData' : prePostColumnData,
      'filterColumn' : filterColumn,
      'filterColumnData' : filterColumnData,
      'centralEcPhColumn' : centralEcPhColumn,
      'centralEcPhColumnData' : centralEcPhColumnData,
      'centralChannel1Column' : centralChannel1Column,
      'centralChannel1ColumnData' : centralChannel1ColumnData,
      'centralChannel2Column' : centralChannel2Column,
      'centralChannel2ColumnData' : centralChannel2ColumnData,
      'centralChannel3Column' : centralChannel3Column,
      'centralChannel3ColumnData' : centralChannel3ColumnData,
      'centralChannel4Column' : centralChannel4Column,
      'centralChannel4ColumnData' : centralChannel4ColumnData,
      'centralChannel5Column' : centralChannel5Column,
      'centralChannel5ColumnData' : centralChannel5ColumnData,
      'centralChannel6Column' : centralChannel6Column,
      'centralChannel6ColumnData' : centralChannel6ColumnData,
      'centralChannel7Column' : centralChannel7Column,
      'centralChannel7ColumnData' : centralChannel7ColumnData,
      'centralChannel8Column' : centralChannel8Column,
      'centralChannel8ColumnData' : centralChannel8ColumnData,
      'localEcPhColumn' : localEcPhColumn,
      'localEcPhColumnData' : localEcPhColumnData,
      'localChannel1Column' : localChannel1Column,
      'localChannel1ColumnData' : localChannel1ColumnData,
      'localChannel2Column' : localChannel2Column,
      'localChannel2ColumnData' : localChannel2ColumnData,
      'localChannel3Column' : localChannel3Column,
      'localChannel3ColumnData' : localChannel3ColumnData,
      'localChannel4Column' : localChannel4Column,
      'localChannel4ColumnData' : localChannel4ColumnData,
      'localChannel5Column' : localChannel5Column,
      'localChannel5ColumnData' : localChannel5ColumnData,
      'localChannel6Column' : localChannel6Column,
      'localChannel6ColumnData' : localChannel6ColumnData,
      'localChannel7Column' : localChannel7Column,
      'localChannel7ColumnData' : localChannel7ColumnData,
      'localChannel8Column' : localChannel8Column,
      'localChannel8ColumnData' : localChannel8ColumnData,
      'graphData' : graphData
    };
  }

  Map<String,dynamic> editDateWise(dynamic dataSource,List<dynamic> noOfDate){
    var generalColumn = [...getColumn(generalParameterList)];
    var generalColumnData = [];
    var fixedColumnData = [];
    var waterColumn = [...getColumn(waterParameterList)];
    var waterColumnData = [];
    var prePostColumn = [...getColumn(prePostParameterList)];
    var prePostColumnData = [];
    var filterColumn = [...getColumn(filterParameterList)];
    var filterColumnData = [];
    var centralEcPhColumn = [...getColumn(centralEcPhParameterList)];
    var centralEcPhColumnData = [];
    var centralChannel1Column = [...getColumn(centralChannel1ParameterList)];
    var centralChannel1ColumnData = [];
    var centralChannel2Column = [...getColumn(centralChannel2ParameterList)];
    var centralChannel2ColumnData = [];
    var centralChannel3Column = [...getColumn(centralChannel3ParameterList)];
    var centralChannel3ColumnData = [];
    var centralChannel4Column = [...getColumn(centralChannel4ParameterList)];
    var centralChannel4ColumnData = [];
    var centralChannel5Column = [...getColumn(centralChannel5ParameterList)];
    var centralChannel5ColumnData = [];
    var centralChannel6Column = [...getColumn(centralChannel6ParameterList)];
    var centralChannel6ColumnData = [];
    var centralChannel7Column = [...getColumn(centralChannel7ParameterList)];
    var centralChannel7ColumnData = [];
    var centralChannel8Column = [...getColumn(centralChannel8ParameterList)];
    var centralChannel8ColumnData = [];
    var localEcPhColumn = [...getColumn(localEcPhParameterList)];
    var localEcPhColumnData = [];
    var localChannel1Column = [...getColumn(localChannel1ParameterList)];
    var localChannel1ColumnData = [];
    var localChannel2Column = [...getColumn(localChannel2ParameterList)];
    var localChannel2ColumnData = [];
    var localChannel3Column = [...getColumn(localChannel3ParameterList)];
    var localChannel3ColumnData = [];
    var localChannel4Column = [...getColumn(localChannel4ParameterList)];
    var localChannel4ColumnData = [];
    var localChannel5Column = [...getColumn(localChannel5ParameterList)];
    var localChannel5ColumnData = [];
    var localChannel6Column = [...getColumn(localChannel6ParameterList)];
    var localChannel6ColumnData = [];
    var localChannel7Column = [...getColumn(localChannel7ParameterList)];
    var localChannel7ColumnData = [];
    var localChannel8Column = [...getColumn(localChannel8ParameterList)];
    var localChannel8ColumnData = [];
    var graphData = [];
    var fixedColumn = 'Date';
    generalColumn.removeWhere((item) => item == 'Date');
    print("noOfDate  => ${noOfDate}");
    for(var findDate in noOfDate){
      if(findDate['show'] == true){
        graphData.add({
          'name' : findDate['name'],
          'totalTime' : '00:00:00',
          'data' : []
        });
        var indexOfDataToAdd = graphData.length - 1;
        for(var date in dataSource['log']){
          if(date['irrigation'].isNotEmpty){
            for(var howManyDate = 0;howManyDate < date['irrigation']['Date'].length;howManyDate++){
              if(date['irrigation']['Date'][howManyDate].contains(findDate['name'])){
                fixedColumnData.add(findDate['name']);
                var myList = [];
                var waterList = [];
                var filterList = [];
                var prePostList = [];
                var centralEcPhList = [];
                var localEcPhList = [];
                var addedUiKeys = <String>{};
                generalParameterLoop : for(var parameter in generalParameterList){
                  if(parameter.show == true && generalColumn.contains(parameter.uiKey) && !addedUiKeys.contains(parameter.uiKey)){
                    addedUiKeys.add(parameter.uiKey);
                    if(parameter.payloadKey == 'ProgramName') {
                      myList.add(getProgramName(dataSource['default']['program'], date['irrigation']['ProgramS_No'][howManyDate]));
                    }
                    else if(parameter.payloadKey == 'Status') {
                      myList.add(date['irrigation']['Status'][howManyDate]);
                    }
                    else if(parameter.payloadKey == 'SequenceData') {
                      myList.add(getName(date['irrigation']['SequenceData'][howManyDate]));
                    }
                    else if(parameter.payloadKey == 'ZoneS_No' || parameter.payloadKey == 'ZoneName') {
                      if(date['irrigation']['ZoneName'] != null && howManyDate < date['irrigation']['ZoneName'].length && date['irrigation']['ZoneName'][howManyDate] != null && date['irrigation']['ZoneName'][howManyDate].toString().isNotEmpty && date['irrigation']['ZoneName'][howManyDate].toString() != '-'){
                        myList.add(date['irrigation']['ZoneName'][howManyDate]);
                      }else if(date['irrigation']['ZoneS_No'] != null && howManyDate < date['irrigation']['ZoneS_No'].length && date['irrigation']['ZoneS_No'][howManyDate] != null){
                        myList.add(getSequenceName(dataSource['default']?['sequence'] ?? [], date['irrigation']['ZoneS_No'][howManyDate]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'Date') {
                      myList.add(date['irrigation']['Date'][howManyDate]);
                    }
                    else if(parameter.payloadKey == 'ProgramCategoryName' || parameter.payloadKey == 'ProgramCategory') {
                      if(date['irrigation']['ProgramCategoryName'] != null && howManyDate < date['irrigation']['ProgramCategoryName'].length){
                        myList.add(getName(date['irrigation']['ProgramCategoryName'][howManyDate]));
                      }else if(date['irrigation']['ProgramCategory'] != null && howManyDate < date['irrigation']['ProgramCategory'].length){
                        myList.add(getName(date['irrigation']['ProgramCategory'][howManyDate]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'HeadUnit') {
                      myList.add(getName(date['irrigation']['HeadUnit'][howManyDate]));
                    }
                    else if(parameter.payloadKey == 'ScheduledStartTime') {
                      myList.add(formatSingleTime(date['irrigation']['ScheduledStartTime'][howManyDate]));
                    }
                    else if(parameter.payloadKey == 'ActualStartTime') {
                      if(date['irrigation']['ActualStartTime'] != null && howManyDate < date['irrigation']['ActualStartTime'].length){
                        myList.add(formatMultiTime(date['irrigation']['ActualStartTime'][howManyDate]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualEndTime') {
                      if(date['irrigation']['ActualEndTime'] != null && howManyDate < date['irrigation']['ActualEndTime'].length){
                        myList.add(formatMultiTime(date['irrigation']['ActualEndTime'][howManyDate]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualStartReason') {
                      if(date['irrigation']['ActualStartReason'] != null && howManyDate < date['irrigation']['ActualStartReason'].length){
                        myList.add(formatMultiReason(date['irrigation']['ActualStartReason'][howManyDate]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualStopReason') {
                      if(date['irrigation']['ActualStopReason'] != null && howManyDate < date['irrigation']['ActualStopReason'].length){
                        myList.add(formatMultiReason(date['irrigation']['ActualStopReason'][howManyDate]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'Pump') {
                      myList.add(getName(date['irrigation']['Pump'][howManyDate]));
                    }
                    else if(parameter.payloadKey == 'PumpCtAverage') {
                      if(howManyDate < date['irrigation']['PumpCtAverage'].length){
                        myList.add(date['irrigation']['PumpCtAverage'][howManyDate]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PumpCtMaximum') {
                      if(howManyDate < date['irrigation']['PumpCtMaximum'].length){
                        myList.add(date['irrigation']['PumpCtMaximum'][howManyDate]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PumpCtMinimum') {
                      if(howManyDate < date['irrigation']['PumpCtMinimum'].length){
                        myList.add(date['irrigation']['PumpCtMinimum'][howManyDate]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureAverage') {
                      if(howManyDate < date['irrigation']['PressureAverage'].length){
                        myList.add(date['irrigation']['PressureAverage'][howManyDate]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureMaximum') {
                      if(howManyDate < date['irrigation']['PressureMaximum'].length){
                        myList.add(date['irrigation']['PressureMaximum'][howManyDate]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureMinimum') {
                      if(howManyDate < date['irrigation']['PressureMinimum'].length){
                        myList.add(date['irrigation']['PressureMinimum'][howManyDate]);
                      }else{
                        myList.add('-');
                      }
                    }
                  }
                }
                waterParameterLoop : for(var parameter in waterParameterList){
                  if(parameter.payloadKey == 'IrrigationMethod') {
                    if(parameter.show == true){
                      waterList.add(date['irrigation']['IrrigationMethod'][howManyDate] == 1 ? 'Time' : 'Quantity (L)');
                    }
                  }
                  if(parameter.payloadKey == 'IrrigationDuration_Quantity') {
                    graphData[indexOfDataToAdd]['totalTime'] = calculateTotalTime([graphData[indexOfDataToAdd]['totalTime'],date['irrigation']['IrrigationDurationCompleted'][howManyDate]]);
                    graphData[indexOfDataToAdd]['data'].add(
                        getGraphData(
                            preValue: date['irrigation']['Pretime'][howManyDate],
                            postValue: date['irrigation']['PostTime'][howManyDate],
                            method: date['irrigation']['IrrigationMethod'][howManyDate],
                            planned: date['irrigation']['IrrigationDuration_Quantity'][howManyDate],
                            actualDuration: date['irrigation']['IrrigationDurationCompleted'][howManyDate],
                            actualLiters: date['irrigation']['IrrigationQuantityCompleted'][howManyDate],
                            flowRate: date['irrigation']['ValveFlowrate'][howManyDate],
                            name: '${date['irrigation']['Date'][howManyDate]}\n${date['irrigation']['ScheduledStartTime'][howManyDate]}'
                        )
                    );
                    if(parameter.show == true){
                      waterList.add(date['irrigation']['IrrigationDuration_Quantity'][howManyDate]);
                    }
                  }
                  if(parameter.payloadKey == 'IrrigationDurationCompleted/IrrigationQuantityCompleted') {
                    if(parameter.show == true){
                      var time = date['irrigation'][parameter.payloadKey.split('/')[0]][howManyDate];
                      var quantity = date['irrigation'][parameter.payloadKey.split('/')[1]][howManyDate];
                      waterList.add('$time HMS\n$quantity L');
                    }
                  }
                }
                prePostParameterLoop : for(var parameter in prePostParameterList){
                  if(parameter.payloadKey == 'PrePostMethod') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation']['PrePostMethod'][howManyDate] == 1 ? 'Time' : 'Quantity (L)');
                    }
                  }
                  if(parameter.payloadKey == 'Pretime/PreQty') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation'][date['irrigation']['PrePostMethod'][howManyDate] == 1 ? 'Pretime' : 'PreQty'][howManyDate]);
                    }
                  }
                  if(parameter.payloadKey == 'PostTime/PostQty') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation'][date['irrigation']['PrePostMethod'][howManyDate] == 1 ? 'PostTime' : 'PostQty'][howManyDate]);
                    }
                  }
                }
                filterParameterLoop : for(var parameter in filterParameterList){
                  if(parameter.payloadKey == 'CentralFilterName') {
                    if(parameter.show == true){
                      var filterName = howManyDate < date['irrigation']['CentralFilterName'].length ? date['irrigation']['CentralFilterName'][howManyDate] : '';
                      var filterDuration = howManyDate < date['irrigation']['CentralFilterOnDuration'].length ? date['irrigation']['CentralFilterOnDuration'][howManyDate] : '';
                      var listOfFilterName = (filterName == null || filterName.isEmpty) ? [] : filterName.split('_');
                      var listOfFilterDuration = (filterDuration == null || filterDuration.isEmpty) ? [] : filterDuration.split('_');
                      var listOfNameAndDuration = [];
                      for(var name = 0;name < listOfFilterName.length;name++){
                        if(name < listOfFilterDuration.length){
                          listOfNameAndDuration.add('${listOfFilterName[name]} - ${listOfFilterDuration[name]}');
                        }else{
                          listOfNameAndDuration.add('${listOfFilterName[name]} - N/A');
                        }
                      }
                      filterList.add(listOfNameAndDuration.join('\n'));
                    }
                  }
                  if(parameter.payloadKey == 'LocalFilterName') {
                    if(parameter.show == true){
                      var filterName = howManyDate < date['irrigation']['LocalFilterName'].length ? date['irrigation']['LocalFilterName'][howManyDate] : '';
                      var filterDuration = howManyDate < date['irrigation']['LocalFilterOnDuration'].length ? date['irrigation']['LocalFilterOnDuration'][howManyDate] : '';
                      var listOfFilterName = (filterName == null || filterName.isEmpty) ? [] : filterName.split('_');
                      var listOfFilterDuration = (filterDuration == null || filterDuration.isEmpty) ? [] : filterDuration.split('_');
                      var listOfNameAndDuration = [];
                      for(var name = 0;name < listOfFilterName.length;name++){
                        if(listOfFilterDuration.length > name){
                          listOfNameAndDuration.add('${listOfFilterName[name]} - ${listOfFilterDuration[name]}');
                        }else{
                          listOfNameAndDuration.add('${listOfFilterName[name]} - N/A');
                        }
                      }
                      filterList.add(listOfNameAndDuration.join('\n'));
                    }
                  }
                }
                centralEcPhParameterLoop : for(var parameter in centralEcPhParameterList){
                  if(parameter.payloadKey == 'CentralEcSetValue') {
                    if(parameter.show == true){
                      centralEcPhList.add(date['irrigation']['CentralEcSetValue'][howManyDate]);
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcAverage'] == null || date['irrigation']['CentralEcAverage'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcAverage'][howManyDate]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcMaximum'] == null || date['irrigation']['CentralEcMaximum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcMaximum'][howManyDate]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcMinimum'] == null || date['irrigation']['CentralEcMinimum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcMinimum'][howManyDate]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhSetValue') {
                    if(parameter.show == true){
                      centralEcPhList.add(date['irrigation']['CentralPhSetValue'][howManyDate]);
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhAverage'] == null || date['irrigation']['CentralPhAverage'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhAverage'][howManyDate]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhMaximum'] == null || date['irrigation']['CentralPhMaximum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhMaximum'][howManyDate]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhMinimum'] == null || date['irrigation']['CentralPhMinimum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhMinimum'][howManyDate]);
                      }
                    }
                  }
                }
                localEcPhParameterLoop : for(var parameter in localEcPhParameterList){
                  if(parameter.payloadKey == 'LocalEcSetValue') {
                    if(parameter.show == true){
                      localEcPhList.add(date['irrigation']['LocalEcSetValue'][howManyDate]);
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcAverage'] == null || date['irrigation']['LocalEcAverage'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcAverage'][howManyDate]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcMaximum'] == null || date['irrigation']['LocalEcMaximum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcMaximum'][howManyDate]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcMinimum'] == null || date['irrigation']['LocalEcMinimum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcMinimum'][howManyDate]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhSetValue') {
                    if(parameter.show == true){
                      localEcPhList.add(date['irrigation']['LocalPhSetValue'][howManyDate]);
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhAverage'] == null || date['irrigation']['LocalPhAverage'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhAverage'][howManyDate]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhMaximum'] == null || date['irrigation']['LocalPhMaximum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhMaximum'][howManyDate]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhMinimum'] == null || date['irrigation']['LocalPhMinimum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhMinimum'][howManyDate]);
                      }
                    }
                  }
                }
                generalColumnData.add(myList);
                waterColumnData.add(waterList);
                filterColumnData.add(filterList);
                prePostColumnData.add(prePostList);
                centralEcPhColumnData.add(centralEcPhList);
                centralChannel1ColumnData.add(getChannelData(channelNo: 0, channelParameterList: centralChannel1ParameterList, date: date, howMany: howManyDate, central: true));
                centralChannel2ColumnData.add(getChannelData(channelNo: 1, channelParameterList: centralChannel2ParameterList, date: date, howMany: howManyDate, central: true));
                centralChannel3ColumnData.add(getChannelData(channelNo: 2, channelParameterList: centralChannel3ParameterList, date: date, howMany: howManyDate, central: true));
                centralChannel4ColumnData.add(getChannelData(channelNo: 3, channelParameterList: centralChannel4ParameterList, date: date, howMany: howManyDate, central: true));
                centralChannel5ColumnData.add(getChannelData(channelNo: 4, channelParameterList: centralChannel5ParameterList, date: date, howMany: howManyDate, central: true));
                centralChannel6ColumnData.add(getChannelData(channelNo: 5, channelParameterList: centralChannel6ParameterList, date: date, howMany: howManyDate, central: true));
                centralChannel7ColumnData.add(getChannelData(channelNo: 6, channelParameterList: centralChannel7ParameterList, date: date, howMany: howManyDate, central: true));
                centralChannel8ColumnData.add(getChannelData(channelNo: 7, channelParameterList: centralChannel8ParameterList, date: date, howMany: howManyDate, central: true));
                localEcPhColumnData.add(localEcPhList);
                localChannel1ColumnData.add(getChannelData(channelNo: 0, channelParameterList: localChannel1ParameterList, date: date, howMany: howManyDate, central: false));
                localChannel2ColumnData.add(getChannelData(channelNo: 1, channelParameterList: localChannel2ParameterList, date: date, howMany: howManyDate, central: false));
                localChannel3ColumnData.add(getChannelData(channelNo: 2, channelParameterList: localChannel3ParameterList, date: date, howMany: howManyDate, central: false));
                localChannel4ColumnData.add(getChannelData(channelNo: 3, channelParameterList: localChannel4ParameterList, date: date, howMany: howManyDate, central: false));
                localChannel5ColumnData.add(getChannelData(channelNo: 4, channelParameterList: localChannel5ParameterList, date: date, howMany: howManyDate, central: false));
                localChannel6ColumnData.add(getChannelData(channelNo: 5, channelParameterList: localChannel6ParameterList, date: date, howMany: howManyDate, central: false));
                localChannel7ColumnData.add(getChannelData(channelNo: 6, channelParameterList: localChannel7ParameterList, date: date, howMany: howManyDate, central: false));
                localChannel8ColumnData.add(getChannelData(channelNo: 7, channelParameterList: localChannel8ParameterList, date: date, howMany: howManyDate, central: false));

              }
            }
          }
        }
      }
    }
    var sendingData = {
      'fixedColumn' : fixedColumn,
      'fixedColumnData': fixedColumnData,
      'generalColumn' : generalColumn,
      'generalColumnData' : generalColumnData,
      'waterColumn' : waterColumn,
      'waterColumnData' : waterColumnData,
      'filterColumn' : filterColumn,
      'filterColumnData' : filterColumnData,
      'prePostColumn' : prePostColumn,
      'prePostColumnData' : prePostColumnData,
      'centralEcPhColumn' : centralEcPhColumn,
      'centralEcPhColumnData' : centralEcPhColumnData,
      'centralChannel1Column' : centralChannel1Column,
      'centralChannel1ColumnData' : centralChannel1ColumnData,
      'centralChannel2Column' : centralChannel2Column,
      'centralChannel2ColumnData' : centralChannel2ColumnData,
      'centralChannel3Column' : centralChannel3Column,
      'centralChannel3ColumnData' : centralChannel3ColumnData,
      'centralChannel4Column' : centralChannel4Column,
      'centralChannel4ColumnData' : centralChannel4ColumnData,
      'centralChannel5Column' : centralChannel5Column,
      'centralChannel5ColumnData' : centralChannel5ColumnData,
      'centralChannel6Column' : centralChannel6Column,
      'centralChannel6ColumnData' : centralChannel6ColumnData,
      'centralChannel7Column' : centralChannel7Column,
      'centralChannel7ColumnData' : centralChannel7ColumnData,
      'centralChannel8Column' : centralChannel8Column,
      'centralChannel8ColumnData' : centralChannel8ColumnData,
      'localEcPhColumn' : localEcPhColumn,
      'localEcPhColumnData' : localEcPhColumnData,
      'localChannel1Column' : localChannel1Column,
      'localChannel1ColumnData' : localChannel1ColumnData,
      'localChannel2Column' : localChannel2Column,
      'localChannel2ColumnData' : localChannel2ColumnData,
      'localChannel3Column' : localChannel3Column,
      'localChannel3ColumnData' : localChannel3ColumnData,
      'localChannel4Column' : localChannel4Column,
      'localChannel4ColumnData' : localChannel4ColumnData,
      'localChannel5Column' : localChannel5Column,
      'localChannel5ColumnData' : localChannel5ColumnData,
      'localChannel6Column' : localChannel6Column,
      'localChannel6ColumnData' : localChannel6ColumnData,
      'localChannel7Column' : localChannel7Column,
      'localChannel7ColumnData' : localChannel7ColumnData,
      'localChannel8Column' : localChannel8Column,
      'localChannel8ColumnData' : localChannel8ColumnData,
      'graphData' : graphData
    };
    return sendingData;
  }

  Map<String,dynamic> editStatusWise(dynamic dataSource,List<dynamic> noOfStatus){
    var generalColumn = [...getColumn(generalParameterList)];
    var generalColumnData = [];
    var fixedColumnData = [];
    var waterColumn = [...getColumn(waterParameterList)];
    var waterColumnData = [];
    var filterColumn = [...getColumn(filterParameterList)];
    var filterColumnData = [];
    var prePostColumn = [...getColumn(prePostParameterList)];
    var prePostColumnData = [];
    var centralEcPhColumn = [...getColumn(centralEcPhParameterList)];
    var centralEcPhColumnData = [];
    var centralChannel1Column = [...getColumn(centralChannel1ParameterList)];
    var centralChannel1ColumnData = [];
    var centralChannel2Column = [...getColumn(centralChannel2ParameterList)];
    var centralChannel2ColumnData = [];
    var centralChannel3Column = [...getColumn(centralChannel3ParameterList)];
    var centralChannel3ColumnData = [];
    var centralChannel4Column = [...getColumn(centralChannel4ParameterList)];
    var centralChannel4ColumnData = [];
    var centralChannel5Column = [...getColumn(centralChannel5ParameterList)];
    var centralChannel5ColumnData = [];
    var centralChannel6Column = [...getColumn(centralChannel6ParameterList)];
    var centralChannel6ColumnData = [];
    var centralChannel7Column = [...getColumn(centralChannel7ParameterList)];
    var centralChannel7ColumnData = [];
    var centralChannel8Column = [...getColumn(centralChannel8ParameterList)];
    var centralChannel8ColumnData = [];
    var localEcPhColumn = [...getColumn(localEcPhParameterList)];
    var localEcPhColumnData = [];
    var localChannel1Column = [...getColumn(localChannel1ParameterList)];
    var localChannel1ColumnData = [];
    var localChannel2Column = [...getColumn(localChannel2ParameterList)];
    var localChannel2ColumnData = [];
    var localChannel3Column = [...getColumn(localChannel3ParameterList)];
    var localChannel3ColumnData = [];
    var localChannel4Column = [...getColumn(localChannel4ParameterList)];
    var localChannel4ColumnData = [];
    var localChannel5Column = [...getColumn(localChannel5ParameterList)];
    var localChannel5ColumnData = [];
    var localChannel6Column = [...getColumn(localChannel6ParameterList)];
    var localChannel6ColumnData = [];
    var localChannel7Column = [...getColumn(localChannel7ParameterList)];
    var localChannel7ColumnData = [];
    var localChannel8Column = [...getColumn(localChannel8ParameterList)];
    var localChannel8ColumnData = [];
    var graphData = [];
    var fixedColumn = 'Status';
    generalColumn.removeWhere((item) => item == 'Status');

    for(var findStatus in noOfStatus){
      if(findStatus['show'] == true){
        graphData.add({
          'name' : getStatus(findStatus['name'].toString())['status'],
          'totalTime' : '00:00:00',
          'data' : []
        });
        var indexOfDataToAdd = graphData.length - 1;
        for(var date in dataSource['log']){
          if(date['irrigation'].isNotEmpty){
            for(var howManyStatus = 0;howManyStatus < date['irrigation']['Status'].length;howManyStatus++){
              if(date['irrigation']['Status'][howManyStatus] == findStatus['name']){
                fixedColumnData.add(getStatus(findStatus['name'])['status']);
                var myList = [];
                var waterList = [];
                var prePostList = [];
                var centralEcPhList = [];
                var localEcPhList = [];
                var filterList = [];
                var addedUiKeys = <String>{};
                generalParameterLoop : for(var parameter in generalParameterList){
                  if(parameter.show == true && generalColumn.contains(parameter.uiKey) && !addedUiKeys.contains(parameter.uiKey)){
                    addedUiKeys.add(parameter.uiKey);
                    if(parameter.payloadKey == 'ProgramName') {
                      myList.add(getProgramName(dataSource['default']['program'], date['irrigation']['ProgramS_No'][howManyStatus]));
                    }
                    else if(parameter.payloadKey == 'Status') {
                      myList.add(date['irrigation']['Status'][howManyStatus]);
                    }
                    else if(parameter.payloadKey == 'SequenceData') {
                      myList.add(getName(date['irrigation']['SequenceData'][howManyStatus]));
                    }
                    else if(parameter.payloadKey == 'ZoneS_No' || parameter.payloadKey == 'ZoneName') {
                      if(date['irrigation']['ZoneName'] != null && howManyStatus < date['irrigation']['ZoneName'].length && date['irrigation']['ZoneName'][howManyStatus] != null && date['irrigation']['ZoneName'][howManyStatus].toString().isNotEmpty && date['irrigation']['ZoneName'][howManyStatus].toString() != '-'){
                        myList.add(date['irrigation']['ZoneName'][howManyStatus]);
                      }else if(date['irrigation']['ZoneS_No'] != null && howManyStatus < date['irrigation']['ZoneS_No'].length && date['irrigation']['ZoneS_No'][howManyStatus] != null){
                        myList.add(getSequenceName(dataSource['default']?['sequence'] ?? [], date['irrigation']['ZoneS_No'][howManyStatus]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'Date') {
                      myList.add(date['irrigation']['Date'][howManyStatus]);
                    }
                    else if(parameter.payloadKey == 'ProgramCategoryName' || parameter.payloadKey == 'ProgramCategory') {
                      if(date['irrigation']['ProgramCategoryName'] != null && howManyStatus < date['irrigation']['ProgramCategoryName'].length){
                        myList.add(getName(date['irrigation']['ProgramCategoryName'][howManyStatus]));
                      }else if(date['irrigation']['ProgramCategory'] != null && howManyStatus < date['irrigation']['ProgramCategory'].length){
                        myList.add(getName(date['irrigation']['ProgramCategory'][howManyStatus]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'HeadUnit') {
                      myList.add(getName(date['irrigation']['HeadUnit'][howManyStatus]));
                    }
                    else if(parameter.payloadKey == 'ScheduledStartTime') {
                      myList.add(formatSingleTime(date['irrigation']['ScheduledStartTime'][howManyStatus]));
                    }
                    else if(parameter.payloadKey == 'ActualStartTime') {
                      if(date['irrigation']['ActualStartTime'] != null && howManyStatus < date['irrigation']['ActualStartTime'].length){
                        myList.add(formatMultiTime(date['irrigation']['ActualStartTime'][howManyStatus]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualEndTime') {
                      if(date['irrigation']['ActualEndTime'] != null && howManyStatus < date['irrigation']['ActualEndTime'].length){
                        myList.add(formatMultiTime(date['irrigation']['ActualEndTime'][howManyStatus]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualStartReason') {
                      if(date['irrigation']['ActualStartReason'] != null && howManyStatus < date['irrigation']['ActualStartReason'].length){
                        myList.add(formatMultiReason(date['irrigation']['ActualStartReason'][howManyStatus]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'ActualStopReason') {
                      if(date['irrigation']['ActualStopReason'] != null && howManyStatus < date['irrigation']['ActualStopReason'].length){
                        myList.add(formatMultiReason(date['irrigation']['ActualStopReason'][howManyStatus]));
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'Pump') {
                      myList.add(getName(date['irrigation']['Pump'][howManyStatus]));
                    }
                    else if(parameter.payloadKey == 'PumpCtAverage') {
                      if(howManyStatus < date['irrigation']['PumpCtAverage'].length){
                        myList.add(date['irrigation']['PumpCtAverage'][howManyStatus]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PumpCtMaximum') {
                      if(howManyStatus < date['irrigation']['PumpCtMaximum'].length){
                        myList.add(date['irrigation']['PumpCtMaximum'][howManyStatus]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PumpCtMinimum') {
                      if(howManyStatus < date['irrigation']['PumpCtMinimum'].length){
                        myList.add(date['irrigation']['PumpCtMinimum'][howManyStatus]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureAverage') {
                      if(howManyStatus < date['irrigation']['PressureAverage'].length){
                        myList.add(date['irrigation']['PressureAverage'][howManyStatus]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureMaximum') {
                      if(howManyStatus < date['irrigation']['PressureMaximum'].length){
                        myList.add(date['irrigation']['PressureMaximum'][howManyStatus]);
                      }else{
                        myList.add('-');
                      }
                    }
                    else if(parameter.payloadKey == 'PressureMinimum') {
                      if(howManyStatus < date['irrigation']['PressureMinimum'].length){
                        myList.add(date['irrigation']['PressureMinimum'][howManyStatus]);
                      }else{
                        myList.add('-');
                      }
                    }
                  }
                }
                waterParameterLoop : for(var parameter in waterParameterList){
                  if(parameter.payloadKey == 'IrrigationMethod') {
                    if(parameter.show == true){
                      waterList.add(date['irrigation']['IrrigationMethod'][howManyStatus] == 1 ? 'Time' : 'Quantity (L)');
                    }
                  }
                  if(parameter.payloadKey == 'IrrigationDuration_Quantity') {
                    graphData[indexOfDataToAdd]['totalTime'] = calculateTotalTime([graphData[indexOfDataToAdd]['totalTime'],date['irrigation']['IrrigationDurationCompleted'][howManyStatus]]);
                    graphData[indexOfDataToAdd]['data'].add(
                        getGraphData(
                            preValue: date['irrigation']['Pretime'][howManyStatus],
                            postValue: date['irrigation']['PostTime'][howManyStatus],
                            method: date['irrigation']['IrrigationMethod'][howManyStatus],
                            planned: date['irrigation']['IrrigationDuration_Quantity'][howManyStatus],
                            actualDuration: date['irrigation']['IrrigationDurationCompleted'][howManyStatus],
                            actualLiters: date['irrigation']['IrrigationQuantityCompleted'][howManyStatus],
                            flowRate: date['irrigation']['ValveFlowrate'][howManyStatus],
                            name: '${date['irrigation']['Date'][howManyStatus]}\n${date['irrigation']['ScheduledStartTime'][howManyStatus]}'
                        )
                    );
                    if(parameter.show == true){
                      waterList.add(date['irrigation']['IrrigationDuration_Quantity'][howManyStatus]);
                    }
                  }
                  if(parameter.payloadKey == 'IrrigationDurationCompleted/IrrigationQuantityCompleted') {
                    if(parameter.show == true){
                      var time = date['irrigation'][parameter.payloadKey.split('/')[0]][howManyStatus];
                      var quantity = date['irrigation'][parameter.payloadKey.split('/')[1]][howManyStatus];
                      waterList.add('$time HMS\n$quantity L');
                    }
                  }
                }
                prePostParameterLoop : for(var parameter in prePostParameterList){
                  if(parameter.payloadKey == 'PrePostMethod') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation']['PrePostMethod'][howManyStatus] == 1 ? 'Time' : 'Quantity (L)');
                    }
                  }
                  if(parameter.payloadKey == 'Pretime/PreQty') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation'][date['irrigation']['PrePostMethod'][howManyStatus] == 1 ? 'Pretime' : 'PreQty'][howManyStatus]);
                    }
                  }
                  if(parameter.payloadKey == 'PostTime/PostQty') {
                    if(parameter.show == true){
                      prePostList.add(date['irrigation'][date['irrigation']['PrePostMethod'][howManyStatus] == 1 ? 'PostTime' : 'PostQty'][howManyStatus]);
                    }
                  }
                }
                filterParameterLoop : for(var parameter in filterParameterList){
                  if(parameter.payloadKey == 'CentralFilterName') {
                    if(parameter.show == true){
                      var filterName = howManyStatus < date['irrigation']['CentralFilterName'].length ? date['irrigation']['CentralFilterName'][howManyStatus] : '';
                      var filterDuration = howManyStatus < date['irrigation']['CentralFilterOnDuration'].length ? date['irrigation']['CentralFilterOnDuration'][howManyStatus] : '';
                      var listOfFilterName = (filterName == null || filterName.isEmpty) ? [] : filterName.split('_');
                      var listOfFilterDuration = (filterDuration == null || filterDuration.isEmpty) ? [] : filterDuration.split('_');
                      var listOfNameAndDuration = [];
                      for(var name = 0;name < listOfFilterName.length;name++){
                        if(listOfFilterDuration.length > name){
                          listOfNameAndDuration.add('${listOfFilterName[name]} - ${listOfFilterDuration[name]}');
                        }else{
                          listOfNameAndDuration.add('${listOfFilterName[name]} - N/A');
                        }
                      }
                      filterList.add(listOfNameAndDuration.join('\n'));
                    }
                  }
                  if(parameter.payloadKey == 'LocalFilterName') {
                    if(parameter.show == true){
                      var filterName = howManyStatus < date['irrigation']['LocalFilterName'].length ? date['irrigation']['LocalFilterName'][howManyStatus] : '';
                      var filterDuration = howManyStatus < date['irrigation']['LocalFilterOnDuration'].length ? date['irrigation']['LocalFilterOnDuration'][howManyStatus] : '';
                      var listOfFilterName = (filterName == null || filterName.isEmpty) ? [] : filterName.split('_');
                      var listOfFilterDuration = (filterDuration == null || filterDuration.isEmpty) ? [] : filterDuration.split('_');
                      var listOfNameAndDuration = [];
                      for(var name = 0;name < listOfFilterName.length;name++){
                        if(listOfFilterDuration.length > name){
                          listOfNameAndDuration.add('${listOfFilterName[name]} - ${listOfFilterDuration[name]}');
                        }else{
                          listOfNameAndDuration.add('${listOfFilterName[name]} - N/A');
                        }
                      }
                      filterList.add(listOfNameAndDuration.join('\n'));
                    }
                  }
                }
                centralEcPhParameterLoop : for(var parameter in centralEcPhParameterList){
                  if(parameter.payloadKey == 'CentralEcSetValue') {
                    if(parameter.show == true){
                      centralEcPhList.add(date['irrigation']['CentralEcSetValue'][howManyStatus]);
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcAverage'] == null || date['irrigation']['CentralEcAverage'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcAverage'][howManyStatus]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcMaximum'] == null || date['irrigation']['CentralEcMaximum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcMaximum'][howManyStatus]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralEcMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralEcMinimum'] == null || date['irrigation']['CentralEcMinimum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralEcMinimum'][howManyStatus]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhSetValue') {
                    if(parameter.show == true){
                      centralEcPhList.add(date['irrigation']['CentralPhSetValue'][howManyStatus]);
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhAverage'] == null || date['irrigation']['CentralPhAverage'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhAverage'][howManyStatus]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhMaximum'] == null || date['irrigation']['CentralPhMaximum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhMaximum'][howManyStatus]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'CentralPhMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['CentralPhMinimum'] == null || date['irrigation']['CentralPhMinimum'].isEmpty){
                        centralEcPhList.add('-');
                      }else{
                        centralEcPhList.add(date['irrigation']['CentralPhMinimum'][howManyStatus]);
                      }
                    }
                  }
                }
                localEcPhParameterLoop : for(var parameter in localEcPhParameterList){
                  if(parameter.payloadKey == 'LocalEcSetValue') {
                    if(parameter.show == true){
                      localEcPhList.add(date['irrigation']['LocalEcSetValue'][howManyStatus]);
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcAverage'] == null || date['irrigation']['LocalEcAverage'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcAverage'][howManyStatus]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcMaximum'] == null || date['irrigation']['LocalEcMaximum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcMaximum'][howManyStatus]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalEcMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalEcMinimum'] == null || date['irrigation']['LocalEcMinimum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalEcMinimum'][howManyStatus]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhSetValue') {
                    if(parameter.show == true){
                      localEcPhList.add(date['irrigation']['LocalPhSetValue'][howManyStatus]);
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhAverage') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhAverage'] == null || date['irrigation']['LocalPhAverage'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhAverage'][howManyStatus]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhMaximum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhMaximum'] == null || date['irrigation']['LocalPhMaximum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhMaximum'][howManyStatus]);
                      }
                    }
                  }
                  if(parameter.payloadKey == 'LocalPhMinimum') {
                    if(parameter.show == true){
                      if(date['irrigation']['LocalPhMinimum'] == null || date['irrigation']['LocalPhMinimum'].isEmpty){
                        localEcPhList.add('-');
                      }else{
                        localEcPhList.add(date['irrigation']['LocalPhMinimum'][howManyStatus]);
                      }
                    }
                  }
                }
                generalColumnData.add(myList);
                waterColumnData.add(waterList);
                prePostColumnData.add(prePostList);
                filterColumnData.add(filterList);
                centralEcPhColumnData.add(centralEcPhList);
                centralChannel1ColumnData.add(getChannelData(channelNo: 0, channelParameterList: centralChannel1ParameterList, date: date, howMany: howManyStatus, central: true));
                centralChannel2ColumnData.add(getChannelData(channelNo: 1, channelParameterList: centralChannel2ParameterList, date: date, howMany: howManyStatus, central: true));
                centralChannel3ColumnData.add(getChannelData(channelNo: 2, channelParameterList: centralChannel3ParameterList, date: date, howMany: howManyStatus, central: true));
                centralChannel4ColumnData.add(getChannelData(channelNo: 3, channelParameterList: centralChannel4ParameterList, date: date, howMany: howManyStatus, central: true));
                centralChannel5ColumnData.add(getChannelData(channelNo: 4, channelParameterList: centralChannel5ParameterList, date: date, howMany: howManyStatus, central: true));
                centralChannel6ColumnData.add(getChannelData(channelNo: 5, channelParameterList: centralChannel6ParameterList, date: date, howMany: howManyStatus, central: true));
                centralChannel7ColumnData.add(getChannelData(channelNo: 6, channelParameterList: centralChannel7ParameterList, date: date, howMany: howManyStatus, central: true));
                centralChannel8ColumnData.add(getChannelData(channelNo: 7, channelParameterList: centralChannel8ParameterList, date: date, howMany: howManyStatus, central: true));
                localEcPhColumnData.add(localEcPhList);
                localChannel1ColumnData.add(getChannelData(channelNo: 0, channelParameterList: localChannel1ParameterList, date: date, howMany: howManyStatus, central: false));
                localChannel2ColumnData.add(getChannelData(channelNo: 1, channelParameterList: localChannel2ParameterList, date: date, howMany: howManyStatus, central: false));
                localChannel3ColumnData.add(getChannelData(channelNo: 2, channelParameterList: localChannel3ParameterList, date: date, howMany: howManyStatus, central: false));
                localChannel4ColumnData.add(getChannelData(channelNo: 3, channelParameterList: localChannel4ParameterList, date: date, howMany: howManyStatus, central: false));
                localChannel5ColumnData.add(getChannelData(channelNo: 4, channelParameterList: localChannel5ParameterList, date: date, howMany: howManyStatus, central: false));
                localChannel6ColumnData.add(getChannelData(channelNo: 5, channelParameterList: localChannel6ParameterList, date: date, howMany: howManyStatus, central: false));
                localChannel7ColumnData.add(getChannelData(channelNo: 6, channelParameterList: localChannel7ParameterList, date: date, howMany: howManyStatus, central: false));
                localChannel8ColumnData.add(getChannelData(channelNo: 7, channelParameterList: localChannel8ParameterList, date: date, howMany: howManyStatus, central: false));
              }
            }
          }
        }
      }
    }
    var sendingData = {
      'fixedColumn' : fixedColumn,
      'fixedColumnData': fixedColumnData,
      'generalColumn' : generalColumn,
      'generalColumnData' : generalColumnData,
      'waterColumn' : waterColumn,
      'waterColumnData' : waterColumnData,
      'prePostColumn' : prePostColumn,
      'prePostColumnData' : prePostColumnData,
      'filterColumn' : filterColumn,
      'filterColumnData' : filterColumnData,
      'centralEcPhColumn' : centralEcPhColumn,
      'centralEcPhColumnData' : centralEcPhColumnData,
      'centralChannel1Column' : centralChannel1Column,
      'centralChannel1ColumnData' : centralChannel1ColumnData,
      'centralChannel2Column' : centralChannel2Column,
      'centralChannel2ColumnData' : centralChannel2ColumnData,
      'centralChannel3Column' : centralChannel3Column,
      'centralChannel3ColumnData' : centralChannel3ColumnData,
      'centralChannel4Column' : centralChannel4Column,
      'centralChannel4ColumnData' : centralChannel4ColumnData,
      'centralChannel5Column' : centralChannel5Column,
      'centralChannel5ColumnData' : centralChannel5ColumnData,
      'centralChannel6Column' : centralChannel6Column,
      'centralChannel6ColumnData' : centralChannel6ColumnData,
      'centralChannel7Column' : centralChannel7Column,
      'centralChannel7ColumnData' : centralChannel7ColumnData,
      'centralChannel8Column' : centralChannel8Column,
      'centralChannel8ColumnData' : centralChannel8ColumnData,
      'localEcPhColumn' : localEcPhColumn,
      'localEcPhColumnData' : localEcPhColumnData,
      'localChannel1Column' : localChannel1Column,
      'localChannel1ColumnData' : localChannel1ColumnData,
      'localChannel2Column' : localChannel2Column,
      'localChannel2ColumnData' : localChannel2ColumnData,
      'localChannel3Column' : localChannel3Column,
      'localChannel3ColumnData' : localChannel3ColumnData,
      'localChannel4Column' : localChannel4Column,
      'localChannel4ColumnData' : localChannel4ColumnData,
      'localChannel5Column' : localChannel5Column,
      'localChannel5ColumnData' : localChannel5ColumnData,
      'localChannel6Column' : localChannel6Column,
      'localChannel6ColumnData' : localChannel6ColumnData,
      'localChannel7Column' : localChannel7Column,
      'localChannel7ColumnData' : localChannel7ColumnData,
      'localChannel8Column' : localChannel8Column,
      'localChannel8ColumnData' : localChannel8ColumnData,
      'graphData' : graphData
    };
    return sendingData;
  }

  List<dynamic> getChannelData({required channelNo,required List<GeneralParameterModel> channelParameterList,required dynamic date,required int howMany,required bool central}){
    List<dynamic> list = [];
    try{
      for(var parameter in channelParameterList){
        debugPrint("parameter => ${parameter.payloadKey} = ${parameter.show}");
        if(date['irrigation']['${central ? 'Central' : 'Local'}FertOnOff'][howMany] == 1){
          if(parameter.payloadKey == '${central ? 'Central' : 'Local'}FertMethod') {
            if(parameter.show == true){
              var data = date['irrigation']['${central ? 'Central' : 'Local'}FertMethod'][howMany];
              list.add([null,''].contains(data) ? data : (data.split('_')[channelNo] == '1' ? 'Time' : data.split('_')[channelNo] == '0' ? null :'Quantity (L)'));
            }
          }
          if(parameter.payloadKey == '${central ? 'Central' : 'Local'}FertilizerChannelDuration/${central ? 'Central' : 'Local'}FertilizerChannelQuantity') {
            if(parameter.show == true){
              list.add([null,'', '-'].contains(list[0]) ? '-' : list[0] == 'Time' ? date['irrigation']['${central ? 'Central' : 'Local'}FertilizerChannelDuration'][howMany].split('_')[channelNo] : date['irrigation']['${central ? 'Central' : 'Local'}FertilizerChannelQuantity'][howMany].split('_')[channelNo]);
            }
          }
          if(parameter.payloadKey == '${central ? 'Central' : 'Local'}FertilizerChannelDurationCompleted/${central ? 'Central' : 'Local'}FertilizerChannelQuantityCompleted') {
            if(parameter.show == true){
              var qtyCompletedData = date['irrigation']['${central ? 'Central' : 'Local'}FertilizerChannelQuantityCompleted'];
              list.add([null,'', '-'].contains(list[0]) ? '-' : list[0] == 'Time' ? (qtyCompletedData[howMany] != null ? qtyCompletedData[howMany].split('_')[channelNo] : '-')
                  : (howMany < qtyCompletedData.length ? qtyCompletedData[howMany].split('_')[channelNo] : '-'));
            }
          }
        }
        else{
          list = ['-', '-', '-'];
        }
      }
    }catch(e,stackTrace){
      debugPrint('getChannelData error => ${e.toString()}');
      debugPrint('getChannelData stackTrac => $stackTrace');
    }
    return list;
  }

  List<dynamic> getColumn(List<GeneralParameterModel> parameterList){
    var list = [];
    for(var parameter in parameterList){
      if(parameter.show == true){
        if(parameter.payloadKey != 'overAll'){
          if (!list.contains(parameter.uiKey)) {
            list.add(parameter.uiKey);
          }
        }
      }
    }
    return list;
  }
}

class GraphData {
  final dynamic preFrom;
  final dynamic preTo;
  final dynamic postFrom;
  final dynamic postTo;
  final dynamic plannedFrom;
  final dynamic plannedTo;
  final dynamic actualFrom;
  final dynamic actualTo;
  final String seqName;
  GraphData({required this.actualFrom,required this.actualTo,required this.plannedFrom,required this.plannedTo,required this.seqName,required this.preFrom,required this.preTo,required this.postFrom,required this.postTo,});
}

GraphData getGraphData({required method, required planned, required actualDuration,
  required actualLiters,required flowRate, required String name, preValue, postValue}){

  int finalMethod = method is String ? int.tryParse(method) ?? 0 : method;

  var preValueInSec = DataConvert().parseTimeString(preValue ?? '00:00:00');
  var postValueInSec = DataConvert().parseTimeString(postValue ?? '00:00:00');
  var plannedSeconds = finalMethod == 1 ? DataConvert().parseTimeString(planned) : 0;
  var actualSeconds = finalMethod == 1 ? DataConvert().parseTimeString(actualDuration) : 0;
  var flowRateForPerSec = flowRate/3600;
  var preInLiters = preValueInSec * flowRateForPerSec;
  var postInLiters = postValueInSec * flowRateForPerSec;
  var plannedInLiters = finalMethod == 1 ? (plannedSeconds * flowRateForPerSec) : planned;
  var actualInLiters =  finalMethod == 1 ? (actualSeconds * flowRateForPerSec) : actualLiters;
  if(plannedInLiters is String){
    plannedInLiters = double.parse(plannedInLiters).toInt();
  }
  if(actualInLiters is String){
    actualInLiters = double.parse(actualInLiters).toInt();
  }
  dynamic preFrom = 0;
  dynamic preTo = 0;
  dynamic actualFrom = 0;
  dynamic actualTo = 0;
  dynamic postFrom = 0;
  dynamic postTo = 0;
  dynamic plannedFrom = 0;
  dynamic plannedTo = 0;
  if(actualInLiters > preInLiters){
    preTo = preInLiters;
    actualFrom = preTo;
    if((plannedInLiters - postInLiters) > actualInLiters){
      actualTo = actualInLiters;
      postFrom = actualTo;
      postTo = postFrom;
      plannedFrom = postTo;
      plannedTo = plannedInLiters;
    }else{
      actualTo = plannedInLiters - postInLiters;
      postFrom = actualTo;
      postTo = plannedInLiters - (plannedInLiters - actualInLiters);
      plannedFrom = postTo;
      plannedTo = plannedInLiters;
    }
  }else{
    preTo = actualInLiters;
    actualFrom = preTo;
    actualTo = actualFrom;
    postFrom = actualTo;
    postTo = postFrom;
    plannedFrom = postTo;
    plannedTo = plannedInLiters;
  }
  return GraphData(
      preFrom: preFrom,
      preTo: preTo,
      actualFrom: actualFrom,
      actualTo: actualTo,
      postFrom: postFrom,
      postTo: postTo,
      plannedFrom: plannedFrom,
      plannedTo: plannedTo,
      seqName: name
  );
}