import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:oro_drip_irrigation/view_models/safe_change_notifier.dart';
import '../models/entry_form/product_category_model.dart';
import '../repository/repository.dart';

class ProductCategoryViewModel extends SafeChangeNotifier {
  final Repository repository;

  List<ProductCategoryModel> categoryList = [];
  bool isLoadingCategory = false;

  ProductCategoryViewModel(this.repository);

  Future<void> getMyProductCategory() async {
    setLoading(true);

    try {
      final response = await repository.fetchCategory();

      if (isDisposed) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["code"] == 200) {
          categoryList = (data["data"] as List)
              .map((e) => ProductCategoryModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Category error: $e");
    } finally {
      if (!isDisposed) {
        setLoading(false);
      }
    }
  }

  void setLoading(bool value) {
    isLoadingCategory = value;
    safeNotify();
  }
}