import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../model/device_object_model.dart';
import '../model/fertigation_model.dart';
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

class FertilizationConfiguration extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const FertilizationConfiguration({super.key, required this.configPvd});

  @override
  State<FertilizationConfiguration> createState() => _FertilizationConfigurationState();
}

class _FertilizationConfigurationState extends State<FertilizationConfiguration> {
  // ── Design tokens (Matching filtration_configuration.dart) ──
  static const Color _channelColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _boosterColor = Color(0xFF059669); // emerald green
  static const Color _sensorColor = Color(0xFF8B5CF6); // violet
  static const Color _doneColor = Color(0xFF059669); // emerald green
  static const Color _inkColor = Color(0xFF0F172A); // slate-900 crisp dark text
  static const Color _subTextColor = Color(0xFF64748B); // slate-500 subtle text

  bool _shouldShowParameter(int objectId, List<double> currentParameterValue) {
    return currentParameterValue.isNotEmpty ||
        widget.configPvd.listOfGeneratedObject.any(
          (object) => object.objectId == objectId && object.controllerId != null,
        );
  }

  // ───────────────────────────────────────────────────────────
  //  PROGRESS CALCULATION
  // ───────────────────────────────────────────────────────────
  _Progress _calcProgress(FertilizationModel site) {
    int total = 0;
    int filled = 0;

    final channelSnoList = site.channel.map((c) => c.sNo).toList();
    if (_shouldShowParameter(10, channelSnoList)) {
      total++;
      if (site.channel.isNotEmpty) filled++;
    }
    if (_shouldShowParameter(7, site.boosterPump)) {
      total++;
      if (site.boosterPump.isNotEmpty) filled++;
    }
    if (_shouldShowParameter(9, site.agitator)) {
      total++;
      if (site.agitator.isNotEmpty) filled++;
    }
    if (_shouldShowParameter(8, site.selector)) {
      total++;
      if (site.selector.isNotEmpty) filled++;
    }
    if (_shouldShowParameter(27, site.ec)) {
      total++;
      if (site.ec.isNotEmpty) filled++;
    }
    if (_shouldShowParameter(28, site.ph)) {
      total++;
      if (site.ph.isNotEmpty) filled++;
    }

    if (total == 0) {
      total = 1;
      if (site.channel.isNotEmpty) filled = 1;
    }

    return _Progress(filled, total, filled);
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final fertilizations = widget.configPvd.fertilization;

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
                  _buildPageHeading(fertilizations.length),
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
                      for (var site in fertilizations)
                        _buildFertilizationCard(site, primaryColor),
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
          child: const Icon(Icons.science_rounded, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fertilization configuration',
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
                'Configure site mode, channels, booster pumps, agitators, selectors, EC and pH sensors',
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
  //  FERTILIZATION CARD
  // ───────────────────────────────────────────────────────────
  Widget _buildFertilizationCard(FertilizationModel site, Color primaryColor) {
    final progress = _calcProgress(site);

    final channelSnoList = site.channel.map((c) => c.sNo).toList();
    final showChannels = _shouldShowParameter(10, channelSnoList);
    final showBooster = _shouldShowParameter(7, site.boosterPump);
    final showAgitator = _shouldShowParameter(9, site.agitator);
    final showSelector = _shouldShowParameter(8, site.selector);
    final showEc = _shouldShowParameter(27, site.ec);
    final showPh = _shouldShowParameter(28, site.ph);

    final showPumpsAgitators = showBooster || showAgitator;
    final showSensors = showSelector || showEc || showPh;

    final bodySections = <Widget>[];

    if (showChannels || (!showPumpsAgitators && !showSensors)) {
      bodySections.add(
        _buildFlowSection(
          title: 'Channels & Injectors',
          icon: Icons.tune_rounded,
          accent: _channelColor,
          children: [
            _buildChannelsTile(site, _channelColor),
          ],
        ),
      );
    }

    if (showPumpsAgitators) {
      bodySections.add(
        _buildFlowSection(
          title: 'Booster & Agitator',
          icon: Icons.speed_rounded,
          accent: _boosterColor,
          children: [
            if (showBooster)
              _buildParameterTile(
                site: site,
                currentParameterValue: site.boosterPump,
                parameterType: 2,
                objectId: 7,
                objectName: 'Booster Pump',
                accent: _boosterColor,
              ),
            if (showAgitator)
              _buildParameterTile(
                site: site,
                currentParameterValue: site.agitator,
                parameterType: 3,
                objectId: 9,
                objectName: 'Agitator',
                accent: _boosterColor,
              ),
          ],
        ),
      );
    }

    if (showSensors) {
      bodySections.add(
        _buildFlowSection(
          title: 'Control & Monitoring',
          icon: Icons.sensors_rounded,
          accent: _sensorColor,
          children: [
            if (showSelector)
              _buildParameterTile(
                site: site,
                currentParameterValue: site.selector,
                parameterType: 4,
                objectId: 8,
                objectName: 'Selector',
                accent: _sensorColor,
              ),
            if (showEc)
              _buildParameterTile(
                site: site,
                currentParameterValue: site.ec,
                parameterType: 5,
                objectId: 27,
                objectName: 'EC Sensor',
                accent: _sensorColor,
              ),
            if (showPh)
              _buildParameterTile(
                site: site,
                currentParameterValue: site.ph,
                parameterType: 6,
                objectId: 28,
                objectName: 'pH Sensor',
                accent: _sensorColor,
              ),
          ],
        ),
      );
    }

    return _buildCardShell(
      site: site,
      progress: progress,
      primaryColor: primaryColor,
      typeSelector: _buildSiteModeSelector(site, primaryColor),
      body: bodySections,
    );
  }

  // ───────────────────────────────────────────────────────────
  //  CARD SHELL
  // ───────────────────────────────────────────────────────────
  Widget _buildCardShell({
    required FertilizationModel site,
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
                    imagePath: '${AppConstants.svgObjectPath}objectId_3.svg',
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.commonDetails.name ?? 'Fertilization',
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
  Widget _buildSiteModeSelector(FertilizationModel site, Color primaryColor) {
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

  Widget _buildChannelsTile(FertilizationModel site, Color accent) {
    int objectId = 10;
    bool isAssigned = site.channel.isNotEmpty;
    List<double> channelSnoList = site.channel.map((channel) => channel.sNo).toList();
    String assignedName = isAssigned
        ? channelSnoList.map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-').join(', ')
        : '';

    return _buildTile(
      title: 'Channels',
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      assignedName: assignedName,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(channelSnoList);
        });
        selectionDialogBox(
          context: context,
          title: 'Select Channels',
          singleSelection: false,
          listOfObject: getUnselectedFertilizationParameterObject(
            currentParameterList: channelSnoList,
            objectId: objectId,
            parameter: 1,
          ),
          onPressed: () {
            if (widget.configPvd.listOfSelectedSno.length > 20) {
              simpleDialogBox(
                context: context,
                title: 'Alert',
                message: 'Only 20 injectors can be selected per site.',
              );
            } else {
              setState(() {
                widget.configPvd.updateSelectionInFertilization(site.commonDetails.sNo!, 1);
              });
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }

  Widget _buildParameterTile({
    required FertilizationModel site,
    required List<double> currentParameterValue,
    required int parameterType,
    required int objectId,
    required String objectName,
    required Color accent,
  }) {
    bool isAssigned = currentParameterValue.isNotEmpty;
    String assignedName = isAssigned
        ? currentParameterValue.map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-').join(', ')
        : '';

    return _buildTile(
      title: objectName,
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      assignedName: assignedName,
      isAssigned: isAssigned,
      accent: accent,
      onTap: () {
        setState(() {
          widget.configPvd.listOfSelectedSno.clear();
          widget.configPvd.listOfSelectedSno.addAll(currentParameterValue);
        });
        selectionDialogBox(
          context: context,
          title: 'Select $objectName',
          singleSelection: false,
          listOfObject: getUnselectedFertilizationParameterObject(
            currentParameterList: currentParameterValue,
            objectId: objectId,
            parameter: parameterType,
          ),
          onPressed: () {
            setState(() {
              widget.configPvd.updateSelectionInFertilization(site.commonDetails.sNo!, parameterType);
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  List<DeviceObjectModel> getUnselectedFertilizationParameterObject({
    required List<double> currentParameterList,
    required int objectId,
    required int parameter,
  }) {
    List<DeviceObjectModel> listOfObject = widget.configPvd.listOfGeneratedObject
        .where((object) => object.objectId == objectId && object.controllerId != null)
        .toList();
    List<double> assigned = [];
    if (![AppConstants.ecObjectId, AppConstants.phObjectId, AppConstants.boosterObjectId, AppConstants.agitatorObjectId].contains(objectId)) {
      for (var site in widget.configPvd.fertilization) {
        List<double> siteParameter = parameter == 1
            ? site.channel.map((channel) => channel.sNo).toList()
            : parameter == 2
            ? site.boosterPump
            : parameter == 3
            ? site.agitator
            : parameter == 4
            ? site.selector
            : parameter == 5
            ? site.ec
            : site.ph;
        assigned.addAll(siteParameter);
      }
    }
    listOfObject = listOfObject
        .where((object) => (!assigned.contains(object.sNo!) || currentParameterList.contains(object.sNo)))
        .toList();
    return listOfObject;
  }
}

Widget getImageWithText(String title, String imagePath, ConfigMakerProvider configPvd) {
  return IntrinsicWidth(
    stepWidth: 150 * configPvd.ratio,
    child: ListTile(
      title: Text(title),
      leading: SizedImage(imagePath: imagePath, color: Colors.black),
    ),
  );
}

enum FertilizationFormation { singleChannel, multipleChannel }

class FertilizationDashboardFormation extends StatefulWidget {
  final FertilizationFormation fertilizationFormation;
  final FertilizationModel fertilizationSite;
  const FertilizationDashboardFormation({
    super.key,
    required this.fertilizationFormation,
    required this.fertilizationSite,
  });
  @override
  State<FertilizationDashboardFormation> createState() => _FertilizationDashboardFormationState();
}

class _FertilizationDashboardFormationState extends State<FertilizationDashboardFormation> {
  late ConfigMakerProvider configPvd;

  @override
  void initState() {
    super.initState();
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: true);
    if (widget.fertilizationFormation == FertilizationFormation.singleChannel) {
      return getSingleChannel();
    } else {
      return getMultipleChannel();
    }
  }

  Widget getSingleChannel() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                ...getAgitator(),
                if (widget.fertilizationSite.agitator.isNotEmpty)
                  SvgPicture.asset(
                    'assets/Images/Fertilization/agitator_connection_pipe_last_1.svg',
                    width: 151,
                    height: 45 * configPvd.ratio,
                  ),
              ],
            ),
            Row(
              children: [
                ...getBooster(),
                SvgPicture.asset(
                  'assets/Images/Fertilization/single_channel_1.svg',
                  width: 150,
                  height: 150 * configPvd.ratio,
                ),
              ],
            ),
          ],
        ),
        getEcPhSelector()
      ],
    );
  }

  List<Widget> getAgitator() {
    return [
      if (widget.fertilizationSite.agitator.isNotEmpty || widget.fertilizationSite.boosterPump.isNotEmpty)
        SvgPicture.asset(
          (widget.fertilizationSite.agitator.isNotEmpty) ? 'assets/Images/Fertilization/agitator_1.svg' : '',
          width: 150,
          height: 47 * configPvd.ratio,
        ),
    ];
  }

  List<Widget> getBooster() {
    return [
      if (widget.fertilizationSite.boosterPump.isNotEmpty || widget.fertilizationSite.agitator.isNotEmpty)
        Stack(
          children: [
            SvgPicture.asset(
              (widget.fertilizationSite.boosterPump.isNotEmpty) ? 'assets/Images/Fertilization/booster_1.svg' : '',
              width: 150,
              height: 150 * configPvd.ratio,
            ),
            Positioned(
              left: 0,
              bottom: 50,
              child: Text(
                widget.fertilizationSite.boosterPump.map((sNo) => getObjectName(sNo, configPvd).name!).join(', '),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
    ];
  }

  Widget getEcPhSelector() {
    return Column(
      children: [
        if (widget.fertilizationSite.selector.isNotEmpty)
          getImageWithText('Selector', '${AppConstants.svgObjectPath}objectId_8.svg', configPvd),
        if (widget.fertilizationSite.ec.isNotEmpty)
          getImageWithText('Ec', '${AppConstants.svgObjectPath}objectId_27.svg', configPvd),
        if (widget.fertilizationSite.ph.isNotEmpty)
          getImageWithText('Ph', '${AppConstants.svgObjectPath}objectId_28.svg', configPvd),
      ],
    );
  }

  Widget getMultipleChannel() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...getAgitator(),
                if (widget.fertilizationSite.agitator.isNotEmpty) ...[
                  if (widget.fertilizationSite.channel.length > 1)
                    for (var middle = 0; middle < widget.fertilizationSite.channel.length - 1; middle++)
                      SvgPicture.asset(
                        'assets/Images/Fertilization/agitator_connection_pipe_first_1.svg',
                        width: 151,
                        height: 45 * configPvd.ratio,
                      ),
                  SvgPicture.asset(
                    'assets/Images/Fertilization/agitator_connection_pipe_last_1.svg',
                    width: 151,
                    height: 45 * configPvd.ratio,
                  ),
                ]
              ],
            ),
            Row(
              children: [
                ...getBooster(),
                mergeInjectorWithLevel(
                  injector: widget.fertilizationSite.channel[0],
                  fertilizerSno: widget.fertilizationSite.commonDetails.sNo!,
                  child: SvgPicture.asset(
                    'assets/Images/Fertilization/multiple_channel_first_1.svg',
                    width: 150,
                    height: 150 * configPvd.ratio,
                  ),
                ),
                if (widget.fertilizationSite.channel.length > 2)
                  for (var middle = 1; middle < widget.fertilizationSite.channel.length - 1; middle++)
                    mergeInjectorWithLevel(
                      fertilizerSno: widget.fertilizationSite.commonDetails.sNo!,
                      injector: widget.fertilizationSite.channel[middle],
                      child: SvgPicture.asset(
                        'assets/Images/Fertilization/multiple_channel_middle_1.svg',
                        width: 150,
                        height: 150 * configPvd.ratio,
                      ),
                    ),
                mergeInjectorWithLevel(
                  fertilizerSno: widget.fertilizationSite.commonDetails.sNo!,
                  injector: widget.fertilizationSite.channel[widget.fertilizationSite.channel.length - 1],
                  child: SvgPicture.asset(
                    'assets/Images/Fertilization/multiple_channel_last_1.svg',
                    width: 150,
                    height: 150 * configPvd.ratio,
                  ),
                )
              ],
            ),
          ],
        ),
        getEcPhSelector()
      ],
    );
  }

  Widget mergeInjectorWithLevel({required Widget child, required Injector injector, required double fertilizerSno}) {
    return Tooltip(
      verticalOffset: 0,
      message:
          '${getObjectName(injector.sNo, configPvd).name} \n level : ${injector.level == 0.0 ? '' : getObjectName(injector.level, configPvd).name}',
      decoration: const BoxDecoration(color: Colors.black),
      textStyle: const TextStyle(fontSize: 10, color: Colors.white),
      child: GestureDetector(
        onTap: () {
          FertilizationModel fertilizerSite =
              configPvd.fertilization.firstWhere((site) => site.commonDetails.sNo == fertilizerSno);
          setState(() {
            configPvd.selectedSno = injector.level;
          });
          selectionDialogBox(
            context: context,
            title: 'Select Level',
            singleSelection: true,
            listOfObject: configPvd.listOfGeneratedObject
                .where((object) =>
                    (object.objectId == 26 &&
                        !configPvd.source.any((src) => src.level == object.sNo) &&
                        !fertilizerSite.channel.any((channel) => channel.level == object.sNo)) ||
                    (object.sNo == injector.level))
                .toList(),
            onPressed: () {
              setState(() {
                for (var channel in fertilizerSite.channel) {
                  if (channel.sNo == injector.sNo) {
                    injector.level = configPvd.selectedSno;
                    break;
                  }
                }
              });
              Navigator.pop(context);
            },
          );
        },
        child: Stack(
          children: [
            child,
            Positioned(
              left: 28 * configPvd.ratio,
              top: 14 * configPvd.ratio,
              child: Container(
                padding: EdgeInsets.all(3 * configPvd.ratio),
                height: 28 * configPvd.ratio,
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
                child: Container(
                  width: 5,
                  height: 15 * configPvd.ratio,
                  color: injector.level == 0.0 ? Colors.grey.shade400 : Theme.of(context).primaryColorLight,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
