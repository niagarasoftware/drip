import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../widgets/crop_advisory_web_sidebar.dart';
import 'dashboard_screen.dart';
import 'crop_weatherScreen.dart';
import 'irrigation_fertigation_screen.dart';
import 'disease_screen.dart';
import 'report_screen.dart';
import '../model/cropadvisory_model.dart';

class CropAdvisoryMainScreen extends StatefulWidget {
  final int initialIndex, userId, controllerId;
  final CropAdvisoryModel cropModel;

  const CropAdvisoryMainScreen({
    super.key,
    this.initialIndex = 0,
    required this.userId,
    required this.controllerId,
    required this.cropModel,
  });

  @override
  State<CropAdvisoryMainScreen> createState() => _CropAdvisoryMainScreenState();
}

class _CropAdvisoryMainScreenState extends State<CropAdvisoryMainScreen> {
  late PersistentTabController _controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _controller = PersistentTabController(initialIndex: widget.initialIndex);
  }

  List<Widget> _buildScreens() {
    return [
      DashboardScreen(
        isInsideMain: true,
        userID: widget.userId,
        controllerId: widget.controllerId,
        onTabChanged: (index) {
          if (kIsWeb) {
            setState(() {
              _selectedIndex = index;
            });
          } else {
            _controller.jumpToTab(index);
          }
        },  model: widget.cropModel,
      ),
      CropWeatherscreen(userId: widget.userId,controllerId: widget.controllerId,),
      const IrrigationFertigationScreen(isInsideMain: true),
      const DiseaseScreen(),
      const ReportScreen(),
    ];
  }

  Widget _buildBody() {
    return _buildScreens()[_selectedIndex];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    const activeColor = Color(0xFF1B7F8A);
    const inactiveColor = Colors.grey;
    
    return [
      PersistentBottomNavBarItem(
        icon: Image.asset('assets/Images/CropAdvisory/home_icon_active.png', width: 24, height: 24, color: activeColor),
        inactiveIcon: Image.asset('assets/Images/CropAdvisory/home_icon_active.png', width: 24, height: 24, color: inactiveColor),
        title: ("Home"),
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: Image.asset('assets/Images/CropAdvisory/weather.png', width: 24, height: 24, color: activeColor),
        inactiveIcon: Image.asset('assets/Images/CropAdvisory/weather.png', width: 24, height: 24, color: inactiveColor),
        title: ("Weather"),
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.water_drop, size: 24, color: activeColor),
        inactiveIcon: const Icon(Icons.water_drop_outlined, size: 24, color: inactiveColor),
        title: ("Irrigation"),
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: Image.asset('assets/Images/CropAdvisory/disease.png', width: 24, height: 24, color: activeColor),
        inactiveIcon: Image.asset('assets/Images/CropAdvisory/disease.png', width: 24, height: 24, color: inactiveColor),
        title: ("Disease"),
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: Image.asset('assets/Images/CropAdvisory/report.png', width: 24, height: 24, color: activeColor),
        inactiveIcon: Image.asset('assets/Images/CropAdvisory/report.png', width: 24, height: 24, color: inactiveColor),
        title: ("Report"),
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        body: Row(
          children: [
            CropAdvisoryWebSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      );
    }

    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineToSafeArea: true,
      backgroundColor: Colors.white,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      hideNavigationBarWhenKeyboardAppears: true,
      decoration: NavBarDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        colorBehindNavBar: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      navBarStyle: NavBarStyle.style1,
      onItemSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}
