// Saved table view for Table Platform v1. In-memory / demo level.

import 'unified_filter_descriptor.dart';
import 'unified_table_state.dart';

/// A saved view: filters, sorts, visible columns, order, density, stats, metrics.
class SavedTableView {
  const SavedTableView({
    required this.id,
    required this.tableId,
    required this.name,
    this.filters = const [],
    this.sorts = const [],
    this.visibleColumnIds,
    this.columnOrder,
    this.density = UnifiedTableDensity.dense,
    this.statsVisible = false,
    this.selectedMetricIds = const [],
  });

  final String id;
  final String tableId;
  final String name;
  final List<UnifiedFilterDescriptor> filters;
  final List<UnifiedSortDescriptor> sorts;
  final List<String>? visibleColumnIds;
  final List<String>? columnOrder;
  final UnifiedTableDensity density;
  final bool statsVisible;
  final List<String> selectedMetricIds;

  /// Export current state to a saved view (same tableId).
  static SavedTableView fromState({
    required String id,
    required String tableId,
    required String name,
    required UnifiedTableState state,
  }) {
    return SavedTableView(
      id: id,
      tableId: tableId,
      name: name,
      filters: List.from(state.filters),
      sorts: List.from(state.sorts),
      visibleColumnIds: state.visibleColumnIds != null ? List.from(state.visibleColumnIds!) : null,
      columnOrder: state.columnOrder != null ? List.from(state.columnOrder!) : null,
      density: state.density,
      statsVisible: state.statsVisible,
      selectedMetricIds: List.from(state.selectedMetricIds),
    );
  }

  /// Apply this view to state (produces new state with view's settings and activeViewId = this.id).
  UnifiedTableState applyTo(UnifiedTableState state) {
    return state.copyWith(
      filters: List.from(filters),
      sorts: List.from(sorts),
      visibleColumnIds: visibleColumnIds != null ? List.from(visibleColumnIds!) : null,
      columnOrder: columnOrder != null ? List.from(columnOrder!) : null,
      density: density,
      statsVisible: statsVisible,
      selectedMetricIds: List.from(selectedMetricIds),
      activeViewId: id,
    );
  }
}
