import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/enums.dart';
import '../../../view_models/analytics_view_model.dart';
import '../../../view_models/bottom_nav_view_model.dart';
import '../../../view_models/customer_list_view_model.dart';
import '../../../view_models/product_category_view_model.dart';
import '../../../view_models/product_stock_view_model.dart';

class ManagementDashboardService extends StatelessWidget {
  final int userId;
  final int userType;
  final Widget child;

  const ManagementDashboardService({
    super.key,
    required this.userId,
    required this.userType,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AnalyticsViewModel(
            Repository(HttpService()),
            userId,
          )..getMySalesData(MySegment.all, userType),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => ProductStockViewModel(
            Repository(HttpService()),
          )..getMyStock(userId, userType),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => CustomerListViewModel(
            Repository(HttpService()),
            userId,
          )..getMyCustomers(userType),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => ProductCategoryViewModel(
            Repository(HttpService()),
          )..getMyProductCategory(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => BottomNavViewModel(),
          lazy: false,
        ),
      ],
      child: child,
    );
  }
}