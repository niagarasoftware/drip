import 'package:http/http.dart' as http;
import 'package:oro_drip_irrigation/services/http_service.dart';

class ConstantRepository{
  HttpService httpService = HttpService();

  Future<http.Response> getUserConstant(body) async {
    return await httpService.postRequest('/user/constant/get', body);
  }

  Future<http.Response> getUserDefaultConfigMaker(body) async {
    return await httpService.postRequest('/user/configMaker/getAsDefault', body);
  }

  Future<http.Response> createUserConstant(body) async {
    return await httpService.postRequest('/user/constant/create', body);
  }

}