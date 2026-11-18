import 'package:http/http.dart' as http;
import 'package:oro_drip_irrigation/services/http_service.dart';


class CalibrationRepository{
  HttpService httpService = HttpService();
  Future<http.Response> getUserCalibration(body) async {
    return await httpService.postRequest('/user/calibration/get', body);
  }

  Future<http.Response> createUserCalibration(body) async {
    return await httpService.postRequest('/user/calibration/create', body);
  }
}