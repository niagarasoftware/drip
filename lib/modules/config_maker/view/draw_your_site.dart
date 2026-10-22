import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../utils/constants.dart';
import '../model/channel_config_model.dart';
import '../model/device_object_model.dart';
import '../model/node_type_model.dart';
import '../model/pump_model.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/node_widget.dart';
import '../widget/painter/pipe_painter.dart';

const double kCanvasWidth = 3000;
const double kCanvasHeight = 2000;
const double kPipeHitTolerance = 14;

class CanvasNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class DrawYourSiteScreen extends StatefulWidget {
  const DrawYourSiteScreen({super.key});

  @override
  State<DrawYourSiteScreen> createState() => _DrawYourSiteScreenState();
}

class _DrawYourSiteScreenState extends State<DrawYourSiteScreen> with TickerProviderStateMixin {
  final List<NodeObject> _nodes = [];
  final List<PipeConnection> _pipes = [];
  String _activeTabId = 'all';

  // ---- Render / performance infrastructure ------------------------------
  // _canvasNotifier : STRUCTURE changes (add/delete node, new pipe, select...)
  // _dragNotifier   : PER-FRAME changes while dragging (pipes repaint + handles move)
  // _nodeTicks      : one tiny notifier per node so only the moved node rebuilds
  // _tc             : camera matrix (pan / zoom) handled by InteractiveViewer
  final CanvasNotifier _canvasNotifier = CanvasNotifier();
  final CanvasNotifier _dragNotifier = CanvasNotifier();
  final Map<String, ValueNotifier<int>> _nodeTicks = {};
  final TransformationController _tc = TransformationController();
  final FocusNode _focus = FocusNode();

  // true while the user is dragging: pipes are painted without blur / ribs
  final ValueNotifier<bool> _simplifyPaint = ValueNotifier<bool>(false);
  Timer? _simplifyTimer;

  // ---- viewport culling -------------------------------------------------
  // Only nodes / pipes that touch (viewport + margin) are built and painted.
  // The built area is rebuilt (debounced) only when the camera leaves it.
  final GlobalKey _viewKey = GlobalKey();
  Rect? _builtRect;
  Timer? _cullTimer;

  Rect? _sceneViewport() {
    final ctx = _viewKey.currentContext;
    final ro = ctx?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return null;
    final Matrix4 inv = Matrix4.inverted(_tc.value);
    return MatrixUtils.transformRect(inv, Offset.zero & ro.size);
  }

  void _onCameraChanged() {
    final vis = _sceneViewport();
    if (vis == null) return;
    final b = _builtRect;
    final bool covered = b != null &&
        b.left <= vis.left &&
        b.top <= vis.top &&
        b.right >= vis.right &&
        b.bottom >= vis.bottom;
    if (covered) return;
    _cullTimer?.cancel();
    _cullTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      final v = _sceneViewport();
      if (v == null) return;
      _builtRect = v.inflate(700);
      _canvasNotifier.notify();
    });
  }

  bool _isBuilt(NodeObject n) {
    final b = _builtRect;
    if (b == null) return true;
    if (n.id == _selectedNodeId || n.id == _connectFromId) return true;
    return b.inflate(60).overlaps(n.position & n.size);
  }

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onCameraChanged);
  }

  void _markInteracting() {
    if (!_simplifyPaint.value) _simplifyPaint.value = true;
    _simplifyTimer?.cancel();
    _simplifyTimer = Timer(const Duration(milliseconds: 180), () {
      _simplifyPaint.value = false;
    });
  }

  ValueNotifier<int> _nodeTick(String id) =>
      _nodeTicks.putIfAbsent(id, () => ValueNotifier<int>(0));

  // _posTicks: position-only changes (a drag). They move the node's Positioned
  // but never rebuild / repaint the node artwork itself.
  final Map<String, ValueNotifier<int>> _posTicks = {};
  ValueNotifier<int> _posTick(String id) =>
      _posTicks.putIfAbsent(id, () => ValueNotifier<int>(0));

  Widget _buildNodeHost(NodeObject node) {
    final Widget content = ListenableBuilder(
      listenable: _nodeTick(node.id),
      builder: (context, _) => NodeWidget(
        key: ValueKey(node.id),
        node: node,
        applyPosition: false,
        isSelected: node.id == _selectedNodeId,
        isConnectSource: node.id == _connectFromId,
        simplify: _simplifyPaint,
        onChannelToggle: (i) {
          node.toggleChannel(i);
          _nodeTick(node.id).value++;
          _dragNotifier.notify();
          _canvasNotifier.notify();
        },
        onTap: () => _onNodeTap(node),
        onLongPress: () => _onNodeLongPress(node),
        onPanStart: (d) => _onNodePanStart(node),
        onPanUpdate: (d) => _onNodePanUpdate(node, d),
        onResizeStart: (d) => _saveToHistory(),
        onResizeUpdate: (d) => _onNodeResizeUpdate(node, d),
      ),
    );
    return ListenableBuilder(
      key: ValueKey('host_${node.id}'),
      listenable: _posTick(node.id),
      child: content, // same instance every frame -> not rebuilt on a move
      builder: (context, child) => Positioned(
        left: node.position.dx,
        top: node.position.dy,
        child: child!,
      ),
    );
  }

  double get _scale => _tc.value.getMaxScaleOnAxis();

  String? _selectedNodeId;
  String? _selectedPipeId;
  bool _connectMode = false;
  String? _connectFromId;
  String? _connectFromPortId;
  Offset? _pendingDragConnectionPos;
  bool _pendingDragIsInput = false;
  int _idCounter = 0;
  bool _globalHideJoints = false;

  bool _isShiftPressed = false;
  bool _initialAutoGenerated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialAutoGenerated) {
      _initialAutoGenerated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_nodes.isEmpty && mounted) {
          final configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
          if (configPvd.source.isNotEmpty ||
              configPvd.pump.isNotEmpty ||
              configPvd.fertilization.isNotEmpty ||
              configPvd.filtration.isNotEmpty ||
              configPvd.channelConfig.isNotEmpty) {
            _generateFromSourceConfig(showSnackBar: false);
          }
        }
      });
    }
  }

  DeviceObjectModel _getObjectName(double sNo, ConfigMakerProvider configPvd) {
    return configPvd.listOfGeneratedObject.firstWhere(
          (object) => object.sNo == sNo,
      orElse: () => DeviceObjectModel(
        objectId: 0,
        sNo: sNo,
        name: '-',
        objectName: '',
        type: '',
        assignObject: [],
      ),
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
  // Auto arrange (layered, compact, non-overlapping)
  // ---------------------------------------------------------------------
  void _generateFromSourceConfig({bool showSnackBar = true}) {
    final configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
    final sources = configPvd.source;
    final pumps = configPvd.pump;
    final fertSites = configPvd.fertilization;
    final channelConfigs = configPvd.channelConfig;
    final filtrations = configPvd.filtration;

    if (sources.isEmpty && pumps.isEmpty && fertSites.isEmpty && channelConfigs.isEmpty && filtrations.isEmpty) {
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No configuration found for sources, pumps, or fertilization.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    _saveToHistory();
    _nodes.clear();
    _pipes.clear();
    _idCounter = 0;

    // Separate water configuration and fertilization configuration
    final waterSources = sources.where((s) => s.sourceType >= 1 && s.sourceType <= 5).toList();
    final mainFertSources = sources.where((s) => s.sourceType == 6).toList();
    final fertTanks = sources.where((s) => s.sourceType == 7).toList();

    // Where (left -> right) on the injector skid does a tank valve end up?
    // Used to order the tanks / valve outlets so the pipes never cross.
    double? valveChannelPos(double vSNo) {
      double sum = 0;
      int n = 0;
      for (int s = 0; s < fertSites.length; s++) {
        final site = fertSites[s];
        for (int c = 0; c < site.channel.length; c++) {
          final inj = site.channel[c];
          for (final ch in channelConfigs) {
            if (ch.commonDetails.sNo == inj.sNo && ch.outletTankValve.contains(vSNo)) {
              sum += s * 10.0 + c;
              n++;
            }
          }
        }
      }
      return n == 0 ? null : sum / n;
    }

    final origTankOrder = List.of(fertTanks);
    double tankKey(dynamic src) {
      double sum = 0;
      int n = 0;
      for (final double v in src.outletTankValve) {
        final p = valveChannelPos(v);
        if (p != null) {
          sum += p;
          n++;
        }
      }
      return n == 0 ? 1000.0 + origTankOrder.indexOf(src) : sum / n;
    }

    fertTanks.sort((a, b) {
      final c = tankKey(a).compareTo(tankKey(b));
      return c != 0 ? c : origTankOrder.indexOf(a).compareTo(origTankOrder.indexOf(b));
    });

    // Collect sNos of pumps used by fertilizer sources/sites
    final fertPumpSNos = <double>{};
    for (final mfs in mainFertSources) {
      fertPumpSNos.addAll(mfs.inletPump);
      fertPumpSNos.addAll(mfs.outletPump);
    }
    for (final ft in fertTanks) {
      fertPumpSNos.addAll(ft.inletPump);
      fertPumpSNos.addAll(ft.outletPump);
    }
    for (final fs in fertSites) {
      fertPumpSNos.addAll(fs.boosterPump);
    }

    final waterPumps = pumps.where((p) => !fertPumpSNos.contains(p.commonDetails.sNo)).toList();
    final fertPumps = pumps.where((p) => fertPumpSNos.contains(p.commonDetails.sNo)).toList();

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
            : _defaultLabelFor(type);
        final node = NodeObject(
          id: _nextId('source_${sNo.toInt()}'),
          position: Offset.zero,
          type: type,
          size: const Size(68, 47),
          label: label,
          showJoints: !_globalHideJoints,
        );
        node.size = node.defaultSize;
        _nodes.add(node);
        sourceMap[sNo] = node;
      }

      for (final p in waterPumps) {
        final double sNo = p.commonDetails.sNo ?? 0.0;
        final String label = (p.commonDetails.name?.isNotEmpty == true)
            ? p.commonDetails.name!
            : 'Pump ${sNo.toInt()}';
        final node = NodeObject(
          id: _nextId('pump_${sNo.toInt()}'),
          position: Offset.zero,
          type: NodeType.pump,
          label: label,
          isOn: true,
          showJoints: !_globalHideJoints,
        );
        node.size = node.defaultSize;
        _nodes.add(node);
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
              id: _nextId('inlet_valve_${vSNo.toString().replaceAll('.', '_')}'),
              position: Offset.zero,
              type: isMulti ? NodeType.multiOutletTankValve : NodeType.singleTankValve,
              label: '${src.commonDetails.name ?? 'Source'} Inlet Valve',
              outletPortCount: src.inletTankValvePortCount,
              isHorizontal: true,
              showJoints: !_globalHideJoints,
            );
            inletValveNode.size = inletValveNode.defaultSize;
            _nodes.add(inletValveNode);
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
              id: _nextId('outlet_valve_${vSNo.toString().replaceAll('.', '_')}'),
              position: Offset.zero,
              type: isMulti ? NodeType.multiOutletTankValve : NodeType.singleTankValve,
              label: '${src.commonDetails.name ?? 'Source'} Outlet Valve',
              outletPortCount: src.outletTankValvePortCount,
              isHorizontal: true,
              showJoints: !_globalHideJoints,
            );
            outletValveNode.size = outletValveNode.defaultSize;
            _nodes.add(outletValveNode);
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
      final Map<String, int> rawLayer = {for (final n in _nodes) n.id: 0};
      for (int it = 0; it < _nodes.length; it++) {
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
        for (final n in _nodes) n.id: usedLayers.indexOf(rawLayer[n.id]!),
      };
      final int L = usedLayers.length;
      final List<List<NodeObject>> layers = List.generate(L, (_) => <NodeObject>[]);
      for (final n in _nodes) {
        layers[layerOf[n.id]!].add(n);
      }

      final Map<String, List<NodeObject>> neighbours = {
        for (final n in _nodes) n.id: <NodeObject>[],
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

    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    // FILTRATION FORMATION (Multi-Filter Station)
    // -------------------------------------------------------------------------
    double maxWaterX = 0.0;
    double maxWaterY = 0.0;
    for (final n in _nodes) {
      if (n.position.dx + n.size.width > maxWaterX) {
        maxWaterX = n.position.dx + n.size.width;
      }
      if (n.position.dy + n.size.height > maxWaterY) {
        maxWaterY = n.position.dy + n.size.height;
      }
    }

    final List<_SupplyNodeRef> waterSupplyNodes = [];

    // First preference: pumps explicitly configured with pumpType == 2 (Irrigation Pump) in PumpConfiguration
    for (final p in waterPumps) {
      if (p.pumpType == 2) {
        final node = pumpMap[p.commonDetails.sNo ?? 0.0];
        if (node != null) waterSupplyNodes.add(_SupplyNodeRef(node, 'output'));
      }
    }

    // Fallback: if no pump has pumpType == 2, use terminal water pumps (no outgoing edge in edges)
    if (waterSupplyNodes.isEmpty) {
      final outgoingFromIds = edges.map((e) => e.from.id).toSet();
      for (final p in waterPumps) {
        final node = pumpMap[p.commonDetails.sNo ?? 0.0];
        if (node != null && !outgoingFromIds.contains(node.id)) {
          waterSupplyNodes.add(_SupplyNodeRef(node, 'output'));
        }
      }
    }

    if (waterSupplyNodes.isEmpty && waterPumps.isNotEmpty) {
      final lastNode = pumpMap[waterPumps.last.commonDetails.sNo ?? 0.0];
      if (lastNode != null) waterSupplyNodes.add(_SupplyNodeRef(lastNode, 'output'));
    }

    // Fallback if no water pumps exist: use terminal water sources or outlet tank valves
    if (waterSupplyNodes.isEmpty && waterSources.isNotEmpty) {
      final outgoingFromIds = edges.map((e) => e.from.id).toSet();
      for (final n in _nodes) {
        if (!outgoingFromIds.contains(n.id)) {
          if (n.type == NodeType.singleTankValve || n.type == NodeType.multiOutletTankValve) {
            final port = n.type == NodeType.multiOutletTankValve ? 'channel_0' : 'outlet';
            waterSupplyNodes.add(_SupplyNodeRef(n, port));
          } else if (n.type == NodeType.overheadTank ||
              n.type == NodeType.sump ||
              n.type == NodeType.well ||
              n.type == NodeType.naturalSource) {
            waterSupplyNodes.add(_SupplyNodeRef(n, 'outlet'));
          }
        }
      }
    }

    final bool hasFertData = mainFertSources.isNotEmpty ||
        fertTanks.isNotEmpty ||
        fertSites.isNotEmpty ||
        channelConfigs.isNotEmpty ||
        fertPumps.isNotEmpty;

    final List<NodeObject> filterNodes = [];
    if (filtrations.isNotEmpty) {
      for (int f = 0; f < filtrations.length; f++) {
        final fSite = filtrations[f];
        final double sNo = fSite.commonDetails.sNo ?? 0.0;
        final String label = (fSite.commonDetails.name?.isNotEmpty == true)
            ? fSite.commonDetails.name!
            : 'Multi-Filter Station';
        final filterNode = NodeObject(
          id: _nextId('multi_filter_${sNo.toInt()}'),
          position: Offset.zero,
          type: NodeType.multiFilter,
          label: label,
          showJoints: !_globalHideJoints,
        );
        filterNode.size = filterNode.defaultSize;
        _nodes.add(filterNode);
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
        _pipes.add(PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: f1.id,
          fromPortId: 'outlet',
          toNodeId: f2.id,
          toPortId: 'inlet',
          waypoints: [],
        ));
      }
    }

    NodeObject? findBlockingNode(Offset startPt, double targetX) {
      final lRect = Rect.fromLTRB(
        math.min(startPt.dx, targetX) + 10.0,
        startPt.dy - 12.0,
        math.max(startPt.dx, targetX) - 5.0,
        startPt.dy + 12.0,
      );
      for (final n in _nodes) {
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
      required List<_SupplyNodeRef> supplyNodes,
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

        _pipes.add(PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: term.id,
          fromPortId: outPort,
          toNodeId: targetNodeId,
          toPortId: targetPortId,
          waypoints: _cleanWaypoints(termPt, wps, targetPt),
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

          final jn = _newJunction(jnPt);

          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: term.id,
            fromPortId: outPort,
            toNodeId: jn.id,
            waypoints: _cleanWaypoints(termPt, wpsToJn, jnPt),
          ));

          if (prevJnId != null && prevJnPt != null) {
            _pipes.add(PipeConnection(
              id: _nextId('pipe'),
              fromNodeId: prevJnId,
              toNodeId: jn.id,
              waypoints: _cleanWaypoints(prevJnPt, [], jnPt),
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
          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: prevJnId,
            toNodeId: targetNodeId,
            toPortId: targetPortId,
            waypoints: _cleanWaypoints(prevJnPt, wps, targetPt),
          ));
        }
      }
    }

    // -------------------------------------------------------------------------
    // FERTILIZATION FORMATION (Placed to the RIGHT side of Water & Pump setup)
    // -------------------------------------------------------------------------
    final List<NodeObject> skidNodes = [];

    if (hasFertData) {
      final double maxWaterX = _nodes.isNotEmpty
          ? _nodes.map((n) => n.position.dx + n.size.width).reduce(math.max)
          : 0.0;
      final double fertStartX = _nodes.isNotEmpty ? math.max(500.0, maxWaterX + 100.0) : 40.0;
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
          id: _nextId('main_fert_${sNo.toInt()}'),
          position: Offset(mfsX, row1Y + 20.0),
          type: NodeType.mainFertilizerSource,
          size: const Size(148, 104),
          label: label,
          showJoints: !_globalHideJoints,
        );
        mfsNode.size = mfsNode.defaultSize;
        _nodes.add(mfsNode);
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
            id: _nextId('fert_pump_${pNo.toInt()}'),
            position: Offset(mfsX + 148.0 + 30.0, row1Y + 35.0),
            type: NodeType.pump,
            size: const Size(68, 47),
            label: pumpLabel,
            isOn: true,
            showJoints: !_globalHideJoints,
          );
          pumpNode.size = pumpNode.defaultSize;
          // Line the pump inlet up with the source outlet so the
          // source -> pump pipe is one short straight run.
          final Offset mfsOutPt = portPosition(mfsNode, 'outlet', isInput: false);
          final Offset pumpInPt = portPosition(pumpNode, 'input', isInput: true);
          pumpNode.position = pumpNode.position + Offset(0, mfsOutPt.dy - pumpInPt.dy);
          _nodes.add(pumpNode);
          fertPumpNodeMap[pNo] = pumpNode;

          // Connect Main Fert Source -> Pump
          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
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
          final deviceObj = _getObjectName(agSNo, configPvd);
          final String label = (deviceObj.name?.isNotEmpty == true && deviceObj.name != '-')
              ? deviceObj.name!
              : 'Air Blower ${a + 1}';

          final double blowerX = startBlowerX + a * 130.0;
          final blowerNode = NodeObject(
            id: _nextId('blower_${agSNo.toInt()}'),
            position: Offset(blowerX, row1Y),
            type: NodeType.blower,
            size: const Size(60, 56),
            label: label,
            showJoints: !_globalHideJoints,
          );
          blowerNode.size = blowerNode.defaultSize;
          _nodes.add(blowerNode);
          agitatorNodeMap[agSNo] = blowerNode;
        }
      } else if (fertTanks.isNotEmpty) {
        final double blowerX = tankStartX + totalTanksSpan + 35.0;
        final blowerNode = NodeObject(
          id: _nextId('blower_default'),
          position: Offset(blowerX, row1Y),
          type: NodeType.blower,
          size: const Size(60, 56),
          label: 'Air Blower',
          showJoints: !_globalHideJoints,
        );
        blowerNode.size = blowerNode.defaultSize;
        _nodes.add(blowerNode);
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
          id: _nextId('fert_tank_${sNo.toInt()}'),
          position: Offset(tankStartX + tankOffsetsX[t], tanksY),
          type: NodeType.fertilizerTank,
          size: const Size(70, 88),
          label: label,
          showJoints: !_globalHideJoints,
        );
        tankNode.size = tankNode.defaultSize;
        _nodes.add(tankNode);
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
            _pipes.add(PipeConnection(
              id: _nextId('pipe'),
              fromNodeId: prevId,
              fromPortId: prevPort,
              toNodeId: tankNode.id,
              toPortId: 'inlet',
              waypoints: _cleanWaypoints(prevPos, [...prevWps, dropPt], inletPt),
            ));
          } else {
            final jn = _newJunction(dropPt);
            _pipes.add(PipeConnection(
              id: _nextId('pipe'),
              fromNodeId: prevId,
              fromPortId: prevPort,
              toNodeId: jn.id,
              waypoints: _cleanWaypoints(prevPos, prevWps, dropPt),
            ));
            _pipes.add(PipeConnection(
              id: _nextId('pipe'),
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

            _pipes.add(PipeConnection(
              id: _nextId('pipe'),
              fromNodeId: blowerNode.id,
              toNodeId: tankNode.id,
              fromPortId: 'outlet',
              toPortId: 'top_inlet',
              waypoints: _cleanWaypoints(
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
            id: _nextId('fert_valve_${sNo.toInt()}'),
            position: const Offset(0, valvesY),
            type: valveType,
            label: valveLabel,
            outletPortCount: portCount,
            isHorizontal: false, // outlets face downwards
            showJoints: !_globalHideJoints,
          );
          valveNode.size = valveNode.defaultSize;

          // Centre the valve inlet exactly under the tank outlet so the
          // tank -> valve pipe is a perfectly straight vertical run.
          final Offset tankOut = tankNode.getPort('outlet', isInput: false);
          final double inletOffset = valveNode.inputPort.dx - valveNode.position.dx;
          valveNode.position = Offset(tankOut.dx - inletOffset, valvesY);
          _nodes.add(valveNode);

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

            final deviceObj = _getObjectName(vSNo, configPvd);
            final String name = (deviceObj.name?.isNotEmpty == true && deviceObj.name != '-')
                ? deviceObj.name!
                : 'Tank Valve ${rank + 1}';
            portLabels.add(name);
          }
          valveNode.portLabels = portLabels;

          // Pipe: Tank outlet -> Valve inlet (straight down)
          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
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
            id: _nextId('skid_${site.commonDetails.sNo?.toInt() ?? s}'),
            position: Offset(skidX, provisionalSkidY),
            type: NodeType.multiInjector,
            size: const Size(308, 132),
            label: label,
            showJoints: !_globalHideJoints,
          );
          skidNode.size = skidNode.defaultSize;
          _nodes.add(skidNode);
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
          id: _nextId('skid_0'),
          position: Offset(skidX, provisionalSkidY),
          type: NodeType.multiInjector,
          size: const Size(308, 132),
          label: 'Multi-Injector Skid',
          showJoints: !_globalHideJoints,
        );
        skidNode.size = skidNode.defaultSize;
        _nodes.add(skidNode);
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
          final NodeObject jnSkidIn = _newJunction(skidInJunctionPt);

          final List<Offset> filterToSkidWps = [
            Offset(filterOutPt.dx + 30.0, filterOutPt.dy),
            Offset(filterOutPt.dx + 30.0, mainPipeY),
          ];
          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: lastFilterNode.id,
            fromPortId: 'outlet',
            toNodeId: jnSkidIn.id,
            waypoints: _cleanWaypoints(filterOutPt, filterToSkidWps, skidInJunctionPt),
          ));

          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: jnSkidIn.id,
            toNodeId: skidNode.id,
            toPortId: 'inlet',
            waypoints: _cleanWaypoints(skidInJunctionPt, [Offset(skidLeftX, skidInletPt.dy)], skidInletPt),
          ));

          final double skidRightX = skidNode.position.dx + skidNode.size.width + 30.0;
          final Offset skidOutJunctionPt = Offset(skidRightX, mainPipeY);
          final NodeObject jnSkidOut = _newJunction(skidOutJunctionPt);

          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: skidNode.id,
            fromPortId: 'outlet',
            toNodeId: jnSkidOut.id,
            waypoints: _cleanWaypoints(skidOutletPt, [Offset(skidRightX, skidOutletPt.dy)], skidOutJunctionPt),
          ));

          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: jnSkidIn.id,
            toNodeId: jnSkidOut.id,
            waypoints: _cleanWaypoints(skidInJunctionPt, [], skidOutJunctionPt),
          ));

          _connectIrrigationLineNodes(
            startJunction: jnSkidOut,
            startPt: skidOutJunctionPt,
            mainPipeY: mainPipeY,
            skidRightX: skidRightX,
            configPvd: configPvd,
          );
        }
      } else {
        final Offset endPt = Offset(filterOutPt.dx + 60.0, filterOutPt.dy);
        final NodeObject jnEnd = _newJunction(endPt);
        _pipes.add(PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: lastFilterNode.id,
          fromPortId: 'outlet',
          toNodeId: jnEnd.id,
          waypoints: [],
        ));

        _connectIrrigationLineNodes(
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
          final NodeObject jnSkidIn = _newJunction(skidInJunctionPt);

          connectWaterSupplyTo(
            supplyNodes: waterSupplyNodes,
            targetNodeId: jnSkidIn.id,
            targetPortId: null,
            targetPt: skidInJunctionPt,
            maxWaterX: maxWaterX,
          );

          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: jnSkidIn.id,
            toNodeId: skidNode.id,
            toPortId: 'inlet',
            waypoints: _cleanWaypoints(skidInJunctionPt, [Offset(skidLeftX, skidInletPt.dy)], skidInletPt),
          ));

          final double skidRightX = skidNode.position.dx + skidNode.size.width + 30.0;
          final Offset skidOutJunctionPt = Offset(skidRightX, mainPipeY);
          final NodeObject jnSkidOut = _newJunction(skidOutJunctionPt);

          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: skidNode.id,
            fromPortId: 'outlet',
            toNodeId: jnSkidOut.id,
            waypoints: _cleanWaypoints(skidOutletPt, [Offset(skidRightX, skidOutletPt.dy)], skidOutJunctionPt),
          ));

          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: jnSkidIn.id,
            toNodeId: jnSkidOut.id,
            waypoints: _cleanWaypoints(skidInJunctionPt, [], skidOutJunctionPt),
          ));

          _connectIrrigationLineNodes(
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
        final NodeObject jnEnd = _newJunction(endPt);

        connectWaterSupplyTo(
          supplyNodes: waterSupplyNodes,
          targetNodeId: jnEnd.id,
          targetPortId: null,
          targetPt: endPt,
          maxWaterX: maxWaterX,
        );

        _connectIrrigationLineNodes(
          startJunction: jnEnd,
          startPt: endPt,
          mainPipeY: endY,
          skidRightX: endX,
          configPvd: configPvd,
        );
      }
    }

    // Every node object is brand new: refresh all per-node notifiers lazily
    // (they are created on demand) and rebuild the structure layer once.
    _builtRect = null; // new layout: build everything, re-cull on next scroll
    setState(() {
      _selectedNodeId = null;
      _selectedPipeId = null;
    });
    _canvasNotifier.notify();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusOnAllNodes();
      }
    });

    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Auto-arranged layout with ${_nodes.length} equipment and ${_pipes.length} connection(s).'),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  void _connectIrrigationLineNodes({
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
    final NodeObject topRiserJn = _newJunction(topRiserPt);
    _pipes.add(PipeConnection(
      id: _nextId('pipe'),
      fromNodeId: startJunction.id,
      toNodeId: topRiserJn.id,
      waypoints: _cleanWaypoints(startPt, [], topRiserPt),
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
          final deviceObj = _getObjectName(vSno, configPvd);
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
        id: _nextId('line_header_$i'),
        position: Offset(headerX, headerY),
        type: NodeType.lineHeader,
        label: lineName,
        showJoints: false,
      );
      lineHeaderNode.size = Size(math.max(120.0, 9.0 * lineName.length + 32.0), 30);
      _nodes.add(lineHeaderNode);

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
          id: _nextId('multi_valve_line_${i}_bank_$b'),
          position: Offset(valveBankX, bankY),
          type: NodeType.multiValve,
          label: '',
          outletPortCount: bankValves,
          showJoints: !_globalHideJoints,
          portLabels: bankValveNames,
        );
        bankNode.size = Size(math.max(120.0, 70.0 * bankValves + 40.0), 190);
        _nodes.add(bankNode);
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
          id: _nextId('multi_fogger_line_$i'),
          position: Offset(valveBankX, foggerSystemY),
          type: NodeType.multiFogger,
          label: '$lineName - Multi-Fogger System',
          outletPortCount: lFoggers,
          showJoints: !_globalHideJoints,
        );
        foggerSystemNode.size = Size(math.max(100.0, 50.0 * lFoggers + 20.0), 112);
        _nodes.add(foggerSystemNode);
      }

      // First inlet port that feeds Line i
      final NodeObject targetFirstNode = lineValveBanks.isNotEmpty
          ? lineValveBanks.first
          : foggerSystemNode!;
      final Offset firstInlet = targetFirstNode.inputPort;
      final double lineDropX = firstInlet.dx - 40.0;

      // Vertical distribution riser junction on right for Line i
      final Offset lineBranchRiserPt = Offset(loopFarX, currentReturnY);
      final NodeObject lineBranchJn = _newJunction(lineBranchRiserPt);

      // Connect right riser: prevRiserJn -> lineBranchJn
      _pipes.add(PipeConnection(
        id: _nextId('pipe'),
        fromNodeId: prevRiserJn.id,
        toNodeId: lineBranchJn.id,
        waypoints: _cleanWaypoints(prevRiserPt, [], lineBranchRiserPt),
      ));

      // Connect horizontal branch pipe from right riser across to left manifold line
      final Offset firstJnPt = Offset(lineDropX, firstInlet.dy);
      final NodeObject jnBank0 = _newJunction(firstJnPt);

      final List<Offset> branchWps = [
        Offset(lineDropX, currentReturnY),
        Offset(lineDropX, firstInlet.dy),
      ];
      _pipes.add(PipeConnection(
        id: _nextId('pipe'),
        fromNodeId: lineBranchJn.id,
        toNodeId: jnBank0.id,
        waypoints: _cleanWaypoints(lineBranchRiserPt, branchWps, firstJnPt),
      ));

      // Connect jnBank0 -> Bank 0 inlet
      _pipes.add(PipeConnection(
        id: _nextId('pipe'),
        fromNodeId: jnBank0.id,
        toNodeId: targetFirstNode.id,
        toPortId: 'inlet',
        waypoints: _cleanWaypoints(firstJnPt, [], firstInlet),
      ));

      NodeObject prevBankJn = jnBank0;
      Offset prevBankJnPt = firstJnPt;

      // Connect subsequent valve bank rows vertically along lineDropX manifold
      for (int b = 1; b < lineValveBanks.length; b++) {
        final bankNode = lineValveBanks[b];
        final Offset bankInlet = bankNode.inputPort;
        final Offset bankJnPt = Offset(lineDropX, bankInlet.dy);
        final NodeObject jnBank = _newJunction(bankJnPt);

        // Vertical drop along manifold
        _pipes.add(PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: prevBankJn.id,
          toNodeId: jnBank.id,
          waypoints: _cleanWaypoints(prevBankJnPt, [], bankJnPt),
        ));

        // Horizontal feed into Bank b inlet
        _pipes.add(PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: jnBank.id,
          toNodeId: bankNode.id,
          toPortId: 'inlet',
          waypoints: _cleanWaypoints(bankJnPt, [], bankInlet),
        ));

        prevBankJn = jnBank;
        prevBankJnPt = bankJnPt;
      }

      // Connect Fogger System if present
      if (lineValveBanks.isNotEmpty && foggerSystemNode != null) {
        final Offset foggerInlet = foggerSystemNode.inputPort;
        final Offset foggerJnPt = Offset(lineDropX, foggerInlet.dy);
        final NodeObject jnFogger = _newJunction(foggerJnPt);

        _pipes.add(PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: prevBankJn.id,
          toNodeId: jnFogger.id,
          waypoints: _cleanWaypoints(prevBankJnPt, [], foggerJnPt),
        ));

        _pipes.add(PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: jnFogger.id,
          toNodeId: foggerSystemNode.id,
          toPortId: 'inlet',
          waypoints: _cleanWaypoints(foggerJnPt, [], foggerInlet),
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

      final jn = _newJunction(jp);
      mergeJunctions[entry.key] = jn;

      _pipes.add(PipeConnection(
        id: _nextId('pipe'),
        fromNodeId: jn.id,
        toNodeId: firstLink.skid.id,
        toPortId: firstLink.skidPort,
        waypoints: _cleanWaypoints(jp, [], channelPt),
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
          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: l.valve.id,
            fromPortId: l.valvePort,
            toNodeId: targetJn.id,
            waypoints: _cleanWaypoints(startPt, [], targetPos),
          ));
        } else {
          final int lIdx = entryLaneMap[entry.key] ?? 0;
          final double lY = lane0 + laneStep * lIdx;
          final List<Offset> wps = [
            Offset(startPt.dx, lY),
            Offset(targetPos.dx, lY),
          ];

          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: l.valve.id,
            fromPortId: l.valvePort,
            toNodeId: targetJn.id,
            waypoints: _cleanWaypoints(startPt, wps, targetPos),
          ));
        }
      } else {
        final int lIdx = entryLaneMap[entry.key] ?? 0;
        final double distLane = lane0 + laneStep * lIdx;

        final Offset trunkEnd = Offset(startPt.dx, distLane);
        final NodeObject jnTrunk = _newJunction(trunkEnd);

        _pipes.add(PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: firstLink.valve.id,
          fromPortId: firstLink.valvePort,
          toNodeId: jnTrunk.id,
          waypoints: _cleanWaypoints(startPt, [], trunkEnd),
        ));

        for (final l in gLinks) {
          final targetKey = '${l.skid.id}|${l.skidPort}';
          final targetJn = mergeJunctions[targetKey]!;
          final Offset targetPos = Offset(targetJn.position.dx + 5, targetJn.position.dy + 5);

          if ((targetPos.dx - startPt.dx).abs() < 1.0) {
            _pipes.add(PipeConnection(
              id: _nextId('pipe'),
              fromNodeId: jnTrunk.id,
              toNodeId: targetJn.id,
              waypoints: _cleanWaypoints(trunkEnd, [], targetPos),
            ));
          } else {
            final Offset teePt = Offset(targetPos.dx, distLane);
            final NodeObject jnTee = _newJunction(teePt);

            _pipes.add(PipeConnection(
              id: _nextId('pipe'),
              fromNodeId: jnTrunk.id,
              toNodeId: jnTee.id,
              waypoints: _cleanWaypoints(trunkEnd, [], teePt),
            ));

            _pipes.add(PipeConnection(
              id: _nextId('pipe'),
              fromNodeId: jnTee.id,
              toNodeId: targetJn.id,
              waypoints: _cleanWaypoints(teePt, [], targetPos),
            ));
          }
        }
      }
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

  NodeObject _newJunction(Offset p) {
    final j = NodeObject(
      id: _nextId('junction'),
      position: p - const Offset(7, 7),
      size: const Size(14, 14),
      type: NodeType.junction,
      label: '',
      showJoints: !_globalHideJoints,
    );
    _nodes.add(j);
    return j;
  }

  /// Removes duplicate and collinear bend points so pipes have only real corners.
  List<Offset> _cleanWaypoints(Offset s, List<Offset> wps, Offset e) {
    bool same(Offset a, Offset b) => (a - b).distance < 0.5;
    final out = <Offset>[s];
    for (final p in [...wps, e]) {
      if (!same(out.last, p)) out.add(p);
    }
    final interior = out.sublist(1);
    if (interior.isNotEmpty && same(interior.last, e)) interior.removeLast();

    final full = <Offset>[s, ...interior, e];
    final res = <Offset>[];
    for (int i = 1; i < full.length - 1; i++) {
      final a = full[i - 1], b = full[i], c = full[i + 1];
      final vertical = (a.dx - b.dx).abs() < 0.5 && (b.dx - c.dx).abs() < 0.5;
      final horizontal = (a.dy - b.dy).abs() < 0.5 && (b.dy - c.dy).abs() < 0.5;
      if (!vertical && !horizontal) res.add(b);
    }
    return res;
  }

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
        final jn = _newJunction(p);
        _pipes.add(PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: prevId,
          fromPortId: prevPort,
          toNodeId: jn.id,
          waypoints: _cleanWaypoints(prevPos, prevWps, p),
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
        final jn = _newJunction(p);
        _pipes.add(PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: jn.id,
          toNodeId: prevId,
          toPortId: prevPort,
          waypoints: _cleanWaypoints(p, [], prevPos),
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
      _pipes.add(PipeConnection(
        id: _nextId('pipe'),
        fromNodeId: r.fromId,
        fromPortId: r.fromPort,
        toNodeId: r.toId,
        toPortId: r.toPort,
        waypoints: _cleanWaypoints(r.startPos, wps, r.endPos),
        flowActive: true,
      ));
    }

    // ---- 5. feedback / same-column edges: old simple routing
    final outCount = <String, int>{};
    for (final r in routes.where((r) => !r.forward)) {
      final idx = outCount[r.edge.from.id] ?? 0;
      outCount[r.edge.from.id] = idx + 1;
      _pipes.add(_createOrthogonalPipe(
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
    final String pipeId = _nextId('pipe');
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

  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];

  Map<String, dynamic> _cloneState() {
    return {
      'nodes': _nodes.map((n) => n.toJson()).toList(),
      'pipes': _pipes.map((p) => p.toJson()).toList(),
      'idCounter': _idCounter,
    };
  }

  void _restoreState(Map<String, dynamic> state) {
    _nodes.clear();
    _pipes.clear();
    for (final n in state['nodes']) {
      _nodes.add(NodeObject.fromJson(n));
    }
    for (final p in state['pipes']) {
      _pipes.add(PipeConnection.fromJson(p));
    }
    _idCounter = state['idCounter'] as int;
    _selectedNodeId = null;
    _selectedPipeId = null;
    _connectFromId = null;
    _builtRect = null;
    _canvasNotifier.notify();
  }

  void _saveToHistory() {
    if (_undoStack.length >= 2) {
      _undoStack.removeAt(0);
    }
    _undoStack.add(_cloneState());
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      final currentState = _cloneState();
      final previousState = _undoStack.removeLast();
      setState(() {
        _restoreState(previousState);
        if (_redoStack.length >= 2) {
          _redoStack.removeAt(0);
        }
        _redoStack.add(currentState);
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      final currentState = _cloneState();
      final nextState = _redoStack.removeLast();
      setState(() {
        _restoreState(nextState);
        if (_undoStack.length >= 2) {
          _undoStack.removeAt(0);
        }
        _undoStack.add(currentState);
      });
    }
  }

  @override
  void dispose() {
    _canvasNotifier.dispose();
    _cullTimer?.cancel();
    _tc.removeListener(_onCameraChanged);
    _simplifyTimer?.cancel();
    _simplifyPaint.dispose();
    _dragNotifier.dispose();
    _tc.dispose();
    _focus.dispose();
    for (final t in _nodeTicks.values) {
      t.dispose();
    }
    for (final t in _posTicks.values) {
      t.dispose();
    }
    super.dispose();
  }

  String _nextId(String prefix) => '${prefix}_${_idCounter++}';

  // ---------------------------------------------------------------------
  // Zoom (camera matrix only - nothing is rebuilt or re-laid-out)
  // ---------------------------------------------------------------------
  /// Mouse wheel / trackpad scroll moves the canvas (Shift + wheel = sideways).
  void _onCanvasPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final Offset d = event.scrollDelta;
    final double dx = _isShiftPressed ? d.dy : d.dx;
    final double dy = _isShiftPressed ? 0.0 : d.dy;
    final Matrix4 m = _tc.value.clone()..leftTranslate(-dx, -dy);
    final double s = m.getMaxScaleOnAxis();
    // keep the canvas from being scrolled completely out of view
    final double tx = m.storage[12].clamp(-(kCanvasWidth * s) + 100.0, 0.0).toDouble();
    final double ty = m.storage[13].clamp(-(kCanvasHeight * s) + 100.0, 0.0).toDouble();
    m.storage[12] = tx;
    m.storage[13] = ty;
    _tc.value = m;
  }

  void _zoomBy(double factor) {
    final double target = (_scale * factor).clamp(0.4, 2.0).toDouble();
    final double k = target / _scale;
    _tc.value = _tc.value.clone()..scale(k, k, 1.0);
  }

  // ---------------------------------------------------------------------
  // Smooth Camera Focus & Google Sheets Tabs Navigation
  // ---------------------------------------------------------------------
  void _focusOnRect(Rect targetRect, {double padding = 140.0}) {
    final Size viewportSize = MediaQuery.of(context).size;
    final double vW = math.max(300.0, viewportSize.width - 60.0);
    final double vH = math.max(300.0, viewportSize.height - 180.0);

    final double rectW = math.max(120.0, targetRect.width + padding * 2.0);
    final double rectH = math.max(120.0, targetRect.height + padding * 2.0);

    final double scaleX = vW / rectW;
    final double scaleY = vH / rectH;
    final double targetScale = math.min(scaleX, scaleY).clamp(0.5, 1.4).toDouble();

    final Offset center = targetRect.center;
    double tx = (vW / 2.0) - (center.dx * targetScale);
    double ty = (vH / 2.0) - (center.dy * targetScale);

    tx = math.min(0.0, tx);
    ty = math.min(0.0, ty);

    final Matrix4 endM = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(targetScale);

    final Matrix4 startM = _tc.value.clone();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    final animation = Matrix4Tween(begin: startM, end: endM).animate(
      CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn),
    );
    animation.addListener(() {
      _tc.value = animation.value;
    });
    controller.forward().then((_) => controller.dispose());
  }

  void _focusOnAllNodes() {
    if (_nodes.isEmpty) return;
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final n in _nodes) {
      if (n.type == NodeType.junction) continue;
      minX = math.min(minX, n.position.dx);
      minY = math.min(minY, n.position.dy);
      maxX = math.max(maxX, n.position.dx + n.size.width);
      maxY = math.max(maxY, n.position.dy + n.size.height);
    }
    if (minX.isFinite) {
      _focusOnRect(Rect.fromLTRB(minX, minY, maxX, maxY));
    }
  }

  void _focusOnWaterSource() {
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final n in _nodes) {
      final bool isWaterSourceNode = n.type == NodeType.overheadTank ||
          n.type == NodeType.sump ||
          n.type == NodeType.well ||
          n.type == NodeType.naturalSource ||
          n.type == NodeType.pump ||
          n.type == NodeType.singleTankValve ||
          n.type == NodeType.multiOutletTankValve;
      if (isWaterSourceNode) {
        minX = math.min(minX, n.position.dx);
        minY = math.min(minY, n.position.dy);
        maxX = math.max(maxX, n.position.dx + n.size.width);
        maxY = math.max(maxY, n.position.dy + n.size.height);
      }
    }

    if (minX.isFinite) {
      _focusOnRect(Rect.fromLTRB(minX, minY, maxX, maxY));
    }
  }

  void _focusOnLine(int lineIdx) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final n in _nodes) {
      final bool matchesLine = n.id.contains('line_header_$lineIdx') ||
          n.id.contains('multi_valve_line_${lineIdx}_') ||
          n.id.contains('multi_fogger_line_$lineIdx');
      if (matchesLine) {
        minX = math.min(minX, n.position.dx);
        minY = math.min(minY, n.position.dy);
        maxX = math.max(maxX, n.position.dx + n.size.width);
        maxY = math.max(maxY, n.position.dy + n.size.height);
      }
    }

    if (minX.isFinite) {
      _focusOnRect(Rect.fromLTRB(minX, minY, maxX, maxY));
    }
  }

  void _focusOnFilterSite(int filterIdx) {
    final configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
    if (filterIdx >= configPvd.filtration.length) return;
    final fSite = configPvd.filtration[filterIdx];
    final double sNo = fSite.commonDetails.sNo ?? 0.0;

    for (final n in _nodes) {
      if (n.type == NodeType.multiFilter && n.id.contains('multi_filter_${sNo.toInt()}')) {
        _focusOnRect(Rect.fromLTWH(n.position.dx, n.position.dy, n.size.width, n.size.height));
        return;
      }
    }
    for (final n in _nodes) {
      if (n.type == NodeType.multiFilter) {
        _focusOnRect(Rect.fromLTWH(n.position.dx, n.position.dy, n.size.width, n.size.height));
        return;
      }
    }
  }

  void _focusOnFertilizationSite(int fertIdx) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final n in _nodes) {
      final bool isFertNode = n.type == NodeType.mainFertilizerSource ||
          n.type == NodeType.fertilizerTank ||
          n.type == NodeType.multiInjector ||
          n.type == NodeType.blower;
      if (isFertNode) {
        minX = math.min(minX, n.position.dx);
        minY = math.min(minY, n.position.dy);
        maxX = math.max(maxX, n.position.dx + n.size.width);
        maxY = math.max(maxY, n.position.dy + n.size.height);
      }
    }

    if (minX.isFinite) {
      _focusOnRect(Rect.fromLTRB(minX, minY, maxX, maxY));
    }
  }

  final ScrollController _sheetTabScrollController = ScrollController();

  Widget _buildGoogleSheetTabBar() {
    final configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
    final lines = configPvd.line;
    final filtrations = configPvd.filtration;
    final fertilizations = configPvd.fertilization;

    final List<_SiteTabItem> tabs = [];

    // 1. All Tab
    tabs.add(_SiteTabItem(
      id: 'all',
      title: 'All',
      icon: Icons.grid_view_rounded,
      accentColor: const Color(0xFF10B981),
      onTap: () {
        setState(() => _activeTabId = 'all');
        _focusOnAllNodes();
      },
    ));

    // 2. Water Source Tab
    tabs.add(_SiteTabItem(
      id: 'water_source',
      title: 'Water Source',
      icon: Icons.water_drop_outlined,
      accentColor: const Color(0xFF0284C7),
      onTap: () {
        setState(() => _activeTabId = 'water_source');
        _focusOnWaterSource();
      },
    ));

    // 2. Irrigation Line Tabs
    const List<Color> lineColors = [
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFF43F5E),
      Color(0xFF06B6D4),
    ];

    for (int i = 0; i < lines.length; i++) {
      final lSpec = lines[i];
      final String lName = (lSpec.commonDetails.name?.isNotEmpty == true && lSpec.commonDetails.name != '-')
          ? lSpec.commonDetails.name!
          : 'Irrigation Line ${i + 1}';
      final Color color = lineColors[i % lineColors.length];

      tabs.add(_SiteTabItem(
        id: 'line_$i',
        title: lName,
        icon: Icons.alt_route_rounded,
        accentColor: color,
        onTap: () {
          setState(() => _activeTabId = 'line_$i');
          _focusOnLine(i);
        },
      ));
    }

    // 3. Filtration Site Tabs
    for (int f = 0; f < filtrations.length; f++) {
      final fSite = filtrations[f];
      final String fName = (fSite.commonDetails.name?.isNotEmpty == true)
          ? fSite.commonDetails.name!
          : 'Filtration Site ${f + 1}';

      tabs.add(_SiteTabItem(
        id: 'filter_$f',
        title: fName,
        icon: Icons.filter_alt_outlined,
        accentColor: const Color(0xFFEF4444),
        onTap: () {
          setState(() => _activeTabId = 'filter_$f');
          _focusOnFilterSite(f);
        },
      ));
    }

    // 4. Fertigation Site Tabs
    for (int s = 0; s < fertilizations.length; s++) {
      final fSite = fertilizations[s];
      final String sName = (fSite.commonDetails.name?.isNotEmpty == true)
          ? fSite.commonDetails.name!
          : 'Fertilization Site ${s + 1}';

      tabs.add(_SiteTabItem(
        id: 'fert_$s',
        title: sName,
        icon: Icons.science_outlined,
        accentColor: const Color(0xFF3B82F6),
        onTap: () {
          setState(() => _activeTabId = 'fert_$s');
          _focusOnFertilizationSite(s);
        },
      ));
    }

    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Color(0xFF334155), width: 1.0),
          bottom: BorderSide(color: Color(0xFF0F172A), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Google Sheets style Left Scroll Action Buttons
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(right: BorderSide(color: Color(0xFF334155), width: 1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    _sheetTabScrollController.animateTo(
                      math.max(0.0, _sheetTabScrollController.offset - 150),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.chevron_left, size: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    _sheetTabScrollController.animateTo(
                      math.min(_sheetTabScrollController.position.maxScrollExtent, _sheetTabScrollController.offset + 150),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.chevron_right, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Google Sheets Tabs
          Expanded(
            child: SingleChildScrollView(
              controller: _sheetTabScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 6, right: 16, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: tabs.map((tab) {
                  final bool isActive = tab.id == _activeTabId;

                  return GestureDetector(
                    onTap: tab.onTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF334155),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        border: Border.all(
                          color: isActive
                              ? tab.accentColor
                              : const Color(0xFF475569),
                          width: isActive ? 1.8 : 1.0,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: tab.accentColor.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, -1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tab.accentColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            tab.icon,
                            size: 14,
                            color: isActive ? Colors.white : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tab.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Node operations
  // ---------------------------------------------------------------------
  void _addNode(NodeType type) {
    _saveToHistory();
    final rnd = math.Random();
    final id = _nextId(type.name);

    final node = NodeObject(
      id: id,
      position: Offset(300 + rnd.nextInt(200).toDouble(), 550 + rnd.nextInt(150).toDouble()),
      type: type,
      label: _defaultLabelFor(type),
      showJoints: !_globalHideJoints,
    );
    node.size = node.defaultSize;

    setState(() {
      _nodes.add(node);
      _selectedNodeId = id;
      _selectedPipeId = null;
    });
    _canvasNotifier.notify();
  }

  String _defaultLabelFor(NodeType type) {
    switch (type) {
      case NodeType.pump:
        return 'New Pump';
      case NodeType.sump:
        return 'New Sump';
      case NodeType.well:
        return 'Open Well';
      case NodeType.overheadTank:
        return 'Overhead Tank';
      case NodeType.naturalSource:
        return 'Natural Source';
      case NodeType.mainFertilizerSource:
        return 'Main Fert Source';
      case NodeType.fertilizerTank:
        return 'Fertilizer Tank';
      case NodeType.multiInjector:
        return 'Multi-Injector Skid';
      case NodeType.multiFilter:
        return 'Multi-Filter Station';
      case NodeType.multiValve:
        return 'Multi-Valve Bank';
      case NodeType.mainValve:
      case NodeType.multiMainValve:
        return 'Multi-Main Valve Bank';
      case NodeType.singleMainValve:
        return 'Main Control Valve';
      case NodeType.singleTankValve:
        return 'Single Tank Valve';
      case NodeType.multiOutletTankValve:
        return 'Multi Outlet Tank Valve';
      case NodeType.multiAgitator:
        return 'Multi-Agitator Station';
      case NodeType.singleAgitator:
        return 'Single Agitator';
      case NodeType.pressureSensor:
        return 'Pressure Sensor';
      case NodeType.moistureSensor:
        return 'Moisture Sensor';
      case NodeType.ecSensor:
        return 'EC Sensor';
      case NodeType.phSensor:
        return 'pH Sensor';
      case NodeType.soilTemperatureSensor:
        return 'Soil Temp Sensor';
      case NodeType.waterMeter:
        return 'Water Meter';
      case NodeType.blower:
        return 'Air Blower';
      case NodeType.multiFogger:
        return 'Multi-Fogger System';
      case NodeType.junction:
        return '';
      default:
        return '';
    }
  }

  /// Drag start: save undo state and make the dragged node the selected one
  /// (its port handles only exist while it is selected).
  void _onNodePanStart(NodeObject node) {
    _saveToHistory();
    if (_selectedNodeId != node.id) {
      _selectedNodeId = node.id;
      _selectedPipeId = null;
      _canvasNotifier.notify();
    }
  }

  void _onNodePanUpdate(NodeObject node, DragUpdateDetails details) {
    final double dx = (node.position.dx + details.delta.dx / _scale)
        .clamp(0.0, kCanvasWidth - node.size.width)
        .toDouble();
    final double dy = (node.position.dy + details.delta.dy / _scale)
        .clamp(0.0, kCanvasHeight - node.size.height)
        .toDouble();
    node.position = Offset(dx, dy);
    _markInteracting();
    _posTick(node.id).value++; // move ONLY this node (no repaint of its artwork)
    _dragNotifier.notify(); // repaint pipes + move handles
  }

  void _onNodeResizeUpdate(NodeObject node, DragUpdateDetails details) {
    final double deltaX = details.delta.dx / _scale;
    final double deltaY = details.delta.dy / _scale;

    double maxW = (kCanvasWidth - node.position.dx).clamp(30.0, 800.0);
    double maxH = (kCanvasHeight - node.position.dy).clamp(30.0, 800.0);

    if (_isShiftPressed && node.size.width > 0) {
      final double aspectRatio = node.size.width / node.size.height;
      double newWidth = (node.size.width + deltaX).clamp(30.0, maxW);
      double newHeight = (newWidth / aspectRatio).clamp(30.0, maxH);
      newWidth = newHeight * aspectRatio;
      node.size = Size(newWidth, newHeight);
    } else {
      double newWidth = (node.size.width + deltaX).clamp(30.0, maxW);
      double newHeight = (node.size.height + deltaY).clamp(30.0, maxH);
      node.size = Size(newWidth, newHeight);
    }
    _markInteracting();
    _nodeTick(node.id).value++;
    _dragNotifier.notify();
  }

  void _scaleSelectedNode(double factor) {
    if (_selectedNodeId == null) return;
    final node = _findNode(_selectedNodeId!);
    if (node == null || node.type == NodeType.junction) return;
    _saveToHistory();
    setState(() {
      final double maxW = (kCanvasWidth - node.position.dx).clamp(30.0, 800.0);
      final double maxH = (kCanvasHeight - node.position.dy).clamp(30.0, 800.0);
      final newW = (node.size.width * factor).clamp(30.0, maxW);
      final newH = (node.size.height * factor).clamp(30.0, maxH);
      node.size = Size(newW, newH);
    });
    _canvasNotifier.notify();
  }

  void _resetSelectedNodeSize() {
    if (_selectedNodeId == null) return;
    final node = _findNode(_selectedNodeId!);
    if (node == null || node.type == NodeType.junction) return;
    _saveToHistory();
    setState(() {
      node.size = node.defaultSize;
    });
    _canvasNotifier.notify();
  }

  void _onNodeTap(NodeObject node) {
    if (_connectMode) {
      _handleConnectPick(node.id);
      return;
    }
    setState(() {
      _selectedNodeId = node.id;
      _selectedPipeId = null;
    });
    _canvasNotifier.notify();
  }

  Set<String> _getAirNodeIds() => computeAirNodeIds(_nodes, _pipes);

  bool _isAirSource(NodeObject node) {
    if (node.type == NodeType.blower) return true;
    return _getAirNodeIds().contains(node.id);
  }

  /// Common "connect mode" logic: the first tap (on a node OR on a pipe,
  /// which auto-creates a junction) sets the source endpoint; the second
  /// tap sets the target endpoint and draws the pipe between them. This is
  /// what lets a new pipe originate from, or land on, an existing pipe
  /// instead of only ever a pump/tank/source node.
  void _handleConnectPick(String endpointNodeId) {
    setState(() {
      if (_connectFromId == null) {
        _connectFromId = endpointNodeId;
      } else if (_connectFromId != endpointNodeId) {
        _saveToHistory();
        final fromNode = _findNode(_connectFromId!);
        final toNode = _findNode(endpointNodeId);

        String? fromPortId;
        String? toPortId;

        if (fromNode != null && toNode != null) {
          final bool fromIsAir = _isAirSource(fromNode);
          final bool toIsAir = _isAirSource(toNode);

          if (fromNode.type == NodeType.fertilizerTank && toIsAir) {
            fromPortId = 'top_inlet';
          } else if (fromNode.type == NodeType.blower) {
            fromPortId = 'outlet';
          }

          if (toNode.type == NodeType.fertilizerTank && fromIsAir) {
            toPortId = 'top_inlet';
          } else if (toNode.type == NodeType.blower) {
            toPortId = 'outlet';
          }
        }

        _pipes.add(PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: _connectFromId!,
          fromPortId: fromPortId,
          toNodeId: endpointNodeId,
          toPortId: toPortId,
        ));
        _connectFromId = null;
        _connectMode = false; // Turn off connect mode after successful connection
      }
    });
    _canvasNotifier.notify();
  }

  void _onNodeLongPress(NodeObject node) {
    if (node.type == NodeType.junction) {
      _confirmDeleteJunction(node);
      return;
    }
    _showNodeEditor(node);
  }

  void _confirmDeleteJunction(NodeObject node) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pipe joint'),
        content: const Text(
            'Remove this joint? If it only joins two pipes they are merged back into one pipe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteNode(node.id);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNodeEditor(NodeObject node) {
    final controller = TextEditingController(text: node.label);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        bool lockAspectRatio = true;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void updateSize(double newW, double newH) {
              _saveToHistory();
              setSheetState(() {
                node.size = Size(
                  newW.clamp(30.0, 600.0),
                  newH.clamp(30.0, 600.0),
                );
              });
              setState(() {});
              _canvasNotifier.notify();
            }

            void scaleBy(double factor) {
              updateSize(node.size.width * factor, node.size.height * factor);
            }

            void resetSize() {
              final def = node.defaultSize;
              updateSize(def.width, def.height);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Edit ${node.type.name}', style: Theme.of(ctx).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder()),
                    ),
                    if (node.type == NodeType.pump ||
                        node.type == NodeType.sump ||
                        node.type == NodeType.well ||
                        node.type == NodeType.overheadTank ||
                        node.type == NodeType.naturalSource ||
                        node.type == NodeType.mainFertilizerSource ||
                        node.type == NodeType.fertilizerTank ||
                        node.type == NodeType.multiInjector ||
                        node.type == NodeType.multiFilter ||
                        node.type == NodeType.multiValve ||
                        node.type == NodeType.mainValve ||
                        node.type == NodeType.multiMainValve ||
                        node.type == NodeType.singleMainValve ||
                        node.type == NodeType.singleTankValve ||
                        node.type == NodeType.multiOutletTankValve ||
                        node.type == NodeType.multiAgitator ||
                        node.type == NodeType.singleAgitator ||
                        node.type == NodeType.pressureSensor ||
                        node.type == NodeType.moistureSensor ||
                        node.type == NodeType.ecSensor ||
                        node.type == NodeType.phSensor ||
                        node.type == NodeType.soilTemperatureSensor ||
                        node.type == NodeType.waterMeter ||
                        node.type == NodeType.blower ||
                        node.type == NodeType.multiFogger) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: Text(node.type == NodeType.pump ? 'Pump running' : 'Active / Flowing'),
                        value: node.isOn,
                        onChanged: (v) {
                          _saveToHistory();
                          setSheetState(() => node.isOn = v);
                          setState(() {});
                          _canvasNotifier.notify();
                        },
                      ),
                      if (node.type == NodeType.multiFilter)
                        SwitchListTile(
                          title: const Text('Filter 2 Backwash Mode'),
                          subtitle: const Text('Filter 1: Filtration | Filter 2: Backwash Flushing'),
                          value: node.isBackwash,
                          onChanged: (v) {
                            _saveToHistory();
                            setSheetState(() => node.isBackwash = v);
                            setState(() {});
                            _canvasNotifier.notify();
                          },
                        ),
                      SwitchListTile(
                        title: const Text('Show joints / bolts'),
                        subtitle: const Text('Hide flange bolts and assembly joints'),
                        value: node.showJoints,
                        onChanged: (v) {
                          _saveToHistory();
                          setSheetState(() => node.showJoints = v);
                          setState(() {});
                          _canvasNotifier.notify();
                        },
                      ),
                      if (node.type == NodeType.waterMeter ||
                          node.type == NodeType.singleTankValve ||
                          node.type == NodeType.multiOutletTankValve ||
                          node.type == NodeType.singleMainValve ||
                          node.type == NodeType.mainValve ||
                          node.type == NodeType.multiMainValve)
                        SwitchListTile(
                          title: const Text('Horizontal orientation'),
                          subtitle: Text(node.isHorizontal
                              ? 'Horizontal (Inlet left, Outlet right)'
                              : 'Vertical (Inlet top, Outlet bottom)'),
                          value: node.isHorizontal,
                          onChanged: (v) {
                            _saveToHistory();
                            setSheetState(() {
                              node.isHorizontal = v;
                              if ((v && node.size.width < node.size.height) ||
                                  (!v && node.size.width > node.size.height)) {
                                node.size = Size(node.size.height, node.size.width);
                              }
                            });
                            setState(() {});
                            _canvasNotifier.notify();
                          },
                        ),
                      if (node.type == NodeType.multiAgitator) ...[
                        const Divider(height: 24),
                        Text(
                          'Outlet Spacing (${((node.outletSpacing - 1.0) * 100).round() >= 0 ? "+" : ""}${((node.outletSpacing - 1.0) * 100).round()}%)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Compact', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Expanded(
                              child: Slider(
                                value: node.outletSpacing.clamp(0.6, 2.0),
                                min: 0.6,
                                max: 2.0,
                                divisions: 28,
                                label: '${(node.outletSpacing * 100).round()}%',
                                onChanged: (v) {
                                  _saveToHistory();
                                  setSheetState(() => node.outletSpacing = v);
                                  setState(() {});
                                  _canvasNotifier.notify();
                                },
                              ),
                            ),
                            const Text('Wide', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Outlet Vertical Pipe Extension (${node.outletPipeLength.round()} px)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('0', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Expanded(
                              child: Slider(
                                value: node.outletPipeLength.clamp(0.0, 300.0),
                                min: 0.0,
                                max: 300.0,
                                divisions: 30,
                                label: '${node.outletPipeLength.round()} px',
                                onChanged: (v) {
                                  _saveToHistory();
                                  setSheetState(() => node.outletPipeLength = v);
                                  setState(() {});
                                  _canvasNotifier.notify();
                                },
                              ),
                            ),
                            const Text('300', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                      if (node.type == NodeType.multiFogger) ...[
                        const Divider(height: 24),
                        Text(
                          'Fogger Nozzle Count (${node.outletPortCount})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('1', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Expanded(
                              child: Slider(
                                value: node.outletPortCount.toDouble().clamp(1.0, 12.0),
                                min: 1.0,
                                max: 12.0,
                                divisions: 11,
                                label: '${node.outletPortCount}',
                                onChanged: (v) {
                                  _saveToHistory();
                                  setSheetState(() => node.outletPortCount = v.round());
                                  setState(() {});
                                  _canvasNotifier.notify();
                                },
                              ),
                            ),
                            const Text('12', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Node Size (${node.size.width.round()} × ${node.size.height.round()} px)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reset', style: TextStyle(fontSize: 12)),
                          onPressed: resetSize,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Quick Preset Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => scaleBy(0.9),
                          child: const Text('-10%'),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => scaleBy(1.1),
                          child: const Text('+10%'),
                        ),
                        ActionChip(
                          label: const Text('0.5x', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final def = node.defaultSize;
                            updateSize(def.width * 0.5, def.height * 0.5);
                          },
                        ),
                        ActionChip(
                          label: const Text('0.75x', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final def = node.defaultSize;
                            updateSize(def.width * 0.75, def.height * 0.75);
                          },
                        ),
                        ActionChip(
                          label: const Text('1.0x', style: TextStyle(fontSize: 11)),
                          onPressed: resetSize,
                        ),
                        ActionChip(
                          label: const Text('1.25x', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final def = node.defaultSize;
                            updateSize(def.width * 1.25, def.height * 1.25);
                          },
                        ),
                        ActionChip(
                          label: const Text('1.5x', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final def = node.defaultSize;
                            updateSize(def.width * 1.5, def.height * 1.5);
                          },
                        ),
                        ActionChip(
                          label: const Text('2.0x', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final def = node.defaultSize;
                            updateSize(def.width * 2.0, def.height * 2.0);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Width & Height Sliders with Lock Aspect Ratio
                    Row(
                      children: [
                        const SizedBox(width: 50, child: Text('Width', style: TextStyle(fontSize: 12))),
                        Expanded(
                          child: Slider(
                            value: node.size.width.clamp(30.0, 500.0),
                            min: 30,
                            max: 500,
                            label: '${node.size.width.round()} px',
                            onChanged: (val) {
                              final ratio = node.size.height / node.size.width;
                              final newH = lockAspectRatio ? val * ratio : node.size.height;
                              updateSize(val, newH);
                            },
                          ),
                        ),
                        SizedBox(width: 35, child: Text('${node.size.width.round()}', style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 50, child: Text('Height', style: TextStyle(fontSize: 12))),
                        Expanded(
                          child: Slider(
                            value: node.size.height.clamp(30.0, 500.0),
                            min: 30,
                            max: 500,
                            label: '${node.size.height.round()} px',
                            onChanged: (val) {
                              final ratio = node.size.width / node.size.height;
                              final newW = lockAspectRatio ? val * ratio : node.size.width;
                              updateSize(newW, val);
                            },
                          ),
                        ),
                        SizedBox(width: 35, child: Text('${node.size.height.round()}', style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: lockAspectRatio,
                          onChanged: (v) => setSheetState(() => lockAspectRatio = v ?? true),
                        ),
                        const Text('Lock Aspect Ratio', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Delete', style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _deleteNode(node.id);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              _saveToHistory();
                              setState(() => node.label = controller.text);
                              _canvasNotifier.notify();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteNode(String nodeId) {
    _saveToHistory();
    final node = _findNode(nodeId);

    // A junction with exactly two pipes attached is just a pass-through
    // point on what was originally one pipe: deleting it reconnects the two
    // halves into a single pipe instead of breaking the run.
    if (node != null && node.type == NodeType.junction) {
      final attached =
      _pipes.where((p) => p.fromNodeId == nodeId || p.toNodeId == nodeId).toList();
      if (attached.length == 2) {
        PipeConnection? before, after;
        for (final p in attached) {
          if (p.toNodeId == nodeId) before = p;
          if (p.fromNodeId == nodeId) after = p;
        }
        if (before != null && after != null) {
          final merged = PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: before.fromNodeId,
            fromPortId: before.fromPortId,
            toNodeId: after.toNodeId,
            toPortId: after.toPortId,
            waypoints: [...before.waypoints, ...after.waypoints],
            flowActive: before.flowActive,
          );
          setState(() {
            _pipes.removeWhere((p) => p.id == before!.id || p.id == after!.id);
            _pipes.add(merged);
            _nodes.removeWhere((n) => n.id == nodeId);
            if (_selectedNodeId == nodeId) _selectedNodeId = null;
            _selectedPipeId = null;
          });
          _canvasNotifier.notify();
          return;
        }
      }
    }

    setState(() {
      _nodes.removeWhere((n) => n.id == nodeId);
      _pipes.removeWhere((p) => p.fromNodeId == nodeId || p.toNodeId == nodeId);
      _removeOrphanJunctions();
      if (_selectedNodeId == nodeId) _selectedNodeId = null;
    });
    _canvasNotifier.notify();
  }

  /// Drops junctions that no longer have any pipe attached (e.g. after the
  /// pipe or node they were tee'd onto was deleted).
  void _removeOrphanJunctions() {
    final used = <String>{};
    for (final p in _pipes) {
      used.add(p.fromNodeId);
      used.add(p.toNodeId);
    }
    _nodes.removeWhere((n) => n.type == NodeType.junction && !used.contains(n.id));
    if (_selectedNodeId != null && _findNode(_selectedNodeId!) == null) {
      _selectedNodeId = null;
    }
  }

  // ---------------------------------------------------------------------
  // Pipe operations
  // ---------------------------------------------------------------------
  NodeObject? _findNode(String id) {
    for (final n in _nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  void _onCanvasTapUp(TapUpDetails details) {
    final pos = details.localPosition;
    final hit = _locateNearestPipeSegment(pos, tolerance: kPipeSnapTolerance);

    if (_connectMode) {
      // Tapping a pipe in connect mode drops a joint exactly on the pipe at
      // that spot, so a new pipe can start from / end on ANY point of an
      // existing pipe, not just on a node.
      if (hit != null) {
        final junctionId = _splitPipeAtPoint(hit.pipe, hit.segmentIndex, hit.point);
        _handleConnectPick(junctionId);
      }
      return;
    }

    setState(() {
      _selectedPipeId = hit?.pipe.id;
      _selectedNodeId = null;
    });
    _canvasNotifier.notify();
  }

  /// Finds the pipe segment nearest to [pos], if any is within [tolerance].
  /// Used for selecting a pipe by tap and adding a bend point by double-tap.
  _PipeHit? _locateNearestPipeSegment(Offset pos, {required double tolerance}) {
    PipeConnection? bestPipe;
    int bestSegment = -1;
    double bestDist = tolerance;
    Offset? bestPoint;

    for (final pipe in _pipes) {
      final from = _findNode(pipe.fromNodeId);
      final to = _findNode(pipe.toNodeId);
      if (from == null || to == null) continue;
      final start = portPosition(from, pipe.fromPortId, isInput: false);
      final end = portPosition(to, pipe.toPortId, isInput: true);
      final points = <Offset>[start, ...pipe.waypoints, end];
      for (int i = 0; i < points.length - 1; i++) {
        final d = distanceToSegment(pos, points[i], points[i + 1]);
        if (d < bestDist) {
          bestDist = d;
          bestPipe = pipe;
          bestSegment = i;
          bestPoint = closestPointOnSegment(pos, points[i], points[i + 1]);
        }
      }
    }

    if (bestPipe == null || bestPoint == null) return null;
    return _PipeHit(
      pipe: bestPipe,
      segmentIndex: bestSegment,
      distance: bestDist,
      point: bestPoint,
    );
  }

  /// Splits [pipe] into two pipes joined by a new small junction node placed
  /// at [point] (which must lie on the segment at [segmentIndex]). Returns the
  /// new junction's node id so it can immediately be used as a connect
  /// endpoint. This is how a new pipe joins onto an existing pipe at any
  /// point along its length (T-joint), and joining again at the same spot
  /// gives a 4-way cross.
  String _splitPipeAtPoint(
      PipeConnection pipe,
      int segmentIndex,
      Offset point, {
        bool saveHistory = true,
      }) {
    if (saveHistory) _saveToHistory();
    final junctionId = _nextId('junction');
    final junction = NodeObject(
      id: junctionId,
      position: point - const Offset(7, 7),
      size: const Size(14, 14),
      type: NodeType.junction,
      label: '',
      showJoints: !_globalHideJoints,
    );

    final int splitAt = segmentIndex.clamp(0, pipe.waypoints.length).toInt();
    final beforeWaypoints = pipe.waypoints.sublist(0, splitAt);
    final afterWaypoints = pipe.waypoints.sublist(splitAt);

    final pipeBefore = PipeConnection(
      id: _nextId('pipe'),
      fromNodeId: pipe.fromNodeId,
      fromPortId: pipe.fromPortId,
      toNodeId: junctionId,
      waypoints: beforeWaypoints,
      flowActive: pipe.flowActive,
    );
    final pipeAfter = PipeConnection(
      id: _nextId('pipe'),
      fromNodeId: junctionId,
      toNodeId: pipe.toNodeId,
      toPortId: pipe.toPortId,
      waypoints: afterWaypoints,
      flowActive: pipe.flowActive,
    );

    setState(() {
      _nodes.add(junction);
      _pipes.remove(pipe);
      _pipes.addAll([pipeBefore, pipeAfter]);
      if (_selectedPipeId == pipe.id) _selectedPipeId = null;
    });
    _canvasNotifier.notify();

    return junctionId;
  }

  void _onCanvasDoubleTapDown(TapDownDetails details) {
    final pos = details.localPosition;
    final hit = _locateNearestPipeSegment(pos, tolerance: kPipeHitTolerance + 8);
    if (hit == null) return;
    _saveToHistory();
    final int clampedIndex = hit.segmentIndex.clamp(0, hit.pipe.waypoints.length).toInt();
    setState(() {
      hit.pipe.waypoints.insert(clampedIndex, pos);
      _selectedPipeId = hit.pipe.id;
    });
    _canvasNotifier.notify();
  }

  void _onWaypointPanUpdate(PipeConnection pipe, int index, DragUpdateDetails details) {
    final current = pipe.waypoints[index];
    double nx = (current.dx + details.delta.dx / _scale).clamp(0.0, kCanvasWidth).toDouble();
    double ny = (current.dy + details.delta.dy / _scale).clamp(0.0, kCanvasHeight).toDouble();

    if (_isShiftPressed) {
      // Find reference points before and after this waypoint to align to
      final fromNode = _findNode(pipe.fromNodeId);
      final toNode = _findNode(pipe.toNodeId);
      if (fromNode != null && toNode != null) {
        final points = <Offset>[
          portPosition(fromNode, pipe.fromPortId, isInput: false),
          ...pipe.waypoints,
          portPosition(toNode, pipe.toPortId, isInput: true),
        ];
        // index in pipe.waypoints corresponds to index + 1 in points
        final refIndex = index + 1;
        final prevPoint = points[refIndex - 1];
        final nextPoint = points[refIndex + 1];

        // Determine closer reference point
        final refPoint = (nx - prevPoint.dx).abs() + (ny - prevPoint.dy).abs() <
            (nx - nextPoint.dx).abs() + (ny - nextPoint.dy).abs()
            ? prevPoint
            : nextPoint;

        if ((nx - refPoint.dx).abs() < (ny - refPoint.dy).abs()) {
          nx = refPoint.dx;
        } else {
          ny = refPoint.dy;
        }
      }
    }

    pipe.waypoints[index] = Offset(nx, ny);
    _markInteracting();
    _dragNotifier.notify();
  }

  void _removeWaypoint(PipeConnection pipe, int index) {
    _saveToHistory();
    setState(() {
      pipe.waypoints.removeAt(index);
    });
    _canvasNotifier.notify();
  }

  void _deletePipe(String pipeId) {
    _saveToHistory();
    setState(() {
      _pipes.removeWhere((p) => p.id == pipeId);
      _removeOrphanJunctions();
      if (_selectedPipeId == pipeId) _selectedPipeId = null;
    });
    _canvasNotifier.notify();
  }

  void _onPortPanStart(NodeObject node, {required bool isInput, String? portId, Offset? initialPos}) {
    _saveToHistory();
    _connectFromId = node.id;
    _connectFromPortId = portId;
    _pendingDragIsInput = isInput;
    _pendingDragConnectionPos = initialPos ?? (isInput ? node.getPort(portId, isInput: true) : node.getPort(portId, isInput: false));
    _canvasNotifier.notify();
    _dragNotifier.notify();
  }

  void _onPortPanUpdate(DragUpdateDetails details) {
    if (_pendingDragConnectionPos != null) {
      _pendingDragConnectionPos = (_pendingDragConnectionPos! + details.delta / _scale);
      _markInteracting();
      _dragNotifier.notify();
    }
  }

  void _onPortPanEnd(DragEndDetails details) {
    if (_pendingDragConnectionPos == null || _connectFromId == null) return;
    final pos = _pendingDragConnectionPos!;

    // Check if dropped on a node
    String? targetNodeId;
    String? targetPortId;
    for (final node in _nodes) {
      if (node.id == _connectFromId) continue;

      // Dropped on an existing joint: join it directly (T -> 4-way cross).
      if (node.type == NodeType.junction) {
        final c = portPosition(node, null, isInput: false);
        if ((c - pos).distance < 14) {
          targetNodeId = node.id;
          break;
        }
        continue;
      }

      // Check if dropped near a specific port of a pump
      if (node.type == NodeType.pump) {
        if ((node.inputPort - pos).distance < 20) {
          targetNodeId = node.id;
          targetPortId = 'input';
          break;
        }
        if ((node.outputPort - pos).distance < 20) {
          targetNodeId = node.id;
          targetPortId = 'output';
          break;
        }
      }

      // Check if dropped near a specific port of a sump
      if (node.type == NodeType.sump) {
        if ((node.inputPort - pos).distance < 20) {
          targetNodeId = node.id;
          targetPortId = 'inlet';
          break;
        }
        if ((node.outputPort - pos).distance < 20) {
          targetNodeId = node.id;
          targetPortId = 'outlet';
          break;
        }
      }

      // Check if dropped near a specific port of an overhead tank
      if (node.type == NodeType.overheadTank) {
        if ((node.inputPort - pos).distance < 20) {
          targetNodeId = node.id;
          targetPortId = 'inlet';
          break;
        }
        if ((node.outputPort - pos).distance < 20) {
          targetNodeId = node.id;
          targetPortId = 'outlet';
          break;
        }
      }

      // Check if dropped near a specific port of a well
      if (node.type == NodeType.well) {
        if ((node.outputPort - pos).distance < 20) {
          targetNodeId = node.id;
          targetPortId = 'suction';
          break;
        }
      }

      // Check if dropped near a specific port of a natural source
      if (node.type == NodeType.naturalSource) {
        if ((node.outputPort - pos).distance < 20) {
          targetNodeId = node.id;
          targetPortId = 'intake';
          break;
        }
      }



      // Check if dropped near a specific port of a main fertilizer source
      if (node.type == NodeType.mainFertilizerSource) {
        final inlet = node.getPort('inlet', isInput: true);
        final waterOutlet = node.getPort('water_outlet', isInput: false);
        final outlet = node.getPort('outlet', isInput: false);
        final ports = [
          MapEntry('inlet', (inlet - pos).distance),
          MapEntry('water_outlet', (waterOutlet - pos).distance),
          MapEntry('outlet', (outlet - pos).distance),
        ];
        ports.sort((a, b) => a.value.compareTo(b.value));
        if (ports.first.value < 35) {
          targetNodeId = node.id;
          targetPortId = ports.first.key;
          break;
        }
      }

      // Check if dropped near a specific port of a fertilizer tank
      if (node.type == NodeType.fertilizerTank) {
        final leftInlet = node.getPort('inlet', isInput: true);
        final topInlet = node.getPort('top_inlet', isInput: true);
        final outlet = node.getPort('outlet', isInput: false);
        // The top port is AIR ONLY; the side inlet / bottom outlet are LIQUID
        // ONLY. Offer just the ports that match the pipe being dragged, so an
        // air hose can never land on a fertilizer port (or the reverse).
        final dragFrom = _connectFromId != null ? _findNode(_connectFromId!) : null;
        final bool dragIsAir = _connectFromPortId == 'top_inlet' ||
            (dragFrom != null && _isAirSource(dragFrom));
        final ports = dragIsAir
            ? [MapEntry('top_inlet', (topInlet - pos).distance)]
            : [
          MapEntry('inlet', (leftInlet - pos).distance),
          MapEntry('outlet', (outlet - pos).distance),
        ];
        ports.sort((a, b) => a.value.compareTo(b.value));
        if (ports.first.value < 35) {
          targetNodeId = node.id;
          targetPortId = ports.first.key;
          break;
        }
      }

      // Check if dropped near a specific port of a multi-injector skid
      if (node.type == NodeType.multiInjector) {
        for (int i = 0; i < 4; i++) {
          final p = node.getPort('channel_$i', isInput: true);
          if ((p - pos).distance < 35) {
            targetNodeId = node.id;
            targetPortId = 'channel_$i';
            break;
          }
        }
        if (targetPortId == null) {
          if ((node.inputPort - pos).distance < 35) {
            targetNodeId = node.id;
            targetPortId = 'inlet';
          } else if ((node.outputPort - pos).distance < 35) {
            targetNodeId = node.id;
            targetPortId = 'outlet';
          }
        }
        if (targetNodeId != null) break;
      }

      // Check if dropped near a specific port of a multi-filter station
      if (node.type == NodeType.multiFilter) {
        final backwashPort = node.getPort('backwash', isInput: true);
        if ((backwashPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'backwash';
        } else if ((node.inputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'inlet';
        } else if ((node.outputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'outlet';
        }
        if (targetNodeId != null) break;
      }

      // Check if dropped near the inlet or outlet port of a main valve or single tank valve
      if (node.type == NodeType.mainValve || node.type == NodeType.multiMainValve || node.type == NodeType.singleMainValve || node.type == NodeType.singleTankValve) {
        if ((node.inputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'inlet';
        } else if ((node.outputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'outlet';
        }
        if (targetNodeId != null) break;
      }

      // Check if dropped near a port of a multi-outlet tank valve manifold
      if (node.type == NodeType.multiOutletTankValve) {
        if ((node.inputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'inlet';
        } else {
          for (int i = 0; i < node.outletPortCount; i++) {
            final p = node.getPort('channel_$i', isInput: false);
            if ((p - pos).distance < 35) {
              targetNodeId = node.id;
              targetPortId = 'channel_$i';
              break;
            }
          }
        }
        if (targetNodeId != null) break;
      }

      // Check if dropped near the inlet port of a multi-valve bank
      if (node.type == NodeType.multiValve) {
        if ((node.inputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'inlet';
        }
        if (targetNodeId != null) break;
      }

      // Check if dropped near a port of a multi-agitator station
      if (node.type == NodeType.multiAgitator) {
        if ((node.inputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'inlet';
        } else if ((node.outputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'outlet';
        }
        if (targetNodeId != null) break;
      }

      // Check if dropped near a port of a blower
      if (node.type == NodeType.blower) {
        if ((node.outputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'outlet';
        }
        if (targetNodeId != null) break;
      }

      // Check if dropped near a port of a multi-fogger system
      if (node.type == NodeType.multiFogger) {
        if ((node.inputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'inlet';
        } else if ((node.outputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'outlet';
        }
        if (targetNodeId != null) break;
      }

      final rect = Rect.fromLTWH(node.position.dx, node.position.dy, node.size.width, node.size.height);
      if (rect.contains(pos)) {
        targetNodeId = node.id;
        if (node.type == NodeType.fertilizerTank && targetPortId == null) {
          final fromNode = _connectFromId != null ? _findNode(_connectFromId!) : null;
          final bool fromIsAir = (fromNode != null && _isAirSource(fromNode)) ||
              _connectFromPortId == 'top_inlet';
          if (fromIsAir) {
            targetPortId = 'top_inlet';
          } else {
            targetPortId = _pendingDragIsInput ? 'outlet' : 'inlet';
          }
        }
        break;
      }
    }

    if (targetNodeId != null) {
      setState(() {
        final newPipe = PipeConnection(
          id: _nextId('pipe'),
          fromNodeId: _pendingDragIsInput ? targetNodeId! : _connectFromId!,
          fromPortId: _pendingDragIsInput ? targetPortId : _connectFromPortId,
          toNodeId: _pendingDragIsInput ? _connectFromId! : targetNodeId!,
          toPortId: _pendingDragIsInput ? _connectFromPortId : targetPortId,
        );
        _pipes.add(newPipe);
      });
    } else {
      // Not on a node: dropped on the side of an existing pipe? Then branch
      // off it at that exact point with a T-joint.
      final srcNode = _connectFromId != null ? _findNode(_connectFromId!) : null;
      final bool onSourceNode = srcNode != null &&
          Rect.fromLTWH(srcNode.position.dx, srcNode.position.dy, srcNode.size.width,
              srcNode.size.height)
              .contains(pos);
      final hit = onSourceNode
          ? null
          : _locateNearestPipeSegment(pos, tolerance: kPipeSnapTolerance);
      if (hit != null) {
        // History was already saved when the port drag started.
        final junctionId =
        _splitPipeAtPoint(hit.pipe, hit.segmentIndex, hit.point, saveHistory: false);
        setState(() {
          _pipes.add(PipeConnection(
            id: _nextId('pipe'),
            fromNodeId: _pendingDragIsInput ? junctionId : _connectFromId!,
            fromPortId: _pendingDragIsInput ? null : _connectFromPortId,
            toNodeId: _pendingDragIsInput ? _connectFromId! : junctionId,
            toPortId: _pendingDragIsInput ? _connectFromPortId : null,
          ));
        });
      }
    }

    setState(() {
      _connectFromId = null;
      _pendingDragConnectionPos = null;
      _pendingDragIsInput = false;
    });
    _canvasNotifier.notify();
    _dragNotifier.notify();
  }

  void _deleteSelected() {
    if (_selectedNodeId != null) {
      _deleteNode(_selectedNodeId!);
    } else if (_selectedPipeId != null) {
      _deletePipe(_selectedPipeId!);
    }
  }

  void _toggleConnectMode() {
    setState(() {
      _connectMode = !_connectMode;
      _connectFromId = null;
      _connectFromPortId = null;
      _selectedNodeId = null;
      _selectedPipeId = null;
    });
    _canvasNotifier.notify();
  }

  // ---------------------------------------------------------------------
  // Export / Import
  // ---------------------------------------------------------------------
  void _showExportDialog() {
    final data = {
      'nodes': _nodes.map((n) => n.toJson()).toList(),
      'pipes': _pipes.map((p) => p.toJson()).toList(),
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configuration JSON'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: SelectableText(jsonStr, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  /// Tiny hit area for a pipe joint. The fitting itself (elbow / tee / cross)
  /// is painted by [PipePainter]; this only makes the joint tappable (select,
  /// or pick as a connect endpoint), draggable and removable.
  Widget _buildJunctionDot(NodeObject node) {
    final bool selected = node.id == _selectedNodeId;
    final bool source = node.id == _connectFromId;
    Color? ring;
    if (selected) {
      ring = Colors.deepOrange;
    } else if (source) {
      ring = Colors.green;
    } else if (_connectMode) {
      ring = Colors.blueAccent.withValues(alpha: 0.6);
    }
    return Positioned(
      key: ValueKey('jn_${node.id}'),
      left: node.position.dx - 4,
      top: node.position.dy - 4,
      width: node.size.width + 8,
      height: node.size.height + 8,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNodeTap(node),
        onLongPress: () => _onNodeLongPress(node),
        onPanStart: (d) => _saveToHistory(),
        onPanUpdate: (d) => _onNodePanUpdate(node, d),
        child: Center(
          child: ring == null
              ? const SizedBox.shrink()
              : Container(
            width: node.size.width + 4,
            height: node.size.height + 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 2),
              color: ring.withValues(alpha: 0.15),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPortHandles() {
    final bool showAll = !_globalHideJoints || _connectFromId != null;
    final List<Widget> handles = [];
    for (final node in _nodes) {
      if (!showAll && node.id != _selectedNodeId) continue;

      if (node.type == NodeType.pump) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_out'),
            position: node.outputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: false),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.blue.withValues(alpha: 0.7),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_in'),
            position: node.inputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: true),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.lightBlue.withValues(alpha: 0.7),
          ),
        );
      } else if (node.type == NodeType.sump) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_in'),
            position: node.inputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: true),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.blueGrey.withValues(alpha: 0.7),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_out'),
            position: node.outputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: false),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.blue.withValues(alpha: 0.7),
          ),
        );
      } else if (node.type == NodeType.overheadTank) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_in'),
            position: node.inputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: true),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.blue.withValues(alpha: 0.7),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_out'),
            position: node.outputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: false),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.lightBlue.withValues(alpha: 0.7),
          ),
        );
      } else if (node.type == NodeType.well || node.type == NodeType.naturalSource) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_out'),
            position: node.outputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: false),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.lightBlue.withValues(alpha: 0.7),
          ),
        );
      } else if (node.type == NodeType.mainFertilizerSource) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_inlet'),
            position: node.getPort('inlet', isInput: true),
            onPanStart: (d) => _onPortPanStart(node, isInput: true, portId: 'inlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: const Color(0xFF1565C0).withValues(alpha: 0.85),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_water_outlet'),
            position: node.getPort('water_outlet', isInput: false),
            onPanStart: (d) => _onPortPanStart(node, isInput: false, portId: 'water_outlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: const Color(0xFF00897B).withValues(alpha: 0.85),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_outlet'),
            position: node.getPort('outlet', isInput: false),
            onPanStart: (d) => _onPortPanStart(node, isInput: false, portId: 'outlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: const Color(0xFF2E7D32).withValues(alpha: 0.85),
          ),
        );
      } else if (node.type == NodeType.fertilizerTank) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_inlet'),
            position: node.getPort('inlet', isInput: true),
            onPanStart: (d) => _onPortPanStart(node, isInput: true, portId: 'inlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: const Color(0xFF2E7D32).withValues(alpha: 0.85),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_top_inlet'),
            position: node.getPort('top_inlet', isInput: true),
            onPanStart: (d) => _onPortPanStart(node, isInput: true, portId: 'top_inlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: const Color(0xFF1565C0).withValues(alpha: 0.85),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_outlet'),
            position: node.getPort('outlet', isInput: false),
            onPanStart: (d) => _onPortPanStart(node, isInput: false, portId: 'outlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: const Color(0xFF4CAF50).withValues(alpha: 0.85),
          ),
        );
      } else if (node.type == NodeType.multiInjector) {
        for (int i = 0; i < 4; i++) {
          handles.add(
            WaypointHandle(
              key: ValueKey('${node.id}_channel_$i'),
              position: node.getPort('channel_$i', isInput: true),
              onPanStart: (d) => _onPortPanStart(
                node,
                isInput: true,
                portId: 'channel_$i',
                initialPos: node.getPort('channel_$i', isInput: true),
              ),
              onPanUpdate: _onPortPanUpdate,
              onPanEnd: _onPortPanEnd,
              onLongPress: () {},
              color: Colors.lightBlue.withValues(alpha: 0.8),
            ),
          );
        }
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_inlet'),
            position: node.inputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: true, portId: 'inlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.blueGrey.withValues(alpha: 0.7),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_outlet'),
            position: node.outputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: false, portId: 'outlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.blue.withValues(alpha: 0.7),
          ),
        );
      } else if (node.type == NodeType.multiFilter) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_backwash'),
            position: node.getPort('backwash', isInput: true),
            onPanStart: (d) => _onPortPanStart(
              node,
              isInput: true,
              portId: 'backwash',
              initialPos: node.getPort('backwash', isInput: true),
            ),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.blueGrey.withValues(alpha: 0.8),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_inlet'),
            position: node.inputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: true, portId: 'inlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.cyan.withValues(alpha: 0.7),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_outlet'),
            position: node.outputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: false, portId: 'outlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.lightBlue.withValues(alpha: 0.7),
          ),
        );
      } else if (node.type == NodeType.multiValve) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_inlet'),
            position: node.inputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: true, portId: 'inlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.blueGrey.withValues(alpha: 0.7),
          ),
        );
      } else if (node.type == NodeType.mainValve ||
          node.type == NodeType.multiMainValve ||
          node.type == NodeType.singleMainValve ||
          node.type == NodeType.singleTankValve) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_inlet'),
            position: node.inputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: true, portId: 'inlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.cyan.withValues(alpha: 0.7),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_outlet'),
            position: node.outputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: false, portId: 'outlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.lightBlue.withValues(alpha: 0.7),
          ),
        );
      } else if (node.type == NodeType.multiOutletTankValve) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_inlet'),
            position: node.inputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: true, portId: 'inlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.cyan.withValues(alpha: 0.85),
          ),
        );
        for (int i = 0; i < node.outletPortCount; i++) {
          handles.add(
            WaypointHandle(
              key: ValueKey('${node.id}_channel_$i'),
              position: node.getPort('channel_$i', isInput: false),
              onPanStart: (d) => _onPortPanStart(node, isInput: false, portId: 'channel_$i'),
              onPanUpdate: _onPortPanUpdate,
              onPanEnd: _onPortPanEnd,
              onLongPress: () {},
              color: Colors.lightBlue.withValues(alpha: 0.85),
            ),
          );
        }
      } else if (node.type == NodeType.multiAgitator) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_inlet'),
            position: node.inputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: true, portId: 'inlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.cyan.withValues(alpha: 0.85),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_outlet'),
            position: node.outputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: false),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.lightBlue.withValues(alpha: 0.85),
          ),
        );
      } else if (node.type == NodeType.blower) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_outlet'),
            position: node.outputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: false, portId: 'outlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.blue.withValues(alpha: 0.85),
          ),
        );

      } else if (node.type == NodeType.multiFogger) {
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_inlet'),
            position: node.inputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: true, portId: 'inlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.cyan.withValues(alpha: 0.85),
          ),
        );
        handles.add(
          WaypointHandle(
            key: ValueKey('${node.id}_outlet'),
            position: node.outputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: false, portId: 'outlet'),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.lightBlue.withValues(alpha: 0.85),
          ),
        );
      }
    }
    return handles;
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                event.logicalKey == LogicalKeyboardKey.shiftRight) {
              _isShiftPressed = true;
            }
          } else if (event is KeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                event.logicalKey == LogicalKeyboardKey.shiftRight) {
              _isShiftPressed = false;
            }
          }
        },
        child: Column(
          children: [
            RepaintBoundary(child: _buildToolbar()),
            Expanded(
              child: Container(
                color: Colors.white,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          // Camera: pan / zoom is just a matrix change, no rebuilds.
                          child: Listener(
                            key: _viewKey,
                            onPointerSignal: _onCanvasPointerSignal,
                            child: InteractiveViewer(
                          transformationController: _tc,
                          constrained: false,
                          scaleEnabled: false, // no wheel / pinch zoom (buttons only)
                          minScale: 0.4,
                          maxScale: 2.0,
                          boundaryMargin: const EdgeInsets.all(100),
                          child: SizedBox(
                            width: kCanvasWidth,
                            height: kCanvasHeight,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: _onCanvasTapUp,
                              onDoubleTapDown: _onCanvasDoubleTapDown,
                              onDoubleTap: () {}, // required so onDoubleTapDown fires
                              child: Stack(
                                children: [
                                  // grid background (static, painted once)
                                  Positioned.fill(
                                    child: RepaintBoundary(
                                      child: CustomPaint(painter: _GridPainter()),
                                    ),
                                  ),

                                  // LAYER 1: pipes + nodes.
                                  // Rebuilds on structure changes only; while dragging,
                                  // only the moved node's own host rebuilds.
                                  ListenableBuilder(
                                    listenable: _canvasNotifier,
                                    builder: (context, _) {
                                      return Stack(
                                        children: [
                                          // pipes
                                          Positioned.fill(
                                            child: RepaintBoundary(
                                              child: ListenableBuilder(
                                                listenable: _dragNotifier,
                                                builder: (context, _) {
                                                  return CustomPaint(
                                                    painter: PipePainter(
                                                      nodes: _nodes,
                                                      pipes: _pipes,
                                                      selectedPipeId: _selectedPipeId,
                                                      pendingConnectFromId: _connectFromId,
                                                      pendingFromPortId: _connectFromPortId,
                                                      pendingDragPos: _pendingDragConnectionPos,
                                                      pendingIsInput: _pendingDragIsInput,
                                                      simplify: _simplifyPaint,
                                                      cullRect: _builtRect,
                                                      repaint: Listenable.merge(
                                                          [_canvasNotifier, _dragNotifier, _simplifyPaint]),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          // nodes (each one rebuilds on its own tick)
                                          for (final node in _nodes)
                                            if (_isBuilt(node))
                                              if (node.type == NodeType.junction)
                                                ListenableBuilder(
                                                  key: ValueKey('host_${node.id}'),
                                                  listenable: _posTick(node.id),
                                                  builder: (context, _) => _buildJunctionDot(node),
                                                )
                                              else
                                                _buildNodeHost(node),
                                        ],
                                      );
                                    },
                                  ),

                                  // LAYER 2: interaction handles (waypoints + ports of
                                  // the selected node only). Follows drag updates.
                                  ListenableBuilder(
                                    listenable: Listenable.merge([_canvasNotifier, _dragNotifier]),
                                    builder: (context, _) {
                                      return Positioned.fill(
                                        child: Stack(
                                          children: [
                                            if (!_globalHideJoints)
                                              for (final pipe in _pipes)
                                                if (pipe.id == _selectedPipeId)
                                                  for (int i = 0; i < pipe.waypoints.length; i++)
                                                    WaypointHandle(
                                                      key: ValueKey('wp_${pipe.id}_$i'),
                                                      position: pipe.waypoints[i],
                                                      onPanStart: (d) => _saveToHistory(),
                                                      onPanUpdate: (d) => _onWaypointPanUpdate(pipe, i, d),
                                                      onLongPress: () => _removeWaypoint(pipe, i),
                                                      color: Colors.deepOrange,
                                                    ),
                                            ..._buildPortHandles(),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Custom attractive scrollbars overlay
                    Positioned.fill(
                      bottom: 36,
                      child: _AttractiveScrollbars(
                        tc: _tc,
                        viewportWidth: constraints.maxWidth,
                        viewportHeight: constraints.maxHeight - 36,
                      ),
                    ),
                    // Google Sheets Style Tab Bar
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 36,
                      child: _buildGoogleSheetTabBar(),
                    ),
                    // Right side vertical floating action buttons (placed to the left of the vertical scrollbar)
                    Positioned(
                      top: 16,
                      right: 22,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Undo',
                                icon: const Icon(Icons.undo),
                                onPressed: _undoStack.isNotEmpty ? _undo : null,
                              ),
                              IconButton(
                                tooltip: 'Redo',
                                icon: const Icon(Icons.redo),
                                onPressed: _redoStack.isNotEmpty ? _redo : null,
                              ),
                              const SizedBox(height: 4),
                              Container(width: 24, height: 1, color: Colors.black12),
                              const SizedBox(height: 4),
                              IconButton(
                                tooltip: _globalHideJoints ? 'Disable Hide Joints' : 'Enable Hide Joints',
                                icon: Icon(_globalHideJoints ? Icons.layers_clear : Icons.layers),
                                onPressed: () {
                                  setState(() {
                                    _globalHideJoints = !_globalHideJoints;
                                    for (final node in _nodes) {
                                      node.showJoints = !_globalHideJoints;
                                    }
                                  });
                                  _canvasNotifier.notify();
                                },
                              ),
                              const SizedBox(height: 4),
                              Container(width: 24, height: 1, color: Colors.black12),
                              const SizedBox(height: 4),
                              IconButton(
                                tooltip: 'Zoom in',
                                icon: const Icon(Icons.zoom_in),
                                onPressed: () => _zoomBy(1.1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: ListenableBuilder(
                                  listenable: _tc,
                                  builder: (_, __) => Text(
                                    '${(_scale * 100).round()}%',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Zoom out',
                                icon: const Icon(Icons.zoom_out),
                                onPressed: () => _zoomBy(0.9),
                              ),
                              const SizedBox(height: 4),
                              Container(width: 24, height: 1, color: Colors.black12),
                              const SizedBox(height: 4),
                              IconButton(
                                tooltip: 'Export configuration (JSON)',
                                icon: const Icon(Icons.file_download),
                                onPressed: _showExportDialog,
                              ),
                              IconButton(
                                tooltip: 'Clear canvas',
                                icon: const Icon(Icons.delete_sweep),
                                onPressed: () {
                                  _saveToHistory();
                                  setState(() {
                                    _nodes.clear();
                                    _pipes.clear();
                                    _selectedNodeId = null;
                                    _selectedPipeId = null;
                                    _connectFromId = null;
                                  });
                                  _canvasNotifier.notify();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
  ),
);
}

  Widget _buildToolbar() {
    return Material(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            _toolButton(Icons.settings_input_component, 'Pump', () => _addNode(NodeType.pump)),
            _toolButton(Icons.inbox, 'Sump', () => _addNode(NodeType.sump)),
            _toolButton(Icons.waves, 'Well', () => _addNode(NodeType.well)),
            _toolButton(Icons.architecture, 'OH Tank', () => _addNode(NodeType.overheadTank)),
            _toolButton(Icons.landscape, 'Natural Src', () => _addNode(NodeType.naturalSource)),
            _toolButton(Icons.science, 'Main Fert Src', () => _addNode(NodeType.mainFertilizerSource)),
            _toolButton(Icons.biotech, 'Fert Tank', () => _addNode(NodeType.fertilizerTank)),
            _toolButton(Icons.tune, 'Multi-Injector', () => _addNode(NodeType.multiInjector)),
            _toolButton(Icons.filter_alt_outlined, 'Multi-Filter', () => _addNode(NodeType.multiFilter)),
            _toolButton(Icons.alt_route, 'Multi-Valve', () => _addNode(NodeType.multiValve)),
            _toolButton(Icons.alt_route, 'Multi Main Valve', () => _addNode(NodeType.multiMainValve)),
            _toolButton(Icons.toggle_on, 'Single Main Valve', () => _addNode(NodeType.singleMainValve)),
            _toolButton(Icons.adjust, 'Single Tank Valve', () => _addNode(NodeType.singleTankValve)),
            _toolButton(Icons.view_array, 'Multi Outlet Tank Valve', () => _addNode(NodeType.multiOutletTankValve)),
            _toolButton(Icons.cyclone, 'Multi-Agitator', () => _addNode(NodeType.multiAgitator)),
            _toolButton(Icons.cyclone, 'Single Agitator', () => _addNode(NodeType.singleAgitator)),
            _toolButton(Icons.speed, 'Pressure Sensor', () => _addNode(NodeType.pressureSensor)),
            _toolButton(Icons.grass, 'Moisture Sensor', () => _addNode(NodeType.moistureSensor)),
            _toolButton(Icons.bolt, 'EC Sensor', () => _addNode(NodeType.ecSensor)),
            _toolButton(Icons.science, 'pH Sensor', () => _addNode(NodeType.phSensor)),
            _toolButton(Icons.thermostat, 'Soil Temp', () => _addNode(NodeType.soilTemperatureSensor)),
            _toolButton(Icons.water_drop, 'Water Meter', () => _addNode(NodeType.waterMeter)),
            _toolButton(Icons.air, 'Air Blower', () => _addNode(NodeType.blower)),
            _toolButton(Icons.cloud, 'Multi-Fogger', () => _addNode(NodeType.multiFogger)),
            const SizedBox(width: 12),
            const VerticalDivider(width: 1),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Auto Arrange from Config', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _generateFromSourceConfig(showSnackBar: true),
            ),
            const SizedBox(width: 12),
            const VerticalDivider(width: 1),
            const SizedBox(width: 12),
            FilterChip(
              label: const Text('Connect pipe'),
              avatar: const Icon(Icons.timeline, size: 18),
              selected: _connectMode,
              onSelected: (_) => _toggleConnectMode(),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete selected', style: TextStyle(color: Colors.red)),
              onPressed: (_selectedNodeId != null || _selectedPipeId != null) ? _deleteSelected : null,
            ),
            if (_selectedNodeId != null &&
                _findNode(_selectedNodeId!)?.type != NodeType.junction) ...[
              const SizedBox(width: 8),
              const VerticalDivider(width: 1),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Reduce node size (-10%)',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _scaleSelectedNode(0.9),
              ),
              IconButton(
                tooltip: 'Increase node size (+10%)',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _scaleSelectedNode(1.1),
              ),
              IconButton(
                tooltip: 'Reset node size',
                icon: const Icon(Icons.aspect_ratio),
                onPressed: _resetSelectedNodeSize,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

/// Reference to a water supply node (pump or source or valve) and its output port.
class _SupplyNodeRef {
  final NodeObject node;
  final String portId;
  _SupplyNodeRef(this.node, this.portId);
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

/// Result of a nearest-pipe-segment lookup: which pipe, which segment
/// (0-based, between points[i] and points[i+1] of that pipe's full path),
/// and how far the query point was from it.
class _PipeHit {
  final PipeConnection pipe;
  final int segmentIndex;
  final double distance;

  /// Closest point on that segment to the query point (where a joint goes).
  final Offset point;

  _PipeHit({
    required this.pipe,
    required this.segmentIndex,
    required this.distance,
    required this.point,
  });
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AttractiveScrollbars extends StatefulWidget {
  final TransformationController tc;
  final double viewportWidth;
  final double viewportHeight;

  const _AttractiveScrollbars({
    required this.tc,
    required this.viewportWidth,
    required this.viewportHeight,
  });

  @override
  State<_AttractiveScrollbars> createState() => _AttractiveScrollbarsState();
}

class _AttractiveScrollbarsState extends State<_AttractiveScrollbars> {
  bool _hoverH = false;
  bool _hoverV = false;
  bool _dragH = false;
  bool _dragV = false;

  double _startThumbLeft = 0.0;
  double _startDragX = 0.0;

  double _startThumbTop = 0.0;
  double _startDragY = 0.0;

  void _scrollToRatioX(double targetRatio, double scale, double minVisX, double spanX) {
    final double clampedRatio = targetRatio.clamp(0.0, 1.0);
    final double newVisLeft = minVisX + clampedRatio * spanX;
    final Matrix4 nextM = widget.tc.value.clone();
    nextM.storage[12] = -newVisLeft * scale;
    widget.tc.value = nextM;
  }

  void _scrollToRatioY(double targetRatio, double scale, double minVisY, double spanY) {
    final double clampedRatio = targetRatio.clamp(0.0, 1.0);
    final double newVisTop = minVisY + clampedRatio * spanY;
    final Matrix4 nextM = widget.tc.value.clone();
    nextM.storage[13] = -newVisTop * scale;
    widget.tc.value = nextM;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.tc,
      builder: (context, _) {
        final Matrix4 m = widget.tc.value;
        final double scale = m.getMaxScaleOnAxis();
        final double tx = m.storage[12];
        final double ty = m.storage[13];

        final double visW = widget.viewportWidth / scale;
        final double visH = widget.viewportHeight / scale;

        const double minVisX = -300.0;
        final double maxVisX = kCanvasWidth + 300.0 - visW;
        final double spanX = math.max(1.0, maxVisX - minVisX);

        const double minVisY = -300.0;
        final double maxVisY = kCanvasHeight + 300.0 - visH;
        final double spanY = math.max(1.0, maxVisY - minVisY);

        final double visLeft = (-tx / scale).clamp(minVisX, maxVisX);
        final double visTop = (-ty / scale).clamp(minVisY, maxVisY);

        final double ratioX = ((visLeft - minVisX) / spanX).clamp(0.0, 1.0);
        final double ratioY = ((visTop - minVisY) / spanY).clamp(0.0, 1.0);

        // Horizontal Track & Thumb (placed at the very bottom edge)
        const double padLeftH = 6.0;
        const double padRightH = 20.0;
        final double trackW = math.max(100.0, widget.viewportWidth - padLeftH - padRightH);
        final double totalSpanW = kCanvasWidth + 600.0;
        final double thumbW = (trackW * (visW / totalSpanW)).clamp(40.0, trackW * 0.85);
        final double availTrackW = math.max(1.0, trackW - thumbW);
        final double thumbLeft = availTrackW * ratioX;

        // Vertical Track & Thumb (placed at the very right edge, after floating action buttons)
        const double padTopV = 6.0;
        const double padBottomV = 20.0;
        final double trackH = math.max(100.0, widget.viewportHeight - padTopV - padBottomV);
        final double totalSpanH = kCanvasHeight + 600.0;
        final double thumbH = (trackH * (visH / totalSpanH)).clamp(40.0, trackH * 0.85);
        final double availTrackH = math.max(1.0, trackH - thumbH);
        final double thumbTop = availTrackH * ratioY;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── HORIZONTAL SCROLLBAR (At the very bottom edge) ──
            Positioned(
              left: padLeftH,
              bottom: 4,
              width: trackW,
              height: 12,
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoverH = true),
                onExit: (_) => setState(() => _hoverH = false),
                child: GestureDetector(
                  onTapDown: (details) {
                    final double localX = details.localPosition.dx;
                    final double targetRatio = (localX - thumbW / 2) / availTrackW;
                    _scrollToRatioX(targetRatio, scale, minVisX, spanX);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _hoverH || _dragH ? 0.90 : 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_hoverH || _dragH ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1))
                            .withValues(alpha: 0.7),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: thumbLeft,
                          top: 1,
                          bottom: 1,
                          width: thumbW,
                          child: GestureDetector(
                            onPanStart: (details) {
                              setState(() {
                                _dragH = true;
                                _startThumbLeft = thumbLeft;
                                _startDragX = details.globalPosition.dx;
                              });
                            },
                            onPanEnd: (_) => setState(() => _dragH = false),
                            onPanCancel: () => setState(() => _dragH = false),
                            onPanUpdate: (details) {
                              if (availTrackW <= 0) return;
                              final double dx = details.globalPosition.dx - _startDragX;
                              final double targetThumbLeft = _startThumbLeft + dx;
                              final double targetRatio = targetThumbLeft / availTrackW;
                              _scrollToRatioX(targetRatio, scale, minVisX, spanX);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: (_dragH || _hoverH)
                                      ? const [Color(0xFF06B6D4), Color(0xFF0284C7)]
                                      : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7)
                                        .withValues(alpha: _dragH || _hoverH ? 0.55 : 0.30),
                                    blurRadius: _dragH || _hoverH ? 8 : 4,
                                    spreadRadius: _dragH || _hoverH ? 1 : 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (int i = 0; i < 3; i++)
                                      Container(
                                        width: 2,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(horizontal: 1.2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── VERTICAL SCROLLBAR (At the very right edge, after floating action buttons) ──
            Positioned(
              right: 4,
              top: padTopV,
              width: 12,
              height: trackH,
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoverV = true),
                onExit: (_) => setState(() => _hoverV = false),
                child: GestureDetector(
                  onTapDown: (details) {
                    final double localY = details.localPosition.dy;
                    final double targetRatio = (localY - thumbH / 2) / availTrackH;
                    _scrollToRatioY(targetRatio, scale, minVisY, spanY);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _hoverV || _dragV ? 0.90 : 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_hoverV || _dragV ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1))
                            .withValues(alpha: 0.7),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: thumbTop,
                          left: 1,
                          right: 1,
                          height: thumbH,
                          child: GestureDetector(
                            onPanStart: (details) {
                              setState(() {
                                _dragV = true;
                                _startThumbTop = thumbTop;
                                _startDragY = details.globalPosition.dy;
                              });
                            },
                            onPanEnd: (_) => setState(() => _dragV = false),
                            onPanCancel: () => setState(() => _dragV = false),
                            onPanUpdate: (details) {
                              if (availTrackH <= 0) return;
                              final double dy = details.globalPosition.dy - _startDragY;
                              final double targetThumbTop = _startThumbTop + dy;
                              final double targetRatio = targetThumbTop / availTrackH;
                              _scrollToRatioY(targetRatio, scale, minVisY, spanY);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: (_dragV || _hoverV)
                                      ? const [Color(0xFF06B6D4), Color(0xFF0284C7)]
                                      : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7)
                                        .withValues(alpha: _dragV || _hoverV ? 0.55 : 0.30),
                                    blurRadius: _dragV || _hoverV ? 8 : 4,
                                    spreadRadius: _dragV || _hoverV ? 1 : 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (int i = 0; i < 3; i++)
                                      Container(
                                        width: 5,
                                        height: 2,
                                        margin: const EdgeInsets.symmetric(vertical: 1.2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SiteTabItem {
  final String id;
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  _SiteTabItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });
}