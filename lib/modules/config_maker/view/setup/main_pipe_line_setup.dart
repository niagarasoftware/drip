import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../model/node_type_model.dart';
import '../../widget/painter/pipe_painter.dart';
import 'irrigation_line_setup.dart';
import 'site_layout_context.dart';
import 'water_source_setup.dart';

/// MAIN WATER PIPELINE SETUP
/// Water supply -> (Filter station) -> (Fertigation skid) -> Irrigation lines.
class MainPipelineSetup extends SiteSetupBase {
  MainPipelineSetup(super.ctx);

  void build({
    required WaterSetupResult water,
    required List<NodeObject> filterNodes,
    required List<NodeObject> skidNodes,
  }) {
    final configPvd = ctx.configPvd;
    final double maxWaterX = water.maxX;
    final double maxWaterY = water.maxY;
    final List<SupplyNodeRef> waterSupplyNodes = water.supplyNodes;
    final irrigation = IrrigationLineSetup(ctx);

    NodeObject? findBlockingNode(Offset startPt, double targetX) {
      final lRect = Rect.fromLTRB(
        math.min(startPt.dx, targetX) + 10.0,
        startPt.dy - 12.0,
        math.max(startPt.dx, targetX) - 5.0,
        startPt.dy + 12.0,
      );
      for (final n in nodes) {
        if (n.type == NodeType.junction || n.type == NodeType.multiFilter || n.type == NodeType.lineHeader) continue;
        final double effHeight = n.size.height + (n.type == NodeType.overheadTank ? 34.0 : 0.0);
        final nRect = Rect.fromLTWH(n.position.dx, n.position.dy, n.size.width, effHeight);
        if (lRect.overlaps(nRect)) {
          return n;
        }
      }
      return null;
    }

    void connectWaterSupplyTo({
      required List<SupplyNodeRef> supplyNodes,
      required String targetNodeId,
      required String? targetPortId,
      required Offset targetPt,
      required double maxWaterX,
    }) {
      if (supplyNodes.isEmpty) return;

      final double trunkX = math.max(maxWaterX + 40.0, targetPt.dx - 30.0);

      if (supplyNodes.length == 1) {
        final termRef = supplyNodes.first;
        final term = termRef.node;
        final String outPort = termRef.portId;
        final Offset termPt = portPosition(term, outPort, isInput: false);
        final blocking = findBlockingNode(termPt, trunkX);

        final List<Offset> wps;
        if (blocking != null) {
          final double bypassX = math.max(termPt.dx + 20.0, blocking.position.dx - 20.0);
          final double effH = blocking.size.height + (blocking.type == NodeType.overheadTank ? 34.0 : 0.0);
          final double bypassY = blocking.position.dy + effH + 35.0;
          wps = [
            Offset(bypassX, termPt.dy),
            Offset(bypassX, bypassY),
            Offset(trunkX, bypassY),
            Offset(trunkX, targetPt.dy - 20.0),
            Offset(targetPt.dx, targetPt.dy - 20.0),
          ];
        } else {
          if ((termPt.dy - targetPt.dy).abs() < 2.0) {
            wps = [];
          } else {
            wps = [
              Offset(trunkX, termPt.dy),
              Offset(trunkX, targetPt.dy - 20.0),
              Offset(targetPt.dx, targetPt.dy - 20.0),
            ];
          }
        }

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: term.id,
          fromPortId: outPort,
          toNodeId: targetNodeId,
          toPortId: targetPortId,
          waypoints: cleanWaypoints(termPt, wps, targetPt),
        ));
      } else {
        String? prevJnId;
        Offset? prevJnPt;

        for (int t = 0; t < supplyNodes.length; t++) {
          final termRef = supplyNodes[t];
          final term = termRef.node;
          final String outPort = termRef.portId;
          final Offset termPt = portPosition(term, outPort, isInput: false);

          final blocking = findBlockingNode(termPt, trunkX);
          Offset jnPt;
          List<Offset> wpsToJn;

          if (blocking != null) {
            final double bypassX = math.max(termPt.dx + 20.0, blocking.position.dx - 20.0);
            final double effH = blocking.size.height + (blocking.type == NodeType.overheadTank ? 34.0 : 0.0);
            final double bypassY = blocking.position.dy + effH + 35.0;
            jnPt = Offset(trunkX, bypassY);
            wpsToJn = [
              Offset(bypassX, termPt.dy),
              Offset(bypassX, bypassY),
            ];
          } else {
            jnPt = Offset(trunkX, termPt.dy);
            wpsToJn = [];
          }

          final jn = newJunction(jnPt);

          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: term.id,
            fromPortId: outPort,
            toNodeId: jn.id,
            waypoints: cleanWaypoints(termPt, wpsToJn, jnPt),
          ));

          if (prevJnId != null && prevJnPt != null) {
            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: prevJnId,
              toNodeId: jn.id,
              waypoints: cleanWaypoints(prevJnPt, [], jnPt),
            ));
          }
          prevJnId = jn.id;
          prevJnPt = jnPt;
        }

        if (prevJnId != null && prevJnPt != null) {
          final List<Offset> wps = (prevJnPt.dy - targetPt.dy).abs() < 2.0
              ? []
              : [
            Offset(trunkX, targetPt.dy - 20.0),
            Offset(targetPt.dx, targetPt.dy - 20.0),
          ];
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: prevJnId,
            toNodeId: targetNodeId,
            toPortId: targetPortId,
            waypoints: cleanWaypoints(prevJnPt, wps, targetPt),
          ));
        }
      }
    }

    // -------------------------------------------------------------------------
    // MAIN WATER PIPELINE FORMATION:
    // Water Supply -> (Filter Station) -> (Fertigation Skid) -> Irrigation Lines
    // -------------------------------------------------------------------------
    if (filterNodes.isNotEmpty) {
      final NodeObject firstFilter = filterNodes.first;
      final Offset filterInletPt = firstFilter.getPort('inlet', isInput: true);

      connectWaterSupplyTo(
        supplyNodes: waterSupplyNodes,
        targetNodeId: firstFilter.id,
        targetPortId: 'inlet',
        targetPt: filterInletPt,
        maxWaterX: maxWaterX,
      );

      final NodeObject lastFilterNode = filterNodes.last;
      final Offset filterOutPt = lastFilterNode.getPort('outlet', isInput: false);

      if (skidNodes.isNotEmpty) {
        for (int s = 0; s < skidNodes.length; s++) {
          final skidNode = skidNodes[s];
          final Offset skidInletPt = skidNode.getPort('inlet', isInput: true);
          final Offset skidOutletPt = skidNode.getPort('outlet', isInput: false);

          final double mainPipeY = math.max(filterOutPt.dy, skidNode.position.dy + skidNode.size.height + 40.0);
          final double skidLeftX = skidNode.position.dx - 30.0;
          final Offset skidInJunctionPt = Offset(skidLeftX, mainPipeY);
          final NodeObject jnSkidIn = newJunction(skidInJunctionPt);

          final List<Offset> filterToSkidWps = [
            Offset(filterOutPt.dx + 30.0, filterOutPt.dy),
            Offset(filterOutPt.dx + 30.0, mainPipeY),
          ];
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: lastFilterNode.id,
            fromPortId: 'outlet',
            toNodeId: jnSkidIn.id,
            waypoints: cleanWaypoints(filterOutPt, filterToSkidWps, skidInJunctionPt),
          ));

          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: jnSkidIn.id,
            toNodeId: skidNode.id,
            toPortId: 'inlet',
            waypoints: cleanWaypoints(skidInJunctionPt, [Offset(skidLeftX, skidInletPt.dy)], skidInletPt),
          ));

          final double skidRightX = skidNode.position.dx + skidNode.size.width + 30.0;
          final Offset skidOutJunctionPt = Offset(skidRightX, mainPipeY);
          final NodeObject jnSkidOut = newJunction(skidOutJunctionPt);

          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: skidNode.id,
            fromPortId: 'outlet',
            toNodeId: jnSkidOut.id,
            waypoints: cleanWaypoints(skidOutletPt, [Offset(skidRightX, skidOutletPt.dy)], skidOutJunctionPt),
          ));

          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: jnSkidIn.id,
            toNodeId: jnSkidOut.id,
            waypoints: cleanWaypoints(skidInJunctionPt, [], skidOutJunctionPt),
          ));

          irrigation.connect(
            startJunction: jnSkidOut,
            startPt: skidOutJunctionPt,
            mainPipeY: mainPipeY,
            skidRightX: skidRightX,
            configPvd: configPvd,
          );
        }
      } else {
        final Offset endPt = Offset(filterOutPt.dx + 60.0, filterOutPt.dy);
        final NodeObject jnEnd = newJunction(endPt);
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: lastFilterNode.id,
          fromPortId: 'outlet',
          toNodeId: jnEnd.id,
          waypoints: [],
        ));

        irrigation.connect(
          startJunction: jnEnd,
          startPt: endPt,
          mainPipeY: filterOutPt.dy,
          skidRightX: filterOutPt.dx,
          configPvd: configPvd,
        );
      }
    } else {
      if (skidNodes.isNotEmpty) {
        for (int s = 0; s < skidNodes.length; s++) {
          final skidNode = skidNodes[s];
          final Offset skidInletPt = skidNode.getPort('inlet', isInput: true);
          final Offset skidOutletPt = skidNode.getPort('outlet', isInput: false);

          final double mainPipeY = math.max(400.0, skidNode.position.dy + skidNode.size.height + 40.0);
          final double skidLeftX = skidNode.position.dx - 30.0;
          final Offset skidInJunctionPt = Offset(skidLeftX, mainPipeY);
          final NodeObject jnSkidIn = newJunction(skidInJunctionPt);

          connectWaterSupplyTo(
            supplyNodes: waterSupplyNodes,
            targetNodeId: jnSkidIn.id,
            targetPortId: null,
            targetPt: skidInJunctionPt,
            maxWaterX: maxWaterX,
          );

          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: jnSkidIn.id,
            toNodeId: skidNode.id,
            toPortId: 'inlet',
            waypoints: cleanWaypoints(skidInJunctionPt, [Offset(skidLeftX, skidInletPt.dy)], skidInletPt),
          ));

          final double skidRightX = skidNode.position.dx + skidNode.size.width + 30.0;
          final Offset skidOutJunctionPt = Offset(skidRightX, mainPipeY);
          final NodeObject jnSkidOut = newJunction(skidOutJunctionPt);

          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: skidNode.id,
            fromPortId: 'outlet',
            toNodeId: jnSkidOut.id,
            waypoints: cleanWaypoints(skidOutletPt, [Offset(skidRightX, skidOutletPt.dy)], skidOutJunctionPt),
          ));

          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: jnSkidIn.id,
            toNodeId: jnSkidOut.id,
            waypoints: cleanWaypoints(skidInJunctionPt, [], skidOutJunctionPt),
          ));

          irrigation.connect(
            startJunction: jnSkidOut,
            startPt: skidOutJunctionPt,
            mainPipeY: mainPipeY,
            skidRightX: skidRightX,
            configPvd: configPvd,
          );
        }
      } else {
        final double endX = math.max(300.0, maxWaterX + 100.0);
        final double endY = math.max(200.0, maxWaterY / 2.0);
        final Offset endPt = Offset(endX, endY);
        final NodeObject jnEnd = newJunction(endPt);

        connectWaterSupplyTo(
          supplyNodes: waterSupplyNodes,
          targetNodeId: jnEnd.id,
          targetPortId: null,
          targetPt: endPt,
          maxWaterX: maxWaterX,
        );

        irrigation.connect(
          startJunction: jnEnd,
          startPt: endPt,
          mainPipeY: endY,
          skidRightX: endX,
          configPvd: configPvd,
        );
      }
    }
  }
}