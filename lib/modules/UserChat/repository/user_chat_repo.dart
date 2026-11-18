import '../../../services/http_service.dart';
import 'package:http/http.dart' as http;

class UserChatRepository {
  final HttpService apiService;
  UserChatRepository(this.apiService);

  Future<http.Response> getUserDealerDetails(body) async {
    return await apiService.postRequest('/user/getDealerDetails', body);
  }

  Future<http.Response> getUserChat(body) async {
    return await apiService.postRequest('/user/chat/get', body);
  }

  Future<http.Response> updateUserChatReadStatus(body) async {
    return await apiService.putRequest('/user/chat/updateReadStatus', body);
  }

  Future<http.Response> createUserChat(body) async {
    return await apiService.postRequest('/user/chat/create', body);
  }

}