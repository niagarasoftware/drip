import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import '../../../models/customer/site_model.dart';
import '../../../StateManagement/duration_notifier.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../utils/constants.dart';


class ChannelWidget extends StatelessWidget {
  final Channel channel;
  final int cIndex, channelLength;
  final List<Agitator> agitator;
  final String siteSno;
  final bool isMobile;
  const ChannelWidget({super.key, required this.channel, required this.cIndex,
    required this.channelLength, required this.agitator, required this.siteSno,
    required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, Tuple2<String?, String?>>(
      selector: (_, provider) => Tuple2(
        provider.getChannelOnOffStatus(channel.sNo.toString()),
        provider.getChannelOtherData(channel.sNo.toString()),
      ),

      builder: (_, data, __) {
        final status = data.item1;
        final other = data.item2;

        final statusParts = status?.split(',') ?? [];
        if (statusParts.length > 1) {
          channel.status = int.tryParse(statusParts[1]) ?? 0;
        }

        final otherParts = other?.split(',') ?? [];
        if (otherParts.isNotEmpty) {
          channel.frtMethod = otherParts[1];
          channel.duration = otherParts[2];
          channel.completedDrQ = otherParts[3];
          channel.onTime = otherParts[4];
          channel.offTime = otherParts[5];
          channel.flowRateLpH = otherParts[6];
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 70,
              height: 120,
              child: Stack(
                children: [
                  Image.asset(AppConstants.getFertilizerChannelImage(cIndex, channel.status,
                      channelLength, agitator, isMobile)),
                  Positioned(
                    top: 52,
                    left: 6,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.teal.shade100,
                      child: Text('${cIndex+1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      width: 60,
                      child: Center(
                        child: Text(channel.duration, style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 65,
                    left: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      width: 60,
                      child: Center(
                        child: Text('${channel.flowRateLpH}-lph', style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                      ),
                    ),
                  ),
                  if (channel.dosingMeter.isNotEmpty)
                    Positioned(
                      top: 78,
                      left: 18,
                      child: SizedBox(
                        width: 60,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final dm in channel.dosingMeter)
                              _DosingMeterValue(meter: dm),
                          ],
                        ),
                      ),
                    ),
                  channel.status == 1 && channel.completedDrQ !='00:00:00' ?
                  Positioned(
                    top: 97,
                    left: 0,
                    child: Container(
                      width: 55,
                      decoration: BoxDecoration(
                        color:Colors.greenAccent,
                        borderRadius: const BorderRadius.all(Radius.circular(2)),
                        border: Border.all(color: Colors.grey, width: .50,),
                      ),
                      child: ChangeNotifierProvider(
                        create: (_) => IncreaseDurationNotifier(channel.duration, channel.completedDrQ, double.parse(channel.flowRateLpH)),
                        child: Stack(
                          children: [
                            Consumer<IncreaseDurationNotifier>(
                              builder: (context, durationNotifier, _) {
                                return Center(
                                  child: Text(channel.frtMethod=='1' || channel.frtMethod=='3'?
                                  durationNotifier.onCompletedDrQ :
                                  '${durationNotifier.onCompletedDrQ} L',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ):
                  const SizedBox(),
                ],
              ),
            ),

            if(!isMobile)...[
              if(kIsWeb)...[
                const SizedBox(height: 4),
                Container(width: 70, height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 3.5),
                Container(width: 70, height: 1, color: Colors.grey.shade300),
              ]
            ]
          ],
        );
      },
    );
  }
}

class _DosingMeterValue extends StatelessWidget {
  final DosingMeterModel meter;
  const _DosingMeterValue({required this.meter});

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getSensorUpdatedValve(meter.sNo.toString()),
      builder: (_, data, __) {
        final parts = data?.split(',') ?? [];
        if (parts.length > 1) {
          meter.value = parts[1];
        }

        return Tooltip(
          message: meter.name,
          child: Container(
            height: 14,
            width: 60,
            margin: const EdgeInsets.only(bottom: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey.shade200, width: .5),
            ),
            child: Center(
              child: Text(
                '${meter.value} - lpm',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}