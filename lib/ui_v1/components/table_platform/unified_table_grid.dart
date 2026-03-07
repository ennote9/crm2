// Unified table grid for Table Platform v1. Wraps UiV1DataGrid with config + visible columns.

import 'package:flutter/material.dart';

import '../data_grid/index.dart';
import '../../theme/density.dart';
import 'unified_table_column.dart';
import 'unified_table_controller.dart';
import 'unified_table_header_cell.dart';
import 'unified_table_state.dart';

/// Maps platform density to ui_v1 density.
UiV1Density _toUiV1Density(UnifiedTableDensity density) {
  switch (density) {
    case UnifiedTableDensity.comfortable:
      return UiV1Density.comfortable;
    case UnifiedTableDensity.dense:
      return UiV1Density.dense;
  }
}

/// Converts [UnifiedTableColumn] to [UiV1DataGridColumn].
UiV1DataGridColumn<T> toDataGridColumn<T>(UnifiedTableColumn<T> col) {
  return UiV1DataGridColumn<T>(
    id: col.id,
    label: col.label,
    width: col.width,
    flex: col.flex,
    cellBuilder: col.cellBuilder,
  );
}

/// Grid that uses [UnifiedTableController]: visible rows and columns from state.
class UnifiedTableGrid<T> extends StatelessWidget {
  const UnifiedTableGrid({
    super.key,
    required this.controller,
    required this.fullList,
    this.selectedIds = const {},
    this.onSelectionChanged,
    this.loading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyMessage = 'No items',
    this.showRowActions = true,
    this.onRowActions,
    this.showHeaderMenus = false,
    this.onStateChanged,
  });

  final UnifiedTableController<T> controller;
  final List<T> fullList;
  final Set<String> selectedIds;
  final void Function(Set<String>)? onSelectionChanged;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyMessage;
  final bool showRowActions;
  final void Function(T)? onRowActions;
  /// When true, each column header shows sort/filter indicators and a menu (sort, filter, clear, hide).
  final bool showHeaderMenus;
  /// Called after sort/filter/hide so the parent can setState.
  final VoidCallback? onStateChanged;

  @override
  Widget build(BuildContext context) {
    final visibleRows = controller.getVisibleRows(fullList);
    final visibleColumns = controller.getVisibleColumns();
    final gridColumns = visibleColumns.map((c) => toDataGridColumn(c)).toList();
    final density = _toUiV1Density(controller.state.density);

    return UiV1DataGrid<T>(
      columns: gridColumns,
      rows: visibleRows,
      rowIdGetter: controller.config.rowIdGetter,
      selectedIds: selectedIds,
      onSelectionChanged: onSelectionChanged,
      loading: loading,
      errorMessage: errorMessage,
      onRetry: onRetry,
      emptyMessage: emptyMessage,
      onRowOpen: controller.config.rowOpen,
      showRowActions: showRowActions,
      onRowActions: onRowActions,
      density: density,
      headerCellBuilder: showHeaderMenus
          ? (context, dataGridColumn, columnIndex) {
              if (columnIndex >= visibleColumns.length) return Text(dataGridColumn.label);
              return buildUnifiedTableHeaderCell<T>(
                context: context,
                column: visibleColumns[columnIndex],
                controller: controller,
                fullList: fullList,
                onStateChanged: onStateChanged ?? () {},
              );
            }
          : null,
    );
  }
}
