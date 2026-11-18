import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/layouts/user_layout.dart';
import '../utils/enums.dart';
import 'layout_builder.dart';

class UserLayoutSelector extends StatelessWidget {
  const UserLayoutSelector({super.key, required this.userRole});
  final UserRole userRole;

  ScreenLayoutBuilder getScreenLayout() {
    switch (userRole) {
      case UserRole.admin:
        return const AdminScreenLayout();
      case UserRole.dealer:
        return const DealerScreenLayout();
      case UserRole.customer:
      case UserRole.subUser:
        return const CustomerScreenLayout();
      case UserRole.superAdmin:
        throw UnimplementedError('Super Admin layout');
    }
  }

  @override
  Widget build(BuildContext context) {
    return getScreenLayout();
  }
}

class DashboardLayoutSelector extends StatelessWidget {
  const DashboardLayoutSelector({super.key, required this.userRole});
  final UserRole userRole;

  ScreenLayoutBuilder getDashboardLayout() {
    switch (userRole) {
      case UserRole.admin:
        return const AdminDashboardLayout();
      case UserRole.dealer:
        return const DealerDashboardLayout();
      case UserRole.customer:
        return const CustomerDashboardLayout();
      case UserRole.superAdmin:
        throw UnimplementedError('Super Admin layout not implemented');
      case UserRole.subUser:
        throw UnimplementedError('Sub user layout not implemented');
    }
  }

  @override
  Widget build(BuildContext context) {
    return getDashboardLayout();
  }
}
