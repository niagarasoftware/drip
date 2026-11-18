import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/admin_dealer/inventory_model.dart';
import '../../models/admin_dealer/new_stock_model.dart';
import '../../models/admin_dealer/stock_model.dart';
import '../../repository/repository.dart';
import '../../utils/enums.dart';
import '../../utils/snack_bar.dart';
import '../safe_change_notifier.dart';

class InventoryViewModel extends SafeChangeNotifier {

  final Repository repository;
  final int userId;
  final UserRole userRole;

  List<InventoryModel> productInventoryList = [];
  List<InventoryModel> filterProductInventoryList = [];

  bool isLoading = false;
  bool isLoadingMore = false;

  final ScrollController scrollController = ScrollController();

  int totalProduct = 0;
  int batchSize = 30;
  int currentSet = 1;

  late List<DropdownMenuEntry<ProductModel>> selectedModel;
  List<ProductModel> activeModelList = <ProductModel>[];
  ProductModel? initialSelectedModel;

  final TextEditingController imeiController = TextEditingController();
  List<DropdownMenuItem<StockModel>> stockEntries = [];
  StockModel? selectedStock;
  int selectedProductId = 0;

  InventoryViewModel(this.repository, this.userId, this.userRole){
    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (isDisposed) return;

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 100) {

      if (totalProduct > productInventoryList.length && !isLoadingMore) {
        isLoadingMore = true;
        safeNotify();
        loadMoreData();
      }
    }
  }

  Future<void> loadMoreData() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (isDisposed) return;
      await loadInventoryData(getSetNumber(productInventoryList.length));
    } finally {
      if (!isDisposed) {
        isLoadingMore = false;
        safeNotify();
      }
    }
  }

  int getSetNumber(int length) {
    int itemsPerSet = 30;
    return (length ~/ itemsPerSet) + 1;
  }

  Future<void> loadInventoryData(int set) async {

    if (set == 1) {
      isLoading = true;
      productInventoryList.clear();
    } else {
      isLoadingMore = true;
    }

    safeNotify();

    try {
      Map<String, dynamic> body = {
        "userId": userId,
        "userType": userRole.name == 'admin' ? 1 : 2,
        "set": set,
        "limit": batchSize,
      };

      var response = await repository.fetchAllMyInventory(body);

      if (isDisposed) return;

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody["code"] == 200) {
          final data = responseBody["data"];

          if (data != null) {
            totalProduct = data["totalProduct"] ?? 0;

            List<dynamic> productList = data["product"] ?? [];

            productInventoryList.addAll(
              productList.map((e) => InventoryModel.fromJson(e)),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Inventory error: $e");
    } finally {
      if (!isDisposed) {
        isLoading = false;
        isLoadingMore = false;
        safeNotify();
      }
    }
  }




  Future<void> getModelByActiveList(
      BuildContext context,
      int catId,
      String catName,
      String mdlName,
      String mdlDis,
      int mdlId,
      String imeiNo,
      int warranty,
      int productId,
      int userId,) async {

    try {
      Map<String, dynamic> body = {
        "categoryId": catId.toString(),
      };

      var response = await repository.fetchModelByCategoryId(body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          final List<dynamic> cntList = jsonData["data"] ?? [];
          activeModelList..clear()..addAll(cntList.map((e) => ProductModel.fromJson(e)));
          selectedModel = activeModelList.map((product) => DropdownMenuEntry<ProductModel>(
            value: product,
            label: product.modelName,
          )).toList();
           displayEditProductDialog(context, catId, catName, mdlName, mdlDis,
               mdlId, imeiNo, warranty, productId, userId);
        } else {
          debugPrint("API Error: ${jsonData['message']}");
        }
      } else {
        debugPrint("HTTP Error: ${response.statusCode}");
      }
    } catch (error, stackTrace) {
      debugPrint('Error fetching models: $error');
      debugPrint(stackTrace.toString());
    } finally {
      isLoading = false;
      safeNotify();
    }
  }

  Future<void> displayEditProductDialog(BuildContext context, int catId, String catName,
      String mdlName, String mdlDis, int mdlId, String imeiNo, int warranty, int productId, int userId) async
  {
    int indexOfInitialSelection = activeModelList.indexWhere((model) => model.modelId == mdlId);
    final formKey = GlobalKey<FormState>();
    final TextEditingController textFieldModelList = TextEditingController();
    final TextEditingController ctrlIMI = TextEditingController();
    final TextEditingController ctrlWrM = TextEditingController();
    ctrlIMI.text = imeiNo;
    ctrlWrM.text = warranty.toString();

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Update Product Details'),
            content: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Form(
                  key: formKey,
                  child: SizedBox(
                    height: 260,
                    child: Column(
                      children: [
                        Text('Category : $catName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                        const SizedBox(height: 15,),
                        DropdownMenu<ProductModel>(
                          controller: textFieldModelList,
                          hintText: 'Model',
                          width: 275,
                          dropdownMenuEntries: selectedModel,
                          initialSelection: initialSelectedModel = activeModelList[indexOfInitialSelection],
                          inputDecorationTheme: const InputDecorationTheme(
                            filled: true,
                            fillColor: Color(0x6467B4BE),
                            contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                            border: OutlineInputBorder(),
                          ),
                          onSelected: (ProductModel? mdl) {
                            mdlId = mdl!.modelId;
                            mdlName = mdl.modelName;
                            mdlDis= mdl.modelDescription;
                          },
                        ),
                        const SizedBox(height: 15,),
                        TextFormField(
                          maxLength: 12,
                          controller: ctrlIMI,
                          decoration: InputDecoration(
                            counterText: '',
                            labelText: 'Device ID',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.teal.shade50,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please fill out this field';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15,),
                        TextFormField(
                          controller: ctrlWrM,
                          validator: (value){
                            if(value==null || value.isEmpty){
                              return 'Please fill out this field';
                            }
                            return null;
                          },
                          maxLength: 2,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.teal.shade50,
                            labelText: 'Warranty(Month)',
                            suffixIcon: const Icon(Icons.close),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              MaterialButton(
                color: Colors.red,
                textColor: Colors.white,
                child: const Text('Cancel'),
                onPressed: () async {
                  Navigator.pop(context);
                },
              ),
              MaterialButton(
                color: Colors.green,
                textColor: Colors.white,
                child: const Text('Update'),
                onPressed: () async {
                  if (formKey.currentState!.validate())
                  {
                    try {
                      final body = {
                        "productId": productId,
                        "modelId": mdlId,
                        "modelName": mdlDis,
                        "deviceId": ctrlIMI.text.trim(),
                        "warrantyMonths": ctrlWrM.text,
                        'modifyUser': userId
                      };
                      var response = await repository.updateProduct(body);
                      if (response.statusCode == 200) {
                        final Map<String, dynamic> jsonData = jsonDecode(response.body);
                        if (jsonData["code"] == 200) {
                          for (var item in productInventoryList) {
                            if (item.productId == productId) {
                              item.deviceId = ctrlIMI.text.trim();
                              item.warrantyMonths = int.parse(ctrlWrM.text);
                              break;
                            }
                          }
                          GlobalSnackBar.show(context, jsonData["message"], 200);
                          Navigator.pop(context);
                        } else {
                          debugPrint("API Error: ${jsonData['message']}");
                          GlobalSnackBar.show(context, jsonData["message"], jsonData["code"]);
                          Navigator.pop(context);
                        }
                      } else {
                        debugPrint("HTTP Error: ${response.statusCode}");
                      }
                    } catch (error, stackTrace) {
                      debugPrint('Error fetching models: $error');
                      debugPrint(stackTrace.toString());
                    } finally {
                      safeNotify();
                    }
                  }
                },
              ),
            ],
          );
        });
  }

  Future<void> displayReplaceProductDialog(BuildContext context, int catId, String catName, String mdlName, int mdlId, String imeiNo, int warranty, int productId, int customerId, int modelId) async
  {
    String selectedOption = 'Option 1';

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Product Replace From'),
              content: SizedBox(
                height: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'Option 1',
                          label: Text('My Stock'),
                          icon: Icon(Icons.looks_one),
                        ),
                        ButtonSegment(
                          value: 'Option 2',
                          label: Text('Other device'),
                          icon: Icon(Icons.looks_two),
                        ),
                      ],
                      selected: <String>{selectedOption},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          selectedOption = newSelection.first;
                        });
                      },
                    ),
                    SizedBox(
                      height: 250,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16,),
                          Column(
                            children: [
                              selectedOption=='Option 1'?SizedBox(
                                child: DropdownButtonFormField<StockModel>(
                                  value: selectedStock,
                                  hint: const Text("Select your stock"),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
                                    filled: true,
                                    fillColor: Colors.teal.shade50,
                                  ),
                                  isExpanded: true, // Ensure dropdown expands to fit content
                                  items: stockEntries,
                                  onChanged: (StockModel? newValue) {
                                    selectedStock = newValue;
                                  },
                                ),
                              ):
                              Row(
                                children: [
                                  SizedBox(
                                    width: 200,
                                    child: TextFormField(
                                      maxLength: 12,
                                      controller: imeiController,
                                      decoration: InputDecoration(
                                        counterText: '',
                                        labelText: 'Device ID',
                                        hintText: 'Please enter New device id',
                                        border: const OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.teal.shade50,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                                      ),
                                      onChanged: (value) {
                                        if (value.trim().isEmpty){
                                          setState(() {
                                            imeiController.text = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10,),
                                  TextButton(
                                    onPressed: () async {
                                    },
                                    child: const Text('verify'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          imeiController.text.trim().isNotEmpty ? const SizedBox(
                            width: 250,
                            child: Column(
                              children: [
                                Text('data'),
                              ],
                            ),
                          )
                              : const SizedBox(),
                          SizedBox(height: 16,),
                          const Text('TO'),
                          const Divider(),
                          Text('Category : $catName'),
                          const SizedBox(height: 5),
                          Text('Model : $mdlName'),
                          const SizedBox(height: 5),
                          Text('IMEI No : $imeiNo'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                MaterialButton(
                  color: Colors.red,
                  textColor: Colors.white,
                  child: const Text('Cancel'),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> fetchFilterData(
      dynamic categoryId,
      dynamic modelId,
      dynamic value) async {

    filterProductInventoryList.clear();

    if (value == null || value.toString().trim().isEmpty) {
      safeNotify();
      return;
    }

    try {
      var response = await repository.fetchFilteredProduct({
        "userId": userId,
        "userType": userRole.name == 'admin' ? 1 : 2,
        "categoryId": categoryId == 0 ? null : categoryId,
        "modelId": modelId == 0 ? null : modelId,
        "deviceId": value,
      });

      if (isDisposed) return;

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);

        if (res["code"] == 200) {
          List<dynamic> data = res["data"] ?? [];

          filterProductInventoryList =
              data.map((e) => InventoryModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint("Filter error: $e");
    }

    safeNotify();
  }


  bool isName(String value) {
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    return nameRegex.hasMatch(value);
  }

  void clearSearch() {
    filterProductInventoryList.clear();
    safeNotify();
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

}