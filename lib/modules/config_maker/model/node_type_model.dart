import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../widget/painter/blower_painter.dart';
import '../widget/painter/multi_agitator_painter.dart';
import '../widget/painter/multi_injector_painter.dart';


/// Type of equipment a node represents on the canvas.
enum NodeType {
  junction,
  pump,
  sump,
  well,
  overheadTank,
  naturalSource,
  mainFertilizerSource,
  fertilizerTank,
  multiInjector,
  multiFilter,
  multiValve,
  mainValve,
  multiMainValve,
  singleMainValve,
  singleTankValve,
  multiOutletTankValve,
  multiAgitator,
  singleAgitator,
  pressureSensor,
  waterMeter,
  moistureSensor,
  blower,
}

/// A draggable piece of equipment on the canvas (pump, tank, source, etc).
class NodeObject {
  String id;
  Offset position; // top-left corner in canvas coordinates
  Size size;
  NodeType type;
  String label;
  bool isOn; // relevant for pumps (running / stopped)
  bool showJoints; // toggle visibility of flange bolts and machine joints
  bool isBackwash; // relevant for multiFilter (filtering vs backwash cleaning)
  bool isHorizontal; // toggle orientation (false = vertical, true = horizontal)
  double outletPipeLength; // Vertical outlet pipe extension
  double outletSpacing; // Horizontal spacing factor between outlets (1.0 = default)
  int outletPortCount; // Number of outlet ports for multi-outlet nodes (e.g. multiOutletTankValve)
  List<String>? portLabels; // Specific labels for individual ports (e.g. tank valves on multiOutletTankValve)

  NodeObject({
    required this.id,
    required this.position,
    this.size = const Size(91, 63),
    required this.type,
    required this.label,
    this.isOn = true,
    this.showJoints = true,
    this.isBackwash = false,
    this.isHorizontal = false,
    this.outletPipeLength = 0.0,
    this.outletSpacing = 1.0,
    this.outletPortCount = 4,
    this.portLabels,
  });

  /// Connection point where pipes coming INTO this node should attach.
  Offset get inputPort {
    if (type == NodeType.pump) {
      final double s = math.min(size.width / 640, size.height / 380);
      final double tx = (size.width - 640 * s) / 2;
      final double ty = (size.height - 380 * s) / 2;
      return Offset(position.dx + tx + 38 * s, position.dy + ty + 176 * s);
    }
    if (type == NodeType.sump) {
      return Offset(position.dx, position.dy + size.height * 0.2);
    }
    if (type == NodeType.overheadTank) {
      return Offset(position.dx + size.width * 0.14, position.dy + size.height * 0.12);
    }
    if (type == NodeType.mainFertilizerSource) {
      return Offset(position.dx + size.width * 0.15, position.dy + size.height * 0.15);
    }
    if (type == NodeType.fertilizerTank) {
      return Offset(position.dx + size.width * (92 / 944), position.dy + size.height * (434 / 1132));
    }
    if (type == NodeType.multiInjector) {
      final p = DetailedMultiInjectorPainter.inletPort(size);
      return Offset(position.dx + p.dx, position.dy + p.dy);
    }
    if (type == NodeType.multiFilter) {
      return Offset(position.dx + size.width * 0.02, position.dy + size.height * 0.10);
    }
    if (type == NodeType.multiValve) {
      return Offset(position.dx + size.width * 0.04, position.dy + size.height * 0.258);
    }
    if (type == NodeType.multiAgitator) {
      final double leftX = 600.0 - 420.0 * outletSpacing;
      final double effH = DetailedMultiAgitatorPainter.effectiveRefHeight(outletPipeLength);
      return Offset(position.dx + size.width * (leftX / 1200), position.dy + size.height * (465 / effH));
    }
    if (type == NodeType.blower) {
      final p = DetailedBlowerPainter.outletPort(size);
      return Offset(position.dx + p.dx, position.dy + p.dy);
    }
    if (type == NodeType.waterMeter) {
      return isHorizontal
          ? Offset(position.dx, position.dy + size.height * 0.5)
          : Offset(position.dx + size.width * 0.5, position.dy);
    }
    if (type == NodeType.mainValve || type == NodeType.multiMainValve || type == NodeType.singleMainValve || type == NodeType.singleTankValve || type == NodeType.multiOutletTankValve) {
      return isHorizontal
          ? Offset(position.dx, position.dy + size.height * 0.5)
          : Offset(position.dx + size.width * 0.5, position.dy);
    }
    if (type == NodeType.singleAgitator || type == NodeType.pressureSensor || type == NodeType.moistureSensor) {
      return Offset(position.dx + size.width * 0.5, position.dy);
    }
    return Offset(position.dx, position.dy + size.height / 2);
  }

  /// Connection point where pipes going OUT of this node should attach.
  Offset get outputPort {
    if (type == NodeType.pump) {
      final double s = math.min(size.width / 640, size.height / 380);
      final double tx = (size.width - 640 * s) / 2;
      final double ty = (size.height - 380 * s) / 2;
      return Offset(position.dx + tx + 604 * s, position.dy + ty + 175 * s);
    }
    if (type == NodeType.sump) {
      return Offset(position.dx + size.width * 0.79, position.dy);
    }
    if (type == NodeType.well) {
      return Offset(position.dx + size.width * 0.595, position.dy);
    }
    if (type == NodeType.naturalSource) {
      return Offset(position.dx + size.width * 0.69, position.dy);
    }
    if (type == NodeType.overheadTank) {
      return Offset(position.dx + size.width * 0.5, position.dy + size.height * 0.95);
    }
    if (type == NodeType.mainFertilizerSource) {
      return Offset(position.dx + size.width * 0.85, position.dy + size.height * 0.82);
    }
    if (type == NodeType.fertilizerTank) {
      return Offset(position.dx + size.width * (500 / 944), position.dy + size.height * (968 / 1132));
    }
    if (type == NodeType.multiInjector) {
      final p = DetailedMultiInjectorPainter.outletPort(size);
      return Offset(position.dx + p.dx, position.dy + p.dy);
    }
    if (type == NodeType.multiFilter) {
      return Offset(position.dx + size.width * 0.98, position.dy + size.height * 0.867);
    }
    if (type == NodeType.multiValve) {
      return inputPort;
    }
    if (type == NodeType.multiAgitator) {
      final double rightX = 600.0 + 420.0 * outletSpacing;
      final double effH = DetailedMultiAgitatorPainter.effectiveRefHeight(outletPipeLength);
      return Offset(position.dx + size.width * (rightX / 1200), position.dy + size.height * (465 / effH));
    }
    if (type == NodeType.blower) {
      final p = DetailedBlowerPainter.outletPort(size);
      return Offset(position.dx + p.dx, position.dy + p.dy);
    }
    if (type == NodeType.waterMeter) {
      return isHorizontal
          ? Offset(position.dx + size.width, position.dy + size.height * 0.5)
          : Offset(position.dx + size.width * 0.5, position.dy + size.height);
    }
    if (type == NodeType.mainValve || type == NodeType.multiMainValve || type == NodeType.singleMainValve || type == NodeType.singleTankValve || type == NodeType.multiOutletTankValve) {
      return isHorizontal
          ? Offset(position.dx + size.width, position.dy + size.height * 0.5)
          : Offset(position.dx + size.width * 0.5, position.dy + size.height);
    }
    if (type == NodeType.singleAgitator || type == NodeType.pressureSensor || type == NodeType.moistureSensor) {
      return Offset(position.dx + size.width * 0.5, position.dy + size.height);
    }
    return Offset(position.dx + size.width, position.dy + size.height / 2);
  }

  /// Returns the specific port location by ID, or falls back to default
  /// input/output ports if ID is null or unknown.
  Offset getPort(String? portId, {required bool isInput}) {
    if (type == NodeType.pump) {
      if (portId == 'input' || (portId == null && isInput)) return inputPort;
      if (portId == 'output' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.sump) {
      if (portId == 'inlet' || (portId == null && isInput)) return inputPort;
      if (portId == 'outlet' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.overheadTank) {
      if (portId == 'inlet' || (portId == null && isInput)) return inputPort;
      if (portId == 'outlet' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.well) {
      if (portId == 'suction' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.naturalSource) {
      if (portId == 'intake' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.mainFertilizerSource) {
      if (portId == 'inlet' || (portId == null && isInput)) return inputPort;
      if (portId == 'outlet' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.fertilizerTank) {
      if (portId == 'top_inlet') {
        return Offset(position.dx + size.width * (500 / 944), position.dy + size.height * (32 / 1132));
      }
      if (portId == 'inlet' || portId == 'left_inlet' || (portId == null && isInput)) {
        return inputPort;
      }
      if (portId == 'outlet' || (portId == null && !isInput)) {
        return outputPort;
      }
    }
    if (type == NodeType.multiInjector) {
      if (portId != null && portId.startsWith('channel_')) {
        final int index = int.tryParse(portId.split('_').last) ?? 0;
        final p = DetailedMultiInjectorPainter.channelTopPort(size, index);
        return Offset(position.dx + p.dx, position.dy + p.dy);
      }
      if (portId == 'inlet' || (portId == null && isInput)) return inputPort;
      if (portId == 'outlet' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.multiFilter) {
      if (portId == 'backwash') {
        return Offset(position.dx + size.width * 0.02, position.dy + size.height * 0.217);
      }
      if (portId == 'inlet' || (portId == null && isInput)) return inputPort;
      if (portId == 'outlet' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.multiValve) {
      return inputPort;
    }
    if (type == NodeType.mainValve || type == NodeType.multiMainValve || type == NodeType.singleMainValve || type == NodeType.singleTankValve) {
      if (portId == 'inlet' || (portId == null && isInput)) return inputPort;
      if (portId == 'outlet' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.multiOutletTankValve) {
      if (portId != null && (portId.startsWith('channel_') || portId.startsWith('outlet_'))) {
        final int index = int.tryParse(portId.split('_').last) ?? 0;
        final int count = math.max(1, outletPortCount);
        if (isHorizontal) {
          final double step = size.height / count;
          return Offset(position.dx + size.width, position.dy + step * index + step / 2);
        } else {
          final double step = size.width / count;
          return Offset(position.dx + step * index + step / 2, position.dy + size.height);
        }
      }
      if (portId == 'inlet' || (portId == null && isInput)) return inputPort;
      if (portId == 'outlet' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.multiAgitator) {
      final double leftX = 600.0 - 420.0 * outletSpacing;
      final double rightX = 600.0 + 420.0 * outletSpacing;
      final double effH = DetailedMultiAgitatorPainter.effectiveRefHeight(outletPipeLength);
      final double ext = outletPipeLength.clamp(0.0, 500.0);
      if (portId == 'tank_left' || portId == 'tank_0') {
        return Offset(position.dx + size.width * (leftX / 1200), position.dy + size.height * ((640 + ext) / effH));
      }
      if (portId == 'tank_center' || portId == 'tank_1') {
        return Offset(position.dx + size.width * (600 / 1200), position.dy + size.height * ((640 + ext) / effH));
      }
      if (portId == 'tank_right' || portId == 'tank_2') {
        return Offset(position.dx + size.width * (rightX / 1200), position.dy + size.height * ((640 + ext) / effH));
      }
      if (portId == 'inlet' || portId == 'left_inlet' || (portId == null && isInput)) return inputPort;
      if (portId == 'outlet' || portId == 'right_outlet' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.singleAgitator) {
      if (portId == 'inlet' || (portId == null && isInput)) return inputPort;
      if (portId == 'outlet' || portId == 'bottom_outlet' || (portId == null && !isInput)) return outputPort;
    }
    if (type == NodeType.pressureSensor || type == NodeType.moistureSensor) {
      if (portId == 'top' || portId == 'inlet' || (portId == null && isInput)) {
        return inputPort;
      }
      if (portId == 'bottom' || portId == 'outlet' || (portId == null && !isInput)) {
        return outputPort;
      }
    }
    if (type == NodeType.blower) {
      return outputPort;
    }
    if (type == NodeType.waterMeter) {
      if (isHorizontal) {
        if (portId == 'left' || portId == 'inlet' || (portId == null && isInput)) {
          return inputPort;
        }
        if (portId == 'right' || portId == 'outlet' || (portId == null && !isInput)) {
          return outputPort;
        }
      } else {
        if (portId == 'top' || portId == 'inlet' || (portId == null && isInput)) {
          return inputPort;
        }
        if (portId == 'bottom' || portId == 'outlet' || (portId == null && !isInput)) {
          return outputPort;
        }
      }
    }
    return isInput ? inputPort : outputPort;
  }

  Offset get center =>
      Offset(position.dx + size.width / 2, position.dy + size.height / 2);

  /// Returns default size based on node type.
  Size get defaultSize {
    switch (type) {
      case NodeType.junction:
        return const Size(14, 14);
      case NodeType.mainFertilizerSource:
        return const Size(98, 70);
      case NodeType.fertilizerTank:
        return const Size(70, 84);
      case NodeType.multiInjector:
        return const Size(196, 112);
      case NodeType.multiFilter:
        return const Size(196, 118);
      case NodeType.multiValve:
        return const Size(210, 126);
      case NodeType.mainValve:
      case NodeType.multiMainValve:
        return const Size(154, 140);
      case NodeType.singleMainValve:
        return const Size(112, 84);
      case NodeType.singleTankValve:
        return const Size(56, 56);
      case NodeType.multiOutletTankValve:
        return Size(math.max(105.0, 35.0 * outletPortCount), 56);
      case NodeType.multiAgitator:
        return const Size(224, 126);
      case NodeType.singleAgitator:
        return const Size(84, 137);
      case NodeType.pressureSensor:
        return const Size(36, 36);
      case NodeType.moistureSensor:
        return const Size(42, 56);
      case NodeType.blower:
        return const Size(112, 105);
      case NodeType.waterMeter:
        return isHorizontal ? const Size(126, 84) : const Size(84, 126);
      case NodeType.overheadTank:
        return const Size(77, 91);
      case NodeType.sump:
      case NodeType.naturalSource:
      case NodeType.well:
        return const Size(91, 63);
      case NodeType.pump:
        return const Size(91, 63);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dx': position.dx,
        'dy': position.dy,
        'w': size.width,
        'h': size.height,
        'type': type.name,
        'label': label,
        'isOn': isOn,
        'showJoints': showJoints,
        'isBackwash': isBackwash,
        'isHorizontal': isHorizontal,
        'outletPipeLength': outletPipeLength,
        'outletSpacing': outletSpacing,
        'outletPortCount': outletPortCount,
      };

  factory NodeObject.fromJson(Map<String, dynamic> j) {
    final String rawType = j['type'] as String;
    final NodeType nodeType = rawType == 'mainValve'
        ? NodeType.multiMainValve
        : (rawType == 'multiTankValve'
            ? NodeType.multiOutletTankValve
            : NodeType.values.byName(rawType));
    return NodeObject(
      id: j['id'] as String,
      position: Offset((j['dx'] as num).toDouble(), (j['dy'] as num).toDouble()),
      size: Size((j['w'] as num?)?.toDouble() ?? 91, (j['h'] as num?)?.toDouble() ?? 63),
      type: nodeType,
      label: j['label'] as String,
      isOn: j['isOn'] as bool? ?? true,
      showJoints: j['showJoints'] as bool? ?? true,
      isBackwash: j['isBackwash'] as bool? ?? false,
      isHorizontal: j['isHorizontal'] as bool? ?? false,
      outletPipeLength: (j['outletPipeLength'] as num?)?.toDouble() ?? 0.0,
      outletSpacing: (j['outletSpacing'] as num?)?.toDouble() ?? 1.0,
      outletPortCount: (j['outletPortCount'] as num?)?.toInt() ?? 4,
    );
  }
}

/// A pipe joining two nodes. [waypoints] are the user-created bend points
/// between the start node's output port and the end node's input port -
/// dragging them bends the pipe, adding/removing them changes its shape
/// and effective length.
class PipeConnection {
  String id;
  String fromNodeId;
  String toNodeId;
  List<Offset> waypoints;
  bool flowActive;

  // Added port identifiers to allow connecting to specific ports (e.g. suction vs discharge on a pump)
  String? fromPortId;
  String? toPortId;

  PipeConnection({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    List<Offset>? waypoints,
    this.flowActive = true,
    this.fromPortId,
    this.toPortId,
  }) : waypoints = waypoints ?? <Offset>[];

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': fromNodeId,
        'to': toNodeId,
        'flowActive': flowActive,
        'fromPortId': fromPortId,
        'toPortId': toPortId,
        'waypoints':
            waypoints.map((w) => {'dx': w.dx, 'dy': w.dy}).toList(growable: false),
      };

  factory PipeConnection.fromJson(Map<String, dynamic> j) => PipeConnection(
        id: j['id'] as String,
        fromNodeId: j['from'] as String,
        toNodeId: j['to'] as String,
        flowActive: j['flowActive'] as bool? ?? true,
        fromPortId: j['fromPortId'] as String?,
        toPortId: j['toPortId'] as String?,
        waypoints: (j['waypoints'] as List)
            .map((w) => Offset(
                ((w as Map)['dx'] as num).toDouble(), (w['dy'] as num).toDouble()))
            .toList(),
      );
}
