import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/setup/site_layout_context.dart';

import '../../model/node_type_model.dart';

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
    final bool hasFertData = data.hasFertData;
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
            : 'Multi-Filter Station';
        final filterNode = NodeObject(
          id: nextId('multi_filter_${sNo.toInt()}'),
          position: Offset.zero,
          type: NodeType.multiFilter,
          label: label,
          showJoints: !globalHideJoints,
        );
        filterNode.size = filterNode.defaultSize;
        nodes.add(filterNode);
        filterNodes.add(filterNode);
      }

      if (hasFertData) {
        // BOTH Filtration and Fertigation exist: place Filtration UNDER the water setup
        final double totalFilterW = filterNodes.fold<double>(0.0, (sum, fn) => sum + fn.size.width) + (filterNodes.length - 1) * 30.0;
        for (int f = 0; f < filterNodes.length; f++) {
          final fn = filterNodes[f];
          final double fnX = math.max(160.0, (maxWaterX - totalFilterW) / 2.0 + f * (fn.size.width + 30.0));
          final double fnY = math.max(180.0, maxWaterY + 45.0);
          fn.position = Offset(fnX, fnY);
        }
      } else {
        // ONLY Filtration exists (No Fertigation): place Filtration IN-LINE (Horizontal) to the right of water setup
        double primarySupplyY = maxWaterY / 2.0;
        if (waterSupplyNodes.isNotEmpty) {
          final termRef = waterSupplyNodes.last;
          final termPt = portPosition(termRef.node, termRef.portId, isInput: false);
          primarySupplyY = termPt.dy;
        }

        final double firstFilterX = math.max(300.0, maxWaterX + 80.0);
        final Offset sampleInletLocal = filterNodes.first.getPort('inlet', isInput: true) - filterNodes.first.position;

        for (int f = 0; f < filterNodes.length; f++) {
          final fn = filterNodes[f];
          final double fnX = firstFilterX + f * (fn.size.width + 40.0);
          final double fnY = math.max(30.0, primarySupplyY - sampleInletLocal.dy);
          fn.position = Offset(fnX, fnY);
        }
      }

      for (int f = 0; f < filterNodes.length - 1; f++) {
        final f1 = filterNodes[f];
        final f2 = filterNodes[f + 1];
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: f1.id,
          fromPortId: 'outlet',
          toNodeId: f2.id,
          toPortId: 'inlet',
          waypoints: [],
        ));
      }
    }

    return filterNodes;
  }
}