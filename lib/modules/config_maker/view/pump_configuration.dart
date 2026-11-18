import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/source_configuration.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../Constants/properties.dart';
import '../model/pump_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/custom_drop_down_button.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';

class PumpConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const PumpConfiguration({super.key, required this.configPvd});

  @override
  State<PumpConfiguration> createState() => _PumpConfigurationState();
}

class _PumpConfigurationState extends State<PumpConfiguration> {
  List<int> pumpModelList = [5, 6, 7, 8, 9, 10];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.configPvd.updateFloatForPump();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(builder: (context, constraint){
        double ratio = constraint.maxWidth < 500 ? 0.6 : 1.0;
        return SizedBox(
          width: constraint.maxWidth,
          height: constraint.maxHeight,
          child:  SingleChildScrollView(
            child: Column(
              children: [
                ResponsiveGridList(
                  horizontalGridMargin: 0,
                  verticalGridMargin: 10,
                  minItemWidth: 500,
                  shrinkWrap: true,
                  listViewBuilderOptions: ListViewBuilderOptions(
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                  children: [
                    for(var pump in widget.configPvd.pump)
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            boxShadow: AppProperties.customBoxShadowLiteTheme
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IntrinsicWidth(
                              stepWidth: 330,
                              stepHeight: 40,
                              child: ListTile(
                                leading: SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_5.svg', color: Colors.black,),
                                title: Text(pump.commonDetails.name!),
                                subtitle: const Text('Select pump mode', style: TextStyle(fontWeight: FontWeight.w100, fontSize: 10),),

                                trailing: !pumpModelList.contains(widget.configPvd.masterData['modelId']) ? IntrinsicWidth(
                                  child: CustomDropDownButton(
                                      value: getPumpTypeCodeToString(pump.pumpType),
                                      list: const ['source', 'irrigation', 'aerator'],
                                      onChanged: (value){
                                        setState(() {
                                          for(var line in widget.configPvd.line){
                                            if(value == 'source'){
                                              if(line.irrigationPump.contains(pump.commonDetails.sNo)){
                                                line.irrigationPump.remove(pump.commonDetails.sNo);
                                              }
                                            }else{
                                              if(line.sourcePump.contains(pump.commonDetails.sNo)){
                                                line.sourcePump.remove(pump.commonDetails.sNo);
                                              }
                                            }

                                          }

                                          pump.pumpType = getPumpTypeStringToCode(value!);
                                        });
                                      }
                                  ),
                                ) : null,
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: Stack(
                                children: [
                                  SvgPicture.asset(
                                    'assets/Images/Source/pump_1.svg',
                                    width: 120,
                                    height: 120,
                                  ),
                                  ...getWaterMeterAndPressure(
                                      pump.pressureIn,
                                      pump.waterMeter,
                                    widget.configPvd
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Wrap(
                                spacing: 30,
                                runSpacing: 20,
                                children: [
                                  for(var mode in [1,2,3])
                                    getWaterMeterAndPressureSelection(pump, mode),
                                  for(var mode in [1,2,3,4])
                                    getFloatSelection(pump, mode),
                                  for(var mode in [1,2])
                                    getLevelSelection(pump, mode)
                                ],
                              ),
                            ),
                            const SizedBox(height: 40,)
                          ],
                        ),
                      )
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget getWaterMeterAndPressureSelection(PumpModel currentPump, int mode){
    int objectId = mode == 1 ? 24 : mode == 2 ? 24 : 22;
    String objectName = mode == 1 ? 'PressureIn' : mode == 2 ? 'PressureOut' : 'Water Meter';
    double currentSno = mode == 1 ? currentPump.pressureIn : mode == 2 ? currentPump.pressureOut : currentPump.waterMeter;
    List<double> validateSensorFromOtherSource = [];
    for(var pump in widget.configPvd.pump){
      if(pump.commonDetails.sNo != currentPump.commonDetails.sNo){
        validateSensorFromOtherSource.add(pump.lowerLevel);
        validateSensorFromOtherSource.add(pump.waterMeter);
        validateSensorFromOtherSource.add(pump.pressureIn);
        validateSensorFromOtherSource.add(pump.pressureOut);
      }else{
        validateSensorFromOtherSource.add(mode == 1 ? pump.pressureOut : pump.pressureIn);
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).primaryColorLight.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg', color: Colors.black,),
          const SizedBox(width: 20,),
          Text('$objectName : ', style: AppProperties.listTileBlackBoldStyle,),
          Center(
            child: Text(currentSno == 0.0 ? '-' : getObjectName(currentSno, widget.configPvd).name!, style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold),),
          ),
          IconButton(
              onPressed: (){
                setState(() {
                  widget.configPvd.selectedSno = currentSno;
                });
                selectionDialogBox(
                    context: context,
                    title: 'Select $objectName',
                    singleSelection: true,
                    listOfObject: widget.configPvd.listOfGeneratedObject.where((object) => (object.objectId == objectId && !validateSensorFromOtherSource.contains(object.sNo))).toList(),
                    onPressed: (){
                      setState(() {
                        if(mode == 1){
                          currentPump.pressureIn = widget.configPvd.selectedSno;
                        }else if(mode == 2){
                          currentPump.pressureOut = widget.configPvd.selectedSno;
                        }else{
                          currentPump.waterMeter = widget.configPvd.selectedSno;
                        }
                        widget.configPvd.selectedSno = 0.0;
                      });
                      Navigator.pop(context);
                    }
                );
              },
              icon: Icon(Icons.touch_app, color: Theme.of(context).primaryColor, size: 20,)
          )
        ],
      ),
    );
  }
  
  Widget getLevelSelection(PumpModel currentPump, int mode){
    int objectId = AppConstants.levelObjectId;
    String objectName = mode == 1 ? 'Lower Level' : 'Upper Level';
    double currentSno = mode == 1 ? currentPump.lowerLevel : currentPump.upperLevel;
    List<double> sensorToDisplay = [];
    for(var src in widget.configPvd.source){
      if(mode == 1){
        if(src.outletPump.contains(currentPump.commonDetails.sNo) && ![null, 0.0].contains(src.level)){
          sensorToDisplay.add(src.level);
        }
      }else{
        if(src.inletPump.contains(currentPump.commonDetails.sNo) && ![null, 0.0].contains(src.level)){
          sensorToDisplay.add(src.level);
        }
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).primaryColorLight.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg', color: Colors.black,),
          const SizedBox(width: 20,),
          Text('$objectName : ', style: AppProperties.listTileBlackBoldStyle,),
          Center(
            child: Text(currentSno == 0.0 ? '-' : getObjectName(currentSno, widget.configPvd).name!, style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold),),
          ),
          IconButton(
              onPressed: (){
                setState(() {
                  widget.configPvd.selectedSno = currentSno;
                });
                selectionDialogBox(
                    context: context,
                    title: 'Select $objectName',
                    singleSelection: true,
                    listOfObject: widget.configPvd.listOfGeneratedObject.where((object) => (object.objectId == objectId && sensorToDisplay.contains(object.sNo))).toList(),
                    onPressed: (){
                      setState(() {
                        if(mode == 1){
                          currentPump.lowerLevel = widget.configPvd.selectedSno;
                        }else{
                          currentPump.upperLevel = widget.configPvd.selectedSno;
                        }
                        widget.configPvd.selectedSno = 0.0;
                      });
                      Navigator.pop(context);
                    }
                );
              },
              icon: Icon(Icons.touch_app, color: Theme.of(context).primaryColor, size: 20,)
          )
        ],
      ),
    );
  }

  Widget getFloatSelection(PumpModel currentPump, int mode){
    int objectId = AppConstants.floatObjectId;
    Map<int, String> controlBy = {
      1 : 'Top Float (Sump)',
      2 : 'Bottom Float (Sump)',
      3 : 'Top Float (Tank)',
      4 : 'Bottom Float (Tank)',
    };
    Map<int, double> sNoSelection = {
      1 : currentPump.topSumpFloat,
      2 : currentPump.bottomSumpFloat,
      3 : currentPump.topTankFloat,
      4 : currentPump.bottomTankFloat,
    };
    String objectName = '${controlBy[mode]}';
    double currentSno = sNoSelection[mode]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).primaryColorLight.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg', color: Colors.black,),
          const SizedBox(width: 20,),
          Text('$objectName : ', style: AppProperties.listTileBlackBoldStyle,),
          Center(
            child: Text(currentSno == 0.0 ? '-' : getObjectName(currentSno, widget.configPvd).name!, style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold),),
          ),
          IconButton(
              onPressed: (){
                List<double> validateFloat = [];
                List<double> topTankFloatSnoForAllSource = [];
                List<double> bottomTankFloatSnoForAllSource = [];
                List<double> topSumpFloatSnoForAllSource = [];
                List<double> bottomSumpFloatSnoForAllSource = [];
                Map<int, List<double>> validateFloatAvailableInSource = {
                  1 : topSumpFloatSnoForAllSource,
                  2 : bottomSumpFloatSnoForAllSource,
                  3 : topTankFloatSnoForAllSource,
                  4 : bottomTankFloatSnoForAllSource,
                };
                for(var src in widget.configPvd.source){
                  if(src.outletPump.contains(currentPump.commonDetails.sNo)){
                    print('take outlet pump');
                    print("src : ${src.toJson()}");
                    topSumpFloatSnoForAllSource.add(src.topFloatForOutletPump);
                    bottomSumpFloatSnoForAllSource.add(src.bottomFloatForOutletPump);
                  }else if(src.inletPump.contains(currentPump.commonDetails.sNo)){
                    print('take inlet pump');
                    print("src : ${src.toJson()}");
                    topTankFloatSnoForAllSource.add(src.topFloatForInletPump);
                    bottomTankFloatSnoForAllSource.add(src.bottomFloatForInletPump);
                  }
                }
                // for(var pump in widget.configPvd.pump){
                //   if(pump.commonDetails.sNo != currentPump.commonDetails.sNo && ){
                //     Map<int, double> sNoSelectionForPumpFloat = {
                //       1 : pump.topSumpFloat,
                //       2 : pump.bottomSumpFloat,
                //       3 : pump.topTankFloat,
                //       4 : pump.bottomTankFloat,
                //     };
                //     validateFloat.add(sNoSelectionForPumpFloat[mode]!);
                //   }
                // }
                setState(() {
                  widget.configPvd.selectedSno = currentSno;
                });
                print("validateFloatAvailableInSource[mode] $mode: ${validateFloatAvailableInSource[mode]}");
                selectionDialogBox(
                    context: context,
                    title: 'Select $objectName',
                    singleSelection: true,
                    listOfObject: widget.configPvd.listOfGeneratedObject.where((object) => (object.objectId == objectId && !validateFloat.contains(object.sNo) && validateFloatAvailableInSource[mode]!.contains(object.sNo))).toList(),
                    onPressed: (){
                      setState(() {
                        if(mode == 1){
                          currentPump.topSumpFloat = widget.configPvd.selectedSno;
                        }else if(mode == 2){
                          currentPump.bottomSumpFloat = widget.configPvd.selectedSno;
                        }else if(mode == 3){
                          currentPump.topTankFloat = widget.configPvd.selectedSno;
                        }else{
                          currentPump.bottomTankFloat = widget.configPvd.selectedSno;
                        }
                        widget.configPvd.selectedSno = 0.0;
                      });
                      Navigator.pop(context);
                    }
                );
              },
              icon: Icon(Icons.touch_app, color: Theme.of(context).primaryColor, size: 20,)
          )
        ],
      ),
    );
  }
}