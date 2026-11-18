import 'dart:convert';
import 'package:flutter/cupertino.dart';

import '../../models/customer/notification_list_model.dart';
import '../../repository/repository.dart';
import '../../utils/snack_bar.dart';


class NotificationViewModel extends ChangeNotifier {
  final Repository repository;
  bool loadingState = false;

  List<NotificationListModel> notificationList = [];

  NotificationViewModel(this.repository);

  Future<void> getNotificationList(int userId, int controllerId) async {
    setLoading(true);
    final body = {"userId": userId, "controllerId": controllerId};

    try {
      final response = await repository.fetchUserPushNotificationType(body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["code"] == 200 && data.containsKey("data")) {
          final List<dynamic> dataList = data['data'];
          notificationList =
              dataList.map((e) => NotificationListModel.fromJson(e)).toList();
        }
      }
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateNotificationList(BuildContext context, int userId, int controllerId, int modifyUser) async {

    final selectedIds = getSelectedIds();
    debugPrint("Update payload: $selectedIds");

    final body = {
      "userId": userId,
      "controllerId": controllerId,
      "modifyUser": controllerId,
      "pushNotification": selectedIds['pushNotificationIds'],
      "sendAndReceive": selectedIds['sendAndReceiveIds']
    };

    try {
      final response = await repository.updateUserPushNotificationType(body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        GlobalSnackBar.show(context, data["message"], 200);
      }
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
    } finally {
      setLoading(false);
    }
  }

  void toggleNotification(int index, bool value, {bool isPush = true}) {
    final item = notificationList[index];

    if (isPush) {
      item.pushNotification = value;
    } else {
      item.sendAndReceive = value;
    }
    notifyListeners();
  }

  Map<String, List<int>> getSelectedIds() {
    final pushIds = notificationList
        .where((n) => n.pushNotification)
        .map((n) => n.pushNotificationId)
        .toList();

    final sendReceiveIds = notificationList
        .where((n) => n.sendAndReceive)
        .map((n) => n.pushNotificationId)
        .toList();

    return {
      "pushNotificationIds": pushIds,
      "sendAndReceiveIds": sendReceiveIds,
    };
  }

  void setLoading(bool state) {
    loadingState = state;
    notifyListeners();
  }
}