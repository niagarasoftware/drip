import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/device_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/device_object_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/irrigation_line_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../../../Constants/dialog_boxes.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';
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
  // ── Design tokens (Matching SourceConfiguration Light Mode) ──
  static const Color _sourceColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _valveColor = Color(0xFF059669); // emerald green
  static const Color _fertColor = Color(0xFFEA580C); // orange
  static const Color _sensorColor = Color(0xFF0EA5E9); // ocean blue
  static const Color _envColor = Color(0xFF7C3AED); // purple
  static const Color _doneColor = Color(0xFF059669); // emerald green
  static const Color _inkColor = Color(0xFF0F172A); // slate-900 crisp dark text
  static const Color _subTextColor = Color(0xFF64748B); // slate-500 subtle text

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

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final lines = widget.configPvd.line;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC), // Slate 50
            Color(0xFFF1F5F9), // Slate 100
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: LayoutBuilder(builder: (context, constraint) {
          final itemWidth = constraint.maxWidth < 460 ? constraint.maxWidth : 460.0;
          return SizedBox(
            width: constraint.maxWidth,
            height: constraint.maxHeight,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildPageHeading(lines.length),
                  const SizedBox(height: 18),
                  ResponsiveGridList(
                    horizontalGridMargin: 0,
                    verticalGridMargin: 16,
                    minItemWidth: itemWidth,
                    listViewBuilderOptions: ListViewBuilderOptions(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    ),
                    children: [
                      for (var line in lines)
                        _buildLineCard(line, primaryColor),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  PAGE INTRO
  // ───────────────────────────────────────────────────────────
  Widget _buildPageHeading(int total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Line configuration',
                style: TextStyle(
                  color: _inkColor,
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.45,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Configure pumps, valves, filtration, fertilization and sensors for irrigation lines',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _subTextColor,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A5F).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.dataset_rounded, color: _inkColor, size: 20),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A5F).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  color: _inkColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'LINES',
                style: TextStyle(
                  color: _subTextColor,
                  fontSize: 8,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

    return _buildCardShell(
      line: line,
      progress: progress,
      primaryColor: primaryColor,
      body: [
        if (sourceAndPumpTiles.isNotEmpty)
          _buildFlowSection(
            title: 'Source & Pumps',
            icon: Icons.water_rounded,
            accent: _sourceColor,
            children: sourceAndPumpTiles,
          ),
        if (valveAndControlTiles.isNotEmpty)
          _buildFlowSection(
            title: 'Valves & Controls',
            icon: Icons.vibration_rounded,
            accent: _valveColor,
            children: valveAndControlTiles,
          ),
        if (fertFilterTiles.isNotEmpty)
          _buildFlowSection(
            title: 'Filtration & Fertilization',
            icon: Icons.science_rounded,
            accent: _fertColor,
            children: fertFilterTiles,
          ),
        if (sensorMeterTiles.isNotEmpty)
          _buildFlowSection(
            title: 'Meters & Pressure Sensors',
            icon: Icons.speed_rounded,
            accent: _sensorColor,
            children: sensorMeterTiles,
          ),
        if (climateTiles.isNotEmpty)
          _buildFlowSection(
            title: 'Climate & Environment',
            icon: Icons.thermostat_rounded,
            accent: _envColor,
            children: climateTiles,
          ),
        if (weatherDevices.isNotEmpty)
          _buildWeatherStationSection(line, weatherDevices),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  CARD SHELL
  // ───────────────────────────────────────────────────────────
  Widget _buildCardShell({
    required IrrigationLineModel line,
    required _Progress progress,
    required Color primaryColor,
    required List<Widget> body,
  }) {
    final remaining = progress.total - progress.filled;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: progress.complete
              ? _doneColor.withValues(alpha: 0.48)
              : const Color(0xFFE2E8F0),
          width: progress.complete ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: progress.complete
                ? _doneColor.withValues(alpha: 0.08)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 11),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withValues(alpha: 0.12),
                        primaryColor.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.15),
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
                    children: [
                      Text(
                        line.commonDetails.name ?? 'Irrigation Line',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _inkColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress.complete
                            ? 'Complete'
                            : progress.total == 0
                                ? 'No parameters available'
                                : '$remaining left to assign',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: progress.complete ? _doneColor : _subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildProgressRing(progress, primaryColor),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _withGaps(body, 10),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> items, double gap) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(items[i]);
    }
    return out;
  }

  Widget _buildProgressRing(_Progress p, Color primaryColor) {
    final color = p.complete
        ? _doneColor
        : p.filled > 0
            ? primaryColor
            : Colors.grey.shade400;

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: p.fraction,
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          p.complete
              ? Icon(Icons.check_rounded, size: 22, color: color)
              : Text(
                  '${p.filled}/${p.total}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                ),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    fontWeight: FontWeight.w800,
                    color: _inkColor,
                  ),
                ),
              ],
            ),
          ),
          for (var device in weatherDevices)
            CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(device.deviceName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              subtitle: Text(device.deviceId, style: const TextStyle(fontSize: 11, color: _subTextColor)),
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
  //  FLOW SECTION
  // ───────────────────────────────────────────────────────────
  Widget _buildFlowSection({
    required String title,
    required IconData icon,
    required Color accent,
    required List<Widget> children,
  }) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 8,
          endIndent: 8,
          color: accent.withValues(alpha: 0.12),
        ));
      }
      rows.add(children[i]);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.06),
            accent.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 13, color: accent),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          ...rows,
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
    String assignedName = isAssigned
        ? currentParameterValue.map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-').join(', ')
        : '';

    return _buildTile(
      title: title,
      imagePath: imagePath,
      assignedName: assignedName,
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
    String assignedName = isAssigned ? (getObjectName(currentValue, widget.configPvd).name ?? '-') : '';

    return _buildTile(
      title: title,
      imagePath: imagePath,
      assignedName: assignedName,
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

  Widget _buildTile({
    required String title,
    required String imagePath,
    required String assignedName,
    required bool isAssigned,
    required VoidCallback onTap,
    required Color accent,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAssigned ? accent.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAssigned ? accent.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: SizedImage(
                  imagePath: imagePath,
                  color: isAssigned ? accent : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (isAssigned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accent.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          assignedName,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Not assigned',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              isAssigned
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.edit_rounded, size: 18, color: accent),
                    )
                  : Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded, size: 18, color: accent),
                    ),
            ],
          ),
        ),
      ),
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
