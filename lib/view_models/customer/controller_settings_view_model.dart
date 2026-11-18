import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../../repository/repository.dart';

class ControllerSettingsViewModel extends ChangeNotifier {

  final Repository repository;
  bool isLoading = false;
  String errorMessage = "";

  List<Map<String, dynamic>> filteredSettingList = [];

  final List<Map<String, dynamic>> allSettings = [
    {'title': 'General', 'icon': Icons.settings_outlined},
    {'title': 'Preference', 'icon': Icons.settings_applications_outlined},
    {'title': 'Constant', 'icon': Icons.private_connectivity_sharp},
    {'title': 'Name', 'icon': Icons.text_fields},
    {'title': 'Condition Library', 'icon': Icons.library_books_outlined},
    {'title': 'Notification', 'icon': Icons.notifications_none},
    {'title': 'Fertilizer Set', 'icon': Icons.format_textdirection_r_to_l},
    {'title': 'Valve Group', 'icon': Icons.group_work_outlined},
    {'title': 'System Definitions', 'icon': Icons.settings_system_daydream_outlined},
    {'title': 'Global Limit', 'icon': Icons.production_quantity_limits},
    {'title': 'Virtual Water Meter', 'icon': Icons.gas_meter_outlined},
    {'title': 'Program Queue', 'icon': Icons.query_stats},
    {'title': 'Frost Protection', 'icon': Icons.fort_outlined},
    {'title': 'Calibration', 'icon': Icons.compass_calibration_outlined},
    {'title': 'Dealer Definition', 'icon': Icons.person_outline},
    {'title': 'View Settings', 'icon': Icons.remove_red_eye_outlined},
    {'title': 'Geography', 'icon': Icons.map_outlined},
    // {'title': 'Geography Area', 'icon': Icons.map_sharp},
    {'title': 'Pump Condition', 'icon': Icons.library_books},
    {'title': 'Controller Log', 'icon': Icons.home_repair_service_outlined},
    {'title': 'Crop Advisory', 'icon': Icons.agriculture_outlined},
  ];

  ControllerSettingsViewModel(this.repository);

  Future<void> getSettingsMenu(int customerId, int controllerId, int modelId) async {
    final isGem = [...AppConstants.gemModelList].contains(modelId);
    setLoading(true);
    try {
      Map<String, Object> body = {
        "userId": customerId,
        "controllerId": controllerId
      };
      var response = await repository.getPlanningHiddenMenu(body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200 && jsonData["data"] is List) {
          final List<dynamic> dataList = jsonData["data"];

          final Set<String> availableTitles = dataList
              .map((e) => e["parameter"]?.toString() ?? '')
              .toSet();

          if(![...AppConstants.gemModelList, ...AppConstants.ecoGemModelList, ...AppConstants.omsGemList].contains(modelId)){
            final allowedTitles = {
              'General',
              'Preference',
              'Name',
            };
            filteredSettingList = allSettings.where((setting) {
              final title = setting['title'];
              return allowedTitles.contains(title);
            }).toList();
          }
          else if([...AppConstants.ecoGemModelList, ...AppConstants.omsGemList].contains(modelId)) {
            final allowedTitles = {
              'General',
              'Preference',
              'Name',
              'Constant',
              'Calibration',
              'Valve Group',
              'Dealer Definition',
              'Pump Condition',
            };
            filteredSettingList = allSettings.where((setting) {
              final title = setting['title'];
              return allowedTitles.contains(title);
            }).toList();
          }
          else{
            filteredSettingList = allSettings.where((setting) {
              if(isGem){
                if (setting['title'] == 'General'
                    || setting['title'] == 'Dealer Definition'
                    || setting['title'] == 'Notification'
                    || setting['title'] == 'Geography'
                    // || setting['title'] == 'Geography Area'
                    || setting['title'] == 'Pump Condition'
                    || setting['title'] == 'Controller Log'
                    || setting['title'] == 'Crop Advisory'
                ) {
                  return true;
                }
              }else{
                if (setting['title'] == 'General') {
                  return true;
                }
              }
              return availableTitles.contains(setting['title']);
            }).toList();
          }
        }
      }
    } catch (error) {
      debugPrint('Error fetching settings menu: $error');
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}