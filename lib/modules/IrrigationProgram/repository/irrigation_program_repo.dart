import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/http_service.dart';

class IrrigationProgramRepository {
  final HttpService apiService;
  IrrigationProgramRepository(this.apiService);

  Future<http.Response> getUserProgramSequence(body) async {
    return await apiService.postRequest('/user/program/sequence/get', body);
  }

  Future<http.Response> getUserProgramSchedule(body) async {
    return await apiService.postRequest('/user/program/schedule/get', body);
  }

  Future<http.Response> getUserProgramCondition(body) async {
    return await apiService.postRequest('/user/program/condition/get', body);
  }

  Future<http.Response> getUserProgramSelection(body) async {
    return await apiService.postRequest('/user/program/selection/get', body);
  }

  Future<http.Response> getUserProgramAlarm(body) async {
    return await apiService.postRequest('/user/program/alarm/get', body);
  }

  Future<http.Response> getUserProgramDetails(body) async {
    return await apiService.postRequest('/user/program/details/get', body);
  }
  // logic changed for the site issue that cause payload update to different site
  Future<http.Response> getUserConfigMaker(body) async {
    try {
      final response = await apiService.postRequest('/user/configMaker/get', body);
      if (response.statusCode == 200) {
        final bodyJson = jsonDecode(response.body);
        if (bodyJson is Map && bodyJson['code'] == 200 && bodyJson['data'] != null) {
          return response;
        }
      }
    } catch (_) {}
    return await apiService.postRequest('/user/configMaker/getAsDefault', body);
  } //still here

  Future<http.Response> getUserProgramWaterAndFert(body) async {
    return await apiService.postRequest('/user/program/waterAndFert/get', body);
  }

  Future<http.Response> getUserFertilizerSet(body) async {
    return await apiService.postRequest('/user/planning/fertilizerSet/get', body);
  }

  Future<http.Response> getProgramLibraryData(body) async {
    return await apiService.postRequest('/user/program/getLibrary', body);
  }

  Future<http.Response> createUserProgram(body) async {
    return await apiService.postRequest('/user/program/create', body);
  }

  Future<http.Response> inactiveUserProgram(body) async {
    return await apiService.putRequest('/user/program/inactive', body);
  }

  Future<http.Response> activeUserProgram(body) async {
    return await apiService.putRequest('/user/program/active', body);
  }

  Future<http.Response> deleteUserProgram(body) async {
    return await apiService.putRequest('/user/program/delete', body);
  }

  Future<http.Response> createProgramFromCopy(body) async {
    return await apiService.postRequest('/user/program/createFromCopy', body);
  }

  Future<http.Response> updateProgramDetails(body) async {
    // return await apiService.putRequest('/user/program/updateDetails', body);
    return await apiService.putRequest('/', body);
  }

  Future<http.Response> getDayCountRtc(body) async {
    return await apiService.postRequest('/user/planning/dayCountRtc/get', body);
  }

  Future<http.Response> createDayCountRtc(body) async {
    return await apiService.postRequest('/user/planning/dayCountRtc/create', body);
  }

 /* post => /api/v1/user/planning/dayCountRtc/get => userId, controllerId
  post => /api/v1/user/planning/dayCountRtc/create => userId, controllerId, dayCountRtc, createUser*/
}