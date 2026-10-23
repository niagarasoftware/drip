import 'package:flutter/material.dart';
import '../model/node_type_model.dart';

/// Bottom sheet dialog for editing properties, sizes, and configurations of a NodeObject.
class NodeEditorBottomSheet extends StatefulWidget {
  final NodeObject node;
  final VoidCallback onSaveHistory;
  final VoidCallback onNotifyCanvas;
  final VoidCallback onDelete;
  final ValueChanged<String> onSaveLabel;

  const NodeEditorBottomSheet({
    super.key,
    required this.node,
    required this.onSaveHistory,
    required this.onNotifyCanvas,
    required this.onDelete,
    required this.onSaveLabel,
  });

  static Future<void> show({
    required BuildContext context,
    required NodeObject node,
    required VoidCallback onSaveHistory,
    required VoidCallback onNotifyCanvas,
    required VoidCallback onDelete,
    required ValueChanged<String> onSaveLabel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => NodeEditorBottomSheet(
        node: node,
        onSaveHistory: onSaveHistory,
        onNotifyCanvas: onNotifyCanvas,
        onDelete: onDelete,
        onSaveLabel: onSaveLabel,
      ),
    );
  }

  @override
  State<NodeEditorBottomSheet> createState() => _NodeEditorBottomSheetState();
}

class _NodeEditorBottomSheetState extends State<NodeEditorBottomSheet> {
  late TextEditingController _labelController;
  bool _lockAspectRatio = true;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.node.label);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _updateSize(double newW, double newH) {
    widget.onSaveHistory();
    setState(() {
      widget.node.size = Size(
        newW.clamp(30.0, 600.0),
        newH.clamp(30.0, 600.0),
      );
    });
    widget.onNotifyCanvas();
  }

  void _scaleBy(double factor) {
    _updateSize(widget.node.size.width * factor, widget.node.size.height * factor);
  }

  void _resetSize() {
    final def = widget.node.defaultSize;
    _updateSize(def.width, def.height);
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit ${node.type.name}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _labelController,
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
                  widget.onSaveHistory();
                  setState(() => node.isOn = v);
                  widget.onNotifyCanvas();
                },
              ),
              if (node.type == NodeType.multiFilter)
                SwitchListTile(
                  title: const Text('Filter 2 Backwash Mode'),
                  subtitle: const Text('Filter 1: Filtration | Filter 2: Backwash Flushing'),
                  value: node.isBackwash,
                  onChanged: (v) {
                    widget.onSaveHistory();
                    setState(() => node.isBackwash = v);
                    widget.onNotifyCanvas();
                  },
                ),
              SwitchListTile(
                title: const Text('Show joints / bolts'),
                subtitle: const Text('Hide flange bolts and assembly joints'),
                value: node.showJoints,
                onChanged: (v) {
                  widget.onSaveHistory();
                  setState(() => node.showJoints = v);
                  widget.onNotifyCanvas();
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
                    widget.onSaveHistory();
                    setState(() {
                      node.isHorizontal = v;
                      if ((v && node.size.width < node.size.height) ||
                          (!v && node.size.width > node.size.height)) {
                        node.size = Size(node.size.height, node.size.width);
                      }
                    });
                    widget.onNotifyCanvas();
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
                          widget.onSaveHistory();
                          setState(() => node.outletSpacing = v);
                          widget.onNotifyCanvas();
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
                          widget.onSaveHistory();
                          setState(() => node.outletPipeLength = v);
                          widget.onNotifyCanvas();
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
                          widget.onSaveHistory();
                          setState(() => node.outletPortCount = v.round());
                          widget.onNotifyCanvas();
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
                  onPressed: _resetSize,
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                  onPressed: () => _scaleBy(0.9),
                  child: const Text('-10%'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _scaleBy(1.1),
                  child: const Text('+10%'),
                ),
                ActionChip(
                  label: const Text('0.5x', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final def = node.defaultSize;
                    _updateSize(def.width * 0.5, def.height * 0.5);
                  },
                ),
                ActionChip(
                  label: const Text('0.75x', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final def = node.defaultSize;
                    _updateSize(def.width * 0.75, def.height * 0.75);
                  },
                ),
                ActionChip(
                  label: const Text('1.0x', style: TextStyle(fontSize: 11)),
                  onPressed: _resetSize,
                ),
                ActionChip(
                  label: const Text('1.25x', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final def = node.defaultSize;
                    _updateSize(def.width * 1.25, def.height * 1.25);
                  },
                ),
                ActionChip(
                  label: const Text('1.5x', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final def = node.defaultSize;
                    _updateSize(def.width * 1.5, def.height * 1.5);
                  },
                ),
                ActionChip(
                  label: const Text('2.0x', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final def = node.defaultSize;
                    _updateSize(def.width * 2.0, def.height * 2.0);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                      final newH = _lockAspectRatio ? val * ratio : node.size.height;
                      _updateSize(val, newH);
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
                      final newW = _lockAspectRatio ? val * ratio : node.size.width;
                      _updateSize(newW, val);
                    },
                  ),
                ),
                SizedBox(width: 35, child: Text('${node.size.height.round()}', style: const TextStyle(fontSize: 12))),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _lockAspectRatio,
                  onChanged: (v) => setState(() => _lockAspectRatio = v ?? true),
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
                      Navigator.pop(context);
                      widget.onDelete();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onSaveHistory();
                      widget.onSaveLabel(_labelController.text);
                      widget.onNotifyCanvas();
                      Navigator.pop(context);
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
  }
}
