import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Widgets/app_logo.dart';
import '../../Widgets/user_account_menu.dart';
import '../../flavors.dart';
import '../../layouts/layout_selector.dart';
import '../../providers/user_provider.dart';
import '../../utils/enums.dart';
import '../../view_models/base_header_view_model.dart';
import '../common/product_inventory.dart';
import '../common/product_search_bar.dart';
import '../common/user_dashboard/widgets/main_menu_segment.dart';


class DealerScreenNarrow extends StatelessWidget {
  const DealerScreenNarrow({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BaseHeaderViewModel>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: Navigator.of(context).canPop() ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final viewedCustomer = context.read<UserProvider>().viewedCustomer;
            Navigator.pop(context, viewedCustomer);
          },
        ) :
        const Padding(
          padding: EdgeInsets.only(left: 15),
          child: AppLogo(),
        ),
        title: F.appFlavor!.name.contains('oro') ? MainMenuSegmentWidget(viewModel: viewModel) :
        null ,
        actions: const <Widget>[
          UserAccountMenu(isNarrow: true),
        ],
        centerTitle: true,
        elevation: 10,
        leadingWidth: Navigator.of(context).canPop() ? 50 :
        F.appFlavor!.name.contains('oro') ? 75 : 110,

        bottom: (F.appFlavor!.name.contains('oro') && viewModel.selectedIndex == 0) ? null : PreferredSize(
          preferredSize: Size.fromHeight((!F.appFlavor!.name.contains('oro') && viewModel.selectedIndex == 1) ? 106 : 50),
          child: _buildBottomBar(viewModel),
        ),
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

  Widget _buildBottomBar(BaseHeaderViewModel viewModel) {
    final isOro = F.appFlavor!.name.contains('oro');
    return Column(
      children: [
        if (!isOro) ...[
          MainMenuSegmentWidget(viewModel: viewModel),
          const SizedBox(height: 8),
        ],
        if (viewModel.selectedIndex == 1)
          ProductSearchBar(viewModel: viewModel, barHeight: 44, barRadius: 10),
      ],
    );
  }
}