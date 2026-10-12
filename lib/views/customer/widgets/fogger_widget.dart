import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';

class FoggerWidget extends StatelessWidget {
  final FoggerModel objFogger;
  final bool isWide;
  const FoggerWidget({super.key, required this.objFogger, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getFanOnOffStatus(objFogger.sNo.toString()),
      builder: (_, status, __) {

        final statusParts = status?.split(',') ?? [];
        if(statusParts.isNotEmpty){
          objFogger.status = int.parse(statusParts[1]);
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
                child: AppConstants.getAsset(isWide ? 'fogger' : 'fogger_mbl', objFogger.status, '', 0),
              ),
              Text(
                objFogger.name,
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