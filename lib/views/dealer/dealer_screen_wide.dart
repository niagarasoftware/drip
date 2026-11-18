import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Widgets/app_logo.dart';
import '../../Widgets/user_account_menu.dart';
import '../../flavors.dart';
import '../../layouts/layout_selector.dart';
import '../../utils/enums.dart';
import '../../view_models/base_header_view_model.dart';
import '../common/product_inventory.dart';
import '../common/product_search_bar.dart';
import '../common/user_dashboard/widgets/main_menu.dart';

class DealerScreenWide extends StatelessWidget {
  const DealerScreenWide({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BaseHeaderViewModel>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: Navigator.of(context).canPop() ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ) :
        const Padding(
          padding: EdgeInsets.only(left: 15),
          child: AppLogo(),
        ),
        title: Row(
          children: [
            MainMenu(viewModel: viewModel),
            if(viewModel.selectedIndex==1)...[
              const Spacer(),
              SizedBox(width : 420,
                  child: ProductSearchBar(viewModel: viewModel, barHeight: 40, barRadius: 20)),
              const Spacer(),
            ]
          ],
        ),
        actions: const <Widget>[
          UserAccountMenu(isNarrow: false),
        ],
        centerTitle: false,
        elevation: 10,
        leadingWidth: Navigator.of(context).canPop() ? 50 :
        F.appFlavor!.name.contains('oro') ? 75:110,
      ),
      body: IndexedStack(
        index: viewModel.selectedIndex,
        children: const [
          DashboardLayoutSelector(userRole: UserRole.dealer),
          ProductInventory(),
        ],
      ),
    );
  }
}