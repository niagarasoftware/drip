import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:oro_drip_irrigation/view_models/safe_change_notifier.dart';
import '../models/admin_dealer/stock_model.dart';
import '../repository/repository.dart';

class ProductStockViewModel extends SafeChangeNotifier {
  final Repository repository;

  List<StockModel> productStockList = [];
  bool isLoadingStock = false;

  ProductStockViewModel(this.repository);

  Future<void> getMyStock(int userId, int userType) async {
    setStockLoading(true);

    final body = {"userId": userId, "userType": userType};

    try {
      final response = await repository.fetchMyStocks(body);

      if (isDisposed) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["code"] == 200) {
          final list = data["data"] as List<dynamic>;
          productStockList =
              list.map((e) => StockModel.fromJson(e)).toList();
        }
      }
    } catch (e, st) {
      debugPrint('Stock fetch error: $e\n$st');
    } finally {
      if (!isDisposed) {
        setStockLoading(false);
      }
    }
  }

  void removeStockModels(List<StockModel> productsToRemove) {
    final idsToRemove = productsToRemove.map((p) => p.productId).toSet();
    productStockList.removeWhere((p) => idsToRemove.contains(p.productId));
    safeNotify();
  }

  void addStockModels(List<StockModel> productsToAdd) {
    productStockList.insertAll(0, productsToAdd);
    safeNotify();
  }

  void setStockLoading(bool loadingState) {
    isLoadingStock = loadingState;
    safeNotify();
  }
}