import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/ec_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/ph_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/pressure_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/pump_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/source_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/valve_configuration.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import 'channel_configuration.dart';
import 'fertilization_configuration.dart';
import 'filtration_configuration.dart';
import 'line_configuration.dart';
import 'moisture_configuration.dart';

/// pill      -> rounded segmented bar, selected tab is a filled pill
/// underline -> flat tabs with an animated underline indicator
enum _TabStyle { pill, underline }

class SiteConfigure extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const SiteConfigure({super.key, required this.configPvd});

  @override
  State<SiteConfigure> createState() => _SiteConfigureState();
}

class _SiteConfigureState extends State<SiteConfigure> {
  late ThemeData themeData;
  late bool themeMode;

  /// change this one line to switch the look
  static const _TabStyle _style = _TabStyle.pill;

  static const Map<int, IconData> _tabIcons = {
    0: Icons.waves_rounded,
    1: Icons.cyclone_rounded,
    2: Icons.filter_alt_rounded,
    3: Icons.alt_route_rounded,
    4: Icons.science_rounded,
    5: Icons.water_drop_rounded,
    6: Icons.electric_bolt_rounded,
    7: Icons.biotech_rounded,
    8: Icons.speed_rounded,
    9: Icons.tune_rounded,
    10: Icons.timeline_rounded,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeData = Theme.of(context);
    themeMode = themeData.brightness == Brightness.light;
  }

  bool _isTabVisible(int tabKey) {
    if (!showTabForAquaCulture(tabKey)) return false;
    final generatedObjects = widget.configPvd.listOfGeneratedObject;

    switch (tabKey) {
      case 0: // Source Configuration: show if at least one pump is available
        return generatedObjects.any((o) =>
            o.objectId == AppConstants.pumpObjectId ||
            o.objectId == AppConstants.sourceObjectId);
      case 2: // Filtration Configuration: show if at least one filter is available
        return generatedObjects.any((o) =>
            o.objectId == AppConstants.filterObjectId ||
            o.objectId == AppConstants.filterSiteObjectId);
      case 4: // Fertilization Configuration: show if at least one channel is available
        return generatedObjects.any((o) =>
            o.objectId == AppConstants.channelObjectId ||
            o.objectId == AppConstants.fertilizerSiteObjectId);
      case 10: // Line Configuration: show if at least one valve is available
        return generatedObjects.any((o) =>
            o.objectId == AppConstants.valveObjectId ||
            o.objectId == AppConstants.mainValveObjectId ||
            o.objectId == AppConstants.irrigationLineObjectId);
      default:
        int? requiredObjectId =
            widget.configPvd.configurationTabObjectId[tabKey];
        if (requiredObjectId == null) return false;
        return generatedObjects.any((o) => o.objectId == requiredObjectId);
    }
  }

  List<MapEntry<int, String>> _visibleTabs() {
    return widget.configPvd.configurationTab.entries
        .where((tab) => _isTabVisible(tab.key))
        .toList();
  }

  int _countOf(int key) => widget.configPvd.listOfGeneratedObject
      .where((o) =>
          o.objectId == widget.configPvd.configurationTabObjectId[key])
      .length;

  Widget _tabContent() {
    switch (widget.configPvd.selectedConfigurationTab) {
      case 0:
        return SourceConfiguration(configPvd: widget.configPvd);
      case 1:
        return PumpConfiguration(configPvd: widget.configPvd);
      case 2:
        return FiltrationConfiguration(configPvd: widget.configPvd);
      case 3:
        return ChannelConfiguration(configPvd: widget.configPvd);
      case 4:
        return FertilizationConfiguration(configPvd: widget.configPvd);
      case 5:
        return MoistureConfiguration(configPvd: widget.configPvd);
      case 6:
        return EcConfiguration(configPvd: widget.configPvd);
      case 7:
        return PhConfiguration(configPvd: widget.configPvd);
      case 8:
        return PressureConfiguration(configPvd: widget.configPvd);
      case 9:
        return ValveConfiguration(configPvd: widget.configPvd);
      default:
        return LineConfiguration(configPvd: widget.configPvd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _visibleTabs();
    if (tabs.isNotEmpty &&
        !tabs.any((t) => t.key == widget.configPvd.selectedConfigurationTab)) {
      widget.configPvd.selectedConfigurationTab = tabs.first.key;
    }
    final int selectedKey = widget.configPvd.selectedConfigurationTab;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(builder: (context, constraint) {
        return SizedBox(
          width: constraint.maxWidth,
          height: constraint.maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getConfigurationCategory(),
              const SizedBox(height: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [
                      ...previous.map((child) => IgnorePointer(child: child)),
                      if (current != null) current,
                    ],
                  ),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.012), end: Offset.zero)
                          .animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                      key: ValueKey(selectedKey), child: _tabContent()),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ───────────────────────── tab bar ─────────────────────────
  Widget getConfigurationCategory() {
    final tabs = _visibleTabs();
    if (tabs.isEmpty) {
      final primary = themeData.primaryColor;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF13172E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF20274B)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.dashboard_customize_rounded, size: 28, color: primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No Site Components Available',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Add pumps, filters, channels, or valves to enable site configuration options.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF8E9BB4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return _style == _TabStyle.pill ? _pillBar(tabs) : _underlineBar(tabs);
  }

  void _select(int key) {
    setState(() {
      widget.configPvd.selectedConfigurationTab = key;
    });
  }

  Widget _countBadge(int count, bool selected, {required Color primary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        color: selected
            ? primary.withValues(alpha: 0.28)
            : const Color(0xFF1C2242),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : const Color(0xFF8E9BB4),
        ),
      ),
    );
  }

  // Style 1 – pills in a soft rounded track
  Widget _pillBar(List<MapEntry<int, String>> tabs) {
    final primary = themeData.primaryColor;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF13172E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF20274B)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final tab in tabs)
              Builder(builder: (context) {
                final bool selected =
                    widget.configPvd.selectedConfigurationTab == tab.key;
                final int count = _countOf(tab.key);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _select(tab.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? Color.alphaBlend(
                                  primary.withValues(alpha: 0.25),
                                  const Color(0xFF1C2242))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(
                                  color: primary.withValues(alpha: 0.6),
                                  width: 1)
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _tabIcons[tab.key] ?? Icons.settings_rounded,
                              size: 16,
                              color: selected
                                  ? primary
                                  : const Color(0xFF8E9BB4),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tab.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    selected ? FontWeight.bold : FontWeight.w500,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF8E9BB4),
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 8),
                              _countBadge(count, selected, primary: primary),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // Style 2 – flat tabs with an underline indicator
  Widget _underlineBar(List<MapEntry<int, String>> tabs) {
    final primary = themeData.primaryColor;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF20274B), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs)
              Builder(builder: (context) {
                final bool selected =
                    widget.configPvd.selectedConfigurationTab == tab.key;
                final int count = _countOf(tab.key);
                return InkWell(
                  onTap: () => _select(tab.key),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        child: Row(
                          children: [
                            Icon(
                              _tabIcons[tab.key] ?? Icons.settings_rounded,
                              size: 17,
                              color:
                                  selected ? primary : const Color(0xFF8E9BB4),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              tab.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: selected
                                    ? primary
                                    : const Color(0xFF8E9BB4),
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 7),
                              _countBadge(count, selected, primary: primary),
                            ],
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: 3,
                        width: selected ? 44 : 0,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  bool showTabForAquaCulture(int tabKey) {
    bool isAquaCultureGem = AppConstants.aquacultureModelList
        .contains(widget.configPvd.masterData['modelId']);
    if (!isAquaCultureGem) return true;
    List<int> tabKeyNotToShowForAquaCulture = [1, 2, 4, 5, 6, 7, 8];
    if (tabKeyNotToShowForAquaCulture.contains(tabKey)) {
      return false;
    }
    return true;
  }
}

DeviceObjectModel getObjectName(double sNo, ConfigMakerProvider configPvd) {
  return configPvd.listOfGeneratedObject.firstWhere(
    (object) => object.sNo! == sNo,
    orElse: () => DeviceObjectModel(
      objectId: 0,
      sNo: sNo,
      name: '-',
      objectName: '',
      type: '',
      assignObject: [],
    ),
  );
}
