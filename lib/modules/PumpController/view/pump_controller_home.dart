import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/app.dart';
import 'package:oro_drip_irrigation/modules/Preferences/view/preference_main_screen.dart';
import 'package:oro_drip_irrigation/modules/PumpController/view/pump_dashboard_screen.dart';
import 'package:oro_drip_irrigation/modules/PumpController/widget/custom_outline_button.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:oro_drip_irrigation/views/customer/widgets/customer_fab_menu.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../models/customer/site_model.dart';
import '../../../providers/user_provider.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../../../views/common/user_dashboard/widgets/valve_status_legend.dart';
import '../../../views/customer/controller_settings/settings_menu_narrow.dart';
import '../../../views/customer/controller_settings/wide/controller_settings_wide.dart';
import '../../Logs/view/power_graph_screen.dart';
import '../../Logs/view/pump_log.dart';
import '../../Logs/view/pump_logs_home.dart';
import '../../Logs/view/voltage_log.dart';
import '../../Preferences/view/standalone_settings.dart';
import '../state_management/pump_controller_provider.dart';

class PumpControllerHome extends StatefulWidget {
  final int userId;
  final int customerId;
  final MasterControllerModel masterData;

  const PumpControllerHome({
    super.key,
    required this.userId,
    required this.customerId,
    required this.masterData,
  });

  @override
  State<PumpControllerHome> createState() => _PumpControllerHomeState();
}

class _PumpControllerHomeState extends State<PumpControllerHome> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late DateTime _focusedDay;
  late DateTime today;
  late bool isPumpWithValveModel;

  @override
  void initState() {
    super.initState();
    // print("userId : ${widget.userId}");
    // print("customerId : ${widget.customerId}");
    _focusedDay = DateTime.now();
    today = DateTime.now();
    _pageController = PageController(initialPage: _selectedIndex);
    isPumpWithValveModel = AppConstants.pumpWithValveModelList.contains(widget.masterData.modelId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width <= 600;

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          _pageController.jumpToPage(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Column(
          children: [
            if (AppConstants.pumpWithValveModelList
                .contains(widget.masterData.modelId))
              buildValveStatusLegend(false),

            Expanded(
              child: isSmallScreen
                  ? _buildSmallScreen()
                  : _buildLargeScreen(),
            ),
          ],
        ),

        bottomNavigationBar: !kIsWeb ? BottomNavigationBar(
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),

            if (isPumpWithValveModel) ...[
              const BottomNavigationBarItem(
                icon: Icon(Icons.touch_app_outlined),
                activeIcon: Icon(Icons.touch_app_rounded),
                label: 'Standalone',
              ),

              if (!AppConstants.pumpWithLightModelList
                  .contains(widget.masterData.modelId))
                const BottomNavigationBarItem(
                  icon: Icon(Icons.schedule_outlined),
                  activeIcon: Icon(Icons.schedule_rounded),
                  label: 'Program',
                ),
            ],

            const BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment),
              label: 'Logs',
            ),

            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          backgroundColor: Theme.of(context).primaryColorDark,
          unselectedItemColor: Colors.white54,
          selectedItemColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 8.0,
          onTap: _onItemTapped,
        )
            : null,
      ),
    );
  }

  Widget _buildLargeScreen() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10,),
                Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: Row(
                      spacing: 15,
                      children: [
                        for(int index = 0; index < (AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId) ? 4 : isPumpWithValveModel ? 5 : 3); index++)
                          CustomOutlineButton(
                              onPressed: () async{
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              isSelected: _selectedIndex == index,
                              label: [
                                "Pump log",
                                if(isPumpWithValveModel)...[
                                  "Standalone",
                                  if(!AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId))
                                    'Program',
                                ],
                                "Power graph",
                                "Voltage log",
                              ][index]
                          )
                      ],
                    ),
                  ),
                ),
                // const SizedBox(height: 10,),
                Row(
                  spacing: 10,
                  children: [
                    SizedBox(
                      height: constraints.maxHeight - (constraints.maxHeight * 0.1),
                      width: 400,
                      child: PumpDashboardScreen(
                        userId: widget.userId,
                        customerId: widget.customerId,
                        masterData: widget.masterData,
                      ),
                    ),
                    if(isPumpWithValveModel ? ![1,2].contains(_selectedIndex) : true)
                      Expanded(
                          child: Container(
                            height: constraints.maxHeight - (constraints.maxHeight * 0.1),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15)
                            ),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)
                              ),
                              color: Colors.white,
                              surfaceTintColor: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: _buildCalendar(constraints),
                              ),
                            ),
                          )
                      ),
                    Expanded(
                      flex: 2,
                        child: Consumer<PumpControllerProvider>(
                            builder: (context, provider, child) {
                            return SizedBox(
                              height: constraints.maxHeight - (constraints.maxHeight * 0.1),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)
                                ),
                                color: Colors.white,
                                surfaceTintColor: Colors.white,
                                child: provider.isLoading
                                    ? const Center(child: CircularProgressIndicator(),)
                                    : _getSelectedScreen(),
                              )
                            );
                          }
                        )
                    ),
                  ],
                )
              ],
            ),
          );
        }
    );
  }

  Widget _buildSmallScreen() {

    return PageView(
      physics: const NeverScrollableScrollPhysics(),
      controller: _pageController,
      children: [
        PumpDashboardScreen(
          userId: widget.userId,
          customerId: widget.customerId,
          masterData: widget.masterData,
        ),
        if (isPumpWithValveModel) ...[
          StandAloneSettings(
            userId: widget.userId,
            customerId: widget.customerId,
            masterData: widget.masterData,
            selectedIndex: _selectedIndex,
          ),
          if(!AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId))
            StandAloneSettings(
              userId: widget.userId,
              customerId: widget.customerId,
              masterData: widget.masterData,
              selectedIndex: _selectedIndex,
            ),
        ],
        PumpLogsHome(
            userId: widget.customerId,
            controllerId: widget.masterData.controllerId,
          masterData: widget.masterData,
        ),
        const SettingsMenuNarrow()
      ],
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  Widget _buildCalendar(BoxConstraints constraints) {
    final theme = Theme.of(context);
    final provider = context.read<PumpControllerProvider>();
    return TableCalendar(
      rowHeight: 40,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      focusedDay: _focusedDay,
      firstDay: DateTime.utc(2020, 10, 16),
      lastDay: DateTime.now(),
      calendarFormat: CalendarFormat.month,
      calendarStyle: CalendarStyle(
        cellMargin: const EdgeInsets.all(4),
        markerSize: 10,
        markerMargin: const EdgeInsets.all(2),
        markerDecoration: boxDecoration,
        outsideDecoration: boxDecoration,
        holidayDecoration: boxDecoration.copyWith(color: Colors.grey.withOpacity(0.1),),
        weekendDecoration: boxDecoration.copyWith(color: Colors.grey.withOpacity(0.1),),
        defaultDecoration: boxDecoration.copyWith(color: Colors.grey.withOpacity(0.1),),
        selectedDecoration: boxDecoration.copyWith(color: theme.primaryColor),
        todayTextStyle: const TextStyle(color: Colors.black),
        todayDecoration: boxDecoration.copyWith(color: theme.primaryColor.withOpacity(0.2), border: Border.all(color: theme.primaryColor)),
      ),
      selectedDayPredicate: (day) {
        return isSameDay(provider.selectedDate, day);
      },
      onDaySelected: (selectedDay, focusedDay) async{
        setState(() {
          provider.selectedDate = selectedDay;
          _focusedDay = focusedDay;
        });
        await _getDataFunction();
      },
    );
  }

  Future<void> _getDataFunction() async{
    final provider = context.read<PumpControllerProvider>();
    switch(_selectedIndex) {
      case 0:
        await provider.getUserPumpLog(widget.customerId, widget.masterData.controllerId, 0, widget.masterData);
      case 1:
        if(!isPumpWithValveModel) {
          await provider.getUserPumpLog(widget.customerId, widget.masterData.controllerId, 0, widget.masterData);
        }
      case 2:
        if(isPumpWithValveModel) {
          await provider.getPumpControllerData(userId: widget.customerId, controllerId: widget.masterData.controllerId, nodeControllerId: 0);
        }
      case 3:
        final int nodeCtrlId = (widget.masterData.nodeList.isNotEmpty && !AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId))
            ? widget.masterData.nodeList.first.controllerId
            : 0;
        await provider.getUserVoltageLog(userId: widget.customerId, controllerId: widget.masterData.controllerId, nodeControllerId: nodeCtrlId);
      default:
        (){};
    }
  }

  final BoxDecoration boxDecoration = BoxDecoration(
    shape: BoxShape.rectangle,
    borderRadius: BorderRadius.circular(4),
  );

  Widget _getSelectedScreen() {
    Widget selectedWidget = const Center(child: Text('Coming soon'),);
    switch(_selectedIndex) {
      case 0:
        selectedWidget = PumpLogScreen(
          userId: widget.customerId,
          controllerId: widget.masterData.controllerId,
          masterData: widget.masterData,
        );
      case 1:
        if(isPumpWithValveModel) {
          selectedWidget = StandAloneSettings(
            userId: widget.userId,
            customerId: widget.customerId,
            masterData: widget.masterData,
            selectedIndex: _selectedIndex,
          );
        } else {
          selectedWidget =  PowerGraphScreen(userId: widget.customerId, controllerId: widget.masterData.controllerId, masterData: widget.masterData);
        }
      case 2:
        if(AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId)){
          selectedWidget =  PowerGraphScreen(userId: widget.customerId, controllerId: widget.masterData.controllerId, masterData: widget.masterData);
        }else if(isPumpWithValveModel) {
          selectedWidget = StandAloneSettings(
            userId: widget.userId,
            customerId: widget.customerId,
            masterData: widget.masterData,
            selectedIndex: _selectedIndex,
          );
        } else {
          selectedWidget =  PumpVoltageLogScreen(userId: widget.customerId, controllerId: widget.masterData.controllerId, masterData: widget.masterData);
        }
      case 3:
        final int nodeCtrlId = (widget.masterData.nodeList.isNotEmpty && !AppConstants.ecoGemAndPlusModelList.contains(widget.masterData.modelId))
            ? widget.masterData.nodeList.first.controllerId
            : 0;
        if(AppConstants.pumpWithLightModelList.contains(widget.masterData.modelId)){
          selectedWidget = PumpVoltageLogScreen(userId: widget.customerId, controllerId: widget.masterData.controllerId, nodeControllerId: nodeCtrlId, masterData: widget.masterData);
        }else if(isPumpWithValveModel) {
          selectedWidget = PowerGraphScreen(userId: widget.customerId, controllerId: widget.masterData.controllerId, masterData: widget.masterData);
        } else {
          selectedWidget = PumpVoltageLogScreen(userId: widget.customerId, controllerId: widget.masterData.controllerId, nodeControllerId: nodeCtrlId, masterData: widget.masterData);
        }
      case 4:
        if(isPumpWithValveModel) {
          selectedWidget = PumpVoltageLogScreen(userId: widget.customerId, controllerId: widget.masterData.controllerId, masterData: widget.masterData);
        } else {
          selectedWidget =  PreferenceMainScreen(
            userId: widget.userId,
            customerId: widget.customerId,
            masterData: {"deviceId": widget.masterData.deviceId, "modelId": widget.masterData.modelId, "controllerId": widget.masterData.controllerId},
            selectedIndex: _selectedIndex,
          );
        }
      default:
        selectedWidget;
    }
    return selectedWidget;
  }
}
