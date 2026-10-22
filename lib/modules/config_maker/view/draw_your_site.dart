import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/setup/fertigation_Setup.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/setup/filtration_setup.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/setup/main_pipe_line_setup.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/setup/site_layout_context.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/setup/water_source_setup.dart';
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

  // ---------------------------------------------------------------------
  // Auto arrange (layered, compact, non-overlapping)
  //
  // The layout logic lives in separate files:
  //   water_source_setup.dart     sources + water pumps + tank valves
  //   filtration_setup.dart       multi-filter stations
  //   fertigation_setup.dart      fert source / tanks / blowers / injector skid
  //   main_pipeline_setup.dart    water supply -> filter -> skid -> lines
  //   irrigation_line_setup.dart  line headers, valve banks, foggers
  // ---------------------------------------------------------------------
  void _generateFromSourceConfig({bool showSnackBar = true}) {
    final configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);

    if (SiteSetupData(configPvd).isEmpty) {
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

    final ctx = SiteLayoutContext(
      nodes: _nodes,
      pipes: _pipes,
      configPvd: configPvd,
      globalHideJoints: _globalHideJoints,
    );

    final water = WaterSourceSetup(ctx).build(); // sources + pumps (top section)
    final filterNodes = FiltrationSetup(ctx).build(water); // filter stations
    final skidNodes = FertigationSetup(ctx).build(); // fertigation (right side)
    MainPipelineSetup(ctx).build(
      water: water,
      filterNodes: filterNodes,
      skidNodes: skidNodes,
    ); // supply -> filter -> skid -> irrigation lines

    _idCounter = ctx.idCounter;

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

  String _defaultLabelFor(NodeType type) => defaultLabelFor(type);

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