import 'package:flutter/material.dart';
import '../model/node_type_model.dart';

/// Top horizontal scrollable toolbar for canvas node creation and canvas actions.
class DrawSiteToolbar extends StatelessWidget {
  final ValueChanged<NodeType> onAddNode;
  final VoidCallback onAutoArrange;
  final VoidCallback onToggleConnectMode;
  final VoidCallback? onDeleteSelected;
  final ValueChanged<double>? onScaleSelectedNode;
  final VoidCallback? onResetSelectedNodeSize;
  final bool connectMode;
  final bool isNodeSelected;
  final bool isPipeSelected;
  final bool isJunctionSelected;
  final bool fullAccess;

  const DrawSiteToolbar({
    super.key,
    required this.onAddNode,
    required this.onAutoArrange,
    required this.onToggleConnectMode,
    required this.onDeleteSelected,
    required this.onScaleSelectedNode,
    required this.onResetSelectedNodeSize,
    required this.connectMode,
    required this.isNodeSelected,
    required this.isPipeSelected,
    required this.isJunctionSelected,
    this.fullAccess = true,
  });

  Widget _toolButton(IconData icon, String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF181C38),
          side: const BorderSide(color: Color(0xFF2B335C)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          minimumSize: const Size(0, 32),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0C0F1D),
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0C0F1D),
          border: Border(bottom: BorderSide(color: Color(0xFF1E2648))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _toolButton(Icons.settings_input_component, 'Pump', () => onAddNode(NodeType.pump)),
              _toolButton(Icons.inbox, 'Sump', () => onAddNode(NodeType.sump)),
              _toolButton(Icons.waves, 'Well', () => onAddNode(NodeType.well)),
              _toolButton(Icons.architecture, 'OH Tank', () => onAddNode(NodeType.overheadTank)),
              _toolButton(Icons.landscape, 'Natural Src', () => onAddNode(NodeType.naturalSource)),
              _toolButton(Icons.science, 'Main Fert Src', () => onAddNode(NodeType.mainFertilizerSource)),
              _toolButton(Icons.biotech, 'Fert Tank', () => onAddNode(NodeType.fertilizerTank)),
              _toolButton(Icons.tune, 'Multi-Injector', () => onAddNode(NodeType.multiInjector)),
              _toolButton(Icons.filter_alt_outlined, 'Multi-Filter', () => onAddNode(NodeType.multiFilter)),
              _toolButton(Icons.alt_route, 'Multi-Valve', () => onAddNode(NodeType.multiValve)),
              _toolButton(Icons.alt_route, 'Multi Main Valve', () => onAddNode(NodeType.multiMainValve)),
              _toolButton(Icons.toggle_on, 'Single Main Valve', () => onAddNode(NodeType.singleMainValve)),
              _toolButton(Icons.adjust, 'Single Tank Valve', () => onAddNode(NodeType.singleTankValve)),
              _toolButton(Icons.view_array, 'Multi Outlet Tank Valve', () => onAddNode(NodeType.multiOutletTankValve)),
              _toolButton(Icons.cyclone, 'Multi-Agitator', () => onAddNode(NodeType.multiAgitator)),
              _toolButton(Icons.cyclone, 'Single Agitator', () => onAddNode(NodeType.singleAgitator)),
              _toolButton(Icons.speed, 'Pressure Sensor', () => onAddNode(NodeType.pressureSensor)),
              _toolButton(Icons.grass, 'Moisture Sensor', () => onAddNode(NodeType.moistureSensor)),
              _toolButton(Icons.bolt, 'EC Sensor', () => onAddNode(NodeType.ecSensor)),
              _toolButton(Icons.science, 'pH Sensor', () => onAddNode(NodeType.phSensor)),
              _toolButton(Icons.thermostat, 'Soil Temp', () => onAddNode(NodeType.soilTemperatureSensor)),
              _toolButton(Icons.water_drop, 'Water Meter', () => onAddNode(NodeType.waterMeter)),
              _toolButton(Icons.air, 'Air Blower', () => onAddNode(NodeType.blower)),
              _toolButton(Icons.cloud, 'Multi-Fogger', () => onAddNode(NodeType.multiFogger)),
              const SizedBox(width: 12),
              const VerticalDivider(width: 1, color: Color(0xFF2B335C)),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Auto Arrange from Config', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: onAutoArrange,
              ),
              const SizedBox(width: 12),
              const VerticalDivider(width: 1, color: Color(0xFF2B335C)),
              const SizedBox(width: 12),
              FilterChip(
                label: Text('Connect pipe', style: TextStyle(color: connectMode ? Colors.white : const Color(0xFF8E9BB4), fontSize: 12)),
                avatar: Icon(Icons.timeline, size: 16, color: connectMode ? Colors.white : const Color(0xFF38BDF8)),
                selected: connectMode,
                backgroundColor: const Color(0xFF181C38),
                selectedColor: const Color(0xFF0284C7),
                side: BorderSide(color: connectMode ? const Color(0xFF0284C7) : const Color(0xFF2B335C)),
                onSelected: (_) => onToggleConnectMode(),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 16),
                label: const Text('Delete selected', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF181C38),
                  side: const BorderSide(color: Color(0xFF2B335C)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (isNodeSelected || isPipeSelected) ? onDeleteSelected : null,
              ),
              if (isNodeSelected && !isJunctionSelected) ...[
                const SizedBox(width: 8),
                const VerticalDivider(width: 1, color: Color(0xFF2B335C)),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Reduce node size (-10%)',
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 18),
                  onPressed: onScaleSelectedNode != null ? () => onScaleSelectedNode!(0.9) : null,
                ),
                IconButton(
                  tooltip: 'Increase node size (+10%)',
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                  onPressed: onScaleSelectedNode != null ? () => onScaleSelectedNode!(1.1) : null,
                ),
                IconButton(
                  tooltip: 'Reset node size',
                  icon: const Icon(Icons.aspect_ratio, color: Colors.white, size: 18),
                  onPressed: onResetSelectedNodeSize,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
