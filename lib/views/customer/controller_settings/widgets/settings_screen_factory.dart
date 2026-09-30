import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/views/customer/controller_settings/wide/notification_wide.dart';

import '../../../../Screens/Dealer/controllerlogfile.dart';
import '../../../../Screens/Dealer/dealer_definition.dart';
import '../../../../Screens/Map/oro_map/map_oro.dart';
import '../../../../Screens/Map/oro_map/map_areator.dart';
import '../../../../Screens/planning/PumpCondition.dart';
import '../../../../Screens/planning/frost_productionScreen.dart';
import '../../../../Screens/planning/names_form.dart';
import '../../../../Screens/planning/valve_group_screen.dart';
import '../../../../Screens/planning/virtual_screen.dart';
import '../../../../models/customer/controller_context.dart';
import '../../../../modules/Preferences/view/preference_main_screen.dart';
import '../../../../modules/SystemDefinitions/view/system_definition_screen.dart';
import '../../../../modules/calibration/view/calibration_screen.dart';
import '../../../../modules/constant/view/constant_base_page.dart';
import '../../../../modules/fertilizer_set/view/fertilizer_Set_screen.dart';
import '../../../../modules/global_limit/view/global_limit_screen.dart';
import '../../../common/general_setting_wide.dart';
import '../../crop_advisory_form.dart';
import '../wide/condition_library_wide.dart';
import '../narrow/condition_library_narrow.dart';
import '../narrow/general_settings_narrow.dart';
import '../narrow/notification_narrow.dart';

class SettingsScreenFactory {
  static void navigateTo(BuildContext context, String title, ControllerContext ctx, bool isNarrow) {
    final widget = getScreenWidget(title, ctx, isNarrow);
    if (widget != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => widget));
    }
  }

  static Widget? getScreenWidget(String title, ControllerContext ctx, bool isNarrow) {
    switch (title) {
      case 'General':
        if(isNarrow){
          return GeneralSettingsNarrow(
              controllerId: ctx.controllerId,
              customerId: ctx.customerId,
              isSubUser: ctx.isSubUser,
              userId: ctx.userId,
            ctx: ctx,
          );
        }else{
          return GeneralSettingWide(
            customerId: ctx.customerId,
            controllerId: ctx.controllerId,
            userId: ctx.userId,
            isSubUser: ctx.isSubUser,
          );
        }

      case 'Preference':
        return PreferenceMainScreen(
          userId: ctx.userId,
          customerId: ctx.customerId,
          masterData: {"deviceId": ctx.master.deviceId, "modelId": ctx.master.modelId, "controllerId": ctx.master.controllerId},
          selectedIndex: 0,
        );

      case 'Constant':
        return ConstantBasePage(userData: {
          "userId": ctx.userId,
          "customerId": ctx.customerId,
          "controllerId": ctx.controllerId,
          "deviceId": ctx.imeiNo,
          "modelId": ctx.modelId,
          "deviceName": ctx.deviceName,
          "categoryId": ctx.categoryId,
          "categoryName": ctx.categoryName,
        });

      case 'Condition Library':
        if(isNarrow){
          return ConditionLibraryNarrow(
            customerId: ctx.customerId,
            controllerId: ctx.controllerId,
            deviceId: ctx.imeiNo,
            userId: ctx.userId,
          );
        }else{
          return ConditionLibraryWide(
            customerId: ctx.customerId,
            controllerId: ctx.controllerId,
            deviceId: ctx.imeiNo,
            userId: ctx.userId,
          );
        }

      case 'Name':
        return Names(
          userID: ctx.userId,
          customerID: ctx.customerId,
          controllerId: ctx.controllerId,
          menuId: 0,
          imeiNo: ctx.imeiNo,
        );

      case 'Fertilizer Set':
        return FertilizerSetScreen(userData: {
          'userId': ctx.userId,
          'customerId': ctx.customerId,
          'controllerId': ctx.controllerId,
          'deviceId': ctx.imeiNo,
          'modelId': ctx.modelId,
        });

      case 'Valve Group':
        return GroupListScreen(
          userId: ctx.userId,
          customerId: ctx.customerId,
          controllerId: ctx.controllerId,
          deviceId: ctx.imeiNo,
        );

      case 'System Definitions':
        return SystemDefinition(
          userId: ctx.userId,
          controllerId: ctx.controllerId,
          deviceId: ctx.imeiNo,
          customerId: ctx.customerId,
        );

      case 'Global Limit':
        return GlobalLimitScreen(userData: {
          'userId': ctx.userId,
          'customerId': ctx.customerId,
          'controllerId': ctx.controllerId,
          'deviceId': ctx.imeiNo,
        });

      case 'Virtual Water Meter':
        return VirtualMeterScreen(
          userId: ctx.customerId,
          controllerId: ctx.controllerId,
          menuId: 67,
          deviceId: ctx.imeiNo,
        );

      case 'Frost Protection':
        return FrostMobUI(
          userId: ctx.customerId,
          controllerId: ctx.controllerId,
          deviceID: ctx.imeiNo,
          menuId: 71,
        );

      case 'Calibration':
        return CalibrationScreen(userData: {
          'userId': ctx.userId,
          'customerId': ctx.customerId,
          'controllerId': ctx.controllerId,
          'deviceId': ctx.imeiNo,
        });

      case 'Dealer Definition':
        return DealerDefinitionInConfig(
          userId: ctx.userId,
          customerId: ctx.customerId,
          controllerId: ctx.controllerId,
          imeiNo: ctx.imeiNo,
        );

      case 'Notification':
        if(isNarrow){
          return NotificationNarrow(
            userId: ctx.userId,
            customerId: ctx.customerId,
            controllerId: ctx.controllerId,
          );
        }else{
          return NotificationWide(
            userId: ctx.userId,
            customerId: ctx.customerId,
            controllerId: ctx.controllerId,
          );
        }

      case 'Geography':
        return ctx.modelId == 72 ? MapScreenValve(
          userId: ctx.userId,
          customerId: ctx.customerId,
          controllerId: ctx.controllerId,
          imeiNo: ctx.imeiNo,
          modelId: ctx.modelId,
        ) : MapScreenOro(userId: ctx.userId, customerId: ctx.customerId, controllerId: ctx.controllerId, imeiNo: ctx.imeiNo, modelId: ctx.modelId,)
        ;

      // case 'Geography Area':
      //   return MapScreenAllArea(
      //     userId: ctx.userId,
      //     customerId: ctx.customerId,
      //     controllerId: ctx.controllerId,
      //     imeiNo: ctx.imeiNo,
      //   );

      case 'Pump Condition':
        return PumpConditionScreen(
          userId: ctx.userId,
          customerId: ctx.customerId,
          controllerId: ctx.controllerId,
          imeiNo: ctx.imeiNo,
          modelid:ctx.modelId,
        );

      case 'Controller Log':
        return ControllerLog(
          deviceID: ctx.imeiNo,
          communicationType: 'MQTT',
        );

      case 'Crop Advisory':
        return CropAdvisoryForm(
          customerId: ctx.customerId,
          controllerId: ctx.controllerId,
          isNarrow: isNarrow,
        );

      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}