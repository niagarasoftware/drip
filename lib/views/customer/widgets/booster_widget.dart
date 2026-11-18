import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../utils/constants.dart';

class BoosterWidget extends StatelessWidget {
  final FertilizerSiteModel fertilizerSite;
  final bool isMobile;
  const BoosterWidget({
    super.key,
    required this.fertilizerSite, required this.isMobile
  });

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getBoosterPumpOnOffStatus(fertilizerSite.boosterPump[0].sNo.toString()),
      builder: (_, status, __) {

        final statusParts = status?.split(',') ?? [];
        if(statusParts.isNotEmpty){
          fertilizerSite.boosterPump[0].status = int.parse(statusParts[1]);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
                width: 70,
                height: 119,
                child : Stack(
                  children: [
                    AppConstants.getAsset('booster', fertilizerSite.boosterPump[0].status,'', 0),

                    Positioned(
                      top: 85,
                      left: 18,
                      child: fertilizerSite.selector.isNotEmpty ? Container(
                        decoration: BoxDecoration(
                          color: fertilizerSite.selector[0].status == 0? Colors.grey.shade300:
                          fertilizerSite.selector[0].status == 1? Colors.greenAccent:
                          fertilizerSite.selector[0].status == 2? Colors.orangeAccent:Colors.redAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        width: 50,
                        height: 25,
                        child: Center(
                          child: Text(fertilizerSite.selector[0].name , style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.normal,
                          )),
                        ),
                      ):
                      const SizedBox(),
                    ),
                    Positioned(
                      top: 50,
                      left: 18,
                      child: fertilizerSite.ec!.isNotEmpty ?
                      Selector<MqttPayloadProvider, String?>(
                        selector: (_, provider) => provider.getSensorUpdatedValve(fertilizerSite.ec![0].sNo.toString()),
                        builder: (_, status, __) {
                          final statusParts = status?.split(',') ?? [];
                          if (statusParts.isNotEmpty) {
                            fertilizerSite.ec![0].value = statusParts[1];
                          }

                          return SizedBox(
                            width: 55,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Center(child: Text('Ec : ', style: TextStyle(fontSize: 10, color: Colors.black45))),
                                Center(
                                  child: Text(
                                    double.parse('${fertilizerSite.ec?[0].value}')
                                        .toStringAsFixed(2),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 5,),
                              ],
                            ),
                          );
                        },
                      ) :
                      const SizedBox(),
                    ),
                    Positioned(
                      top: 63,
                      left: 18,
                      child: fertilizerSite.ph!.isNotEmpty ? Selector<MqttPayloadProvider, String?>(
                        selector: (_, provider) => provider.getSensorUpdatedValve(fertilizerSite.ph![0].sNo.toString()),
                        builder: (_, status, __) {
                          final statusParts = status?.split(',') ?? [];
                          if (statusParts.isNotEmpty) {
                            fertilizerSite.ph![0].value = statusParts[1];
                          }

                          return SizedBox(
                            width: 55,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Center(child: Text('pH : ', style: TextStyle(fontSize: 10, color: Colors.black45))),
                                Center(
                                  child: Text(
                                    double.parse('${fertilizerSite.ph?[0].value}')
                                        .toStringAsFixed(2),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 5,),
                              ],
                            ),
                          );
                        },
                      ) :
                      const SizedBox(),
                    ),
                  ],
                )
            ),

            if(!isMobile)...[
              if(kIsWeb)...[
                SizedBox(
                  width: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width:10),
                      SizedBox(
                        width:6.5,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 1, height: 10,color: Colors.grey.shade300),
                            const SizedBox(width: 3.5),
                            Container(width: 1, height: 6.5,color: Colors.grey.shade300),
                          ],
                        ),
                      ),
                      SizedBox(
                        width : 53.5,
                        child: Column(
                          children: [
                            const SizedBox(height: 5),
                            Container(width: 53.5, height: 1,color: Colors.grey.shade300),
                            const SizedBox(height: 3.5),
                            Container(width: 53.5, height: 1,color: Colors.grey.shade300),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ]
          ],
        );
      },
    );
  }
}