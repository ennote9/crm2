// Unified table column model for Table Platform v1.

import 'package:flutter/material.dart';

/// Hint for column value type (sort/filter/format).
enum UnifiedTableColumnType {
  text,
  number,
  date,
  status,
}

/// Filter UI type for typed column filter dialog (text = operator + input, enum = one of / value list, date = date picker).
enum UnifiedColumnFilterType {
  text,
  enum_,
  date,
}

/// Column definition for [UnifiedTableConfig]. Supports sort, filter, hide, stats.
class UnifiedTableColumn<T> {
  const UnifiedTableColumn({
    required this.id,
    required this.label,
    required this.cellBuilder,
    this.valueGetter,
    this.sortable = true,
    this.filterable = false,
    this.hideable = true,
    this.statsEligible = false,
    this.width,
    this.flex = 1,
    this.columnType = UnifiedTableColumnType.text,
    this.filterType,
  });

  final String id;
  final String label;
  final Widget Function(T row) cellBuilder;
  final Comparable? Function(T row)? valueGetter;
  final bool sortable;
  final bool filterable;
  final bool hideable;
  final bool statsEligible;
  final double? width;
  final int flex;
  final UnifiedTableColumnType columnType;
  /// When set, typed filter dialog uses this (text / enum / date). Defaults to text.
  final UnifiedColumnFilterType? filterType;
}
