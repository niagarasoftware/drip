import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/views/customer/widgets/valve_sensors_popover.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';

class BuildMainValve extends StatefulWidget {
  final MainValveModel valve;
  final int customerId, controllerId, modelId;
  final bool isNarrow;

  const BuildMainValve({
    super.key,
    required this.valve,
    required this.customerId,
    required this.controllerId,
    required this.modelId,
    this.isNarrow = false,
  });

  @override
  State<BuildMainValve> createState() => _BuildMainValveState();
}

class _BuildMainValveState extends State<BuildMainValve> {

  void _openSensorsPopover(BuildContext context,
      {String? section, bool hasAnySensor = false}) {
    showPopover(
      context: context,
      bodyBuilder: (context) =>
          MainValveSensorsPopover(
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
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getValveOnOffStatus(
        [...AppConstants.ecoGemModelList].contains(widget.modelId)
            ? double.parse(widget.valve.sNo.toString()).toStringAsFixed(3)
            : widget.valve.sNo.toString(),
      ),
      builder: (_, status, __) {

        final statusParts = status?.split(',') ?? [];
        if (statusParts.length > 1) {
          widget.valve.status = int.tryParse(statusParts[1]) ?? 0;
          widget.valve.completePercent = statusParts.length > 2
              ? (int.tryParse(statusParts[2]) ?? 0)
              : 0;
          if (statusParts.length > 3) {
            widget.valve.lastRunningDT = statusParts[3];
          }
        }


        const width = 70.0;
        final height = widget.isNarrow ? 70.0 : 100.0;
        final iconSize = widget.isNarrow ? 43.0 : 70.0;

        final bool hasInputPressure = widget.valve.inputPressure.isNotEmpty;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
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
                      onTap: () => _openSensorsPopover(context),
                      child: SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: widget.isNarrow ? Image.asset('assets/png/m_main_valve_gray.png',
                          color: widget.valve.completePercent==100? Colors.blue.shade500 :
                          widget.valve.status == 0 ? Colors.black54 : widget.valve.status == 1 ? Colors.green
                              : widget.valve.status == 1 ? Colors.orange : Colors.red,
                        ) : AppConstants.getAsset('main_valve', widget.valve.status, '', widget.valve.completePercent),
                      ),
                    ),
                  ),
                  Text(
                    widget.valve.name,
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
              ..._buildSensorPositioned(widget.valve, hasInputPressure),
            ],
          ),
        );
      },
    );
  }


  // First 2 chips positioned near the top (near the pipeline), any
  List<Widget> _buildSensorPositioned(MainValveModel valve, bool hasInputPressure) {
    final chips = _buildSensorChips(valve, hasInputPressure);
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

  // Flat list of chip widgets, one per active sensor type, in a fixed order.
  List<Widget> _buildSensorChips(MainValveModel valve, bool hasInputPressure) {
    final chips = <Widget>[];

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

    return chips;
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
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

}