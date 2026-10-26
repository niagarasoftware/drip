import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../Constants/communication_codes.dart';
import '../model/device_model.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import '../widget/connection_grid_list_tile.dart';
import '../widget/connector_widget.dart';
import '../../../Constants/dialog_boxes.dart';
import '../widget/node_dialogs.dart';
import '../widget/select_object_categories_dialog.dart';
import '../../../flavors.dart';
import '../../../utils/shared_preferences_helper.dart';

class Connection extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  const Connection({
    super.key,
    required this.configPvd,
  });

  @override
  State<Connection> createState() => _ConnectionState();
}

class _ConnectionState extends State<Connection> {
  late Future<bool> updateValuesConnectionPageInitialize;

  @override
  void initState() {
    super.initState();
    updateValuesConnectionPageInitialize = updateConnection();
    _loadUserRole();
  }

  String userRole = '';

  Future<void> _loadUserRole() async {
    final role = await PreferenceHelper.getUserRole();
    if (!mounted) return;
    setState(() => userRole = role ?? '');
  }

  bool get _canEditDeviceId => ["admin", "1"].contains(userRole) || F.title.contains('ORO');

  Future<bool> updateConnection() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      List<int> listOfCategory = [];
      for (var device in widget.configPvd.listOfDeviceModel) {
        if (![10].contains(device.categoryId) &&
            ![1, 2, 4].contains(device.modelId) &&
            device.masterId != null &&
            !listOfCategory.contains(device.categoryId)) {
          listOfCategory.add(device.categoryId);
        }
      }
      if (listOfCategory.isEmpty) {
        return false;
      }
      widget.configPvd.selectedCategory = listOfCategory[0];
      for (var device in widget.configPvd.listOfDeviceModel) {
        if (device.categoryId == listOfCategory[0] && device.masterId != null) {
          widget.configPvd.selectedModelControllerId = device.controllerId;
          break;
        }
      }
      widget.configPvd.updateSelectedConnectionNoAndItsType(0, '');
      widget.configPvd.updateConnectionListTile();
      return true;
    } catch (e) {
      debugPrint('Error in updateConnection: ${e.toString()}');
      return false;
    }
  }

  // ───────────────────────── state helpers ─────────────────────────
  String? _activeType; // currently opened terminal tab ('1,2', analog, digital ...)
  String? _pressedType; // tab currently being pressed (for the press animation)

  List<_TerminalInfo> _terminals(DeviceModel d) {
    if (AppConstants.weatherModelList.contains(d.categoryId)) return [];
    final int relay = d.noOfRelay == 0 ? d.noOfLatch : d.noOfRelay;
    return [
      if (relay != 0)
        _TerminalInfo(
          type: '1,2',
          name: d.noOfRelay == 0 ? 'Latch' : 'Relay',
          keyWord: d.noOfRelay == 0 ? 'L' : 'R',
          color: AppConstants.outputColor,
          total: relay,
          icon: Icons.electrical_services_rounded,
        ),
      if (d.noOfAnalogInput != 0)
        _TerminalInfo(
          type: AppConstants.analogCode,
          name: 'Analog',
          keyWord: 'A',
          color: getObjectTypeCodeToColor(3),
          total: d.noOfAnalogInput,
          icon: Icons.sensors_rounded,
        ),
      if (d.noOfDigitalInput != 0)
        _TerminalInfo(
          type: AppConstants.digitalCode,
          name: 'Digital',
          keyWord: 'D',
          color: getObjectTypeCodeToColor(4),
          total: d.noOfDigitalInput,
          icon: Icons.toggle_on_rounded,
        ),
      if (d.noOfPulseInput != 0)
        _TerminalInfo(
          type: AppConstants.pulseCode,
          name: 'Pulse',
          keyWord: 'P',
          color: getObjectTypeCodeToColor(6),
          total: d.noOfPulseInput,
          icon: Icons.speed_rounded,
        ),
      if (d.noOfMoistureInput != 0)
        _TerminalInfo(
          type: AppConstants.moistureCode,
          name: 'Moisture',
          keyWord: 'M',
          color: getObjectTypeCodeToColor(5),
          total: d.noOfMoistureInput,
          icon: Icons.water_drop_rounded,
        ),
      if (d.noOfI2CInput != 0)
        _TerminalInfo(
          type: AppConstants.i2cCode,
          name: 'I2C',
          keyWord: 'I2C',
          color: getObjectTypeCodeToColor(7),
          total: d.noOfI2CInput,
          icon: Icons.cable_rounded,
        ),
    ];
  }

  int _usedPins(DeviceModel d, String type) => widget.configPvd.listOfGeneratedObject
      .where((o) => o.controllerId == d.controllerId && o.type == type)
      .length;

  /// objects of this type that still have no pin
  int _pending(DeviceModel d, String type) => widget.configPvd.listOfGeneratedObject
      .where((o) => d.connectingObjectId.contains(o.objectId) && o.controllerId == null && o.type == type)
      .length;

  List<int> _categories() {
    List<int> list = [];
    for (var device in widget.configPvd.listOfDeviceModel) {
      if (![10].contains(device.categoryId) &&
          ![1, 2, 4].contains(device.modelId) &&
          device.masterId != null &&
          !list.contains(device.categoryId)) {
        list.add(device.categoryId);
      }
    }
    list.sort();
    return list;
  }

  String _categoryName(int categoryId) => widget.configPvd.listOfDeviceModel
      .firstWhere((device) => device.categoryId == categoryId)
      .deviceName;

  List<DeviceModel> _modelsOf(int categoryId) {
    final models = widget.configPvd.listOfDeviceModel
        .where((device) => (device.categoryId == categoryId &&
        device.masterId != null &&
        ![...AppConstants.ecModel, ...AppConstants.phModel].contains(device.modelId)))
        .toList();
    if (models.isNotEmpty) return models;
    return widget.configPvd.listOfDeviceModel
        .where((d) => d.categoryId == categoryId && d.masterId != null)
        .take(1)
        .toList();
  }

  void _selectModel(DeviceModel model) {
    setState(() {
      widget.configPvd.selectedCategory = model.categoryId;
      widget.configPvd.selectedModelControllerId = model.controllerId;
      _activeType = null;
    });
    widget.configPvd.updateSelectedConnectionNoAndItsType(0, '');
    widget.configPvd.updateConnectionListTile();
  }

  // ───────────────────────── node management ─────────────────────────
  bool _isMaster(DeviceModel m) => m.controllerId == widget.configPvd.masterData['controllerId'];

  List<DeviceModel> _allNodes() => [for (final c in _categories()) ..._modelsOf(c)];

  DeviceModel? _selectedDeviceOrNull() {
    for (final d in widget.configPvd.listOfDeviceModel) {
      if (d.controllerId == widget.configPvd.selectedModelControllerId && d.masterId != null) return d;
    }
    return null;
  }

  /// Nodes that are attached to the master but have no object wired to them.
  List<DeviceModel> _detachedNodes() => _allNodes()
      .where((n) => !widget.configPvd.listOfGeneratedObject.any((o) => o.controllerId == n.controllerId))
      .toList();

  /// Called after a node was added / edited / deleted.
  void _afterNodeChange() {
    if (!mounted) return;
    setState(() {
      final cfg = widget.configPvd;
      if (_selectedDeviceOrNull() == null) {
        final nodes = _allNodes();
        _activeType = null;
        if (nodes.isEmpty) {
          cfg.selectedModelControllerId = 0;
          cfg.updateSelectedConnectionNoAndItsType(0, '');
          return;
        }
        cfg.selectedCategory = nodes.first.categoryId;
        cfg.selectedModelControllerId = nodes.first.controllerId;
        cfg.updateSelectedConnectionNoAndItsType(0, '');
      }
      cfg.updateConnectionListTile();
    });
  }

  void _addNode() => showAddNodeDialog(context: context, configPvd: widget.configPvd, onChanged: _afterNodeChange);

  void _editNode(DeviceModel node) => showEditNodeDialog(
    context: context,
    configPvd: widget.configPvd,
    node: node,
    canEditDeviceId: _canEditDeviceId,
    onChanged: _afterNodeChange,
  );

  Widget _addNodeButton() {
    const accentGreen = Color(0xFF10B981);
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _addNode,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [
                Color.alphaBlend(accentGreen.withValues(alpha: 0.25), const Color(0xFF181C38)),
                Color.alphaBlend(accentGreen.withValues(alpha: 0.08), const Color(0xFF181C38)),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: accentGreen, width: 1.2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 18, color: accentGreen),
              SizedBox(width: 8),
              Text(
                'Add Node',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accentGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyNodes() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hub_outlined, size: 46, color: Color(0xFF8E9BB4)),
          const SizedBox(height: 10),
          const Text('No nodes added yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Add a node to start wiring objects.', style: TextStyle(fontSize: 12, color: Color(0xFF8E9BB4))),
          const SizedBox(height: 16),
          SizedBox(width: 200, child: _addNodeButton()),
        ],
      ),
    );
  }

  // ───────────────────────── build ─────────────────────────
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: updateValuesConnectionPageInitialize,
      builder: (context, snapShot) {
        if (snapShot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapShot.hasError) {
          return const Center(child: Text('Error loading data', style: TextStyle(color: Colors.white)));
        }
        if (snapShot.hasData) {
          final DeviceModel? selectedOrNull = _selectedDeviceOrNull();
          if (selectedOrNull == null) return _emptyNodes();
          final DeviceModel selectedDevice = selectedOrNull;
          final bool manualMode = widget.configPvd.selectedSelectionMode == SelectionMode.manual;
          final terminals = _terminals(selectedDevice);
          if (terminals.isNotEmpty && !terminals.any((t) => t.type == _activeType)) {
            _activeType = terminals.first.type;
          }
          final _TerminalInfo? active =
          terminals.isEmpty ? null : terminals.firstWhere((t) => t.type == _activeType);

          return LayoutBuilder(builder: (context, c) {
            final bool wide = c.maxWidth >= 900 && c.maxHeight.isFinite;
            if (wide) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 240, child: _sidebar()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(selectedDevice, terminals),
                          const SizedBox(height: 10),
                          if (manualMode) ...[
                            _detachedNodesSection(selectedDevice),
                            const SizedBox(height: 10),
                          ],
                          Expanded(child: _workArea(selectedDevice, terminals, active, true)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _navStrip(),
                  const SizedBox(height: 10),
                  _header(selectedDevice, terminals),
                  const SizedBox(height: 10),
                  if (manualMode) ...[
                    _detachedNodesSection(selectedDevice),
                    const SizedBox(height: 10),
                  ],
                  _workArea(selectedDevice, terminals, active, false),
                  const SizedBox(height: 16),
                ],
              ),
            );
          });
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  // ───────────────────────── device navigator ─────────────────────────
  /// Wide screens: vertical list, devices grouped by category
  Widget _sidebar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13172E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF20274B)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                for (final cat in _categories()) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _categoryName(cat).toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: Color(0xFF8E9BB4),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181C38),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_modelsOf(cat).length}',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF8E9BB4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final m in _modelsOf(cat))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _modelTile(m),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF20274B)),
          Padding(padding: const EdgeInsets.all(10), child: _addNodeButton()),
        ],
      ),
    );
  }

  /// Narrow screens: horizontal strip
  Widget _navStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final cat in _categories()) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    _categoryName(cat).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF8E9BB4)),
                  ),
                ),
                Row(
                  children: [
                    for (final m in _modelsOf(cat))
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: SizedBox(width: 200, child: _modelTile(m)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 10),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: SizedBox(width: 150, child: _addNodeButton()),
          ),
        ],
      ),
    );
  }

  Widget _modelTile(DeviceModel model) {
    final primary = Theme.of(context).primaryColor;
    final bool selected = widget.configPvd.selectedModelControllerId == model.controllerId;
    return Tooltip(
      message: model.modelDescription,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _selectModel(model),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: selected
                ? LinearGradient(
                    colors: [primary.withOpacity(0.35), const Color(0xFF181C38)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: selected ? null : const Color(0xFF181C38),
            border: Border.all(
              color: selected ? primary : const Color(0xFF232A4D),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? primary : const Color(0xFF13172E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.memory_rounded, size: 18, color: selected ? Colors.white : primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.deviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '# ${model.deviceId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: selected ? const Color(0xFFC084FC) : const Color(0xFF8E9BB4),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isMaster(model))
                Tooltip(
                  message: 'Edit node',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _editNode(model),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF8E9BB4)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── header + terminal tabs ─────────────────────────
  Widget _header(DeviceModel d, List<_TerminalInfo> terminals) {
    final primary = Theme.of(context).primaryColor;
    final bool showToggle = [...AppConstants.gemModelList, ...AppConstants.omsGemList]
        .contains(widget.configPvd.masterData['modelId']);
    int used = 0;
    int total = 0;
    for (final t in terminals) {
      used += _usedPins(d, t.type);
      total += t.total;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF13172E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF20274B)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.developer_board_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.deviceName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('${d.modelDescription}  ·  # ${d.deviceId}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8E9BB4))),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => showSelectObjectCategoriesSideSheet(
                  context: context,
                  configPvd: widget.configPvd,
                  selectedDevice: d,
                  onChanged: () {
                    widget.configPvd.updateConnectionListTile();
                    setState(() {});
                  },
                ),
                icon: const Icon(Icons.tune_rounded, size: 15),
                label: const Text('Select Object Categories',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 10),
              if (total > 0 && showToggle) const SizedBox(width: 10),
              if (showToggle) getSelectionCategory(),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── real tabs + attached content card ─────────────────────────
  static const double _tabH = 46;

  Widget _workArea(DeviceModel d, List<_TerminalInfo> terminals, _TerminalInfo? active, bool fill) {
    if (active == null) {
      // devices without terminals (e.g. weather): objects only
      return _objectsPanel(d, null, fill);
    }
    final int activeIndex = terminals.indexOf(active);

    final Widget panels = fill
        ? Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 5, child: _pinsPanel(d, active, true)),
        const SizedBox(width: 10),
        Expanded(flex: 6, child: _objectsPanel(d, active, true)),
      ],
    )
        : Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pinsPanel(d, active, false),
        const SizedBox(height: 10),
        _objectsPanel(d, active, false),
      ],
    );

    // content switches with a soft fade + slide when the tab changes
    final Widget inner = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      layoutBuilder: fill
          ? (current, previous) => Stack(
        fit: StackFit.expand,
        children: [
          ...previous.map((child) => IgnorePointer(child: child)),
          if (current != null) current,
        ],
      )
          : AnimatedSwitcher.defaultLayoutBuilder,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.015, 0), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey('${d.controllerId}-${active.type}'), child: panels),
    );

    // the card the tabs are attached to – border takes the active tab colour
    final Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(top: _tabH - 1),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F1D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(activeIndex == 0 ? 0 : 14),
          topRight: const Radius.circular(14),
          bottomLeft: const Radius.circular(14),
          bottomRight: const Radius.circular(14),
        ),
        border: Border.all(color: active.color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: active.color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: inner,
    );

    final Widget tabBar = SizedBox(
      height: _tabH + 1,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [for (final t in terminals) _tab(d, t)],
        ),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          fill ? Positioned.fill(child: content) : content,
          // drawn after the card so the selected tab covers the card's top border
          Positioned(top: 0, left: 0, right: 0, child: tabBar),
        ],
      ),
    );
  }

  Widget _tab(DeviceModel d, _TerminalInfo t) {
    final bool selected = t.type == _activeType;
    final bool pressed = _pressedType == t.type;
    final int used = _usedPins(d, t.type);
    final int pending = _pending(d, t.type);
    final double progress = t.total == 0 ? 0 : (used / t.total).clamp(0.0, 1.0);
    const double r = 12;

    final Widget label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: t.color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(t.color),
              ),
            ),
            Icon(t.icon, size: 13, color: t.color),
          ],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : const Color(0xFFE2E8F0),
                )),
            Text('$used / ${t.total} pins',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF8E9BB4))),
          ],
        ),
      ],
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(right: 6, bottom: selected ? 0 : 2),
      child: AnimatedScale(
        scale: pressed ? 0.96 : 1,
        alignment: Alignment.bottomCenter,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: selected ? _tabH + 1 : _tabH - 8,
          padding: const EdgeInsets.fromLTRB(1.6, 1.6, 1.6, 0),
          decoration: BoxDecoration(
            color: selected ? t.color : const Color(0xFF232A4D),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(r)),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        Color.alphaBlend(t.color.withValues(alpha: 0.35), const Color(0xFF13172E)),
                        Color.alphaBlend(t.color.withValues(alpha: 0.12), const Color(0xFF13172E)),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: selected ? null : const Color(0xFF181C38),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(r - 1.6)),
            ),
            child: Material(
              color: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                splashColor: t.color.withValues(alpha: 0.20),
                hoverColor: t.color.withValues(alpha: 0.10),
                highlightColor: Colors.transparent,
                onHighlightChanged: (v) => setState(() => _pressedType = v ? t.type : null),
                onTap: () {
                  setState(() => _activeType = t.type);
                  widget.configPvd.updateSelectedConnectionNoAndItsType(0, '');
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: selected ? 3 : 0,
                      color: t.color,
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: label,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel({
    required String title,
    required IconData icon,
    required Color color,
    String? trailing,
    Widget? action,
    required Widget child,
    required bool fill,
  }) {
    final body = Padding(padding: const EdgeInsets.all(10), child: child);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13172E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF20274B)),
      ),
      child: Column(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF181C38),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                if (action != null) ...[
                  const SizedBox(width: 10),
                  action,
                ],
                const Spacer(),
                if (trailing != null)
                  Flexible(
                    flex: 2,
                    fit: FlexFit.tight,
                    child: Text(trailing,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E9BB4))),
                  ),
              ],
            ),
          ),
          if (fill) Expanded(child: SingleChildScrollView(child: body)) else body,
        ],
      ),
    );
  }

  Widget _pinsPanel(DeviceModel d, _TerminalInfo info, bool fill) {
    final bool manual = widget.configPvd.selectedSelectionMode == SelectionMode.manual;
    final pins = <Widget>[
      for (int i = 0; i < info.total; i++)
        ConnectorWidget(
          connectionNo: i + 1,
          selectedDevice: d,
          configPvd: widget.configPvd,
          type: info.type,
          keyWord: info.keyWord,
          color: info.color,
        ),
      if (info.type == AppConstants.analogCode && d.categoryId == 6)
        ConnectorWidget(
          connectionNo: 9,
          selectedDevice: d,
          configPvd: widget.configPvd,
          type: info.type,
          keyWord: '',
          color: info.color,
        ),
    ];
    return _panel(
      title: '${info.name} terminals',
      icon: info.icon,
      color: info.color,
      trailing: manual ? 'Tap a pin · double-tap to clear' : '${_usedPins(d, info.type)} / ${info.total} wired',
      fill: fill,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [for (final p in pins) SizedBox(width: 176, child: p)],
      ),
    );
  }

  Widget _objectsPanel(DeviceModel d, _TerminalInfo? info, bool fill) {
    final bool manual = widget.configPvd.selectedSelectionMode == SelectionMode.manual;
    final Color color = info?.color ?? Theme.of(context).primaryColor;

    Widget body;
    if (manual) {
      body = _objectCards(d, info);
    } else if (info == null) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: getAutoSelection(d));
    } else if (info.type == '1,2') {
      body = outputObject(d);
    } else {
      body = inputObject(title: '${info.name} Input', sensorCode: info.type);
    }

    return _panel(
      title: manual ? 'Object cards' : 'Objects & quantities',
      icon: manual ? Icons.touch_app_rounded : Icons.auto_fix_high_rounded,
      color: color,
      trailing: manual
          ? 'Tap a card to wire it to the selected node'
          : 'Set quantities · pins are allocated automatically',
      fill: fill,
      child: body,
    );
  }

  // ───────────────────────── manual mode: detached nodes + object cards ─────────────────────────
  Color _typeColor(String type) => type == '1,2' ? AppConstants.outputColor : getObjectTypeCodeToColor(int.parse(type));

  int _pinTotal(DeviceModel n, String type) {
    switch (type) {
      case '1,2':
        return n.noOfRelay == 0 ? n.noOfLatch : n.noOfRelay;
      case '3':
        return n.noOfAnalogInput;
      case '4':
        return n.noOfDigitalInput;
      case '5':
        return n.noOfMoistureInput;
      case '6':
        return n.noOfPulseInput;
      case '7':
        return n.noOfI2CInput;
    }
    return 0;
  }

  /// Free pins of [node] that [object] may use (same pin rules as the automatic mode).
  List<int> _freePins(DeviceModel node, DeviceObjectModel object) {
    final used = widget.configPvd.listOfGeneratedObject
        .where((g) => g.controllerId == node.controllerId && g.type == object.type && g.sNo != object.sNo)
        .map((g) => g.connectionNo)
        .toSet();
    var pins = [for (int i = 1; i <= _pinTotal(node, object.type); i++) i].where((i) => !used.contains(i)).toList();

    if (node.categoryId == 6) {
      if (object.type == '3') {
        if (object.objectId == AppConstants.phObjectId && node.modelId == 33) {
          pins = pins.where((i) => [5, 6].contains(i)).toList();
        }
        if (object.objectId == AppConstants.ecObjectId && node.modelId == 33) {
          pins = pins.where((i) => [7, 8].contains(i)).toList();
        }
      } else if (object.type == '4' && object.objectId == AppConstants.pressureSwitchObjectId) {
        pins = pins.where((i) => i == 5).toList();
      }
    }
    return pins;
  }

  void _unwire(DeviceObjectModel o) {
    o.controllerId = null;
    o.connectionNo = 0;
  }

  void _wireObject(DeviceModel node, DeviceObjectModel object, int pinNo) {
    final cfg = widget.configPvd;
    // an object already sitting on that pin goes back to "unassigned"
    for (final g in cfg.listOfGeneratedObject) {
      if (g.controllerId == node.controllerId && g.type == object.type && g.connectionNo == pinNo && g.sNo != object.sNo) {
        _unwire(g);
      }
    }
    for (final g in cfg.listOfGeneratedObject) {
      if (g.sNo == object.sNo) {
        g.controllerId = node.controllerId;
        g.connectionNo = pinNo;
        if (g.objectId == AppConstants.ecObjectId) {
          for (final e in cfg.ec) {
            if (e.sNo == g.sNo) e.controllerId = g.controllerId!;
          }
        } else if (g.objectId == AppConstants.phObjectId) {
          for (final ph in cfg.ph) {
            if (ph.sNo == g.sNo) ph.controllerId = g.controllerId!;
          }
        }
      }
    }
    cfg.updateConnectionListTile();
    setState(() {});
  }

  void _onObjectCardTap(DeviceModel node, DeviceObjectModel object) {
    final cfg = widget.configPvd;
    if (object.controllerId == node.controllerId) return; // already here – use the detach button

    int pin;
    if (cfg.selectedConnectionNo != 0 && cfg.selectedType == object.type) {
      pin = cfg.selectedConnectionNo; // pin-first flow: the pin the user tapped on the left
    } else {
      final free = _freePins(node, object);
      if (free.isEmpty) {
        simpleDialogBox(
          context: context,
          title: 'Alert',
          message: 'No free ${object.type == '1,2' ? 'relay/latch' : 'input'} terminal is left on ${node.deviceName} for ${object.name ?? object.objectName}.',
        );
        return;
      }
      pin = free.first;
    }
    _wireObject(node, object, pin);
  }

  void _detachObject(DeviceObjectModel object) {
    _unwire(object);
    widget.configPvd.updateConnectionListTile();
    setState(() {});
  }

  Widget _detachedNodesSection(DeviceModel selected) {
    final primary = Theme.of(context).primaryColor;
    final detached = _detachedNodes();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF13172E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B2A12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_off_rounded, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              const Text('Detached nodes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF3B2A12), borderRadius: BorderRadius.circular(10)),
                child: Text('${detached.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
              ),
              const Spacer(),
              const Flexible(
                child: Text('Pick a node, then tap an object card to wire it',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF8E9BB4))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (detached.isEmpty)
            const Text('Every node already has at least one object wired.',
                style: TextStyle(fontSize: 12, color: Color(0xFF8E9BB4)))
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final n in detached)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _selectModel(n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: n.controllerId == selected.controllerId ? primary.withOpacity(0.25) : const Color(0xFF181C38),
                        border: Border.all(
                          color: n.controllerId == selected.controllerId ? primary : const Color(0xFF2B335C),
                          width: n.controllerId == selected.controllerId ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.memory_rounded, size: 15, color: primary),
                          const SizedBox(width: 6),
                          Text(n.deviceName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 6),
                          Text('# ${n.deviceId}',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF8E9BB4))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _objectCards(DeviceModel node, _TerminalInfo? info) {
    final cfg = widget.configPvd;
    final String? type = info?.type;

    final cards = cfg.listOfGeneratedObject.where((o) {
      if (type != null && o.type != type) return false;
      if (o.objectId == AppConstants.powerSupplyObjectId) return false;
      if (o.objectId == AppConstants.pumpObjectId && AppConstants.ecoGemModelList.contains(cfg.masterData['modelId'])) {
        return false;
      }
      final bool onThisNode = o.controllerId == node.controllerId;
      final bool free = o.controllerId == null && node.connectingObjectId.contains(o.objectId);
      return onThisNode || free;
    }).toList()
      ..sort((a, b) => a.sNo!.compareTo(b.sNo!));

    if (cards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 30, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('No objects for this node yet.\nUse “Select Object Categories” above to choose available objects.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => showSelectObjectCategoriesDialog(
                  context: context,
                  configPvd: cfg,
                  selectedDevice: node,
                  onChanged: () {
                    cfg.updateConnectionListTile();
                    setState(() {});
                  },
                ),
                icon: const Icon(Icons.category_rounded, size: 16),
                label: const Text('Select Object Categories'),
              ),
            ],
          ),
        ),
      );
    }

    String pinLabel(DeviceObjectModel o) {
      String kw = '';
      for (final t in _terminals(node)) {
        if (t.type == o.type) kw = t.keyWord;
      }
      return '$kw${o.connectionNo}';
    }

    return ResponsiveGridList(
      horizontalGridMargin: 2,
      verticalGridMargin: 4,
      minItemWidth: 190,
      shrinkWrap: true,
      listViewBuilderOptions: ListViewBuilderOptions(
        physics: const NeverScrollableScrollPhysics(),
      ),
      children: cards.map((object) {
        final color = _typeColor(object.type);
        final bool onThisNode = object.controllerId == node.controllerId;
        final bool pinSelected =
            onThisNode && object.type == cfg.selectedType && object.connectionNo == cfg.selectedConnectionNo;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onObjectCardTap(node, object),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: pinSelected ? color.withOpacity(0.2) : const Color(0xFF181C38),
              border: Border.all(
                color: onThisNode ? color : const Color(0xFF2B335C),
                width: pinSelected ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0A2035),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: SvgPicture.asset(
                    'assets/Images/Svg/objectId_${object.objectId}.svg',
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        object.name ?? object.objectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        onThisNode ? 'Wired · ${pinLabel(object)}' : 'Unassigned',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: onThisNode ? color : const Color(0xFF8E9BB4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onThisNode)
                  Tooltip(
                    message: 'Detach from ${node.deviceName}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _detachObject(object),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.link_off_rounded, size: 17, color: Color(0xFFEF4444)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ───────────────────────── mode toggle + auto list (unchanged logic) ─────────────────────────
  Widget getSelectionCategory() {
    final primary = Theme.of(context).primaryColor;
    return SegmentedButton<SelectionMode>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10)),
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return const Color(0xFF181C38);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(0xFF8E9BB4);
        }),
        side: WidgetStateProperty.all(const BorderSide(color: Color(0xFF2B335C))),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      segments: const [
        ButtonSegment<SelectionMode>(
          value: SelectionMode.auto,
          label: Text('Automatic'),
          icon: Icon(Icons.auto_fix_high_rounded, size: 14),
        ),
        ButtonSegment<SelectionMode>(
          value: SelectionMode.manual,
          label: Text('Manual'),
          icon: Icon(Icons.touch_app_rounded, size: 14),
        ),
      ],
      selected: {widget.configPvd.selectedSelectionMode},
      onSelectionChanged: (Set<SelectionMode> newSelection) {
        setState(() {
          widget.configPvd.selectedConnectionNo = 0;
          widget.configPvd.selectedSelectionMode = newSelection.first;
        });
      },
    );
  }

  List<Widget> getAutoSelection(DeviceModel selectedDevice) {
    return [
      outputObject(selectedDevice),
      const SizedBox(height: 6),
      inputObject(title: 'Analog Input', sensorCode: AppConstants.analogCode),
      inputObject(title: 'Digital Input', sensorCode: AppConstants.digitalCode),
      inputObject(title: 'Moisture Input', sensorCode: AppConstants.moistureCode),
      inputObject(title: 'Pulse Input', sensorCode: AppConstants.pulseCode),
      inputObject(title: 'I2C Input', sensorCode: AppConstants.i2cCode),
    ];
  }

  Widget outputObject(DeviceModel selectedDevice) {
    List<int> filteredObjectList = widget.configPvd.listOfSampleObjectModel
        .where((object) {
      if (object.objectId == AppConstants.pumpObjectId &&
          AppConstants.ecoGemModelList.contains(widget.configPvd.masterData['modelId'])) {
        return false;
      } else {
        return true;
      }
    })
        .where((object) => (object.type == '1,2' &&
            (!['', '0', null].contains(object.count) ||
                widget.configPvd.listOfGeneratedObject.any((g) => g.objectId == object.objectId))))
        .toList()
        .where((object) => selectedDevice.connectingObjectId.contains(object.objectId))
        .map((object) => object.objectId)
        .toList();

    List<DeviceObjectModel> filteredList = widget.configPvd.listOfObjectModelConnection
        .where((object) => filteredObjectList.contains(object.objectId))
        .toList();

    return ConnectionGridListTile(
      listOfObjectModel: filteredList,
      title: 'Output Objects (Relay/Latch)',
      leadingColor: AppConstants.outputColor,
      configPvd: widget.configPvd,
      selectedDevice: selectedDevice,
    );
  }

  Widget inputObject({
    required String title,
    required String sensorCode,
  }) {
    DeviceModel selectedDevice = widget.configPvd.listOfDeviceModel
        .firstWhere((device) => device.controllerId == widget.configPvd.selectedModelControllerId);
    List<int> filteredObjectList = widget.configPvd.listOfSampleObjectModel
        .where((object) => (object.type == sensorCode &&
            (!['', '0', null].contains(object.count) ||
                widget.configPvd.listOfGeneratedObject.any((g) => g.objectId == object.objectId))))
        .toList()
        .where((object) => selectedDevice.connectingObjectId.contains(object.objectId))
        .map((object) => object.objectId)
        .toList();

    List<DeviceObjectModel> filteredList = widget.configPvd.listOfObjectModelConnection
        .where((object) => filteredObjectList.contains(object.objectId))
        .toList();

    return filteredList.isNotEmpty
        ? ConnectionGridListTile(
      listOfObjectModel: filteredList,
      title: title,
      configPvd: widget.configPvd,
      selectedDevice: selectedDevice,
    )
        : const SizedBox.shrink();
  }
}

enum SelectionMode { auto, manual }

class _TerminalInfo {
  final String type;
  final String name;
  final String keyWord;
  final Color color;
  final int total;
  final IconData icon;
  const _TerminalInfo({
    required this.type,
    required this.name,
    required this.keyWord,
    required this.color,
    required this.total,
    required this.icon,
  });
}