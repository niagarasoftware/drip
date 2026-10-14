import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../model/pump_model.dart';
import '../model/source_model.dart';
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

class PumpConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const PumpConfiguration({super.key, required this.configPvd});

  @override
  State<PumpConfiguration> createState() => _PumpConfigurationState();
}

class _PumpConfigurationState extends State<PumpConfiguration> {
  // ── Design tokens (Matching source_configuration.dart Light Mode) ──
  static const Color _inletColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _outletColor = Color(0xFF059669); // emerald green
  static const Color _agitatorColor = Color(0xFFEA580C); // orange
  static const Color _doneColor = Color(0xFF059669); // emerald green
  static const Color _inkColor = Color(0xFF0F172A); // slate-900 crisp dark text
  static const Color _subTextColor = Color(0xFF64748B); // slate-500 subtle text

  List<int> pumpModelList = [5, 6, 7, 8, 9, 10];

  @override
  void initState() {
    super.initState();
    widget.configPvd.updateFloatForPump();
  }

  // ───────────────────────────────────────────────────────────
  //  PROGRESS CALCULATION
  // ───────────────────────────────────────────────────────────
  _Progress _calcProgress(PumpModel pump) {
    int total = 9;
    int filled = 0;
    if (pump.pressureIn != 0.0) filled++;
    if (pump.pressureOut != 0.0) filled++;
    if (pump.waterMeter != 0.0) filled++;
    if (pump.topSumpFloat != 0.0) filled++;
    if (pump.bottomSumpFloat != 0.0) filled++;
    if (pump.topTankFloat != 0.0) filled++;
    if (pump.bottomTankFloat != 0.0) filled++;
    if (pump.lowerLevel != 0.0) filled++;
    if (pump.upperLevel != 0.0) filled++;

    return _Progress(filled, total, filled);
  }

  double _getFloatSno(PumpModel pump, int mode) {
    switch (mode) {
      case 1:
        return pump.topSumpFloat;
      case 2:
        return pump.bottomSumpFloat;
      case 3:
        return pump.topTankFloat;
      case 4:
        return pump.bottomTankFloat;
      default:
        return 0.0;
    }
  }

  double _getLevelSno(PumpModel pump, int mode) {
    return mode == 1 ? pump.lowerLevel : pump.upperLevel;
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final pumps = widget.configPvd.pump;

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
                  _buildPageHeading(pumps.length),
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
                      for (var pump in pumps)
                        _buildPumpCard(pump, primaryColor),
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
          child: const Icon(Icons.speed_rounded, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pump configuration',
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
                'Configure pump modes, pressure sensors, floats and levels',
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
                'PUMPS',
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
  //  PUMP CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildPumpCard(PumpModel pump, Color primaryColor) {
    final progress = _calcProgress(pump);
    final showModeDropdown = !pumpModelList.contains(widget.configPvd.masterData['modelId']);

    return _buildCardShell(
      pump: pump,
      progress: progress,
      primaryColor: primaryColor,
      typeSelector: showModeDropdown ? _buildPumpModeSelector(pump, primaryColor) : null,
      body: [
        _buildFlowSection(
          title: 'Pressure & Flow Sensors',
          icon: Icons.speed_rounded,
          accent: _inletColor,
          children: [
            for (var mode in [1, 2, 3])
              _buildPressureAndWaterMeterTile(pump, mode, _inletColor),
          ],
        ),
        _buildFlowSection(
          title: 'Float Switches',
          icon: Icons.waves_rounded,
          accent: _outletColor,
          children: [
            for (var mode in [1, 2, 3, 4])
              _buildFloatTile(pump, mode, _outletColor),
          ],
        ),
        _buildFlowSection(
          title: 'Level Sensors',
          icon: Icons.unfold_more_rounded,
          accent: _agitatorColor,
          children: [
            for (var mode in [1, 2])
              _buildLevelTile(pump, mode, _agitatorColor),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  CARD SHELL
  // ───────────────────────────────────────────────────────────
  Widget _buildCardShell({
    required PumpModel pump,
    required _Progress progress,
    required Color primaryColor,
    Widget? typeSelector,
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
                    imagePath: '${AppConstants.svgObjectPath}objectId_5.svg',
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pump.commonDetails.name ?? 'Pump',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _inkColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (typeSelector != null) typeSelector,
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
  //  MODE SELECTOR
  // ───────────────────────────────────────────────────────────
  Widget _buildPumpModeSelector(PumpModel pump, Color primaryColor) {
    final currentType = getPumpTypeCodeToString(pump.pumpType);
    const pumpTypes = ['source', 'irrigation', 'aerator'];
    const modeIcons = {
      'source': Icons.water_rounded,
      'irrigation': Icons.grass_rounded,
      'aerator': Icons.air_rounded,
    };

    return PopupMenuButton<String>(
      tooltip: 'Change pump mode',
      initialValue: currentType,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      onSelected: (value) {
        setState(() {
          for (var line in widget.configPvd.line) {
            if (value == 'source') {
              if (line.irrigationPump.contains(pump.commonDetails.sNo)) {
                line.irrigationPump.remove(pump.commonDetails.sNo);
              }
            } else {
              if (line.sourcePump.contains(pump.commonDetails.sNo)) {
                line.sourcePump.remove(pump.commonDetails.sNo);
              }
            }
          }
          pump.pumpType = getPumpTypeStringToCode(value);
        });
      },
      itemBuilder: (context) => pumpTypes.map((type) {
        final selected = type == currentType;
        return PopupMenuItem<String>(
          value: type,
          child: Row(
            children: [
              Icon(
                modeIcons[type] ?? Icons.circle,
                size: 18,
                color: selected ? primaryColor : Colors.grey.shade600,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? primaryColor : _inkColor,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check_rounded, size: 18, color: primaryColor),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 4, 7, 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withValues(alpha: 0.10),
              primaryColor.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(modeIcons[currentType] ?? Icons.circle, size: 14, color: primaryColor),
            const SizedBox(width: 5),
            Text(
              currentType.toUpperCase(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: primaryColor),
          ],
        ),
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

  Widget _buildPressureAndWaterMeterTile(PumpModel currentPump, int mode, Color accent) {
    int objectId = mode == 1 ? 24 : mode == 2 ? 24 : 22;
    String objectName = mode == 1 ? 'Pressure In' : mode == 2 ? 'Pressure Out' : 'Water Meter';
    double currentSno = mode == 1 ? currentPump.pressureIn : mode == 2 ? currentPump.pressureOut : currentPump.waterMeter;
    bool isAssigned = currentSno != 0.0;
    String assignedName = isAssigned ? getObjectName(currentSno, widget.configPvd).name ?? '-' : '';

    List<double> validateSensorFromOtherSource = [];
    for (var pump in widget.configPvd.pump) {
      if (pump.commonDetails.sNo != currentPump.commonDetails.sNo) {
        validateSensorFromOtherSource.add(pump.lowerLevel);
        validateSensorFromOtherSource.add(pump.waterMeter);
        validateSensorFromOtherSource.add(pump.pressureIn);
        validateSensorFromOtherSource.add(pump.pressureOut);
      } else {
        validateSensorFromOtherSource.add(mode == 1 ? pump.pressureOut : pump.pressureIn);
      }
    }

    return _buildTile(
      title: objectName,
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      assignedName: assignedName,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.selectedSno = currentSno;
        });
        selectionDialogBox(
          context: context,
          title: 'Select $objectName',
          singleSelection: true,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) => (object.objectId == objectId && !validateSensorFromOtherSource.contains(object.sNo)))
              .toList(),
          onPressed: () {
            setState(() {
              if (mode == 1) {
                currentPump.pressureIn = widget.configPvd.selectedSno;
              } else if (mode == 2) {
                currentPump.pressureOut = widget.configPvd.selectedSno;
              } else {
                currentPump.waterMeter = widget.configPvd.selectedSno;
              }
              widget.configPvd.selectedSno = 0.0;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildFloatTile(PumpModel currentPump, int mode, Color accent) {
    int objectId = AppConstants.floatObjectId;
    Map<int, String> controlBy = {
      1: 'Top Float (Sump)',
      2: 'Bottom Float (Sump)',
      3: 'Top Float (Tank)',
      4: 'Bottom Float (Tank)',
    };
    String objectName = controlBy[mode] ?? 'Float Switch';
    double currentSno = _getFloatSno(currentPump, mode);
    bool isAssigned = currentSno != 0.0;
    String assignedName = isAssigned ? getObjectName(currentSno, widget.configPvd).name ?? '-' : '';

    return _buildTile(
      title: objectName,
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      assignedName: assignedName,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        List<double> validateFloat = [];
        List<double> topTankFloatSnoForAllSource = [];
        List<double> bottomTankFloatSnoForAllSource = [];
        List<double> topSumpFloatSnoForAllSource = [];
        List<double> bottomSumpFloatSnoForAllSource = [];
        Map<int, List<double>> validateFloatAvailableInSource = {
          1: topSumpFloatSnoForAllSource,
          2: bottomSumpFloatSnoForAllSource,
          3: topTankFloatSnoForAllSource,
          4: bottomTankFloatSnoForAllSource,
        };
        for (var src in widget.configPvd.source) {
          if (src.outletPump.contains(currentPump.commonDetails.sNo)) {
            topSumpFloatSnoForAllSource.add(src.topFloatForOutletPump);
            bottomSumpFloatSnoForAllSource.add(src.bottomFloatForOutletPump);
          } else if (src.inletPump.contains(currentPump.commonDetails.sNo)) {
            topTankFloatSnoForAllSource.add(src.topFloatForInletPump);
            bottomTankFloatSnoForAllSource.add(src.bottomFloatForInletPump);
          }
        }
        setState(() {
          widget.configPvd.selectedSno = currentSno;
        });
        selectionDialogBox(
          context: context,
          title: 'Select $objectName',
          singleSelection: true,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) => (object.objectId == objectId &&
                  !validateFloat.contains(object.sNo) &&
                  validateFloatAvailableInSource[mode]!.contains(object.sNo)))
              .toList(),
          onPressed: () {
            setState(() {
              if (mode == 1) {
                currentPump.topSumpFloat = widget.configPvd.selectedSno;
              } else if (mode == 2) {
                currentPump.bottomSumpFloat = widget.configPvd.selectedSno;
              } else if (mode == 3) {
                currentPump.topTankFloat = widget.configPvd.selectedSno;
              } else {
                currentPump.bottomTankFloat = widget.configPvd.selectedSno;
              }
              widget.configPvd.selectedSno = 0.0;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildLevelTile(PumpModel currentPump, int mode, Color accent) {
    int objectId = AppConstants.levelObjectId;
    String objectName = mode == 1 ? 'Lower Level' : 'Upper Level';
    double currentSno = _getLevelSno(currentPump, mode);
    bool isAssigned = currentSno != 0.0;
    String assignedName = isAssigned ? getObjectName(currentSno, widget.configPvd).name ?? '-' : '';

    List<double> sensorToDisplay = [];
    for (var src in widget.configPvd.source) {
      if (mode == 1) {
        if (src.outletPump.contains(currentPump.commonDetails.sNo) && src.level != 0.0) {
          sensorToDisplay.add(src.level);
        }
      } else {
        if (src.inletPump.contains(currentPump.commonDetails.sNo) && src.level != 0.0) {
          sensorToDisplay.add(src.level);
        }
      }
    }

    return _buildTile(
      title: objectName,
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      assignedName: assignedName,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.selectedSno = currentSno;
        });
        selectionDialogBox(
          context: context,
          title: 'Select $objectName',
          singleSelection: true,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) => (object.objectId == objectId && sensorToDisplay.contains(object.sNo)))
              .toList(),
          onPressed: () {
            setState(() {
              if (mode == 1) {
                currentPump.lowerLevel = widget.configPvd.selectedSno;
              } else {
                currentPump.upperLevel = widget.configPvd.selectedSno;
              }
              widget.configPvd.selectedSno = 0.0;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

List<Widget> getWaterMeterAndPressure(double pressureInSno, double waterMeterSno, ConfigMakerProvider configPvd){
  return [
    if(pressureInSno != 0.0)
      Positioned(
        right: 0,
        top: 15 * configPvd.ratio,
        child: Image.asset(
          'assets/Images/Png/objectId_24.png',
          width: 30,
          height: 30,
        ),
      ),
    if(waterMeterSno != 0.0)
      Positioned(
        right: 0,
        top: 50 * configPvd.ratio,
        child: Image.asset(
          'assets/Images/Png/objectId_22.png',
          width: 30,
          height: 30,
        ),
      ),
  ];
}

Widget singlePump(SourceModel source, bool fillingPump, ConfigMakerProvider configPvd, {bool dashboard = false}){
  List<double> currentParameter = fillingPump ? source.inletPump : source.outletPump;
  if (currentParameter.isEmpty) return const SizedBox();

  final pumpMatches = configPvd.pump.where((pump) => pump.commonDetails.sNo == currentParameter[0]);
  if (pumpMatches.isEmpty) return const SizedBox();
  final pModel = pumpMatches.first;

  return Stack(
    children: [
      Positioned(
        left : fillingPump ? 40 : null,
        right : (!fillingPump && dashboard) ? 0 : (!fillingPump) ? 40 : null,
        bottom: 32 * configPvd.ratio,
        child: SvgPicture.asset(
          'assets/Images/Source/backside_pipe_1.svg',
          width: 120 ,
          height: 8.5 * configPvd.ratio,
        ),
      ),
      SvgPicture.asset(
        'assets/Images/Source/pump_1.svg',
        width: 120,
        height: 120 * configPvd.ratio,
      ),
      ...getWaterMeterAndPressure(
          pModel.pressureIn,
          pModel.waterMeter,
          configPvd
      ),
      Positioned(
        left : 5,
        top: 0,
        child: Text(getObjectName(currentParameter[0], configPvd).name ?? '', style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),),
      )
    ],
  );
}

Widget multiplePump(SourceModel source, bool fillingPump, ConfigMakerProvider configPvd,
    {bool dashBoard = false, int? maxOutletPumpForTank}){
  List<double> currentParameter = fillingPump ? source.inletPump : source.outletPump;
  return Row(
    children: [
      for(var i = 0; i < currentParameter.length; i++)
        Builder(builder: (context) {
          final pumpMatches = configPvd.pump.where((pump) => pump.commonDetails.sNo == currentParameter[i]);
          final pModel = pumpMatches.isNotEmpty ? pumpMatches.first : null;
          return Stack(
            children: [
              Positioned(
                left: fillingPump ? (i == 0 ? 50 : null) : null,
                right: (!fillingPump && i == currentParameter.length - 1 && !dashBoard) ? 40 : null,
                bottom: 32 * configPvd.ratio,
                child: SvgPicture.asset(
                  'assets/Images/Source/backside_pipe_1.svg',
                  width: 120,
                  height: 8.5 * configPvd.ratio,
                ),
              ),
              SvgPicture.asset(
                'assets/Images/Source/pump_1.svg',
                width: 120,
                height: 120 * configPvd.ratio,
              ),
              if (pModel != null)
                ...getWaterMeterAndPressure(
                  pModel.pressureIn,
                  pModel.waterMeter,
                  configPvd,
                ),
              if(currentParameter.length > 1)
                Positioned(
                  right: i == 0 ? 0 : null,
                  left: i == 1 ? 0 : null,
                  bottom: 16 * configPvd.ratio,
                  child: SvgPicture.asset(
                    'assets/Images/Source/${
                        i == 0
                            ? 'front_corner_left_radius_pipe_1'
                            : i == (currentParameter.length - 1)
                            ? 'front_corner_right_radius_pipe_1'
                            : 'backside_pipe_1'}.svg',
                    width: 120,
                    height: 8.5 * configPvd.ratio,
                  ),
                ),
              Positioned(
                left : 5,
                top: 0,
                child: Text(getObjectName(currentParameter[i], configPvd).name ?? '', style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),),
              )
            ],
          );
        }),
      if(maxOutletPumpForTank != null)
        for(var i = 0; i < (maxOutletPumpForTank - currentParameter.length); i++)
          SizedBox(
            width: 94,
            height: 120 * configPvd.ratio,
            child: Stack(
              children: [
                Positioned(
                  bottom : 32 * configPvd.ratio,
                  child: SvgPicture.asset(
                    'assets/Images/Source/backside_pipe_1.svg',
                    width: 120,
                    height: 8.5 * configPvd.ratio,
                  ),
                )
              ],
            ),
          )
    ],
  );
}

Widget getTankImage(SourceModel source ,ConfigMakerProvider configPvd, {bool dashboard = false, bool inlet = true,}){
  bool levelAvailable = source.level != 0.0;
  bool topFloatAvailableForOutlet = source.topFloatForOutletPump != 0.0;
  bool bottomFloatAvailableForOutlet = source.bottomFloatForOutletPump != 0.0;
  bool topFloatAvailableForInlet = source.topFloatForInletPump != 0.0;
  bool bottomFloatAvailableForInlet = source.bottomFloatForInletPump != 0.0;
  bool outletWaterMeter = source.outletWaterMeter != 0.0;
  if(source.sourceType == 1){
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/tank_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        if(levelAvailable)
          Positioned(
            left: 52,
            bottom: 28,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.green
                ),
              ),
            ),
          ),
        if(topFloatAvailableForOutlet)
          Positioned(
            right: 40,
            bottom: 50,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 40,
            ),
          ),
        if(topFloatAvailableForInlet)
          Positioned(
            left: 40,
            bottom: 50,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 40,
            ),
          ),
        if(bottomFloatAvailableForOutlet)
          Positioned(
            right: 50,
            bottom: 25,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 70,
              height: 70,
            ),
          ),
        if(bottomFloatAvailableForInlet)
          Positioned(
            left: 50,
            bottom: 25,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 70,
              height: 70,
            ),
          ),
        if(outletWaterMeter)
          Positioned(
            right: 0,
            bottom: 20,
            child: Image.asset(
              'assets/Images/Png/objectId_${AppConstants.waterMeterObjectId}.png',
              width: 30,
              height: 30,
            ),
          )
      ],
    );
  }
  else if(source.sourceType == 2){
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/sump_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        if(levelAvailable)
          Positioned(
            left: 52,
            bottom: 35,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.green
                ),
              ),
            ),
          ),
        if(topFloatAvailableForOutlet)
          Positioned(
            right: 55,
            bottom: 55,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 30,
            ),
          ),
        if(bottomFloatAvailableForOutlet)
          Positioned(
            right: 70,
            bottom: 35,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 50,
              height: 50,
            ),
          ),
        if(outletWaterMeter)
          Positioned(
            right: 0,
            bottom: 20,
            child: Image.asset(
              'assets/Images/Png/objectId_${AppConstants.waterMeterObjectId}.png',
              width: 30,
              height: 30,
            ),
          )
      ],
    );
  }
  else if(source.sourceType == 3){
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/well_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        if(levelAvailable)
          Positioned(
            left: 45,
            bottom: 22,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.green
                ),
              ),
            ),
          ),
        if(topFloatAvailableForOutlet)
          Positioned(
            right: 55,
            bottom: 55,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 40,
            ),
          ),
        if(bottomFloatAvailableForOutlet)
          Positioned(
            right: 70,
            bottom: 35,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 50,
              height: 50,
            ),
          ),
        if(outletWaterMeter)
          Positioned(
            right: 0,
            bottom: 20,
            child: Image.asset(
              'assets/Images/Png/objectId_${AppConstants.waterMeterObjectId}.png',
              width: 30,
              height: 30,
            ),
          )
      ],
    );
  }
  else if(source.sourceType == 4){
    return SvgPicture.asset(
      'assets/Images/Source/bore_1.svg',
      width: 120,
      height: 120 * configPvd.ratio,
    );
  }
  else if(source.sourceType == 5){
    return SvgPicture.asset(
      'assets/Images/Source/pond_1.svg',
      width: 120,
      height: 120* configPvd.ratio,
    );
  }else if(source.sourceType == 6){
    return SvgPicture.asset(
      'assets/Images/Source/fertilizer_source.svg',
      width: 120,
      height: 120* configPvd.ratio,
    );
  }else{
    return SvgPicture.asset(
      'assets/Images/Source/fertilizer_tank.svg',
      width: 120,
      height: 120* configPvd.ratio,
    );
  }
}