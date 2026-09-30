import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import '../flavors.dart';
import '../models/customer/site_model.dart';
import '../StateManagement/duration_notifier.dart';
import '../StateManagement/mqtt_payload_provider.dart';
import '../repository/repository.dart';
import '../services/http_service.dart';
import '../services/mqtt_service.dart';
import '../utils/constants.dart';
import '../utils/enums.dart';
import '../utils/formatters.dart';
import '../utils/snack_bar.dart';

class PumpWidget extends StatelessWidget {
  final PumpModel pump;
  final bool isSourcePump;
  final String deviceId;
  final int customerId, controllerId, modelId;
  final bool isMobile, isNova, isAvailFrtSite;
  final String pumpPosition;

  PumpWidget({super.key, required this.pump, required this.isSourcePump,
    required this.deviceId, required this.customerId, required this.controllerId,
    required this.isMobile, required this.modelId, required this.pumpPosition,
    required this.isNova, required this.isAvailFrtSite});

  final ValueNotifier<int> popoverUpdateNotifier = ValueNotifier<int>(0);

  static const excludedReasons = [
    '3', '4', '5', '6', '21', '22', '23', '24',
    '25', '26', '27', '28', '29', '30', '31'
  ];

  @override
  Widget build(BuildContext context) {

    return Selector<MqttPayloadProvider, Tuple2<String?, String?>>(
      selector: (_, provider) => Tuple2(
        provider.getPumpOnOffStatus(pump.sNo.toString()),
        provider.getPumpOtherData(pump.sNo.toString()),
      ),
      builder: (_, data, __) {
        final status = data.item1;
        final other = data.item2;

        final statusParts = status?.split(',') ?? [];
        if (statusParts.length > 1) {
          pump.status = int.tryParse(statusParts[1]) ?? 0;
        }

        final otherParts = other?.split(',') ?? [];
        if (otherParts.length >= 8) {
          pump.reason = otherParts[1];
          pump.setValue = otherParts[2];
          pump.actualValue = otherParts[3];
          pump.phase = otherParts[4];
          pump.voltage = otherParts[5];
          pump.current = otherParts[6];
          pump.onDelayLeft = otherParts[7];
        }

        final hasVoltage = pump.voltage.isNotEmpty;
        final voltages = hasVoltage ? pump.voltage.split('_') : [];
        final currents = hasVoltage ? pump.current.split('_') : [];

        final List<String> columns = ['-', '-', '-'];
        if (hasVoltage) {
          for (var pair in currents) {
            final parts = pair.trim().replaceAll('"', '').split(':');
            if (parts.length == 2) {
              final index = int.tryParse(parts[0].trim());
              if (index != null && index >= 1 && index <= columns.length) {
                columns[index - 1] = parts[1].trim();
              }
            }
          }
        }

        return Stack(
          children: [
            SizedBox(
              width: 70,
              height: 100,
              child: Column(
                children: [
                  Builder(
                    builder: (buttonContext) => Tooltip(
                      message: 'View more details',
                      child: TextButton(
                        onPressed: () {
                          showPopover(
                            context: buttonContext,
                            bodyBuilder: (context) {
                              return ValueListenableBuilder<int>(
                                valueListenable: popoverUpdateNotifier,
                                builder: (context, _, __) {
                                  return Material(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        hasVoltage?
                                        _buildVoltagePopoverContent(context, voltages, columns, isNova) :
                                        Container(),
                                        if (isSourcePump) _buildBottomControlButtons(context),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            onPop: () => debugPrint('Popover was popped!'),
                            direction: PopoverDirection.bottom,
                            width: 325,
                            arrowHeight: 15,
                            arrowWidth: 30,
                          );
                        },
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                          minimumSize: WidgetStateProperty.all(Size.zero),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: WidgetStateProperty.all(Colors.transparent),
                        ),
                        child: SizedBox(
                          height : 70,
                          child: AppConstants.getAsset(isMobile ? 'mobile pump' : 'pump', pump.status, '', 0),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    pump.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            if (pump.onDelayLeft != '00:00:00' && Formatters().isValidTimeFormat(pump.onDelayLeft))
              Positioned(
                top: isMobile ? 20 : 40,
                left: 7.5,
                child: ChangeNotifierProvider(
                  create: (_) => DecreaseDurationNotifier(pump.onDelayLeft),
                  child: Consumer<DecreaseDurationNotifier>(
                    builder: (context, notifier, _) {
                      // Hide the widget when countdown reaches 00:00:00
                      if (notifier.onDelayLeft == '00:00:00') {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        width: 55,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(2),
                          ),
                          border: Border.all(
                            color: Colors.green,
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Text(
                                "On delay",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                              const Divider(
                                height: 0,
                                color: Colors.grey,
                              ),
                              Text(
                                notifier.onDelayLeft,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            if (int.tryParse(pump.reason) case final reason? when reason > 0 && reason != 31)
              Positioned(
                top: 1,
                left: 37.5,
                child: Tooltip(
                  message: getContentByCode(reason),
                  textStyle: const TextStyle(color: Colors.black54),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.deepOrangeAccent,
                    child: Icon(Icons.info_outline, size: 17, color: Colors.white),
                  ),
                ),
              ),

            if (pump.reason == '11' || pump.reason == '22')
              Positioned(
                top: pump.actualValue == '0.0' ? 50 : 40,
                left: 0,
                child: Container(
                  width: 67,
                  decoration: BoxDecoration(
                    color: pump.status == 1 ? Colors.greenAccent : Colors.yellowAccent,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    border: Border.all(color: Colors.grey, width: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        if(pump.actualValue!='0.0')...[
                          Text('Max: ${pump.actualValue}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                          const Divider(height: 0, color: Colors.grey, thickness: 0.5),
                        ],
                        Text(
                          pump.status == 1 ? 'cRm: ${pump.setValue}' : 'Brk: ${pump.setValue}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              )

            else if (pump.reason == '8' && isTimeFormat(pump.actualValue.split('_').last))
              Positioned(
                top: 40,
                left: 0,
                child: Container(
                  width: 67,
                  decoration: BoxDecoration(
                    color: pump.status == 1 ? Colors.greenAccent : Colors.yellowAccent,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    border: Border.all(color: Colors.grey, width: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('Restart within', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        const Divider(height: 0, color: Colors.grey, thickness: 0.5),
                        Text(
                          pump.actualValue.split('_').last,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVoltagePopoverContent(BuildContext context,
      voltages, columns, bool isNova) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (int.tryParse(pump.reason) != null &&
            int.parse(pump.reason) > 0 &&
            int.parse(pump.reason) != 31)
          _buildReasonContainer(context),

        if(!isNova)...[
          const SizedBox(height: 8),

          if(F.appFlavor!.name.contains('smart'))...[
            _buildVoltageCurrentInfo(voltages.sublist(0, 3), ['RY', 'YB', 'BR']),
          ]else...[
            if (voltages.length == 6)...[
              _buildVoltageCurrentInfo(voltages.sublist(0, 3), ['RN', 'YN', 'BN']),
              const SizedBox(height: 5),
              _buildVoltageCurrentInfo(voltages.sublist(3, 6), ['RY', 'YB', 'BR']),
            ]else ...[
              _buildVoltageCurrentInfo(voltages.sublist(0, 3), ['RN', 'YN', 'BN']),
            ],
          ],
          const SizedBox(height: 8),
          _buildVoltageCurrentInfo(columns, ['RC', 'YC', 'BC']),
          const SizedBox(height: 10),
        ]else...[
          ListTile(
            title: const Text(
              'This pump connected with',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            trailing: Text(
              getPumpConnectedPhaseNames(columns),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            dense: true,
          ),
        ],
      ],
    );
  }

  String getPumpConnectedPhaseNames(List<String> columns) {
    const phaseNames = ['RC', 'YC', 'BC'];
    List<String> connected = [];

    for (int i = 0; i < columns.length && i < 3; i++) {
      final value = columns[i].trim();
      if (value != '-' && value.isNotEmpty) {
        connected.add(phaseNames[i]);
      }
    }

    if (connected.isEmpty) return '-';

    return connected.join(' & ');
  }

  Widget _buildReasonContainer(BuildContext context) {
    return Container(
      width: 325,
      height: isMobile? 40 : 35,
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                pump.reason == '8' &&
                    isTimeFormat(pump.actualValue.split('_').last)
                    ? '${getContentByCode(int.parse(pump.reason))}, It will be restart automatically within ${pump.actualValue.split('_').last} (hh:mm:ss)'
                    : getContentByCode(int.parse(pump.reason)),
                style: const TextStyle(
                    fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.normal),
              ),
            ),
            if (!excludedReasons.contains(pump.reason))
              SizedBox(
                height: isMobile? 30 : 23,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade200,
                  ),
                  onPressed: () {
                    String payload = '${pump.sNo},1';
                    String payLoadFinal = jsonEncode({
                      "6300": {"6301": payload}
                    });
                    MqttService().topicToPublishAndItsMessage(payLoadFinal, '${AppConstants.publishTopic}/$deviceId');
                    sentUserOperationToServer('${pump.name} Reset Manually', payLoadFinal);
                    GlobalSnackBar.show(context, 'Reset comment sent successfully', 200);
                    Navigator.pop(context);
                  },
                  child: const Text('Reset',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildVoltageCurrentInfo(List<String> values, List<String> prefixes) {

    return Container(
      width: 320,
      height: 30,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            ...List.generate(3, (index) {
              Color bgColor, borderColor;
              switch (index) {
                case 0:
                  bgColor = Colors.red.shade100;
                  borderColor = Colors.red.shade300;
                  break;
                case 1:
                  bgColor = Colors.yellow.shade100;
                  borderColor = Colors.yellow;
                  break;
                case 2:
                  bgColor = Colors.blue.shade100;
                  borderColor = Colors.blue.shade300;
                  break;
                default:
                  bgColor = Colors.white;
                  borderColor = Colors.grey;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 7),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor, width: 0.7),
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                  width: 95,
                  height: 45,
                  child: Center(
                    child: Text(
                      '${prefixes[index]} : ${values[index]}',
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
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

  Widget _buildBottomControlButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Spacer(),
          MaterialButton(
            color: Colors.green,
            textColor: Colors.white,
            onPressed: () {
              String payload = '${pump.sNo},1,1';
              if(AppConstants.ecoGemModelList.contains(modelId)) {
                payload = payload.replaceAll(RegExp(r'[.]'), ',');
              }

              final payLoadFinal = jsonEncode({"6200": {"6201": payload}});
              MqttService().topicToPublishAndItsMessage(payLoadFinal, '${AppConstants.publishTopic}/$deviceId');
              sentUserOperationToServer('${pump.name} Start Manually', payLoadFinal);
              GlobalSnackBar.show(context, 'Pump start comment sent successfully', 200);
              Navigator.pop(context);
            },
            child: const Text('Start Manually'),
          ),
          const SizedBox(width: 8),
          MaterialButton(
            color: Colors.redAccent,
            textColor: Colors.white,
            onPressed: () {
              String payload = '${pump.sNo},0,1';
              if(AppConstants.ecoGemModelList.contains(modelId)) {
                payload = payload.replaceAll(RegExp(r'[.]'), ',');
              }

              final payLoadFinal = jsonEncode({"6200": {"6201": payload}});
              MqttService().topicToPublishAndItsMessage(payLoadFinal, '${AppConstants.publishTopic}/$deviceId');
              sentUserOperationToServer('${pump.name} Stop Manually', payLoadFinal);
              GlobalSnackBar.show(context, 'Pump stop comment sent successfully', 200);
              Navigator.pop(context);
            },
            child: const Text('Stop Manually'),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  bool isTimeFormat(String value) {
    final timeRegExp = RegExp(r'^([0-1]?\d|2[0-3]):[0-5]\d:[0-5]\d$');
    return timeRegExp.hasMatch(value);
  }

  String getContentByCode(int code) {
    return PumpReasonCode.fromCode(code).content;
  }

  void sentUserOperationToServer(String msg, String data) async
  {
    Map<String, Object> body = {"userId": customerId, "controllerId": controllerId, "messageStatus": msg, "hardware": jsonDecode(data), "createUser": customerId};
    final response = await Repository(HttpService()).sendManualOperationToServer(body);
    if (response.statusCode == 200) {
      debugPrint(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }
}

class AeratorWidget extends StatelessWidget {
  final PumpModel pump;
  final String deviceId;
  final int customerId, controllerId, modelId;
  final bool isMobile;

  AeratorWidget({super.key, required this.pump,
    required this.deviceId, required this.customerId, required this.controllerId,
    required this.isMobile, required this.modelId});

  final ValueNotifier<int> popoverUpdateNotifier = ValueNotifier<int>(0);

  static const excludedReasons = [
    '3', '4', '5', '6', '21', '22', '23', '24',
    '25', '26', '27', '28', '29', '30', '31'
  ];

  @override
  Widget build(BuildContext context) {

    return Selector<MqttPayloadProvider, Tuple2<String?, String?>>(
      selector: (_, provider) => Tuple2(
        provider.getPumpOnOffStatus(pump.sNo.toString()),
        provider.getPumpOtherData(pump.sNo.toString()),
      ),
      builder: (_, data, __) {
        final status = data.item1;
        final other = data.item2;

        final statusParts = status?.split(',') ?? [];
        if (statusParts.length > 1) {
          pump.status = int.tryParse(statusParts[1]) ?? 0;
        }

        final otherParts = other?.split(',') ?? [];
        if (otherParts.length >= 8) {
          pump.reason = otherParts[1];
          pump.setValue = otherParts[2];
          pump.actualValue = otherParts[3];
          pump.phase = otherParts[4];
          pump.voltage = otherParts[5];
          pump.current = otherParts[6];
          pump.onDelayLeft = otherParts[7];
        }

        final hasVoltage = pump.voltage.isNotEmpty;
        final voltages = hasVoltage ? pump.voltage.split('_') : [];
        final currents = hasVoltage ? pump.current.split('_') : [];

        final List<String> columns = ['-', '-', '-', '-'];
        if (hasVoltage) {
          for (var pair in currents) {
            final parts = pair.trim().replaceAll('"', '').split(':');
            if (parts.length == 2) {
              final index = int.tryParse(parts[0].trim());
              if (index != null && index >= 1 && index <= columns.length) {
                columns[index - 1] = parts[1].trim();
              }
            }
          }
        }

        return Stack(
          children: [
            SizedBox(
              width: 70,
              height: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                    builder: (buttonContext) => Tooltip(
                      message: 'View more details',
                      child: TextButton(
                        onPressed: () {
                          showPopover(
                            context: buttonContext,
                            bodyBuilder: (context) {
                              return ValueListenableBuilder<int>(
                                valueListenable: popoverUpdateNotifier,
                                builder: (context, _, __) {
                                  return Material(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        hasVoltage?
                                        _buildVoltagePopoverContent(context, voltages, columns, false) :
                                        Container(),
                                       _buildBottomControlButtons(context),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            onPop: () => debugPrint('Popover was popped!'),
                            direction: PopoverDirection.bottom,
                            width: 325,
                            arrowHeight: 15,
                            arrowWidth: 30,
                          );
                        },
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                          minimumSize: WidgetStateProperty.all(Size.zero),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: WidgetStateProperty.all(Colors.transparent),
                        ),
                        child: SizedBox(
                          height : 67,
                          child: AppConstants.getAsset('aerator', pump.status, '', 0),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    pump.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            if (pump.onDelayLeft != '00:00:00' && Formatters().isValidTimeFormat(pump.onDelayLeft))
              Positioned(
                top: isMobile? 20:40,
                left: 7.5,
                child: Container(
                  width: 55,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    border: Border.all(color: Colors.green, width: 0.5),
                  ),
                  child: ChangeNotifierProvider(
                    create: (_) => DecreaseDurationNotifier(pump.onDelayLeft),
                    child: Consumer<DecreaseDurationNotifier>(
                      builder: (context, notifier, _) {
                        return Center(
                          child: Column(
                            children: [
                              const Text("On delay", style: TextStyle(fontSize: 10, color: Colors.black)),
                              const Divider(height: 0, color: Colors.grey),
                              Text(notifier.onDelayLeft, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            if (int.tryParse(pump.reason) case final reason? when reason > 0 && reason != 31)
              Positioned(
                top: 1,
                left: 47,
                child: Tooltip(
                  message: getContentByCode(reason),
                  textStyle: const TextStyle(color: Colors.black54),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.deepOrangeAccent,
                    child: Icon(Icons.info_outline, size: 17, color: Colors.white),
                  ),
                ),
              ),

            if (pump.reason == '11' || pump.reason == '22')
              Positioned(
                top: pump.actualValue == '0.0' ? 50 : 40,
                left: 0,
                child: Container(
                  width: 67,
                  decoration: BoxDecoration(
                    color: pump.status == 1 ? Colors.greenAccent : Colors.yellowAccent,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    border: Border.all(color: Colors.grey, width: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        if(pump.actualValue!='0.0')...[
                          Text('Max: ${pump.actualValue}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                          const Divider(height: 0, color: Colors.grey, thickness: 0.5),
                        ],
                        Text(
                          pump.status == 1 ? 'cRm: ${pump.setValue}' : 'Brk: ${pump.setValue}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              )

            else if (pump.reason == '8' && isTimeFormat(pump.actualValue.split('_').last))
              Positioned(
                top: 40,
                left: 0,
                child: Container(
                  width: 67,
                  decoration: BoxDecoration(
                    color: pump.status == 1 ? Colors.greenAccent : Colors.yellowAccent,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    border: Border.all(color: Colors.grey, width: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('Restart within', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        const Divider(height: 0, color: Colors.grey, thickness: 0.5),
                        Text(
                          pump.actualValue.split('_').last,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVoltagePopoverContent(BuildContext context,
      voltages, columns, bool isNova) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (int.tryParse(pump.reason) != null &&
            int.parse(pump.reason) > 0 &&
            int.parse(pump.reason) != 31)
          _buildReasonContainer(context),

        if(!isNova)...[
          const SizedBox(height: 8),
          if (voltages.length == 6)...[
            _buildVoltageCurrentInfo(voltages.sublist(0, 3), ['RY', 'YB', 'BR'], false),
            const SizedBox(height: 5),
            _buildVoltageCurrentInfo(voltages.sublist(3, 6), ['RN', 'YN', 'BN'], false),
          ]else ...[
            _buildVoltageCurrentInfo(voltages.sublist(0, 3), ['RY', 'YB', 'BR'], false),
          ],
          const SizedBox(height: 8),
          _buildVoltageCurrentInfo(columns, ['C1', 'C2', 'C3', 'C4'], true),
          const SizedBox(height: 10),
        ]else...[
          ListTile(
            title: const Text(
              'This pump connected with',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            trailing: Text(
              getPumpConnectedPhaseNames(columns),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            dense: true,
          ),
        ],
      ],
    );
  }

  String getPumpConnectedPhaseNames(List<String> columns) {
    const phaseNames = ['RC', 'YC', 'BC'];
    List<String> connected = [];

    for (int i = 0; i < columns.length && i < 3; i++) {
      final value = columns[i].trim();

      if (value != '-' && value.isNotEmpty) {
        connected.add(phaseNames[i]);
      }
    }

    if (connected.isEmpty) return '-';

    return connected.join(' & ');
  }

  Widget _buildReasonContainer(BuildContext context) {
    return Container(
      width: 325,
      height: isMobile? 40 : 35,
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                pump.reason == '8' &&
                    isTimeFormat(pump.actualValue.split('_').last)
                    ? '${getContentByCode(int.parse(pump.reason))}, It will be restart automatically within ${pump.actualValue.split('_').last} (hh:mm:ss)'
                    : getContentByCode(int.parse(pump.reason)),
                style: const TextStyle(
                    fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.normal),
              ),
            ),
            if (!excludedReasons.contains(pump.reason))
              SizedBox(
                height: isMobile? 30 : 23,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade200,
                  ),
                  onPressed: () {
                    String payload = '${pump.sNo},1';
                    String payLoadFinal = jsonEncode({
                      "6300": {"6301": payload}
                    });
                    MqttService().topicToPublishAndItsMessage(payLoadFinal, '${AppConstants.publishTopic}/$deviceId');
                    sentUserOperationToServer('${pump.name} Reset Manually', payLoadFinal);
                    GlobalSnackBar.show(context, 'Reset comment sent successfully', 200);
                    Navigator.pop(context);
                  },
                  child: const Text('Reset',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildVoltageCurrentInfo(List<String> values, List<String> prefixes, bool isAerator) {

    return Container(
      width: 320,
      height: 30,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            ...List.generate(isAerator ? 4:3, (index) {
              Color bgColor, borderColor;

              if(isAerator) {
                bgColor = Colors.green.shade100;
                borderColor = Colors.green.shade300;
              }else{
                switch (index) {
                  case 0:
                    bgColor = Colors.red.shade100;
                    borderColor = Colors.red.shade300;
                    break;
                  case 1:
                    bgColor = Colors.yellow.shade100;
                    borderColor = Colors.yellow;
                    break;
                  case 2:
                    bgColor = Colors.blue.shade100;
                    borderColor = Colors.blue.shade300;
                    break;
                  default:
                    bgColor = Colors.white;
                    borderColor = Colors.grey;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(right: 7),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor, width: 0.7),
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                  width: isAerator ? 70 : 95,
                  height: 45,
                  child: Center(
                    child: Text(
                      '${prefixes[index]} : ${values[index]}',
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
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

  Widget _buildBottomControlButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Spacer(),
          MaterialButton(
            color: Colors.green,
            textColor: Colors.white,
            onPressed: () {
              String payload = '${pump.sNo},1,1';
              if(AppConstants.ecoGemModelList.contains(modelId)) {
                payload = payload.replaceAll(RegExp(r'[.]'), ',');
              }

              final payLoadFinal = jsonEncode({"6200": {"6201": payload}});
              MqttService().topicToPublishAndItsMessage(payLoadFinal, '${AppConstants.publishTopic}/$deviceId');
              sentUserOperationToServer('${pump.name} Start Manually', payLoadFinal);
              GlobalSnackBar.show(context, 'Pump start comment sent successfully', 200);
              Navigator.pop(context);
            },
            child: const Text('Start Manually'),
          ),
          const SizedBox(width: 8),
          MaterialButton(
            color: Colors.redAccent,
            textColor: Colors.white,
            onPressed: () {
              String payload = '${pump.sNo},0,1';
              if(AppConstants.ecoGemModelList.contains(modelId)) {
                payload = payload.replaceAll(RegExp(r'[.]'), ',');
              }

              final payLoadFinal = jsonEncode({"6200": {"6201": payload}});
              MqttService().topicToPublishAndItsMessage(payLoadFinal, '${AppConstants.publishTopic}/$deviceId');
              sentUserOperationToServer('${pump.name} Stop Manually', payLoadFinal);
              GlobalSnackBar.show(context, 'Pump stop comment sent successfully', 200);
              Navigator.pop(context);
            },
            child: const Text('Stop Manually'),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  bool isTimeFormat(String value) {
    final timeRegExp = RegExp(r'^([0-1]?\d|2[0-3]):[0-5]\d:[0-5]\d$');
    return timeRegExp.hasMatch(value);
  }

  String getContentByCode(int code) {
    return PumpReasonCode.fromCode(code).content;
  }

  void sentUserOperationToServer(String msg, String data) async
  {
    Map<String, Object> body = {"userId": customerId, "controllerId": controllerId, "messageStatus": msg, "hardware": jsonDecode(data), "createUser": customerId};
    final response = await Repository(HttpService()).sendManualOperationToServer(body);
    if (response.statusCode == 200) {
      debugPrint(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }
}

class VoltageWidget extends StatelessWidget {
  const VoltageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, List<String>?>(
      selector: (_, provider) => provider.getNovaVoltage(),
      builder: (_, data, __) {

        if (data == null || data.isEmpty) {
          return const SizedBox();
        }

        final pumpCount = data.length;

        final payload = data.first;
        final parts = payload.split(",");

        if (parts.length < 7) return const SizedBox();

        final voltageList = parts[5].split("_");

        final currentRaw = parts[6].split("_");

        String bcCurrentFromPump2 = "-";
        if (pumpCount == 2) {
          bcCurrentFromPump2 = getBcCurrentFromSecondPump(data);
        }

        List<String> currentColumns = ["0", "0", "0"];

        for (var c in currentRaw) {
          if (c.contains(":")) {
            var sp = c.split(":");
            var phase = int.tryParse(sp[0]) ?? 0;
            var value = sp[1];

            if (phase == 1) currentColumns[0] = value;
            if (phase == 2) currentColumns[1] = value;
            if (phase == 3) currentColumns[2] = value;
          }
        }

        if (pumpCount == 2) {
          currentColumns[2] = bcCurrentFromPump2;
        }

        return Column(
          children: [
            _buildVoltagePopoverContent(
                context,
                voltageList,
                currentColumns,
            ),
          ],
        );
      },
    );
  }

  String getBcCurrentFromSecondPump(List<String> data) {
    if (data.length < 2) return "-";

    final payload = data[1];
    final parts = payload.split(",");

    if (parts.length < 7) return "-";

    final currents = parts[6].split("_");

    for (var pair in currents) {
      var sp = pair.split(":");
      if (sp.length == 2) {
        int phase = int.parse(sp[0]);
        if (phase == 3) {
          return sp[1];
        }
      }
    }

    return "-";
  }


  Widget _buildVoltagePopoverContent(BuildContext context, voltages, columns) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (voltages.length == 6) ...[
          _buildVoltageCurrentInfo(voltages.sublist(0, 3), ['RY', 'YB', 'BR']),
          const SizedBox(height: 5),
          _buildVoltageCurrentInfo(voltages.sublist(3, 6), ['RN', 'YN', 'BN']),
        ] else ...[
          _buildVoltageCurrentInfo(voltages.sublist(0, 3), ['RY', 'YB', 'BR']),
        ],
        const SizedBox(height: 8),
        _buildVoltageCurrentInfo(columns, ['RC', 'YC', 'BC']),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildVoltageCurrentInfo(List<String> values, List<String> prefixes) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          ...List.generate(3, (index) {
            Color bgColor, borderColor;
            switch (index) {
              case 0:
                bgColor = Colors.red.shade100;
                borderColor = Colors.red;
                break;
              case 1:
                bgColor = Colors.yellow.shade200;
                borderColor = Colors.yellow;
                break;
              case 2:
                bgColor = Colors.blue.shade100;
                borderColor = Colors.blue;
                break;
              default:
                bgColor = Colors.white;
                borderColor = Colors.grey;
            }

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 7),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor, width: 0.7),
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                  width: 95,
                  height: 30,
                  child: Center(
                    child: Text(
                      '${prefixes[index]} : ${values[index]}',
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}