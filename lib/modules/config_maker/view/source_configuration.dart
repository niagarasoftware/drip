import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/device_object_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:oro_drip_irrigation/utils/Theme/smart_comm_theme.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../Constants/properties.dart';
import '../model/source_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/custom_drop_down_button.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';

class SourceConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const SourceConfiguration({super.key, required this.configPvd});

  @override
  State<SourceConfiguration> createState() => _SourceConfigurationState();
}

class _SourceConfigurationState extends State<SourceConfiguration> {

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
                    for(var source in widget.configPvd.source)
                      if(AppConstants.aquacultureModelList.contains(widget.configPvd.masterData['modelId']))
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                              boxShadow: AppProperties.customBoxShadowLiteTheme
                          ),
                          child: Column(
                            children: [
                              Text('${source.commonDetails.name}', style: TextStyle(color: primary, fontSize: 14),),
                              SingleChildScrollView(
                                child: Row(
                                  children: List.generate(source.aerator.length, (index){
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      spacing: 10,
                                      children: [
                                        Image.asset(
                                          'assets/png/aerators_o.png',
                                          height: 100,
                                          width: 100,
                                        ),
                                        Text(getObjectName(source.aerator[index], widget.configPvd).name!,style: AppProperties.listTileBlackBoldStyle,)                                      ],
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Theme.of(context).primaryColorLight.withValues(alpha: 0.1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedImage(imagePath: 'assets/png/aerators_o.png', color: Colors.black,),
                                    const SizedBox(width: 20,),
                                    const Text('Aerators : ', style: AppProperties.listTileBlackBoldStyle,),
                                    Expanded(
                                      child: Center(
                                        child: Text(source.valves.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', '), style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),),
                                      ),
                                    ),
                                    IconButton(
                                        onPressed: (){
                                          setState(() {
                                            widget.configPvd.listOfSelectedSno.clear();
                                            widget.configPvd.listOfSelectedSno.addAll(source.valves);
                                          });
                                          selectionDialogBox(
                                              context: context,
                                              title: 'Select Aerator',
                                              singleSelection: false,
                                              listOfObject: widget.configPvd.listOfGeneratedObject.where((object) => (object.objectId == AppConstants.pumpObjectId)).toList(),
                                              onPressed: (){
                                                setState(() {
                                                  source.aerator.clear();
                                                  source.aerator.addAll(widget.configPvd.listOfSelectedSno);
                                                  widget.configPvd.updateAssignObject(sNo: source.commonDetails.sNo!, objectId: AppConstants.pumpObjectId, listOfSerialNo: widget.configPvd.listOfSelectedSno);
                                                  widget.configPvd.listOfSelectedSno.clear();
                                                });
                                                Navigator.pop(context);
                                              }
                                          );
                                        },
                                        icon: Icon(Icons.touch_app, color: Theme.of(context).primaryColor, size: 20,)
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      else
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
                              stepWidth: 250,
                              child: ListTile(
                                leading: SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_1.svg', color: Colors.black,),
                                title: Text(source.commonDetails.name!),
                                trailing: IntrinsicWidth(
                                  child: CustomDropDownButton(
                                      value: getTankCodeToString(source.sourceType),
                                      list: const ['Tank', 'Sump', 'Well', 'Bore',
                                        'Fertilizer Source', 'Fertilizer Tank',
                                        'Others'],
                                      onChanged: (value){
                                        setState(() {
                                          source.sourceType = getTankStringToCode(value!);
                                          if([4, 5].contains(source.sourceType)){
                                            source.inletPump.clear();
                                            source.level = 0.0;
                                            source.topFloatForInletPump = 0.0;
                                            source.bottomFloatForInletPump = 0.0;
                                          }
                                        });
                                      }
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 200,
                              alignment: Alignment.center,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    if(source.inletPump.isNotEmpty)
                                      ...[
                                        if(source.inletPump.length == 1)
                                          singlePump(source, true, widget.configPvd)
                                        else
                                          multiplePump(source, true, widget.configPvd)
                                      ],
                                    Stack(
                                    children: [
                                        getTankImage(source, widget.configPvd),
                                        Positioned(
                                          left : 5,
                                          top: 0,
                                          child: Text(getObjectName(source.commonDetails.sNo!, widget.configPvd).name!,style: AppProperties.listTileBlackBoldStyle,),
                                        ),
                                      ],
                                    ),
                                    if(source.outletPump.isNotEmpty)
                                      ...[
                                        if(source.outletPump.length == 1)
                                          singlePump(source, false, widget.configPvd)
                                        else
                                          multiplePump(source, false, widget.configPvd)
                                      ],
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Wrap(
                                spacing: 30,
                                runSpacing: 20,
                                children: [
                                  for(var pumpMode in [1,2])
                                    ...[
                                      if(pumpMode == 1 && ![4,5].contains(source.sourceType))
                                        getPumpSelection(source, pumpMode),
                                      if(pumpMode == 2)
                                        getPumpSelection(source, pumpMode),
                                    ],
                                  if(![4,5].contains(source.sourceType) && widget.configPvd.listOfGeneratedObject.any((object) => object.objectId == AppConstants.valveObjectId))
                                    ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Theme.of(context).primaryColorLight.withValues(alpha: 0.1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.valveObjectId}.svg', color: Colors.black,),
                                            const SizedBox(width: 20,),
                                            const Text('Inlet Valve : ', style: AppProperties.listTileBlackBoldStyle,),
                                            Expanded(
                                              child: Center(
                                                child: Text(source.valves.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', '), style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),),
                                              ),
                                            ),
                                            IconButton(
                                                onPressed: (){
                                                  setState(() {
                                                    widget.configPvd.listOfSelectedSno.clear();
                                                    widget.configPvd.listOfSelectedSno.addAll(source.valves);
                                                  });
                                                  selectionDialogBox(
                                                      context: context,
                                                      title: 'Select Valve',
                                                      singleSelection: false,
                                                      listOfObject: widget.configPvd.listOfGeneratedObject.where((object) => (object.objectId == AppConstants.valveObjectId && !widget.configPvd.source.any((src) => src.outletValves.contains(object.sNo)))).toList(),
                                                      onPressed: (){
                                                        setState(() {
                                                          source.valves.clear();
                                                          source.valves.addAll(widget.configPvd.listOfSelectedSno);
                                                          widget.configPvd.updateAssignObject(sNo: source.commonDetails.sNo!, objectId: AppConstants.valveObjectId,listOfSerialNo: widget.configPvd.listOfSelectedSno);
                                                          widget.configPvd.listOfSelectedSno.clear();
                                                        });
                                                        Navigator.pop(context);
                                                      }
                                                  );
                                                },
                                                icon: Icon(Icons.touch_app, color: Theme.of(context).primaryColor, size: 20,)
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Theme.of(context).primaryColorLight.withValues(alpha: 0.1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.valveObjectId}.svg', color: Colors.black,),
                                            const SizedBox(width: 20,),
                                            const Text('Outlet Valve : ', style: AppProperties.listTileBlackBoldStyle,),
                                            Expanded(
                                              child: Center(
                                                child: Text(source.outletValves.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', '), style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),),
                                              ),
                                            ),
                                            IconButton(
                                                onPressed: (){
                                                  setState(() {
                                                    widget.configPvd.listOfSelectedSno.clear();
                                                    widget.configPvd.listOfSelectedSno.addAll(source.outletValves);
                                                  });
                                                  selectionDialogBox(
                                                      context: context,
                                                      title: 'Select Outlet Valve',
                                                      singleSelection: false,
                                                      listOfObject: widget.configPvd.listOfGeneratedObject.where((object) => (object.objectId == AppConstants.valveObjectId && !widget.configPvd.source.any((src) => src.valves.contains(object.sNo)))).toList(),
                                                      onPressed: (){
                                                        setState(() {
                                                          source.outletValves.clear();
                                                          source.outletValves.addAll(widget.configPvd.listOfSelectedSno);
                                                          widget.configPvd.updateAssignObject(sNo: source.commonDetails.sNo!, objectId: AppConstants.valveObjectId,listOfSerialNo: widget.configPvd.listOfSelectedSno);
                                                          widget.configPvd.listOfSelectedSno.clear();
                                                        });
                                                        Navigator.pop(context);
                                                      }
                                                  );
                                                },
                                                icon: Icon(Icons.touch_app, color: Theme.of(context).primaryColor, size: 20,)
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  if(![4,5].contains(source.sourceType))
                                    for(var mode in [1,2,3,4,5,6])
                                      getLevelAndFloatSelection(source, mode),
                                  if([6,7].contains(source.sourceType))
                                    ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Theme.of(context).primaryColorLight.withOpacity(0.1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.agitatorObjectId}.svg', color: Colors.black,),
                                            const SizedBox(width: 20,),
                                            const Text('Agitator : ', style: AppProperties.listTileBlackBoldStyle,),
                                            Expanded(
                                              child: Center(
                                                child: Text(source.agitator.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', '), style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),),
                                              ),
                                            ),
                                            IconButton(
                                                onPressed: (){
                                                  setState(() {
                                                    widget.configPvd.listOfSelectedSno.clear();
                                                    widget.configPvd.listOfSelectedSno.addAll(source.agitator);
                                                  });
                                                  selectionDialogBox(
                                                      context: context,
                                                      title: 'Select Agitator',
                                                      singleSelection: false,
                                                      listOfObject: widget.configPvd.listOfGeneratedObject.where((object) => (object.objectId == AppConstants.agitatorObjectId )).toList(),
                                                      onPressed: (){
                                                        setState(() {
                                                          source.agitator.clear();
                                                          source.agitator.addAll(widget.configPvd.listOfSelectedSno);
                                                          widget.configPvd.updateAssignObject(sNo: source.commonDetails.sNo!, objectId: AppConstants.agitatorObjectId,listOfSerialNo: widget.configPvd.listOfSelectedSno);
                                                          widget.configPvd.listOfSelectedSno.clear();
                                                        });
                                                        Navigator.pop(context);
                                                      }
                                                  );
                                                },
                                                icon: Icon(Icons.touch_app, color: Theme.of(context).primaryColor, size: 20,)
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                ],
                              ),
                            ),
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

  Widget getPumpSelection(SourceModel source, int pumpMode){
    List<double> currentParameter = pumpMode == 1 ? source.inletPump : source.outletPump;
    List<double> checkingParameter = pumpMode == 1 ? source.outletPump : source.inletPump;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).primaryColorLight.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_5.svg', color: Colors.black,),
          const SizedBox(width: 20,),
          Text('${pumpMode == 1 ? 'Inlet' : 'Outlet'} Pump : ', style: AppProperties.listTileBlackBoldStyle,),
          Center(
            child: Text(currentParameter.isEmpty ? '-' : currentParameter.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', '), style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold),),
          ),
          IconButton(
              onPressed: (){
                setState(() {
                  widget.configPvd.listOfSelectedSno.clear();
                  widget.configPvd.listOfSelectedSno.addAll(currentParameter);
                });
                selectionDialogBox(
                    context: context,
                    title: 'Select ${pumpMode == 1 ? 'Inlet' : 'Outlet'} Pump',
                    singleSelection: false,
                    listOfObject: widget.configPvd.listOfGeneratedObject.where((object) => (object.objectId == 5 && !checkingParameter.contains(object.sNo))).toList(),
                    onPressed: (){
                      setState(() {
                        if(pumpMode == 1){
                          source.inletPump.clear();
                          source.inletPump.addAll(widget.configPvd.listOfSelectedSno);
                        }else{
                          source.outletPump.clear();
                          source.outletPump.addAll(widget.configPvd.listOfSelectedSno);
                        }
                        widget.configPvd.listOfSelectedSno.clear();
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

  Widget getLevelAndFloatSelection(SourceModel source, int mode){
    int objectId = mode == 1 ? AppConstants.levelObjectId : mode == 6 ? AppConstants.waterMeterObjectId : AppConstants.floatObjectId;
    Map<int, String> currentObjectName = {
      1: 'Level',
      2: 'Top Float For Inlet Pumps',
      3: 'Bottom Float For Inlet Pumps',
      4: 'Top Float For Outlet Pumps',
      5: 'Bottom Float For Outlet Pumps',
      6: 'Outlet Water Meter',
    };
    Map<int, double> currentSno = {
      1: source.level,
      2: source.topFloatForInletPump,
      3: source.bottomFloatForInletPump,
      4: source.topFloatForOutletPump,
      5: source.bottomFloatForOutletPump,
      6: source.outletWaterMeter,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).primaryColorLight.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg', color: Colors.black,),
          const SizedBox(width: 20,),
          Text('${currentObjectName[mode]} : ', style: AppProperties.listTileBlackBoldStyle,),
          Center(
            child: Text(currentSno[mode] == 0.0 ? '-' : getObjectName(currentSno[mode]!, widget.configPvd).name!, style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold),),
          ),
          IconButton(
              onPressed: (){
                List<double> validateSensorFromOtherSource = [];
                for(var src in widget.configPvd.source){
                  validateSensorFromOtherSource.add(src.level);
                  validateSensorFromOtherSource.add(src.outletWaterMeter);
                  validateSensorFromOtherSource.add(src.topFloatForInletPump);
                  validateSensorFromOtherSource.add(src.bottomFloatForInletPump);
                  validateSensorFromOtherSource.add(src.topFloatForOutletPump);
                  validateSensorFromOtherSource.add(src.bottomFloatForOutletPump);
                }
                validateSensorFromOtherSource.remove(currentSno[mode]);
                setState(() {
                  widget.configPvd.selectedSno = currentSno[mode]!;
                });
                selectionDialogBox(
                    context: context,
                    title: 'Select ${currentObjectName[mode]}',
                    singleSelection: true,
                    listOfObject: widget.configPvd.listOfGeneratedObject.where((object) {
                      if(object.objectId != objectId){
                        return false;
                      }
                      if(validateSensorFromOtherSource.contains(object.sNo)){
                        return false;
                      }
                      return true;
                    }).toList(),
                    onPressed: (){
                      bool sensorRemovedInAnyPump = false;
                      double oldSensorSno = 0.0;
                      late DeviceObjectModel deviceObjectModel;
                      List<String> sensorsRemovedFromPump = [];

                      if(mode == 1){
                        oldSensorSno = source.level;
                        source.level = widget.configPvd.selectedSno;
                      }else if(mode == 2){
                        oldSensorSno = source.topFloatForInletPump;
                        source.topFloatForInletPump = widget.configPvd.selectedSno;
                      }else if(mode == 3){
                        oldSensorSno = source.bottomFloatForInletPump;
                        source.bottomFloatForInletPump = widget.configPvd.selectedSno;
                      }else if(mode == 4){
                        oldSensorSno = source.topFloatForOutletPump;
                        source.topFloatForOutletPump = widget.configPvd.selectedSno;
                      }else if(mode == 5){
                        oldSensorSno = source.bottomFloatForOutletPump;
                        source.bottomFloatForOutletPump = widget.configPvd.selectedSno;
                      }else{
                        source.outletWaterMeter = widget.configPvd.selectedSno;
                      }
                      widget.configPvd.selectedSno = 0.0;
                      setState(() {});
                      Navigator.pop(context);
                      // This is for show dialog to indicate user the remove sensor is also removed from pump configuration.
                      if(widget.configPvd.selectedSno == 0.0){
                        deviceObjectModel = widget.configPvd.listOfGeneratedObject.firstWhere((object) => object.sNo == oldSensorSno);
                        for(var pump in widget.configPvd.pump){
                          if([...source.outletPump, ...source.inletPump].contains(pump.commonDetails.sNo)){
                            if(mode == 1){
                              if(pump.lowerLevel == oldSensorSno){
                                pump.lowerLevel = 0.0;
                                sensorsRemovedFromPump.add(pump.commonDetails.name!);
                                sensorRemovedInAnyPump = true;
                              }else if(pump.upperLevel == oldSensorSno){
                                pump.upperLevel = 0.0;
                                sensorRemovedInAnyPump = true;
                                sensorsRemovedFromPump.add(pump.commonDetails.name!);
                              }
                            }else if([2,3,4,5].contains(mode)){
                              bool isFloatRemoved = false;
                              if(pump.topTankFloat == oldSensorSno){
                                pump.topTankFloat = 0.0;
                                isFloatRemoved = true;
                              }else if(pump.bottomTankFloat == oldSensorSno){
                                pump.bottomTankFloat = 0.0;
                                isFloatRemoved = true;
                              }else if(pump.topSumpFloat == oldSensorSno){
                                pump.topSumpFloat = 0.0;
                                isFloatRemoved = true;
                              }else if(pump.bottomSumpFloat == oldSensorSno){
                                pump.bottomSumpFloat = 0.0;
                                isFloatRemoved = true;
                              }
                              if(isFloatRemoved){
                                print("");
                                sensorsRemovedFromPump.add(pump.commonDetails.name!);
                                sensorRemovedInAnyPump = true;
                              }
                            }
                          }
                        }
                      }
                      setState(() {});
                      if(sensorRemovedInAnyPump){
                        simpleDialogBox(
                            context: context,
                            title: 'Alert',
                            message: 'The ${deviceObjectModel.name} is removed from ${sensorsRemovedFromPump.join(',')} in the pump configuration'
                        );
                      }
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

List<Widget> getWaterMeterAndPressure(double pressureInSno, double waterMeterSno, ConfigMakerProvider configPvd){
  return [
    if(pressureInSno != 0.0)
      Positioned(
        right: 0,
        top: 15 * configPvd.ratio,
        child: Image.asset(
            'assets/Images/Png/objectId_24.png',
          width: 30,
          height: 30,
        ),
        // child: SvgPicture.asset(
        //   '${AppConstants.svgObjectPath}objectId_24.svg',
        //   width: 30,
        //   height: 30 * configPvd.ratio,
        //   color: Colors.red,
        // ),
      ),
    if(waterMeterSno != 0.0)
      Positioned(
      right: 0,
      top: 50 * configPvd.ratio,
        child: Image.asset(
          'assets/Images/Png/objectId_22.png',
          width: 30,
          height: 30,
        ),
      // child: SvgPicture.asset(
      //   '${AppConstants.svgObjectPath}objectId_22.svg',
      //   width: 25,
      //   height: 25 * configPvd.ratio,
      //   color: Colors.blue,
      // ),
    ),
  ];
}

Widget singlePump(SourceModel source, bool fillingPump, ConfigMakerProvider configPvd, {bool dashboard = false}){
  List<double> currentParameter = fillingPump ? source.inletPump : source.outletPump;
  return Stack(
    children: [
      Positioned(
        left : fillingPump ? 40 : null,
        right : (!fillingPump && dashboard) ? 0 : (!fillingPump) ? 40 : null,
        bottom: 32 * configPvd.ratio,
        child: SvgPicture.asset(
          'assets/Images/Source/backside_pipe_1.svg',
          width: 120 ,
          height: 8.5 * configPvd.ratio,
        ),
      ),
      SvgPicture.asset(
        'assets/Images/Source/pump_1.svg',
        width: 120,
        height: 120 * configPvd.ratio,
      ),
      ...getWaterMeterAndPressure(
          configPvd.pump.firstWhere((pump) => pump.commonDetails.sNo == currentParameter[0]).pressureIn,
          configPvd.pump.firstWhere((pump) => pump.commonDetails.sNo == currentParameter[0]).waterMeter,
        configPvd
      ),
      Positioned(
        left : 5,
        top: 0,
        child: Text(getObjectName(currentParameter[0], configPvd).name!,style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),),
      )
    ],
  );
}

Widget multiplePump(SourceModel source, bool fillingPump, ConfigMakerProvider configPvd,
    {bool dashBoard = false, int? maxOutletPumpForTank}){
  List<double> currentParameter = fillingPump ? source.inletPump : source.outletPump;
  return Row(
    children: [
      for(var i = 0;i < currentParameter.length;i++)
        Stack(
          children: [
            Positioned(
              left: fillingPump ? (i == 0 ? 50 : null) : null,
              right: (!fillingPump && i == currentParameter.length -1 && !dashBoard) ? 40 : null,
              bottom: 32 * configPvd.ratio,
              child: SvgPicture.asset(
                'assets/Images/Source/backside_pipe_1.svg',
                width: 120,
                height: 8.5 * configPvd.ratio,
              ),
            ),
            SvgPicture.asset(
              'assets/Images/Source/pump_1.svg',
              width: 120,
              height: 120 * configPvd.ratio,
            ),
            ...getWaterMeterAndPressure(
                configPvd.pump.firstWhere((pump) => pump.commonDetails.sNo == currentParameter[i]).pressureIn,
                configPvd.pump.firstWhere((pump) => pump.commonDetails.sNo == currentParameter[i]).waterMeter,
              configPvd
            ),
            if(currentParameter.length > 1)
              Positioned(
              right: i == 0 ? 0 : null,
              left: i == 1 ? 0 : null,
              bottom: 16 * configPvd.ratio,
              child: SvgPicture.asset(
                'assets/Images/Source/${
                    i == 0
                        ? 'front_corner_left_radius_pipe_1'
                        : i == (currentParameter.length - 1)
                        ? 'front_corner_right_radius_pipe_1'
                        : 'backside_pipe_1'}.svg',
                width: 120,
                height: 8.5 * configPvd.ratio,
              ),
            ),
            Positioned(
              left : 5,
              top: 0,
              child: Text(getObjectName(currentParameter[i], configPvd).name!,style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),),
            )
          ],
        ),
      if(maxOutletPumpForTank != null)
        for(var i = 0;i < (maxOutletPumpForTank - currentParameter.length);i++)
          SizedBox(
            width: 94,
            height: 120 * configPvd.ratio,
            child: Stack(
              children: [
                Positioned(
                  bottom : 32 * configPvd.ratio,
                  child: SvgPicture.asset(
                    'assets/Images/Source/backside_pipe_1.svg',
                    width: 120,
                    height: 8.5 * configPvd.ratio,
                  ),
                )
              ],
            ),
          )
    ],
  );
}

Widget getTankImage(SourceModel source ,ConfigMakerProvider configPvd, {bool dashboard = false, bool inlet = true,}){
  bool levelAvailable = source.level != 0.0;
  bool topFloatAvailableForOutlet = source.topFloatForOutletPump != 0.0;
  bool bottomFloatAvailableForOutlet = source.bottomFloatForOutletPump != 0.0;
  bool topFloatAvailableForInlet = source.topFloatForInletPump != 0.0;
  bool bottomFloatAvailableForInlet = source.bottomFloatForInletPump != 0.0;
  bool outletWaterMeter = source.outletWaterMeter != 0.0;
  bool outletValve = source.outletValves.isNotEmpty;
  if(source.sourceType == 1){
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/tank_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        if(levelAvailable)
          Positioned(
            left: 52,
            bottom: 28,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.green
                ),
              ),
            ),
          ),
        if(topFloatAvailableForOutlet)
          Positioned(
            right: 40,
            bottom: 50,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 40,
            ),
          ),
        if(topFloatAvailableForInlet)
          Positioned(
            left: 40,
            bottom: 50,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 40,
            ),
          ),
        if(bottomFloatAvailableForOutlet)
          Positioned(
            right: 50,
            bottom: 25,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 70,
              height: 70,
            ),
          ),
        if(bottomFloatAvailableForInlet)
          Positioned(
            left: 50,
            bottom: 25,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 70,
              height: 70,
            ),
          ),
        if(outletWaterMeter)
          Positioned(
            right: 0,
            bottom: 20,
            child: Image.asset(
              'assets/Images/Png/objectId_${AppConstants.waterMeterObjectId}.png',
              width: 30,
              height: 30,
            ),
          )
      ],
    );
  }
  else if(source.sourceType == 2){
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/sump_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        if(levelAvailable)
          Positioned(
            left: 52,
            bottom: 35,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.green
                ),
              ),
            ),
          ),
        if(topFloatAvailableForOutlet)
          Positioned(
            right: 55,
            bottom: 55,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 30,
            ),
          ),
        if(bottomFloatAvailableForOutlet)
          Positioned(
            right: 70,
            bottom: 35,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 50,
              height: 50,
            ),
          ),
        if(outletWaterMeter)
          Positioned(
            right: 0,
            bottom: 20,
            child: Image.asset(
              'assets/Images/Png/objectId_${AppConstants.waterMeterObjectId}.png',
              width: 30,
              height: 30,
            ),
          )
      ],
    );
  }
  else if(source.sourceType == 3){
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/well_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        // if(levelAvailable || topFloatAvailable || bottomFloatAvailable)
        //   Positioned(
        //     right: 47,
        //     bottom: 20,
        //     child: SvgPicture.asset(
        //       'assets/Images/Source/water_view.svg',
        //       width: 55,
        //       height: 55,
        //     ),
        //   ),
        if(levelAvailable)
          Positioned(
            left: 45,
            bottom: 22,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.green
                ),
              ),
            ),
          ),
        if(topFloatAvailableForOutlet)
          Positioned(
            right: 55,
            bottom: 55,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 30,
            ),
          ),
        if(bottomFloatAvailableForOutlet)
          Positioned(
            right: 70,
            bottom: 35,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 50,
              height: 50,
            ),
          ),
        if(outletWaterMeter)
          Positioned(
            right: 0,
            bottom: 20,
            child: Image.asset(
              'assets/Images/Png/objectId_${AppConstants.waterMeterObjectId}.png',
              width: 30,
              height: 30,
            ),
          )
      ],
    );
  }
  else if(source.sourceType == 4){
    return SvgPicture.asset(
      'assets/Images/Source/bore_1.svg',
      width: 120,
      height: 120 * configPvd.ratio,
    );
  }
  else if(source.sourceType == 5){
    return SvgPicture.asset(
      'assets/Images/Source/pond_1.svg',
      width: 120,
      height: 120* configPvd.ratio,
    );
  }else if(source.sourceType == 6){
    return SvgPicture.asset(
      'assets/Images/Source/fertilizer_source.svg',
      width: 120,
      height: 120* configPvd.ratio,
    );
  }else{
    return SvgPicture.asset(
      'assets/Images/Source/fertilizer_tank.svg',
      width: 120,
      height: 120* configPvd.ratio,
    );
  }
}