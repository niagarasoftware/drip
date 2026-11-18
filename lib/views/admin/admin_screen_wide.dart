import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/utils/enums.dart';
import 'package:provider/provider.dart';
import '../../Widgets/app_logo.dart';
import '../../Widgets/user_account_menu.dart';
import '../../flavors.dart';
import '../../layouts/layout_selector.dart';
import '../../layouts/user_layout.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../view_models/admin_dealer/customer_search_view_model.dart';
import '../../view_models/base_header_view_model.dart';
import '../common/all_customer_search_bar.dart';
import '../common/product_inventory.dart';
import '../common/stock_entry.dart';
import '../common/product_search_bar.dart';
import '../common/user_dashboard/widgets/main_menu.dart';

class AdminScreenWide extends StatelessWidget {
  const AdminScreenWide({super.key});

  @override
  Widget build(BuildContext context) {

    final viewModel = context.watch<BaseHeaderViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 15),
          child: AppLogo(),
        ),
        title: Row(
          children: [
            MainMenu(viewModel: viewModel),

            if (viewModel.selectedIndex == 0) ...[
              const SizedBox(width: 16),
              SizedBox(
                width: 420,
                child: AllCustomerSearchBar(
                  // Use Provider to get the instance
                  viewModel: context.watch<CustomerSearchViewModel>(),
                  barHeight: 43,
                  barRadius: 20,
                  onCustomerSelected: (customer) {

                    final userProvider = context.read<UserProvider>();

                    final user = UserModel(
                      token: userProvider.loggedInUser.token,
                      id: customer.userId,
                      name: customer.userName,
                      role: UserRole.customer,
                      countryCode: customer.countryCode,
                      mobileNo: customer.mobileNumber,
                      email: 'customer@gmail.com',
                      configPermission: false,
                      password: userProvider.loggedInUser.password,
                    );

                    userProvider.pushViewedCustomer(user);

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerScreenLayout()),
                    ).then((_) => userProvider.popViewedCustomer());

                  },
                ),
              ),
              const Spacer(),
            ],

            if(viewModel.selectedIndex==1)...[
              const Spacer(),
              SizedBox(width : 420, child: ProductSearchBar(
                  viewModel: viewModel, barHeight: 40, barRadius: 20)),
              const Spacer(),
            ]
          ],
        ),
        actions: const <Widget>[
          UserAccountMenu(isNarrow: false),
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