import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/utils/helpers/mc_permission_helper.dart';
import 'package:provider/provider.dart';

import '../../../models/customer/site_model.dart';
import '../../../modules/IrrigationProgram/view/program_library.dart';
import '../../../modules/ScheduleView/view/schedule_view_screen.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/constants.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../input_output_connection_details.dart';
import '../node_list/node_list.dart';
import '../stand_alone/stand_alone_wide.dart';
import 'alarm_button.dart';

class SideActionMenu extends StatelessWidget {
  final double screenHeight;
  final Function(String status) callbackFunction;

  const SideActionMenu({
    super.key,
    required this.screenHeight,
    required this.callbackFunction,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CustomerScreenControllerViewModel>();
    final loggedInUser = context.read<UserProvider>().loggedInUser;

    final cM = vm.mySiteList.data[vm.sIndex].master[vm.mIndex];

    final hasPlanning = cM.getPermissionStatus("Planning");
    final hasStandaloneOnOff = cM.getPermissionStatus("Standalone On/Off");
    final hasViewLog = cM.getPermissionStatus("View Controller Log");

    return Container(
      width: 60,
      height: screenHeight,
      color: Theme.of(context).primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          /// WiFi Strength
          _buildWifiStrength(vm),

          const SizedBox(height: 15),

          /// Alarm Button
          AlarmButton(
            alarmPayload: vm.alarmDL,
            deviceID: cM.deviceId,
            customerId: vm.mySiteList.data[vm.sIndex].customerId,
            controllerId: cM.controllerId,
            irrigationLine: cM.irrigationLine,
            isNarrow: false,
            isOMS: false,
          ),

          const SizedBox(height: 15),
          _buildNodeStatus(context, vm.mySiteList.data[vm.sIndex].customerId, loggedInUser.id, cM),

          if (![...AppConstants.ecoGemModelList].contains(cM.modelId)) ...[
            const SizedBox(height: 15),
            _buildIoDetails(context, vm, cM),
          ],

          if(hasPlanning)...[
            const SizedBox(height: 15),
            _buildProgramButton(context, vm, loggedInUser.id, cM),
          ],

          if(hasViewLog)...[
            if ([...AppConstants.gemModelList].contains(cM.modelId)) ...[
              const SizedBox(height: 15),
              _buildScheduleView(context, vm, loggedInUser.id, cM),
            ],
          ],

          if(hasStandaloneOnOff)...[
            const SizedBox(height: 15),
            _buildManualButton(context, vm, loggedInUser.id, cM),
          ],
        ],
      ),
    );
  }

  /// ------------------ Private helper widgets -------------------

  Widget _buildWifiStrength(CustomerScreenControllerViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.transparent,
      ),
      width: 45,
      height: 45,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            vm.wifiStrength == 0
                ? Icons.wifi_off
                : vm.wifiStrength <= 20
                ? Icons.network_wifi_1_bar_outlined
                : vm.wifiStrength <= 40
                ? Icons.network_wifi_2_bar_outlined
                : vm.wifiStrength <= 80
                ? Icons.network_wifi_3_bar_outlined
                : Icons.wifi,
            color: Colors.white,
          ),
          Text(
            '${vm.wifiStrength} %',
            style: const TextStyle(fontSize: 11.0, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeStatus(BuildContext context, int customerId,
      int userId, MasterControllerModel cM) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.transparent,
      child: SizedBox(
        height: 45,
        width: 45,
        child: IconButton(
          tooltip: 'Node status',
          onPressed: () {
            showGeneralDialog(
              barrierLabel: "Side sheet",
              barrierDismissible: true,
              barrierColor: const Color(0xff66000000),
              transitionDuration: const Duration(milliseconds: 300),
              context: context,
              pageBuilder: (context, animation1, animation2) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    elevation: 15,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.zero,
                    child: NodeList(
                      customerId: customerId,
                      userId: userId,
                      nodes: cM.nodeList,
                      configObjects: cM.configObjects,
                      masterData: cM, isWide: true,
                    ),
                  ),
                );
              },
              transitionBuilder: (context, animation1, animation2, child) {
                return SlideTransition(
                  position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(animation1),
                  child: child,
                );
              },
            );
          },
          icon: const Icon(Icons.format_list_numbered),
          color: Colors.white,
          iconSize: 24.0,
          hoverColor: Theme.of(context).primaryColorLight,
        ),
      ),
    );
  }

  Widget _buildIoDetails(BuildContext context, CustomerScreenControllerViewModel vm,
      MasterControllerModel cM) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
      child: IconButton(
        tooltip: 'Input/Output Connection details',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InputOutputConnectionDetails(
                masterInx: vm.mIndex,
                nodes: cM.nodeList,
              ),
            ),
          );
        },
        icon: const Icon(Icons.settings_input_component_outlined),
        color: Colors.white,
        iconSize: 24.0,
      ),
    );
  }

  Widget _buildProgramButton(BuildContext context, CustomerScreenControllerViewModel vm,
      int userId, MasterControllerModel cM) {
    return SizedBox(
      width: 45,
      height: 45,
      child: IconButton(
        tooltip: 'Program',
        onPressed:() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProgramLibraryScreenNew(
                customerId: vm.mySiteList.data[vm.sIndex].customerId,
                controllerId: cM.controllerId,
                deviceId: cM.deviceId,
                userId: userId,
                groupId: vm.mySiteList.data[vm.sIndex].groupId,
                categoryId: cM.categoryId,
                modelId: cM.modelId,
                deviceName: cM.deviceName,
                categoryName: cM.categoryName,
                callbackFunction: callbackFunction,
                nodeList: cM.nodeList,
              ),
            ),
          );
        },
        icon: const Icon(Icons.list_alt),
        color: Colors.white,
        iconSize: 24.0,
      ),
    );
  }

  Widget _buildScheduleView(BuildContext context, CustomerScreenControllerViewModel vm,
      int userId, MasterControllerModel cM) {
    return SizedBox(
      width: 45,
      height: 45,
      child: IconButton(
        tooltip: 'Scheduled Program details',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleViewScreen(
                deviceId: cM.deviceId,
                userId: userId,
                controllerId: cM.controllerId,
                customerId: vm.mySiteList.data[vm.sIndex].customerId,
                groupId: vm.mySiteList.data[vm.sIndex].groupId,
              ),
            ),
          );
        },
        icon: const Icon(Icons.view_list_outlined),
        color: Colors.white,
        iconSize: 24.0,
      ),
    );
  }

  Widget _buildManualButton(BuildContext context, CustomerScreenControllerViewModel vm,
      int userId, MasterControllerModel cM) {

    return SizedBox(
      width: 45,
      height: 45,
      child: IconButton(
        tooltip: 'Manual',
        onPressed: () {
          showGeneralDialog(
            barrierLabel: "Side sheet",
            barrierDismissible: true,
            barrierColor: const Color(0xff66000000),
            transitionDuration: const Duration(milliseconds: 300),
            context: context,
            pageBuilder: (context, animation1, animation2) {
              return Align(
                alignment: Alignment.centerRight,
                child: Material(
                  elevation: 15,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.zero,
                  child: StandAloneWide(
                    siteId: vm.mySiteList.data[vm.sIndex].groupId,
                    controllerId: cM.controllerId,
                    customerId: vm.mySiteList.data[vm.sIndex].customerId,
                    deviceId: cM.deviceId,
                    callbackFunction: callbackFunction,
                    userId: userId,
                    masterData: cM,
                  ),
                ),
              );
            },
            transitionBuilder: (context, animation1, animation2, child) {
              return SlideTransition(
                position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(animation1),
                child: child,
              );
            },
          );
        },
        icon: const Icon(Icons.touch_app_outlined),
        color: Colors.white,
        iconSize: 24.0,
      ),
    );
  }
}