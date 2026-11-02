
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/Logs/view/valve_log.dart';
import 'package:oro_drip_irrigation/modules/PumpController/state_management/pump_controller_provider.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';

import '../../../models/customer/site_model.dart';
import '../../Preferences/widgets/custom_segmented_control.dart';
import '../widgets/custom_calendar_mobile.dart';
import '../widgets/time_line2.dart';

class PumpLogScreen extends StatefulWidget {
  final int userId,controllerId, nodeControllerId;
  final MasterControllerModel masterData;
  final bool showMobileCalendar;
  const PumpLogScreen({super.key, required this.userId, required this.controllerId, this.nodeControllerId = 0, required this.masterData, this.showMobileCalendar = false});

  @override
  State<PumpLogScreen> createState() => _PumpLogScreenState();
}

class _PumpLogScreenState extends State<PumpLogScreen> {
  bool showGraph = false;

  @override
  void initState() {
    super.initState();
    if(mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PumpControllerProvider>().getUserPumpLog(
          widget.userId,
          widget.controllerId,
          widget.nodeControllerId,
          widget.masterData,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final readProvider = context.read<PumpControllerProvider>();
    final watchProvider = context.watch<PumpControllerProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: [...AppConstants.ecoGemAndPlusModelList, ...AppConstants.gemModelList].contains(widget.masterData.modelId) ? AppBar(
        title: const Text('Pump log'),
      ) : PreferredSize(preferredSize: const Size(0, 0), child: Container()),
      body: SafeArea(
        child: Column(
          children: [
            if(kIsWeb ? widget.showMobileCalendar : true)
              MobileCustomCalendar(
                focusedDay: readProvider.focusedDay,
                calendarFormat: readProvider.calendarFormat,
                selectedDate: watchProvider.selectedDate,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    readProvider.selectedDate = selectedDay;
                    readProvider.focusedDay = focusedDay;
                  });
                  readProvider.getUserPumpLog(widget.userId, widget.controllerId, widget.nodeControllerId, widget.masterData);
                },
                onFormatChanged: (format) {
                  if (readProvider.calendarFormat != format) {
                    setState(() {
                      readProvider.calendarFormat = format;
                    });
                  }
                },
              ),
            const SizedBox(height: 10,),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, ),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if(readProvider.segments.isNotEmpty && readProvider.segments.length != 1)
                    CustomSegmentedControl(
                        segmentTitles: readProvider.segments,
                        groupValue: readProvider.selectedIndex,
                        onChanged: (newValue) {
                          setState(() {
                            readProvider.selectedIndex = newValue!;
                            readProvider.scrollController.animateTo(
                                readProvider.scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut
                            );
                          });
                        }
                    )
                  else
                    Container(),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  controller: readProvider.scrollController,
                  itemCount: watchProvider.pumpLogData.isNotEmpty ? watchProvider.pumpLogData.length : 1,
                  itemBuilder: (context, index) {
                    if(watchProvider.pumpLogData.isNotEmpty) {
                      final logData = watchProvider.pumpLogData[index];
                      if(AppConstants.pumpWithValveModelList.contains(widget.masterData.modelId) && !AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId)) {
                        return ValveLog(events: logData.motor1, masterData: widget.masterData,);
                      }
                      return Timeline2(
                        events: readProvider.selectedIndex == 1 ? logData.motor2 : readProvider.selectedIndex == 2 ? logData.motor3 : logData.motor1,
                        motorName: readProvider.segments[readProvider.selectedIndex],
                      );
                    } else {
                      return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(readProvider.message),
                              FilledButton(
                                  onPressed: (){
                                    readProvider.getUserPumpLog(widget.userId, widget.controllerId, widget.nodeControllerId, widget.masterData);
                                  },
                                  child: const Text("Reload")
                              )
                            ],
                          )
                      );
                    }
                  },
                ),
              )
            ),
          ],
        ),
      ),
    );
  }
}

