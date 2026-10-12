import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Constants/constants.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/repository/irrigation_program_repo.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/device_object_model.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/model/LineDataModel.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../../../Constants/data_convertion.dart';
import '../model/sequence_model.dart';
import 'package:intl/intl.dart';
import '../../../services/http_service.dart';

class IrrigationProgramMainProvider extends ChangeNotifier {
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;
  bool ignoreValidation = false;

  void updateTabIndex(int newIndex) {
    _selectedTabIndex = newIndex;
    notifyListeners();
  }

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  void updateBottomNavigation(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void clearDispose() {
    // // // print("invoked");
    irrigationLine?.sequence = [];
    currentIndex = 0;
    addNext = false;
    addNew = false;
    notifyListeners();
  }

  //TODO:SEQUENCE SCREEN PROVIDER
  final IrrigationProgramRepository repository = IrrigationProgramRepository(HttpService());

  SequenceModel? _irrigationLine;
  SequenceModel? get irrigationLine => _irrigationLine;

  List<ProgramIrrigationLine>? _sampleIrrigationLine;
  List<ProgramIrrigationLine>? get sampleIrrigationLine => _sampleIrrigationLine;

  List<ProgramFilterSite>? _filterSite;
  List<ProgramFilterSite>? get filterSite => _filterSite;
  List<ProgramFertilizerSite>? _fertilizerSite;
  List<ProgramFertilizerSite>? get fertilizerSite => _fertilizerSite;
  List<ProgramWaterSource>? _waterSource;
  List<ProgramWaterSource>? get waterSource => _waterSource;
  List<ProgramPump>? _pump;
  List<ProgramPump>? get pump => _pump;
  List<ProgramMoistureSensor>? _moistureSensor;
  List<ProgramMoistureSensor>? get moistureSensor => _moistureSensor;
  List<DeviceObjectModel>? _agitators;
  List<DeviceObjectModel>? _aerators;
  List<DeviceObjectModel>? _mainValves;
  List<FertilizerSourceTank>? _tank ;

  List<dynamic> _rawWaterSource = [];
  List<dynamic> get rawWaterSource => _rawWaterSource;

  List<dynamic> _rawFertilizerChannel = [];
  List<dynamic> get rawFertilizerChannel => _rawFertilizerChannel;

  List<DeviceObjectModel>? get agitators => _agitators;
  List<DeviceObjectModel>? get aerators => _aerators;
  List<DeviceObjectModel>? get mainValves => _mainValves;
  List<FertilizerSourceTank>? get tank => _tank ;

  List<DeviceObjectModel>? _selectedObjects;
  List<Map<String, dynamic>> _selectedControllers = [];
  List<DeviceObjectModel>? get selectedObjects=> _selectedObjects;
  List<Map<String, dynamic>> get selectedControllers=> _selectedControllers;
  List<Map<String, dynamic>> irrigationLineFromConfigMaker = [];
  int selectedPumpLocation = 0;

  List<dynamic> configObjects = [];

  Future<void> getUserProgramSequence({required int userId, required int controllerId, required int serialNumber, required int groupId, required int categoryId, required int modelId}) async {
    try {
      var userData = {
        "userId": userId,
        "controllerId": controllerId,
        "serialNumber": serialNumber
      };
      // print("userData ==> $userData");
      var userBody = {
        ...userData,
        "groupId": groupId,
        "categoryId": categoryId
      };
      print("userBody : $userBody");
      var getUserConfigMaker = await repository.getUserConfigMaker(userBody);
      var getUserProgramSequence = await repository.getUserProgramSequence(userData);
      apiData = null;
      ignoreValidation = false;
      _sampleIrrigationLine = null;
      _filterSite = null;
      _fertilizerSite = null;
      _waterSource = null;
      _pump = null;
      _moistureSensor = null;
      _irrigationLine = null;
      _agitators = null;
      _aerators = null;
      _mainValves = null;
      _tank = null;
      configObjects.clear();
      irrigationLineFromConfigMaker.clear();
      if(getUserConfigMaker.statusCode == 200) {
        final responseJson = getUserProgramSequence.body;
        var sequenceJson = jsonDecode(responseJson);
        final configMakerJson = jsonDecode(getUserConfigMaker.body);
        print('configMakerJson---->:$configMakerJson');
        configObjects = configMakerJson['data']['configObject'];

        for(var seq in sequenceJson['data']['sequence']){
          for(var v = (seq['valve'].length - 1); v >= 0; v--){
            bool isValveAvailable = configObjects.any((obj) => obj['sNo'] == seq['valve'][v]['sNo']);
            if(isValveAvailable == false){
              seq['valve'].removeAt(v);
            }
          }
          for(var v = (seq['mainValve'].length - 1); v >= 0; v--){
            bool isMainValveAvailable = configObjects.any((obj) => obj['sNo'] == seq['mainValve'][v]['sNo']);
            if(isMainValveAvailable == false){
              seq['mainValve'].removeAt(v);
            }
          }
        }
        for(var line in configMakerJson['data']['irrigationLine']){
          irrigationLineFromConfigMaker.add(
            {
              'sNo' : line['sNo'],
              'irrigationPump' : line['irrigationPump'],
            }
          );
        }
        // irrigationLineFromConfigMaker = List.from(configMakerJson['data']['irrigationLine']);

        final processedData = Constants.payloadConversion(configMakerJson['data']);
        apiData = processedData;
        _sampleIrrigationLine = (processedData['irrigationLine'] as List).map((e) => ProgramIrrigationLine.fromJson(e as Map<String, dynamic>)).toList();
        _filterSite = (processedData['filterSite'] as List).map((element) => ProgramFilterSite.fromJson(element as Map<String, dynamic>)).toList();
        _fertilizerSite = (processedData['fertilizerSite'] as List).map((element) => ProgramFertilizerSite.fromJson(element as Map<String, dynamic>)).toList();
        _waterSource = (processedData['waterSource'] as List).map((element) => ProgramWaterSource.fromJson(element as Map<String, dynamic>)).toList();
        _pump = (processedData['pump'] as List).map((element) => ProgramPump.fromJson(element as Map<String, dynamic>)).toList();
        _moistureSensor = (processedData['moistureSensor'] as List).map((element) => ProgramMoistureSensor.fromJson(element as Map<String, dynamic>)).toList();

        final configMakerData = configMakerJson['data']?['configMaker'] ?? configMakerJson['data'] ?? {};
        _rawWaterSource = configMakerData['waterSource'] ?? [];
        _rawFertilizerChannel = configMakerData['fertilizerChannel'] ?? [];

        final List<dynamic> rawFertilizerChannels =
            _rawFertilizerChannel;

        final Set<String> tankSNos = {};

// 1. Get tank/source SNo from fertilizerChannel
        for (final channel in rawFertilizerChannels) {
          final sources = channel['source'];

          if (sources is List) {
            for (final source in sources) {
              if (source != null) {
                tankSNos.add(source.toString());
              }
            }
          }
        }

        print('tankSNos => $tankSNos');

// 2. Find corresponding Source objects from configObject
        final tankObjects = configObjects.where((obj) {
          final sno = obj['sNo']?.toString();

          return sno != null &&
              tankSNos.contains(sno) &&
              obj['objectName'] == 'Source';
        }).toList();

        print('tankObjects => $tankObjects');

// 3. Convert Source objects into FertilizerSourceTank
        _tank = tankObjects
            .map(
              (source) => FertilizerSourceTank.fromJson(
            Map<String, dynamic>.from(source),
          ),
        )
            .toList();

        print(
          'Tank list => ${_tank?.map((e) => e.tank.name).toList()}',
        );
        // print("_sampleIrrigationLine :: ${_sampleIrrigationLine!.map((e) => e.irrigationLine.toJson())}");
        if(_fertilizerSite != null) {
          _agitators = fertilizerSite!.map((e) {
            return e.agitator != null ? List<DeviceObjectModel>.from(e.agitator!) : [];
          })
            .expand((list) => list)
            .whereType<DeviceObjectModel>()
            .toList();
        }

        _aerators = _sampleIrrigationLine!.map((e) => e.aerator != null ? List<DeviceObjectModel>.from(e.aerator!) : [])
            .expand((list) => list)
            .whereType<DeviceObjectModel>()
            .toList();

        _mainValves = _sampleIrrigationLine!.map((e) => e.mainValve != null ? List<DeviceObjectModel>.from(e.mainValve!) : [])
            .expand((list) => list)
            .whereType<DeviceObjectModel>()
            .toList();

        await Future.delayed(Duration.zero,() {
          _irrigationLine = SequenceModel.fromJson(sequenceJson);
          for (var element in _irrigationLine!.sequence) {
            // print("element in sequence :: $element");
           /* element['valve'].removeWhere((e) => configObjects.any((config) => config['sNo'] != e['sNo']));
            element['mainValve'].removeWhere((e) => configObjects.any((config) => config['sNo'] != e['sNo']));*/
          }
          updateGroup(valveGroup: _irrigationLine!.defaultData.group);
        }).then((value) {
          if(irrigationLine!.sequence.isEmpty) {
            addNewSequence(serialNumber: serialNumber, zoneSno: 1);
          }
        });
        if(AppConstants.ecoGemAndPlusModelList.contains(modelId)) {
          for(int i = 0; i < _irrigationLine!.sequence.length; i++) {
            _irrigationLine!.sequence[i]['sNo'] = '${i+1}';
          }
          // print("Serial number :: ${_irrigationLine!.sequence.map((e) => e['sNo'])}");
        }
      } else {
        log("HTTP Request failed or received an unexpected response.");
        throw Exception("Failed to load sequence data");
      }
    } catch (e, stackTrace) {
      log('Error: $e');
      log('stackTrace: $stackTrace');
      rethrow;
    }
    // notifyListeners();
  }

  //TODO:New SEQUENCE SCREEN PROVIDER
  bool reorder = false;
  void updateReorder() {
    reorder = !reorder;
    notifyListeners();
  }

  bool addNext = false;
  bool addNew = false;
  void updateCheckBoxSelection({index, newValue}) {
    irrigationLine!.sequence[index]['selected'] = newValue;
    notifyListeners();
  }

  void updateGroup({required List<ValveGroup> valveGroup}) {
    // irrigationLine!.defaultData.group = valveGroup;
    for (var i = 0; i < irrigationLine!.sequence.length; i++) {
      if (irrigationLine!.sequence[i]['selectedGroup'].isNotEmpty) {
        irrigationLine!.sequence[i]['selectedGroup'].forEach((group) {
          for (var j = 0; j < valveGroup.length; j++) {
            if (valveGroup[j].id == group) {
              for (var l = 0; l < valveGroup[j].valve.length; l++) {
                bool valveExistsInSequence = irrigationLine!.sequence[i]['valve'].any((e) => e['sNo'] == valveGroup[j].valve[l].sNo) ?? false;

                if (!valveExistsInSequence) {
                  irrigationLine!.sequence[i]['valve'].add(valveGroup[j].valve[l].toJson());
                }
              }

              irrigationLine!.sequence[i]['valve'].removeWhere((e) {
                return !valveGroup[j].valve.any((valve) => valve.sNo == e['sNo']);
              });
            }
          }
        });
      }
    }
    notifyListeners();
  }

  List<String> deleteSelection = ["Select", "Select all", "Unselect all"];
  String selectedOption = "Unselect all";

  void deleteFunction({indexToShow, serialNumber, modelId}) {
    Future.delayed(Duration.zero, () {
      irrigationLine!.sequence.removeWhere((element) => element['selected'] == true);
      if(irrigationLine!.sequence.isEmpty) {
        addNewSequence(serialNumber: serialNumber, zoneSno: 1);
      }
    }).then((value) {
      addNext = false;
      for(var i = 0; i < _irrigationLine!.sequence.length; i++) {
        if(_irrigationLine!.sequence[i]['name'].contains('Sequence')) {
          _irrigationLine!.sequence[i]['name'] = 'Sequence ${serialNumber == 0 ? serialNumberCreation : serialNumber}.${i+1}';
        }
      }
      if(selectedOption == deleteSelection[1] || _irrigationLine!.sequence.isEmpty) {
        assigningCurrentIndex(0);
      } else if(selectedOption == deleteSelection[0]) {
        assigningCurrentIndex(_irrigationLine!.sequence.length-1);
      }
      selectedOption = deleteSelection[2];
    });
    if(AppConstants.ecoGemAndPlusModelList.contains(modelId)) {
      for(int i = 0; i < _irrigationLine!.sequence.length; i++) {
        _irrigationLine!.sequence[i]['sNo'] = '${i+1}';
      }
    }
    // print("invoked");
    // print("Sequence after deletion :: ${_irrigationLine!.sequence}");
    notifyListeners();
  }

  void updateDeleteSelection({newOption}) {
    selectedOption = newOption;
    if(selectedOption == deleteSelection[1]) {
      for(var i = 0; i < irrigationLine!.sequence.length; i++) {
        irrigationLine!.sequence[i]['selected'] = true;
      }
    } else if(selectedOption == deleteSelection[2]){
      for(var i = 0; i < irrigationLine!.sequence.length; i++) {
        irrigationLine!.sequence[i]['selected'] = false;
      }
    }
    notifyListeners();
  }

  void updateNextButton(indexToShow) {
    // // print("indexToShow in the update next button ==> $indexToShow");
    if(indexToShow == irrigationLine!.sequence.length) {
      addNew = true;
      addNext = false;
    } else {
      addNew = false;
      addNext = true;
    }
    notifyListeners();
  }

  void updateAddNext({serialNumber, indexToShow, required int modelId}) {
    addNextSequence(serialNumber: serialNumber, zoneSno: irrigationLine!.sequence.length+1, indexToInsert: indexToShow, modelId: modelId);
    assigningCurrentIndex(indexToShow);
    notifyListeners();
  }

  int currentIndex = 0;
  void assigningCurrentIndex(newIndex) {
    currentIndex = newIndex;
    if (sequenceData.isNotEmpty && newIndex >= 0 && newIndex < sequenceData.length) {
      selectedGroup = newIndex;
      waterQuantity.text = sequenceData[selectedGroup]['quantityValue'] ?? '';
      preValue.text = sequenceData[selectedGroup]['preValue'] ?? '';
      postValue.text = sequenceData[selectedGroup]['postValue'] ?? '';
      refreshTime();
    }
    notifyListeners();
  }

  //TODO: adding sequence function
  void addNewSequence({required int serialNumber, required int zoneSno}) {
    irrigationLine!.sequence.add({
      "sNo": "${serialNumber == 0 ? serialNumberCreation : serialNumber}.$zoneSno",
      "id": 'SEQ${serialNumber == 0 ? serialNumberCreation : serialNumber}.$zoneSno',
      "name": 'Sequence ${serialNumber == 0 ? serialNumberCreation : serialNumber}.$zoneSno',
      "selected": false,
      "selectedGroup": [],
      "modified": false,
      "location": '',
      "valve": [],
      "mainValve": []
    });
    notifyListeners();
  }

  void addNextSequence({int? serialNumber, zoneSno, indexToInsert, required int modelId}) {
    dynamic missingNum;
    for(var i = 0; i < _irrigationLine!.sequence.length; i++) {
      if(!_irrigationLine!.sequence.map((e)=> e['sNo']).toList().contains("${serialNumber == 0 ? serialNumberCreation : serialNumber}.${i+1}")) {
        missingNum = "${i+1}";
      }
    }
    missingNum ??= "${_irrigationLine!.sequence.length + 1}";
    _irrigationLine!.sequence.insert(
        indexToInsert+1,
        {
          "sNo": "${serialNumber == 0 ? serialNumberCreation : serialNumber}.$missingNum",
          "id": 'SEQ${serialNumber == 0 ? serialNumberCreation : serialNumber}.$missingNum',
          "name": 'Sequence ${serialNumber == 0 ? serialNumberCreation : serialNumber}.$missingNum',
          "selected": false,
          "selectedGroup": [],
          "modified": false,
          "location": '',
          "valve": [],
          "mainValve": [],
        });

    if(AppConstants.ecoGemAndPlusModelList.contains(modelId)) {
      for(int i = 0; i < _irrigationLine!.sequence.length; i++) {
        _irrigationLine!.sequence[i]['sNo'] = '${i+1}';
      }
    }

    for(var i = 0; i < _irrigationLine!.sequence.length; i++) {
      if(_irrigationLine!.sequence[i]['name'].contains('Sequence')) {
        _irrigationLine!.sequence[i]['name'] = 'Sequence ${serialNumber == 0 ? serialNumberCreation : serialNumber}.${i+1}';
      }
      // print("\n");
    }
    notifyListeners();
  }

  bool checkValveContainment2({valves, sequenceIndex, i, isMainValve}) {
    if(isMainValve) {
      if(irrigationLine!.sequence[sequenceIndex]['mainValve'].any((mainValve) => mainValve['sNo']! == valves[i]["sNo"])) {
        return true;
      }
    } else {
      if(irrigationLine!.sequence[sequenceIndex]['valve'].any((valve) => valve['sNo']! == valves[i]["sNo"])) {
        return true;
      }
    }
    return false;
  }

  void addValvesInSequence({
    required valves,
    int? serialNumber,
    int? sNo,
    required int lineIndex,
    required int sequenceIndex,
    required bool isMainValve,
    bool isGroup = false,
    required String groupId,
    required BuildContext context,
    required int modelId
  }) {
    List<Map<String, dynamic>> valvesToAdd = [];

    for (var i = 0; i < valves.length; i++) {
      bool valveExists = checkValveContainment2(
        valves: valves,
        sequenceIndex: sequenceIndex,
        i: i,
        isMainValve: isMainValve,
      );

      final totalValves = irrigationLine!.sequence.expand((e) => e['valve']).toList().length;
      final currentValves = irrigationLine!.sequence[sequenceIndex]['valve'].length;
      if (isGroup) {
        if (!valveExists) {
          if (AppConstants.ecoGemAndPlusModelList.contains(modelId)) {
            if (totalValves < 32 && currentValves < 4) {
              valvesToAdd.add(valves[i]);
            } else {
              showAdaptiveDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Warning!"),
                    content: Text(
                      currentValves >= 4 ? 'Maximum 4 valves can be created for a Zone' : 'Maximum 32 valves can be created for a Program',
                      style: const TextStyle(color: Colors.red),
                    ),
                    actions: [
                      TextButton(
                        child: const Text("OK"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                },
              );
            }
          } else {
            valvesToAdd.add(valves[i]);
          }
        }
      } else {
        if (valveExists) {
          if (isMainValve) {
            irrigationLine!.sequence[sequenceIndex]["mainValve"].removeWhere((e) => e["sNo"] == valves[i]['sNo']);
          } else {
            irrigationLine!.sequence[sequenceIndex]["valve"].removeWhere((e) => e["sNo"] == valves[i]['sNo']);
          }
        }

        if (!valveExists) {
          if (AppConstants.ecoGemAndPlusModelList.contains(modelId)) {
            if (totalValves < 32 && currentValves < 4) {
              if (isMainValve) {
                irrigationLine!.sequence[sequenceIndex]['mainValve'].add(valves[i]);
              } else {
                irrigationLine!.sequence[sequenceIndex]['valve'].add(valves[i]);
              }
            } else {
              showAdaptiveDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Warning!"),
                    content: Text(
                      currentValves >= 4 ? 'Maximum 4 valves can be created for a Zone' : 'Maximum 32 valves can be created for a Program',
                      style: const TextStyle(color: Colors.red),
                    ),
                    actions: [
                      TextButton(
                        child: const Text("OK"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                },
              );
            }
          } else {
            if (isMainValve) {
              irrigationLine!.sequence[sequenceIndex]['mainValve'].add(valves[i]);
            } else {
              irrigationLine!.sequence[sequenceIndex]['valve'].add(valves[i]);
            }
          }
        }
      }
    }

    if (isGroup) {
      if(!(irrigationLine!.sequence[sequenceIndex]['selectedGroup'].contains(groupId))) {
        irrigationLine!.sequence[sequenceIndex]['selectedGroup'].add(groupId);
        for (var valve in valvesToAdd) {
          if (!isMainValve) {
            irrigationLine!.sequence[sequenceIndex]['valve'].add(valve);
          }
        }
      } else {
        irrigationLine!.sequence[sequenceIndex]['selectedGroup'].remove(groupId);
        for (var valve in valves) {
          if (!isMainValve) {
            irrigationLine!.sequence[sequenceIndex]['valve'].removeWhere((e) => e['sNo'] == valve['sNo']);
          }
        }
      }
    }

    notifyListeners();
  }

  void reorderSelectedValves(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    addNext = false;
    final valve = irrigationLine!.sequence[oldIndex];
    irrigationLine!.sequence.removeAt(oldIndex);
    irrigationLine!.sequence.insert(newIndex, valve);
    currentIndex = newIndex;
    notifyListeners();
  }

  //TODO: SCHEDULE SCREEN PROVIDERS
  SampleScheduleModel? _sampleScheduleModel;
  SampleScheduleModel? get sampleScheduleModel => _sampleScheduleModel;

  int _currentRtcIndex = 0;
  int get currentRtcIndex => _currentRtcIndex;

  void updateCurrentRtcIndex(newIndex) {
    _currentRtcIndex = newIndex;
    notifyListeners();
  }

  Future<void> scheduleData(int userId, int controllerId, int serialNumber) async {
    try {
      var userData = {
        "userId": userId,
        "controllerId": controllerId,
        "serialNumber": serialNumber
      };
      var getUserProgramSchedule = await repository.getUserProgramSchedule(userData);
      _sampleScheduleModel = null;
      if(getUserProgramSchedule.statusCode == 200) {
        final responseJson = getUserProgramSchedule.body;
        final convertedJson = jsonDecode(responseJson);
        if(convertedJson['data']['schedule'].isEmpty) {
          convertedJson['data']['schedule'] = {
            "scheduleAsRunList" : {
              "rtc" : {
                "rtc1": {"onTime": "00:00:00", "offTime": "00:00:00", "interval": "00:00:00", "noOfCycles": "1", "maxTime": "00:00:00", "condition": false, "stopMethod": "Continuous"},
              },
              "schedule": { "noOfDays": "1", "startDate": DateTime.now().toString(), "type" : ['DO WATERING'], "endDate": DateTime.now().toString(), "isForceToEndDate": false},
            },
            "scheduleByDays" : {
              "rtc" : {
                "rtc1": {"onTime": "00:00:00", "offTime": "00:00:00", "interval": "00:00:00", "noOfCycles": "1", "maxTime": "00:00:00", "condition": false, "stopMethod": "Continuous"},
              },
              "schedule": { "startDate": DateTime.now().toString(), "runDays": "1", "skipDays": "0", "endDate": DateTime.now().toString(), "isForceToEndDate": false}
            },
            "dayCountSchedule" : {
              "schedule": { "onTime": "00:00:00", "interval": "00:00:00", "shouldLimitCycles": false, "noOfCycles": "1"}
            },
            "selected" : "NO SCHEDULE",
          };
        }
        _sampleScheduleModel = SampleScheduleModel.fromJson(convertedJson);
      } else {
        log("HTTP Request failed or received an unexpected response.");
        throw Exception("Failed to load schedule data");
      }
    } catch (e) {
      log('Error: $e');
      rethrow;
    }

    Future.delayed(Duration.zero, () {
      notifyListeners();
    });
  }

  void updateRtcProperty(newTime, selectedRtc, property, scheduleType) {
    if(scheduleType == sampleScheduleModel!.scheduleAsRunList){
      final selectedRtcKey = sampleScheduleModel!.scheduleAsRunList.rtc.keys.toList()[selectedRtc];
      sampleScheduleModel!.scheduleAsRunList.rtc[selectedRtcKey][property] = newTime;
    } else {
      final selectedRtcKey = sampleScheduleModel!.scheduleByDays.rtc.keys.toList()[selectedRtc];
      sampleScheduleModel!.scheduleByDays.rtc[selectedRtcKey][property] = newTime;
      // print(sampleScheduleModel!.scheduleAsRunList.rtc[selectedRtcKey]['maxTime']);
    }
    notifyListeners();
  }

  String startDate({required int serialNumber}) {
    if(selectedScheduleType == scheduleTypes[1]) {
      return sampleScheduleModel!.scheduleAsRunList.schedule['startDate'];
    } else {
      return sampleScheduleModel!.scheduleByDays.schedule['startDate'];
    }
  }

  void updateDate(newDate, dateType) {
    if(selectedScheduleType == scheduleTypes[1]) {
      sampleScheduleModel!.scheduleAsRunList.schedule[dateType] = newDate.toString();
      // print(sampleScheduleModel!.scheduleAsRunList.schedule[dateType]);
    } else if(selectedScheduleType == scheduleTypes[2]) {
      sampleScheduleModel!.scheduleByDays.schedule[dateType] = newDate.toString();
    }
    notifyListeners();
  }

  void updateForceToEndDate2({required newValue}){
    if(selectedScheduleType == scheduleTypes[1]) {
      sampleScheduleModel!.scheduleAsRunList.schedule['isForceToEndDate'] = newValue;
    } else if(selectedScheduleType == scheduleTypes[2]) {
      sampleScheduleModel!.scheduleByDays.schedule['isForceToEndDate'] = newValue;
    }
    notifyListeners();
  }

  void updateNumberOfDays(newNumberOfDays, daysType, scheduleType) {
    scheduleType.schedule[daysType] = newNumberOfDays;
    notifyListeners();
  }

  List<String> scheduleTypes = ['NO SCHEDULE', 'SCHEDULE BY DAYS', 'SCHEDULE BY RUN LIST', 'SCHEDULE BY PROGRAM'];
  List<String> scheduleTypesForEcoGem = ['NO SCHEDULE'];

  String get selectedScheduleType => sampleScheduleModel?.selected ?? scheduleTypes[0];

  void updateSelectedScheduleType(newValue) {
    sampleScheduleModel!.selected = newValue;
    if(selectedScheduleType == scheduleTypes[1]) {
      sampleScheduleModel!.scheduleAsRunList.schedule['startDate'] = DateTime.now().toString();
    } else if(selectedScheduleType == scheduleTypes[2]) {
      sampleScheduleModel!.scheduleByDays.schedule['startDate'] = DateTime.now().toString();
    }
    notifyListeners();
  }

  void updateDayCountSchedule({required String property, required dynamic newValue}){
    sampleScheduleModel!.dayCountSchedule.schedule[property] = newValue;
    notifyListeners();
  }

  List<String> stopMethods = ["Continuous", "Stop time", "Max run time"];

  List<String> scheduleOptions = ['DO NOTHING', 'DO ONE TIME', 'DO WATERING', 'DO FERTIGATION'];

  void initializeDropdownValues(numberOfDays, existingDays, type) {
    if (sampleScheduleModel!.scheduleAsRunList.schedule['type'].isEmpty || int.parse(existingDays) == 0) {
      sampleScheduleModel!.scheduleAsRunList.schedule['type'] = List.generate(int.parse(numberOfDays), (index) => scheduleOptions[2]);
    } else {
      if (int.parse(numberOfDays) != int.parse(existingDays)) {
        if (int.parse(numberOfDays) < int.parse(existingDays)) {
          for (var i = 0; i < int.parse(existingDays); i++) {
            sampleScheduleModel!.scheduleAsRunList.schedule['type'][i] = type[i];
          }
        } else {
          var newDays = int.parse(numberOfDays) - int.parse(existingDays);
          for (var i = 0; i < newDays; i++) {
            sampleScheduleModel!.scheduleAsRunList.schedule['type'].add(scheduleOptions[2]);
          }
        }
      }
    }
    // print(type);
    notifyListeners();
  }

  void updateDropdownValue(index, newValue) {
    setAllSame(-1);
    if (index >= 0 && index < sampleScheduleModel!.scheduleAsRunList.schedule['type'].length) {
      sampleScheduleModel!.scheduleAsRunList.schedule['type'][index] = newValue;
    } else {
      sampleScheduleModel!.scheduleAsRunList.schedule['type'].add(newValue);
    }
    notifyListeners();
  }

  int selectedButtonIndex = -1;
  void setAllSame(index) {
    bool allSame = true;
    switch(index) {
      case 0:
        for (int i = 0; i < sampleScheduleModel!.scheduleAsRunList.schedule['type'].length; i++) {
          sampleScheduleModel!.scheduleAsRunList.schedule['type'][i] = scheduleOptions[0];
          if(sampleScheduleModel!.scheduleAsRunList.schedule['type'][i] != scheduleOptions[0]) {
            allSame = false;
          }
        }
        break;
      case 1:
        for (int i = 0; i < sampleScheduleModel!.scheduleAsRunList.schedule['type'].length; i++) {
          sampleScheduleModel!.scheduleAsRunList.schedule['type'][i] = scheduleOptions[1];
          if(sampleScheduleModel!.scheduleAsRunList.schedule['type'][i] != scheduleOptions[1]) {
            allSame = false;
          }
        }
        break;
      case 2:
        for (int i = 0; i < sampleScheduleModel!.scheduleAsRunList.schedule['type'].length; i++) {
          sampleScheduleModel!.scheduleAsRunList.schedule['type'][i] = scheduleOptions[2];
          if(sampleScheduleModel!.scheduleAsRunList.schedule['type'][i] != scheduleOptions[2]) {
            allSame = false;
          }
        }
        break;
      case 3:
        for (int i = 0; i < sampleScheduleModel!.scheduleAsRunList.schedule['type'].length; i++) {
          sampleScheduleModel!.scheduleAsRunList.schedule['type'][i] = scheduleOptions[3];
          if(sampleScheduleModel!.scheduleAsRunList.schedule['type'][i] != scheduleOptions[3]) {
            allSame = false;
          }
        }
        break;
    }
    if (allSame) {
      selectedButtonIndex = index;
    }
    notifyListeners();
  }

  String? errorText;

  void validateInputAndSetErrorText(input, runListLimit) {
    if (input.isEmpty) {
      errorText = 'Please enter a value';
    } else {
      int? parsedValue = int.tryParse(input);
      if (parsedValue == null) {
        errorText = 'Please enter a valid number';
      } else if (parsedValue > (runListLimit)) {
        errorText = 'Value should not exceed $runListLimit';
      } else {
        errorText = null;
      }
    }
    notifyListeners();
  }

  //TODO: CONDITIONS PROVIDER
  SampleConditions? _sampleConditions;
  SampleConditions? get sampleConditions => _sampleConditions;
  bool conditionsLibraryIsNotEmpty = false;

  Future<void> getUserProgramCondition(int userId, int controllerId, int serialNumber) async {
    try {
      var userData = {
        "userId": userId,
        "controllerId": controllerId,
        "serialNumber": serialNumber
      };
      var getUserProgramCondition = await repository.getUserProgramCondition(userData);

      _sampleConditions = null;
      // var getUserProgramCondition = await httpService.postRequest('getUserProgramCondition', userData);
      if(getUserProgramCondition.statusCode == 200) {
        final responseJson = getUserProgramCondition.body;
        final convertedJson = jsonDecode(responseJson);
        _sampleConditions = SampleConditions.fromJson(convertedJson);
      } else {
        log("HTTP Request failed or received an unexpected response.");
        throw Exception("Failed to load condition data");
      }
    } catch (e) {
      log('Error: $e');
      rethrow;
    }
    Future.delayed(Duration.zero, () {
      notifyListeners();
    });
  }

  void updateConditionType(newValue, conditionTypeIndex) {
    _sampleConditions!.condition[conditionTypeIndex].selected = newValue;
    notifyListeners();
  }

  void updateConditions(title, sNo, newValue, conditionTypeIndex) {
    // // print('$title, $sNo, $newValue, $conditionTypeIndex');
    _sampleConditions!.condition[conditionTypeIndex].value = {
      "sNo": sNo,
      "name" : newValue
    };
    notifyListeners();
  }

  //TODO: WATER AND FERT PROVIDER
  int sequenceSno = 0;
  List<dynamic> sequenceData = [];
  List<dynamic> serverDataWM = [];
  List<dynamic> channelData = [];
  int selectedGroup = 0;
  int selectedCentralSite = 0;
  int selectedLocalSite = 0;
  int selectedInjector = 0;
  String waterValueInTime = '';
  String waterValueInQuantity = '';
  List<dynamic> sequence = [];
  String radio = 'set individual';
  dynamic apiData = {};
  dynamic recipe = [];
  dynamic constantSetting = {};
  dynamic fertilizerSet = [];
  int segmentedControlGroupValue = 0;
  int segmentedControlCentralLocal = 0;
  TextEditingController waterQuantity = TextEditingController();
  TextEditingController preValue = TextEditingController();
  TextEditingController postValue = TextEditingController();
  TextEditingController ec = TextEditingController();
  TextEditingController ph = TextEditingController();
  TextEditingController channel = TextEditingController();
  TextEditingController injectorValue = TextEditingController();
  final Map<int, TextEditingController> _injectorControllers = {};
  ScrollController scrollControllerGroup = ScrollController();
  ScrollController scrollControllerSite = ScrollController();
  ScrollController scrollControllerInjector = ScrollController();
  int modelId = 0;

  Map<int, Widget> myTabs = <int, Widget>{
    0: const Padding(
      padding: EdgeInsets.all(5),
      child: Text("Water",style: TextStyle(color: Colors.black),),
    ),
    1: const Padding(
      padding: EdgeInsets.all(5),
      child: Text("Fertilizer",style: TextStyle(color: Colors.black)),
    ),
  };

  Map<int, Widget> cOrL = <int, Widget>{
    0: const Padding(
      padding: EdgeInsets.all(5),
      child: Text("Central",style: TextStyle(color: Colors.black),),
    ),
    1: const Padding(
      padding: EdgeInsets.all(5),
      child: Text("Local",style: TextStyle(color: Colors.black)),
    ),
  };

  void clearWaterFert(){
    sequenceSno = 0;
    sequenceData = [];
    serverDataWM = [];
    channelData = [];
    selectedGroup = 0;
    selectedCentralSite = 0;
    selectedLocalSite = 0;
    selectedInjector = 0;
    sequence = [];
    radio = 'set individual';
    recipe = [];
    constantSetting = {};
    fertilizerSet = [];
    segmentedControlGroupValue = 0;
    segmentedControlCentralLocal = 0;
    modelId = 0;
    // waterQuantity = TextEditingController();
    // preValue = TextEditingController();
    // postValue = TextEditingController();
    // ec = TextEditingController();
    // ph = TextEditingController();
    // injectorValue = TextEditingController();
    // scrollControllerGroup = ScrollController();
    // scrollControllerSite = ScrollController();
    // scrollControllerInjector = ScrollController();
    notifyListeners();
  }

  editFertilizerSet(dynamic data){
    fertilizerSet = data;
    notifyListeners();
  }

  void editSegmentedControlGroupValue(int value){
    segmentedControlGroupValue = value;
    myTabs = <int, Widget>{
      0: Padding(
        padding: const EdgeInsets.all(5),
        child: Text("Water",style: TextStyle(color: segmentedControlGroupValue == 0 ? Colors.black : Colors.black),),
      ),
      1: Padding(
        padding: const EdgeInsets.all(5),
        child: Text("Fertilizer",style: TextStyle(color: segmentedControlGroupValue == 1 ? Colors.black : Colors.black)),
      ),
    };
    notifyListeners();
  }

  List<Map<String, dynamic>> getOutletValveForChannel(dynamic channelSNo) {
    final double? targetChannelSNo = (channelSNo is num)
        ? channelSNo.toDouble()
        : double.tryParse(channelSNo.toString());

    dynamic matchedChannel;
    for (var ch in _rawFertilizerChannel) {
      final chSNo = (ch['sNo'] is num) ? (ch['sNo'] as num).toDouble() : double.tryParse(ch['sNo']?.toString() ?? '');
      if (chSNo == targetChannelSNo) {
        matchedChannel = ch;
        break;
      }
    }

    Set<double> allowedValveSNos = {};
    if (matchedChannel != null) {
      var rawValves = matchedChannel['outletTankValve'] ?? matchedChannel['tankValve'];
      if (rawValves is List && rawValves.isNotEmpty) {
        for (var v in rawValves) {
          if (v != null) {
            final double? parsedSNo = (v is num) ? v.toDouble() : double.tryParse(v.toString());
            if (parsedSNo != null) {
              allowedValveSNos.add(parsedSNo);
            }
          }
        }
      }
    }

    List<Map<String, dynamic>> result = [];

    // 1. Filter configObjects by allowed outlet tank valve sNos
    if (allowedValveSNos.isNotEmpty) {
      for (var obj in configObjects) {
        final double? objSNo = (obj['sNo'] is num) ? (obj['sNo'] as num).toDouble() : double.tryParse(obj['sNo']?.toString() ?? '');
        if (objSNo != null && allowedValveSNos.contains(objSNo)) {
          result.add({
            'sNo': objSNo,
            'name': obj['name'] ?? 'Outlet Tank Valve',
          });
        }
      }
      if (result.isNotEmpty) {
        return result;
      }
    }
    return result;
  }

  TextEditingController getInjectorController(int index){
    if (!_injectorControllers.containsKey(index)) {
      _injectorControllers[index] = TextEditingController();
    }
    return _injectorControllers[index]!;
  }

  void editSegmentedCentralLocal(int value){
    segmentedControlCentralLocal = value;
    selectedCentralSite = 0;
    selectedLocalSite = 0;
    selectedInjector = 0;
    // // print('first');
    if(sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'].length != 0){
      ec.text = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['ecValue'].toString() ?? '';
      ph.text = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['phValue'].toString() ?? '';
      for(var index = 0;index < sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['fertilizer'].length;index++){
        getInjectorController(index).text = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['fertilizer'][index]['quantityValue'].toString() ?? '';
      }
    }
    cOrL = <int, Widget>{
      0: Padding(
        padding: const EdgeInsets.all(5),
        child: Text("Central",style: TextStyle(color: segmentedControlCentralLocal == 0 ? Colors.black : Colors.black),),
      ),
      1: Padding(
        padding: const EdgeInsets.all(5),
        child: Text("Local",style: TextStyle(color: segmentedControlCentralLocal == 1 ? Colors.black : Colors.black)),
      ),
    };
    notifyListeners();
  }

  var waterAndFertData = [];

  // void selectingTheSite(){
  //   if(sequenceData.isNotEmpty){
  //     0 = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite'] == -1 ? 0 : sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite'];
  //     editGroupSiteInjector(segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite', sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite'] == -1 ? 0 : sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']);
  //   }
  //   notifyListeners();
  // }

  Future<void> getWaterAndFertData({required int userId, required int controllerId, required int serialNumber}) async {
    try {
      var userData = {
        "userId": userId,
        "controllerId": controllerId,
        "serialNumber": serialNumber
      };
      // print("userData : ${userData}");
      var getWaterAndFert = await repository.getUserProgramWaterAndFert(userData);
      var getRecipe = await repository.getUserFertilizerSet(userData);
      clearWaterFert();
      constantSetting = null;
      recipe = [];

      if(getWaterAndFert.statusCode == 200) {
        final responseJsonOfWaterAndFert = getWaterAndFert.body;
        final convertedJsonOfWaterAndFert = jsonDecode(responseJsonOfWaterAndFert);
        constantSetting = convertedJsonOfWaterAndFert['data']['default']['constant'];

        sequenceData = convertedJsonOfWaterAndFert['data']['waterAndFert'];
        updateEcPhAlarmsFromSequences();
      } else {
        log("HTTP Request failed or received an unexpected response.");
        throw Exception("Failed to load water and fert data");
      }

      if(getRecipe.statusCode == 200){
        final responseJsonOfRecipe = getRecipe.body;
        final convertedJsonOfRecipe = jsonDecode(responseJsonOfRecipe);
        recipe = convertedJsonOfRecipe['data']['fertilizerSet'];
        for (var r in recipe) {
          if (r['channel'] != null) {
            for (var ch in r['channel']) {
              if (ch['method'] == 'Pro.qty per 1000L') {
                ch['method'] = 'Pro.quant per 1000L';
              }
            }
          }
        }
      }else {
        log("HTTP Request failed for recipe.");
        throw Exception("Failed to load recipe data");
      }

      notifyListeners();
    } catch (e) {
      // log('Error: $e');
      rethrow;
    }
  }

  dynamic returnSequenceDataUpdate({required central,required local,required i,required sequence,required bool newSequence}){
    String prePostMethod = 'Time';
    String preValue = '00:00:00';
    String postValue = '00:00:00';
    bool applyFertilizerForCentral = false;
    bool applyFertilizerForLocal = false;
    String moistureCondition = '-';
    dynamic moistureSno = 0;
    bool applyMoisture = false;
    if(newSequence == false){
      prePostMethod = sequence[0]['prePostMethod'];
      preValue = sequence[0]['preValue'];
      postValue = sequence[0]['postValue'];
      moistureCondition = sequence[0]['moistureCondition'] ?? '-';
      moistureSno = sequence[0]['moistureSno'] ?? 0;
      applyMoisture = sequence[0]['applyMoisture'] ?? false;
    }
    var centralDuplicate = [];
    for(var i in central){
      var line = apiData['irrigationLine'].where((line)=> line['centralFertilization'] == i['sNo']).map((line) => {
        'objectId' : line['objectId'],
        'sNo' : line['sNo'],
        'name' : line['name'],
      }).toList();
      var channel = i['channel'].map((channel) => {
        'objectId' : channel['objectId'],
        'sNo' : channel['sNo'],
        'name' : channel['name'],
      }).toList();
      var ec = i['ec'].map((ec) => {
        'objectId' : ec['objectId'],
        'sNo' : ec['sNo'],
        'name' : ec['name'],
      }).toList();
      var ph = i['ph'].map((ph) => {
        'objectId' : ph['objectId'],
        'sNo' : ph['sNo'],
        'name' : ph['name'],
      }).toList();
      centralDuplicate.add({
        'sNo' : i['sNo'],
        'name' : i['name'],
        'location' : i['location'],
        'irrigationLine' : line,
        'channel' : channel,
        'ecSensor' : ec,
        'phSensor' : ph,
      });
    }
    var localDuplicate = [];
    for(var i in local){
      var line = apiData['irrigationLine'].where((line)=> line['localFertilization'] == i['sNo']).map((line) => {
        'objectId' : line['objectId'],
        'sNo' : line['sNo'],
        'name' : line['name'],
      }).toList();
      var channel = i['channel'].map((channel) => {
        'objectId' : channel['objectId'],
        'sNo' : channel['sNo'],
        'name' : channel['name'],
      }).toList();
      var ec = i['ec'].map((ec) => {
        'objectId' : ec['objectId'],
        'sNo' : ec['sNo'],
        'name' : ec['name'],
      }).toList();
      var ph = i['ph'].map((ph) => {
        'objectId' : ph['objectId'],
        'sNo' : ph['sNo'],
        'name' : ph['name'],
      }).toList();
      localDuplicate.add({
        'sNo' : i['sNo'],
        'name' : i['name'],
        'location' : i['location'],
        'irrigationLine' : line,
        'channel' : channel,
        'ecSensor' : ec,
        'phSensor' : ph,
      });
    }
    var generateNew = [];
    var myCentral = [];
    var myLocal = [];

    // this process is to find the central site for the sequence
    bool centralSelectedOrNot = selectedObjects!.any((object) => object.objectId == 3 && object.siteMode == 1);
    if(centralSelectedOrNot){
      double centralSiteSnoThatSelectedInSelection = selectedObjects!.where((object)=> object.objectId == 3 && object.siteMode == 1).toList()[0].sNo!;
      for(var cd in centralDuplicate){
        if(cd['sNo'] == centralSiteSnoThatSelectedInSelection){
          int recipe = -1;
          bool applyRecipe = false;
          if(newSequence == false){
            if(sequence[0]['centralDosing'].isNotEmpty){
              if(sequence[0]['centralDosing'][0]['sNo'] == centralSiteSnoThatSelectedInSelection){
                recipe = sequence[0]['centralDosing'][0]['recipe'];
                applyRecipe = sequence[0]['centralDosing'][0]['applyRecipe'];
                applyFertilizerForCentral = sequence[0]['applyFertilizerForCentral'];
              }
            }
          }
          var createSite = {
            'objectId' : cd['objectId'],
            'sNo' : cd['sNo'],
            'name' : cd['name'],
            'recipe' : recipe,
            'applyRecipe' : applyRecipe,
          };
          var fertilizer = [];
          for(var fert in cd['channel']){
            String method = 'Time';
            String timeValue = '00:00:00';
            String quantityValue = '';
            double? outletTankValve;
            bool onOff = false;
            if(newSequence == false){
              if(sequence[0]['centralDosing'].isNotEmpty){
                for(var oldFert in sequence[0]['centralDosing'][0]['fertilizer']){
                  if(oldFert['sNo'] == fert['sNo']){
                    method = oldFert['method'];
                    timeValue = oldFert['timeValue'];
                    quantityValue = oldFert['quantityValue'];
                    onOff = oldFert['onOff'];
                    if (oldFert['outletTankValve'] != null && oldFert['outletTankValve'] is double) {
                      outletTankValve = oldFert['outletTankValve'];
                    }
                    break;
                  }
                }
              }

            }
            fert['method'] = method;
            fert['timeValue'] = timeValue;
            fert['quantityValue'] = quantityValue;
            fert['onOff'] = onOff;
            fert['outletTankValve'] = outletTankValve;
            fertilizer.add(fert);
          }

          if(cd['ecSensor'].length != 0){
            String ecValue = '0';
            bool needEcValue = false;
            if(newSequence == false){
              if(sequence[0]['centralDosing'].isNotEmpty){
                ecValue = (sequence[0]['centralDosing'][0]['ecValue'] ?? '').toString();
                needEcValue = sequence[0]['centralDosing'][0]['needEcValue'] ?? false;
              }
            }
            createSite['ecValue'] = ecValue;
            createSite['needEcValue'] = needEcValue;
          }
          if(cd['phSensor'].length != 0){
            String phValue = '0';
            bool needPhValue = false;
            if(newSequence == false){
              if(sequence[0]['centralDosing'].isNotEmpty){
                phValue = (sequence[0]['centralDosing'][0]['phValue'] ?? '').toString();
                needPhValue = sequence[0]['centralDosing'][0]['needPhValue'] ?? false;
              }
            }
            createSite['phValue'] = phValue;
            createSite['needPhValue'] = needPhValue;
          }
          createSite['fertilizer'] = fertilizer;
          myCentral.add(createSite);
        }
      }
    }
    // process end for central

    // this process is to find the local site for the sequence
    bool localSelectedOrNot = selectedObjects!.any((object) => object.objectId == 3 && object.siteMode == 2);
    if(localSelectedOrNot){
      double localSiteSnoThatSelectedInSelection = selectedObjects!.where((object)=> object.objectId == 3 && object.siteMode == 2).toList()[0].sNo!;
      for(var ld in localDuplicate){
        if(ld['sNo'] == localSiteSnoThatSelectedInSelection){
          int recipe = -1;
          bool applyRecipe = false;
          if(newSequence == false){
            if(sequence[0]['localDosing'].isNotEmpty){
              if(sequence[0]['localDosing'][0]['sNo'] == localSiteSnoThatSelectedInSelection){
                recipe = sequence[0]['localDosing'][0]['recipe'];
                applyRecipe = sequence[0]['localDosing'][0]['applyRecipe'];
                applyFertilizerForLocal = sequence[0]['applyFertilizerForLocal'];
              }
            }
          }
          var createSite = {
            'objectId' : ld['objectId'],
            'sNo' : ld['sNo'],
            'name' : ld['name'],
            'recipe' : recipe,
            'applyRecipe' : applyRecipe,
          };
          var fertilizer = [];
          for(var fert in ld['channel']){
            String method = 'Time';
            String timeValue = '00:00:00';
            String quantityValue = '';
            double? outletTankValve;
            bool onOff = false;
            if(newSequence == false){
              if(sequence[0]['localDosing'].isNotEmpty){
                for(var oldFert in sequence[0]['localDosing'][0]['fertilizer']){
                  if(oldFert['sNo'] == fert['sNo']){
                    method = oldFert['method'];
                    timeValue = oldFert['timeValue'];
                    quantityValue = oldFert['quantityValue'];
                    onOff = oldFert['onOff'];
                    if (oldFert['outletTankValve'] != null && oldFert['outletTankValve'] is double) {
                      outletTankValve = oldFert['outletTankValve'];
                    }
                    break;
                  }
                }
              }

            }
            fert['method'] = method;
            fert['timeValue'] = timeValue;
            fert['quantityValue'] = quantityValue;
            fert['onOff'] = onOff;
            fert['outletTankValve'] = outletTankValve;
            fertilizer.add(fert);
          }
          if(ld['ecSensor'].length != 0){
            String ecValue = '0';
            bool needEcValue = false;
            if(newSequence == false){
              if(sequence[0]['localDosing'].isNotEmpty){
                ecValue = (sequence[0]['localDosing'][0]['ecValue'] ?? '').toString();
                needEcValue = sequence[0]['localDosing'][0]['needEcValue'] ?? false;
              }
            }
            createSite['ecValue'] = ecValue;
            createSite['needEcValue'] = needEcValue;
          }
          if(ld['phSensor'].length != 0){
            String phValue = '0';
            bool needPhValue = false;
            if(newSequence == false){
              if(sequence[0]['localDosing'].isNotEmpty){
                phValue = (sequence[0]['localDosing'][0]['phValue'] ?? '').toString();
                needPhValue = sequence[0]['localDosing'][0]['needPhValue'] ?? false;
              }
            }
            createSite['phValue'] = phValue;
            createSite['needPhValue'] = needPhValue;
          }
          createSite['fertilizer'] = fertilizer;
          myLocal.add(createSite);
        }
      }
    }
    // process end for local


    // update sequence value default or data from http
    String method = 'Time';
    String timeValue = '00:00:00';
    String quantityValue = '0';
    if(newSequence == false){
      method = sequence[0]['method'];
      timeValue = sequence[0]['timeValue'];
      quantityValue = sequence[0]['quantityValue'];
    }

    generateNew.add({
      'sNo' : sequence[0]['sNo'],
      'valve' : sequence[0]['valve'],
      'mainValve' : sequence[0]['mainValve'],
      'seqName' : sequence[0]['seqName'],
      'moistureCondition' : moistureCondition,
      'moistureSno' : moistureSno,
      'applyMoisture' : applyMoisture,
      'levelCondition' : '-',
      'levelSno' : 0,
      'prePostMethod' : prePostMethod,
      'preValue' : preValue,
      'postValue' : postValue,
      'method' : method,
      'timeValue' : timeValue,
      'quantityValue' : quantityValue,
      'centralDosing' : myCentral,
      'localDosing' : myLocal,
      'applyFertilizerForCentral' : applyFertilizerForCentral,
      'applyFertilizerForLocal' : applyFertilizerForLocal,
      'selectedCentralSite' : 0,
      'selectedLocalSite' : 0,
    });
    // print('generateNew : $generateNew');
    return generateNew;
  }

  bool isSiteVisible(data,localOrCentral){
    var checkList = [];
    for(var i in data){
      checkList.add(i['sNo']);
    }
    bool CentralpgmMode = false;
    bool LocalpgmMode = false;
    bool visible = false;
    /*if(localOrCentral == 'central'){
      for(var pm in selectionModel!.data!.centralFertilizerSite!){
        if(pm.selected == true){
          CentralpgmMode = true;
        }
      }
    }
    if(localOrCentral == 'local'){
      for(var pm in selectionModel!.data!.localFertilizerSite!){
        if(pm.selected == true){
          LocalpgmMode = true;
        }
      }
    }
    if(localOrCentral == 'central'){
      if(CentralpgmMode == true){
        for(var slt in selectionModel!.data!.centralFertilizerSite!){
          // // print('slt.selected : ${slt.selected}');
          // // print('slt.sNo : ${slt.sNo}');
          if(slt.selected == true){
            if(checkList.contains(slt.sNo)){
              visible = true;
            }
          }
        }

      }
    }
    if(localOrCentral == 'local'){
      if(LocalpgmMode == true){
        for(var slt in selectionModel!.data!.localFertilizerSite!){
          if(slt.selected == true){
            if(checkList.contains(slt.sNo)){
              visible = true;
            }
          }
        }
      }
    }*/
    return ((localOrCentral == 'central' ? CentralpgmMode : LocalpgmMode) == true) ? visible : true;
  }

  dynamic deepCopy(dynamic originalList) {
    dynamic copiedList = [];
    if(originalList.isNotEmpty){
      for (var map in originalList) {
        copiedList.add(Map.from({
          "sNo": map['sNo'],
          "id": map['id'],
          "seqName": map['name'],
          "location": map['location'],
          "valve": List.from(map['valve']),
          "mainValve": List.from(map['mainValve']),
        }));
      }
    }

    return copiedList;
  }

  void waterAndFert(int model){
    modelId = model;
    final valSeqList = deepCopy(_irrigationLine!.sequence);
    var givenSeq = [];
    var myOldSeq = [];
    if(valSeqList.isNotEmpty){
      for(var i in valSeqList){
        // print("sequence sno == ${i['sNo']}");
        givenSeq.add(i['sNo']);
      }
    }
    // print('givenSeq : $givenSeq');
    if(sequenceData.isNotEmpty){
      for(var i in sequenceData){
        myOldSeq.add(i['sNo']);
      }
    }
    var generateNew = [];
    var central = [];
    var local = [];
    // print("apiData : $apiData");
    for(var site in apiData['fertilizerSite']){
      if(site['siteMode'] == 1){
        central.add(site);
      }else{
        local.add(site);
      }
    }
    for(var i = 0;i < valSeqList.length;i++){
      var seqList = [];
      bool newData = false;
      if(myOldSeq.isNotEmpty){
        add : for(var j = 0;j < myOldSeq.length;j++){
          if(myOldSeq.contains(valSeqList[i]['sNo'])){
            if(valSeqList[i]['sNo'] == myOldSeq[j]){
              if(valSeqList[i]['valve'].length == sequenceData[j]['valve'].length){
                for(var lst in sequenceData[j]['valve']){
                  seqList.add(lst['sNo']);
                }
                checkValve : for(var checkVal in valSeqList[i]['valve']){
                  if(!seqList.contains(checkVal['sNo'])){
                    newData = true;
                    break checkValve;
                  }else{
                    newData = false;
                  }
                }
                if(newData == true){
                  generateNew.addAll(returnSequenceDataUpdate(central: central, local: local, i: i,sequence: [valSeqList[i]],newSequence: true));
                  break add;
                }else{
                  sequenceData[j]['seqName'] = valSeqList[i]['seqName'];
                  sequenceData[j]['mainValve'] = valSeqList[i]['mainValve'];
                  generateNew.addAll(returnSequenceDataUpdate(central: central, local: local, i: i,sequence: [sequenceData[j]],newSequence: false));
                  break add;
                }
              }else{
                generateNew.addAll(returnSequenceDataUpdate(central: central, local: local, i: i,sequence: [valSeqList[i]],newSequence: true));
              }
            }
          }else{
            generateNew.addAll(returnSequenceDataUpdate(central: central, local: local, i: i,sequence: [valSeqList[i]],newSequence: true));
            break add;
          }
        }
      }else{
        generateNew.addAll(returnSequenceDataUpdate(central: central, local: local, i: i,sequence: [valSeqList[i]],newSequence: true));
      }
    }

    sequenceData = generateNew;
    updateEcPhAlarmsFromSequences();
    if(sequenceData.isNotEmpty){
      if (currentIndex >= 0 && currentIndex < sequenceData.length) {
        selectedGroup = currentIndex;
      } else if (selectedGroup >= 0 && selectedGroup < sequenceData.length) {
        currentIndex = selectedGroup;
      } else {
        selectedGroup = 0;
        currentIndex = 0;
      }
      waterValueInTime = sequenceData[selectedGroup]['timeValue'];
      // print('waterValueInTime : ${waterValueInTime}');
      waterQuantity.text = sequenceData[selectedGroup]['quantityValue'] ?? '';
      preValue.text = sequenceData[selectedGroup]['preValue'] ?? '';
      postValue.text = sequenceData[selectedGroup]['postValue'] ?? '';
      if(sequenceData[selectedGroup]['centralDosing'].isNotEmpty){
        ec.text = sequenceData[selectedGroup]['centralDosing']?[selectedCentralSite]?['ecValue'].toString() ?? '';
        ph.text = sequenceData[selectedGroup]['centralDosing']?[selectedCentralSite]?['phValue'].toString() ?? '';
      }
    }
    if(sequenceData[selectedGroup]['centralDosing'].isNotEmpty){
      segmentedControlCentralLocal = 0;
    }else if(sequenceData[selectedGroup]['localDosing'].isNotEmpty){
      segmentedControlCentralLocal = 1;
    }
    for(var seq in sequenceData){
      // print('seq ==== ${seq['sNo']}');
    }

    // print('after seq : ${sequenceData}');
    refreshTime();
    notifyListeners();
  }

  String fertMethodHw(String value){
    switch (value){
      case ('Time'):{
        return '1';
      }
      case ('Pro.time'):{
        return '3';
      }
      case ('Quantity'):{
        return '2';
      }
      case ('Pro.quantity'):{
        return '4';
      }
      case ('Pro.quant per 1000L'):{
        return '5';
      }
      default : {
        return '0';
      }
    }
  }

  String zeroWithUnderScore(int total){
    return List.generate(total, (index) => '0').join('_');
  }

  dynamic hwPayloadForWF(serialNumber, programType){
    var wf = '';
    var payload = '';
    int channelLimit = 20;
    editGroupSiteInjector('selectedGroup', 0);
    for(var sq in sequenceData){
      editGroupSiteInjector('selectedGroup', sequenceData.indexOf(sq));
      var valId = '';
      var mvId = '';
      for(var vl in sq['valve']){
        valId += '${valId.isNotEmpty ? '_' : ''}${vl['sNo']}';
      }
      for(var vl in sq['mainValve']){
        mvId += '${mvId.isNotEmpty ? '_' : ''}${vl['sNo']}';
      }

      // final joined strings (used in the payload)
      var centralMethod = '';
      var centralTimeAndQuantity = '';
      var centralFertOnOff = '';
      var centralFertSno = '';
      var centralEcActive = 0;
      var centralEcValue = '';
      var centralPhActive = 0;
      var centralPhValue = '';
      var localMethod = '';
      var localTimeAndQuantity = '';
      var localFertOnOff = '';
      var localFertId = '';
      var localEcActive = 0;
      var localEcValue = '';
      var localPhActive = 0;
      var localPhValue = '';
      var centralTankValve = '';
      var localTankValve = '';

      // lists collected inside the loops, joined after the loops
      List<String> centralMethodList = [];
      List<String> centralTimeAndQuantityList = [];
      List<String> centralFertOnOffList = [];
      List<String> centralFertSnoList = [];
      List<String> centralTankValveList = [];

      List<String> localMethodList = [];
      List<String> localTimeAndQuantityList = [];
      List<String> localFertOnOffList = [];
      List<String> localFertIdList = [];
      List<String> localTankValveList = [];

      // ---------------- CENTRAL ----------------
      if(!isSiteVisible(sq['centralDosing'],'central') || sq[segmentedControlCentralLocal == 0 ? 'applyFertilizerForCentral' : 'applyFertilizerForLocal'] == false || sq['centralDosing'].isEmpty || sq['selectedCentralSite'] == -1){
        centralMethod = zeroWithUnderScore(channelLimit);
        centralTimeAndQuantity = zeroWithUnderScore(channelLimit);
        centralFertOnOff = zeroWithUnderScore(channelLimit);
        centralTankValve = zeroWithUnderScore(channelLimit);
        centralEcActive = 0;
        centralEcValue = '';
        centralPhActive = 0;
        centralPhValue = '';
      }else{
        var site = sq['centralDosing'][sq['selectedCentralSite']];

        for(var ft in site['fertilizer']){
          centralMethodList.add('${fertMethodHw(ft['method'])}');
          centralFertOnOffList.add('${ft['onOff'] == true ? 1 : 0}');
          centralFertSnoList.add('${ft['sNo']}');
          centralTankValveList.add(ft['outletTankValve'] == null ? '' : ft['outletTankValve'].toString());
          centralTimeAndQuantityList.add('${ft['method'].contains('ime') ? ft['timeValue'] : ft['quantityValue']}');
        }

        // EC / PH do not depend on the fertilizer, so set them once
        centralEcActive = site['needEcValue'] == true ? 1 : 0;
        centralEcValue = '${site['ecValue'] ?? 0}';
        centralPhActive = site['needPhValue'] == true ? 1 : 0;
        centralPhValue = '${site['phValue'] ?? 0}';

        // pad with zeros up to channelLimit
        for(var i = centralMethodList.length; i < channelLimit; i++){
          centralMethodList.add('0');
          centralTimeAndQuantityList.add('0');
          centralFertOnOffList.add('0');
          centralTankValveList.add('');
        }

        // join after the loop
        centralMethod = centralMethodList.join('_');
        centralFertOnOff = centralFertOnOffList.join('_');
        centralFertSno = centralFertSnoList.join('_');
        centralTankValve = centralTankValveList.join('_');
        centralTimeAndQuantity = centralTimeAndQuantityList.join('_');
      }

      // ---------------- LOCAL ----------------
      if(!isSiteVisible(sq['localDosing'],'local') || sq[segmentedControlCentralLocal == 0 ? 'applyFertilizerForCentral' : 'applyFertilizerForLocal'] == false || sq['localDosing'].isEmpty || sq['selectedLocalSite'] == -1){
        localMethod = zeroWithUnderScore(channelLimit);
        localTimeAndQuantity = zeroWithUnderScore(channelLimit);
        localFertOnOff = zeroWithUnderScore(channelLimit);
        localTankValve = zeroWithUnderScore(channelLimit);
        localEcActive = 0;
        localEcValue = '';
        localPhActive = 0;
        localPhValue = '';
      }else{
        var site = sq['localDosing'][sq['selectedLocalSite']];

        for(var ft in site['fertilizer']){
          localMethodList.add(fertMethodHw(ft['method']));
          localFertOnOffList.add('${ft['onOff'] == true ? 1 : 0}');
          localFertIdList.add('${ft['sNo']}');
          localTankValveList.add(ft['outletTankValve'] == null ? '' : ft['outletTankValve'].toString());
          localTimeAndQuantityList.add('${ft['method'].contains('ime') ? ft['timeValue'] : ft['quantityValue']}');
        }

        localEcActive = site['needEcValue'] == true ? 1 : 0;
        localEcValue = '${site['ecValue'] ?? 0}';
        localPhActive = site['needPhValue'] == true ? 1 : 0;
        localPhValue = '${site['phValue'] ?? 0}';

        for(var i = localMethodList.length; i < channelLimit; i++){
          localMethodList.add('0');
          localTimeAndQuantityList.add('0');
          localFertOnOffList.add('0');
          localTankValveList.add('');
        }

        localMethod = localMethodList.join('_');
        localFertOnOff = localFertOnOffList.join('_');
        localFertId = localFertIdList.join('_');
        localTankValve = localTankValveList.join('_');
        localTimeAndQuantity = localTimeAndQuantityList.join('_');
      }

      payload += payload.isNotEmpty ? ';' : '';
      print("sq['mainValve'] : ${sq['mainValve']}");
      Map<String, dynamic> jsonPayload = {
        'S_No' : sq['sNo'],
        'ProgramS_No' : serialNumber,
        'SequenceData' : sq['valve'].map((valve) => valve['sNo']).toList().join('_'),
        'MainValve' : sq['mainValve'].map((mainValve) => mainValve['sNo']).toList().join('_'),
        'Pump' : '',
        'ValveFlowrate' : programType == "Irrigation Program" ? getNominalFlow() : 1,
        'IrrigationMethod' : sq['method'] == 'Time' ? 1 : 2,
        'IrrigationDuration_Quantity' : sq['method'] == 'Time' ? sq['timeValue'] : sq['quantityValue'],
        'CentralFertOnOff' : sq['applyFertilizerForCentral'] == false ? 0 : sq['selectedCentralSite'] == -1 ? 0 : 1,
        'CentralFertilizerSite' : sq['selectedCentralSite'] == -1 ? 0 : sq['centralDosing'].isEmpty ? 0 : sq['centralDosing'][sq['selectedCentralSite']]['sNo'],
        'LocalFertOnOff' : sq['applyFertilizerForLocal'] == false ? 0 : sq['selectedLocalSite'] == -1 ? 0 : 1,
        'LocalFertilizerSite' : sq['selectedLocalSite'] == -1 ? 0 : sq['localDosing'].isEmpty ? 0 : sq['localDosing'][sq['selectedLocalSite']]['sNo'],
        'PrePostMethod' : sq['prePostMethod'] == 'Time' ? 1 : 2,
        'PreTime_PreQty' : sq['preValue'],
        'PostTime_PostQty' : sq['postValue'],
        'CentralFertMethod' : centralMethod,
        'LocalFertMethod' : localMethod,
        'CentralFertChannelSelection' : centralFertOnOff,
        'LocalFertChannelSelection' : localFertOnOff,
        'CentralFertDuration_Qty' : centralTimeAndQuantity,
        'LocalFertDuration_Qty' : localTimeAndQuantity,
        'CentralEcBasedOnOff' : centralEcActive,
        'CentralEcSetValue' : centralEcValue == '' ? 0.0 : double.parse(centralEcValue),
        'CentralPhBasedOnOff' : centralPhActive,
        'CentralPhSetValue' : centralPhValue == '' ? 0.0 : double.parse(centralPhValue),
        'LocalEcBasedOnOff' : localEcActive,
        'LocalEcSetValue' : localEcValue == '' ? 0.0 : double.parse(localEcValue),
        'LocalPhBasedOnOff' : localPhActive,
        'LocalPhSetValue' : localPhValue == '' ? 0.0 : double.parse(localPhValue),
        'ZoneCondition' : sq['moistureSno'],
        'ImmediateStopByCondition' : sq['levelSno'],
        'Name' : sq['seqName'],
        'CentralFertTank' : centralTankValve,
        'LocalFertTank' : localTankValve,
      };
      payload += jsonPayload.values.toList().join(',');
    }
    return payload;
  }


  dynamic ecoGemPayloadForWF(serialNumber){
    var wf = '';
    var payload = '';
    editGroupSiteInjector('selectedGroup', 0);
    int channelLimit = AppConstants.ecoGemAndPlusModelList.contains(modelId) ? 1 : 8;
    for(var sq in sequenceData){
      editGroupSiteInjector('selectedGroup', sequenceData.indexOf(sq));
      var valId = '';
      for(var vl in sq['valve']){
        valId += '${valId.isNotEmpty ? '_' : ''}${vl['sNo']}';
      }
      var centralMethod = '';
      var centralTimeAndQuantity = '';
      var centralFertOnOff = '';
      var centralFertSno = '';
      var localMethod = '';
      var localTimeAndQuantity = '';
      var localFertOnOff = '';
      var localFertId = '';
      if(!isSiteVisible(sq['centralDosing'],'central') || sq[segmentedControlCentralLocal == 0 ? 'applyFertilizerForCentral' : 'applyFertilizerForLocal'] == false || sq['centralDosing'].isEmpty || sq['selectedCentralSite'] == -1){
        centralMethod = channelLimit == 1 ? '0' : '0_0_0_0_0_0_0_0';
        centralTimeAndQuantity += channelLimit == 1 ? '0' : '0_0_0_0_0_0_0_0';
        centralFertOnOff += channelLimit == 1 ? '0' : '0_0_0_0_0_0_0_0';
      }else{
        var fertList = [];
        for(var ft in sq['centralDosing'][sq['selectedCentralSite']]['fertilizer']){
          centralMethod += '${centralMethod.isNotEmpty ? '_' : ''}${fertMethodHw(ft['method'])}';
          centralFertOnOff += '${centralFertOnOff.isNotEmpty ? '_' : ''}${ft['onOff'] == true ? 1 : 0}';
          centralFertSno += '${centralFertSno.isNotEmpty ? '_' : ''}${ft['sNo']}';
          centralTimeAndQuantity += '${centralTimeAndQuantity.isNotEmpty ? '_' : ''}${ft['method'].contains('ime') ? ft['timeValue'] : ft['quantityValue']}';
          fertList.add(fertMethodHw(ft['method']));
        }
        for(var coma = fertList.length;coma < channelLimit;coma++){
          centralMethod += '${centralMethod.isNotEmpty ? '_' : ''}0';
          centralTimeAndQuantity += '${centralTimeAndQuantity.isNotEmpty ? '_' : ''}0';
          centralFertOnOff += '${centralFertOnOff.isNotEmpty ? '_' : ''}0';
        }
      }

      if(!isSiteVisible(sq['localDosing'],'local') || sq[segmentedControlCentralLocal == 0 ? 'applyFertilizerForCentral' : 'applyFertilizerForLocal'] == false || sq['localDosing'].isEmpty || sq['selectedLocalSite'] == -1){
        localMethod = channelLimit == 1 ? '0' : '0_0_0_0_0_0_0_0';
        localTimeAndQuantity += channelLimit == 1 ? '0' : '0_0_0_0_0_0_0_0';
        localFertOnOff += channelLimit == 1 ? '0' : '0_0_0_0_0_0_0_0';
      }else{
        var fertList = [];
        for(var ft in sq['localDosing'][sq['selectedLocalSite']]['fertilizer']){
          localMethod += '${localMethod.isNotEmpty ? '_' : ''}${fertMethodHw(ft['method'])}';
          localFertOnOff += '${localFertOnOff.isNotEmpty ? '_' : ''}${ft['onOff'] == true ? 1 : 0}';
          localFertId += '${localFertId.isNotEmpty ? '_' : ''}${ft['sNo']}';
          localTimeAndQuantity += '${localTimeAndQuantity.isNotEmpty ? '_' : ''}${ft['method'].contains('ime') ? ft['timeValue'] : ft['quantityValue']}';
          fertList.add(fertMethodHw(ft['method']));
        }
        for(var coma = fertList.length;coma < channelLimit;coma++){
          localMethod += '${localMethod.isNotEmpty ? '_' : ''}0';
          localTimeAndQuantity += '${localTimeAndQuantity.isNotEmpty ? '_' : ''}0';
          localFertOnOff += '${localFertOnOff.isNotEmpty ? '_' : ''}0';
        }
      }
      payload += payload.isNotEmpty ? ';' : '';
      /*print('sq :: $sq');
      print('sq moisture :: ${sq['moistureSno']}');
      print('sq level :: ${sq['levelSno']}');*/
      var getValve = [];
      for(var v = 0;v < 4;v++){
        if(sq['valve'].length > v){
          String valSerialNo = sq['valve'][v]['sNo'].toString().split('.')[1];
          if(valSerialNo.length == 2){
            valSerialNo += '0';
          }
          getValve.add(valSerialNo);
        }else{
          getValve.add('0');
        }
      }
      // String sequenceSerialNo = sq['sNo'].toString();
      // String valSerialNo = sq['valve'][v]['sNo'].toString().split('.')[1];
      // String zoneSerialNo = sequenceSerialNo.contains('.') ? sequenceSerialNo.split('.')[1] : sequenceSerialNo;
      String zoneTime = '';
      String zoneQuantity = '';
      print("sequenceData[selectedGroup]['quantityValue'] : ${sequenceData[selectedGroup]['quantityValue']}");
      print("getNominalFlow() : ${getNominalFlow()}");
      zoneTime = DataConvert().convertLitersToTime(double.parse(sequenceData[selectedGroup]['quantityValue']), getNominalFlow());

      zoneQuantity = DataConvert().convertTimeToLiters(sequenceData[selectedGroup]['timeValue'], getNominalFlow());
      Map<String, dynamic> jsonPayload = {
        'Zone_No' : sq['sNo'],
        'Program_No' : serialNumber,
        'SequenceData' : getValve.join(','),
        'ValveFlowRate' : getNominalFlow(),
        'IrrigationMethod' : sq['method'] == 'Time' ? 1 : 2,
        'IrrigationDuration_Quantity' : timeAndQuantityForWaterValueInEcoGem(
            sq['method'] == 'Time'
                ? sequenceData[selectedGroup]['timeValue']
                : zoneTime,
            sequenceData[selectedGroup]['quantityValue']),
        'CentralFertOnOff' : sq['applyFertilizerForCentral'] == false ? 0 : sq['selectedCentralSite'] == -1 ? 0 : 1,
        // 'PrePostMethod' : sq['prePostMethod'] == 'Time' ? 1 : 2,
        'PreTime_PreQty' : timeAndQuantityForEcoGem(sq['preValue']),
        'PostTime_PostQty' : timeAndQuantityForEcoGem(sq['postValue']),
        'CentralFertMethod' : centralMethod,
        // 'CentralFertChannelSelection' : centralFertOnOff,
        'CentralFertDuration_Qty' : timeAndQuantityForEcoGem(centralTimeAndQuantity),
      };
      payload += jsonPayload.values.toList().join(',');
    }
    List<String> originalList = payload.split(';');
    List<List<String>> subLists = [];
    List<String> payLoadList = [];
    int howMuchPayloadNeedToSendInSingleShot = 8;
    for (int i = 0; i < originalList.length; i += howMuchPayloadNeedToSendInSingleShot) {
      int end = (i + howMuchPayloadNeedToSendInSingleShot < originalList.length) ? i + howMuchPayloadNeedToSendInSingleShot : originalList.length;
      subLists.add(originalList.sublist(i, end));
    }
    payLoadList = subLists.map((e) => (e as List).join(';')).toList();
    // print('payLoadList :: ${jsonEncode(payLoadList)}');
    return payLoadList;
  }

  String timeAndQuantityForEcoGem(String value){
    if(value.contains(':')){
      var timePayload = value.split(':').join(',');
      return '$timePayload,0';
    }else{
      return '0,0,0,$value';
    }
  }

  String timeAndQuantityForWaterValueInEcoGem(String timeValue, String quantityValue){
    var timePayload = timeValue.split(':').join(',');
    return '$timePayload,$quantityValue';
  }

  dynamic editWaterSetting(String title, String value){
    print("water method updated...........111111");

    if(title == 'method'){
      var maxFertInSec = getMaxFertilizerValueForSelectedSequence();
      var diff = (postValueInSec() + preValueInSec() + maxFertInSec);
      var quantity = diff * flowRate();

      if(AppConstants.ecoGemAndPlusModelList.contains(modelId)){
        if(sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'].isNotEmpty){
          for(var fert in sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['fertilizer']){
            fert['method'] = value;
            fert['timeValue'] = '00:00:00';
            fert['quantityValue'] = '0';
          }
        }
      }

      if(value == 'Time'){
        sequenceData[selectedGroup]['timeValue'] = formatTime(diff);
      }else{
        sequenceData[selectedGroup]['quantityValue'] = '${quantity.toInt() == 0 ? 0 : quantity.toInt() + 1}';
        waterQuantity.text = '${quantity.toInt() == 0 ? 0 : quantity.toInt() + 1}';
      }

      sequenceData[selectedGroup]['method'] = value;
      if(sequenceData[selectedGroup]['method'] == 'Time'){
        if(sequenceData[selectedGroup]['timeValue'] == '00:00:00'){
          waterValueInTime = '00:00:00';
          waterValueInQuantity = '0';

        }else{
          refreshTime();
        }
      }else{
        if(sequenceData[selectedGroup]['quantityValue'] == '0'){
          waterValueInQuantity = '0';
          waterValueInTime = '00:00:00';
        }else{
          refreshTime();
        }
      }
      /*if(sequenceData[selectedGroup]['method'] == 'Time' && value == 'Time'){
        // don't do anything...
      }else if(value == 'Time'){
        sequenceData[selectedGroup]['timeValue'] = DataConvert().convertLitersToTime(double.parse(sequenceData[selectedGroup]['quantityValue']), getNominalFlow());
      }else{
        sequenceData[selectedGroup]['quantityValue'] = DataConvert().convertTimeToLiters(sequenceData[selectedGroup]['timeValue'], getNominalFlow());
      }
      sequenceData[selectedGroup]['method'] = value;*/
      print("water method updated...........");
    }else if(title == 'timeValue'){
      sequenceData[selectedGroup]['timeValue'] = value;
      refreshTime();
    }
    else if(title == 'quantityValue'){
      var maxFertInSec = getMaxFertilizerValueForSelectedSequence();
      int currentWaterValueInSec = waterValueInSec();
      if(currentWaterValueInSec > (24*3600)){
        var oneDayQuantity = flowRate() * (24*3600);
        // print('one day == > $oneDayQuantity');
        sequenceData[selectedGroup]['quantityValue'] = '${oneDayQuantity.toInt()}';
        waterQuantity.text = '${oneDayQuantity.toInt()}';
        refreshTime();
        return {'message' : 'water value limit up to 24 hours'};
      }
      var diff = (postValueInSec() + preValueInSec() + maxFertInSec);
      var quantity = diff * flowRate();
      // print('quantity : ${quantity}');
      if(quantity != 0){
        if((value != '' ? int.parse(value) : 0) <= quantity.toInt()){
          sequenceData[selectedGroup]['quantityValue'] = '${quantity.toInt()}';
          waterQuantity.text = '${quantity.toInt() + 1}';
          refreshTime();
          return {'message' : 'water value limit up to ${waterQuantity.text} because of (pre + post + channels)value in liters'};
        }else{
          sequenceData[selectedGroup]['quantityValue'] = (value == '' ? '0' : value);
        }
      }else{
        sequenceData[selectedGroup]['quantityValue'] = (value == '' ? '0' : value);
      }
      refreshTime();
    }
    notifyListeners();
  }

  int parseTimeString(String timeString) {
    print("timeString : $timeString");
    List<String> parts = timeString.split(':');
    int totalSeconds = ((int.parse(parts[0]) * 3600) + (int.parse(parts[1]) * 60) + (int.parse(parts[2])));
    return totalSeconds;
  }

  String formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;

    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return '$hoursStr:$minutesStr:$secondsStr';
  }

  void refreshTime(){
    if(sequenceData[selectedGroup]['method'] == 'Quantity'){
      // print('stoped it1');
      // print('flow : ${getNominalFlow()}');
      var hour = (sequenceData[selectedGroup]['quantityValue'] == '' ? 0 : int.parse(sequenceData[selectedGroup]['quantityValue']))/getNominalFlow();
      // print('hour : $hour');
      waterValueInTime = DataConvert().convertHoursToTime((sequenceData[selectedGroup]['quantityValue'] == '' ? 0 : int.parse(sequenceData[selectedGroup]['quantityValue']))/getNominalFlow());
      // print('stoped it1.1');
      waterValueInQuantity = sequenceData[selectedGroup]['quantityValue'];
    }else{
      // print('stoped it2');
      waterValueInQuantity = DataConvert().convertTimeToLiters(sequenceData[selectedGroup]['timeValue'],getNominalFlow()).toString();
      waterValueInTime = sequenceData[selectedGroup]['timeValue'];
    }
    // print('waterValueInTime : $waterValueInTime, waterValueInQuantity : $waterValueInQuantity');
    notifyListeners();
  }

  //TODO : edit ec ph in central and local
  dynamic editGroupSiteInjector(String title,dynamic value){
    switch(title){
      case ('applyFertilizer'):{
        sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'applyFertilizerForCentral' : 'applyFertilizerForLocal'] = value;
        if(value == false){
          if(sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['needEcValue'] != null){
            sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['needEcValue'] = false;
          }
          // print('ecValue');
          if(sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['ecValue'] != null){
            sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['ecValue'] = 0;
          }
          // print('needPhValue');

          if(sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['needPhValue'] != null){
            sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['needPhValue'] = false;
          }
          // print('phValue');

          if(sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['phValue'] != null){
            sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['phValue'] = 0;
          }
          // print('fertilizer');
          for(var fert = 0;fert < sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['fertilizer'].length;fert++){
            sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['fertilizer'][fert]['method'] = 'Time';
            sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['fertilizer'][fert]['timeValue'] = '00:00:00';
            sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['fertilizer'][fert]['quantityValue'] = '0';
            getInjectorController(fert).text = '0';
          }
        }
        break;
      }
      case ('selectedGroup'):{
        // print('waterValueInTime : $waterValueInTime, waterValueInQuantity : $waterValueInQuantity');
        selectedGroup = value;
        currentIndex = value;
        waterQuantity.text = sequenceData[selectedGroup]['quantityValue'] ?? '';
        preValue.text = sequenceData[selectedGroup]['preValue'];
        postValue.text = sequenceData[selectedGroup]['postValue'];
        refreshTime();
        break;
      }
      case ('selectedCentralSite'):{
        selectedCentralSite = value;
        if(sequenceData[selectedGroup]['centralDosing'].length != 0){
          sequenceData[selectedGroup]['selectedCentralSite'] = sequenceData[selectedGroup]['selectedCentralSite'] = value;
          ec.text = sequenceData[selectedGroup]['centralDosing'][selectedCentralSite]['ecValue'].toString() ?? '';
          ph.text = sequenceData[selectedGroup]['centralDosing'][selectedCentralSite]['phValue'].toString() ?? '';
          selectedInjector = 0;
          for(var index = 0;index < sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['fertilizer'].length;index++){
            getInjectorController(index).text = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['fertilizer'][index]['quantityValue'].toString() ?? '';
          }
        }
        // // print('--------------${jsonEncode(sequenceData[selectedGroup])}');
        break;
      }
      case ('selectedLocalSite'):{
        selectedLocalSite = value;
        if( sequenceData[selectedGroup]['localDosing'].length != 0){
          sequenceData[selectedGroup]['selectedLocalSite'] = sequenceData[selectedGroup]['selectedLocalSite'] =value;
          ec.text = sequenceData[selectedGroup]['localDosing'][selectedLocalSite]['ecValue'].toString() ?? '';
          ph.text = sequenceData[selectedGroup]['localDosing'][selectedLocalSite]['phValue'].toString() ?? '';
          selectedInjector = 0;
          for(var index = 0;index < sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['fertilizer'].length;index++){
            getInjectorController(index).text = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['fertilizer'][index]['quantityValue'].toString() ?? '';
          }
        }
        break;
      }
      case ('selectedInjector'):{
        selectedInjector = value;
        var dosingList = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'];
        int siteIndex = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite'];
        if (siteIndex < 0 || siteIndex >= dosingList.length) siteIndex = 0;
        if (dosingList.isNotEmpty && siteIndex < dosingList.length) {
          for(var index = 0;index < dosingList[siteIndex]['fertilizer'].length;index++){
            getInjectorController(index).text = dosingList[siteIndex]['fertilizer'][index]['quantityValue'].toString() ?? '';
          }
        }
        break;
      }
      case ('selectedRecipe') : {
        try{
          var dosingList = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'];
          int siteIndex = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite'];
          if (siteIndex < 0 || siteIndex >= dosingList.length) siteIndex = 0;
          if (dosingList.isNotEmpty && siteIndex < dosingList.length) {
            dosingList[siteIndex]['recipe'] = value;
          }
          if(value != -1){
            int selectedIndex = value;
            var apply = true;
            for(var channelIndex = 0; channelIndex < recipe[selectedIndex]['channel'].length; channelIndex++){
              var channel = recipe[selectedIndex]['channel'][channelIndex];
              if(channel['method'].contains('ime')){
                int water = parseTimeString(formatTime(waterValueInSec()));
                int pre = parseTimeString(formatTime(preValueInSec()));
                int post = parseTimeString(formatTime(postValueInSec()));
                int fertilizer = parseTimeString(channel['timeValue']);
                var result = water - (pre + post);
                if(fertilizer < result || fertilizer == result){

                }else{
                  apply = false;
                  return {'message' : '${recipe[selectedIndex]['recipeName']} setting is not match with your current setting'};
                }
              }else{
                var diff = waterValueInSec() - preValueInSec() - postValueInSec();
                selectedInjector = channelIndex;
                var flowRate = getFlowRate(channelIndex);
                if(flowRate > 0 && ((channel['quantityValue'] != '' ? int.parse(channel['quantityValue']) : 0)/flowRate > diff)){
                  apply = false;
                  return {'message' : '${recipe[selectedIndex]['recipeName']} setting is not match with your current setting'};
                }
              }
            }
            if(apply == true && dosingList.isNotEmpty && siteIndex < dosingList.length){
              if(recipe[selectedIndex]['ecActive'] != null && recipe[selectedIndex]['ecValue'] != null){
                debugPrint("sequenceData => $sequenceData");
                dosingList[siteIndex]['needEcValue'] = true;
                dosingList[siteIndex]['ecValue'] = recipe[selectedIndex]['ecValue'];
                ec.text = recipe[selectedIndex]['ecValue'];
              }
              if(recipe[selectedIndex]['phActive'] != null && recipe[selectedIndex]['phValue'] != null){
                dosingList[siteIndex]['needPhValue'] = true;
                dosingList[siteIndex]['phValue'] = recipe[selectedIndex]['phValue'];
                ph.text = recipe[selectedIndex]['phValue'];
              }
              for(var channel = 0; channel < recipe[selectedIndex]['channel'].length; channel++){
                if (channel < dosingList[siteIndex]['fertilizer'].length) {
                  dosingList[siteIndex]['fertilizer'][channel]['onOff'] = recipe[selectedIndex]['channel'][channel]['active'] == 1;
                  String channelMethod = recipe[selectedIndex]['channel'][channel]['method'];
                  if (channelMethod == 'Pro.qty per 1000L') {
                    channelMethod = 'Pro.quant per 1000L';
                  }
                  dosingList[siteIndex]['fertilizer'][channel]['method'] = channelMethod;
                  dosingList[siteIndex]['fertilizer'][channel]['timeValue'] = recipe[selectedIndex]['channel'][channel]['timeValue'];
                  dosingList[siteIndex]['fertilizer'][channel]['quantityValue'] = recipe[selectedIndex]['channel'][channel]['quantityValue'];
                  getInjectorController(channel).text = dosingList[siteIndex]['fertilizer'][channel]['quantityValue'].toString() ?? '';
                }
              }
            }
          }
        }catch(e, stackTrace){
          print('e : $e');
          print('stackTrace : $stackTrace');
        }
      }
      break;
      case ('applyRecipe') : {
        // // print('value : $value');
        if(value == false){
          for(var i in sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing']){
            i['recipe'] = -1;
          }
        }
        sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite']]['applyRecipe'] = value;
      }
      break;
      case ('applyMoisture') : {
        if (value is bool) {
          sequenceData[selectedGroup]['applyMoisture'] = value;
        } else if (value is Map) {
          sequenceData[selectedGroup]['moistureCondition'] = value['name'];
          sequenceData[selectedGroup]['moistureSno'] = value['sNo'];
        }
        break;
      }
      case ('applyLevel') : {
        sequenceData[selectedGroup]['levelCondition'] = value['name'];
        sequenceData[selectedGroup]['levelSno'] = value['sNo'];
      }
    }
    updateEcPhAlarmsFromSequences();
    notifyListeners();
  }

  void editNext(){
    if(segmentedControlGroupValue == 1){
      if(sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['fertilizer'].length - 1 != selectedInjector){
        editGroupSiteInjector('selectedInjector',selectedInjector + 1);
      }
      // else if(sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'].length - 1 != (0)){
      //   editGroupSiteInjector(segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite',(0) + 1);
      // }
      else if(sequenceData.length - 1 != selectedGroup){
        editGroupSiteInjector('selectedGroup',selectedGroup + 1);
        // editGroupSiteInjector(segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite',0);
        editGroupSiteInjector('selectedInjector', 0);
      }
    }else{
      if(sequenceData.length - 1 != selectedGroup){
        editGroupSiteInjector('selectedGroup',selectedGroup + 1);
      }
    }

    notifyListeners();
  }

  void editBack(){
    if(segmentedControlGroupValue == 1){
      if(selectedInjector != 0){
        editGroupSiteInjector('selectedInjector',selectedInjector - 1);
      }
      // else if((0) != 0){
      //   editGroupSiteInjector(segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite',(0) - 1);
      // }
      else if(selectedGroup != 0){
        editGroupSiteInjector('selectedGroup',selectedGroup - 1);
        editGroupSiteInjector(segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite',sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'].length -1);
        editGroupSiteInjector('selectedInjector', sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['fertilizer'].length -1);
      }
    }else{
      if(selectedGroup != 0){
        editGroupSiteInjector('selectedGroup',selectedGroup - 1);
      }
    }
    notifyListeners();
  }

  bool isAnySequenceEcOn() {
    if (sequenceData.isEmpty) return false;
    for (var seq in sequenceData) {
      if (seq is Map) {
        final applyCentral = seq['applyFertilizerForCentral'] ?? true;
        if (applyCentral == true) {
          final centralList = seq['centralDosing'] as List? ?? [];
          for (var cd in centralList) {
            if (cd is Map && cd['needEcValue'] == true) {
              return true;
            }
          }
        }
        final applyLocal = seq['applyFertilizerForLocal'] ?? true;
        if (applyLocal == true) {
          final localList = seq['localDosing'] as List? ?? [];
          for (var ld in localList) {
            if (ld is Map && ld['needEcValue'] == true) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  bool isAnySequencePhOn() {
    if (sequenceData.isEmpty) return false;
    for (var seq in sequenceData) {
      if (seq is Map) {
        final applyCentral = seq['applyFertilizerForCentral'] ?? true;
        if (applyCentral == true) {
          final centralList = seq['centralDosing'] as List? ?? [];
          for (var cd in centralList) {
            if (cd is Map && cd['needPhValue'] == true) {
              return true;
            }
          }
        }
        final applyLocal = seq['applyFertilizerForLocal'] ?? true;
        if (applyLocal == true) {
          final localList = seq['localDosing'] as List? ?? [];
          for (var ld in localList) {
            if (ld is Map && ld['needPhValue'] == true) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  void updateEcPhAlarmsFromSequences() {
    if (_newAlarmList == null || _newAlarmList!.alarmList.isEmpty) return;

    final ecActive = isAnySequenceEcOn();
    final phActive = isAnySequencePhOn();

    for (var alarm in _newAlarmList!.alarmList) {
      if (alarm.sNo == 4) {
        alarm.value = ecActive;
      }

      if (alarm.sNo == 5 || alarm.sNo == 6) {
        alarm.value = phActive;
      }
    }
  }

  void editEcPhNeedOrNot(String title){
    if(title == 'ec'){
      if(sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['needEcValue'] == true){
        sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['needEcValue'] = false;
      }else{
        sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['needEcValue'] = true;
      }
    }else if(title == 'ph'){
      if(sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['needPhValue'] == true){
        sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['needPhValue'] = false;
      }else{
        sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['needPhValue'] = true;
      }
    }
    updateEcPhAlarmsFromSequences();
    notifyListeners();
  }

  void editEcPh(String title,String ecOrPh, String value){
    if(title == 'centralDosing'){
      sequenceData[selectedGroup]['centralDosing'][selectedCentralSite][ecOrPh] = value;
    }else if(title == 'localDosing'){
      // // print(value);
      sequenceData[selectedGroup]['localDosing'][selectedLocalSite][ecOrPh] = value;
    }
    updateEcPhAlarmsFromSequences();
    notifyListeners();
  }

  int waterValueInSec(){
    int sec = 0;
    if(sequenceData[selectedGroup]['method'] == 'Time'){
      var splitTime = sequenceData[selectedGroup]['timeValue'].split(':');
      sec = (int.parse(splitTime[0]) * 3600 + int.parse(splitTime[1]) * 60 + int.parse(splitTime[2]));
    }else{
      var nominalFlowRate = [];
      var sno = [];
      for(var valInSeq in sequenceData[selectedGroup]['valve']){
        for(var valveInConstant in constantSetting['valve']){
          if(!sno.contains(valveInConstant['sNo']) && valveInConstant['sNo'] == valInSeq['sNo']){
            sno.add(valveInConstant['sNo']);
            nominalFlowRate.add(valveInConstant['setting'][0]['value'].toString());
          }
        }

      }
      var totalFlowRate = 0;
      for(var flwRate in nominalFlowRate){
        totalFlowRate = totalFlowRate + int.parse(flwRate);
      }
      var valveFlowRate = totalFlowRate * 0.00027778;
      if(sequenceData[selectedGroup]['quantityValue'] == '0'){
        sec = 0;
      }else{
        print(sequenceData[selectedGroup]['quantityValue']);
        sec = ((sequenceData[selectedGroup]['quantityValue'] != '' ? int.parse(sequenceData[selectedGroup]['quantityValue']) : 0)/valveFlowRate).round();
      }
    }
    return sec;
  }

  int fertilizerValueInSec({dynamic fertilizerData}){
    int sec = 0;
    if(['Time','Pro.time'].contains(fertilizerData['method'])){
      var splitTime = fertilizerData['timeValue'].split(':');
      sec = (int.parse(splitTime[0]) * 3600 + int.parse(splitTime[1]) * 60 + int.parse(splitTime[2]));
    }else{
      var nominalFlowRate = 0;
      for(var channel in constantSetting['fertilizerChannel']){
        if(channel['sNo'] == fertilizerData['sNo']){
          var channelFlowRate = channel['setting'][0]['value'].toString();
          nominalFlowRate = channelFlowRate == '' ? 0 : int.parse(channelFlowRate);
        }
      }
      var fertilizerFlowRate = nominalFlowRate * 0.00027778;
      if(fertilizerData['quantityValue'] == '0'){
        sec = 0;
      }else{
        sec = ((fertilizerData['quantityValue'] != '' ? double.parse(fertilizerData['quantityValue'] == '' ? '0' : fertilizerData['quantityValue']) : 0)/fertilizerFlowRate).round();
      }
    }
    return sec;
  }

  int preValueInSec(){
    int sec = 0;
    if(sequenceData[selectedGroup]['prePostMethod'] == 'Time'){
      var splitTime = sequenceData[selectedGroup]['preValue'].split(':');
      sec = int.parse(splitTime[0]) * 3600 + int.parse(splitTime[1]) * 60 + int.parse(splitTime[2]);
    }else{
      var nominalFlowRate = [];
      var sno = [];
      for(var valInSeq in sequenceData[selectedGroup]['valve']){
        for(var valveInConstant in constantSetting['valve']){
          if(!sno.contains(valveInConstant['sNo']) && valveInConstant['sNo'] == valInSeq['sNo']){
            sno.add(valveInConstant['sNo']);
            nominalFlowRate.add(valveInConstant['setting'][0]['value'].toString());
          }
        }
      }
      var totalFlowRate = 0;
      for(var flwRate in nominalFlowRate){
        totalFlowRate = totalFlowRate + int.parse(flwRate);
      }
      // // print('nominalFlowRate : $nominalFlowRate');
      var valveFlowRate = totalFlowRate * 0.00027778;
      if(sequenceData[selectedGroup]['preValue'] == '0'){
        sec = 0;
      }else{
        sec = ((sequenceData[selectedGroup]['preValue'] != '' ? int.parse(sequenceData[selectedGroup]['preValue']) : 0)/valveFlowRate).toInt();
      }
    }
    // // print('pre in seconds : $sec');
    return sec;
  }

  int postValueInSec(){
    int sec = 0;
    if(sequenceData[selectedGroup]['prePostMethod'] == 'Time'){
      var splitTime = sequenceData[selectedGroup]['postValue'].split(':');
      sec = int.parse(splitTime[0]) * 3600 + int.parse(splitTime[1]) * 60 + int.parse(splitTime[2]);
    }else{
      var nominalFlowRate = [];
      var sno = [];
      for(var valInSeq in sequenceData[selectedGroup]['valve']){
        for(var valveInConstant in constantSetting['valve']){

          if(!sno.contains(valveInConstant['sNo']) && valveInConstant['sNo'] == valInSeq['sNo']){
            sno.add(valveInConstant['sNo']);
            nominalFlowRate.add(valveInConstant['setting'][0]['value'].toString());
          }
        }
      }
      var totalFlowRate = 0;
      for(var flwRate in nominalFlowRate){
        totalFlowRate = totalFlowRate + int.parse(flwRate);
      }
      var valveFlowRate = totalFlowRate * 0.00027778;
      if(sequenceData[selectedGroup]['postValue'] == '0'){
        sec = 0;
      }else{
        sec = ((sequenceData[selectedGroup]['postValue'] != '' ? int.parse(sequenceData[selectedGroup]['postValue']) : 0)/valveFlowRate).toInt();
      }
    }
    return sec;
  }

  double flowRate(){
    var nominalFlowRate = [];
    var sno = [];
    for(var valInSeq in sequenceData[selectedGroup]['valve']){
      for(var valveInConstant in constantSetting['valve']){
        if(!sno.contains(valveInConstant['sNo']) && valveInConstant['sNo'] == valInSeq['sNo']){
          sno.add(valveInConstant['sNo']);
          nominalFlowRate.add(valveInConstant['setting'][0]['value'].toString());
        }
      }

    }
    var totalFlowRate = 0;
    // // print('nominalFlowRate : ${nominalFlowRate}');
    for(var flwRate in nominalFlowRate){
      totalFlowRate = totalFlowRate + int.parse(flwRate);
    }
    // print('totalFlowRate : ${totalFlowRate}');
    var valveFlowRate = totalFlowRate * 0.00027778;
    return valveFlowRate;
  }

  int getNominalFlow(){
    var nominalFlowRate = [];
    var sno = [];
    for(var valInSeq in sequenceData[selectedGroup]['valve']){
      for(var valveInConstant in constantSetting['valve']){
        if(!sno.contains(valveInConstant['sNo']) && valveInConstant['sNo'] == valInSeq['sNo']){
          sno.add(valveInConstant['sNo']);
          nominalFlowRate.add(valveInConstant['setting'][0]['value'].toString());
        }
      }
    }
    var totalFlowRate = 0;
    // // print('nominalFlowRate : ${nominalFlowRate}');
    for(var flwRate in nominalFlowRate){
      totalFlowRate = totalFlowRate + int.parse(flwRate);
    }
    // print('totalFlowRate : ${totalFlowRate}');
    return totalFlowRate;
  }

  double fertilizerFlowRate(){
    var nominalFlowRate = [];
    for(var channel in sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'][0]['fertilizer']){
      for(var channelInConstant in constantSetting['fertilizerChannel']){
        if(channelInConstant['sNo'] == channel['sNo']){
          var channelFlowRate = channelInConstant['setting'][0]['value'].toString();
          nominalFlowRate.add(channelFlowRate == '' ? 0 : int.parse(channelFlowRate));
        }
      }
    }
    var totalFlowRate = 0;
    for(var flwRate in nominalFlowRate){
      totalFlowRate = (totalFlowRate + flwRate).toInt();
    }
    var fertilizerFlowRate = totalFlowRate * 0.00027778;
    return fertilizerFlowRate;
  }

  int getMaxFertilizerValueForSelectedSequence(){
    int maxFertInSec = 0;
    if(sequenceData[selectedGroup]['centralDosing'].isNotEmpty){
      for(var i = 0;i < sequenceData[selectedGroup]['centralDosing'][0]['fertilizer'].length;i++){
        int fertInSec = fertilizerValueInSec(fertilizerData: sequenceData[selectedGroup]['centralDosing'][0]['fertilizer'][i]);
        if(fertInSec > maxFertInSec){
          maxFertInSec = fertInSec;
        }
      }
    }
    if(sequenceData[selectedGroup]['localDosing'].isNotEmpty){
      for(var i = 0;i < sequenceData[selectedGroup]['localDosing'][0]['fertilizer'].length;i++){
        int fertInSec = fertilizerValueInSec(fertilizerData: sequenceData[selectedGroup]['localDosing'][0]['fertilizer'][i]);
        if(fertInSec > maxFertInSec){
          maxFertInSec = fertInSec;
        }
      }
    }
    return maxFertInSec;
  }

  //TODO : edit pre post in fert segment
  dynamic editPrePostMethod(String title,int index,String value){
    switch (title){
      case 'prePostMethod' :{
        if(sequenceData[index]['prePostMethod'] != value){
          if(value == 'Time'){
            sequenceData[index]['preValue'] = '00:00:00';
            sequenceData[index]['postValue'] = '00:00:00';
          }else{
            sequenceData[index]['preValue'] = '0';
            sequenceData[index]['postValue'] = '0';
            preValue.text = '0';
            postValue.text = '0';
          }
          sequenceData[index]['prePostMethod'] = value;
        }
        break;
      }
      case 'preValue' :{
        if(sequenceData[index]['prePostMethod'] != 'Time'){
          var maxFertInSec = getMaxFertilizerValueForSelectedSequence();
          // print('preValue maxFertInSec :${maxFertInSec}');
          var diff = waterValueInSec() - (postValueInSec() + maxFertInSec);
          var quantity = diff * flowRate();
          // print('quantity : ${quantity}');
          if(int.parse(value) >= quantity.toInt()){
            sequenceData[index]['preValue'] = '${quantity.toInt()}';
            preValue.text = '${quantity.toInt()}';
            return {'message' : 'pre value limit up to ${preValue.text} because of (water - pre + post + channels)value in liters'};
          }else{
            sequenceData[index]['preValue'] = (value == '' ? '0' : value);
          }
        }else{
          sequenceData[index]['preValue'] = value;
        }
        break;
      }
      case 'postValue' :{
        if(sequenceData[index]['prePostMethod'] != 'Time'){
          var maxFertInSec = getMaxFertilizerValueForSelectedSequence();
          var diff = waterValueInSec() - (preValueInSec() + maxFertInSec);
          var quantity = diff * flowRate();
          // // print('post diff : ${quantity}');
          if(int.parse(value) >= quantity.toInt()){
            sequenceData[index]['postValue'] = '${quantity.toInt()}';
            postValue.text = '${quantity.toInt()}';
            return {'message' : 'post value limit up to ${postValue.text} because of (water - pre + post)value in liters'};
          }else{
            sequenceData[index]['postValue'] = (value == '' ? '0' : value);
          }
        }else{
          sequenceData[index]['postValue'] = value;
        }
        break;
      }

    }
    notifyListeners();
  }

  // void editSelectedSite(String centralOrLocal,dynamic value){
  //   if(centralOrLocal == 'centralDosing'){
  //     sequenceData[selectedGroup]['selectedCentralSite'] = sequenceData[selectedGroup]['selectedCentralSite'] == value ? -1 : value;
  //   }else{
  //     sequenceData[selectedGroup]['selectedLocalSite'] = sequenceData[selectedGroup]['selectedLocalSite'] == value ? -1 : value;
  //   }
  //   notifyListeners();
  // }

  void editOnOffInInjector(String centralOrLocal,int index,bool value){
    // // print('sequenceData check1 : ${jsonEncode(sequenceData)}');
    sequenceData[selectedGroup][centralOrLocal][centralOrLocal == 'centralDosing' ? selectedCentralSite : selectedLocalSite]['fertilizer'][index]['onOff'] = value;
    // // print('sequenceData check2 : ${jsonEncode(sequenceData)}');
    notifyListeners();
  }

  double getFlowRate(int index){
    var nominalFlowRate = 0;
    try{
      var dosingList = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'centralDosing' : 'localDosing'];
      int siteIndex = sequenceData[selectedGroup][segmentedControlCentralLocal == 0 ? 'selectedCentralSite' : 'selectedLocalSite'];
      if (siteIndex < 0 || siteIndex >= dosingList.length) siteIndex = 0;
      if (dosingList.isNotEmpty && siteIndex < dosingList.length) {
        var fertList = dosingList[siteIndex]['fertilizer'];
        if (index >= 0 && index < fertList.length) {
          var targetFert = fertList[index];
          for(var channelInConstant in constantSetting['fertilizerChannel']){
            if(channelInConstant['sNo'] == targetFert['sNo']){
              print("channelInConstant => $channelInConstant");
              var channelFlowRate = channelInConstant['setting'][0]['value'].toString();
              nominalFlowRate = channelFlowRate == '' ? 0 : int.parse(channelFlowRate);
            }
          }
        }
      }
    }catch(e){
      print("getFlowRate error => $e");
    }
    print("nominalFlowRate => $nominalFlowRate");
    return nominalFlowRate * 0.0002778;
  }

  dynamic editParticularChannelDetails(String title,String centralOrLocal,dynamic value,int index){
    switch(title){
      case ('outletTankValve') : {
        double? outletTankValveSno;
        if (value != null) {
          outletTankValveSno = (value is num) ? value.toDouble() : double.tryParse(value.toString());
        }
        sequenceData[selectedGroup][centralOrLocal][centralOrLocal == 'centralDosing' ? selectedCentralSite : selectedLocalSite]['fertilizer'][index]['outletTankValve'] = outletTankValveSno;
        break;
      }
      case ('method') : {
        sequenceData[selectedGroup][centralOrLocal][centralOrLocal == 'centralDosing' ? selectedCentralSite : selectedLocalSite]['fertilizer'][index ?? selectedInjector]['method'] = value;
        break;
      }
      case ('quantityValue') : {
        var editingSelectedFertilizer = sequenceData[selectedGroup][centralOrLocal][centralOrLocal == 'centralDosing' ? selectedCentralSite : selectedLocalSite]['fertilizer'][index];
        var diff = waterValueInSec() - preValueInSec() - postValueInSec();
        var waterFlowRate = getNominalFlow();
        var literForOneSeconds = waterFlowRate/3600;
        var fertilizerGapInLiters = literForOneSeconds * diff;
        var userInput = value != '' ? double.parse(value) : 0;
        var howMany1000In_fertilizerGapInLiters = fertilizerGapInLiters/1000;
        var injectorPer1000L = howMany1000In_fertilizerGapInLiters * userInput;
        var flowRate = getFlowRate(index);
        var maxFertilizerLimitInLiters = diff * flowRate;
        print('howMany1000In_fertilizerGapInLiters => $howMany1000In_fertilizerGapInLiters  fertilizerGapInLiters => $fertilizerGapInLiters injectorPer1000L => $injectorPer1000L  maxFertilizerLimitInLiters => $maxFertilizerLimitInLiters');
        if(editingSelectedFertilizer['method'] == 'Pro.quant per 1000L'){
          if(injectorPer1000L > maxFertilizerLimitInLiters){
            editingSelectedFertilizer['quantityValue'] = ((maxFertilizerLimitInLiters /
                howMany1000In_fertilizerGapInLiters) - 0.1)
                .toStringAsFixed(1); // 0.2 for ensure always fertilizer is less than water
            getInjectorController(index).text = editingSelectedFertilizer['quantityValue'].toString();
            return {'message' : 'fertilizer value limit up to ${getInjectorController(index).text}'};
          }else{
            editingSelectedFertilizer['quantityValue'] = (value == '' ? '0' : value);
          }
        }else{
          if(userInput/flowRate > diff){
            editingSelectedFertilizer['quantityValue'] = '${(diff * flowRate).toInt()}';
            getInjectorController(index).text = editingSelectedFertilizer['quantityValue'].toString() ?? '';
            return {'message' : 'fertilizer value limit up to ${getInjectorController(index).text} because of (water - pre + post + current channels)value in liters'};
          }else{
            editingSelectedFertilizer['quantityValue'] = (value == '' ? '0' : value);
          }
        }
        break;
      }
      case ('timeValue') : {
        sequenceData[selectedGroup][centralOrLocal][centralOrLocal == 'centralDosing' ? selectedCentralSite : selectedLocalSite]['fertilizer'][index]['timeValue'] = value;
        break;
      }
    }
    notifyListeners();
  }

  String giveNameForSequence(dynamic data){
    var name = '';
    for(var i in data['selected']){
      name += '${name.length != 0 ? '&' : ''}$i';
    }
    return name;
  }


  String getName(dynamic sNo){
    var name = '';
    for(var n in configObjects){
      if(n['sNo'].toString() == sNo.toString()){
        name = n['name'];
      }
    }
    return name.isEmpty ? 'Location N/A' : name;
  }
  void dataToWF() {
    serverDataWM = sequenceData;
    notifyListeners();
  }

  //TODO: SELECTION PROVIDER
  AdditionalData? _additionalData;
  AdditionalData? get additionalData => _additionalData;
  List<String> filtrationModes = ['TIME', 'DP', 'BOTH'];
  String get selectedCentralFiltrationMode => _additionalData?.centralFiltrationOperationMode ?? "TIME";
  String get selectedLocalFiltrationMode => _additionalData?.localFiltrationOperationMode ?? "TIME";

  List valveFlowRate = [];
  int totalValveFlowRate = 0;
  int pumpStationValveFlowRate = 0;
  List pumpStationFlowRate = [];
  bool pumpStationCanEnable = false;

  void updateFiltrationMode(newValue, bool isCentral) {
    if(isCentral) {
      _additionalData?.centralFiltrationOperationMode = newValue;
    } else {
      _additionalData?.localFiltrationOperationMode = newValue;
    }
    notifyListeners();
  }

  bool get isPumpStationMode => _additionalData?.pumpStationMode ?? false;
  bool get isChangeOverMode => _additionalData?.changeOverMode ?? false;
  bool get isProgramBasedSet => _additionalData?.programBasedSet ?? false;
  bool get isProgramBasedInjector => _additionalData?.programBasedInjector ?? false;

  void updatePumpStationMode(newValue, title) {
    switch(title) {
      case 0: _additionalData?.pumpStationMode = newValue;
      break;
      case 1: _additionalData?.changeOverMode = newValue;
      break;
      case "Program based set selection": _additionalData?.programBasedSet = newValue;
      break;
      case "Program based Injector selection": _additionalData?.programBasedInjector = newValue;
      break;
      default:
        log('No match found');
    }
    notifyListeners();
  }

  bool get centralFiltBegin => _additionalData?.centralFiltrationBeginningOnly ?? false;
  bool get localFiltBegin => _additionalData?.localFiltrationBeginningOnly ?? false;

  void updateFiltBegin(newValue, isCentral) {
    if(isCentral) {
      _additionalData?.centralFiltrationBeginningOnly = newValue;
    } else {
      _additionalData?.localFiltrationBeginningOnly = newValue;
    }
    notifyListeners();
  }

  Map<String, dynamic> calculateTotalFlowRate() {
    int pumpStationValveFlowRate = 0;
    List pumpStationFlowRate = [];
    double selectedHeadUnits = selectedObjects!.isNotEmpty ? selectedObjects?.firstWhere((e) => e.objectId == 2).sNo ?? 0.0 : 0.0;
    List<double> availableIrrigationPumps = [];
    List<Map<String, dynamic>> sequenceData = [];
    if(constantSetting['pump'] != null) {
      for (var line = 0; line < irrigationLineFromConfigMaker.length; line++) {
        if(irrigationLineFromConfigMaker[line]['sNo'] == selectedHeadUnits) {
          availableIrrigationPumps = List.from(irrigationLineFromConfigMaker[line]['irrigationPump']);
        }
      }
      for (int index = 0; index < constantSetting['pump'].length; index++) {
        if(availableIrrigationPumps.contains(constantSetting['pump'][index]['sNo'])) {
          if(constantSetting['pump'][index]['setting'][0]['value']){
            pumpStationFlowRate.add(constantSetting['pump'][index]['setting'][1]['value']);
          }
        }
      }
    }
    if (pumpStationFlowRate.isNotEmpty) {
      pumpStationValveFlowRate = pumpStationFlowRate.map((flowRate) => int.parse(flowRate)).reduce((a, b) => a + b);
    }

    for (var index = 0; index < irrigationLine!.sequence.length; index++) {
      var sequenceValveFlowRate = [];
      int cumulativeSequenceFlowRate = 0;
      for (var val in irrigationLine!.sequence[index]['valve']) {
        if(constantSetting['valve'] != null) {
          for(var valveInConstant in constantSetting['valve']){
            if(val['sNo'] == valveInConstant['sNo']){
              var valveFlowRateInConstant = valveInConstant['setting'][0]['value'].toString();
              if(valveFlowRateInConstant.isNotEmpty){
                sequenceValveFlowRate.add(valveFlowRateInConstant);
              }
            }
          }
        }
      }
      if(sequenceValveFlowRate.isNotEmpty) {
        cumulativeSequenceFlowRate = sequenceValveFlowRate.map((flowRate) => int.parse(flowRate)).reduce((a, b) => a + b);
        if(cumulativeSequenceFlowRate > pumpStationValveFlowRate){
          sequenceData.add({
            'name': irrigationLine!.sequence[index]['name'],
            'flowrate': cumulativeSequenceFlowRate
          });
        }
      }
    }
    return {
      "pumpFlowRate": pumpStationValveFlowRate,
      "sequenceData": sequenceData,
    };
  }

  Future<void> getUserProgramSelection(int userId, int controllerId, int serialNumber) async {
    var userData = {
      "userId": userId,
      "controllerId": controllerId,
      "serialNumber": serialNumber
    };

    try {
      final response = await repository.getUserProgramSelection(userData);
      final jsonData = json.decode(response.body);
      _additionalData = null;
      _selectedObjects = [];
      // _selectedControllers = [];
      // if(jsonData['data']['selection']['nodeSelection'] != null){
      //   _selectedControllers = jsonData['data']['selection']['nodeSelection'];
      // }
      if (jsonData['data']['selection']['selected'] != null) {
        _selectedObjects = (jsonData['data']['selection']['selected'] as List)
            .map((e) => DeviceObjectModel.fromJson(e as Map<String, dynamic>))
            .toList();

        if (configObjects.isNotEmpty) {
          _selectedObjects!.removeWhere((element) => !configObjects.any((element2) {
            double configSNo = double.tryParse(element2['sNo'].toString()) ?? 0.0;
            if(element.objectId == 5) {
              final irrigationPumpSnoList = sampleIrrigationLine!.map((e) => e.irrigationPump ?? []).expand((list) => list).toList().map((ele) => ele.sNo).toList();
              irrigationPumpSnoList.contains(element.sNo);
              // sampleIrrigationLine!.map((e) => e.irrigationPump
            }
            return element.objectId == 5
                ? sampleIrrigationLine!.map((e) => e.irrigationPump ?? []).expand((list) => list).toList().map((ele) => ele.sNo).toList().contains(element.sNo)
                : configSNo == element.sNo;
          }));
        } else {
          print("Warning: configObjects is empty, skipping filter");
        }
      } else {
        _selectedObjects = [];
      }
      _additionalData = AdditionalData.fromJson(jsonData['data']['selection']);
    } catch (e) {
      log('Error: $e');
      rethrow;
    }
    Future.delayed(Duration.zero, () {
      notifyListeners();
    });
  }

  //TODO: ALARM SCREEN PROVIDER
  NewAlarmList? _newAlarmList;
  NewAlarmList? get newAlarmList => _newAlarmList;

  Future<void> getUserProgramAlarm(userId, controllerId, int serialNumber) async {
    try {
      var userData = {
        "userId": userId,
        "controllerId": controllerId,
        "serialNumber": serialNumber
      };
      var getUserProgramAlarm = await repository.getUserProgramAlarm(userData);

      _newAlarmList = null;
      if(getUserProgramAlarm.statusCode == 200) {
        final responseJson = getUserProgramAlarm.body;
        final convertedJson = jsonDecode(responseJson);
        _newAlarmList = NewAlarmList.fromJson(convertedJson);
        updateEcPhAlarmsFromSequences();
      } else {
        log("HTTP Request failed or received an unexpected response.");
        throw Exception("Failed to load alarm data");
      }
    } catch (e) {
      log('Error: $e');
      rethrow;
    }
    Future.delayed(Duration.zero, () {
      notifyListeners();
    });
  }

  //TODO: DONE SCREEN PROVIDER
  List<dynamic> programList = [];
  int programCount = 0;
  String programName = '';
  String defaultProgramName = '';
  String priority = '';
  List<String> priorityList = ["High", "Low"];
  bool isCompletionEnabled = false;
  String selectedProgramType = 'Irrigation Program';
  int serialNumberCreation = 0;
  bool irrigationProgramType = false;

  List<int> serialNumberList = [];
  ProgramDetails? _programDetails;
  ProgramDetails? get programDetails => _programDetails;
  String get delayBetweenZones => _programDetails!.delayBetweenZones;
  String get adjustPercentage => _programDetails!.adjustPercentage;
  String get cyclicOnTime => _programDetails!.cyclicOnTime;
  String get cyclicOffTime => _programDetails!.cyclicOffTime;
  bool get enablePressure => _programDetails!.enablePressure;
  String get pressureValue => _programDetails!.pressureValue;
  String get controlMode => _programDetails!.controlMode;
  String get setPressure => _programDetails!.setPressure;
  String get pressureTolerance => _programDetails!.pressureTolerance;
  String get setFlow => _programDetails!.setFlow;
  String get flowTolerance => _programDetails!.flowTolerance;
  String get flowScanTime => _programDetails!.flowScanTime;

  Future<void> doneData(int userId, int controllerId, int serialNumber) async {
    try {
      var userData = {
        "userId": userId,
        "controllerId": controllerId,
        "serialNumber": serialNumber
      };

      var getUserProgramName = await repository.getUserProgramDetails(userData);
      // var getUserProgramName = await httpService.postRequest('getUserProgramDetails', userData);
      _programDetails = null;
      if (getUserProgramName.statusCode == 200) {
        final responseJson = getUserProgramName.body;
        final convertedJson = jsonDecode(responseJson);
        _programDetails = ProgramDetails.fromJson(convertedJson);
        if(_programLibrary != null) {
          programCount = _programLibrary!.program.isEmpty ? 1 : _programLibrary!.program.length + 1;
          serialNumberCreation = _programLibrary!.program.length + 1;
        }
        priority = _programDetails!.priority != "" ? _programDetails!.priority : "Low";
        // if(_programDetails != null) {
        programName = serialNumber == 0
            ? "Program $programCount"
            : _programDetails!.programName.isEmpty
            ? _programDetails!.defaultProgramName
            : _programDetails!.programName;
        // } else {
        //   programName = _programDetails!.defaultProgramName;
        // }
        selectedProgramType = _programDetails!.programType == '' ? selectedProgramType : _programDetails!.programType;
        defaultProgramName = (_programDetails!.defaultProgramName == '' || _programDetails!.defaultProgramName.isEmpty) ?  "Program $programCount" : _programDetails!.defaultProgramName;
        isCompletionEnabled = _programDetails!.completionOption;
        Future.delayed(Duration.zero, () {
          notifyListeners();
        });
      } else {
        log("HTTP Request failed or received an unexpected response.");
        throw Exception("Failed to load program details");
      }
    } catch (e) {
      log('Error: $e');
      rethrow;
    }
  }

  //TODO: PROGRAM LIBRARY
  ProgramLibrary? _programLibrary;
  ProgramLibrary? get programLibrary => _programLibrary;
  final List<String> filterList = ["Active programs", "Inactive programs"];
  int _selectedFilterType = 0;
  int get selectedFilterType => _selectedFilterType;

  void updateSelectedFilterType(int newIndex) {
    _selectedFilterType = newIndex;
    notifyListeners();
  }

  Future<String> programLibraryData(int userId, int controllerId) async {
    try {
      var userData = {
        "userId": userId,
        "controllerId": controllerId,
      };

      print("user data in programLibraryData :: $userData");
      var getUserProgramName = await repository.getProgramLibraryData(userData);
      // var getUserProgramName = await httpService.postRequest('getUserProgramLibrary', userData);
      _programLibrary = null;
      if (getUserProgramName.statusCode == 200) {
        final responseJson = getUserProgramName.body;
        final convertedJson = jsonDecode(responseJson);
        _programLibrary = ProgramLibrary.fromJson(convertedJson);
        print("program library data => ${convertedJson['data']['conditionLibraryCount']}");
        priority = _programDetails?.priority != "" ? _programDetails?.priority ?? "None" : "None";
        conditionsLibraryIsNotEmpty = convertedJson['data']['conditionLibraryCount'] != 0;
        // irrigationProgramType = _programLibrary?.program[serialNumber].programType == "Irrigation Program" ? true : false;
        notifyListeners();
        return convertedJson['message'];
      } else {
        log("HTTP Request failed or received an unexpected response.");
        throw Exception("HTTP Request failed or received an unexpected response.");
      }
      // return getUserProgramName.statusCode;
    } catch (e) {
      log('Error: $e');
      rethrow;
    }
  }

  //TODO: PROGRAM RESET
  Future<String> userProgramReset(int userId, int controllerId, int programId, deviceId, serialNumber, String defaultProgramName, String programName, String active, String controllerReadStatus, int customerId) async {
    try {
      var userData = {
        "userId": customerId,
        "controllerId": controllerId,
        "createUser": userId,
        "programId": programId,
        "defaultProgramName": defaultProgramName,
        "serialNumber": serialNumber,
        "programName": programName,
        "modifyUser": userId,
        "controllerReadStatus": controllerReadStatus,
      };

      var getUserProgramName = active == "inactive"
          ? await repository.inactiveUserProgram(userData)
          : active == "active"
          ? await repository.activeUserProgram(userData)
          : await repository.deleteUserProgram(userData);
      // var getUserProgramName = await httpService.putRequest(active == "inactive" ? "inactiveUserProgram" : active == "active" ? "activeUserProgram" : 'resetUserProgram', userData);
      if (getUserProgramName.statusCode == 200) {
        final responseJson = getUserProgramName.body;
        final convertedJson = jsonDecode(responseJson);
        notifyListeners();
        return convertedJson['message'];
      } else {
        log("HTTP Request failed or received an unexpected response.");
        throw Exception("HTTP Request failed or received an unexpected response.");
      }
    } catch (e) {
      log('Error: $e');
      rethrow;
    }
  }

  void updatePriority(newValue, index) {
    _programLibrary?.program[index].priority = newValue;
    notifyListeners();
  }

  void updateProgramName(dynamic newValue, String type) {
    switch (type) {
      case 'programName':
        programName = newValue != '' ? newValue : programName;
        break;
      case 'priority':
        priority = newValue;
        break;
      case 'completion':
        isCompletionEnabled = newValue as bool;
        break;
      case 'programType':
        selectedProgramType = newValue as String;
        break;
      case "delayBetweenZones":
        _programDetails!.delayBetweenZones = newValue;
        break;
      case "adjustPercentage":
        _programDetails!.adjustPercentage = newValue;
        break;
      case "cyclicOnTime":
        _programDetails!.cyclicOnTime = newValue;
        break;
      case "cyclicOffTime":
        _programDetails!.cyclicOffTime = newValue;
        break;
      case "enablePressure":
        _programDetails!.enablePressure = newValue;
        break;
      case "pressureValue":
        _programDetails!.pressureValue = newValue;
        break;
      case "controlMode":
        _programDetails!.controlMode = newValue;
        break;
      case "setPressure":
        _programDetails!.setPressure = newValue;
        break;
      case "pressureTolerance":
        _programDetails!.pressureTolerance = newValue;
        break;
      case "setFlow":
        _programDetails!.setFlow = newValue;
        break;
      case "flowTolerance":
        _programDetails!.flowTolerance = newValue;
        break;
      case "flowScanTime":
        _programDetails!.flowScanTime = newValue;
        break;
      default:
        log("Not found");
    }
    notifyListeners();
  }

  List<String> commonLabels = [
    'Sequence',
    'Schedule',
    'Conditions',
    'Selection',
    'Water & Fert',
    'Alarm',
    'Additional',
    'Preview'
  ];
  List<IconData> commonIcons = [
    Icons.view_headline_rounded,
    Icons.calendar_month,
    Icons.fact_check,
    Icons.checklist,
    Icons.local_florist_rounded,
    Icons.alarm_rounded,
    Icons.done_rounded,
    Icons.preview,
  ];

  Tuple<List<String>, List<IconData>> getLabelAndIcon({
    required int sno,
    String? programType,
    bool? conditionLibrary,
  }) {
    print("conditionLibrary :: $conditionLibrary");
    List<String> labels = [];
    List<IconData> icons = [];

    final irrigationProgram = sno == 0
        ? selectedProgramType == "Irrigation Program"
        : programType == "Irrigation Program";

    if (irrigationProgram) {
      // --- Irrigation Program ---
      commonLabels = commonLabels
          .map((label) => label == "Settings" ? "Water & Fert" : label)
          .toList();
      commonIcons = commonIcons
          .map((icon) =>
      icon == Icons.settings ? Icons.local_florist_rounded : icon)
          .toList();

      final showConditions = conditionLibrary ?? false;
      labels = showConditions
          ? commonLabels
          : commonLabels.where((e) => e != "Conditions").toList();
      icons = showConditions
          ? commonIcons
          : commonIcons.where((e) => e != Icons.fact_check).toList();
    } else {
      // --- Non-Irrigation Program ---
      commonLabels = commonLabels
          .map((label) => label == "Water & Fert" ? "Settings" : label)
          .toList();
      commonIcons = commonIcons
          .map((icon) =>
      icon == Icons.local_florist_rounded ? Icons.settings : icon)
          .toList();

      final showConditions = conditionLibrary ?? false;

      if (showConditions) {
        labels = commonLabels
            .where((e) => !["Selection", "Preview"].contains(e))
            .toList();
        icons = commonIcons
            .where((e) => ![Icons.checklist, Icons.preview].contains(e))
            .toList();
      } else {
        labels = commonLabels
            .where(
                (e) => !["Conditions", "Selection", "Preview"].contains(e))
            .toList();
        icons = commonIcons
            .where((e) =>
        ![Icons.fact_check, Icons.checklist, Icons.preview]
            .contains(e))
            .toList();
      }
    }

    return Tuple(labels, icons);
  }


  //TODO: UPDATE PROGRAM DETAILS
  Future<String> updateUserProgramDetails(
      int userId, int controllerId, int serialNumber, int programId, String programName, String priority, defaultProgramName, String controllerReadStatus, hardwareData, customerId) async {
    try {
      Map<String, dynamic> userData = {
        "userId": customerId,
        "controllerId": controllerId,
        "serialNumber": serialNumber,
        "createUser": userId,
        "programId": programId,
        "programName": programName,
        "priority": priority,
        "defaultProgramName": defaultProgramName,
        "controllerReadStatus": controllerReadStatus,
        "hardware": hardwareData
      };

      var updateUserProgramDetails = await repository.updateProgramDetails(userData);
      // var updateUserProgramDetails = await httpService.putRequest('updateUserProgramDetails', userData);

      if (updateUserProgramDetails.statusCode == 200) {
        final responseJson = updateUserProgramDetails.body;
        final convertedJson = jsonDecode(responseJson);
        notifyListeners();
        return convertedJson['message'];
      } else {
        throw Exception("HTTP Request failed or received an unexpected response.");
      }
    } catch (e) {
      log('Error: $e');
      rethrow;
    }
  }

  //TODO: CREATE COPY OF PROGRAM
  Future<String> userProgramCopy(int userId, int controllerId, int oldSerialNumber, int serialNumber, String programName, String defaultProgramName, String programType, int customerId) async {
    try {
      var userData = {
        "userId": customerId,
        "controllerId": controllerId,
        "createUser": userId,
        "serialNumber": serialNumber,
        "oldSerialNumber": oldSerialNumber,
        "defaultProgramName": defaultProgramName,
        "programName": programName,
        "programType": programType,
        // "programId": programId
      };

      var getUserProgramName = await repository.createProgramFromCopy(userData);

      if (getUserProgramName.statusCode == 200) {
        final responseJson = getUserProgramName.body;
        final convertedJson = jsonDecode(responseJson);
        notifyListeners();
        return convertedJson['message'];
      } else {
        log("HTTP Request failed or received an unexpected response.");
        throw Exception("HTTP Request failed or received an unexpected response.");
      }
    } catch (e) {
      log('Error: $e');
      rethrow;
    }
  }

  //TODO: Program Payload conversion for hardware
  DateTime get scheduleAsRunListStartDate => DateTime.parse(_sampleScheduleModel!.scheduleAsRunList.schedule['startDate']);
  DateTime get scheduleByDayStartDate => DateTime.parse(_sampleScheduleModel!.scheduleByDays.schedule['startDate']);
  DateTime get scheduleAsRunListEndDate => DateTime.parse(_sampleScheduleModel!.scheduleAsRunList.schedule['endDate']);
  DateTime get scheduleByDayEndDate => DateTime.parse(_sampleScheduleModel!.scheduleByDays.schedule['endDate']);

  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  String get formattedScheduleAsRunListStartDate => formatter.format(scheduleAsRunListStartDate);
  String get formattedScheduleByDayStartDate => formatter.format(scheduleByDayStartDate);
  String get formattedScheduleAsRunListEndDate => formatter.format(scheduleAsRunListEndDate);
  String get formattedScheduleByDayEndDate => formatter.format(scheduleByDayEndDate);

  dynamic getDaySelectionMode() {
    List typeData = _sampleScheduleModel!.scheduleAsRunList.schedule['type'];
    var selectionModeList = [];
    for(var i = 0; i < typeData.length; i++) {
      switch(typeData[i]) {
        case "DO NOTHING":
          selectionModeList.add(0);
          break;
        case "DO WATERING":
          selectionModeList.add(1);
          break;
        case "DO ONE TIME":
          selectionModeList.add(3);
          break;
        case "DO FERTIGATION":
          selectionModeList.add(2);
          break;
      }
    }
    return selectionModeList.isNotEmpty ? selectionModeList.join('_') : "1";
  }

  List<String> generateRtcTimeList(Map<String, dynamic> rtcData, String key) {
    return List.generate(6, (index) {
      final rtcKey = 'rtc${index + 1}';
      String rtcValue;

      switch(key) {
        case "noOfCycles":
          rtcValue = rtcValue = index < rtcData.length ? rtcData[rtcKey]['noOfCycles'].toString() : '0';
          break;
        case "stopMethod":
          rtcValue = rtcValue = index < rtcData.length ? rtcData[rtcKey]['stopMethod'] == stopMethods[2] ? "3" : rtcData[rtcKey]['stopMethod'] == stopMethods[1] ? "2" : "1" : "0";
        default:
          rtcValue = index < rtcData.length
              ? '${rtcData[rtcKey][key]}'.length == 5
              ? '${rtcData[rtcKey][key]}:00'
              : '${rtcData[rtcKey][key]}'
              : "00:00:00";
      // return rtcValue;
      }
      return rtcValue;
    });
  }

  List<String> generateRtcTimeByUser(Map<String, dynamic> rtcData) {
    return List.generate(6, (index) {
      final rtcKey = 'rtc${index + 1}';
      String rtcValue;

      rtcValue = index < rtcData.length
          ? (rtcData[rtcKey]['stopMethod'] == stopMethods[2])
          ? '${rtcData[rtcKey]['maxTime']}'
          : (rtcData[rtcKey]['stopMethod'] == stopMethods[1])
          ? '${rtcData[rtcKey]['offTime']}'
          : '${rtcData[rtcKey]['onTime']}'
          : "00:00:00";
      return rtcValue;
    });
  }

  String generateRtcTimeString(String key) {
    var rtcTimeList = generateRtcTimeList(selectedScheduleType == scheduleTypes[1] ? sampleScheduleModel!.scheduleAsRunList.rtc : sampleScheduleModel!.scheduleByDays.rtc, key);
    return rtcTimeList.join('_');
  }

  String generateRtcTimeStringByUser() {
    var rtcTimeList = generateRtcTimeByUser(selectedScheduleType == scheduleTypes[1] ? sampleScheduleModel!.scheduleAsRunList.rtc : sampleScheduleModel!.scheduleByDays.rtc);
    return rtcTimeList.join('_');
  }

  String get rtcOnTime => generateRtcTimeString('onTime');
  String get rtcStopMethod => generateRtcTimeString('stopMethod');
  String get rtcMaxTime => generateRtcTimeString('maxTime');
  String get rtcOffTime => generateRtcTimeString('offTime');
  String get rtcNoOfCycles => generateRtcTimeString('noOfCycles');
  String get rtcInterval => generateRtcTimeString('interval');

  String generateFertilizerString({dataList, requiredType}) {
    return dataList?.where((element) => element.selected == true).map((element) => "1").toList().join('_') ?? "0";
  }

  String getProgramStopMethod(method) {
    return List.generate(6, (index) => method).join('_');
  }

  List<String?> get conditionList => _sampleConditions?.condition
      .map((e) => e.selected ? e.value['sNo']?.toString() : "0")
      .toList() ?? List.generate(4, (index) => '0');

  dynamic dataToMqtt(serialNumber, programType) {
    final scheduleType = selectedScheduleType;
    final schedule = scheduleType == scheduleTypes[1]
        ? sampleScheduleModel!.scheduleAsRunList.schedule
        : sampleScheduleModel!.scheduleByDays.schedule;

    final centralFertilizerSite = fertilizerSite!.where((site) {
      for (var i = 0; i < selectedObjects!.length; i++) {
        if (site.siteMode == 1 && selectedObjects![i].objectId == 3 && selectedObjects![i].sNo == site.fertilizerSite?.sNo) {
          return true;
        }
      }
      return false;
    });

    final localFertilizerSite = fertilizerSite!.where((site) {
      for (var i = 0; i < selectedObjects!.length; i++) {
        if (site.siteMode == 2 && selectedObjects![i].objectId == 3 && selectedObjects![i].sNo == site.fertilizerSite?.sNo) {
          return true;
        }
      }
      return false;
    });

    final centralFilterSite = filterSite!.where((site) {
      // print("Central filter site ==> ${site.filterSite?.sNo}");
      for (var i = 0; i < selectedObjects!.length; i++) {
        if (site.siteMode == 1 && selectedObjects![i].objectId == 4 && selectedObjects![i].sNo == site.filterSite?.sNo) {
          return true;
        }
      }
      return false;
    });

    final localFilterSite = filterSite!.where((site) {
      for (var i = 0; i < selectedObjects!.length; i++) {
        if (site.siteMode == 2 && selectedObjects![i].objectId == 4 && selectedObjects![i].sNo == site.filterSite?.sNo) {
          return true;
        }
      }
      return false;
    });

    var endDate = DateTime.parse(schedule['endDate']).isBefore(DateTime.parse(startDate(serialNumber: serialNumber)))
        ? DateTime.now().toString() :(schedule['endDate'] ?? DateTime.now().toString());
    final isForceToEndDate = schedule['isForceToEndDate'] ?? false;
    var noOfDays = ((schedule['noOfDays'] == "" || schedule['noOfDays'] == "0") ? "1": schedule['noOfDays']) ?? '1';
    final runDays = ((schedule['runDays'] == "" || schedule['runDays'] == "0") ? "1": schedule['runDays']) ?? '1';
    final runListLimit = sampleScheduleModel?.defaultModel.runListLimit ?? 0;
    final skipDays = schedule['skipDays'] ?? '0';
    final dateRange = (DateTime.parse(endDate).difference(DateTime.parse(startDate(serialNumber: serialNumber)))).inDays;
    final firstDate = DateTime.parse(startDate(serialNumber: serialNumber)).add(Duration(days: (scheduleType == scheduleTypes[1] ? int.parse(noOfDays) : 0)
        + int.parse(runDays != '' ? runDays : "1") + int.parse(skipDays != '' ? skipDays : "0") - (selectedScheduleType == scheduleTypes[1] ? 2 : 1)));
    endDate = dateRange < (scheduleType == scheduleTypes[1] ? int.parse(noOfDays) : 0)
        + int.parse(runDays != '' ? runDays : "1") + int.parse(skipDays != '' ? skipDays : "0")
        ? firstDate
        : DateTime.parse(endDate);
    List totalAgitators = [];
   /* print('head unit pause :: ${sampleIrrigationLine!.where((headUnit) {
      var sampleLineValveList = headUnit.valve!.map((valve) => valve.sNo).toList();
      dynamic valveList = irrigationLine!.sequence.map((seq) {
        return seq['valve'];
      }).toList().expand((element) => element).toList();

      valveList = valveList.map((val) => val['sNo']).toList();
      List<double?> usedValveInSequence = sampleLineValveList.where((valSno) => valveList.contains(valSno)).toList();
      return usedValveInSequence.isEmpty;
    }).map((e) => e.irrigationLine).toList().map((e) => e.sNo).toList().join("_")}');*/

  /*  print('Head unit to pause :: ${
        sampleIrrigationLine!.where((headUnit) {
          sampleIrrigationLine!.map((element) => element.irrigationLine.sNo).toList();
          selectedObjects!.map((element) => element.sNo).toList();
          List<double?> selectedPumpSnos = selectedObjects!.where((e) => e.objectId == 5).map((e) => e.sNo).toList();
          List<double?> matchingLocations = sampleIrrigationLine!
              .expand((line) => line.irrigationPump!)
              .where((pump) => selectedPumpSnos.contains(pump.sNo))
              .map((pump) => pump.location)
              .toList();
          List<double?> selectedHeadUnitList = selectedObjects!.where((e) => e.objectId == 2 && e.siteMode == null).map((e) => e.sNo).toList();
          List<double?> filteredList = matchingLocations.where((e) => !selectedHeadUnitList.contains(e)).toList();
          return filteredList.contains(headUnit.irrigationLine.sNo);
        }).map((e) => e.irrigationLine.sNo).join("_")}');*/

    final List? selectedAgitators = _irrigationLine?.sequence
        .expand((e) => e['valve'].map((valve) => valve['sNo']))
        .toList();

    print("selectedAgitators :: $selectedAgitators");
    if(agitators != null && agitators!.isNotEmpty) {
      totalAgitators = agitators!.map((e) => e.sNo).toList();
    }

    /*print("filter selection :: ${centralFilterSite.toList().isNotEmpty
        ? centralFilterSite
        .where((element) => selectedObjects!.any((ele) => ele.sNo == element.filterSite!.sNo))
        .map((e) => e.filters != null ? List<DeviceObjectModel>.from(e.filters!) : [])
        .expand((list) => list)
        .whereType<DeviceObjectModel>()
        .where((device) => selectedObjects!.any((selected) => selected.sNo == device.sNo))  // This ensures only selected devices are kept
        .map((e) => e.sNo)
        .join('_')
        : ''}");

    print("selectedObjects in the dataToMqtt :: ${selectedObjects!.map((e) => e.sNo)}");*/

    /*print("not selected agitators :: ${totalAgitators
        .where((agitator) => !(selectedAgitators ?? []).contains(agitator))
        .toList().join(',')}");
    */
    return {
      "2500" : {
        "2501" : "${hwPayloadForWF(serialNumber, programType)};",
        "2502": "${
            {
              "S_No": '$serialNumber',/*S_No*/
              "ProgramType": AppConstants.omsGemList.contains(modelId)
                  ?
              5 :
              '${programType == "Irrigation Program" ? 1 : programType.contains('Aerator') ? 4 : 2}',/*ProgramType*/
              "ProgramCategory": AppConstants.omsGemList.contains(modelId)
                  ? additionalData!.nodeSelection.map((e) => e['serialNo']).join('_') :
              '${programType == "Irrigation Program"
                  ? selectedObjects!.any((element) => element.objectId == 5)
                  ? sampleIrrigationLine!.where((line) => selectedObjects!
                  .any((element) => line.irrigationPump != null && line.irrigationPump!.any((pump) => element.sNo == pump.sNo)))
                  .map((line) => line.irrigationLine)
                  .toSet().toList().map((e) => e.sNo).join("_")
                  : sampleIrrigationLine!.where((headUnit) {
                return irrigationLine!.sequence.any((sequenceItem) {
                  return sequenceItem['valve'].any((valve) {
                    return headUnit.valve!.any((valveItem) {
                      return valveItem.sNo == valve['sNo'];
                    });
                  });
                });
              }).map((e) => e.irrigationLine)
                  .toSet().toList().map((e) => e.sNo).toList().join("_")
                  : _irrigationLine?.sequence.map((e) {
                List valveSerialNumbers = e['valve'].map((valve) => valve['sNo']).toSet().toList();
                return valveSerialNumbers.join('_');
              }).toList().join("+")}', /*ProgramCategory*/
              "Sequence": '${_irrigationLine?.sequence.map((e) => e['sNo']).toList().join("_")}',/*Sequence*/
              "PumpStationMode": '${isPumpStationMode ? 1 : 0}',/*PumpStationMode*/
              "Pump": selectedObjects!.where((pump) => pump.objectId == 5).map((e) => e.sNo).toList().join('_'),/*Pump*/
              "MainValve": selectedObjects!.where((pump) => pump.objectId == 14).map((e) => e.sNo).toList().join('_'),/*MainValve*/
              "Priority": '${priority == priorityList[0] ? 1 : 2}',/*Priority*/
              "DelayBetweenZones": delayBetweenZones.length == 5 ? "$delayBetweenZones:00" : delayBetweenZones,/*DelayBetweenZones*/
              "ScaleFactor": adjustPercentage != "0" ? adjustPercentage : "100",/*ScaleFactor*/
              "SchedulingMethod": '${selectedScheduleType == scheduleTypes[0]/*SchedulingMethod*/
                  ? 1 : selectedScheduleType == scheduleTypes[1] ? 2 : selectedScheduleType == scheduleTypes[2] ? 3 : 4}',
              "ScheduleStartDate": formatter.format(DateTime.parse(startDate(serialNumber: serialNumber))),/*ScheduleStartDate*/
              "ScheduleDayCount": selectedScheduleType == scheduleTypes[1] ? noOfDays : "${int.parse(runDays) + int.parse(skipDays)}",/*ScheduleDayCount*/
              "ScheduleDaySelection": '${selectedScheduleType == scheduleTypes[3]/*ScheduleDaySelection*/
                  ? _sampleScheduleModel!.dayCountSchedule.schedule["shouldLimitCycles"] == true ? "1" : "0"
                  : selectedScheduleType == scheduleTypes[1]
                  ? getDaySelectionMode()
                  : [runDays, skipDays].join("_")}',
              "ScheduleEndDate": isForceToEndDate ? (endDate.runtimeType == String ? formatter.format(DateTime.parse(endDate)) : formatter.format(DateTime.parse(endDate.toString()))) : "0001-01-01",/*ScheduleEndDate*/
              "RtcOnTime": (selectedScheduleType == scheduleTypes[3]/*RtcOnTime*/
                  ? _sampleScheduleModel!.dayCountSchedule.schedule["onTime"]
                  : (AppConstants.omsGemList.contains(modelId) ? rtcOnTime.split('_').first : rtcOnTime)),
              "ProgramStopMethod": _sampleScheduleModel!.defaultModel.allowStopMethod
                  ? rtcStopMethod
                  : (_sampleScheduleModel!.defaultModel.rtcMaxTime
                  ? getProgramStopMethod(3)
                  : _sampleScheduleModel!.defaultModel.rtcOffTime
                  ? getProgramStopMethod(2)
                  : getProgramStopMethod(1)),/*ProgramStopMethod*/
              "RtcOff_MaxTime": (_sampleScheduleModel!.defaultModel.rtcMaxTime
                  ? rtcMaxTime
                  : _sampleScheduleModel!.defaultModel.rtcOffTime
                  ? rtcOffTime
                  : _sampleScheduleModel!.defaultModel.allowStopMethod
                  ? generateRtcTimeStringByUser() : rtcOnTime),/*RtcOff_MaxTime*/
              "CycleCount": selectedScheduleType == scheduleTypes[3] ? (_sampleScheduleModel!.dayCountSchedule.schedule["noOfCycles"] == '' ? '0' : _sampleScheduleModel!.dayCountSchedule.schedule["noOfCycles"]): rtcNoOfCycles,/*CycleCount*/
              "IntervalBetweenCycles": selectedScheduleType == scheduleTypes[3] ? _sampleScheduleModel!.dayCountSchedule.schedule["interval"] : rtcInterval,/*IntervalBetweenCycles*/
              "CentralFertilizerSite": centralFertilizerSite.toList().isNotEmpty
                  ? sampleIrrigationLine!
                  .map((e) => e.centralFertilization != null ? [e.centralFertilization!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .where((device) => selectedObjects!.any((obj) => obj.sNo == device.sNo))
                  .toList()
                  .map((e) => e.sNo)
                  .toSet()
                  .toList()
                  .join('_')
                  : "",/*CentralFertilizerSite*/
              "LocalFertilizerSite": localFertilizerSite.toList().isNotEmpty
                  ? sampleIrrigationLine!
                  .map((e) => e.localFertilization != null ? [e.localFertilization!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .where((device) => selectedObjects!.any((obj) => obj.sNo == device.sNo))
                  .toList()
                  .map((e) => e.sNo)
                  .toSet()
                  .toList()
                  .join('_')
                  : "",/*LocalFertilizerSite*/
              "CentralFertilizerTankSelection": centralFertilizerSite.map((e) => e.selector != null ? List<DeviceObjectModel>.from(e.selector!) : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .toList().isNotEmpty
                  ? centralFertilizerSite.map((e) => e.selector != null ? List<DeviceObjectModel>.from(e.selector!) : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .where((device) => selectedObjects!.any((obj) => obj.sNo == device.sNo))
                  .map((e) => e.sNo)
                  .toSet()
                  .toList()
                  .join('_')
                  : "",/*CentralFertilizerTankSelection*/
              "LocalFertilizerTankSelection": localFertilizerSite.map((e) => e.selector != null ? List<DeviceObjectModel>.from(e.selector!) : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .toList().isNotEmpty
                  ? localFertilizerSite.map((e) => e.selector != null ? List<DeviceObjectModel>.from(e.selector!) : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .where((device) => selectedObjects!.any((obj) => obj.sNo == device.sNo))
                  .map((e) => e.sNo)
                  .toSet()
                  .toList()
                  .join('_')
                  : "",/*LocalFertilizerTankSelection*/
              "CentralFilterSite": centralFilterSite.toList().isNotEmpty
                  ? sampleIrrigationLine!.map((e) => e.centralFiltration != null ? [e.centralFiltration!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .where((device) => selectedObjects!.any((obj) => obj.sNo == device.sNo))
                  .map((e) => e.sNo)
                  .toSet()
                  .toList()
                  .join('_')
                  : "",/*CentralFilterSite*/
              "LocalFilterSite": localFilterSite.toList().isNotEmpty
                  ? sampleIrrigationLine!.map((e) => e.localFiltration
                  != null ? [e.localFiltration!] : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .where((device) => selectedObjects!.any((obj) => obj.sNo == device.sNo))
                  .map((e) => e.sNo)
                  .toSet()
                  .toList()
                  .join('_')
                  : "",/*LocalFilterSite*/
              "CentralFilterSiteOperationMode": '${selectedCentralFiltrationMode == "TIME"
                  ? 1 : selectedCentralFiltrationMode == "DP"
                  ? 2
                  : 3}',/*CentralFilterSiteOperationMode*/
              "LocalFilterSiteOperationMode": '${selectedLocalFiltrationMode == "TIME"
                  ? 1
                  : selectedLocalFiltrationMode == "DP"
                  ? 2
                  : 3}',/*LocalFilterSiteOperationMode*/
              "CentralFilterSelection": centralFilterSite.toList().isNotEmpty
                  ? centralFilterSite
                  .where((element) => selectedObjects!.any((ele) => ele.sNo == element.filterSite!.sNo))
                  .map((e) => e.filters != null ? List<DeviceObjectModel>.from(e.filters!) : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .where((device) => selectedObjects!.any((selected) => selected.sNo == device.sNo))
                  .map((e) => e.sNo)
                  .join('_')
                  : '',/*CentralFilterSelection*/
              "LocalFilterSelection": localFilterSite.toList().isNotEmpty
                  ? localFilterSite
                  .where((element) => selectedObjects!.any((ele) => ele.sNo == element.filterSite!.sNo))
                  .map((e) => e.filters != null ? List<DeviceObjectModel>.from(e.filters!) : [])
                  .expand((list) => list)
                  .whereType<DeviceObjectModel>()
                  .where((device) => selectedObjects!.any((selected) => selected.sNo == device.sNo))
                  .toList().map((e) => e.sNo).join('_') : '',/*LocalFilterSelection*/
              "CentralFilterBeginningOnly": '${centralFiltBegin ? 1 : 0}',/*CentralFilterBeginningOnly*/
              "LocalFilterBeginningOnly": '${localFiltBegin ? 1 : 0}',/*LocalFilterBeginningOnly*/
              "ConditionBasedProgram": '${_sampleConditions?.condition != null
                  ? _sampleConditions!.condition.any((element) => element.selected == true)
                  ? 1
                  : 0
                  : 0}',/*ConditionBasedProgram*/
              "Conditions": conditionList.map((value) => value ?? '0').toList().join("_"),/*Conditions*/
              "AlarmOnOff": AppConstants.omsGemList.contains(modelId)
                  ?
              '${newAlarmList!.alarmList[0].sNo}:${newAlarmList!.alarmList[0].value ? 1 : 0}:${newAlarmList!.alarmList[2].sNo}:${newAlarmList!.alarmList[2].value ? 1 : 0}'
                  : newAlarmList!.alarmList.map((e) => e.value == true ? 1 : 0).toList().join('_'),
              "PumpChangeOverFlag": '${isChangeOverMode ? 1 : 0}',/*PumpChangeOverFlag*/
              "HeadUnit": '${programType == "Irrigation Program"
                  ? sampleIrrigationLine!.where((line) => selectedObjects!
                  .any((element) => line.irrigationLine.sNo == element.sNo))
                  .map((line) => line.irrigationLine)
                  .toList().map((e) => e.sNo).join("_")
                  : _irrigationLine?.sequence.map((e) {
                List valveSerialNumbers = e['valve'].map((valve) => valve['sNo']).toList();
                return valveSerialNumbers.join('_');
              }).toList().join("+")}',/*HeadUnit*/
              "HeadUnitToPause": programType == "Irrigation Program"
                  ? selectedObjects!.any((element) => element.objectId == 5)
                  ? sampleIrrigationLine!.where((headUnit) {
                sampleIrrigationLine!.map((element) => element.irrigationLine.sNo).toList();
                selectedObjects!.map((element) => element.sNo).toList();
                List<double?> selectedPumpSnos = selectedObjects!.where((e) => e.objectId == 5).map((e) => e.sNo).toList();
                List<double?> matchingLocations = sampleIrrigationLine!
                    .expand((line) => line.irrigationPump!)
                    .where((pump) => selectedPumpSnos.contains(pump.sNo))
                    .map((pump) => pump.location)
                    .toList();
                List<double?> selectedHeadUnitList = selectedObjects!.where((e) => e.objectId == 2 && e.siteMode == null).map((e) => e.sNo).toList();
                List<double?> filteredList = matchingLocations.where((e) => !selectedHeadUnitList.contains(e)).toList();
                return filteredList.contains(headUnit.irrigationLine.sNo);
              }).map((e) => e.irrigationLine.sNo).join("_")
                  : sampleIrrigationLine!.where((headUnit) {
                var sampleLineValveList = headUnit.valve!.map((valve) => valve.sNo).toList();
                dynamic valveList = irrigationLine!.sequence.map((seq) {
                  return seq['valve'];
                }).toList().expand((element) => element).toList();

                valveList = valveList.map((val) => val['sNo']).toList();
                List<double?> usedValveInSequence = sampleLineValveList.where((valSno) => valveList.contains(valSno)).toList();
                return usedValveInSequence.isEmpty;
              }).map((e) => e.irrigationLine).toList().map((e) => e.sNo).toList().join("_")
                  : totalAgitators
                  .where((agitator) => !(selectedAgitators ?? []).contains(agitator))
                  .toList().join(','),/*HeadUnitToPause*/
              "Name": programName,
              "CyclicOnTime": cyclicOnTime,
              "CyclicOffTime": AppConstants.omsGemList.contains(modelId) ? (controlMode == 'Pressure' ? pressureTolerance : flowTolerance) : cyclicOffTime,
              "EnablePressure": AppConstants.omsGemList.contains(modelId) ?  (controlMode == 'Pressure' ? '1' : '2') : (enablePressure ? '1' : '0'),
              "PressureValue": AppConstants.omsGemList.contains(modelId) ? (controlMode == 'Pressure' ? setPressure : setFlow) : pressureValue,
              "FlowScanTime": flowScanTime,
            }.entries.map((e) => e.value).join(",")
        };"
      }
    };
  }

  List<int> _getPayloadForEcoGemPumpAndFilter({required objectId}) {
    final configObject = configObjects.where((pump) => pump['objectId'] == objectId).map((e) => e['sNo']).toList();
    final selectedObject = selectedObjects!.where((pump) => pump.objectId == objectId).map((e) => e.sNo).toList();
    print("configObject in the _getPayloadForEcoGemPumpAndFilter :: $configObject");
    print("selectedObject in the _getPayloadForEcoGemPumpAndFilter :: $selectedObject");
    var payload = [0,0];
    for(var obj in selectedObject){
      print("obj in the for loop :: $obj");
      print("index in the for loop :: ${configObject.indexOf(obj)}");
      int indexOfObject = configObject.isEmpty ? 0 : configObject.indexOf(obj);
      payload[indexOfObject] = 1;
      print("payload[indexOfObject] :: ${payload[indexOfObject]}");
    }
    print("payload in _getPayloadForEcoGemPumpAndFilter :: $payload");
    return payload;
  }

  dynamic dataToMqttForEcoGem(serialNumber, programType) {
    final scheduleType = selectedScheduleType;
    final schedule = scheduleType == scheduleTypes[1]
        ? sampleScheduleModel!.scheduleAsRunList.schedule
        : sampleScheduleModel!.scheduleByDays.schedule;

    print("selectedObjects :: ${selectedObjects!.map((e) => e.objectId)}");
    print("selectedObjects :: ${selectedObjects!.map((e) => e.sNo)}");
    final centralFilterSite = filterSite!.where((site) {
      print("Central filter site ==> ${site.filterSite?.sNo}");
      for (var i = 0; i < selectedObjects!.length; i++) {
        if (site.siteMode == 1 && selectedObjects![i].objectId == 4 && selectedObjects![i].sNo == site.filterSite?.sNo) {
          return true;
        }
      }
      return false;
    });

    var endDate = DateTime.parse(schedule['endDate']).isBefore(DateTime.parse(startDate(serialNumber: serialNumber)))
        ? DateTime.now().toString() :(schedule['endDate'] ?? DateTime.now().toString());
    var noOfDays = ((schedule['noOfDays'] == "" || schedule['noOfDays'] == "0") ? "1": schedule['noOfDays']) ?? '1';
    final runDays = ((schedule['runDays'] == "" || schedule['runDays'] == "0") ? "1": schedule['runDays']) ?? '1';
    final skipDays = schedule['skipDays'] ?? '0';
    final dateRange = (DateTime.parse(endDate).difference(DateTime.parse(startDate(serialNumber: serialNumber)))).inDays;
    final firstDate = DateTime.parse(startDate(serialNumber: serialNumber)).add(Duration(days: (scheduleType == scheduleTypes[1] ? int.parse(noOfDays) : 0)
        + int.parse(runDays != '' ? runDays : "1") + int.parse(skipDays != '' ? skipDays : "0") - (selectedScheduleType == scheduleTypes[1] ? 2 : 1)));
    endDate = dateRange < (scheduleType == scheduleTypes[1] ? int.parse(noOfDays) : 0)
        + int.parse(runDays != '' ? runDays : "1") + int.parse(skipDays != '' ? skipDays : "0")
        ? firstDate
        : DateTime.parse(endDate);
    var pumpPayload = _getPayloadForEcoGemPumpAndFilter(objectId: AppConstants.pumpObjectId);
    var filterPayload = _getPayloadForEcoGemPumpAndFilter(objectId: AppConstants.filterObjectId);
    print("filterPayload :: $filterPayload");
    return {
      "2500" : {
        "2502": {
              "S_No": '$serialNumber',
              "no of zones": '${_irrigationLine!.sequence.length}',
              "PumpStationMode": '${isPumpStationMode ? 1 : 0}',
              "Pump": pumpPayload.join(','),
              "DelayBetweenZones": delayBetweenZones.length == 5 ? "${delayBetweenZones.replaceAll(':', ',')},00" : delayBetweenZones.replaceAll(':', ','),
              "ScaleFactor": adjustPercentage != "0" ? adjustPercentage : "100",
              "SchedulingMethod": '${selectedScheduleType == scheduleTypesForEcoGem[0]
                  ? 1 : 2}',
              "IntervalBetweenCycles": selectedScheduleType == scheduleTypes[3] ? _sampleScheduleModel!.dayCountSchedule.schedule["interval"].replaceAll(':', ',') : '00,00,00',/*IntervalBetweenCycles*/
              "CentralFilterSiteOperationMode": '${selectedCentralFiltrationMode == "TIME"
                  ? 1 : selectedCentralFiltrationMode == "DP"
                  ? 2
                  : 3}',/*CentralFilterSiteOperationMode*/
              "CentralFilterSelection": centralFilterSite.isNotEmpty ? filterPayload.join(',') : '0,0',
              "AlarmOnOff": newAlarmList!.alarmList.where((ele) => ele.ecoGemPayload).map((e) => e.value == true ? 1 : 0).toList().join(','),/*AlarmOnOff*/
              // "AlarmOnOff": '0,0,0,0,0,0',/*AlarmOnOff*/
              "Name": programName,
            }.entries.map((e) => e.value).join(","),
      }
    };
  }
}

class Tuple<Labels, Icons> {
  final Labels labels;
  final Icons icons;

  Tuple(this.labels, this.icons);
}