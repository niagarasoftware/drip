import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/standalone.dart' as tz;
import '../../repository/repository.dart';
import '../../services/communication_service.dart';
import '../../utils/constants.dart';
import '../../utils/snack_bar.dart';


class GeneralSettingViewModel extends ChangeNotifier {
  final Repository repository;

  bool isLoading = false;
  String errorMessage = "";

  int? customerId;
  int? controllerId;
  int? userId;
  bool? isSubUser;

  List<Map<String, dynamic>> subUsers = [];

  String farmName = '';
  String controllerCategory = '';
  String modelName = '';
  String deviceId = '';
  String categoryName = '';
  String controllerLocation = '';
  String controllerVersion = '';
  String newVersion = '';
  int groupId = 0;
  int modelId = 0;

  String? countryCode;
  String? simNumber;

  String? selectedTimeZone;
  String currentDate = '';
  String currentTime = '';

  double opacity = 1.0;
  Timer? _timer;

  final List<String> timeZones =
  tz.timeZoneDatabase.locations.keys.toList();

  GeneralSettingViewModel(this.repository);

  void initIds({
    required int customerId,
    required int controllerId,
    int? userId,
    bool? isSubUser,
  }) {
    this.customerId = customerId;
    this.controllerId = controllerId;
    this.userId = userId;
    this.isSubUser = isSubUser;
  }


  Future<void> getControllerInfo() async {
    if (customerId == null || controllerId == null) return;

    setLoading(true);

    try {
      Map<String, Object> body = {
        "userId": customerId!,
        "controllerId": controllerId!
      };
       var response = await repository.fetchMasterControllerDetails(body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["code"] == 200) {
          final firstItem =
          (data["data"] as List).isNotEmpty ? data["data"][0] : {};

          farmName = firstItem['groupName'] ?? "";
          controllerCategory = firstItem['deviceName'] ?? "";
          modelName = firstItem['modelName'] ?? "";
          deviceId = firstItem['deviceId'] ?? "";
          categoryName = firstItem['categoryName'] ?? "";
          modelId = firstItem['modelId'] ?? 0;
          groupId = firstItem['groupId'] ?? 0;

          countryCode = firstItem['countryCode']  ?? "";
          simNumber = firstItem['simNumber'] ?? "";

          controllerVersion = firstItem['hwVersion'] ?? "";
          newVersion = firstItem['availableHwVersion'] ?? "";

          controllerLocation = firstItem['controllerLocation'] ?? "";

          updateCurrentDateTime(firstItem['timeZone'] ?? "");

          if (controllerVersion != newVersion) {
            timerFunction();
          } else {
            _timer?.cancel();
          }
        }
      }
    } catch (e) {
      debugPrint("Error getControllerInfo: $e");
    } finally {
      setLoading(false);
    }
  }


  Future<void> getSubUserList() async {
    if (customerId == null) return;

    setLoading(true);

    try {
      Map<String, Object> body = {"userId": customerId!};

      var response = await repository.fetchSubUserList(body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["code"] == 200) {
          print("data shared user --> $data");
           subUsers = List<Map<String, dynamic>>.from(data["data"]);
        }
      }
    } catch (e) {
      debugPrint("Error getSubUserList: $e");
    } finally {
      setLoading(false);
    }
  }


  void updateCurrentDateTime(String timeZone) {
    final tz.Location location = tz.getLocation(timeZone);
    final tz.TZDateTime now = tz.TZDateTime.now(location);

    currentDate = DateFormat.yMd().format(now);
    currentTime = DateFormat.jm().format(now);

    selectedTimeZone = timeZone;
    notifyListeners();
  }


  Future<void> updateMasterDetails(BuildContext context) async {
    if (customerId == null || controllerId == null) return;

    setLoading(true);

    try {
      Map<String, Object?> body = {
        "userId": customerId,
        "controllerId": controllerId,
        "deviceName": controllerCategory,
        "timeZone": selectedTimeZone,
        "controllerLocation": controllerLocation,
        "groupId": groupId,
        "groupName": farmName,
        "countryCode": [...AppConstants.ecoGemModelList, ...AppConstants.gsmModelList]
            .contains(modelId) ? countryCode : null,
        "simNumber": [...AppConstants.ecoGemModelList, ...AppConstants.gsmModelList]
            .contains(modelId) ? simNumber : null,
        "modifyUser": userId,
      };

      final payLoadFinal = jsonEncode({"6800": {"6801": selectedTimeZone}});
      final commService = Provider.of<CommunicationService>(context, listen: false);
      commService.sendCommand(serverMsg: '', payload: payLoadFinal);

      var response = await repository.updateMasterDetails(body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        GlobalSnackBar.show(context, data["message"], data["code"]);
      }
    } catch (e) {
      debugPrint("Error updateMasterDetails: $e");
    } finally {
      setLoading(false);
    }
  }

  Future<void> updatedSubUserPermission(Map<String, dynamic> body, int subUsrId, BuildContext context) async {
    try {
      var response = await repository.updatedSubUserPermission(body);
      if (response.statusCode == 200) {
        print(response.body);
        final data = jsonDecode(response.body);
        GlobalSnackBar.show(context, data["message"], data["code"]);
        Navigator.pop(context);
      }
    } catch (error) {
      debugPrint('Error fetching device list: $error');
    }
  }

  Future<List<dynamic>?> getSubUserSharedDeviceList(Map<String, dynamic> body) async {
    try {
      var response = await repository.getSubUserSharedDeviceList(body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["code"] == 200) {
          var list = data['data'] as List;
          return list;
        }
      }
    } catch (error) {
      debugPrint('Error fetching device list: $error');
    }
    return null;
  }

  Future<void> updateCustomerList(Map<String, dynamic> json) async {
    if (json['status'] != 'success') return;
    debugPrint(json as String?);
  }


  void timerFunction() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      opacity = opacity == 1.0 ? 0.0 : 1.0;
      notifyListeners();
    });
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}