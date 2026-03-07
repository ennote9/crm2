// Unified View Panel v1. Single entry for filters, columns, sort, statistics.

import 'package:flutter/material.dart';

import '../../icons/ui_icons.dart';
import '../../theme/tokens.dart';
import 'unified_table_config.dart';
import 'unified_table_controller.dart';
import 'unified_table_state.dart';
import 'unified_table_column.dart';
import 'unified_typed_filter_dialog.dart';

/// Opens the unified view panel as a dialog. Pass [controller], [fullList], [onStateChanged].
/// [initialTabIndex]: 0=Filters, 1=Columns, 2=Sort, 3=Statistics.
void showUnifiedViewPanel<T>({
  required BuildContext context,
  required UnifiedTableController<T> controller,
  required List<T> fullList,
  required VoidCallback onStateChanged,
  int initialTabIndex = 0,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => _UnifiedViewPanelDialog<T>(
      controller: controller,
      fullList: fullList,
      onStateChanged: onStateChanged,
      initialTabIndex: initialTabIndex,
    ),
  );
}

class _UnifiedViewPanelDialog<T> extends StatefulWidget {
  const _UnifiedViewPanelDialog({
    required this.controller,
    required this.fullList,
    required this.onStateChanged,
    this.initialTabIndex = 0,
  });

  final UnifiedTableController<T> controller;
  final List<T> fullList;
  final VoidCallback onStateChanged;
  final int initialTabIndex;

  @override
  State<_UnifiedViewPanelDialog<T>> createState() => _UnifiedViewPanelDialogState<T>();
}

class _UnifiedViewPanelDialogState<T> extends State<_UnifiedViewPanelDialog<T>> {
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 3);
  }

  UnifiedTableConfig<T> get config => widget.controller.config;
  UnifiedTableState get state => widget.controller.state;

  void _applyState(UnifiedTableState next) {
    widget.controller.state = next;
    widget.onStateChanged();
    setState(() {});
  }

  void _reset() {
    _applyState(config.initialState);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(s.md, s.md, s.md, s.xs),
              child: Row(
                children: [
                  Text('View:', style: theme.textTheme.titleSmall),
                  SizedBox(width: s.xs),
                  DropdownButton<String?>(
                    value: state.activeViewId,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Custom')),
                      ...config.savedViews.map((v) => DropdownMenuItem<String?>(value: v.id, child: Text(v.name))),
                    ],
                    onChanged: (id) {
                      if (id == null) {
                        _applyState(state.copyWith(activeViewId: null));
                      } else {
                        for (final v in config.savedViews) {
                          if (v.id == id) {
                            widget.controller.applyView(v);
                            widget.onStateChanged();
                            setState(() {});
                            break;
                          }
                        }
                      }
                    },
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
              child: Row(
                children: [
                  _sectionTab(context, 0, 'Filters'),
                  SizedBox(width: s.xxs),
                  _sectionTab(context, 1, 'Columns'),
                  SizedBox(width: s.xxs),
                  _sectionTab(context, 2, 'Sort'),
                  SizedBox(width: s.xxs),
                  _sectionTab(context, 3, 'Statistics'),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(s.md),
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    _FiltersSection<T>(
                      controller: widget.controller,
                      fullList: widget.fullList,
                      onStateChanged: () {
                        widget.onStateChanged();
                        setState(() {});
                      },
                      openTypedFilter: _openTypedFilterForColumn,
                    ),
                    _ColumnsSection<T>(
                      controller: widget.controller,
                      onStateChanged: () {
                        widget.onStateChanged();
                        setState(() {});
                      },
                    ),
                    _SortSection<T>(
                      controller: widget.controller,
                      onStateChanged: () {
                        widget.onStateChanged();
                        setState(() {});
                      },
                    ),
                    _StatisticsSection<T>(
                      controller: widget.controller,
                      visibleRows: widget.controller.getVisibleRows(widget.fullList),
                      onStateChanged: () {
                        widget.onStateChanged();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(s.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTab(BuildContext context, int index, String label) {
    final theme = Theme.of(context);
    final selected = _selectedTabIndex == index;
    return TextButton(
      onPressed: () => setState(() => _selectedTabIndex = index),
      style: TextButton.styleFrom(
        foregroundColor: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }

  void _openTypedFilterForColumn(UnifiedTableColumn<T> column) {
    final filterForColumn = state.filters.where((f) => f.columnId == column.id).toList();
    final currentFilter = filterForColumn.isNotEmpty ? filterForColumn.first : null;
    showUnifiedTypedFilterDialog<T>(
      context: context,
      column: column,
      fullList: widget.fullList,
      currentFilter: currentFilter,
      onApply: (descriptor) {
        if (descriptor == null) {
          _applyState(state.removeFilter(columnId: column.id));
        } else {
          _applyState(state.addOrReplaceFilter(descriptor));
        }
      },
    );
  }
}

String _columnLabel<T>(UnifiedTableConfig<T> config, String columnId) {
  for (final c in config.columns) {
    if (c.id == columnId) return c.label;
  }
  return columnId;
}

UnifiedTableColumn<T>? _columnById<T>(UnifiedTableConfig<T> config, String columnId) {
  for (final c in config.columns) {
    if (c.id == columnId) return c;
  }
  return null;
}

class _FiltersSection<T> extends StatelessWidget {
  const _FiltersSection({
    required this.controller,
    required this.fullList,
    required this.onStateChanged,
    required this.openTypedFilter,
  });

  final UnifiedTableController<T> controller;
  final List<T> fullList;
  final VoidCallback onStateChanged;
  final void Function(UnifiedTableColumn<T> column) openTypedFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final config = controller.config;
    final filters = controller.state.filters;
    final filterableColumns = config.columns.where((c) => c.filterable && c.valueGetter != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (filters.isNotEmpty) ...[
          ...filters.map((f) {
            final columnLabel = _columnLabel(config, f.columnId);
            final valueStr = f.toHumanReadableValueString();
            final label = valueStr.isEmpty ? columnLabel : '$columnLabel: $valueStr';
            return Padding(
              padding: EdgeInsets.only(bottom: s.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(UiIcons.close, size: 18),
                    onPressed: () {
                      controller.state = controller.state.removeFilter(columnId: f.columnId);
                      onStateChanged();
                    },
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            );
          }),
          TextButton(
            onPressed: () {
              controller.state = controller.state.clearFilters();
              onStateChanged();
            },
            child: const Text('Clear all filters'),
          ),
          SizedBox(height: s.sm),
        ],
        if (filterableColumns.isNotEmpty) ...[
          Text('Add filter', style: theme.textTheme.labelMedium),
          SizedBox(height: s.xxs),
          DropdownButtonFormField<String>(
            key: ValueKey('add_filter_${filters.length}'),
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
              contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
            ),
            initialValue: null,
            hint: const Text('Select column'),
            items: filterableColumns.map((c) => DropdownMenuItem(value: c.id, child: Text(c.label))).toList(),
            onChanged: (columnId) {
              if (columnId == null) return;
              final column = _columnById(config, columnId);
              if (column != null) openTypedFilter(column);
            },
          ),
        ],
      ],
    );
  }
}

class _ColumnsSection<T> extends StatelessWidget {
  const _ColumnsSection({
    required this.controller,
    required this.onStateChanged,
  });

  final UnifiedTableController<T> controller;
  final VoidCallback onStateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final config = controller.config;
    final order = controller.state.columnOrder ?? config.columns.map((c) => c.id).toList();
    final visibleIds = controller.state.visibleColumnIds?.toSet() ?? config.columns.map((c) => c.id).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Visible columns and order', style: theme.textTheme.labelMedium),
        SizedBox(height: s.xs),
        ...order.asMap().entries.map((entry) {
          final i = entry.key;
          final columnId = entry.value;
          final column = _columnById(config, columnId);
          if (column == null) return const SizedBox.shrink();
          final visible = visibleIds.contains(columnId);
          return Padding(
            padding: EdgeInsets.only(bottom: s.xxs),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    onPressed: i > 0
                        ? () {
                            final next = List<String>.from(order);
                            next.insert(i - 1, next.removeAt(i));
                            controller.state = controller.state.copyWithAsCustom(
                              columnOrder: next,
                              visibleColumnIds: controller.state.visibleColumnIds != null ? List.from(visibleIds) : null,
                            );
                            onStateChanged();
                          }
                        : null,
                    style: IconButton.styleFrom(minimumSize: const Size(28, 28), padding: EdgeInsets.zero),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    onPressed: i < order.length - 1
                        ? () {
                            final next = List<String>.from(order);
                            next.insert(i + 1, next.removeAt(i));
                            controller.state = controller.state.copyWithAsCustom(
                              columnOrder: next,
                              visibleColumnIds: controller.state.visibleColumnIds != null ? List.from(visibleIds) : null,
                            );
                            onStateChanged();
                          }
                        : null,
                    style: IconButton.styleFrom(minimumSize: const Size(28, 28), padding: EdgeInsets.zero),
                  ),
                ),
                Checkbox(
                  value: visible,
                  onChanged: column.hideable
                      ? (v) {
                          final next = Set<String>.from(visibleIds);
                          if (v == true) {
                            next.add(columnId);
                          } else {
                            next.remove(columnId);
                          }
                          if (next.isEmpty) return;
                          final visibleOrdered = order.where((id) => next.contains(id)).toList();
                          controller.state = controller.state.copyWithAsCustom(
                            visibleColumnIds: visibleOrdered,
                            columnOrder: order,
                          );
                          onStateChanged();
                        }
                      : null,
                ),
                Expanded(child: Text(column.label, style: theme.textTheme.bodyMedium)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SortSection<T> extends StatelessWidget {
  const _SortSection({
    required this.controller,
    required this.onStateChanged,
  });

  final UnifiedTableController<T> controller;
  final VoidCallback onStateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final config = controller.config;
    final sorts = controller.state.sorts;
    final sortableColumns = config.columns.where((c) => c.sortable && c.valueGetter != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sorts.isNotEmpty) ...[
          ...sorts.asMap().entries.map((entry) {
            final i = entry.key;
            final sort = entry.value;
            final columnLabel = _columnLabel(config, sort.columnId);
            return Padding(
              padding: EdgeInsets.only(bottom: s.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      onPressed: i > 0
                          ? () {
                              final next = List<UnifiedSortDescriptor>.from(sorts);
                              final t = next[i - 1];
                              next[i - 1] = next[i];
                              next[i] = t;
                              controller.state = controller.state.copyWithAsCustom(sorts: next);
                              onStateChanged();
                            }
                          : null,
                      style: IconButton.styleFrom(minimumSize: const Size(28, 28), padding: EdgeInsets.zero),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      onPressed: i < sorts.length - 1
                          ? () {
                              final next = List<UnifiedSortDescriptor>.from(sorts);
                              final t = next[i + 1];
                              next[i + 1] = next[i];
                              next[i] = t;
                              controller.state = controller.state.copyWithAsCustom(sorts: next);
                              onStateChanged();
                            }
                          : null,
                      style: IconButton.styleFrom(minimumSize: const Size(28, 28), padding: EdgeInsets.zero),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$columnLabel ${sort.ascending ? '↑' : '↓'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(UiIcons.close, size: 18),
                    onPressed: () {
                      final next = sorts.where((x) => x.columnId != sort.columnId).toList();
                      controller.state = controller.state.copyWithAsCustom(sorts: next);
                      onStateChanged();
                    },
                    style: IconButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: s.sm),
        ],
        if (sortableColumns.isNotEmpty) ...[
          Text('Add sort', style: theme.textTheme.labelMedium),
          SizedBox(height: s.xxs),
          DropdownButtonFormField<String>(
            key: const ValueKey('add_sort'),
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
              contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
            ),
            initialValue: null,
            hint: const Text('Select column'),
            items: sortableColumns
                .where((c) => !sorts.any((s) => s.columnId == c.id))
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.label)))
                .toList(),
            onChanged: (columnId) {
              if (columnId == null) return;
              final next = List<UnifiedSortDescriptor>.from(sorts);
              next.add(UnifiedSortDescriptor(columnId: columnId, ascending: true));
              controller.state = controller.state.copyWithAsCustom(sorts: next);
              onStateChanged();
            },
          ),
        ],
      ],
    );
  }
}

class _StatisticsSection<T> extends StatelessWidget {
  const _StatisticsSection({
    required this.controller,
    required this.visibleRows,
    required this.onStateChanged,
  });

  final UnifiedTableController<T> controller;
  final List<T> visibleRows;
  final VoidCallback onStateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final config = controller.config;
    final statsVisible = controller.state.statsVisible;
    final selectedIds = controller.state.selectedMetricIds;
    final metrics = config.availableMetrics;
    final rawValues = controller.getStatsValues(visibleRows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Show statistics', style: theme.textTheme.bodyMedium),
            const Spacer(),
            Switch(
              value: statsVisible,
              onChanged: (v) {
                controller.state = controller.state.copyWithAsCustom(statsVisible: v);
                onStateChanged();
              },
            ),
          ],
        ),
        SizedBox(height: s.sm),
        Text('Metrics', style: theme.textTheme.labelMedium),
        SizedBox(height: s.xxs),
        ...metrics.map((m) {
          final selected = selectedIds.isEmpty || selectedIds.contains(m.id);
          final value = rawValues[m.id] ?? 0;
          final valueStr = controller.formatMetricValue(m.id, value);
          return CheckboxListTile(
            dense: true,
            title: Text(m.label, style: theme.textTheme.bodySmall),
            secondary: Text(valueStr, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            value: selected,
            onChanged: (v) {
              var next = List<String>.from(selectedIds.isEmpty ? metrics.map((x) => x.id) : selectedIds);
              if (v == true) {
                if (!next.contains(m.id)) next.add(m.id);
              } else {
                next = next.where((id) => id != m.id).toList();
                if (next.isEmpty) next = [metrics.first.id];
              }
              controller.state = controller.state.copyWithAsCustom(selectedMetricIds: next);
              onStateChanged();
            },
          );
        }),
      ],
    );
  }
}
