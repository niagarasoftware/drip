import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';

class ConnectionBanner extends StatelessWidget {
  final CustomerScreenControllerViewModel vm;
  final int commMode;

  const ConnectionBanner({super.key, required this.vm, required this.commMode});


  @override
  Widget build(BuildContext context) {
    if (commMode == 2) {
      return Container(
        width: double.infinity,
        color: Colors.black38,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: const Text(
          'Bluetooth mode enabled. Please ensure Bluetooth is connected.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.white70),
        ),
      );
    }else if (vm.isNotCommunicate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updatePayloadOnOffline(context);
      });
      return _buildBanner('NO COMMUNICATION TO CONTROLLER', Colors.red.shade300);
    }else if (vm.powerSupply == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updatePayloadOnOffline(context);
      });

      return _buildBanner('NO POWER SUPPLY TO CONTROLLER', Colors.red.shade300);
    }
    return const SizedBox();
  }

  Widget _buildBanner(String text, Color color) {
    return Container(
      height: 25,
      color: color,
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.white)),
    );
  }

  void _updatePayloadOnOffline(BuildContext context) {
    final master = vm.mySiteList.data[vm.sIndex].master[vm.mIndex];
    final LiveMessage? live = master.live;

    final LiveMessage? updatedLive = live?.update2402OnNoComm();

    Provider.of<MqttPayloadProvider>(context, listen: false)
        .updateReceivedPayload(
      jsonEncode(updatedLive?.toJson() ?? _defaultPayload()),
      true,
    );
  }

  String _defaultPayload() => '''
  {
    "cC": "00000000",
    "cM": {
      "WifiStrength": 0, "PowerSupply": 0
    },
    "cD": "0000-00-00",
    "cT": "00:00:00",
    "mC": "2400"
  }''';

}

extension LiveMessageOfflineUpdate on LiveMessage {
  LiveMessage update2402OnNoComm() {
    if (cM is! Map<String, dynamic>) return this;

    final updatedCM = Map<String, dynamic>.from(cM);

    if (!updatedCM.containsKey('2402')) return this;

    final raw = updatedCM['2402'];
    if (raw is! String || raw.isEmpty) return this;

    final updated2402 = raw
        .split(';')
        .map((entry) {
      final parts = entry.split(',');
      if (parts.length >= 2) {
        // force OFF
        parts[1] = '0';
      }
      return parts.join(',');
    })
        .join(';');

    updatedCM['2402'] = updated2402;

    return LiveMessage(
      cC: cC,
      cM: updatedCM,
      cD: cD,
      cT: cT,
      mC: mC,
    );
  }
}