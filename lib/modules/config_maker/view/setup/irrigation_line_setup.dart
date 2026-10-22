import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../model/node_type_model.dart';
import '../../state_management/config_maker_provider.dart';
import 'site_layout_context.dart';

/// IRRIGATION LINE SETUP
/// Irrigation line headers, valve banks and fogger systems, fed from the main
/// water pipe through a right-hand distribution riser.
class IrrigationLineSetup extends SiteSetupBase {
  IrrigationLineSetup(super.ctx);

  /// Draws every irrigation line starting at [startJunction].
  void connect({
    required NodeObject startJunction,
    required Offset startPt,
    required double mainPipeY,
    required double skidRightX,
    required ConfigMakerProvider configPvd,
  }) {
    final lines = configPvd.line;
    if (lines.isEmpty) return;

    // Maximum number of valves shown per row / multiValve bank
    const int kMaxValvesPerRow = 20;

    // Check total assigned valves & foggers across all lines
    final int totalValves = lines.fold<int>(0, (sum, l) => sum + l.valve.length + l.mainValve.length + l.flowControlValve.length);
    final int totalFoggers = lines.fold<int>(0, (sum, l) => sum + l.fogger.length);

    // Calculate actual maximum right edge across all irrigation line equipment
    double maxLineEquipmentX = math.max(300.0, skidRightX);
    for (int i = 0; i < lines.length; i++) {
      final lineSpec = lines[i];
      int lValves = lineSpec.valve.length;
      if (lValves == 0) {
        lValves = lineSpec.mainValve.length + lineSpec.flowControlValve.length;
      }
      int lFoggers = lineSpec.fogger.length;
      if (totalValves == 0 && totalFoggers == 0 && i == 0) {
        lValves = 6;
        lFoggers = 4;
      }
      if (lValves > 0) {
        final int bankValves = math.min(lValves, kMaxValvesPerRow);
        final double bankWidth = math.max(120.0, 70.0 * bankValves + 40.0);
        maxLineEquipmentX = math.max(maxLineEquipmentX, 80.0 + bankWidth);
      }
      if (lFoggers > 0) {
        final double foggerWidth = math.max(100.0, 50.0 * lFoggers + 20.0);
        maxLineEquipmentX = math.max(maxLineEquipmentX, 80.0 + foggerWidth);
      }
    }

    // Main Irrigation Line loop far right riser position (tight wrap around equipment)
    final double loopFarX = math.max(450.0, maxLineEquipmentX + 80.0);
    double currentReturnY = mainPipeY + 90.0;

    // Common supply pipe segment from startJunction -> right distribution riser top
    final Offset topRiserPt = Offset(loopFarX, startPt.dy);
    final NodeObject topRiserJn = newJunction(topRiserPt);
    pipes.add(PipeConnection(
      id: nextId('pipe'),
      fromNodeId: startJunction.id,
      toNodeId: topRiserJn.id,
      waypoints: cleanWaypoints(startPt, [], topRiserPt),
    ));

    NodeObject prevRiserJn = topRiserJn;
    Offset prevRiserPt = topRiserPt;

    for (int i = 0; i < lines.length; i++) {
      final lineSpec = lines[i];

      // Get Line i's valve count and fogger count
      int lValves = lineSpec.valve.length;
      if (lValves == 0) {
        lValves = lineSpec.mainValve.length + lineSpec.flowControlValve.length;
      }
      int lFoggers = lineSpec.fogger.length;

      // Fallback for Line 0 if no line has assigned valves or foggers yet
      if (totalValves == 0 && totalFoggers == 0 && i == 0) {
        lValves = 6;
        lFoggers = 4;
      }

      // If this specific line has 0 valves and 0 foggers, skip creating nodes for it
      if (lValves == 0 && lFoggers == 0) continue;

      final String lineName = (lineSpec.commonDetails.name?.isNotEmpty == true && lineSpec.commonDetails.name != '-')
          ? lineSpec.commonDetails.name!
          : 'Irrigation Line ${i + 1}';

      // Gather all valve names for Line i
      final List<String> allValveNames = [];
      if (lineSpec.valve.isNotEmpty) {
        for (int v = 0; v < lineSpec.valve.length; v++) {
          final double vSno = lineSpec.valve[v];
          final deviceObj = getObjectName(vSno, configPvd);
          final String name = (deviceObj.name?.isNotEmpty == true && deviceObj.name != '-')
              ? deviceObj.name!
              : 'Valve ${v + 1}';
          allValveNames.add(name);
        }
      } else {
        for (int v = 0; v < lValves; v++) {
          allValveNames.add('Valve ${v + 1}');
        }
      }

      final double headerX = 80.0;
      final double headerY = currentReturnY - 40.0;

      final lineHeaderNode = NodeObject(
        id: nextId('line_header_$i'),
        position: Offset(headerX, headerY),
        type: NodeType.lineHeader,
        label: lineName,
        showJoints: false,
      );
      lineHeaderNode.size = Size(math.max(120.0, 9.0 * lineName.length + 32.0), 30);
      nodes.add(lineHeaderNode);

      final double valveBankX = 80.0;
      final double valveBankStartY = currentReturnY + 55.0;

      // Split lValves into rows/banks of at most kMaxValvesPerRow (20) valves
      final int bankCount = lValves > 0 ? (lValves / kMaxValvesPerRow).ceil() : 0;
      final List<NodeObject> lineValveBanks = [];

      for (int b = 0; b < bankCount; b++) {
        final int startIdx = b * kMaxValvesPerRow;
        final int endIdx = math.min(startIdx + kMaxValvesPerRow, lValves);
        final int bankValves = endIdx - startIdx;
        final List<String> bankValveNames = allValveNames.sublist(
          math.min(startIdx, allValveNames.length),
          math.min(endIdx, allValveNames.length),
        );

        final double bankY = valveBankStartY + b * (190.0 + 35.0);

        final bankNode = NodeObject(
          id: nextId('multi_valve_line_${i}_bank_$b'),
          position: Offset(valveBankX, bankY),
          type: NodeType.multiValve,
          label: '',
          outletPortCount: bankValves,
          showJoints: !globalHideJoints,
          portLabels: bankValveNames,
        );
        bankNode.size = Size(math.max(120.0, 70.0 * bankValves + 40.0), 190);
        nodes.add(bankNode);
        lineValveBanks.add(bankNode);
      }

      // Height occupied by all valve banks in Line i
      final double valveBanksTotalH = bankCount > 0
          ? (bankCount * 190.0 + (bankCount - 1) * 35.0)
          : 0.0;

      // Create Multi-Fogger System for Line i (below last valve bank row)
      NodeObject? foggerSystemNode;
      if (lFoggers > 0) {
        final double foggerSystemY = bankCount > 0
            ? (valveBankStartY + valveBanksTotalH + 35.0)
            : valveBankStartY;
        foggerSystemNode = NodeObject(
          id: nextId('multi_fogger_line_$i'),
          position: Offset(valveBankX, foggerSystemY),
          type: NodeType.multiFogger,
          label: '$lineName - Multi-Fogger System',
          outletPortCount: lFoggers,
          showJoints: !globalHideJoints,
        );
        foggerSystemNode.size = Size(math.max(100.0, 50.0 * lFoggers + 20.0), 112);
        nodes.add(foggerSystemNode);
      }

      // First inlet port that feeds Line i
      final NodeObject targetFirstNode = lineValveBanks.isNotEmpty
          ? lineValveBanks.first
          : foggerSystemNode!;
      final Offset firstInlet = targetFirstNode.inputPort;
      final double lineDropX = firstInlet.dx - 40.0;

      // Vertical distribution riser junction on right for Line i
      final Offset lineBranchRiserPt = Offset(loopFarX, currentReturnY);
      final NodeObject lineBranchJn = newJunction(lineBranchRiserPt);

      // Connect right riser: prevRiserJn -> lineBranchJn
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: prevRiserJn.id,
        toNodeId: lineBranchJn.id,
        waypoints: cleanWaypoints(prevRiserPt, [], lineBranchRiserPt),
      ));

      // Connect horizontal branch pipe from right riser across to left manifold line
      final Offset firstJnPt = Offset(lineDropX, firstInlet.dy);
      final NodeObject jnBank0 = newJunction(firstJnPt);

      final List<Offset> branchWps = [
        Offset(lineDropX, currentReturnY),
        Offset(lineDropX, firstInlet.dy),
      ];
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: lineBranchJn.id,
        toNodeId: jnBank0.id,
        waypoints: cleanWaypoints(lineBranchRiserPt, branchWps, firstJnPt),
      ));

      // Connect jnBank0 -> Bank 0 inlet
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: jnBank0.id,
        toNodeId: targetFirstNode.id,
        toPortId: 'inlet',
        waypoints: cleanWaypoints(firstJnPt, [], firstInlet),
      ));

      NodeObject prevBankJn = jnBank0;
      Offset prevBankJnPt = firstJnPt;

      // Connect subsequent valve bank rows vertically along lineDropX manifold
      for (int b = 1; b < lineValveBanks.length; b++) {
        final bankNode = lineValveBanks[b];
        final Offset bankInlet = bankNode.inputPort;
        final Offset bankJnPt = Offset(lineDropX, bankInlet.dy);
        final NodeObject jnBank = newJunction(bankJnPt);

        // Vertical drop along manifold
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: prevBankJn.id,
          toNodeId: jnBank.id,
          waypoints: cleanWaypoints(prevBankJnPt, [], bankJnPt),
        ));

        // Horizontal feed into Bank b inlet
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: jnBank.id,
          toNodeId: bankNode.id,
          toPortId: 'inlet',
          waypoints: cleanWaypoints(bankJnPt, [], bankInlet),
        ));

        prevBankJn = jnBank;
        prevBankJnPt = bankJnPt;
      }

      // Connect Fogger System if present
      if (lineValveBanks.isNotEmpty && foggerSystemNode != null) {
        final Offset foggerInlet = foggerSystemNode.inputPort;
        final Offset foggerJnPt = Offset(lineDropX, foggerInlet.dy);
        final NodeObject jnFogger = newJunction(foggerJnPt);

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: prevBankJn.id,
          toNodeId: jnFogger.id,
          waypoints: cleanWaypoints(prevBankJnPt, [], foggerJnPt),
        ));

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: jnFogger.id,
          toNodeId: foggerSystemNode.id,
          toPortId: 'inlet',
          waypoints: cleanWaypoints(foggerJnPt, [], foggerInlet),
        ));
      }

      // Calculate vertical Y for next line setup below Line i
      final double lineSetupBottom = foggerSystemNode != null
          ? (foggerSystemNode.position.dy + 112.0)
          : (lineValveBanks.isNotEmpty ? lineValveBanks.last.position.dy + 190.0 : valveBankStartY + 190.0);

      currentReturnY = lineSetupBottom + 100.0;
      prevRiserJn = lineBranchJn;
      prevRiserPt = lineBranchRiserPt;
    }
  }
}