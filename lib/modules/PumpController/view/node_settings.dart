import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/Preferences/widgets/custom_segmented_control.dart';
import 'package:oro_drip_irrigation/modules/PumpController/view/set_serial.dart';

import '../../../models/customer/site_model.dart';
import 'lora_settings.dart';

class NodeSettings extends StatefulWidget {
  final int userId, controllerId, customerId;
  final List<NodeListModel> nodeList;
  final String deviceId;
  const NodeSettings({super.key, required this.nodeList, required this.deviceId, required this.userId, required this.controllerId, required this.customerId});

  @override
  State<NodeSettings> createState() => _NodeSettingsState();
}

class _NodeSettingsState extends State<NodeSettings> {
  int _groupValue = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 15,),
        CustomSegmentedControl(
            segmentTitles: const {
              0: "Node details",
              1: "Node settings",
            },
            groupValue: _groupValue,
            onChanged: (int? value) {
              setState(() {
                _groupValue = value!;
              });
            },
        ),
        if(_groupValue == 0)
          SetSerialScreen(
            nodeList: widget.nodeList,
            deviceId: widget.deviceId,
          )
        else
          GeneralScreen(
            deviceId: widget.deviceId,
            userId: widget.userId,
            controllerId: widget.controllerId,
            customerId: widget.customerId,
          )
      ],
    );
  }
}
