import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/constant/state_management/constant_provider.dart';
import 'package:oro_drip_irrigation/modules/constant/widget/find_suitable_widget.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../../../StateManagement/overall_use.dart';


class GeneralInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  const GeneralInConstant({super.key, required this.constPvd, required this.overAllPvd});

  @override
  State<GeneralInConstant> createState() => _GeneralInConstantState();
}

class _GeneralInConstantState extends State<GeneralInConstant> {
  ValueNotifier<int> hoveredSno = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ResponsiveGridList(
          horizontalGridMargin: 0,
          verticalGridSpacing: 20,
          horizontalGridSpacing: 30,
          verticalGridMargin: 20,
          minItemWidth: 300,
          shrinkWrap: true,
          listViewBuilderOptions: ListViewBuilderOptions(
            physics: const NeverScrollableScrollPhysics(),
          ),
          children: widget.constPvd.general
              .where((generalSetting) => AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']) ? generalSetting.gemDisplay : generalSetting.ecoGemDisplay)
              .map((generalSetting){
            return AnimatedBuilder(
                animation: hoveredSno,
                builder: (context, child){
                  return MouseRegion(
                    onEnter: (_){
                      hoveredSno.value = generalSetting.sNo;
                    },
                    onExit: (_){
                      hoveredSno.value = 0;
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: hoveredSno.value == generalSetting.sNo
                                    ? Theme.of(context).primaryColorLight.withOpacity(0.8)
                                    : const Color(0xff000040).withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 4)
                            )
                          ]
                      ),
                      child: ListTile(
                        title: Text(generalSetting.title, style: Theme.of(context).textTheme.labelLarge,),
                        trailing: SizedBox(
                            width: 80,
                            child: AnimatedBuilder(
                                animation: generalSetting.value,
                                builder: (context, child){
                                  return FindSuitableWidget(
                                    constantSettingModel: generalSetting,
                                    onUpdate: (value){
                                      generalSetting.value.value = value;
                                    },
                                    onOk: (){
                                      setState(() {
                                        generalSetting.value.value = widget.overAllPvd.getTime();
                                      });
                                      Navigator.pop(context);
                                    },
                                    popUpItemModelList: [],
                                  );
                                }
                            )
                        ),
                      ),
                    ),
                  );
                }
            );
      
          }).toList(),
        ),
      ),
    );
  }
}
