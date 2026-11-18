import 'package:flutter/material.dart';

import '../../../../models/customer/site_model.dart';
import 'custom_card_table.dart';
import 'custom_switch_row.dart';


class FertilizerSiteCard extends StatelessWidget {
  final List<FertilizerSiteModel> sites;
  final void Function(FertilizerItem, bool) onChanged;

  const FertilizerSiteCard({
    super.key,
    required this.sites,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (sites.isEmpty) return const SizedBox();

    return Column(
      children: sites.map((site) {
        final rows = <DataRow>[];

        rows.addAll(site.channel.map((c) => CustomSwitchRow(
          iconPath: 'assets/png/fert_chanel.png',
          label: c.name,
          value: c.selected,
          onChanged: (val) => onChanged(c, val),
        )));

        rows.addAll(site.boosterPump.map((bp) => CustomSwitchRow(
          iconPath: 'assets/png/booster_pump.png',
          label: bp.name,
          value: bp.selected,
          onChanged: (val) => onChanged(bp, val),
        )));

        rows.addAll(site.agitator.map((a) => CustomSwitchRow(
          iconPath: 'assets/png/agitator_gray.png',
          label: a.name,
          value: a.selected,
          onChanged: (val) => onChanged(a, val),
        )));

        rows.addAll(site.selector.map((a) => CustomSwitchRow(
          iconPath: 'assets/png/selector.png',
          label: a.name,
          value: a.selected,
          onChanged: (val) => onChanged(a, val),
        )));

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CustomCardTable(
            title: site.name,
            rows: rows,
          ),
        );
      }).toList(),
    );
  }
}