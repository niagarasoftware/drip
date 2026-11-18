import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/Constants/dialog_boxes.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import 'connection_grid_list_tile.dart';

class ToggleTextFormFieldForConnection extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  String initialValue;
  DeviceObjectModel object;
  DeviceModel selectedDevice;
  ToggleTextFormFieldForConnection({super.key,required this.initialValue, required this.object, required this.configPvd,required this.selectedDevice});

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
    // TODO: implement initState
    super.initState();
    myController = TextEditingController();
    myController.text = widget.initialValue;
    if(mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        myFocus.addListener(() {
          if(!myFocus.hasFocus){
            toggleEditing();
            Map<String, int> mappingBalanceType = {
              '1,2' : (widget.selectedDevice.noOfRelay == 0 ? widget.selectedDevice.noOfLatch : widget.selectedDevice.noOfRelay) - getConfigureCountByType('1,2'),
              '3' : widget.selectedDevice.noOfAnalogInput - getNoFixedConnectionCount() - getConfigureCountByType('3'),
              '4' : widget.selectedDevice.noOfDigitalInput - getNoFixedConnectionCount() - getConfigureCountByType('4'),
              '5' : widget.selectedDevice.noOfMoistureInput - getConfigureCountByType('5'),
              '6' : widget.selectedDevice.noOfPulseInput - getConfigureCountByType('6'),
              '7' : widget.selectedDevice.noOfI2CInput - getConfigureCountByType('7'),
            };
            var newCount = myController.text == '' ? 0 : int.parse(myController.text);
            int oldCount = widget.object.count == '' ? 0 : int.parse(widget.object.count!);
            int? increasingCount;
            int? decreasingCount;
            if(newCount > oldCount){
              increasingCount = newCount - oldCount;
            }else{
              decreasingCount = oldCount - newCount;
            }
            int countLimitFromProductLimit = getNotConfiguredObjectByObjectId(widget.object.objectId, widget.configPvd) + oldCount;
            int balancePossibleCountToConfigure = mappingBalanceType[widget.object.type]!;

            print('oldCount :: $oldCount  newCount :: $newCount    maxLimit :: $countLimitFromProductLimit  mappingBalanceType :: ${mappingBalanceType[widget.object.type]!}  balancePossibleCountToConfigure :: $balancePossibleCountToConfigure');
            if(newCount == oldCount){
              //  don't do anything....
            }else if(newCount > countLimitFromProductLimit && newCount <= balancePossibleCountToConfigure){
              // validate non configured to configure count
              print('111111111');
              int validateCount = newCount < countLimitFromProductLimit ? newCount : countLimitFromProductLimit;
              bool updateOthers = updateConnectionForFixedInputs(oldCount: oldCount, newCount: validateCount, countLimitFromProductLimit: countLimitFromProductLimit);
              if(updateOthers){
                print('no ph,ec');

                widget.configPvd.updateObjectConnection(widget.object, validateCount);
              }
            }else if(increasingCount != null && increasingCount <= balancePossibleCountToConfigure){
              // only update if there is place to configure
              print('22222222');
              bool updateOthers = updateConnectionForFixedInputs(oldCount: oldCount, newCount: newCount, countLimitFromProductLimit: countLimitFromProductLimit);
              if(updateOthers){
                print('no ph,ec');
                widget.configPvd.updateObjectConnection(widget.object, oldCount + increasingCount);
              }
            }else if(increasingCount != null && increasingCount >= balancePossibleCountToConfigure){
              // only update max object possible to configure
              print('3333333333');
              bool updateOthers = updateConnectionForFixedInputs(oldCount: oldCount, newCount: newCount, countLimitFromProductLimit: countLimitFromProductLimit);
              if(updateOthers){
                print('oldCount + balancePossibleCountToConfigure == > ${oldCount + balancePossibleCountToConfigure}');
                widget.configPvd.updateObjectConnection(widget.object, oldCount + balancePossibleCountToConfigure);
              }
            }else{
              print('44444444');
              widget.configPvd.updateObjectConnection(widget.object, newCount);
            }
            setState(() {
              focus = false;
            });
          }
          if(myFocus.hasFocus == true){
            setState(() {
              focus = true;
            });
          }
        });
      });
    }
  }


  int getNoFixedConnectionCount(){
    int fixedConnectionCount = 0;
    if(widget.object.type == '3'){
      if(AppConstants.smartPlusEcPhModel.contains(widget.selectedDevice.modelId)){
        int phSensorConfigureToNodeCount = 0;
        int ecSensorConfigureToNodeCount = 0;
        for(var object in widget.configPvd.listOfGeneratedObject){
          if(object.objectId == AppConstants.phObjectId && object.controllerId == widget.selectedDevice.controllerId){
            phSensorConfigureToNodeCount += 1;
          }
          if(object.objectId == AppConstants.ecObjectId && object.controllerId == widget.selectedDevice.controllerId){
            ecSensorConfigureToNodeCount += 1;
          }
        }
        fixedConnectionCount = phSensorConfigureToNodeCount + ecSensorConfigureToNodeCount;
      }
    }
    else if(widget.object.type == '4'){
      if(widget.selectedDevice.connectingObjectId.contains(AppConstants.pressureSwitchObjectId)){
        bool pressureSwitchConfigureToNode = false;
        for(var object in widget.configPvd.listOfGeneratedObject){

          if(object.objectId == AppConstants.pressureSwitchObjectId && object.controllerId == widget.selectedDevice.controllerId){
            pressureSwitchConfigureToNode = true;;
          }
        }
        if(!pressureSwitchConfigureToNode){
          fixedConnectionCount = 1;
        }
      }

    }
    print('fixedConnectionCount : $fixedConnectionCount');

    return fixedConnectionCount;
  }



  bool updateConnectionForFixedInputs({
    required int oldCount,
    required int newCount,
    required int countLimitFromProductLimit,
}){
    print('oldCount : $oldCount');
    print('newCount : $newCount');
    print('countLimitFromProductLimit : $countLimitFromProductLimit');
    int ph = 28;
    int ec = 27;
    int pressureSwitch = 23;

    if ([ph, ec].contains(widget.object.objectId)) {
      print('updating ec, ph');
      int updateCount = newCount > 2
          ? 2
          : (newCount > countLimitFromProductLimit
          ? countLimitFromProductLimit
          : newCount);
      widget.configPvd.updateObjectConnection(widget.object, updateCount);
      return false;
    }else if(widget.object.objectId == pressureSwitch){
      print('updating pressureSwitch');
      int updateCount = newCount > 1 ? 1 : newCount;
      widget.configPvd.updateObjectConnection(widget.object, updateCount);
      return false;
    }
    return true;
  }

  int getConfigureCountByType(String type){
    List<DeviceObjectModel> listOfObject = widget.configPvd.listOfGeneratedObject.where((object) => object.controllerId == widget.selectedDevice.controllerId && object.type == type).toList();
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
    if(focus == false){
      myController.text = widget.initialValue;
    }
    return GestureDetector(
      onTap: toggleEditing,
      child: isEditing
          ? SizedBox(
        width: 80,
        child: TextFormField(
          focusNode: myFocus,
          controller: myController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
          onFieldSubmitted: (value){

          },
          maxLength: 2,
          onChanged: (value){

          },
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                  borderSide: BorderSide.none
              )
          ),
        ),
      )
          : Container(
          margin: const EdgeInsets.all(2),
          width: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
          ),
          height: double.infinity,
          child: Center(child: Text(widget.initialValue, style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w600),))
      ),
    );
  }
}
