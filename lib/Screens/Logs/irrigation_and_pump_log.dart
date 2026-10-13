import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:oro_drip_irrigation/utils/constants.dart';

import '../../StateManagement/customer_provider.dart';
import '../../models/customer/site_model.dart';
import '../../modules/Logs/repository/log_repos.dart';
import '../../modules/Logs/view/pump_list.dart';

import '../../modules/irrigation_report/view/channel_log_page.dart';
import '../../modules/irrigation_report/view/list_of_log_config.dart';
import '../../modules/irrigation_report/view/standalone_log.dart';
import '../../modules/irrigation_report/view/zone_log.dart';
import '../../modules/irrigation_report/view/zone_cyclic_log.dart';
import '../../modules/irrigation_report/view/motor_cyclic_log.dart';

import '../../services/http_service.dart';

class IrrigationAndPumpLog extends StatefulWidget {
  final Map<String, dynamic> userData;
  final MasterControllerModel masterData;

  const IrrigationAndPumpLog({
    super.key,
    required this.userData,
    required this.masterData,
  });

  @override
  State<IrrigationAndPumpLog> createState() =>
      _IrrigationAndPumpLogState();
}

class _IrrigationAndPumpLogState
    extends State<IrrigationAndPumpLog>
    with SingleTickerProviderStateMixin {

  late TabController tabController;

  List pumpList = [];

  String message = '';

  final LogRepository repository =
  LogRepository(HttpService());

  // Channel Log data
  List<ChannelLogRecord> channelLogData = [];

  bool get isEcoGem =>
      AppConstants.ecoGemAndPlusModelList
          .contains(widget.masterData.modelId);

  bool get isOmsGem =>
      AppConstants.omsGemList
          .contains(widget.masterData.modelId);

  bool get showPumpLog =>
      isEcoGem || pumpList.isNotEmpty;

  int _calculateTabLength() {
    if (isOmsGem) {
      return 1;
    }

    if (isEcoGem) {
      return 3; // Motor + Zone Cyclic + Pump
    }

    // Irrigation + Zone + Standalone + Channel
    // + optional Pump
    return 4 + (showPumpLog ? 1 : 0);
  }

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: _calculateTabLength(),
      vsync: this,
    );

    getUserNodePumpList();
  }

  void _updateTabController() {
    final newLength = _calculateTabLength();

    if (tabController.length == newLength) {
      return;
    }

    final oldController = tabController;

    final oldIndex = oldController.index;

    tabController = TabController(
      length: newLength,
      vsync: this,
      initialIndex: oldIndex < newLength
          ? oldIndex
          : newLength - 1,
    );

    oldController.dispose();
  }

  Future<void> getUserNodePumpList() async {
    try {
      final userData = {
        'userId': widget.userData['customerId'],
        'controllerId':
        widget.userData['controllerId'],
      };

      final result =
      await repository.getUserNodePumpList(
        userData,
      );

      if (!mounted) return;

      final response = jsonDecode(result.body);

      setState(() {
        if (result.statusCode == 200 &&
            response['data'] is List) {
          pumpList = response['data'];
          message = '';
        } else {
          pumpList = [];
          message =
              response['message']?.toString() ?? '';
        }

        _updateTabController();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = e.toString();
      });

      debugPrint('Pump list error: $e');
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Tab> tabs = [];
    final List<Widget> pages = [];

    if (isOmsGem) {
      // Preserve the single-tab behavior for OMS models.
      // Replace this page if your OMS model uses
      // a different dedicated log screen.
      tabs.add(
        const Tab(text: 'Irrigation Log'),
      );

      pages.add(
        ListOfLogConfig(
          userData: widget.userData,
          masterData: widget.masterData,
        ),
      );
    } else if (isEcoGem) {
      tabs.addAll([
        const Tab(text: 'Motor Cyclic Log'),
        const Tab(text: 'Zone Cyclic Log'),
        const Tab(text: 'Pump Log'),
      ]);

      pages.addAll([
        MotorCyclicLog(
          userData: widget.userData,
        ),
        ZoneCyclicLog(
          userData: widget.userData,
        ),
        PumpList(
          pumpList: pumpList,
          userId: widget.userData['customerId'],
          masterData: widget.masterData,
          userData: widget.userData,
        ),
      ]);
    } else {
      tabs.addAll([
        const Tab(text: 'Irrigation Log'),
        const Tab(text: 'Zone Log'),
        const Tab(text: 'Standalone Log'),
        // const Tab(text: 'Channel Log'),
      ]);

      pages.addAll([
        ListOfLogConfig(
          userData: widget.userData,
          masterData: widget.masterData,
        ),

        ZoneLog(
          userData: widget.userData,
          masterData: widget.masterData,
        ),

        StandaloneLog(
          userData: widget.userData,
        ),

        // ChannelLogPage(
        //   logs: channelLogData,
        // ),
      ]);

      if (showPumpLog) {
        tabs.add(
          const Tab(text: 'Pump Log'),
        );

        pages.add(
          PumpList(
            pumpList: pumpList,
            userId: widget.userData['customerId'],
            masterData: widget.masterData,
            userData: widget.userData,
          ),
        );
      }
    }

    return Scaffold(
      key: ValueKey(
        Provider.of<CustomerProvider>(context)
            .controllerId,
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor:
              const Color(0xFF006775),
              unselectedLabelColor:
              Colors.grey,
              indicatorColor:
              const Color(0xFF006775),
              tabs: tabs,
            ),

            Expanded(
              child: TabBarView(
                controller: tabController,
                children: pages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}