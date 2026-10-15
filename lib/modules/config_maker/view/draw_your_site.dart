import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/node_type_model.dart';
import '../widget/node_widget.dart';
import '../widget/painter/pipe_painter.dart';

const double kCanvasWidth = 1900;
const double kCanvasHeight = 1150;
const double kPipeHitTolerance = 14;

class CanvasNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class DrawYourSiteScreen extends StatefulWidget {
  const DrawYourSiteScreen({super.key});

  @override
  State<DrawYourSiteScreen> createState() => _DrawYourSiteScreenState();
}

class _DrawYourSiteScreenState extends State<DrawYourSiteScreen> {
  final List<NodeObject> _nodes = [];
  final List<PipeConnection> _pipes = [];
  final CanvasNotifier _canvasNotifier = CanvasNotifier();

  String? _selectedNodeId;
  String? _selectedPipeId;
  bool _connectMode = false;
  String? _connectFromId;
  String? _connectFromPortId;
  Offset? _pendingDragConnectionPos;
  bool _pendingDragIsInput = false;
  double _scale = 1.0;
  int _idCounter = 0;
  bool _globalHideJoints = false;

  bool _isShiftPressed = false;

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
  void initState() {
    super.initState();
    // Start with a fresh page without default layout
  }

  @override
  void dispose() {
    _canvasNotifier.dispose();
    super.dispose();
  }

  String _nextId(String prefix) => '${prefix}_${_idCounter++}';

  // ---------------------------------------------------------------------
  // Default starter layout (mirrors the multi-source / multi-pump diagram)
  // ---------------------------------------------------------------------
  void _loadDefaultLayout() {
    _nodes.clear();
    _pipes.clear();
    _idCounter = 0;

    NodeObject addNode(NodeType type, String label, double dx, double dy,
        {Size size = const Size(96, 74)}) {
      final n = NodeObject(
        id: _nextId(type.name),
        position: Offset(dx, dy),
        size: size,
        type: type,
        label: label,
      );
      _nodes.add(n);
      return n;
    }

    void connect(NodeObject from, NodeObject to, {List<Offset> bends = const []}) {
      _pipes.add(PipeConnection(
        id: _nextId('pipe'),
        fromNodeId: from.id,
        toNodeId: to.id,
        waypoints: List.of(bends),
      ));
    }

    final source1 = addNode(NodeType.naturalSource, 'Source 1\n(Borewell)', 40, 60);
    final source2 = addNode(NodeType.naturalSource, 'Source 2\n(Pond)', 40, 260);
    final source3 = addNode(NodeType.naturalSource, 'Source 3\n(U/G Tank)', 40, 460);

    final pumpS1A = addNode(NodeType.pump, 'Pump S1A', 230, 60);
    final pumpS2A = addNode(NodeType.pump, 'Pump S2A', 230, 260);
    final pumpS3A = addNode(NodeType.pump, 'Pump S3A', 230, 460);

    final overheadTank = addNode(
        NodeType.overheadTank, 'Overhead Tank', 760, 40,
        size: const Size(110, 130));
    final intermediateTank = addNode(
        NodeType.overheadTank, 'Intermediate Tank', 760, 330,
        size: const Size(110, 130));

    final pumpT1 = addNode(NodeType.pump, 'Transfer\nPump T1', 520, 340);
    final pumpT2 = addNode(NodeType.pump, 'Transfer\nPump T2', 520, 460);

    final dist1 = addNode(NodeType.singleMainValve, 'Distribution\n(Irrigation)', 1080, 60);
    final dist2 = addNode(NodeType.singleMainValve, 'Distribution\n(Users)', 1080, 340);

    final sump = addNode(NodeType.sump, 'Sump /\nCollection Tank', 40, 760,
        size: const Size(130, 90));
    final pumpE1 = addNode(NodeType.pump, 'Extraction\nPump E1', 260, 720);
    final pumpE2 = addNode(NodeType.pump, 'Extraction\nPump E2', 260, 840);
    final otherTank = addNode(NodeType.naturalSource, 'Other Source\n/ Drain', 500, 780);

    connect(source1, pumpS1A);
    connect(pumpS1A, overheadTank);
    connect(source2, pumpS2A);
    connect(pumpS2A, overheadTank, bends: [const Offset(430, 297), const Offset(430, 105)]);
    connect(source3, pumpS3A);
    connect(pumpS3A, overheadTank, bends: [const Offset(470, 497), const Offset(470, 115)]);

    connect(overheadTank, pumpT1, bends: [const Offset(700, 377)]);
    connect(pumpT1, intermediateTank);
    connect(overheadTank, pumpT2, bends: [const Offset(690, 497)]);
    connect(pumpT2, intermediateTank);

    connect(overheadTank, dist1);
    connect(intermediateTank, dist2);

    final valveBank = addNode(NodeType.multiValve, 'Control Valve Manifold', 750, 580);
    connect(intermediateTank, valveBank);
    connect(valveBank, dist2, bends: [const Offset(1050, 617), const Offset(1050, 380)]);

    connect(sump, pumpE1);
    connect(pumpE1, otherTank);
    connect(sump, pumpE2, bends: [const Offset(150, 877)]);
    connect(pumpE2, otherTank);
  }

  // ---------------------------------------------------------------------
  // Node operations
  // ---------------------------------------------------------------------
  void _addNode(NodeType type) {
    _saveToHistory();
    final rnd = Random();
    final id = _nextId(type.name);
    Size size = const Size(96, 74);
    if (type == NodeType.mainFertilizerSource) {
      size = const Size(140, 100);
    } else if (type == NodeType.fertilizerTank) {
      size = const Size(100, 120);
    } else if (type == NodeType.multiInjector) {
      size = const Size(280, 160);
    } else if (type == NodeType.multiFilter) {
      size = const Size(280, 168);
    } else if (type == NodeType.multiValve) {
      size = const Size(300, 180);
    } else if (type == NodeType.mainValve || type == NodeType.multiMainValve) {
      size = const Size(220, 200);
    } else if (type == NodeType.singleMainValve) {
      size = const Size(160, 120);
    } else if (type == NodeType.singleTankValve) {
      size = const Size(120, 120);
    } else if (type == NodeType.multiOutletTankValve) {
      size = const Size(280, 120);
    } else if (type == NodeType.multiAgitator) {
      size = const Size(320, 180);
    } else if (type == NodeType.singleAgitator) {
      size = const Size(120, 196);
    } else if (type == NodeType.pressureSensor) {
      size = const Size(50, 50);
    } else if (type == NodeType.moistureSensor) {
      size = const Size(60, 80);
    } else if (type == NodeType.waterMeter) {
      size = const Size(120, 180);
    } else if (type == NodeType.blower) {
      size = const Size(160, 150);
    } else if (type == NodeType.overheadTank) {
      size = const Size(110, 130);
    } else if (type == NodeType.sump || type == NodeType.naturalSource || type == NodeType.well) {
      size = const Size(130, 90);
    }

    setState(() {
      _nodes.add(NodeObject(
        id: id,
        position: Offset(300 + rnd.nextInt(200).toDouble(), 550 + rnd.nextInt(150).toDouble()),
        type: type,
        size: size,
        label: _defaultLabelFor(type),
        showJoints: !_globalHideJoints,
      ));
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
      case NodeType.waterMeter:
        return 'Water Meter';
      case NodeType.blower:
        return 'Air Blower';
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
    _canvasNotifier.notify();
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
    _canvasNotifier.notify();
  }

  void _scaleSelectedNode(double factor) {
    if (_selectedNodeId == null) return;
    final node = _findNode(_selectedNodeId!);
    if (node == null) return;
    _saveToHistory();
    setState(() {
      final double maxW = (kCanvasWidth - node.position.dx).clamp(30.0, 800.0);
      final double maxH = (kCanvasHeight - node.position.dy).clamp(30.0, 800.0);
      final newW = (node.size.width * factor).clamp(30.0, maxW);
      final newH = (node.size.height * factor).clamp(30.0, maxH);
      node.size = Size(newW, newH);
    });
  }

  void _resetSelectedNodeSize() {
    if (_selectedNodeId == null) return;
    final node = _findNode(_selectedNodeId!);
    if (node == null) return;
    _saveToHistory();
    setState(() {
      node.size = node.defaultSize;
    });
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

  Set<String> _getAirNodeIds() {
    final Set<String> airNodeIds = {};
    for (final node in _nodes) {
      if (node.type == NodeType.blower) {
        airNodeIds.add(node.id);
      }
    }
    for (final pipe in _pipes) {
      final from = _findNode(pipe.fromNodeId);
      final to = _findNode(pipe.toNodeId);
      if (from == null || to == null) continue;
      if (from.type == NodeType.fertilizerTank && pipe.fromPortId == 'top_inlet') {
        airNodeIds.add(from.id);
      }
      if (to.type == NodeType.fertilizerTank && pipe.toPortId == 'top_inlet') {
        airNodeIds.add(to.id);
      }
    }
    return airNodeIds;
  }

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
    _showNodeEditor(node);
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
                        node.type == NodeType.waterMeter ||
                        node.type == NodeType.blower) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: Text(node.type == NodeType.pump ? 'Pump running' : 'Active / Flowing'),
                        value: node.isOn,
                        onChanged: (v) {
                          _saveToHistory();
                          setSheetState(() => node.isOn = v);
                          setState(() {});
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
                        },
                      ),
                      if (node.type == NodeType.waterMeter)
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
                                },
                              ),
                            ),
                            const Text('300', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
    setState(() {
      _nodes.removeWhere((n) => n.id == nodeId);
      _pipes.removeWhere((p) => p.fromNodeId == nodeId || p.toNodeId == nodeId);
      if (_selectedNodeId == nodeId) _selectedNodeId = null;
    });
    _canvasNotifier.notify();
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
    final hit = _locateNearestPipeSegment(pos, tolerance: kPipeHitTolerance + 4);
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

    for (final pipe in _pipes) {
      final from = _findNode(pipe.fromNodeId);
      final to = _findNode(pipe.toNodeId);
      if (from == null || to == null) continue;
      final start = from.getPort(pipe.fromPortId, isInput: false);
      final end = to.getPort(pipe.toPortId, isInput: true);
      final points = <Offset>[start, ...pipe.waypoints, end];
      for (int i = 0; i < points.length - 1; i++) {
        final d = distanceToSegment(pos, points[i], points[i + 1]);
        if (d < bestDist) {
          bestDist = d;
          bestPipe = pipe;
          bestSegment = i;
        }
      }
    }

    if (bestPipe == null) return null;
    return _PipeHit(pipe: bestPipe, segmentIndex: bestSegment, distance: bestDist);
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
        final points = <Offset>[fromNode.outputPort, ...pipe.waypoints, toNode.inputPort];
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
    _canvasNotifier.notify();
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
  }

  void _onPortPanUpdate(DragUpdateDetails details) {
    if (_pendingDragConnectionPos != null) {
      _pendingDragConnectionPos = (_pendingDragConnectionPos! + details.delta / _scale);
      _canvasNotifier.notify();
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

      // Check if dropped near a specific port of a fertilizer tank
      if (node.type == NodeType.fertilizerTank) {
        final leftInlet = node.getPort('inlet', isInput: true);
        final topInlet = node.getPort('top_inlet', isInput: true);
        final outlet = node.getPort('outlet', isInput: false);
        final ports = [
          MapEntry('inlet', (leftInlet - pos).distance),
          MapEntry('top_inlet', (topInlet - pos).distance),
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
          for (int i = 0; i < 4; i++) {
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
    }

    setState(() {
      _connectFromId = null;
      _pendingDragConnectionPos = null;
      _pendingDragIsInput = false;
    });
    _canvasNotifier.notify();
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
      _selectedNodeId = null;
      _selectedPipeId = null;
    });
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

  List<Widget> _buildPortHandles() {
    if (_globalHideJoints) return const [];
    final List<Widget> handles = [];
    for (final node in _nodes) {
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
            key: ValueKey('${node.id}_in'),
            position: node.inputPort,
            onPanStart: (d) => _onPortPanStart(node, isInput: true),
            onPanUpdate: _onPortPanUpdate,
            onPanEnd: _onPortPanEnd,
            onLongPress: () {},
            color: Colors.lightGreen.withValues(alpha: 0.7),
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
            color: Colors.green.withValues(alpha: 0.7),
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
        for (int i = 0; i < 4; i++) {
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
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                event.logicalKey == LogicalKeyboardKey.shiftRight) {
              setState(() => _isShiftPressed = true);
            }
          } else if (event is KeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                event.logicalKey == LogicalKeyboardKey.shiftRight) {
              setState(() => _isShiftPressed = false);
            }
          }
        },
        child: Column(
          children: [
            RepaintBoundary(child: _buildToolbar()),
            Expanded(
              child: Container(
                color: const Color(0xFFF3F5F7),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Transform.scale(
                            scale: _scale,
                            alignment: Alignment.topLeft,
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
                                    // grid background
                                    Positioned.fill(
                                      child: RepaintBoundary(
                                        child: CustomPaint(painter: _GridPainter()),
                                      ),
                                    ),
                                    ListenableBuilder(
                                      listenable: _canvasNotifier,
                                      builder: (context, _) {
                                        return Stack(
                                          children: [
                                            // pipes
                                            Positioned.fill(
                                              child: RepaintBoundary(
                                                child: CustomPaint(
                                                  painter: PipePainter(
                                                    nodes: _nodes,
                                                    pipes: _pipes,
                                                    selectedPipeId: _selectedPipeId,
                                                    pendingConnectFromId: _connectFromId,
                                                    pendingFromPortId: _connectFromPortId,
                                                    pendingDragPos: _pendingDragConnectionPos,
                                                    pendingIsInput: _pendingDragIsInput,
                                                    repaint: _canvasNotifier,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // nodes
                                            for (final node in _nodes)
                                              NodeWidget(
                                                key: ValueKey(node.id),
                                                node: node,
                                                isSelected: node.id == _selectedNodeId,
                                                isConnectSource: node.id == _connectFromId,
                                                onTap: () => _onNodeTap(node),
                                                onLongPress: () => _onNodeLongPress(node),
                                                onPanStart: (d) => _saveToHistory(),
                                                onPanUpdate: (d) => _onNodePanUpdate(node, d),
                                                onResizeStart: (d) => _saveToHistory(),
                                                onResizeUpdate: (d) => _onNodeResizeUpdate(node, d),
                                              ),
                                            // waypoint drag handles
                                            if (!_globalHideJoints)
                                              for (final pipe in _pipes)
                                                for (int i = 0; i < pipe.waypoints.length; i++)
                                                  WaypointHandle(
                                                    key: ValueKey('wp_${pipe.id}_$i'),
                                                    position: pipe.waypoints[i],
                                                    onPanStart: (d) => _saveToHistory(),
                                                    onPanUpdate: (d) => _onWaypointPanUpdate(pipe, i, d),
                                                    onLongPress: () => _removeWaypoint(pipe, i),
                                                    color: pipe.id == _selectedPipeId
                                                        ? Colors.deepOrange
                                                        : const Color(0xFFFFA726),
                                                  ),
                                            // port handles
                                            ..._buildPortHandles(),
                                          ],
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
                    ),
                    // Right side vertical floating action buttons
                    Positioned(
                      top: 16,
                      right: 16,
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
                                },
                              ),
                              const SizedBox(height: 4),
                              Container(width: 24, height: 1, color: Colors.black12),
                              const SizedBox(height: 4),
                              IconButton(
                                tooltip: 'Zoom in',
                                icon: const Icon(Icons.zoom_in),
                                onPressed: () => setState(() => _scale = (_scale + 0.1).clamp(0.4, 2.0).toDouble()),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '${(_scale * 100).round()}%',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Zoom out',
                                icon: const Icon(Icons.zoom_out),
                                onPressed: () => setState(() => _scale = (_scale - 0.1).clamp(0.4, 2.0).toDouble()),
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
                                tooltip: 'Reset to default layout',
                                icon: const Icon(Icons.restart_alt),
                                onPressed: () {
                                  _saveToHistory();
                                  setState(_loadDefaultLayout);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
            _toolButton(Icons.water_drop, 'Water Meter', () => _addNode(NodeType.waterMeter)),
            _toolButton(Icons.air, 'Air Blower', () => _addNode(NodeType.blower)),
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
            if (_selectedNodeId != null) ...[
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

  _PipeHit({required this.pipe, required this.segmentIndex, required this.distance});
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
