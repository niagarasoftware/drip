import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state_management/config_maker_provider.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/blower_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/ec_sensor_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/fertilizer_tank_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/main_fertilizer_source_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/moisture_sensor_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_agitator_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_filter_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_fogger_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_injector_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_main_valve_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_outlet_tank_valve_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/multi_valve_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/natural_source_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/over_head_tank_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/ph_sensor_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/pressure_sensor_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/soil_temperature_sensor_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/pump_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/single_agitator_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/single_main_valve_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/single_tank_valve_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/sump_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/water_meter_painter.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/painter/well_painter.dart';
import '../model/node_type_model.dart';
import '../model/irrigation_line_model.dart';

String _getDeviceName(double sNo, ConfigMakerProvider configPvd) {
  for (final obj in configPvd.listOfGeneratedObject) {
    if (obj.sNo == sNo) {
      if (obj.name != null && obj.name!.isNotEmpty && obj.name != '-') {
        return obj.name!;
      }
    }
  }
  for (final v in configPvd.valveConfig) {
    if (v.commonDetails.sNo == sNo) {
      if (v.commonDetails.name != null && v.commonDetails.name!.isNotEmpty && v.commonDetails.name != '-') {
        return v.commonDetails.name!;
      }
    }
  }
  String sNoStr = sNo.toString();
  if (sNoStr.endsWith('.0')) {
    sNoStr = sNo.toInt().toString();
  }
  return sNoStr;
}

IrrigationLineModel? _findLineForNode(NodeObject node, ConfigMakerProvider configPvd) {
  if (configPvd.line.isEmpty) return null;

  final match = RegExp(r'line_(\d+)').firstMatch(node.id);
  if (match != null) {
    final idx = int.tryParse(match.group(1)!);
    if (idx != null && idx >= 0 && idx < configPvd.line.length) {
      return configPvd.line[idx];
    }
  }

  for (int i = 0; i < configPvd.line.length; i++) {
    final lName = configPvd.line[i].commonDetails.name;
    if (lName != null && lName.isNotEmpty && lName != '-' && node.label.contains(lName)) {
      return configPvd.line[i];
    }
  }

  return null;
}


class NodeImageCache {
  static final Map<String, ui.Image> _cache = {};

  static ui.Image renderAndCache(
      String key,
      CustomPainter painter,
      Size size, {
        double devicePixelRatio = 4.0,
      }) {
    final existing = _cache[key];
    if (existing != null) return existing;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(devicePixelRatio, devicePixelRatio);
    painter.paint(canvas, size);
    final picture = recorder.endRecording();
    final w = (size.width * devicePixelRatio).ceil().clamp(1, 4000);
    final h = (size.height * devicePixelRatio).ceil().clamp(1, 4000);
    final image = picture.toImageSync(w, h);
    _cache[key] = image;
    return image;
  }

  static void clear() {
    for (final img in _cache.values) {
      img.dispose();
    }
    _cache.clear();
  }
}

class CachedNodePainterWidget extends StatelessWidget {
  final String cacheKey;
  final CustomPainter painter;
  final Size size;
  final ValueListenable<bool>? simplify;

  const CachedNodePainterWidget({
    super.key,
    required this.cacheKey,
    required this.painter,
    required this.size,
    this.simplify,
  });

  @override
  Widget build(BuildContext context) {
    if (simplify == null) {
      return _buildImage(context);
    }
    return ValueListenableBuilder<bool>(
      valueListenable: simplify!,
      builder: (context, isLite, _) {
        if (!isLite) {
          return CustomPaint(
            size: size,
            painter: painter,
          );
        }
        return _buildImage(context);
      },
    );
  }

  Widget _buildImage(BuildContext context) {
    final double dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 3.0;
    final double ratio = math.max(4.0, dpr * 1.5);
    final String fullKey = '${cacheKey}_r${ratio.toStringAsFixed(1)}';
    final ui.Image cachedImage = NodeImageCache.renderAndCache(
      fullKey,
      painter,
      size,
      devicePixelRatio: ratio,
    );
    return RawImage(
      image: cachedImage,
      width: size.width,
      height: size.height,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
    );
  }
}

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
  final void Function(int channelIndex)? onChannelToggle;
  final ValueListenable<bool>? simplify;

  /// When false the parent positions this widget (so a pure move does not
  /// rebuild or repaint the node artwork).
  final bool applyPosition;

  const NodeWidget({
    super.key,
    required this.node,
    required this.onTap,
    required this.onLongPress,
    required this.onPanUpdate,
    this.onPanStart,
    this.onResizeUpdate,
    this.onResizeStart,
    this.onChannelToggle,
    this.isSelected = false,
    this.isConnectSource = false,
    this.simplify,
    this.applyPosition = true,
  });

  IconData get _icon {
    switch (node.type) {
      case NodeType.junction:
        return Icons.circle;
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
      case NodeType.ecSensor:
        return Icons.bolt;
      case NodeType.phSensor:
        return Icons.science;
      case NodeType.soilTemperatureSensor:
        return Icons.thermostat;
      case NodeType.waterMeter:
        return Icons.water_drop;
      case NodeType.blower:
        return Icons.air;
      case NodeType.multiFogger:
        return Icons.cloud;
      case NodeType.lineHeader:
        return Icons.label;

    }
  }

  Color get _iconColor {
    switch (node.type) {
      case NodeType.junction:
        return const Color(0xFF455A64);
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
      case NodeType.ecSensor:
        return const Color(0xFF00838F);
      case NodeType.phSensor:
        return const Color(0xFFD84315);
      case NodeType.soilTemperatureSensor:
        return const Color(0xFFD32F2F);
      case NodeType.waterMeter:
        return const Color(0xFF2F6FB5);
      case NodeType.blower:
        return const Color(0xFF37474F);
      case NodeType.multiFogger:
        return const Color(0xFF0288D1);
      case NodeType.lineHeader:
        return const Color(0xFF10B981);
    }
  }

  Widget _buildWrapper({
    required Widget child,
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
  }) {
    final bool showNameBadge =
        node.type != NodeType.junction && node.label.trim().isNotEmpty;

    final Widget body = RepaintBoundary(
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
          if (node.type == NodeType.multiInjector)
            ...List.generate(DetailedMultiInjectorPainter.channelCount, (i) {
              // Same rect the painter draws -> tap target matches the button.
              final Rect r =
              DetailedMultiInjectorPainter.channelButtonRect(node.size, i)
                  .inflate(4);
              return Positioned(
                left: r.left,
                top: r.top,
                width: r.width,
                height: r.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (onChannelToggle != null) {
                      onChannelToggle!(i);
                    } else {
                      node.toggleChannel(i);
                      onTap();
                    }
                  },
                  child: const SizedBox.expand(),
                ),
              );
            }),
          if (showNameBadge &&
              node.type != NodeType.singleTankValve &&
              node.type != NodeType.multiOutletTankValve &&
              node.type != NodeType.multiValve)
            Positioned(
              bottom: (node.type == NodeType.ecSensor || node.type == NodeType.phSensor || node.type == NodeType.soilTemperatureSensor)
                  ? -22
                  : -16,
              left: -20,
              right: -20,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  onLongPress: onLongPress,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xEE0F172A),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.shade400
                            : (isConnectSource
                            ? Colors.orangeAccent
                            : const Color(0x33FFFFFF)),
                        width: isSelected || isConnectSource ? 1.2 : 0.8,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 3.5,
                          height: 3.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: node.isOn
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 3.5),
                        Flexible(
                          child: Text(
                            node.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (isSelected && onResizeUpdate != null)
            Positioned(
              right: -10,
              bottom: (node.type == NodeType.ecSensor || node.type == NodeType.phSensor || node.type == NodeType.soilTemperatureSensor)
                  ? -22
                  : -16,
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
    );
    if (!applyPosition) return body;
    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isConnectSource
        ? Colors.orange
        : (isSelected ? Colors.blue : Colors.grey.shade400);

    final String szKey = '${node.size.width.toInt()}x${node.size.height.toInt()}';

    if (node.type == NodeType.pump) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'pump_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
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
        child: CachedNodePainterWidget(
          cacheKey: 'sump_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedSumpPainter(
            isOn: node.isOn,
            phase: 0.0,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.well) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'well_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedWellPainter(
            isOn: node.isOn,
            phase: 0.0,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.overheadTank) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'overhead_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedOverheadTankPainter(
            isOn: node.isOn,
            phase: 0.0,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.naturalSource) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'natural_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedNaturalSourcePainter(
            isOn: node.isOn,
            phase: 0.0,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.mainFertilizerSource) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'main_fert_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedMainFertilizerSourcePainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.fertilizerTank) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'fert_tank_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedFertilizerTankPainter(
            isOn: node.isOn,
            phase: 0.0,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.multiInjector) {
      // IMPORTANT: copy the list. If the model mutates its list in place the
      // old and new painter would share one instance, listEquals() would say
      // "unchanged" and the live painter would never repaint.
      final List<bool> chStates = List<bool>.of(node.activeChannelStates);
      final String chKey = chStates.map((e) => e ? '1' : '0').join();
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'multi_inj_v5_${node.isOn}_${node.showJoints}_${chKey}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedMultiInjectorPainter(
            isOn: node.isOn,
            phase: 0.0,
            showJoints: node.showJoints,
            channelStates: chStates,
          ),
        ),
      );
    }

    if (node.type == NodeType.multiFilter) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'multi_filter_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedMultiFilterPainter(
            isOn: node.isOn,
            filter1IsBackwash: false,
            filter2IsBackwash: true,
            phase: 0.0,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.lineHeader) {
      int lineIdx = 0;
      final match = RegExp(r'line_header_(\d+)').firstMatch(node.id);
      if (match != null) {
        lineIdx = int.tryParse(match.group(1)!) ?? 0;
      }

      const List<Color> lineColors = [
        Color(0xFF10B981), // Emerald Green
        Color(0xFF3B82F6), // Royal Blue
        Color(0xFFF59E0B), // Amber Orange
        Color(0xFF8B5CF6), // Purple Violet
        Color(0xFFF43F5E), // Rose Pink
        Color(0xFF06B6D4), // Cyan Sky
      ];
      final Color accentColor = lineColors[lineIdx % lineColors.length];

      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xEE0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.8),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  node.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 0.8),
                ),
                child: Text(
                  'LINE ${lineIdx + 1}',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (node.type == NodeType.multiValve) {
      int effectiveValves = node.outletPortCount;
      List<String> valveNames = [];
      try {
        final configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);

        if (node.portLabels != null && node.portLabels!.isNotEmpty) {
          valveNames = node.portLabels!;
          effectiveValves = valveNames.length;
        } else {
          final lineModel = _findLineForNode(node, configPvd);
          if (lineModel != null) {
            effectiveValves = lineModel.valve.length;
            for (final double vSno in lineModel.valve) {
              valveNames.add(_getDeviceName(vSno, configPvd));
            }
          } else if (configPvd.line.isNotEmpty) {
            effectiveValves = configPvd.line.fold<int>(0, (sum, l) => sum + l.valve.length);
          }
        }

        node.outletPortCount = effectiveValves;
        final double targetW = math.max(120.0, 70.0 * effectiveValves + 40.0);
        if (node.size.width != targetW) {
          node.size = Size(targetW, 200);
        }
      } catch (_) {}

      if (effectiveValves <= 0) return const SizedBox.shrink();

      final String vNamesKey = valveNames.join('_');
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'multi_valve_${node.id}_${node.isOn}_${node.showJoints}_${effectiveValves}_${vNamesKey}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedMultiValvePainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
            valves: effectiveValves,
            valveNames: valveNames,
          ),
        ),
      );
    }

    if (node.type == NodeType.singleMainValve) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'single_main_valve_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedSingleMainValvePainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.mainValve || node.type == NodeType.multiMainValve) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'multi_main_valve_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedMultiMainValvePainter(
            valves: [node.isOn, node.isOn, node.isOn, node.isOn],
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.singleTankValve) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'single_tank_valve_${node.isOn}_${node.showJoints}_${node.isHorizontal}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedSingleTankValvePainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
            isHorizontal: node.isHorizontal,
          ),
        ),
      );
    }

    if (node.type == NodeType.multiOutletTankValve) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'multi_outlet_tank_valve_${node.isOn}_${node.showJoints}_${node.isHorizontal}_${node.outletPortCount}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedMultiOutletTankValvePainter(
            states: List.generate(node.outletPortCount, (_) => node.isOn),
            showJoints: node.showJoints,
            isHorizontal: node.isHorizontal,
          ),
        ),
      );
    }

    if (node.type == NodeType.multiAgitator) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'multi_agitator_${node.isOn}_${node.showJoints}_${node.outletPipeLength}_${node.outletSpacing}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedMultiAgitatorPainter(
            isOn: node.isOn,
            phase: 0.0,
            showJoints: node.showJoints,
            outletPipeLength: node.outletPipeLength,
            outletSpacing: node.outletSpacing,
          ),
        ),
      );
    }

    if (node.type == NodeType.singleAgitator) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'single_agitator_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedSingleAgitatorPainter(
            isOn: node.isOn,
            phase: 0.0,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.pressureSensor) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'pressure_sensor_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedPressureSensorPainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.moistureSensor) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'moisture_sensor_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedMoistureSensorPainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.ecSensor) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'ec_sensor_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedEcSensorPainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.phSensor) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'ph_sensor_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedPhSensorPainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.soilTemperatureSensor) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'soil_temp_sensor_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedSoilTemperatureSensorPainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
          ),
        ),
      );
    }

    if (node.type == NodeType.waterMeter) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'water_meter_${node.isOn}_${node.showJoints}_${node.isHorizontal}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedWaterMeterPainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
            orientation: node.isHorizontal ? Axis.horizontal : Axis.vertical,
          ),
        ),
      );
    }

    if (node.type == NodeType.blower) {
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'blower_${node.isOn}_${node.showJoints}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedBlowerPainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
            phase: 0.0,
            speed: node.isOn ? 1.0 : 0.0,
          ),
        ),
      );
    }

    if (node.type == NodeType.multiFogger) {
      int effectiveFoggers = node.outletPortCount;
      List<String> foggerNames = [];
      try {
        final configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
        final lineModel = _findLineForNode(node, configPvd);

        if (lineModel != null) {
          effectiveFoggers = lineModel.fogger.length;
          for (final double fSno in lineModel.fogger) {
            foggerNames.add(_getDeviceName(fSno, configPvd));
          }
        } else if (configPvd.line.isNotEmpty) {
          effectiveFoggers = configPvd.line.fold<int>(0, (sum, l) => sum + l.fogger.length);
        }

        node.outletPortCount = effectiveFoggers;
        final double targetW = math.max(100.0, 50.0 * effectiveFoggers + 20.0);
        if (node.size.width != targetW) {
          node.size = Size(targetW, 125);
        }
      } catch (_) {}

      if (effectiveFoggers <= 0) return const SizedBox.shrink();

      final String fNamesKey = foggerNames.join('_');
      return _buildWrapper(
        padding: EdgeInsets.zero,
        child: CachedNodePainterWidget(
          cacheKey: 'multi_fogger_${node.id}_${node.isOn}_${node.showJoints}_${effectiveFoggers}_${fNamesKey}_$szKey',
          size: node.size,
          simplify: simplify,
          painter: DetailedMultiFoggerPainter(
            isOn: node.isOn,
            showJoints: node.showJoints,
            foggers: effectiveFoggers,
            foggerNames: foggerNames,
          ),
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