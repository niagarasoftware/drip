import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/Logs/view/power_graph_screen.dart';
import 'package:oro_drip_irrigation/modules/Logs/view/pump_log.dart';
import 'package:oro_drip_irrigation/modules/Logs/view/valve_log_screen.dart';
import 'package:oro_drip_irrigation/modules/Logs/view/voltage_log.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';

import '../../../models/customer/site_model.dart';

class PumpLogsHome extends StatefulWidget {
  final int userId, controllerId;
  final MasterControllerModel masterData;
  const PumpLogsHome({super.key, required this.userId, required this.controllerId, required this.masterData});

  @override
  State<PumpLogsHome> createState() => _PumpLogsHomeState();
}

class _PumpLogsHomeState extends State<PumpLogsHome> with TickerProviderStateMixin{
  late TabController tabController;
  late final bool isPumpWithValveModel;

  @override
  void initState() {
    super.initState();
    isPumpWithValveModel = AppConstants.pumpWithValveModelList.contains(widget.masterData.modelId) &&
        !AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId);
    tabController = TabController(length: isPumpWithValveModel ? 4 : 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key : ValueKey(widget.controllerId),
      child: Scaffold(
        body: SafeArea(
            child: DefaultTabController(
                length: isPumpWithValveModel ? 4 : 3,
                child: Column(
                  children: [
                    TabBar(
                        tabs: [
                          const Tab(text: "Pump log"),
                          if (isPumpWithValveModel)
                            const Tab(text: "Valve log"),
                          const Tab(text: "Power graph"),
                          const Tab(text: "Voltage log"),
                        ]
                    ),
                    Expanded(
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                            children: [
                              PumpLogScreen(
                                userId: widget.userId,
                                controllerId: widget.controllerId,
                                masterData: widget.masterData,
                              ),
                              if (isPumpWithValveModel)
                                ValveLogScreen(
                                  userId: widget.userId,
                                  controllerId: widget.controllerId,
                                  masterData: widget.masterData,
                                ),
                              PowerGraphScreen(userId: widget.userId, controllerId: widget.controllerId, masterData: widget.masterData,),
                              PumpVoltageLogScreen(userId: widget.userId, controllerId: widget.controllerId, masterData: widget.masterData,),
                            ]
                        )
                    )
                  ],
                )
            )
        ),
      ),
    );
  }
}
