import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../model/device_object_model.dart';
import '../model/fertigation_model.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/config_template_widgets.dart';
import '../widget/object_manager_bar.dart';
import '../widget/painter/multi_injector_painter.dart';
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
  static const Color _subTextColor = Color(0xFF8E9BB4); // slate-400 subtle text

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
    if (_shouldShowParameter(AppConstants.channelObjectId, channelSnoList)) {
      total++;
      if (site.channel.isNotEmpty) filled++;
    }
    if (_shouldShowParameter(AppConstants.boosterObjectId, site.boosterPump)) {
      total++;
      if (site.boosterPump.isNotEmpty) filled++;
    }
    if (_shouldShowParameter(AppConstants.agitatorObjectId, site.agitator)) {
      total++;
      if (site.agitator.isNotEmpty) filled++;
    }
    if (_shouldShowParameter(8, site.selector)) {
      total++;
      if (site.selector.isNotEmpty) filled++;
    }
    if (_shouldShowParameter(AppConstants.ecObjectId, site.ec)) {
      total++;
      if (site.ec.isNotEmpty) filled++;
    }
    if (_shouldShowParameter(AppConstants.phObjectId, site.ph)) {
      total++;
      if (site.ph.isNotEmpty) filled++;
    }

    if (total == 0) {
      total = 1;
      if (site.channel.isNotEmpty) filled = 1;
    }

    return _Progress(filled, total, filled);
  }

  void _showDarkModeAlertDialog({
    required String title,
    required String message,
    IconData icon = Icons.warning_amber_rounded,
    Color iconColor = const Color(0xFFF59E0B),
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
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF8E9BB4),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addFertilizationSite() {
    final p = widget.configPvd;

    // Check for unassigned injectors (channels)
    List<double> assignedChannelSnos = [];
    for (var site in p.fertilization) {
      for (var ch in site.channel) {
        assignedChannelSnos.add(ch.sNo);
      }
    }

    List<DeviceObjectModel> unassignedChannels = p.listOfGeneratedObject
        .where((o) =>
            o.objectId == AppConstants.channelObjectId &&
            o.controllerId != null &&
            o.sNo != null &&
            !assignedChannelSnos.contains(o.sNo!))
        .toList();

    // Check for unassigned booster pumps
    List<double> assignedBoosterSnos = [];
    for (var site in p.fertilization) {
      assignedBoosterSnos.addAll(site.boosterPump);
    }

    List<DeviceObjectModel> unassignedBoosters = p.listOfGeneratedObject
        .where((o) =>
            o.objectId == AppConstants.boosterObjectId &&
            o.controllerId != null &&
            o.sNo != null &&
            !assignedBoosterSnos.contains(o.sNo!))
        .toList();

    if (unassignedChannels.isEmpty) {
      _showDarkModeAlertDialog(
        title: 'No Unassigned Injectors',
        message: 'No unassigned injector is available. Please add more injectors before creating a new fertilization site.',
      );
      return;
    }

    if (unassignedBoosters.isEmpty) {
      _showDarkModeAlertDialog(
        title: 'No Unassigned Booster Pumps',
        message: 'No unassigned booster pump is available. Please add more booster pumps before creating a new fertilization site.',
      );
      return;
    }

    DeviceObjectModel? sampleObj;
    for (var o in p.listOfSampleObjectModel) {
      if (o.objectId == AppConstants.fertilizerSiteObjectId) {
        sampleObj = o;
        break;
      }
    }
    if (sampleObj == null) {
      sampleObj = DeviceObjectModel(
        objectId: AppConstants.fertilizerSiteObjectId,
        objectName: 'Fertilization Site',
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
      _showDarkModeAlertDialog(
        title: 'Limit Reached',
        message: 'Only $cap Fertigation Site can be added for this master controller model.',
      );
      return;
    }

    setState(() {
      p.updateObjectCount(AppConstants.fertilizerSiteObjectId, '${currentCount + 1}');
      if (p.fertilization.isNotEmpty) {
        final newSite = p.fertilization.last;
        final channelToAssign = unassignedChannels.first;
        newSite.channel.add(Injector(sNo: channelToAssign.sNo!));
        final boosterToAssign = unassignedBoosters.first;
        newSite.boosterPump.add(boosterToAssign.sNo!);
      }
    });
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final fertilizations = widget.configPvd.fertilization;

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
                    title: 'Fertilization configuration',
                    subtitle: 'Configure site mode, channels, booster pumps, agitators, selectors, EC and pH sensors',
                    totalCount: fertilizations.length,
                    countUnitSingular: 'site',
                    countUnitPlural: 'sites',
                    primaryColor: primaryColor,
                    icon: Icons.science_rounded,
                    onAddPressed: _addFertilizationSite,
                    addButtonLabel: 'Add Site',
                  ),
                  const SizedBox(height: 18),
                  if (fertilizations.isEmpty)
                    ConfigEmptyState(
                      title: 'No Fertigation Sites Added',
                      subtitle: 'Tap the button below to add a fertigation site to your configuration.',
                      icon: Icons.science_rounded,
                      primaryColor: primaryColor,
                      onAddPressed: _addFertilizationSite,
                      buttonLabel: 'Add Site',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: fertilizations.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final site = fertilizations[index];
                        return _buildFertilizationCard(site, primaryColor);
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

  Widget _buildFertilizationPainterBlock(FertilizationModel site, Color primaryColor) {
    if (site.channel.isNotEmpty) {
      final int count = site.channel.length;
      final List<String> names = site.channel
          .map((c) => getObjectName(c.sNo, widget.configPvd).name ?? '')
          .toList();
      const double painterH = 155.0;
      final double painterW = painterH * DetailedMultiInjectorPainter.aspectRatioFor(count);

      return Container(
        width: double.infinity,
        height: painterH + 20,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF12162B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: MultiInjectorView(
              isOn: false,
              channelCount: count,
              channelNames: names,
              size: Size(painterW, painterH),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 90,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF12162B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedImage(
              imagePath: '${AppConstants.svgObjectPath}objectId_3.svg',
              color: primaryColor,
            ),
            const SizedBox(height: 6),
            const Text(
              'No Injectors Assigned',
              style: TextStyle(
                color: _subTextColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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

  Widget _buildFertilizationHeaderBlock({
    required FertilizationModel site,
    required _Progress progress,
    required Color primaryColor,
    Widget? typeSelector,
  }) {
    final itemName = site.commonDetails.name ?? 'Fertilization Site';

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
                          site.commonDetails.sNo!,
                          AppConstants.fertilizerSiteObjectId,
                        );
                      });
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFertilizationPainterBlock(site, primaryColor),
        ],
      ),
    );
  }

  Widget _buildFertilizationCard(FertilizationModel site, Color primaryColor) {
    final currentType = getCentralLocalCodeToString(site.siteMode);
    const modeTypes = ['Central', 'Local'];
    const modeIcons = {
      'Central': Icons.hub_rounded,
      'Local': Icons.location_on_rounded,
    };

    final typeSelector = ConfigTypeSelector(
      currentType: currentType,
      typeList: modeTypes,
      typeIcons: modeIcons,
      tooltip: 'Change site mode',
      onSelected: (value) {
        setState(() {
          site.siteMode = getCentralLocalStringToCode(value);
        });
      },
    );

    final progress = _calcProgress(site);

    final channelSnoList = site.channel.map((c) => c.sNo).toList();
    final showChannels = _shouldShowParameter(AppConstants.channelObjectId, channelSnoList);
    final showBooster = _shouldShowParameter(AppConstants.boosterObjectId, site.boosterPump);
    final showAgitator = _shouldShowParameter(AppConstants.agitatorObjectId, site.agitator);
    final showSelector = _shouldShowParameter(8, site.selector);
    final showEc = _shouldShowParameter(AppConstants.ecObjectId, site.ec);
    final showPh = _shouldShowParameter(AppConstants.phObjectId, site.ph);

    final showPumpsAgitators = showBooster || showAgitator;
    final showSensors = showSelector || showEc || showPh;

    final bodySections = <Widget>[];

    if (showChannels || (!showPumpsAgitators && !showSensors)) {
      bodySections.add(
        ConfigFlowSection(
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
        ConfigFlowSection(
          title: 'Booster & Agitator',
          icon: Icons.speed_rounded,
          accent: _boosterColor,
          children: [
            if (showBooster)
              _buildParameterTile(
                site: site,
                currentParameterValue: site.boosterPump,
                parameterType: 2,
                objectId: AppConstants.boosterObjectId,
                objectName: 'Booster Pump',
                accent: _boosterColor,
              ),
            if (showAgitator)
              _buildParameterTile(
                site: site,
                currentParameterValue: site.agitator,
                parameterType: 3,
                objectId: AppConstants.agitatorObjectId,
                objectName: 'Agitator',
                accent: _boosterColor,
              ),
          ],
        ),
      );
    }

    if (showSensors) {
      bodySections.add(
        ConfigFlowSection(
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
                objectId: AppConstants.ecObjectId,
                objectName: 'EC Sensor',
                accent: _sensorColor,
              ),
            if (showPh)
              _buildParameterTile(
                site: site,
                currentParameterValue: site.ph,
                parameterType: 6,
                objectId: AppConstants.phObjectId,
                objectName: 'pH Sensor',
                accent: _sensorColor,
              ),
          ],
        ),
      );
    }

    return ConfigCardShell(
      headerBlock: _buildFertilizationHeaderBlock(
        site: site,
        progress: progress,
        primaryColor: primaryColor,
        typeSelector: typeSelector,
      ),
      isComplete: progress.complete,
      completeColor: _doneColor,
      expandHeader: true,
      rightPanelWidth: 500.0,
      body: bodySections,
    );
  }

  Widget _buildChannelsTile(FertilizationModel site, Color accent) {
    int objectId = AppConstants.channelObjectId;
    bool isAssigned = site.channel.isNotEmpty;
    List<double> channelSnoList = site.channel.map((channel) => channel.sNo).toList();
    List<String> names = isAssigned
        ? channelSnoList.map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-').toList()
        : [];

    return ConfigComponentTile(
      title: 'Channels',
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: names,
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
              _showDarkModeAlertDialog(
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
    List<String> names = isAssigned
        ? currentParameterValue.map((sNo) => getObjectName(sNo, widget.configPvd).name ?? '-').toList()
        : [];

    return ConfigComponentTile(
      title: objectName,
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: names,
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
