import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/model/sequence_model.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../state_management/irrigation_program_provider.dart';

class AlarmScreen extends StatefulWidget {
  final int modelId;
  const AlarmScreen({super.key, required this.modelId});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  late IrrigationProgramMainProvider irrigationProgramMainProvider;
  late List<AlarmData> alarmList;
  final iconList = [
    MdiIcons.gaugeLow,
    MdiIcons.gaugeFull,
    MdiIcons.gaugeEmpty,
    'assets/SVGPicture/ec high.svg',
    'assets/SVGPicture/ph low.svg',
    'assets/SVGPicture/ph high.svg',
    MdiIcons.speedometerSlow,
    MdiIcons.speedometer,
    MdiIcons.powerPlugOff,
    'assets/SVGPicture/no communication.svg',
    'assets/SVGPicture/wrong feedback1.svg',
    'assets/SVGPicture/sump empty.svg',
    'assets/SVGPicture/tank full.svg',
    MdiIcons.batteryLow,
    'assets/SVGPicture/ec diff.svg',
    'assets/SVGPicture/ph-differencef.svg',
    'assets/SVGPicture/pumpoff1.svg',
    'assets/SVGPicture/pressure switch.svg',
    'assets/SVGPicture/pressure switch.svg',
  ];
  @override
  void initState() {
    // TODO: implement initState
    irrigationProgramMainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    // print("Model id in alarm screen :: ${widget.modelId}");
    if(AppConstants.gemModelList.contains(widget.modelId)) {
      alarmList = irrigationProgramMainProvider.newAlarmList!.alarmList.where((e) => e.gemDisplay).toList();
    } else {
      alarmList = irrigationProgramMainProvider.newAlarmList!.alarmList.where((e) => e.ecoGemDisplay).toList();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    irrigationProgramMainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: true);

    return Container(
      margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width * 0.025),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MaterialButton(
              // color: Colors.greenAccent.shade100,
              // minWidth: MediaQuery.of(context).size.width - 40,
              textColor: Colors.white,
              elevation: 8,
              color: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)
              ),
              onPressed: () {
                setState(() {
                  for(var i = 0; i < alarmList.length; i++) {
                    alarmList[i].value = irrigationProgramMainProvider.newAlarmList!.defaultAlarm[i].value;
                    print(irrigationProgramMainProvider.newAlarmList!.defaultAlarm[i].value);
                   /* final newIndex = irrigationProgramMainProvider.newAlarmList!.alarmList.indexWhere((e) => e.sNo == alarmList[i].sNo);
                    irrigationProgramMainProvider.newAlarmList!.alarmList[newIndex].value = irrigationProgramMainProvider.newAlarmList!.defaultAlarm[i].value;*/
                  }
                });
              },
              child: Text("Use global alarm".toUpperCase()),
            ),
          ),
          const SizedBox(height: 5,),
          Expanded(
            child: ResponsiveGridList(
              horizontalGridMargin: 20,
              verticalGridMargin: 10,
              minItemWidth: 350,
              children: [
                for(var index = 0; index < alarmList.length; index++)
                  if(AppConstants.omsGemList.contains(widget.modelId) && [1, 3].contains(alarmList[index].sNo))
                    Column(
                      children: [
                        _buildAlarmListTile(index),
                        if(index == alarmList.length - 1)
                          const SizedBox(height: 80)
                      ],
                    )
                  else if(!AppConstants.omsGemList.contains(widget.modelId))
                    Column(
                      children: [
                        _buildAlarmListTile(index),
                        if(index == alarmList.length - 1)
                          const SizedBox(height: 80)
                      ],
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmListTile(int index) {
    return  Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: AppProperties.customBoxShadowLiteTheme
      ),
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width > 1200 ? 8 : 0),
      child: ListTile(
        horizontalTitleGap: 30,
        title: Text(alarmList[index].name),
        trailing: IntrinsicWidth(
          child: Switch(
              value: alarmList[index].value,
              onChanged: (newValue) {
                setState(() {
                  final newIndex = irrigationProgramMainProvider.newAlarmList!.alarmList.indexWhere((e) => e.sNo == alarmList[index].sNo);
                  irrigationProgramMainProvider.newAlarmList!.alarmList[newIndex].value = newValue;
                });
              }
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppProperties.linearGradientLeading,
          ),
          child: iconList[alarmList.indexOf(alarmList[index])] is IconData
              ? Icon(
            iconList[alarmList.indexOf(alarmList[index])] as IconData,
            color: Colors.white,
            size: 24,
          )
              : SvgPicture.asset(
            iconList[alarmList.indexOf(alarmList[index])] as String,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
