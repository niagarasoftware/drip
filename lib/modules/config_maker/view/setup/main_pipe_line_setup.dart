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

    // Calculate a main line Y that is guaranteed to run below all water sources,
    // all filter stations and all fertigation skids without overlaying any equipment.
    double calcMainPipeY() {
      double maxY = maxWaterY + 80.0;
      for (final fn in filterNodes) {
        maxY = math.max(maxY, fn.position.dy + fn.size.height + 60.0);
      }
      for (final sn in skidNodes) {
        maxY = math.max(maxY, sn.position.dy + sn.size.height + 60.0);
      }
      return math.max(maxY, 420.0).roundToDouble();
    }

    final double mainPipeY = calcMainPipeY();

    NodeObject? findBlockingNode(Offset startPt, double targetX) {
      final lRect = Rect.fromLTRB(
        math.min(startPt.dx, targetX) + 10.0,
        startPt.dy - 12.0,
        math.max(startPt.dx, targetX) - 5.0,
        startPt.dy + 12.0,
      );
      NodeObject? lowestBlocking;
      double maxBottom = -1.0;
      for (final n in nodes) {
        if (n.type == NodeType.junction || n.type == NodeType.multiFilter || n.type == NodeType.lineHeader) continue;
        final double effHeight = n.size.height + (n.type == NodeType.overheadTank ? 34.0 : 0.0);
        final nRect = Rect.fromLTWH(n.position.dx, n.position.dy, n.size.width, effHeight);
        if (lRect.overlaps(nRect)) {
          final double bottom = n.position.dy + effHeight;
          if (bottom > maxBottom) {
            maxBottom = bottom;
            lowestBlocking = n;
          }
        }
      }
      return lowestBlocking;
    }

    void connectWaterSupplyTo({
      required List<SupplyNodeRef> supplyNodes,
      required String targetNodeId,
      required String? targetPortId,
      required Offset targetPt,
      required double maxWaterX,
      required double maxWaterY,
    }) {
      if (supplyNodes.isEmpty) return;

      final double mainY = math.max(maxWaterY + 40.0, targetPt.dy);
      final bool isTargetOnRight = targetPt.dx >= maxWaterX;

      if (isTargetOnRight) {
        final double trunkX = math.max(maxWaterX + 60.0, targetPt.dx);

        if (supplyNodes.length == 1) {
          final termRef = supplyNodes.first;
          final term = termRef.node;
          final String outPort = termRef.portId;
          final Offset termPt = portPosition(term, outPort, isInput: false);
          final blocking = findBlockingNode(termPt, trunkX);

          final List<Offset> wps;
          if (blocking != null) {
            final double bypassX = (blocking.position.dx - termPt.dx > 60.0)
                ? termPt.dx + 25.0
                : math.max(termPt.dx + 20.0, blocking.position.dx - 20.0);
            final double effH = blocking.size.height + (blocking.type == NodeType.overheadTank ? 34.0 : 0.0);
            final double bypassY = math.max(blocking.position.dy + effH + 35.0, maxWaterY + 20.0);
            wps = [
              Offset(bypassX, termPt.dy),
              Offset(bypassX, bypassY),
              Offset(trunkX, bypassY),
              Offset(trunkX, targetPt.dy),
            ];
          } else {
            if ((termPt.dy - targetPt.dy).abs() < 2.0) {
              wps = [];
            } else {
              wps = [
                Offset(trunkX, termPt.dy),
                Offset(trunkX, targetPt.dy),
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
              final double bypassX = (blocking.position.dx - termPt.dx > 60.0)
                  ? termPt.dx + 25.0
                  : math.max(termPt.dx + 20.0, blocking.position.dx - 20.0);
              final double effH = blocking.size.height + (blocking.type == NodeType.overheadTank ? 34.0 : 0.0);
              final double bypassY = math.max(blocking.position.dy + effH + 35.0, maxWaterY + 20.0);
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
              Offset(trunkX, targetPt.dy),
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
      } else {
        // Target is to the LEFT or UNDER the water setup
        if (supplyNodes.length == 1) {
          final termRef = supplyNodes.first;
          final term = termRef.node;
          final String outPort = termRef.portId;
          final Offset termPt = portPosition(term, outPort, isInput: false);

          final List<Offset> wps;
          if ((termPt.dy - targetPt.dy).abs() < 2.0) {
            wps = [];
          } else {
            wps = [
              Offset(termPt.dx, mainY),
              Offset(targetPt.dx, mainY),
            ];
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
          final sortedSupply = [...supplyNodes]..sort((a, b) {
            final pA = portPosition(a.node, a.portId, isInput: false);
            final pB = portPosition(b.node, b.portId, isInput: false);
            return pA.dx.compareTo(pB.dx);
          });

          NodeObject? prevJn;
          Offset? prevJnPt;

          for (int t = 0; t < sortedSupply.length; t++) {
            final termRef = sortedSupply[t];
            final term = termRef.node;
            final String outPort = termRef.portId;
            final Offset termPt = portPosition(term, outPort, isInput: false);

            final Offset jnPt = Offset(termPt.dx, mainY);
            final jn = newJunction(jnPt);

            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: term.id,
              fromPortId: outPort,
              toNodeId: jn.id,
              waypoints: cleanWaypoints(termPt, [], jnPt),
            ));

            if (prevJn != null && prevJnPt != null) {
              pipes.add(PipeConnection(
                id: nextId('pipe'),
                fromNodeId: prevJn.id,
                toNodeId: jn.id,
                waypoints: cleanWaypoints(prevJnPt, [], jnPt),
              ));
            }

            prevJn = jn;
            prevJnPt = jnPt;
          }

          if (prevJn != null && prevJnPt != null) {
            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: prevJn.id,
              toNodeId: targetNodeId,
              toPortId: targetPortId,
              waypoints: cleanWaypoints(prevJnPt, [Offset(targetPt.dx, mainY)], targetPt),
            ));
          }
        }
      }
    }

    // -------------------------------------------------------------------------
    // MAIN WATER PIPELINE FORMATION:
    // Water Supply -> (Filter Station) -> (Fertigation Skid) -> Irrigation Lines
    // -------------------------------------------------------------------------
    if (filterNodes.isNotEmpty) {
      if (filterNodes.length == 1) {
        final NodeObject singleFilter = filterNodes.first;
        final Offset filterInletPt = singleFilter.getPort('inlet', isInput: true);

        connectWaterSupplyTo(
          supplyNodes: waterSupplyNodes,
          targetNodeId: singleFilter.id,
          targetPortId: 'inlet',
          targetPt: filterInletPt,
          maxWaterX: maxWaterX,
          maxWaterY: maxWaterY,
        );

        final NodeObject lastFilterNode = singleFilter;
        final Offset filterOutPt = lastFilterNode.getPort('outlet', isInput: false);

        if (skidNodes.isNotEmpty) {
          final Map<double, NodeObject> skidOutMap = {};
          final List<double> fertSiteSNos = data.fertSites
              .map((s) => s.commonDetails.sNo ?? 0.0)
              .toList();

          NodeObject prevJn = lastFilterNode;
          String? prevPort = 'outlet';

          for (int s = 0; s < skidNodes.length; s++) {
            final skidNode = skidNodes[s];
            final Offset skidInletPt = skidNode.getPort('inlet', isInput: true);
            final Offset skidOutletPt = skidNode.getPort('outlet', isInput: false);

            final double skidLeftX = (skidNode.position.dx - 30.0).roundToDouble();
            final Offset skidInJunctionPt = Offset(skidLeftX, mainPipeY);
            final NodeObject jnSkidIn = newJunction(skidInJunctionPt);

            final Offset prevPt = portPosition(prevJn, prevPort, isInput: false);
            final List<Offset> wps = (prevJn.id == lastFilterNode.id)
                ? [Offset((prevPt.dx + 30.0).roundToDouble(), prevPt.dy), Offset((prevPt.dx + 30.0).roundToDouble(), mainPipeY)]
                : [];
            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: prevJn.id,
              fromPortId: prevPort,
              toNodeId: jnSkidIn.id,
              waypoints: cleanWaypoints(prevPt, wps, skidInJunctionPt),
            ));

            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: jnSkidIn.id,
              toNodeId: skidNode.id,
              toPortId: 'inlet',
              waypoints: cleanWaypoints(skidInJunctionPt, [Offset(skidLeftX, skidInletPt.dy)], skidInletPt),
            ));

            final double skidRightX = (skidNode.position.dx + skidNode.size.width + 30.0).roundToDouble();
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

            if (s < fertSiteSNos.length) {
              skidOutMap[fertSiteSNos[s]] = jnSkidOut;
            }

            prevJn = jnSkidOut;
            prevPort = null;
          }

          irrigation.connect(
            defaultStartJunction: prevJn,
            defaultStartPt: portPosition(prevJn, null, isInput: false),
            mainPipeY: mainPipeY,
            skidOutJunctionMap: skidOutMap,
            configPvd: configPvd,
          );
        } else {
          final Offset endPt = Offset(filterOutPt.dx + 30.0, mainPipeY);
          final NodeObject jnEnd = newJunction(endPt);
          final List<Offset> filterOutWps = [
            Offset(filterOutPt.dx + 30.0, filterOutPt.dy),
          ];
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: lastFilterNode.id,
            fromPortId: 'outlet',
            toNodeId: jnEnd.id,
            waypoints: cleanWaypoints(filterOutPt, filterOutWps, endPt),
          ));

          irrigation.connect(
            defaultStartJunction: jnEnd,
            defaultStartPt: endPt,
            mainPipeY: mainPipeY,
            skidOutJunctionMap: {},
            configPvd: configPvd,
          );
        }
      } else {
        // MULTIPLE FILTRATION SITES: Feed each site in PARALLEL via raw supply & clean collector headers

        // 1. Raw Water Supply Header across top inlets
        final List<NodeObject> supplyJunctions = [];
        for (int f = 0; f < filterNodes.length; f++) {
          final fn = filterNodes[f];
          final Offset inPt = fn.getPort('inlet', isInput: true);
          final jnIn = newJunction(inPt);
          supplyJunctions.add(jnIn);

          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: jnIn.id,
            toNodeId: fn.id,
            toPortId: 'inlet',
            waypoints: [],
          ));
        }

        for (int f = 0; f < supplyJunctions.length - 1; f++) {
          final jn1 = supplyJunctions[f];
          final jn2 = supplyJunctions[f + 1];
          final p1 = portPosition(jn1, null, isInput: false);
          final p2 = portPosition(jn2, null, isInput: true);
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: jn1.id,
            toNodeId: jn2.id,
            waypoints: cleanWaypoints(p1, [], p2),
          ));
        }

        // Connect main water supply from water setup to first supply header junction
        final NodeObject firstJnIn = supplyJunctions.first;
        final Offset firstJnInPt = portPosition(firstJnIn, null, isInput: true);
        connectWaterSupplyTo(
          supplyNodes: waterSupplyNodes,
          targetNodeId: firstJnIn.id,
          targetPortId: null,
          targetPt: firstJnInPt,
          maxWaterX: maxWaterX,
          maxWaterY: maxWaterY,
        );

        // 2. Clean Water Collector Header across bottom outlets
        final List<NodeObject> collectorJunctions = [];
        for (int f = 0; f < filterNodes.length; f++) {
          final fn = filterNodes[f];
          final Offset outPt = fn.getPort('outlet', isInput: false);
          final Offset jnOutPt = Offset(outPt.dx, mainPipeY);
          final jnOut = newJunction(jnOutPt);
          collectorJunctions.add(jnOut);

          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: fn.id,
            fromPortId: 'outlet',
            toNodeId: jnOut.id,
            waypoints: cleanWaypoints(outPt, [], jnOutPt),
          ));
        }

        for (int f = 0; f < collectorJunctions.length - 1; f++) {
          final jn1 = collectorJunctions[f];
          final jn2 = collectorJunctions[f + 1];
          final p1 = portPosition(jn1, null, isInput: false);
          final p2 = portPosition(jn2, null, isInput: true);
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: jn1.id,
            toNodeId: jn2.id,
            waypoints: cleanWaypoints(p1, [], p2),
          ));
        }

        // Last collector junction feeds downstream into Fertigation Skid / Irrigation Lines
        final NodeObject lastJnOut = collectorJunctions.last;
        final Offset lastJnOutPt = portPosition(lastJnOut, null, isInput: false);

        if (skidNodes.isNotEmpty) {
          final Map<double, NodeObject> skidOutMap = {};
          final List<double> fertSiteSNos = data.fertSites
              .map((s) => s.commonDetails.sNo ?? 0.0)
              .toList();

          NodeObject prevJn = lastJnOut;
          String? prevPort;

          for (int s = 0; s < skidNodes.length; s++) {
            final skidNode = skidNodes[s];
            final Offset skidInletPt = skidNode.getPort('inlet', isInput: true);
            final Offset skidOutletPt = skidNode.getPort('outlet', isInput: false);

            final double skidLeftX = skidNode.position.dx - 30.0;
            final Offset skidInJunctionPt = Offset(skidLeftX, mainPipeY);
            final NodeObject jnSkidIn = newJunction(skidInJunctionPt);

            final Offset prevPt = portPosition(prevJn, prevPort, isInput: false);
            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: prevJn.id,
              fromPortId: prevPort,
              toNodeId: jnSkidIn.id,
              waypoints: cleanWaypoints(prevPt, [], skidInJunctionPt),
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

            if (s < fertSiteSNos.length) {
              skidOutMap[fertSiteSNos[s]] = jnSkidOut;
            }

            prevJn = jnSkidOut;
            prevPort = null;
          }

          irrigation.connect(
            defaultStartJunction: prevJn,
            defaultStartPt: portPosition(prevJn, null, isInput: false),
            mainPipeY: mainPipeY,
            skidOutJunctionMap: skidOutMap,
            configPvd: configPvd,
          );
        } else {
          irrigation.connect(
            defaultStartJunction: lastJnOut,
            defaultStartPt: lastJnOutPt,
            mainPipeY: mainPipeY,
            skidOutJunctionMap: {},
            configPvd: configPvd,
          );
        }
      }
    } else {
      if (skidNodes.isNotEmpty) {
        final Map<double, NodeObject> skidOutMap = {};
        final List<double> fertSiteSNos = data.fertSites
            .map((s) => s.commonDetails.sNo ?? 0.0)
            .toList();

        NodeObject? prevJn;

        for (int s = 0; s < skidNodes.length; s++) {
          final skidNode = skidNodes[s];
          final Offset skidInletPt = skidNode.getPort('inlet', isInput: true);
          final Offset skidOutletPt = skidNode.getPort('outlet', isInput: false);

          final double skidLeftX = skidNode.position.dx - 30.0;
          final Offset skidInJunctionPt = Offset(skidLeftX, mainPipeY);
          final NodeObject jnSkidIn = newJunction(skidInJunctionPt);

          if (s == 0) {
            connectWaterSupplyTo(
              supplyNodes: waterSupplyNodes,
              targetNodeId: jnSkidIn.id,
              targetPortId: null,
              targetPt: skidInJunctionPt,
              maxWaterX: maxWaterX,
              maxWaterY: maxWaterY,
            );
          } else if (prevJn != null) {
            final Offset prevPt = portPosition(prevJn, null, isInput: false);
            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: prevJn.id,
              toNodeId: jnSkidIn.id,
              waypoints: cleanWaypoints(prevPt, [], skidInJunctionPt),
            ));
          }

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

          if (s < fertSiteSNos.length) {
            skidOutMap[fertSiteSNos[s]] = jnSkidOut;
          }

          prevJn = jnSkidOut;
        }

        if (prevJn != null) {
          irrigation.connect(
            defaultStartJunction: prevJn,
            defaultStartPt: portPosition(prevJn, null, isInput: false),
            mainPipeY: mainPipeY,
            skidOutJunctionMap: skidOutMap,
            configPvd: configPvd,
          );
        }
      } else {
        final double maxIrrigationX = IrrigationLineSetup.requiredRightX(configPvd);
        final double mainLineX = math.max(maxWaterX + 150.0, maxIrrigationX + 140.0).roundToDouble();
        final Offset targetPt = Offset(mainLineX, mainPipeY);
        final NodeObject jnEnd = newJunction(targetPt);

        connectWaterSupplyTo(
          supplyNodes: waterSupplyNodes,
          targetNodeId: jnEnd.id,
          targetPortId: null,
          targetPt: targetPt,
          maxWaterX: maxWaterX,
          maxWaterY: maxWaterY,
        );

        irrigation.connect(
          defaultStartJunction: jnEnd,
          defaultStartPt: targetPt,
          mainPipeY: mainPipeY,
          skidOutJunctionMap: {},
          configPvd: configPvd,
        );
      }
    }
  }
}