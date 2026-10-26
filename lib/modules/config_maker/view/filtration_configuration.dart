import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:provider/provider.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../model/device_object_model.dart';
import '../model/filtration_model.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/config_template_widgets.dart';
import '../widget/object_manager_bar.dart';
import '../widget/painter/multi_filter_painter.dart';
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
  // ── Design tokens (Matching source_configuration.dart) ──
  static const Color _inletColor = Color(0xFF0284C7); // ocean sky blue
  static const Color _outletColor = Color(0xFF059669); // emerald green
  static const Color _doneColor = Color(0xFF059669); // emerald green
  static const Color _inkColor = Colors.white; // dark mode crisp white text
  static const Color _subTextColor = Color(0xFF8E9BB4); // slate-400 subtle text

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

  void _addFiltrationSite() {
    final p = widget.configPvd;

    // Check for unassigned filters
    List<double> assignedFilterSnos = [];
    for (var site in p.filtration) {
      for (var filter in site.filters) {
        assignedFilterSnos.add(filter.sNo);
      }
    }

    List<DeviceObjectModel> unassignedFilters = p.listOfGeneratedObject
        .where((o) =>
            o.objectId == AppConstants.filterObjectId &&
            o.sNo != null &&
            !assignedFilterSnos.contains(o.sNo!))
        .toList();

    if (unassignedFilters.isEmpty) {
      _showDarkModeAlertDialog(
        title: 'No Unassigned Filters',
        message: 'No unassigned filter is available. Please add more filters before creating a new filtration site.',
      );
      return;
    }

    DeviceObjectModel? sampleObj;
    for (var o in p.listOfSampleObjectModel) {
      if (o.objectId == AppConstants.filterSiteObjectId) {
        sampleObj = o;
        break;
      }
    }
    if (sampleObj == null) {
      sampleObj = DeviceObjectModel(
        objectId: AppConstants.filterSiteObjectId,
        objectName: 'Filtration Site',
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
        message: 'Only $cap Filtration Site can be added for this master controller model.',
      );
      return;
    }

    setState(() {
      p.updateObjectCount(AppConstants.filterSiteObjectId, '${currentCount + 1}');
      if (p.filtration.isNotEmpty) {
        final newSite = p.filtration.last;
        final filterToAssign = unassignedFilters.first;
        newSite.filters.add(Filter(sNo: filterToAssign.sNo!, filterMode: 1));
      }
    });
  }

  // ───────────────────────────────────────────────────────────
  //  BUILD
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final filtrations = widget.configPvd.filtration;

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
                    title: 'Filtration configuration',
                    subtitle: 'Configure site mode, filters, filter types, and pressure sensors',
                    totalCount: filtrations.length,
                    countUnitSingular: 'site',
                    countUnitPlural: 'sites',
                    primaryColor: primaryColor,
                    icon: Icons.filter_alt_rounded,
                    onAddPressed: _addFiltrationSite,
                    addButtonLabel: 'Add Site',
                  ),
                  const SizedBox(height: 18),
                  if (filtrations.isEmpty)
                    ConfigEmptyState(
                      title: 'No Filtration Sites Added',
                      subtitle: 'Tap the button below to add a filtration site to your configuration.',
                      icon: Icons.filter_alt_rounded,
                      primaryColor: primaryColor,
                      onAddPressed: _addFiltrationSite,
                      buttonLabel: 'Add Site',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtrations.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final site = filtrations[index];
                        return _buildFiltrationCard(site, primaryColor);
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

  Widget _buildFiltrationPainterBlock(FiltrationModel site, Color primaryColor) {
    if (site.filters.isNotEmpty) {
      final List<String> filterNames = site.filters
          .map((f) => getObjectName(f.sNo, widget.configPvd).name ?? '')
          .toList();

      const double painterH = 200.0;
      final double calculatedW = DetailedMultiFilterPainter.calculateWidth(painterH, site.filters.length);
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
            child: CustomPaint(
              painter: DetailedMultiFilterPainter(
                isOn: true,
                filterCount: site.filters.length,
                filterNames: filterNames,
              ),
              size: Size(calculatedW, painterH),
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
              imagePath: '${AppConstants.svgObjectPath}objectId_4.svg',
              color: primaryColor,
            ),
            const SizedBox(height: 6),
            const Text(
              'No Filters Assigned',
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

  Widget _buildFiltrationHeaderBlock({
    required FiltrationModel site,
    required _Progress progress,
    required Color primaryColor,
    Widget? typeSelector,
  }) {
    final itemName = site.commonDetails.name ?? 'Filtration Site';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF181C38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: const VisualDensity(vertical: -2),
            title: Text(
              itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (typeSelector != null) typeSelector,
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
                            AppConstants.filterSiteObjectId,
                          );
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildFiltrationPainterBlock(site, primaryColor),
        ],
      ),
    );
  }

  Widget _buildFiltrationCard(FiltrationModel site, Color primaryColor) {
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

    return ConfigCardShell(
      headerBlock: _buildFiltrationHeaderBlock(
        site: site,
        progress: progress,
        primaryColor: primaryColor,
        typeSelector: typeSelector,
      ),
      isComplete: progress.complete,
      completeColor: _doneColor,
      expandHeader: true,
      rightPanelWidth: 500.0,
      body: [
        ConfigFlowSection(
          title: 'Filters',
          icon: Icons.tune_rounded,
          accent: _inletColor,
          children: [
            _buildFiltersTile(site, _inletColor),
          ],
        ),
        ConfigFlowSection(
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

  Widget _buildFiltersTile(FiltrationModel site, Color accent) {
    int objectId = 11;
    bool isAssigned = site.filters.isNotEmpty;
    List<String> names = isAssigned
        ? site.filters.map((filter) => getObjectName(filter.sNo, widget.configPvd).name ?? '-').toList()
        : [];

    return ConfigComponentTile(
      title: 'Filter',
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: names,
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

  Widget _buildPressureTile(FiltrationModel site, int pressureMode, Color accent) {
    int objectId = 24;
    String objectName = pressureMode == 1 ? 'Pressure In' : 'Pressure Out';
    double currentSno = pressureMode == 1 ? site.pressureIn : site.pressureOut;
    bool isAssigned = currentSno != 0.0;
    List<String> names = isAssigned ? [getObjectName(currentSno, widget.configPvd).name ?? '-'] : [];

    return ConfigComponentTile(
      title: objectName,
      imagePath: '${AppConstants.svgObjectPath}objectId_$objectId.svg',
      names: names,
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
