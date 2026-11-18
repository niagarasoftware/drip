import 'package:http/http.dart' as http;
import 'package:oro_drip_irrigation/services/http_service.dart';


class GlobalLimitRepository{

  HttpService httpService = HttpService();

  Future<http.Response> getUserGlobalLimit(body) async {
    return await httpService.postRequest('/user/planning/globalLimit/get', body);
  }

  Future<http.Response> createUserGlobalLimit(body) async {
    return await httpService.postRequest('/user/planning/globalLimit/create', body);
  }

}