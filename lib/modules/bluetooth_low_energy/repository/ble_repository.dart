import 'package:http/http.dart' as http;
import 'package:oro_drip_irrigation/services/http_service.dart';

class BleRepository{
  HttpService httpService = HttpService();

  Future<http.Response> getNodeBluetoothSetting(body) async {
    return await httpService.postRequest('/user/deviceList/bluetoothSetting', body);
  }

}