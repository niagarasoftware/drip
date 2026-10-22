import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:oro_drip_irrigation/modules/Logs/view/pump_log_dashboard.dart';
import 'package:provider/provider.dart';

import 'package:oro_drip_irrigation/utils/constants.dart';

import '../../StateManagement/customer_provider.dart';
import '../../models/customer/site_model.dart';
import '../../modules/Logs/repository/log_repos.dart';

import '../../modules/irrigation_report/view/channel_log_page.dart';
import '../../modules/irrigation_report/view/list_of_log_config.dart';
import '../../modules/irrigation_report/view/fertigation_card_list_page.dart';
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
  State<IrrigationAndPumpLog> createState() => _IrrigationAndPumpLogState();
}

class _IrrigationAndPumpLogState extends State<IrrigationAndPumpLog>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  List pumpList = [];

  String message = '';

  final LogRepository repository = LogRepository(HttpService());

  // Channel Log data
  List<ChannelLogRecord> channelLogData = [];

  bool get isEcoGem =>
      AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId);

  bool get isOmsGem =>
      AppConstants.omsGemList.contains(widget.masterData.modelId);

  bool get showPumpLog => isEcoGem || pumpList.isNotEmpty;

  int _calculateTabLength() {
    if (isOmsGem) {
      return 1;
    }

    if (isEcoGem) {
      return 3; // Motor + Zone Cyclic + Pump
    }

    // Irrigation + Zone + Fertilizer + Standalone
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

  @override
  void didUpdateWidget(covariant IrrigationAndPumpLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCtrlId =
        oldWidget.userData['controllerId'] ?? oldWidget.masterData.controllerId;
    final newCtrlId =
        widget.userData['controllerId'] ?? widget.masterData.controllerId;
    if (oldCtrlId != newCtrlId ||
        oldWidget.userData['customerId'] != widget.userData['customerId']) {
      getUserNodePumpList();
    }
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
      initialIndex: oldIndex < newLength ? oldIndex : newLength - 1,
    );

    oldController.dispose();
  }

  Future<void> getUserNodePumpList() async {
    try {
      final userData = {
        'userId': widget.userData['customerId'],
        'controllerId': widget.userData['controllerId'],
      };

      final result = await repository.getUserNodePumpList(userData);

      if (!mounted) return;

      final response = jsonDecode(result.body);

      List fetchedList = [];
      if (result.statusCode == 200 &&
          response['data'] is List &&
          (response['data'] as List).isNotEmpty) {
        fetchedList = response['data'];
      } else if (widget.masterData.nodeList.isNotEmpty) {
        final pumpNodes = widget.masterData.nodeList.where((n) {
          return AppConstants.pumpList.contains(n.modelId) ||
              n.categoryId == 1 ||
              n.categoryName.toLowerCase().contains('pump');
        }).toList();

        final nodesToUse =
            pumpNodes.isNotEmpty ? pumpNodes : widget.masterData.nodeList;
        fetchedList = nodesToUse
            .map((n) => {
                  'controllerId': n.controllerId,
                  'deviceId': n.deviceId,
                  'deviceName': n.deviceName.isNotEmpty
                      ? n.deviceName
                      : 'Node ${n.serialNumber}',
                })
            .toList();
      }

      setState(() {
        pumpList = fetchedList;
        message =
            fetchedList.isEmpty ? (response['message']?.toString() ?? '') : '';
        _updateTabController();
      });
    } catch (e) {
      if (!mounted) return;

      List fallbackList = [];
      if (widget.masterData.nodeList.isNotEmpty) {
        final pumpNodes = widget.masterData.nodeList.where((n) {
          return AppConstants.pumpList.contains(n.modelId) ||
              n.categoryId == 1 ||
              n.categoryName.toLowerCase().contains('pump');
        }).toList();

        final nodesToUse =
            pumpNodes.isNotEmpty ? pumpNodes : widget.masterData.nodeList;
        fallbackList = nodesToUse
            .map((n) => {
                  'controllerId': n.controllerId,
                  'deviceId': n.deviceId,
                  'deviceName': n.deviceName.isNotEmpty
                      ? n.deviceName
                      : 'Node ${n.serialNumber}',
                })
            .toList();
      }

      setState(() {
        pumpList = fallbackList;
        message = fallbackList.isEmpty ? e.toString() : '';
        _updateTabController();
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
        builder: (context) {
          if (card.page is FertigationCardListPage) {
            return card.page;
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(card.title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: card.page,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CustomerScreenControllerViewModel? customerVM;
    try {
      customerVM =
          Provider.of<CustomerScreenControllerViewModel>(context, listen: true);
    } catch (_) {}

    final bool isOffline = customerVM?.isNotCommunicate ?? false;

    final List<_LogCardItem> cards = _buildCardItems();

    return Scaffold(
      key: ValueKey(
        Provider.of<CustomerProvider>(context).controllerId,
      ),
      backgroundColor: const Color(0xFFF7FAFD),
      body: SafeArea(
        child: _buildOverviewDashboard(context, cards, isOffline, customerVM),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card builders
  // ---------------------------------------------------------------------------

  _LogCardItem _irrigationCard() {
    return _LogCardItem(
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
    );
  }

  _LogCardItem _zoneLogCard() {
    return _LogCardItem(
      title: 'Cumulative Log',
      subtitle:
          'Review cumulative irrigation history, valve activity and runtime details.',
      iconWidget: const Icon(
        Icons.grid_view_rounded,
        color: Color(0xFF7C3AED),
        size: 28,
      ),
      accentColor: const Color(0xFF7C3AED),
      iconBgColor: const Color(0xFFEDE9FE),
      buttonColor: const Color(0xFF7C3AED),
      features: const [
        _FeatureBullet(
          icon: Icons.grid_view_rounded,
          text: 'cumulative irrigation records',
          iconColor: Color(0xFF7C3AED),
        ),
        _FeatureBullet(
          icon: Icons.device_hub_rounded,
          text: 'Valve activity',
          iconColor: Color(0xFF7C3AED),
        ),
        _FeatureBullet(
          icon: Icons.access_time_rounded,
          text: 'Runtime per zone',
          iconColor: Color(0xFF7C3AED),
        ),
        _FeatureBullet(
          icon: Icons.bar_chart_rounded,
          text: 'Usage summary',
          iconColor: Color(0xFF7C3AED),
        ),
      ],
      page: ZoneLog(
        userData: widget.userData,
        masterData: widget.masterData,
      ),
    );
  }

  _LogCardItem _fertilizerLogCard() {
    return _LogCardItem(
      title: 'Fertilizer Log',
      subtitle:
          'Track fertigation recipes, fertilizer channel runtime and EC/pH details.',
      iconWidget: const Icon(
        Icons.science_outlined,
        color: Color(0xFF0D9488),
        size: 28,
      ),
      accentColor: const Color(0xFF0D9488),
      iconBgColor: const Color(0xFFCCFBF1),
      buttonColor: const Color(0xFF006573),
      features: const [
        _FeatureBullet(
          icon: Icons.science_outlined,
          text: 'Fertigation recipes',
          iconColor: Color(0xFF0D9488),
        ),
        _FeatureBullet(
          icon: Icons.water_drop_outlined,
          text: 'Channel duration & quantity',
          iconColor: Color(0xFF0D9488),
        ),
        _FeatureBullet(
          icon: Icons.speed_rounded,
          text: 'EC & pH monitoring',
          iconColor: Color(0xFF0D9488),
        ),
        _FeatureBullet(
          icon: Icons.bar_chart_rounded,
          text: 'Program & sequence views',
          iconColor: Color(0xFF0D9488),
        ),
      ],
      page: FertigationCardListPage(
        serverData: const {'logName': 'Fertilizer'},
        userData: widget.userData,
        nameData: const [],
      ),
    );
  }

  _LogCardItem _standaloneLogCard() {
    return _LogCardItem(
      title: 'Standalone Log',
      subtitle:
          'Track standalone (manual) operations with their start and stop history.',
      iconWidget: const Icon(
        Icons.touch_app_outlined,
        color: Color(0xFFDB2777),
        size: 28,
      ),
      accentColor: const Color(0xFFDB2777),
      iconBgColor: const Color(0xFFFCE7F3),
      buttonColor: const Color(0xFFDB2777),
      features: const [
        _FeatureBullet(
          icon: Icons.play_arrow_outlined,
          text: 'Manual start & stop events',
          iconColor: Color(0xFFDB2777),
        ),
        _FeatureBullet(
          icon: Icons.access_time_rounded,
          text: 'Duration of each run',
          iconColor: Color(0xFFDB2777),
        ),
        _FeatureBullet(
          icon: Icons.water_drop_outlined,
          text: 'Water usage data',
          iconColor: Color(0xFFDB2777),
        ),
        _FeatureBullet(
          icon: Icons.bar_chart_rounded,
          text: 'Run-wise details',
          iconColor: Color(0xFFDB2777),
        ),
      ],
      page: StandaloneLog(
        userData: widget.userData,
      ),
    );
  }

  _LogCardItem _pumpLogCard() {
    return _LogCardItem(
      title: 'Pump Log',
      subtitle:
          'Track pump operations, start/stop events, runtime and fault history.',
      iconWidget: SvgPicture.asset(
        'assets/svg_images/pump.svg',
        width: 26,
        height: 26,
        colorFilter: const ColorFilter.mode(Color(0xFFEA580C), BlendMode.srcIn),
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
      page: PumpLogDashboardScreen(
        pumpList: pumpList,
        userId: widget.userData['customerId'],
        controllerId: widget.masterData.controllerId,
        masterData: widget.masterData,
        userData: widget.userData,
        showMobileCalendar: true,
      ),
    );
  }

  List<_LogCardItem> _buildCardItems() {
    final List<_LogCardItem> cards = [];

    if (isOmsGem) {
      cards.add(_irrigationCard());
    } else if (isEcoGem) {
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
        _pumpLogCard(),
      ]);
    } else {
      cards.addAll([
        _irrigationCard(),
        _zoneLogCard(),
        _fertilizerLogCard(),
        _standaloneLogCard(),
        // Matches _calculateTabLength(): pump log only when it applies
        if (showPumpLog) _pumpLogCard(),
      ]);
    }

    return cards;
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

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
                        const Color(0xFFE2E8F0).withValues(alpha: 0.4),
                        const Color(0xFFE2E8F0).withValues(alpha: 0.0),
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
                        const Color(0xFFE0F2FE).withValues(alpha: 0.45),
                        const Color(0xFFE0F2FE).withValues(alpha: 0.0),
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
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Responsive Cards Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;

                      if (width >= 1150) {
                        // All cards in a single row
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF006775).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.eco_outlined,
            size: 30,
            color: Color(0xFF006775),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Logs',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'View and manage your system logs',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(BuildContext context, _LogCardItem card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle top-right ambient colored corner glow
          Positioned(
            top: -30,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      card.accentColor.withValues(alpha: 0.12),
                      card.accentColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Card content
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openLogDetail(context, card),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: card.iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: card.iconWidget),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text(
                      card.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      card.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Feature bullet list
                    for (final item in card.features) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(item.icon, size: 18, color: item.iconColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.text,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // View Log button
                    InkWell(
                      onTap: () => _openLogDetail(context, card),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: card.buttonColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Log',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogCardItem {
  final String title;
  final String subtitle;
  final Widget iconWidget;
  final Color accentColor;
  final Color iconBgColor;
  final Color buttonColor;
  final List<_FeatureBullet> features;
  final Widget page;

  const _LogCardItem({
    required this.title,
    required this.subtitle,
    required this.iconWidget,
    required this.accentColor,
    required this.iconBgColor,
    required this.buttonColor,
    required this.features,
    required this.page,
  });
}

class _FeatureBullet {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _FeatureBullet({
    required this.icon,
    required this.text,
    required this.iconColor,
  });
}
