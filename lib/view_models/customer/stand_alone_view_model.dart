import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer/program_model.dart';
import '../../models/customer/site_model.dart';
import '../../models/customer/stand_alone_model.dart';
import '../../repository/repository.dart';
import '../../services/communication_service.dart';
import '../../utils/constants.dart';


enum SegmentWithFlow {manual, duration, flow}

class StandAloneViewModel extends ChangeNotifier {

  final Repository repository;
  bool isLoading = false;
  String errorMessage = "";

  SegmentWithFlow segmentWithFlow = SegmentWithFlow.manual;
  String durationValue = '00:00:00';
  String selectedIrLine = '0';

  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();
  final TextEditingController flowLiter = TextEditingController();


  List<ProgramModel> programList = [];

  StandAloneModel? standAloneData;

  bool visibleLoading = false;
  int ddCurrentPosition = 0;
  int serialNumber = 0;
  int standAloneMethod = 0;
  int startFlag = 0;
  String strFlow = '0';
  String strDuration = '00:00:00';
  String strSelectedLineOfProgram = '0';

  late List<Map<String, dynamic>> standaloneSelection  = [];

  final int userId, customerId, controllerId;
  final String deviceId;

  MasterControllerModel masterData;

  StandAloneViewModel(this.repository, this.masterData, this.userId, this.customerId, this.controllerId, this.deviceId);

  Future<void> getProgramList() async {
    setLoading(true);
    programList.clear();
    try {
      Map<String, Object> body = {"userId": customerId, "controllerId": controllerId};
      final response = await repository.fetchCustomerProgramList(body);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          List<dynamic> programsJson = jsonData['data'];
          programList = [...programsJson.map((programJson) => ProgramModel.fromJson(programJson))];

          if(![...AppConstants.ecoGemModelList].contains(masterData.modelId)){
            ProgramModel defaultProgram = ProgramModel(
              programId: 0,
              serialNumber: 0,
              programName: 'Default',
              defaultProgramName: '',
              programType: '',
              priority: '',
              startDate: '',
              startTime: '',
              sequenceCount: 0,
              scheduleType: '',
              firstSequence: '',
              duration: '',
              programCategory: '',
            );

            bool programWithNameExists = false;
            for (ProgramModel program in programList) {
              if (program.programName == 'Default') {
                programWithNameExists = true;
                break;
              }
            }

            if (!programWithNameExists) {
              programList.insert(0, defaultProgram);
            } else {
              debugPrint('Program with name \'Default\' already exists in widget.programList.');
            }
          }

          getExitManualOperation();
        }
      }
    } catch (error) {
      debugPrint('Error fetching country list: $error');
    } finally {
      setLoading(false);
    }
  }

  Future<void> getExitManualOperation() async
  {
    try {
      Map<String, Object> body = {"userId": customerId, "controllerId": controllerId};
      final response = await repository.fetchUserManualOperation(body);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null){
          try{

            bool isNova = [...AppConstants.ecoGemModelList].contains(masterData.modelId);

            dynamic data = jsonResponse['data'];
            startFlag = data['startFlag'];
            serialNumber = data['serialNumber'];
            try {
              if(isNova){
                standAloneMethod = 3;
              }else{
                standAloneMethod = data['method'];
                if (standAloneMethod == 0){
                  standAloneMethod = 3;
                }
              }

            } catch (e) {
              debugPrint('Error: $e');
            }

            if(isNova){
              strFlow = '0';
              strDuration = '00:00:00';
            }else{
              strFlow = data['flow'];
              strDuration = data['duration'];
            }

            if(isNova && serialNumber==0) {
              serialNumber = programList[0].serialNumber;
            }

            int position = findPositionByName(serialNumber, programList);

            if (position != -1) {
              ddCurrentPosition = position;
            }else {
              debugPrint("'$serialNumber' not found in the list.");
            }

            if(standAloneMethod == 3){
              segmentWithFlow = SegmentWithFlow.manual;
            }else if(standAloneMethod == 1){
              segmentWithFlow = SegmentWithFlow.duration;
            }else{
              segmentWithFlow = SegmentWithFlow.flow;
            }

            int count = strDuration.split(':').length - 1;
            if(count>1){
              durationValue = strDuration;
            }else{
              durationValue = '$strDuration:00';
            }
            flowLiter.text = strFlow;

            await Future.delayed(const Duration(milliseconds: 500));
            fetchStandAloneSelection(serialNumber, ddCurrentPosition);

          }catch(e){
            debugPrint(e.toString());
          }
        } else {
          throw Exception('Invalid response format: "data" is null');
        }
      }
    } catch (error) {
      debugPrint('Error fetching country list: $error');
    } finally {
      setLoading(false);
    }

  }


  Future<void> fetchStandAloneSelection(int sNo, int cIndex) async {

    ddCurrentPosition = cIndex;

    Map<String, Object> body = {
      "userId": customerId,
      "controllerId": controllerId,
      "serialNumber": sNo
    };

    try {
      var response = await repository.fetchManualOperation(body);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['data'] != null) {
          dynamic data = jsonResponse['data'];
          standAloneData = StandAloneModel.fromJson(data);
          updatePreviousSelection(standAloneData!);
        } else {
          debugPrint('Invalid response format: "data" is null');
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Error fetching Product stock: $error');
      debugPrint(stackTrace.toString());
    } finally {
      notifyListeners();
    }
  }

  void updatePreviousSelection(StandAloneModel data) {

    for (var item in standAloneData!.selection) {
      if (item.sNo is num) {
        final num fullNo = item.sNo as num;
        final int serialNo = fullNo.floor();

        switch (serialNo) {
          case 5:
            for (var line in masterData.irrigationLine) {
              for (var waterSource in line.outletSources) {
                waterSource.outletPump
                    .where((pump) => pump.sNo == fullNo)
                    .forEach((pump) => pump.selected = true);
              }
            }
            break;

          case 7:
            for (var line in masterData.irrigationLine) {
              line.centralFertilizerSite?.boosterPump
                  .where((booster) => booster.sNo == fullNo)
                  .forEach((booster) => booster.selected = true);
            }
            break;

          case 9:
            for (var line in masterData.irrigationLine) {
              line.centralFertilizerSite?.agitator
                  .where((agitator) => agitator.sNo == fullNo)
                  .forEach((agitator) => agitator.selected = true);
            }
            break;

          case 10:
            for (var line in masterData.irrigationLine) {
              line.centralFertilizerSite?.channel
                  .where((channel) => channel.sNo == fullNo)
                  .forEach((channel) => channel.selected = true);
            }
            break;

          case 11:
            for (var line in masterData.irrigationLine) {
              line.centralFilterSite?.filters
                  .where((filter) => filter.sNo == fullNo)
                  .forEach((filter) => filter.selected = true);
            }
            break;

          case 13:
            if (ddCurrentPosition == 0) {
              for (var line in masterData.irrigationLine) {
                line.valveObjects
                    .where((valve) => valve.sNo == fullNo)
                    .forEach((valve) => valve.isOn = true); // valves use isOn
              }
            }
            break;

          case 14:
            for (var line in masterData.irrigationLine) {
              line.valveObjects
                  .where((valve) => valve.sNo == fullNo)
                  .forEach((valve) => valve.isOn = true);
            }
            break;
        }
      } else if (item.sNo is String) {
        final String sequenceNo = item.sNo;
        for (var seq in standAloneData!.sequence) {
          if (seq.sNo == sequenceNo) {
            seq.selected = true;
          }
        }
      }
    }
  }

  Future<void> segmentSelectionCallbackFunction(segIndex, value, sldIrLine) async
  {
    if (value.contains(':')) {
      strDuration = value;
    } else {
      strFlow = value;
    }
    strSelectedLineOfProgram = sldIrLine;
    if(segIndex==0){
      standAloneMethod = 3;
    }else{
      standAloneMethod = segIndex;
    }
    notifyListeners();
  }

  int findPositionByName(int sNo, List<ProgramModel> programList) {
    for (int i = 0; i < programList.length; i++) {
      if (programList[i].serialNumber == sNo) {
        return i;
      }
    }
    return -1;
  }

  void showDurationInputDialog(BuildContext context) {
    List<String> timeParts = durationValue.split(':');
    _hoursController.text = timeParts[0];
    _minutesController.text = timeParts[1];
    _secondsController.text = timeParts[2];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Standalone duration'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 23),
                  decoration: const InputDecoration(
                    labelText: 'Hours',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 23),
                  decoration: const InputDecoration(
                    labelText: 'Minutes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _secondsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 23),
                  decoration: const InputDecoration(
                    labelText: 'Seconds',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            MaterialButton(
              color: Colors.redAccent,
              textColor: Colors.white,
              onPressed:() async {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            MaterialButton(
              color: Colors.teal,
              textColor: Colors.white,
              onPressed:() async {
                if (_validateTime(_hoursController.text, 'hours') &&
                    _validateTime(_minutesController.text, 'minutes') &&
                    _validateTime(_secondsController.text, 'seconds')) {

                  // Pad each value to 2 digits with leading zeros
                  String hours = _hoursController.text.padLeft(2, '0');
                  String minutes = _minutesController.text.padLeft(2, '0');
                  String seconds = _secondsController.text.padLeft(2, '0');

                  durationValue = '$hours:$minutes:$seconds';
                  segmentSelectionCallbackFunction(segmentWithFlow.index, durationValue, selectedIrLine);
                  Navigator.of(context).pop();
                }
                else{
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Invalid time formed'),
                        content: const Text('Please fill correct time format and try again.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: const Text('Set duration'),
            ),
          ],
        );
      },
    );
  }

  bool _validateTime(String value, String fieldType) {
    if (value.isEmpty) {
      return false;
    }
    int intValue = int.tryParse(value) ?? -1;
    if (intValue < 0) {
      return false;
    }
    switch (fieldType) {
      case 'hours':
        return intValue >= 0 && intValue <= 23;
      case 'minutes':
      case 'seconds':
        return intValue >= 0 && intValue <= 59;
      default:
        return false;
    }
  }

  void stopAllManualOperation(BuildContext context) {

    bool isNova = [...AppConstants.ecoGemModelList].contains(masterData.modelId);

    final commService = Provider.of<CommunicationService>(context, listen: false);
    if(ddCurrentPosition==0 && !isNova){
      String payLoadFinal = jsonEncode({
        "800": {"801": '0,0,0,0,0'}
      });
      commService.sendCommand(serverMsg: '', payload: payLoadFinal);
      sentManualModeToServer(0, 0, standAloneMethod, strDuration, strFlow, standaloneSelection, payLoadFinal);
      Navigator.of(context).pop();
    }else{
      String strSldSqnNo = '';
      for (var lineOrSq in standAloneData!.sequence) {
        if(lineOrSq.selected){
          strSldSqnNo = lineOrSq.sNo;
          break;
        }
      }

      if (isNova) {
        strSldSqnNo = strSldSqnNo.replaceAll(RegExp(r'[.]'), ',');
      }

      String payLoadFinal = jsonEncode({
        "3900": {"3901": '0,${programList[ddCurrentPosition].serialNumber},$strSldSqnNo,0,0,0,0,0,0,0,0'}
      });
      commService.sendCommand(serverMsg: '', payload: payLoadFinal);
      sentManualModeToServer(0, 0, standAloneMethod, strDuration, strFlow, standaloneSelection, payLoadFinal);

      Navigator.pop(context, 'OK');
    }
  }

  void startManualOperation(context){

    standaloneSelection.clear();

    bool isNova = [...AppConstants.ecoGemModelList].contains(masterData.modelId);
    bool isAerator = [...AppConstants.aquacultureModelList].contains(masterData.modelId);

    String strSldSourcePumpSrlNo = extractRelaySrlNosFromSources(
      masterData.irrigationLine.expand((line) => line.inletSources).toList(), false,
    );

    String strSldIrrigationPumpSrlNo = extractRelaySrlNosFromSources(
        masterData.irrigationLine.expand((line) => line.outletSources).toList(), false);

    String strSldAeratorPumpSrlNo = extractRelaySrlNosFromSources(
        masterData.irrigationLine.expand((line) => line.aeratorSources).toList(), true);

    String strSldCtrlFilterSrlNo = extractFilterRelaySrlNos(masterData.irrigationLine,'central');
    String strSldCtrlFrtBoosterSrlNo = extractCFrtBoosterSNos(masterData.irrigationLine,'central');
    String strSldCtrlFrtChannelSrlNo = extractCFrtChannelSNos(masterData.irrigationLine,'central');
    String strSldCtrlFrtAgitatorSrlNo = extractCFrtAgitatorSN(masterData.irrigationLine,'central');
    String strSldCtrlFrtSelectorSrlNo = extractCFrtSelectorSN(masterData.irrigationLine,'central');

    String strSldLocFilterSrlNo = extractFilterRelaySrlNos(masterData.irrigationLine,'local');
    String strSldLocFrtBoosterSrlNo = extractCFrtBoosterSNos(masterData.irrigationLine,'local');
    String strSldLocFrtChannelSrlNo = extractCFrtChannelSNos(masterData.irrigationLine,'local');
    String strSldLocFrtAgitatorSrlNo = extractCFrtAgitatorSN(masterData.irrigationLine,'local');
    String strSldLocFrtSelectorSrlNo = extractCFrtSelectorSN(masterData.irrigationLine,'local');


    if(ddCurrentPosition==0 && !isNova) {
      List<String> allPumpSrlNo = [];
      List<String> allRelaySrlNo = [];

      String strSldValveSrlNo = '';

      allPumpSrlNo = [
        strSldSourcePumpSrlNo,
        strSldIrrigationPumpSrlNo,
        strSldAeratorPumpSrlNo,
      ];

      for (var line in masterData.irrigationLine) {
        for (int j = 0; j < line.valveObjects.length; j++) {
          if (line.valveObjects[j].isOn) {
            strSldValveSrlNo += '${line.valveObjects[j].sNo}_';
            standaloneSelection.add({
              'sNo': line.valveObjects[j].sNo,
              'selected': line.valveObjects[j].isOn,
            });
          }
        }
      }

      for (var line in masterData.irrigationLine) {
        for (int j = 0; j < line.mainValveObjects.length; j++) {
          if (line.mainValveObjects[j].selected) {
            strSldValveSrlNo += '${line.mainValveObjects[j].sNo}_';
            standaloneSelection.add({
              'sNo': line.mainValveObjects[j].sNo,
              'selected': line.mainValveObjects[j].selected,
            });
          }
        }
      }

      strSldValveSrlNo = strSldValveSrlNo.isNotEmpty ? strSldValveSrlNo.substring(
          0, strSldValveSrlNo.length - 1) : '';

      allRelaySrlNo = [
        strSldValveSrlNo,

        strSldCtrlFilterSrlNo,
        strSldLocFilterSrlNo,

        strSldCtrlFrtBoosterSrlNo,
        strSldLocFrtBoosterSrlNo,

        strSldCtrlFrtChannelSrlNo,
        strSldLocFrtChannelSrlNo,

        strSldCtrlFrtAgitatorSrlNo,
        strSldLocFrtAgitatorSrlNo,

        strSldCtrlFrtSelectorSrlNo,
        strSldLocFrtSelectorSrlNo,
      ];

      if (strSldIrrigationPumpSrlNo.isNotEmpty && strSldValveSrlNo.isEmpty)
      {
        showDialog<String>(
            context: context,
            builder: (BuildContext dgContext) =>
                AlertDialog(
                  title: const Text('StandAlone'),
                  content: const Text(
                      'Valve is not open! Are you sure! You want to Start the Selected Pump?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dgContext, 'Cancel'),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () {
                        startByStandaloneDefault(context, allRelaySrlNo, allPumpSrlNo);
                        Navigator.pop(dgContext, 'OK');
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                )
        );
      }
      else {
        startByStandaloneDefault(context, allRelaySrlNo, allPumpSrlNo);
        Navigator.pop(context, 'OK');
      }
    }
    else {
      String strSldSqnNo = '';

      String strSldMainValveId = '';
      String strSldCtrlFilterId = '';
      String strSldLocFilterId = '';
      String sldLocFilterRelayOnOffStatus = '';
      String sldCtrlFilterRelayOnOffStatus = '';

      for (var line in masterData.irrigationLine) {
        for (int j = 0; j < line.mainValveObjects.length; j++) {
          if (line.mainValveObjects[j].selected) {
            strSldMainValveId += '${line.mainValveObjects[j].sNo}_';
            standaloneSelection.add({
              'sNo': line.mainValveObjects[j].sNo,
              'selected': line.mainValveObjects[j].selected,
            });
          }
        }
      }

      strSldMainValveId = strSldMainValveId.isNotEmpty ? strSldMainValveId.substring(
          0, strSldMainValveId.length - 1) : '';


      for (var lineOrSq in standAloneData!.sequence) {
        if(lineOrSq.selected){
          strSldSqnNo = lineOrSq.sNo;
          standaloneSelection.add({
            'id': lineOrSq.id,
            'sNo': lineOrSq.sNo,
            'name': lineOrSq.name,
            'location': lineOrSq.location,
            'selected': lineOrSq.selected,
          });
          break;
        }
      }

      if (strSldSqnNo.isEmpty) {
        displayAlert(context, 'You must select an zone.');
      }else if (strSldIrrigationPumpSrlNo.isEmpty) {
        displayAlert(context, 'You must select an irrigation pump.');
      }else{
        if (isNova) {
          strSldIrrigationPumpSrlNo = strSldIrrigationPumpSrlNo.replaceAll(RegExp(r'[._]'), ',');
          strSldSqnNo = strSldSqnNo.replaceAll(RegExp(r'[.]'), ',');
          strSldSqnNo = '0,$strSldSqnNo';
        }

        String payload = '';
        String payLoadFinal = '';

        if(standAloneMethod==1 && strDuration=='00:00:00'){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid Duration input'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        else if(standAloneMethod==2 && (strFlow.isEmpty || strFlow=='0')){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid Liter'),
              duration: Duration(seconds: 3),
            ),
          );
        }else{
          payload = '${1},${programList[ddCurrentPosition].serialNumber},'
              '$strSldSqnNo,$strSldIrrigationPumpSrlNo,$strSldMainValveId,$strSldCtrlFilterId,'
              '$sldCtrlFilterRelayOnOffStatus,$strSldLocFilterId,$sldLocFilterRelayOnOffStatus'
              ',$standAloneMethod,${standAloneMethod==3?'0':standAloneMethod==1?strDuration:strFlow}';

          payLoadFinal = jsonEncode({
            "3900": {"3901": payload}
          });

          final commService = Provider.of<CommunicationService>(context, listen: false);
          commService.sendCommand(serverMsg: '', payload: payLoadFinal);
          sentManualModeToServer(programList[ddCurrentPosition].serialNumber, 1, standAloneMethod, strDuration, strFlow, standaloneSelection, payLoadFinal);
          Navigator.pop(context, 'OK');
        }
      }
    }
  }

  String extractRelaySrlNosFromSources(List<dynamic> sources, bool isAerator) {
    final Set<String> serialNos = {};
    for (var source in sources) {
      final srlNo = getSelectedRelaySrlNo(isAerator ? source.aeratorPump : source.outletPump);
      if (srlNo.isNotEmpty) {
        serialNos.addAll(srlNo.split(','));
      }
    }
    return serialNos.join('_');
  }

  String extractFilterRelaySrlNos(List<IrrigationLineModel> lines, String type) {
    final List<String> result = [];
    for (var line in lines) {
      if(type=='central'){
        if (line.centralFilterSite != null && line.centralFilterSite!.filters.isNotEmpty) {
          final filterSrlNo = getSelectedRelaySrlNo(line.centralFilterSite!.filters);
          if (filterSrlNo.isNotEmpty) {
            result.add(filterSrlNo);
          }
        }
      }else{
        if (line.localFilterSite != null && line.localFilterSite!.filters.isNotEmpty) {
          final filterSrlNo = getSelectedRelaySrlNo(line.localFilterSite!.filters);
          if (filterSrlNo.isNotEmpty) {
            result.add(filterSrlNo);
          }
        }
      }
    }
    return result.join('_');
  }

  String extractCFrtBoosterSNos(List<IrrigationLineModel> lines, String type) {
    final List<String> result = [];
    for (var line in lines) {
      if(type=='central'){
        if (line.centralFertilizerSite != null && line.centralFertilizerSite!.channel.isNotEmpty) {
          final boosterSrlNo = getSelectedRelaySrlNo(line.centralFertilizerSite!.boosterPump);
          if (boosterSrlNo.isNotEmpty) {
            result.add(boosterSrlNo);
          }
        }
      }else{
        if (line.localFertilizerSite != null && line.localFertilizerSite!.channel.isNotEmpty) {
          final boosterSrlNo = getSelectedRelaySrlNo(line.localFertilizerSite!.boosterPump);
          if (boosterSrlNo.isNotEmpty) {
            result.add(boosterSrlNo);
          }
        }
      }
    }
    return result.join('_');
  }

  String extractCFrtChannelSNos(List<IrrigationLineModel> lines, String type) {
    final List<String> result = [];
    for (var line in lines) {
      if(type=='central'){
        if (line.centralFertilizerSite != null && line.centralFertilizerSite!.channel.isNotEmpty) {
          final channelSrlNo = getSelectedRelaySrlNo(line.centralFertilizerSite!.channel);
          if (channelSrlNo.isNotEmpty) {
            result.add(channelSrlNo);
          }
        }
      }else{
        if (line.localFertilizerSite != null && line.localFertilizerSite!.channel.isNotEmpty) {
          final channelSrlNo = getSelectedRelaySrlNo(line.localFertilizerSite!.channel);
          if (channelSrlNo.isNotEmpty) {
            result.add(channelSrlNo);
          }
        }
      }
    }
    return result.join('_');
  }

  String extractCFrtAgitatorSN(List<IrrigationLineModel> lines, String type) {
    final List<String> result = [];
    for (var line in lines) {
      if(type=='central'){
        if (line.centralFertilizerSite != null && line.centralFertilizerSite!.channel.isNotEmpty) {
          final agitatorSrlNo = getSelectedRelaySrlNo(line.centralFertilizerSite!.agitator);
          if (agitatorSrlNo.isNotEmpty) {
            result.add(agitatorSrlNo);
          }
        }
      }else{
        if (line.localFertilizerSite != null && line.localFertilizerSite!.channel.isNotEmpty) {
          final agitatorSrlNo = getSelectedRelaySrlNo(line.localFertilizerSite!.agitator);
          if (agitatorSrlNo.isNotEmpty) {
            result.add(agitatorSrlNo);
          }
        }
      }
    }
    return result.join('_');
  }

  String extractCFrtSelectorSN(List<IrrigationLineModel> lines, String type) {
    final List<String> result = [];
    for (var line in lines) {
      if(type=='central'){
        if (line.centralFertilizerSite != null && line.centralFertilizerSite!.selector.isNotEmpty) {
          final selectorSrlNo = getSelectedRelaySrlNo(line.centralFertilizerSite!.selector);
          if (selectorSrlNo.isNotEmpty) {
            result.add(selectorSrlNo);
          }
        }
      }else{
        if (line.localFertilizerSite != null && line.localFertilizerSite!.selector.isNotEmpty) {
          final selectorSrlNo = getSelectedRelaySrlNo(line.localFertilizerSite!.selector);
          if (selectorSrlNo.isNotEmpty) {
            result.add(selectorSrlNo);
          }
        }
      }
    }
    return result.join('_');
  }



  String getSelectedRelaySrlNo(itemList) {
    String result = '';
    for (int i = 0; i < itemList.length; i++) {
      if (itemList[i].selected) {
        result += '${itemList[i].sNo}_';
        standaloneSelection.add({
          'sNo': itemList[i].sNo,
          'selected': itemList[i].selected,
        });
      }
    }
    return result.isNotEmpty ? result.substring(0, result.length - 1) : '';
  }

  void startByStandaloneDefault(context, List<String> allRelaySrlNo, List<String> allPumpSno){
    String pumpRelays = allPumpSno.where((s) => s.isNotEmpty).join('_');
    String otherRelays = allRelaySrlNo.where((s) => s.isNotEmpty).join('_');

    String payload = '';
    String payLoadFinal = '';

    if(standAloneMethod==1 && strDuration=='00:00:00'){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Duration input'),
          duration: Duration(seconds: 3),
        ),
      );
    }else{
      payload = '1,$pumpRelays,$otherRelays,$standAloneMethod,${standAloneMethod==3?'0':standAloneMethod==1?strDuration:strFlow}';
      payLoadFinal = jsonEncode({
        "800": {"801": payload}
      });

      final commService = Provider.of<CommunicationService>(context, listen: false);
      commService.sendCommand(serverMsg: '', payload: payLoadFinal);
      sentManualModeToServer(0, 1, standAloneMethod, strDuration, strFlow, standaloneSelection, payLoadFinal);
    }
  }

  Future<void> sentManualModeToServer(int sNo, int sFlag, int method, String dur, String flow, List<Map<String, dynamic>> selection, String payLoad) async {
    try {
      final body = {
        "userId": customerId,
        "controllerId": controllerId,
        "serialNumber": sNo,
        "programName": programList[ddCurrentPosition].programName,
        "sequenceName": sNo==0 ? null : selection.isNotEmpty ? selection.last['name'] : '',
        "startFlag": sFlag,
        "method": method,
        "duration": dur,
        "flow": flow,
        "fromDashboard":false,
        "selection": selection,
        "createUser": userId,
        "hardware": jsonDecode(payLoad),
      };

      try {
        var response = await repository.updateStandAloneData(body);
        if (response.statusCode == 200) {
          standaloneSelection.clear();
        }
      } catch (error, stackTrace) {
        debugPrint('Error fetching Product stock: $error');
        debugPrint(stackTrace.toString());
      } finally {
        notifyListeners();
      }

    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void displayAlert(BuildContext context, String msg){
    showDialog<String>(
        context: context,
        builder: (BuildContext dgContext) => AlertDialog(
          title: const Text('Stand Alone'),
          content: Text(msg), // Removed '${}' around msg
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(dgContext, 'OK');
              },
              child: const Text('Ok'),
            ),
          ],
        )
    );
  }

}