import 'package:flutter/cupertino.dart';

import '../../../models/customer/site_model.dart';
import '../home_sub_classes/filter_site.dart';

List<Widget> buildFilter (BuildContext context, List<FilterSiteModel> filterSite,
    bool isFrtAvail, bool isMobile, bool isNova) {
  return filterSite.expand((site) => [
    if (site.pressureIn != null)
      Padding(
        padding: EdgeInsets.only(top: (isFrtAvail && !isMobile) ? 38.5 : 0.5),
        child: PressureSensorWidget(sensor: site.pressureIn!, isMobile: isMobile),
      ),

    ...List.generate(site.filters.length, (index) {
      final filter = site.filters[index];
      final isLast = index == site.filters.length - 1;

      return Padding(
        padding: EdgeInsets.only(top: (isFrtAvail && !isMobile) ? 38.5: 0.5),
        child: FilterWidget(
          filter: filter,
          siteSno: site.sNo.toString(),
          isMobile: isMobile,
          isLast: isLast,
          sensorAvailable: site.pressureIn != null,
        ),
      );
    }),

    if (site.pressureOut != null)
      Padding(
        padding: EdgeInsets.only(top: (isFrtAvail && !isMobile) ? 38.5: 0.5),
        child: PressureSensorWidget(sensor: site.pressureOut!, isMobile: isMobile),
      ),
  ]).toList();
}