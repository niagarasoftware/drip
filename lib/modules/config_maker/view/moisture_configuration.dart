import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../../../Constants/dialog_boxes.dart';
import '../../../Constants/properties.dart';
import '../model/moisture_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';

class MoistureConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const MoistureConfiguration({super.key, required this.configPvd});

  @override
  State<MoistureConfiguration> createState() => _MoistureConfigurationState();
}

class _MoistureConfigurationState extends State<MoistureConfiguration> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(builder: (context, constraint){
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
                    for(var moistureSensor in widget.configPvd.moisture)
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
                              stepWidth: 300,
                              child: ListTile(
                                leading: SizedImage(
                                    imagePath: '${AppConstants.svgObjectPath}objectId_25.svg',
                                  color: Colors.black,
                                ),
                                title: Text(moistureSensor.commonDetails.name!),
                              ),
                            ),
                            // Container(
                            //   width: double.infinity,
                            //   alignment: Alignment.center,
                            //   child: Stack(
                            //     children: [
                            //       SvgPicture.asset(
                            //         'assets/Images/Source/pump_1.svg',
                            //         width: 120,
                            //         height: 120,
                            //       ),
                            //       ...getWaterMeterAndPressure(
                            //           pump.pressure,
                            //           pump.waterMeter,
                            //           widget.configPvd
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: getObject(moistureSensor: moistureSensor, list: moistureSensor.valves, objectId: AppConstants.valveObjectId),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: getObject(moistureSensor: moistureSensor, list: moistureSensor.soilTemperature, objectId: AppConstants.soilTemperatureObjectId),
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

  Widget getObject({
    required MoistureModel moistureSensor,
    required List<double> list,
    required int objectId,
}){
    String name = objectId == AppConstants.valveObjectId ? 'Valve' : 'Soil Temperature';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).primaryColorLight.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedImage(
              imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
            color: Colors.black,
          ),
          const SizedBox(width: 20,),
          Text('$name : ', style: AppProperties.listTileBlackBoldStyle,),
          Center(
            child: Text(list.isEmpty ? '-' : list.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', '), style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold),),
          ),
          IconButton(
              onPressed: (){
                setState(() {
                  widget.configPvd.listOfSelectedSno.clear();
                  widget.configPvd.listOfSelectedSno.addAll(list);
                });
                selectionDialogBox(
                    context: context,
                    title: 'Select $name',
                    singleSelection: false,
                    listOfObject: widget.configPvd.listOfGeneratedObject.where((object) => object.objectId == objectId).toList(),
                    onPressed: (){
                      setState(() {
                        widget.configPvd.updateSelectionInMoisture(moistureSensor.commonDetails.sNo!, objectId);
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
