import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/shared_preferences_helper.dart';
import 'api_service.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

class HttpService implements ApiService {
  @override
  Future<http.Response> getRequest(String endpoint, {String? type, Map<String, String>? queryParams}) async {
    final token = await PreferenceHelper.getToken();
    final uri = Uri.parse('${AppConstants.apiUrl}$endpoint').replace(queryParameters: queryParams);
    AppLog.log('uri:$uri');
    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    return type == 'MQTTCONFIG'
        ? http.get(Uri.parse(endpoint), headers: headers)
        : http.get(uri, headers: headers);
  }

  @override
  Future<http.Response> postRequest(String endpoint, Map<String, dynamic> bodyData) async {

    AppLog.log('bodyData : $bodyData');
    AppLog.log('${AppConstants.apiUrl}$endpoint');
    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    return http.post(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(bodyData),
    );

  }

  @override
  Future<http.Response> putRequest(String endpoint, Map<String, dynamic> bodyData) async {
    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    return http.put(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(bodyData),
    );
  }

  @override
  Future<http.Response> deleteRequest(String endpoint, Map<String, dynamic> bodyData) async {
    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    return http.delete(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(bodyData),
    );

  }
}
