import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../models/customer/site_model.dart';

class FloatSwitchPopover extends StatelessWidget {
  final WaterSourceModel source;
  final ValueNotifier<int> popoverUpdateNotifier;
  final bool isMobile;

  const FloatSwitchPopover({
    super.key,
    required this.source,
    required this.popoverUpdateNotifier,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {

    return Consumer<MqttPayloadProvider>(
      builder: (_, provider, __) {

        final floatSwitches = source.floatSwitches;

        return Stack(
          children: floatSwitches.map((fs) {
            final update = provider.getSensorUpdatedValve(fs.sNo.toString());
            final parts = update?.split(',') ?? [];
            final status = parts.length > 2 ? parts[1] : null;
            final text = status == '0' ? 'Low' : 'High';

            if (fs.value == "topFloatForInletPump") {
              return Positioned(
                top: isMobile ? 13 : 15,
                left: isMobile ? 10 : 13,
                child: _buildFloatSwitchIcon(text),
              );
            }
            else if (fs.value == "bottomFloatForInletPump") {
              return Positioned(
                top: isMobile ? 33 : 35,
                left: isMobile ? 14.5 : 17.5,
                child: _buildFloatSwitchIcon(text),
              );
            }
            else if (fs.value == "topFloatForOutletPump") {
              return Positioned(
                top: isMobile ? 13 : 15,
                left: isMobile ? 39 : 42,
                child: _buildFloatSwitchIcon(text),
              );
            } else {
              return Positioned(
                top: isMobile ? 33 : 35,
                left: isMobile ? 34 : 37,
                child: _buildFloatSwitchIcon(text),
              );
            }
          }).toList(),
        );
      },
    );

  }

  Widget _buildFloatSwitchIcon(String text) {

    return SizedBox(
      width: 25,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/png/float_switch.png',
            width: 15,
            height: 15,
          ),
          Positioned(
            top : 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: text == 'Low'? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}