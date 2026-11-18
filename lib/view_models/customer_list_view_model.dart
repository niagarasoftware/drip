import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:oro_drip_irrigation/view_models/safe_change_notifier.dart';

import '../models/admin_dealer/customer_list_model.dart';
import '../repository/repository.dart';

class CustomerListViewModel extends SafeChangeNotifier {
  final Repository repository;
  final int userId;

  List<CustomerListModel> myCustomerList = [];
  List<CustomerListModel> filteredCustomerList = [];

  bool isLoadingCustomer = false;
  bool accountCreated = false;
  String responseMsg = '';

  bool searching = false;
  final TextEditingController txtFldSearch = TextEditingController();

  CustomerListViewModel(this.repository, this.userId);

  List<CustomerListModel> get subDealerList =>
      filteredCustomerList.where((c) => c.isSubdealer == "1").toList();

  List<CustomerListModel> get customerList =>
      filteredCustomerList.where((c) => c.isSubdealer != "1").toList();

  Future<void> getMyCustomers(int userType) async {
    setCustomerLoading(true);

    final body = {"userId": userId, "userType": userType};

    try {
      final response = await repository.fetchMyCustomerList(body);

      if (isDisposed) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["code"] == 200) {
          final list = data["data"];
          if (list is List) {
            myCustomerList =
                list.map((e) => CustomerListModel.fromJson(e)).toList();
            refreshFilter();
          }
        }
      }
    } catch (e, st) {
      debugPrint('Customer fetch error: $e\n$st');
    } finally {
      if (!isDisposed) {
        setCustomerLoading(false);
      }
    }
  }

  Future<void> updateCustomerList(Map<String, dynamic> json) async {
    if (json['status'] != 'success') return;
    if (isDisposed) return;

    final newCustomer = CustomerListModel(
      id: json['userId'],
      name: json['userName'],
      countryCode: json['countryCode'],
      mobileNumber: json['mobileNumber'],
      emailId: json['emailId'],
      serviceRequestCount: json['serviceRequestCount'],
      criticalAlarmCount: json['criticalAlarmCount'],
    );

    if (!myCustomerList.any((c) => c.id == newCustomer.id)) {
      myCustomerList.add(newCustomer);
      refreshFilter();
      accountCreated = true;
      responseMsg = json['message'];
      safeNotify();
    }
  }

  void filterCustomer(String query) {
    searching = true;

    if (query.isEmpty) {
      filteredCustomerList = List.from(myCustomerList);
    } else {
      final q = query.toLowerCase();
      filteredCustomerList = myCustomerList.where((customer) {
        return customer.name.toLowerCase().contains(q) ||
            customer.mobileNumber.toLowerCase().contains(q);
      }).toList();
    }

    safeNotify();
  }

  void searchCustomer() {
    searching = true;
    filterCustomer(txtFldSearch.text);
  }

  void clearSearch() {
    searching = false;
    txtFldSearch.clear();
    refreshFilter();
    safeNotify();
  }

  void refreshFilter() {
    if (searching) {
      final q = txtFldSearch.text.toLowerCase();
      filteredCustomerList = myCustomerList.where((customer) {
        return customer.name.toLowerCase().contains(q) ||
            customer.mobileNumber.toLowerCase().contains(q);
      }).toList();
    } else {
      filteredCustomerList = List.from(myCustomerList);
    }
  }

  void setCustomerLoading(bool loadingState) {
    isLoadingCustomer = loadingState;
    safeNotify();
  }

  @override
  void dispose() {
    txtFldSearch.dispose();
    super.dispose();
  }
}