import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

import '../../../../StateManagement/mqtt_payload_provider.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/my_function.dart';
import '../../../customer/widgets/float_switch_popover.dart';
import '../../../customer/widgets/valve_sensors_popover.dart';

class ValveWidget extends StatelessWidget {
  final ValveModel valve;
  final int customerId, controllerId, modelId;
  final bool isLastValve;
  const ValveWidget({
    super.key,
    required this.valve,
    required this.customerId,
    required this.controllerId,
    required this.isLastValve,
    required this.modelId,
  });

  void _openSensorsPopover(
      BuildContext context, {
        String? section,
        double popoverHeight = 340,
        bool hasAnySensor = false,
      }) {
    showPopover(
      context: context,
      bodyBuilder: (context) => ValveSensorsPopover(
        valve: valve,
        customerId: customerId,
        controllerId: controllerId,
        initialSection: section,
      ),
      direction: PopoverDirection.bottom,
      width: hasAnySensor ? 580 : 270,
      height: popoverHeight,
      arrowHeight: 15,
      arrowWidth: 30,
      barrierColor: Colors.black54,
      arrowDyOffset: -40,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getValveOnOffStatus(
        [...AppConstants.ecoGemModelList].contains(modelId)
            ? double.parse(valve.sNo.toString()).toStringAsFixed(3)
            : valve.sNo.toString(),
      ),
      builder: (_, status, __) {
        // ---- Parse incoming MQTT status ----
        final statusParts = status?.split(',') ?? [];
        if (statusParts.length > 1) {
          valve.status = int.tryParse(statusParts[1]) ?? 0;
          valve.completePercent = statusParts.length > 2
              ? (int.tryParse(statusParts[2]) ?? 0)
              : 0;
          if (statusParts.length > 3) {
            valve.lastRunningDT = statusParts[3];
          }
        }

        // ---- Sensor availability flags (single source of truth) ----
        final bool hasMoisture = valve.moistureSensors.isNotEmpty;
        final bool hasSoilTemperature = valve.soilTemperature.isNotEmpty;
        final bool hasInputPressure = valve.inputPressure.isNotEmpty;
        final bool hasLateralPressure = valve.lateralPressure.isNotEmpty;
        final bool hasWaterSource = valve.waterSources.isNotEmpty;
        final bool hasAnySensor =
            hasMoisture || hasSoilTemperature || hasInputPressure || hasLateralPressure;

        final ValueNotifier<int> popoverUpdateNotifier = ValueNotifier<int>(0);

        // ---- Sensor chip builder ----
        Widget buildSensorChip({
          required IconData icon,
          required Color color,
          required String label,
          required VoidCallback onTap,
        }) {
          return GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.all(1),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 0.7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 9, color: color),
                  const SizedBox(width: 1),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Builds each sensor-type chip and returns them as a flat list,
        // in a fixed order: moisture, input pressure, lateral pressure, soil temp.
        List<Widget> buildSensorChips({double popoverHeight = 340}) {
          final chips = <Widget>[];

          if (hasMoisture) {
            chips.add(Consumer<MqttPayloadProvider>(
              builder: (_, provider, __) {
                for (var sensor in valve.moistureSensors) {
                  final sensorUpdate =
                  provider.getSensorUpdatedValve(sensor.sNo.toString());
                  final parts = sensorUpdate?.split(',') ?? [];
                  if (parts.length > 1) {
                    sensor.value = parts[1];
                  }
                }
                final sensorList = valve.moistureSensors
                    .map((sensor) => {
                  'name': sensor.name,
                  'value': sensor.value,
                })
                    .toList();

                return buildSensorChip(
                  icon: Icons.water_drop,
                  color: MyFunction().getMoistureColor(sensorList),
                  label: 'M',
                  onTap: () => _openSensorsPopover(
                    context,
                    section: 'moisture',
                    popoverHeight: popoverHeight,
                    hasAnySensor: true,
                  ),
                );
              },
            ));
          }

          if (hasInputPressure) {
            chips.add(Consumer<MqttPayloadProvider>(
              builder: (_, provider, __) {
                for (var sensor in valve.inputPressure) {
                  final sensorUpdate =
                  provider.getSensorUpdatedValve(sensor.sNo.toString());
                  final parts = sensorUpdate?.split(',') ?? [];
                  if (parts.length > 1) {
                    sensor.value = parts[1];
                  }
                }
                return buildSensorChip(
                  icon: Icons.speed,
                  color: Colors.orange,
                  label: 'IP',
                  onTap: () => _openSensorsPopover(
                    context,
                    section: 'inputPressure',
                    popoverHeight: popoverHeight,
                    hasAnySensor: true,
                  ),
                );
              },
            ));
          }

          if (hasLateralPressure) {
            chips.add(Consumer<MqttPayloadProvider>(
              builder: (_, provider, __) {
                for (var sensor in valve.lateralPressure) {
                  final sensorUpdate =
                  provider.getSensorUpdatedValve(sensor.sNo.toString());
                  final parts = sensorUpdate?.split(',') ?? [];
                  if (parts.length > 1) {
                    sensor.value = parts[1];
                  }
                }
                return buildSensorChip(
                  icon: Icons.speed,
                  color: Colors.lightBlue,
                  label: 'LT',
                  onTap: () => _openSensorsPopover(
                    context,
                    section: 'lateralPressure',
                    popoverHeight: popoverHeight,
                    hasAnySensor: true,
                  ),
                );
              },
            ));
          }

          if (hasSoilTemperature) {
            chips.add(Consumer<MqttPayloadProvider>(
              builder: (_, provider, __) {
                for (var sensor in valve.soilTemperature) {
                  final sensorUpdate =
                  provider.getSensorUpdatedValve(sensor.sNo.toString());
                  final parts = sensorUpdate?.split(',') ?? [];
                  if (parts.length > 1) {
                    sensor.value = parts[1];
                  }
                }
                return buildSensorChip(
                  icon: Icons.thermostat,
                  color: Colors.deepOrange,
                  label: 'SOT',
                  onTap: () => _openSensorsPopover(
                    context,
                    section: 'soilTemp',
                    popoverHeight: popoverHeight,
                    hasAnySensor: true,
                  ),
                );
              },
            ));
          }

          return chips;
        }

        // Returns the sensor chips as two stacked Positioned rows:
        // the first 2 chips at top:19, any remaining chips at top:65.
        List<Widget> buildSensorPositioned({double popoverHeight = 340}) {
          final chips = buildSensorChips(popoverHeight: popoverHeight);
          if (chips.isEmpty) return const [];

          final topRow = chips.take(2).toList();
          final bottomRow =
          chips.length > 2 ? chips.skip(2).toList() : const <Widget>[];

          final widgets = <Widget>[
            Positioned(
              top: 19,
              left: 0,
              right: 0,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 1,
                runSpacing: 1,
                children: topRow,
              ),
            ),
          ];

          if (bottomRow.isNotEmpty) {
            widgets.add(
              Positioned(
                top: 65,
                left: 0,
                right: 0,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 1,
                  runSpacing: 1,
                  children: bottomRow,
                ),
              ),
            );
          }

          return widgets;
        }

        // ---- Water-source valve layout ----
        if (hasWaterSource) {
          return SizedBox(
            width: 140,
            height: 100,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LEFT: valve icon + name + optional last-opened time
                SizedBox(
                  width: 70,
                  height: 100,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _openSensorsPopover(
                                context,
                                hasAnySensor: hasAnySensor,
                                popoverHeight: hasAnySensor ? 340 : 70,
                              ),
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: AppConstants.getAsset(
                                  'valve_cws',
                                  valve.status,
                                  '',
                                  valve.completePercent,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            valve.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      ...buildSensorPositioned(),
                    ],
                  ),
                ),

                // RIGHT: water source icon + level + float switch
                SizedBox(
                  width: 70,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: AppConstants.getAsset(
                              'source',
                              0,
                              'After Valve',
                              0,
                            ),
                          ),
                          Text(
                            valve.waterSources[0].name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      if (valve.waterSources[0].level.isNotEmpty) ...[
                        Positioned(
                          top: 20,
                          left: 2,
                          right: 2,
                          child: Consumer<MqttPayloadProvider>(
                            builder: (_, provider, __) {
                              final sensorUpdate = provider
                                  .getSensorUpdatedValve(valve
                                  .waterSources[0].level[0].sNo
                                  .toString());
                              final parts = sensorUpdate?.split(',') ?? [];

                              if (parts.length > 1) {
                                valve.waterSources[0].level.first.value =
                                parts[1];
                              }

                              return Container(
                                height: 17,
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 0.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    MyFunction().getUnitByParameter(
                                      context,
                                      'Level Sensor',
                                      valve.waterSources[0].level.first.value
                                          .toString(),
                                    ) ??
                                        '',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 43,
                          left: 18,
                          right: 18,
                          child: Consumer<MqttPayloadProvider>(
                            builder: (_, provider, __) {
                              final sensorUpdate = provider
                                  .getSensorUpdatedValve(valve
                                  .waterSources[0].level[0].sNo
                                  .toString());
                              final parts = sensorUpdate?.split(',') ?? [];

                              if (parts.length > 2) {
                                valve.waterSources[0].level.first.value =
                                parts[2];
                              }

                              return Container(
                                height: 17,
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 0.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${valve.waterSources[0].level.first.value}%',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (valve.waterSources.isNotEmpty)
                        FloatSwitchPopover(
                          source: valve.waterSources[0],
                          popoverUpdateNotifier: popoverUpdateNotifier,
                          isMobile: false,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // ---- Plain valve (no water source) layout ----
        return SizedBox(
          width: 70,
          height: 100,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _openSensorsPopover(
                        context,
                        popoverHeight: hasAnySensor ? 340 : 70,
                        hasAnySensor: hasAnySensor,
                      ),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: AppConstants.getAsset(
                          isLastValve ? 'valve_lj' : 'valve',
                          valve.status,
                          '',
                          valve.completePercent,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    valve.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              ...buildSensorPositioned(popoverHeight: 340),
            ],
          ),
        );
      },
    );
  }
}

/*

import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

import '../../../../StateManagement/mqtt_payload_provider.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/my_function.dart';
import '../../../customer/widgets/float_switch_popover.dart';

class ValveWidget extends StatelessWidget {
  final ValveModel valve;
  final int customerId, controllerId, modelId;
  final bool isLastValve;
  const ValveWidget({super.key, required this.valve, required this.customerId,
    required this.controllerId, required this.isLastValve, required this.modelId});

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getValveOnOffStatus([...AppConstants.ecoGemModelList].contains(modelId) ?
      double.parse(valve.sNo.toString()).toStringAsFixed(3): valve.sNo.toString()),
      builder: (_, status, __) {

        final statusParts = status?.split(',') ?? [];
        if(statusParts.isNotEmpty){
          valve.status = int.parse(statusParts[1]);
          if(statusParts.length > 2){
            valve.completePercent = int.parse(statusParts[2]);
          }else{
            valve.completePercent = 0;
          }
        }

        bool hasMoisture = valve.moistureSensors.isNotEmpty;
        bool hasSoilTemperature = valve.soilTemperature.isNotEmpty;
        bool hasInputPressure = valve.inputPressure.isNotEmpty;
        bool hasLateralPressure = valve.lateralPressure.isNotEmpty;
        bool hasWaterSource = valve.waterSources.isNotEmpty;

        final ValueNotifier<int> popoverUpdateNotifier = ValueNotifier<int>(0);


        return hasWaterSource ? SizedBox(
          width: 140,
          height: 100,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: AppConstants.getAsset('valve_cws', valve.status, '', valve.completePercent),
                        ),
                        Text(
                          valve.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                    if (hasMoisture)
                      Positioned(
                        top: 20,
                        left: 33,
                        child: TextButton(
                          onPressed: () async {

                            showPopover(
                              context: context,
                              bodyBuilder: (context) {
                                return MoistureSensorPopover(valve: valve,
                                  customerId: customerId, controllerId: controllerId);
                              },
                              direction: PopoverDirection.bottom,
                              width: 580,
                              height: 700,
                              arrowHeight: 15,
                              arrowWidth: 30,
                              barrierColor: Colors.black54,
                              arrowDyOffset: -40,
                            );
                          },
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(EdgeInsets.zero),
                            minimumSize: WidgetStateProperty.all(Size.zero),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: WidgetStateProperty.all(Colors.transparent),
                          ),
                          child: Consumer<MqttPayloadProvider>(
                            builder: (_, provider, __) {

                              for (var sensor in valve.moistureSensors) {
                                final sensorUpdate = provider.getSensorUpdatedValve(sensor.sNo.toString());
                                final statusParts = sensorUpdate?.split(',') ?? [];
                                if (statusParts.length > 1) {
                                  sensor.value = statusParts[1];
                                }
                              }

                              final sensorList = valve.moistureSensors.map((sensor) => {
                                'name': sensor.name,
                                'value': sensor.value,
                              }).toList();

                              return CircleAvatar(
                                radius: 15,
                                backgroundColor: MyFunction().getMoistureColor(sensorList),
                                child: Image.asset(
                                  'assets/png/moisture_sensor.png',
                                  width: 25,
                                  height: 25,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 70,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: AppConstants.getAsset('source', 0, 'After Valve', 0),
                        ),
                        Text(
                          valve.waterSources[0].name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                    if (valve.waterSources[0].level.isNotEmpty) ...[
                      Positioned(
                        top: 20,
                        left: 2,
                        right: 2,
                        child: Consumer<MqttPayloadProvider>(
                          builder: (_, provider, __) {
                            final sensorUpdate = provider.getSensorUpdatedValve(valve.waterSources[0].level[0].sNo.toString());
                            final statusParts = sensorUpdate?.split(',') ?? [];

                            if (statusParts.length > 1) {
                              valve.waterSources[0].level.first.value = statusParts[1];
                            }

                            return Container(
                              height: 17,
                              decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: Colors.grey, width: 0.5),
                              ),
                              child: Center(
                                child: Text(
                                  MyFunction().getUnitByParameter(context, 'Level Sensor', valve.waterSources[0].level.first.value.toString()) ?? '',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 43,
                        left: 18,
                        right: 18,
                        child: Consumer<MqttPayloadProvider>(
                          builder: (_, provider, __) {
                            final sensorUpdate = provider.getSensorUpdatedValve(valve.waterSources[0].level[0].sNo.toString());
                            final statusParts = sensorUpdate?.split(',') ?? [];

                            if (statusParts.length > 2) {
                              valve.waterSources[0].level.first.value = statusParts[2];
                            }

                            return Container(
                              height: 17,
                              decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey, width: 0.5),
                              ),
                              child: Center(
                                child: Text(
                                  '${valve.waterSources[0].level.first.value}%',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );

                          },
                        ),
                      ),
                    ],

                    if (valve.waterSources.isNotEmpty) FloatSwitchPopover(source: valve.waterSources[0],
                        popoverUpdateNotifier: popoverUpdateNotifier, isMobile: false),
                  ],
                ),
              )
            ],
          ),
        ) :
        SizedBox(
          width: 70,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: AppConstants.getAsset(isLastValve? 'valve_lj' : 'valve', valve.status, '', valve.completePercent),
                  ),
                  Text(
                    valve.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
              if (hasMoisture)
                Positioned(
                  top: 20,
                  left: 33,
                  child: TextButton(
                    onPressed: () async {

                      showPopover(
                        context: context,
                        bodyBuilder: (context) {
                          return MoistureSensorPopover(valve: valve,
                            customerId: customerId, controllerId: controllerId);
                        },
                        direction: PopoverDirection.bottom,
                        width: 580,
                        height: 340,
                        arrowHeight: 15,
                        arrowWidth: 30,
                        barrierColor: Colors.black54,
                        arrowDyOffset: -40,
                      );
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                      minimumSize: WidgetStateProperty.all(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Consumer<MqttPayloadProvider>(
                      builder: (_, provider, __) {

                        for (var sensor in valve.moistureSensors) {
                          final sensorUpdate = provider.getSensorUpdatedValve(sensor.sNo.toString());
                          final statusParts = sensorUpdate?.split(',') ?? [];
                          if (statusParts.length > 1) {
                            sensor.value = statusParts[1];
                          }
                        }

                        final sensorList = valve.moistureSensors.map((sensor) => {
                          'name': sensor.name,
                          'value': sensor.value,
                        }).toList();

                        return CircleAvatar(
                          radius: 15,
                          backgroundColor: MyFunction().getMoistureColor(sensorList),
                          child: Image.asset(
                            'assets/png/moisture_sensor.png',
                            width: 25,
                            height: 25,
                          ),
                        );
                      },
                    ),
                  ),
                ),

              if (hasInputPressure)
                Positioned(
                  top: 15,
                  left: 0,
                  child: TextButton(
                    onPressed: () async {
                      showPopover(
                        context: context,
                        bodyBuilder: (context) {
                          return PressureSensorPopover(
                            valve: valve,
                            customerId: customerId,
                            controllerId: controllerId,
                            sensorType: 'input',
                          );
                        },
                        direction: PopoverDirection.bottom,
                        width: 580,
                        height: 320,
                        arrowHeight: 15,
                        arrowWidth: 30,
                        barrierColor: Colors.black54,
                        arrowDyOffset: -70,
                      );
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                      minimumSize: WidgetStateProperty.all(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Consumer<MqttPayloadProvider>(
                      builder: (_, provider, __) {
                        for (var sensor in valve.inputPressure) {
                          final sensorUpdate = provider.getSensorUpdatedValve(sensor.sNo.toString());
                          final statusParts = sensorUpdate?.split(',') ?? [];
                          if (statusParts.length > 1) {
                            sensor.value = statusParts[1];
                          }
                        }

                        final displaySensor = valve.inputPressure.first;

                        return Container(
                          width: 65,
                          height: 17,
                          decoration: BoxDecoration(
                            color: Colors.yellowAccent,
                            borderRadius: const BorderRadius.all(Radius.circular(2)),
                            border: Border.all(color: Colors.grey, width: 0.5),
                          ),
                          child: Text(
                            "IP: ${MyFunction().getUnitByParameter(context, 'Pressure Sensor', displaySensor.value.toString()) ?? ''}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              if (hasLateralPressure)
                Positioned(
                  top: 63,
                  left: 0,
                  child: TextButton(
                    onPressed: () async {
                      showPopover(
                        context: context,
                        bodyBuilder: (context) {
                          return PressureSensorPopover(
                            valve: valve,
                            customerId: customerId,
                            controllerId: controllerId,
                            sensorType: 'lateral',
                          );
                        },
                        direction: PopoverDirection.bottom,
                        width: 580,
                        height: 320,
                        arrowHeight: 15,
                        arrowWidth: 30,
                        barrierColor: Colors.black54,
                        arrowDyOffset: -20,
                      );
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                      minimumSize: WidgetStateProperty.all(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Consumer<MqttPayloadProvider>(
                      builder: (_, provider, __) {
                        for (var sensor in valve.lateralPressure) {
                          final sensorUpdate = provider.getSensorUpdatedValve(sensor.sNo.toString());
                          final statusParts = sensorUpdate?.split(',') ?? [];
                          if (statusParts.length > 1) {
                            sensor.value = statusParts[1];
                          }
                        }

                        final displaySensor = valve.lateralPressure.first;

                        return Container(
                          width: 65,
                          height: 17,
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent,
                            borderRadius: const BorderRadius.all(Radius.circular(2)),
                            border: Border.all(color: Colors.grey, width: 0.5),
                          ),
                          child: Text(
                            "LT: ${MyFunction().getUnitByParameter(context, 'Pressure Sensor', displaySensor.value.toString()) ?? ''}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              if (hasSoilTemperature)
                Positioned(
                  top: 43,
                  left: 0,
                  child: TextButton(
                    onPressed: () async {
                      showPopover(
                        context: context,
                        bodyBuilder: (context) {
                          return PressureSensorPopover(
                            valve: valve,
                            customerId: customerId,
                            controllerId: controllerId,
                            sensorType: 'lateral',
                          );
                        },
                        direction: PopoverDirection.bottom,
                        width: 580,
                        height: 320,
                        arrowHeight: 15,
                        arrowWidth: 30,
                        barrierColor: Colors.black54,
                        arrowDyOffset: -20,
                      );
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                      minimumSize: WidgetStateProperty.all(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Consumer<MqttPayloadProvider>(
                      builder: (_, provider, __) {
                        for (var sensor in valve.soilTemperature) {
                          final sensorUpdate = provider.getSensorUpdatedValve(sensor.sNo.toString());
                          final statusParts = sensorUpdate?.split(',') ?? [];
                          if (statusParts.length > 1) {
                            sensor.value = statusParts[1];
                          }
                        }

                        final displaySensor = valve.soilTemperature.first;

                        return Container(
                          width: 65,
                          height: 17,
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent,
                            borderRadius: const BorderRadius.all(Radius.circular(2)),
                            border: Border.all(color: Colors.grey, width: 0.5),
                          ),
                          child: Text(
                            "SOT: ${MyFunction().getUnitByParameter(context, 'Temperature', displaySensor.value.toString()) ?? ''}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}*/
