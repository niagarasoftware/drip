import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../repository/repository.dart';
import '../utils/enums.dart';
import '../utils/routes.dart';
import '../utils/shared_preferences_helper.dart';

class BaseHeaderViewModel extends ChangeNotifier {
  bool _isDisposed = false;

  int selectedIndex = 0;
  int hoveredIndex = -1;
  final List<String> menuTitles;

  MainMenuSegment _segmentView = MainMenuSegment.dashboard;
  MainMenuSegment get mainMenuSegmentView => _segmentView;

  final Repository repository;
  Map<String, dynamic>? jsonDataMap;
  final TextEditingController txtFldSearch = TextEditingController();

  BaseHeaderViewModel({
    required this.repository,
    required this.menuTitles,
  });

  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    txtFldSearch.dispose();
    super.dispose();
  }

  void updateMainMenuSegmentView(MainMenuSegment newView) {
    _segmentView = newView;
    selectedIndex = newView.index;
    safeNotify();
  }

  Future<void> fetchCategoryModelList(int userId, UserRole userRole) async {
    try {
      Map<String, dynamic> body = {
        "userId": userId,
        "userType": userRole.name == 'admin' ? 1 : 2,
      };

      final response = await repository.fetchAllCategoriesAndModels(body);

      if (_isDisposed) return; // STOP

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody["code"] == 200) {
          jsonDataMap = responseBody;
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (!_isDisposed) safeNotify();
    }
  }

  void onDestinationSelectingChange(int index) {
    selectedIndex = index;
    safeNotify();
  }

  void onHoverChange(int index) {
    hoveredIndex = index;
    safeNotify();
  }

  void clearSearch() {
    txtFldSearch.clear();
    safeNotify();
  }

  Future<void> logout(BuildContext context) async {
    await PreferenceHelper.clearAll();

    if (!context.mounted) return;

    const route = kIsWeb ? Routes.login : Routes.loginOtp;
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
          (_) => false,
    );
  }
}