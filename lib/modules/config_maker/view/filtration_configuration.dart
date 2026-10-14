import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../model/device_object_model.dart';
import '../model/filtration_model.dart';
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

class FiltrationConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const FiltrationConfiguration({super.key, required this.configPvd});

  @override
  State<FiltrationConfiguration> createState() => _FiltrationConfigurationState();
}

class _FiltrationConfigurationState extends State<FiltrationConfiguration> {
  // ── Design tokens (Matching pump_configuration.dart Light Mode) ──
  static const Color _inletColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _outletColor = Color(0xFF059669); // emerald green
  static const Color _doneColor = Color(0xFF059669); // emerald green
  static const Color _inkColor = Color(0xFF0F172A); // slate-900 crisp dark text
  static const Color _subTextColor = Color(0xFF64748B); // slate-500 subtle text

  // ───────────────────────────────────────────────────────────
  //  PROGRESS CALCULATION
  // ───────────────────────────────────────────────────────────
  _Progress _calcProgress(FiltrationModel site) {
    int total = 3;
    int filled = 0;
    if (site.filters.isNotEmpty) filled++;
    if (site.pressureIn != 0.0) filled++;
    if (site.pressureOut != 0.0) filled++;

    return _Progress(filled, total, filled);
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final filtrations = widget.configPvd.filtration;

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
                  _buildPageHeading(filtrations.length),
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
                      for (var site in filtrations)
                        _buildFiltrationCard(site, primaryColor),
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
          child: const Icon(Icons.filter_alt_rounded, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtration configuration',
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
                'Configure site mode, filters, filter types, and pressure sensors',
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
                'SITES',
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
  //  FILTRATION CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildFiltrationCard(FiltrationModel site, Color primaryColor) {
    final progress = _calcProgress(site);

    return _buildCardShell(
      site: site,
      progress: progress,
      primaryColor: primaryColor,
      typeSelector: _buildSiteModeSelector(site, primaryColor),
      body: [
        _buildFlowSection(
          title: 'Filters & Types',
          icon: Icons.tune_rounded,
          accent: _inletColor,
          children: [
            _buildFiltersTile(site, _inletColor),
            if (site.filters.isNotEmpty) ...[
              for (int i = 0; i < site.filters.length; i++)
                _buildFilterItemTile(site, i, _inletColor),
            ],
          ],
        ),
        _buildFlowSection(
          title: 'Pressure Sensors',
          icon: Icons.speed_rounded,
          accent: _outletColor,
          children: [
            _buildPressureTile(site, 1, _outletColor),
            _buildPressureTile(site, 2, _outletColor),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  CARD SHELL
  // ───────────────────────────────────────────────────────────
  Widget _buildCardShell({
    required FiltrationModel site,
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
                    imagePath: '${AppConstants.svgObjectPath}objectId_4.svg',
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.commonDetails.name ?? 'Filtration',
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
  //  SITE MODE SELECTOR
  // ───────────────────────────────────────────────────────────
  Widget _buildSiteModeSelector(FiltrationModel site, Color primaryColor) {
    final currentType = getCentralLocalCodeToString(site.siteMode);
    const modeTypes = ['Central', 'Local'];
    const modeIcons = {
      'Central': Icons.hub_rounded,
      'Local': Icons.location_on_rounded,
    };

    return PopupMenuButton<String>(
      tooltip: 'Change site mode',
      initialValue: currentType,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      onSelected: (value) {
        setState(() {
          site.siteMode = getCentralLocalStringToCode(value);
        });
      },
      itemBuilder: (context) => modeTypes.map((type) {
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
                  type,
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

  Widget _buildFiltersTile(FiltrationModel site, Color accent) {
    int objectId = 11;
    bool isAssigned = site.filters.isNotEmpty;
    String assignedName = isAssigned
        ? site.filters.map((filter) => getObjectName(filter.sNo, widget.configPvd).name ?? '-').join(', ')
        : '';

    return _buildTile(
      title: 'Filter',
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      assignedName: assignedName,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          List<double> listOfFilterSno = site.filters.map((filter) => filter.sNo).toList();
          widget.configPvd.listOfSelectedSno.addAll(listOfFilterSno);
        });
        selectionDialogBox(
          context: context,
          title: 'Select Filters',
          singleSelection: false,
          listOfObject: getUnselectedFilterObject(site),
          onPressed: () {
            setState(() {
              site.filters.clear();
              List<Filter> listOfFilter = widget.configPvd.listOfSelectedSno
                  .map((sNo) => Filter.fromJson({"sNo": sNo, "filterMode": 1}))
                  .toList();
              site.filters.addAll(listOfFilter);
              widget.configPvd.listOfSelectedSno.clear();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildFilterItemTile(FiltrationModel site, int index, Color accent) {
    final filter = site.filters[index];
    final filterName = getObjectName(filter.sNo, widget.configPvd).name ?? 'Filter ${index + 1}';
    final isDisc = filter.filterMode == 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedImage(
              imagePath: '${AppConstants.svgObjectPath}objectId_11.svg',
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filterName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _inkColor,
                  ),
                ),
                Text(
                  isDisc ? 'Disc Filter' : 'Sand Filter',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _subTextColor,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<int>(
            tooltip: 'Select filter type',
            initialValue: filter.filterMode,
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            onSelected: (value) {
              setState(() {
                widget.configPvd.updateFilterMode(site, index, value);
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(
                      Icons.waves_rounded,
                      size: 16,
                      color: filter.filterMode == 1 ? accent : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sand filter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: filter.filterMode == 1 ? FontWeight.w700 : FontWeight.w500,
                        color: filter.filterMode == 1 ? accent : _inkColor,
                      ),
                    ),
                    if (filter.filterMode == 1) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check_rounded, size: 16, color: accent),
                    ],
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 2,
                child: Row(
                  children: [
                    Icon(
                      Icons.disc_full_rounded,
                      size: 16,
                      color: filter.filterMode == 2 ? accent : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Disc filter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: filter.filterMode == 2 ? FontWeight.w700 : FontWeight.w500,
                        color: filter.filterMode == 2 ? accent : _inkColor,
                      ),
                    ),
                    if (filter.filterMode == 2) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check_rounded, size: 16, color: accent),
                    ],
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isDisc ? 'Disc' : 'Sand',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, size: 16, color: accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureTile(FiltrationModel site, int pressureMode, Color accent) {
    int objectId = 24;
    String objectName = pressureMode == 1 ? 'Pressure In' : 'Pressure Out';
    double currentSno = pressureMode == 1 ? site.pressureIn : site.pressureOut;
    bool isAssigned = currentSno != 0.0;
    String assignedName = isAssigned ? getObjectName(currentSno, widget.configPvd).name ?? '-' : '';

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
          listOfObject: getPressureSensor(site, pressureMode),
          onPressed: () {
            setState(() {
              if (pressureMode == 1) {
                site.pressureIn = widget.configPvd.selectedSno;
              } else {
                site.pressureOut = widget.configPvd.selectedSno;
              }
              widget.configPvd.selectedSno = 0.0;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  List<DeviceObjectModel> getUnselectedFilterObject(FiltrationModel filtrationSite) {
    List<DeviceObjectModel> filterObject = widget.configPvd.listOfGeneratedObject
        .where((object) => object.objectId == 11)
        .toList();
    List<double> assignedFilters = [];
    for (var site in widget.configPvd.filtration) {
      for (var filter in site.filters) {
        assignedFilters.add(filter.sNo);
      }
    }
    List<double> filterSnoOfFiltrationSite = filtrationSite.filters.map((filter) => filter.sNo).toList();
    filterObject = filterObject.where((object) => (!assignedFilters.contains(object.sNo!) || filterSnoOfFiltrationSite.contains(object.sNo))).toList();
    return filterObject;
  }

  List<DeviceObjectModel> getPressureSensor(FiltrationModel filtrationSite, int pressureMode) {
    List<double> assignedPressureSensor = [];
    List<double> sensorList = [];
    for (var filtration in widget.configPvd.filtration) {
      if (filtration.pressureIn != 0.0) {
        assignedPressureSensor.add(filtration.pressureIn);
      }
      if (filtration.pressureOut != 0.0) {
        assignedPressureSensor.add(filtration.pressureOut);
      }
    }
    for (var object in widget.configPvd.listOfGeneratedObject) {
      double currentPressureSno = pressureMode == 1 ? filtrationSite.pressureIn : filtrationSite.pressureOut;
      if (currentPressureSno == object.sNo || (!assignedPressureSensor.contains(object.sNo) && object.objectId == 24)) {
        sensorList.add(object.sNo!);
      }
    }
    return widget.configPvd.listOfGeneratedObject.where((generatedObject) => sensorList.contains(generatedObject.sNo)).toList();
  }
}

enum FiltrationFormation { singleFilter, multipleFilter }

class FiltrationDashboardFormation extends StatefulWidget {
  final FiltrationFormation filtrationFormation;
  final FiltrationModel filtrationSite;
  const FiltrationDashboardFormation({
    super.key,
    required this.filtrationFormation,
    required this.filtrationSite,
  });

  @override
  State<FiltrationDashboardFormation> createState() => _FiltrationDashboardFormationState();
}

class _FiltrationDashboardFormationState extends State<FiltrationDashboardFormation> {
  late ConfigMakerProvider configPvd;

  @override
  void initState() {
    super.initState();
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: true);
    if (widget.filtrationFormation == FiltrationFormation.singleFilter) {
      return singleFilter();
    } else {
      return multipleFilter();
    }
  }

  Widget firstHorizontalPipe() {
    return SizedBox(
      width: 60 * configPvd.ratio,
      height: 150 * configPvd.ratio,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/Images/Filtration/horizontal_pipe_4.svg',
              width: 60,
              height: 8 * configPvd.ratio,
            ),
          ),
          Positioned(
            top: 22 * configPvd.ratio,
            right: 0,
            child: SvgPicture.asset(
              'assets/Images/Filtration/horizontal_pipe_0.svg',
              width: 60,
              height: 8 * configPvd.ratio,
            ),
          ),
          if (widget.filtrationSite.pressureIn != 0.0)
            Positioned(
              top: 30,
              left: 15,
              child: Image.asset(
                'assets/Images/Png/objectId_24.png',
                width: 30,
                height: 30,
              ),
            ),
        ],
      ),
    );
  }

  Widget secondHorizontalPipe() {
    return SizedBox(
      width: 60,
      height: 150 * configPvd.ratio,
      child: Stack(
        children: [
          Positioned(
            bottom: 2 * configPvd.ratio,
            child: SvgPicture.asset(
              'assets/Images/Filtration/horizontal_pipe_4.svg',
              width: 60 * configPvd.ratio,
              height: 8 * configPvd.ratio,
            ),
          ),
          if (widget.filtrationSite.pressureOut != 0.0)
            Positioned(
              right: 15,
              bottom: 10,
              child: Image.asset(
                'assets/Images/Png/objectId_24.png',
                width: 30,
                height: 30,
              ),
            ),
        ],
      ),
    );
  }

  Widget singleFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        firstHorizontalPipe(),
        Stack(
          children: [
            FilterModeSelectionWidget(
                filterIndex: 0,
                filtrationSite: widget.filtrationSite,
                child: SvgPicture.asset(
                  'assets/Images/Filtration/single_filter_4.svg',
                  width: 150,
                  height: 150 * configPvd.ratio,
                )),
            if (widget.filtrationSite.filters[0].filterMode == 2)
              Positioned(
                bottom: 40,
                left: 47,
                child: FilterModeSelectionWidget(
                    filtrationSite: widget.filtrationSite,
                    filterIndex: 0,
                    child: SvgPicture.asset(
                      'assets/Images/Filtration/disc.svg',
                      color: Theme.of(context).primaryColor,
                      width: 50,
                      height: 50 * configPvd.ratio,
                    )),
              ),
            Positioned(
              left: 20,
              top: 6 * configPvd.ratio,
              child: Text(
                getObjectName(widget.filtrationSite.filters[0].sNo, configPvd).name!,
                style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        secondHorizontalPipe(),
      ],
    );
  }

  Widget multipleFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        firstHorizontalPipe(),
        if (widget.filtrationSite.filters.isNotEmpty)
          multipleFilterFirstFilter(
            widget.filtrationSite.filters[0].sNo,
          ),
        if (widget.filtrationSite.filters.length > 2)
          for (var middleFilter = 1; middleFilter < widget.filtrationSite.filters.length - 1; middleFilter++)
            multipleFilterMiddleFilter(widget.filtrationSite.filters[middleFilter].sNo),
        if (widget.filtrationSite.filters.length > 1)
          multipleFilterLastFilter(widget.filtrationSite.filters[widget.filtrationSite.filters.length - 1].sNo),
        secondHorizontalPipe(),
      ],
    );
  }

  Widget multipleFilterFirstFilter(double filterSno) {
    return Stack(
      children: [
        FilterModeSelectionWidget(
          filterIndex: 0,
          filtrationSite: widget.filtrationSite,
          child: SvgPicture.asset(
            'assets/Images/Filtration/multiple_filter_first_4.svg',
            width: 150,
            height: 150 * configPvd.ratio,
          ),
        ),
        if (widget.filtrationSite.filters[0].filterMode == 2)
          Positioned(
            bottom: 40,
            left: 37,
            child: FilterModeSelectionWidget(
                filtrationSite: widget.filtrationSite,
                filterIndex: 0,
                child: SvgPicture.asset(
                  'assets/Images/Filtration/disc.svg',
                  color: Theme.of(context).primaryColor,
                  width: 50,
                  height: 50 * configPvd.ratio,
                )),
          ),
        Positioned(
          top: 20 * configPvd.ratio,
          child: SvgPicture.asset(
            'assets/Images/Filtration/multiple_filter_first_backwash_pipe_0.svg',
            width: 150,
            height: 17.3 * configPvd.ratio,
          ),
        ),
        Positioned(
          left: 20,
          top: 6,
          child: Text(
            getObjectName(filterSno, configPvd).name!,
            style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget multipleFilterMiddleFilter(double filterSno) {
    int filterIndex = widget.filtrationSite.filters.indexWhere((filter) => filter.sNo == filterSno);
    return Stack(
      children: [
        FilterModeSelectionWidget(
          filterIndex: filterIndex,
          filtrationSite: widget.filtrationSite,
          child: SvgPicture.asset(
            'assets/Images/Filtration/multiple_filter_middle_4.svg',
            width: 150,
            height: 150 * configPvd.ratio,
          ),
        ),
        if (widget.filtrationSite.filters[filterIndex].filterMode == 2)
          Positioned(
            bottom: 40,
            left: 47,
            child: FilterModeSelectionWidget(
                filtrationSite: widget.filtrationSite,
                filterIndex: filterIndex,
                child: SvgPicture.asset(
                  'assets/Images/Filtration/disc.svg',
                  width: 50,
                  height: 50 * configPvd.ratio,
                  color: Theme.of(context).primaryColor,
                )),
          ),
        Positioned(
          top: 20 * configPvd.ratio,
          child: SvgPicture.asset(
            'assets/Images/Filtration/multiple_filter_middle_backwash_pipe_0.svg',
            width: 150,
            height: 17.1 * configPvd.ratio,
          ),
        ),
        Positioned(
          left: 20,
          top: 6,
          child: Text(
            getObjectName(filterSno, configPvd).name!,
            style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget multipleFilterLastFilter(double filterSno) {
    return Stack(
      children: [
        FilterModeSelectionWidget(
          filterIndex: widget.filtrationSite.filters.length - 1,
          filtrationSite: widget.filtrationSite,
          child: SvgPicture.asset(
            'assets/Images/Filtration/multiple_filter_last_4.svg',
            width: 150,
            height: 150 * configPvd.ratio,
          ),
        ),
        if (widget.filtrationSite.filters[widget.filtrationSite.filters.length - 1].filterMode == 2)
          Positioned(
            bottom: 40,
            left: 47,
            child: FilterModeSelectionWidget(
                filtrationSite: widget.filtrationSite,
                filterIndex: widget.filtrationSite.filters.length - 1,
                child: SvgPicture.asset(
                  'assets/Images/Filtration/disc.svg',
                  width: 50,
                  height: 50 * configPvd.ratio,
                  color: Theme.of(context).primaryColor,
                )),
          ),
        Positioned(
          bottom: 0,
          child: SvgPicture.asset(
            'assets/Images/Filtration/multiple_filter_last_bottom_filtration_pipe_4.svg',
            width: 150,
            height: 17 * configPvd.ratio,
          ),
        ),
        Positioned(
          left: 20,
          top: 6,
          child: Text(
            getObjectName(filterSno, configPvd).name!,
            style: TextStyle(fontSize: 12 * configPvd.ratio, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class FilterModeSelectionWidget extends StatefulWidget {
  final FiltrationModel filtrationSite;
  final Widget child;
  final int filterIndex;
  const FilterModeSelectionWidget({super.key, required this.child, required this.filtrationSite, required this.filterIndex});

  @override
  State<FilterModeSelectionWidget> createState() => _FilterModeSelectionWidgetState();
}

class _FilterModeSelectionWidgetState extends State<FilterModeSelectionWidget> {
  late ConfigMakerProvider configPvd;

  @override
  void initState() {
    super.initState();
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: true);
    return InkWell(
      child: widget.child,
      onTap: () {
        showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(builder: (context, stateSetter) {
                return AlertDialog(
                  title: const Text('Select Filter Type'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile(
                          title: const Text("Sand filter"),
                          value: 1,
                          groupValue: widget.filtrationSite.filters[widget.filterIndex].filterMode,
                          onChanged: (value) {
                            stateSetter(() {
                              setState(() {
                                configPvd.updateFilterMode(widget.filtrationSite, widget.filterIndex, value!);
                              });
                            });
                          }),
                      RadioListTile(
                        title: const Text("Disc filter"),
                        value: 2,
                        groupValue: widget.filtrationSite.filters[widget.filterIndex].filterMode,
                        onChanged: (value) {
                          stateSetter(() {
                            setState(() {
                              configPvd.updateFilterMode(widget.filtrationSite, widget.filterIndex, value!);
                            });
                          });
                        },
                      )
                    ],
                  ),
                );
              });
            });
      },
    );
  }
}
