// Saved table view for Table Platform v2. In-memory / demo level; structure ready for backend.

import 'unified_filter_descriptor.dart';
import 'unified_table_state.dart';
import 'saved_view_share_mode.dart';

/// A saved view: filters, sorts, columns, density, stats, metrics, ownership, sharing, timestamps.
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
    this.ownerUserId,
    this.sharedMode = SavedViewShareMode.private_,
    this.createdAt,
    this.updatedAt,
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
  /// Owner user id (for future ACL). Null = system/default.
  final String? ownerUserId;
  final SavedViewShareMode sharedMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isShared => sharedMode == SavedViewShareMode.shared;

  SavedTableView copyWith({
    String? id,
    String? tableId,
    String? name,
    List<UnifiedFilterDescriptor>? filters,
    List<UnifiedSortDescriptor>? sorts,
    List<String>? visibleColumnIds,
    List<String>? columnOrder,
    UnifiedTableDensity? density,
    bool? statsVisible,
    List<String>? selectedMetricIds,
    String? ownerUserId,
    SavedViewShareMode? sharedMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedTableView(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      name: name ?? this.name,
      filters: filters ?? List.from(this.filters),
      sorts: sorts ?? List.from(this.sorts),
      visibleColumnIds: visibleColumnIds ?? (this.visibleColumnIds != null ? List.from(this.visibleColumnIds!) : null),
      columnOrder: columnOrder ?? (this.columnOrder != null ? List.from(this.columnOrder!) : null),
      density: density ?? this.density,
      statsVisible: statsVisible ?? this.statsVisible,
      selectedMetricIds: selectedMetricIds ?? List.from(this.selectedMetricIds),
      ownerUserId: ownerUserId ?? this.ownerUserId,
      sharedMode: sharedMode ?? this.sharedMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Export current state to a saved view (same tableId). Sets timestamps if not provided.
  static SavedTableView fromState({
    required String id,
    required String tableId,
    required String name,
    required UnifiedTableState state,
    String? ownerUserId,
    SavedViewShareMode sharedMode = SavedViewShareMode.private_,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
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
      ownerUserId: ownerUserId,
      sharedMode: sharedMode,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
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
