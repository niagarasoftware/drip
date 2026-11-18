import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/admin_dealer/stock_model.dart';
import '../../models/admin_dealer/new_stock_model.dart';
import '../../models/admin_dealer/simple_category.dart';
import '../../repository/repository.dart';
import '../safe_change_notifier.dart';

class StockEntryViewModel extends SafeChangeNotifier {

  final Repository repository;

  StockEntryViewModel(this.repository) {
    _setupInitialValues();
    fetchCategoryList();
  }

  // ================= VARIABLES =================

  List<StockModel> productStockList = [];

  final TextEditingController modelTextController = TextEditingController();
  final TextEditingController imeiController = TextEditingController();
  final TextEditingController warrantyMonthsController = TextEditingController();
  final TextEditingController manufacturingDateController = TextEditingController();

  String errorMsg = '';

  List<SimpleCategory> categoryList = [];
  List<DropdownMenuEntry<ProductModel>> modelEntries = [];

  SimpleCategory? selectedCategory;

  int selectedCategoryId = 0;
  int selectedModelId = 0;

  List<Map<String, dynamic>> addedProductList = [];

  // ================= INITIAL SETUP =================

  void _setupInitialValues() {
    imeiController.addListener(() {
      final text = imeiController.text.toUpperCase();
      imeiController.value = imeiController.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });

    warrantyMonthsController.text = '12';
    manufacturingDateController.text =
        DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  // ================= FETCH STOCK =================

  Future<void> getMyStock(int userId, int userType) async {

    try {
      var response = await repository.fetchMyStocks({
        "userType": userType,
        "userId": userId,
      });

      if (isDisposed) return;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["code"] == 200) {
          final stockList = jsonData["data"] ?? [];

          productStockList =
              stockList.map<StockModel>((e) => StockModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint("Stock fetch error: $e");
    }

    safeNotify();
  }

  // ================= UPDATE STOCK =================

  void updateStockList(Map<String, dynamic> jsonData) {

    if (jsonData['status'] != 'success') return;

    List<dynamic> dataList = jsonData["data"] ?? [];
    List<dynamic> productList = jsonData["products"] ?? [];

    for (var dataItem in dataList) {
      String deviceId = dataItem["deviceId"];
      int productId = dataItem["productId"];

      for (var product in productList) {
        if (product["deviceId"] == deviceId) {
          product["productId"] = productId;
        }
      }
    }

    productStockList.insertAll(
      0,
      productList.map((e) => StockModel.fromJson(e)).toList(),
    );

    safeNotify();
  }

  void removeStockList(Map<String, dynamic> jsonData) {

    if (jsonData['status'] != 'success') return;

    for (var product in jsonData['products']) {
      productStockList.removeWhere(
              (stock) => stock.productId == product['productId']);
    }

    safeNotify();
  }

  // ================= CATEGORY =================

  Future<void> fetchCategoryList() async {

    try {
      var response =
      await repository.fetchActiveCategory({"active": "1"});

      if (isDisposed) return;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["code"] == 200) {
          final categories = jsonData["data"] as List?;

          if (categories != null) {
            categoryList = categories
                .map((item) => SimpleCategory(
              id: item["categoryId"],
              name: item["categoryName"],
            ))
                .toList();
          }
        }
      }
    } catch (e) {
      errorMsg = "Error fetching categories: $e";
    }

    safeNotify();
  }

  // ================= MODELS =================

  Future<void> getModelsByCategoryId() async {

    if (selectedCategoryId == 0) return;

    try {
      var response = await repository.fetchModelByCategoryId({
        "categoryId": selectedCategoryId,
      });

      if (isDisposed) return;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["code"] == 200) {
          final models = jsonData["data"] as List?;

          if (models != null) {
            modelEntries = models.map((item) {
              final model = ProductModel.fromJson(item);
              return DropdownMenuEntry<ProductModel>(
                value: model,
                label: model.modelName,
              );
            }).toList();
          }
        }
      }
    } catch (e) {
      errorMsg = "Error fetching models: $e";
    }

    safeNotify();
  }

  // ================= SAVE LOCAL =================

  Future<void> saveStockListToLocal() async {

    errorMsg = '';

    if (selectedCategoryId == 0 || selectedModelId == 0) {
      errorMsg = "Category and Model must be selected!";
      safeNotify();
      return;
    }

    if (_isAnyFieldEmpty()) {
      errorMsg = "All fields are required!";
      safeNotify();
      return;
    }

    String imei = imeiController.text.trim();

    if (isIMEIAlreadyExists(imei)) {
      errorMsg = "Device ID already exists!";
      safeNotify();
      return;
    }

    try {
      var response =
      await repository.checkProduct({"deviceId": imei});

      if (isDisposed) return;

      var data = jsonDecode(response.body);

      if (data['code'] == 404) {
        addProductToList();
      } else {
        errorMsg = "The product ID already exists!";
      }
    } catch (e) {
      errorMsg = "Error checking product: $e";
    }

    safeNotify();
  }

  void removeNewStock(int index) {
    addedProductList.removeAt(index);
    safeNotify();
  }

  // ================= ADD STOCK TO SERVER =================

  Future<bool> addProductStock(int userId) async {

    try {
      var response = await repository.createProduct({
        'products': addedProductList,
        'createUser': userId,
      });

      if (isDisposed) return false;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["code"] == 200) {
          _clearForm();
          addedProductList.clear();
          safeNotify();
          return true;
        } else {
          errorMsg = jsonData["message"];
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    safeNotify();
    return false;
  }

  // ================= HELPERS =================

  void addProductToList() {

    addedProductList.add({
      "categoryName": selectedCategory?.name ?? '',
      "categoryId": selectedCategoryId.toString(),
      "modelName": modelTextController.text,
      "modelId": selectedModelId.toString(),
      "deviceId": imeiController.text.trim(),
      "productDescription": '',
      "dateOfManufacturing":
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "warrantyMonths": warrantyMonthsController.text,
    });

    safeNotify();
  }

  bool isIMEIAlreadyExists(String newIMEI) {
    return addedProductList
        .any((product) => product['deviceId'] == newIMEI);
  }

  bool _isAnyFieldEmpty() {
    return imeiController.text.trim().isEmpty ||
        manufacturingDateController.text.trim().isEmpty ||
        warrantyMonthsController.text.trim().isEmpty;
  }

  void _clearForm() {
    imeiController.clear();
    manufacturingDateController.clear();
    warrantyMonthsController.clear();
  }

  // ================= DISPOSE =================

  @override
  void dispose() {
    modelTextController.dispose();
    imeiController.dispose();
    warrantyMonthsController.dispose();
    manufacturingDateController.dispose();
    super.dispose();
  }
}