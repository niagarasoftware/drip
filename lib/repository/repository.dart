import 'package:http/http.dart' as http;
import '../services/http_service.dart';


abstract class ApiRepository {
  Future<dynamic> validateUser(Map<String, dynamic> body);
  Future<dynamic> checkLoginAuth(Map<String, dynamic> body);
  Future<http.Response> fetchAllMySalesReports(Map<String, dynamic> body);
}

class RepositoryImpl implements ApiRepository {
  final HttpService apiService;
  RepositoryImpl(this.apiService);

  @override
  Future<dynamic> checkLoginAuth(Map<String, dynamic> body) async {
    return apiService.postRequest('/auth/signIn', body);
  }

  @override
  Future<dynamic> validateUser(Map<String, dynamic> body) async {
    return apiService.postRequest('/user/check', body);
  }

  @override
  Future<http.Response> fetchAllMySalesReports(Map<String, dynamic> body) async {
    return await apiService.postRequest('/product/getSalesReport', body);
  }
}

class Repository{
  final HttpService apiService;
  Repository(this.apiService);

  Future<http.Response> checkLoginAuth(body) async {
    return apiService.postRequest('/auth/signIn', body);
  }

  Future<http.Response> checkMobileNumber(body) async {
    return apiService.postRequest('/auth/verification', body);
  }

  Future<http.Response> fetchAllMySalesReports(body) async {
    return await apiService.postRequest('/product/getSalesReport', body);
  }

  Future<http.Response> fetchMyStocks(body) async {
    return await apiService.postRequest('/product/getStock', body);
  }

  Future<http.Response> userVerifyWithDeviceToken(body) async {
    return await apiService.postRequest('/userVerifyWithDeviceToken', body);
  }

  Future<http.Response> fetchMyCustomerList(body) async {
    return await apiService.postRequest('/user/getUserList', body);
  }

  Future<http.Response> searchAllMyCustomers(query) async {
    return await apiService.postRequest('/user/search', query);
  }

  Future<http.Response> fetchAllMyInventory(body) async {
    return await apiService.postRequest('/product/getInventory', body);
  }

  Future<http.Response> fetchAllCategoriesAndModels(body) async {
    return await apiService.postRequest('/product/getCategoryModelAndDeviceId', body);
  }

  Future<http.Response> fetchFilteredProduct(body) async {
    return await apiService.postRequest('/product/getByFilter', body);
  }

  Future<http.Response> fetchDeviceList(body) async {
    return await apiService.postRequest('/product/getList', body);
  }

  Future<http.Response> fetchMasterControllerDetails(body) async {
    return await apiService.postRequest('/user/deviceList/getMasterDetails', body);
  }

  Future<http.Response> updateMasterDetails(body) async {
    return await apiService.putRequest('/user/deviceList/updateMasterDetails', body);
  }

  Future<http.Response> fetchSubUserList(body) async {
    return await apiService.postRequest('/user/sharedUser/get', body);
  }

  Future<http.Response> fetchUserPushNotificationType(body) async {
    return await apiService.postRequest('/user/deviceList/pushNotificationType/get', body);
  }

  Future<http.Response> updateUserPushNotificationType(body) async {
    return await apiService.putRequest('/user/deviceList/pushNotificationType/update', body);
  }

  Future<http.Response> fetchCountryList() async {
    return await apiService.getRequest('/country/get');
  }

  Future<http.Response> fetchStateList(countryId) async {
    return await apiService.getRequest('/state/get/$countryId');
  }

  Future<http.Response> fetchSentAndReceivedData(body) async {
    return await apiService.postRequest('/user/sentAndReceivedMessage/getStatus', body);
  }

  Future<http.Response> fetchSensorHourlyData(body) async {
    return await apiService.postRequest('/user/log/sensorHourly/get', body);
  }

  Future<http.Response> fetchNodeHourlyData(body) async {
    return await apiService.postRequest('/user/log/nodeStatusHourly/get', body);
  }

  Future<http.Response> fetchSentAndReceivedHardwarePayload(body) async {
    return await apiService.postRequest('/user/sentAndReceivedMessage/getHardwarePayload', body);
  }


  Future<http.Response> createCustomerAccount(body) async {
    return await apiService.postRequest('/user/create', body);
  }

  Future<http.Response> createSubUserAccount(body) async {
    return await apiService.postRequest('/user/createWithMainUser', body);
  }

  Future<http.Response> fetchActiveCategory(body) async {
    return await apiService.postRequest('/category/getByActive', body);
  }

  Future<http.Response> fetchCategory() async {
    return await apiService.getRequest('/category/get');
  }

  Future<http.Response> createCategory(body) async {
    return await apiService.postRequest('/category/create', body);
  }

  Future<http.Response> updateCategory(body) async {
    return await apiService.putRequest('/category/update', body);
  }

  Future<http.Response> updateUserNodeDetails(body) async {
    return await apiService.putRequest('/user/deviceList/updateNodeDetails', body);
  }

  Future<http.Response> inActiveCategoryById(body) async {
    return await apiService.putRequest('/category/inactive', body);
  }

  Future<http.Response> activeCategoryById(body) async {
    return await apiService.putRequest('/category/active', body);
  }

  Future<http.Response> fetchModelByCategoryId(body) async {
    return await apiService.postRequest('/model/getByCategoryId', body);
  }

  Future<http.Response> checkProduct(body) async {
    return await apiService.postRequest('/product/checkStatus', body);
  }

  Future<http.Response> createProduct(body) async {
    return await apiService.postRequest('/product/create', body);
  }

  Future<http.Response> updateProduct(body) async {
    return await apiService.putRequest('/product/update', body);
  }

  Future<http.Response> updateUserDetails(body) async {
    return await apiService.putRequest('/user/updateDetails', body);
  }

  Future<http.Response> addProductToDealer(body) async {
    return await apiService.postRequest('/product/addToDealer', body);
  }

  Future<http.Response> addProductToSubDealer(body) async {
    return await apiService.postRequest('/product/addToSubdealer', body);
  }

  Future<http.Response> addProductToCustomer(body) async {
    return await apiService.postRequest('/product/addToCustomer', body);
  }

  Future<http.Response> removeProductFromCustomer(body) async {
    return await apiService.deleteRequest('/product/removeFromCustomer', body);
  }

  Future<http.Response> fetchUserGroupWithMasterList(body) async {
    return await apiService.postRequest('/user/deviceList/getGroupWithMaster', body);
  }

  Future<http.Response> fetchMasterProductStock(body) async {
    return await apiService.postRequest('/product/getMasterStock', body);
  }

  Future<http.Response> createUserGroupAndDeviceList(body) async {
    return await apiService.postRequest('/user/deviceList/createAndGroup', body);
  }

  Future<http.Response> createNewMaster(body) async {
    return await apiService.postRequest('/user/deviceList/createWithGroup', body);
  }

  Future<http.Response> fetchAllMySite(body) async {
     return await apiService.postRequest('/user/dashboard', body);
  }

  Future<http.Response> fetchSharedUserSite(body) async {
    return await apiService.postRequest('/sharedUser/userDevice/get', body);
  }

  Future<http.Response> fetchSiteAiAdvisoryData(body) async {
    return await apiService.postRequest('/user/deviceList/aiAdvisory/get', body);
  }

  Future<http.Response> updateSiteAiAdvisoryData(body) async {
    return await apiService.putRequest('/user/deviceList/aiAdvisory/update', body);
  }

  Future<http.Response> updateControllerCommunicationMode(body) async {
    return await apiService.putRequest('/user/deviceList/updateCommunicationMode', body);
  }

  Future<http.Response> getUserFilterBackwasing(body) async {
    return await apiService.postRequest('/user/planning/filterBackwashing/get', body);
  }


  Future<http.Response> UpdateFilterBackwasing(body) async {
    return await apiService.postRequest('/user/planning/filterBackwashing/create', body);
  }
  Future<http.Response> getUserwaterSource(body) async {
    return await apiService.postRequest('/user/planning/waterSource/get', body);
  }
  Future<http.Response> UpdatewaterSource(body) async {
    return await apiService.postRequest('/user/planning/waterSource/create', body);
  }
  Future<http.Response> getUservirtualwatermeter(body) async {
    return await apiService.postRequest('/user/planning/virtualwatermeter/get', body);
  }
  Future<http.Response> Updatevirtualwatermeter(body) async {
    return await apiService.postRequest('/user/planning/virtualwatermeter/create', body);
  }
  Future<http.Response> getUserfrostProtection(body) async {
    return await apiService.postRequest('/user/planning/frostProtectionAndRainDelay/get', body);
  }
  Future<http.Response> UpdatefrostProtection(body) async {
    return await apiService.postRequest('/user/planning/frostProtectionAndRainDelay/create', body);
  }
  Future<http.Response> getUserPlanningPumpCondition(body) async {
    return await apiService.postRequest('/user/planning/pumpCondition/get', body);
  }
  Future<http.Response> updateUserPlanningPumpCondition(body) async {
    return await apiService.postRequest('/user/planning/pumpCondition/create', body);
  }

  ///Todo: Program urls
  Future<http.Response> getUserProgramSequence(body) async {
    return await apiService.postRequest('/user/program/sequence/get', body);
  }

  Future<http.Response> getUserProgramSchedule(body) async {
    return await apiService.postRequest('/user/program/schedule/get', body);
  }

  Future<http.Response> getUserProgramCondition(body) async {
    return await apiService.postRequest('/user/program/condition/get', body);
  }

  Future<http.Response> getUserProgramSelection(body) async {
    return await apiService.postRequest('/user/program/selection/get', body);
  }

  Future<http.Response> getUserProgramAlarm(body) async {
    return await apiService.postRequest('/user/program/alarm/get', body);
  }

  Future<http.Response> getUserProgramDetails(body) async {
    return await apiService.postRequest('/user/program/details/get', body);
  }

  Future<http.Response> getUserConfigMaker(body) async {
    return await apiService.postRequest('/user/configMaker/getAsDefault', body);
  }

  Future<http.Response> getdealerDefinition(body) async {
    return await apiService.postRequest('/user/dealerDefinition/get', body);
  }

  Future<http.Response> createdealerDefinition(body) async {
    return await apiService.postRequest('/user/dealerDefinition/create', body);
  }

  Future<http.Response> updateUserNames(body) async {
     return await apiService.putRequest('/user/configMaker/name/update', body);
  }

  Future<http.Response> getUserProgramWaterAndFert(body) async {
    return await apiService.postRequest('/user/program/waterAndFert/get', body);
  }

  Future<http.Response> getProgramLibraryData(body) async {
    return await apiService.postRequest('/user/program/getLibrary', body);
  }

  Future<http.Response> createUserProgram(body) async {
    return await apiService.postRequest('/user/program/create', body);
  }

  Future<http.Response> inactiveUserProgram(body) async {
    return await apiService.putRequest('/user/program/inactive', body);
  }

  Future<http.Response> activeUserProgram(body) async {
    return await apiService.putRequest('/user/program/active', body);
  }

  Future<http.Response> deleteUserProgram(body) async {
    return await apiService.putRequest('/user/program/delete', body);
  }

  Future<http.Response> createProgramFromCopy(body) async {
    return await apiService.postRequest('/user/program/createFromCopy', body);
  }

  Future<http.Response> updateProgramDetails(body) async {
    return await apiService.putRequest('/user/program/updateDetails', body);
  }


  ///Todo: Preference urls
  Future<http.Response> getUserPreferenceSetting(body) async {
    return await apiService.postRequest('/user/preference/setting/get', body);
  }

  Future<http.Response> getUserPreferenceGeneral(body) async {
    return await apiService.postRequest('/user/preference/general/get', body);
  }

  Future<http.Response> getUserPreferenceCalibration(body) async {
    return await apiService.postRequest('/user/preference/calibration/get', body);
  }

  Future<http.Response> getUserPreferenceNotification(body) async {
    return await apiService.postRequest('/user/preference/notification/get', body);
  }

  Future<http.Response> createUserPreference(body) async {
    return await apiService.postRequest('/user/preference/create', body);
  }

  Future<http.Response> checkPassword(body) async {
    return await apiService.postRequest('/user/check', body);
  }


  ///Todo: System definition urls
  Future<http.Response> getUserPlanningSystemDefinition(body) async {
    return await apiService.postRequest('/user/planning/systemDefinition/get', body);
  }

  Future<http.Response> createUserPlanningSystemDefinition(body) async {
    return await apiService.postRequest('/user/planning/systemDefinition/create', body);
  }


  ///Todo: Other planning urls
  Future<http.Response> getUserPlanningValveGroup(body) async {
    return await apiService.postRequest('/user/planning/valveGroup/get', body);
  }


  Future<http.Response> fetchCustomerProgramList(body) async {
    return await apiService.postRequest('/user/program/getNameList', body);
  }

  Future<http.Response> fetchUserManualOperation(body) async {
    return await apiService.postRequest('/user/manualOperation/recent/get', body);
  }

  Future<http.Response> getUserValveGroup(body) async {
    return await apiService.postRequest('/user/planning/valveGroup/get', body);
  }

  Future<http.Response> createUserValveGroup(body) async {
    return await apiService.postRequest('/user/planning/valveGroup/create', body);
  }

  Future<http.Response> fetchManualOperation(body) async {
    return await apiService.postRequest('/user/manualOperation/get', body);
  }

  Future<http.Response> updateStandAloneData(body) async {
    return await apiService.postRequest('/user/manualOperation/create', body);
  }

  Future<http.Response> fetchConstantData(body) async {
    return await apiService.postRequest('/user/constant/get', body);
  }

  Future<http.Response> saveConstantData(body) async {
    return await apiService.postRequest('/user/constant/create', body);
  }

  Future<http.Response> fetchConditionLibrary(body) async {
    return await apiService.postRequest('/user/planning/conditionLibrary/get', body);
  }

  Future<http.Response> getPlanningHiddenMenu(body) async {
    return await apiService.postRequest('/user/dealerDefinition/mainMenu/get', body);
  }

  Future<http.Response> getUserIrrigationLog(body) async {
    return await apiService.postRequest('/user/log/gem/get', body);
  }

  ///Todo: Schedule view urls
  Future<http.Response> updateUserSequencePriority(body) async {
    return await apiService.postRequest('/user/sequencePriority/update', body);
  }

  Future<http.Response> sendManualOperationToServer(body) async {
    return await apiService.postRequest('/user/sentAndReceivedMessage/createManually', body);
  }

  Future<http.Response> saveConditionLibrary(body) async {
    return await apiService.postRequest('/user/planning/conditionLibrary/create', body);
  }

  Future<http.Response> getUserServiceRequest(body) async {
    return await apiService.postRequest('/user/serviceRequest/get', body);
  }

  Future<http.Response> getUserServiceRequestForDealer(body) async {
    return await apiService.postRequest('/user/serviceRequest/getForDealer', body);
  }

  Future<http.Response> getUserCriticalAlarmForDealer(body) async {
    return await apiService.postRequest('/user/deviceList/criticalAlarmForDealer', body);
  }

  Future<http.Response> getUserAllServiceRequestForDealer(body) async {
    return await apiService.postRequest('/user/serviceRequest/getAllForDealer', body);
  }

  Future<http.Response> getAllUserAllServiceRequestForAdmin(body) async {
     return await apiService.postRequest('/user/serviceRequest/getAllForAdmin', body);
  }

  Future<http.Response> createUserServiceRequest(body) async {
    return await apiService.postRequest('/user/serviceRequest/create', body);
  }

  Future<http.Response> updateUserServiceRequest(body) async {
    return await apiService.putRequest('/user/serviceRequest/update', body);
  }

  Future<http.Response> getUserDeviceFirmwareDetails(body) async {
    return await apiService.postRequest('/user/deviceList/getFirmwareDetails', body);
  }
  Future<http.Response> getUserDashboard(body) async {
    return await apiService.postRequest('/user/deviceList/getFirmwareDetails', body);
  }


  Future<http.Response> getSubUserSharedDeviceList(body) async {
    return await apiService.postRequest('/user/sharedUser/getDevice', body);
  }

  Future<http.Response> updatedSubUserPermission(body) async {
    return await apiService.postRequest('/user/sharedUser/create', body);
  }

  Future<http.Response> getweather(body) async {
    return await apiService.postRequest('/user/live/weather/get', body);
  }
  //http://13.235.254.21:5000/api/v1/user/live/weather/get
  Future<http.Response> getweatherReport(body) async {
    ///api/v1/user/log/weatherHourly/get
    return await apiService.postRequest('/user/log/weatherHourly/get', body);
  }
  Future<http.Response> updateUserDeviceFirmwareDetails(body) async {
    return await apiService.putRequest('/user/deviceList/loraFrequency/update', body);
  }

  Future<http.Response> getresetAccumulation(body) async {
    return await apiService.postRequest('/user/resetAccumulation/get', body);
  }

  Future<http.Response> updateresetAccumulation(body) async {
    return await apiService.putRequest('/user/resetAccumulation/update', body);
  }
  Future<http.Response> checkpassword(body) async {
    return await apiService.postRequest('/user/verifyPasskey', body);
  }
  Future<http.Response> getgeography(body) async {
     return await apiService.postRequest('/user/geography/get', body);
  }
  Future<http.Response> creategeography(body) async {
    return await apiService.postRequest('/user/geography/create', body);
  }
  Future<http.Response> getgeographyArea(body) async {
    return await apiService.postRequest('/user/deviceList/valveGeographyArea/get', body);
  }
  Future<http.Response> updategeographyArea(body) async {
    return await apiService.putRequest('/user/deviceList/valveGeographyArea/update', body);
  }
  Future<http.Response> getMqttConfigure() async {
    return await apiService.getRequest('http://13.235.254.21:9000/getConfigs',type: "MQTTCONFIG");
  }
///Todo: Crop Advisory urls

  Future<http.Response> getCropList(body) async {
    return await apiService.postRequest('/user/cropAdvisoryInfo/get', body);
  }
  Future<http.Response> createCropList(body) async {
    return await apiService.postRequest('/user/cropAdvisoryInfo/create', body);
  }
  Future<http.Response> deleteCropList(body) async {
    return await apiService.deleteRequest('/user/cropAdvisoryInfo/delete', body);
  }
}

