import 'package:flutter/material.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../../../Constants/dialog_boxes.dart';
import '../../../Constants/properties.dart';
import '../model/moisture_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';

class EcConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const EcConfiguration({super.key, required this.configPvd});

  @override
  State<EcConfiguration> createState() => _EcConfigurationState();
}

class _EcConfigurationState extends State<EcConfiguration> {
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
                    for(var ecSensor = 0; ecSensor < widget.configPvd.ec.length;ecSensor++)
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
                                  imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.ecObjectId}.svg',
                                  color: Colors.black,
                                ),
                                title: Text(widget.configPvd.ec[ecSensor].name!),
                              ),
                            ),
                            ListTile(
                              title: const Text('Ec Controller'),
                              trailing: IntrinsicWidth(
                                child: PopupMenuButton<int>(
                                  child: Row(
                                    spacing: 10,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      widget.configPvd.ec[ecSensor].ecControllerId == 0
                                          ? const Text(' - ')
                                          : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(widget.configPvd.listOfDeviceModel.firstWhere((node) => node.controllerId == widget.configPvd.ec[ecSensor].ecControllerId).deviceName),
                                          Text(widget.configPvd.listOfDeviceModel.firstWhere((node) => node.controllerId == widget.configPvd.ec[ecSensor].ecControllerId).deviceId, style: const TextStyle(fontSize: 10, color: Colors.black45),),
                                        ],
                                      ),
                                      const Icon(Icons.arrow_drop_down_circle)
                                    ],
                                  ),
                                  onSelected: (value){
                                    setState(() {
                                      for(var node in widget.configPvd.listOfDeviceModel){
                                        if(node.controllerId == widget.configPvd.ec[ecSensor].ecControllerId){
                                          node.masterId = null;
                                        }
                                        if(value == node.controllerId){
                                          node.masterId = widget.configPvd.masterData['controllerId'];
                                        }
                                      }
                                      widget.configPvd.ec[ecSensor].ecControllerId = value;
                                    });
                                  },
                                    itemBuilder: (context){
                                      return [
                                        const PopupMenuItem(
                                            value: 0,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('-'),
                                                Text('', style: TextStyle(fontSize: 10, color: Colors.black45),),
                                              ],
                                            )
                                        ),
                                        for(var node in widget.configPvd.listOfDeviceModel.where((node) {
                                          if(AppConstants.ecModel.contains(node.modelId)){
                                            bool showNode = true;
                                            for(var ec in widget.configPvd.ec){
                                              if(ec.sNo != widget.configPvd.ec[ecSensor].sNo){
                                                if(ec.ecControllerId == node.controllerId){
                                                  showNode = false;
                                                }
                                              }
                                            }
                                            return showNode;
                                          }else{
                                            return false;
                                          }
                                        }))
                                            PopupMenuItem(
                                              value: node.controllerId,
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(node.deviceName),
                                                    Text(node.deviceId, style: const TextStyle(fontSize: 10, color: Colors.black45),),
                                                  ],
                                                )
                                            )
                                      ];
                                    },
                                ),
                              ),
                            )
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
}