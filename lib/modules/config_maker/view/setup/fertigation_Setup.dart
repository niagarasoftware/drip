import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../utils/constants.dart';
import '../../model/channel_config_model.dart';
import '../../model/node_type_model.dart';
import '../../model/pump_model.dart';
import '../../widget/painter/pipe_painter.dart';
import 'site_layout_context.dart';

class _Segment {
  final double start;
  final double end;
  _Segment(this.start, this.end);
}

/// One fertilizer pipe: tank-valve outlet (facing down) -> skid channel.
class _FertLink {
  final NodeObject valve;
  final String valvePort;
  final NodeObject skid;
  final String skidPort;

  /// X of the valve outlet / skid channel, and Y of the horizontal lane.
  double x1 = 0;
  double x2 = 0;
  double lane = 0;

  _FertLink(this.valve, this.valvePort, this.skid, this.skidPort);
}

/// FERTIGATION SETUP
/// Main fertilizer source + pump, fertilizer tanks, air blowers / agitators,
/// tank valves and the multi-injector skid(s), placed to the RIGHT of the
/// water setup, plus the pipes between them.
class FertigationSetup extends SiteSetupBase {
  FertigationSetup(super.ctx);

  /// Returns the injector skid nodes (empty when there is no fertigation data).
  List<NodeObject> build() {
    final configPvd = ctx.configPvd;
    final pumps = data.pumps;
    final fertSites = data.fertSites;
    final channelConfigs = data.channelConfigs;
    final mainFertSources = data.mainFertSources;
    final fertTanks = data.fertTanks;
    final bool hasFertData = data.hasFertData;
    final valveChannelPos = data.valveChannelPos;

    // -------------------------------------------------------------------------
    // FERTILIZATION FORMATION (Placed to the RIGHT side of Water & Pump setup)
    // -------------------------------------------------------------------------
    final List<NodeObject> skidNodes = [];

    if (hasFertData) {
      final double maxWaterX = nodes.isNotEmpty
          ? nodes.map((n) => n.position.dx + n.size.width).reduce(math.max)
          : 0.0;
      final double fertStartX = nodes.isNotEmpty ? math.max(500.0, maxWaterX + 100.0) : 40.0;
      const double fertStartY = 40.0;

      // Row 1: Main Fert Source + Pump (Left) & Air Blower (Right)
      const double row1Y = fertStartY;
      NodeObject? supplyStartNode;
      String? supplyStartPort;

      final Map<double, NodeObject> mainFertNodeMap = {};
      final Map<double, NodeObject> fertPumpNodeMap = {};

      double mfsX = fertStartX;
      for (final mfs in mainFertSources) {
        final double sNo = mfs.commonDetails.sNo ?? 0.0;
        final String label = (mfs.commonDetails.name?.isNotEmpty == true)
            ? mfs.commonDetails.name!
            : 'Main Fert Source';
        final mfsNode = NodeObject(
          id: nextId('main_fert_${sNo.toInt()}'),
          position: Offset(mfsX, row1Y + 20.0),
          type: NodeType.mainFertilizerSource,
          size: const Size(148, 104),
          label: label,
          showJoints: !globalHideJoints,
        );
        mfsNode.size = mfsNode.defaultSize;
        nodes.add(mfsNode);
        mainFertNodeMap[sNo] = mfsNode;

        supplyStartNode = mfsNode;
        supplyStartPort = 'outlet';

        // Outlet pump for Main Fert Source (e.g. "New Pump")
        if (mfs.outletPump.isNotEmpty) {
          final double pNo = mfs.outletPump.first;
          final pumpModel = pumps.cast<PumpModel?>().firstWhere(
                (p) => p?.commonDetails.sNo == pNo,
            orElse: () => null,
          );
          final String pumpLabel = (pumpModel?.commonDetails.name?.isNotEmpty == true)
              ? pumpModel!.commonDetails.name!
              : 'New Pump';
          final pumpNode = NodeObject(
            id: nextId('fert_pump_${pNo.toInt()}'),
            position: Offset(mfsX + 148.0 + 30.0, row1Y + 35.0),
            type: NodeType.pump,
            size: const Size(68, 47),
            label: pumpLabel,
            isOn: true,
            showJoints: !globalHideJoints,
          );
          pumpNode.size = pumpNode.defaultSize;
          // Line the pump inlet up with the source outlet so the
          // source -> pump pipe is one short straight run.
          final Offset mfsOutPt = portPosition(mfsNode, 'outlet', isInput: false);
          final Offset pumpInPt = portPosition(pumpNode, 'input', isInput: true);
          pumpNode.position = pumpNode.position + Offset(0, mfsOutPt.dy - pumpInPt.dy);
          nodes.add(pumpNode);
          fertPumpNodeMap[pNo] = pumpNode;

          // Connect Main Fert Source -> Pump
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: mfsNode.id,
            toNodeId: pumpNode.id,
            fromPortId: 'outlet',
            toPortId: 'input',
            waypoints: [],
          ));

          supplyStartNode = pumpNode;
          supplyStartPort = 'output';
        }
        mfsX += 240.0;
      }

      // Calculate dynamic width allocation and X offsets for each fertilizer tank
      // based on its actual outlet valve size / port count.
      final List<double> tankAllocW = [];
      for (int t = 0; t < fertTanks.length; t++) {
        final tankSpec = fertTanks[t];
        double valveW = 42.0;
        if (tankSpec.outletTankValve.isNotEmpty) {
          final bool isMulti = tankSpec.isMultiOutletTankValve || tankSpec.outletTankValve.length > 1;
          if (isMulti) {
            final int portCount = math.max(1, tankSpec.outletTankValvePortCount);
            valveW = math.max(80.0, 26.0 * portCount);
          } else {
            valveW = 42.0;
          }
        }
        tankAllocW.add(math.max(70.0, valveW));
      }

      final List<double> tankOffsetsX = [];
      double currentTankOffset = 0.0;
      for (int t = 0; t < fertTanks.length; t++) {
        if (t == 0) {
          tankOffsetsX.add(0.0);
        } else {
          final double prevAlloc = tankAllocW[t - 1];
          final double currAlloc = tankAllocW[t];
          final double step = (prevAlloc / 2.0) + (currAlloc / 2.0) + 12.0;
          currentTankOffset += step;
          tankOffsetsX.add(currentTankOffset);
        }
      }

      final double totalTanksSpan = fertTanks.isEmpty
          ? 100.0
          : (tankOffsetsX.last + tankAllocW.last);

      final double tankStartX = mainFertSources.isNotEmpty ? mfsX + 20.0 : fertStartX;

      // Air Blower / Agitator nodes generated dynamically from data
      final Map<double, NodeObject> agitatorNodeMap = {};

      final Set<double> allAgitatorSNos = {};
      for (final tank in fertTanks) {
        allAgitatorSNos.addAll(tank.agitator);
      }
      for (final site in fertSites) {
        allAgitatorSNos.addAll(site.agitator);
      }

      if (allAgitatorSNos.isEmpty && fertTanks.isNotEmpty) {
        for (final obj in configPvd.listOfGeneratedObject) {
          if (obj.objectId == AppConstants.agitatorObjectId) {
            if (obj.sNo != null) allAgitatorSNos.add(obj.sNo!);
          }
        }
      }

      final List<double> sortedAgitatorSNos = allAgitatorSNos.toList()..sort();

      if (sortedAgitatorSNos.isNotEmpty) {
        final double startBlowerX = tankStartX + totalTanksSpan + 35.0;

        for (int a = 0; a < sortedAgitatorSNos.length; a++) {
          final double agSNo = sortedAgitatorSNos[a];
          final deviceObj = getObjectName(agSNo, configPvd);
          final String label = (deviceObj.name?.isNotEmpty == true && deviceObj.name != '-')
              ? deviceObj.name!
              : 'Air Blower ${a + 1}';

          final double blowerX = startBlowerX + a * 130.0;
          final blowerNode = NodeObject(
            id: nextId('blower_${agSNo.toInt()}'),
            position: Offset(blowerX, row1Y),
            type: NodeType.blower,
            size: const Size(60, 56),
            label: label,
            showJoints: !globalHideJoints,
          );
          blowerNode.size = blowerNode.defaultSize;
          nodes.add(blowerNode);
          agitatorNodeMap[agSNo] = blowerNode;
        }
      } else if (fertTanks.isNotEmpty) {
        final double blowerX = tankStartX + totalTanksSpan + 35.0;
        final blowerNode = NodeObject(
          id: nextId('blower_default'),
          position: Offset(blowerX, row1Y),
          type: NodeType.blower,
          size: const Size(60, 56),
          label: 'Air Blower',
          showJoints: !globalHideJoints,
        );
        blowerNode.size = blowerNode.defaultSize;
        nodes.add(blowerNode);
        agitatorNodeMap[0.0] = blowerNode;
      }

      // Row 2: Fertilizer Tanks
      const double tanksY = row1Y + 140.0;
      final Map<double, NodeObject> fertTankNodeMap = {};

      for (int t = 0; t < fertTanks.length; t++) {
        final tankSpec = fertTanks[t];
        final double sNo = tankSpec.commonDetails.sNo ?? 0.0;
        final String label = (tankSpec.commonDetails.name?.isNotEmpty == true)
            ? tankSpec.commonDetails.name!
            : 'Fertilizer Tank';
        final tankNode = NodeObject(
          id: nextId('fert_tank_${sNo.toInt()}'),
          position: Offset(tankStartX + tankOffsetsX[t], tanksY),
          type: NodeType.fertilizerTank,
          size: const Size(70, 88),
          label: label,
          showJoints: !globalHideJoints,
        );
        tankNode.size = tankNode.defaultSize;
        nodes.add(tankNode);
        fertTankNodeMap[sNo] = tankNode;
      }

      // Main fertilizer supply line (green): ONE trunk from the pump with a
      // tee above every tank, instead of several pipes drawn on top of each other.
      if (supplyStartNode != null && fertTanks.isNotEmpty) {
        const double supplyY = tanksY - 65.0;
        final Offset startPt = portPosition(supplyStartNode, supplyStartPort, isInput: false);
        final double trunkX = startPt.dx + 20.0;

        String prevId = supplyStartNode.id;
        String? prevPort = supplyStartPort;
        Offset prevPos = startPt;
        List<Offset> prevWps = [Offset(trunkX, startPt.dy), Offset(trunkX, supplyY)];

        for (int t = 0; t < fertTanks.length; t++) {
          final tankNode = fertTankNodeMap[fertTanks[t].commonDetails.sNo ?? 0.0]!;
          final Offset inletPt = tankNode.getPort('inlet', isInput: true);
          final Offset dropPt = Offset(inletPt.dx, supplyY);

          if (t == fertTanks.length - 1) {
            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: prevId,
              fromPortId: prevPort,
              toNodeId: tankNode.id,
              toPortId: 'inlet',
              waypoints: cleanWaypoints(prevPos, [...prevWps, dropPt], inletPt),
            ));
          } else {
            final jn = newJunction(dropPt);
            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: prevId,
              fromPortId: prevPort,
              toNodeId: jn.id,
              waypoints: cleanWaypoints(prevPos, prevWps, dropPt),
            ));
            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: jn.id,
              toNodeId: tankNode.id,
              toPortId: 'inlet',
              waypoints: [],
            ));
            prevId = jn.id;
            prevPort = null;
            prevPos = dropPt;
            prevWps = [];
          }
        }
      }

      // Connect Air Blower Lines (Blue) dynamically based on assigned agitator data
      if (agitatorNodeMap.isNotEmpty && fertTanks.isNotEmpty) {
        final List<double> sortedAgKeys = agitatorNodeMap.keys.toList()..sort();

        for (int t = 0; t < fertTanks.length; t++) {
          final tankSpec = fertTanks[t];
          final double tankSNo = tankSpec.commonDetails.sNo ?? 0.0;
          final tankNode = fertTankNodeMap[tankSNo]!;
          final Offset topInletPt = tankNode.getPort('top_inlet', isInput: true);

          List<double> assignedAgitators = tankSpec.agitator;
          if (assignedAgitators.isEmpty) {
            if (fertSites.isNotEmpty) {
              for (final site in fertSites) {
                if (site.agitator.isNotEmpty) {
                  assignedAgitators = site.agitator;
                  break;
                }
              }
            }
            if (assignedAgitators.isEmpty && agitatorNodeMap.length == 1) {
              assignedAgitators = [agitatorNodeMap.keys.first];
            }
          }

          for (final agSNo in assignedAgitators) {
            final blowerNode = agitatorNodeMap[agSNo] ?? agitatorNodeMap[0.0];
            if (blowerNode == null) continue;

            final int agIdx = math.max(0, sortedAgKeys.indexOf(agSNo));
            final double airY = tanksY - 35.0 - (agIdx * 15.0);
            final Offset blowerPt = blowerNode.outputPort;
            final double dropX = blowerPt.dx - 10.0;

            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: blowerNode.id,
              toNodeId: tankNode.id,
              fromPortId: 'outlet',
              toPortId: 'top_inlet',
              waypoints: cleanWaypoints(
                blowerPt,
                [
                  Offset(dropX, blowerPt.dy),
                  Offset(dropX, airY),
                  Offset(topInletPt.dx, airY),
                ],
                topInletPt,
              ),
            ));
          }
        }
      }

      // Row 3: Outlet Tank Valves.
      // Fertilizer tank valves are VERTICAL: inlet on top (straight under the
      // tank outlet) and the outlet port(s) facing DOWNWARDS.
      const double valvesY = tanksY + 88.0 + 22.0;
      final Map<double, NodeObject> fertTankValveNodeMap = {};
      final Map<double, String> fertTankValvePortMap = {};
      double maxValveBottom = valvesY + 60.0;

      for (int t = 0; t < fertTanks.length; t++) {
        final tankSpec = fertTanks[t];
        final double sNo = tankSpec.commonDetails.sNo ?? 0.0;
        final tankNode = fertTankNodeMap[sNo]!;

        if (tankSpec.outletTankValve.isNotEmpty) {
          final bool isMulti = tankSpec.isMultiOutletTankValve || tankSpec.outletTankValve.length > 1;
          final int portCount = math.max(1, tankSpec.outletTankValvePortCount);
          final NodeType valveType = isMulti ? NodeType.multiOutletTankValve : NodeType.singleTankValve;
          final String valveLabel = isMulti ? 'Multi Outlet Tank Valve' : 'Single Tank Valve';

          final valveNode = NodeObject(
            id: nextId('fert_valve_${sNo.toInt()}'),
            position: const Offset(0, valvesY),
            type: valveType,
            label: valveLabel,
            outletPortCount: portCount,
            isHorizontal: false, // outlets face downwards
            showJoints: !globalHideJoints,
          );
          valveNode.size = valveNode.defaultSize;

          // Centre the valve inlet exactly under the tank outlet so the
          // tank -> valve pipe is a perfectly straight vertical run.
          final Offset tankOut = tankNode.getPort('outlet', isInput: false);
          final double inletOffset = valveNode.inputPort.dx - valveNode.position.dx;
          valveNode.position = Offset(tankOut.dx - inletOffset, valvesY);
          nodes.add(valveNode);

          maxValveBottom = math.max(maxValveBottom, valveNode.position.dy + valveNode.size.height);

          // Outlet ports are handed out left -> right:
          // 1. Single-channel dedicated valves first (ordered by target channel index)
          // 2. Multi-channel / common valves last
          final ranked = List<int>.generate(tankSpec.outletTankValve.length, (i) => i);
          ranked.sort((a, b) {
            final vA = tankSpec.outletTankValve[a];
            final vB = tankSpec.outletTankValve[b];

            final countA = channelConfigs.where((ch) => ch.outletTankValve.contains(vA)).length;
            final countB = channelConfigs.where((ch) => ch.outletTankValve.contains(vB)).length;

            if (countA != countB) {
              return countA.compareTo(countB);
            }

            final pa = valveChannelPos(vA) ?? (1000.0 + a);
            final pb = valveChannelPos(vB) ?? (1000.0 + b);
            final c = pa.compareTo(pb);
            return c != 0 ? c : a.compareTo(b);
          });

          final List<String> portLabels = [];
          for (int rank = 0; rank < ranked.length; rank++) {
            final double vSNo = tankSpec.outletTankValve[ranked[rank]];
            fertTankValveNodeMap[vSNo] = valveNode;
            fertTankValvePortMap[vSNo] =
            isMulti ? 'channel_${math.min(rank, portCount - 1)}' : 'outlet';

            final deviceObj = getObjectName(vSNo, configPvd);
            final String name = (deviceObj.name?.isNotEmpty == true && deviceObj.name != '-')
                ? deviceObj.name!
                : 'Tank Valve ${rank + 1}';
            portLabels.add(name);
          }
          valveNode.portLabels = portLabels;

          // Pipe: Tank outlet -> Valve inlet (straight down)
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: tankNode.id,
            toNodeId: valveNode.id,
            fromPortId: 'outlet',
            toPortId: 'inlet',
            waypoints: [],
          ));
        }
      }

      // Row 4: Multi-Injector Skid(s) / Multi Channel Connection
      // (final Y is set after the fertilizer pipes are laid out so there is
      // always enough room for the horizontal pipe lanes)
      final double provisionalSkidY = maxValveBottom + 150.0;
      final double totalAreaW = totalTanksSpan;

      final List<_FertLink> fertLinks = [];

      if (fertSites.isNotEmpty) {
        for (int s = 0; s < fertSites.length; s++) {
          final site = fertSites[s];
          final String label = (site.commonDetails.name?.isNotEmpty == true)
              ? site.commonDetails.name!
              : 'Multi-Injector Skid';

          final double skidX = tankStartX + (totalAreaW - 308.0) / 2.0 + s * 340.0;
          final skidNode = NodeObject(
            id: nextId('skid_${site.commonDetails.sNo?.toInt() ?? s}'),
            position: Offset(skidX, provisionalSkidY),
            type: NodeType.multiInjector,
            size: const Size(308, 132),
            label: label,
            showJoints: !globalHideJoints,
          );
          skidNode.size = skidNode.defaultSize;
          nodes.add(skidNode);
          skidNodes.add(skidNode);

          // Tank Valves -> Skid Channels
          for (int c = 0; c < site.channel.length; c++) {
            final inj = site.channel[c];
            final String targetPort = 'channel_$c';

            final cConfig = channelConfigs.cast<ChannelConfigModel?>().firstWhere(
                  (ch) => ch?.commonDetails.sNo == inj.sNo,
              orElse: () => null,
            );

            bool linkAdded = false;
            if (cConfig != null && cConfig.outletTankValve.isNotEmpty) {
              for (final double vSNo in cConfig.outletTankValve) {
                if (fertTankValveNodeMap.containsKey(vSNo)) {
                  final targetValveNode = fertTankValveNodeMap[vSNo]!;
                  final sourcePort = fertTankValvePortMap[vSNo] ?? 'outlet';
                  fertLinks.add(_FertLink(targetValveNode, sourcePort, skidNode, targetPort));
                  linkAdded = true;
                }
              }
            }

            if (!linkAdded && fertTankValveNodeMap.isNotEmpty) {
              final valves = fertTankValveNodeMap.values.toSet().toList();
              final targetValveNode = valves[c % valves.length];
              final sourcePort = targetValveNode.type == NodeType.multiOutletTankValve
                  ? 'channel_${c % math.max(1, targetValveNode.outletPortCount)}'
                  : 'outlet';
              fertLinks.add(_FertLink(targetValveNode, sourcePort, skidNode, targetPort));
            }
          }
        }
      } else if (fertTanks.isNotEmpty || channelConfigs.isNotEmpty) {
        // Create 1 default Multi-Injector Skid if channels exist but no site object
        final double skidX = tankStartX + (totalAreaW - 308.0) / 2.0;
        final skidNode = NodeObject(
          id: nextId('skid_0'),
          position: Offset(skidX, provisionalSkidY),
          type: NodeType.multiInjector,
          size: const Size(308, 132),
          label: 'Multi-Injector Skid',
          showJoints: !globalHideJoints,
        );
        skidNode.size = skidNode.defaultSize;
        nodes.add(skidNode);
        skidNodes.add(skidNode);

        final valves = fertTankValveNodeMap.values.toSet().toList();
        final int channelCount = math.max(4, channelConfigs.length);

        for (int c = 0; c < channelCount; c++) {
          final String targetPort = 'channel_$c';
          final cConfig = c < channelConfigs.length ? channelConfigs[c] : null;

          bool linkAdded = false;
          if (cConfig != null && cConfig.outletTankValve.isNotEmpty) {
            for (final double vSNo in cConfig.outletTankValve) {
              if (fertTankValveNodeMap.containsKey(vSNo)) {
                final targetValveNode = fertTankValveNodeMap[vSNo]!;
                final sourcePort = fertTankValvePortMap[vSNo] ?? 'outlet';
                fertLinks.add(_FertLink(targetValveNode, sourcePort, skidNode, targetPort));
                linkAdded = true;
              }
            }
          }

          if (!linkAdded && valves.isNotEmpty) {
            final targetValveNode = valves[c % valves.length];
            final String sourcePort = targetValveNode.type == NodeType.multiOutletTankValve
                ? 'channel_${c % math.max(1, targetValveNode.outletPortCount)}'
                : 'outlet';
            fertLinks.add(_FertLink(targetValveNode, sourcePort, skidNode, targetPort));
          }
        }
      }

      _routeFertilizerLinks(fertLinks, skidNodes, maxValveBottom);
    }

    return skidNodes;
  }

  // ---------------------------------------------------------------------
  // Fertilizer pipe routing (tank valve outlets -> injector skid channels)
  // ---------------------------------------------------------------------

  /// Draws every valve outlet (facing down) to its skid channel (entering
  /// from the top) as a tidy "bus":
  ///
  ///   valve outlet -> straight down -> own horizontal lane -> down -> channel
  ///
  ///  * a single skid is first centred under the valves (shortest jogs);
  ///  * lanes are evenly spaced and ordered so that pipes do not cross;
  ///  * when several valve outlets feed ONE channel they merge in a joint
  ///    just above that channel instead of being drawn on top of each other;
  ///  * the skid is pushed down so there is always room for the lanes.
  void _routeFertilizerLinks(
      List<_FertLink> links,
      List<NodeObject> skids,
      double valveBottom,
      ) {
    if (skids.isEmpty || links.isEmpty) return;

    // 1. Centre a lone skid under the valves it is fed from.
    if (skids.length == 1) {
      final skid = skids.first;
      final diffs = [
        for (final l in links)
          l.valve.getPort(l.valvePort, isInput: false).dx -
              l.skid.getPort(l.skidPort, isInput: true).dx,
      ]..sort();
      final double shift = diffs[diffs.length ~/ 2];
      skid.position = Offset(math.max(0.0, skid.position.dx + shift), skid.position.dy);
    }

    // Update coordinates
    double portBottom = valveBottom;
    for (final l in links) {
      l.x1 = l.valve.getPort(l.valvePort, isInput: false).dx;
      l.x2 = l.skid.getPort(l.skidPort, isInput: true).dx;
      portBottom = math.max(portBottom, l.valve.getPort(l.valvePort, isInput: false).dy);
    }

    // 2. Group links by valve source (valve.id + valvePort)
    final Map<String, List<_FertLink>> sourceGroups = {};
    for (final l in links) {
      final key = '${l.valve.id}|${l.valvePort}';
      sourceGroups.putIfAbsent(key, () => []).add(l);
    }

    // 3. Group links by target skid channel (skid.id + skidPort)
    final Map<String, List<_FertLink>> targetGroups = {};
    for (final l in links) {
      final key = '${l.skid.id}|${l.skidPort}';
      targetGroups.putIfAbsent(key, () => []).add(l);
    }

    // Calculate center X of skids
    double skidSumX = 0;
    for (final s in skids) {
      skidSumX += s.position.dx + s.size.width / 2;
    }
    final double skidCenterX = skids.isNotEmpty ? skidSumX / skids.length : 300.0;

    // Sort source entries by distance to skid center ascending
    final sortedSourceEntries = sourceGroups.entries.toList()
      ..sort((a, b) {
        final startXA = a.value.first.valve.getPort(a.value.first.valvePort, isInput: false).dx;
        final startXB = b.value.first.valve.getPort(b.value.first.valvePort, isInput: false).dx;
        final distA = (startXA - skidCenterX).abs();
        final distB = (startXB - skidCenterX).abs();
        final c = distA.compareTo(distB);
        return c != 0 ? c : startXA.compareTo(startXB);
      });

    const double firstLaneGap = 16.0;
    const double laneStep = 10.0;
    const double mergeGap = 16.0;
    const double skidGap = 25.0;

    // Assign horizontal lanes with Greedy Interval Coloring so non-overlapping routes share Y-levels
    final List<List<_Segment>> laneOccupancy = [];
    final Map<String, int> entryLaneMap = {};

    int assignLane(double xA, double xB) {
      const double margin = 10.0;
      final segStart = math.min(xA, xB) - margin;
      final segEnd = math.max(xA, xB) + margin;

      for (int l = 0; l < laneOccupancy.length; l++) {
        final lane = laneOccupancy[l];
        final bool overlaps = lane.any((s) => !(segEnd < s.start || segStart > s.end));
        if (!overlaps) {
          lane.add(_Segment(segStart, segEnd));
          return l;
        }
      }
      laneOccupancy.add([_Segment(segStart, segEnd)]);
      return laneOccupancy.length - 1;
    }

    for (final entry in sortedSourceEntries) {
      final gLinks = entry.value;
      final firstLink = gLinks.first;
      final Offset startPt = firstLink.valve.getPort(firstLink.valvePort, isInput: false);

      if (gLinks.length == 1) {
        final l = gLinks.first;
        final Offset channelPt = l.skid.getPort(l.skidPort, isInput: true);
        if ((startPt.dx - channelPt.dx).abs() >= 1.0) {
          entryLaneMap[entry.key] = assignLane(startPt.dx, channelPt.dx);
        }
      } else {
        double minX = startPt.dx;
        double maxX = startPt.dx;
        for (final l in gLinks) {
          final Offset channelPt = l.skid.getPort(l.skidPort, isInput: true);
          minX = math.min(minX, channelPt.dx);
          maxX = math.max(maxX, channelPt.dx);
        }
        entryLaneMap[entry.key] = assignLane(minX, maxX);
      }
    }

    final int totalLanes = math.max(1, laneOccupancy.length);
    final double lane0 = portBottom + firstLaneGap;
    final double mergeY = lane0 + (totalLanes * laneStep) + mergeGap;
    final double skidY = mergeY + skidGap;

    for (final s in skids) {
      s.position = Offset(s.position.dx, skidY);
    }

    // 4. Create merge junctions above each skid channel that has incoming links
    final Map<String, NodeObject> mergeJunctions = {};
    for (final entry in targetGroups.entries) {
      final firstLink = entry.value.first;
      final Offset channelPt = firstLink.skid.getPort(firstLink.skidPort, isInput: true);
      final Offset jp = Offset(channelPt.dx, mergeY);

      final jn = newJunction(jp);
      mergeJunctions[entry.key] = jn;

      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: jn.id,
        toNodeId: firstLink.skid.id,
        toPortId: firstLink.skidPort,
        waypoints: cleanWaypoints(jp, [], channelPt),
      ));
    }

    // 5. Create pipes for each source group
    for (final entry in sortedSourceEntries) {
      final gLinks = entry.value;
      final firstLink = gLinks.first;
      final Offset startPt = firstLink.valve.getPort(firstLink.valvePort, isInput: false);

      if (gLinks.length == 1) {
        final l = gLinks.first;
        final targetKey = '${l.skid.id}|${l.skidPort}';
        final targetJn = mergeJunctions[targetKey]!;
        final Offset targetPos = Offset(targetJn.position.dx + 5, targetJn.position.dy + 5);

        if ((startPt.dx - targetPos.dx).abs() < 1.0) {
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: l.valve.id,
            fromPortId: l.valvePort,
            toNodeId: targetJn.id,
            waypoints: cleanWaypoints(startPt, [], targetPos),
          ));
        } else {
          final int lIdx = entryLaneMap[entry.key] ?? 0;
          final double lY = lane0 + laneStep * lIdx;
          final List<Offset> wps = [
            Offset(startPt.dx, lY),
            Offset(targetPos.dx, lY),
          ];

          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: l.valve.id,
            fromPortId: l.valvePort,
            toNodeId: targetJn.id,
            waypoints: cleanWaypoints(startPt, wps, targetPos),
          ));
        }
      } else {
        final int lIdx = entryLaneMap[entry.key] ?? 0;
        final double distLane = lane0 + laneStep * lIdx;

        final Offset trunkEnd = Offset(startPt.dx, distLane);
        final NodeObject jnTrunk = newJunction(trunkEnd);

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: firstLink.valve.id,
          fromPortId: firstLink.valvePort,
          toNodeId: jnTrunk.id,
          waypoints: cleanWaypoints(startPt, [], trunkEnd),
        ));

        for (final l in gLinks) {
          final targetKey = '${l.skid.id}|${l.skidPort}';
          final targetJn = mergeJunctions[targetKey]!;
          final Offset targetPos = Offset(targetJn.position.dx + 5, targetJn.position.dy + 5);

          if ((targetPos.dx - startPt.dx).abs() < 1.0) {
            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: jnTrunk.id,
              toNodeId: targetJn.id,
              waypoints: cleanWaypoints(trunkEnd, [], targetPos),
            ));
          } else {
            final Offset teePt = Offset(targetPos.dx, distLane);
            final NodeObject jnTee = newJunction(teePt);

            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: jnTrunk.id,
              toNodeId: jnTee.id,
              waypoints: cleanWaypoints(trunkEnd, [], teePt),
            ));

            pipes.add(PipeConnection(
              id: nextId('pipe'),
              fromNodeId: jnTee.id,
              toNodeId: targetJn.id,
              waypoints: cleanWaypoints(teePt, [], targetPos),
            ));
          }
        }
      }
    }
  }
}