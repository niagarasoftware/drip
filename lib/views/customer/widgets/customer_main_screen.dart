import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/irrigation_report/view/oms_log.dart';
import '../../../Screens/Dealer/sevicecustomer.dart';
import '../../../Screens/Logs/irrigation_and_pump_log.dart';
import '../../../Screens/Map/oro_map/map_areator.dart';
import '../../../Screens/Map/oro_map/map_oro.dart';
import '../../../Screens/planning/weather/view/weather_Gsm.dart';
import '../../../Screens/planning/weather/view/weather_screen_new.dart';
import '../../../layouts/layout_selector.dart';
import '../../../models/customer/site_model.dart';
import '../../../modules/PumpController/view/pump_controller_home.dart';
import '../../../utils/constants.dart';
import '../../../utils/enums.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../controller_settings/wide/controller_settings_wide.dart';
import '../customer_product.dart';
import '../send_and_received/sent_and_received.dart';
import '../site_config.dart';

Widget buildCustomerMainScreen({required int index, required UserRole role, required int userId,
  required CustomerScreenControllerViewModel vm}) {
  final cSite = vm.mySiteList.data[vm.sIndex];
  final cMaster = cSite.master[vm.mIndex];

  final isGem = [...AppConstants.gemModelList].contains(cMaster.modelId);
  final isNova = [...AppConstants.ecoGemModelList].contains(cMaster.modelId);
  final isOms = [...AppConstants.omsGemList].contains(cMaster.modelId);
  final isAquaculture = [...AppConstants.aquacultureModelList].contains(cMaster.modelId);
  final isGsmWeather = [...AppConstants.weatherModelList].contains(cMaster.modelId);

   switch (index) {
    case 0:
      return (isGem || isNova || isOms) ?
      const DashboardLayoutSelector(userRole: UserRole.customer) : isGsmWeather ?
      WeatherGsm(customerId: cSite.customerId, controllerId: cMaster.controllerId, deviceID: cMaster.deviceId,jsondata: dashboardToWeatherFormat(cMaster)) :
      vm.isChanged ? PumpControllerHome(
        userId: userId,
        customerId: cSite.customerId,
        masterData: cMaster,
      )  :
      const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Please wait...'),
              SizedBox(height: 10),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );

    case 1:
      return CustomerProduct(customerId: cSite.customerId);

    case 2:
      return SentAndReceived(
        customerId: cSite.customerId,
        controllerId: cMaster.controllerId,
        isWide: true,
      );
    case 3:
      return (isGem || isNova) ? IrrigationAndPumpLog(
        userData: {
          'userId': userId,
          'controllerId': cMaster.controllerId,
          'customerId': cSite.customerId,
        },
        masterData: cMaster,
      ) : isOms ? OmsLog(
          userId: cSite.customerId,
          controllerId: cMaster.controllerId,
          nodeControllerId: 0
      ):
      ControllerSettingWide(
        userId: userId,
        customerId: cSite.customerId,
        masterController: cMaster,
      );

    case 4:
      return (isGem || isNova || isOms) ? ControllerSettingWide(
        userId: userId,
        customerId: cSite.customerId,
        masterController: cMaster,
      ) :
      SiteConfig(
        userId: userId,
        customerId: cSite.customerId,
        customerName: cSite.customerName,
        groupId: cSite.groupId,
        groupName: cSite.groupName,
      );

    case 5:
      return (isGem || isNova || isOms) ? SiteConfig(
        userId: userId,
        customerId: cSite.customerId,
        customerName: cSite.customerName,
        groupId: cSite.groupId,
        groupName: cSite.groupName,
      ) :
      TicketHomePage(
        userId: cSite.customerId,
        controllerId: cMaster.controllerId,
      );
    case 6:
      return TicketHomePage(
        userId: cSite.customerId,
        controllerId: cMaster.controllerId,
      );
    case 7:
      return isAquaculture ? MapScreenValve(customerId: cSite.customerId,
        controllerId: cMaster.controllerId,
        userId: cSite.customerId,
        imeiNo: cMaster.deviceId, modelId: cMaster.modelId,) :
      WeatherScreenNew(customerId: cSite.customerId,
          controllerId: cMaster.controllerId,
          deviceID: cMaster.deviceId,
          isNarrow: false);

     case 8:
       return  MapScreenOro(customerId: cSite.customerId,
         controllerId: cMaster.controllerId,
         userId: cSite.customerId,
         imeiNo: cMaster.deviceId, modelId: cMaster.modelId,
       isCheckDashboard: true,);

    default:
      return const Scaffold(
        body: Center(
          child: Text("Invalid screen index"),
        ),
      );
  }
}

Map<String, dynamic> dashboardToWeatherFormat(
    MasterControllerModel dashboard) {

  final deviceList = <Map<String, dynamic>>[];
  final configList = dashboard.configObjects.map((e) => e.toJson()).toList();

  deviceList.add({
    "controllerId": dashboard.controllerId,
    "deviceId": dashboard.deviceId,
    "deviceName": dashboard.deviceName,
    "serialNumber": 1,
  });

  return {
    "weatherLive": dashboard.live?.toJson(),
    "deviceList": deviceList,
    "configObject": configList,
  };
}