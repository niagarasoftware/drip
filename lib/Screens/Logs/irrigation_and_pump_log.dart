import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:oro_drip_irrigation/utils/constants.dart';

import '../../StateManagement/customer_provider.dart';
import '../../models/customer/site_model.dart';
import '../../modules/Logs/repository/log_repos.dart';
import 'package:oro_drip_irrigation/modules/Logs/view/pump_log_dashboard.dart';

import '../../modules/irrigation_report/view/channel_log_page.dart';
import '../../modules/irrigation_report/view/list_of_log_config.dart';
import '../../modules/irrigation_report/view/standalone_log.dart';
import '../../modules/irrigation_report/view/zone_log.dart';
import '../../modules/irrigation_report/view/zone_cyclic_log.dart';
import '../../modules/irrigation_report/view/motor_cyclic_log.dart';

import '../../services/http_service.dart';
import '../../view_models/customer/customer_screen_controller_view_model.dart';

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

  void _openLogDetail(BuildContext context, _LogCardItem card) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(card.title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: card.page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Tab> tabs = [];
    final List<Widget> pages = [];

    if (isOmsGem) {
      cards.add(
        _LogCardItem(
          title: 'Irrigation Log',
          subtitle:
              'View detailed records of irrigation cycles, water usage and duration for each zone.',
          iconWidget: const Icon(
            Icons.water_drop_outlined,
            color: Color(0xFF0284C7),
            size: 28,
          ),
          accentColor: const Color(0xFF0284C7),
          iconBgColor: const Color(0xFFE0F2FE),
          buttonColor: const Color(0xFF278EA5),
          features: const [
            _FeatureBullet(
              icon: Icons.access_time_rounded,
              text: 'Irrigation start & stop times',
              iconColor: Color(0xFF0284C7),
            ),
            _FeatureBullet(
              icon: Icons.water_drop_outlined,
              text: 'Water usage data',
              iconColor: Color(0xFF0284C7),
            ),
            _FeatureBullet(
              icon: Icons.schedule_rounded,
              text: 'Duration & frequency',
              iconColor: Color(0xFF0284C7),
            ),
            _FeatureBullet(
              icon: Icons.bar_chart_rounded,
              text: 'Zone-wise details',
              iconColor: Color(0xFF0284C7),
            ),
          ],
          page: ListOfLogConfig(
            userData: widget.userData,
            masterData: widget.masterData,
          ),
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
        PumpLogDashboardScreen(
          pumpList: pumpList,
          userId: widget.userData['customerId'],
          controllerId: widget.masterData.controllerId,
          masterData: widget.masterData,
          userData: widget.userData,
      cards.addAll([
        _LogCardItem(
          title: 'Motor Cyclic Log',
          subtitle:
              'Track cyclic motor operations, runtime intervals and status logs.',
          iconWidget: const Icon(
            Icons.sync_rounded,
            color: Color(0xFF0284C7),
            size: 28,
          ),
          accentColor: const Color(0xFF0284C7),
          iconBgColor: const Color(0xFFE0F2FE),
          buttonColor: const Color(0xFF278EA5),
          features: const [
            _FeatureBullet(
              icon: Icons.access_time_rounded,
              text: 'Motor runtime & duration',
              iconColor: Color(0xFF0284C7),
            ),
            _FeatureBullet(
              icon: Icons.play_arrow_outlined,
              text: 'Start & stop intervals',
              iconColor: Color(0xFF0284C7),
            ),
            _FeatureBullet(
              icon: Icons.schedule_rounded,
              text: 'Cycle frequency',
              iconColor: Color(0xFF0284C7),
            ),
            _FeatureBullet(
              icon: Icons.bar_chart_rounded,
              text: 'Motor-wise details',
              iconColor: Color(0xFF0284C7),
            ),
          ],
          page: MotorCyclicLog(userData: widget.userData),
        ),
        _LogCardItem(
          title: 'Zone Cyclic Log',
          subtitle:
              'Monitor zone-wise cyclic irrigation status, flow and runtime information.',
          iconWidget: const Icon(
            Icons.pin_drop_outlined,
            color: Color(0xFF16A34A),
            size: 28,
          ),
          accentColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFDCFCE7),
          buttonColor: const Color(0xFF2E8B57),
          features: const [
            _FeatureBullet(
              icon: Icons.grid_view_rounded,
              text: 'Zone cyclic activity',
              iconColor: Color(0xFF16A34A),
            ),
            _FeatureBullet(
              icon: Icons.device_hub_rounded,
              text: 'Valve sequence events',
              iconColor: Color(0xFF16A34A),
            ),
            _FeatureBullet(
              icon: Icons.waves_rounded,
              text: 'Flow rate & duration',
              iconColor: Color(0xFF16A34A),
            ),
            _FeatureBullet(
              icon: Icons.access_time_rounded,
              text: 'Runtime per zone',
              iconColor: Color(0xFF16A34A),
            ),
          ],
          page: ZoneCyclicLog(userData: widget.userData),
        ),
        _LogCardItem(
          title: 'Pump Log',
          subtitle:
              'Track pump operations, start/stop events, runtime and fault history.',
          iconWidget: SvgPicture.asset(
            'assets/svg_images/pump.svg',
            width: 26,
            height: 26,
            colorFilter:
                const ColorFilter.mode(Color(0xFFEA580C), BlendMode.srcIn),
          ),
          accentColor: const Color(0xFFEA580C),
          iconBgColor: const Color(0xFFFFEDD5),
          buttonColor: const Color(0xFFF38220),
          features: const [
            _FeatureBullet(
              icon: Icons.play_arrow_outlined,
              text: 'Start / Stop events',
              iconColor: Color(0xFFEA580C),
            ),
            _FeatureBullet(
              icon: Icons.access_time_rounded,
              text: 'Runtime & total hours',
              iconColor: Color(0xFFEA580C),
            ),
            _FeatureBullet(
              icon: Icons.warning_amber_rounded,
              text: 'Fault / alarm history',
              iconColor: Color(0xFFEA580C),
            ),
            _FeatureBullet(
              icon: Icons.trending_up_rounded,
              text: 'Performance trends',
              iconColor: Color(0xFFEA580C),
            ),
          ],
          page: PumpList(
            pumpList: pumpList,
            userId: widget.userData['customerId'],
            masterData: widget.masterData,
            userData: widget.userData,
          ),
        ),
      ]);
    } else {
      cards.addAll([
        _LogCardItem(
          title: 'Irrigation Log',
          subtitle:
              'View detailed records of irrigation cycles, water usage and duration for each zone.',
          iconWidget: const Icon(
            Icons.water_drop_outlined,
            color: Color(0xFF0284C7),
            size: 28,
          ),
          accentColor: const Color(0xFF0284C7),
          iconBgColor: const Color(0xFFE0F2FE),
          buttonColor: const Color(0xFF278EA5),
          features: const [
            _FeatureBullet(
              icon: Icons.access_time_rounded,
              text: 'Irrigation start & stop times',
              iconColor: Color(0xFF0284C7),
            ),
            _FeatureBullet(
              icon: Icons.water_drop_outlined,
              text: 'Water usage data',
              iconColor: Color(0xFF0284C7),
            ),
            _FeatureBullet(
              icon: Icons.schedule_rounded,
              text: 'Duration & frequency',
              iconColor: Color(0xFF0284C7),
            ),
            _FeatureBullet(
              icon: Icons.bar_chart_rounded,
              text: 'Zone-wise details',
              iconColor: Color(0xFF0284C7),
            ),
          ],
          page: ListOfLogConfig(
            userData: widget.userData,
            masterData: widget.masterData,
          ),
        ),
        _LogCardItem(
          title: 'Cumulative Log',
          subtitle:
              'Monitor zone-wise cumulative activities, including valve status, flow and runtime information.',
          iconWidget: const Icon(
            Icons.pin_drop_outlined,
            color: Color(0xFF16A34A),
            size: 28,
          ),
          accentColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFDCFCE7),
          buttonColor: const Color(0xFF2E8B57),
          features: const [
            _FeatureBullet(
              icon: Icons.grid_view_rounded,
              text: 'Zone status & activity',
              iconColor: Color(0xFF16A34A),
            ),
            _FeatureBullet(
              icon: Icons.device_hub_rounded,
              text: 'Valve open/close events',
              iconColor: Color(0xFF16A34A),
            ),
            _FeatureBullet(
              icon: Icons.waves_rounded,
              text: 'Flow rate & volume',
              iconColor: Color(0xFF16A34A),
            ),
            _FeatureBullet(
              icon: Icons.access_time_rounded,
              text: 'Runtime per zone',
              iconColor: Color(0xFF16A34A),
            ),
          ],
          page: ZoneLog(
            userData: widget.userData,
            masterData: widget.masterData,
          ),
        ),
        _LogCardItem(
          title: 'Standalone Log',
          subtitle:
              'Access logs for standalone devices such as pumps, filters and other independent units.',
          iconWidget: const Icon(
            Icons.developer_board_rounded,
            color: Color(0xFF6D28D9),
            size: 28,
          ),
          accentColor: const Color(0xFF6D28D9),
          iconBgColor: const Color(0xFFEDE9FE),
          buttonColor: const Color(0xFF5E50D6),
          features: const [
            _FeatureBullet(
              icon: Icons.precision_manufacturing_outlined,
              text: 'Pump operation logs',
              iconColor: Color(0xFF6D28D9),
            ),
            _FeatureBullet(
              icon: Icons.filter_alt_outlined,
              text: 'Filter status & backwash',
              iconColor: Color(0xFF6D28D9),
            ),
            _FeatureBullet(
              icon: Icons.show_chart_rounded,
              text: 'Device performance',
              iconColor: Color(0xFF6D28D9),
            ),
            _FeatureBullet(
              icon: Icons.access_time_rounded,
              text: 'Runtime & events',
              iconColor: Color(0xFF6D28D9),
            ),
          ],
          page: StandaloneLog(
            userData: widget.userData,
          ),
        ),
        _LogCardItem(
          title: 'Pump Log',
          subtitle:
              'Track pump operations, start/stop events, runtime and fault history.',
          iconWidget: SvgPicture.asset(
            'assets/svg_images/pump.svg',
            width: 26,
            height: 26,
            colorFilter:
                const ColorFilter.mode(Color(0xFFEA580C), BlendMode.srcIn),
          ),
          accentColor: const Color(0xFFEA580C),
          iconBgColor: const Color(0xFFFFEDD5),
          buttonColor: const Color(0xFFF38220),
          features: const [
            _FeatureBullet(
              icon: Icons.play_arrow_outlined,
              text: 'Start / Stop events',
              iconColor: Color(0xFFEA580C),
            ),
            _FeatureBullet(
              icon: Icons.access_time_rounded,
              text: 'Runtime & total hours',
              iconColor: Color(0xFFEA580C),
            ),
            _FeatureBullet(
              icon: Icons.warning_amber_rounded,
              text: 'Fault / alarm history',
              iconColor: Color(0xFFEA580C),
            ),
            _FeatureBullet(
              icon: Icons.trending_up_rounded,
              text: 'Performance trends',
              iconColor: Color(0xFFEA580C),
            ),
          ],
          page: PumpList(
            pumpList: pumpList,
            userId: widget.userData['customerId'],
            controllerId: widget.masterData.controllerId,
            masterData: widget.masterData,
            userData: widget.userData,
          ),
        ),
      ]);
    }

    return cards;
  }

  Widget _buildOverviewDashboard(
    BuildContext context,
    List<_LogCardItem> cards,
    bool isOffline,
    CustomerScreenControllerViewModel? customerVM,
  ) {
    return LayoutBuilder(
      builder: (context, screenConstraints) {
        final bool isCompact = screenConstraints.maxWidth < 620;

        return Stack(
          children: [
            // Ambient soft pastel glow in bottom corners
            Positioned(
              bottom: -120,
              left: -100,
              child: IgnorePointer(
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE2E8F0).withOpacity(0.4),
                        const Color(0xFFE2E8F0).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -120,
              child: IgnorePointer(
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE0F2FE).withOpacity(0.45),
                        const Color(0xFFE0F2FE).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 24,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Responsive Cards Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;

                      if (width >= 1050) {
                        // 4 cards in a row
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < cards.length; i++) ...[
                              if (i > 0) const SizedBox(width: 18),
                              Expanded(
                                child: _buildLogCard(context, cards[i]),
                              ),
                            ],
                          ],
                        );
                      } else if (width >= 620) {
                        // 2 cards per row
                        final rows = <Widget>[];
                        for (int i = 0; i < cards.length; i += 2) {
                          final hasNext = i + 1 < cards.length;
                          rows.add(
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: _buildLogCard(context, cards[i])),
                                const SizedBox(width: 16),
                                if (hasNext)
                                  Expanded(
                                      child:
                                          _buildLogCard(context, cards[i + 1]))
                                else
                                  const Spacer(),
                              ],
                            ),
                          );
                          if (i + 2 < cards.length) {
                            rows.add(const SizedBox(height: 16));
                          }
                        }
                        return Column(children: rows);
                      } else {
                        // 1 column (mobile)
                        return Column(
                          children: [
                            for (int i = 0; i < cards.length; i++) ...[
                              if (i > 0) const SizedBox(height: 16),
                              _buildLogCard(context, cards[i]),
                            ],
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      },
    );
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