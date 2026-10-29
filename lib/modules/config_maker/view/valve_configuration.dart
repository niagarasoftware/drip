import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/valve_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';

import '../../../Constants/dialog_boxes.dart';
import '../../../utils/constants.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/config_template_widgets.dart';
import '../widget/painter/single_valve_painter.dart';
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

class ValveConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const ValveConfiguration({super.key, required this.configPvd});

  @override
  State<ValveConfiguration> createState() => _ValveConfigurationState();
}

class _ValveConfigurationState extends State<ValveConfiguration> {
  // ── Design tokens (Matching channel_configuration.dart) ──
  static const Color _inputPressureColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _lateralPressureColor = Color(0xFFD97706); // warm amber
  static const Color _doneColor = Color(0xFF059669); // emerald green

  // ───────────────────────────────────────────────────────────
  //  PROGRESS CALCULATION
  // ───────────────────────────────────────────────────────────
  _Progress _calcProgress(ValveConfigModel valveConfig) {
    int total = 2;
    int filled = 0;
    if (valveConfig.inputPressure.isNotEmpty) filled++;
    if (valveConfig.lateralPressure.isNotEmpty) filled++;

    return _Progress(filled, total, filled);
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    final valveConfigs = widget.configPvd.valveConfig;

    return Container(
      color: colors.canvasBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              if (valveConfigs.isEmpty)
                ConfigEmptyState(
                  title: 'No Valves Configured',
                  subtitle: 'No valves found in current configuration.',
                  icon: Icons.vibration_rounded,
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
                    mainAxisExtent: 336,
                  ),
                  itemCount: valveConfigs.length,
                  itemBuilder: (context, index) {
                    final valve = valveConfigs[index];
                    return _buildValveCard(valve, primaryColor, colors);
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
  //  VALVE PAINTER LEADING & HEADER BLOCK
  // ───────────────────────────────────────────────────────────
  Widget _buildValvePainterBlock(ConfigMakerColors colors) {
    return Container(
      width: 90,
      height: 64,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.innerSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: RepaintBoundary(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SingleValveView(
              isOn: false,
              size: Size(110, 80),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValveHeaderBlock({
    required ValveConfigModel valveConfig,
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
          _buildValvePainterBlock(colors),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valveConfig.commonDetails.name ?? 'Valve',
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
  //  VALVE CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildValveCard(ValveConfigModel valveConfig, Color primaryColor, ConfigMakerColors colors) {
    final progress = _calcProgress(valveConfig);

    return ConfigCardShell(
      headerBlock: _buildValveHeaderBlock(
        valveConfig: valveConfig,
        primaryColor: primaryColor,
        colors: colors,
      ),
      isComplete: progress.complete,
      completeColor: _doneColor,
      body: [
        ConfigFlowSection(
          title: 'Input Pressure',
          icon: Icons.speed_rounded,
          accent: _inputPressureColor,
          children: [
            _buildPressureTile(valveConfig, true, _inputPressureColor),
          ],
        ),
        ConfigFlowSection(
          title: 'Lateral Pressure',
          icon: Icons.compress_rounded,
          accent: _lateralPressureColor,
          children: [
            _buildPressureTile(valveConfig, false, _lateralPressureColor),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  COMPONENT TILES
  // ───────────────────────────────────────────────────────────
  Widget _buildPressureTile(
      ValveConfigModel valveConfig, bool inputPressure, Color accent) {
    int objectId = AppConstants.pressureSensorObjectId;
    List<double> list =
    inputPressure ? valveConfig.inputPressure : valveConfig.lateralPressure;
    String title = inputPressure ? 'Input Pressure' : 'Lateral Pressure';
    bool isAssigned = list.isNotEmpty;
    List<String> names = isAssigned
        ? list
        .map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-')
        .toList()
        : const [];

    return ConfigComponentTile(
      title: title,
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: names,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(list);
        });
        selectionDialogBox(
          context: context,
          title: 'Select $title',
          singleSelection: false,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) =>
          object.objectId == AppConstants.pressureSensorObjectId)
              .toList(),
          onPressed: () {
            setState(() {
              widget.configPvd.updateSelectionInValveConfig(
                valveConfig.commonDetails.sNo!,
                AppConstants.pressureSensorObjectId,
                inputPressure,
              );
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
