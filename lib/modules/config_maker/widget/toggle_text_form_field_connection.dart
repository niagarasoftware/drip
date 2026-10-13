import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import 'connection_grid_list_tile.dart';

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
    int oldCount = widget.object.count == '' ? 0 : int.parse(widget.object.count!);
    int? increasingCount;
    if (newCount > oldCount) {
      increasingCount = newCount - oldCount;
    }
    int countLimitFromProductLimit =
        getNotConfiguredObjectByObjectId(widget.object.objectId, widget.configPvd) +
            oldCount;
    int balancePossibleCountToConfigure =
        mappingBalanceType[widget.object.type] ?? 0;

    if (newCount == oldCount) {
      // no change
    } else if (newCount > countLimitFromProductLimit &&
        newCount <= balancePossibleCountToConfigure) {
      int validateCount = newCount < countLimitFromProductLimit
          ? newCount
          : countLimitFromProductLimit;
      bool updateOthers = updateConnectionForFixedInputs(
          oldCount: oldCount,
          newCount: validateCount,
          countLimitFromProductLimit: countLimitFromProductLimit);
      if (updateOthers) {
        widget.configPvd.updateObjectConnection(widget.object, validateCount);
      }
    } else if (increasingCount != null &&
        increasingCount <= balancePossibleCountToConfigure) {
      bool updateOthers = updateConnectionForFixedInputs(
          oldCount: oldCount,
          newCount: newCount,
          countLimitFromProductLimit: countLimitFromProductLimit);
      if (updateOthers) {
        widget.configPvd.updateObjectConnection(
            widget.object, oldCount + increasingCount);
      }
    } else if (increasingCount != null &&
        increasingCount >= balancePossibleCountToConfigure) {
      bool updateOthers = updateConnectionForFixedInputs(
          oldCount: oldCount,
          newCount: newCount,
          countLimitFromProductLimit: countLimitFromProductLimit);
      if (updateOthers) {
        widget.configPvd.updateObjectConnection(
            widget.object, oldCount + balancePossibleCountToConfigure);
      }
    } else {
      widget.configPvd.updateObjectConnection(widget.object, newCount);
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
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
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
                color: currentVal > 0 ? const Color(0xff0F172A) : Colors.grey.shade400,
              ),
            ),
          ),
          Container(width: 1, height: 16, color: Colors.grey.shade300),
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
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
            ),
          ),
          Container(width: 1, height: 16, color: Colors.grey.shade300),
          InkWell(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
            onTap: () => _updateConnectionCount(currentVal + 1),
            child: Container(
              width: 26,
              height: double.infinity,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 15,
                color: Color(0xff0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}