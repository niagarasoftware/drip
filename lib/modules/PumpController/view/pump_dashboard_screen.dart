import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:oro_drip_irrigation/Constants/constants.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';
import 'package:oro_drip_irrigation/modules/PumpController/view/pump_with_valves.dart';
import 'package:oro_drip_irrigation/repository/repository.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:oro_drip_irrigation/utils/environment.dart';
import 'package:oro_drip_irrigation/utils/snack_bar.dart';
import 'package:provider/provider.dart';

import '../../../models/customer/site_model.dart';
import '../../../Screens/dashboard/wave_view.dart';
import '../../../Widgets/sized_image.dart';
import '../../../flavors.dart';
import '../../../services/communication_service.dart';
import '../../../services/http_service.dart';
import '../model/pump_controller_data_model.dart';
import '../widget/custom_bouncing_button.dart';
import '../widget/custom_connection_error.dart';
import '../widget/custom_countdown_timer.dart';
import '../widget/custom_gauge.dart';
import '../widget/mode_card.dart';

class PumpDashboardScreen extends StatefulWidget {
  final int userId, customerId;
  final MasterControllerModel masterData;
  const PumpDashboardScreen({
    super.key,
    required this.userId,
    required this.customerId,
    required this.masterData
  });

  @override
  State<PumpDashboardScreen> createState() => _PumpDashboardScreenState();
}

class _PumpDashboardScreenState extends State<PumpDashboardScreen> with TickerProviderStateMixin{
  late AnimationController _controller;
  late AnimationController _controller2;
  String _formattedTime = "00:00:00";
  int requestedLive = 0;
  bool hasRequestedLive = false;
  final MqttService mqttService = MqttService();
  final Repository repository = Repository(HttpService());
  late Animation<double> _animation2;

  /// Used to print the phase/reason debug block only when the payload changes
  /// (build() runs very often, so printing every build would flood the console).
  String _lastDebugSignature = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _controller.addListener(() {setState(() {});});
    _controller.repeat();
    // mqttService.pumpDashboardPayload = widget.masterData.live?.cM as PumpControllerData?;
    mqttService.pumpDashboardPayload =
    widget.masterData.live?.cM != null
        ? widget.masterData.live?.cM as PumpControllerData?
        : null;
    _animation2 = Tween<double>(begin: 1.0, end: 0.0).animate(_controller2);
    if(mounted){
      getLive();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    _controller2.dispose();
    super.dispose();
  }

  Future<void> liveRequest() async{
    final result = await context.read<CommunicationService>().sendCommand(
      payload: AppConstants.wlcModelList.contains(widget.masterData.modelId) ?  '*${jsonEncode({"sentSms": "#live"})}#' : jsonEncode({"sentSms": "#live"}),
      serverMsg: '',
    );
  }

  Future<void> getLive() async{
    liveRequest();
    if(mounted){
      setState(() {
        mqttService.pumpDashboardPayload!.dataFetchingStatus = 2;
      });
      Future.delayed(const Duration(seconds: 10), () {
        if(mqttService.pumpDashboardPayload!.dataFetchingStatus != 1) {
          if(mounted){
            setState(() {
              mqttService.pumpDashboardPayload!.dataFetchingStatus = 3;
            });
          }
        }
      });
    }
  }

  void handleLiveRequest() async {
    if (mqttService.pumpDashboardPayload!.dataFetchingStatus == 1) {
      if (requestedLive != 1 && mqttService.pumpDashboardPayload!.pumps.any((e) => e.status == 1)) {
        await Future.delayed(const Duration(seconds: 1));
        liveRequest();
        setState(() {
          requestedLive = 1;
        });
      } else if (requestedLive != 2 && mqttService.pumpDashboardPayload!.pumps.every((e) => e.status == 0)) {
        await Future.delayed(const Duration(seconds: 1));
        liveRequest();
        setState(() {
          requestedLive = 2;
        });
      }
    }
  }

  String getCommunicationType(String version) {
    return version.startsWith('1')
        ? version.replaceFirst('1', 'L')
        : version.startsWith('2')
        ? version.replaceFirst('2', 'G')
        : version.startsWith('3')
        ? version.replaceFirst('3', 'W')
        : version;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Safe double parse: returns 0 for "-", "" or garbage instead of throwing.
  double _toD(dynamic value) => double.tryParse(value.toString().trim()) ?? 0;

  /// Shows whole numbers without decimals, otherwise 2 decimals (e.g. power factor 0.95).
  String _fmt(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  /// Returns the "n-th" comma separated item of a list as double (0 if missing).
  double _at(List<String> list, int i) => i < list.length ? _toD(list[i]) : 0;

  /// Current value at index [i] (use -1 for "last"), with the 2 character prefix
  /// stripped exactly like before, but without throwing a RangeError.
  String _currentAt(PumpControllerData data, int i) {
    final parts = data.current.toString().split(',');
    if (parts.isEmpty) return '- A';
    final idx = i < 0 ? parts.length - 1 : i;
    if (idx >= parts.length) return '- A';
    final raw = parts[idx].trim();
    return '${raw.length > 2 ? raw.substring(2) : raw} A';
  }

  /// True when the pump "reason" text describes an ON event (whole word match,
  /// so words like "controller" / "condition" no longer count as "on").
  bool _reasonIsOn(dynamic pumpItem) {
    if (pumpItem.reasonCode == 0) return pumpItem.status == 1;
    final reason = pumpItem.reason.toString();
    final hasOn = RegExp(r'\bon\b', caseSensitive: false).hasMatch(reason);
    final hasOff = RegExp(r'\boff\b', caseSensitive: false).hasMatch(reason);
    return hasOn && !hasOff;
  }

  // ---------------------------------------------------------------------------
  // DEBUG
  // ---------------------------------------------------------------------------

  /// Prints raw + parsed R/Y/B voltage, current, power, power factor and every
  /// pump's reason. Only prints when something in the payload changed.
  void _debugPhaseData(PumpControllerData data) {
    if (!kDebugMode) return;

    final signature = [
      data.voltage,
      data.current,
      data.power,
      data.powerFactor,
      data.dataFetchingStatus,
      data.pumps.map((p) => '${p.reasonCode}:${p.status}:${p.reason}').join(';'),
    ].join('|');
    if (signature == _lastDebugSignature) return;
    _lastDebugSignature = signature;

    final voltage = data.voltage.toString().split(',');
    final current = data.current.toString().split(',');
    const labels = ['R', 'Y', 'B'];
    final lineToLine = _at(voltage, 0) > 300 && _at(voltage, 1) > 300 && _at(voltage, 2) > 300;

    final b = StringBuffer();
    b.writeln('══════════ PUMP DASHBOARD PHASE DEBUG ══════════');
    b.writeln('model=${widget.masterData.modelId} | flavor=${F.name} | numberOfPumps=${data.numberOfPumps} | dataFetchingStatus=${data.dataFetchingStatus}');
    b.writeln('RAW voltage="${data.voltage}"');
    b.writeln('RAW current="${data.current}"');
    b.writeln('RAW power="${data.power}"');
    b.writeln('RAW powerFactor="${data.powerFactor}"');
    b.writeln('RAW energyParameters="${data.energyParameters}"');
    b.writeln('voltage mode => ${lineToLine ? "LINE-TO-LINE (all > 300)" : "PHASE-TO-NEUTRAL"}');
    for (var i = 0; i < 3; i++) {
      final vRaw = i < voltage.length ? voltage[i] : '<missing>';
      final cRaw = i < current.length ? current[i] : '<missing>';
      b.writeln('${labels[i]} | voltage raw="$vRaw" parsed=${_at(voltage, i)} | current raw="$cRaw" shown="${_currentAt(data, i)}"');
    }
    if (voltage.length != 3) b.writeln('⚠ voltage has ${voltage.length} items (expected 3)');
    if (current.length != 3) b.writeln('⚠ current has ${current.length} items (expected 3)');
    for (var i = 0; i < data.pumps.length; i++) {
      final p = data.pumps[i];
      b.writeln('PUMP[$i] status=${p.status} reasonCode=${p.reasonCode} reason="${p.reason}" '
          '=> reason ${[30, 31, 100].contains(p.reasonCode) ? "HIDDEN (code in 30/31/100)" : "VISIBLE"}');
    }
    if (data.dataFetchingStatus != 1) {
      b.writeln('⚠ dataFetchingStatus != 1 -> reasonCode is forced to 100 in buildNewPumpDetails, so the reason is hidden until live data arrives');
    }
    b.writeln('════════════════════════════════════════════════');
    debugPrint(b.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (!hasRequestedLive) {
      hasRequestedLive = true;
      Future.microtask(() => handleLiveRequest());
    }
    final ThemeData themeData = Theme.of(context);
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)
      ),
      child: RefreshIndicator(
        onRefresh: getLive,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: StreamBuilder<PumpControllerData?>(
            stream: mqttService.pumpDashboardPayloadStream,
            builder: (BuildContext context, AsyncSnapshot<PumpControllerData?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('Data not available'));
              }
              _debugPhaseData(snapshot.data!);
              return ListView(
                children: [
                  const SizedBox(height: 10,),
                  if(([30, 31].contains(snapshot.data!.pumps[0].reasonCode)))
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                          color: snapshot.data!.pumps[0].reasonCode == 30 ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(5)
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5,),
                      child: FadeTransition(
                        opacity: snapshot.data!.pumps[0].reasonCode == 30
                            ? _animation2
                            : const AlwaysStoppedAnimation(1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.electric_bolt, color: Colors.white,),
                            Text(snapshot.data!.pumps[0].reasonCode == 30 ? "Power off" : "Power on", style: const TextStyle(color: Colors.white),)
                          ],
                        ),
                      ),
                    )
                  else
                    ConnectionErrorToast(dataFetchingStatus: snapshot.data!.dataFetchingStatus),
                  Container(
                    width: MediaQuery.of(context).size.width <= 500 ? MediaQuery.of(context).size.width : 400,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      // boxShadow: AppProperties.customBoxShadowLiteTheme
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedImageMedium(imagePath: 'assets/Images/Png/${F.name.contains('oro') ? 'Oro' : F.name.contains('agritel') ? 'Agritel' : 'SmartComm'}/category_${2}.png'),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                spacing: 5,
                                children: [
                                  Text(widget.masterData.deviceName, style: themeData.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),),
                                  Badge(
                                    alignment: const Alignment(-3.1, -1),
                                    smallSize: 0.1,
                                    backgroundColor: Colors.transparent,
                                    label: Text("${snapshot.data?.signalStrength ?? "0"}%", style: const TextStyle(fontSize: 8, color: Colors.red, fontWeight: FontWeight.bold),),
                                    child: getIcon(snapshot.data!.signalStrength),
                                  ),
                                  // SelectableText(widget.deviceId, style: themeData.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.normal, fontSize: 12),),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                spacing: 5,
                                children: [
                                  SelectableText(widget.masterData.deviceId, style: themeData.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.normal, fontSize: 12),),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    spacing: 5,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: const Color(0xffFFFACD),
                                            border: Border.all(color: const Color(0xffEB7C17)),
                                            borderRadius: BorderRadius.circular(10)
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        child: Text('CVS : ${(snapshot.data!.version.toString().split(',').length > 1
                                            ? snapshot.data!.version.toString().split(',')[0]
                                            : snapshot.data!.version)}', style: const TextStyle(fontSize: 8, color: Color(0xffEB7C17)),),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                            color: const Color(0xffFFFACD),
                                            border: Border.all(color: const Color(0xffEB7C17)),
                                            borderRadius: BorderRadius.circular(10)
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        child: Text('MVS : ${(snapshot.data!.version.toString().split(',').length > 1
                                            ? snapshot.data!.version.toString().split(',')[1]
                                            : snapshot.data!.version)}', style: const TextStyle(fontSize: 8, color: Color(0xffEB7C17)),),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  _buildPhaseWidget(snapshot),
                  const Divider(),
                  const SizedBox(height: 15,),
                  for(var index = 0; index < int.parse(snapshot.data!.numberOfPumps); index++)
                    buildNewPumpDetails(index: index, pumpData: snapshot.data!,),
                  if(widget.masterData.configObjects.any((e) => e.objectId == 19) && !AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId))
                    _buildLight(snapshot.data!.pumps.firstWhere((pump) => pump is PumpValveModel) as PumpValveModel, snapshot.data!),
                  if(AppConstants.pumpWithValveModelList.contains(widget.masterData.modelId))
                    PumpWithValves(
                      valveData: snapshot.data!.pumps.firstWhere((pump) => pump is PumpValveModel) as PumpValveModel,
                      dataFetchingStatus: snapshot.data!.dataFetchingStatus,
                      userId: widget.userId,
                      customerId: widget.customerId,
                      masterData: widget.masterData,
                    ),
                  const SizedBox(height: 20,),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseWidget(AsyncSnapshot<PumpControllerData?> snapshot) {
    final List<String> voltage = snapshot.data!.voltage.toString().split(',');
    final List<String> powerFactor = snapshot.data!.powerFactor != null ? snapshot.data!.powerFactor.toString().split(',') : [];
    final List<String> power = snapshot.data!.power != null ? snapshot.data!.power.toString().split(',') : [];

    final double vR = _at(voltage, 0);
    final double vY = _at(voltage, 1);
    final double vB = _at(voltage, 2);
    final bool allAbove300 = vR > 300 && vY > 300 && vB > 300;
    final bool anyAbove300 = vR > 300 || vY > 300 || vB > 300;

    dynamic title;
    dynamic value;
    dynamic value2;
    if(F.name.contains('oro') || F.name.contains('agritel')) {
      title = !allAbove300
          ? ["RN ${vR.toStringAsFixed(0)}",
        "YN ${vY.toStringAsFixed(0)}",
        "BN ${vB.toStringAsFixed(0)}"] : null;
      if(snapshot.data!.power != null) {
        value2 = ["RP ${_at(power, 0).toStringAsFixed(0)}",
          "YP ${_at(power, 1).toStringAsFixed(0)}",
          "BP ${_at(power, 2).toStringAsFixed(0)}"];
      } else {
        value2 = allAbove300
            ? ["RY ${vR.toStringAsFixed(0)}",
          "YB ${vY.toStringAsFixed(0)}",
          "BR ${vB.toStringAsFixed(0)}"]
            : ["RY ${calculatePhToPh(vR, vY)}",
          "YB ${calculatePhToPh(vY, vB)}",
          "BR ${calculatePhToPh(vB, vR)}"];
      }
      if(snapshot.data!.powerFactor != null) {
        value = ["RPF ${_fmt(_at(powerFactor, 0))}",
          "YPF ${_fmt(_at(powerFactor, 1))}",
          "BPF ${_fmt(_at(powerFactor, 2))}"];
      }
    } else {
      value2 = !anyAbove300
          ? ["RN ${vR.toStringAsFixed(0)}",
        "YN ${vY.toStringAsFixed(0)}",
        "BN ${vB.toStringAsFixed(0)}"]
          : ["RY ${vR.toStringAsFixed(0)}",
        "YB ${vY.toStringAsFixed(0)}",
        "BR ${vB.toStringAsFixed(0)}"];
    }

    return Container(
      color: Colors.white,
      width: MediaQuery.of(context).size.width <= 500 ? MediaQuery.of(context).size.width : 400,
      padding: const EdgeInsets.only(bottom: 10),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          if(!AppConstants.pumpWithValveModelList.contains(widget.masterData.modelId) || (snapshot.data!.pumps.firstWhere((pump) => pump is PumpValveModel) as PumpValveModel).phaseType != "1")
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (AppConstants.singlePhaseWlcModelList.contains(widget.masterData.modelId))
                  buildContainer(
                    title: title != null ? title[0] : null,
                    value: value != null ? value[0] : null,
                    value2: value2 != null ? value2[0] : null,
                    color1: Colors.redAccent.shade100,
                    color2: Colors.redAccent.shade700,
                  )
                else
                  for(var index = 0; index < 3; index++)
                    buildContainer(
                      title: title != null ? title[index] : null,
                      value: value != null ? value[index] : null,
                      value2: value2 != null ? value2[index] : null,
                      // value: snapshot.data!.voltage.split(',')[index],
                      color1: [
                        Colors.redAccent.shade100,
                        Colors.amberAccent.shade100,
                        Colors.lightBlueAccent.shade100,
                      ][index],
                      color2: [
                        Colors.redAccent.shade700,
                        Colors.amberAccent.shade700,
                        Colors.lightBlueAccent.shade700,
                      ][index],
                    )
              ],
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: _boxDecoration(Theme.of(context).primaryColor, Theme.of(context).primaryColorDark),
              // padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("VOLTAGE : ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
                  // FIX: int.parse crashed on decimal values like "230.5"
                  Text(_fmt(vR + vB), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          if(snapshot.data!.energyParameters != null && snapshot.data!.energyParameters.isNotEmpty)
            const SizedBox(height: 8,),
          if(snapshot.data!.energyParameters != null && snapshot.data!.energyParameters.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                      text: TextSpan(
                          children: [
                            TextSpan(text: "Instant Energy:", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
                            TextSpan(text: " ${snapshot.data!.energyParameters.split(',')[0]}", style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                          ]
                      )
                  ),
                  RichText(
                      text: TextSpan(
                          children: [
                            TextSpan(text: "Cumulative Energy:", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
                            TextSpan(text: " ${snapshot.data!.energyParameters.split(',')[1]}", style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                          ]
                      )
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  Icon getIcon(int value) {
    Color iconColor;
    IconData iconData;

    if (value >= 10 && value <= 30) {
      iconData = MdiIcons.signalCellular1;
      iconColor = Colors.orange;
    } else if (value > 30 && value <= 70) {
      iconData = MdiIcons.signalCellular2;
      iconColor = Colors.orange;
    } else if (value > 70 && value <= 100) {
      iconData = MdiIcons.signalCellular3;
      iconColor = Colors.orange;
    } else {
      iconData = MdiIcons.signalOff;
      iconColor = Colors.orange;
    }

    return Icon(iconData, color: iconColor);
  }

  String calculatePhToPh(double val1, double val2) {
    double tpc, tp2c;
    tpc = val1 * val1;
    tp2c = val2 * val2;

    tpc = (tpc + tp2c);
    tp2c = val1 * val2;

    tpc = tpc + tp2c;

    tp2c = sqrt(tpc);

    return tp2c.toStringAsFixed(0);
  }

  Widget buildNewPumpDetails({required int index, required PumpControllerData pumpData}) {
    final pumps = widget.masterData.configObjects.where((e) => e.objectId == 5).toList();
    final pumpItem = pumpData.pumps[index];
    if(![0, 30, 31].contains(pumpItem.reasonCode) && pumpItem.reason.contains('off') && !pumpItem.reason.contains('auto mobile key')) {
      pumpItem.status = 3;
    }
    if(pumpData.dataFetchingStatus !=1) {
      pumpItem.reasonCode = 100;
      pumpItem.status = 0;
    }
    final actualReasonCode = pumpData.pumps[index].reasonCode;

    _formattedTime = pumpItem.onDelayTimer;
    final voltageTripCondition = [3, 4, 5].contains(pumpItem.reasonCode);
    final currentTripCondition = [8, 9, 10].contains(pumpItem.reasonCode);
    final pressureTripCondition = [41, 42].contains(pumpItem.reasonCode);
    final phase = pumpItem.phase;
    final otherTripCondition = [13, 14, 1, 2].contains(pumpItem.reasonCode);
    final tripCondition = voltageTripCondition || currentTripCondition || otherTripCondition || pressureTripCondition;
    final remainingTimeCondition = mqttService.isConnected && (pumpItem.maximumRunTimeRemaining != "00:00:00"
        && pumpItem.maximumRunTimeRemaining != "")
        && !tripCondition
        && (pumpItem.status == 1);
    final cyclicOnDelayCondition = pumpData.dataFetchingStatus == 1 && (pumpItem.cyclicOnDelay != "00:00:00"
        && pumpItem.cyclicOnDelay != "") && pumpItem.status == 1 && !tripCondition;
    final cyclicOffDelayCondition = pumpData.dataFetchingStatus == 1 && (pumpItem.cyclicOffDelay != "00:00:00"
        && pumpItem.cyclicOffDelay != "")
        && [0, 3].contains(pumpItem.status)
        && [30, 11].contains(pumpItem.reasonCode);

    const excludedReasons = [0, 30, 31, 32, 40, 100];
    final allowedResetModelIds = [48, 49, 52, 53, 54, 55];
    final showResetButton = !excludedReasons.contains(pumpItem.reasonCode) &&
        allowedResetModelIds.contains(widget.masterData.modelId);

    // Reason text shown next to the pump name
    final bool reasonIsOn = _reasonIsOn(pumpItem);
    final Color reasonColor = reasonIsOn ? Colors.green.shade700 : Colors.red.shade700;
    final Color reasonBgColor = reasonIsOn ? Colors.green.shade50 : Colors.red.shade50;
    final String reasonText = pumpItem.reasonCode == 0
        ? (pumpItem.status == 1 ? "Turned on through the mobile" : "Turned off through the mobile")
        : pumpItem.reason.toString();
    final bool showReason = ![30, 31, 100].contains(pumpItem.reasonCode) && reasonText.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width <= 500 ? MediaQuery.of(context).size.width : 400,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                height: 25,
                width: 140,
                decoration: BoxDecoration(
                  // gradient: AppProperties.linearGradientLeading,
                    color: Theme.of(context).primaryColorLight,
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(3))
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pumps[index].name,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10),
                      ),
                    ),
                    if(showResetButton)
                      const VerticalDivider(color: Colors.white54, indent: 5, endIndent: 5,),
                    if(showResetButton)
                      InkWell(
                        onTap: pumpData.dataFetchingStatus == 1 ? () async {
                          String payLoadFinal = jsonEncode({"sentSms":"RESET"});
                          var data = {
                            "userId": widget.customerId,
                            "controllerId": widget.masterData.controllerId,
                            "data": payLoadFinal,
                            "messageStatus": "${pumps[index].name} Reset Manually",
                            "createUser": widget.userId,
                            "hardware": payLoadFinal,
                          };
                          await mqttService.topicToPublishAndItsMessage(payLoadFinal, "${Environment.mqttPublishTopic}/${widget.masterData.deviceId}");

                          await repository.sendManualOperationToServer(data);
                          GlobalSnackBar.show(context, 'Reset command sent successfully', 200);
                          await Future.delayed(const Duration(seconds: 2));
                          liveRequest();
                        } : null,
                        borderRadius: BorderRadius.circular(4),
                        splashColor: Colors.white.withAlpha(80),
                        highlightColor: Colors.white.withAlpha(40),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            "RESET",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: pumpData.dataFetchingStatus == 1 ? Colors.white : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Reason text (was commented out, which is why it never showed)
              if(showReason)
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      reasonText.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: reasonColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).primaryColorLight,
              width: 0.5,
            ),
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10), bottomLeft: Radius.circular(10), topRight: Radius.circular(10)),
          ),
          elevation: 4,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shadowColor: Theme.of(context).primaryColorLight.withAlpha(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            width: MediaQuery.of(context).size.width <= 500 ? MediaQuery.of(context).size.width : 400,
            decoration: BoxDecoration(
              // boxShadow: neumorphicButtonShadow,
              // boxShadow: customBoxShadow,
                color: Colors.white,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                border: Border.all(color: Theme.of(context).primaryColor, width: 0.3)
            ),
            child: Column(
              children: [
                if(pumpItem.reasonCode != 30 && pumpItem.reasonCode != 31)
                  SizedBox(
                    width: double.maxFinite,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if(voltageTripCondition || currentTripCondition || pressureTripCondition)
                          Container(
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                              decoration: BoxDecoration(
                                  color: reasonBgColor,
                                  borderRadius: BorderRadius.circular(5)
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'SET ${!pressureTripCondition ? (voltageTripCondition
                                          ? phase == 1
                                          ? "RY"
                                          : phase == 2
                                          ? "YB"
                                          : "BR"
                                          : phase == 1
                                          ? "RC"
                                          : phase == 2
                                          ? "YC" : "BC"): ''} : ',
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                    TextSpan(
                                      text: '${pumpItem.set}',
                                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                          ),
                        if(voltageTripCondition || currentTripCondition || pressureTripCondition)
                          Container(
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                              decoration: BoxDecoration(
                                  color: reasonBgColor,
                                  borderRadius: BorderRadius.circular(5)
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'ACT ${!pressureTripCondition ? voltageTripCondition
                                          ? phase == 1
                                          ? "RY"
                                          : phase == 2
                                          ? "YB"
                                          : "BR"
                                          : phase == 1
                                          ? "RC"
                                          : phase == 2
                                          ? "YC" : "BC" : ''} : ',
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                    TextSpan(
                                      text: '${pumpItem.actual}',
                                      style: const TextStyle( color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // const SizedBox(width: 10,),
                    Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        Image.asset(
                          pumpData.pumps[index].status == 1
                              ? 'assets/gif/runningmotor.gif'
                              : pumpData.pumps[index].status == 3
                              ? 'assets/png/faultmotor.png'
                              : pumpData.pumps[index].status == 2
                              ? 'assets/png/readymotor.png'
                              : 'assets/png/idealmotor.png',
                        ),
                        /*getTypesOfPump(
                          mode: pumpData.pumps[index].status,
                          controller: _controller,
                          animationValue: _animation.value
                      ),*/
                        if(pumpItem.onDelayLeft != "00:00:00" && pumpData.dataFetchingStatus == 1 && pumpItem.reasonCode != 30)
                          Positioned(
                              top: 8,
                              left: 22,
                              child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(5)
                                  ),
                                  child: CountdownTimerWidget(
                                    initialSeconds: Constants.parseTime(_formattedTime).inSeconds,
                                    fontColor: Colors.white,
                                  )
                              )
                          )
                      ],
                    ),
                    Row(
                      children: [
                        _buildPumpControlButton(
                          label: "ON",
                          color: Colors.green,
                          command: "on",
                          delay: Constants.parseTime(pumpItem.onDelayTimer).inSeconds + 3,
                          pumpData: pumpData,
                          index: index,
                        ),
                        _buildPumpControlButton(
                          label: "OFF",
                          color: Colors.red,
                          command: "off",
                          delay: 10,
                          pumpData: pumpData,
                          index: index,
                        ),
                      ],
                    ),
                    if(!AppConstants.pumpWithValveModelList.contains(widget.masterData.modelId) || (pumpData.pumps.firstWhere((pump) => pump is PumpValveModel) as PumpValveModel).phaseType != "1")
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if(AppConstants.singlePhaseWlcModelList.contains(widget.masterData.modelId))
                            buildCurrentContainer(
                              title: 'BC : ',
                              value: _currentAt(pumpData, 0),
                              color1: Colors.lightBlueAccent.shade100,
                              color2: Colors.lightBlueAccent.shade700,
                            )
                          else ...[
                            if(int.parse(pumpData.numberOfPumps) == 1)
                              for(var i = 0; i < min(3, pumpData.current.toString().split(',').length); i++)
                                buildCurrentContainer(
                                  title: ['RC : ', 'YC : ', 'BC : '][i],
                                  value: _currentAt(pumpData, i),
                                  color1: [
                                    Colors.redAccent.shade100,
                                    Colors.amberAccent.shade100,
                                    Colors.lightBlueAccent.shade100,
                                  ][i],
                                  color2: [
                                    Colors.redAccent.shade700,
                                    Colors.amberAccent.shade700,
                                    Colors.lightBlueAccent.shade700,
                                  ][i],
                                ),
                            if(int.parse(pumpData.numberOfPumps) == 2 && index == 0)
                              for(var i = 0; i < int.parse(pumpData.numberOfPumps); i++)
                                buildCurrentContainer(
                                  title: ['RC : ', 'YC : '][i],
                                  value: _currentAt(pumpData, i),
                                  color1: [
                                    Colors.redAccent.shade100,
                                    Colors.amberAccent.shade100,
                                  ][i],
                                  color2: [
                                    Colors.redAccent.shade700,
                                    Colors.amberAccent.shade700,
                                  ][i],
                                ),
                            if(int.parse(pumpData.numberOfPumps) == 2 && index == 1)
                              buildCurrentContainer(
                                title: 'BC : ',
                                value: _currentAt(pumpData, -1),
                                color1: Colors.lightBlueAccent.shade100,
                                color2: Colors.lightBlueAccent.shade700,
                              ),
                            if(int.parse(pumpData.numberOfPumps) == 3 && index == 0)
                              buildCurrentContainer(
                                title: 'RC : ',
                                value: _currentAt(pumpData, 0),
                                color1: Colors.redAccent.shade100,
                                color2: Colors.redAccent.shade700,
                              ),
                            if(int.parse(pumpData.numberOfPumps) == 3 && index == 1)
                              buildCurrentContainer(
                                title: 'YC : ',
                                value: _currentAt(pumpData, 1),
                                color1: Colors.amberAccent.shade100,
                                color2: Colors.amberAccent.shade700,
                              ),
                            if(int.parse(pumpData.numberOfPumps) == 3 && index == 2)
                              buildCurrentContainer(
                                title: 'BC : ',
                                value: _currentAt(pumpData, -1),
                                color1: Colors.lightBlueAccent.shade100,
                                color2: Colors.lightBlueAccent.shade700,
                              ),
                          ],
                        ],
                      )
                    else
                      buildCurrentContainer(
                        title: 'CT : ',
                        value: _currentAt(pumpData, 2),
                        color1: Theme.of(context).primaryColorLight,
                        color2: Theme.of(context).primaryColor,
                      ),
                    // const SizedBox(width: 10,),
                  ],
                ),
                // const SizedBox(height: 10,),
                // const SizedBox(height: 10,),
                LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return Container(
                        width: constraints.maxWidth,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          // color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          runAlignment: WrapAlignment.center,
                          // spacing: 15,
                          // runSpacing: 10,
                          direction: Axis.horizontal,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if(pumpItem.reasonCode == 8 && pumpItem.dryRunRestartTimeRemaining != "" && pumpItem.dryRunRestartTimeRemaining != "00:00:00")
                                    Expanded(
                                      child: _buildCountdownColumn(
                                        title: " Dry run Restart \nRemaining",
                                        gradient: AppProperties.linearGradientLeading2,
                                        initialSeconds: Constants.parseTime(pumpItem.dryRunRestartTimeRemaining).inSeconds,
                                      ),
                                    ),
                                  if (remainingTimeCondition)
                                    Expanded(
                                      child: _buildCountdownColumn(
                                        title: " Max runtime \nRemaining",
                                        gradient: AppProperties.linearGradientLeading2,
                                        initialSeconds: Constants.parseTime(pumpItem.maximumRunTimeRemaining).inSeconds,
                                      ),
                                    ),
                                  if (remainingTimeCondition)
                                    const SizedBox(width: 15),
                                  if ((cyclicOffDelayCondition || cyclicOnDelayCondition) && pumpData.dataFetchingStatus == 1)
                                    Expanded(
                                      child: _buildCountdownColumn(
                                        title: cyclicOffDelayCondition ? "Cyclic off delay \nRemaining" : "Cyclic on delay \nRemaining",
                                        gradient: cyclicOffDelayCondition ? AppProperties.redLinearGradientLeading : AppProperties.greenLinearGradientLeading,
                                        initialSeconds: Constants.parseTime(cyclicOffDelayCondition ? pumpItem.cyclicOffDelay : pumpItem.cyclicOnDelay).inSeconds,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // if(remainingTimeCondition || cyclicOffDelayCondition || cyclicOnDelayCondition)
                            //   Divider(
                            //     indent: 10,
                            //     endIndent: 10,
                            //     color: Theme.of(context).primaryColor,
                            //     thickness: 0.3,
                            //   ),
                            if (pumpItem.level.toString().split(',')[0] != "-")
                              _buildPumpDetailColumn(
                                  title: "Level",
                                  content: WaveView(
                                    percentageValue: pumpItem.level.toString().split(',')[1] != '-'
                                    // ? 70
                                        ? double.parse(pumpItem.level.toString().split(',')[1])
                                        : 0,
                                    width: pumpItem.waterMeter == "-" && pumpItem.pressure == "-" ? constraints.maxWidth/2 - 50 : 50,
                                    borderRadius: pumpItem.waterMeter == "-" && pumpItem.pressure == "-" ? 15 : 80,
                                    // height: ,
                                  ),
                                  icon: Icons.propane_tank,
                                  footer1: "${(num.parse(pumpItem.level.toString().split(',')[0]) * 3.2808399).toStringAsFixed(2)} feet",
                                  footer2: '',
                                  condition: pumpItem.waterMeter == "-" && pumpItem.pressure == "-"
                              ),
                            if (pumpItem.waterMeter != "-")
                              _buildPumpDetailColumn(
                                  title: "Water meter",
                                  content: SizedBox(
                                    height: 100,
                                    width: constraints.maxWidth * 0.3,
                                    child: CustomGauge(
                                      currentValue: pumpItem.waterMeter != '-'
                                          ? double.parse(pumpItem.waterMeter)
                                          : 0,
                                      maxValue: 120.0,
                                    ),
                                  ),
                                  icon: Icons.speed,
                                  footer1: "${pumpItem.waterMeter} Lps",
                                  footer2: "total flow:${pumpItem.cumulativeFlow} L",
                                  condition: pumpItem.level.toString().split(',')[0] == "-" && (pumpItem.pressure == "-")
                              ),
                            if (pumpItem.pressure != "-")
                              _buildPumpDetailColumn(
                                  title: "Pressure",
                                  content: SizedBox(
                                    height: 100,
                                    width: constraints.maxWidth * 0.3,
                                    child: CustomGauge(
                                      currentValue: pumpItem.pressure != '-'
                                          ? double.parse(pumpItem.pressure)
                                          : 0,
                                      maxValue: 15,
                                    ),
                                  ),
                                  icon: MdiIcons.carBrakeLowPressure,
                                  footer1: "${pumpItem.pressure} bar",
                                  footer2: '',
                                  condition: pumpItem.waterMeter == "-" && pumpItem.level.toString().split(',')[0] == "-"
                              ),
                            if(pumpItem.float.split(':').every((element) => element != "-"))
                              Divider(
                                indent: 10,
                                endIndent: 10,
                                color: Theme.of(context).primaryColor,
                                thickness: 0.3,
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for(var i = 0; i < pumpItem.float.split(':').length; i++)
                                  if(pumpItem.float.split(':')[i] != "-")
                                    _buildColumn(
                                        title1: i == 0
                                            ? "Sump Bottom Float"//Changed as requested by Subash.D
                                            : i == 1
                                            ? "Sump Top Float"
                                            : i == 2
                                            ? "Tank Bottom Float"
                                            : i == 3
                                            ? "Tank Top Float"
                                            : "Unknown",
                                        value1: pumpItem.float.split(':')[i].toString() == "1" ? "High" : "Low",
                                        constraints: constraints,
                                        icon: MdiIcons.formatFloatCenter,
                                        color: const Color(0xffb6f6e5)
                                    ),

                              ],
                            )
                          ],
                        ),
                      );
                    }
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15,),
        AppConstants.wlcModelList.contains(widget.masterData.modelId)
            ? buildModeCard(
          context: context,
          modeStatus: pumpData.manualMode, // your live payload value
          isLoading: false,
          pumpName: pumps[index].name,
          onModeSelected: (PumpMode selectedMode) async {
            String payLoadFinal =
                '*${jsonEncode({"sentSms": "MANUAL${selectedMode.statusCode}"})}#';

            var data = {
              "userId": widget.customerId,
              "controllerId": widget.masterData.controllerId,
              "data": payLoadFinal,
              "messageStatus": "${pumps[index].name} Mode set to ${selectedMode.label}",
              "createUser": widget.userId,
              "hardware": payLoadFinal,
            };

            final result = await context.read<CommunicationService>().sendCommand(
              serverMsg: '',
              payload: payLoadFinal,
            );
            debugPrint("mode change result => $result");

            await repository.sendManualOperationToServer(data);

            GlobalSnackBar.show(
              context,
              '${selectedMode.label} set successfully',
              200,
            );
          },
        ) : Container(),

      ],
    );
  }



  Widget buildManualModeCard({
    required String manualModeStatus,
    required Function(bool) onToggle,
    required String pumpName,
    bool isLoading = false,
  }) {
    bool isOn = manualModeStatus == '0';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isOn ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.white,
          child: Column(
            children: [
              InkWell(
                onTap: isLoading ? null : () => onToggle(!isOn),
                splashColor: isOn ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side - Pump info with live indicator
                      Expanded(
                        child: Row(
                          children: [
                            // Animated status dot
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOn ? Colors.green : Colors.grey,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isOn ? Colors.green : Colors.grey).withOpacity(0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pumpName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        isOn ? Icons.flash_on : Icons.flash_off,
                                        size: 14,
                                        color: isOn ? Colors.green : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isOn ? "Manual Control Active" : "Auto Mode",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isOn ? Colors.green.shade700 : Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Right side - Modern toggle switch
                      Container(
                        width: 52,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: isOn ? Colors.green : Colors.grey.shade300,
                        ),
                        child: Stack(
                          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: isLoading
                                  ? const Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                ),
                              )
                                  : Icon(
                                isOn ? Icons.check : Icons.close,
                                size: 12,
                                color: isOn ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildLight(PumpValveModel pumpItem, PumpControllerData pumpData) {
    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width <= 500 ? MediaQuery.of(context).size.width : 400,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: 25,
                width: 80,
                decoration: BoxDecoration(
                  // gradient: AppProperties.linearGradientLeading,
                    color: Theme.of(context).primaryColorLight,
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(3))
                ),
                child: const Center(
                  child: Text(
                    "Light",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white,),
                  ),
                ),
              ),
              if(pumpData.dataFetchingStatus == 1)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(pumpItem.lightReason,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: (pumpItem.lightReason.contains('ON') ? Colors.green.shade700 : Colors.red.shade700),
                        fontWeight: FontWeight.bold,
                        // fontSize: titleFontSize
                      ),
                      textAlign: TextAlign.right,
                      // overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).primaryColorLight,
              width: 0.5,
            ),
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10), bottomLeft: Radius.circular(10), topRight: Radius.circular(10)),
          ),
          elevation: 4,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shadowColor: Theme.of(context).primaryColorLight.withAlpha(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            width: MediaQuery.of(context).size.width <= 500 ? MediaQuery.of(context).size.width : 400,
            decoration: BoxDecoration(
              // boxShadow: neumorphicButtonShadow,
              // boxShadow: customBoxShadow,
                color: Colors.white,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                border: Border.all(color: Theme.of(context).primaryColor, width: 0.3)
            ),
            child: Column(
              children: [
                const SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // const SizedBox(width: 10,),
                    Container(
                      padding: const EdgeInsets.all(8),
                      // decoration: BoxDecoration(
                      //   shape: BoxShape.circle,
                      //   color: pumpItem.light == "1" ? Colors.yellow.shade100 : Colors.grey.shade200,
                      //   border: Border.all(color: pumpItem.light == "1" ? Colors.yellow : Colors.grey),
                      //   boxShadow: [
                      //     BoxShadow(
                      //       color: pumpItem.light == "1" ? Colors.yellow.shade300.withOpacity(0.5) : pumpItem.light == "2" ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                      //       spreadRadius: pumpItem.light == "1" ? 10 : 5,
                      //       blurRadius: 10,
                      //       offset: const Offset(0, 3),
                      //     ),
                      //   ],
                      // ),
                      child: Image.asset(
                        pumpData.dataFetchingStatus == 1 ? pumpItem.light == "1" ? "assets/gif/light on.gif" : "assets/png/light off.png" : "assets/png/light off.png",
                        width: 80,
                        height: 90,
                      ),
                      /*child: Icon(
                        pumpItem.light == "1" ? Icons.lightbulb : Icons.lightbulb_outlined,
                        color: pumpItem.light == "1" ? Colors.yellow.shade700 : pumpItem.light == "2" ? Colors.red.shade600 : Colors.grey.shade600,
                        size: 40,
                        semanticLabel: pumpItem.light == "1" ? 'Light On' : 'Light Off',
                      ),*/
                    ),
                    Row(
                      children: [
                        BounceEffectButton(
                          label: "ON",
                          textColor: Colors.green,
                          onTap: pumpData.dataFetchingStatus == 1 ? () async {
                            setState(() => pumpItem.light = "2");
                            var data = {
                              "userId": widget.customerId,
                              "controllerId": widget.masterData.controllerId,
                              "data": {"sentSms": "lighton"},
                              "messageStatus": "Turned on light manually",
                              "createUser": widget.userId,
                              "hardware": {"sentSms": "lighton"},
                            };
                            await mqttService.topicToPublishAndItsMessage(jsonEncode({"sentSms": "lighton"}), "${Environment.mqttPublishTopic}/${widget.masterData.deviceId}",);
                            await repository.sendManualOperationToServer(data);
                            await Future.delayed(const Duration(seconds: 2));
                            liveRequest();
                          } : null,
                        ),
                        BounceEffectButton(
                          label: "OFF",
                          textColor: Colors.red,
                          onTap: pumpData.dataFetchingStatus == 1 ? () async {
                            setState(() => pumpItem.light = "2");
                            var data = {
                              "userId": widget.customerId,
                              "controllerId": widget.masterData.controllerId,
                              "data": {"sentSms": "lightoff"},
                              "messageStatus": "Turned off light manually",
                              "createUser": widget.userId,
                              "hardware": {"sentSms": "lightoff"},
                            };
                            await mqttService.topicToPublishAndItsMessage(jsonEncode({"sentSms": "lightoff"}), "${Environment.mqttPublishTopic}/${widget.masterData.deviceId}",);
                            await repository.sendManualOperationToServer(data);
                            await Future.delayed(const Duration(seconds: 2));
                            liveRequest();
                          } : null,
                        )
                      ],
                    ),
                    /* Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if(int.parse(pumpData.numberOfPumps) == 1)
                          for(var i = 0; i < pumpData.current.toString().split(',').length; i++)
                            buildCurrentContainer(
                              title: ['RC : ', 'YC : ', 'BC : '][i],
                              value: "${pumpData.current.toString().split(',')[i].substring(2)} A",
                              color1: [
                                Colors.redAccent.shade100,
                                Colors.amberAccent.shade100,
                                Colors.lightBlueAccent.shade100,
                              ][i],
                              color2: [
                                Colors.redAccent.shade700,
                                Colors.amberAccent.shade700,
                                Colors.lightBlueAccent.shade700,
                              ][i],
                            ),
                      ],
                    )*/
                    // const SizedBox(width: 10,),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15,)
      ],
    );
  }

  Widget _buildPumpControlButton({required String label, required Color color, required String command, required int delay, required PumpControllerData pumpData, required int index}) {
    bool isWlc = AppConstants.wlcModelList.contains(widget.masterData.modelId);
    bool isAutoMode = pumpData.manualMode.toUpperCase() == '1' || pumpData.manualMode.toUpperCase() == 'AUTO';
    bool isDisabled = (isWlc && isAutoMode) || pumpData.dataFetchingStatus != 1;

    return BounceEffectButton(
      label: label,
      textColor: color,
      onTap: !isDisabled ? () async {
        setState(() => pumpData.pumps[index].status = 2);
        var data = {
          "userId": widget.customerId,
          "controllerId": widget.masterData.controllerId,
          "data": {"sentSms": "motor${index+1}$command"},
          "messageStatus": "Motor${index+1} $label",
          "createUser": widget.userId,
          "hardware": {"sentSms": "motor${index+1}$command"},
        };
        var payload = {"sentSms": "motor${index+1}$command"};
        var normalCommand = jsonEncode(payload);
        String? wlcCommand = '*$normalCommand#';
        final result = await context.read<CommunicationService>().sendCommand(
          serverMsg: '',
          payload: isWlc ? wlcCommand : normalCommand,
        );
        debugPrint("motor on/off result => $result");
        // await mqttService.topicToPublishAndItsMessage(jsonEncode({"sentSms": "motor${index+1}$command"}), "${Environment.mqttPublishTopic}/${widget.masterData.deviceId}",);
        await repository.sendManualOperationToServer(data);
        await Future.delayed(Duration(seconds: delay));
        liveRequest();
      } : null,
    );
  }

  Widget _buildColumn({
    required String title1,
    required String value1,
    BoxConstraints? constraints,
    IconData? icon,
    Color? color
  }) {
    return SizedBox(
      width: constraints != null ? constraints.maxWidth * 0.25 : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300), textAlign: TextAlign.center,),
          Text(value1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),)
        ],
      ),
    );
  }

  Widget _buildCountdownColumn({
    required String title,
    required Gradient gradient,
    required int initialSeconds,
  }) {
    return Column(
      key: ValueKey('$title-$initialSeconds'),
      children: [
        Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black38),
        ),
        IntrinsicWidth(
          child: Container(
            decoration: BoxDecoration(
              // gradient: gradient,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey, width: 0.5)
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CountdownTimerWidget(
              initialSeconds: initialSeconds,
              fontColor: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildButton({required String label, required Color color, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        color: color,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              shadows: [Shadow(offset: const Offset(2, 2), blurRadius: 6, color: Colors.black.withOpacity(0.3))],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildContainer({
    String? title,
    required String? value,
    String? value2,
    required Color color1,
    required Color color2,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: _boxDecoration(color1, color2),
        // padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(title != null) Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
            if(value != null) Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400,)),
            if (value2 != null) Text(value2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget buildCurrentContainer({
    required String title,
    required String value,
    required Color color1,
    required Color color2,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      width: 100,
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   colors: [color1, color2],
        //   begin: Alignment.topCenter,
        //   end: Alignment.bottomCenter,
        // ),
        color: color1,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color2, width: 0.3),
        boxShadow: [
          BoxShadow(
            color: color2.withOpacity(0.5),
            offset: const Offset(0, 0),
            // blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w400,
              // fontSize: titleFontSize,
            ),
          ),
          // SizedBox(height: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                // fontSize: titleFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration(Color color1, Color color2) {
    return BoxDecoration(
      gradient: LinearGradient(colors: [color1, color2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color2, width: 0.3),
      boxShadow: [BoxShadow(color: color2.withOpacity(0.5), offset: const Offset(0, 0))],
    );
  }

  Widget _buildPumpDetailColumn({
    required String title,
    required Widget content,
    required String footer1,
    required String footer2,
    required IconData icon,
    bool condition = true
  }) {
    if(condition) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                    gradient: AppProperties.linearGradientLeading,
                    shape: BoxShape.circle
                ),
                child: Icon(icon, color: Colors.white,),
              ),
              const SizedBox(width: 10,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 5,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Actual value".toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w400),),
                          const SizedBox(height: 5,),
                          if(footer2 != '')
                            Text("total flow".toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w400),),
                        ],
                      ),
                      const SizedBox(width: 5,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(":".toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w400, ),),
                          const SizedBox(height: 5,),
                          if(footer2 != '')
                            Text(":".toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w400, ),),
                        ],
                      ),
                      const SizedBox(width: 5,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(footer1, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis,),
                          const SizedBox(height: 5,),
                          if(footer2 != '')
                            Text(footer2.split(':')[1], style: const TextStyle(fontWeight: FontWeight.bold, ),),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
          content
        ],
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase()),
          content,
          Text(footer1, style: const TextStyle(fontWeight: FontWeight.bold),),
          if(footer2 != '')
          // Text(footer2)
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5)
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Column(
                children: [
                  Text(footer2.split(':')[0].toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  Text(footer2.split(':')[1], style: const TextStyle(color: Colors.black)),
                ],
              ),
            )
        ],
      ),
    );
  }
}