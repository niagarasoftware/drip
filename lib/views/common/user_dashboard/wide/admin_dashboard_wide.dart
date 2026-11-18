import 'package:flutter/material.dart';
import '../../../../models/admin_dealer/stock_model.dart';
import '../../../../utils/enums.dart';
import '../widgets/analytics_view.dart';
import '../widgets/customer_view.dart';
import '../widgets/product_view.dart';


class AdminDashboardWide extends StatelessWidget {
  const AdminDashboardWide({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  height: 400,
                  child: const AnalyticsView(screenType: 'Wide', userType: 1),
                ),
                const ProductView(isWideScreen: true),
              ]),
            ),
          ),
          SizedBox(
            width: 325,
            height: MediaQuery.sizeOf(context).height,
            child: CustomerView(
              role: UserRole.admin,
              isNarrow: false,
              onCustomerProductChanged: (String action, List<StockModel> updatedProducts) {
                print('Action: $action');
                print('Updated products count: ${updatedProducts.length}');
              },
            ),
          ),
        ],
      ),
    );
  }
}