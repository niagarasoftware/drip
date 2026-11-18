import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../repository/repository.dart';
import '../utils/enums.dart';
import '../utils/routes.dart';
import '../utils/shared_preferences_helper.dart';

class NavRailViewModel extends ChangeNotifier {

  final Repository repository;
  late Map<String, dynamic> jsonDataMap;

  late int selectedIndex;
  TextEditingController txtFldSearch = TextEditingController();
  bool searched = false;

  NavRailViewModel(this.repository){
    initState();
  }

  void initState() {
    selectedIndex = 0;
    notifyListeners();
  }

  void onDestinationSelectingChange(int index){
    selectedIndex = index;
    notifyListeners();
  }

  Future<void> getCategoryModelList(int userId, UserRole userRole) async {
    try {
      Map<String, dynamic> body = {
        "userId": userId,
        "userType": userRole.name == 'admin' ? 1 : 2,
      };

      var response = await repository.fetchAllCategoriesAndModels(body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody["code"] == 200) {
          jsonDataMap = responseBody;
        } else {
          debugPrint("API Error: ${responseBody['message']}");
        }
      }
    } catch (error) {
      debugPrint("Error: $error");
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout(context) async {
    await PreferenceHelper.clearAll();
    const route = kIsWeb ? Routes.login : Routes.loginOtp;
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false,);
    // Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false,);
  }

  void clearSearch() {
    txtFldSearch.clear();
    searched = false;
    notifyListeners();
  }

}