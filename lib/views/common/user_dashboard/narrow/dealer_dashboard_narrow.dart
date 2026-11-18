import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/admin_dealer/stock_model.dart';
import '../../../../utils/enums.dart';
import '../../../../view_models/bottom_nav_view_model.dart';
import '../../../../view_models/product_stock_view_model.dart';
import '../widgets/analytics_view.dart';
import '../widgets/customer_view.dart';
import '../widgets/stock_view.dart';

class DealerDashboardNarrow extends StatelessWidget {
  const DealerDashboardNarrow({super.key});

  @override
  Widget build(BuildContext context) {
    final navModel = context.watch<BottomNavViewModel>();

    final pages = [
      const AnalyticsView(screenType: 'Narrow', userType: 2),
      CustomerView(role: UserRole.dealer, isNarrow: true,
        onCustomerProductChanged: (String action, List<StockModel> updatedProducts) {
          final viewModel = context.read<ProductStockViewModel>();
          if(action == 'added'){
            viewModel.removeStockModels(updatedProducts);
          } else if(action == 'removed'){
            viewModel.addStockModels(updatedProducts);
          }
      }),
      const StockView(role:  UserRole.dealer, isWide: false)];

    return Scaffold(
      body: IndexedStack(
        index: navModel.index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navModel.index,
        onTap: navModel.setIndex,
        backgroundColor: Theme.of(context).primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Stock',
          ),
        ],
      ),
    );
  }
}
