import '../../../services/http_service.dart';
import 'package:http/http.dart' as http;

class PreferenceRepository {
  final HttpService apiService;
  PreferenceRepository(this.apiService);
  Future<http.Response> getUserPreferenceSetting(body) async {
    return await apiService.postRequest('/user/preference/setting/get', body);
  }

  Future<http.Response> getUserPreferenceGeneral(body) async {
    return await apiService.postRequest('/user/preference/general/get', body);
  }

  Future<http.Response> getUserPreferenceCalibration(body) async {
    return await apiService.postRequest('/user/preference/calibration/get', body);
  }

  Future<http.Response> getUserPreferenceNotification(body) async {
    return await apiService.postRequest('/user/preference/notification/get', body);
  }

  Future<http.Response> createUserPreference(body) async {
    return await apiService.postRequest('/user/preference/create', body);
  }

  Future<http.Response> checkPassword(body) async {
    return await apiService.postRequest('/user/verifyPasskey', body);
  }

  Future<http.Response> getUserPreferenceValveSetting(body) async {
    return await apiService.postRequest('/user/planning/irrigationSetting/get', body);
  }

  Future<http.Response> createUserPreferenceValveSetting(body) async {
    return await apiService.postRequest('/user/planning/valveSetting/create', body);
  }

  Future<http.Response> createUserPreferenceMoistureSetting(body) async {
    return await apiService.postRequest('/user/planning/moistureSetting/create', body);
  }

  Future<http.Response> getUserPreferenceValveStandaloneSetting(body) async {
    return await apiService.postRequest('/user/planning/valveStandalone/get', body);
  }

  Future<http.Response> createUserPreferenceValveStandaloneSetting(body) async {
    return await apiService.postRequest('/user/planning/valveStandalone/create', body);
  }
}