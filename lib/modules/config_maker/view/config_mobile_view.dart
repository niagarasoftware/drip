import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/product_limit.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../config_maker/model/device_object_model.dart';
import '../../config_maker/model/device_model.dart';
import '../../config_maker/state_management/config_maker_provider.dart';
import 'config_base_page.dart';
import 'connection.dart';
import 'device_list.dart';

class ConfigMobileView extends StatefulWidget {
  List<DeviceModel> listOfDevices;
  ConfigMobileView({super.key, required this.listOfDevices});
  @override
  _ConfigMobileViewState createState() => _ConfigMobileViewState();
}

class _ConfigMobileViewState extends State<ConfigMobileView>
    with SingleTickerProviderStateMixin {
  late ConfigMakerProvider configPvd;
  late TabController _tabController;
  late ThemeData themeData;
  late bool themeMode;

  @override
  void initState() {
    super.initState();
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
    _tabController = TabController(length: ConfigMakerTabs.values.length, vsync: this);
    if(configPvd.selectedTab == ConfigMakerTabs.deviceList){
      _tabController.index = 0;
    }else if(configPvd.selectedTab == ConfigMakerTabs.productLimit){
      _tabController.index = 1;
    }else if(configPvd.selectedTab == ConfigMakerTabs.connection){
      _tabController.index = 2;
    }else{
      _tabController.index = 3;
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    themeData = Theme.of(context);
    themeMode = themeData.brightness == Brightness.light;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeData.primaryColorDark.withValues(alpha: themeMode ? 1.0 : 0.2),
        title: const Text("Config Maker"),
        bottom: TabBar(
          tabAlignment: TabAlignment.start,
          isScrollable: true,
          controller: _tabController,
          onTap: (value){
            ConfigMakerTabs selectedTab = value == 0
                ? ConfigMakerTabs.deviceList
                : value == 1
                ? ConfigMakerTabs.productLimit
                : value == 2
                ? ConfigMakerTabs.connection
                : ConfigMakerTabs.siteConfigure;

            ConfigMakerTabs previousTab = updateConfigMakerTabs(
              context: context,
              configPvd: configPvd,
              setState: setState,
              selectedTab: selectedTab,
            );
            setState(() {
              _tabController.index = previousTab == ConfigMakerTabs.deviceList
                  ? 0
                  : previousTab == ConfigMakerTabs.productLimit
                  ? 1
                  : previousTab == ConfigMakerTabs.connection
                  ? 2
                  : 3;
            });
          },
          tabs: ConfigMakerTabs.values.map((tab) {
            return Tab(text: getTabName(tab));
          }).toList(),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          DeviceList(listOfDevices: widget.listOfDevices),
          ProductLimit(listOfDevices: widget.listOfDevices, configPvd: configPvd,),
          Connection(configPvd: configPvd),
          SiteConfigure(configPvd: configPvd)
        ],
      ),
    );
  }
}

ConfigMakerTabs updateConfigMakerTabs({
  required BuildContext context,
  required ConfigMakerProvider configPvd,
  required Function(Function()) setState,
  required ConfigMakerTabs selectedTab,
}){
  bool update = true;
  if([ConfigMakerTabs.connection, ConfigMakerTabs.siteConfigure].contains(selectedTab)){
    final List<DeviceObjectModel> deviceObjects = configPvd.listOfSampleObjectModel;
    final pumpObject = getObjectById(deviceObjects, 5);
    final valveObject = getObjectById(deviceObjects, 13);
    final channelObject = getObjectById(deviceObjects, 10);
    final dosingObject = getObjectById(deviceObjects, 3);
    bool pumpAvailable = pumpObject.count != '0';
    bool valveAvailable = valveObject.count != '0';
    bool dosingAvailable = dosingObject.count != '0';
    bool channelAvailable = channelObject.count != '0';
    if(!pumpAvailable && ![...AppConstants.ecoGemFlowControlValveModel, ...AppConstants.omsGemList].contains(configPvd.masterData['modelId'])){
      update = false;
      simpleDialogBox(context: context, title: 'Alert', message: 'At least one ${!pumpAvailable ? pumpObject.objectName : ''} must be provided in the product limit.');
      List<int> notice = [];
      if(!pumpAvailable){
        notice.add(pumpObject.objectId);
      }
      configPvd.noticeObjectForTemporary(notice);
    }else if(dosingAvailable && !channelAvailable){
      update = false;
      configPvd.noticeObjectForTemporary([channelObject.objectId]);
      simpleDialogBox(context: context, title: 'Alert', message: 'At least one ${channelObject.objectName} must be provided for the dosing site.');
    }

  }
  if(update){
    setState(() {
      configPvd.selectedTab = selectedTab;
    });
  }
  return configPvd.selectedTab;
}

DeviceObjectModel getObjectById(List<DeviceObjectModel> objects, int objectId) {
  return objects.firstWhere(
        (object) => object.objectId == objectId,
    orElse: () => throw Exception('Object with ID $objectId not found'),
  );
}