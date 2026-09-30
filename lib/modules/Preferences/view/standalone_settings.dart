import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/program_library.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/schedule_screen.dart';
import 'package:oro_drip_irrigation/modules/Preferences/state_management/preference_provider.dart';
import 'package:oro_drip_irrigation/modules/Preferences/view/moisture_settings.dart';
import 'package:oro_drip_irrigation/modules/Preferences/widgets/custom_segmented_control.dart';
import 'package:oro_drip_irrigation/services/http_service.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid/responsive_grid.dart';
import '../../../models/customer/site_model.dart';
import '../model/preference_data_model.dart';
import '../repository/preferences_repo.dart';
import '../widgets/progress_dialog.dart';
import '../../IrrigationProgram/widgets/custom_native_time_picker.dart';

class StandAloneSettings extends StatefulWidget {
  final int userId, customerId, selectedIndex;
  final MasterControllerModel masterData;

  const StandAloneSettings({
    super.key,
    required this.userId,
    required this.customerId,
    required this.masterData,
    required this.selectedIndex,
  });

  @override
  State<StandAloneSettings> createState() => _StandAloneSettingsState();
}

class _StandAloneSettingsState extends State<StandAloneSettings> {
  final PreferenceRepository repository = PreferenceRepository(HttpService());
  int _selectedSetting = 0;
  late final bool isPumpWithLight;


  @override
  void initState() {
    super.initState();
    // Initialize provider data in initState
    final provider = Provider.of<PreferenceProvider>(context, listen: false);
    provider.getStandAloneSettings(
      userId: widget.customerId,
      controllerId: widget.masterData.controllerId,
      selectedIndex: widget.selectedIndex,
    );
    isPumpWithLight = AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId);
  }

  @override
  Widget build(BuildContext context) {
    final valves = widget.masterData.configObjects.where((e) => e.objectId == (AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId) ? 19: 13)).map((ele) => ele.name).toList();

    return Scaffold(
      body: Consumer<PreferenceProvider>(
        builder: (context, provider, child) {
          return (provider.standaloneSettings == null || provider.programSettings == null)
              ? const Center(child: CircularProgressIndicator())
              : Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // if (widget.selectedIndex == 2) ...[
                //   CustomSegmentedControl(
                //     segmentTitles: const {
                //       0: "Valve settings",
                //       1: "Moisture settings"
                //     },
                //     groupValue: _selectedSetting,
                //     onChanged: (value) => setState(() => _selectedSetting = value!),
                //   ),
                //   const SizedBox(height: 10),
                // ],
                Expanded(
                  child: _selectedSetting == 0
                      ? _buildValveSettings(context, valves, provider)
                      : const MoistureSettings(),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FilledButton.icon(
        onPressed: () {
          final provider = Provider.of<PreferenceProvider>(context, listen: false);
          if(widget.selectedIndex == 1 && provider.standaloneSettings!.setting[0].value == true && provider.standaloneSettings!.setting.where((e) => e.serialNumber != 1).every((ele) => ele.value == false)){
            _showAlert();
          } else {
            _sendSettings(context);
          }
        },
        label: const Text('Send'),
        icon: const Icon(Icons.send),
      ),
    );
  }

  void _showAlert() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Alert!", style: TextStyle(color: Colors.red, fontSize: 16),),
            content: const SizedBox(
              height: 100,
              child: Center(
                child: Text("The standalone system cannot be activated without opening the valves, as this may cause the pipeline to burst."),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK")
              )
            ],
          );
        }
    );
  }

  Widget _buildValveSettings(BuildContext context, List<String> valves, PreferenceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorLight,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                topLeft: Radius.circular(3),
              ),
            ),
            child: Center(
              child: Text(
                widget.selectedIndex == 1 ? "Standalone Settings" : "Program settings",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              color: Colors.white,
              border: Border.all(color: Theme.of(context).primaryColorLight, width: 0.3),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ResponsiveGridList(
              desiredItemWidth: MediaQuery.of(context).size.width <= 500 ? 150 : 200,
              minSpacing: 8,
              children: widget.selectedIndex == 1
                  ? List.generate(
                valves.length + 1,
                    (i) => _buildSettingTile(context, provider.standaloneSettings!.setting[i], valves, i-1),
              )
                  : List.generate(
                valves.length + 4,
                    (i) => _buildSettingTile(context, provider.programSettings!.setting[i], valves, i-4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(BuildContext context, WidgetSetting setting, List<String> titles, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).primaryColorLight, width: 0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: widget.selectedIndex == 1
          ? SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(widget.selectedIndex == 1
            ? setting.serialNumber == 1 ? setting.title : titles[index]
            : [1,2,3,4].contains(setting.serialNumber) ? setting.title : titles[index]),
        value: setting.value,
        onChanged: (value) => setState(() => setting.value = value),
      )
          : ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text([1,2,3,4].contains(setting.serialNumber) ? setting.title : titles[index]),
        trailing: _buildTrailingWidget(context, setting),
      ),
    );
  }

  Widget _buildTrailingWidget(BuildContext context, WidgetSetting setting) {
    switch (setting.widgetTypeId) {
      case 3:
        return CustomNativeTimePicker(
          initialValue: setting.value!,
          is24HourMode: true,
          onChanged: (value) => setState(() => setting.value = value), modelId: AppConstants.ecoGemModelList.first,
        );
      case 2:
        return Switch(
          value: setting.value,
          onChanged: (value) => setState(() => setting.value = value),
        );
      case 1:
        return SizedBox(
          width: 80,
          child: TextFormField(
            initialValue: setting.value.toString(),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() => setting.value = value),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: const InputDecoration(
              isDense: true,
              hintText: "000",
              contentPadding: EdgeInsets.symmetric(vertical: 5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide.none,
              ),
              fillColor: cardColor,
              filled: true,
            ),
          ),
        );
      default:
        return const Text("Unknown");
    }
  }

  Future<void> _sendSettings(BuildContext context) async {
    final provider = Provider.of<PreferenceProvider>(context, listen: false);
    Map<String, dynamic> rawPayload = {};

    if (widget.selectedIndex == 1) {
      rawPayload = {
        "sentSms": 'standalone,${provider.standaloneSettings!.setting.map((e) => e.value ? '1' : '0').join(',')}'
      };
    } else {
      if (_selectedSetting == 0) {
        rawPayload = {
          "sentSms":
          'valvesetting,${provider.programSettings!.setting.map((e) {
            if(e.widgetTypeId == 2) {
              return e.value ? '1' : '0';
            }else if(e.value is String && (e.value as String).isEmpty){
              return '0';
            } else {
              if(e.value.toString().contains(':')) {
                final result = e.value.split(':');
                if(e.serialNumber == 3) {
                  return '${result[0]},${result[1]},${result[2]}';
                } else {
                  return '${result[0]},${result[1]}';
                }
              } else {
                return e.value;
              }
            }
          }).join(',')}'
        };
      } else {
        rawPayload = {
          "sentSms":
          'moisturesetting,${provider.standaloneSettings!.setting.map((e) => e.widgetTypeId == 2 ? (e.value ? '1' : '0') : e.value).join(',')}'
        };
      }
    }
    final payload = jsonEncode({_selectedSetting == 0 ? "55" : "57": jsonEncode(rawPayload)});

    final resultFromDialog = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PayloadProgressDialog(
        payloads: [payload],
        deviceId: widget.masterData.deviceId,
        isToGem: false,
        mqttService: MqttService(),
        shouldSendFailedPayloads: false,
        isWlc: AppConstants.wlcModelList.contains(widget.masterData.modelId),
      ),
    );

    Map<String, dynamic> userData = {
      "userId": widget.customerId,
      "controllerId": widget.masterData.controllerId,
      "createUser": widget.userId,
      "hardware": rawPayload,
      if (_selectedSetting == 0)
        if(widget.selectedIndex == 1)
          "valveStandalone" : provider.standaloneSettings!.toJson()
        else
            "valveSetting" : provider.programSettings!.toJson()
      else
        "moistureSetting": provider.moistureSettings!.toJson()
    };

    if (resultFromDialog) {
      try {
        final result = widget.selectedIndex == 1
            ? await repository.createUserPreferenceValveStandaloneSetting(userData)
            : _selectedSetting == 0
            ? await repository.createUserPreferenceValveSetting(userData)
            : await repository.createUserPreferenceMoistureSetting(userData);
        final response = jsonDecode(result.body);
        showSnackBar(
            message: response['message'], context: context);
      } catch (error) {
        if (kDebugMode) {
          // print('Stack trace in the sending valve settings :: $stackTrace');
        }
        showSnackBar(message: '$error', context: context);
      }
    }
  }
}