import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oro_drip_irrigation/views/common/user_dashboard/widgets/sensor_popover_content.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

import '../../../../StateManagement/mqtt_payload_provider.dart';
import '../../../../models/customer/sensor_hourly_data_model.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../repository/repository.dart';
import '../../../../services/http_service.dart';
import '../../../../utils/my_function.dart';

class SensorWidget extends StatelessWidget {
  final SensorModel sensor;
  final String sensorType;
  final String imagePath;
  final int customerId, controllerId;

  const SensorWidget({
    super.key,
    required this.sensor,
    required this.sensorType,
    required this.imagePath,
    required this.customerId,
    required this.controllerId,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getSensorUpdatedValve(sensor.sNo.toString()),
      builder: (_, status, __) {
        final statusParts = status?.split(',') ?? [];
        if (statusParts.isNotEmpty) {
          sensor.value = statusParts[1];
        }

        return SizedBox(
          width: 70,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (sensorType != 'Pressure Switch')
                _buildSensorButton(context)
              else ...[
                const SizedBox(height: 1),
                Stack(
                  children: [
                    Image.asset(
                      imagePath,
                      width: 70,
                      height: 70,
                    ),
                    Positioned(
                      top: 36,
                      left: 17.5,
                      child: Container(
                        height: 18,
                        width: 45,
                        decoration: BoxDecoration(
                          color: sensor.value == "1" ? Colors.green.shade300 : Colors.red.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Center(
                          child: Text(
                            sensor.value == "1" ? 'Low' : 'High',
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              Text(
                sensor.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensorButton(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: 70,
          height: 65,
          child: TextButton(
            onPressed: () async {

              showPopover(
                context: context,
                bodyBuilder: (context) => SensorPopoverContent(
                  sensor: sensor,
                  sensorType: sensorType,
                  customerId: customerId,
                  controllerId: controllerId,
                ),
                direction: PopoverDirection.bottom,
                width: 550,
                height: 310,
                arrowHeight: 15,
                arrowWidth: 30,
                barrierColor: Colors.black54,
              );
            },
            style: ButtonStyle(
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              minimumSize: WidgetStateProperty.all(Size.zero),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
            ),
            child: Image.asset(imagePath, width: 70, height: 70),
          ),
        ),
        Positioned(
          top: 17,
          left: sensorType == 'Pressure Sensor' ? 10 : 1,
          right: sensorType == 'Pressure Sensor' ? 10 : 1,
          child: Container(
            width: 70,
            height: 17,
            decoration: BoxDecoration(
              color: Colors.yellow,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.grey, width: 0.5),
            ),
            child: Center(
              child: Text(
                MyFunction().getUnitByParameter(context, sensorType, sensor.value.toString()) ?? '',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<List<SensorHourlyDataModel>> fetchSensorData(DateTime fromDate, DateTime toDate) async {
    List<SensorHourlyDataModel> sensors = [];

    try {
      final from = DateFormat('yyyy-MM-dd').format(fromDate);
      final to = DateFormat('yyyy-MM-dd').format(toDate);

      final body = {
        "userId": customerId,
        "controllerId": controllerId,
        "fromDate": from,
        "toDate": to,
      };

      final response = await Repository(HttpService()).fetchSensorHourlyData(body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          sensors = (jsonData['data'] as List).map((item) {
            final dateStr = item['date'];
            final Map<String, List<SensorHourlyData>> hourlyDataMap = {};

            item.forEach((key, value) {
              if (key == 'date') return;
              if (value is String && value.isNotEmpty) {
                final entries = value.split(';');
                hourlyDataMap[key] = entries
                    .map((entry) => SensorHourlyData.fromCsv(entry, key, dateStr))
                    .toList();
              } else {
                hourlyDataMap[key] = [];
              }
            });

            return SensorHourlyDataModel(date: dateStr, data: hourlyDataMap);
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching sensor hourly data: $e');
    }

    return sensors;
  }

  List<SensorHourlyData> getSensorDataById(String sensorId, List<SensorHourlyDataModel> sensorData) {
    final result = <SensorHourlyData>[];
    for (final model in sensorData) {
      model.data.forEach((_, sensorList) {
        result.addAll(sensorList.where((sensor) => sensor.sensorId == sensorId));
      });
    }
    return result;
  }
}