import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../Constants/properties.dart';
import '../model/pressure_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';

class PressureConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const PressureConfiguration({super.key, required this.configPvd});

  @override
  State<PressureConfiguration> createState() => _PressureConfigurationState();
}

class _PressureConfigurationState extends State<PressureConfiguration> {
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
                    for(var ps in widget.configPvd.pressureSensor)
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
                                title: Text(ps.commonDetails.name!),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: getObject(pressureSensor: ps, objectList: ps.mainValve, objectId: AppConstants.mainValveObjectId),
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
    required PressureModel pressureSensor,
    required List<double> objectList,
    required int objectId
  }){
    String objectName = AppConstants.valveObjectId == objectId ? 'Valves' : 'Main Valves';
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
          Text('$objectName : ', style: AppProperties.listTileBlackBoldStyle,),
          Center(
            child: Text(objectList.isEmpty ? '-' : objectList.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', '), style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold),),
          ),
          IconButton(
              onPressed: (){
                setState(() {
                  widget.configPvd.listOfSelectedSno.clear();
                  widget.configPvd.listOfSelectedSno.addAll(objectList);
                });
                selectionDialogBox(
                    context: context,
                    title: 'Select $objectName',
                    singleSelection: false,
                    listOfObject: widget.configPvd.listOfGeneratedObject.where((object) => object.objectId == objectId).toList(),
                    onPressed: (){
                      setState(() {
                        widget.configPvd.updateSelectionInPressure(pressureSensor.commonDetails.sNo!, objectId);
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
