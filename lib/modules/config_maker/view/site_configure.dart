import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/ec_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/ph_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/pressure_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/pump_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/source_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/valve_configuration.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import 'channel_configuration.dart';
import 'fertilization_configuration.dart';
import 'filtration_configuration.dart';
import 'line_configuration.dart';
import 'moisture_configuration.dart';

class SiteConfigure extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const SiteConfigure({super.key, required this.configPvd});

  @override
  State<SiteConfigure> createState() => _SiteConfigureState();
}

class _SiteConfigureState extends State<SiteConfigure> {
  late ThemeData themeData;
  late bool themeMode;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    themeData = Theme.of(context);
    themeMode = themeData.brightness == Brightness.light;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(builder: (context, constraint){
        return SizedBox(
          width: constraint.maxWidth,
          height: constraint.maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getConfigurationCategory(),
              Expanded(
                child: widget.configPvd.selectedConfigurationTab == 0 ?
                    SourceConfiguration(configPvd: widget.configPvd)
                    : widget.configPvd.selectedConfigurationTab == 1
                    ? PumpConfiguration(configPvd: widget.configPvd)
                    : widget.configPvd.selectedConfigurationTab == 2
                    ? FiltrationConfiguration(configPvd: widget.configPvd)
                    : widget.configPvd.selectedConfigurationTab == 3
                    ? FertilizationConfiguration(configPvd: widget.configPvd)
                    : widget.configPvd.selectedConfigurationTab == 4 
                    ? MoistureConfiguration(configPvd: widget.configPvd)
                    : widget.configPvd.selectedConfigurationTab == 5
                    ? EcConfiguration(configPvd: widget.configPvd,)
                    : widget.configPvd.selectedConfigurationTab == 6
                    ? PhConfiguration(configPvd: widget.configPvd,)
                    : widget.configPvd.selectedConfigurationTab == 7 ?
                    PressureConfiguration(configPvd: widget.configPvd) :
                    widget.configPvd.selectedConfigurationTab == 8 ?
                    ValveConfiguration(configPvd: widget.configPvd) :
                    widget.configPvd.selectedConfigurationTab == 9 ?
                    ChannelConfiguration(configPvd: widget.configPvd)
                        : LineConfiguration(configPvd: widget.configPvd)
              )
            ],
          ),
        );
      }),
    );
  }

  Widget getConfigurationCategory(){
    List<int> listOfCategory = [];
    for(var device in widget.configPvd.listOfDeviceModel){
      if(device.categoryId != 1 && device.masterId != null && !listOfCategory.contains(device.categoryId)){
        listOfCategory.add(device.categoryId);
      }
    }
    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 10,
             mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for(var tab in widget.configPvd.configurationTab.entries)
                if(
                widget.configPvd.listOfGeneratedObject.any((object) => object.objectId == widget.configPvd.configurationTabObjectId[tab.key])
                &&
                showTabForAquaCulture(tab.key)
                )
                  InkWell(
                    onTap: (){
                    setState(() {
                      widget.configPvd.selectedConfigurationTab = tab.key;
                    });
                  },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                    padding: EdgeInsets.symmetric(horizontal: 15,vertical: widget.configPvd.selectedConfigurationTab == tab.key ? 12 :10),
                    decoration: BoxDecoration(
                      border: const Border(top: BorderSide(width: 0.5), left: BorderSide(width: 0.5), right: BorderSide(width: 0.5)),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                        color: widget.configPvd.selectedConfigurationTab == tab.key ? themeData.primaryColor : Colors.grey.shade100
                    ),
                    child: Text(tab.value, style: TextStyle(color: widget.configPvd.selectedConfigurationTab == tab.key ? Colors.white : Colors.black, fontSize: 13),),
                  ),
                  )
            ],
          ),
        ),
        Container(
          width: double.infinity,
          height: 3,
          color: themeData.primaryColor,
        )
      ],
    );
    return child;
  }

  bool showTabForAquaCulture(int tabKey){
    bool isAquaCultureGem = AppConstants.aquacultureModelList.contains(widget.configPvd.masterData['modelId']);
    if(!isAquaCultureGem) return true;
    List<int> tabKeyNotToShowForAquaCulture = [1, 2, 3, 4, 5, 6, 7];
    if(tabKeyNotToShowForAquaCulture.contains(tabKey)) {
      print("these tab not to show aqua culture..");
      return false;
    }
    return true;
  }
}

DeviceObjectModel getObjectName(double sNo,ConfigMakerProvider configPvd){
  return configPvd.listOfGeneratedObject.firstWhere((object) => object.sNo! == sNo);
}