import 'package:flutter/cupertino.dart';

import '../../../../models/customer/site_model.dart';
import 'custom_card_table.dart';
import 'custom_switch_row.dart';

class MainValveCard extends StatelessWidget {
  final List<MainValveModel> mainValve;
  final void Function(MainValveModel, bool) onChanged;

  const MainValveCard({
    super.key,
    required this.mainValve,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (mainValve.isEmpty) return const SizedBox();

    return CustomCardTable(
      title: "Main Valve",
      rows: mainValve.map((mValve) {
        return CustomSwitchRow(
          iconPath: 'assets/png/m_main_valve_gray.png',
          label: mValve.name,
          value: mValve.selected,
          onChanged: (val) => onChanged(mValve, val),
        );
      }).toList(),
    );
  }
}

