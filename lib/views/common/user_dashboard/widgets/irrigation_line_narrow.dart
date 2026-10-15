import 'package:flutter/material.dart';
import '../../../../models/customer/site_model.dart';
import '../../../customer/widgets/valve_widget_mobile.dart';
import 'customer_widget_builders.dart';

class IrrigationLineNarrow extends StatelessWidget {
  final int customerId, controllerId, modelId;
  final String deviceId;
  final List<ValveModel> valves;
  final List<MainValveModel> mainValves;
  final List<LightModel> lights;
  final List<FanModel> fans;
  final List<GateModel> gates;
  final List<FoggerModel> fogger;
  final List<SensorModel> pressureIn;
  final List<SensorModel> pressureOut;
  final List<SensorModel> waterMeter;
  final List<SensorModel> humidity;
  final List<SensorModel> co2;
  final List<SensorModel> temperature;
  final List<SensorModel> soilTemperature;

  const IrrigationLineNarrow({
    super.key,
    required this.valves,
    required this.mainValves,
    required this.lights,
    required this.fans,
    required this.gates,
    required this.fogger,
    required this.pressureIn,
    required this.pressureOut,
    required this.waterMeter,
    required this.co2,
    required this.humidity,
    required this.temperature,
    required this.soilTemperature,
    required this.customerId,
    required this.controllerId,
    required this.deviceId,
    required this.modelId,
  });

  @override
  Widget build(BuildContext context) {
    final baseSensors = [
      ...sensorList(sensors: pressureIn, type: 'Pressure Sensor',
          imagePath: 'assets/png/mobile/m_pressure_sensor.png', customerId: customerId, controllerId: controllerId),

      ...sensorList(sensors: pressureOut, type: 'Pressure Sensor',
          imagePath: 'assets/png/mobile/m_pressure_sensor.png', customerId: customerId, controllerId: controllerId),

      ...sensorList(sensors: waterMeter, type: 'Water Meter',
        imagePath: 'assets/png/mobile/m_water_meter.png', customerId: customerId, controllerId: controllerId),

      ...sensorList(sensors: humidity, type: 'Humidity Sensor',
          imagePath: 'assets/png/mobile/m_humidity_sensor.png', customerId: customerId, controllerId: controllerId),

      ...sensorList(sensors: co2, type: 'CO2 Sensor',
          imagePath: 'assets/png/mobile/m_Co2_sensor.png', customerId: customerId, controllerId: controllerId),

      ...sensorList(sensors: temperature, type: 'Temperature Sensor',
          imagePath: 'assets/png/mobile/m_temperature_sensor.png', customerId: customerId, controllerId: controllerId),

      ...sensorList(sensors: soilTemperature, type: 'Soil Temperature Sensor',
          imagePath: 'assets/png/mobile/m_soil_temperature.png', customerId: customerId, controllerId: controllerId),

    ];

    final allItems = [
      ...lightList(list: lights, isWide: false),
      ...fanList(list: fans, isWide: false),
      ...foggerList(list: fogger, isWide: false),

      ...mainValveList(list: mainValves, customerId: customerId,
        controllerId: controllerId, modelId: modelId, isNarrow: true),

      ...valveList(valves: valves, customerId: customerId,
        controllerId: controllerId, modelId: modelId, isNarrow: true, prsOutIsAval: false),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const itemWidth = 65.0;

        final itemsPerRow =
        (constraints.maxWidth / itemWidth).floor().clamp(1, 100);

        final rowHeight = itemsPerRow == 5 ? 58.0 : 65.0;

        final columns =
        (constraints.maxWidth / itemWidth).floor().clamp(1, 10);

        int usedCells = 0;

        for (var item in allItems) {
          final hasSource =
              item is ValveWidgetMobile && item.valve.waterSources.isNotEmpty;
          usedCells += hasSource ? 2 : 1;
        }

        final rows = (usedCells / columns).ceil();

        final gridItemWidth = constraints.maxWidth / columns;
        final gridItemHeight =
            gridItemWidth / (itemWidth / rowHeight);


        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (baseSensors.isNotEmpty) ...baseSensors,
            SizedBox(
              child: Stack(
                children: [
                  Positioned(
                    top: 3,
                    left: 5,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      child: Divider(
                        height: 5,
                        thickness: 3,
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ),

                  for (int r = 1; r <= rows; r++)
                    Positioned(
                      top: r * gridItemHeight + 3,
                      left: 5,
                      right: 0,
                      child: Column(
                        children: [
                          Divider(height: 5, color: Colors.grey.shade200, thickness: 3)
                        ],
                      ),
                    ),

                  Wrap(
                    alignment: WrapAlignment.start,
                    runAlignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: allItems.map((item) {
                      final bool hasSource =
                          item is ValveWidgetMobile && item.valve.waterSources.isNotEmpty;

                      return SizedBox(
                        width: hasSource ? gridItemWidth * 2 : gridItemWidth,
                        height: gridItemHeight,
                        child: item,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}