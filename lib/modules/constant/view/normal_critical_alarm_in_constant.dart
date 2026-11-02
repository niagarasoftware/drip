import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/constant/model/alarm_in_constant_model.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';

import '../../../StateManagement/overall_use.dart';
import '../state_management/constant_provider.dart';
import '../widget/find_suitable_widget.dart';

class NormalCriticalInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  const NormalCriticalInConstant({super.key, required this.constPvd, required this.overAllPvd});

  @override
  State<NormalCriticalInConstant> createState() => _NormalCriticalInConstantState();
}

class _NormalCriticalInConstantState extends State<NormalCriticalInConstant> {
  double cellWidth = 180;
  ValueNotifier<int> selectedIrrigationLine = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isGem = AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']);
    bool isNova = AppConstants.ecoGemModelList.contains(widget.constPvd.userData['modelId']);
    
    List<ConstantSettingModel> visibleSettings = widget.constPvd.defaultNormalCriticalAlarmSetting.where((defaultSetting) {
      bool display = isGem ? defaultSetting.gemDisplay : defaultSetting.ecoGemDisplay;
      if (isNova && display) {
        String titleLower = defaultSetting.title.toLowerCase();
        if (titleLower.contains('alarm on status') ||
            titleLower.contains('auto reset') ||
            titleLower.contains('reset after irrigation') ||
            titleLower.contains('active')) {
          display = false;
        }
      }
      return display;
    }).toList();

    double minWidth = (cellWidth * 1) + (visibleSettings.length * cellWidth) + 50;
    Color borderColor = const Color(0xffE1E2E3);
    return Column(
      children: [
        getIrrigationLine(),
        Expanded(
          child: AnimatedBuilder(
              animation: selectedIrrigationLine,
              builder: (context, child){
                return DataTable2(
                    border: TableBorder(
                      top: BorderSide(color: borderColor, width: 1),
                      bottom: BorderSide(color: borderColor, width: 1),
                      left: BorderSide(color: borderColor, width: 1),
                      right: BorderSide(color: borderColor, width: 1),
                    ),
                    minWidth: minWidth,
                    fixedLeftColumns: minWidth < screenWidth ? 0 : 1,
                    columns: [
                      DataColumn2(
                          headingRowAlignment: MainAxisAlignment.center,
                          fixedWidth: cellWidth,
                          label: Text('Alarm', style: Theme.of(context).textTheme.labelLarge,textAlign: TextAlign.center, softWrap: true)
                      ),
                      ...visibleSettings.map((defaultSetting) {
                        return DataColumn2(
                            headingRowAlignment: MainAxisAlignment.center,
                            fixedWidth: cellWidth,
                            label: Text(defaultSetting.title, style: Theme.of(context).textTheme.labelLarge,textAlign: TextAlign.center, softWrap: true,)
                        );
                      }),
                    ],
                    rows: List.generate(widget.constPvd.normalCriticalAlarm[selectedIrrigationLine.value].normal.length, (row){
                      AlarmInConstantModel normalAlarm = widget.constPvd.normalCriticalAlarm[selectedIrrigationLine.value].normal[row];
                      AlarmInConstantModel criticalAlarm = widget.constPvd.normalCriticalAlarm[selectedIrrigationLine.value].critical[row];
                      return DataRow2(
                          specificRowHeight: AppConstants.ecoGemModelList.contains(widget.constPvd.userData['modelId']) ? 50 : 100,
                          color: WidgetStatePropertyAll(
                            row.isOdd ? Colors.white : const Color(0xffF8F8F8),
                          ),
                          cells: [
                            DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Center(child: Text(normalAlarm.title, textAlign: TextAlign.center, style: TextStyle(color: Colors.orange.shade500),)),
                                    if(!AppConstants.ecoGemModelList.contains(widget.constPvd.userData['modelId']))
                                      Center(child: Text(normalAlarm.title, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade500),)),
                                  ],
                                )
                            ),
                            for(var index = 0;index < widget.constPvd.defaultNormalCriticalAlarmSetting.length;index++)
                              if(visibleSettings.contains(widget.constPvd.defaultNormalCriticalAlarmSetting[index]))
                                DataCell(
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        if (isNova && widget.constPvd.defaultNormalCriticalAlarmSetting[index].title.toLowerCase().contains('scan time') && !(normalAlarm.title.toLowerCase().contains('low flow') || normalAlarm.title.toLowerCase().contains('high flow') || normalAlarm.title.toLowerCase().contains('no flow')))
                                          SizedBox(height: 40, width: cellWidth, child: const Center(child: Text('-')))
                                        else
                                          AnimatedBuilder(
                                              animation: normalAlarm.setting[index].value,
                                              builder: (context, child){
                                                return SizedBox(
                                                  height: 40,
                                                  width: cellWidth,
                                                  child: FindSuitableWidget(
                                                    constantSettingModel: normalAlarm.setting[index],
                                                    onUpdate: (value){
                                                      normalAlarm.setting[index].value.value = value;
                                                      if(normalAlarm.setting[index].common != null){
                                                        criticalAlarm.setting[index].value.value = value;
                                                      }
                                                    },
                                                    onOk: (){
                                                      normalAlarm.setting[index].value.value = widget.overAllPvd.getTime();
                                                      if(normalAlarm.setting[index].common != null){
                                                        criticalAlarm.setting[index].value.value = widget.overAllPvd.getTime();
                                                      }
                                                      Navigator.pop(context);
                                                    },
                                                    popUpItemModelList: normalAlarm.setting[index].sNo == 2 ? widget.constPvd.alarmOnStatus : widget.constPvd.alarmResetAfterIrrigation,
                                                  ),
                                                );
                                              }
                                          ),
                                        if(criticalAlarm.setting[index].common == null && !AppConstants.ecoGemModelList.contains(widget.constPvd.userData['modelId']))
                                          AnimatedBuilder(
                                              animation: criticalAlarm.setting[index].value,
                                              builder: (context, child){
                                                return SizedBox(
                                                  height: 40,
                                                  width: cellWidth,
                                                  child: FindSuitableWidget(
                                                    constantSettingModel: criticalAlarm.setting[index],
                                                    onUpdate: (value){
                                                      criticalAlarm.setting[index].value.value = value;
                                                    },
                                                    onOk: (){
                                                      criticalAlarm.setting[index].value.value = widget.overAllPvd.getTime();
                                                      Navigator.pop(context);
                                                    },
                                                    popUpItemModelList: criticalAlarm.setting[index].sNo == 2 ? widget.constPvd.alarmOnStatus : widget.constPvd.alarmResetAfterIrrigation,
                                                  ),
                                                );
                                              }
                                          ),
                                      ],
                                    )
                                )
                          ]
                      );
                    })
                );
              }
          ),
        )

      ],
    );
  }

  Widget getIrrigationLine(){
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for(var line = 0;line < widget.constPvd.normalCriticalAlarm.length;line++)
                AnimatedBuilder(
                    animation: selectedIrrigationLine,
                    builder: (context, child){
                      return InkWell(
                        onTap: (){
                          selectedIrrigationLine.value = line;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          padding: EdgeInsets.symmetric(horizontal: 15,vertical: selectedIrrigationLine.value == line ? 12 :10),
                          decoration: BoxDecoration(
                              border: const Border(top: BorderSide(width: 0.5), left: BorderSide(width: 0.5), right: BorderSide(width: 0.5)),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                              color: selectedIrrigationLine.value == line ? Theme.of(context).primaryColor : Colors.grey.shade100
                          ),
                          child: Text(widget.constPvd.normalCriticalAlarm[line].name, style: TextStyle(color: selectedIrrigationLine.value == line ? Colors.white : Colors.black, fontSize: 13),),
                        ),
                      );
                    }
                )

            ],
          ),
        ),
        Container(
          width: double.infinity,
          height: 3,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 10,)
      ],
    );
  }
}
