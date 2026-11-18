import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/admin_dealer/customer_model.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';

class CustomerSearchViewModel extends ChangeNotifier {
  List<Customer> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int selectedIndex = 0;

  List<Customer> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> searchCustomers(String query) async {
    print('🔍 Searching for: "$query"'); // Debug

    if (query.isEmpty) {
      _searchResults = [];
      _isLoading = false;
      _errorMessage = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final bool isMobileNumber = RegExp(r'^[0-9+\-\s()]+$').hasMatch(query) &&
          query.replaceAll(RegExp(r'[^0-9]'), '').length >= 6;

      Map<String, dynamic> bodyQuery = {
        "userName": isMobileNumber ? "" : query,
        "mobileNumber": isMobileNumber ? query : "",
      };

      var response = await Repository(HttpService()).searchAllMyCustomers(bodyQuery);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['code'] == 200 && responseData['data'] != null) {
          final List<dynamic> dataList = responseData['data'];
          _searchResults = dataList.map((json) => Customer.fromJson(json)).toList();
          _errorMessage = '';
        } else {
          _searchResults = [];
          _errorMessage = responseData['message'] ?? 'No customers found';
          print('⚠️ No customers found');
        }
      } else {
        _errorMessage = 'Failed to load customers';
        _searchResults = [];
        print('❌ Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _searchResults = [];
      print('❌ Exception: $e');
    } finally {
      _isLoading = false;
      print('🏁 Search completed, notifying listeners');
      notifyListeners(); // This will update the UI with results
    }
  }

  void clearSearch() {
    _searchResults = [];
    _errorMessage = '';
    _isLoading = false;
    notifyListeners();
  }
}