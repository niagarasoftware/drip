import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../../../Constants/dialog_boxes.dart';
import '../model/device_object_model.dart';
import '../view/product_limit.dart';
import '../state_management/config_maker_provider.dart';

class ToggleTextFormFieldForProductLimit extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  String initialValue;
  DeviceObjectModel object;
  Color leadingColor;
  ToggleTextFormFieldForProductLimit({super.key,required this.initialValue, required this.object, required this.configPvd,required this.leadingColor});

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
    // TODO: implement initState
    super.initState();
    myController = TextEditingController();
    myController.text = widget.initialValue;
    if(mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        myFocus.addListener(() {
          if(!myFocus.hasFocus){
            toggleEditing();
            var integerValue = myController.text == '' ? 0 : int.parse(myController.text);

            if(widget.object.type == '-'){
              if(AppConstants.ecoGemModelList.contains(widget.configPvd.masterData['modelId'])){
                if([AppConstants.irrigationLineObjectId].contains(widget.object.objectId)){
                  int maxAllowableCount = 1;
                  validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
                }else{
                  widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
                }
              }else{
                widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
              }

            }else{
              /* do validate expect source, line, site. */
              int availableCount = widget.object.type == '1,2'
                  ? balanceCountForRelayLatch(widget.configPvd)
                  : balanceCountForInputType(int.parse(widget.object.type), widget.configPvd);

              /* gem, eco gem, pump and pump with valve model validation */
              availableCount += widget.initialValue == '' ? 0 : int.parse(widget.initialValue);

              /*-----------     pump    ---------------*/
              if(AppConstants.pumpModelList.contains(widget.configPvd.masterData['modelId'])){
                if([AppConstants.levelObjectId, AppConstants.waterMeterObjectId].contains(widget.object.objectId)){
                  // level , water meter -- oro pump
                  int maxAllowableCount = 1;
                  validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
                }else if(AppConstants.pressureSensorObjectId == widget.object.objectId){
                  // float -- oro pump
                  int maxAllowableCount = 2;
                  validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
                }else{
                  doAvailableCountValidate(integerValue: integerValue, availableCount: availableCount);
                }
              }

              /*-----------     pump with valve    ---------------*/
              else if(AppConstants.pumpWithValveModelList.contains(widget.configPvd.masterData['modelId'])){
                /* filter output object for pump with valve model*/
                if(widget.object.objectId == AppConstants.pumpObjectId){
                  /*only one pump allowed to config*/
                  int maxAllowablePumpCount = 1;
                  if(integerValue > maxAllowablePumpCount){
                    simpleDialogBox(context: context, title: 'Alert', message: 'Only one ${widget.object.objectName} should be connect with ${widget.configPvd.masterData['deviceName']}.');
                    integerValue = maxAllowablePumpCount;
                  }
                  widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
                }else if([AppConstants.lightObjectId].contains(widget.object.objectId) && AppConstants.pumpWithLightModelList.contains(widget.configPvd.masterData['modelId'])){
                  /*only one pump allowed to config*/
                  int maxAllowableCount = 10;
                  if(integerValue > maxAllowableCount){
                    simpleDialogBox(context: context, title: 'Alert', message: 'Only 10 ${widget.object.objectName} should be connect with ${widget.configPvd.masterData['deviceName']}.');
                    integerValue = maxAllowableCount;
                  }
                  widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
                }else if([AppConstants.pumpObjectId, AppConstants.lightObjectId, AppConstants.pressureSensorObjectId, AppConstants.pressureSwitchObjectId, AppConstants.soilTemperatureObjectId].contains(widget.object.objectId)){
                  /*only one pump allowed to config*/
                  int maxAllowableCount = 1;
                  if(integerValue > maxAllowableCount){
                    simpleDialogBox(context: context, title: 'Alert', message: 'Only one ${widget.object.objectName} should be connect with ${widget.configPvd.masterData['deviceName']}.');
                    integerValue = maxAllowableCount;
                  }
                  widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
                }else{
                  doAvailableCountValidate(integerValue: integerValue, availableCount: availableCount);
                }
              }

              /*-----------     eco gem    ---------------*/
              else if(AppConstants.ecoGemModelList.contains(widget.configPvd.masterData['modelId'])){
                /*only two pump allowed to config*/
                if([AppConstants.pumpObjectId].contains(widget.object.objectId)){
                  int maxAllowableCount = 2;
                  validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
                }else if([AppConstants.filterObjectId, AppConstants.pressureSensorObjectId].contains(widget.object.objectId)){
                  int maxAllowableCount = 2;
                  validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
                }else if([AppConstants.channelObjectId, AppConstants.boosterObjectId, AppConstants.levelObjectId].contains(widget.object.objectId)){
                  int maxAllowableCount = 1;
                  validateObjectForEcoGem(integerValue: integerValue, maxAllowableCount: maxAllowableCount);
                }else{
                  doAvailableCountValidate(integerValue: integerValue, availableCount: availableCount);
                }
              }

              /*-----------     gem    ---------------*/
              else{
                doAvailableCountValidate(integerValue: integerValue, availableCount: availableCount);
              }
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

  void doAvailableCountValidate({required int integerValue, required int availableCount}){
    if(integerValue > availableCount){
      print('integerValue : $integerValue || availableCount : $availableCount');
      simpleDialogBox(context: context, title: 'Alert', message: 'The maximum allowable value is $availableCount. Please enter a value less than or equal to $availableCount.');
      widget.configPvd.updateObjectCount(widget.object.objectId, availableCount.toString());
    }else{
      widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
    }
  }

  void validateObjectForEcoGem({required int integerValue, required int maxAllowableCount}){
    if(integerValue > maxAllowableCount){
      simpleDialogBox(context: context, title: 'Alert', message: 'Only $maxAllowableCount ${widget.object.objectName} should be connect with ${widget.configPvd.masterData['deviceName']}.');
      widget.configPvd.updateObjectCount(widget.object.objectId, maxAllowableCount.toString());
    }else{
      widget.configPvd.updateObjectCount(widget.object.objectId, integerValue.toString());
    }
  }

  void validateAndUpdateObjectCount(DeviceObjectModel object,int newCount){
    List<DeviceObjectModel> availableObject = widget.configPvd.listOfGeneratedObject.where((available) => (available.objectId == object.objectId)).toList();
    if(availableObject.length >= newCount){
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
    if(focus == false){
      myController.text = widget.initialValue;
    }
    if(!editable()){
      return const Text('Limit reached');
    }
    bool themeMode = Theme.of(context).brightness == Brightness.light;
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
          maxLength: 3,
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

  bool editable(){
    bool visible = true;
    if(widget.object.type == '1,2'){
      if(balanceCountForRelayLatch(widget.configPvd) == 0 && ['', '0'].contains(widget.object.count)){
        visible = false;
      }
    }else if(widget.object.type != '-'){
      if(balanceCountForInputType(int.parse(widget.object.type), widget.configPvd) == 0 && ['', '0'].contains(widget.object.count)){
        visible = false;
      }
    }
    if(widget.object.objectId == AppConstants.pumpObjectId && AppConstants.ecoGemModelList.contains(widget.configPvd.masterData['modelId'])){
      visible = true;
    }
    return visible;
  }

}