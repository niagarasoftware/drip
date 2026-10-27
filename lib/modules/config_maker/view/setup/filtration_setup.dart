import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/setup/site_layout_context.dart';

import '../../model/node_type_model.dart';
import '../../widget/painter/multi_filter_painter.dart';
import '../../widget/painter/pipe_painter.dart';
import 'water_source_setup.dart';

/// FILTRATION SETUP
/// Multi-filter stations: placed under the water setup when fertigation also
/// exists, otherwise in-line to the right of the water setup.
class FiltrationSetup extends SiteSetupBase {
  FiltrationSetup(super.ctx);

  /// Returns the filter nodes (empty when nothing is configured).
  List<NodeObject> build(WaterSetupResult water) {
    final filtrations = data.filtrations;
    final double maxWaterX = water.maxX;
    final double maxWaterY = water.maxY;
    final List<SupplyNodeRef> waterSupplyNodes = water.supplyNodes;

    // -------------------------------------------------------------------------
    // FILTRATION FORMATION (Multi-Filter Station)
    // -------------------------------------------------------------------------
    final List<NodeObject> filterNodes = [];
    if (filtrations.isNotEmpty) {
      for (int f = 0; f < filtrations.length; f++) {
        final fSite = filtrations[f];
        final double sNo = fSite.commonDetails.sNo ?? 0.0;
        final String label = (fSite.commonDetails.name?.isNotEmpty == true)
            ? fSite.commonDetails.name!
            : 'Multi-Filter Station ${f + 1}';

        // Extract individual filter names by serial number
        final List<String> filterNames = fSite.filters.map((filter) {
          final deviceObj = ctx.getObjectName(filter.sNo, ctx.configPvd);
          return (deviceObj.name?.isNotEmpty == true && deviceObj.name != '-')
              ? deviceObj.name!
              : 'Filter ${filter.sNo.toInt()}';
        }).toList();

        final int filterCount = fSite.filters.isNotEmpty ? fSite.filters.length : 2;

        final filterNode = NodeObject(
          id: nextId('multi_filter_${sNo.toInt()}'),
          position: Offset.zero,
          type: NodeType.multiFilter,
          label: label,
          outletPortCount: filterCount,
          portLabels: filterNames,
          showJoints: !globalHideJoints,
        );
        filterNode.size = Size(DetailedMultiFilterPainter.calculateWidth(132, filterCount), 132);
        nodes.add(filterNode);
        filterNodes.add(filterNode);
      }

      // Place all filtration sites sequentially one after another to the right of the water setup
      double primarySupplyY = maxWaterY / 2.0;
      if (waterSupplyNodes.isNotEmpty) {
        final termRef = waterSupplyNodes.last;
        final termPt = portPosition(termRef.node, termRef.portId, isInput: false);
        primarySupplyY = termPt.dy;
      }

      final Offset sampleInletLocal = filterNodes.first.getPort('inlet', isInput: true) - filterNodes.first.position;
      final double targetY = math.max(30.0, primarySupplyY - sampleInletLocal.dy);

      double currentX = math.max(420.0, maxWaterX + 160.0);
      for (int f = 0; f < filterNodes.length; f++) {
        final fn = filterNodes[f];
        fn.position = Offset(currentX, targetY);
        currentX += fn.size.width + 80.0; // 80px space between filtration sites so every site is visible
      }
    }

    return filterNodes;
  }
}