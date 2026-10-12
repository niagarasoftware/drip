import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/constant/model/object_in_constant_model.dart';
import 'package:provider/provider.dart';

import '../../../Constants/dialog_boxes.dart';
import '../../../StateManagement/overall_use.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../services/mqtt_service.dart';
import '../../../services/communication_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/environment.dart';
import '../state_management/constant_provider.dart';
import '../widget/find_suitable_widget.dart';

class FilterSiteInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  const FilterSiteInConstant({super.key, required this.constPvd, required this.overAllPvd});

  @override
  State<FilterSiteInConstant> createState() => _FilterSiteInConstantState();
}

class _FilterSiteInConstantState extends State<FilterSiteInConstant> {
  double cellWidth = 200;
  MqttService mqttService = MqttService();
  final Repository repository = Repository(HttpService());


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int settingLength = widget.constPvd.defaultFilterSiteSetting.where((setting) {
      if(AppConstants.gemModelList.contains(widget.constPvd.userData['modelId'])){
        return setting.gemDisplay;
      }else{
        return setting.ecoGemDisplay;
      }
    }).length;
    settingLength = settingLength + 1;
    double minWidth = (cellWidth * 1) + (settingLength * cellWidth) + 50;
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
        DataColumn2(
            headingRowAlignment: MainAxisAlignment.center,
            fixedWidth: cellWidth,
            label: Text('Filter Site', style: Theme.of(context).textTheme.labelLarge,textAlign: TextAlign.center, softWrap: true)
        ),
        ...widget.constPvd.defaultFilterSiteSetting
            .where((defaultSetting) => AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']) ? defaultSetting.gemDisplay : defaultSetting.ecoGemDisplay)
            .map((defaultSetting) {
          return DataColumn2(
              headingRowAlignment: MainAxisAlignment.center,
              fixedWidth: cellWidth,
              label: Text(defaultSetting.title, style: Theme.of(context).textTheme.labelLarge,textAlign: TextAlign.center, softWrap: true,)
          );
        }),
        DataColumn2(
            headingRowAlignment: MainAxisAlignment.center,
            fixedWidth: cellWidth,
            label: Text('Backwash Command ono/ff', style: Theme.of(context).textTheme.labelLarge,textAlign: TextAlign.center, softWrap: true)
        ),
      ],
      rows: List.generate(widget.constPvd.filterSite.length, (row){
        ObjectInConstantModel filterSite = widget.constPvd.filterSite[row];
        return DataRow2(
            color: WidgetStatePropertyAll(
              row.isOdd ? Colors.white : const Color(0xffF8F8F8),
            ),
            cells: [
              DataCell(
                  Center(child: Text(filterSite.name.toString(), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).primaryColorLight),))
              ),
              ...filterSite.setting
                  .where((defaultSetting) => AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']) ? defaultSetting.gemDisplay : defaultSetting.ecoGemDisplay)
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
                          popUpItemModelList: widget.constPvd.filterSiteWhileBackwash,
                        );
                      },
                    )

                );
              }),
              DataCell(
                  Center(
                      child:  FilledButton.icon(
                        icon: const Icon(Icons.swipe),
                        onPressed: () async{
                          var jsonData = {
                            "4000": {"4001": filterSite.sNo.toString()}
                          };
                          String manualBackwashPayload = jsonEncode(jsonData);
                          context.read<CommunicationService>().sendCommand(serverMsg: '', payload: manualBackwashPayload);
                          var data = {
                            "userId": widget.constPvd.userData["customerId"],
                            "controllerId": widget.constPvd.userData["controllerId"],
                            "data": jsonData,
                            "messageStatus": "manual backwash on/off",
                            "createUser": widget.constPvd.userData["customerId"],
                            "hardware": jsonData,
                          };
                          await repository.sendManualOperationToServer(data);
                          loadingDialog();
                        },
                        label: const Text('Manual Backwash on/off', style: TextStyle(fontSize: 10),),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                  )
              ),
            ]
        );
      }),
    );
  }

  void loadingDialog()async{
    showDialog(
        barrierDismissible: false,
        context: context, builder: (context){
      return const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            spacing: 20,
            children: [
              CircularProgressIndicator(),
              Text('Please wait...')
            ],
          ),
        ),
      );
    }
    );
    await Future.delayed(const Duration(seconds: 2), (){
      Navigator.pop(context);
    });

    simpleDialogBox(context: context, title: 'Success', message: 'Manual Backwash on/off command Sent Successfully...');
  }

}
