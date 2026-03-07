// Unified table header cell: label + sort/filter indicators + column menu.

import 'package:flutter/material.dart';

import '../../icons/ui_icons.dart';
import 'unified_table_controller.dart';
import 'unified_table_state.dart';
import 'unified_table_column.dart';
import 'unified_typed_filter_dialog.dart';

/// Builds a header cell with label, sort/filter indicators, and menu (sort, filter, clear, hide).
Widget buildUnifiedTableHeaderCell<T>({
  required BuildContext context,
  required UnifiedTableColumn<T> column,
  required UnifiedTableController<T> controller,
  required List<T> fullList,
  required VoidCallback onStateChanged,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final sorts = controller.state.sorts;
  final filters = controller.state.filters;
  UnifiedSortDescriptor? sortDesc;
  try {
    sortDesc = sorts.firstWhere((s) => s.columnId == column.id);
  } catch (_) {}
  final hasFilter = filters.any((f) => f.columnId == column.id);
  final filterForColumn = filters.where((f) => f.columnId == column.id).toList();
  final currentFilterForColumn = filterForColumn.isNotEmpty ? filterForColumn.first : null;

  return Row(
    children: [
      Expanded(
        child: Text(
          column.label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      if (sortDesc != null)
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(
            sortDesc.ascending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: colorScheme.primary,
          ),
        ),
      if (hasFilter)
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(
            UiIcons.filterList,
            size: 14,
            color: colorScheme.primary,
          ),
        ),
      PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        icon: Icon(Icons.more_horiz, size: 18, color: colorScheme.onSurfaceVariant),
        tooltip: 'Column menu',
        onSelected: (value) {
          switch (value) {
            case 'sort_asc':
              _setSort(controller, column.id, true);
              onStateChanged();
              break;
            case 'sort_desc':
              _setSort(controller, column.id, false);
              onStateChanged();
              break;
            case 'clear_sort':
              _clearSort(controller, column.id);
              onStateChanged();
              break;
            case 'filter':
              if (column.filterable && column.valueGetter != null) {
                showUnifiedTypedFilterDialog<T>(
                  context: context,
                  column: column,
                  fullList: fullList,
                  currentFilter: currentFilterForColumn,
                  onApply: (descriptor) {
                    if (descriptor == null) {
                      controller.state = controller.state.removeFilter(columnId: column.id);
                    } else {
                      controller.state = controller.state.addOrReplaceFilter(descriptor);
                    }
                    onStateChanged();
                  },
                );
              }
              break;
            case 'clear_filter':
              controller.state = controller.state.removeFilter(columnId: column.id);
              onStateChanged();
              break;
            case 'hide':
              _hideColumn(controller, column.id);
              onStateChanged();
              break;
          }
        },
        itemBuilder: (context) {
          final items = <PopupMenuEntry<String>>[];
          if (column.sortable) {
            items.add(const PopupMenuItem(
              value: 'sort_asc',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.arrow_upward, size: 18),
                title: Text('Sort ascending'),
              ),
            ));
            items.add(const PopupMenuItem(
              value: 'sort_desc',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.arrow_downward, size: 18),
                title: Text('Sort descending'),
              ),
            ));
            if (sortDesc != null) {
              items.add(const PopupMenuItem(
                value: 'clear_sort',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Clear sort'),
                ),
              ));
            }
          }
          if (column.filterable) {
            items.add(const PopupMenuItem(
              value: 'filter',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(UiIcons.filterList, size: 18),
                title: Text('Filter...'),
              ),
            ));
            if (hasFilter) {
              items.add(const PopupMenuItem(
                value: 'clear_filter',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Clear filter'),
                ),
              ));
            }
          }
          if (column.hideable) {
            if (items.isNotEmpty) items.add(const PopupMenuDivider());
            items.add(const PopupMenuItem(
              value: 'hide',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.visibility_off, size: 18),
                title: Text('Hide column'),
              ),
            ));
          }
          return items;
        },
      ),
    ],
  );
}

void _setSort<T>(UnifiedTableController<T> controller, String columnId, bool ascending) {
  final next = controller.state.sorts.where((s) => s.columnId != columnId).toList();
  next.add(UnifiedSortDescriptor(columnId: columnId, ascending: ascending));
  controller.state = controller.state.copyWithAsCustom(sorts: next);
}

void _clearSort<T>(UnifiedTableController<T> controller, String columnId) {
  final next = controller.state.sorts.where((s) => s.columnId != columnId).toList();
  controller.state = controller.state.copyWithAsCustom(sorts: next);
}

void _hideColumn<T>(UnifiedTableController<T> controller, String columnId) {
  final visible = controller.state.visibleColumnIds ?? controller.config.columns.map((c) => c.id).toList();
  final next = visible.where((id) => id != columnId).toList();
  if (next.isEmpty) return;
  final order = controller.state.columnOrder ?? visible;
  final nextOrder = order.where((id) => id != columnId).toList();
  controller.state = controller.state.copyWithAsCustom(
    visibleColumnIds: next,
    columnOrder: nextOrder,
  );
}
