import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';

import '../modules/config_maker/model/device_object_model.dart';
import '../modules/config_maker/state_management/config_maker_provider.dart';
import '../Widgets/custom_buttons.dart';


void simpleDialogBox({
  required BuildContext context,
  required String title,
  required String message,
  Widget? content,
  List<Widget>? actionButton,
}){
  showDialog(
      useRootNavigator: true,
      context: context,
      builder: (context){
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0)
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: content ?? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Image.asset('assets/Images/Png/no_data.png'),
              ),
              SizedBox(height: 10,),
              Text(
                message,
                style: const TextStyle(fontSize: 16, color: Color(0xff727272)),
              ),
            ],
          ),
          actions: [
            if(actionButton != null)
              ...actionButton
            else
              CustomMaterialButton()
          ],
        );
      }
  );
}

void selectionDialogBox({
  required BuildContext context,
  required String title,
  required bool singleSelection,
  required void Function()? onPressed,
  required List<DeviceObjectModel> listOfObject,
}){
  print("selectionDialogBox listOfObject  ===== ${listOfObject.map((object) => '${object.name}(${object.controllerId})').toList()}");
  showDialog(
      context: context,
      builder: (context){
        return Consumer(
          builder: (BuildContext context, ConfigMakerProvider configPvd, Widget? child) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.touch_app,
                    color: Colors.orange,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 20,),
                  if(!singleSelection)
                    Row(
                    spacing: 10,
                    children: [
                      Checkbox(
                          value: configPvd.rangeMode,
                          onChanged: (value){
                            configPvd.updateRangeMode(value!);
                          }
                      ),
                      const Text('Range Mode')
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: double.infinity  > 500 ? 500 : double.infinity,
                height: 350,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: listOfObject
                        .where((object) {
                          if(AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId']) && object.objectId == AppConstants.pumpObjectId){
                            return true;
                          }else{
                            if([AppConstants.fertilizerSiteObjectId, AppConstants.filterSiteObjectId, AppConstants.sourceObjectId].contains(object.objectId)){
                              return true;
                            }
                            return object.controllerId != null;
                          }
                        }).map((object){
                      return InkWell(
                        onTap: (){
                          if(!singleSelection){
                            if(configPvd.rangeMode){
                              List<double> list = listOfObject.map((object) => object.sNo!).toList();
                              configPvd.updateListOfSelectedSnoWhenRangeMode(list, list.indexOf(object.sNo!));
                            }else{
                              configPvd.updateListOfSelectedSno(object.sNo!);
                            }
                          }else{
                            configPvd.updateSelectedSno(object.sNo!);
                          }
                        },
                        child: IntrinsicWidth(
                          child: Container(
                            // width: 100,
                            padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 6),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: (singleSelection ? configPvd.selectedSno == object.sNo : configPvd.listOfSelectedSno.contains(object.sNo))
                                    ? Colors.green.shade300
                                    : Colors.grey.shade100
                            ),
                            child: Center(
                              child: Text(object.name!,style: AppProperties.listTileBlackBoldStyle,),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                CustomMaterialButton(
                  onPressed: onPressed,
                )
              ],
            );
          },
        );
      }
  );
}
