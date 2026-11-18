import 'package:flutter/cupertino.dart';

import '../utils/helpers/debouncer.dart';

class SearchProvider extends ChangeNotifier {
  bool _isSearching = false;
  String _searchValue = '';
  int _categoryId = 0;
  int _modelId = 0;
  bool _pendingSearch = false;

  final Debouncer _debouncer = Debouncer(milliseconds: 400);

  bool get isSearching => _isSearching;
  String get searchValue => _searchValue;
  int get categoryId => _categoryId;
  int get modelId => _modelId;
  bool get pendingSearch => _pendingSearch;

  // --- NEW DEBOUNCED SEARCH ---
  void updateSearchDebounced(String value) {
    _debouncer.run(() {
      _searchValue = value;
      _isSearching = value.isNotEmpty;
      _pendingSearch = true;
      notifyListeners();
    });
  }

  void setCategory(int id) {
    if (_categoryId == id) return;
    _categoryId = id;
    _pendingSearch = true;
    _isSearching = true;
    notifyListeners();
  }

  void setModel(int id) {
    if (_modelId == id) return;
    _modelId = id;
    _pendingSearch = true;
    _isSearching = true;
    notifyListeners();
  }

  void setSearching(bool status) {
    if (_isSearching == status) return;
    _isSearching = status;
    _pendingSearch = true;
    notifyListeners();
  }

  void markHandled() {
    if (!_pendingSearch) return;
    _pendingSearch = false;
    notifyListeners();
  }

  void clear() {
    _searchValue = '';
    _categoryId = 0;
    _modelId = 0;
    _isSearching = false;
    _pendingSearch = false;
    notifyListeners();
  }
}