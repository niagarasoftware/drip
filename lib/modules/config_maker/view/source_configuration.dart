import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/device_object_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../model/source_model.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/object_manager_bar.dart';
import '../../../Widgets/sized_image.dart';
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
                  _buildPageHeading(sources.length, primaryColor),
                  const SizedBox(height: 18),
                  if (sources.isEmpty)
                    _buildEmptyState(primaryColor)
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

  Widget _buildEmptyState(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF13172E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF20274B)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.waves_rounded, size: 48, color: primaryColor.withValues(alpha: 0.8)),
          const SizedBox(height: 12),
          const Text(
            'No Water Sources Added',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap the button below to add a water source to your configuration.',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E9BB4)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addSource,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  PAGE INTRO
  // ───────────────────────────────────────────────────────────
  Widget _buildPageHeading(int total, Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.tune_rounded, color: primaryColor, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Source configuration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$total ${total == 1 ? 'source' : 'sources'}',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Configure pumps, valves and sensors for your sources',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF8E9BB4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _addSource,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Source',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildSourcePainterLeading(int sourceType) {
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
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF181C38),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: painter,
        size: const Size(88, 88),
      ),
    );
  }

  Widget _buildSourceHeaderBlock({
    required SourceModel source,
    required _Progress progress,
    required Color primaryColor,
    Widget? typeSelector,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF181C38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSourcePainterLeading(source.sourceType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.commonDetails.name ?? 'Source',
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
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  CARD SHELL (shared by both card types)
  // ───────────────────────────────────────────────────────────
  Widget _buildCardShell({
    required SourceModel source,
    required _Progress progress,
    required Color primaryColor,
    Widget? typeSelector,
    required List<Widget> body,
    Widget? footer,
  }) {
    final sourceHeaderBlock = _buildSourceHeaderBlock(
      source: source,
      progress: progress,
      primaryColor: primaryColor,
      typeSelector: typeSelector,
    );

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxW = constraints.maxWidth;
          final bool isUltraWide = maxW >= 880 && body.isNotEmpty;
          final bool isMediumWide = maxW >= 620;

          if (isUltraWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 280,
                        child: sourceHeaderBlock,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildBodyGrid(body, wide: true),
                      ),
                    ],
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 10),
                  footer,
                ],
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sourceHeaderBlock,
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildBodyGrid(body, wide: isMediumWide),
                ],
                if (footer != null) ...[
                  const SizedBox(height: 10),
                  footer,
                ],
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildBodyGrid(List<Widget> body, {required bool wide}) {
    if (body.isEmpty) return const SizedBox();

    if (wide) {
      final rows = <Widget>[];
      for (var i = 0; i < body.length; i += 2) {
        final hasPair = i + 1 < body.length;
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: body[i]),
                if (hasPair) ...[
                  const SizedBox(width: 10),
                  Expanded(child: body[i + 1]),
                ],
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
        children: _withGaps(body, 10),
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
  //  TYPE SELECTOR (replaces the plain dropdown)
  // ───────────────────────────────────────────────────────────
  Widget _buildTypeSelector(SourceModel source, String currentType, Color primaryColor) {
    const activeAccent = Color(0xFF38BDF8); // Bright sky blue accent for high visibility

    return PopupMenuButton<String>(
      tooltip: 'Change source type',
      initialValue: currentType,
      color: const Color(0xFF181C38),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2B335C)),
      ),
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
      itemBuilder: (context) => _tankTypeList.map((type) {
        final selected = type == currentType;
        return PopupMenuItem<String>(
          value: type,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? activeAccent.withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _tankTypeIcons[type] ?? Icons.circle,
                  size: 18,
                  color: selected ? activeAccent : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? activeAccent : Colors.white,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, size: 18, color: activeAccent),
              ],
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2648),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activeAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_tankTypeIcons[currentType] ?? Icons.circle, size: 14, color: activeAccent),
            const SizedBox(width: 6),
            Text(
              currentType,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, size: 18, color: activeAccent),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  AQUACULTURE SOURCE CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildAquacultureSourceCard(SourceModel source, Color primaryColor) {
    final progress = _calcProgress(source);

    return _buildCardShell(
      source: source,
      progress: progress,
      primaryColor: primaryColor,
      body: [
        _buildFlowSection(
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

    return _buildCardShell(
      source: source,
      progress: progress,
      primaryColor: primaryColor,
      typeSelector: _buildTypeSelector(source, currentTankType, primaryColor),
      body: [
        // ── Nutrient ──
        if (isFertilizerSource)
          _buildFlowSection(
            title: 'Nutrient',
            icon: Icons.science_rounded,
            accent: primaryColor,
            children: [
              _buildParameterTileForNutrient(source, primaryColor),
            ],
          ),

        // ── Inlet ──
        if (!isBoreOrPond)
          _buildFlowSection(
            title: 'Inlet',
            icon: Icons.south_west_rounded,
            accent: _inletColor,
            children: [
              if (!isFertilizerSource) _buildParameterTileForPump(source, 1, _inletColor),
              _buildParameterTileForTankValve(source, true, _inletColor),
            ],
          ),

        // ── Outlet ──
        _buildFlowSection(
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
          _buildFlowSection(
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
    final active = progress.sensorFilled > 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181C38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _subTextColor),
        ),
        child: ExpansionTile(
          key: PageStorageKey('sensors_${source.commonDetails.sNo}'),
          dense: true,
          visualDensity: const VisualDensity(vertical: -3),
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: active ? primaryColor.withValues(alpha: 0.18) : const Color(0xFF12162B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sensors_rounded,
              size: 14,
              color: active ? primaryColor : const Color(0xFF8E9BB4),
            ),
          ),
          title: Row(
            children: [
              const Flexible(
                child: Text(
                  'Level and sensors',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: active ? primaryColor.withValues(alpha: 0.18) : const Color(0xFF12162B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${progress.sensorFilled}/6 active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: active ? primaryColor : const Color(0xFF8E9BB4),
                  ),
                ),
              ),
            ],
          ),
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
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  FLOW SECTION (Inlet / Outlet / Mixing)
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
          color: accent.withValues(alpha: 0.18),
        ));
      }
      rows.add(children[i]);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF181C38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 13, color: accent),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
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
  //  COMPONENT TILE
  //  Row style (default): icon, label, assigned chips, action.
  //  Compact style: small bordered box used in the sensor grid.
  // ───────────────────────────────────────────────────────────
  Widget _buildComponentTile({
    required String title,
    required String imagePath,
    required List<String> names,
    required bool isAssigned,
    required VoidCallback onTap,
    required Color accent,
    bool compact = false,
  }) {
    if (compact) {
      return Material(
        color: isAssigned ? accent.withValues(alpha: 0.15) : const Color(0xFF12162B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isAssigned
              ? BorderSide(color: accent.withValues(alpha: 0.5))
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: SizedImage(
                    imagePath: imagePath,
                    color: isAssigned ? accent : const Color(0xFF8E9BB4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC0CCE0),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAssigned ? names.join(', ') : 'Tap to add',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isAssigned ? FontWeight.bold : FontWeight.w500,
                          fontStyle: isAssigned ? FontStyle.normal : FontStyle.italic,
                          color: isAssigned ? accent : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isAssigned ? accent.withValues(alpha: 0.18) : const Color(0xFF12162B),
                  borderRadius: BorderRadius.circular(8),
                  border: isAssigned ? Border.all(color: accent.withValues(alpha: 0.4)) : null,
                ),
                child: SizedImage(
                  imagePath: imagePath,
                  color: isAssigned ? accent : const Color(0xFF8E9BB4),
                ),
              ),
              const SizedBox(width: 10),

              // Label + chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (isAssigned)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final name in names)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF12162B),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: accent.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ),
                        ],
                      )
                    else
                      const Text(
                        'Not assigned',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action
              isAssigned
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.edit_rounded, size: 17, color: accent),
                    )
                  : Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded, size: 17, color: accent),
                    ),
            ],
          ),
        ),
      ),
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