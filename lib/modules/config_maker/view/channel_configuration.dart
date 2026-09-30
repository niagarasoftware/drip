import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/channel_config_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/source_configuration.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../Constants/properties.dart';
import '../model/device_object_model.dart';
import '../model/pump_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/custom_drop_down_button.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';

class ChannelConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const ChannelConfiguration({super.key, required this.configPvd});

  @override
  State<ChannelConfiguration> createState() => _ChannelConfigurationState();
}

class _ChannelConfigurationState extends State<ChannelConfiguration> {

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
                    for(var channel in widget.configPvd.channelConfig)
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            boxShadow: AppProperties.customBoxShadowLiteTheme
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Wrap(
                                spacing: 30,
                                runSpacing: 20,
                                children: [
                                  getDosingMeterSelection(channel),
                                  getObject(
                                      channel: channel,
                                      list: channel.source,
                                      objectId: AppConstants.sourceObjectId,
                                      listOfObject: widget.configPvd.source.where((src) => ([6,7].contains(src.sourceType))).map((e) => e.commonDetails).toList()
                                  ),
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

  Widget getDosingMeterSelection(ChannelConfigModel channel){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).primaryColorLight.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.dosingMeterObjectId}.svg', color: Colors.black,),
          const SizedBox(width: 20,),
          const Text('Dosing Meter : ', style: AppProperties.listTileBlackBoldStyle,),
          Center(
            child: Text(channel.dosingMeter == 0.0 ? '-' : getObjectName(channel.dosingMeter, widget.configPvd).name!, style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold),),
          ),
          IconButton(
              onPressed: (){
                setState(() {
                  widget.configPvd.selectedSno = channel.dosingMeter;
                });
                selectionDialogBox(
                    context: context,
                    title: 'Select Dosing Meter',
                    singleSelection: true,
                    listOfObject: widget.configPvd.listOfGeneratedObject.where((object) => (object.objectId == AppConstants.dosingMeterObjectId)).toList(),
                    onPressed: (){
                      setState(() {
                        channel.dosingMeter = widget.configPvd.selectedSno;
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

  Widget getObject({
    required ChannelConfigModel channel,
    required List<double> list,
    required List<DeviceObjectModel> listOfObject,
    required int objectId,
  }){
    String name = objectId == AppConstants.dosingMeterObjectId ? 'Dosing Meter' : 'Fertilizer Tank';
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
            child: Text(list.isEmpty ? '-' : list.map((sNo) => getObjectName(sNo, widget.configPvd).name!).join(', '), style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold),),
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
                    listOfObject: listOfObject,
                    onPressed: (){
                      setState(() {
                        widget.configPvd.updateSelectionInChannel(channel.commonDetails.sNo!, objectId);
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