import 'package:http/http.dart' as http;

import '../../../services/http_service.dart';
class LogRepository {
  final HttpService apiService;
  LogRepository(this.apiService);

  Future<http.Response> getUserPumpHourlyLog(body, bool isNode) async{
    return await apiService.postRequest('/user/log/${isNode ? 'nodePumpHourly': 'pumpHourly'}/get', body);
  }

  Future<http.Response> getUserPumpLog(body, bool isNode) async{
    return await apiService.postRequest('/user/log/${isNode ? 'nodePump': 'pump'}/get', body);
  }

  Future<http.Response> getUserVoltageLog(body, bool isNode) async{
    return await apiService.postRequest('/user/log/${isNode ? 'nodePumpVoltage': 'pumpVoltage'}/get', body);
  }

  Future<http.Response> getUserNodePumpList(body) async{
    return await apiService.postRequest('/user/deviceList/getNodePumpList', body);
  }
}