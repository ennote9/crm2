import 'package:flutter/material.dart';

/// Column definition for [UiV1DataGrid].
class UiV1DataGridColumn<T> {
  const UiV1DataGridColumn({
    required this.id,
    required this.label,
    this.width,
    this.flex = 1,
    required this.cellBuilder,
  });

  final String id;
  final String label;
  /// Fixed width in logical pixels. If null, column uses [flex] to share remaining space.
  final double? width;
  /// Flex weight when [width] is null. Ignored when [width] is set.
  final int flex;
  /// Builds the cell widget for a row.
  final Widget Function(T row) cellBuilder;
}
