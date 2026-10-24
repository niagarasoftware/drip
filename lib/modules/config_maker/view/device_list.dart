import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/config_maker/widget/drop_down_search_field.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../../Constants/communication_codes.dart';
import '../../../Constants/dialog_boxes.dart';
import '../../../Constants/properties.dart';
import '../../../services/mqtt_service.dart';
import '../../../utils/environment.dart';
import '../../../utils/shared_preferences_helper.dart';
import '../model/device_model.dart';
import '../repository/config_maker_repository.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/custom_buttons.dart';
import '../../../Widgets/custom_drop_down_button.dart';
import '../../../Widgets/sized_image.dart';
import '../../../flavors.dart';
import 'config_base_page.dart';

class DeviceList extends StatefulWidget {
  List<DeviceModel> listOfDevices;
  DeviceList({
    super.key,
    required this.listOfDevices
  });

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  late ConfigMakerProvider configPvd;
  bool selectAllNode = false;
  late ThemeData themeData;
  late bool themeMode;
  String replaceDeviceId = '';
  MqttService mqttService = MqttService();
  String userRole = '';

  // ── design tokens (all colours derive from the app theme) ──
  static const Color _ink = Color(0xff101828);
  static const Color _muted = Color(0xff667085);
  static const Color _line = Color(0xffEAECF0);

  @override
  void initState() {
    super.initState();
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
    getUserRole();
  }

  void getUserRole() async {
    String? role = await PreferenceHelper.getUserRole();
    if (!mounted) return;
    setState(() {
      userRole = role ?? '';
    });
    print("userRole :: $userRole");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeData = Theme.of(context);
    themeMode = themeData.brightness == Brightness.light;
  }

  bool get _isPumpModel =>
      [...AppConstants.pumpWithValveModelList, ...AppConstants.pumpModelList]
          .contains(configPvd.masterData['modelId']);

  bool get _canEditDeviceId =>
      ["admin", "1"].contains(userRole) || F.title.contains('ORO');

  /// Nodes shown in the table (same filter as before).
  List<DeviceModel> get _nodes => widget.listOfDevices
      .where((node) => node.masterId == configPvd.masterData['controllerId'] && node.serialNumber != null)
      .where((node) => configPvd.masterData['controllerId'] != node.controllerId)
      .toList();

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: true);
    final nodes = _nodes;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            children: [
              if (_isPumpModel)
                Column(
                  spacing: 15,
                  children: [
                    Image.asset(
                      'assets/Images/Png/${F.name.contains('oro') ? 'Oro' : 'SmartComm'}/category_${configPvd.masterData['categoryId']}.png',
                      width: 200,
                      height: 200,
                    ),
                    Text('${configPvd.masterData["modelDescription"]}'),
                    const SizedBox(height: 20),
                  ],
                ),
              masterBox(listOfDevices: widget.listOfDevices, nodeCount: nodes.length),
              if (!_isPumpModel) ...[
                _buildConnector(),
                Expanded(child: _buildNodeTable(nodes)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── node table (compact) ────────────────────────

  static const int _fNo = 1, _fModel = 5, _fId = 3, _fExtend = 3, _fInterval = 2, _fAction = 2;

  Widget _buildNodeTable(List<DeviceModel> nodes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, 900.0);
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _line),
            boxShadow: const [BoxShadow(color: Color(0x12101828), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  _buildTableHeader(),
                  Expanded(
                    child: nodes.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                      itemCount: nodes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: _line),
                      itemBuilder: (context, i) => _buildNodeRow(nodes[i], i),
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

  Widget _buildTableHeader() {
    final style = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: themeData.primaryColorDark, letterSpacing: 0.3);
    Widget h(int flex, String text) => Expanded(flex: flex, child: Text(text, style: style));
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: themeData.primaryColor.withOpacity(0.08),
        border: const Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          h(_fNo, 'No'),
          h(_fModel, 'Model'),
          h(_fId, 'Device ID'),
          h(_fExtend, 'Extend'),
          h(_fInterval, 'Interval'),
          const Expanded(flex: _fAction, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.developer_board_outlined, size: 32, color: themeData.primaryColor.withOpacity(0.6)),
          const SizedBox(height: 8),
          const Text('No nodes added yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 2),
          const Text('Use Add Nodes to attach devices to this master.',
              style: TextStyle(fontSize: 12, color: _muted)),
        ],
      ),
    );
  }

  Widget _buildNodeRow(DeviceModel device, int index) {
    final primary = themeData.primaryColor;
    final showExtend = ![44, 45, 46, 47].contains(device.modelId) &&
        configPvd.listOfDeviceModel.any((d) => d.categoryId == 10 && d.masterId != null) &&
        device.interfaceTypeId == 1;

    return _HoverRow(
      base: index.isOdd ? const Color(0xffFAFBFC) : Colors.white,
      hover: primary.withOpacity(0.06),
      builder: (color) => Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        color: color,
        child: Row(
          children: [
            // No
            Expanded(
              flex: _fNo,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Text('${index + 1}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary)),
                ),
              ),
            ),
            // Model + description chip
            Expanded(
              flex: _fModel,
              child: Row(
                children: [
                  Flexible(
                    child: Text(device.modelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink)),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xffF2F4F7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(device.modelDescription,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: _muted)),
                    ),
                  ),
                ],
              ),
            ),
            // Device ID
            Expanded(
              flex: _fId,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    device.deviceId,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: themeData.primaryColorDark,
                    ),
                  ),
                ),
              ),
            ),
            // Extend
            Expanded(
              flex: _fExtend,
              child: showExtend
                  ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CustomDropDownButton(
                    value: getInitialExtendValue(device.extendControllerId),
                    list: [
                      '-',
                      ...configPvd.listOfDeviceModel
                          .where((d) => (d.masterId != null && d.categoryId == 10 && !AppConstants.extendLoraList.contains(d.modelId)))
                          .map((d) => '${d.deviceName}\n${d.deviceId}')
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        device.extendControllerId = getExtendControllerId(newValue!);
                      });
                    }
                ),
              )
                  : const Text('N/A', style: TextStyle(fontSize: 13, color: _muted)),
            ),
            // Interval
            Expanded(
              flex: _fInterval,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CustomDropDownButton(
                    value: getIntervalCodeToString(device.interfaceInterval!, 'Sec'),
                    list: [5, 10, 15, 20, 25].map((e) => getIntervalCodeToString(e, 'Sec')).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        device.interfaceInterval = getIntervalStringToCode(newValue!);
                      });
                    }
                ),
              ),
            ),
            // Actions
            Expanded(
              flex: _fAction,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _iconAction(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    tooltip: 'Remove node',
                    onTap: () => _onDeleteDevice(device),
                  ),
                  const SizedBox(width: 6),
                  if (_canEditDeviceId)
                    editDeviceIdWidget(masterOrNode: 2, device: device)
                  else
                    _iconAction(
                      icon: Icons.find_replace,
                      color: primary,
                      tooltip: 'Replace device',
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                elevation: 12,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                                contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.find_replace_rounded, color: primary, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Replace Node Device',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1E293B)),
                                      ),
                                    ),
                                  ],
                                ),
                                content: DropDownSearchField(productStock: configPvd.productStock, oldDevice: device.toJson(), masterOrNode: 2),
                              );
                            }
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
    bool onDark = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: onDark ? Colors.white.withOpacity(0.16) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: onDark ? Colors.white : color),
        ),
      ),
    );
  }

  /// Remove-node logic (unchanged).
  void _onDeleteDevice(DeviceModel device) {
    bool configured = configPvd.listOfGeneratedObject.any((object) => object.controllerId == device.controllerId);
    int valveCount = configPvd.listOfGeneratedObject.where((object) => object.objectId == AppConstants.valveObjectId).length;
    int moistureCount = configPvd.listOfGeneratedObject.where((object) => object.objectId == AppConstants.moistureObjectId).length;

    if (configured) {
      simpleDialogBox(context: context, title: 'Alert', message: '${device.deviceName} cannot be removed. Please detach all connected objects first.');
    } else if (
    AppConstants.pumpWithValveModelList.contains(configPvd.masterData['modelId'])
        &&
        ((AppConstants.senseModelList.contains(device.modelId) && moistureCount != 0) || (![...AppConstants.pumpWithValveModelList, ...AppConstants.senseModelList].contains(device.modelId) && valveCount > 2))) {
      if (AppConstants.senseModelList.contains(device.modelId) && moistureCount != 0) {
        simpleDialogBox(context: context, title: 'Alert', message: '${device.deviceName} cannot be removed. Because Moisture connected to ${device.deviceName}.');
      } else if (valveCount > 2) {
        simpleDialogBox(context: context, title: 'Alert', message: '${device.deviceName} cannot be removed. Because valve connected to ${device.deviceName}');
      }
    } else {
      setState(() {
        device.masterId = null;
        if (device.categoryId == 10) {
          for (var d in configPvd.listOfDeviceModel) {
            if (d.extendControllerId != null && d.extendControllerId == device.masterId) {
              d.extendControllerId = null;
            }
          }
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  MASTER CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget masterBox({required List<DeviceModel> listOfDevices, required int nodeCount}) {
    final primary = themeData.primaryColor;
    final dark = themeData.primaryColorDark;

    Widget circle(double size, double opacity) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [dark, primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [BoxShadow(color: dark.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -60, child: circle(170, 0.06)),
          Positioned(right: 150, bottom: -70, child: circle(120, 0.05)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: SizedImageMedium(
                      imagePath: 'assets/Images/Png/${F.name.contains('oro') ? 'Oro' : 'SmartComm'}/category_${configPvd.masterData['categoryId']}.png'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${configPvd.masterData['deviceName']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hub_rounded, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Master',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text('Device ID', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                          const SizedBox(width: 8),
                          SelectableText(
                            '${configPvd.masterData['deviceId']}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_canEditDeviceId)
                            editDeviceIdWidget(masterOrNode: 1, onDark: true)
                          else
                            _iconAction(
                              icon: Icons.find_replace,
                              color: Colors.white,
                              tooltip: 'Replace device',
                              onDark: true,
                              onTap: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        backgroundColor: Colors.white,
                                        elevation: 12,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                                        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                                        title: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: themeData.primaryColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.find_replace_rounded, color: themeData.primaryColor, size: 24),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Text(
                                                'Replace Master Device',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1E293B)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: DropDownSearchField(productStock: configPvd.productStock, oldDevice: configPvd.masterData, masterOrNode: 1),
                                      );
                                    }
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_isPumpModel) ...[
                  _statTile(Icons.device_hub, '$nodeCount', nodeCount == 1 ? 'Node' : 'Nodes'),
                  const SizedBox(width: 12),
                  _addNodesButton(listOfDevices),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75))),
        ],
      ),
    );
  }

  Widget _addNodesButton(List<DeviceModel> listOfDevices) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showAddNodesDialog(listOfDevices),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, size: 18, color: themeData.primaryColor),
              const SizedBox(width: 6),
              Text('Add Nodes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: themeData.primaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  /// Short vertical link that shows the nodes hang under the master.
  Widget _buildConnector() {
    final c = themeData.primaryColor.withOpacity(0.45);
    return SizedBox(
      height: 18,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 38),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: Container(width: 2, color: c)),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ADD NODES (logic unchanged)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAddNodesDialog(List<DeviceModel> listOfDevices) {
    setState(() {
      selectAllNode = false;
    });
    for (var device in listOfDevices) {
      if (device.serialNumber != null && device.masterId != null && configPvd.serialNumber < device.serialNumber!) {
        setState(() {
          configPvd.serialNumber = device.serialNumber!;
        });
      }
    }
    print('configPvd.masterData ::: ${configPvd.masterData}');
    print('listOfDevices ::: ${listOfDevices}');

    List<DeviceModel> possibleNodeToConfigUnderMaster = listOfDevices.where((node) {
      List<int> nodeUnderPumpWithValveModel = [15, 17, 23, 25, 42];
      List<int> nodeNotUnderGemModel = [48, 49];
      print("node => ${node.modelId} == ${node.modelDescription} == ${node.modelName}");
      if (AppConstants.pumpWithValveModelList.contains(configPvd.masterData['modelId']) && nodeUnderPumpWithValveModel.contains(node.modelId)) {
        /* this condition filter node for pump with valve model * */
        return true;
      } else if (AppConstants.gemModelList.contains(configPvd.masterData['modelId']) && !nodeNotUnderGemModel.contains(node.modelId)) {
        /* this condition filter node for gem model */
        return true;
      } else if (AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId'])) {
        /* this condition filter node for eco gem */
        return true;
      } else if (AppConstants.omsGemList.contains(configPvd.masterData['modelId'])) {
        print('omssssss');
        return true;
      } else {
        return false;
      }
    }).toList();
    print('possibleNodeToConfigUnderMaster : $possibleNodeToConfigUnderMaster');
    bool isThereNodeToConfigure = possibleNodeToConfigUnderMaster.any((node) => node.masterId == null);
    if (!isThereNodeToConfigure) {
      simpleDialogBox(context: context, title: 'Alert', message: 'There are no available nodes to configure at the moment');
      return;
    }

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, stateSetter) {
                final filteredNodes = listOfDevices
                    .where((node) => node.masterId == null)
                    .where((node) {
                  List<int> nodeUnderPumpWithValveModel = [15, 17, 23, 25, 42];
                  List<int> nodeUnderEcoGemModel = [36, 50, 42];
                  List<int> nodeNotUnderGemModel = [48, 49];
                  if (AppConstants.pumpWithValveModelList.contains(configPvd.masterData['modelId']) && nodeUnderPumpWithValveModel.contains(node.modelId)) {
                    return true;
                  } else if (AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId']) && nodeUnderEcoGemModel.contains(node.modelId)) {
                    return true;
                  } else if (AppConstants.gemModelList.contains(configPvd.masterData['modelId']) && !nodeNotUnderGemModel.contains(node.modelId)) {
                    return true;
                  } else if (AppConstants.omsGemList.contains(configPvd.masterData['modelId'])) {
                    return true;
                  } else {
                    return false;
                  }
                }).toList();

                final selectedCount = filteredNodes.where((n) => n.select).length;

                return AlertDialog(
                  backgroundColor: Colors.white,
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeData.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.hub_rounded, color: themeData.primaryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Nodes for Configuration',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1E293B)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select nodes to configure under Master controller',
                              style: TextStyle(fontSize: 12, color: Color(0xff64748B), fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width >= 550 ? 550 : double.infinity,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selectAllNode,
                                  activeColor: themeData.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (value) {
                                    stateSetter(() {
                                      setState(() {
                                        selectAllNode = !selectAllNode;
                                        for (var device in configPvd.listOfDeviceModel) {
                                          device.select = selectAllNode;
                                        }
                                      });
                                    });
                                  },
                                ),
                                const Text(
                                  'Select All Available Nodes',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff334155)),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: themeData.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$selectedCount selected',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themeData.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (var device in filteredNodes)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: device.select ? themeData.primaryColor.withOpacity(0.04) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: device.select ? themeData.primaryColor : Colors.grey.shade200,
                                  width: device.select ? 1.5 : 1.0,
                                ),
                              ),
                              child: CheckboxListTile(
                                activeColor: themeData.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                value: device.select,
                                onChanged: (value) {
                                  stateSetter(() {
                                    setState(() {
                                      device.select = value!;
                                    });
                                  });
                                },
                                title: Text(
                                  device.deviceName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1E293B)),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      device.modelDescription,
                                      style: TextStyle(color: themeData.primaryColor, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '•  ID: ${device.deviceId}',
                                      style: const TextStyle(color: Color(0xff64748B), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xff475467))),
                    ),
                    CustomMaterialButton(
                      title: 'Add Selected',
                      icon: Icons.add_rounded,
                      onPressed: () {
                        for (var node in configPvd.listOfDeviceModel) {
                          stateSetter(() {
                            setState(() {
                              if (node.select) {
                                configPvd.serialNumber += 1;
                                node.masterId = configPvd.masterData['controllerId'];
                                node.select = false;
                                node.serialNumber = configPvd.serialNumber;
                              }
                            });
                          });
                        }
                        stateSetter(() {
                          setState(() {
                            configPvd.listOfDeviceModel.sort((a, b) {
                              if (a.serialNumber == null && b.serialNumber == null) return 0;
                              if (a.serialNumber == null) return 1; // nulls last
                              if (b.serialNumber == null) return -1;
                              return a.serialNumber!.compareTo(b.serialNumber!);
                            });
                          });
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REPLACE DEVICE ID (logic unchanged, button restyled)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget editDeviceIdWidget({required int masterOrNode, DeviceModel? device, bool onDark = false}) {
    return _iconAction(
      icon: Icons.edit_note_outlined,
      color: themeData.primaryColor,
      tooltip: 'Replace device ID',
      onDark: onDark,
      onTap: () {
        setState(() {
          replaceDeviceId = masterOrNode == 1 ? configPvd.masterData['deviceId'] : device!.deviceId;
        });
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: Colors.white,
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeData.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit_note_rounded, color: themeData.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Replace Device ID',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1E293B)),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter the new unique identifier for this device:',
                      style: TextStyle(fontSize: 13, color: Color(0xff64748B)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: replaceDeviceId,
                      decoration: InputDecoration(
                        labelText: 'Device ID',
                        hintText: 'Enter device ID',
                        prefixIcon: Icon(Icons.developer_board_rounded, color: themeData.primaryColor),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: themeData.primaryColor, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          replaceDeviceId = value;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xff475467))),
                  ),
                  CustomMaterialButton(
                    title: 'Replace',
                    icon: Icons.find_replace_rounded,
                    onPressed: () async {
                      Navigator.pop(context);
                      loadingDialog();
                      int status = await changeDeviceId(
                        productId: masterOrNode == 1 ? configPvd.masterData['productId'] : device!.productId,
                        modelId: masterOrNode == 1 ? configPvd.masterData['modelId'] : device!.modelId,
                        controllerId: masterOrNode == 1 ? configPvd.masterData['controllerId'] : device!.controllerId,
                        deviceId: masterOrNode == 1 ? configPvd.masterData['deviceId'] : device!.deviceId,
                        masterOrNode: masterOrNode,
                      );
                      if (status == 200) {
                        var oldTopic = '${Environment.mqttSubscribeTopic}/${configPvd.masterData['deviceId']}';
                        if (masterOrNode == 1) {
                          configPvd.masterData['deviceId'] = replaceDeviceId;
                        } else {
                          device!.deviceId = replaceDeviceId;
                        }
                        setState(() {});
                        mqttService.topicToSubscribe('${Environment.mqttSubscribeTopic}/${configPvd.masterData['deviceId']}');
                        mqttService.topicToUnSubscribe(oldTopic);
                        Navigator.pop(context);
                      }
                    },
                  )
                ],
              );
            }
        );
      },
    );
  }

  Future<int> changeDeviceId({required int productId, required int modelId, required int controllerId, required String deviceId, required int masterOrNode}) async {
    try {
      var body = {
        // "productId": productId,
        // "modelId": modelId,
        "deviceId": replaceDeviceId,
        // "modifyUser": configPvd.masterData['customerId'],
      };
      var response = await ConfigMakerRepository().checkProduct(body);
      print("response +++ ${response.body}");
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (response.statusCode == 200 && jsonData["code"] == 200) {
        print("jsonData : $jsonData");
        String message = '${jsonData['message']}';
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 100));
        simpleDialogBox(
            context: context,
            title: 'Alert',
            message: message,
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_outline_rounded, color: Theme.of(context).primaryColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Registered Owner', style: TextStyle(fontSize: 11, color: Color(0xff64748B))),
                            Text(
                              '${jsonData['data'][0]['userName']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1E293B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.phone_outlined, color: Theme.of(context).primaryColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mobile Number', style: TextStyle(fontSize: 11, color: Color(0xff64748B))),
                            Text(
                              '${jsonData['data'][0]['mobileNumber']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1E293B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actionButton: [
              CustomMaterialButton(
                title: 'Cancel',
                outlined: true,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              CustomMaterialButton(
                title: 'Replace',
                icon: Icons.find_replace_rounded,
                onPressed: () async {
                  var newDeviceData = {
                    'deviceId': jsonData['data'][0]['deviceId'],
                    'modelId': jsonData['data'][0]['modelId'],
                  };
                  var oldDeviceData = {
                    'deviceId': deviceId,
                    'modelId': modelId,
                    'controllerId': controllerId,
                  };
                  Navigator.pop(context);
                  loadingDialog();
                  int statusCode = await configPvd.replaceDevice(newDevice: newDeviceData, oldDevice: oldDeviceData, masterOrNode: masterOrNode);
                  if (statusCode == 200) {
                    Navigator.pop(context);
                    simpleDialogBox(context: context, title: 'Success', message: 'Product updated successfully..');
                  } else {
                    Navigator.pop(context);
                    simpleDialogBox(context: context, title: 'Failed', message: 'Product not updated..');
                  }
                },
              ),
            ]
        );

        return jsonData['code'];
      } else {
        var newDeviceData = {
          'deviceId': replaceDeviceId,
          'modelId': null,
        };
        var oldDeviceData = {
          'deviceId': deviceId,
          'modelId': modelId,
          'controllerId': controllerId,
        };
        int statusCode = await configPvd.replaceDevice(newDevice: newDeviceData, oldDevice: oldDeviceData, masterOrNode: masterOrNode);
        if (statusCode == 200) {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 100));
          simpleDialogBox(context: context, title: 'Success', message: 'Product updated successfully..');
        } else {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 100));
          simpleDialogBox(context: context, title: 'Failed', message: 'Product not updated..');
        }
        return 404;
      }
    } catch (e, stackTrace) {
      simpleDialogBox(context: context, title: 'Failed', message: e.toString());
      print('Error on converting to device model :: $e');
      print('stackTrace on converting to device model :: $stackTrace');
      return 404;
    }
  }

  void loadingDialog() {
    showDialog(
        context: context,
        useRootNavigator: true,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(themeData.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please wait...',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1E293B)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Updating device configuration...',
                        style: TextStyle(fontSize: 12, color: Color(0xff64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  String getInitialExtendValue(int? extendControllerId) {
    String value;
    if (extendControllerId != null) {
      DeviceModel deviceModel = configPvd.listOfDeviceModel.firstWhere((device) => device.controllerId == extendControllerId);
      value = '${deviceModel.deviceName}\n${deviceModel.deviceId}';
    } else {
      value = '-';
    }
    print('getInitialExtendValue : $value');
    return value;
  }

  int? getExtendControllerId(String value) {
    if (value == '-') {
      return null;
    } else {
      DeviceModel deviceModel = configPvd.listOfDeviceModel.firstWhere((device) => device.deviceId == value.split('\n')[1]);
      return deviceModel.controllerId;
    }
  }

  String getTabName(ConfigMakerTabs configMakerTabs) {
    switch (configMakerTabs) {
      case ConfigMakerTabs.connection:
        return 'Connection';
      case ConfigMakerTabs.siteConfigure:
        return 'Site Configure';
      case ConfigMakerTabs.siteDiagram:
        return 'Site Diagram';
    }
  }

  String getTabImage(ConfigMakerTabs configMakerTabs) {
    switch (configMakerTabs) {
      case ConfigMakerTabs.connection:
        return 'connection_';
      case ConfigMakerTabs.siteConfigure:
        return 'site_configure_';
      case ConfigMakerTabs.siteDiagram:
        return 'site_diagram_';
    }
  }
}

class _HoverRow extends StatefulWidget {
  final Color base;
  final Color hover;
  final Widget Function(Color color) builder;
  const _HoverRow({required this.base, required this.hover, required this.builder});

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: widget.builder(hovering ? Color.alphaBlend(widget.hover, widget.base) : widget.base),
    );
  }
}

Color textColorInCell = const Color(0xff667085);
TextStyle textStyleInCell = TextStyle(color: textColorInCell, fontWeight: FontWeight.bold, fontSize: 13);