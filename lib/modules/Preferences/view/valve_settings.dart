import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/widgets/custom_native_time_picker.dart';
import 'package:oro_drip_irrigation/modules/Preferences/model/preference_data_model.dart';
import 'package:oro_drip_irrigation/modules/Preferences/state_management/preference_provider.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../../../models/customer/site_model.dart';
import '../../IrrigationProgram/view/schedule_screen.dart';

class ValveSettings extends StatefulWidget {
  final int selectedMode;
  final MasterControllerModel masterData;
  const ValveSettings({super.key, required this.masterData, required this.selectedMode});

  @override
  State<ValveSettings> createState() => _ValveSettingsState();
}

class _ValveSettingsState extends State<ValveSettings> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<PreferenceProvider>(context, listen: false);
        setState(() {
          if(widget.selectedMode == 1){
            provider.standaloneSettings!.setting[4].value = true;
          } else {
            provider.standaloneSettings!.setting[4].value = false;
          }
        });
        provider.getMode();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final valves = widget.masterData.configObjects.where((e) => e.objectId == 13).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: 30,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(3))
              ),
              child: Center(
                child: Text(
                  widget.selectedMode == 1 ? "Standalone Settings" : "Program Settings",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white,),
                ),
              ),
            ),
          ),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                  color: Colors.white,
                  border: Border.all(color: Theme.of(context).primaryColorLight, width: 0.3)
                // boxShadow: AppProperties.customBoxShadowLiteTheme
              ),
              child: Consumer<PreferenceProvider>(
                builder: (context, provider, _) {
                  final settings = provider.standaloneSettings!.setting;
                  final firstHalf = settings.sublist(0, 5);
                  final secondHalf = settings.sublist(widget.selectedMode == 2 ? 5 : 4, (widget.selectedMode == 2 ? 4 : 5)+valves.length);

                  return ListView(
                    padding: const EdgeInsets.all(15),
                    children: [
                      if(widget.selectedMode == 2)...[
                        ResponsiveGridList(
                            listViewBuilderOptions: ListViewBuilderOptions(
                                shrinkWrap: true
                            ),
                            minItemWidth: MediaQuery.of(context).size.width <= 500 ? 150 : 200,
                            children: [
                              ...firstHalf.where((e) => e.serialNumber != 5).map((item) => _buildSettingTile(context, item)),
                            ]
                        ),
                        const SizedBox(height: 10,),
                        const Divider(),
                        const SizedBox(height: 10,),
                      ],
                      ResponsiveGridList(
                          listViewBuilderOptions: ListViewBuilderOptions(
                              shrinkWrap: true
                          ),
                          minItemWidth: MediaQuery.of(context).size.width <= 500 ? 150 : 200,
                          children: [
                            ...secondHalf.map((item) => _buildSecondHalfTile(context, item, provider.mode)),
                          ]
                      ),
                      const SizedBox(height: 60),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, WidgetSetting settingItem) {
    final provider = Provider.of<PreferenceProvider>(context, listen: false);

    // return Text("${settingItem.title},${settingItem.value}");
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).primaryColorLight, width: 0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(settingItem.title),
        trailing: IntrinsicWidth(
          child: settingItem.widgetTypeId == 3
              ? CustomNativeTimePicker(
            initialValue: settingItem.value!,
            is24HourMode: true,
            onChanged: (newValue) {
              provider.updateSettingValue(settingItem.title, newValue);
            }, modelId: widget.masterData.modelId,
          )
              : settingItem.widgetTypeId == 2
              ? Switch(
            value: settingItem.value,
            onChanged: (newValue) {
              provider.updateSwitchValue(settingItem.title, newValue);
            },
          )
              : SizedBox(
            width: 80,
            child: TextFormField(
              key: Key(settingItem.title),
              initialValue: settingItem.value,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onChanged: (newValue) {
                provider.updateSettingValue(settingItem.title, newValue);
              },
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
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
          ),
        ),
      ),
    );
  }

  Widget _buildSecondHalfTile(BuildContext context, WidgetSetting settingItem, String mode) {
    final provider = Provider.of<PreferenceProvider>(context, listen: false);
    // return Text("${settingItem.title},${settingItem.value}");
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).primaryColorLight, width: 0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(settingItem.title),
        trailing: IntrinsicWidth(
          child: mode == "Manual"
              ? Switch(
            value: settingItem.serialNumber != 5
                ? provider.getSwitchState(settingItem.value)
                : settingItem.value,
            onChanged: (newValue) {
              if(settingItem.serialNumber != 5) {
                provider.updateSwitchValue(settingItem.title, newValue);
              } else {
                setState(() {
                  provider.standaloneSettings!.setting[4].value = newValue;
                });
                // print("Serial Number: ${settingItem.serialNumber}, Value: $newValue, updated : ${settingItem.value}, value in the :: ${provider.valveSettings!.setting[4].value}");
              }
            },
          )
              : settingItem.serialNumber != 5 ? CustomNativeTimePicker(
            initialValue: provider.getDuration(settingItem.value),
            is24HourMode: true,
            onChanged: (newValue) {
              provider.updateSettingValue(settingItem.title, newValue);
            }, modelId: widget.masterData.modelId,
          ) : Container(),
        ),
      ),
    );
  }
}

