import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../model/node_type_model.dart';
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

/// WATER SOURCE SETUP
/// Sources (sump / well / tank / natural source), water pumps, tank valves and
/// the pipes between them, laid out in clean layers (top section of the canvas).
class WaterSourceSetup extends SiteSetupBase {
  WaterSourceSetup(super.ctx);

  WaterSetupResult build() {
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
  // Clean pipe routing
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
      final double dropY = math.max(start.dy + 30.0, fromNode.position.dy + fromNode.size.height + 20.0) +
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