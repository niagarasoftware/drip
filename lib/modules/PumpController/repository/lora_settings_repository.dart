import '../../../services/http_service.dart';
import 'package:http/http.dart' as http;

class LoraSettingsRepository {
  final HttpService apiService;
  LoraSettingsRepository(this.apiService);

  Future<http.Response> getLoraSettings(body) async {
    return await apiService.postRequest('/user/deviceList/loraFrequency/get', body);
  }

  Future<http.Response> updateLoraSettings(body) async {
    return await apiService.putRequest('/user/deviceList/loraFrequency/update', body);
  }
}