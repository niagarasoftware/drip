import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/device_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/device_object_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/irrigation_line_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';

import '../../../Constants/dialog_boxes.dart';
import '../../../utils/constants.dart';
import '../../../Widgets/sized_image.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/config_template_widgets.dart';
import '../widget/object_manager_bar.dart';
import 'config_object_name_editing.dart';

/// Simple holder for progress metrics.
class _Progress {
  final int filled;
  final int total;
  final int sensorFilled;
  const _Progress(this.filled, this.total, this.sensorFilled);

  bool get complete => total > 0 && filled == total;
  double get fraction => total == 0 ? 0 : filled / total;
}

class LineConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const LineConfiguration({super.key, required this.configPvd});

  @override
  State<LineConfiguration> createState() => _LineConfigurationState();
}

class _LineConfigurationState extends State<LineConfiguration> {
  // ── Design tokens (Matching SourceConfiguration Dark Mode) ──
  static const Color _sourceColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _valveColor = Color(0xFF059669); // emerald green
  static const Color _fertColor = Color(0xFFEA580C); // orange
  static const Color _sensorColor = Color(0xFF0EA5E9); // ocean blue
  static const Color _envColor = Color(0xFF7C3AED); // purple
  static const Color _doneColor = Color(0xFF059669); // emerald green

  bool availability(int objectId) {
    return widget.configPvd.listOfSampleObjectModel.any(
        (object) => (object.objectId == objectId && object.count != '0'));
  }

  // ───────────────────────────────────────────────────────────
  //  PROGRESS CALCULATION
  // ───────────────────────────────────────────────────────────
  _Progress _calcProgress(IrrigationLineModel line) {
    int total = 0;
    int filled = 0;

    void checkList(bool isAvailable, List<double> list) {
      if (isAvailable) {
        total++;
        if (list.isNotEmpty) filled++;
      }
    }

    void checkScalar(bool isAvailable, double val) {
      if (isAvailable) {
        total++;
        if (val != 0.0) filled++;
      }
    }

    if (availability(AppConstants.sourceObjectId) &&
        !AppConstants.aquacultureModelList.contains(widget.configPvd.masterData['modelId'])) {
      checkList(true, line.waterSource);
    }
    if (widget.configPvd.pump.any((p) => p.pumpType == 1)) checkList(true, line.sourcePump);
    if (widget.configPvd.pump.any((p) => p.pumpType == 2)) checkList(true, line.irrigationPump);
    if (widget.configPvd.pump.any((p) => p.pumpType == 3)) checkList(true, line.aerator);

    checkList(availability(AppConstants.valveObjectId), line.valve);
    checkList(availability(AppConstants.mainValveObjectId), line.mainValve);
    checkList(availability(AppConstants.flowControlValveObjectId), line.flowControlValve);

    checkScalar(availability(AppConstants.fertilizerSiteObjectId), line.centralFertilization);
    checkScalar(availability(AppConstants.fertilizerSiteObjectId), line.localFertilization);
    checkScalar(availability(AppConstants.filterSiteObjectId), line.centralFiltration);
    checkScalar(availability(AppConstants.filterSiteObjectId), line.localFiltration);

    checkScalar(availability(AppConstants.waterMeterObjectId), line.waterMeter);
    checkScalar(availability(AppConstants.analogWaterMeterObjectId), line.analogWaterMeter);
    checkScalar(availability(AppConstants.pressureSensorObjectId), line.pressureIn);
    checkScalar(availability(AppConstants.pressureSensorObjectId), line.pressureOut);

    return _Progress(filled, total, filled);
  }

  void _addLine() {
    final p = widget.configPvd;
    DeviceObjectModel? sampleObj;
    for (var o in p.listOfSampleObjectModel) {
      if (o.objectId == AppConstants.irrigationLineObjectId) {
        sampleObj = o;
        break;
      }
    }
    if (sampleObj == null) {
      sampleObj = DeviceObjectModel(
        objectId: AppConstants.irrigationLineObjectId,
        objectName: 'Irrigation Line',
        type: '-',
        count: '0',
        assignObject: [],
      );
      p.listOfSampleObjectModel.add(sampleObj);
    }

    int currentCount = 0;
    if (sampleObj.count != null && sampleObj.count != '') {
      currentCount = int.tryParse(sampleObj.count!) ?? 0;
    }

    int? cap = maxCountForObject(p, sampleObj);

    if (cap != null && currentCount + 1 > cap) {
      simpleDialogBox(
        context: context,
        title: 'Alert',
        message: 'Only $cap Irrigation Line can be added for this master controller model.',
      );
      return;
    }

    setState(() {
      p.updateObjectCount(AppConstants.irrigationLineObjectId, '${currentCount + 1}');
    });
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final lines = widget.configPvd.line;

    return Container(
      color: const Color(0xFF0C0F1D),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ConfigPageHeading(
                      title: 'Line configuration',
                      subtitle: 'Configure pumps, valves, filtration, fertilization and sensors for irrigation lines',
                      totalCount: lines.length,
                      countUnitSingular: 'line',
                      countUnitPlural: 'lines',
                      primaryColor: primaryColor,
                      icon: Icons.alt_route_rounded,
                      onAddPressed: _addLine,
                      addButtonLabel: 'Add Line',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        isScrollControlled: true,
                        context: context,
                        builder: (context) {
                          return SizedBox(
                            width: 700,
                            child: ConfigObjectNameEditing(
                              listOfObjectInLine: widget.configPvd.listOfGeneratedObject,
                              configPvd: widget.configPvd,
                            ),
                          );
                        },
                      );
                    },
                    tooltip: 'Edit Object Names',
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181C38),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF20274B)),
                      ),
                      child: const Icon(Icons.dataset_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (lines.isEmpty)
                ConfigEmptyState(
                  title: 'No Irrigation Lines Added',
                  subtitle: 'Tap the button below to add an irrigation line to your configuration.',
                  icon: Icons.alt_route_rounded,
                  primaryColor: primaryColor,
                  onAddPressed: _addLine,
                  buttonLabel: 'Add Line',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lines.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    return _buildLineCard(line, primaryColor);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelGradientButton({
    required VoidCallback onTap,
    String tooltip = 'Delete',
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEF4444),
                  Color(0xFFB91C1C),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete({
    required BuildContext context,
    required String itemName,
    required VoidCallback onDelete,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF181C38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF2B335C)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Delete $itemName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to delete "$itemName"? This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF8E9BB4),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8E9BB4),
                            side: const BorderSide(color: Color(0xFF2B335C)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────
  //  LINE HEADER BLOCK
  // ───────────────────────────────────────────────────────────
  Widget _buildLineHeaderBlock({
    required IrrigationLineModel line,
    required _Progress progress,
    required Color primaryColor,
  }) {
    final remaining = progress.total - progress.filled;
    final itemName = line.commonDetails.name ?? 'Irrigation Line';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF181C38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF252D54)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withValues(alpha: 0.25),
                  primaryColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.35),
              ),
            ),
            child: SizedImage(
              imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.irrigationLineObjectId}.svg',
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  progress.complete
                      ? 'All parameters configured'
                      : progress.total == 0
                          ? 'No parameters available'
                          : '$remaining left to assign',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: progress.complete ? _doneColor : const Color(0xFF8E9BB4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildCancelGradientButton(
            onTap: () {
              _confirmDelete(
                context: context,
                itemName: itemName,
                onDelete: () {
                  setState(() {
                    widget.configPvd.deleteGeneratedObject(
                      line.commonDetails.sNo!,
                      AppConstants.irrigationLineObjectId,
                    );
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  BODY GRID (2-column on wide screens, 1-column on narrow)
  // ───────────────────────────────────────────────────────────
  Widget _buildBodyGrid(List<Widget> bodyItems, {required bool wide}) {
    if (bodyItems.isEmpty) return const SizedBox();

    if (wide) {
      final rows = <Widget>[];
      for (var i = 0; i < bodyItems.length; i += 2) {
        final hasPair = i + 1 < bodyItems.length;
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: bodyItems[i]),
                if (hasPair) ...[
                  const SizedBox(width: 10),
                  Expanded(child: bodyItems[i + 1]),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withGaps(rows, 10),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withGaps(bodyItems, 10),
      );
    }
  }

  List<Widget> _withGaps(List<Widget> items, double gap) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(items[i]);
    }
    return out;
  }

  // ───────────────────────────────────────────────────────────
  //  LINE CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildLineCard(IrrigationLineModel line, Color primaryColor) {
    final progress = _calcProgress(line);

    final sourceAndPumpTiles = <Widget>[
      if (availability(AppConstants.sourceObjectId) &&
          !AppConstants.aquacultureModelList.contains(widget.configPvd.masterData['modelId']))
        _buildListTile(
          line: line,
          title: 'Source only for monitoring',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.sourceObjectId}.svg',
          parameterType: LineParameter.source,
          objectId: AppConstants.sourceObjectId,
          currentParameterValue: line.waterSource,
          validateAllLine: false,
          accent: _sourceColor,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((o) => o.objectId == AppConstants.sourceObjectId)
              .toList(),
        ),
      if (widget.configPvd.pump.any((p) => p.pumpType == 1))
        _buildListTile(
          line: line,
          title: 'Source Pump',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.pumpObjectId}.svg',
          parameterType: LineParameter.sourcePump,
          objectId: AppConstants.pumpObjectId,
          currentParameterValue: line.sourcePump,
          validateAllLine: false,
          accent: _sourceColor,
          listOfObject: widget.configPvd.listOfGeneratedObject.where((pumpObject) {
            return widget.configPvd.pump
                .any((pump) => pump.commonDetails.sNo == pumpObject.sNo && pump.pumpType == 1);
          }).toList(),
        ),
      if (widget.configPvd.pump.any((p) => p.pumpType == 2))
        _buildListTile(
          line: line,
          title: 'Irrigation Pump',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.pumpObjectId}.svg',
          parameterType: LineParameter.irrigationPump,
          objectId: AppConstants.pumpObjectId,
          currentParameterValue: line.irrigationPump,
          validateAllLine: false,
          accent: _sourceColor,
          listOfObject: widget.configPvd.listOfGeneratedObject.where((pumpObject) {
            return widget.configPvd.pump
                .any((pump) => pump.commonDetails.sNo == pumpObject.sNo && pump.pumpType == 2);
          }).toList(),
        ),
      if (widget.configPvd.pump.any((p) => p.pumpType == 3))
        _buildListTile(
          line: line,
          title: 'Aerator Pump',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.pumpObjectId}.svg',
          parameterType: LineParameter.aerator,
          objectId: AppConstants.pumpObjectId,
          currentParameterValue: line.aerator,
          validateAllLine: false,
          accent: _sourceColor,
          listOfObject: widget.configPvd.listOfGeneratedObject.where((pumpObject) {
            return widget.configPvd.pump
                .any((pump) => pump.commonDetails.sNo == pumpObject.sNo && pump.pumpType == 3);
          }).toList(),
        ),
    ];

    final valveAndControlTiles = <Widget>[
      if (availability(AppConstants.valveObjectId))
        _buildListTile(
          line: line,
          title: 'Valve',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.valveObjectId}.svg',
          parameterType: LineParameter.valve,
          objectId: AppConstants.valveObjectId,
          currentParameterValue: line.valve,
          validateAllLine: true,
          accent: _valveColor,
        ),
      if (availability(AppConstants.flowControlValveObjectId))
        _buildListTile(
          line: line,
          title: 'Flow Control Valve',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.flowControlValveObjectId}.svg',
          parameterType: LineParameter.flowControlValve,
          objectId: AppConstants.flowControlValveObjectId,
          currentParameterValue: line.flowControlValve,
          validateAllLine: true,
          accent: _valveColor,
        ),
      if (availability(AppConstants.mainValveObjectId))
        _buildListTile(
          line: line,
          title: 'Main Valve',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.mainValveObjectId}.svg',
          parameterType: LineParameter.mainValve,
          objectId: AppConstants.mainValveObjectId,
          currentParameterValue: line.mainValve,
          validateAllLine: true,
          accent: _valveColor,
        ),
      if (availability(AppConstants.gateObjectId))
        _buildListTile(
          line: line,
          title: 'Gate',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.gateObjectId}.svg',
          parameterType: LineParameter.gate,
          objectId: AppConstants.gateObjectId,
          currentParameterValue: line.gate,
          validateAllLine: true,
          accent: _valveColor,
        ),
    ];

    final fertFilterTiles = <Widget>[
      if (availability(AppConstants.fertilizerSiteObjectId))
        _buildScalarTile(
          line: line,
          title: 'Central Fertilization',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.fertilizerSiteObjectId}.svg',
          parameterType: LineParameter.centralFertilization,
          objectId: AppConstants.fertilizerSiteObjectId,
          currentValue: line.centralFertilization,
          validateAllLine: false,
          accent: _fertColor,
          listOfObject: widget.configPvd.fertilization
              .where((site) => site.siteMode == 1)
              .map((site) => site.commonDetails)
              .toList(),
        ),
      if (availability(AppConstants.fertilizerSiteObjectId))
        _buildScalarTile(
          line: line,
          title: 'Local Fertilization',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.fertilizerSiteObjectId}.svg',
          parameterType: LineParameter.localFertilization,
          objectId: AppConstants.fertilizerSiteObjectId,
          currentValue: line.localFertilization,
          validateAllLine: false,
          accent: _fertColor,
          listOfObject: widget.configPvd.fertilization
              .where((site) => site.siteMode == 2)
              .map((site) => site.commonDetails)
              .toList(),
        ),
      if (availability(AppConstants.filterSiteObjectId))
        _buildScalarTile(
          line: line,
          title: 'Central Filtration',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.filterSiteObjectId}.svg',
          parameterType: LineParameter.centralFiltration,
          objectId: AppConstants.filterSiteObjectId,
          currentValue: line.centralFiltration,
          validateAllLine: false,
          accent: _fertColor,
          listOfObject: widget.configPvd.filtration
              .where((site) => site.siteMode == 1)
              .map((site) => site.commonDetails)
              .toList(),
        ),
      if (availability(AppConstants.filterSiteObjectId))
        _buildScalarTile(
          line: line,
          title: 'Local Filtration',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.filterSiteObjectId}.svg',
          parameterType: LineParameter.localFiltration,
          objectId: AppConstants.filterSiteObjectId,
          currentValue: line.localFiltration,
          validateAllLine: false,
          accent: _fertColor,
          listOfObject: widget.configPvd.filtration
              .where((site) => site.siteMode == 2)
              .map((site) => site.commonDetails)
              .toList(),
        ),
    ];

    final sensorMeterTiles = <Widget>[
      if (availability(AppConstants.waterMeterObjectId))
        _buildScalarTile(
          line: line,
          title: 'Water Meter',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.waterMeterObjectId}.svg',
          parameterType: LineParameter.waterMeter,
          objectId: AppConstants.waterMeterObjectId,
          currentValue: line.waterMeter,
          validateAllLine: true,
          accent: _sensorColor,
        ),
      if (availability(AppConstants.analogWaterMeterObjectId))
        _buildScalarTile(
          line: line,
          title: 'Analog Water Meter',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.analogWaterMeterObjectId}.svg',
          parameterType: LineParameter.analogWaterMeter,
          objectId: AppConstants.analogWaterMeterObjectId,
          currentValue: line.analogWaterMeter,
          validateAllLine: true,
          accent: _sensorColor,
        ),
      if (availability(AppConstants.pressureSensorObjectId))
        _buildScalarTile(
          line: line,
          title: 'Pressure In',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.pressureSensorObjectId}.svg',
          parameterType: LineParameter.pressureIn,
          objectId: AppConstants.pressureSensorObjectId,
          currentValue: line.pressureIn,
          validateAllLine: true,
          accent: _sensorColor,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) =>
                  (object.objectId == AppConstants.pressureSensorObjectId && object.sNo != line.pressureOut))
              .where((object) => (!widget.configPvd.line.any((l) =>
                      l.commonDetails.sNo != line.commonDetails.sNo &&
                      [l.pressureIn, l.pressureOut].contains(object.sNo)) &&
                  object.sNo != line.pressureOut))
              .toList(),
        ),
      if (availability(AppConstants.pressureSensorObjectId))
        _buildScalarTile(
          line: line,
          title: 'Pressure Out',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.pressureSensorObjectId}.svg',
          parameterType: LineParameter.pressureOut,
          objectId: AppConstants.pressureSensorObjectId,
          currentValue: line.pressureOut,
          validateAllLine: true,
          accent: _sensorColor,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) =>
                  (object.objectId == AppConstants.pressureSensorObjectId && object.sNo != line.pressureIn))
              .where((object) => (!widget.configPvd.line.any((l) =>
                      l.commonDetails.sNo != line.commonDetails.sNo &&
                      [l.pressureIn, l.pressureOut].contains(object.sNo)) &&
                  object.sNo != line.pressureIn))
              .toList(),
        ),
      if (availability(AppConstants.powerSupplyObjectId))
        _buildScalarTile(
          line: line,
          title: 'Power Supply',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.powerSupplyObjectId}.svg',
          parameterType: LineParameter.powerSupply,
          objectId: AppConstants.powerSupplyObjectId,
          currentValue: line.powerSupply,
          validateAllLine: true,
          accent: _sensorColor,
        ),
      if (availability(AppConstants.pressureSwitchObjectId))
        _buildScalarTile(
          line: line,
          title: 'Pressure Switch',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.pressureSwitchObjectId}.svg',
          parameterType: LineParameter.pressureSwitch,
          objectId: AppConstants.pressureSwitchObjectId,
          currentValue: line.pressureSwitch,
          validateAllLine: true,
          accent: _sensorColor,
        ),
    ];

    final climateTiles = <Widget>[
      if (availability(AppConstants.lightObjectId))
        _buildListTile(
          line: line,
          title: 'Light',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.lightObjectId}.svg',
          parameterType: LineParameter.light,
          objectId: AppConstants.lightObjectId,
          currentParameterValue: line.light,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.fanObjectId))
        _buildListTile(
          line: line,
          title: 'Fan',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.fanObjectId}.svg',
          parameterType: LineParameter.fan,
          objectId: AppConstants.fanObjectId,
          currentParameterValue: line.fan,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.foggerObjectId))
        _buildListTile(
          line: line,
          title: 'Fogger',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.foggerObjectId}.svg',
          parameterType: LineParameter.fogger,
          objectId: AppConstants.foggerObjectId,
          currentParameterValue: line.fogger,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.mistObjectId))
        _buildListTile(
          line: line,
          title: 'Mist',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.mistObjectId}.svg',
          parameterType: LineParameter.mist,
          objectId: AppConstants.mistObjectId,
          currentParameterValue: line.mist,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.heaterObjectId))
        _buildListTile(
          line: line,
          title: 'Heater',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.heaterObjectId}.svg',
          parameterType: LineParameter.heater,
          objectId: AppConstants.heaterObjectId,
          currentParameterValue: line.heater,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.humidityObjectId))
        _buildListTile(
          line: line,
          title: 'Humidity',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.humidityObjectId}.svg',
          parameterType: LineParameter.humidity,
          objectId: AppConstants.humidityObjectId,
          currentParameterValue: line.humidity,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.screenObjectId))
        _buildListTile(
          line: line,
          title: 'Screen',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.screenObjectId}.svg',
          parameterType: LineParameter.screen,
          objectId: AppConstants.screenObjectId,
          currentParameterValue: line.screen,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.co2ObjectId))
        _buildListTile(
          line: line,
          title: 'Co2',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.co2ObjectId}.svg',
          parameterType: LineParameter.co2,
          objectId: AppConstants.co2ObjectId,
          currentParameterValue: line.co2,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.moistureObjectId))
        _buildListTile(
          line: line,
          title: 'Moisture',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.moistureObjectId}.svg',
          parameterType: LineParameter.moisture,
          objectId: AppConstants.moistureObjectId,
          currentParameterValue: line.moisture,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.ventObjectId))
        _buildListTile(
          line: line,
          title: 'Vent',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.ventObjectId}.svg',
          parameterType: LineParameter.vent,
          objectId: AppConstants.ventObjectId,
          currentParameterValue: line.vent,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.pesticideObjectId))
        _buildListTile(
          line: line,
          title: 'Pesticides',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.pesticideObjectId}.svg',
          parameterType: LineParameter.pesticides,
          objectId: AppConstants.pesticideObjectId,
          currentParameterValue: line.pesticides,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.soilTemperatureObjectId))
        _buildListTile(
          line: line,
          title: 'Soil Temperature',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.soilTemperatureObjectId}.svg',
          parameterType: LineParameter.soilTemperature,
          objectId: AppConstants.soilTemperatureObjectId,
          currentParameterValue: line.soilTemperature,
          validateAllLine: true,
          accent: _envColor,
        ),
      if (availability(AppConstants.temperatureObjectId))
        _buildListTile(
          line: line,
          title: 'Temperature',
          imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.temperatureObjectId}.svg',
          parameterType: LineParameter.temperature,
          objectId: AppConstants.temperatureObjectId,
          currentParameterValue: line.temperature,
          validateAllLine: true,
          accent: _envColor,
        ),
    ];

    final weatherDevices = widget.configPvd.listOfDeviceModel
        .where((device) => (device.masterId != null && device.categoryId == 4))
        .toList();

    final bodySections = <Widget>[
      if (sourceAndPumpTiles.isNotEmpty)
        ConfigFlowSection(
          title: 'Source & Pumps',
          icon: Icons.water_rounded,
          accent: _sourceColor,
          children: sourceAndPumpTiles,
        ),
      if (valveAndControlTiles.isNotEmpty)
        ConfigFlowSection(
          title: 'Valves & Controls',
          icon: Icons.vibration_rounded,
          accent: _valveColor,
          children: valveAndControlTiles,
        ),
      if (fertFilterTiles.isNotEmpty)
        ConfigFlowSection(
          title: 'Filtration & Fertilization',
          icon: Icons.science_rounded,
          accent: _fertColor,
          children: fertFilterTiles,
        ),
      if (sensorMeterTiles.isNotEmpty)
        ConfigFlowSection(
          title: 'Meters & Pressure Sensors',
          icon: Icons.speed_rounded,
          accent: _sensorColor,
          children: sensorMeterTiles,
        ),
      if (climateTiles.isNotEmpty)
        ConfigFlowSection(
          title: 'Climate & Environment',
          icon: Icons.thermostat_rounded,
          accent: _envColor,
          children: climateTiles,
        ),
      if (weatherDevices.isNotEmpty)
        _buildWeatherStationSection(line, weatherDevices),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF13172E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: progress.complete
              ? _doneColor.withValues(alpha: 0.48)
              : const Color(0xFF20274B),
          width: progress.complete ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: progress.complete
                ? _doneColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLineHeaderBlock(
            line: line,
            progress: progress,
            primaryColor: primaryColor,
          ),
          if (bodySections.isNotEmpty) ...[
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 620;
              return _buildBodyGrid(bodySections, wide: isWide);
            }),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  WEATHER STATION SECTION
  // ───────────────────────────────────────────────────────────
  Widget _buildWeatherStationSection(IrrigationLineModel line, List<DeviceModel> weatherDevices) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF181C38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_rounded, size: 16, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Text(
                  'Weather Station',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          for (var device in weatherDevices)
            CheckboxListTile(
              dense: true,
              activeColor: Theme.of(context).primaryColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(
                device.deviceName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
              subtitle: Text(
                device.deviceId,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8E9BB4)),
              ),
              value: line.weatherStation.contains(device.controllerId),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    line.weatherStation.add(device.controllerId);
                  } else {
                    line.weatherStation.remove(device.controllerId);
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  TILES FOR PARAMETERS
  // ───────────────────────────────────────────────────────────
  Widget _buildListTile({
    required IrrigationLineModel line,
    required String title,
    required String imagePath,
    required LineParameter parameterType,
    required int objectId,
    required List<double> currentParameterValue,
    required bool validateAllLine,
    required Color accent,
    List<DeviceObjectModel>? listOfObject,
  }) {
    bool isAssigned = currentParameterValue.isNotEmpty;
    List<String> names = isAssigned
        ? currentParameterValue.map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-').toList()
        : const [];

    return ConfigComponentTile(
      title: title,
      imagePath: imagePath,
      names: names,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(currentParameterValue);
          if (currentParameterValue.isNotEmpty) {
            widget.configPvd.selectedSno = currentParameterValue[0];
          }
        });
        selectionDialogBox(
          context: context,
          title: 'Select $title',
          singleSelection: false,
          listOfObject: listOfObject ??
              getUnselectedLineParameterObject(
                currentParameterList: currentParameterValue,
                objectId: objectId,
                parameter: parameterType,
                validateAllLine: validateAllLine,
              ),
          onPressed: () {
            setState(() {
              widget.configPvd.updateSelectionInLine(line.commonDetails.sNo!, parameterType);
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildScalarTile({
    required IrrigationLineModel line,
    required String title,
    required String imagePath,
    required LineParameter parameterType,
    required int objectId,
    required double currentValue,
    required bool validateAllLine,
    required Color accent,
    List<DeviceObjectModel>? listOfObject,
  }) {
    bool isAssigned = currentValue != 0.0;
    List<String> names = isAssigned ? [getObjectName(currentValue, widget.configPvd).name ?? '-'] : const [];

    return ConfigComponentTile(
      title: title,
      imagePath: imagePath,
      names: names,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          if (currentValue != 0.0) {
            widget.configPvd.listOfSelectedSno.add(currentValue);
            widget.configPvd.selectedSno = currentValue;
          } else {
            widget.configPvd.selectedSno = 0.0;
          }
        });
        selectionDialogBox(
          context: context,
          title: 'Select $title',
          singleSelection: true,
          listOfObject: listOfObject ??
              getUnselectedLineParameterObject(
                currentParameterList: currentValue != 0.0 ? [currentValue] : [],
                objectId: objectId,
                parameter: parameterType,
                validateAllLine: validateAllLine,
              ),
          onPressed: () {
            setState(() {
              widget.configPvd.updateSelectionInLine(line.commonDetails.sNo!, parameterType);
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  List<DeviceObjectModel> getUnselectedLineParameterObject({
    required List<double> currentParameterList,
    required int objectId,
    required LineParameter parameter,
    required bool validateAllLine,
  }) {
    List<DeviceObjectModel> listOfObject = widget.configPvd.listOfGeneratedObject
        .where((object) => object.objectId == objectId)
        .toList();
    List<double> assigned = [];
    if (validateAllLine) {
      for (var line in widget.configPvd.line) {
        List<double> lineParameter = parameter == LineParameter.sourcePump
            ? line.sourcePump
            : parameter == LineParameter.irrigationPump
                ? line.irrigationPump
                : parameter == LineParameter.valve
                    ? line.valve
                    : parameter == LineParameter.flowControlValve
                        ? line.flowControlValve
                        : parameter == LineParameter.mainValve
                            ? line.mainValve
                            : parameter == LineParameter.fan
                                ? line.fan
                                : parameter == LineParameter.fogger
                                    ? line.fogger
                                    : parameter == LineParameter.pesticides
                                        ? line.pesticides
                                        : parameter == LineParameter.heater
                                            ? line.heater
                                            : parameter == LineParameter.screen
                                                ? line.screen
                                                : parameter == LineParameter.vent
                                                    ? line.vent
                                                    : parameter == LineParameter.moisture
                                                        ? line.moisture
                                                        : parameter == LineParameter.temperature
                                                            ? line.temperature
                                                            : parameter == LineParameter.soilTemperature
                                                                ? line.soilTemperature
                                                                : parameter == LineParameter.humidity
                                                                    ? line.humidity
                                                                    : parameter == LineParameter.waterMeter
                                                                        ? [line.waterMeter]
                                                                        : parameter == LineParameter.analogWaterMeter
                                                                            ? [line.analogWaterMeter]
                                                                            : parameter == LineParameter.powerSupply
                                                                                ? [line.powerSupply]
                                                                                : parameter == LineParameter.pressureSwitch
                                                                                    ? [line.pressureSwitch]
                                                                                    : parameter == LineParameter.pressureIn
                                                                                        ? [line.pressureIn]
                                                                                        : parameter == LineParameter.pressureOut
                                                                                            ? [line.pressureOut]
                                                                                            : line.co2;
        assigned.addAll(lineParameter);
      }
    }

    listOfObject = listOfObject
        .where((object) => (!assigned.contains(object.sNo!) || currentParameterList.contains(object.sNo)))
        .toList();
    return listOfObject;
  }
}
