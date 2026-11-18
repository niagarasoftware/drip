import 'package:http/http.dart' as http;
import 'package:oro_drip_irrigation/services/http_service.dart';


class IrrigationRepository{

  HttpService httpService = HttpService();

  Future<http.Response> getUserLogConfig(body) async {
    return await httpService.postRequest('/user/logConfig/get', body);
  }

  Future<http.Response> getUserNames(body) async {
    return await httpService.postRequest('/user/configMaker/getAsDefault', body);
  }

  Future<http.Response> createUserLogConfig(body) async {
    return await httpService.postRequest('/user/logConfig/create', body);
  }

  Future<http.Response> updateUserLogConfig(body) async {
    return await httpService.postRequest('/user/logConfig/update', body);
  }

  Future<http.Response> deleteUserLogConfig(body) async {
    return await httpService.postRequest('/user/logConfig/delete', body);
  }

  Future<http.Response> getLogDateWise(body) async {
    return await httpService.postRequest('/user/log/gem/get', body);
  }

  Future<http.Response> getNovaLogDateWise(body) async {
    return await httpService.postRequest('/user/log/nova/get', body);
  }

  Future<http.Response> getOmsLog(body) async {
    return await httpService.postRequest('/user/log/oms/get', body);
  }
}