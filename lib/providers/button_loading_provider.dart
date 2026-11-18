import 'package:flutter/material.dart';

class ButtonLoadingProvider with ChangeNotifier {
  final Map<String, bool> _loadingStates = {};

  bool isLoading(String id) => _loadingStates[id] ?? false;

  void setLoading(String id, bool value) {
    _loadingStates[id] = value;
    notifyListeners();
  }
}