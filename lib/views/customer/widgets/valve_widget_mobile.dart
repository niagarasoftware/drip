import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/my_function.dart';
import 'float_switch_popover.dart';
import 'valve_sensors_popover.dart';

class ValveWidgetMobile extends StatefulWidget {
  final ValveModel valve;
  final int customerId, controllerId, modelId;

  const ValveWidgetMobile({
    super.key,
    required this.valve,
    required this.customerId,
    required this.controllerId,
    required this.modelId,
  });

  @override
  State<ValveWidgetMobile> createState() => _ValveWidgetMobileState();
}

class _ValveWidgetMobileState extends State<ValveWidgetMobile> {

  void _openSensorsPopover(BuildContext context,
      {String? section, bool hasAnySensor = false}) {

    showPopover(
      context: context,
      bodyBuilder: (context) => ValveSensorsPopover(
        valve: widget.valve,
        customerId: widget.customerId,
        controllerId: widget.controllerId,
        initialSection: section,
      ),
      direction: PopoverDirection.bottom,
      width: hasAnySensor ? 550 : 270,
      height: hasAnySensor ? 340 : 70,
      arrowHeight: 15,
      arrowWidth: 30,
      barrierColor: Colors.black54,
      arrowDyOffset: -40,
    );
  }

  @override
  Widget build(BuildContext context) {
    final valve = widget.valve;

    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getValveOnOffStatus(
        [...AppConstants.ecoGemModelList].contains(widget.modelId)
            ? double.parse(valve.sNo.toString()).toStringAsFixed(3)
            : valve.sNo.toString(),
      ),
      builder: (_, status, __) {
        final statusParts = status?.split(',') ?? [];
        if (statusParts.isNotEmpty) {
          valve.status = int.tryParse(statusParts[1]) ?? valve.status;
          if(statusParts.length > 2){
            valve.completePercent = int.parse(statusParts[2]);
          }else{
            valve.completePercent = 0;
          }
        }

        final bool hasMoisture = valve.moistureSensors.isNotEmpty;
        final bool hasInputPressure = valve.inputPressure.isNotEmpty;
        final bool hasLateralPressure = valve.lateralPressure.isNotEmpty;
        final bool hasSoilTemperature = valve.soilTemperature.isNotEmpty;
        final bool hasWaterSource = valve.waterSources.isNotEmpty;
        final bool hasAnySensor = hasMoisture || hasInputPressure || hasLateralPressure || hasSoilTemperature;

        return hasWaterSource
            ? _buildWithSource(valve, hasMoisture, hasInputPressure, hasLateralPressure, hasSoilTemperature, hasAnySensor)
            : _buildWithoutSource(valve, hasMoisture, hasInputPressure, hasLateralPressure, hasSoilTemperature, hasAnySensor);
      },
    );
  }


  Widget _buildWithSource(ValveModel valve, bool hasMoisture, bool hasInputPressure, bool hasLateralPressure, bool hasSoilTemperature, bool hasAnySensor) {
    return SizedBox(
      width: 140,
      height: 65,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 65, height: 65, child: _buildValveIcon(valve, hasMoisture, hasInputPressure, hasLateralPressure, hasSoilTemperature, hasAnySensor)),
          SizedBox(width: 65, height: 65, child: _buildWaterSource(valve)),
        ],
      ),
    );
  }

  Widget _buildWithoutSource(ValveModel valve, bool hasMoisture, bool hasInputPressure, bool hasLateralPressure, bool hasSoilTemperature, bool hasAnySensor) {
    return SizedBox(width: 70, height: 70, child: _buildValveIcon(valve, hasMoisture, hasInputPressure, hasLateralPressure, hasSoilTemperature, hasAnySensor));
  }

  Widget _buildSensorChip({
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
          color: color.withOpacity(0.12),
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
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // Flat list of chip widgets, one per active sensor type, in a fixed order.
  List<Widget> _buildSensorChips(ValveModel valve, bool hasMoisture, bool hasInputPressure, bool hasLateralPressure, bool hasSoilTemperature) {
    final chips = <Widget>[];

    if (hasMoisture) {
      chips.add(Consumer<MqttPayloadProvider>(
        builder: (_, provider, __) {
          for (var sensor in valve.moistureSensors) {
            final sensorUpdate = provider.getSensorUpdatedValve(sensor.sNo.toString());
            final statusParts = sensorUpdate?.split(',') ?? [];
            if (statusParts.length > 1) {
              sensor.value = statusParts[1];
            }
          }
          final sensorList = valve.moistureSensors.map((s) => {'name': s.name, 'value': s.value}).toList();

          return _buildSensorChip(
            icon: Icons.water_drop,
            color: MyFunction().getMoistureColor(sensorList),
            label: 'M',
            onTap: () => _openSensorsPopover(context, section: 'moisture', hasAnySensor: true),
          );
        },
      ));
    }

    if (hasInputPressure) {
      chips.add(Consumer<MqttPayloadProvider>(
        builder: (_, provider, __) {
          for (var sensor in valve.inputPressure) {
            final sensorUpdate = provider.getSensorUpdatedValve(sensor.sNo.toString());
            final statusParts = sensorUpdate?.split(',') ?? [];
            if (statusParts.length > 1) {
              sensor.value = statusParts[1];
            }
          }
          return _buildSensorChip(
            icon: Icons.speed,
            color: Colors.orange,
            label: 'IP',
            onTap: () => _openSensorsPopover(context, section: 'inputPressure', hasAnySensor: true),
          );
        },
      ));
    }

    if (hasLateralPressure) {
      chips.add(Consumer<MqttPayloadProvider>(
        builder: (_, provider, __) {
          for (var sensor in valve.lateralPressure) {
            final sensorUpdate = provider.getSensorUpdatedValve(sensor.sNo.toString());
            final statusParts = sensorUpdate?.split(',') ?? [];
            if (statusParts.length > 1) {
              sensor.value = statusParts[1];
            }
          }
          return _buildSensorChip(
            icon: Icons.speed,
            color: Colors.lightBlue,
            label: 'LT',
            onTap: () => _openSensorsPopover(context, section: 'lateralPressure', hasAnySensor: true),
          );
        },
      ));
    }

    if (hasSoilTemperature) {
      chips.add(Consumer<MqttPayloadProvider>(
        builder: (_, provider, __) {
          for (var sensor in valve.soilTemperature) {
            final sensorUpdate = provider.getSensorUpdatedValve(sensor.sNo.toString());
            final statusParts = sensorUpdate?.split(',') ?? [];
            if (statusParts.length > 1) {
              sensor.value = statusParts[1];
            }
          }
          return _buildSensorChip(
            icon: Icons.thermostat,
            color: Colors.deepOrange,
            label: 'SOT',
            onTap: () => _openSensorsPopover(context, section: 'soilTemp', hasAnySensor: true),
          );
        },
      ));
    }

    return chips;
  }

  // First 2 chips positioned near the top (near the pipeline), any
  // remaining chips (3rd/4th) pinned to the bottom of the icon box.
  List<Widget> _buildSensorPositioned(ValveModel valve, bool hasMoisture, bool hasInputPressure, bool hasLateralPressure, bool hasSoilTemperature) {
    final chips = _buildSensorChips(valve, hasMoisture, hasInputPressure, hasLateralPressure, hasSoilTemperature);
    if (chips.isEmpty) return const [];

    final topRow = chips.take(2).toList();
    final bottomRow = chips.length > 2 ? chips.skip(2).toList() : const <Widget>[];

    final widgets = <Widget>[
      Positioned(
        top: 5,
        left: 0,
        right: 0,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 1,
          children: topRow,
        ),
      ),
    ];

    if (bottomRow.isNotEmpty) {
      widgets.add(
        Positioned(
          bottom: 13,
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

  Widget _buildValveIcon(ValveModel valve, bool hasMoisture, bool hasInputPressure, bool hasLateralPressure, bool hasSoilTemperature, bool hasAnySensor) {
    final Color valveColor = _valveColor(valve.status, valve.completePercent);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _openSensorsPopover(context),
              child: SizedBox(
                width: 43,
                height: 43,
                child: Image.asset(
                  valve.status == 1 ? 'assets/gif/m_valve_green.gif' : 'assets/png/m_valve_grey.png',
                  color: valve.status == 1 ? null : valveColor,
                ),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                valve.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            )
          ],
        ),
        ..._buildSensorPositioned(valve, hasMoisture, hasInputPressure, hasLateralPressure, hasSoilTemperature),
      ],
    );
  }

  Color _valveColor(int status, int cPer) {
    if (status == 0 && cPer == 0) return Colors.black54;
    if (status == 0 && cPer == 100) return Colors.blue;
    if (status == 0 && cPer > 0 && cPer < 100) return Colors.yellow;
    if (status == 2) return Colors.orange;
    return Colors.red;
  }

  Widget _buildWaterSource(ValveModel valve) {
    final source = valve.waterSources[0];
    final bool hasLevel = source.level.isNotEmpty;
    final bool hasFloatSwitch = source.floatSwitches.isNotEmpty;
    final ValueNotifier<int> popoverUpdateNotifier = ValueNotifier<int>(0);
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 45, height: 30, child: AppConstants.getAsset('source', 0, 'After Valve', 0)),
            Text(
              source.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
        if (hasLevel) ...[
          _buildLevelIndicator(source, 1),
          _buildLevelIndicator(source, 2),
        ],
        if (hasFloatSwitch) FloatSwitchPopover(source: source,
            popoverUpdateNotifier: popoverUpdateNotifier, isMobile: true),
      ],
    );
  }

  Widget _buildLevelIndicator(dynamic source, int index) {
    final double top = index == 1 ? 1.0 : 17.0;
    final double left = index == 2 ? 35.0 : 2.0;
    return Positioned(
      top: top,
      left: left,
      right: 2,
      child: Consumer<MqttPayloadProvider>(
        builder: (_, provider, __) {
          final sensorUpdate = provider.getSensorUpdatedValve(source.level[0].sNo.toString());
          final statusParts = sensorUpdate?.split(',') ?? [];
          if (statusParts.length > index) {
            source.level.first.value = statusParts[index];
          }
          final text = index == 1
              ? (MyFunction().getUnitByParameter(context, 'Level Sensor', source.level.first.value.toString()) ?? '')
              : '${source.level.first.value}%';
          return Container(
            height: 17,
            decoration: BoxDecoration(
              color: Colors.yellow,
              borderRadius: BorderRadius.circular(index == 1 ? 2 : 3),
              border: Border.all(color: Colors.grey, width: 0.5),
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/my_function.dart';
import 'float_switch_popover.dart';

class ValveWidgetMobile extends StatefulWidget {
  final ValveModel valve;
  final int customerId, controllerId, modelId;

  const ValveWidgetMobile({
    super.key,
    required this.valve,
    required this.customerId,
    required this.controllerId,
    required this.modelId,
  });

  @override
  State<ValveWidgetMobile> createState() => _ValveWidgetMobileState();
}

class _ValveWidgetMobileState extends State<ValveWidgetMobile> {

  @override
  Widget build(BuildContext context) {
    final valve = widget.valve;

    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getValveOnOffStatus(
        [...AppConstants.ecoGemModelList].contains(widget.modelId)
            ? double.parse(valve.sNo.toString()).toStringAsFixed(3)
            : valve.sNo.toString(),
      ),
      builder: (_, status, __) {
        final statusParts = status?.split(',') ?? [];
        if (statusParts.isNotEmpty) {
          valve.status = int.tryParse(statusParts[1]) ?? valve.status;
          if(statusParts.length > 2){
            valve.completePercent = int.parse(statusParts[2]);
          }else{
            valve.completePercent = 0;
          }
        }

        final bool hasMoisture = valve.moistureSensors.isNotEmpty;
        final bool hasInputPressure = valve.inputPressure.isNotEmpty;
        final bool hasLateralPressure = valve.lateralPressure.isNotEmpty;
        final bool hasWaterSource = valve.waterSources.isNotEmpty;

        return hasWaterSource
            ? _buildWithSource(valve, hasMoisture, hasInputPressure, hasLateralPressure)
            : _buildWithoutSource(valve, hasMoisture, hasInputPressure, hasLateralPressure);
      },
    );
  }


  Widget _buildWithSource(ValveModel valve, bool hasMoisture, bool hasInputPressure, bool hasLateralPressure) {
    return SizedBox(
      width: 140,
      height: 65,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 65, height: 65, child: _buildValveIcon(valve, hasMoisture, hasInputPressure, hasLateralPressure)),
          SizedBox(width: 65, height: 65, child: _buildWaterSource(valve)),
        ],
      ),
    );
  }

  Widget _buildWithoutSource(ValveModel valve, bool hasMoisture, bool hasInputPressure, bool hasLateralPressure) {
    return SizedBox(width: 70, height: 70, child: _buildValveIcon(valve, hasMoisture, hasInputPressure, hasLateralPressure));
  }

  Widget _buildValveIcon(ValveModel valve, bool hasMoisture, bool hasInputPressure, bool hasLateralPressure) {
    final Color valveColor = _valveColor(valve.status, valve.completePercent);
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 43,
              height: 43,
              child: Image.asset(
                valve.status == 1 ? 'assets/gif/m_valve_green.gif' : 'assets/png/m_valve_grey.png',
                color: valve.status == 1 ? null : valveColor,
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                valve.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            )
          ],
        ),
        if (hasMoisture) _buildMoistureButton(valve),
        if (hasInputPressure) _buildPressureButton(valve, 'input'),
        if (hasLateralPressure) _buildPressureButton(valve, 'lateral'),
      ],
    );
  }

  Color _valveColor(int status, int cPer) {
    if (status == 0 && cPer == 0) return Colors.black54;
    if (status == 0 && cPer == 100) return Colors.blue;
    if (status == 0 && cPer > 0 && cPer < 100) return Colors.yellow;
    if (status == 2) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMoistureButton(ValveModel valve) {
    return Positioned(
      top: 2,
      left: 38,
      child: TextButton(
        onPressed: () async {
          showPopover(
            context: context,
            bodyBuilder: (context) {
              return MoistureSensorPopover(valve: valve, customerId: widget.customerId,
                  controllerId: widget.controllerId);
            },
            direction: PopoverDirection.bottom,
            width: 550,
            height: 310,
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
        child: CircleAvatar(
          radius: 15,
          backgroundColor: MyFunction().getMoistureColor(valve.moistureSensors
              .map((s) => {'name': s.name, 'value': s.value}).toList()),
          child: Image.asset('assets/png/moisture_sensor.png', width: 25, height: 25),
        ),
      ),
    );
  }

  Widget _buildPressureButton(ValveModel valve, String sensorType) {
    final sensorList = sensorType == 'lateral' ? valve.lateralPressure : valve.inputPressure;

    // Position input badge upper-left, lateral badge lower-left so they don't overlap the moisture button
    final double top = sensorType == 'lateral' ? 35 : 5;

    return Positioned(
      top: top,
      left: 0,
      child: TextButton(
        onPressed: () async {
          showPopover(
            context: context,
            bodyBuilder: (context) {
              return PressureSensorPopover(
                valve: valve,
                customerId: widget.customerId,
                controllerId: widget.controllerId,
                sensorType: sensorType,
              );
            },
            direction: PopoverDirection.bottom,
            width: 550,
            height: 320,
            arrowHeight: 15,
            arrowWidth: 30,
            barrierColor: Colors.black54,
            arrowDyOffset: sensorType == 'lateral' ? -20 : -55,
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
            for (var sensor in sensorList) {
              final sensorUpdate = provider.getSensorUpdatedValve(sensor.sNo.toString());
              final statusParts = sensorUpdate?.split(',') ?? [];
              if (statusParts.length > 1) {
                sensor.value = statusParts[1];
              }
            }

            final displaySensor = sensorList.first;

            return Container(
              width: 50,
              height: 16,
              decoration: BoxDecoration(
                color: sensorType == 'lateral' ? Colors.lightBlueAccent : Colors.yellowAccent,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
                border: Border.all(color: Colors.grey, width: 0.5),
              ),
              child: Text(
                MyFunction().getUnitByParameter(context, 'Pressure Sensor', displaySensor.value.toString()) ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildWaterSource(ValveModel valve) {
    final source = valve.waterSources[0];
    final bool hasLevel = source.level.isNotEmpty;
    final bool hasFloatSwitch = source.floatSwitches.isNotEmpty;
    final ValueNotifier<int> popoverUpdateNotifier = ValueNotifier<int>(0);
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 45, height: 30, child: AppConstants.getAsset('source', 0, 'After Valve', 0)),
            Text(
              source.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
        if (hasLevel) ...[
          _buildLevelIndicator(source, 1),
          _buildLevelIndicator(source, 2),
        ],
        if (hasFloatSwitch) FloatSwitchPopover(source: source,
            popoverUpdateNotifier: popoverUpdateNotifier, isMobile: true),
      ],
    );
  }

  Widget _buildLevelIndicator(dynamic source, int index) {
    final double top = index == 1 ? 1.0 : 17.0;
    final double left = index == 2 ? 35.0 : 2.0;
    return Positioned(
      top: top,
      left: left,
      right: 2,
      child: Consumer<MqttPayloadProvider>(
        builder: (_, provider, __) {
          final sensorUpdate = provider.getSensorUpdatedValve(source.level[0].sNo.toString());
          final statusParts = sensorUpdate?.split(',') ?? [];
          if (statusParts.length > index) {
            source.level.first.value = statusParts[index];
          }
          final text = index == 1
              ? (MyFunction().getUnitByParameter(context, 'Level Sensor', source.level.first.value.toString()) ?? '')
              : '${source.level.first.value}%';
          return Container(
            height: 17,
            decoration: BoxDecoration(
              color: Colors.yellow,
              borderRadius: BorderRadius.circular(index == 1 ? 2 : 3),
              border: Border.all(color: Colors.grey, width: 0.5),
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}*/
