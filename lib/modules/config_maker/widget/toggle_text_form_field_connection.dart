import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import 'connection_grid_list_tile.dart';
import 'object_manager_bar.dart';

class ToggleTextFormFieldForConnection extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  final String initialValue;
  final DeviceObjectModel object;
  final DeviceModel selectedDevice;

  const ToggleTextFormFieldForConnection({
    super.key,
    required this.initialValue,
    required this.object,
    required this.configPvd,
    required this.selectedDevice,
  });

  @override
  State<ToggleTextFormFieldForConnection> createState() => _ToggleTextFormFieldForConnectionState();
}

class _ToggleTextFormFieldForConnectionState extends State<ToggleTextFormFieldForConnection> {
  FocusNode myFocus = FocusNode();
  late TextEditingController myController;
  bool focus = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    myController = TextEditingController();
    myController.text = widget.initialValue;
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        myFocus.addListener(() {
          if (!myFocus.hasFocus && isEditing) {
            toggleEditing();
            var newCount = myController.text == '' ? 0 : int.parse(myController.text);
            _updateConnectionCount(newCount);
            setState(() {
              focus = false;
            });
          }
          if (myFocus.hasFocus == true) {
            setState(() {
              focus = true;
            });
          }
        });
      });
    }
  }

  void _updateConnectionCount(int newCount) {
    if (newCount < 0) return;
    int oldCount = widget.object.count == '' ? 0 : int.parse(widget.object.count!);
    if (newCount == oldCount) return;

    Map<String, int> mappingBalanceType = {
      '1,2': (widget.selectedDevice.noOfRelay == 0
              ? widget.selectedDevice.noOfLatch
              : widget.selectedDevice.noOfRelay) -
          getConfigureCountByType('1,2'),
      '3': widget.selectedDevice.noOfAnalogInput -
          getNoFixedConnectionCount() -
          getConfigureCountByType('3'),
      '4': widget.selectedDevice.noOfDigitalInput -
          getNoFixedConnectionCount() -
          getConfigureCountByType('4'),
      '5': widget.selectedDevice.noOfMoistureInput -
          getConfigureCountByType('5'),
      '6': widget.selectedDevice.noOfPulseInput -
          getConfigureCountByType('6'),
      '7': widget.selectedDevice.noOfI2CInput -
          getConfigureCountByType('7'),
    };
    int balancePossibleCountToConfigure =
        mappingBalanceType[widget.object.type] ?? 0;

    if (newCount > oldCount) {
      int increasingCount = newCount - oldCount;
      if (increasingCount > balancePossibleCountToConfigure) {
        increasingCount = balancePossibleCountToConfigure;
      }

      if (increasingCount <= 0) return;

      int targetCount = oldCount + increasingCount;
      int unassignedCount =
          getNotConfiguredObjectByObjectId(widget.object.objectId, widget.configPvd);

      if (unassignedCount < increasingCount) {
        int neededNewObjects = increasingCount - unassignedCount;

        DeviceObjectModel? sampleObj;
        for (var obj in widget.configPvd.listOfSampleObjectModel) {
          if (obj.objectId == widget.object.objectId) {
            sampleObj = obj;
            break;
          }
        }

        if (sampleObj != null) {
          int currentSampleCount =
              (sampleObj.count == null || sampleObj.count == '')
                  ? 0
                  : int.parse(sampleObj.count!);
          int newSampleCount = currentSampleCount + neededNewObjects;

          int? cap = maxCountForObject(widget.configPvd, sampleObj);
          if (cap != null && newSampleCount > cap) {
            newSampleCount = cap;
            int maxAllowedNewObjects = cap - currentSampleCount;
            if (maxAllowedNewObjects < 0) maxAllowedNewObjects = 0;
            if (maxAllowedNewObjects < neededNewObjects) {
              increasingCount = unassignedCount + maxAllowedNewObjects;
              targetCount = oldCount + increasingCount;
            }
          }

          if (newSampleCount > currentSampleCount) {
            widget.configPvd
                .updateObjectCount(widget.object.objectId, newSampleCount.toString());
          }
        }
      }

      bool updateOthers = updateConnectionForFixedInputs(
        oldCount: oldCount,
        newCount: targetCount,
        countLimitFromProductLimit: targetCount,
      );
      if (updateOthers) {
        widget.configPvd.updateObjectConnection(widget.object, targetCount);
      }
    } else {
      bool updateOthers = updateConnectionForFixedInputs(
        oldCount: oldCount,
        newCount: newCount,
        countLimitFromProductLimit: newCount,
      );
      if (updateOthers) {
        widget.configPvd.updateObjectConnection(widget.object, newCount);
      }
    }
  }

  int getNoFixedConnectionCount() {
    int fixedConnectionCount = 0;
    if (widget.object.type == '3') {
      if (AppConstants.smartPlusEcPhModel.contains(widget.selectedDevice.modelId)) {
        int phSensorConfigureToNodeCount = 0;
        int ecSensorConfigureToNodeCount = 0;
        for (var object in widget.configPvd.listOfGeneratedObject) {
          if (object.objectId == AppConstants.phObjectId &&
              object.controllerId == widget.selectedDevice.controllerId) {
            phSensorConfigureToNodeCount += 1;
          }
          if (object.objectId == AppConstants.ecObjectId &&
              object.controllerId == widget.selectedDevice.controllerId) {
            ecSensorConfigureToNodeCount += 1;
          }
        }
        fixedConnectionCount = phSensorConfigureToNodeCount + ecSensorConfigureToNodeCount;
      }
    } else if (widget.object.type == '4') {
      if (widget.selectedDevice.connectingObjectId.contains(AppConstants.pressureSwitchObjectId)) {
        bool pressureSwitchConfigureToNode = false;
        for (var object in widget.configPvd.listOfGeneratedObject) {
          if (object.objectId == AppConstants.pressureSwitchObjectId &&
              object.controllerId == widget.selectedDevice.controllerId) {
            pressureSwitchConfigureToNode = true;
          }
        }
        if (!pressureSwitchConfigureToNode) {
          fixedConnectionCount = 1;
        }
      }
    }
    return fixedConnectionCount;
  }

  bool updateConnectionForFixedInputs({
    required int oldCount,
    required int newCount,
    required int countLimitFromProductLimit,
  }) {
    int ph = 28;
    int ec = 27;
    int pressureSwitch = 23;

    if ([ph, ec].contains(widget.object.objectId)) {
      int updateCount = newCount > 2
          ? 2
          : (newCount > countLimitFromProductLimit
              ? countLimitFromProductLimit
              : newCount);
      widget.configPvd.updateObjectConnection(widget.object, updateCount);
      return false;
    } else if (widget.object.objectId == pressureSwitch) {
      int updateCount = newCount > 1 ? 1 : newCount;
      widget.configPvd.updateObjectConnection(widget.object, updateCount);
      return false;
    }
    return true;
  }

  int getConfigureCountByType(String type) {
    List<DeviceObjectModel> listOfObject = widget.configPvd.listOfGeneratedObject
        .where((object) =>
            object.controllerId == widget.selectedDevice.controllerId &&
            object.type == type)
        .toList();
    return listOfObject.length;
  }

  @override
  void dispose() {
    myController.dispose();
    myFocus.dispose();
    super.dispose();
  }

  void toggleEditing() {
    setState(() {
      isEditing = !isEditing;
      if (isEditing) {
        myFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (focus == false) {
      myController.text = widget.initialValue;
    }

    int currentVal = int.tryParse(widget.initialValue) ?? 0;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF12162B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3258)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
            onTap: currentVal > 0 ? () => _updateConnectionCount(currentVal - 1) : null,
            child: Container(
              width: 26,
              height: double.infinity,
              alignment: Alignment.center,
              child: Icon(
                Icons.remove_rounded,
                size: 15,
                color: currentVal > 0 ? const Color(0xFF8E9BB4) : const Color(0xFF2A3258),
              ),
            ),
          ),
          Container(width: 1, height: 16, color: const Color(0xFF2A3258)),
          GestureDetector(
            onTap: toggleEditing,
            child: Container(
              width: 32,
              height: double.infinity,
              alignment: Alignment.center,
              child: isEditing
                  ? TextFormField(
                      focusNode: myFocus,
                      controller: myController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ],
                      maxLength: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        border: InputBorder.none,
                      ),
                    )
                  : Text(
                      widget.initialValue,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC084FC),
                      ),
                    ),
            ),
          ),
          Container(width: 1, height: 16, color: const Color(0xFF2A3258)),
          InkWell(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
            onTap: () => _updateConnectionCount(currentVal + 1),
            child: Container(
              width: 26,
              height: double.infinity,
              alignment: Alignment.center,
              child: Icon(
                Icons.add_rounded,
                size: 15,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}