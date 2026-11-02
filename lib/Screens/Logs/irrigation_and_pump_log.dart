import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/irrigation_report/view/motor_cyclic_log.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../StateManagement/customer_provider.dart';
import '../../models/customer/site_model.dart';
import '../../modules/Logs/repository/log_repos.dart';
import '../../modules/Logs/view/pump_list.dart';
import '../../modules/irrigation_report/view/list_of_log_config.dart';
import '../../modules/irrigation_report/view/standalone_log.dart';
import '../../modules/irrigation_report/view/zone_cyclic_log.dart';
import '../../modules/irrigation_report/view/zone_log.dart';
import '../../services/http_service.dart';

class IrrigationAndPumpLog extends StatefulWidget {
  final Map<String, dynamic> userData;
  final MasterControllerModel masterData;
  const IrrigationAndPumpLog(
      {super.key, required this.userData, required this.masterData});

  @override
  State<IrrigationAndPumpLog> createState() => _IrrigationAndPumpLogState();
}

class _IrrigationAndPumpLogState extends State<IrrigationAndPumpLog>
    with TickerProviderStateMixin {
  late TabController tabController;
  List pumpList = [];
  String message = '';
  final LogRepository repository = LogRepository(HttpService());

  @override
  void initState() {
    tabController = TabController(length: _calculateTabLength(), vsync: this);
    getUserNodePumpList();
    super.initState();
  }

  int _calculateTabLength() {
    int length = 0;

    if (AppConstants.ecoGemAndPlusModelList
        .contains(widget.masterData.modelId)) {
      // Motor + Zone
      length = 2;
    } else {
      // Irrigation + Zone + Standalone
      length = 3;
    }

    // Pump Log
    if (!AppConstants.ecoGemAndPlusModelList
        .contains(widget.masterData.modelId)
        ? pumpList.isNotEmpty
        : true) {
      length += 1;
    }

    if (AppConstants.omsGemList.contains(widget.masterData.modelId)) {
      length = 1;
    }

    return length;
  }

  Future<void> getUserNodePumpList() async {
    final userData = {
      'userId': widget.userData['customerId'],
      'controllerId': widget.userData['controllerId']
    };
    final result = await repository.getUserNodePumpList(userData);
    setState(() {
      if (result.statusCode == 200 && jsonDecode(result.body)['data'] != null) {
        pumpList = jsonDecode(result.body)['data'];
        tabController =
            TabController(length: _calculateTabLength(), vsync: this);
      } else {
        message = jsonDecode(result.body)['message'];
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    tabController = TabController(
      length: _calculateTabLength(),
      vsync: this,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey(Provider.of<CustomerProvider>(context).controllerId),
      body: SafeArea(
        child: DefaultTabController(
          length: tabController.length,
          child: Column(
            children: [
              TabBar(
                controller: tabController,
                tabs: [
                  if (AppConstants.ecoGemAndPlusModelList
                      .contains(widget.masterData.modelId)) ...[
                    const Tab(text: "Motor Cyclic Log"),
                    const Tab(text: "Zone Cyclic Log"),
                  ] else ...[
                    const Tab(text: "Irrigation Log"),
                    const Tab(text: "Zone Log"),
                    const Tab(text: "Standalone Log"),
                  ],
                  if (!AppConstants.ecoGemAndPlusModelList
                          .contains(widget.masterData.modelId)
                      ? pumpList.isNotEmpty
                      : true)
                    const Tab(text: "Pump Log"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    if (AppConstants.ecoGemAndPlusModelList
                        .contains(widget.masterData.modelId)) ...[
                      MotorCyclicLog(userData: widget.userData),
                      ZoneCyclicLog(userData: widget.userData),
                    ] else ...[
                      ListOfLogConfig(
                        userData: widget.userData,
                        masterData: widget.masterData,
                      ),
                      ZoneLog(
                        userData: widget.userData,
                        masterData: widget.masterData,
                      ),
                      StandaloneLog(userData: widget.userData),
                    ],
                    if (!AppConstants.ecoGemAndPlusModelList
                            .contains(widget.masterData.modelId)
                        ? pumpList.isNotEmpty
                        : true) ...[
                      PumpList(
                        pumpList: pumpList,
                        userId: widget.userData['customerId'],
                        masterData: widget.masterData,
                        userData: widget.userData,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}