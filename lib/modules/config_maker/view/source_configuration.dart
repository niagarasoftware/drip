import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/device_object_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../model/source_model.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/config_template_widgets.dart';
import '../widget/object_manager_bar.dart';
import '../../../utils/constants.dart';
import '../widget/painter/over_head_tank_painter.dart';
import '../widget/painter/sump_painter.dart';
import '../widget/painter/well_painter.dart';
import '../widget/painter/natural_source_painter.dart';
import '../widget/painter/main_fertilizer_source_painter.dart';
import '../widget/painter/fertilizer_tank_painter.dart';

/// Simple holder for how much of a source card has been assigned.
class _Progress {
  final int filled;
  final int total;
  final int sensorFilled;
  const _Progress(this.filled, this.total, this.sensorFilled);

  bool get complete => total > 0 && filled == total;
  double get fraction => total == 0 ? 0 : filled / total;
}

class SourceConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const SourceConfiguration({super.key, required this.configPvd});

  @override
  State<SourceConfiguration> createState() => _SourceConfigurationState();
}

class _SourceConfigurationState extends State<SourceConfiguration> {
  // ── Design tokens ──
  static const Color _inletColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _outletColor = Color(0xFF059669); // emerald green
  static const Color _agitatorColor = Color(0xFFEA580C); // orange
  static const Color _doneColor = Color(0xFF059669); // emerald green
  static const Color _inkColor = Colors.white; // dark mode crisp white text
  static const Color _subTextColor = Color(0xFF8E9BB4); // slate-400 subtle text

  static const List<String> _tankTypeList = [
    'Tank',
    'Sump',
    'Well',
    'Bore',
    'Fertilizer Source',
    'Fertilizer Tank',
    'Others',
  ];

  static const Map<String, IconData> _tankTypeIcons = {
    'Tank': Icons.water_drop_rounded,
    'Sump': Icons.layers_rounded,
    'Well': Icons.vertical_align_bottom_rounded,
    'Bore': Icons.south_rounded,
    'Fertilizer Source': Icons.science_rounded,
    'Fertilizer Tank': Icons.eco_rounded,
    'Others': Icons.more_horiz_rounded,
  };

  bool get _isAquaculture =>
      AppConstants.aquacultureModelList.contains(widget.configPvd.masterData['modelId']);

  bool _hasObject(int objectId) =>
      widget.configPvd.listOfGeneratedObject.any((o) => o.objectId == objectId);

  List<String> _namesOf(List<double> list) =>
      list.map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-').toList();

  // ───────────────────────────────────────────────────────────
  //  PROGRESS
  // ───────────────────────────────────────────────────────────
  _Progress _calcProgress(SourceModel source) {
    if (_isAquaculture) {
      return _Progress(source.aerator.isNotEmpty ? 1 : 0, 1, 0);
    }

    final isFertilizerSource = [6, 7].contains(source.sourceType);
    final isBoreOrPond = [4, 5].contains(source.sourceType);
    final hasAgitators = _hasObject(AppConstants.agitatorObjectId);
    final showSensors = !isBoreOrPond && !isFertilizerSource;

    if (isFertilizerSource) {
      final slots = <bool>[
        source.nutrient != 0.0,
        if (source.inletTankValve.isNotEmpty) true,
        if (source.outletTankValve.isNotEmpty) true,
        if (hasAgitators && source.agitator.isNotEmpty) true,
      ];
      return _Progress(
        slots.where((e) => e).length,
        slots.length,
        0,
      );
    }

    final sensorSlots = <bool>[
      source.level != 0.0,
      source.outletWaterMeter != 0.0,
      source.topFloatForInletPump != 0.0,
      source.bottomFloatForInletPump != 0.0,
      source.topFloatForOutletPump != 0.0,
      source.bottomFloatForOutletPump != 0.0,
    ];

    final slots = <bool>[
      if (!isBoreOrPond) source.inletPump.isNotEmpty,
      source.outletPump.isNotEmpty,
      if (!isBoreOrPond && source.inletTankValve.isNotEmpty) true,
      if (source.outletTankValve.isNotEmpty) true,
      if (showSensors) ...sensorSlots,
    ];

    return _Progress(
      slots.where((e) => e).length,
      slots.length,
      sensorSlots.where((e) => e).length,
    );
  }

  void _addSource() {
    final p = widget.configPvd;
    DeviceObjectModel? sampleObj;
    for (var o in p.listOfSampleObjectModel) {
      if (o.objectId == AppConstants.sourceObjectId) {
        sampleObj = o;
        break;
      }
    }
    if (sampleObj == null) {
      sampleObj = DeviceObjectModel(
        objectId: AppConstants.sourceObjectId,
        objectName: 'Water Source',
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
        message: 'Only $cap Water Source can be added for this master controller model.',
      );
      return;
    }

    setState(() {
      p.updateObjectCount(AppConstants.sourceObjectId, '${currentCount + 1}');
    });
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final sources = widget.configPvd.source;

    return Container(
      color: const Color(0xFF0C0F1D),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: LayoutBuilder(builder: (context, constraint) {
          return SizedBox(
            width: constraint.maxWidth,
            height: constraint.maxHeight,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  ConfigPageHeading(
                    title: 'Source configuration',
                    subtitle: 'Configure pumps, valves and sensors for your sources',
                    totalCount: sources.length,
                    countUnitSingular: 'source',
                    countUnitPlural: 'sources',
                    primaryColor: primaryColor,
                    icon: Icons.tune_rounded,
                    onAddPressed: _addSource,
                    addButtonLabel: 'Add Source',
                  ),
                  const SizedBox(height: 18),
                  if (sources.isEmpty)
                    ConfigEmptyState(
                      title: 'No Water Sources Added',
                      subtitle: 'Tap the button below to add a water source to your configuration.',
                      icon: Icons.waves_rounded,
                      primaryColor: primaryColor,
                      onAddPressed: _addSource,
                      buttonLabel: 'Add Source',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sources.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final source = sources[index];
                        return _isAquaculture
                            ? _buildAquacultureSourceCard(source, primaryColor)
                            : _buildStandardSourceCard(source, primaryColor);
                      },
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

  Widget _buildSourcePainterBlock(int sourceType) {
    CustomPainter painter;
    switch (sourceType) {
      case 1:
        painter = DetailedOverheadTankPainter(isOn: true);
        break;
      case 2:
        painter = DetailedSumpPainter(isOn: true);
        break;
      case 3:
        painter = DetailedWellPainter(isOn: true);
        break;
      case 4:
      case 5:
        painter = DetailedNaturalSourcePainter(isOn: true);
        break;
      case 6:
        painter = DetailedMainFertilizerSourcePainter(isOn: true);
        break;
      case 7:
        painter = DetailedFertilizerTankPainter(isOn: true);
        break;
      default:
        painter = DetailedOverheadTankPainter(isOn: true);
    }

    return Container(
      width: double.infinity,
      height: 80,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF12162B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CustomPaint(
          painter: painter,
          size: const Size(85, 72),
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

  Widget _buildSourceHeaderBlock({
    required SourceModel source,
    required _Progress progress,
    required Color primaryColor,
    Widget? typeSelector,
  }) {
    final itemName = source.commonDetails.name ?? 'Source';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF181C38),
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
                      itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (typeSelector != null) ...[
                      const SizedBox(height: 6),
                      typeSelector,
                    ],
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
                          source.commonDetails.sNo!,
                          AppConstants.sourceObjectId,
                        );
                      });
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSourcePainterBlock(source.sourceType),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  AQUACULTURE SOURCE CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildAquacultureSourceCard(SourceModel source, Color primaryColor) {
    final progress = _calcProgress(source);

    return ConfigCardShell(
      headerBlock: _buildSourceHeaderBlock(
        source: source,
        progress: progress,
        primaryColor: primaryColor,
      ),
      isComplete: progress.complete,
      completeColor: _doneColor,
      body: [
        ConfigFlowSection(
          title: 'Aeration',
          icon: Icons.air_rounded,
          accent: primaryColor,
          children: [
            _buildComponentTile(
              title: 'Aerators',
              imagePath: 'assets/png/aerators_o.png',
              names: _namesOf(source.aerator),
              isAssigned: source.aerator.isNotEmpty,
              accent: primaryColor,
              onTap: () {
                setState(() {
                  widget.configPvd.listOfSelectedSno.clear();
                  widget.configPvd.listOfSelectedSno.addAll(source.aerator);
                });
                selectionDialogBox(
                  context: context,
                  title: 'Select Aerator',
                  singleSelection: false,
                  listOfObject: widget.configPvd.listOfGeneratedObject
                      .where((object) => (object.objectId == AppConstants.pumpObjectId))
                      .toList(),
                  onPressed: () {
                    setState(() {
                      source.aerator.clear();
                      source.aerator.addAll(widget.configPvd.listOfSelectedSno);
                      widget.configPvd.updateAssignObject(
                        sNo: source.commonDetails.sNo!,
                        objectId: AppConstants.pumpObjectId,
                        listOfSerialNo: widget.configPvd.listOfSelectedSno,
                      );
                      widget.configPvd.listOfSelectedSno.clear();
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  STANDARD SOURCE CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildStandardSourceCard(SourceModel source, Color primaryColor) {
    final isFertilizerSource = [6, 7].contains(source.sourceType);
    final isBoreOrPond = [4, 5].contains(source.sourceType);
    final hasAgitators = _hasObject(AppConstants.agitatorObjectId);
    final showSensors = !isBoreOrPond && !isFertilizerSource;

    String currentTankType = getTankCodeToString(source.sourceType);
    if (!_tankTypeList.contains(currentTankType)) {
      currentTankType = 'Tank';
    }

    final progress = _calcProgress(source);

    final typeSelector = ConfigTypeSelector(
      currentType: currentTankType,
      typeList: _tankTypeList,
      typeIcons: _tankTypeIcons,
      tooltip: 'Change source type',
      onSelected: (value) {
        setState(() {
          source.sourceType = getTankStringToCode(value);
          if ([4, 5].contains(source.sourceType)) {
            source.inletPump.clear();
            source.level = 0.0;
            source.topFloatForInletPump = 0.0;
            source.bottomFloatForInletPump = 0.0;
          }
        });
      },
    );

    return ConfigCardShell(
      headerBlock: _buildSourceHeaderBlock(
        source: source,
        progress: progress,
        primaryColor: primaryColor,
        typeSelector: typeSelector,
      ),
      isComplete: progress.complete,
      completeColor: _doneColor,
      body: [
        // ── Nutrient ──
        if (isFertilizerSource)
          ConfigFlowSection(
            title: 'Nutrient',
            icon: Icons.science_rounded,
            accent: primaryColor,
            children: [
              _buildParameterTileForNutrient(source, primaryColor),
            ],
          ),

        // ── Inlet ──
        if (!isBoreOrPond)
          ConfigFlowSection(
            title: 'Inlet',
            icon: Icons.south_west_rounded,
            accent: _inletColor,
            children: [
              if (!isFertilizerSource) _buildParameterTileForPump(source, 1, _inletColor),
              _buildParameterTileForTankValve(source, true, _inletColor),
            ],
          ),

        // ── Outlet ──
        ConfigFlowSection(
          title: 'Outlet',
          icon: Icons.north_east_rounded,
          accent: _outletColor,
          children: [
            if (!isFertilizerSource) _buildParameterTileForPump(source, 2, _outletColor),
            _buildParameterTileForTankValve(source, false, _outletColor),
          ],
        ),

        // ── Agitator ──
        if (isFertilizerSource && hasAgitators)
          ConfigFlowSection(
            title: 'Mixing',
            icon: Icons.sync_rounded,
            accent: _agitatorColor,
            children: [
              _buildParameterTileForAgitator(source, _agitatorColor),
            ],
          ),
      ],
      // ── Sensors (full-width footer) ──
      footer: showSensors ? _buildSensorsSection(source, progress, primaryColor) : null,
    );
  }

  // ───────────────────────────────────────────────────────────
  //  SENSORS (collapsible, 3-column grid on wide screens)
  // ───────────────────────────────────────────────────────────
  Widget _buildSensorsSection(SourceModel source, _Progress progress, Color primaryColor) {
    return ConfigSensorsSection(
      storageKey: PageStorageKey('sensors_${source.commonDetails.sNo}'),
      title: 'Level and sensors',
      activeSensorCount: progress.sensorFilled,
      totalSensors: 6,
      primaryColor: primaryColor,
      children: [
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 560 ? 3 : 2;
          // 3 cols -> [level, in-top, in-bottom] / [meter, out-top, out-bottom]
          final order = cols == 3 ? [1, 2, 3, 6, 4, 5] : [1, 6, 2, 3, 4, 5];
          const gap = 8.0;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final m in order)
                SizedBox(
                  width: w,
                  child: _buildParameterTileForSensor(source, m, primaryColor),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildComponentTile({
    required String title,
    required String imagePath,
    required List<String> names,
    required bool isAssigned,
    required VoidCallback onTap,
    required Color accent,
    bool compact = false,
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

  Widget _buildParameterTileForPump(SourceModel source, int pumpMode, Color accent) {
    List<double> currentParameter = pumpMode == 1 ? source.inletPump : source.outletPump;
    List<double> checkingParameter = pumpMode == 1 ? source.outletPump : source.inletPump;

    return _buildComponentTile(
      title: '${pumpMode == 1 ? 'Inlet' : 'Outlet'} pump',
      imagePath: '${AppConstants.svgObjectPath}objectId_5.svg',
      names: _namesOf(currentParameter),
      isAssigned: currentParameter.isNotEmpty,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(currentParameter);
        });
        selectionDialogBox(
          context: context,
          title: 'Select ${pumpMode == 1 ? 'Inlet' : 'Outlet'} Pump',
          singleSelection: false,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) => (object.objectId == 5 && !checkingParameter.contains(object.sNo)))
              .toList(),
          onPressed: () {
            setState(() {
              if (pumpMode == 1) {
                source.inletPump.clear();
                source.inletPump.addAll(widget.configPvd.listOfSelectedSno);
              } else {
                source.outletPump.clear();
                source.outletPump.addAll(widget.configPvd.listOfSelectedSno);
              }
              widget.configPvd.listOfSelectedSno.clear();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildParameterTileForSensor(SourceModel source, int mode, Color accent) {
    int objectId = mode == 1
        ? AppConstants.levelObjectId
        : mode == 6
        ? AppConstants.waterMeterObjectId
        : AppConstants.floatObjectId;

    Map<int, String> currentObjectName = {
      1: 'Level sensor',
      2: 'Inlet top float',
      3: 'Inlet bottom float',
      4: 'Outlet top float',
      5: 'Outlet bottom float',
      6: 'Outlet water meter',
    };

    Map<int, double> currentSno = {
      1: source.level,
      2: source.topFloatForInletPump,
      3: source.bottomFloatForInletPump,
      4: source.topFloatForOutletPump,
      5: source.bottomFloatForOutletPump,
      6: source.outletWaterMeter,
    };

    double activeSno = currentSno[mode] ?? 0.0;

    return _buildComponentTile(
      title: currentObjectName[mode]!,
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: activeSno == 0.0 ? const [] : [getObjectName(activeSno, widget.configPvd).name ?? '-'],
      isAssigned: activeSno != 0.0,
      accent: accent,
      compact: true,
      onTap: () {
        List<double> validateSensorFromOtherSource = [];
        for (var src in widget.configPvd.source) {
          validateSensorFromOtherSource.add(src.level);
          validateSensorFromOtherSource.add(src.outletWaterMeter);
          validateSensorFromOtherSource.add(src.topFloatForInletPump);
          validateSensorFromOtherSource.add(src.bottomFloatForInletPump);
          validateSensorFromOtherSource.add(src.topFloatForOutletPump);
          validateSensorFromOtherSource.add(src.bottomFloatForOutletPump);
        }
        validateSensorFromOtherSource.remove(activeSno);

        setState(() {
          widget.configPvd.selectedSno = activeSno;
        });

        selectionDialogBox(
          context: context,
          title: 'Select ${currentObjectName[mode]}',
          singleSelection: true,
          listOfObject: widget.configPvd.listOfGeneratedObject.where((object) {
            if (object.objectId != objectId) {
              return false;
            }
            if (validateSensorFromOtherSource.contains(object.sNo)) {
              return false;
            }
            return true;
          }).toList(),
          onPressed: () {
            bool sensorRemovedInAnyPump = false;
            double oldSensorSno = activeSno;
            DeviceObjectModel? deviceObjectModel;
            List<String> sensorsRemovedFromPump = [];

            if (mode == 1) {
              oldSensorSno = source.level;
              source.level = widget.configPvd.selectedSno;
            } else if (mode == 2) {
              oldSensorSno = source.topFloatForInletPump;
              source.topFloatForInletPump = widget.configPvd.selectedSno;
            } else if (mode == 3) {
              oldSensorSno = source.bottomFloatForInletPump;
              source.bottomFloatForInletPump = widget.configPvd.selectedSno;
            } else if (mode == 4) {
              oldSensorSno = source.topFloatForOutletPump;
              source.topFloatForOutletPump = widget.configPvd.selectedSno;
            } else if (mode == 5) {
              oldSensorSno = source.bottomFloatForOutletPump;
              source.bottomFloatForOutletPump = widget.configPvd.selectedSno;
            } else {
              oldSensorSno = source.outletWaterMeter;
              source.outletWaterMeter = widget.configPvd.selectedSno;
            }

            widget.configPvd.selectedSno = 0.0;
            setState(() {});
            Navigator.pop(context);

            if (oldSensorSno != 0.0 && oldSensorSno != (currentSno[mode] ?? 0.0)) {
              final matches = widget.configPvd.listOfGeneratedObject.where((object) => object.sNo == oldSensorSno);
              if (matches.isNotEmpty) {
                deviceObjectModel = matches.first;
              }
              for (var pump in widget.configPvd.pump) {
                if ([...source.outletPump, ...source.inletPump].contains(pump.commonDetails.sNo)) {
                  if (mode == 1) {
                    if (pump.lowerLevel == oldSensorSno) {
                      pump.lowerLevel = 0.0;
                      sensorsRemovedFromPump.add(pump.commonDetails.name ?? '');
                      sensorRemovedInAnyPump = true;
                    } else if (pump.upperLevel == oldSensorSno) {
                      pump.upperLevel = 0.0;
                      sensorRemovedInAnyPump = true;
                      sensorsRemovedFromPump.add(pump.commonDetails.name ?? '');
                    }
                  } else if ([2, 3, 4, 5].contains(mode)) {
                    bool isFloatRemoved = false;
                    if (pump.topTankFloat == oldSensorSno) {
                      pump.topTankFloat = 0.0;
                      isFloatRemoved = true;
                    } else if (pump.bottomTankFloat == oldSensorSno) {
                      pump.bottomTankFloat = 0.0;
                      isFloatRemoved = true;
                    } else if (pump.topSumpFloat == oldSensorSno) {
                      pump.topSumpFloat = 0.0;
                      isFloatRemoved = true;
                    } else if (pump.bottomSumpFloat == oldSensorSno) {
                      pump.bottomSumpFloat = 0.0;
                      isFloatRemoved = true;
                    }
                    if (isFloatRemoved) {
                      sensorsRemovedFromPump.add(pump.commonDetails.name ?? '');
                      sensorRemovedInAnyPump = true;
                    }
                  }
                }
              }
            }
            setState(() {});
            if (sensorRemovedInAnyPump && deviceObjectModel != null) {
              simpleDialogBox(
                context: context,
                title: 'Alert',
                message: 'The ${deviceObjectModel.name ?? 'Sensor'} is removed from ${sensorsRemovedFromPump.join(',')} in the pump configuration',
              );
            }
          },
        );
      },
    );
  }

  Widget _buildParameterTileForTankValve(SourceModel source, bool isInlet, Color accent) {
    final List<double> currentList = isInlet ? source.inletTankValve : source.outletTankValve;

    return _buildComponentTile(
      title: isInlet ? 'Inlet tank valve' : 'Outlet tank valve',
      imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.tankValveObjectId}.svg',
      names: _namesOf(currentList),
      isAssigned: currentList.isNotEmpty,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(currentList);
        });
        selectionDialogBox(
          context: context,
          title: isInlet ? 'Select Inlet Tank Valve' : 'Select Outlet Tank Valve',
          singleSelection: false,
          listOfObject: widget.configPvd.listOfGeneratedObject.where((object) {
            if (object.objectId != AppConstants.tankValveObjectId) return false;
            if (isInlet) {
              return !widget.configPvd.source.any((src) => src.outletTankValve.contains(object.sNo));
            } else {
              return !widget.configPvd.source.any((src) => src.inletTankValve.contains(object.sNo));
            }
          }).toList(),
          onPressed: () {
            setState(() {
              if (isInlet) {
                source.inletTankValve.clear();
                source.inletTankValve.addAll(widget.configPvd.listOfSelectedSno);
              } else {
                source.outletTankValve.clear();
                source.outletTankValve.addAll(widget.configPvd.listOfSelectedSno);
              }
              widget.configPvd.updateAssignObject(
                sNo: source.commonDetails.sNo!,
                objectId: AppConstants.tankValveObjectId,
                listOfSerialNo: widget.configPvd.listOfSelectedSno,
              );
              widget.configPvd.listOfSelectedSno.clear();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildParameterTileForAgitator(SourceModel source, Color accent) {
    return _buildComponentTile(
      title: 'Agitator',
      imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.agitatorObjectId}.svg',
      names: _namesOf(source.agitator),
      isAssigned: source.agitator.isNotEmpty,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(source.agitator);
        });
        selectionDialogBox(
          context: context,
          title: 'Select Agitator',
          singleSelection: false,
          listOfObject: widget.configPvd.listOfGeneratedObject
              .where((object) => (object.objectId == AppConstants.agitatorObjectId))
              .toList(),
          onPressed: () {
            setState(() {
              source.agitator.clear();
              source.agitator.addAll(widget.configPvd.listOfSelectedSno);
              widget.configPvd.updateAssignObject(
                sNo: source.commonDetails.sNo!,
                objectId: AppConstants.agitatorObjectId,
                listOfSerialNo: widget.configPvd.listOfSelectedSno,
              );
              widget.configPvd.listOfSelectedSno.clear();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildParameterTileForNutrient(SourceModel source, Color accent) {
    final nutrientName = widget.configPvd.getNutrientName(source.nutrient);
    final isAssigned = source.nutrient != 0.0;

    return _buildComponentTile(
      title: 'Nutrient',
      imagePath: '${AppConstants.svgObjectPath}objectId_${AppConstants.channelObjectId}.svg',
      names: isAssigned ? [nutrientName.isNotEmpty ? nutrientName : 'SNo: ${source.nutrient}'] : const [],
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        _showNutrientSelectionDialog(context, source);
      },
    );
  }

  void _showNutrientSelectionDialog(BuildContext context, SourceModel source) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final categories = widget.configPvd.nutrientList;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Nutrient',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _inkColor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (categories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'No nutrients available',
                            style: TextStyle(color: _subTextColor),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: Icon(
                                  source.nutrient == 0.0
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: source.nutrient == 0.0
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade400,
                                ),
                                title: const Text(
                                  'None / Clear Selection',
                                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: _subTextColor),
                                ),
                                onTap: () {
                                  setState(() {
                                    source.nutrient = 0.0;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                              const Divider(height: 1),
                              for (var cat in categories) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                                  child: Text(
                                    cat.category,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                for (var item in cat.list)
                                  ListTile(
                                    dense: true,
                                    leading: Icon(
                                      source.nutrient == item.sNo
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      color: source.nutrient == item.sNo
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade400,
                                    ),
                                    title: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: source.nutrient == item.sNo
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'sNo: ${item.sNo}',
                                      style: const TextStyle(fontSize: 11, color: _subTextColor),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        source.nutrient = item.sNo;
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
