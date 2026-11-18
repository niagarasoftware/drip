import 'package:http/http.dart' as http;

abstract class ApiService {
  Future<http.Response> getRequest(String endpoint, {String? type, Map<String, String>? queryParams});
  Future<http.Response> postRequest(String endpoint, Map<String, dynamic> bodyData);
  Future<http.Response> putRequest(String endpoint, Map<String, dynamic> bodyData);
  Future<http.Response> deleteRequest(String endpoint, Map<String, dynamic> bodyData);
}