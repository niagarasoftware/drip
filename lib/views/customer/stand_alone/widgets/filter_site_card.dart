import 'package:flutter/cupertino.dart';

import '../../../../models/customer/site_model.dart';
import 'custom_card_table.dart';
import 'custom_switch_row.dart';

class FilterSiteCard extends StatelessWidget {
  final List<FilterSiteModel> sites;
  final void Function(Filters, bool) onChanged;

  const FilterSiteCard({
    super.key,
    required this.sites,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (sites.isEmpty) return const SizedBox();

    return Column(
      children: sites.map((site) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CustomCardTable(
            title: site.name,
            rows: site.filters.map((filter) {
              return CustomSwitchRow(
                iconPath: 'assets/png/filter.png',
                label: filter.name,
                value: filter.selected,
                onChanged: (val) => onChanged(filter, val),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}