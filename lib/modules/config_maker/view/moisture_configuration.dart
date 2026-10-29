import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/moisture_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';

import '../../../Constants/dialog_boxes.dart';
import '../../../utils/constants.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/config_template_widgets.dart';
import '../widget/painter/moisture_sensor_painter.dart';
import 'utils/config_maker_colors.dart';

/// Simple holder for progress metrics.
class _Progress {
  final int filled;
  final int total;
  final int sensorFilled;
  const _Progress(this.filled, this.total, this.sensorFilled);

  bool get complete => total > 0 && filled == total;
  double get fraction => total == 0 ? 0 : filled / total;
}

class MoistureConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const MoistureConfiguration({super.key, required this.configPvd});

  @override
  State<MoistureConfiguration> createState() => _MoistureConfigurationState();
}

class _MoistureConfigurationState extends State<MoistureConfiguration> {
  // ── Design tokens (Matching pressure_configuration.dart & valve_configuration.dart) ──
  static const Color _valveColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _soilTempColor = Color(0xFFD97706); // warm amber
  static const Color _doneColor = Color(0xFF059669); // emerald green

  // ───────────────────────────────────────────────────────────
  //  PROGRESS CALCULATION
  // ───────────────────────────────────────────────────────────
  _Progress _calcProgress(MoistureModel moistureSensor) {
    int total = 2;
    int filled = 0;
    if (moistureSensor.valves.isNotEmpty) filled++;
    if (moistureSensor.soilTemperature.isNotEmpty) filled++;

    return _Progress(filled, total, filled);
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    final moistureSensors = widget.configPvd.moisture;

    return Container(
      color: colors.canvasBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              if (moistureSensors.isEmpty)
                ConfigEmptyState(
                  title: 'No Moisture Sensors Configured',
                  subtitle: 'No moisture sensors found in current configuration.',
                  icon: Icons.water_drop_rounded,
                  primaryColor: primaryColor,
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 460,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 350,
                  ),
                  itemCount: moistureSensors.length,
                  itemBuilder: (context, index) {
                    final moistureSensor = moistureSensors[index];
                    return _buildMoistureCard(moistureSensor, primaryColor, colors);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  MOISTURE PAINTER LEADING & HEADER BLOCK
  // ───────────────────────────────────────────────────────────
  Widget _buildMoisturePainterBlock(MoistureModel moistureSensor, ConfigMakerColors colors) {
    bool isAssigned = moistureSensor.valves.isNotEmpty || moistureSensor.soilTemperature.isNotEmpty;
    return Container(
      width: 90,
      height: 64,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.innerSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: RepaintBoundary(
          child: FittedBox(
            fit: BoxFit.contain,
            child: MoistureSensorView(
              isOn: isAssigned,
              size: const Size(100, 180),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoistureHeaderBlock({
    required MoistureModel moistureSensor,
    required Color primaryColor,
    required ConfigMakerColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.innerSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildMoisturePainterBlock(moistureSensor, colors),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              moistureSensor.commonDetails.name ?? 'Moisture Sensor',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  MOISTURE CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildMoistureCard(MoistureModel moistureSensor, Color primaryColor, ConfigMakerColors colors) {
    final progress = _calcProgress(moistureSensor);

    return ConfigCardShell(
      headerBlock: _buildMoistureHeaderBlock(
        moistureSensor: moistureSensor,
        primaryColor: primaryColor,
        colors: colors,
      ),
      isComplete: progress.complete,
      completeColor: _doneColor,
      body: [
        ConfigFlowSection(
          title: 'Valves',
          icon: Icons.vibration_rounded,
          accent: _valveColor,
          children: [
            _buildValveTile(moistureSensor, _valveColor),
          ],
        ),
        ConfigFlowSection(
          title: 'Soil Temperature',
          icon: Icons.thermostat_rounded,
          accent: _soilTempColor,
          children: [
            _buildSoilTemperatureTile(moistureSensor, _soilTempColor),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  COMPONENT TILES
  // ───────────────────────────────────────────────────────────
  Widget _buildValveTile(MoistureModel moistureSensor, Color accent) {
    int objectId = AppConstants.valveObjectId;
    bool isAssigned = moistureSensor.valves.isNotEmpty;
    List<String> assignedNames = isAssigned
        ? moistureSensor.valves
            .map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-')
            .toList()
        : const [];

    return ConfigComponentTile(
      title: 'Valve',
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: assignedNames,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(moistureSensor.valves);
        });
        selectionDialogBox(
          context: context,
          title: 'Select Valve',
          singleSelection: false,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) => object.objectId == AppConstants.valveObjectId)
              .toList(),
          onPressed: () {
            setState(() {
              widget.configPvd.updateSelectionInMoisture(
                moistureSensor.commonDetails.sNo!,
                AppConstants.valveObjectId,
              );
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildSoilTemperatureTile(MoistureModel moistureSensor, Color accent) {
    int objectId = AppConstants.soilTemperatureObjectId;
    bool isAssigned = moistureSensor.soilTemperature.isNotEmpty;
    List<String> assignedNames = isAssigned
        ? moistureSensor.soilTemperature
            .map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-')
            .toList()
        : const [];

    return ConfigComponentTile(
      title: 'Soil Temperature',
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: assignedNames,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(moistureSensor.soilTemperature);
        });
        selectionDialogBox(
          context: context,
          title: 'Select Soil Temperature',
          singleSelection: false,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) => object.objectId == AppConstants.soilTemperatureObjectId)
              .toList(),
          onPressed: () {
            setState(() {
              widget.configPvd.updateSelectionInMoisture(
                moistureSensor.commonDetails.sNo!,
                AppConstants.soilTemperatureObjectId,
              );
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
