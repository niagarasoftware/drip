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

  /// Draws every irrigation line starting at the assigned fertigation site or [defaultStartJunction].
  void connect({
    required NodeObject defaultStartJunction,
    required Offset defaultStartPt,
    required double mainPipeY,
    required Map<double, NodeObject> skidOutJunctionMap,
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
    double maxLineEquipmentX = 300.0;
    double maxRightX = defaultStartPt.dx;
    for (final jn in skidOutJunctionMap.values) {
      final p = portPosition(jn, null, isInput: false);
      maxRightX = math.max(maxRightX, p.dx);
    }

    for (int i = 0; i < lines.length; i++) {
      final lineSpec = lines[i];
      int lValves = lineSpec.valve.length;
      if (lValves == 0) {
        lValves = lineSpec.mainValve.length + lineSpec.flowControlValve.length;
      }
      int lFoggers = lineSpec.fogger.length;
      if (lValves > 0) {
        final int bankValves = math.min(lValves, kMaxValvesPerRow);
        final double bankWidth = math.max(200.0, 60.0 * bankValves + 90.0);
        maxLineEquipmentX = math.max(maxLineEquipmentX, 70.0 + bankWidth + 30.0);
      }
      if (lFoggers > 0) {
        final double foggerWidth = math.max(120.0, 50.0 * lFoggers + 30.0);
        maxLineEquipmentX = math.max(maxLineEquipmentX, 70.0 + foggerWidth + 30.0);
      }
    }

    maxRightX = math.max(maxRightX, maxLineEquipmentX);

    const double valveBankX = 70.0;
    const double lineLeftX = 30.0;
    final double mainRiserX = (maxRightX + 60.0 + skidOutJunctionMap.length * 50.0).roundToDouble();

    double currentY = math.max(mainPipeY + 40.0, defaultStartPt.dy + 40.0);

    // 1. Main water supply riser from defaultStartJunction to mainRiserX
    final Offset mainTopRiserPt = Offset(mainRiserX, defaultStartPt.dy);
    final NodeObject mainTopRiserJn;
    if ((defaultStartPt.dx - mainRiserX).abs() > 1.0) {
      mainTopRiserJn = newJunction(mainTopRiserPt);
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: defaultStartJunction.id,
        toNodeId: mainTopRiserJn.id,
        waypoints: cleanWaypoints(defaultStartPt, [], mainTopRiserPt),
      ));
    } else {
      mainTopRiserJn = defaultStartJunction;
    }

    NodeObject prevMainRiserJn = mainTopRiserJn;
    Offset prevMainRiserPt = mainTopRiserPt;

    // Track vertical fertigation risers per site sNo
    final Map<double, NodeObject> lastFertRiserJnMap = {};
    final Map<double, Offset> lastFertRiserPtMap = {};

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

      // Determine which fertigation site feeds this line (check central, then local)
      final double assignedSNo = (lineSpec.centralFertilization != 0.0)
          ? lineSpec.centralFertilization
          : lineSpec.localFertilization;

      final double topPipeY = currentY.roundToDouble() + 30.0;

      // 1. Line Header Badge Node ("Irrigation Line X") placed above top pipe on the left
      final lineHeaderNode = NodeObject(
        id: nextId('line_header_$i'),
        position: Offset(40.0, topPipeY - 36.0),
        type: NodeType.lineHeader,
        label: lineName,
        showJoints: false,
      );
      lineHeaderNode.size = Size(math.max(120.0, 9.0 * lineName.length + 32.0), 30);
      nodes.add(lineHeaderNode);

      final double valveBankStartY = topPipeY + 45.0;

      // Split lValves into rows/banks of at most kMaxValvesPerRow (15) valves
      final int bankCount = lValves > 0 ? (lValves / kMaxValvesPerRow).ceil() : 0;
      final List<NodeObject> lineValveBanks = [];

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

      // First inlet port that feeds Line i (Bank 0 or fogger)
      final NodeObject targetFirstNode = lineValveBanks.isNotEmpty
          ? lineValveBanks.first
          : foggerSystemNode!;
      final Offset firstInlet = targetFirstNode.inputPort;

      // --- MAIN WATER PIPE FORMATION FOR LINE i ---
      // 1. Right main water riser junction
      final Offset mainRiserJnPt = Offset(mainRiserX, topPipeY);
      final NodeObject mainRiserJn = newJunction(mainRiserJnPt);

      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: prevMainRiserJn.id,
        toNodeId: mainRiserJn.id,
        waypoints: cleanWaypoints(prevMainRiserPt, [], mainRiserJnPt),
      ));

      prevMainRiserJn = mainRiserJn;
      prevMainRiserPt = mainRiserJnPt;

      // 2. Check if this line has an assigned fertigation site
      NodeObject lineSupplyJn = mainRiserJn;
      Offset lineSupplyJnPt = mainRiserJnPt;

      if (assignedSNo != 0.0 && skidOutJunctionMap.containsKey(assignedSNo)) {
        final NodeObject skidOutJn = skidOutJunctionMap[assignedSNo]!;
        final Offset skidOutPt = portPosition(skidOutJn, null, isInput: false);
        final int siteIndex = skidOutJunctionMap.keys.toList().indexOf(assignedSNo);
        final double fertRiserX = math.max(skidOutPt.dx, maxLineEquipmentX + 60.0 + siteIndex * 50.0).roundToDouble();

        final Offset fertRiserJnPt = Offset(fertRiserX, topPipeY);
        final NodeObject fertRiserJn = newJunction(fertRiserJnPt);

        if (lastFertRiserJnMap.containsKey(assignedSNo)) {
          final NodeObject prevFertJn = lastFertRiserJnMap[assignedSNo]!;
          final Offset prevFertPt = lastFertRiserPtMap[assignedSNo]!;
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: prevFertJn.id,
            toNodeId: fertRiserJn.id,
            waypoints: cleanWaypoints(prevFertPt, [], fertRiserJnPt),
          ));
        } else {
          final List<Offset> wps = (skidOutPt.dx - fertRiserX).abs() > 1.0
              ? [Offset(fertRiserX, skidOutPt.dy)]
              : [];
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: skidOutJn.id,
            toNodeId: fertRiserJn.id,
            waypoints: cleanWaypoints(skidOutPt, wps, fertRiserJnPt),
          ));
        }

        lastFertRiserJnMap[assignedSNo] = fertRiserJn;
        lastFertRiserPtMap[assignedSNo] = fertRiserJnPt;

        // Connect main water pipe from mainRiserJn to fertRiserJn
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: mainRiserJn.id,
          toNodeId: fertRiserJn.id,
          waypoints: cleanWaypoints(mainRiserJnPt, [], fertRiserJnPt),
        ));

        lineSupplyJn = fertRiserJn;
        lineSupplyJnPt = fertRiserJnPt;
      }

      // 3. Create line components along top horizontal supply pipe
      NodeObject? mvNode;
      if (lineSpec.mainValve.isNotEmpty) {
        final int mvCount = lineSpec.mainValve.length;
        if (mvCount == 1) {
          final double mvSNo = lineSpec.mainValve.first;
          final deviceObj = getObjectName(mvSNo, configPvd);
          final String mvLabel = (deviceObj.name?.isNotEmpty == true && deviceObj.name != '-')
              ? deviceObj.name!
              : 'Main Control Valve';
          mvNode = NodeObject(
            id: nextId('single_main_valve_line_${i}_${mvSNo.toInt()}'),
            position: Offset.zero,
            type: NodeType.singleMainValve,
            label: mvLabel,
            isHorizontal: true,
            showJoints: !globalHideJoints,
          );
          mvNode.size = mvNode.defaultSize;
        } else {
          final List<String> mvNames = lineSpec.mainValve
              .map((sNo) => getObjectName(sNo, configPvd).name ?? '')
              .toList();
          mvNode = NodeObject(
            id: nextId('multi_main_valve_line_${i}'),
            position: Offset.zero,
            type: NodeType.multiMainValve,
            label: 'Multi-Main Valve',
            outletPortCount: mvCount,
            portLabels: mvNames,
            isHorizontal: true,
            showJoints: !globalHideJoints,
          );
          mvNode.size = mvNode.defaultSize;
        }
      }

      NodeObject? psNode;
      if (lineSpec.pressureIn != 0.0) {
        final double psSNo = lineSpec.pressureIn;
        final deviceObj = getObjectName(psSNo, configPvd);
        final String psLabel = (deviceObj.name?.isNotEmpty == true && deviceObj.name != '-')
            ? deviceObj.name!
            : 'Pressure In';
        psNode = NodeObject(
          id: nextId('pressure_in_line_${i}_${psSNo.toInt()}'),
          position: Offset.zero,
          type: NodeType.pressureSensor,
          label: psLabel,
          isHorizontal: true,
          showJoints: false,
        );
        psNode.size = psNode.defaultSize; // 54x54 (2x size)
      }

      NodeObject? wmNode;
      if (lineSpec.waterMeter != 0.0) {
        final double wmSNo = lineSpec.waterMeter;
        final deviceObj = getObjectName(wmSNo, configPvd);
        final String wmLabel = (deviceObj.name?.isNotEmpty == true && deviceObj.name != '-')
            ? deviceObj.name!
            : 'Water Meter';
        wmNode = NodeObject(
          id: nextId('water_meter_line_${i}_${wmSNo.toInt()}'),
          position: Offset.zero,
          type: NodeType.waterMeter,
          label: wmLabel,
          isHorizontal: true,
          showJoints: !globalHideJoints,
        );
        wmNode.size = wmNode.defaultSize;
      }

      // Order from right side: 1 - Main Valve, 2 - Pressure Sensor, 3 - Water Meter
      final List<MapEntry<NodeObject, bool>> lineComps = [];
      if (mvNode != null) lineComps.add(MapEntry(mvNode, true));
      if (psNode != null) lineComps.add(MapEntry(psNode, false));
      if (wmNode != null) lineComps.add(MapEntry(wmNode, true));

      if (lineComps.isNotEmpty) {
        final double minX = 180.0;
        final double maxX = math.max(minX + 240.0, lineSupplyJnPt.dx - 80.0);
        final double midX = (minX + maxX) / 2.0;

        const double stepX = 150.0;
        final double totalSpan = (lineComps.length - 1) * stepX;
        final double rightmostCenterX = midX + totalSpan / 2.0;

        for (int k = 0; k < lineComps.length; k++) {
          final entry = lineComps[k];
          final n = entry.key;
          final bool isInline = entry.value;
          final double centerX = rightmostCenterX - k * stepX;

          if (isInline) {
            n.position = Offset(
              (centerX - n.size.width / 2.0).roundToDouble(),
              (topPipeY - n.size.height / 2.0).roundToDouble(),
            );
          } else {
            // Mounted on top of pipe
            n.position = Offset(
              (centerX - n.size.width / 2.0).roundToDouble(),
              (topPipeY - n.size.height).roundToDouble(),
            );
          }
          nodes.add(n);
        }
      }

      // 4. Far-left elbow junction at lineLeftX, topPipeY
      final Offset leftElbowJnPt = Offset(lineLeftX, topPipeY);
      final NodeObject leftElbowJn = newJunction(leftElbowJnPt);

      // Connect supply through inline pipe nodes (right -> left) to leftElbowJn
      final List<NodeObject> inlinePipeNodes = lineComps
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      NodeObject prevSupplyJn = lineSupplyJn;
      String? prevSupplyPort;
      Offset prevSupplyPt = lineSupplyJnPt;

      for (int k = 0; k < inlinePipeNodes.length; k++) {
        final inlineNode = inlinePipeNodes[k];
        final Offset inPt = portPosition(inlineNode, 'inlet', isInput: true);
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: prevSupplyJn.id,
          fromPortId: prevSupplyPort,
          toNodeId: inlineNode.id,
          toPortId: 'inlet',
          waypoints: cleanWaypoints(prevSupplyPt, [], inPt),
        ));

        prevSupplyJn = inlineNode;
        prevSupplyPort = 'outlet';
        prevSupplyPt = portPosition(inlineNode, 'outlet', isInput: false);
      }

      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: prevSupplyJn.id,
        fromPortId: prevSupplyPort,
        toNodeId: leftElbowJn.id,
        waypoints: cleanWaypoints(prevSupplyPt, [], leftElbowJnPt),
      ));

      // 3. Lower elbow junction on far-left aligned with firstInlet.dy
      final Offset lowerLeftJnPt = Offset(lineLeftX, firstInlet.dy);
      final NodeObject lowerLeftJn = newJunction(lowerLeftJnPt);

      // Left vertical drop pipe: leftElbowJn -> lowerLeftJn (turns 90° down on far left)
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: leftElbowJn.id,
        toNodeId: lowerLeftJn.id,
        waypoints: cleanWaypoints(leftElbowJnPt, [], lowerLeftJnPt),
      ));

      // 4. Horizontal feed into Bank 0 inlet: lowerLeftJn -> targetFirstNode (turns 90° right into valve header)
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: lowerLeftJn.id,
        toNodeId: targetFirstNode.id,
        toPortId: 'inlet',
        waypoints: cleanWaypoints(lowerLeftJnPt, [], firstInlet),
      ));

      NodeObject prevLeftJn = lowerLeftJn;
      Offset prevLeftPt = lowerLeftJnPt;

      // Connect subsequent valve bank rows if bankCount > 1
      for (int b = 1; b < lineValveBanks.length; b++) {
        final bankNode = lineValveBanks[b];
        final Offset bankInlet = bankNode.inputPort;
        final Offset bankJnPt = Offset(lineLeftX, bankInlet.dy);
        final NodeObject jnBank = newJunction(bankJnPt);

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: prevLeftJn.id,
          toNodeId: jnBank.id,
          waypoints: cleanWaypoints(prevLeftPt, [], bankJnPt),
        ));

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: jnBank.id,
          toNodeId: bankNode.id,
          toPortId: 'inlet',
          waypoints: cleanWaypoints(bankJnPt, [], bankInlet),
        ));

        prevLeftJn = jnBank;
        prevLeftPt = bankJnPt;
      }

      // Connect Fogger System if present
      if (lineValveBanks.isNotEmpty && foggerSystemNode != null) {
        final Offset foggerInlet = foggerSystemNode.inputPort;
        final Offset foggerJnPt = Offset(lineLeftX, foggerInlet.dy);
        final NodeObject jnFogger = newJunction(foggerJnPt);

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: prevLeftJn.id,
          toNodeId: jnFogger.id,
          waypoints: cleanWaypoints(prevLeftPt, [], foggerJnPt),
        ));

        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: jnFogger.id,
          toNodeId: foggerSystemNode.id,
          toPortId: 'inlet',
          waypoints: cleanWaypoints(foggerJnPt, [], foggerInlet),
        ));

        prevLeftJn = jnFogger;
        prevLeftPt = foggerJnPt;
      }

      final double lineSetupBottom = foggerSystemNode != null
          ? (foggerSystemNode.position.dy + 112.0)
          : (lineValveBanks.isNotEmpty ? lineValveBanks.last.position.dy + 190.0 : valveBankStartY + 190.0);

      currentY = lineSetupBottom + 60.0;
    }
  }
}