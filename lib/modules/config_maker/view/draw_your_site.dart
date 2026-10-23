import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'setup/fertigation_Setup.dart';
import 'setup/filtration_setup.dart';
import 'setup/main_pipe_line_setup.dart';
import 'setup/site_layout_context.dart';
import 'setup/water_source_setup.dart';

import '../model/canvas_helpers.dart';
import '../model/node_type_model.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/attractive_scrollbars.dart';
import '../widget/draw_site_controls.dart';
import '../widget/draw_site_toolbar.dart';
import '../widget/node_editor_bottom_sheet.dart';
import '../widget/node_widget.dart';
import '../widget/painter/grid_painter.dart';
import '../widget/painter/pipe_painter.dart';
import '../widget/site_tab_bar.dart';

const double kCanvasWidth = 3000;
const double kCanvasHeight = 2000;
const double kPipeHitTolerance = 14;

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
  final CanvasNotifier _canvasNotifier = CanvasNotifier();
  final CanvasNotifier _dragNotifier = CanvasNotifier();
  final Map<String, ValueNotifier<int>> _nodeTicks = {};
  final TransformationController _tc = TransformationController();
  final FocusNode _focus = FocusNode();

  // true while the user is dragging: pipes are painted without blur / ribs
  final ValueNotifier<bool> _simplifyPaint = ValueNotifier<bool>(false);
  Timer? _simplifyTimer;

  // ---- viewport culling -------------------------------------------------
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
      child: content,
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

    final water = WaterSourceSetup(ctx).build();
    final filterNodes = FiltrationSetup(ctx).build(water);
    final skidNodes = FertigationSetup(ctx).build();
    MainPipelineSetup(ctx).build(
      water: water,
      filterNodes: filterNodes,
      skidNodes: skidNodes,
    );

    _idCounter = ctx.idCounter;

    _builtRect = null;
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
    _sheetTabScrollController.dispose();
    for (final t in _nodeTicks.values) {
      t.dispose();
    }
    for (final t in _posTicks.values) {
      t.dispose();
    }
    super.dispose();
  }

  double get _canvasWidth {
    double maxX = 0.0;
    for (final n in _nodes) {
      final double r = n.position.dx + n.size.width + 600.0;
      if (r > maxX) maxX = r;
    }
    for (final p in _pipes) {
      for (final wp in p.waypoints) {
        final double r = wp.dx + 600.0;
        if (r > maxX) maxX = r;
      }
    }
    return math.max(kCanvasWidth, maxX);
  }

  double get _canvasHeight {
    double maxY = 0.0;
    for (final n in _nodes) {
      final double b = n.position.dy + n.size.height + 600.0;
      if (b > maxY) maxY = b;
    }
    for (final p in _pipes) {
      for (final wp in p.waypoints) {
        final double b = wp.dy + 600.0;
        if (b > maxY) maxY = b;
      }
    }
    return math.max(kCanvasHeight, maxY);
  }

  String _nextId(String prefix) => '${prefix}_${_idCounter++}';

  void _onCanvasPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final Offset d = event.scrollDelta;
    final double dx = _isShiftPressed ? d.dy : d.dx;
    final double dy = _isShiftPressed ? 0.0 : d.dy;
    final Matrix4 m = _tc.value.clone()..leftTranslate(-dx, -dy);
    final double s = m.getMaxScaleOnAxis();
    final double tx = m.storage[12].clamp(-(_canvasWidth * s) + 100.0, 0.0).toDouble();
    final double ty = m.storage[13].clamp(-(_canvasHeight * s) + 100.0, 0.0).toDouble();
    m.storage[12] = tx;
    m.storage[13] = ty;
    _tc.value = m;
  }

  void _zoomBy(double factor) {
    final double target = (_scale * factor).clamp(0.4, 2.0).toDouble();
    final double k = target / _scale;
    _tc.value = _tc.value.clone()..scale(k, k, 1.0);
  }

  void _focusOnRect(
      Rect targetRect, {
        double padding = 140.0,
        double? paddingX,
        double? paddingY,
        double? maxScale,
        double minScale = 0.3,
        double? targetScale,
        bool alignTopLeft = false,
        bool fitWidth = false,
      }) {
    final ctx = _viewKey.currentContext;
    final ro = ctx?.findRenderObject();
    final Size viewportSize = (ro is RenderBox && ro.hasSize)
        ? ro.size
        : MediaQuery.of(context).size;

    final double pX = paddingX ?? padding;
    final double pY = paddingY ?? padding;

    final double vW = math.max(200.0, viewportSize.width - pX - 80.0);
    final double vH = math.max(200.0, viewportSize.height - pY - 180.0);

    final double rectW = math.max(50.0, targetRect.width);
    final double rectH = math.max(50.0, targetRect.height);

    final double scaleX = vW / rectW;
    final double scaleY = vH / rectH;
    final double upperLimit = maxScale ?? 1.4;
    final double lowerLimit = math.min(minScale, upperLimit);

    final double computedScale;
    if (targetScale != null) {
      computedScale = targetScale;
    } else if (fitWidth) {
      computedScale = math.min(scaleX, upperLimit).clamp(lowerLimit, upperLimit).toDouble();
    } else {
      computedScale = math.min(scaleX, scaleY).clamp(lowerLimit, upperLimit).toDouble();
    }

    final double tx;
    final double ty;

    if (alignTopLeft) {
      tx = pX - (targetRect.left * computedScale);
      ty = pY - (targetRect.top * computedScale);
    } else {
      final Offset center = targetRect.center;
      tx = (viewportSize.width / 2.0) - (center.dx * computedScale);
      ty = (vH / 2.0) - (center.dy * computedScale);
    }

    final Matrix4 endM = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(computedScale);

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
      const double marginLeft = 50.0;
      const double marginRight = 20.0;
      const double marginTop = 50.0;
      const double marginBottom = 30.0;

      final Rect target = Rect.fromLTRB(
        math.max(0.0, minX - marginLeft),
        math.max(0.0, minY - marginTop),
        maxX + marginRight,
        maxY + marginBottom,
      );

      _focusOnRect(
        target,
        paddingX: 12.0,
        paddingY: 12.0,
        fitWidth: true,
        alignTopLeft: true,
        maxScale: 1.0,
        minScale: 0.15,
      );
    }
  }

  /// Focuses on an irrigation line and fits the line's full width into the
  /// current viewport, so the zoom depends on the screen size and all valves
  /// of a row are visible without horizontal scrolling.
  void _focusOnLine(int lineIdx) {
    final String headerId = 'line_header_$lineIdx';
    final String bankPrefix = 'multi_valve_line_${lineIdx}_bank_';

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    void include(Rect r) {
      minX = math.min(minX, r.left);
      minY = math.min(minY, r.top);
      maxX = math.max(maxX, r.right);
      maxY = math.max(maxY, r.bottom);
    }

    for (final n in _nodes) {
      final bool isLineNode = n.id == headerId ||
          n.id.startsWith(bankPrefix) ||
          (n.type == NodeType.multiValve && n.id.contains('line_${lineIdx}_'));
      if (!isLineNode) continue;

      double w = n.size.width;
      if (n.type == NodeType.multiValve) {
        // node width = 60 * valves + 60  ->  recover the valve count
        final int valves = math.max(1, ((n.size.width - 60.0) / 75.0).round());
        // painted spacing is ~157px per valve for a 180px-high node
        final double spacing = n.size.height * 0.875;
        w = valves * spacing;
      }
      include(Rect.fromLTWH(n.position.dx, n.position.dy, w, n.size.height));
    }

    if (!minX.isFinite) return;

    // Margins (reduce these to zoom in a little more)
    const double marginLeft = 50.0;  // main header pipe on the left
    const double marginRight = 20.0;
    const double marginTop = 50.0;   // room for the "Irrigation Line" badge
    const double marginBottom = 30.0;

    final Rect target = Rect.fromLTRB(
      math.max(0.0, minX - marginLeft),
      math.max(0.0, minY - marginTop),
      maxX + marginRight,
      maxY + marginBottom,
    );

    _focusOnRect(
      target,
      paddingX: 12.0,
      paddingY: 12.0,
      fitWidth: true,
      alignTopLeft: true,
      maxScale: 1.0,
      minScale: 0.15,
    );
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

    final List<SiteTabItem> tabs = [];

    // 1. All Tab
    tabs.add(SiteTabItem(
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
    tabs.add(SiteTabItem(
      id: 'water_source',
      title: 'Water Source',
      icon: Icons.water_drop_outlined,
      accentColor: const Color(0xFF0284C7),
      onTap: () {
        setState(() => _activeTabId = 'water_source');
        _focusOnWaterSource();
      },
    ));

    // 3. Irrigation Line Tabs
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

      tabs.add(SiteTabItem(
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

    // 4. Filtration Site Tabs
    for (int f = 0; f < filtrations.length; f++) {
      final fSite = filtrations[f];
      final String fName = (fSite.commonDetails.name?.isNotEmpty == true)
          ? fSite.commonDetails.name!
          : 'Filtration Site ${f + 1}';

      tabs.add(SiteTabItem(
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

    // 5. Fertigation Site Tabs
    for (int s = 0; s < fertilizations.length; s++) {
      final fSite = fertilizations[s];
      final String sName = (fSite.commonDetails.name?.isNotEmpty == true)
          ? fSite.commonDetails.name!
          : 'Fertilization Site ${s + 1}';

      tabs.add(SiteTabItem(
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

    return SiteTabBar(
      activeTabId: _activeTabId,
      tabs: tabs,
      scrollController: _sheetTabScrollController,
    );
  }

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
        .clamp(0.0, _canvasWidth - node.size.width)
        .toDouble();
    final double dy = (node.position.dy + details.delta.dy / _scale)
        .clamp(0.0, _canvasHeight - node.size.height)
        .toDouble();
    node.position = Offset(dx, dy);
    _markInteracting();
    _posTick(node.id).value++;
    _dragNotifier.notify();
  }

  void _onNodeResizeUpdate(NodeObject node, DragUpdateDetails details) {
    final double deltaX = details.delta.dx / _scale;
    final double deltaY = details.delta.dy / _scale;

    double maxW = (_canvasWidth - node.position.dx).clamp(30.0, 800.0);
    double maxH = (_canvasHeight - node.position.dy).clamp(30.0, 800.0);

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
      final double maxW = (_canvasWidth - node.position.dx).clamp(30.0, 800.0);
      final double maxH = (_canvasHeight - node.position.dy).clamp(30.0, 800.0);
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
        _connectMode = false;
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
    NodeEditorBottomSheet.show(
      context: context,
      node: node,
      onSaveHistory: _saveToHistory,
      onNotifyCanvas: _canvasNotifier.notify,
      onDelete: () => _deleteNode(node.id),
      onSaveLabel: (label) {
        setState(() => node.label = label);
      },
    );
  }

  void _deleteNode(String nodeId) {
    _saveToHistory();
    final node = _findNode(nodeId);

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

  PipeHit? _locateNearestPipeSegment(Offset pos, {required double tolerance}) {
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
    return PipeHit(
      pipe: bestPipe,
      segmentIndex: bestSegment,
      distance: bestDist,
      point: bestPoint,
    );
  }

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
    double nx = (current.dx + details.delta.dx / _scale).clamp(0.0, _canvasWidth).toDouble();
    double ny = (current.dy + details.delta.dy / _scale).clamp(0.0, _canvasHeight).toDouble();

    if (_isShiftPressed) {
      final fromNode = _findNode(pipe.fromNodeId);
      final toNode = _findNode(pipe.toNodeId);
      if (fromNode != null && toNode != null) {
        final points = <Offset>[
          portPosition(fromNode, pipe.fromPortId, isInput: false),
          ...pipe.waypoints,
          portPosition(toNode, pipe.toPortId, isInput: true),
        ];
        final refIndex = index + 1;
        final prevPoint = points[refIndex - 1];
        final nextPoint = points[refIndex + 1];

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

    String? targetNodeId;
    String? targetPortId;
    for (final node in _nodes) {
      if (node.id == _connectFromId) continue;

      if (node.type == NodeType.junction) {
        final c = portPosition(node, null, isInput: false);
        if ((c - pos).distance < 14) {
          targetNodeId = node.id;
          break;
        }
        continue;
      }

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

      if (node.type == NodeType.well) {
        if ((node.outputPort - pos).distance < 20) {
          targetNodeId = node.id;
          targetPortId = 'suction';
          break;
        }
      }

      if (node.type == NodeType.naturalSource) {
        if ((node.outputPort - pos).distance < 20) {
          targetNodeId = node.id;
          targetPortId = 'intake';
          break;
        }
      }

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

      if (node.type == NodeType.fertilizerTank) {
        final leftInlet = node.getPort('inlet', isInput: true);
        final topInlet = node.getPort('top_inlet', isInput: true);
        final outlet = node.getPort('outlet', isInput: false);
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

      if (node.type == NodeType.multiValve) {
        if ((node.inputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'inlet';
        }
        if (targetNodeId != null) break;
      }

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

      if (node.type == NodeType.blower) {
        if ((node.outputPort - pos).distance < 35) {
          targetNodeId = node.id;
          targetPortId = 'outlet';
        }
        if (targetNodeId != null) break;
      }

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
      final srcNode = _connectFromId != null ? _findNode(_connectFromId!) : null;
      final bool onSourceNode = srcNode != null &&
          Rect.fromLTWH(srcNode.position.dx, srcNode.position.dy, srcNode.size.width,
              srcNode.size.height)
              .contains(pos);
      final hit = onSourceNode
          ? null
          : _locateNearestPipeSegment(pos, tolerance: kPipeSnapTolerance);
      if (hit != null) {
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
            RepaintBoundary(
              child: DrawSiteToolbar(
                onAddNode: _addNode,
                onAutoArrange: () => _generateFromSourceConfig(showSnackBar: true),
                onToggleConnectMode: _toggleConnectMode,
                onDeleteSelected: _deleteSelected,
                onScaleSelectedNode: _scaleSelectedNode,
                onResetSelectedNodeSize: _resetSelectedNodeSize,
                connectMode: _connectMode,
                isNodeSelected: _selectedNodeId != null,
                isPipeSelected: _selectedPipeId != null,
                isJunctionSelected: _selectedNodeId != null &&
                    _findNode(_selectedNodeId!)?.type == NodeType.junction,
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Listener(
                            key: _viewKey,
                            onPointerSignal: _onCanvasPointerSignal,
                            child: InteractiveViewer(
                              transformationController: _tc,
                              constrained: false,
                              scaleEnabled: false,
                              minScale: 0.4,
                              maxScale: 2.0,
                              boundaryMargin: const EdgeInsets.all(100),
                              child: SizedBox(
                                width: _canvasWidth,
                                height: _canvasHeight,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: _onCanvasTapUp,
                                  onDoubleTapDown: _onCanvasDoubleTapDown,
                                  onDoubleTap: () {},
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: RepaintBoundary(
                                          child: CustomPaint(painter: const GridPainter()),
                                        ),
                                      ),
                                      ListenableBuilder(
                                        listenable: _canvasNotifier,
                                        builder: (context, _) {
                                          return Stack(
                                            children: [
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
                        Positioned.fill(
                          bottom: 36,
                          child: AttractiveScrollbars(
                            tc: _tc,
                            viewportWidth: constraints.maxWidth,
                            viewportHeight: constraints.maxHeight - 36,
                            canvasWidth: _canvasWidth,
                            canvasHeight: _canvasHeight,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 36,
                          child: _buildGoogleSheetTabBar(),
                        ),
                        Positioned(
                          top: 16,
                          right: 22,
                          child: DrawSiteControlsOverlay(
                            onUndo: _undo,
                            onRedo: _redo,
                            canUndo: _undoStack.isNotEmpty,
                            canRedo: _redoStack.isNotEmpty,
                            globalHideJoints: _globalHideJoints,
                            transformationController: _tc,
                            onToggleHideJoints: () {
                              setState(() {
                                _globalHideJoints = !_globalHideJoints;
                                for (final node in _nodes) {
                                  node.showJoints = !_globalHideJoints;
                                }
                              });
                              _canvasNotifier.notify();
                            },
                            onZoomIn: () => _zoomBy(1.1),
                            onZoomOut: () => _zoomBy(0.9),
                            onExportJson: _showExportDialog,
                            onClearCanvas: () {
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
}