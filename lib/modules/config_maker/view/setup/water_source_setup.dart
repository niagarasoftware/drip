import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../model/node_type_model.dart';
import '../../model/source_model.dart';
import '../../widget/painter/pipe_painter.dart';
import 'site_layout_context.dart';

/// Reference to a water supply node (pump or source or valve) and its output port.
class SupplyNodeRef {
  final NodeObject node;
  final String portId;
  SupplyNodeRef(this.node, this.portId);
}

/// What the later setups (filtration / fertigation / main pipeline) need to
/// know about the water setup.
class WaterSetupResult {
  WaterSetupResult({
    required this.supplyNodes,
    required this.maxX,
    required this.maxY,
  });

  /// Nodes (+ output port) the main irrigation water leaves the water setup from.
  final List<SupplyNodeRef> supplyNodes;

  /// Right / bottom edge of the water setup.
  final double maxX;
  final double maxY;
}

/// One pipe to be drawn by the auto-arrange layout.
class _LayoutEdge {
  final NodeObject from;
  final NodeObject to;
  final String fromPort;
  final String toPort;
  _LayoutEdge(this.from, this.to, this.fromPort, this.toPort);
}

/// Working data for one edge while the clean router builds pipes.
class _Route {
  final _LayoutEdge edge;
  late Offset start, end, startPos, endPos;
  late double y1, y2;
  late String fromId, toId;
  String? fromPort, toPort;
  int gap = 0;
  bool forward = true;
  bool straight = false;
  double? lane;
  List<Offset> stem = [];
  _Route(this.edge);
}

// ---------------------------------------------------------------------------
// Helper classes for the horizontal tree layout (waterSources.length > 8)
// ---------------------------------------------------------------------------

/// Where a horizontal run leaves an outlet port.
class _HExit {
  final Offset point; // where the horizontal run starts
  final List<Offset> stem; // waypoints needed to reach it (drop below a tank)
  _HExit(this.point, this.stem);
}

/// A target that an incoming pipe must connect to.
class _HFeed {
  final NodeObject node;
  final String? port;
  final Offset inPt;
  _HFeed(this.node, this.port, this.inPt);
}

/// [inlet valve] + tank + [outlet valve] placed as one horizontal chain.
class _HUnit {
  final _HFeed feed; // where the incoming pipe must connect
  final NodeObject outNode;
  final String outPort;
  final double right, bottom;
  _HUnit(this.feed, this.outNode, this.outPort, this.right, this.bottom);
}

/// Shared state while the horizontal layout is being built.
class _HState {
  final Map<double, NodeObject> sourceMap = {};
  final Map<double, NodeObject> pumpMap = {};
  final Map<double, NodeObject> valveMap = {};
  final Map<double, List<SourceModel>> pumpToTanks = {};
  final Set<String> positioned = {};
  final Set<double> donePumps = {};
  final Set<double> doneSources = {};
  final Map<double, double> placedBy = {}; // source sNo -> pump that placed it
  final Map<double, _HFeed> feedOf = {}; // source sNo -> where its inlet pipe connects
}

/// Water Source Formation types based on site data topology
enum WaterSourceFormation {
  compactLinear,       // Small site (<= 3 sources, direct column / linear)
  parallelBus,         // Standard site (4 to 8 sources in parallel bus formation)
  horizontalTree,      // Large site (> 8 sources in horizontal tree layout)
  cascadedStage,       // Multi-stage series (primary source -> intermediate tank -> secondary pump)
  commonHeader,        // Central manifold for mixed source types
  distributedCluster,  // Multi-station or isolated clusters
  matrixGrid,          // High-density tank farm / grid array
}

/// WATER SOURCE SETUP
/// Sources (sump / well / tank / natural source), water pumps, tank valves and
/// the pipes between them, laid out in clean layers (top section of the canvas).
class WaterSourceSetup extends SiteSetupBase {
  WaterSourceSetup(super.ctx);

  /// Evaluates site data to determine the optimal [WaterSourceFormation].
  WaterSourceFormation determineFormation() {
    final waterSources = data.waterSources;
    final waterPumps = data.waterPumps;

    if (waterSources.isEmpty && waterPumps.isEmpty) {
      return WaterSourceFormation.compactLinear;
    }

    // ---- 1. Cascaded detection (pump-to-pump chains between sources) ----
    // Intermediate = fed by a pump AND feeds another pump
    final intermediates = waterSources
        .where((s) => s.inletPump.isNotEmpty && s.outletPump.isNotEmpty)
        .length;

    // Longest chain of sources linked through pumps
    int chainDepth() {
      // a feeds b when a's outletPump appears in b's inletPump
      final Map<dynamic, List<dynamic>> next = {};
      for (final a in waterSources) {
        next[a.commonDetails.sNo] = waterSources
            .where((b) =>
        b.commonDetails.sNo != a.commonDetails.sNo &&
            b.inletPump.any((p) => a.outletPump.contains(p)))
            .map((b) => b.commonDetails.sNo)
            .toList();
      }

      final memo = <dynamic, int>{};
      int dfs(dynamic id, Set<dynamic> path) {
        if (memo.containsKey(id)) return memo[id]!;
        if (path.contains(id)) return 0; // loop guard
        path.add(id);
        int best = 1;
        for (final n in next[id] ?? const []) {
          final d = 1 + dfs(n, path);
          if (d > best) best = d;
        }
        path.remove(id);
        return memo[id] = best;
      }

      int maxDepth = 0;
      for (final s in waterSources) {
        final d = dfs(s.commonDetails.sNo, {});
        if (d > maxDepth) maxDepth = d;
      }
      return maxDepth;
    }

    // River land: intermediates = 3, depth = 4 -> cascaded
    // KSR:        intermediates = 1, depth = 3 -> not cascaded
    if (intermediates >= 2 && chainDepth() >= 4) {
      return WaterSourceFormation.cascadedStage;
    }

    // ---- 2. Common header ----
    final distinctTypes = waterSources.map((s) => s.sourceType).toSet();
    if (distinctTypes.length >= 3 && waterSources.length <= 8) {
      return WaterSourceFormation.commonHeader;
    }

    // ---- 3. Size-based ----
    if (waterSources.length > 8) {
      return WaterSourceFormation.horizontalTree;
    } else if (waterSources.length >= 4) {
      return WaterSourceFormation.parallelBus;
    } else {
      return WaterSourceFormation.compactLinear;
    }
  }

  WaterSetupResult build() {
    final formation = determineFormation();

    switch (formation) {
      case WaterSourceFormation.horizontalTree:
      case WaterSourceFormation.matrixGrid:
        return _buildHorizontalLayout();
      case WaterSourceFormation.cascadedStage:
      case WaterSourceFormation.commonHeader:
      case WaterSourceFormation.distributedCluster:
      case WaterSourceFormation.parallelBus:
      case WaterSourceFormation.compactLinear:
        return _buildStandardLayout();
    }
  }

  WaterSetupResult _buildStandardLayout() {
    final waterSources = data.waterSources;
    final waterPumps = data.waterPumps;
    final List<_LayoutEdge> edges = [];
    final Map<double, NodeObject> pumpMap = {};

    // -------------------------------------------------------------------------
    // WATER FORMATION (Top section - sources sourceType 1..5 and water pumps)
    // -------------------------------------------------------------------------
    if (waterSources.isNotEmpty || waterPumps.isNotEmpty) {
      final Map<double, NodeObject> sourceMap = {};

      for (final src in waterSources) {
        final double sNo = src.commonDetails.sNo ?? 0.0;
        final NodeType type = _getNodeTypeForSource(src.sourceType);
        final String label = (src.commonDetails.name?.isNotEmpty == true)
            ? src.commonDetails.name!
            : defaultLabelFor(type);
        final node = NodeObject(
          id: nextId('source_${sNo.toInt()}'),
          position: Offset.zero,
          type: type,
          size: const Size(68, 47),
          label: label,
          showJoints: !globalHideJoints,
        );
        node.size = node.defaultSize;
        nodes.add(node);
        sourceMap[sNo] = node;
      }

      for (final p in waterPumps) {
        final double sNo = p.commonDetails.sNo ?? 0.0;
        final String label = (p.commonDetails.name?.isNotEmpty == true)
            ? p.commonDetails.name!
            : 'Pump ${sNo.toInt()}';
        final node = NodeObject(
          id: nextId('pump_${sNo.toInt()}'),
          position: Offset.zero,
          type: NodeType.pump,
          label: label,
          isOn: true,
          showJoints: !globalHideJoints,
        );
        node.size = node.defaultSize;
        nodes.add(node);
        pumpMap[sNo] = node;
      }

      final Set<String> edgeKeys = {}; // from.port > to.port (unique pipe)
      final Set<String> pairKeys = {}; // from > to (used for loop detection)
      void addEdge(NodeObject from, NodeObject to, String fp, String tp) {
        if (edgeKeys.add('${from.id}.$fp>${to.id}.$tp')) {
          edges.add(_LayoutEdge(from, to, fp, tp));
          pairKeys.add('${from.id}>${to.id}');
        }
      }

      final Map<double, NodeObject> tankValveMap = {};

      for (final src in waterSources) {
        final double sNo = src.commonDetails.sNo ?? 0.0;
        final sn = sourceMap[sNo];
        if (sn == null) continue;

        // Create Tank Valve nodes if assigned
        // (water sources keep HORIZONTAL tank valves: inlet left, outlet right)
        NodeObject? inletValveNode;
        if (src.inletTankValve.isNotEmpty) {
          final double vSNo = src.inletTankValve.first;
          if (tankValveMap.containsKey(vSNo)) {
            inletValveNode = tankValveMap[vSNo]!;
          } else {
            final bool isMulti = src.isMultiInletTankValve;
            inletValveNode = NodeObject(
              id: nextId('inlet_valve_${vSNo.toString().replaceAll('.', '_')}'),
              position: Offset.zero,
              type: isMulti ? NodeType.multiOutletTankValve : NodeType.singleTankValve,
              label: '${src.commonDetails.name ?? 'Source'} Inlet Valve',
              outletPortCount: src.inletTankValvePortCount,
              isHorizontal: true,
              showJoints: !globalHideJoints,
            );
            inletValveNode.size = inletValveNode.defaultSize;
            nodes.add(inletValveNode);
            tankValveMap[vSNo] = inletValveNode;
          }

          final bool multiValve = inletValveNode.type == NodeType.multiOutletTankValve;
          final int channels = multiValve ? math.max(1, inletValveNode.outletPortCount) : 1;
          for (int c = 0; c < channels; c++) {
            addEdge(
              inletValveNode,
              sn,
              multiValve ? 'channel_$c' : 'outlet',
              'inlet',
            );
          }
        }

        NodeObject? outletValveNode;
        if (src.outletTankValve.isNotEmpty) {
          final double vSNo = src.outletTankValve.first;
          if (tankValveMap.containsKey(vSNo)) {
            outletValveNode = tankValveMap[vSNo]!;
          } else {
            final bool isMulti = src.isMultiOutletTankValve;
            outletValveNode = NodeObject(
              id: nextId('outlet_valve_${vSNo.toString().replaceAll('.', '_')}'),
              position: Offset.zero,
              type: isMulti ? NodeType.multiOutletTankValve : NodeType.singleTankValve,
              label: '${src.commonDetails.name ?? 'Source'} Outlet Valve',
              outletPortCount: src.outletTankValvePortCount,
              isHorizontal: true,
              showJoints: !globalHideJoints,
            );
            outletValveNode.size = outletValveNode.defaultSize;
            nodes.add(outletValveNode);
            tankValveMap[vSNo] = outletValveNode;
          }

          addEdge(
            sn,
            outletValveNode,
            'outlet',
            'inlet',
          );
        }

        // Connect inlet pumps
        for (final pNo in src.inletPump) {
          final pn = pumpMap[pNo];
          if (pn == null) continue;
          if (inletValveNode != null) {
            addEdge(pn, inletValveNode, 'output', 'inlet');
          } else {
            addEdge(pn, sn, 'output', 'inlet');
          }
        }

        // Connect outlet pumps
        for (final pNo in src.outletPump) {
          final pn = pumpMap[pNo];
          if (pn == null) continue;
          if (outletValveNode != null) {
            addEdge(
              outletValveNode,
              pn,
              outletValveNode.type == NodeType.multiOutletTankValve ? 'channel_0' : 'outlet',
              'input',
            );
          } else {
            addEdge(sn, pn, 'outlet', 'input');
          }
        }
      }

      // 1. Layering
      final layeringEdges =
      edges.where((e) => !pairKeys.contains('${e.to.id}>${e.from.id}')).toList();
      final Map<String, int> rawLayer = {for (final n in nodes) n.id: 0};
      for (int it = 0; it < nodes.length; it++) {
        bool changed = false;
        for (final e in layeringEdges) {
          final next = rawLayer[e.from.id]! + 1;
          if (rawLayer[e.to.id]! < next) {
            rawLayer[e.to.id] = next;
            changed = true;
          }
        }
        if (!changed) break;
      }
      final usedLayers = rawLayer.values.toSet().toList()..sort();
      final Map<String, int> layerOf = {
        for (final n in nodes) n.id: usedLayers.indexOf(rawLayer[n.id]!),
      };
      final int L = usedLayers.length;
      final List<List<NodeObject>> layers = List.generate(L, (_) => <NodeObject>[]);
      for (final n in nodes) {
        layers[layerOf[n.id]!].add(n);
      }

      final Map<String, List<NodeObject>> neighbours = {
        for (final n in nodes) n.id: <NodeObject>[],
      };
      for (final e in edges) {
        neighbours[e.from.id]!.add(e.to);
        neighbours[e.to.id]!.add(e.from);
      }

      // 2. Order inside columns
      void sortLayer(int l, int ref) {
        if (ref < 0 || ref >= L) return;
        final refIdx = {for (int i = 0; i < layers[ref].length; i++) layers[ref][i].id: i};
        final curIdx = {for (int i = 0; i < layers[l].length; i++) layers[l][i].id: i};
        double key(NodeObject n) {
          final idxs = neighbours[n.id]!
              .where((m) => refIdx.containsKey(m.id))
              .map((m) => refIdx[m.id]!)
              .toList();
          if (idxs.isEmpty) return curIdx[n.id]!.toDouble();
          return idxs.reduce((a, b) => a + b) / idxs.length;
        }

        final keys = {for (final n in layers[l]) n.id: key(n)};
        layers[l].sort((a, b) {
          final c = keys[a.id]!.compareTo(keys[b.id]!);
          return c != 0 ? c : curIdx[a.id]!.compareTo(curIdx[b.id]!);
        });
      }

      for (int it = 0; it < 4; it++) {
        for (int l = 1; l < L; l++) {
          sortLayer(l, l - 1);
        }
        for (int l = L - 2; l >= 0; l--) {
          sortLayer(l, l + 1);
        }
      }

      // 3. X positions
      final laneCount = List<int>.filled(math.max(L - 1, 1), 0);
      for (final e in edges) {
        final fl = layerOf[e.from.id]!, tl = layerOf[e.to.id]!;
        if (tl > fl) laneCount[tl - 1]++;
      }
      final gaps = [for (final c in laneCount) 48.0 + 18.0 * math.max(c - 1, 0)];
      final colW = [
        for (final layer in layers) layer.map((n) => n.size.width).reduce(math.max),
      ];
      final colX = List<double>.filled(L, 0);
      double x = 40.0;
      for (int i = 0; i < L; i++) {
        colX[i] = x;
        x += colW[i] + (i < L - 1 ? gaps[i] : 0);
      }

      // 4. Y positions
      const double vGap = 42.0;
      double block(NodeObject n) =>
          n.size.height + (n.type == NodeType.overheadTank ? 34.0 : 0.0);

      final Map<String, double> top = {};
      final colH = [
        for (final layer in layers)
          layer.fold<double>(0, (s, n) => s + block(n)) + vGap * (layer.length - 1),
      ];
      final double maxColH = colH.reduce(math.max);
      for (int l = 0; l < L; l++) {
        double y = (maxColH - colH[l]) / 2;
        for (final n in layers[l]) {
          top[n.id] = y;
          y += block(n) + vGap;
        }
      }

      double centerOf(NodeObject n) => top[n.id]! + n.size.height / 2;

      void relax(int l) {
        final layer = layers[l];
        final desired = <double>[];
        for (final n in layer) {
          final nb = neighbours[n.id]!.where((m) => layerOf[m.id] != l).toList();
          if (nb.isEmpty) {
            desired.add(top[n.id]!);
          } else {
            final avg = nb.map(centerOf).reduce((a, b) => a + b) / nb.length;
            desired.add(avg - n.size.height / 2);
          }
        }
        double cursor = -double.infinity;
        for (int i = 0; i < layer.length; i++) {
          final t = math.max(desired[i], cursor);
          top[layer[i].id] = t;
          cursor = t + block(layer[i]) + vGap;
        }
      }

      for (int it = 0; it < 4; it++) {
        for (int l = 0; l < L; l++) {
          relax(l);
        }
        for (int l = L - 1; l >= 0; l--) {
          relax(l);
        }
      }

      final double shiftY = 30.0 - top.values.reduce(math.min);
      for (int l = 0; l < L; l++) {
        for (final n in layers[l]) {
          n.position = Offset(
            colX[l] + (colW[l] - n.size.width) / 2,
            top[n.id]! + shiftY,
          );
        }
      }

      // 5. Clean pipe routing for water edges
      _snapNearStraightEdges(edges);
      _buildCleanPipes(edges, layerOf, colX, colW);
    }

    // Right / bottom edge of everything built so far (= the water setup)
    double maxWaterX = 0.0;
    double maxWaterY = 0.0;
    for (final n in nodes) {
      if (n.position.dx + n.size.width > maxWaterX) {
        maxWaterX = n.position.dx + n.size.width;
      }
      if (n.position.dy + n.size.height > maxWaterY) {
        maxWaterY = n.position.dy + n.size.height;
      }
    }

    final List<SupplyNodeRef> waterSupplyNodes = [];

    // First preference: pumps explicitly configured with pumpType == 2 (Irrigation Pump) in PumpConfiguration
    for (final p in waterPumps) {
      if (p.pumpType == 2) {
        final node = pumpMap[p.commonDetails.sNo ?? 0.0];
        if (node != null) waterSupplyNodes.add(SupplyNodeRef(node, 'output'));
      }
    }

    // Fallback: if no pump has pumpType == 2, use terminal water pumps (no outgoing edge in edges)
    if (waterSupplyNodes.isEmpty) {
      final outgoingFromIds = edges.map((e) => e.from.id).toSet();
      for (final p in waterPumps) {
        final node = pumpMap[p.commonDetails.sNo ?? 0.0];
        if (node != null && !outgoingFromIds.contains(node.id)) {
          waterSupplyNodes.add(SupplyNodeRef(node, 'output'));
        }
      }
    }

    if (waterSupplyNodes.isEmpty && waterPumps.isNotEmpty) {
      final lastNode = pumpMap[waterPumps.last.commonDetails.sNo ?? 0.0];
      if (lastNode != null) waterSupplyNodes.add(SupplyNodeRef(lastNode, 'output'));
    }

    // Fallback if no water pumps exist: use terminal water sources or outlet tank valves
    if (waterSupplyNodes.isEmpty && waterSources.isNotEmpty) {
      final outgoingFromIds = edges.map((e) => e.from.id).toSet();
      for (final n in nodes) {
        if (!outgoingFromIds.contains(n.id)) {
          if (n.type == NodeType.singleTankValve || n.type == NodeType.multiOutletTankValve) {
            final port = n.type == NodeType.multiOutletTankValve ? 'channel_0' : 'outlet';
            waterSupplyNodes.add(SupplyNodeRef(n, port));
          } else if (n.type == NodeType.overheadTank ||
              n.type == NodeType.sump ||
              n.type == NodeType.well ||
              n.type == NodeType.naturalSource) {
            waterSupplyNodes.add(SupplyNodeRef(n, 'outlet'));
          }
        }
      }
    }

    return WaterSetupResult(
      supplyNodes: waterSupplyNodes,
      maxX: maxWaterX,
      maxY: maxWaterY,
    );
  }

  // -------------------------------------------------------------------------
  // HORIZONTAL TREE LAYOUT (used when waterSources.length > 8)
  // source -> pumps (column) -> tank rows -> (tank with outlet pumps -> ...)
  // -------------------------------------------------------------------------
  static const double _hPumpGap = 130;
  static const double _hTankGap = 110;
  static const double _hUnitGap = 60;
  static const double _hBusReserve = 40; // space above a row for its bus pipe
  static const double _hBusAbove = 30; // bus sits this far above tank inlets
  static const double _hRowTail = 60; // label + outlet drop below a row
  static const double _hTrunkOff = 30;
  static const int _hMaxPerRow = 4;
  static const int _hMaxColRows = 3; // tank rows per pump column before a new column starts (wider, shorter layout)

  WaterSetupResult _buildHorizontalLayout() {
    final waterSources = data.waterSources;
    final waterPumps = data.waterPumps;
    final s = _HState();

    // 1. nodes ---------------------------------------------------------------
    for (final src in waterSources) {
      final double sNo = src.commonDetails.sNo ?? 0.0;
      final NodeType type = _getNodeTypeForSource(src.sourceType);
      final String label = (src.commonDetails.name?.isNotEmpty == true)
          ? src.commonDetails.name!
          : defaultLabelFor(type);
      final node = NodeObject(
        id: nextId('source_${sNo.toInt()}'),
        position: Offset.zero,
        type: type,
        size: const Size(68, 47),
        label: label,
        showJoints: !globalHideJoints,
      );
      node.size = node.defaultSize;
      nodes.add(node);
      s.sourceMap[sNo] = node;
    }

    for (final p in waterPumps) {
      final double sNo = p.commonDetails.sNo ?? 0.0;
      final String label = (p.commonDetails.name?.isNotEmpty == true)
          ? p.commonDetails.name!
          : 'Pump ${sNo.toInt()}';
      final node = NodeObject(
        id: nextId('pump_${sNo.toInt()}'),
        position: Offset.zero,
        type: NodeType.pump,
        label: label,
        isOn: true,
        showJoints: !globalHideJoints,
      );
      node.size = node.defaultSize;
      nodes.add(node);
      s.pumpMap[sNo] = node;
    }

    NodeObject makeValve(double vSNo, SourceModel src, bool inlet) {
      final bool isMulti =
      inlet ? src.isMultiInletTankValve : src.isMultiOutletTankValve;
      final v = NodeObject(
        id: nextId('${inlet ? 'inlet' : 'outlet'}_valve_${vSNo.toString().replaceAll('.', '_')}'),
        position: Offset.zero,
        type: isMulti ? NodeType.multiOutletTankValve : NodeType.singleTankValve,
        label: '${src.commonDetails.name ?? 'Source'} ${inlet ? 'Inlet' : 'Outlet'} Valve',
        outletPortCount: inlet ? src.inletTankValvePortCount : src.outletTankValvePortCount,
        isHorizontal: true,
        showJoints: !globalHideJoints,
      );
      v.size = v.defaultSize;
      nodes.add(v);
      return v;
    }

    for (final src in waterSources) {
      if (src.inletTankValve.isNotEmpty) {
        final v = src.inletTankValve.first;
        s.valveMap.putIfAbsent(v, () => makeValve(v, src, true));
      }
      if (src.outletTankValve.isNotEmpty) {
        final v = src.outletTankValve.first;
        s.valveMap.putIfAbsent(v, () => makeValve(v, src, false));
      }
    }

    for (final src in waterSources) {
      for (final pNo in src.inletPump) {
        s.pumpToTanks.putIfAbsent(pNo, () => []).add(src);
      }
    }

    // 2. tree layout from every root source (no inlet pump) -------------------
    final roots = waterSources.where((x) => x.inletPump.isEmpty).toList();
    if (roots.isEmpty && waterSources.isNotEmpty) roots.add(waterSources.first);

    double cursorY = 40.0;
    for (final root in roots) {
      final double sNo = root.commonDetails.sNo ?? 0.0;
      final node = s.sourceMap[sNo];
      if (node == null || !s.doneSources.add(sNo)) continue;
      node.position = Offset(70.0, cursorY);
      s.positioned.add(node.id);
      final double h = _hLayoutPumps(
          s, root, node, 'outlet', node.position.dx + node.size.width, cursorY);
      cursorY += math.max(h, node.size.height + _hRowTail) + 40.0;
    }

    // pumps that fill tanks but are not listed as an outlet pump of any placed
    // source: lay them out on their own so that no tank is ever lost
    for (final entry in s.pumpToTanks.entries.toList()) {
      final double pNo = entry.key;
      final pump = s.pumpMap[pNo];
      if (pump == null || s.donePumps.contains(pNo)) continue;
      final bool allPlaced =
      entry.value.every((t) => s.doneSources.contains(t.commonDetails.sNo ?? 0.0));
      if (allPlaced) continue;
      s.donePumps.add(pNo);
      final double h = _hLayoutPumpRow(s, pNo, pump, 70.0, cursorY);
      s.positioned.add(pump.id);
      cursorY += h + 40.0;
    }

    // anything not reachable from a root goes on a tidy row at the bottom
    final leftovers = [
      ...s.sourceMap.values,
      ...s.pumpMap.values,
      ...s.valveMap.values,
    ].where((n) => !s.positioned.contains(n.id)).toList();
    double cleanX = 70.0;
    for (final n in leftovers) {
      n.position = Offset(cleanX, cursorY);
      cleanX += n.size.width + 40.0;
    }

    if (leftovers.isNotEmpty) {
      debugPrint('WaterSourceSetup: ${leftovers.length} nodes are not linked to '
          'the tree: ${leftovers.map((n) => n.label).join(', ')}');
    }

    // a tank fed by several pumps: the pump that placed it has its pipe,
    // every other inlet pump gets its own pipe to the same inlet
    for (final src in waterSources) {
      final double sNo = src.commonDetails.sNo ?? 0.0;
      final feed = s.feedOf[sNo];
      if (feed == null) continue;
      for (final pNo in src.inletPump) {
        final pump = s.pumpMap[pNo];
        if (pump == null || pNo == s.placedBy[sNo]) continue;
        pipes.add(_createOrthogonalPipe(
          fromNode: pump,
          toNode: feed.node,
          fromPortId: 'output',
          toPortId: feed.port,
        ));
      }
    }

    // 3. bounds ----------------------------------------------------------------
    double maxWaterX = 0.0, maxWaterY = 0.0;
    for (final n in nodes) {
      maxWaterX = math.max(maxWaterX, n.position.dx + n.size.width);
      maxWaterY = math.max(maxWaterY, n.position.dy + n.size.height);
    }

    // 4. supply nodes (same rules as the vertical layout) ----------------------
    final List<SupplyNodeRef> supply = [];
    for (final p in waterPumps) {
      if (p.pumpType == 2) {
        final n = s.pumpMap[p.commonDetails.sNo ?? 0.0];
        if (n != null) supply.add(SupplyNodeRef(n, 'output'));
      }
    }
    if (supply.isEmpty) {
      // pumps that feed no tank = the irrigation pumps
      for (final p in waterPumps) {
        final double pNo = p.commonDetails.sNo ?? 0.0;
        final n = s.pumpMap[pNo];
        if (n != null && (s.pumpToTanks[pNo] ?? const []).isEmpty) {
          supply.add(SupplyNodeRef(n, 'output'));
        }
      }
    }
    if (supply.isEmpty) {
      // last tanks of the chain (outlet valve if they have one)
      for (final src in waterSources) {
        if (_hHasChildren(s, src)) continue;
        final tank = s.sourceMap[src.commonDetails.sNo ?? 0.0];
        if (tank == null) continue;
        final ov = src.outletTankValve.isNotEmpty ? s.valveMap[src.outletTankValve.first] : null;
        if (ov != null) {
          supply.add(SupplyNodeRef(
              ov, ov.type == NodeType.multiOutletTankValve ? 'channel_0' : 'outlet'));
        } else {
          supply.add(SupplyNodeRef(tank, 'outlet'));
        }
      }
    }

    return WaterSetupResult(supplyNodes: supply, maxX: maxWaterX, maxY: maxWaterY);
  }

  bool _hHasChildren(_HState s, SourceModel src) =>
      src.outletPump.any((p) => s.pumpMap.containsKey(p));

  /// Estimated number of tank rows a pump's group needs (used to decide when
  /// to start a new pump column).
  int _hPumpRows(_HState s, double pNo, [Set<double>? seen]) {
    final visited = seen ?? <double>{};
    if (!visited.add(pNo)) return 1;
    final tanks = (s.pumpToTanks[pNo] ?? const <SourceModel>[])
        .where((t) => !s.doneSources.contains(t.commonDetails.sNo ?? 0.0))
        .toList();
    final int normals = tanks.where((t) => !_hHasChildren(s, t)).length;
    int rows = (normals / _hMaxPerRow).ceil();
    for (final t in tanks.where((t) => _hHasChildren(s, t))) {
      int child = 0;
      for (final p in t.outletPump) {
        if (s.pumpMap.containsKey(p)) child += _hPumpRows(s, p, visited);
      }
      rows += math.max(1, child);
    }
    return math.max(1, rows);
  }

  /// Lays out all pumps taking water from [outNode] to the right of [rightX].
  /// Pumps are split into several columns placed side by side (instead of one
  /// tall column), so the whole formation is wide and short. Columns after the
  /// first are fed from a bus line running above the whole formation.
  /// Returns the height used by the tallest column.
  double _hLayoutPumps(_HState s, SourceModel src, NodeObject outNode,
      String outPort, double rightX, double top) {
    final pumpNos = src.outletPump
        .where((p) => s.pumpMap.containsKey(p) && !s.donePumps.contains(p))
        .toList();
    if (pumpNos.isEmpty) return 0.0;

    // split pumps into columns
    final cols = <List<double>>[];
    int curRows = 0;
    for (final pNo in pumpNos) {
      final int w = _hPumpRows(s, pNo);
      if (cols.isEmpty || (curRows > 0 && curRows + w > _hMaxColRows)) {
        cols.add(<double>[]);
        curRows = 0;
      }
      cols.last.add(pNo);
      curRows += w;
    }

    final nodeById = {for (final n in nodes) n.id: n};
    final double busY = top - 20.0;
    double colX = rightX + _hPumpGap;
    double maxH = 0.0;
    final colTrunkX = <double>[];
    final colFeeds = <List<_HFeed>>[];

    for (final col in cols) {
      final int startCount = s.positioned.length;
      double y = top;
      final feeds = <_HFeed>[];
      for (final pNo in col) {
        if (!s.donePumps.add(pNo)) continue;
        final pump = s.pumpMap[pNo]!;
        final double h = _hLayoutPumpRow(s, pNo, pump, colX, y);
        s.positioned.add(pump.id);
        feeds.add(_HFeed(pump, 'input', portPosition(pump, 'input', isInput: true)));
        y += h;
      }
      maxH = math.max(maxH, y - top);

      // right edge of everything placed in this column (incl. nested pumps)
      double colRight = colX;
      for (final id in s.positioned.skip(startCount)) {
        final n = nodeById[id];
        if (n != null) colRight = math.max(colRight, n.position.dx + n.size.width);
      }
      colTrunkX.add(colX - _hTrunkOff);
      colFeeds.add(feeds);
      colX = colRight + _hPumpGap;
    }

    if (colFeeds.length == 1) {
      _hFan(outNode, outPort, colFeeds.first, colTrunkX.first);
      return maxH;
    }

    // extra columns: junction on the top bus above each column's trunk
    final junctions = <NodeObject>[];
    final junctionPts = <Offset>[];
    for (int k = 1; k < colFeeds.length; k++) {
      final pt = Offset(colTrunkX[k], busY);
      junctions.add(newJunction(pt));
      junctionPts.add(pt);
    }

    // source -> column 0 pumps + the top bus (its last target)
    _hFan(
      outNode,
      outPort,
      [...colFeeds.first, _HFeed(junctions.first, null, junctionPts.first)],
      colTrunkX.first,
    );

    for (int k = 0; k < junctions.length; k++) {
      if (k + 1 < junctions.length) {
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: junctions[k].id,
          toNodeId: junctions[k + 1].id,
          waypoints: cleanWaypoints(junctionPts[k], [], junctionPts[k + 1]),
          flowActive: true,
        ));
      }
      _hFanCore(junctions[k].id, null, junctionPts[k],
          _HExit(junctionPts[k], const []), colFeeds[k + 1], colTrunkX[k + 1]);
    }
    return maxH;
  }

  /// One pump + the tank rows it fills. Returns the height used.
  double _hLayoutPumpRow(
      _HState s, double pNo, NodeObject pump, double pumpX, double top) {
    pump.position = Offset(pumpX, top + _hBusReserve);

    final tanks = (s.pumpToTanks[pNo] ?? const <SourceModel>[])
        .where((t) => !s.doneSources.contains(t.commonDetails.sNo ?? 0.0))
        .toList();
    final normals = tanks.where((t) => !_hHasChildren(s, t)).toList();
    final hubs = tanks.where((t) => _hHasChildren(s, t)).toList();

    // rows: normal tanks in chunks, every "hub" tank (feeds more pumps) alone
    final rows = <List<SourceModel>>[];
    for (int i = 0; i < normals.length; i += _hMaxPerRow) {
      rows.add(normals.sublist(i, math.min(i + _hMaxPerRow, normals.length)));
    }
    for (final h in hubs) {
      rows.add([h]);
    }

    final double tankX0 = pumpX + pump.size.width + _hTankGap;
    final double trunkX = pumpX + pump.size.width + _hTrunkOff;
    double cursor = top;
    final rowUnits = <List<_HUnit>>[];

    for (final row in rows) {
      final double rowTop = cursor + _hBusReserve;
      double x = tankX0;
      double bottom = rowTop;
      final units = <_HUnit>[];
      for (final t in row) {
        s.doneSources.add(t.commonDetails.sNo ?? 0.0);
        final u = _hPlaceUnit(s, t, pNo, x, rowTop);
        units.add(u);
        x = u.right + _hUnitGap;
        bottom = math.max(bottom, u.bottom);
      }
      double rowH = bottom - cursor + _hRowTail;
      if (row.length == 1 && _hHasChildren(s, row.first)) {
        final u = units.first;
        final double childH =
        _hLayoutPumps(s, row.first, u.outNode, u.outPort, u.right, cursor);
        rowH = math.max(rowH, childH);
      }
      rowUnits.add(units);
      cursor += rowH;
    }

    final allUnits = rowUnits.expand((e) => e).toList();
    if (allUnits.length == 1) {
      _hFan(pump, 'output', [allUnits.first.feed], trunkX);
    } else if (allUnits.isNotEmpty) {
      // pump -> vertical trunk -> one bus start per row -> tees into tanks
      final busFeeds = <_HFeed>[];
      final busJunctions = <NodeObject>[];
      final busPts = <Offset>[];
      for (final units in rowUnits) {
        final double minY = units.map((u) => u.feed.inPt.dy).reduce(math.min);
        final p = Offset(trunkX + 14.0, minY - _hBusAbove);
        final jn = newJunction(p);
        busJunctions.add(jn);
        busPts.add(p);
        busFeeds.add(_HFeed(jn, null, p));
      }
      _hFan(pump, 'output', busFeeds, trunkX);
      for (int i = 0; i < rowUnits.length; i++) {
        _hBus(busJunctions[i], busPts[i], rowUnits[i]);
      }
    }

    return math.max(cursor - top, pump.size.height + _hBusReserve + _hRowTail);
  }

  /// Places [inlet valve] + tank + [outlet valve] in one horizontal chain.
  _HUnit _hPlaceUnit(_HState s, SourceModel src, double pNo, double x, double y) {
    final tank = s.sourceMap[src.commonDetails.sNo ?? 0.0]!;
    final NodeObject? inV =
    src.inletTankValve.isNotEmpty ? s.valveMap[src.inletTankValve.first] : null;
    final NodeObject? outV =
    src.outletTankValve.isNotEmpty ? s.valveMap[src.outletTankValve.first] : null;

    double cx = x;
    final bool placeIn = inV != null && !s.positioned.contains(inV.id);
    if (placeIn) {
      inV.position = Offset(cx, y);
      cx += inV.size.width + 45.0;
    }
    tank.position = Offset(cx, y);
    s.positioned.add(tank.id);
    final Offset tankIn = portPosition(tank, 'inlet', isInput: true);

    if (placeIn) {
      s.positioned.add(inV.id);
      final bool multi = inV.type == NodeType.multiOutletTankValve;
      final String p0 = multi ? 'channel_0' : 'outlet';
      // align so valve -> tank is a straight line
      final Offset v0 = portPosition(inV, p0, isInput: false);
      inV.position = inV.position + Offset(0, tankIn.dy - v0.dy);

      final int channels = multi ? math.max(1, inV.outletPortCount) : 1;
      final double mergeX = tank.position.dx - 22.0;
      for (int c = 0; c < channels; c++) {
        final String port = multi ? 'channel_$c' : 'outlet';
        final Offset vo = portPosition(inV, port, isInput: false);
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: inV.id,
          fromPortId: port,
          toNodeId: tank.id,
          toPortId: 'inlet',
          waypoints: (vo.dy - tankIn.dy).abs() < 0.5
              ? cleanWaypoints(vo, [], tankIn)
              : cleanWaypoints(vo, [Offset(mergeX, vo.dy), Offset(mergeX, tankIn.dy)], tankIn),
          flowActive: true,
        ));
      }
    }

    double right = tank.position.dx + tank.size.width;
    double bottom = tank.position.dy + tank.size.height;
    if (placeIn) bottom = math.max(bottom, inV.position.dy + inV.size.height);

    NodeObject outNode = tank;
    String outPort = 'outlet';
    if (outV != null && !s.positioned.contains(outV.id)) {
      final Offset tankOut = portPosition(tank, 'outlet', isInput: false);
      final double dropY =
      math.max(tankOut.dy + 30.0, tank.position.dy + tank.size.height + 20.0);
      outV.position = Offset(right + 50.0, y);
      final Offset vin0 = portPosition(outV, 'inlet', isInput: true);
      outV.position = outV.position + Offset(0, dropY - vin0.dy);
      final Offset vin = portPosition(outV, 'inlet', isInput: true);
      s.positioned.add(outV.id);

      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: tank.id,
        fromPortId: 'outlet',
        toNodeId: outV.id,
        toPortId: 'inlet',
        waypoints: cleanWaypoints(tankOut, [Offset(tankOut.dx, dropY)], vin),
        flowActive: true,
      ));

      outNode = outV;
      outPort = outV.type == NodeType.multiOutletTankValve ? 'channel_0' : 'outlet';
      right = outV.position.dx + outV.size.width;
      bottom = math.max(bottom, outV.position.dy + outV.size.height);
    }

    final feed = placeIn
        ? _HFeed(inV, 'inlet', portPosition(inV, 'inlet', isInput: true))
        : _HFeed(tank, 'inlet', tankIn);
    final double srcNo = src.commonDetails.sNo ?? 0.0;
    s.placedBy[srcNo] = pNo;
    s.feedOf[srcNo] = feed;
    return _HUnit(feed, outNode, outPort, right, bottom);
  }

  /// Exit point of an outlet port. Bottom outlets (tanks) drop first, so the
  /// pipe never runs through the node itself.
  _HExit _hExit(NodeObject n, String port) {
    final p = portPosition(n, port, isInput: false);
    final bool bottomOutlet = p.dy > n.position.dy + n.size.height * 0.7;
    if (!bottomOutlet) return _HExit(p, const []);
    final double dropY = math.max(p.dy + 30.0, n.position.dy + n.size.height + 20.0);
    final d = Offset(p.dx, dropY);
    return _HExit(d, [d]);
  }

  /// One output -> many inputs through a single vertical trunk at [trunkX]
  /// with a tee at each branch (all pipes orthogonal).
  void _hFan(NodeObject from, String fromPort, List<_HFeed> targets, double trunkX) {
    if (targets.isEmpty) return;
    _hFanCore(from.id, fromPort, portPosition(from, fromPort, isInput: false),
        _hExit(from, fromPort), targets, trunkX);
  }

  /// Removes duplicate / zero-length waypoints.
  List<Offset> _hDedupe(Offset start, List<Offset> wps, Offset end) {
    final out = <Offset>[];
    Offset prev = start;
    for (final w in wps) {
      if ((w - prev).distance < 0.5) continue;
      out.add(w);
      prev = w;
    }
    while (out.isNotEmpty && (out.last - end).distance < 0.5) {
      out.removeLast();
    }
    return out;
  }

  void _hFanCore(String fromId, String? fromPort, Offset start, _HExit ex,
      List<_HFeed> targets, double trunkX) {
    if (targets.isEmpty) return;
    final double ey = ex.point.dy;

    if (targets.length == 1) {
      final t = targets.first;
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: fromId,
        fromPortId: fromPort,
        toNodeId: t.node.id,
        toPortId: t.port,
        waypoints: cleanWaypoints(
          start,
          _hDedupe(
              start,
              [...ex.stem, Offset(trunkX, ey), Offset(trunkX, t.inPt.dy)],
              t.inPt),
          t.inPt,
        ),
        flowActive: true,
      ));
      return;
    }

    final rootPt = Offset(trunkX, ey);
    final String rootId;
    if (ex.stem.isEmpty && (start - rootPt).distance < 0.5) {
      // the source point already is the trunk start (e.g. a bus junction)
      rootId = fromId;
    } else {
      final root = newJunction(rootPt);
      rootId = root.id;
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: fromId,
        fromPortId: fromPort,
        toNodeId: root.id,
        waypoints: cleanWaypoints(start, _hDedupe(start, ex.stem, rootPt), rootPt),
        flowActive: true,
      ));
    }

    final sorted = [...targets]..sort((a, b) => a.inPt.dy.compareTo(b.inPt.dy));
    final up = sorted.where((t) => t.inPt.dy < ey - 0.5).toList().reversed.toList();
    final down = sorted.where((t) => t.inPt.dy >= ey - 0.5).toList();

    void chain(List<_HFeed> group) {
      String prevId = rootId;
      Offset prevPt = rootPt;
      for (int i = 0; i < group.length; i++) {
        final t = group[i];
        final p = Offset(trunkX, t.inPt.dy);
        if ((t.inPt.dy - ey).abs() < 0.5) {
          // already level with the trunk start: straight run from the root
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: rootId,
            toNodeId: t.node.id,
            toPortId: t.port,
            waypoints: cleanWaypoints(rootPt, [], t.inPt),
            flowActive: true,
          ));
          continue;
        }
        if (i == group.length - 1) {
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: prevId,
            toNodeId: t.node.id,
            toPortId: t.port,
            waypoints: cleanWaypoints(prevPt, _hDedupe(prevPt, [p], t.inPt), t.inPt),
            flowActive: true,
          ));
        } else {
          final j = newJunction(p);
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: prevId,
            toNodeId: j.id,
            waypoints: cleanWaypoints(prevPt, [], p),
            flowActive: true,
          ));
          pipes.add(PipeConnection(
            id: nextId('pipe'),
            fromNodeId: j.id,
            toNodeId: t.node.id,
            toPortId: t.port,
            waypoints: cleanWaypoints(p, [], t.inPt),
            flowActive: true,
          ));
          prevId = j.id;
          prevPt = p;
        }
      }
    }

    chain(up);
    chain(down);
  }

  /// Horizontal bus above a row of tanks: tee at each tank, then a short drop
  /// into its inlet. The bus never touches a tank body.
  void _hBus(NodeObject startJn, Offset startPt, List<_HUnit> units) {
    String prevId = startJn.id;
    Offset prevPt = startPt;
    final double busY = startPt.dy;
    for (int i = 0; i < units.length; i++) {
      final f = units[i].feed;
      final double x = f.inPt.dx - 16.0;
      final p = Offset(x, busY);
      if (i == units.length - 1) {
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: prevId,
          toNodeId: f.node.id,
          toPortId: f.port,
          waypoints: cleanWaypoints(prevPt, [p, Offset(x, f.inPt.dy)], f.inPt),
          flowActive: true,
        ));
      } else {
        final j = newJunction(p);
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: prevId,
          toNodeId: j.id,
          waypoints: cleanWaypoints(prevPt, [], p),
          flowActive: true,
        ));
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: j.id,
          toNodeId: f.node.id,
          toPortId: f.port,
          waypoints: cleanWaypoints(p, [Offset(x, f.inPt.dy)], f.inPt),
          flowActive: true,
        ));
        prevId = j.id;
        prevPt = p;
      }
    }
  }

  NodeType _getNodeTypeForSource(int sourceType) {
    switch (sourceType) {
      case 1:
        return NodeType.overheadTank;
      case 2:
        return NodeType.sump;
      case 3:
        return NodeType.well;
      case 4:
      case 5:
        return NodeType.naturalSource;
      case 6:
        return NodeType.mainFertilizerSource;
      case 7:
        return NodeType.fertilizerTank;
      default:
        return NodeType.sump;
    }
  }

  // ---------------------------------------------------------------------
  // Clean pipe routing (vertical / layered layout)
  // ---------------------------------------------------------------------

  /// A port that is only a few px off its partner (e.g. valve outlet vs tank
  /// inlet) would otherwise get a tiny 2px jog. Nudge the target node so the
  /// run is perfectly straight, unless that would un-straighten one of the
  /// node's other pipes.
  void _snapNearStraightEdges(List<_LayoutEdge> edges) {
    const double tol = 8.0;
    final moved = <String>{};

    double dyOf(_LayoutEdge e) =>
        portPosition(e.from, e.fromPort, isInput: false).dy -
            portPosition(e.to, e.toPort, isInput: true).dy;

    for (final e in edges) {
      if (_isTankNode(e.from)) continue; // tank outlets use a drop stem
      if (moved.contains(e.to.id) || moved.contains(e.from.id)) continue;
      final dy = dyOf(e);
      if (dy.abs() < 0.5 || dy.abs() > tol) continue;

      final alreadyStraight = edges.any((o) =>
      !identical(o, e) &&
          (o.to.id == e.to.id || o.from.id == e.to.id) &&
          dyOf(o).abs() < 0.5);
      if (alreadyStraight) continue;

      e.to.position = e.to.position + Offset(0, dy);
      moved.add(e.to.id);
    }
  }

  bool _isTankNode(NodeObject n) =>
      n.type == NodeType.overheadTank || n.type == NodeType.fertilizerTank;

  void _buildCleanPipes(
      List<_LayoutEdge> edges,
      Map<String, int> layerOf,
      List<double> colX,
      List<double> colW,
      ) {
    const double laneMargin = 24.0;
    const double maxLaneStep = 30.0;

    // ---- describe every edge
    final routes = <_Route>[];
    for (final e in edges) {
      final r = _Route(e);
      r.start = portPosition(e.from, e.fromPort, isInput: false);
      r.end = portPosition(e.to, e.toPort, isInput: true);
      r.startPos = r.start;
      r.endPos = r.end;
      r.y1 = r.start.dy;
      if (_isTankNode(e.from)) {
        // tank outlet: pipe first drops below the tank, then runs sideways
        r.y1 = math.max(r.start.dy + 30.0, e.from.position.dy + e.from.size.height + 20.0);
        r.stem = [Offset(r.start.dx, r.y1)];
      }
      r.y2 = r.end.dy;
      r.fromId = e.from.id;
      r.fromPort = e.fromPort;
      r.toId = e.to.id;
      r.toPort = e.toPort;
      final fl = layerOf[e.from.id]!, tl = layerOf[e.to.id]!;
      r.forward = tl > fl;
      r.gap = tl - 1;
      r.straight = r.forward && r.stem.isEmpty && (r.y1 - r.y2).abs() < 2.0;
      routes.add(r);
    }

    // ---- 1. lanes per gap, ordered to minimise crossings
    bool inside(double v, double p, double q) =>
        v > math.min(p, q) + 0.5 && v < math.max(p, q) - 0.5;
    // crossings if [a] is drawn LEFT of [b]
    int crossLeft(_Route a, _Route b) =>
        (inside(b.y1, a.y1, a.y2) ? 1 : 0) + (inside(a.y2, b.y1, b.y2) ? 1 : 0);

    final byGap = <int, List<_Route>>{};
    for (final r in routes.where((r) => r.forward && !r.straight)) {
      byGap.putIfAbsent(r.gap, () => []).add(r);
    }
    byGap.forEach((g, list) {
      list.sort((a, b) {
        final c = a.y1.compareTo(b.y1);
        return c != 0 ? c : a.y2.compareTo(b.y2);
      });
      final order = <_Route>[];
      for (final r in list) {
        int bestPos = order.length, best = 1 << 30;
        for (int pos = 0; pos <= order.length; pos++) {
          int c = 0;
          for (int i = 0; i < pos; i++) {
            c += crossLeft(order[i], r);
          }
          for (int i = pos; i < order.length; i++) {
            c += crossLeft(r, order[i]);
          }
          if (c < best) {
            best = c;
            bestPos = pos;
          }
        }
        order.insert(bestPos, r);
      }
      final double left = colX[g] + colW[g];
      final double right = colX[g + 1];
      final int n = order.length;
      final double step =
      n > 1 ? math.min(maxLaneStep, (right - left - 2 * laneMargin) / (n - 1)) : 0.0;
      final double first = (left + right) / 2 - step * (n - 1) / 2;
      for (int k = 0; k < n; k++) {
        order[k].lane = first + step * k;
      }
    });

    final forwardRoutes = routes.where((r) => r.forward).toList();

    // ---- 2. fan-OUT: one trunk leaves the port, a tee at every branch
    final srcGroups = <String, List<_Route>>{};
    for (final r in forwardRoutes) {
      srcGroups.putIfAbsent('${r.edge.from.id}|${r.edge.fromPort}', () => []).add(r);
    }
    for (final g in srcGroups.values) {
      if (g.length < 2) continue;
      g.sort((a, b) {
        if (a.lane == null && b.lane == null) return 0;
        if (a.lane == null) return 1;
        if (b.lane == null) return -1;
        return a.lane!.compareTo(b.lane!);
      });
      String prevId = g.first.edge.from.id;
      String? prevPort = g.first.edge.fromPort;
      Offset prevPos = g.first.start;
      List<Offset> prevWps = List.of(g.first.stem);
      for (int i = 0; i < g.length - 1; i++) {
        final r = g[i];
        final p = Offset(r.lane ?? (r.start.dx + 20), r.y1);
        final jn = newJunction(p);
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: prevId,
          fromPortId: prevPort,
          toNodeId: jn.id,
          waypoints: cleanWaypoints(prevPos, prevWps, p),
          flowActive: true,
        ));
        r.fromId = jn.id;
        r.fromPort = null;
        r.startPos = p;
        prevId = jn.id;
        prevPort = null;
        prevPos = p;
        prevWps = [];
      }
      final last = g.last;
      last.fromId = prevId;
      last.fromPort = null;
      last.startPos = prevPos;
      for (final r in g) {
        r.stem = []; // the stem belongs to the trunk now
      }
    }

    // ---- 3. fan-IN: branches merge into one trunk that enters the port
    final dstGroups = <String, List<_Route>>{};
    for (final r in forwardRoutes) {
      dstGroups.putIfAbsent('${r.edge.to.id}|${r.edge.toPort}', () => []).add(r);
    }
    for (final g in dstGroups.values) {
      if (g.length < 2) continue;
      g.sort((a, b) {
        if (a.lane == null && b.lane == null) return 0;
        if (a.lane == null) return 1;
        if (b.lane == null) return -1;
        return b.lane!.compareTo(a.lane!); // closest to the port first
      });
      String prevId = g.first.edge.to.id;
      String? prevPort = g.first.edge.toPort;
      Offset prevPos = g.first.end;
      for (int i = 0; i < g.length - 1; i++) {
        final r = g[i];
        final p = Offset(r.lane ?? (r.end.dx - 20), r.y2);
        final jn = newJunction(p);
        pipes.add(PipeConnection(
          id: nextId('pipe'),
          fromNodeId: jn.id,
          toNodeId: prevId,
          toPortId: prevPort,
          waypoints: cleanWaypoints(p, [], prevPos),
          flowActive: true,
        ));
        r.toId = jn.id;
        r.toPort = null;
        r.endPos = p;
        prevId = jn.id;
        prevPort = null;
        prevPos = p;
      }
      final last = g.last;
      last.toId = prevId;
      last.toPort = null;
      last.endPos = prevPos;
    }

    // ---- 4. the actual branch pipes
    for (final r in forwardRoutes) {
      final wps = <Offset>[
        ...r.stem,
        if (r.lane != null) Offset(r.lane!, r.y1),
        if (r.lane != null) Offset(r.lane!, r.y2),
      ];
      pipes.add(PipeConnection(
        id: nextId('pipe'),
        fromNodeId: r.fromId,
        fromPortId: r.fromPort,
        toNodeId: r.toId,
        toPortId: r.toPort,
        waypoints: cleanWaypoints(r.startPos, wps, r.endPos),
        flowActive: true,
      ));
    }

    // ---- 5. feedback / same-column edges: old simple routing
    final outCount = <String, int>{};
    for (final r in routes.where((r) => !r.forward)) {
      final idx = outCount[r.edge.from.id] ?? 0;
      outCount[r.edge.from.id] = idx + 1;
      pipes.add(_createOrthogonalPipe(
        fromNode: r.edge.from,
        toNode: r.edge.to,
        fromPortId: r.edge.fromPort,
        toPortId: r.edge.toPort,
        indexOffset: idx,
      ));
    }
  }

  PipeConnection _createOrthogonalPipe({
    required NodeObject fromNode,
    required NodeObject toNode,
    String? fromPortId,
    String? toPortId,
    int indexOffset = 0,
    double? laneX, // dedicated vertical lane chosen by the layout
  }) {
    final String pipeId = nextId('pipe');
    final Offset start = portPosition(fromNode, fromPortId, isInput: false);
    final Offset end = portPosition(toNode, toPortId, isInput: true);
    final List<Offset> waypoints = [];
    final double dy = end.dy - start.dy;
    final double midX = laneX ?? (start.dx + end.dx) / 2.0;

    if (fromNode.type == NodeType.overheadTank || fromNode.type == NodeType.fertilizerTank) {
      final double dropY =
          math.max(start.dy + 30.0, fromNode.position.dy + fromNode.size.height + 20.0) +
              indexOffset * 10.0;
      waypoints.add(Offset(start.dx, dropY));
      waypoints.add(Offset(midX, dropY));
      waypoints.add(Offset(midX, end.dy));
    } else if (fromNode.type == NodeType.sump ||
        fromNode.type == NodeType.well ||
        fromNode.type == NodeType.naturalSource ||
        toNode.type == NodeType.overheadTank ||
        toNode.type == NodeType.fertilizerTank) {
      waypoints.add(Offset(midX, start.dy));
      waypoints.add(Offset(midX, end.dy));
    } else if (dy.abs() > 8) {
      waypoints.add(Offset(midX, start.dy));
      waypoints.add(Offset(midX, end.dy));
    }

    return PipeConnection(
      id: pipeId,
      fromNodeId: fromNode.id,
      toNodeId: toNode.id,
      fromPortId: fromPortId,
      toPortId: toPortId,
      waypoints: waypoints,
      flowActive: true,
    );
  }
}