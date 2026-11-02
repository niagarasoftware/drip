import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oro_drip_irrigation/utils/environment.dart';

import '../../../models/customer/site_model.dart';
import '../../../services/mqtt_service.dart';
import '../model/pump_controller_data_model.dart';

class SetSerialScreen extends StatefulWidget {
  final List<NodeListModel> nodeList;
  final String deviceId;
  const SetSerialScreen({super.key, required this.nodeList, required this.deviceId});

  @override
  State<SetSerialScreen> createState() => _SetSerialScreenState();
}

class _SetSerialScreenState extends State<SetSerialScreen> {
  @override
  Widget build(BuildContext context) {
    final MqttService mqttService = MqttService();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 50,
            child: Row(
              children: [
                const SizedBox(width: 5),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 5),
                        CircleAvatar(radius: 5, backgroundColor: Colors.green),
                        SizedBox(width: 5),
                        Text('Connected', style: TextStyle(fontSize: 12, color: Colors.black)),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(width: 5),
                        CircleAvatar(radius: 5, backgroundColor: Colors.grey),
                        SizedBox(width: 5),
                        Text('No Communication', style: TextStyle(fontSize: 12, color: Colors.black)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 10),
                        CircleAvatar(radius: 5, backgroundColor: Colors.redAccent),
                        SizedBox(width: 5),
                        Text('Set Serial Error', style: TextStyle(fontSize: 12, color: Colors.black)),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(width: 10),
                        CircleAvatar(radius: 5, backgroundColor: Colors.yellow),
                        SizedBox(width: 5),
                        Text('Low Battery', style: TextStyle(fontSize: 12, color: Colors.black)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 40,
                  child: IconButton(
                    tooltip: 'Set serial for all Nodes',
                    icon: Icon(
                      Icons.format_list_numbered,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Confirmation'),
                        content: const Text('Are you sure! you want to proceed to reset all node ids?'),
                        actions: [
                          MaterialButton(
                            color: Colors.redAccent,
                            textColor: Colors.white,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          MaterialButton(
                            color: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                            onPressed: () {
                              MqttService().topicToPublishAndItsMessage(jsonEncode({'sentSms': 'setserial,3'}), '${Environment.mqttPublishTopic}/${widget.deviceId}');
                              Navigator.of(context).pop();
                            },
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                /*SizedBox(
                  width: 40,
                  child: IconButton(
                    tooltip: 'Test Communication',
                    icon: Icon(
                      Icons.network_check,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    onPressed: (){},
                  ),
                ),*/
              ],
            ),
          ),
          SizedBox(
            width:400,
            height: 35,
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 400,
              headingRowHeight: 35.0,
              headingRowColor: WidgetStateProperty.all<Color>(Theme.of(context).primaryColorDark.withValues(alpha: 0.3)),
              columns: const [
                DataColumn2(
                    label: Center(child: Text('S.No', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: Colors.black),)),
                    fixedWidth: 35
                ),
                DataColumn2(
                  label: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: Colors.black),)),
                  fixedWidth: 55,
                ),
                DataColumn2(
                  label: Center(child: Text('Rf.No', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: Colors.black),)),
                  fixedWidth: 45,
                ),
                DataColumn2(
                  label: Text('Category', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: Colors.black),),
                  size: ColumnSize.M,
                  numeric: true,
                ),
                DataColumn2(
                  label: Text('Info', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: Colors.black),),
                  fixedWidth: 100,
                ),
              ],
              rows: List<DataRow>.generate(0,(index) => const DataRow(cells: [],),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.nodeList.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = widget.nodeList[index];
                  return ExpansionTile(
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline,),
                        IconButton(
                          onPressed: () {
                            // context.read<NodeListViewModel>().showEditProductDialog(context, nodeList[index].deviceName, nodeList[index].controllerId, index);
                          },
                          icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColorDark,),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.teal.shade50,
                    title: Row(
                      children: [
                        SizedBox(width: 30, child: Text('${item.serialNumber}', style: const TextStyle(fontSize: 13),)),
                        SizedBox(
                          width:50,
                          child: StreamBuilder<PumpControllerData?>(
                              stream: mqttService.pumpDashboardPayloadStream,
                              builder: (BuildContext context, AsyncSnapshot<PumpControllerData?> snapshot) {
                                final status = snapshot.data != null
                                    ? (snapshot.data!.pumps.firstWhere((pump) => pump is PumpValveModel) as PumpValveModel).setSerialFlag.split(',')
                                    : '0,0'.split(',');
                                // print("status :: $status");
                                return Center(
                                    child: CircleAvatar(
                                      radius: 7,
                                      backgroundColor: status[index] == '1'
                                          ? Colors.green.shade400
                                          : status[index] == '0'
                                          ? Colors.grey
                                          : Colors.redAccent,
                                    )
                                );
                              }
                          ),
                        ),
                        SizedBox(width: 40, child: Center(child: Text('${item.referenceNumber}', style: const TextStyle(fontSize: 13),))),
                        SizedBox(
                          width: 142,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(item.deviceName, style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black, fontSize: 13)),
                              Text(item.deviceId, style: const TextStyle(fontWeight: FontWeight.normal,fontSize: 11, color: Colors.black)),
                              RichText(
                                text: TextSpan(
                                  children: <TextSpan>[
                                    TextSpan(text: '${item.categoryName} - ', style: const TextStyle(fontWeight: FontWeight.normal,fontSize: 10, color: Colors.black)),
                                    TextSpan(text: mapInterfaceType(item.interface), style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 10, color: Colors.black),),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              color: Colors.teal.shade100,
                              width : 370,
                              height: 25,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5, right: 5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Missed communication :',
                                        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13)),
                                    const Spacer(),
                                    Text(
                                      'Total : ${item.communicationCount.split(',').first}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 8,),
                                    Text(
                                      'Continuous : ${item.communicationCount.split(',').last}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ListTile(
                              tileColor: Colors.white,
                              // tileColor: Theme.of(context).primaryColor,
                              textColor: Colors.black,
                              title: const Text('Last feedback', style: TextStyle(fontSize: 10)),
                              subtitle: Text(
                                formatDateTime(item.lastFeedbackReceivedTime),
                                style: const TextStyle(fontSize: 10),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.solar_power),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${item.sVolt} - V',
                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.battery_3_bar_rounded),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${item.batVolt} - V',
                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                  ),
                                  const SizedBox(width: 5),
                                  IconButton(
                                    tooltip: 'Serial set',
                                    onPressed: () async {
                                      final payload = jsonEncode({"sentSms": 'setserial,${item.categoryId == 9 ? '1' : '2'}'});
                                      MqttService().topicToPublishAndItsMessage(payload, '${Environment.mqttPublishTopic}/${widget.deviceId}');
                                      setState(() {
                                        final pump = mqttService.pumpDashboardPayload!.pumps.firstWhere((pump) => pump is PumpValveModel) as PumpValveModel;
                                        List<String> flags = pump.setSerialFlag.split(',');
                                        flags[index] = '2';
                                        pump.setSerialFlag = flags.join(',');
                                      });

                                    },
                                    icon: const Icon(Icons.fact_check_outlined),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
            ),
          ),
        ],
      ),
    );
  }

  String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) {
      return "No feedback received";
    }
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm a');
      return formatter.format(dateTime);
    } catch (e) {
      return "00 00, 0000, 00:00";
    }
  }

  String mapInterfaceType(String interface) {
    switch (interface) {
      case "RS485":
        return "Wired";
      case "LoRa":
        return "Wireless";
      case "MQTT":
        return "GSM";
      default:
        return interface;
    }
  }
}
