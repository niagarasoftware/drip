import 'package:flutter/material.dart';

class CustomerBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final bool hasWeatherStation;
  const CustomerBottomNav({super.key, required this.index,
    required this.onTap, required this.hasWeatherStation});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: index,
      onTap: onTap,
      backgroundColor: Theme.of(context).primaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Scheduled Program'),
        const BottomNavigationBarItem(icon: Icon(Icons.report_gmailerrorred), label: 'Log'),
        if(hasWeatherStation)...const [
          BottomNavigationBarItem(icon: Icon(Icons.cloud_outlined), label: 'Weather'),
        ],
        const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
      ],
    );
  }
}