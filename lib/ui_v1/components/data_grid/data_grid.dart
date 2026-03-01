import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/density.dart';
import 'data_grid_column.dart';

const double _checkboxWidth = 48;
const double _actionsColumnWidth = 40;

/// Minimum table width when horizontal scroll is used (avoids overflow when container is narrow).
const double _minTableWidth = 560;

/// Data grid v1: full width, sticky header, dense sizing, multi-select, row actions, states, keyboard.
class UiV1DataGrid<T> extends StatefulWidget {
  const UiV1DataGrid({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowIdGetter,
    this.selectedIds = const {},
    this.onSelectionChanged,
    this.loading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyMessage = 'No items',
    this.onRowOpen,
    this.showRowActions = true,
    this.onRowActions,
    this.density = UiV1Density.dense,
  });

  final List<UiV1DataGridColumn<T>> columns;
  final List<T> rows;
  final String Function(T) rowIdGetter;
  final Set<String> selectedIds;
  final void Function(Set<String>)? onSelectionChanged;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyMessage;
  final void Function(T)? onRowOpen;
  final bool showRowActions;
  final void Function(T)? onRowActions;
  final UiV1Density density;

  @override
  State<UiV1DataGrid<T>> createState() => _UiV1DataGridState<T>();
}

class _UiV1DataGridState<T> extends State<UiV1DataGrid<T>> {
  int _focusedRowIndex = 0;
  final FocusNode _focusNode = FocusNode();

  UiV1DensityTokens get _density =>
      UiV1DensityTokens.forDensity(widget.density);

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  List<double> _computeWidths(double totalWidth) {
    final cols = widget.columns;
    final contentWidth = (totalWidth - _checkboxWidth - (widget.showRowActions ? _actionsColumnWidth : 0))
        .clamp(0.0, double.infinity);
    final fixedTotal = cols.where((c) => c.width != null).fold<double>(0, (s, c) => s + c.width!);
    final flexSum = cols.where((c) => c.width == null).fold<int>(0, (s, c) => s + c.flex);
    var remainingForFlex = (contentWidth - fixedTotal).clamp(0.0, double.infinity);
    final widths = <double>[];
    final flexIndices = <int>[];
    for (var i = 0; i < cols.length; i++) {
      final c = cols[i];
      if (c.width != null) {
        widths.add(c.width!);
      } else {
        flexIndices.add(i);
        widths.add(0);
      }
    }
    if (flexSum > 0 && flexIndices.isNotEmpty) {
      var assigned = 0.0;
      for (var k = 0; k < flexIndices.length; k++) {
        final i = flexIndices[k];
        final isLast = k == flexIndices.length - 1;
        final flex = cols[i].flex;
        final w = isLast
            ? (remainingForFlex - assigned).clamp(0.0, double.infinity)
            : (remainingForFlex * flex / flexSum).floorToDouble();
        widths[i] = w;
        assigned += w;
      }
    }
    return widths;
  }

  void _toggleSelection(String id) {
    final next = Set<String>.from(widget.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    widget.onSelectionChanged?.call(next);
  }

  void _toggleSelectAll() {
    if (widget.rows.isEmpty) return;
    final allIds = widget.rows.map(widget.rowIdGetter).toSet();
    final selected = widget.selectedIds;
    if (selected.length >= allIds.length) {
      widget.onSelectionChanged?.call({});
    } else {
      widget.onSelectionChanged?.call(allIds);
    }
  }

  bool? get _headerCheckboxValue {
    if (widget.rows.isEmpty) return false;
    final allIds = widget.rows.map(widget.rowIdGetter).toSet();
    final n = widget.selectedIds.length;
    if (n == 0) return false;
    if (n >= allIds.length) return true;
    return null; // indeterminate
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final rows = widget.rows;
    if (rows.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _focusedRowIndex = (_focusedRowIndex + 1).clamp(0, rows.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _focusedRowIndex = (_focusedRowIndex - 1).clamp(0, rows.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      final row = rows[_focusedRowIndex];
      _toggleSelection(widget.rowIdGetter(row));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final row = rows[_focusedRowIndex];
      widget.onRowOpen?.call(row);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final headerHeight = _density.tableHeaderHeight;
    final rowHeight = _density.tableRowHeight;
    final padX = _density.tableCellPaddingX;
    final padY = _density.tableCellPaddingY;

    if (widget.loading) {
      return _buildSkeleton(theme, headerHeight, rowHeight, padX, padY);
    }
    if (widget.errorMessage != null) {
      return _buildError(context, theme);
    }
    if (widget.rows.isEmpty) {
      return _buildEmpty(context, theme);
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final viewportHeight = constraints.maxHeight;
          final useHorizontalScroll = viewportWidth < _minTableWidth;
          final tableWidth = useHorizontalScroll ? _minTableWidth : viewportWidth;
          final widths = _computeWidths(tableWidth);

          final table = SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, theme, colorScheme, headerHeight, padX, padY, widths, tableWidth),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.rows.length,
                    itemBuilder: (context, index) {
                      final row = widget.rows[index];
                      final id = widget.rowIdGetter(row);
                      final selected = widget.selectedIds.contains(id);
                      final focused = index == _focusedRowIndex;
                      return _DataRowWidget<T>(
                        row: row,
                        columns: widget.columns,
                        widths: widths,
                        maxRowWidth: tableWidth,
                        rowHeight: rowHeight,
                        padX: padX,
                        padY: padY,
                        selected: selected,
                        focused: focused,
                        showRowActions: widget.showRowActions,
                        onTap: () => setState(() => _focusedRowIndex = index),
                        onCheckboxTap: () => _toggleSelection(id),
                        onRowActionsTap: widget.onRowActions != null
                            ? () => widget.onRowActions!(row)
                            : null,
                        colorScheme: colorScheme,
                        theme: theme,
                      );
                    },
                  ),
                ),
              ],
            ),
          );

          if (useHorizontalScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                height: viewportHeight,
                child: table,
              ),
            );
          }

          return table;
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    double headerHeight,
    double padX,
    double padY,
    List<double> widths,
    double maxWidth,
  ) {
    final value = _headerCheckboxValue;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: Container(
        height: headerHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: ClipRect(
          child: SizedBox(
            width: maxWidth,
            child: Row(
              children: [
                SizedBox(
                  width: _checkboxWidth,
                  child: Center(
                    child: Checkbox(
                      value: value,
                      tristate: true,
                      onChanged: widget.onSelectionChanged != null ? (_) => _toggleSelectAll() : null,
                    ),
                  ),
                ),
                for (var i = 0; i < widget.columns.length; i++)
                  SizedBox(
                    width: widths[i],
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.columns[i].label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                if (widget.showRowActions)
                  SizedBox(width: _actionsColumnWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(
    ThemeData theme,
    double headerHeight,
    double rowHeight,
    double padX,
    double padY,
  ) {
    final colorScheme = theme.colorScheme;
    final n = widget.columns.isEmpty ? 4 : widget.columns.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: headerHeight,
          color: colorScheme.surfaceContainerHighest,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) {
              return Container(
                height: rowHeight,
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const SizedBox(width: _checkboxWidth),
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    if (widget.showRowActions) const SizedBox(width: _actionsColumnWidth),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          widget.emptyMessage,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataRowWidget<T> extends StatelessWidget {
  const _DataRowWidget({
    required this.row,
    required this.columns,
    required this.widths,
    required this.maxRowWidth,
    required this.rowHeight,
    required this.padX,
    required this.padY,
    required this.selected,
    required this.focused,
    required this.showRowActions,
    required this.onTap,
    required this.onCheckboxTap,
    this.onRowActionsTap,
    required this.colorScheme,
    required this.theme,
  });

  final T row;
  final List<UiV1DataGridColumn<T>> columns;
  final List<double> widths;
  final double maxRowWidth;
  final double rowHeight;
  final double padX;
  final double padY;
  final bool selected;
  final bool focused;
  final bool showRowActions;
  final VoidCallback onTap;
  final VoidCallback onCheckboxTap;
  final VoidCallback? onRowActionsTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    Color? bg = selected
        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
        : null;
    if (focused && !selected) {
      bg = colorScheme.surfaceContainerHighest;
    }

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        hoverColor: theme.hoverColor,
        highlightColor: theme.highlightColor,
        child: Container(
          height: rowHeight,
          decoration: BoxDecoration(
            border: focused
                ? Border(
                    left: BorderSide(color: colorScheme.primary, width: 2),
                  )
                : null,
          ),
          child: ClipRect(
            child: SizedBox(
              width: maxRowWidth,
              child: Row(
                children: [
                  SizedBox(
                    width: _checkboxWidth,
                    child: Center(
                      child: Checkbox(
                        value: selected,
                        onChanged: (_) => onCheckboxTap(),
                      ),
                    ),
                  ),
                  for (var i = 0; i < columns.length; i++)
                    SizedBox(
                      width: widths[i],
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ClipRect(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: (widths[i] - 2 * padX).clamp(0, double.infinity),
                              ),
                              child: columns[i].cellBuilder(row),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (showRowActions)
                    SizedBox(
                      width: _actionsColumnWidth,
                      child: IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: onRowActionsTap,
                        tooltip: 'Actions',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
