import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:oro_drip_irrigation/view_models/safe_change_notifier.dart';
import '../models/sales_data_model.dart';
import '../repository/repository.dart';
import '../utils/enums.dart';

class AnalyticsViewModel extends SafeChangeNotifier {
  final Repository repository;
  SalesDataModel mySalesData = SalesDataModel(graph: {});
  int totalSales = 0;
  final int userId;

  bool isLoadingSalesData = false;
  MySegment segmentView = MySegment.all;

  AnalyticsViewModel(this.repository, this.userId);

  Future<void> getMySalesData(MySegment segment, int userType) async {
    if (isLoadingSalesData) return;

    segmentView = segment;
    setLoadingSales(true);

    final body = {
      "userId": userId,
      "userType": userType,
      "type": segment == MySegment.all ? 'All' : 'Year',
      "year": DateTime.now().year,
    };

    try {
      final response = await repository.fetchAllMySalesReports(body);

      if (isDisposed) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["code"] == 200 && data.containsKey("data")) {
          mySalesData = SalesDataModel.fromJson(data);
          totalSales = mySalesData.total
              ?.fold(0, (sum, e) => sum! + e.totalProduct) ??
              0;
        }
      }
    } catch (e, st) {
      debugPrint('Error in getMySalesData: $e\n$st');
    } finally {
      if (!isDisposed) {
        setLoadingSales(false);
      }
    }
  }

  void updateSegmentView(MySegment newSegment) {
    segmentView = newSegment;
    safeNotify();
  }

  void setLoadingSales(bool loadingState) {
    isLoadingSalesData = loadingState;
    safeNotify();
  }
}