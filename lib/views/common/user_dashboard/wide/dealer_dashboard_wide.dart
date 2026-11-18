import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/admin_dealer/stock_model.dart';
import '../../../../utils/enums.dart';
import '../../../../view_models/product_stock_view_model.dart';
import '../widgets/analytics_view.dart';
import '../widgets/customer_view.dart';
import '../widgets/stock_view.dart';

class DealerDashboardWide extends StatelessWidget {
  const DealerDashboardWide({super.key});

  @override
  Widget build(BuildContext context) {

    final viewModel = context.watch<ProductStockViewModel>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      height: 400,
                      child: const AnalyticsView(screenType: 'Wide', userType: 2)
                  ),
                  SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      height: (viewModel.productStockList.length * 35) + 92,
                      child: const StockView(role:  UserRole.dealer, isWide: true)
                  ),
                ]),
              ),
            ),
            SizedBox(
              width: 350,
              height: MediaQuery.sizeOf(context).height,
              child: CustomerView(
                role: UserRole.dealer,
                isNarrow: false,
                onCustomerProductChanged: (String action, List<StockModel> updatedProducts) {
                  final viewModel = context.read<ProductStockViewModel>();
                  if(action == 'added'){
                    viewModel.removeStockModels(updatedProducts);
                  } else if(action == 'removed'){
                    viewModel.addStockModels(updatedProducts);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}