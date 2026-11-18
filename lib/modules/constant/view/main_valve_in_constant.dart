import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/constant/model/object_in_constant_model.dart';

import '../../../StateManagement/overall_use.dart';
import '../state_management/constant_provider.dart';
import '../widget/find_suitable_widget.dart';

class MainValveInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  const MainValveInConstant({super.key, required this.constPvd, required this.overAllPvd});

  @override
  State<MainValveInConstant> createState() => _MainValveInConstantState();
}

class _MainValveInConstantState extends State<MainValveInConstant> {
  double cellWidth = 180;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double minWidth = (cellWidth * 4) + (widget.constPvd.defaultMainValveSetting.length * cellWidth) + 50;
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
        ...['Main Valve', 'Location', 'Device', 'Connection No'].map((title) {
          return DataColumn2(
              headingRowAlignment: MainAxisAlignment.center,
              fixedWidth: cellWidth,
              label: Text(title, style: Theme.of(context).textTheme.labelLarge,textAlign: TextAlign.center, softWrap: true)
          );
        }),
        ...widget.constPvd.defaultMainValveSetting.map((defaultSetting) {
          return DataColumn2(
              headingRowAlignment: MainAxisAlignment.center,
              fixedWidth: cellWidth,
              label: Text(defaultSetting.title, style: Theme.of(context).textTheme.labelLarge,textAlign: TextAlign.center, softWrap: true,)
          );
        }),
      ],
      rows: List.generate(widget.constPvd.mainValve.length, (row){
        ObjectInConstantModel mainValve = widget.constPvd.mainValve[row];
        return DataRow2(
            color: WidgetStatePropertyAll(
              row.isOdd ? Colors.white : const Color(0xffF8F8F8),
            ),
            cells: [
              DataCell(
                  Center(child: Text(mainValve.name.toString(), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).primaryColorLight),))
              ),
              DataCell(
                  Center(child: Text(widget.constPvd.getName(mainValve.location),textAlign: TextAlign.center,))
              ),
              DataCell(
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(widget.constPvd.getDeviceDetails(key: 'deviceName', controllerId: mainValve.controllerId!),textAlign: TextAlign.center, softWrap: true, style: TextStyle(color: Theme.of(context).primaryColorLight),),
                        Text(widget.constPvd.getDeviceDetails(key: 'deviceId', controllerId: mainValve.controllerId!), style: TextStyle(fontWeight: FontWeight.w100, color: Colors.grey.shade700) ),
                      ],
                    ),
                  )
              ),
              DataCell(
                  Center(
                    child: Text('${mainValve.connectionNo}',textAlign: TextAlign.center, softWrap: true, ),
                  )
              ),
              ...mainValve.setting.map((setting) {
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
                          popUpItemModelList: widget.constPvd.mainValveMode,
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
