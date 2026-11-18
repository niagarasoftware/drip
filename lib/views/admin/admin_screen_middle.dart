import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Widgets/app_logo.dart';
import '../../Widgets/user_account_menu.dart';
import '../../flavors.dart';
import '../../layouts/layout_selector.dart';
import '../../utils/enums.dart';
import '../../view_models/base_header_view_model.dart';
import '../common/product_inventory.dart';
import '../common/stock_entry.dart';
import '../common/user_dashboard/widgets/main_menu.dart';

class AdminScreenMiddle extends StatelessWidget {
  const AdminScreenMiddle({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BaseHeaderViewModel>();
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 15),
          child: AppLogo(),
        ),
        title: MainMenu(viewModel: viewModel),
        actions: const <Widget>[
          UserAccountMenu(isNarrow: true),
        ],
        centerTitle: false,
        elevation: 10,
        leadingWidth: F.appFlavor!.name.contains('oro') ? 75:110,
      ),
      body: IndexedStack(
        index: viewModel.selectedIndex,
        children: const [
          DashboardLayoutSelector(userRole: UserRole.admin),
          ProductInventory(),
          StockEntry(isNarrow: false),
        ],
      ),
    );
  }
}