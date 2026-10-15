import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/views/customer/stand_alone/widgets/valve_card_table.dart';

import '../../../../models/customer/site_model.dart';

class IrrigationLineCard extends StatelessWidget {
  final IrrigationLineModel line;
  final bool showSwitch;

  final void Function(ValveModel valve, bool value) onToggleValve;
  final void Function(FoggerModel fogger, bool value) onToggleFogger;

  const IrrigationLineCard({
    super.key,
    required this.line,
    required this.showSwitch,
    required this.onToggleValve,
    required this.onToggleFogger,
  });

  @override
  Widget build(BuildContext context) {

    if (line.name == 'All irrigation line' ||
        line.name == 'All Aquaculture line') {
      return const SizedBox();
    }

    final rows = [
      ...line.valveObjects.map((valve) => DataRow(cells: [
        DataCell(Image.asset('assets/png/m_valve_grey.png', width: 40, height: 40)),
        DataCell(Text(valve.name)),
        DataCell(Transform.scale(
          scale: 0.7,
          child: Switch(
            activeThumbColor: Colors.teal,
            hoverColor: Colors.pink.shade100,
            value: valve.isOn,
            onChanged: (val) => onToggleValve(valve, val),
          ),
        )),
      ])),

      ...line.foggerObjects.map((fogger) => DataRow(cells: [
        DataCell(Image.asset('assets/png/mobile/m_fogger_grey.png', width: 40, height: 40)),
        DataCell(Text(fogger.name)),
        DataCell(Transform.scale(
          scale: 0.7,
          child: Switch(
            activeThumbColor: Colors.teal,
            hoverColor: Colors.pink.shade100,
            value: fogger.isOn,
            onChanged: (val) => onToggleFogger(fogger, val),
          ),
        )),
      ])),
    ];

    return ValveCardTable(
      title: line.name,
      showSwitch: showSwitch,
      switchValue: true,
      onSwitchChanged: (_) {},
      rows: rows,
    );
  }
}