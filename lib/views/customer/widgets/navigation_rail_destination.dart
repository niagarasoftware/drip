import 'package:flutter/material.dart';
import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';

class NavigationDestinationsBuilder {

  static List<NavigationRailDestination> build(
      BuildContext context, MasterControllerModel master) {

    return [
      const NavigationRailDestination(
        icon: Tooltip(message: 'Home', child: Icon(Icons.home_outlined)),
        selectedIcon: Icon(Icons.home, color: Colors.white),
        label: Text(''),
      ),
      const NavigationRailDestination(
        icon: Tooltip(message: 'All my devices', child: Icon(Icons.devices_other)),
        selectedIcon: Icon(Icons.devices_other, color: Colors.white),
        label: Text(''),
      ),
      const NavigationRailDestination(
        icon: Tooltip(message: 'Sent & Received', child: Icon(Icons.question_answer_outlined)),
        selectedIcon: Icon(Icons.question_answer, color: Colors.white),
        label: Text(''),
      ),
      if ([...AppConstants.gemModelList, ...AppConstants.ecoGemModelList, ...AppConstants.omsGemList].contains(master.modelId))
        const NavigationRailDestination(
          icon: Tooltip(message: 'Controller Logs', child: Icon(Icons.receipt_outlined)),
          selectedIcon: Icon(Icons.receipt, color: Colors.white),
          label: Text(''),
        ),
      const NavigationRailDestination(
        icon: Tooltip(message: 'Settings', child: Icon(Icons.settings_outlined)),
        selectedIcon: Icon(Icons.settings, color: Colors.white),
        label: Text(''),
      ),
      const NavigationRailDestination(
        icon: Tooltip(message: 'Configuration', child: Icon(Icons.confirmation_num_outlined)),
        selectedIcon: Icon(Icons.confirmation_num, color: Colors.white),
        label: Text(''),
      ),
      const NavigationRailDestination(
        icon: Tooltip(message: 'Service Request', child: Icon(Icons.support_agent_sharp)),
        selectedIcon: Icon(Icons.support_agent_sharp, color: Colors.white),
        label: Text(''),
      ),
      if ([...AppConstants.gemModelList].contains(master.modelId)
          && ![...AppConstants.aquacultureModelList].contains(master.modelId))
        const NavigationRailDestination(
          icon: Tooltip(message: 'Weather', child: Icon(Icons.sunny_snowing)),
          selectedIcon: Icon(Icons.wb_sunny_rounded, color: Colors.white),
          label: Text(''),
        ),
      if ([...AppConstants.aquacultureModelList].contains(master.modelId) || [...AppConstants.gemModelList].contains(master.modelId))
        const NavigationRailDestination(
          icon: Tooltip(message: 'Geography', child: Icon(Icons.map_outlined)),
          selectedIcon: Icon(Icons.map_outlined, color: Colors.white),
          label: Text(''),
        ),
    ];
  }
}