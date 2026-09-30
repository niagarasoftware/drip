import '../../../services/http_service.dart';
import 'package:http/http.dart' as http;

class SystemDefinitionsRepository {
  final HttpService apiService;
  SystemDefinitionsRepository(this.apiService);

  Future<http.Response> getUserPlanningSystemDefinition(body) async {
    print(body);
    return await apiService.postRequest('/user/planning/systemDefinition/get', body);
  }

  Future<http.Response> createUserPlanningSystemDefinition(body) async {
    return await apiService.postRequest('/user/planning/systemDefinition/create', body);
  }
}