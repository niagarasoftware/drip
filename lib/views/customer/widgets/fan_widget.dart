import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';

class FanWidget extends StatelessWidget {
  final FanModel objFan;
  final bool isWide;
  const FanWidget({super.key, required this.objFan, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getFanOnOffStatus(objFan.sNo.toString()),
      builder: (_, status, __) {

        final statusParts = status?.split(',') ?? [];
        if(statusParts.isNotEmpty){
          objFan.status = int.parse(statusParts[1]);
        }

        return SizedBox(
          width: 70,
          height: isWide? 100 : 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: isWide? 70 : 43,
                height: isWide? 70 : 43,
                child: AppConstants.getAsset(isWide ? 'fan' : 'fan_mbl', objFan.status, '', 0),
              ),
              Text(
                objFan.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }

}