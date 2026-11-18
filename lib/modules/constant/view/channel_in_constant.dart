import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/constant/model/object_in_constant_model.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../../../StateManagement/overall_use.dart';
import '../state_management/constant_provider.dart';
import '../widget/find_suitable_widget.dart';

class ChannelInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  const ChannelInConstant({super.key, required this.constPvd, required this.overAllPvd});

  @override
  State<ChannelInConstant> createState() => _ChannelInConstantState();
}

class _ChannelInConstantState extends State<ChannelInConstant> {
  double cellWidth = 180;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int settingLength = widget.constPvd.defaultChannelSetting.where((setting) {
      if(AppConstants.gemModelList.contains(widget.constPvd.userData['modelId'])){
        return setting.gemDisplay;
      }else{
        return setting.ecoGemDisplay;
      }
    }).length;
    double minWidth = (cellWidth * 4) + (settingLength * cellWidth) + 50;
    Color borderColor = const Color(0xffE1E2E3);
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
        ...['Channel', 'Location', 'Device', 'Connection No'].map((title) {
          return DataColumn2(
              headingRowAlignment: MainAxisAlignment.center,
              fixedWidth: cellWidth,
              label: Text(title, style: Theme.of(context).textTheme.labelLarge,textAlign: TextAlign.center, softWrap: true)
          );
        }),
        ...widget.constPvd.defaultChannelSetting
            .where((defaultSetting) => AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']) ? defaultSetting.gemDisplay : defaultSetting.ecoGemPayload)
            .map((defaultSetting) {
          return DataColumn2(
              headingRowAlignment: MainAxisAlignment.center,
              fixedWidth: cellWidth,
              label: Text(defaultSetting.title, style: Theme.of(context).textTheme.labelLarge,textAlign: TextAlign.center, softWrap: true,)
          );
        }),
      ],
      rows: List.generate(widget.constPvd.channel.length, (row){
        ObjectInConstantModel channel = widget.constPvd.channel[row];
        return DataRow2(
            color: WidgetStatePropertyAll(
              row.isOdd ? Colors.white : const Color(0xffF8F8F8),
            ),
            cells: [
              DataCell(
                  Center(child: Text(channel.name.toString(), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).primaryColorLight),))
              ),
              DataCell(
                  Center(child: Text(widget.constPvd.getName(channel.location),textAlign: TextAlign.center,))
              ),
              DataCell(
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(widget.constPvd.getDeviceDetails(key: 'deviceName', controllerId: channel.controllerId),textAlign: TextAlign.center, softWrap: true, style: TextStyle(color: Theme.of(context).primaryColorLight),),
                        Text(widget.constPvd.getDeviceDetails(key: 'deviceId', controllerId: channel.controllerId), style: TextStyle(fontWeight: FontWeight.w100, color: Colors.grey.shade700) ),
                      ],
                    ),
                  )
              ),
              DataCell(
                  Center(
                    child: Text('${channel.connectionNo}',textAlign: TextAlign.center, softWrap: true, ),
                  )
              ),
              ...channel.setting
                  .where((defaultSetting) => AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']) ? defaultSetting.gemDisplay : defaultSetting.ecoGemPayload)
                  .map((setting) {
                return DataCell(
                    AnimatedBuilder(
                      animation: setting.value,
                      builder: (context, child){
                        return FindSuitableWidget(
                          constantSettingModel: setting,
                          onUpdate: (value){
                            setting.value.value = value;
                          },
                          onOk: (){
                            setting.value.value = widget.overAllPvd.getTime();
                            Navigator.pop(context);
                          },
                          popUpItemModelList: widget.constPvd.fertilizerChannelMode,
                        );
                      },
                    )

                );
              }),
            ]
        );
      }),

    );

  }
}
