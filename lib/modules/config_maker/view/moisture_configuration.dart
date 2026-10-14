import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/moisture_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../../../Constants/dialog_boxes.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';

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
  // ── Design tokens (Matching ChannelConfiguration Light Mode) ──
  static const Color _valveColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _soilTempColor = Color(0xFFD97706); // warm amber
  static const Color _doneColor = Color(0xFF059669); // emerald green
  static const Color _inkColor = Color(0xFF0F172A); // slate-900 crisp dark text
  static const Color _subTextColor = Color(0xFF64748B); // slate-500 subtle text

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
    final primaryColor = Theme.of(context).primaryColor;
    final moistureSensors = widget.configPvd.moisture;

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
                  _buildPageHeading(moistureSensors.length),
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
                      for (var moistureSensor in moistureSensors)
                        _buildMoistureCard(moistureSensor, primaryColor),
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
          child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moisture configuration',
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
                'Configure valves and soil temperature sensors for moisture sensors',
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
                'SENSORS',
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
  //  MOISTURE CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildMoistureCard(MoistureModel moistureSensor, Color primaryColor) {
    final progress = _calcProgress(moistureSensor);

    return _buildCardShell(
      moistureSensor: moistureSensor,
      progress: progress,
      primaryColor: primaryColor,
      body: [
        _buildFlowSection(
          title: 'Valves',
          icon: Icons.vibration_rounded,
          accent: _valveColor,
          children: [
            _buildValveTile(moistureSensor, _valveColor),
          ],
        ),
        _buildFlowSection(
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
  //  CARD SHELL
  // ───────────────────────────────────────────────────────────
  Widget _buildCardShell({
    required MoistureModel moistureSensor,
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
                    imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.moistureObjectId}.svg',
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moistureSensor.commonDetails.name ?? 'Moisture Sensor',
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
                        progress.complete ? 'Complete' : '$remaining left to assign',
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

  Widget _buildValveTile(MoistureModel moistureSensor, Color accent) {
    int objectId = AppConstants.valveObjectId;
    bool isAssigned = moistureSensor.valves.isNotEmpty;
    String assignedName = isAssigned
        ? moistureSensor.valves.map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-').join(', ')
        : '';

    return _buildTile(
      title: 'Valve',
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      assignedName: assignedName,
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
              widget.configPvd.updateSelectionInMoisture(moistureSensor.commonDetails.sNo!, AppConstants.valveObjectId);
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
    String assignedName = isAssigned
        ? moistureSensor.soilTemperature.map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-').join(', ')
        : '';

    return _buildTile(
      title: 'Soil Temperature',
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      assignedName: assignedName,
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
              widget.configPvd.updateSelectionInMoisture(moistureSensor.commonDetails.sNo!, AppConstants.soilTemperatureObjectId);
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
