import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/pressure_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';

import '../../../Constants/dialog_boxes.dart';
import '../../../utils/constants.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/config_template_widgets.dart';
import '../widget/painter/pressure_sensor_painter.dart';
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

class PressureConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const PressureConfiguration({super.key, required this.configPvd});

  @override
  State<PressureConfiguration> createState() => _PressureConfigurationState();
}

class _PressureConfigurationState extends State<PressureConfiguration> {
  // ── Design tokens (Matching valve_configuration.dart) ──
  static const Color _mainValveColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _doneColor = Color(0xFF059669); // emerald green

  // ───────────────────────────────────────────────────────────
  //  PROGRESS CALCULATION
  // ───────────────────────────────────────────────────────────
  _Progress _calcProgress(PressureModel pressureSensor) {
    int total = 1;
    int filled = 0;
    if (pressureSensor.mainValve.isNotEmpty) filled++;

    return _Progress(filled, total, filled);
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    final pressureSensors = widget.configPvd.pressureSensor;

    return Container(
      color: colors.canvasBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              ConfigPageHeading(
                title: 'Pressure configuration',
                subtitle: 'Configure main valves for pressure sensors',
                totalCount: pressureSensors.length,
                countUnitSingular: 'sensor',
                countUnitPlural: 'sensors',
                primaryColor: primaryColor,
                icon: Icons.speed_rounded,
              ),
              const SizedBox(height: 18),
              if (pressureSensors.isEmpty)
                ConfigEmptyState(
                  title: 'No Pressure Sensors Configured',
                  subtitle: 'No pressure sensors found in current configuration.',
                  icon: Icons.speed_rounded,
                  primaryColor: primaryColor,
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 215,
                  ),
                  itemCount: pressureSensors.length,
                  itemBuilder: (context, index) {
                    final pressureSensor = pressureSensors[index];
                    return _buildPressureCard(pressureSensor, primaryColor, colors);
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
  //  PRESSURE PAINTER LEADING & HEADER BLOCK
  // ───────────────────────────────────────────────────────────
  Widget _buildPressurePainterBlock(PressureModel pressureSensor, ConfigMakerColors colors) {
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
            child: PressureSensorView(
              isOn: pressureSensor.mainValve.isNotEmpty,
              size: const Size(110, 80),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPressureHeaderBlock({
    required PressureModel pressureSensor,
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
          _buildPressurePainterBlock(pressureSensor, colors),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pressureSensor.commonDetails.name ?? 'Pressure Sensor',
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
  //  PRESSURE CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildPressureCard(PressureModel pressureSensor, Color primaryColor, ConfigMakerColors colors) {
    final progress = _calcProgress(pressureSensor);

    return ConfigCardShell(
      headerBlock: _buildPressureHeaderBlock(
        pressureSensor: pressureSensor,
        primaryColor: primaryColor,
        colors: colors,
      ),
      isComplete: progress.complete,
      completeColor: _doneColor,
      body: [
        ConfigFlowSection(
          title: 'Main Valves',
          icon: Icons.vibration_rounded,
          accent: _mainValveColor,
          children: [
            _buildMainValveTile(pressureSensor, _mainValveColor),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  COMPONENT TILES
  // ───────────────────────────────────────────────────────────
  Widget _buildMainValveTile(PressureModel pressureSensor, Color accent) {
    int objectId = AppConstants.mainValveObjectId;
    bool isAssigned = pressureSensor.mainValve.isNotEmpty;
    List<String> assignedNames = isAssigned
        ? pressureSensor.mainValve
            .map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-')
            .toList()
        : const [];

    return ConfigComponentTile(
      title: 'Main Valve',
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: assignedNames,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(pressureSensor.mainValve);
        });
        selectionDialogBox(
          context: context,
          title: 'Select Main Valve',
          singleSelection: false,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) => object.objectId == AppConstants.mainValveObjectId)
              .toList(),
          onPressed: () {
            setState(() {
              widget.configPvd.updateSelectionInPressure(
                pressureSensor.commonDetails.sNo!,
                AppConstants.mainValveObjectId,
              );
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
