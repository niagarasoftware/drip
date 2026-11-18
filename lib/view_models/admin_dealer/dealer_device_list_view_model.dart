import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/src/response.dart';
import '../../models/admin_dealer/stock_model.dart';
import '../../models/device_list_model.dart';
import '../../repository/repository.dart';

class DealerDeviceListViewModel extends ChangeNotifier {
  final Repository repository;
  final int userId, customerId;
  final int stockLength;
  final ScrollController scrollController = ScrollController();

  bool isLoading = false;
  bool isLoadingMoreData = false;
  bool checkboxValue = false;
  int totalProduct = 0;
  int batchSize = 100;
  int currentSet = 1;

  List<DeviceListModel> dealerDeviceList = [];
  List<bool> selectedProducts = [];
  late TextStyle commonTextStyle;

  DealerDeviceListViewModel(this.repository, this.userId, this.customerId, this.stockLength) {
    _initialize();
  }

  void _initialize() {
    selectedProducts = List<bool>.filled(stockLength, false);
    commonTextStyle = const TextStyle(fontSize: 11);
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 100) {
      if (totalProduct > dealerDeviceList.length && !isLoadingMoreData) {
        loadDeviceList(getSetNumber(dealerDeviceList.length), isLoadMore: true);
      }
    }
  }

  Future<void> loadDeviceList(int currentSet, {bool isLoadMore = false}) async {
    if (isLoading || isLoadingMoreData) return;

    if (isLoadMore) {
      isLoadingMoreData = true;
    } else {
      isLoading = true;
      dealerDeviceList.clear();
    }

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      Map<String, dynamic> body = {
        "userId": customerId,
        "userType": 2,
        "set": currentSet,
        "limit": batchSize
      };

      var response = await repository.fetchDeviceList(body);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          totalProduct = jsonData["data"]["totalProduct"] ?? 0;
          List<DeviceListModel> newDevices = (jsonData["data"]["product"] as List)
              .map((item) => DeviceListModel.fromJson(item))
              .toList();
          dealerDeviceList.addAll(newDevices);
        } else {
          debugPrint("API Error: ${jsonData['message'] ?? 'Unknown error'}");
        }
      } else {
        debugPrint("HTTP Error: ${response.statusCode}");
      }
    } catch (error, stackTrace) {
      debugPrint("Error fetching device list: $error");
      debugPrint(stackTrace.toString());
    } finally {
      isLoading = false;
      isLoadingMoreData = false;
      notifyListeners();
    }
  }

  int getSetNumber(int length) {
    return (length ~/ batchSize) + 1;
  }

  void toggleProductSelection(int index) {
    if (index >= 0 && index < selectedProducts.length) {
      selectedProducts[index] = !selectedProducts[index];
      notifyListeners();
    }
  }

  Future<void> addProductToDealer(BuildContext context, List<StockModel> productStockList/*, Function(Map<String, dynamic>) onDeviceListAdded*/, bool fromAdminPage) async {
    List<Map<String, dynamic>> selectedProductList = [];
    List<DeviceListModel> newDevices = [];

    for (int i = 0; i < stockLength; i++) {
      if (selectedProducts[i]) {
        print("Index: $i, Product ID: ${productStockList[i].productId}, Category Name: ${productStockList[i].categoryName}");

        selectedProductList.add({
          "productId": productStockList[i].productId,
          "categoryName": productStockList[i].categoryName,
        });

        newDevices.add(DeviceListModel(
          categoryName: productStockList[i].categoryName,
          deviceId: productStockList[i].imeiNo,
          model: productStockList[i].model,
          modifyDate: productStockList[i].dtOfMnf,
          productId: productStockList[i].productId,
          productStatus: 2,
          siteName: '',
        ));
      }
    }

    if(selectedProductList.isNotEmpty){
      Navigator.pop(context);
      Map<String, dynamic> body = {
        "fromUserId": userId,
        "toUserId": customerId,
        "createUser": userId,
        "products": selectedProductList,
      };

      print(fromAdminPage);

      try {

        Response response;

        if(fromAdminPage){
          response = await repository.addProductToDealer(body);
        }else{
          response = await repository.addProductToSubDealer(body);
        }
        if (response.statusCode == 200) {
          print(response.body);
          final Map<String, dynamic> jsonData = jsonDecode(response.body);
          if(jsonData["code"] == 200) {
            dealerDeviceList.insertAll(0, newDevices);
           /* onDeviceListAdded({
              "status" :'success',
              "products": selectedProductList,
            });*/
          }
        }
      } catch (error, stackTrace) {
        debugPrint('Error fetching Product stock: $error');
        debugPrint(stackTrace.toString());
      } finally {
        //isLoadingSalesData = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }
}