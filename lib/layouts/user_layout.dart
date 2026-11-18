import 'package:flutter/material.dart';

import '../utils/my_helper_class.dart';
import '../views/admin/admin_screen_middle.dart';
import '../views/admin/admin_screen_narrow.dart';
import '../views/admin/admin_screen_wide.dart';
import '../views/common/login/middle/login_tablet.dart';
import '../views/common/login/narrow/login_mobile.dart';
import '../views/common/login/wide/login_web.dart';
import '../views/common/user_dashboard/customer_dashboard_service.dart';
import '../views/common/user_dashboard/middle/admin_dashboard_middle.dart';
import '../views/common/user_dashboard/middle/customer_home_middle.dart';
import '../views/common/user_dashboard/middle/dealer_dashboard_middle.dart';
import '../views/common/user_dashboard/narrow/admin_dashboard_narrow.dart';
import '../views/common/user_dashboard/narrow/customer_home_narrow.dart';
import '../views/common/user_dashboard/narrow/dealer_dashboard_narrow.dart';
import '../views/common/user_dashboard/wide/admin_dashboard_wide.dart';
import '../views/common/user_dashboard/wide/customer_home_wide.dart';
import '../views/common/user_dashboard/wide/dealer_dashboard_wide.dart';
import '../views/customer/view_base_layout/customer_screen_middle.dart';
import '../views/customer/view_base_layout/customer_screen_narrow.dart';
import '../views/customer/view_base_layout/customer_screen_wide.dart';
import '../views/dealer/dealer_screen_middle.dart';
import '../views/dealer/dealer_screen_narrow.dart';
import '../views/dealer/dealer_screen_wide.dart';
import 'layout_builder.dart';

class LoginScreenLayout extends ScreenLayoutBuilder {
  const LoginScreenLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const LoginMobile();
  @override
  Widget buildMiddle(BuildContext context) => const LoginTablet();
  @override
  Widget buildWide(BuildContext context) => const LoginWeb();
}

class AdminScreenLayout extends ScreenLayoutBuilder with LayoutHelpers {
  const AdminScreenLayout({super.key});

  @override
  Widget build(BuildContext context) =>
      wrapWithBaseHeader(context, menuTitles: ['Dashboard', 'Inventory', 'Stock'],
          child: super.build(context));

  @override
  Widget buildNarrow(BuildContext context) => const AdminScreenNarrow();
  @override
  Widget buildMiddle(BuildContext context) => const AdminScreenMiddle();
  @override
  Widget buildWide(BuildContext context) => const AdminScreenWide();
}

class AdminDashboardLayout extends ScreenLayoutBuilder with LayoutHelpers {
  const AdminDashboardLayout({super.key});

  @override
  Widget build(BuildContext context) =>
      wrapWithDashboardService(userType: 1, context: context, child: super.build(context));

  @override
  Widget buildNarrow(BuildContext context) => const AdminDashboardNarrow();
  @override
  Widget buildMiddle(BuildContext context) => const AdminDashboardMiddle();
  @override
  Widget buildWide(BuildContext context) => const AdminDashboardWide();
}

class DealerScreenLayout extends ScreenLayoutBuilder with LayoutHelpers {
  const DealerScreenLayout({super.key});

  @override
  Widget build(BuildContext context) =>
      wrapWithBaseHeader(context, menuTitles: ['Dashboard', 'Inventory'], child: super.build(context));

  @override
  Widget buildNarrow(BuildContext context) => const DealerScreenNarrow();
  @override
  Widget buildMiddle(BuildContext context) => const DealerScreenMiddle();
  @override
  Widget buildWide(BuildContext context) => const DealerScreenWide();
}

class DealerDashboardLayout extends ScreenLayoutBuilder with LayoutHelpers {
  const DealerDashboardLayout({super.key});

  @override
  Widget build(BuildContext context) =>
      wrapWithDashboardService(userType: 2, context: context, child: super.build(context));

  @override
  Widget buildNarrow(BuildContext context) => const DealerDashboardNarrow();
  @override
  Widget buildMiddle(BuildContext context) => const DealerDashboardMiddle();
  @override
  Widget buildWide(BuildContext context) => const DealerDashboardWide();
}

class CustomerScreenLayout extends ScreenLayoutBuilder with LayoutHelpers {
  const CustomerScreenLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final viewedCustomer = getUserProvider(context).viewedCustomer!;
    return CustomerDashboardService(
      customerId: viewedCustomer.id,
      child: super.build(context),
    );
  }

  @override
  Widget buildNarrow(BuildContext context) => const CustomerScreenNarrow();
  @override
  Widget buildMiddle(BuildContext context) => const CustomerScreenMiddle();
  @override
  Widget buildWide(BuildContext context) => const CustomerScreenWide();
}


class CustomerDashboardLayout extends ScreenLayoutBuilder {
  const CustomerDashboardLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const CustomerHomeNarrow();
  @override
  Widget buildMiddle(BuildContext context) => const CustomerHomeMiddle();
  @override
  Widget buildWide(BuildContext context) => const CustomerHomeWide();
}
