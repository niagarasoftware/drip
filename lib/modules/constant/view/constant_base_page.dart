import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';
import 'package:oro_drip_irrigation/Widgets/custom_buttons.dart';
import 'package:oro_drip_irrigation/modules/constant/model/constant_menu_model.dart';
import 'package:oro_drip_irrigation/modules/constant/model/constant_setting_type_Model.dart';
import 'package:oro_drip_irrigation/modules/constant/repository/constant_repository.dart';
import 'package:oro_drip_irrigation/modules/constant/state_management/constant_provider.dart';
import 'package:oro_drip_irrigation/modules/constant/view/ec_ph_in_constant.dart';
import 'package:oro_drip_irrigation/modules/constant/view/fertilizer_site_in_constant.dart';
import 'package:oro_drip_irrigation/modules/constant/view/global_alarm_in_constant.dart';
import 'package:oro_drip_irrigation/modules/constant/view/main_valve_in_constant.dart';
import 'package:oro_drip_irrigation/modules/constant/view/common_alarm_in_constant.dart';
import 'package:oro_drip_irrigation/modules/constant/view/normal_critical_alarm_in_constant.dart';
import 'package:oro_drip_irrigation/modules/constant/view/pump_in_constant.dart';
import 'package:oro_drip_irrigation/modules/constant/view/valve_in_constant.dart';
import 'package:oro_drip_irrigation/modules/constant/view/water_meter_in_constant.dart';
import 'package:oro_drip_irrigation/modules/constant/widget/arrow_tab.dart';
import 'package:oro_drip_irrigation/modules/constant/widget/custom_check_box.dart';
import 'package:oro_drip_irrigation/modules/constant/widget/custom_pop_up_button.dart';
import 'package:oro_drip_irrigation/modules/constant/widget/custom_switch.dart';
import 'package:oro_drip_irrigation/modules/constant/widget/custom_text_form_field.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/overall_use.dart';
import 'channel_in_constant.dart';
import 'filter_in_constant.dart';
import 'filter_site_in_constant.dart';
import 'general_in_constant.dart';
import 'level_in_constant.dart';
import 'moisture_in_constant.dart';

class ConstantBasePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ConstantBasePage({super.key, required this.userData});

  @override
  State<ConstantBasePage> createState() => _ConstantBasePageState();
}

class _ConstantBasePageState extends State<ConstantBasePage> with SingleTickerProviderStateMixin{
  late TabController tabController;
  late Future<int> constantResponse;
  late ConstantProvider constPvd;
  late OverAllUse overAllPvd;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("userData : ${widget.userData}");
    constPvd = Provider.of<ConstantProvider>(context, listen: false);
    overAllPvd = Provider.of<OverAllUse>(context, listen: false);
    constantResponse = getData(widget.userData);
  }

  Future<int> getData(userData)async{
    try{
      await Future.delayed(const Duration(seconds: 1));
      var body = {
        "userId": userData['customerId'],
        "controllerId": userData['controllerId'],
      };
      var constantResponse = await ConstantRepository().getUserConstant(body);
      Map<String, dynamic> constantJsonData = jsonDecode(constantResponse.body);
      var configMakerResponse = await ConstantRepository().getUserDefaultConfigMaker(body);
      Map<String, dynamic> configMakerJsonData = jsonDecode(configMakerResponse.body);
      constPvd.updateConstant(constantData: constantJsonData,configMakerData: configMakerJsonData, userDataAndMasterData: userData);
      setState(() {
        tabController = TabController(length: constPvd.listOfConstantMenuModel.length, vsync: this);
      });
      return constantJsonData['code'];
    }catch(e,stacktrace){
      print('Error on getting constant data :: $e');
      print('Stacktrace on getting constant data :: $stacktrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    constPvd = Provider.of<ConstantProvider>(context, listen: true);
    overAllPvd = Provider.of<OverAllUse>(context, listen: true);
    return FutureBuilder<int>(
        future: constantResponse,
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Loading state
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}'); // Error state
          } else if (snapshot.hasData) {
            return Scaffold(
              appBar: MediaQuery.of(context).size.width < 500 ? AppBar(
                title: Text('Constant'),
              ): null,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              floatingActionButton: Row(
                spacing: 20,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(tabController.index == 0 ? Colors.grey.shade500 : Theme.of(context).primaryColor)
                      ),
                      onPressed: (){
                        if(tabController.index != 0){
                          setState(() {
                            updateTabs(tabController.index - 1);
                          });
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white)
                  ),
                  IconButton(
                    alignment: Alignment.center,
                      style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(tabController.index == (constPvd.listOfConstantMenuModel.length - 1) ? Colors.grey.shade500 : Theme.of(context).primaryColor)
                      ),
                      onPressed: (){
                        if(tabController.index != constPvd.listOfConstantMenuModel.length - 1){
                          setState(() {
                            updateTabs(tabController.index + 1);
                          });
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white,)
                  ),
                ],
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 20,
                    children: [
                      getTabs(),
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                            children: getTabBarView()
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const Text('No data'); // Shouldn't reach here normally
          }
        }
    );
  }

  void updateTabs(index){
    constPvd.listOfConstantMenuModel[index].arrowTabState.value = ArrowTabState.onProgress;
    for(var i = 0; i< index;i++){
      constPvd.listOfConstantMenuModel[i].arrowTabState.value = ArrowTabState.complete;
    }
    for(var i = constPvd.listOfConstantMenuModel.length - 1; i > index;i--){
      constPvd.listOfConstantMenuModel[i].arrowTabState.value = ArrowTabState.inComplete;
    }
    tabController.animateTo(index);
  }

  List<Widget> getTabBarView(){
    return List.generate(tabController.length, (index){
      if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.generalInConstant){
        return GeneralInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.pumpInConstant){
        return PumpInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.filterSiteInConstant){
        return FilterSiteInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.filterInConstant){
        return FilterInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.mainValveInConstant){
        return MainValveInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.valveInConstant){
        return ValveInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.waterMeterInConstant){
        return WaterMeterInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.fertilizerSiteInConstant){
        return FertilizerSiteInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.fertilizerChannelInConstant){
        return ChannelInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.ecPhInConstant){
        return EcPhInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.moistureSensorInConstant){
        return MoistureInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.levelSensorInConstant){
        return LevelInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.normalCriticalInConstant){
        return NormalCriticalInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.commonAlarmInConstant){
        return CommonAlarmInConstant(constPvd: constPvd, overAllPvd: overAllPvd,);
      }else if(constPvd.listOfConstantMenuModel[index].dealerDefinitionId == AppConstants.globalAlarmInConstant){
        return GlobalAlarmInConstant(constPvd: constPvd, overAllPvd: overAllPvd, userData: widget.userData,);
      }else{
        return Text(constPvd.listOfConstantMenuModel[index].parameter);
      }
    });
  }

  Widget getTabs(){
    return TabBar(
      overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.hovered)) {
          return Colors.transparent;
        }
        return null;
      }),
      tabAlignment: TabAlignment.start,
      dividerHeight: 0,
      labelPadding: const EdgeInsets.all(0),
      isScrollable: true,
      indicator: const BoxDecoration(),
      controller: tabController,
      tabs: List.generate(constPvd.listOfConstantMenuModel.length, (index){
        return Tab(
            child: AnimatedBuilder(
                animation: constPvd.listOfConstantMenuModel[index].arrowTabState,
                builder: (context, child){
                  return ArrowTab(
                      index: index,
                      title: constPvd.listOfConstantMenuModel[index].parameter,
                      arrowTabState: constPvd.listOfConstantMenuModel[index].arrowTabState.value
                  );
                }
            ),
        );
      }),
      onTap: (value){
        constPvd.listOfConstantMenuModel[value].arrowTabState.value = ArrowTabState.onProgress;
        for(var i = 0; i< value;i++){
          constPvd.listOfConstantMenuModel[i].arrowTabState.value = ArrowTabState.complete;
        }
        for(var i = constPvd.listOfConstantMenuModel.length - 1; i > value;i--){
          constPvd.listOfConstantMenuModel[i].arrowTabState.value = ArrowTabState.inComplete;
        }
        setState(() {
          tabController.animateTo(value);
        });
        print("value ==> ${value}");
        print("constant tab length ==> ${tabController.length}");
        print("constant tab index ==> ${tabController.index}");
      },
    );
  }
}
