import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../models/entry_form/product_category_model.dart';
import '../../../repository/repository.dart';
import '../../../utils/snack_bar.dart';

class CategoryFormViewModel extends ChangeNotifier {
  final Repository repository;

  bool isLoading = false;
  String errorMsg = '';

  final formKey = GlobalKey<FormState>();
  TextEditingController catName = TextEditingController();

  List<ProductCategoryModel> categoryList = <ProductCategoryModel>[];
  bool editCategory= false;
  int sldCatID = 0;

  CategoryFormViewModel(this.repository) {
    _setupInitialValues();
  }

  void _setupInitialValues() {

  }

  Future<void> getCategoryList() async {
    setLoading(true);
    try {
      var response = await repository.fetchCategory();
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          final cntList = jsonData["data"] as List;
          categoryList.clear();
          for (int i=0; i < cntList.length; i++) {
            categoryList.add(ProductCategoryModel.fromJson(cntList[i]));
          }
        }
      }
    } catch (error) {
      errorMsg = 'Error fetching category list: $error';
    } finally {
      setLoading(false);
    }
  }

  Future<void> inactiveCategory(BuildContext context, int userId, int categoryId, String status) async {
    setLoading(true);
    try {
      Map<String, Object> body = {
        'modifyUser': userId,
        'categoryId': categoryId,
      };

      final Response response;
      if(status=='1'){
        response = await repository.inActiveCategoryById(body);
      }else{
        response = await repository.activeCategoryById(body);
      }

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          getCategoryList();
          GlobalSnackBar.show(context, jsonData["message"], 200);
        }
      }
    } catch (error) {
      errorMsg = 'Error fetching category list: $error';
    } finally {
      setLoading(false);
    }
  }


  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void productEditing() {
    editCategory = !editCategory;
    catName.clear();
    notifyListeners();
  }

  Widget showAddAndEditForm(BuildContext context, bool edit, int userId, int categoryId)
  {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListTile(
              title: Text(edit?"Edit Category Name":"Add Category Name", style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text("Please fill out the name correctly.", style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(height: 10,),
                      TextFormField(
                        controller: catName,
                        validator: (value){
                          if(value==null ||value.isEmpty){
                            return 'Please fill out this field';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                          border: OutlineInputBorder(),
                          labelText: 'Category Name',
                          icon: Icon(Icons.contactless_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 60,
            child: ListTile(
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    child: const Text('Save'),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        try {
                          final Response response;
                          if(edit){
                            Map<String, Object> body = {
                              "categoryId": sldCatID.toString(),
                              'categoryName': catName.text,
                              'modifyUser': userId,
                              'smsFormat': '0',
                              'relayCount': '0',
                            };
                            response = await repository.updateCategory(body);
                          }else{
                            Map<String, Object> body = {
                              'categoryName': catName.text,
                              'createUser': userId,
                              'smsFormat': '0',
                              'relayCount': '0',
                            };
                            response = await repository.createCategory(body);
                          }

                          if (response.statusCode == 200) {
                            final jsonData = jsonDecode(response.body);
                            if (jsonData["code"] == 200) {
                              getCategoryList();
                              GlobalSnackBar.show(context, jsonData["message"], 200);
                              Navigator.pop(context);
                            }
                          }
                        } catch (error) {
                          errorMsg = 'Error fetching category list: $error';
                        } finally {
                          setLoading(false);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    catName.dispose();
  }
}