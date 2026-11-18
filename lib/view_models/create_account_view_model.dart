import 'dart:convert';
import 'package:flutter/cupertino.dart';
import '../models/country_list_model.dart';
import '../models/state_list_model.dart';
import '../repository/repository.dart';
import '../utils/enums.dart';

//for sub-dealer creation...........
enum AccountType { customer, dealer }

class CreateAccountViewModel extends ChangeNotifier {
  final Repository repository;
  bool isLoading = false;
  String errorMsg = '';

  List<CountryListModel> countryList = [];
  List<StateListModel> stateList = [];
  List<String> countries = [];
  List<String> states = [];

  int selectedCountryID = 0;
  int selectedStateID = 0;

  final formKey = GlobalKey<FormState>();
  String? name, email, country, state, city, address;
  final TextEditingController mobileNoController = TextEditingController();
  String dialCode = '91';

  AccountType accountType = AccountType.customer;

  final Function(Map<String, dynamic>) onAccountCreatedSuccess;

  CreateAccountViewModel(this.repository, {required this.onAccountCreatedSuccess});

  Future<void> getCountryList() async {
    setLoading(true);
    try {
      final response = await repository.fetchCountryList();
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          final countryData = jsonData["data"] as List;
          countries = countryData.map((e) => e['countryName'] as String).toList();
          countryList = countryData.map((e) => CountryListModel.fromJson(e)).toList();
        }
      }
    } catch (error) {
      debugPrint('Error fetching country list: $error');
    } finally {
      setLoading(false);
    }
  }

  int? getCountryIdByName(String countryName) {
    return countryList.firstWhereOrNull(
          (country) => country.countryName.toLowerCase() == countryName.toLowerCase(),
    )?.countryId;
  }

  Future<void> getStateList(String countryId) async {
    setLoading(true);
    try {
      final response = await repository.fetchStateList(countryId);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          final stateData = jsonData["data"] as List;
          states = stateData.map((e) => e['stateName'] as String).toList();
          stateList = stateData.map((e) => StateListModel.fromJson(e)).toList();
        }
      }
    } catch (error) {
      debugPrint('Error fetching state list: $error');
    } finally {
      setLoading(false);
    }
  }

  int? getStateIdByName(String stateName) {
    return stateList.firstWhereOrNull(
          (state) => state.stateName.toLowerCase() == stateName.toLowerCase(),
    )?.stateId;
  }

  Future<void> createAccount(int userId, UserRole role, int customerId) async {

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      errorMsg = '';
      setLoading(true);

      try {
        final cusType = role == UserRole.admin ? '2' :
        accountType.name == "dealer" ? '2' : '3';
        final body = {
          'userName': name ?? '',
          'countryCode': dialCode.replaceAll('+', ''),
          'mobileNumber': mobileNoController.text,
          'userType': cusType,
          'createUser': role == UserRole.subUser ? customerId : userId,
          'address': address ?? '',
          'pinCode': '',
          'city': city ?? '',
          'country': selectedCountryID.toString(),
          'state': selectedStateID.toString(),
          'email': email ?? '',
          'mainUserId': customerId != 0 ? customerId : userId,
          'isSubdealer': accountType.name == "dealer" ? "1" : "0",
        };

        final response = customerId != 0
            ? await repository.createSubUserAccount(body)
            : await repository.createCustomerAccount(body);

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          if (jsonData["code"] == 200) {
            onAccountCreatedSuccess({
              'status': 'success',
              'message': 'Account created successfully',
              'userId': jsonData["data"]['userId'],
              'userName': name ?? '',
              'countryCode': dialCode.replaceAll('+', ''),
              'mobileNumber': mobileNoController.text,
              'emailId': email ?? '',
              'serviceRequestCount': 0,
              'criticalAlarmCount': 0,
            });
          } else{
            errorMsg = jsonData["message"];
          }
        }
      } catch (error) {
        debugPrint('Error creating account: $error');
      } finally {
        setLoading(false);
      }
    }
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setAccountType(AccountType type) {
    accountType = type;
    notifyListeners();
  }
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}