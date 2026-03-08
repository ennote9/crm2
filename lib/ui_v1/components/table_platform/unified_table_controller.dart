// Unified table controller: applies search, filters, sort; produces visible rows and stats on filtered data.
// Controller owns: search, filters, sorts, visible rows, stats, visible columns.
// Page owns: full dataset, UI wiring, row open, presets/saved views definitions.

import 'unified_filter_descriptor.dart';
import 'unified_table_config.dart';
import 'unified_table_state.dart';
import 'unified_table_column.dart';

/// Controller applies search -> filters -> sort; visible rows = result; stats = on that result only.
class UnifiedTableController<T> {
  UnifiedTableController({
    required this.config,
    UnifiedTableState? initialState,
  }) : state = initialState ?? config.initialState;

  final UnifiedTableConfig<T> config;
  UnifiedTableState state;

  /// Optional: custom search predicate. If null, uses [config.searchFields] and column valueGetters.
  bool Function(T row, String query)? customSearch;

  /// Optional escape hatch: post-filter after platform filters. If null, only platform filters apply.
  List<T> Function(List<T> rows)? customFilter;

  /// Apply [state] to [fullList]: search -> platform filters -> optional customFilter -> sort.
  /// Stats must be computed on the returned list.
  List<T> getVisibleRows(List<T> fullList) {
    var list = List<T>.from(fullList);
    final q = state.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((row) => _matchesSearch(row, q)).toList();
    }
    if (state.filters.isNotEmpty) {
      list = list.where((row) => _matchesFilters(row)).toList();
    }
    if (customFilter != null) {
      list = customFilter!(list);
    }
    _applySort(list);
    return list;
  }

  bool _matchesSearch(T row, String query) {
    if (customSearch != null) return customSearch!(row, query);
    if (config.searchFields.isEmpty) return true;
    final parts = <String>[];
    for (final col in config.columns) {
      if (!config.searchFields.contains(col.id)) continue;
      if (col.valueGetter != null) {
        final v = col.valueGetter!(row);
        if (v != null) parts.add(v.toString().toLowerCase());
      }
    }
    final searchable = parts.join(' ');
    return searchable.contains(query);
  }

  bool _matchesFilters(T row) {
    for (final f in state.filters) {
      final col = _columnById(f.columnId);
      if (col == null) continue;
      final cellValue = col.valueGetter?.call(row);
      if (!_evaluateFilter(f, cellValue)) return false;
    }
    return true;
  }

  bool _evaluateFilter(UnifiedFilterDescriptor f, Comparable? cellValue) {
    final str = cellValue?.toString() ?? '';
    final valStr = (f.value ?? '').toString().toLowerCase();
    switch (f.operator) {
      case UnifiedFilterOperator.equals:
        return _eq(cellValue, f.value);
      case UnifiedFilterOperator.notEquals:
        return !_eq(cellValue, f.value);
      case UnifiedFilterOperator.contains:
        return str.toLowerCase().contains(valStr);
      case UnifiedFilterOperator.notContains:
        return !str.toLowerCase().contains(valStr);
      case UnifiedFilterOperator.startsWith:
        return str.toLowerCase().startsWith(valStr);
      case UnifiedFilterOperator.endsWith:
        return str.toLowerCase().endsWith(valStr);
      case UnifiedFilterOperator.inList:
        if (f.values == null || f.values!.isEmpty) return false;
        final set = f.values!.map((e) => e.toString()).toSet();
        return set.contains(cellValue.toString());
      case UnifiedFilterOperator.notInList:
        if (f.values == null || f.values!.isEmpty) return true;
        final set = f.values!.map((e) => e.toString()).toSet();
        return !set.contains(cellValue.toString());
      case UnifiedFilterOperator.greaterThan:
        return _compare(cellValue, f.value) > 0;
      case UnifiedFilterOperator.greaterThanOrEqual:
        return _compare(cellValue, f.value) >= 0;
      case UnifiedFilterOperator.lessThan:
        return _compare(cellValue, f.value) < 0;
      case UnifiedFilterOperator.lessThanOrEqual:
        return _compare(cellValue, f.value) <= 0;
      case UnifiedFilterOperator.between:
        return _compare(cellValue, f.value) >= 0 && _compare(cellValue, f.secondaryValue) <= 0;
      case UnifiedFilterOperator.isEmpty:
        return cellValue == null || str.trim().isEmpty;
      case UnifiedFilterOperator.isNotEmpty:
        return cellValue != null && str.trim().isNotEmpty;
    }
  }

  bool _eq(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a == null || b == null) return false;
    return a.toString() == b.toString();
  }

  int _compare(Comparable? a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (b is Comparable) return a.compareTo(b);
    return a.compareTo(b.toString());
  }

  UnifiedTableColumn<T>? _columnById(String id) {
    for (final c in config.columns) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _applySort(List<T> list) {
    if (state.sorts.isEmpty) return;
    list.sort((a, b) {
      for (final s in state.sorts) {
        final col = _columnById(s.columnId);
        if (col == null || col.valueGetter == null) continue;
        final va = col.valueGetter!(a);
        final vb = col.valueGetter!(b);
        if (va == null && vb == null) continue;
        if (va == null) return s.ascending ? 1 : -1;
        if (vb == null) return s.ascending ? -1 : 1;
        final c = va.compareTo(vb);
        if (c != 0) return s.ascending ? c : -c;
      }
      return 0;
    });
  }

  /// Visible columns in display order (from state.visibleColumnIds / columnOrder).
  List<UnifiedTableColumn<T>> getVisibleColumns() {
    final order = state.columnOrder ?? state.visibleColumnIds ?? config.columns.map((c) => c.id).toList();
    final visible = state.visibleColumnIds?.toSet() ?? config.columns.map((c) => c.id).toSet();
    final result = <UnifiedTableColumn<T>>[];
    for (final id in order) {
      if (!visible.contains(id)) continue;
      final col = _columnById(id);
      if (col != null) result.add(col);
    }
    for (final col in config.columns) {
      if (!result.any((c) => c.id == col.id)) result.add(col);
    }
    return result;
  }

  /// Stats for [visibleRows] only (current filtered dataset).
  Map<String, num> getStatsValues(List<T> visibleRows) {
    final result = <String, num>{};
    final ids = state.selectedMetricIds.isEmpty
        ? config.availableMetrics.map((m) => m.id).toList()
        : state.selectedMetricIds;
    for (final metric in config.availableMetrics) {
      if (!ids.contains(metric.id)) continue;
      result[metric.id] = metric.compute(visibleRows);
    }
    return result;
  }

  String formatMetricValue(String metricId, num value) {
    for (final m in config.availableMetrics) {
      if (m.id == metricId) return m.format(value);
    }
    return value.toString();
  }
}
