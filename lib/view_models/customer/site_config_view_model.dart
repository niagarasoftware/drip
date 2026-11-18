import 'dart:convert';
import 'package:flutter/cupertino.dart';
import '../../models/admin_dealer/product_list_with_node.dart';
import '../../models/admin_dealer/stock_model.dart';
import '../../repository/repository.dart';


class SiteConfigViewModel extends ChangeNotifier {

  final Repository repository;
  bool isLoading = false;
  String errorMessage = "";

  List<ProductListWithNode> customerSiteList = <ProductListWithNode>[];

  SiteConfigViewModel(this.repository);

  Future<void> getCustomerSite(int customerId) async
  {
    Map<String, dynamic> body = {
      "userId": customerId,
    };
    try {
      var response = await repository.fetchUserGroupWithMasterList(body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        print(response.body);
        if(jsonData["code"] == 200){
          customerSiteList.clear();
          final cntList = jsonData["data"] as List;
          for (int i=0; i < cntList.length; i++) {
            customerSiteList.add(ProductListWithNode.fromJson(cntList[i]));
          }
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Error fetching Product stock: $error');
      debugPrint(stackTrace.toString());
    } finally {
      notifyListeners();
    }
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

}