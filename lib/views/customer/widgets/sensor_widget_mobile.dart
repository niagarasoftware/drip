import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

import '../../../models/customer/site_model.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../utils/my_function.dart';
import '../../common/user_dashboard/widgets/sensor_popover_content.dart';

class SensorWidgetMobile extends StatelessWidget {
  final SensorModel sensor;
  final String sensorType;
  final String imagePath;
  final int customerId, controllerId;

  const SensorWidgetMobile({
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

        return ListTile(
          minVerticalPadding: 0,
          minLeadingWidth: 0,
          horizontalTitleGap: 8,
          contentPadding: const EdgeInsets.only(left: 6, right: 12),
          visualDensity: const VisualDensity(vertical: -4),

          leading: sensorType == 'Pressure Switch' ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 25,
                height: 25,
                child: Image(image: AssetImage('assets/png/mobile/m_pressure_switch.png')),
              ),
              const SizedBox(width: 5),
              _statusBox(sensor),
            ],
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () async {

                  showPopover(
                    context: context,
                    bodyBuilder: (context) => SensorPopoverContent(
                      sensor: sensor,
                      sensorType: sensorType,
                      customerId: customerId,
                      controllerId: controllerId,
                    ),
                    direction: PopoverDirection.top,
                    width: MediaQuery.sizeOf(context).width-26,
                    height: 310,
                    arrowHeight: 15,
                    arrowWidth: 30,
                    barrierColor: Colors.black54,
                    arrowDyOffset: -5,
                    arrowDxOffset: -180,
                  );
                },
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                  minimumSize: WidgetStateProperty.all(Size.zero),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: Image.asset(imagePath, width: 40, height: 40),
              ),
              const SizedBox(width: 5),
              _unitBox(context, sensor, sensorType),
            ],
          ),

          title: Text(
            sensor.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        );
      },
    );
  }

  Widget _statusBox(SensorModel sensor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: sensor.value == "1" ? Colors.green.shade300 : Colors.red.shade300,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Text(
        sensor.value == "1" ? 'Low' : 'High',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _unitBox(BuildContext context, SensorModel sensor, String sensorType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.yellow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Text(
        MyFunction()
            .getUnitByParameter(context, sensorType, sensor.value.toString()) ??
            '',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}