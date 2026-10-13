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
  final lowerTitle = title.toLowerCase();
  IconData iconData = Icons.info_outline_rounded;
  Color iconColor = Theme.of(context).primaryColor;
  Color iconBgColor = Theme.of(context).primaryColor.withOpacity(0.1);

  if (lowerTitle.contains('success')) {
    iconData = Icons.check_circle_rounded;
    iconColor = Colors.teal.shade700;
    iconBgColor = Colors.teal.shade50;
  } else if (lowerTitle.contains('failed') || lowerTitle.contains('error')) {
    iconData = Icons.error_outline_rounded;
    iconColor = Colors.red.shade600;
    iconBgColor = Colors.red.shade50;
  } else if (lowerTitle.contains('alert') || lowerTitle.contains('warning')) {
    iconData = Icons.warning_amber_rounded;
    iconColor = Colors.amber.shade800;
    iconBgColor = Colors.amber.shade50;
  }

  showDialog(
      useRootNavigator: true,
      context: context,
      builder: (context){
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xff1E293B),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: content ?? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/Images/Png/no_data.png',
                    width: 90,
                    height: 90,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.folder_open_rounded,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xff475467),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if(actionButton != null)
              ...actionButton
            else
              const CustomMaterialButton()
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
              backgroundColor: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.touch_app_rounded,
                      color: Colors.orange.shade800,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xff1E293B),
                      ),
                    ),
                  ),
                  if(!singleSelection)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: configPvd.rangeMode,
                            activeColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (value){
                              configPvd.updateRangeMode(value!);
                            },
                          ),
                          const Text(
                            'Range Mode',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xff334155)),
                          )
                        ],
                      ),
                    ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width >= 500 ? 500 : double.infinity,
                height: 350,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
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
                        final isSelected = singleSelection
                            ? configPvd.selectedSno == object.sNo
                            : configPvd.listOfSelectedSno.contains(object.sNo);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade100,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                                  width: 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Theme.of(context).primaryColor.withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(Icons.check_circle, size: 16, color: Colors.white),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    object.name!,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.white : const Color(0xff334155),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              actions: [
                CustomMaterialButton(
                  title: 'Apply',
                  onPressed: onPressed,
                )
              ],
            );
          },
        );
      }
  );
}
