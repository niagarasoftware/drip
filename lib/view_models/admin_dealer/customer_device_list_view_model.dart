import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/admin_dealer/stock_model.dart';
import '../../models/admin_dealer/product_list_with_node.dart';
import '../../models/device_list_model.dart';
import '../../repository/repository.dart';
import '../../utils/snack_bar.dart';
import '../../views/admin_dealer/customer_device_list.dart';

class CustomerDeviceListViewModel extends ChangeNotifier {
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

  List<DeviceListModel> customerDeviceList = [];
  List<bool> selectedProducts = [];
  late TextStyle commonTextStyle;

  List<ProductListWithNode> customerSiteList = <ProductListWithNode>[];
  List<StockModel> myMasterControllerList = <StockModel>[];

  int selectedRadioTile = 0;
  final ValueNotifier<MasterController> selectedItem = ValueNotifier<MasterController>(MasterController.gem1);
  final TextEditingController textFieldSiteName = TextEditingController();
  final TextEditingController textFieldSiteDisc = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final void Function(String action, List<StockModel> updatedProducts) onProductUpdatedCallback;


  CustomerDeviceListViewModel(
      this.repository,
      this.userId,
      this.customerId,
      this.stockLength, {
        required this.onProductUpdatedCallback,
      }) {
    _initialize();
  }

  void _initialize() {
    selectedProducts = List<bool>.filled(stockLength, false);
    commonTextStyle = const TextStyle(fontSize: 11);
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 100) {
      if (totalProduct > customerDeviceList.length && !isLoadingMoreData) {
        loadDeviceList(getSetNumber(customerDeviceList.length), isLoadMore: true);
      }
    }
  }

  Future<void> loadDeviceList(int currentSet, {bool isLoadMore = false}) async {
    if (isLoading || isLoadingMoreData) return;

    if (isLoadMore) {
      isLoadingMoreData = true;
    } else {
      isLoading = true;
      customerDeviceList.clear();
    }

    notifyListeners();

    try {
      Map<String, dynamic> body = {
        "userId": customerId,
        "userType": 3,
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
          customerDeviceList.addAll(newDevices);
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

  Future<void> addProductToCustomer(BuildContext context, List<StockModel> productStockList) async {
    List<Map<String, String>> selectedProductList = [];
    List<DeviceListModel> newDevices = [];
    for (int i = 0; i < stockLength; i++) {
      if (selectedProducts[i]) {
        selectedProductList.add({
          "productId": productStockList[i].productId.toString(),
          "categoryName": productStockList[i].categoryName,
          "modelName": productStockList[i].model,
        });
        newDevices.add(DeviceListModel(
          categoryName: productStockList[i].categoryName,
          deviceId: productStockList[i].imeiNo,
          model: productStockList[i].model,
          modifyDate: productStockList[i].dtOfMnf,
          productId: productStockList[i].productId,
          productStatus: 3,
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

      try {
        var response = await repository.addProductToCustomer(body);
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = jsonDecode(response.body);
          if(jsonData["code"] == 200){
            customerDeviceList.insertAll(0, newDevices);

            onProductUpdatedCallback(
              'added',
              newDevices.map((d) => StockModel(
                productId: d.productId,
                categoryName: d.categoryName,
                model: d.model,
                imeiNo: d.deviceId,
                dtOfMnf: d.modifyDate,
              )).toList(),
            );
          }
        }
      } catch (error, stackTrace) {
        debugPrint('Error fetching Product stock: $error');
        debugPrint(stackTrace.toString());
      } finally {
        notifyListeners();
      }
    }
  }

  Future<void> getCustomerSite() async
  {
    Map<String, dynamic> body = {
      "userId": customerId,
    };
    try {
      var response = await repository.fetchUserGroupWithMasterList(body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
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

  Future<void> getMasterProduct() async
  {
    Map<String, dynamic> body = {
      "userId": customerId,
      "userType": 3,
    };
    try {
      var response = await repository.fetchMasterProductStock(body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        if(jsonData["code"] == 200){
          myMasterControllerList.clear();
          final cntList = jsonData["data"] as List;
          for (int i=0; i < cntList.length; i++) {
            myMasterControllerList.add(StockModel.fromJson(cntList[i]));
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

  Future<void> displayCustomerSiteDialog(BuildContext context, String ctrlName, String ctrlModel, String ctrlIMEI) async {
    return showDialog(context: context,  builder: (context) {
      return AlertDialog(
        title: const Text('Create Customer Site'),
        content: SizedBox(
          height: 223,
          child : Form(
            key: formKey,
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text(ctrlName),
                  subtitle: Text('$ctrlModel\n$ctrlIMEI'),
                ),
                TextFormField(
                  controller: textFieldSiteName,
                  decoration: const InputDecoration(hintText: "Enter your site name"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8,),
                TextFormField(
                  controller: textFieldSiteDisc,
                  decoration: const InputDecoration(hintText: "address"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          MaterialButton(
            color: Colors.red,
            textColor: Colors.white,
            child: const Text('CANCEL'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          MaterialButton(
            color: Colors.teal,
            textColor: Colors.white,
            child: const Text('CREATE'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Map<String, dynamic> body = {
                  "userId": customerId,
                  "productId": myMasterControllerList[selectedRadioTile].productId,
                  "createUser": userId,
                  "groupName": textFieldSiteName.text,
                  "groupAddress": textFieldSiteDisc.text,
                };

                try {
                  var response = await repository.createUserGroupAndDeviceList(body);
                  debugPrint(response.body);
                  if (response.statusCode == 200) {
                    final Map<String, dynamic> jsonData = jsonDecode(response.body);
                    if(jsonData["code"] == 200){
                      getCustomerSite();
                      getMasterProduct();
                      Navigator.pop(context);
                    }
                  }
                } catch (error, stackTrace) {
                  debugPrint('Error fetching Product stock: $error');
                  debugPrint(stackTrace.toString());
                } finally {
                  notifyListeners();
                }
              }
            },
          ),
        ],
      );
    });
  }

  Future<void> createNewMaster(BuildContext context, int currentSiteInx) async
  {
    Navigator.pop(context);

    Map<String, dynamic> body = {
      "userId": customerId,
      "productId": myMasterControllerList[selectedRadioTile].productId,
      "createUser": userId,
      "groupId": customerSiteList[currentSiteInx].userGroupId,
    };

    try {
      var response = await repository.createNewMaster(body);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["code"] == 200) {
          getCustomerSite();
          getMasterProduct();
          GlobalSnackBar.show(context, data["message"], data["code"]);
        } else {
          GlobalSnackBar.show(context, data["message"], data["code"]);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Error fetching Product stock: $error');
      debugPrint(stackTrace.toString());
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeProductFromCustomer(int productId) async
  {
    Map<String, dynamic> body = {
      "userId": customerId,
      "dealerId": userId,
      "productId": productId,
      "modifyUser": userId,
    };

    try {
      var response = await repository.removeProductFromCustomer(body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        if(jsonData["code"] == 200){

          final removedDevice = customerDeviceList.firstWhere(
                (device) => device.productId == productId,
            orElse: () => DeviceListModel(
              categoryName: '',
              deviceId: '',
              model: '',
              modifyDate: '',
              productId: productId,
              productStatus: 0,
              siteName: '',
            ),
          );

          customerDeviceList.removeWhere((device) => device.productId == productId);
          notifyListeners();

          onProductUpdatedCallback(
            'removed',
            [StockModel(
              productId: removedDevice.productId,
              categoryName: removedDevice.categoryName,
              model: removedDevice.model,
              imeiNo: removedDevice.deviceId,
              dtOfMnf: removedDevice.modifyDate,
            )],
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Error fetching Product stock: $error');
      debugPrint(stackTrace.toString());
    } finally {
      notifyListeners();
    }
  }


  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }
}