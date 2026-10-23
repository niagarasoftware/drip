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
    const int kMaxValvesPerRow = 15;

    // Check total assigned valves & foggers across all lines
    final int totalValves = lines.fold<int>(0, (sum, l) => sum + l.valve.length + l.mainValve.length + l.flowControlValve.length);
    final int totalFoggers = lines.fold<int>(0, (sum, l) => sum + l.fogger.length);

    // If no irrigation line has any valves or foggers configured, do not draw irrigation lines
    if (totalValves == 0 && totalFoggers == 0) return;

    // Calculate actual maximum right edge across all irrigation line equipment
    double maxLineEquipmentX = math.max(300.0, skidRightX);
    for (int i = 0; i < lines.length; i++) {
      final lineSpec = lines[i];
      int lValves = lineSpec.valve.length;
      if (lValves == 0) {
        lValves = lineSpec.mainValve.length + lineSpec.flowControlValve.length;
      }
      int lFoggers = lineSpec.fogger.length;
      if (lValves > 0) {
        final int bankValves = math.min(lValves, kMaxValvesPerRow);
        final double bankWidth = math.max(120.0, 60.0 * bankValves + 60.0);
        maxLineEquipmentX = math.max(maxLineEquipmentX, 70.0 + bankWidth);
      }
      if (lFoggers > 0) {
        final double foggerWidth = math.max(100.0, 50.0 * lFoggers + 20.0);
        maxLineEquipmentX = math.max(maxLineEquipmentX, 70.0 + foggerWidth);
      }
    }

    // Equipment and manifold positions on left
    const double headerX = 70.0;
    const double valveBankX = 70.0;
    const double lineDropX = 30.0; // Left manifold line

    double currentY = math.max(mainPipeY + 70.0, startPt.dy + 70.0);

    // Direct main supply pipe: startJunction -> left distribution manifold top
    final Offset topHeaderPt = Offset(lineDropX, startPt.dy);
    final NodeObject topHeaderJn;
    if ((startPt.dx - lineDropX).abs() > 1.0) {
      topHeaderJn = newJunction(topHeaderPt);
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: startJunction.id,
        toNodeId: topHeaderJn.id,
        waypoints: cleanWaypoints(startPt, [], topHeaderPt),
      ));
    } else {
      topHeaderJn = startJunction;
    }

    NodeObject prevJn = topHeaderJn;
    Offset prevPt = topHeaderPt;

    for (int i = 0; i < lines.length; i++) {
      final lineSpec = lines[i];

      // Get Line i's valve count and fogger count
      int lValves = lineSpec.valve.length;
      if (lValves == 0) {
        lValves = lineSpec.mainValve.length + lineSpec.flowControlValve.length;
      }
      int lFoggers = lineSpec.fogger.length;

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

      final double headerY = currentY;

      final lineHeaderNode = NodeObject(
        id: nextId('line_header_$i'),
        position: Offset(headerX, headerY),
        type: NodeType.lineHeader,
        label: lineName,
        showJoints: false,
      );
      lineHeaderNode.size = Size(math.max(120.0, 9.0 * lineName.length + 32.0), 30);
      nodes.add(lineHeaderNode);

      final double valveBankStartY = headerY + 45.0;

      // Split lValves into rows/banks of at most kMaxValvesPerRow (15) valves
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
        bankNode.size = Size(math.max(120.0, 60.0 * bankValves + 60.0), 180);
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

      final Offset lineJnPt = Offset(lineDropX, firstInlet.dy);
      final NodeObject lineJn = newJunction(lineJnPt);

      // Connect along left manifold riser
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: prevJn.id,
        toNodeId: lineJn.id,
        waypoints: cleanWaypoints(prevPt, [], lineJnPt),
      ));

      // Connect horizontal feed into Bank 0 inlet
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: lineJn.id,
        toNodeId: targetFirstNode.id,
        toPortId: 'inlet',
        waypoints: cleanWaypoints(lineJnPt, [], firstInlet),
      ));

      prevJn = lineJn;
      prevPt = lineJnPt;

      // Connect subsequent valve bank rows
      for (int b = 1; b < lineValveBanks.length; b++) {
        final bankNode = lineValveBanks[b];
        final Offset bankInlet = bankNode.inputPort;
        final Offset bankJnPt = Offset(lineDropX, bankInlet.dy);
        final NodeObject jnBank = newJunction(bankJnPt);

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: prevJn.id,
          toNodeId: jnBank.id,
          waypoints: cleanWaypoints(prevPt, [], bankJnPt),
        ));

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: jnBank.id,
          toNodeId: bankNode.id,
          toPortId: 'inlet',
          waypoints: cleanWaypoints(bankJnPt, [], bankInlet),
        ));

        prevJn = jnBank;
        prevPt = bankJnPt;
      }

      // Connect Fogger System if present
      if (lineValveBanks.isNotEmpty && foggerSystemNode != null) {
        final Offset foggerInlet = foggerSystemNode.inputPort;
        final Offset foggerJnPt = Offset(lineDropX, foggerInlet.dy);
        final NodeObject jnFogger = newJunction(foggerJnPt);

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: prevJn.id,
          toNodeId: jnFogger.id,
          waypoints: cleanWaypoints(prevPt, [], foggerJnPt),
        ));

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: jnFogger.id,
          toNodeId: foggerSystemNode.id,
          toPortId: 'inlet',
          waypoints: cleanWaypoints(foggerJnPt, [], foggerInlet),
        ));

        prevJn = jnFogger;
        prevPt = foggerJnPt;
      }

      final double lineSetupBottom = foggerSystemNode != null
          ? (foggerSystemNode.position.dy + 112.0)
          : (lineValveBanks.isNotEmpty ? lineValveBanks.last.position.dy + 190.0 : valveBankStartY + 190.0);

      currentY = lineSetupBottom + 60.0;
    }
  }
}