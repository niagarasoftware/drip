import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import '../../../models/customer/site_model.dart';
import '../../../StateManagement/duration_notifier.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../utils/constants.dart';

class FilterSiteView extends StatelessWidget {
  final FilterSiteModel filterSite;
  final bool isMobile;
  const FilterSiteView({super.key, required this.filterSite, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            filterSite.pressureIn != null ?
            PressureSensorWidget(
              sensor: filterSite.pressureIn!, isMobile: isMobile,
            ):
            const SizedBox(),
            Padding(
              padding: const EdgeInsets.only(top: 1.9),
              child: SizedBox(
                height: kIsWeb ? 91:76,
                width: filterSite.filters.length * 70,
                child: ListView.builder(
                  itemCount: filterSite.filters.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int flIndex) {
                    final isLast = flIndex == filterSite.filters.length - 1;
                    return FilterWidget(filter: filterSite.filters[flIndex],
                      siteSno: filterSite.sNo.toString(), isMobile: isMobile,
                      isLast: isLast, sensorAvailable: filterSite.pressureIn != null);
                  },
                ),
              ),
            ),
            filterSite.pressureOut != null ?
            PressureSensorWidget(
              sensor: filterSite.pressureOut!, isMobile: isMobile,
            ):
            const SizedBox(),
          ],
        ),
        SizedBox(
          width: filterSite.pressureIn != null? filterSite.filters.length * 70+70:
          filterSite.filters.length * 70,
          height: 20,
          child: Center(
            child: Text(filterSite.name, style: TextStyle(color: Theme.of(context).primaryColorDark, fontSize: 11)),
          ),
        ),
      ],
    );
  }
}

class FilterWidget extends StatelessWidget {
  final Filters filter;
  final String siteSno;
  final bool isMobile;
  final bool isLast;
  final bool sensorAvailable;
  const FilterWidget({super.key, required this.filter, required this.siteSno,
    required this.isMobile, required this.isLast, required this.sensorAvailable});

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, Tuple2<String?, String?>>(
      selector: (_, provider) => Tuple2(
        provider.getFilterOnOffStatus(filter.sNo.toString()),
        provider.getFilterOtherData(siteSno),
      ),
      builder: (_, data, __) {
        final status = data.item1;
        final other = data.item2;

        final statusParts = status?.split(',') ?? [];
        final otherParts = other?.split(',') ?? [];

        if (statusParts.length > 1) {
          filter.status = int.tryParse(statusParts[1]) ?? 0;
        }

        if (otherParts.length >= 4) {
          filter.defPrsVal = otherParts[3];
        }

        int siteStatus = 0;

        if(filter.status==1){
          if (otherParts.length >= 4) {
            int value = int.parse(otherParts[1]);
            siteStatus = value < 0 ? 0 : value;
            filter.onDelayLeft = otherParts[2];

          }
        }else{
          if (otherParts.length >= 4) {
            if(otherParts[1]=='-1'){
              siteStatus = 1;
              filter.onDelayLeft = otherParts[2];
            }else{
              filter.onDelayLeft = '00:00:00';
            }
          }

        }

        return SizedBox(
          width: 70,
          height: 100,
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(width:70, height: 70, child: AppConstants.getAsset(isMobile ?
                  'mobile filter':'filter', filter.status,'${filter.filterMode}', 0)),
                  filter.onDelayLeft != '00:00:00' && siteStatus != 0 ?
                  Positioned(
                    top: 52,
                    left: 7.5,
                    child: Container(
                      width: 55,
                      decoration: BoxDecoration(
                        color:Colors.greenAccent,
                        borderRadius: const BorderRadius.all(Radius.circular(2)),
                        border: Border.all(color: Colors.grey, width: .50,),
                      ),
                      child: ChangeNotifierProvider(
                        create: (_) => DecreaseDurationNotifier(filter.onDelayLeft),
                        child: Stack(
                          children: [
                            Consumer<DecreaseDurationNotifier>(
                              builder: (context, durationNotifier, _) {
                                return Center(
                                  child: Text(durationNotifier.onDelayLeft,
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
                  ) :
                  const SizedBox(),
                  if(otherParts.length >= 4 && otherParts[1]=='-1')...[
                    Positioned(
                      top: 37,
                      left: 7.5,
                      child: Container(
                        width: 55,
                        decoration: BoxDecoration(
                          color:Colors.greenAccent,
                          borderRadius: const BorderRadius.all(Radius.circular(2)),
                          border: Border.all(color: Colors.grey, width: .50,),
                        ),
                        child: const Text('Start in',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  ],

                  if(isLast && sensorAvailable)...[
                    Positioned(
                      top: 0,
                      right: 2,
                      child: Container(
                        width: 35,
                        decoration: BoxDecoration(
                          color:Colors.yellow,
                          borderRadius: const BorderRadius.all(Radius.circular(2)),
                          border: Border.all(color: Colors.grey, width: .50),
                        ),
                        child: Text(filter.defPrsVal,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  ]
                ],
              ),
              Text(
                filter.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PressureSensorWidget extends StatelessWidget {
  final PressureSensor sensor;
  final bool isMobile;
  const PressureSensorWidget({
    super.key,
    required this.sensor, required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) => provider.getSensorUpdatedValve(sensor.sNo.toString()),
      builder: (_, status, __) {

        final statusParts = status?.split(',') ?? [];
        if(statusParts.isNotEmpty){
          sensor.value = statusParts[1];
        }

        return SizedBox(
          width: 70,
          height: 100,
          child: Column(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child : Stack(
                  children: [
                    Center(
                      child: Image.asset(isMobile ? 'assets/png/mobile/m_dp_prs_sensor.png':
                      'assets/png/dp_prs_sensor.png'),
                    ),
                    Positioned(
                      top: 42,
                      left: 5,
                      child: Container(
                        width: 60,
                        height: 17,
                        decoration: BoxDecoration(
                          color:Colors.yellow,
                          borderRadius: const BorderRadius.all(Radius.circular(2)),
                          border: Border.all(color: Colors.grey, width: .50,),
                        ),
                        child: Center(
                          child: Text('${sensor.value} bar', style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(sensor.name, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
              )
            ],
          ),
        );
      },
    );
  }

}
