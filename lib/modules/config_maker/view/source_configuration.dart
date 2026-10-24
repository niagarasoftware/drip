import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/device_object_model.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../model/source_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';

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
  static const Color _inkColor = Color(0xFF0F172A); // slate-900 crisp dark text
  static const Color _subTextColor = Color(0xFF64748B); // slate-500 subtle text

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

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final sources = widget.configPvd.source;

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
                  _buildPageHeading(sources.length),
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
                      for (var source in sources)
                        if (_isAquaculture)
                          _buildAquacultureSourceCard(source, primaryColor)
                        else
                          _buildStandardSourceCard(source, primaryColor),
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
          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Source configuration',
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
                'Configure pumps, valves and sensors for your sources',
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
                'SOURCES',
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
  //  CARD SHELL (shared by both card types)
  // ───────────────────────────────────────────────────────────
  Widget _buildCardShell({
    required SourceModel source,
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
                    imagePath: '${AppConstants.svgObjectPath}objectId_1.svg',
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.commonDetails.name ?? 'Source',
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
  //  TYPE SELECTOR (replaces the plain dropdown)
  // ───────────────────────────────────────────────────────────
  Widget _buildTypeSelector(SourceModel source, String currentType, Color primaryColor) {
    return PopupMenuButton<String>(
      tooltip: 'Change source type',
      initialValue: currentType,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
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
          child: Row(
            children: [
              Icon(
                _tankTypeIcons[type] ?? Icons.circle,
                size: 18,
                color: selected ? primaryColor : Colors.grey.shade600,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 14,
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
            Icon(_tankTypeIcons[currentType] ?? Icons.circle, size: 14, color: primaryColor),
            const SizedBox(width: 5),
            Text(
              currentType,
              style: TextStyle(
                fontSize: 12,
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

        // ── Sensors ──
        if (showSensors) _buildSensorsSection(source, progress, primaryColor),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  SENSORS (collapsible, 2-column grid)
  // ───────────────────────────────────────────────────────────
  Widget _buildSensorsSection(SourceModel source, _Progress progress, Color primaryColor) {
    final active = progress.sensorFilled > 0;

    Widget pair(int a, int b) => Row(
      children: [
        Expanded(child: _buildParameterTileForSensor(source, a, primaryColor)),
        const SizedBox(width: 8),
        Expanded(child: _buildParameterTileForSensor(source, b, primaryColor)),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _subTextColor),
        ),
        child: ExpansionTile(
          key: PageStorageKey('sensors_${source.commonDetails.sNo}'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: active ? primaryColor.withValues(alpha: 0.12) : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sensors_rounded,
              size: 16,
              color: active ? primaryColor : Colors.grey.shade600,
            ),
          ),
          title: Row(
            children: [
              const Flexible(
                child: Text(
                  'Level and sensors',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _inkColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? primaryColor.withValues(alpha: 0.12) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${progress.sensorFilled}/6 active',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: active ? primaryColor : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 4),
            pair(1, 6),
            const SizedBox(height: 8),
            pair(2, 3),
            const SizedBox(height: 8),
            pair(4, 5),
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
        color: isAssigned ? accent.withValues(alpha: 0.08) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isAssigned ? accent.withValues(alpha: 0.4) : Colors.grey.shade300,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: SizedImage(
                    imagePath: imagePath,
                    color: isAssigned ? accent : Colors.grey.shade500,
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
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAssigned ? names.join(', ') : 'Tap to add',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isAssigned ? FontWeight.w700 : FontWeight.w500,
                          fontStyle: isAssigned ? FontStyle.normal : FontStyle.italic,
                          color: isAssigned ? accent : Colors.grey.shade400,
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            children: [
              // Icon badge
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

              // Label + chips
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
                    const SizedBox(height: 4),
                    if (isAssigned)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final name in names)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: accent.withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                        ],
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

              // Action
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