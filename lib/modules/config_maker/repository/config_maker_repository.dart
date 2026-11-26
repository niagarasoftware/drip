import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oro_drip_irrigation/services/http_service.dart';

class ConfigMakerRepository{
  HttpService httpService = HttpService();

  Future<http.Response> getUserConfigMaker(body) async {
    print('config maker :: $body');
    try {
      final response = await httpService.postRequest('/user/configMaker/get', body);
      if (response.statusCode == 200) {
        final bodyJson = jsonDecode(response.body);
        if (bodyJson is Map && bodyJson['code'] == 200 && bodyJson['data'] != null) {
          return response;
        }
      }
    } catch (_) {}
    return await httpService.postRequest('/user/configMaker/getAsDefault', body);
  }

  Future<http.Response> productReplace(body) async {
    return await httpService.postRequest('/product/replace', body);
  }

  Future<http.Response> createUserConfigMaker(body) async {
    return await httpService.postRequest('/user/configMaker/create', body);
  }

  Future<http.Response> updateProduct(body) async {
    return await httpService.putRequest('/product/update', body);
  }

  Future<http.Response> checkProduct(body) async {
    return await httpService.postRequest('/product/forReplace', body);
  }

  Future<http.Response> getProductStock(body) async {
    return await httpService.postRequest('/product/getDealerStockForReplace', body);
  }
}