// Unified table state for Table Platform v1. Holds search, filters, sort, columns, density, stats.

import 'unified_filter_descriptor.dart';

/// Single sort descriptor: column id + direction.
class UnifiedSortDescriptor {
  const UnifiedSortDescriptor({required this.columnId, this.ascending = true});
  final String columnId;
  final bool ascending;
}

/// Density for table rows/header.
enum UnifiedTableDensity {
  dense,
  comfortable,
}

/// Full UI state for a unified table. Stats are computed on current filtered dataset elsewhere.
class UnifiedTableState {
  const UnifiedTableState({
    this.searchQuery = '',
    this.filters = const [],
    this.sorts = const [],
    this.visibleColumnIds,
    this.columnOrder,
    this.density = UnifiedTableDensity.dense,
    this.statsVisible = false,
    this.selectedMetricIds = const [],
  });

  final String searchQuery;
  /// Platform filters. Applied in controller in order.
  final List<UnifiedFilterDescriptor> filters;
  final List<UnifiedSortDescriptor> sorts;
  /// If null, all columns visible. Otherwise only these ids.
  final List<String>? visibleColumnIds;
  /// If null, default order. Otherwise column order for display.
  final List<String>? columnOrder;
  final UnifiedTableDensity density;
  final bool statsVisible;
  final List<String> selectedMetricIds;

  UnifiedTableState copyWith({
    String? searchQuery,
    List<UnifiedFilterDescriptor>? filters,
    List<UnifiedSortDescriptor>? sorts,
    List<String>? visibleColumnIds,
    List<String>? columnOrder,
    UnifiedTableDensity? density,
    bool? statsVisible,
    List<String>? selectedMetricIds,
  }) {
    return UnifiedTableState(
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      sorts: sorts ?? this.sorts,
      visibleColumnIds: visibleColumnIds ?? this.visibleColumnIds,
      columnOrder: columnOrder ?? this.columnOrder,
      density: density ?? this.density,
      statsVisible: statsVisible ?? this.statsVisible,
      selectedMetricIds: selectedMetricIds ?? this.selectedMetricIds,
    );
  }

  /// Use when the user manually changes state (filters, sorts, columns, density, metrics, stats visibility).
  UnifiedTableState copyWithAsCustom({
    String? searchQuery,
    List<UnifiedFilterDescriptor>? filters,
    List<UnifiedSortDescriptor>? sorts,
    List<String>? visibleColumnIds,
    List<String>? columnOrder,
    UnifiedTableDensity? density,
    bool? statsVisible,
    List<String>? selectedMetricIds,
  }) {
    return UnifiedTableState(
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      sorts: sorts ?? this.sorts,
      visibleColumnIds: visibleColumnIds ?? this.visibleColumnIds,
      columnOrder: columnOrder ?? this.columnOrder,
      density: density ?? this.density,
      statsVisible: statsVisible ?? this.statsVisible,
      selectedMetricIds: selectedMetricIds ?? this.selectedMetricIds,
    );
  }

  /// Add or replace filter for the same column (by descriptor.identity). Returns new state; use copyWithAsCustom when from user action.
  UnifiedTableState addOrReplaceFilter(UnifiedFilterDescriptor descriptor) {
    final next = List<UnifiedFilterDescriptor>.from(filters);
    next.removeWhere((f) => f.identity == descriptor.identity);
    next.add(descriptor);
    return copyWithAsCustom(filters: next);
  }

  /// Remove filter(s) for column [columnId], or filter with [filterId] if provided. Returns new state.
  UnifiedTableState removeFilter({String? columnId, String? filterId}) {
    if (columnId != null) {
      final next = filters.where((f) => f.columnId != columnId).toList();
      return copyWithAsCustom(filters: next);
    }
    if (filterId != null) {
      final next = filters.where((f) => f.identity != filterId).toList();
      return copyWithAsCustom(filters: next);
    }
    return this;
  }

  /// Clear all filters. Returns new state.
  UnifiedTableState clearFilters() {
    if (filters.isEmpty) return this;
    return copyWithAsCustom(filters: const []);
  }
}
