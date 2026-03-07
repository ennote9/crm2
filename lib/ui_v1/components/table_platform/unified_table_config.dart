// Unified table config for Table Platform v1. Pass columns, search fields, defaults, metrics, row open.

import 'saved_table_view.dart';
import 'unified_stats_metric.dart';
import 'unified_table_column.dart';
import 'unified_table_state.dart';

/// Full configuration for a unified table. New list page = config + data + row open.
class UnifiedTableConfig<T> {
  const UnifiedTableConfig({
    required this.tableId,
    required this.columns,
    required this.rowIdGetter,
    this.searchFields = const [],
    this.defaultSorts = const [],
    this.defaultDensity = UnifiedTableDensity.dense,
    this.defaultVisibleColumnIds,
    this.defaultStatsVisible = false,
    this.availableMetrics = const [],
    this.defaultMetricIds = const [],
    this.rowOpen,
    this.savedViews = const [],
  });

  final String tableId;
  final List<UnifiedTableColumn<T>> columns;
  final String Function(T) rowIdGetter;
  /// Column ids or field names used for search. If empty, search is no-op or uses first column.
  final List<String> searchFields;
  final List<UnifiedSortDescriptor> defaultSorts;
  final UnifiedTableDensity defaultDensity;
  final List<String>? defaultVisibleColumnIds;
  final bool defaultStatsVisible;
  final List<UnifiedStatsMetricDefinition<T>> availableMetrics;
  final List<String> defaultMetricIds;
  final void Function(T)? rowOpen;
  final List<SavedTableView> savedViews;

  /// Initial state from this config.
  UnifiedTableState get initialState => UnifiedTableState(
        searchQuery: '',
        filters: const [],
        sorts: List.from(defaultSorts),
        visibleColumnIds: defaultVisibleColumnIds ?? columns.map((c) => c.id).toList(),
        columnOrder: defaultVisibleColumnIds != null ? List.from(defaultVisibleColumnIds!) : columns.map((c) => c.id).toList(),
        density: defaultDensity,
        statsVisible: defaultStatsVisible,
        selectedMetricIds: List.from(defaultMetricIds),
        activeViewId: null,
      );
}
