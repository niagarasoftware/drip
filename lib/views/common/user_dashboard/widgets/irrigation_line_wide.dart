import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/views/common/user_dashboard/widgets/sensor_widget.dart';
import 'package:oro_drip_irrigation/views/common/user_dashboard/widgets/valve_widget.dart';
import 'package:provider/provider.dart';

import '../../../../Widgets/pump_widget.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../../../customer/widgets/agitator_widget.dart';
import '../../../customer/widgets/booster_widget.dart';
import '../../../customer/widgets/channel_widget.dart';
import '../../../customer/widgets/fan_widget.dart';
import '../../../customer/widgets/filter_builder.dart';
import '../../../customer/widgets/gate_widget.dart';
import '../../../customer/widgets/light_widget.dart';
import '../../../customer/widgets/main_valve_widget.dart';
import '../../../customer/widgets/source_column_widget.dart';
import 'customer_widget_builders.dart';
import 'fertilizer_live_panel.dart';

class IrrigationLineWide extends StatelessWidget {
  final int customerId, controllerId, modelId;
  final String deviceId;
  final List<WaterSourceModel> inletWaterSources;
  final List<WaterSourceModel> outletWaterSources;
  final List<FilterSiteModel> cFilterSite;
  final List<FertilizerSiteModel> cFertilizerSite;
  final List<FilterSiteModel> lFilterSite;
  final List<FertilizerSiteModel> lFertilizerSite;

  final List<ValveModel> valves;
  final List<MainValveModel> mainValves;
  final List<LightModel> lights;
  final List<GateModel> gates;
  final List<FanModel> fans;
  final List<SensorModel> prsSwitch;
  final List<SensorModel> pressureIn;
  final List<SensorModel> pressureOut;
  final List<SensorModel> waterMeter;
  final List<SensorModel> humidity;
  final List<SensorModel> co2;
  final List<SensorModel> temperature;
  final List<SensorModel> soilTemperature;
  final double containerWidth;
  final bool isNava;


  IrrigationLineWide({
    super.key,
    required this.inletWaterSources,
    required this.outletWaterSources,
    required this.cFilterSite,
    required this.cFertilizerSite,
    required this.lFilterSite,
    required this.lFertilizerSite,
    required this.valves,
    required this.mainValves,
    required this.lights,
    required this.fans,
    required this.gates,
    required this.prsSwitch,
    required this.pressureIn,
    required this.pressureOut,
    required this.waterMeter,
    required this.humidity,
    required this.co2,
    required this.temperature,
    required this.soilTemperature,
    required this.customerId,
    required this.controllerId,
    required this.deviceId,
    required this.containerWidth,
    required this.modelId,
    required this.isNava,
  });

  final ValueNotifier<int> popoverUpdateNotifier = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {

    final allValveWidgets = [

      ...mainValveList(
        list: mainValves,
        customerId: customerId,
        controllerId: controllerId,
        modelId: modelId,
        isNarrow: false,
      ),

      ...valveList(
        valves: valves,
        customerId: customerId,
        controllerId: controllerId,
        modelId: modelId,
        isNarrow: false,
        prsOutIsAval: pressureOut.isNotEmpty,
      ),

    ];

    final gateWidgets = gates.asMap().entries.map((entry) {
      return GateWidget(objGate: entry.value);
    }).toList();

    final fanWidgets = fans.asMap().entries.map((entry) {
      return FanWidget(objFan: entry.value, isWide: true);
    }).toList();

    final lightWidgets = lights.asMap().entries.map((entry) {
      return LightWidget(objLight: entry.value, isWide: true);
    }).toList();

    final allItems = [
      if (inletWaterSources.isNotEmpty)
        ..._buildWaterSource(context, inletWaterSources, true, true, cFertilizerSite.isNotEmpty? true : false),

      if (outletWaterSources.isNotEmpty)
        ..._buildWaterSource(context, outletWaterSources, inletWaterSources.isNotEmpty, false, cFertilizerSite.isNotEmpty),

      if (cFilterSite.isNotEmpty)
        ...buildFilter(context, cFilterSite, cFertilizerSite.isNotEmpty, false, false),

      if (lFilterSite.isNotEmpty)
        ...buildFilter(context, lFilterSite, (cFertilizerSite.isNotEmpty || lFertilizerSite.isNotEmpty), false, false),

      if (cFertilizerSite.isNotEmpty)
        ..._buildFertilizer(context, cFertilizerSite, isNava),

      if (lFertilizerSite.isNotEmpty)
        ..._buildFertilizer(context, lFertilizerSite, isNava),

      ...lightWidgets,
      ...fanWidgets,
      ..._buildSensorItems(prsSwitch, 'Pressure Switch', 'assets/png/pressure_switch_wj.png'),
      ..._buildSensorItems(pressureIn, 'Pressure Sensor', 'assets/png/pressure_sensor_wj.png'),
      ..._buildSensorItems(waterMeter, 'Water Meter', 'assets/png/water_meter_wj.png'),
      ...allValveWidgets,
      ..._buildSensorItems(pressureOut, 'Pressure Sensor', 'assets/png/pressure_sensor_wjl.png'),
      ..._buildSensorItems(co2, 'CO2 Sensor', 'assets/png/co2_sensor_wj.png'),
      ..._buildSensorItems(humidity, 'Humidity Sensor', 'assets/png/humidity_sensor_wj.png'),
      ..._buildSensorItems(temperature, 'Temperature Sensor', 'assets/png/temperature_sensor.png'),
      ..._buildSensorItems(soilTemperature, 'Soil Temperature Sensor', 'assets/png/Soil_temperature.png'),
      ...gateWidgets,
    ];

    print(allItems);

    int cFrtChannelCount = 0;
    int lFrtChannelCount = 0;

    if(cFertilizerSite.isNotEmpty) {
      cFrtChannelCount = (cFertilizerSite[0].channel.length + cFertilizerSite[0].agitator.length + 2);
    }
    if(lFertilizerSite.isNotEmpty){
      lFrtChannelCount = (lFertilizerSite[0].channel.length + lFertilizerSite[0].agitator.length + 2);
    }

    int itemsPerRow = ((MediaQuery.sizeOf(context).width - 140) / 67).floor() -
        (cFrtChannelCount + lFrtChannelCount);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: 0,
          children: allItems.asMap().entries.map<Widget>((entry) {

            final index = entry.key;
            final item = entry.value;

            if(cFertilizerSite.isNotEmpty) {
              if (((item is ValveWidget) || (item is BuildMainValve)
                  ||(item is LightWidget)||(item is SensorWidget))
                  && index < itemsPerRow) {
                return Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: item,
                );
              }
              else{
                return item;
              }
            }
            else{
              return item;
            }
          }).toList(),
        ),
      ),
    );
  }

  List<Widget> _buildWaterSource(
      BuildContext context,
      List<WaterSourceModel> waterSources,
      bool isAvailInlet,
      bool isInlet,
      bool isAvailFertilizer,
      ) {
    final List<Widget> gridItems = [];

    for (int index = 0; index < waterSources.length; index++) {
      final source = waterSources[index];

      // --------------------------------------------------
      // WATER SOURCE
      // --------------------------------------------------
      gridItems.add(
        Padding(
          padding: EdgeInsets.only(
            top: isAvailFertilizer ? 38.5 : 8,
          ),
          child: SourceColumnWidget(
            source: source,
            isInletSource: isInlet,
            isAvailInlet: isAvailInlet,
            index: index,
            total: waterSources.length,
            popoverUpdateNotifier: popoverUpdateNotifier,
            deviceId: deviceId,
            customerId: customerId,
            controllerId: controllerId,
            modelId: modelId,
            isMobile: false,
            isAvailFrtSite:
            (cFertilizerSite.isNotEmpty || lFertilizerSite.isNotEmpty),
          ),
        ),
      );

      // --------------------------------------------------
      // PUMP + WATER METER
      // --------------------------------------------------
      for (final pump in source.outletPump) {
        gridItems.add(
          Padding(
            padding: EdgeInsets.only(
              top: isAvailFertilizer ? 38.5 : 8,
            ),
            child: PumpWidget(
              pump: pump,
              isSourcePump: isInlet,
              deviceId: deviceId,
              customerId: customerId,
              controllerId: controllerId,
              isMobile: false,
              modelId: modelId,
              pumpPosition: 'First',
              isNova: false,
              isAvailFrtSite:
              (cFertilizerSite.isNotEmpty || lFertilizerSite.isNotEmpty),
            ),
          ),
        );

        // Water Meter — only if this pump actually has one
        if (pump.waterMeter.isNotEmpty) {
          gridItems.add(
            Padding(
              padding: EdgeInsets.only(
                top: isAvailFertilizer ? 30.5 : 8,
              ),
              child: SensorWidget(
                sensor: pump.waterMeter.first,
                sensorType: 'Water Meter',
                imagePath: 'assets/png/water_meter_wj.png',
                customerId: customerId,
                controllerId: controllerId,
              ),
            ),
          );
        }
      }

    }

    return gridItems;
  }

 /* List<Widget> _buildWaterSource(BuildContext context, List<WaterSourceModel> waterSources,
      bool isAvailInlet, bool isInlet, bool isAvailFertilizer) {

    final List<Widget> gridItems = [];
    for (int index = 0; index < waterSources.length; index++) {
      final source = waterSources[index];
      gridItems.add(Padding(
        padding: EdgeInsets.only(top: isAvailFertilizer? 38.5:8),
        child: SourceColumnWidget(
          source: source,
          isInletSource: isInlet,
          isAvailInlet: isAvailInlet,
          index: index,
          total: waterSources.length,
          popoverUpdateNotifier: popoverUpdateNotifier,
          deviceId: deviceId,
          customerId: customerId,
          controllerId: controllerId,
          modelId: modelId,
          isMobile: false,
          isAvailFrtSite: (cFertilizerSite.isNotEmpty || lFertilizerSite.isNotEmpty),
        ),
      ));
      gridItems.addAll(source.outletPump.map((pump) => Padding(
        padding: EdgeInsets.only(top: isAvailFertilizer? 38.5:8),
        child: PumpWidget(
          pump: pump,
          isSourcePump: isInlet,
          deviceId: deviceId,
          customerId: customerId,
          controllerId: controllerId,
          isMobile: false,
          modelId: modelId,
          pumpPosition: 'First',
          isNova: false,
          isAvailFrtSite: (cFertilizerSite.isNotEmpty || lFertilizerSite.isNotEmpty),
        ),
      )));
    }
    return gridItems;
  }*/

  List<Widget> _buildSensorItems(List<SensorModel> sensors, String type, String imagePath) {
    return sensors.map((sensor) {
      return SensorWidget(
        sensor: sensor,
        sensorType: type,
        imagePath: imagePath,
        customerId: customerId,
        controllerId: controllerId,
      );
    }).toList();
  }


  List<Widget> _buildFertilizer(
      BuildContext context,
      List<FertilizerSiteModel> fertilizerSite,
      bool isNova,
      ) {
    return List.generate(fertilizerSite.length, (siteIndex) {
      final site = fertilizerSite[siteIndex];
      final widgets = <Widget>[];

      // Vertical line before each site except the first.
      if (siteIndex != 0) {
        widgets.add(_buildVerticalLine(height: 120));
      }

      // Booster pump.
      widgets.add(
        BoosterWidget(
          fertilizerSite: site,
          isMobile: false,
        ),
      );

      // Channels.
      for (int channelIndex = 0;
      channelIndex < site.channel.length;
      channelIndex++) {
        final channel = site.channel[channelIndex];

        widgets.add(
          ChannelWidget(
            channel: channel,
            cIndex: channelIndex,
            channelLength: site.channel.length,
            agitator: site.agitator,
            siteSno: site.sNo.toString(),
            isMobile: false,
          ),
        );
      }

      // Multiple agitators.
      if (site.agitator.isNotEmpty) {
        widgets.add(
          AgitatorWidget(
            fertilizerSite: site,
            isMobile: false,
          ),
        );
      }

      // Ending vertical line on web.
      if (kIsWeb) {
        widgets.add(_buildVerticalLine(height: 130));
      }

      /*// Calculate widths.
      final boosterPumpWidth = site.boosterPump.length * 70.0;
      final channelWidth = site.channel.length * 70.0;
      final agitatorWidth = site.agitator.isNotEmpty ? 57.5 : 0.0;
      final totalWidth = boosterPumpWidth + channelWidth + agitatorWidth;*/

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets,
            ),
            Positioned(
              left: 3,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.grey,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  site.name,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      return SizedBox(
        //width: agitatorWidth > 0 ? totalWidth : totalWidth + 5.5,
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: widgets.map((widget) {
                return InkWell(
                  onTap: () {
                    final customerVM =
                    context.read<CustomerScreenControllerViewModel>();

                    showRightSheet(
                      context,
                      ChangeNotifierProvider.value(
                        value: customerVM,
                        child: FertilizerLivePanel(
                          deviceId: deviceId,
                          controllerId: controllerId,
                          customerId: customerId,
                          isWide: true,
                        ),
                      ),
                    );
                  },
                  child: widget,
                );
              }).toList(),
            ),
            // Site name.
            Positioned(
              left: 3,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.grey,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  site.name,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /*List<Widget> _buildFertilizer(BuildContext context,
      List<FertilizerSiteModel> fertilizerSite, bool isNova) {
    return List.generate(fertilizerSite.length, (siteIndex) {
      final site = fertilizerSite[siteIndex];
      final widgets = <Widget>[];

      if (siteIndex != 0) {
        widgets.add(_buildVerticalLine(height: 120));
      }

      widgets.add(BoosterWidget(fertilizerSite: site, isMobile: false));

      for (int channelIndex = 0; channelIndex < site.channel.length; channelIndex++) {
        final channel = site.channel[channelIndex];

        widgets.add(ChannelWidget(
          channel: channel,
          cIndex: channelIndex,
          channelLength: site.channel.length,
          agitator: site.agitator,
          siteSno: site.sNo.toString(),
          isMobile: false,
        ));

        if (channelIndex == site.channel.length - 1 && site.agitator.isNotEmpty) {
          widgets.add(AgitatorWidget(
            fertilizerSite: site,
            isMobile: false,
          ));
        }
      }

      if (kIsWeb) {
        widgets.add(_buildVerticalLine(height: 130));
      }

      final boosterPumpWidth = site.boosterPump.length * 70.0;
      final channelWidth = site.channel.length * 70.0;
      final agitatorWidth = site.agitator.length * 57.5;

      final totalWidth = boosterPumpWidth + channelWidth + agitatorWidth;

      return SizedBox(
        width: agitatorWidth>0? totalWidth : totalWidth+5.5,
        //width: ((site.boosterPump.length + site.channel.length + site.agitator.length ) * 70) + 5,
        child: Stack(
          children: [
            Row(
              children: widgets.map((w) {
                return InkWell(
                  onTap: () {
                    final customerVM = context.read<CustomerScreenControllerViewModel>();
                    showRightSheet(
                      context,
                      ChangeNotifierProvider.value(
                        value: customerVM,
                        child: FertilizerLivePanel(
                          deviceId: deviceId,
                          controllerId: controllerId,
                          customerId: customerId,
                          isWide: true,
                        ),
                      ),
                    );
                  },
                  child: w,
                );
              }).toList(),
            ),
            // Row(children: widgets),
            Positioned(
              left: 3,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey, width: 0.5),
                ),
                child: Text(
                  site.name,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

    }).toList();
  }*/

  Widget _buildVerticalLine({required double height}) {
    return SizedBox(
      width: 4.5,
      height: height,
      child: const Row(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 42.0, bottom: 5),
            child: VerticalDivider(width: 0, color: Colors.black12),
          ),
          SizedBox(width: 4.5),
          Padding(
            padding: EdgeInsets.only(top: 46.0, bottom: 2),
            child: VerticalDivider(width: 0, color: Colors.black12),
          ),
        ],
      ),
    );
  }


  void showRightSheet(BuildContext context, Widget child) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "LiveData",
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            elevation: 10,
            child: SizedBox(
              width: 600,
              height: double.infinity,
              child: child,
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }
}