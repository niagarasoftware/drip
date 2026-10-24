import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/valve_configuration.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/product_limit.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/site_configure.dart';
import 'package:oro_drip_irrigation/Widgets/sized_image.dart';
import 'package:oro_drip_irrigation/modules/constant/state_management/constant_provider.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:oro_drip_irrigation/services/communication_service.dart';
import 'package:oro_drip_irrigation/utils/environment.dart';
import 'package:provider/provider.dart';
import '../../../Constants/constants.dart';
import '../../../Constants/properties.dart';
import '../../../Widgets/status_box.dart';
import '../../../flavors.dart';
import '../../Preferences/view/preference_main_screen.dart';
import '../../constant/view/constant_base_page.dart';
import '../model/channel_config_model.dart';
import '../model/device_model.dart';
import '../model/ec_model.dart';
import '../model/fertigation_model.dart';
import '../model/filtration_model.dart';
import '../model/irrigation_line_model.dart';
import '../model/moisture_model.dart';
import '../model/ph_model.dart';
import '../model/pressure_model.dart';
import '../model/pump_model.dart';
import '../model/source_model.dart';
import '../repository/config_maker_repository.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/custom_buttons.dart';
import '../../../Widgets/custom_side_tab.dart';
import '../../../Widgets/title_with_back_button.dart';
import '../../../utils/constants.dart';
import '../../../Constants/dialog_boxes.dart';
import 'config_base_page.dart';
import 'config_mobile_view.dart';
import 'connection.dart';
import 'device_list.dart';
import 'draw_your_site.dart';

class ConfigWebView extends StatefulWidget {
  List<DeviceModel> listOfDevices;
  ConfigWebView({super.key, required this.listOfDevices});

  @override
  State<ConfigWebView> createState() => _ConfigWebViewState();
}

class _ConfigWebViewState extends State<ConfigWebView> {
  late ConfigMakerProvider configPvd;
  late Future<List<DeviceModel>> listOfDevices;
  double sideNavigationWidth = 220;
  double sideNavigationBreakPointWidth = 60;
  double sideNavigationTabWidth = 200;
  double sideNavigationTabBreakPointWidth = 50;
  double webBreakPoint = 1000;
  late ThemeData themeData;
  late bool themeMode;
  List<Map<String, dynamic>> listOfPayload = [];
  PayloadSendState payloadSendState = PayloadSendState.idle;
  MqttService mqttService = MqttService();
  bool isDataSaved = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  HardwareAcknowledgementState payloadState = HardwareAcknowledgementState.notSent;
  bool isNewConfig = false;

  @override
  void initState() {
    super.initState();
    configPvd = Provider.of<ConfigMakerProvider>(context, listen: false);
    mqttService.initializeMQTTClient();
    mqttService.connect();
    mqttService.topicToSubscribe('${Environment.mqttSubscribeTopic}/${configPvd.masterData['deviceId']}');
    // MqttManager().topicToPublishAndItsMessage('${Environment.mqttWebPublishTopic}/${configPvd.masterData['deviceId']}', jsonEncode(configMakerPayload));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeData = Theme.of(context);
    themeMode = themeData.brightness == Brightness.light;
  }

  void _onPopInvokedWithResult(bool didPop, dynamic result) async {
    if (didPop) return; // If already popped, do nothing

    if (!isDataSaved) {
      bool? shouldLeave = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
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
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Unsaved Changes",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1E293B)),
              ),
            ],
          ),
          content: const Text(
            "You have unsaved changes in your configuration. Do you really want to leave?",
            style: TextStyle(fontSize: 14, color: Color(0xff475467), height: 1.4),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel", style: TextStyle(color: Color(0xff475467))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text("Leave", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (shouldLeave == true) {
        Navigator.of(context).pop(result);
      }
    } else {
      Navigator.of(context).pop(result);
    }
  }

  Widget getHardwareAcknowledgementWidget(HardwareAcknowledgementState state){
    if(state == HardwareAcknowledgementState.notSent){
      return const StatusBox(color:  Colors.black87,child: Text('Do you want to send payload..',),);
    }else if(state == HardwareAcknowledgementState.success){
      return const StatusBox(color:  Colors.green,child: Text('Success..',),);
    }else if(state == HardwareAcknowledgementState.failed){
      return const StatusBox(color:  Colors.red,child: Text('Failed..',),);
    }else if(state == HardwareAcknowledgementState.errorOnPayload){
      return const StatusBox(color:  Colors.red,child: Text('Payload error..',),);
    }else{
      return const SizedBox(
          width: double.infinity,
          height: 5,
          child: LinearProgressIndicator()
      );
    }
  }

  Map<String, dynamic> getConstantHardwarePayload(){
    var constPvd = Provider.of<ConstantProvider>(context, listen: false);
    var generalPayload = constPvd.getGeneralPayload();
    print("generalPayload : $generalPayload");
    var globalAlarmPayload = constPvd.getGlobalAlarmPayload();
    print("globalAlarmPayload : $globalAlarmPayload");
    var globalAlarmForEcoGem = constPvd.getEcoGemPayloadForGlobalAlarm();
    print("globalAlarmForEcoGem : $globalAlarmForEcoGem");
    var levelSensorPayload = constPvd.getObjectInConstantPayload(constPvd.level);
    print("levelSensorPayload : $levelSensorPayload");
    var pumpPayload = constPvd.getObjectInConstantPayload(constPvd.pump);
    print("pumpPayload : $pumpPayload");
    var channelPayload = constPvd.getObjectInConstantPayload(constPvd.channel);
    print("channelPayload : $channelPayload");
    var fertilizerSitePayload = constPvd.getFertilizerSitePayload();
    print("fertilizerSitePayload : $fertilizerSitePayload");
    var waterMeterPayload = constPvd.getObjectInConstantPayload(constPvd.waterMeter);
    print("waterMeterPayload : $waterMeterPayload");
    var mainValvePayload = constPvd.getObjectInConstantPayload(constPvd.mainValve);
    print("mainValvePayload : $mainValvePayload");
    var valvePayload = constPvd.getObjectInConstantPayload(constPvd.valve);
    print("valvePayload : $valvePayload");
    var normalCriticalPayload = AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId']) ? constPvd.getNormalCriticalAlarmForEcoGem() : constPvd.getNormalCriticalAlarm();
    print("normalCriticalPayload : $normalCriticalPayload");
    var filterPayload = constPvd.getFilterSitePayload();
    print("filterPayload : $filterPayload");
    print("constPvd.userData['modelId'] : ${constPvd.userData['modelId']}");
    bool isGem = AppConstants.gemModelList.contains(constPvd.userData['modelId']);
    bool isOms = AppConstants.omsGemList.contains(constPvd.userData['modelId']);
    var hardwarePayload = {
      "300" : {
        "301" : isOms ? '' : generalPayload,
        if(isGem)
          "302" : mainValvePayload,
        "303" : valvePayload,
        "304" : waterMeterPayload,
        "305" : channelPayload,
        if(isGem)
          "306" : fertilizerSitePayload,
        if(isGem)
          "307" : levelSensorPayload,
        "308" : normalCriticalPayload,
        "309" : pumpPayload,
        "310" : filterPayload,
      }
    };
    return hardwarePayload;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REDESIGNED UI
  // ═══════════════════════════════════════════════════════════════════════════

  List<ConfigMakerTabs> get _visibleTabs =>
      ConfigMakerTabs.values.where(validateTab).toList();

  Color get _barColor =>
      themeData.primaryColorDark.withOpacity(themeMode ? 1.0 : 0.2);

  void _goToStep(int offset) {
    final tabs = _visibleTabs;
    final index = tabs.indexOf(configPvd.selectedTab) + offset;
    if (index < 0 || index >= tabs.length) return;
    updateConfigMakerTabs(
      context: context,
      configPvd: configPvd,
      setState: setState,
      selectedTab: tabs[index],
    );
  }

  void _onSendConfig() {
    String? validationError = configPvd.validateGemConfiguration();
    if (validationError != null) {
      simpleDialogBox(
        context: context,
        title: 'Alert',
        message: validationError,
      );
      return;
    }
    setState(() {
      payloadSendState = PayloadSendState.idle;
    });
    sendToMqtt();
    sendToHttp();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        backgroundColor: _barColor,
        bottomNavigationBar: _buildActionBar(),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(
                        key: ValueKey(configPvd.selectedTab),
                        child: configPvd.selectedTab == ConfigMakerTabs.deviceList
                            ? DeviceList(listOfDevices: widget.listOfDevices)
                            : configPvd.selectedTab == ConfigMakerTabs.productLimit
                            ? ProductLimit(listOfDevices: widget.listOfDevices, configPvd: configPvd)
                            : configPvd.selectedTab == ConfigMakerTabs.connection
                            ? Connection(configPvd: configPvd)
                            : configPvd.selectedTab == ConfigMakerTabs.siteConfigure
                            ? SiteConfigure(configPvd: configPvd)
                            : const DrawYourSiteScreen(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── header ──────────────────────────────────────

  Widget _buildHeader() {
    final tabs = _visibleTabs;
    final selectedIndex = tabs.indexOf(configPvd.selectedTab);
    final deviceId = '${configPvd.masterData['deviceId'] ?? ''}';

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Tooltip(
            message: 'Back',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Config Maker',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (deviceId.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                deviceId,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, letterSpacing: 0.4),
              ),
            ),
          ],
          const SizedBox(width: 10),
          _buildMqttChip(),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildStepper(tabs, selectedIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Config is a real sequence (devices → limits → connections → site),
  /// so numbered steps with a "done" state show the user where they are.
  Widget _buildStepper(List<ConfigMakerTabs> tabs, int selectedIndex) {
    final children = <Widget>[];
    for (var i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      final selected = i == selectedIndex;
      final done = i < selectedIndex;

      if (i > 0) {
        children.add(Container(
          width: 20,
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(i <= selectedIndex ? 0.8 : 0.25),
            borderRadius: BorderRadius.circular(1),
          ),
        ));
      }

      final pillColor = selected
          ? (themeMode ? Colors.white : themeData.primaryColorLight.withOpacity(0.5))
          : Colors.transparent;
      final textColor = selected && themeMode ? themeData.primaryColor : Colors.white;

      children.add(
        Tooltip(
          message: getTabName(tab),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => updateConfigMakerTabs(
              context: context,
              configPvd: configPvd,
              setState: setState,
              selectedTab: tab,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? themeData.primaryColorLight
                          : selected
                          ? (themeMode
                          ? themeData.primaryColor.withOpacity(0.12)
                          : Colors.white.withOpacity(0.2))
                          : Colors.transparent,
                      border: (!done && !selected)
                          ? Border.all(color: Colors.white.withOpacity(0.45))
                          : null,
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                      '${i + 1}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    getTabName(tab),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  // ───────────────────────────── bottom action bar ───────────────────────────

  // ─────────────────────────────────────────────────────────────────────────────
// REPLACE the old _buildActionBar(), _sectionLabel(), _barDivider() and
// _barButton() in _ConfigWebViewState with everything below.
// All existing logic (_goToStep, _onSendConfig, _openConstantPage,
// _openPreferencePage, _showClearConfigDialog) is reused unchanged.
// ─────────────────────────────────────────────────────────────────────────────

  static const Color _sendGreen = Color(0xff16A34A);

  Widget _buildActionBar() {
    final tabs = _visibleTabs;
    final index = tabs.indexOf(configPvd.selectedTab);
    final isFirst = index <= 0;
    final isLast = index >= tabs.length - 1;

    return Container(
      decoration: BoxDecoration(
        color: _barColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.12))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 950;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth - 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ── LEFT : tools ─────────────────────────────────────────
                    _toolsGroup(compact),

                    // ── RIGHT : navigation + send ────────────────────────────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _iconAction(
                          icon: Icons.chevron_left_rounded,
                          tooltip: 'Previous step',
                          onTap: isFirst ? null : () => _goToStep(-1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${index + 1} / ${tabs.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        _solidButton(
                          label: (isLast || compact)
                              ? 'Next'
                              : 'Next: ${getTabName(tabs[index + 1])}',
                          tooltip: isLast
                              ? 'Last step'
                              : 'Proceed to ${getTabName(tabs[index + 1])}',
                          background: Colors.white,
                          foreground: themeData.primaryColor,
                          trailing: Icons.arrow_forward_rounded,
                          onTap: isLast ? null : () => _goToStep(1),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 1,
                          height: 22,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(width: 10),
                        _solidButton(
                          label: 'Send Config',
                          tooltip: 'Save & transmit configuration to device',
                          background: _sendGreen,
                          foreground: Colors.white,
                          leadingWidget: SizedImageSmall(
                            imagePath: '${AppConstants.svgObjectPath}send.svg',
                            color: Colors.white,
                          ),
                          onTap: (){},
                          // onTap: _onSendConfig,
                        ),
                        const SizedBox(width: 4),
                        _moreMenu(),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Constant + Preference in one translucent pill.
  Widget _toolsGroup(bool compact) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ghostButton(
            icon: Icons.tune_rounded,
            label: 'Constant',
            tooltip: 'Open Constant settings page',
            compact: compact,
            onTap: _openConstantPage,
          ),
          Container(width: 1, height: 18, color: Colors.white.withOpacity(0.2)),
          _ghostButton(
            icon: Icons.settings_outlined,
            label: 'Preference',
            tooltip: 'Open Preference settings page',
            compact: compact,
            onTap: _openPreferencePage,
          ),
        ],
      ),
    );
  }

  /// Text-less/low-emphasis button used inside the tools pill.
  Widget _ghostButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? tooltip,
    bool compact = false,
  }) {
    return Tooltip(
      message: tooltip ?? label,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        hoverColor: Colors.white.withOpacity(0.14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Small round icon button (used for "previous step").
  Widget _iconAction({
    required IconData icon,
    required VoidCallback? onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          hoverColor: Colors.white.withOpacity(0.14),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  /// Filled button – used for Next (white) and Send Config (green).
  Widget _solidButton({
    required String label,
    required VoidCallback? onTap,
    required Color background,
    required Color foreground,
    IconData? trailing,
    Widget? leadingWidget,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? label,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(10),
          elevation: onTap == null ? 0 : 2,
          shadowColor: Colors.black38,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            hoverColor: Colors.black.withOpacity(0.06),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingWidget != null) ...[
                    leadingWidget,
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
                    Icon(trailing, color: foreground, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Overflow menu: keeps the destructive action away from Send.
  Widget _moreMenu() {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      offset: const Offset(0, -56),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
      onSelected: (value) {
        if (value == 'clear') _showClearConfigDialog();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'clear',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.delete_sweep_outlined, color: Colors.red.shade600, size: 18),
              const SizedBox(width: 10),
              Text(
                'Clear Config',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _barDivider() => Container(width: 1, height: 22, color: Colors.white.withOpacity(0.2));

  Widget _buildMqttChip() {
    return StreamBuilder(
      stream: mqttService.mqttConnectionStream,
      initialData: MqttConnectionState.disconnected,
      builder: (context, snapShot) {
        final connected = mqttService.isConnected;
        final dotColor = connected ? Colors.greenAccent : Colors.redAccent;
        final statusText = connected ? 'MQTT Connected' : 'MQTT Disconnected';
        return Tooltip(
          message: statusText,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dotColor.withOpacity(0.35), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: [BoxShadow(color: dotColor.withOpacity(0.8), blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// One button style for the whole bar.
  /// primary  → solid white (the single main action on each side)
  /// default  → translucent outline
  /// onTap == null → disabled
  Widget _barButton({
    required String label,
    required VoidCallback? onTap,
    Widget? leading,
    Widget? trailing,
    bool primary = false,
    bool compact = false,
    bool isDanger = false,
    String? tooltip,
  }) {
    final enabled = onTap != null;
    final fg = primary
        ? themeData.primaryColor
        : isDanger
        ? Colors.redAccent.shade100
        : Colors.white;
    final showLabel = !compact || primary;

    return Tooltip(
      message: tooltip ?? label,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: primary
              ? Colors.white
              : isDanger
              ? Colors.red.withOpacity(0.12)
              : Colors.white.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: primary
                ? BorderSide.none
                : isDanger
                ? BorderSide(color: Colors.redAccent.withOpacity(0.4))
                : BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            hoverColor: primary
                ? themeData.primaryColorLight.withOpacity(0.15)
                : isDanger
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.12),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 10, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) leading,
                  if (leading != null && showLabel) const SizedBox(width: 6),
                  if (showLabel)
                    Text(
                      label,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  if (trailing != null && showLabel) const SizedBox(width: 6),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────── dialogs / pages (logic unchanged) ───────────────────

  void _showClearConfigDialog() {
    showDialog(
      context: context,
      builder: (context) {
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
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade600, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Clear Configuration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1E293B)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently remove the current configuration. Please enter your password to continue.',
                style: TextStyle(fontSize: 14, color: Color(0xff475467), height: 1.4),
              ),
              const SizedBox(height: 16),
              Form(
                key: formKey,
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    } else if (value !=
                        (F.title.toLowerCase().contains('oro')
                            ? 'Oro@321'
                            : F.title.toLowerCase().contains('smart')
                            ? 'LK@321'
                            : F.title.toLowerCase().contains('agritel')
                            ? 'Agritel@321'
                            : 'Oro@321')) {
                      return 'Invalid password';
                    }
                    return null;
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintText: 'Enter Password',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff94A3B8),
                    ),
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: Theme.of(context).primaryColor),
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
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancel', style: TextStyle(color: Color(0xff475467))),
            ),
            CustomMaterialButton(
              color: Colors.red.shade600,
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  configPvd.clearData();
                  setState(() {
                    isNewConfig = true;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Clear Config', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openPreferencePage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preference')),
        body: PreferenceMainScreen(
          userId: configPvd.masterData['userId'],
          customerId: configPvd.masterData['customerId'],
          masterData: configPvd.masterData,
          selectedIndex: 0,
        ),
      );
    }));
  }

  void _openConstantPage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Constant'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                icon: const Icon(Icons.send, size: 18),
                onPressed: _showSendConstantDialog,
                label: const Text('Send constant'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        body: ConstantBasePage(userData: {
          "userId": configPvd.masterData['userId'],
          "customerId": configPvd.masterData['customerId'],
          "controllerId": configPvd.masterData['controllerId'],
          "deviceId": configPvd.masterData['deviceId'],
          "modelId": configPvd.masterData['modelId'],
          "deviceName": configPvd.masterData['deviceName'],
          "categoryId": configPvd.masterData['categoryId'],
          "categoryName": configPvd.masterData['categoryName'],
        }),
      );
    }));
  }

  /// Same send / acknowledgement loop as before, moved out of the widget tree.
  void _showSendConstantDialog() {
    setState(() {
      payloadState = HardwareAcknowledgementState.notSent;
      mqttService.acknowledgementPayload = null;
    });
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, stateSetter) {
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.cloud_upload_rounded, color: Theme.of(context).primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Send Constant Payload',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1E293B)),
                ),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: getHardwareAcknowledgementWidget(payloadState),
            ),
            actions: [
              if (payloadState != HardwareAcknowledgementState.sending &&
                  payloadState != HardwareAcknowledgementState.notSent)
                const CustomMaterialButton(title: 'Close'),
              if (payloadState == HardwareAcknowledgementState.notSent)
                CustomMaterialButton(title: 'Cancel', outlined: true),
              if (payloadState == HardwareAcknowledgementState.notSent)
                CustomMaterialButton(
                  title: 'Send Payload',
                  icon: Icons.send_rounded,
                  onPressed: () async {
                    sendToHttp();
                    var payload = jsonEncode(getConstantHardwarePayload());
                    int delayDuration = 50;
                    for (var delay = 0; delay < delayDuration; delay++) {
                      if (delay == 0) {
                        stateSetter(() {
                          setState(() {
                            context.read<CommunicationService>().sendCommand(
                              serverMsg: '',
                              payload: payload,
                            );
                            payloadState = HardwareAcknowledgementState.sending;
                          });
                        });
                      }
                      stateSetter(() {
                        setState(() {
                          if (mqttService.acknowledgementPayload != null) {
                            if (validatePayloadFromHardware(mqttService.acknowledgementPayload, ['cC'], configPvd.masterData['deviceId']) &&
                                validatePayloadFromHardware(mqttService.acknowledgementPayload!, ['cM', '4201', 'PayloadCode'], '300')) {
                              final code = mqttService.acknowledgementPayload!['cM']['4201']['Code'];
                              if (code == '200') {
                                payloadState = HardwareAcknowledgementState.success;
                              } else if (code == '90') {
                                payloadState = HardwareAcknowledgementState.programRunning;
                              } else if (code == '1') {
                                payloadState = HardwareAcknowledgementState.hardwareUnknownError;
                              } else {
                                payloadState = HardwareAcknowledgementState.errorOnPayload;
                              }
                              mqttService.acknowledgementPayload = null;
                            }
                          }
                        });
                      });
                      await Future.delayed(const Duration(seconds: 1));
                      if (delay == delayDuration - 1) {
                        stateSetter(() {
                          setState(() {
                            payloadState = HardwareAcknowledgementState.failed;
                          });
                        });
                      }
                      if (payloadState != HardwareAcknowledgementState.sending) {
                        break;
                      }
                    }
                  },
                ),
            ],
          );
        });
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  UNCHANGED LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  void sendToMqtt(){
    String? validationError = configPvd.validateGemConfiguration();
    if (validationError != null) return;
    configPvd.updateObjectDetails();
    setState(() {
      listOfPayload.clear();
      listOfPayload.addAll(configPvd.getOroPumpPayload());
      listOfPayload.addAll(configPvd.getPumpWithValvePayload());
      listOfPayload.addAll(configPvd.getWeatherMasterPayload());
    });

    if([...AppConstants.gemModelList, ...AppConstants.ecoGemModelList, ...AppConstants.omsGemList, ...AppConstants.aquacultureModelList].contains(configPvd.masterData['modelId'])){
      bool gem = AppConstants.gemModelList.contains(configPvd.masterData['modelId']);
      bool omsGem = AppConstants.omsGemList.contains(configPvd.masterData['modelId']);
      final Map<String, dynamic> configMakerPayload = {
        '100' : {
          '101' : configPvd.getDeviceListPayload(),
          '102' : configPvd.getObjectPayload(),
          if(gem && !omsGem)
            '103' : configPvd.getPumpPayload(),
          if(gem && !omsGem)
            '104' : configPvd.getFilterPayload(),
          if(gem && !omsGem)
            '105' : configPvd.getFertilizerPayload(),
          if(gem && !omsGem)
            '106' : configPvd.getFertilizerInjectorPayload(),
          if(gem && !omsGem)
            '107' : configPvd.getIrrigationLinePayload(),
          if(gem && !omsGem && configPvd.valveConfig.any((valve) => !valve.valveModelParameterIsEmpty()))
            '108' : configPvd.getValveConfigPayload(),
          if(gem && !omsGem && configPvd.moisture.any((moisture) => !moisture.isMoistureModelParameterIsEmpty()))
            '109' : configPvd.getMoisturePayload(),
          if(gem && !omsGem && configPvd.listOfGeneratedObject.any((obj) => obj.objectId == AppConstants.tankValveObjectId))
            '110' : configPvd.getTankValvePayload(),

        }
      };
      setState(() {
        var payloadTitle = AppConstants.ecoGemModelList.contains(configPvd.masterData['modelId']) ? 'Eco Gem Config' : 'Gem Config';
        listOfPayload.insert(0,{
          'title' : '${configPvd.masterData['deviceId']}($payloadTitle)',
          'deviceId' : configPvd.masterData['deviceId'],
          'deviceIdToSend' : configPvd.masterData['deviceId'],
          'payload' : jsonEncode(configMakerPayload),
          'acknowledgementState' : HardwareAcknowledgementState.notSent,
          'selected' : true,
          'checkingCode' : '100',
          'hardwareType' : HardwareType.gem
        });
      });
    }
    debugPrint("listOfPayload ==> $listOfPayload");
    payloadAlertBox();
  }

  void payloadAlertBox() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, stateSetter) {
            final isSending = payloadSendState == PayloadSendState.start;
            final isIdle = payloadSendState == PayloadSendState.idle;
            final isStopped = payloadSendState == PayloadSendState.stop;
            final canSelect = isIdle || isStopped;
            final allSelected = listOfPayload.isNotEmpty &&
                listOfPayload.every((p) => p['selected'] == true);

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.fact_check_rounded,
                        color: Theme.of(context).primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Configuration Payload',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xff1E293B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${listOfPayload.length} ${listOfPayload.length == 1 ? 'payload' : 'payloads'} to transmit',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff64748B),
                              fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  if (canSelect && listOfPayload.length > 1)
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        stateSetter(() {
                          setState(() {
                            final target = !allSelected;
                            for (var p in listOfPayload) {
                              p['selected'] = target;
                            }
                          });
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          allSelected ? 'Deselect all' : 'Select all',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width >= 520
                    ? 480
                    : double.infinity,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var payload in listOfPayload) ...[
                          _buildCompactPayloadCard(
                            context: context,
                            payload: payload,
                            canSelect: canSelect,
                            onChanged: (value) {
                              stateSetter(() {
                                setState(() {
                                  payload['selected'] = value;
                                });
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (isIdle || isSending)
                  CustomMaterialButton(
                    outlined: true,
                    title: isSending ? 'Stop' : 'Cancel',
                    onPressed: () {
                      stateSetter(() {
                        setState(() {
                          payloadSendState = PayloadSendState.stop;
                        });
                        Navigator.pop(context);
                      });
                    },
                  ),
                if (isIdle)
                  CustomMaterialButton(
                    title: 'Send',
                    icon: Icons.send_rounded,
                    color: const Color(0xff16A34A),
                    onPressed: () async {
                      payloadLoop:
                      for (var payload in listOfPayload) {
                        print("payload : ${payload}");
                        if (!payload['selected']) {
                          continue payloadLoop;
                        }
                        bool mqttAttempt = true;
                        int delayDuration = 60;
                        delayLoop:
                        for (var sec = 0; sec < delayDuration; sec++) {
                          if (sec == 0) {
                            payloadSendState = PayloadSendState.start;
                            payload['acknowledgementState'] =
                                HardwareAcknowledgementState.sending;
                          }
                          if (sec == delayDuration - 1) {
                            payload['acknowledgementState'] =
                                HardwareAcknowledgementState.failed;
                          }
                          debugPrint(
                              "${payload['hardwareType']}\n sec ${sec + 1}   -- ${payload['deviceId']} \n ${mqttService.acknowledgementPayload}");
                          if (mqttAttempt == true) {
                            context.read<CommunicationService>().sendCommand(
                                  serverMsg: '',
                                  payload: AppConstants.wlcModelList
                                          .contains(configPvd.masterData['modelId'])
                                      ? Constants.sendPayloadWithCrc(
                                          payload['payload'])
                                      : payload['payload'],
                                );
                            mqttAttempt = false;
                          }
                          stateSetter(() {
                            setState(() {
                              if (payload['hardwareType'] as HardwareType ==
                                  HardwareType.gem) {
                                // listening acknowledgement from gem
                                if (mqttService.acknowledgementPayload != null) {
                                  print(
                                      "mqttService.acknowledgementPayload! : ${sec + 1}");
                                  if (validatePayloadFromHardware(
                                          mqttService.acknowledgementPayload!,
                                          ['cC'],
                                          payload['deviceIdToSend']) &&
                                      validatePayloadFromHardware(
                                          mqttService.acknowledgementPayload!,
                                          ['cM', '4201', 'PayloadCode'],
                                          payload['checkingCode'])) {
                                    if (mqttService.acknowledgementPayload!['cM']
                                            ['4201']['Code'] ==
                                        '200') {
                                      payload['acknowledgementState'] =
                                          HardwareAcknowledgementState.success;
                                    } else if (mqttService
                                                .acknowledgementPayload!['cM']
                                            ['4201']['Code'] ==
                                        '90') {
                                      payload['acknowledgementState'] =
                                          HardwareAcknowledgementState
                                              .programRunning;
                                    } else if (mqttService
                                                .acknowledgementPayload!['cM']
                                            ['4201']['Code'] ==
                                        '1') {
                                      payload['acknowledgementState'] =
                                          HardwareAcknowledgementState
                                              .hardwareUnknownError;
                                      debugPrint(
                                          'successfully!! update status for ${payload['title']}  and its code : ${mqttService.acknowledgementPayload!['cM']['4201']['Code']} -- ${payload['acknowledgementState']}');
                                    } else {
                                      payload['acknowledgementState'] =
                                          HardwareAcknowledgementState
                                              .errorOnPayload;
                                    }
                                    mqttService.acknowledgementPayload = null;
                                  }
                                }
                              } else if ([
                                HardwareType.pump,
                                HardwareType.pumpWithValve,
                                HardwareType.weather
                              ].contains(
                                  payload['hardwareType'] as HardwareType)) {
                                if (mqttService.acknowledgementPayload != null) {
                                  if (validatePayloadFromHardware(
                                          mqttService.acknowledgementPayload!,
                                          ['cC'],
                                          payload['deviceId']) &&
                                      validatePayloadFromHardware(
                                          mqttService.acknowledgementPayload!,
                                          ['cM'],
                                          payload['checkingCode'])) {
                                    payload['acknowledgementState'] =
                                        HardwareAcknowledgementState.success;
                                    mqttService.acknowledgementPayload = null;
                                  }
                                }
                              }
                            });
                          });
                          if ((payload['acknowledgementState']
                                  as HardwareAcknowledgementState) !=
                              HardwareAcknowledgementState.sending) {
                            break delayLoop;
                          }
                          await Future.delayed(
                              const Duration(milliseconds: 500));
                        }
                      }
                      if (payloadSendState == PayloadSendState.start) {
                        stateSetter(() {
                          setState(() {
                            payloadSendState = PayloadSendState.stop;
                            mqttService.acknowledgementPayload = null;
                          });
                        });
                      }
                    },
                  ),
                if (isStopped)
                  CustomMaterialButton(
                    title: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCompactPayloadCard({
    required BuildContext context,
    required Map<String, dynamic> payload,
    required bool canSelect,
    required ValueChanged<bool?> onChanged,
  }) {
    final selected = payload['selected'] == true;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: canSelect ? () => onChanged(!selected) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withOpacity(0.04)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? primaryColor.withOpacity(0.35)
                : Colors.grey.shade200,
            width: selected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: selected,
                onChanged: canSelect ? onChanged : null,
                activeColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${payload['title']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xff1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.developer_board_rounded,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Device: ${payload['deviceId']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            payloadAcknowledgementWidget(
                payload['acknowledgementState'] as HardwareAcknowledgementState),
          ],
        ),
      ),
    );
  }

  Widget payloadAcknowledgementWidget(HardwareAcknowledgementState state) {
    Color bg;
    Color fg;
    Color borderColor;
    IconData? icon;
    String label;
    bool showSpinner = false;

    switch (state) {
      case HardwareAcknowledgementState.notSent:
        bg = const Color(0xffF1F5F9);
        fg = const Color(0xff64748B);
        borderColor = const Color(0xffE2E8F0);
        icon = Icons.schedule_rounded;
        label = 'Not sent';
        break;
      case HardwareAcknowledgementState.success:
        bg = const Color(0xffDCFCE7);
        fg = const Color(0xff15803D);
        borderColor = const Color(0xffBBF7D0);
        icon = Icons.check_circle_rounded;
        label = 'Success';
        break;
      case HardwareAcknowledgementState.failed:
        bg = const Color(0xffFEE2E2);
        fg = const Color(0xffB91C1C);
        borderColor = const Color(0xffFCA5A5);
        icon = Icons.cancel_rounded;
        label = 'Failed';
        break;
      case HardwareAcknowledgementState.programRunning:
        bg = const Color(0xffFFEDD5);
        fg = const Color(0xffC2410C);
        borderColor = const Color(0xffFED7AA);
        icon = Icons.running_with_errors_rounded;
        label = 'Program Running';
        break;
      case HardwareAcknowledgementState.errorOnPayload:
        bg = const Color(0xffFEE2E2);
        fg = const Color(0xffB91C1C);
        borderColor = const Color(0xffFCA5A5);
        icon = Icons.error_outline_rounded;
        label = 'Payload Error';
        break;
      case HardwareAcknowledgementState.hardwareUnknownError:
        bg = const Color(0xffFEE2E2);
        fg = const Color(0xffB91C1C);
        borderColor = const Color(0xffFCA5A5);
        icon = Icons.warning_amber_rounded;
        label = 'Unknown Error';
        break;
      case HardwareAcknowledgementState.sending:
        bg = const Color(0xffEFF6FF);
        fg = const Color(0xff1D4ED8);
        borderColor = const Color(0xffBFDBFE);
        label = 'Sending...';
        showSpinner = true;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fg,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  void sendToHttp()async{
    String? validationError = configPvd.validateGemConfiguration();
    if (validationError != null) return;
    var listOfSampleObjectModel = configPvd.listOfSampleObjectModel.map((object){
      return object.toJson();
    }).toList();
    var listOfObjectModelConnection = configPvd.listOfObjectModelConnection.map((object){
      return object.toJson();
    }).toList();
    var listOfGeneratedObject = configPvd.listOfGeneratedObject.map((object){
      return object.toJson(data: configPvd.configMakerDataFromHttp);
    }).toList();
    var filtration = configPvd.filtration.cast<FiltrationModel>().map((object){
      return object.toJson();
    }).toList();
    var fertilization = configPvd.fertilization.cast<FertilizationModel>().map((object){
      return object.toJson();
    }).toList();
    var source = configPvd.source.cast<SourceModel>().map((object){
      return object.toJson();
    }).toList();
    var pump = configPvd.pump.cast<PumpModel>().map((object){
      return object.toJson();
    }).toList();
    var moisture = configPvd.moisture.cast<MoistureModel>().map((object){
      return object.toJson();
    }).toList();
    var pressure = configPvd.pressureSensor.cast<PressureModel>().map((object){
      return object.toJson();
    }).toList();
    var valve = configPvd.valveConfig.cast<ValveConfigModel>().map((object){
      return object.toJson();
    }).toList();
    var channel = configPvd.channelConfig.cast<ChannelConfigModel>().map((object){
      return object.toJson();
    }).toList();
    var line = configPvd.line.cast<IrrigationLineModel>().map((object){
      return object.toJson();
    }).toList();
    var ecSensor = configPvd.ec.cast<EcModel>().map((object){
      return object.toJson();
    }).toList();
    var phSensor = configPvd.ph.cast<PhModel>().map((object){
      return object.toJson();
    }).toList();
    var body = {
      "userId" : configPvd.masterData['customerId'],
      "controllerId" : configPvd.masterData['controllerId'],
      'groupId' : configPvd.masterData['groupId'],
      "isNewConfig" : isNewConfig ? '1' : '0',
      "productLimit" : listOfSampleObjectModel,
      "connectionCount" : listOfObjectModelConnection,
      "configObject" : listOfGeneratedObject,
      "waterSource" : source,
      "pump" : pump,
      "filterSite" : filtration,
      "fertilizerSite" : fertilization,
      "moistureSensor" : moisture,
      "pressureSensor" : pressure,
      "valve" : valve,
      "fertilizerChannel" : channel,
      "irrigationLine" : line,
      "ecSensor" : ecSensor,
      "phSensor" : phSensor,
      "deviceList" : configPvd.listOfDeviceModel
          .where((device) => device.controllerId != configPvd.masterData['controllerId'])
          .map((device) {
        return {
          'productId' : device.productId,
          'controllerId' : device.controllerId,
          'masterId' : device.masterId,
          'referenceNumber' : configPvd.findOutReferenceNumber(device),
          'serialNumber' : device.serialNumber,
          'interfaceTypeId' : device.interfaceTypeId,
          'interfaceInterval' : device.masterId == null ? null : device.interfaceInterval,
          'extendControllerId' : device.extendControllerId,
        };
      }).toList(),
      "hardware" : listOfPayload.map((payload) {
        return {
          'title' : payload['title'],
          'payload' : payload['payload']
        };
      }).toList(),
      "controllerReadStatus" : '0',
      "serialNumber" : configPvd.serialNumber,
      "createUser" : configPvd.masterData['userId']
    };
    body['configObject'] = configPvd.listOfGeneratedObject.map((object){
      return object.toJson(data: body);
    }).toList();
    try{
      var response = await ConfigMakerRepository().createUserConfigMaker(body);
      debugPrint('response : ${response.body}');
    }catch(e){
      debugPrint('createUserConfigMaker error : $e');
    }
  }

  bool validateTab(ConfigMakerTabs tab){
    bool display = false;
    if(AppConstants.pumpWithValveModelList.contains(configPvd.masterData['modelId']) || AppConstants.weatherGsmModelList.contains(configPvd.masterData['modelId'])){
      if([ConfigMakerTabs.deviceList.name, ConfigMakerTabs.productLimit.name].contains(tab.name)){
        display = true;
      }
    }
    // else if(AppConstants.omsGemList.contains(configPvd.masterData['modelId'])){
    //   if([ConfigMakerTabs.deviceList.name, ConfigMakerTabs.productLimit.name, ConfigMakerTabs.connection.name].contains(tab.name)){
    //     display = true;
    //   }
    // }
    else{
      display = true;
    }
    return display;
  }

  String getTabImage(ConfigMakerTabs configMakerTabs) {
    switch (configMakerTabs) {
      case ConfigMakerTabs.deviceList:
        return 'device_list';
      case ConfigMakerTabs.productLimit:
        return 'product_limit';
      case ConfigMakerTabs.connection:
        return 'connection';
      case ConfigMakerTabs.siteConfigure:
        return 'site_configure';
      case ConfigMakerTabs.siteDiagram:
        return 'site_diagram';
      default:
        throw ArgumentError('Invalid ConfigMakerTabs value: $configMakerTabs');
    }
  }

}

bool validatePayloadFromHardware(Map<String, dynamic>? payload, List<String> keys, String checkingValue){
  print("keys : $keys   checkingValue : $checkingValue");
  bool condition = false;
  dynamic checkingNestedData = payload;
  if(payload!.containsKey('cC')){
    for(var key in keys){
      if(checkingNestedData != null && checkingNestedData.containsKey(key)){
        checkingNestedData = checkingNestedData[key];
      }else{
        condition = false;
        break;
      }
    }
  }
  if(checkingNestedData is String){
    if(checkingNestedData.contains(checkingValue)){
      condition = true;
    }else if(checkingNestedData == checkingValue){
      condition = true;
    }
  }

  if(kDebugMode){
    print("checkingNestedData : $checkingNestedData \n checkingValue : $checkingValue \n condition : $condition");
  }
  return condition;
}

enum HardwareAcknowledgementState{notSent, sending, failed, success, errorOnPayload, hardwareUnknownError, programRunning}
enum PayloadSendState{idle, start, stop}
enum HardwareType{gem, pump, economic, pumpWithValve, weather}