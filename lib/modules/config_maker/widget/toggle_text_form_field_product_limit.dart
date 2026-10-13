import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../../../Constants/dialog_boxes.dart';
import '../model/device_object_model.dart';
import '../view/product_limit.dart';
import '../state_management/config_maker_provider.dart';

class ToggleTextFormFieldForProductLimit extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  final String initialValue;
  final DeviceObjectModel object;
  final Color leadingColor;

  const ToggleTextFormFieldForProductLimit({
    super.key,
    required this.initialValue,
    required this.object,
    required this.configPvd,
    required this.leadingColor,
  });

  @override
  State<ToggleTextFormFieldForProductLimit> createState() => _ToggleTextFormFieldForProductLimitState();
}

class _ToggleTextFormFieldForProductLimitState extends State<ToggleTextFormFieldForProductLimit> {
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
            var integerValue = myController.text == '' ? 0 : int.parse(myController.text);
            _updateCount(integerValue);
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

  void _updateCount(int integerValue) {
    if (integerValue < 0) return;

    if (widget.object.type == '-') {
      if (AppConstants.ecoGemModelList.contains(widget.configPvd.masterData['modelId'])) {
        if ([AppConstants.irrigationLineObjectId].contains(widget.object.objectId)) {
          int maxAllowableCount = 1;
          validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
        } else {
          widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
        }
      } else {
        widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
      }
    } else {
      /* do validate expect source, line, site. */
      int availableCount = widget.object.type == '1,2'
          ? balanceCountForRelayLatch(widget.configPvd)
          : balanceCountForInputType(int.parse(widget.object.type), widget.configPvd);

      /* gem, eco gem, pump and pump with valve model validation */
      availableCount += widget.initialValue == '' ? 0 : int.parse(widget.initialValue);

      /*-----------     pump    ---------------*/
      if (AppConstants.pumpModelList.contains(widget.configPvd.masterData['modelId'])) {
        if ([AppConstants.levelObjectId, AppConstants.waterMeterObjectId].contains(widget.object.objectId)) {
          int maxAllowableCount = 1;
          validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
        } else if (AppConstants.pressureSensorObjectId == widget.object.objectId) {
          int maxAllowableCount = 2;
          validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
        } else {
          doAvailableCountValidate(integerValue: integerValue, availableCount: availableCount);
        }
      }
      /*-----------     pump with valve    ---------------*/
      else if (AppConstants.pumpWithValveModelList.contains(widget.configPvd.masterData['modelId'])) {
        if (widget.object.objectId == AppConstants.pumpObjectId) {
          int maxAllowablePumpCount = 1;
          if (integerValue > maxAllowablePumpCount) {
            simpleDialogBox(context: context, title: 'Alert', message: 'Only one ${widget.object.objectName} should be connected with ${widget.configPvd.masterData['deviceName']}.');
            integerValue = maxAllowablePumpCount;
          }
          widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
        } else if ([AppConstants.lightObjectId].contains(widget.object.objectId) && AppConstants.pumpWithLightModelList.contains(widget.configPvd.masterData['modelId'])) {
          int maxAllowableCount = 10;
          if (integerValue > maxAllowableCount) {
            simpleDialogBox(context: context, title: 'Alert', message: 'Only 10 ${widget.object.objectName} should be connected with ${widget.configPvd.masterData['deviceName']}.');
            integerValue = maxAllowableCount;
          }
          widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
        } else if ([AppConstants.pumpObjectId, AppConstants.lightObjectId, AppConstants.pressureSensorObjectId, AppConstants.pressureSwitchObjectId, AppConstants.soilTemperatureObjectId].contains(widget.object.objectId)) {
          int maxAllowableCount = 1;
          if (integerValue > maxAllowableCount) {
            simpleDialogBox(context: context, title: 'Alert', message: 'Only one ${widget.object.objectName} should be connected with ${widget.configPvd.masterData['deviceName']}.');
            integerValue = maxAllowableCount;
          }
          widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
        } else {
          doAvailableCountValidate(integerValue: integerValue, availableCount: availableCount);
        }
      }
      /*-----------     eco gem    ---------------*/
      else if (AppConstants.ecoGemModelList.contains(widget.configPvd.masterData['modelId'])) {
        if ([AppConstants.pumpObjectId].contains(widget.object.objectId)) {
          int maxAllowableCount = 2;
          validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
        } else if ([AppConstants.filterObjectId, AppConstants.pressureSensorObjectId].contains(widget.object.objectId)) {
          int maxAllowableCount = 2;
          validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
        } else if ([AppConstants.channelObjectId, AppConstants.boosterObjectId, AppConstants.levelObjectId].contains(widget.object.objectId)) {
          int maxAllowableCount = 1;
          validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
        } else {
          doAvailableCountValidate(integerValue: integerValue, availableCount: availableCount);
        }
      }
      /*-----------     gem    ---------------*/
      else {
        doAvailableCountValidate(integerValue: integerValue, availableCount: availableCount);
      }
    }
  }

  void doAvailableCountValidate({required int integerValue, required int availableCount}) {
    if (integerValue > availableCount) {
      simpleDialogBox(
        context: context,
        title: 'Alert',
        message: 'The maximum allowable value is $availableCount. Please enter a value less than or equal to $availableCount.',
      );
      widget.configPvd.updateObjectCount(widget.object.objectId, availableCount.toString());
    } else {
      widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
    }
  }

  void validateObjectForEcoGem({required int integerValue, required int maxAllowableCount}) {
    if (integerValue > maxAllowableCount) {
      simpleDialogBox(
        context: context,
        title: 'Alert',
        message: 'Only $maxAllowableCount ${widget.object.objectName} should be connected with ${widget.configPvd.masterData['deviceName']}.',
      );
      widget.configPvd.updateObjectCount(widget.object.objectId, maxAllowableCount.toString());
    } else {
      widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
    }
  }

  void validateAndUpdateObjectCount(DeviceObjectModel object, int newCount) {
    List<DeviceObjectModel> availableObject = widget.configPvd.listOfGeneratedObject
        .where((available) => (available.objectId == object.objectId))
        .toList();
    if (availableObject.length >= newCount) {
      widget.configPvd.updateObjectCount(object.objectId, newCount.toString());
    }
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
    if (!editable()) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          'Limit reached',
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    int currentVal = int.tryParse(widget.initialValue) ?? 0;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
            onTap: currentVal > 0 ? () => _updateCount(currentVal - 1) : null,
            child: Container(
              width: 26,
              height: double.infinity,
              alignment: Alignment.center,
              child: Icon(
                Icons.remove_rounded,
                size: 15,
                color: currentVal > 0 ? const Color(0xff1E293B) : Colors.grey.shade400,
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
                      maxLength: 3,
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
                        color: widget.leadingColor,
                      ),
                    ),
            ),
          ),
          Container(width: 1, height: 16, color: Colors.grey.shade300),
          InkWell(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
            onTap: () => _updateCount(currentVal + 1),
            child: Container(
              width: 26,
              height: double.infinity,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 15,
                color: Color(0xff1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool editable() {
    bool visible = true;
    if (widget.object.type == '1,2') {
      if (balanceCountForRelayLatch(widget.configPvd) == 0 && ['', '0'].contains(widget.object.count)) {
        visible = false;
      }
    } else if (widget.object.type != '-') {
      if (balanceCountForInputType(int.parse(widget.object.type), widget.configPvd) == 0 && ['', '0'].contains(widget.object.count)) {
        visible = false;
      }
    }
    if (widget.object.objectId == AppConstants.pumpObjectId && AppConstants.ecoGemModelList.contains(widget.configPvd.masterData['modelId'])) {
      visible = true;
    }
    return visible;
  }
}