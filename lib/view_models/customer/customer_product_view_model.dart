import 'dart:convert';
import 'package:flutter/cupertino.dart';
import '../../models/customer/customer_product_model.dart';
import '../../repository/repository.dart';

class CustomerProductViewModel extends ChangeNotifier {

  final Repository repository;
  bool isLoading = false;
  String errorMessage = "";

  List<CustomerProductModel> productInventoryListCus = [];

  CustomerProductViewModel(this.repository);

  Future<void> getCustomerProducts(userId) async {

    setLoading(true);
    try {
      Map<String, dynamic> body = {"userId": userId, "userType": 3, "set": 1, "limit":100};
      final response = await repository.fetchAllMyInventory(body);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          productInventoryListCus = (jsonData["data"]["product"] as List).map((data) =>
              CustomerProductModel.fromJson(data)).toList();
        }
      }
    } catch (error) {
      debugPrint('Error fetching country list: $error');
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  String getDateTime(dateString){
    DateTime dateTime = DateTime.parse(dateString);
    String dateOnly = "${dateTime.year.toString().padLeft(4, '0')}-"
        "${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
    return dateOnly;
  }

}