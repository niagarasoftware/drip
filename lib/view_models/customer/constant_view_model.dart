import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/customer/constant_model.dart';
import '../../repository/repository.dart';
import '../../utils/snack_bar.dart';

class ConstantViewModel extends ChangeNotifier {
  final Repository repository;
  bool isLoading = false;
  String errorMessage = "";

  BuildContext context;

  late UserConstant userConstant;
  late List<ConstantMenu> filteredMenu = [];

  List<TextEditingController> txtEdControllers = [];
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();

  List<TextEditingController> txtEdControllersNF = [];
  List<TextEditingController> txtEdControllersRatio = [];
  List<TextEditingController> txtEdControllersThreshold = [];

  List<TextEditingController> txtEdControllersMin = [];
  List<TextEditingController> txtEdControllersMax = [];
  List<TextEditingController> txtEdControllersHeight = [];

  List<TextEditingController> txtEdControllersMinMS = [];
  List<TextEditingController> txtEdControllersMaxMS = [];

  List<TextEditingController> txtEdControllersCheRatio = [];
  List<TextEditingController> txtEdControllersChePulse = [];
  List<TextEditingController> txtEdControllersCheNF = [];

  List<TextEditingController> txtEdControllersEcPhDelta = [];
  List<TextEditingController> txtEdControllersEcPhFineTune = [];
  List<TextEditingController> txtEdControllersEcPhCoarse = [];
  List<TextEditingController> txtEdControllersEcPhDeadBand = [];
  List<TextEditingController> txtEdControllersEcPhAvgFiltSpeed = [];
  List<TextEditingController> txtEdControllersEcPhPercentage = [];

  ConstantViewModel(this.context, this.repository) {
    txtEdControllersCheRatio =
        List.generate(8, (index) => TextEditingController());
    txtEdControllersChePulse =
        List.generate(8, (index) => TextEditingController());
    txtEdControllersCheNF =
        List.generate(8, (index) => TextEditingController());

    txtEdControllersEcPhDelta =
        List.generate(8, (index) => TextEditingController());
    txtEdControllersEcPhFineTune =
        List.generate(8, (index) => TextEditingController());
    txtEdControllersEcPhCoarse =
        List.generate(8, (index) => TextEditingController());
    txtEdControllersEcPhDeadBand =
        List.generate(8, (index) => TextEditingController());
    txtEdControllersEcPhAvgFiltSpeed =
        List.generate(8, (index) => TextEditingController());
    txtEdControllersEcPhPercentage =
        List.generate(8, (index) => TextEditingController());
  }

  Future<void> getConstantData(int customerId, int controllerId) async {
    setLoading(true);
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        var response = await repository.fetchConstantData(
            {"userId": customerId, "controllerId": controllerId});
        print(response.body);
        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          if (jsonData["code"] == 200) {
            userConstant = UserConstant.fromJson(context, jsonData['data']);
            filteredMenu = userConstant.defaultData.constantMenus
                .where((item) => item.parameter != "Normal Alarm")
                .toList();

            txtEdControllers =
                List.generate(12, (index) => TextEditingController());
            txtEdControllersNF = List.generate(
                userConstant.constant.valveList!.length,
                (index) => TextEditingController());
            txtEdControllersRatio = List.generate(
                userConstant.constant.waterMeterList!.length,
                (index) => TextEditingController());
            txtEdControllersThreshold = List.generate(
                userConstant.constant.criticalAlarm!.length,
                (index) => TextEditingController());

            txtEdControllersMin = List.generate(
                userConstant.constant.levelSensor!.length,
                (index) => TextEditingController());
            txtEdControllersMax = List.generate(
                userConstant.constant.levelSensor!.length,
                (index) => TextEditingController());
            txtEdControllersHeight = List.generate(
                userConstant.constant.levelSensor!.length,
                (index) => TextEditingController());

            txtEdControllersMinMS = List.generate(
                userConstant.constant.moistureSensor!.length,
                (index) => TextEditingController());
            txtEdControllersMaxMS = List.generate(
                userConstant.constant.moistureSensor!.length,
                (index) => TextEditingController());

            for (int i = 0; i < userConstant.constant.generalMenu.length; i++) {
              if (userConstant.constant.generalMenu[i].widgetTypeId == 1) {
                txtEdControllers[i].text =
                    userConstant.constant.generalMenu[i].value;
              }
            }

            for (int i = 0; i < userConstant.constant.valveList!.length; i++) {
              txtEdControllersNF[i].text =
                  userConstant.constant.valveList![i].txtValue;
            }

            for (int i = 0;
                i < userConstant.constant.waterMeterList!.length;
                i++) {
              txtEdControllersNF[i].text =
                  userConstant.constant.waterMeterList![i].radio;
            }

            for (int i = 0;
                i < userConstant.constant.levelSensor!.length;
                i++) {
              txtEdControllersMin[i].text =
                  userConstant.constant.levelSensor![i].min.toString();
              txtEdControllersMax[i].text =
                  userConstant.constant.levelSensor![i].max.toString();
              txtEdControllersHeight[i].text =
                  userConstant.constant.levelSensor![i].height.toString();
            }

            for (int i = 0;
                i < userConstant.constant.moistureSensor!.length;
                i++) {
              txtEdControllersMinMS[i].text =
                  userConstant.constant.moistureSensor![i].min.toString();
              txtEdControllersMaxMS[i].text =
                  userConstant.constant.moistureSensor![i].max.toString();
            }

            for (int i = 0;
                i < userConstant.constant.fertilization!.length;
                i++) {
              for (int j = 0;
                  j < userConstant.constant.fertilization![i].channel.length;
                  j++) {
                txtEdControllersCheRatio[j].text = userConstant
                    .constant.fertilization![i].channel[j].ratioTxtValue;
                txtEdControllersChePulse[j].text = userConstant
                    .constant.fertilization![i].channel[j].pulseTxtValue;
                txtEdControllersCheNF[j].text = userConstant
                    .constant.fertilization![i].channel[j].nmlFlowTxtValue;
              }

              for (int j = 0;
                  j < userConstant.constant.fertilization![i].ecSensor.length;
                  j++) {
                txtEdControllersEcPhDelta[j].text =
                    userConstant.constant.fertilization![i].ecSensor[j].delta;
                txtEdControllersEcPhFineTune[j].text = userConstant
                    .constant.fertilization![i].ecSensor[j].fineTuning;
                txtEdControllersEcPhCoarse[j].text = userConstant
                    .constant.fertilization![i].ecSensor[j].coarseTuning;
                txtEdControllersEcPhDeadBand[j].text = userConstant
                    .constant.fertilization![i].ecSensor[j].deadband;
                txtEdControllersEcPhAvgFiltSpeed[j].text = userConstant
                    .constant.fertilization![i].ecSensor[j].avgFiltSpeed;
                txtEdControllersEcPhPercentage[j].text = userConstant
                    .constant.fertilization![i].ecSensor[j].percentage;
              }

              int ecLength =
                  userConstant.constant.fertilization![i].ecSensor.length;

              for (int j = 0;
                  j < userConstant.constant.fertilization![i].phSensor.length;
                  j++) {
                txtEdControllersEcPhDelta[j + ecLength].text =
                    userConstant.constant.fertilization![i].phSensor[j].delta;
                txtEdControllersEcPhFineTune[j + ecLength].text = userConstant
                    .constant.fertilization![i].phSensor[j].fineTuning;
                txtEdControllersEcPhCoarse[j + ecLength].text = userConstant
                    .constant.fertilization![i].phSensor[j].coarseTuning;
                txtEdControllersEcPhDeadBand[j + ecLength].text = userConstant
                    .constant.fertilization![i].phSensor[j].deadband;
                txtEdControllersEcPhAvgFiltSpeed[j + ecLength].text =
                    userConstant
                        .constant.fertilization![i].phSensor[j].avgFiltSpeed;
                txtEdControllersEcPhPercentage[j + ecLength].text = userConstant
                    .constant.fertilization![i].phSensor[j].percentage;
              }
            }

            menuOnChange(0);
          }
        }
      } catch (error) {
        debugPrint('Error fetching language list: $error');
      } finally {
        setLoading(false);
      }
    });
  }

  void menuOnChange(int index) {
    for (var item in filteredMenu) {
      item.isSelected = false;
    }
    filteredMenu[index].isSelected = true;
    notifyListeners();
  }

  void updateGeneralValve(int index, String value, String type) {
    String finalVal = value.trim();

    int fSiteIndex = 0;
    List<String> parts = type.split('_');
    if (parts.length > 1) {
      fSiteIndex = int.parse(parts[1]);
    }

    if (type == 'value') {
      userConstant.constant.valveList![index].txtValue = finalVal;
    } else if (type == 'ratio') {
      userConstant.constant.waterMeterList![index].radio = finalVal;
    } else if (type == 'Threshold') {
      userConstant.constant.criticalAlarm![index].threshold = finalVal;
    } else if (type == 'levelSensorMin') {
      userConstant.constant.levelSensor![index].min = double.parse(finalVal);
    } else if (type == 'levelSensorMax') {
      userConstant.constant.levelSensor![index].max = double.parse(finalVal);
    } else if (type == 'levelSensorHeight') {
      userConstant.constant.levelSensor![index].height = double.parse(finalVal);
    } else if (type == 'moistureSensorMinMS') {
      userConstant.constant.moistureSensor![index].min = double.parse(finalVal);
    } else if (type == 'moistureSensorMaxMS') {
      userConstant.constant.moistureSensor![index].max = double.parse(finalVal);
    } else if (type == 'ratioTxtValue') {
      userConstant.constant.fertilization![0].channel[index].ratioTxtValue =
          finalVal;
    } else if (type == 'pulseTxtValue') {
      userConstant.constant.fertilization![0].channel[index].pulseTxtValue =
          finalVal;
    } else if (type == 'boosterDelayTxtValue') {
      userConstant.constant.fertilization![0].channel[index].nmlFlowTxtValue =
          finalVal;
    } else if (parts[0] == 'EcDelta') {
      userConstant.constant.fertilization![fSiteIndex].ecSensor[index].delta =
          finalVal;
    } else if (parts[0] == 'PhDelta') {
      userConstant.constant.fertilization![fSiteIndex].phSensor[index].delta =
          finalVal;
    } else if (parts[0] == 'EcFineTune') {
      userConstant.constant.fertilization![fSiteIndex].ecSensor[index]
          .fineTuning = finalVal;
    } else if (parts[0] == 'PhFineTune') {
      userConstant.constant.fertilization![fSiteIndex].phSensor[index]
          .fineTuning = finalVal;
    } else if (parts[0] == 'EcCoarse') {
      userConstant.constant.fertilization![fSiteIndex].ecSensor[index]
          .coarseTuning = finalVal;
    } else if (parts[0] == 'PhCoarse') {
      userConstant.constant.fertilization![fSiteIndex].phSensor[index]
          .coarseTuning = finalVal;
    } else if (parts[0] == 'EcDeadBand') {
      userConstant.constant.fertilization![fSiteIndex].ecSensor[index]
          .deadband = finalVal;
    } else if (parts[0] == 'PhDeadBand') {
      userConstant.constant.fertilization![fSiteIndex].phSensor[index]
          .deadband = finalVal;
    } else if (parts[0] == 'EcAvgFiltSpeed') {
      userConstant.constant.fertilization![fSiteIndex].ecSensor[index]
          .avgFiltSpeed = finalVal;
    } else if (parts[0] == 'PhAvgFiltSpeed') {
      userConstant.constant.fertilization![fSiteIndex].phSensor[index]
          .avgFiltSpeed = finalVal;
    } else if (parts[0] == 'EcPercentage') {
      userConstant.constant.fertilization![fSiteIndex].ecSensor[index]
          .percentage = finalVal;
    } else if (parts[0] == 'PhPercentage') {
      userConstant.constant.fertilization![fSiteIndex].phSensor[index]
          .percentage = finalVal;
    } else {
      userConstant.constant.generalMenu[index].value = finalVal;
    }
  }

  void updateGeneralSwitch(int index, bool status, String type) {
    if (type == 'globalAlarm') {
      userConstant.constant.globalAlarm![index].value = status;
    } else {
      userConstant.constant.generalMenu[index].value = status;
    }

    notifyListeners();
  }

  void showDurationInputDialog(
      BuildContext context, String durationValue, int index, String cnsType) {
    List<String> timeParts = durationValue.split(':');
    _hoursController.text = timeParts[0];
    _minutesController.text = timeParts[1];
    _secondsController.text = timeParts[2];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('duration'),
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
              onPressed: () async {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            MaterialButton(
              color: Colors.teal,
              textColor: Colors.white,
              onPressed: () async {
                if (_validateTime(_hoursController.text, 'hours') &&
                    _validateTime(_minutesController.text, 'minutes') &&
                    _validateTime(_secondsController.text, 'seconds')) {
                  durationValue =
                      '${_hoursController.text}:${_minutesController.text}:${_secondsController.text}';

                  int fSiteIndex = 0;

                  List<String> parts = cnsType.split('_');
                  if (parts.length > 1) {
                    fSiteIndex = int.parse(parts[1]);
                  }

                  if (cnsType == 'general') {
                    userConstant.constant.generalMenu[index].value =
                        durationValue;
                  } else if (cnsType == 'valve') {
                    userConstant.constant.valveList![index].duration =
                        durationValue;
                  } else if (cnsType == 'mainValve') {
                    userConstant.constant.mainValveList![index].duration =
                        durationValue;
                  } else if (cnsType == 'irrigateLine_lfd') {
                    userConstant.constant.irrigationLineList![index]
                        .lowFlowDelay = durationValue;
                  } else if (cnsType == 'irrigateLine_hfd') {
                    userConstant.constant.irrigationLineList![index]
                        .highFlowDelay = durationValue;
                  } else if (cnsType == 'scanTime') {
                    userConstant.constant.criticalAlarm![index].scanTime =
                        durationValue;
                  } else if (cnsType == 'autoResetDuration') {
                    userConstant.constant.criticalAlarm![index]
                        .autoResetDuration = durationValue;
                  } else if (cnsType == 'minimalOnTime') {
                    userConstant.constant.fertilization![index].minimalOnTime =
                        durationValue;
                  } else if (cnsType == 'minimalOffTime') {
                    userConstant.constant.fertilization![index].minimalOffTime =
                        durationValue;
                  } else if (cnsType == 'boosterDelay') {
                    userConstant.constant.fertilization![index].boosterDelay =
                        durationValue;
                  } else if (parts[0] == 'controlCycle1') {
                    userConstant.constant.fertilization![fSiteIndex]
                        .ecSensor[index].controlCycle = durationValue;
                  } else if (parts[0] == 'controlCycle2') {
                    userConstant.constant.fertilization![fSiteIndex]
                        .phSensor[index].controlCycle = durationValue;
                  } else if (parts[0] == 'integ1') {
                    userConstant.constant.fertilization![fSiteIndex]
                        .ecSensor[index].integ = durationValue;
                  } else if (parts[0] == 'integ2') {
                    userConstant.constant.fertilization![fSiteIndex]
                        .phSensor[index].integ = durationValue;
                  }

                  notifyListeners();
                  Navigator.of(context).pop();
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Invalid time formed'),
                        content: const Text(
                            'Please fill correct time format and try again.'),
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

  void pumpStationOnChange(int index, bool status) {
    userConstant.constant.pumpList![index].pumpStation = status;
    notifyListeners();
  }

  void controlGemOnChange(int index, bool status) {
    userConstant.constant.pumpList![index].controlGem = status;
    notifyListeners();
  }

  void ddOnChange(int index, String selectedValue, String type) {
    if (type == 'mainValve') {
      userConstant.constant.mainValveList![index].delay = selectedValue;
    } else if (type == 'criticalAlarm') {
      userConstant.constant.criticalAlarm![index].alarmOnStatus = selectedValue;
    } else if (type == 'resetAfterIrrigation') {
      userConstant.constant.criticalAlarm![index].resetAfterIrrigation =
          selectedValue;
    } else if (type == 'levelSensor') {
      userConstant.constant.levelSensor![index].highLow = selectedValue;
    } else if (type == 'units') {
      userConstant.constant.levelSensor![index].units = selectedValue;
    } else if (type == 'base') {
      userConstant.constant.levelSensor![index].base = selectedValue;
    } else if (type == 'highLowMS') {
      userConstant.constant.moistureSensor![index].highLow = selectedValue;
    } else if (type == 'unitsMS') {
      userConstant.constant.moistureSensor![index].units = selectedValue;
    } else if (type == 'baseMS') {
      userConstant.constant.moistureSensor![index].base = selectedValue;
    } else if (type == 'Injector Mode') {
      userConstant.constant.fertilization![0].channel[index].injectorMode =
          selectedValue;
    }

    notifyListeners();
  }

  void lowFlowAction(int index, String selectedValue) {
    userConstant.constant.irrigationLineList![index].lowFlowAction =
        selectedValue;
    notifyListeners();
  }

  void highFlowAction(int index, String selectedValue) {
    userConstant.constant.irrigationLineList![index].highFlowAction =
        selectedValue;
    notifyListeners();
  }

  Future<void> saveConstantData(
      context, int customerId, int controllerId, int createUserId) async {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        Map<String, dynamic> cnsMenu = userConstant.constant.toJson();

        Map<String, dynamic> body = {
          "userId": customerId,
          "controllerId": controllerId,
          "general": cnsMenu['general'],
          "line": cnsMenu['irrigationLine'],
          "mainValve": cnsMenu['mainValve'],
          "valve": cnsMenu['valveList'],
          "pump": cnsMenu['pumpList'],
          "waterMeter": cnsMenu['waterMeter'],
          "filtration": [],
          "fertilization": cnsMenu['fertilization'],
          "ecPh": [],
          "analogSensor": [],
          "moistureSensor": cnsMenu['moistureSensor'],
          "levelSensor": cnsMenu['levelSensor'],
          "normalAlarm": [],
          "criticalAlarm": cnsMenu['criticalAlarm'],
          "commonAlarm": cnsMenu['commonAlarm'] ?? [],
          "globalAlarm": cnsMenu['globalAlarm'],
          "controllerReadStatus": '0',
          "createUser": createUserId,
        };

        print(body);

        Map<String, String> jsonObjectGeneral = {
          "301":
              "${body['general'][9]['value']}, ${body['general'][10]['value']}, ${body['general'][11]['value']}"
        };

        var response = await repository.saveConstantData(body);
        print(response.body);
        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          if (jsonData["code"] == 200) {
            GlobalSnackBar.show(context, jsonData["message"], jsonData["code"]);
          }
        }
      } catch (error) {
        debugPrint('Error fetching language list: $error');
      } finally {
        setLoading(false);
      }
    });
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
