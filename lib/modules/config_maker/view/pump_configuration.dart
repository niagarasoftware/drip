import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';

import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../utils/constants.dart';
import '../model/pump_model.dart';
import '../model/source_model.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/config_template_widgets.dart';
import '../widget/painter/pump_painter.dart';
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

class PumpConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const PumpConfiguration({super.key, required this.configPvd});

  @override
  State<PumpConfiguration> createState() => _PumpConfigurationState();
}

class _PumpConfigurationState extends State<PumpConfiguration> {
  // ── Design tokens (Matching source_configuration.dart) ──
  static const Color _inletColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _doneColor = Color(0xFF059669); // emerald green

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
    int total = 3;
    int filled = 0;
    if (pump.pressureIn != 0.0) filled++;
    if (pump.pressureOut != 0.0) filled++;
    if (pump.waterMeter != 0.0) filled++;

    return _Progress(filled, total, filled);
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    final pumps = widget.configPvd.pump;

    return Container(
      color: colors.canvasBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              if (pumps.isEmpty)
                ConfigEmptyState(
                  title: 'No Pumps Configured',
                  subtitle: 'No pumps found in current configuration.',
                  icon: Icons.speed_rounded,
                  primaryColor: primaryColor,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pumps.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final pump = pumps[index];
                    return _buildPumpCard(pump, primaryColor, colors);
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
  //  PUMP PAINTER LEADING & HEADER BLOCK
  // ───────────────────────────────────────────────────────────
  Widget _buildPumpPainterBlock(ConfigMakerColors colors) {
    return Container(
      width: double.infinity,
      height: 105,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.innerSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CustomPaint(
          painter: DetailedPumpPainter(isOn: true),
          size: const Size(160, 95),
        ),
      ),
    );
  }

  Widget _buildPumpHeaderBlock({
    required PumpModel pump,
    required _Progress progress,
    required Color primaryColor,
    required ConfigMakerColors colors,
    Widget? typeSelector,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.innerSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pump.commonDetails.name ?? 'Pump',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (typeSelector != null) ...[
                      const SizedBox(height: 6),
                      typeSelector,
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildPumpPainterBlock(colors)),
        ],
      ),
    );
  }

  Widget _buildCompactGrid(List<Widget> tiles) {
    const gap = 8.0;
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final hasSecond = i + 1 < tiles.length;
      rows.add(
        Row(
          children: [
            Expanded(child: tiles[i]),
            const SizedBox(width: gap),
            Expanded(
              child: hasSecond ? tiles[i + 1] : const SizedBox(),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: gap),
          rows[r],
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  PUMP CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildControlledBySourceTile(
    PumpModel pump,
    List<SourceModel> matchingSources,
    Color accent,
    ConfigMakerColors colors,
  ) {
    return ConfigFlowSection(
      title: 'Select the source that controls the filling operation.',
      icon: Icons.alt_route_rounded,
      accent: accent,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: RadioGroup<double>(
            groupValue: pump.controlledBySource,
            onChanged: (double? value) {
              if (value != null) {
                setState(() {
                  pump.controlledBySource = value;
                });
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var source in matchingSources) ...[
                  Builder(
                    builder: (context) {
                      final double sourceSno = source.commonDetails.sNo ?? 0.0;
                      final bool isSelected = pump.controlledBySource == sourceSno;
                      final String sourceTitle = (source.commonDetails.name?.isNotEmpty == true)
                          ? source.commonDetails.name!
                          : getObjectName(sourceSno, widget.configPvd).name ?? 'Source ${sourceSno.toInt()}';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              pump.controlledBySource = sourceSno;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                Radio<double>(
                                  value: sourceSno,
                                  activeColor: accent,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    sourceTitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? colors.textPrimary : colors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPumpCard(PumpModel pump, Color primaryColor, ConfigMakerColors colors) {
    final progress = _calcProgress(pump);
    final showModeDropdown = !pumpModelList.contains(widget.configPvd.masterData['modelId']);

    final matchingSources = widget.configPvd.source
        .where((s) => s.inletPump.contains(pump.commonDetails.sNo))
        .toList();

    if (matchingSources.isEmpty) {
      pump.controlledBySource = 0.0;
    } else if (matchingSources.length == 1) {
      pump.controlledBySource = matchingSources.first.commonDetails.sNo ?? 0.0;
    } else {
      if (!matchingSources.any((s) => s.commonDetails.sNo == pump.controlledBySource)) {
        pump.controlledBySource = matchingSources.first.commonDetails.sNo ?? 0.0;
      }
    }

    String currentTypeStr = getPumpTypeCodeToString(pump.pumpType);
    String currentTypeFormatted = currentTypeStr[0].toUpperCase() + currentTypeStr.substring(1);

    final typeSelector = showModeDropdown
        ? ConfigTypeSelector(
            currentType: currentTypeFormatted,
            typeList: const ['Source', 'Irrigation', 'Aerator'],
            typeIcons: const {
              'Source': Icons.water_rounded,
              'Irrigation': Icons.grass_rounded,
              'Aerator': Icons.air_rounded,
            },
            tooltip: 'Change pump mode',
            onSelected: (value) {
              setState(() {
                final codeStr = value.toLowerCase();
                for (var line in widget.configPvd.line) {
                  if (codeStr == 'source') {
                    if (line.irrigationPump.contains(pump.commonDetails.sNo)) {
                      line.irrigationPump.remove(pump.commonDetails.sNo);
                    }
                  } else {
                    if (line.sourcePump.contains(pump.commonDetails.sNo)) {
                      line.sourcePump.remove(pump.commonDetails.sNo);
                    }
                  }
                }
                pump.pumpType = getPumpTypeStringToCode(codeStr);
              });
            },
          )
        : null;

    return ConfigCardShell(
      headerBlock: _buildPumpHeaderBlock(
        pump: pump,
        progress: progress,
        primaryColor: primaryColor,
        colors: colors,
        typeSelector: typeSelector,
      ),
      isComplete: progress.complete,
      completeColor: _doneColor,
      body: [
        if (matchingSources.isNotEmpty)
          _buildControlledBySourceTile(pump, matchingSources, primaryColor, colors),
        ConfigFlowSection(
          title: 'Pressure & Flow Sensors',
          icon: Icons.speed_rounded,
          accent: _inletColor,
          children: [
            _buildCompactGrid([
              for (var mode in [1, 2, 3])
                _buildPressureAndWaterMeterTile(pump, mode, _inletColor),
            ]),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  COMPONENT TILES
  // ───────────────────────────────────────────────────────────
  Widget _buildComponentTile({
    required String title,
    required String imagePath,
    required List<String> names,
    required bool isAssigned,
    required VoidCallback onTap,
    required Color accent,
    bool compact = true,
  }) {
    return ConfigComponentTile(
      title: title,
      imagePath: imagePath,
      names: names,
      isAssigned: isAssigned,
      onTap: onTap,
      accent: accent,
      compact: compact,
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

    return _buildComponentTile(
      title: objectName,
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: isAssigned ? [assignedName] : const [],
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
}

List<Widget> getWaterMeterAndPressure(double pressureInSno, double waterMeterSno, ConfigMakerProvider configPvd) {
  return [
    if (pressureInSno != 0.0)
      Positioned(
        right: 0,
        top: 15 * configPvd.ratio,
        child: Image.asset(
          'assets/Images/Png/objectId_24.png',
          width: 30,
          height: 30,
        ),
      ),
    if (waterMeterSno != 0.0)
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

Widget singlePump(SourceModel source, bool fillingPump, ConfigMakerProvider configPvd, {bool dashboard = false}) {
  List<double> currentParameter = fillingPump ? source.inletPump : source.outletPump;
  if (currentParameter.isEmpty) return const SizedBox();

  final pumpMatches = configPvd.pump.where((pump) => pump.commonDetails.sNo == currentParameter[0]);
  if (pumpMatches.isEmpty) return const SizedBox();
  final pModel = pumpMatches.first;

  return Stack(
    children: [
      Positioned(
        left: fillingPump ? 40 : null,
        right: (!fillingPump && dashboard) ? 0 : (!fillingPump) ? 40 : null,
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
      ...getWaterMeterAndPressure(
        pModel.pressureIn,
        pModel.waterMeter,
        configPvd,
      ),
      Positioned(
        left: 5,
        top: 0,
        child: Text(
          getObjectName(currentParameter[0], configPvd).name ?? '',
          style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),
        ),
      )
    ],
  );
}

Widget multiplePump(SourceModel source, bool fillingPump, ConfigMakerProvider configPvd,
    {bool dashBoard = false, int? maxOutletPumpForTank}) {
  List<double> currentParameter = fillingPump ? source.inletPump : source.outletPump;
  return Row(
    children: [
      for (var i = 0; i < currentParameter.length; i++)
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
              if (currentParameter.length > 1)
                Positioned(
                  right: i == 0 ? 0 : null,
                  left: i == 1 ? 0 : null,
                  bottom: 16 * configPvd.ratio,
                  child: SvgPicture.asset(
                    'assets/Images/Source/${i == 0 ? 'front_corner_left_radius_pipe_1' : i == (currentParameter.length - 1) ? 'front_corner_right_radius_pipe_1' : 'backside_pipe_1'}.svg',
                    width: 120,
                    height: 8.5 * configPvd.ratio,
                  ),
                ),
              Positioned(
                left: 5,
                top: 0,
                child: Text(
                  getObjectName(currentParameter[i], configPvd).name ?? '',
                  style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),
                ),
              )
            ],
          );
        }),
      if (maxOutletPumpForTank != null)
        for (var i = 0; i < (maxOutletPumpForTank - currentParameter.length); i++)
          SizedBox(
            width: 94,
            height: 120 * configPvd.ratio,
            child: Stack(
              children: [
                Positioned(
                  bottom: 32 * configPvd.ratio,
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

Widget getTankImage(SourceModel source, ConfigMakerProvider configPvd, {bool dashboard = false, bool inlet = true}) {
  bool levelAvailable = source.level != 0.0;
  bool topFloatAvailableForOutlet = source.topFloatForOutletPump != 0.0;
  bool bottomFloatAvailableForOutlet = source.bottomFloatForOutletPump != 0.0;
  bool topFloatAvailableForInlet = source.topFloatForInletPump != 0.0;
  bool bottomFloatAvailableForInlet = source.bottomFloatForInletPump != 0.0;
  bool outletWaterMeter = source.outletWaterMeter != 0.0;
  if (source.sourceType == 1) {
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/tank_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        if (levelAvailable)
          Positioned(
            left: 52,
            bottom: 28,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.green),
              ),
            ),
          ),
        if (topFloatAvailableForOutlet)
          Positioned(
            right: 40,
            bottom: 50,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 40,
            ),
          ),
        if (topFloatAvailableForInlet)
          Positioned(
            left: 40,
            bottom: 50,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 40,
            ),
          ),
        if (bottomFloatAvailableForOutlet)
          Positioned(
            right: 50,
            bottom: 25,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 70,
              height: 70,
            ),
          ),
        if (bottomFloatAvailableForInlet)
          Positioned(
            left: 50,
            bottom: 25,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 70,
              height: 70,
            ),
          ),
        if (outletWaterMeter)
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
  } else if (source.sourceType == 2) {
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/sump_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        if (levelAvailable)
          Positioned(
            left: 52,
            bottom: 35,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.green),
              ),
            ),
          ),
        if (topFloatAvailableForOutlet)
          Positioned(
            right: 55,
            bottom: 55,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 30,
            ),
          ),
        if (bottomFloatAvailableForOutlet)
          Positioned(
            right: 70,
            bottom: 35,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 50,
              height: 50,
            ),
          ),
        if (outletWaterMeter)
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
  } else if (source.sourceType == 3) {
    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Images/Source/well_${!inlet ? 'outlet_' : ''}1.svg',
          width: 120,
          height: 120 * configPvd.ratio,
        ),
        if (levelAvailable)
          Positioned(
            left: 45,
            bottom: 22,
            child: Container(
              width: 10,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white),
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 20,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.green),
              ),
            ),
          ),
        if (topFloatAvailableForOutlet)
          Positioned(
            right: 55,
            bottom: 55,
            child: SvgPicture.asset(
              'assets/Images/Source/top_float.svg',
              width: 30,
              height: 40,
            ),
          ),
        if (bottomFloatAvailableForOutlet)
          Positioned(
            right: 70,
            bottom: 35,
            child: SvgPicture.asset(
              'assets/Images/Source/bottom_float.svg',
              width: 50,
              height: 50,
            ),
          ),
        if (outletWaterMeter)
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
  } else if (source.sourceType == 4) {
    return SvgPicture.asset(
      'assets/Images/Source/bore_1.svg',
      width: 120,
      height: 120 * configPvd.ratio,
    );
  } else if (source.sourceType == 5) {
    return SvgPicture.asset(
      'assets/Images/Source/pond_1.svg',
      width: 120,
      height: 120 * configPvd.ratio,
    );
  } else if (source.sourceType == 6) {
    return SvgPicture.asset(
      'assets/Images/Source/fertilizer_source.svg',
      width: 120,
      height: 120 * configPvd.ratio,
    );
  } else {
    return SvgPicture.asset(
      'assets/Images/Source/fertilizer_tank.svg',
      width: 120,
      height: 120 * configPvd.ratio,
    );
  }
}
