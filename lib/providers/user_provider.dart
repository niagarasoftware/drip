import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/enums.dart';

class UserProvider extends ChangeNotifier {
  UserModel _loggedInUser = UserModel.empty();

  /// Stack of viewed customers (so we can go back step by step)
  final List<UserModel> _viewedCustomerStack = [];

  UserModel get loggedInUser => _loggedInUser;
  UserModel? get viewedCustomer => _viewedCustomerStack.isNotEmpty ? _viewedCustomerStack.last : null;

  UserRole get role => _loggedInUser.role;

  /// Set the logged-in user (Admin, Dealer, etc.)
  void setLoggedInUser(UserModel user) {
    _loggedInUser = user;
    _viewedCustomerStack.clear();
    notifyListeners();
  }

  /// Push a customer to the stack
  void pushViewedCustomer(UserModel customer) {
    _viewedCustomerStack.add(customer);
    notifyListeners();
  }

  /// Pop the last viewed customer (when going back)
  void popViewedCustomer() {
    if (_viewedCustomerStack.isNotEmpty) {
      _viewedCustomerStack.removeLast();
      notifyListeners();
    }
  }

  /// Clear all viewed customers
  void clearViewedCustomers() {
    _viewedCustomerStack.clear();
    notifyListeners();
  }

  /// Update a specific user in the stack or logged in user
  void updateUser(UserModel updatedUser) {
    if (_loggedInUser.id == updatedUser.id) {
      _loggedInUser = updatedUser;
    }

    for (int i = 0; i < _viewedCustomerStack.length; i++) {
      if (_viewedCustomerStack[i].id == updatedUser.id) {
        _viewedCustomerStack[i] = updatedUser;
      }
    }

    notifyListeners();
  }

  /// Change logged-in user role
  void changeRole(UserRole newRole) {
    if (_loggedInUser.role != newRole) {
      _loggedInUser = _loggedInUser.copyWith(role: newRole);
      notifyListeners();
    }
  }

  /// Reset to default
  void resetUser() {
    _loggedInUser = UserModel.empty();
    _viewedCustomerStack.clear();
    notifyListeners();
  }
}