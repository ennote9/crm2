// State holder for Orders list: search, filters, view, showStatistics.
// Lives in app/playground scope so it survives Navigator.push/pop.

import 'package:flutter/material.dart';

import '../../components/toolbar/command_toolbar.dart';

/// Holds Orders list UI state so it is preserved when navigating to Order Details and back.
class OrdersListState extends ChangeNotifier {
  String _searchText = '';
  Set<String> _statusFilters = {};
  String? _warehouseFilter;
  UiV1WorklistViewId _viewId = UiV1WorklistViewId.all;
  bool _isCustomView = false;
  bool _showStatistics = false;

  String get searchText => _searchText;
  Set<String> get statusFilters => Set.unmodifiable(_statusFilters);
  String? get warehouseFilter => _warehouseFilter;
  UiV1WorklistViewId get viewId => _viewId;
  bool get isCustomView => _isCustomView;
  bool get showStatistics => _showStatistics;

  void setSearchText(String value) {
    if (_searchText == value) return;
    _searchText = value;
    notifyListeners();
  }

  void setStatusFilters(Set<String> value) {
    if (_setEquals(_statusFilters, value)) return;
    _statusFilters = Set.from(value);
    notifyListeners();
  }

  void setWarehouseFilter(String? value) {
    if (_warehouseFilter == value) return;
    _warehouseFilter = value;
    notifyListeners();
  }

  void setViewId(UiV1WorklistViewId value) {
    if (_viewId == value) return;
    _viewId = value;
    notifyListeners();
  }

  void setIsCustomView(bool value) {
    if (_isCustomView == value) return;
    _isCustomView = value;
    notifyListeners();
  }

  void setShowStatistics(bool value) {
    if (_showStatistics == value) return;
    _showStatistics = value;
    notifyListeners();
  }

  void reset() {
    _searchText = '';
    _statusFilters = {};
    _warehouseFilter = null;
    _viewId = UiV1WorklistViewId.all;
    _isCustomView = false;
    notifyListeners();
  }

  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final e in a) {
      if (!b.contains(e)) return false;
    }
    return true;
  }
}
