import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/icon_widget.dart';
import '../../icons/ui_icons.dart';
import '../../theme/density.dart';
import 'data_grid_column.dart';

const double _selectionWidth = 48;
const double _actionsWidth = 48;

/// Data grid v1: full width, sticky header, dense sizing, multi-select, row actions, states, keyboard.
/// Layout: selection column (48) + data columns (Expanded by flex) + actions column (48). No pixel math.
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
    this.headerCellBuilder,
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
  /// When set, used to build each header cell (label + menu, etc.). Column index 0-based.
  final Widget Function(BuildContext context, UiV1DataGridColumn<T> column, int columnIndex)? headerCellBuilder;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, theme, colorScheme, headerHeight, padX, padY),
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
                  rowHeight: rowHeight,
                  padX: padX,
                  padY: padY,
                  selected: selected,
                  focused: focused,
                  showRowActions: widget.showRowActions,
                  onTap: () {
                    setState(() => _focusedRowIndex = index);
                    widget.onRowOpen?.call(row);
                  },
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
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    double headerHeight,
    double padX,
    double padY,
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
        child: Row(
          children: [
            SizedBox(
              width: _selectionWidth,
              child: Center(
                child: Checkbox(
                  value: value,
                  tristate: true,
                  onChanged: widget.onSelectionChanged != null ? (_) => _toggleSelectAll() : null,
                ),
              ),
            ),
            for (var i = 0; i < widget.columns.length; i++)
              Expanded(
                flex: widget.columns[i].flex,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: widget.headerCellBuilder != null
                        ? widget.headerCellBuilder!(context, widget.columns[i], i)
                        : Text(
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
            if (widget.showRowActions) SizedBox(width: _actionsWidth),
          ],
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
                    const SizedBox(width: _selectionWidth),
                    for (var i = 0; i < n; i++)
                      Expanded(
                        flex: widget.columns.isEmpty ? 1 : widget.columns[i].flex,
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
                    if (widget.showRowActions) const SizedBox(width: _actionsWidth),
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
              icon: const Icon(UiIcons.refresh),
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
    // Soft background highlight only; no vertical blue stripe.
    final isDark = theme.brightness == Brightness.dark;
    Color? bg;
    BoxDecoration? decoration;
    if (selected) {
      bg = isDark
          ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.85)
          : colorScheme.surfaceContainerHighest;
      decoration = BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
          bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      );
    } else if (focused) {
      bg = colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.5 : 0.7);
    }

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        hoverColor: theme.hoverColor,
        highlightColor: theme.highlightColor,
        child: Container(
          height: rowHeight,
          decoration: decoration,
          child: Row(
            children: [
              SizedBox(
                width: _selectionWidth,
                child: Center(
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => onCheckboxTap(),
                  ),
                ),
              ),
              for (var i = 0; i < columns.length; i++)
                Expanded(
                  flex: columns[i].flex,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth.clamp(0.0, double.infinity),
                            ),
                            child: columns[i].cellBuilder(row),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              if (showRowActions)
                SizedBox(
                  width: _actionsWidth,
                  child: IconButton(
                    icon: const UiV1Icon(icon: UiIcons.moreHoriz),
                    onPressed: onRowActionsTap,
                    tooltip: 'Actions',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
