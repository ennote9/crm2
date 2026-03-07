// Column header menu for Table Platform v1. Sort, filter placeholder, hide.

import 'package:flutter/material.dart';

import '../../icons/ui_icons.dart';
import 'unified_table_column.dart';

/// Callbacks for column header menu actions.
class UnifiedColumnHeaderMenuActions<T> {
  const UnifiedColumnHeaderMenuActions({
    this.onSortAsc,
    this.onSortDesc,
    this.onClearSort,
    this.onFilter,
    this.onClearFilter,
    this.onHideColumn,
  });

  final void Function(UnifiedTableColumn<T> column)? onSortAsc;
  final void Function(UnifiedTableColumn<T> column)? onSortDesc;
  final void Function(UnifiedTableColumn<T> column)? onClearSort;
  final void Function(UnifiedTableColumn<T> column)? onFilter;
  final void Function(UnifiedTableColumn<T> column)? onClearFilter;
  final void Function(UnifiedTableColumn<T> column)? onHideColumn;
}

/// Builds a popup menu for a column header: Sort asc/desc, Filter (placeholder), Clear filter, Hide column.
Widget unifiedColumnHeaderMenu<T>({
  required BuildContext context,
  required UnifiedTableColumn<T> column,
  required UnifiedColumnHeaderMenuActions<T> actions,
  bool isSortedAsc = false,
  bool isSortedDesc = false,
  bool hasFilter = false,
}) {
  return PopupMenuButton<String>(
    onSelected: (value) {
      switch (value) {
        case 'sort_asc':
          actions.onSortAsc?.call(column);
          break;
        case 'sort_desc':
          actions.onSortDesc?.call(column);
          break;
        case 'clear_sort':
          actions.onClearSort?.call(column);
          break;
        case 'filter':
          actions.onFilter?.call(column);
          break;
        case 'clear_filter':
          actions.onClearFilter?.call(column);
          break;
        case 'hide':
          actions.onHideColumn?.call(column);
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
        if (isSortedAsc || isSortedDesc) {
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
            title: Text('Filter'),
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
        // Hide column item
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
  );
}
