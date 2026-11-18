import '../../../services/http_service.dart';
import 'package:http/http.dart' as http;

class ScheduleViewRepository {
  final HttpService apiService;
  ScheduleViewRepository(this.apiService);

  Future<http.Response> updateUserSequencePriority(body) async {
    return await apiService.postRequest('/user/sequencePriority/update', body);
  }

  Future<http.Response> createUserSentAndReceivedMessageManually(body) async {
    return await apiService.postRequest('/user/sentAndReceivedMessage/createManually', body);
  }

  Future<http.Response> getUserIrrigationLog(body) async {
    return await apiService.postRequest('/user/log/gem/get', body);
  }
}