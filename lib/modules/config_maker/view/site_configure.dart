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

  List<MapEntry<int, String>> _visibleTabs() {
    return widget.configPvd.configurationTab.entries
        .where((tab) =>
    widget.configPvd.listOfGeneratedObject
        .any((object) => object.objectId == widget.configPvd.configurationTabObjectId[tab.key]) &&
        showTabForAquaCulture(tab.key))
        .toList();
  }

  int _countOf(int key) => widget.configPvd.listOfGeneratedObject
      .where((o) => o.objectId == widget.configPvd.configurationTabObjectId[key])
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
                      position: Tween<Offset>(begin: const Offset(0, 0.012), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(key: ValueKey(selectedKey), child: _tabContent()),
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
    return _style == _TabStyle.pill ? _pillBar(tabs) : _underlineBar(tabs);
  }

  void _select(int key) {
    setState(() {
      widget.configPvd.selectedConfigurationTab = key;
    });
  }

  Widget _countBadge(int count, bool selected, {required Color onColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        color: selected ? onColor.withOpacity(0.22) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: selected ? onColor : const Color(0xff475467),
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
        color: themeMode ? Colors.grey.shade100 : Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeMode ? Colors.grey.shade200 : Colors.white12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs)
              Builder(builder: (context) {
                final bool selected = widget.configPvd.selectedConfigurationTab == tab.key;
                final int count = _countOf(tab.key);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _select(tab.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(colors: [primary, primary.withOpacity(0.80)])
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: selected
                            ? [BoxShadow(color: primary.withOpacity(0.30), blurRadius: 10, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _tabIcons[tab.key] ?? Icons.settings_rounded,
                            size: 16,
                            color: selected ? Colors.white : const Color(0xff667085),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            tab.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : (themeMode ? const Color(0xff475467) : Colors.white70),
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 7),
                            _countBadge(count, selected, onColor: Colors.white),
                          ],
                        ],
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
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs)
              Builder(builder: (context) {
                final bool selected = widget.configPvd.selectedConfigurationTab == tab.key;
                final int count = _countOf(tab.key);
                return InkWell(
                  onTap: () => _select(tab.key),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        child: Row(
                          children: [
                            Icon(
                              _tabIcons[tab.key] ?? Icons.settings_rounded,
                              size: 17,
                              color: selected ? primary : const Color(0xff667085),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              tab.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                color: selected
                                    ? primary
                                    : (themeMode ? const Color(0xff475467) : Colors.white70),
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 7),
                              _countBadge(count, selected, onColor: primary),
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
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
    bool isAquaCultureGem = AppConstants.aquacultureModelList.contains(widget.configPvd.masterData['modelId']);
    if (!isAquaCultureGem) return true;
    List<int> tabKeyNotToShowForAquaCulture = [1, 2, 4, 5, 6, 7, 8];
    if (tabKeyNotToShowForAquaCulture.contains(tabKey)) {
      return false;
    }
    return true;
  }
}

DeviceObjectModel getObjectName(double sNo, ConfigMakerProvider configPvd) {
  return configPvd.listOfGeneratedObject.firstWhere((object) => object.sNo! == sNo);
}