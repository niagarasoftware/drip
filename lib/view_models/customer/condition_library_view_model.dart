import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/models/customer/condition_library_model.dart';
import 'package:provider/provider.dart';
import '../../repository/repository.dart';
import '../../services/communication_service.dart';
import '../../utils/snack_bar.dart';

class ConditionLibraryViewModel extends ChangeNotifier {

  final Repository repository;
  bool isLoading = false;
  bool _isDisposed = false;
  String errorMessage = "";

  late ConditionLibraryModel clData;

  List<String> connectingCondition = [];
  List<List<String>> connectedTo = [];

  String? selectedConditions;

  List<TextEditingController> vtTEVControllers = [];
  List<TextEditingController> amTEVControllers = [];


  ConditionLibraryViewModel(this.repository);

  Future<void> getConditionLibraryData(int customerId, int controllerId) async {
    setLoading(true);
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        var response = await repository.fetchConditionLibrary({
          "userId": customerId,
          "controllerId": controllerId,
        });

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          //print(response.body);
          if (jsonData["code"] == 200) {
            clData = ConditionLibraryModel.fromJson(jsonData['data']);
            clData.cnLibrary.condition.sort((a, b) => (a.sNo).compareTo(b.sNo));
            vtTEVControllers = List.generate(
              clData.cnLibrary.condition.length,
                  (index) => TextEditingController(),
            );
            amTEVControllers = List.generate(
              clData.cnLibrary.condition.length,
                  (index) => TextEditingController(),
            );
            connectedTo = List.generate(5, (index) => []);
          }
        }
      } catch (error) {
        debugPrint('Error fetching condition library: $error');
      } finally {
        setLoading(false);
      }
    });
  }

  void conTypeOnChange(String type, int index){
    clData.cnLibrary.condition[index].type = type;
    clData.cnLibrary.condition[index].component = '--';
    clData.cnLibrary.condition[index].parameter = '--';
    clData.cnLibrary.condition[index].threshold = '--';
    clData.cnLibrary.condition[index].value = '--';
    clData.cnLibrary.condition[index].reason = '--';
    clData.cnLibrary.condition[index].delayTime = '--';
    clData.cnLibrary.condition[index].alertMessage = '--';
    safeNotify();
  }

  void componentOnChange(String component, int index, String serialNo){
    clData.cnLibrary.condition[index].component = component;
    clData.cnLibrary.condition[index].componentSNo = serialNo;
    clData.cnLibrary.condition[index].parameter = '--';
    clData.cnLibrary.condition[index].threshold = '--';
    clData.cnLibrary.condition[index].value = '--';
    clData.cnLibrary.condition[index].reason = '--';
    clData.cnLibrary.condition[index].delayTime = '--';
    clData.cnLibrary.condition[index].alertMessage = '--';
    updateRule(index);
    safeNotify();
  }

  void parameterOnChange(String param, int index) {
    clData.cnLibrary.condition[index].parameter = param;
    updateRule(index);
    safeNotify();
  }

  void thresholdOnChange(String valT, int index){
    clData.cnLibrary.condition[index].threshold = valT;
    updateRule(index);
    if(valT.contains('Lower')){
      clData.cnLibrary.condition[index].delayTime = '10 Sec';
    }else{
      clData.cnLibrary.condition[index].delayTime = '3 Sec';
    }
    safeNotify();
  }

  void valueOnChange(String val, int index){
    clData.cnLibrary.condition[index].value = val;
    updateRule(index);
    safeNotify();
  }

  void reasonOnChange(String reason, int index){
    clData.cnLibrary.condition[index].reason = reason;

    clData.cnLibrary.condition[index].alertMessage =
    '${clData.cnLibrary.condition[index].reason} detected in '
        '${clData.cnLibrary.condition[index].component}';
    amTEVControllers[index].text = clData.cnLibrary.condition[index].alertMessage;
    updateRule(index);
    amTEVControllers[index].text = clData.cnLibrary.condition[index].alertMessage;

    safeNotify();
  }

  void updateLineName(String lineName, String lineSno, int index) {
    final condition = clData.cnLibrary.condition[index];

    condition.reason = lineName;
    condition.componentSNo = lineSno;

    condition.alertMessage = '';
    amTEVControllers[index].text = condition.alertMessage;

    updateRule(index);
    safeNotify();
  }

  void lineReasonOnChange(String reason, int index) {
    final condition = clData.cnLibrary.condition[index];

    condition.reason = reason;

    final lineName = condition.name.isNotEmpty ? condition.name
        : 'Unknown Line';

    condition.alertMessage = '$reason detected in $lineName';
    amTEVControllers[index].text = condition.alertMessage;
    updateRule(index);

    safeNotify();
  }

  void delayTimeOnChange(String delayTime, int index){
    clData.cnLibrary.condition[index].delayTime = delayTime;
    safeNotify();
  }

  void switchStateOnChange(bool status, int index){
    clData.cnLibrary.condition[index].status = status;
    safeNotify();
  }

  void buildConnectingConditions() {
    connectingCondition = clData.cnLibrary.condition.map((c) => c.name).toList();
    safeNotify();
  }


  List<String> getAvailableCondition(int index) {
    buildConnectingConditions();
    if (index >= 0 && index < connectingCondition.length) {
      connectingCondition.removeAt(index);
    }
    List<String> available = List.from(connectingCondition);
    if(clData.cnLibrary.condition[index].component!='--'){
      List<String> resultList = clData.cnLibrary.condition[index].component.split(RegExp(r'\s*&\s*'));
      connectedTo[index] = resultList;
    }

    available.removeWhere((source) {
      if (index >= connectedTo.length) {
        connectedTo.addAll(List.generate(index - connectedTo.length + 1, (_) => <String>[]));
      }
      return connectedTo[index].contains(source);
    });

    return available;
  }

  void combinedTO(int index, String source, int sNo) {
    if (connectedTo[index].contains(source)) {
      connectedTo[index].remove(source);
    } else {
      if (connectedTo[index].length >= 2) {
        return;
      }
      connectedTo[index].add(source);
    }

    List<String> cc = connectedTo[index];
    String resultNames = cc.join(" & ");

    List<int> serials = cc.map((name) {
      final cond = clData.cnLibrary.condition.firstWhere((c) => c.name == name);
      return cond.sNo;
    }).toList();
    String resultSerials = serials.join("_");

    clData.cnLibrary.condition[index].component = resultNames;
    clData.cnLibrary.condition[index].componentSNo = resultSerials;

    safeNotify();
  }

  void clearCombined(int index) {
    connectedTo[index].clear();
    clData.cnLibrary.condition[index].component = '--';
    clData.cnLibrary.condition[index].componentSNo = '';
    safeNotify();
  }


  void updateRule(int index) {

    String isValue = 'is';
    final cSno = clData.cnLibrary.condition[index].componentSNo;
    if(cSno.toString().startsWith('23.') || cSno.toString().startsWith('40.')){
      isValue = '';
    }

    if(clData.cnLibrary.condition[index].parameter!='--'){
      clData.cnLibrary.condition[index].rule =
      '${clData.cnLibrary.condition[index].parameter} of '
          '${clData.cnLibrary.condition[index].component} $isValue '
          '${clData.cnLibrary.condition[index].threshold} '
          '${clData.cnLibrary.condition[index].value}';
    }else{
      clData.cnLibrary.condition[index].rule = '';
    }

    safeNotify();
  }

  void createNewCondition() {
    List<int> existingSerials = clData.cnLibrary.condition
        .map((c) => c.sNo)
        .toList()
      ..sort();

    int newSerial = 1;
    for (int i = 0; i < existingSerials.length; i++) {
      if (existingSerials[i] != i + 1) {
        newSerial = i + 1;
        break;
      }
      newSerial = existingSerials.length + 1;
    }

    Condition newCondition = Condition(
      sNo: newSerial,
      name: "Condition $newSerial",
      status: false,
      type: "Sensor",
      rule: "--",
      component: "--",
      componentSNo: '0',
      parameter: "--",
      threshold: "--",
      value: "--",
      reason: "--",
      delayTime: "--",
      alertMessage: "--",
    );

    clData.cnLibrary.condition.add(newCondition);

    vtTEVControllers = List.generate(
      clData.cnLibrary.condition.length,
          (index) => TextEditingController(),
    );
    amTEVControllers = List.generate(
      clData.cnLibrary.condition.length,
          (index) => TextEditingController(),
    );

    safeNotify();
  }

  Future<void> saveConditionLibrary(
      BuildContext context, int customerId, int controllerId, userId, deviceId) async {
    try {
      List<Map<String, dynamic>> payloadList = [];

      for (var condition in clData.cnLibrary.condition) {

        String input = condition.value;
        final match = RegExp(r'[\d.]+').firstMatch(input);
        String numberOnly = match != null ? match.group(0)! : '0';

        if (condition.componentSNo.toString().startsWith('23.') ||
            condition.componentSNo.toString().startsWith('40.')) {
          numberOnly = condition.value.toLowerCase().contains('high') ? '1' : '0';
        }

        List<String> serialNo = [];
        if (condition.type == 'Combined') {
          serialNo = condition.componentSNo.split('_');
        }

        payloadList.add({
          'sNo': condition.sNo,
          'name': condition.name,
          'status': condition.status ? 1 : 0,
          'delayTime': formatTime(condition.delayTime),
          'StartTime': '00:01:00',
          'StopTime': '23:59:00',
          'notify': 1,
          'category': getConditionCategory(condition),
          'object': condition.type == 'Combined' ? serialNo[0] : condition.componentSNo,
          'operator': condition.type == 'Sensor'
              ? getOperatorOfSensor(condition)
              : condition.type == 'Program'
              ? getOperatorOfProgram(condition)
              : getOperatorOfCombined(condition),
          'setValue': condition.type == 'Combined' ? serialNo[1] : numberOnly,
          'Bypass': 0,
        });
      }

      String payloadString = payloadList.map((e) => e.values.join(',')).join(';');

      String payLoadFinal = jsonEncode({
        "1000": {"1001": payloadString}
      });

      final commService = Provider.of<CommunicationService>(context, listen: false);
      commService.sendCommand(serverMsg: '', payload: payLoadFinal);

      Map<String, dynamic> body = {
        "userId": customerId,
        "controllerId": controllerId,
        "condition": clData.cnLibrary.toJson(),
        "hardware": jsonDecode(payLoadFinal),
        "createUser": userId,
      };

      var response = await repository.saveConditionLibrary(body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        GlobalSnackBar.show(context, jsonData["message"], jsonData["code"]);
      }

    } catch (error) {
      debugPrint('Error fetching language list: $error');
    } finally {
      setLoading(false);
    }
  }

  int getConditionCategory(Condition condition) {
    if (condition.type == 'Program') {
      if(condition.component == 'Any irrigation program' || condition.component == 'Any fertilizer program'
          || condition.component == 'Any Pre(Time/Qty) program'){
        return 11;
      }
      return 1;
    }
    else if (condition.type == 'Sensor' && condition.parameter=='Level') {
      return 9;
    }else if (condition.type == 'Sensor' && condition.parameter=='Moisture') {
      return 8;
    }
    else if (condition.type == 'Combined') {
      if(condition.threshold == 'Anyone is' && condition.value == 'True'){
        return 6;
      }else if(condition.threshold == 'Both are' && condition.value == 'True'){
        return 6;
      }
      return 7;
    }
    return 5;
  }

  int getOperatorOfSensor(Condition condition) {
    if (condition.threshold == 'Above') {
      return 4;
    }else if (condition.threshold == 'Below') {
      return 5;
    }
    return 6;
  }

  int getOperatorOfProgram(Condition condition) {
    if(condition.component == 'Any irrigation program'){
      if (condition.threshold == 'is Running' && condition.value=='True') {
        return 19;
      }
      return 20;
    }
    else if(condition.component == 'Any fertilizer program'){
      if (condition.threshold == 'is Running' && condition.value=='True') {
        return 21;
      }
      return 22;
    }
    else if(condition.component == 'Any Pre(Time/Qty) program'){
      if (condition.threshold == 'is Running' && condition.value=='True') {
        return 24;
      }
      return 25;
    }
    else{
      if (condition.threshold == 'is Starting') {
        return 8;
      }else if (condition.threshold == 'is Ending') {
        return 9;
      }
      else if (condition.threshold == 'is Running' && condition.value=='True') {
        return 10;
      }else if (condition.threshold == 'is Running' && condition.value=='False') {
        return 11;
      }
      return 0;
    }
  }

  int getOperatorOfCombined(Condition condition) {
    if(condition.threshold == 'Anyone is'){
      return 2;
    }
    return 1;
  }

  void removeCondition(int index) {
    clData.cnLibrary.condition.removeAt(index);
    connectedTo.clear();
    safeNotify();
  }

  void updateConditionName(int index, String name) {
    clData.cnLibrary.condition[index].name = name;
    connectedTo.clear();
    safeNotify();
  }

  String formatTime(String time) {
    if (time.contains("Sec")) {
      int seconds = int.parse(time.replaceAll(RegExp(r'[^0-9]'), ''));
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      int secs = seconds % 60;
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }
    return time;
  }


  void setLoading(bool value) {
    isLoading = value;
    safeNotify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}