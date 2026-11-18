import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/customer/site_model.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../utils/constants.dart';

class AgitatorWidget extends StatelessWidget {
  final FertilizerSiteModel fertilizerSite;
  final bool isMobile;

  const AgitatorWidget({
    super.key,
    required this.fertilizerSite,
    required this.isMobile,
  });

  // Fixed frame height for the agitator area.
  // Change this value according to your UI.
  static const double frameHeight = 130.0;

  @override
  Widget build(BuildContext context) {
    if (fertilizerSite.agitator.isEmpty) {
      return const SizedBox.shrink();
    }

    return Selector<MqttPayloadProvider, String>(
      selector: (_, provider) {
        final statuses = <String>[];
        for (final agitator in fertilizerSite.agitator) {
          final status = provider.getAgitatorOnOffStatus(agitator.sNo.toString());
          statuses.add(status ?? '');
        }
        return statuses.join('|');
      },
      builder: (_, status, __) {
        _updateAgitatorStatuses(status);

        return SizedBox(
          width: 53,
          height: frameHeight,
          child: Stack(
            children: [
              // AGITATORS - Always start from TOP
              Positioned(
                top: 0,
                left: 0,
                child: agitatorWidget(),
              ),
              // BOTTOM LINES - Always stay at the same bottom position
              if (kIsWeb && !isMobile)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 53, height: 1, color: Colors.grey.shade300),
                      const SizedBox(height: 3.5),
                      Container(width: 53, height: 1, color: Colors.grey.shade300),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // UPDATE ALL AGITATOR STATUS
  void _updateAgitatorStatuses(String status) {
    if (status.isEmpty) return;

    final statusList = status.split('|');
    for (int i = 0; i < statusList.length && i < fertilizerSite.agitator.length; i++) {
      final agitatorStatus = statusList[i];
      if (agitatorStatus.isEmpty) continue;

      final statusParts = agitatorStatus.split(',');
      if (statusParts.length > 1) {
        final statusValue = int.tryParse(statusParts[1]);
        if (statusValue != null) {
          fertilizerSite.agitator[i].status = statusValue;
        }
      }
    }
  }

  // DISPLAY ALL AGITATORS VERTICALLY
  Widget agitatorWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fertilizerSite.agitator.map((agitator) {
        final height = agitator.status == 1 ? 99.0 : 34.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 53,
              height: height,
              child: AppConstants.getAsset('agitator', agitator.status, '', 0),
            ),
            SizedBox(
              width: 53,
              child: Text(
                agitator.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: Colors.black),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/*
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../utils/constants.dart';

class AgitatorWidget extends StatelessWidget {
  final FertilizerSiteModel fertilizerSite;
  final bool isMobile;
  const AgitatorWidget({
    super.key,
    required this.fertilizerSite, required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getAgitatorOnOffStatus(fertilizerSite.agitator[0].sNo.toString()),
      builder: (_, status, __) {

        final statusParts = status?.split(',') ?? [];
        if(statusParts.isNotEmpty){
          fertilizerSite.agitator[0].status = int.parse(statusParts[1]);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [

            agitatorWidget(fertilizerSite),

            if(kIsWeb && !isMobile)...[
              SizedBox(height: fertilizerSite.agitator[0].status==1? 25:90),
              Container(width: 53, height: 1,color: Colors.grey.shade300),
              const SizedBox(height: 3.5),
              Container(width: 53, height: 1,color: Colors.grey.shade300),
            ]
          ],
        );
      },
    );
  }

  Widget agitatorWidget(FertilizerSiteModel fertilizerSite) {
    final agitator = fertilizerSite.agitator[0];
    final height = agitator.status == 1 ? 99.0 : 34.0;

    Widget content = SizedBox(
      width: 53,
      height: height,
      child: AppConstants.getAsset(
        'agitator',
        agitator.status,
        '',
        0,
      ),
    );

    return content;
  }

}*/
