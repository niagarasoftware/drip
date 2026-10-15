import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/blower_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/fertilizer_tank_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/main_fertilizer_source_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/moisture_sensor_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_agitator_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_filter_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_injector_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_main_valve_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_outlet_tank_valve_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_valve_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/natural_source_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/over_head_tank_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/pressure_sensor_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/pump_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/single_agitator_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/single_main_valve_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/single_tank_valve_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/sump_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/water_meter_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/well_painter.dart';
import '../model/node_type_model.dart';


class NodeWidget extends StatelessWidget {
  final NodeObject node;
  final bool isSelected;
  final bool isConnectSource;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragStartDetails)? onPanStart;
  final void Function(DragUpdateDetails)? onResizeUpdate;
  final void Function(DragStartDetails)? onResizeStart;

  const NodeWidget({
    super.key,
    required this.node,
    required this.onTap,
    required this.onLongPress,
    required this.onPanUpdate,
    this.onPanStart,
    this.onResizeUpdate,
    this.onResizeStart,
    this.isSelected = false,
    this.isConnectSource = false,
  });

  IconData get _icon {
    switch (node.type) {
      case NodeType.pump:
        return Icons.settings_input_component;
      case NodeType.naturalSource:
      case NodeType.well:
        return Icons.water;
      case NodeType.overheadTank:
        return Icons.propane_tank_outlined;
      case NodeType.sump:
        return Icons.inbox;
      case NodeType.mainFertilizerSource:
        return Icons.science;
      case NodeType.fertilizerTank:
        return Icons.biotech;
      case NodeType.multiInjector:
        return Icons.tune;
      case NodeType.multiFilter:
        return Icons.filter_alt_outlined;
      case NodeType.multiValve:
        return Icons.alt_route;
      case NodeType.mainValve:
      case NodeType.multiMainValve:
        return Icons.alt_route;
      case NodeType.singleMainValve:
        return Icons.toggle_on;
      case NodeType.singleTankValve:
        return Icons.adjust;
      case NodeType.multiOutletTankValve:
        return Icons.view_array;
      case NodeType.multiAgitator:
      case NodeType.singleAgitator:
        return Icons.cyclone;
      case NodeType.pressureSensor:
        return Icons.speed;
      case NodeType.moistureSensor:
        return Icons.grass;
      case NodeType.waterMeter:
        return Icons.water_drop;
      case NodeType.blower:
        return Icons.air;
    }
  }

  Color get _iconColor {
    switch (node.type) {
      case NodeType.pump:
        return node.isOn ? const Color(0xFF1565C0) : Colors.grey;
      case NodeType.naturalSource:
      case NodeType.well:
        return const Color(0xFF00897B);
      case NodeType.overheadTank:
        return const Color(0xFF3949AB);
      case NodeType.sump:
        return const Color(0xFF6D4C41);
      case NodeType.mainFertilizerSource:
        return const Color(0xFF2E7D32);
      case NodeType.fertilizerTank:
        return const Color(0xFF0288D1);
      case NodeType.multiInjector:
        return const Color(0xFF1976D2);
      case NodeType.multiFilter:
        return const Color(0xFFD32F2F);
      case NodeType.multiValve:
        return const Color(0xFF2E7D32);
      case NodeType.mainValve:
      case NodeType.multiMainValve:
        return const Color(0xFF1565C0);
      case NodeType.singleMainValve:
        return const Color(0xFFD32F2F);
      case NodeType.singleTankValve:
        return const Color(0xFF0288D1);
      case NodeType.multiOutletTankValve:
        return const Color(0xFF0288D1);
      case NodeType.multiAgitator:
      case NodeType.singleAgitator:
        return const Color(0xFF1B4EBF);
      case NodeType.pressureSensor:
        return const Color(0xFFE65100);
      case NodeType.moistureSensor:
        return const Color(0xFF2E7D32);
      case NodeType.waterMeter:
        return const Color(0xFF2F6FB5);
      case NodeType.blower:
        return const Color(0xFF37474F);
    }
  }

  Widget _buildWrapper({
    required Widget child,
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
  }) {
    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              onLongPress: onLongPress,
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              child: Container(
                width: node.size.width,
                height: node.size.height,
                padding: padding ?? const EdgeInsets.all(4),
                decoration: decoration ??
                    BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected || isConnectSource
                          ? Border.all(
                              color: isConnectSource ? Colors.orange : Colors.blue,
                              width: 2,
                            )
                          : null,
                    ),
                child: child,
              ),
            ),
            if (isSelected && onResizeUpdate != null)
              Positioned(
                right: -10,
                bottom: -10,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: onResizeStart,
                  onPanUpdate: onResizeUpdate,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 3),
                      ],
                    ),
                    child: const Icon(
                      Icons.open_in_full,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isConnectSource
        ? Colors.orange
        : (isSelected ? Colors.blue : Colors.grey.shade400);

    if (node.type == NodeType.pump) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CustomPaint(
          painter: DetailedPumpPainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.sump) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: SumpView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.well) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: WellView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.overheadTank) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: OverheadTankView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.naturalSource) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: NaturalSourceView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.mainFertilizerSource) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: MainFertilizerSourceView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.fertilizerTank) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: FertilizerTankView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.multiInjector) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: MultiInjectorView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.multiFilter) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: MultiFilterView(
          isOn: node.isOn,
          filter1IsBackwash: false,
          filter2IsBackwash: true,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.multiValve) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: MultiValveView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.singleMainValve) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: SingleMainValveView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.mainValve || node.type == NodeType.multiMainValve) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: MultiMainValveView(
          states: [node.isOn, node.isOn, node.isOn, node.isOn],
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.singleTankValve) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: SingleTankValveView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.multiOutletTankValve) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: MultiOutletTankValveView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.multiAgitator) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: MultiAgitatorView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
          outletPipeLength: node.outletPipeLength,
          outletSpacing: node.outletSpacing,
        ),
      );
    }

    if (node.type == NodeType.singleAgitator) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: SingleAgitatorView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.pressureSensor) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: PressureSensorView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.moistureSensor) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: MoistureSensorView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.waterMeter) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: WaterMeterView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          orientation: node.isHorizontal ? Axis.horizontal : Axis.vertical,
          size: node.size,
        ),
      );
    }

    if (node.type == NodeType.blower) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: BlowerView(
          isOn: node.isOn,
          showJoints: node.showJoints,
          size: node.size,
        ),
      );
    }

    return _buildWrapper(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: isSelected || isConnectSource ? 3 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, color: _iconColor, size: 26),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              node.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small draggable circular handle placed on a pipe bend point (waypoint)
/// or, in read-only style, on a port. Dragging it reshapes the pipe;
/// long-pressing it removes that bend point.
class WaypointHandle extends StatelessWidget {
  final Offset position;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragStartDetails)? onPanStart;
  final void Function(DragEndDetails)? onPanEnd;
  final VoidCallback onLongPress;
  final Color color;

  const WaypointHandle({
    super.key,
    required this.position,
    required this.onPanUpdate,
    this.onPanStart,
    this.onPanEnd,
    required this.onLongPress,
    this.color = const Color(0xFFFF9800),
  });

  static const double diameter = 16;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - diameter / 2,
      top: position.dy - diameter / 2,
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          onLongPress: onLongPress,
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)],
            ),
          ),
        ),
      ),
    );
  }
}
