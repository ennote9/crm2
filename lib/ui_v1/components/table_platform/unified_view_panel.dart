// Unified View Panel v2. Single entry: filters, columns, sort, statistics, saved views CRUD.

import 'package:flutter/material.dart';

import '../../icons/ui_icons.dart';
import '../../theme/tokens.dart';
import 'saved_table_view.dart';
import 'saved_view_share_mode.dart';
import 'bulk_paste_parser.dart';
import 'unified_filter_descriptor.dart';
import 'unified_table_config.dart';
import 'unified_table_controller.dart';
import 'unified_table_state.dart';
import 'unified_table_column.dart';
import 'unified_stats_metric.dart';

/// Opens the unified view panel as a dialog. For drawer use, put [UnifiedViewPanelContent] in [Drawer]/[EndDrawer].
/// When [savedViews] and [onSavedViewsChanged] are set, header shows Save / Save as / Delete / Share / Reset.
void showUnifiedViewPanel<T>({
  required BuildContext context,
  required UnifiedTableController<T> controller,
  required List<T> fullList,
  required VoidCallback onStateChanged,
  int initialTabIndex = 0,
  List<SavedTableView>? savedViews,
  void Function(List<SavedTableView>)? onSavedViewsChanged,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: UnifiedViewPanelContent<T>(
          controller: controller,
          fullList: fullList,
          onStateChanged: onStateChanged,
          initialTabIndex: initialTabIndex,
          savedViews: savedViews,
          onSavedViewsChanged: onSavedViewsChanged,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    ),
  );
}

/// Content for View Panel. Use inside [Drawer]/[EndDrawer] or via [showUnifiedViewPanel].
class UnifiedViewPanelContent<T> extends StatefulWidget {
  const UnifiedViewPanelContent({
    super.key,
    required this.controller,
    required this.fullList,
    required this.onStateChanged,
    this.initialTabIndex = 0,
    this.savedViews,
    this.onSavedViewsChanged,
    this.onClose,
  });

  final UnifiedTableController<T> controller;
  final List<T> fullList;
  final VoidCallback onStateChanged;
  final int initialTabIndex;
  final List<SavedTableView>? savedViews;
  final void Function(List<SavedTableView>)? onSavedViewsChanged;
  final VoidCallback? onClose;

  @override
  State<UnifiedViewPanelContent<T>> createState() => _UnifiedViewPanelContentState<T>();
}

class _UnifiedViewPanelContentState<T> extends State<UnifiedViewPanelContent<T>> {
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 3);
  }

  UnifiedTableConfig<T> get config => widget.controller.config;
  UnifiedTableState get state => widget.controller.state;
  List<SavedTableView> get _savedViews => widget.savedViews ?? config.savedViews;

  void _applyState(UnifiedTableState next) {
    widget.controller.state = next;
    widget.onStateChanged();
    setState(() {});
  }

  void _reset() {
    _applyState(config.initialState);
  }

  SavedTableView? get _currentView {
    final id = state.activeViewId;
    if (id == null) return null;
    for (final v in _savedViews) {
      if (v.id == id) return v;
    }
    return null;
  }

  void _saveCurrentView() {
    final v = _currentView;
    if (v == null || widget.onSavedViewsChanged == null) return;
    final updated = SavedTableView.fromState(
      id: v.id,
      tableId: config.tableId,
      name: v.name,
      state: state,
      ownerUserId: v.ownerUserId,
      sharedMode: v.sharedMode,
      createdAt: v.createdAt,
      updatedAt: DateTime.now(),
    );
    final next = _savedViews.map((x) => x.id == v.id ? updated : x).toList();
    widget.onSavedViewsChanged!(next);
    widget.onStateChanged();
    setState(() {});
  }

  void _saveAsNewView() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController(text: _currentView?.name ?? '');
        return AlertDialog(
          title: const Text('Save as new view'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty || widget.onSavedViewsChanged == null) return;
    final newId = 'view_${DateTime.now().millisecondsSinceEpoch}';
    final newView = SavedTableView.fromState(
      id: newId,
      tableId: config.tableId,
      name: name,
      state: state,
    );
    final next = List<SavedTableView>.from(_savedViews)..add(newView);
    widget.onSavedViewsChanged!(next);
    widget.controller.state = state.copyWith(activeViewId: newId);
    widget.onStateChanged();
    setState(() {});
  }

  void _deleteCurrentView() {
    final v = _currentView;
    if (v == null || widget.onSavedViewsChanged == null) return;
    final next = _savedViews.where((x) => x.id != v.id).toList();
    widget.onSavedViewsChanged!(next);
    _applyState(state.copyWith(activeViewId: null));
  }

  void _toggleShareCurrentView() {
    final v = _currentView;
    if (v == null || widget.onSavedViewsChanged == null) return;
    final nextMode = v.sharedMode == SavedViewShareMode.shared ? SavedViewShareMode.private_ : SavedViewShareMode.shared;
    final updated = v.copyWith(sharedMode: nextMode, updatedAt: DateTime.now());
    final next = _savedViews.map((x) => x.id == v.id ? updated : x).toList();
    widget.onSavedViewsChanged!(next);
    widget.onStateChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final hasCrud = widget.savedViews != null && widget.onSavedViewsChanged != null;
    final currentView = _currentView;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.all(s.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('View', style: theme.textTheme.titleSmall),
                  SizedBox(width: s.xs),
                  DropdownButton<String?>(
                    value: state.activeViewId,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Custom')),
                      ..._savedViews.map((v) => DropdownMenuItem<String?>(value: v.id, child: Text(v.name))),
                    ],
                    onChanged: (id) {
                      if (id == null) {
                        _applyState(state.copyWith(activeViewId: null));
                      } else {
                        for (final v in _savedViews) {
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
                ],
              ),
              if (hasCrud) ...[
                SizedBox(height: s.xs),
                Wrap(
                  spacing: s.xxs,
                  runSpacing: s.xxs,
                  children: [
                    FilledButton.tonal(
                      onPressed: currentView != null ? _saveCurrentView : null,
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 32)),
                      child: const Text('Save'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _saveAsNewView(),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 32)),
                      child: const Text('Save as'),
                    ),
                    TextButton(
                      onPressed: currentView != null ? _deleteCurrentView : null,
                      child: const Text('Delete'),
                    ),
                    if (currentView != null)
                      TextButton(
                        onPressed: _toggleShareCurrentView,
                        child: Text(currentView.isShared ? 'Shared' : 'Private'),
                      ),
                    TextButton(onPressed: _reset, child: const Text('Reset')),
                  ],
                ),
              ] else
                Padding(
                  padding: EdgeInsets.only(top: s.xs),
                  child: TextButton(onPressed: _reset, child: const Text('Reset')),
                ),
            ],
          ),
        ),
        Divider(height: 1),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
          child: Row(
            children: [
              _sectionTab(0, 'Filters'),
              SizedBox(width: s.xxs),
              _sectionTab(1, 'Columns'),
              SizedBox(width: s.xxs),
              _sectionTab(2, 'Sort'),
              SizedBox(width: s.xxs),
              _sectionTab(3, 'Statistics'),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(s.md),
            child: IndexedStack(
              index: _selectedTabIndex,
              sizing: StackFit.loose,
              children: [
                _FiltersSection<T>(
                  controller: widget.controller,
                  fullList: widget.fullList,
                  onStateChanged: () {
                    widget.onStateChanged();
                    setState(() {});
                  },
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
              if (widget.onClose != null)
                TextButton(
                  onPressed: widget.onClose,
                  child: const Text('Close'),
                )
              else
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTab(int index, String label) {
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

enum _FilterMode { text, enum_, date }

_FilterMode _effectiveFilterMode<T>(UnifiedTableColumn<T>? column) {
  if (column == null) return _FilterMode.text;
  if (column.filterType == UnifiedColumnFilterType.enum_) return _FilterMode.enum_;
  if (column.filterType == UnifiedColumnFilterType.date) return _FilterMode.date;
  return _FilterMode.text;
}

List<UnifiedFilterOperator> _operatorsForMode(_FilterMode mode) {
  switch (mode) {
    case _FilterMode.text:
      return [
        UnifiedFilterOperator.contains,
        UnifiedFilterOperator.notContains,
        UnifiedFilterOperator.equals,
        UnifiedFilterOperator.notEquals,
        UnifiedFilterOperator.startsWith,
        UnifiedFilterOperator.endsWith,
        UnifiedFilterOperator.inList,
        UnifiedFilterOperator.notInList,
        UnifiedFilterOperator.isEmpty,
        UnifiedFilterOperator.isNotEmpty,
      ];
    case _FilterMode.enum_:
      return [
        UnifiedFilterOperator.equals,
        UnifiedFilterOperator.notEquals,
        UnifiedFilterOperator.inList,
        UnifiedFilterOperator.notInList,
        UnifiedFilterOperator.isEmpty,
        UnifiedFilterOperator.isNotEmpty,
      ];
    case _FilterMode.date:
      return [
        UnifiedFilterOperator.equals,
        UnifiedFilterOperator.lessThan,
        UnifiedFilterOperator.greaterThan,
        UnifiedFilterOperator.between,
        UnifiedFilterOperator.isEmpty,
        UnifiedFilterOperator.isNotEmpty,
      ];
  }
}

UnifiedFilterOperator _defaultOperator(_FilterMode mode) {
  switch (mode) {
    case _FilterMode.text:
      return UnifiedFilterOperator.contains;
    case _FilterMode.enum_:
      return UnifiedFilterOperator.inList;
    case _FilterMode.date:
      return UnifiedFilterOperator.equals;
  }
}

String _operatorLabel(UnifiedFilterOperator op, _FilterMode mode) {
  if (op == UnifiedFilterOperator.equals && mode == _FilterMode.date) return 'On date';
  if (op == UnifiedFilterOperator.greaterThan && mode == _FilterMode.date) return 'After';
  if (op == UnifiedFilterOperator.lessThan && mode == _FilterMode.date) return 'Before';
  return UnifiedFilterDescriptor.operatorLabel(op);
}

class _InlineFilterRow<T> extends StatefulWidget {
  const _InlineFilterRow({
    super.key,
    required this.descriptor,
    required this.config,
    required this.fullList,
    required this.filterableColumnIds,
    required this.onChanged,
    required this.onRemove,
  });

  final UnifiedFilterDescriptor descriptor;
  final UnifiedTableConfig<T> config;
  final List<T> fullList;
  final List<String> filterableColumnIds;
  final void Function(UnifiedFilterDescriptor?) onChanged;
  final VoidCallback onRemove;

  @override
  State<_InlineFilterRow<T>> createState() => _InlineFilterRowState<T>();
}

class _InlineFilterRowState<T> extends State<_InlineFilterRow<T>> {
  late TextEditingController _textController;
  late TextEditingController _dateFromController;
  late TextEditingController _dateToController;
  Set<String> _enumSelection = {};
  String _enumSearch = '';

  @override
  void initState() {
    super.initState();
    _syncFromDescriptor();
  }

  @override
  void didUpdateWidget(covariant _InlineFilterRow<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.descriptor.columnId != widget.descriptor.columnId ||
        oldWidget.descriptor.operator != widget.descriptor.operator ||
        oldWidget.descriptor.value != widget.descriptor.value ||
        oldWidget.descriptor.values != widget.descriptor.values ||
        oldWidget.descriptor.secondaryValue != widget.descriptor.secondaryValue) {
      _syncFromDescriptor();
    }
  }

  void _syncFromDescriptor() {
    final f = widget.descriptor;
    final column = _columnById(widget.config, f.columnId);
    final mode = _effectiveFilterMode(column);
    final isBulk = mode == _FilterMode.text &&
        (f.operator == UnifiedFilterOperator.inList || f.operator == UnifiedFilterOperator.notInList);
    if (isBulk && f.values != null && f.values!.isNotEmpty) {
      _textController = TextEditingController(text: f.values!.map((e) => e.toString()).join('\n'));
    } else {
      _textController = TextEditingController(text: f.value?.toString() ?? '');
    }
    _dateFromController = TextEditingController(text: f.value?.toString() ?? '');
    _dateToController = TextEditingController(text: f.secondaryValue?.toString() ?? '');
    _enumSelection = f.values != null && f.values!.isNotEmpty
        ? f.values!.map((e) => e.toString()).toSet()
        : (f.value != null ? {f.value.toString()} : {});
  }

  @override
  void dispose() {
    _textController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  void _emit(UnifiedFilterDescriptor d) => widget.onChanged(d);

  bool get _needsValue {
    final op = widget.descriptor.operator;
    return op != UnifiedFilterOperator.isEmpty && op != UnifiedFilterOperator.isNotEmpty;
  }

  bool get _needsSecondaryValue => widget.descriptor.operator == UnifiedFilterOperator.between;

  bool get _isTextBulk =>
      _effectiveFilterMode(_columnById(widget.config, widget.descriptor.columnId)) == _FilterMode.text &&
      (widget.descriptor.operator == UnifiedFilterOperator.inList ||
          widget.descriptor.operator == UnifiedFilterOperator.notInList);

  List<String> _distinctEnumValues() {
    final column = _columnById(widget.config, widget.descriptor.columnId);
    if (column?.valueGetter == null) return [];
    final set = <String>{};
    for (final row in widget.fullList) {
      final v = column!.valueGetter!(row);
      if (v != null) set.add(v.toString());
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final column = _columnById(widget.config, widget.descriptor.columnId);
    final mode = _effectiveFilterMode(column);
    final operators = _operatorsForMode(mode);

    return Container(
      margin: EdgeInsets.only(bottom: s.sm),
      padding: EdgeInsets.all(s.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(tokens.radius.sm),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: widget.filterableColumnIds.contains(widget.descriptor.columnId)
                      ? widget.descriptor.columnId
                      : null,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Column',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.xs)),
                    contentPadding: EdgeInsets.symmetric(horizontal: s.xs, vertical: s.xxs),
                  ),
                  items: widget.filterableColumnIds.map((id) {
                    return DropdownMenuItem(value: id, child: Text(_columnLabel(widget.config, id)));
                  }).toList(),
                  onChanged: (columnId) {
                    if (columnId == null) return;
                    final col = _columnById(widget.config, columnId);
                    _emit(UnifiedFilterDescriptor(
                      columnId: columnId,
                      operator: _defaultOperator(_effectiveFilterMode(col)),
                      id: widget.descriptor.id,
                    ));
                  },
                ),
              ),
              SizedBox(width: s.xs),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<UnifiedFilterOperator>(
                  initialValue: widget.descriptor.operator,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Operator',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.xs)),
                    contentPadding: EdgeInsets.symmetric(horizontal: s.xs, vertical: s.xxs),
                  ),
                  items: operators.map((op) {
                    return DropdownMenuItem(
                      value: op,
                      child: Text(_operatorLabel(op, mode)),
                    );
                  }).toList(),
                  onChanged: (op) {
                    if (op == null) return;
                    _emit(UnifiedFilterDescriptor(
                      columnId: widget.descriptor.columnId,
                      operator: op,
                      value: widget.descriptor.value,
                      secondaryValue: widget.descriptor.secondaryValue,
                      values: widget.descriptor.values,
                      id: widget.descriptor.id,
                    ));
                  },
                ),
              ),
              IconButton(
                icon: const Icon(UiIcons.close, size: 18),
                onPressed: widget.onRemove,
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (_needsValue) ...[
            SizedBox(height: s.xs),
            if (mode == _FilterMode.text) ..._buildTextValueEditor(tokens, theme),
            if (mode == _FilterMode.enum_) ..._buildEnumValueEditor(tokens, theme),
            if (mode == _FilterMode.date) ..._buildDateValueEditor(tokens, theme),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildTextValueEditor(UiV1Tokens tokens, ThemeData theme) {
    final s = tokens.spacing;
    if (_isTextBulk) {
      return [
        TextField(
          controller: _textController,
          maxLines: 4,
          minLines: 2,
          decoration: InputDecoration(
            isDense: true,
            labelText: 'Values',
            hintText: 'Paste or type; separate by newline, comma, semicolon, tab',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
            contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
          ),
          onChanged: (_) {
            setState(() {});
            final parsed = parseBulkPasteValues(_textController.text);
            if (parsed.isNotEmpty) {
              _emit(UnifiedFilterDescriptor(
                columnId: widget.descriptor.columnId,
                operator: widget.descriptor.operator,
                values: parsed,
                id: widget.descriptor.id,
              ));
            }
          },
        ),
        SizedBox(height: s.xxs),
        Text(
          'Parsed: ${bulkPasteCounts(_textController.text).$1}, Unique: ${bulkPasteCounts(_textController.text).$2}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ];
    }
    return [
      TextField(
        controller: _textController,
        decoration: InputDecoration(
          isDense: true,
          labelText: 'Value',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
          contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
        ),
        onChanged: (_) {
          final v = _textController.text.trim();
          _emit(UnifiedFilterDescriptor(
            columnId: widget.descriptor.columnId,
            operator: widget.descriptor.operator,
            value: v.isEmpty ? null : v,
            id: widget.descriptor.id,
          ));
        },
      ),
    ];
  }

  List<Widget> _buildEnumValueEditor(UiV1Tokens tokens, ThemeData theme) {
    final s = tokens.spacing;
    final single = widget.descriptor.operator == UnifiedFilterOperator.equals ||
        widget.descriptor.operator == UnifiedFilterOperator.notEquals;
    final options = _distinctEnumValues();
    final filtered = _enumSearch.trim().isEmpty
        ? options
        : options.where((v) => v.toLowerCase().contains(_enumSearch.trim().toLowerCase())).toList();

    if (single) {
      return [
        DropdownButtonFormField<String>(
          initialValue: _enumSelection.isEmpty ? null : _enumSelection.single,
          decoration: InputDecoration(
            isDense: true,
            labelText: 'Value',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
            contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
          ),
          items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) {
            if (v == null) return;
            _enumSelection = {v};
            _emit(UnifiedFilterDescriptor(
              columnId: widget.descriptor.columnId,
              operator: widget.descriptor.operator,
              value: v,
              id: widget.descriptor.id,
            ));
          },
        ),
      ];
    }

    return [
      ExpansionTile(
        title: Text(
          _enumSelection.isEmpty ? 'Select values' : '${_enumSelection.length} selected',
          style: theme.textTheme.bodySmall,
        ),
        initiallyExpanded: _enumSelection.isNotEmpty,
        children: [
          Padding(
            padding: EdgeInsets.only(left: s.xs, right: s.xs, bottom: s.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search…',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.xs)),
                  ),
                  onChanged: (v) => setState(() => _enumSearch = v),
                ),
                SizedBox(height: s.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final value = filtered[i];
                      final selected = _enumSelection.contains(value);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(value, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                        value: selected,
                        onChanged: (v) {
                          final next = Set<String>.from(_enumSelection);
                          if (v == true) {
                            next.add(value);
                          } else {
                            next.remove(value);
                          }
                          setState(() => _enumSelection = next);
                          _emit(UnifiedFilterDescriptor(
                            columnId: widget.descriptor.columnId,
                            operator: widget.descriptor.operator,
                            values: next.toList(),
                            id: widget.descriptor.id,
                          ));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildDateValueEditor(UiV1Tokens tokens, ThemeData theme) {
    final s = tokens.spacing;
    if (_needsSecondaryValue) {
      return [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _dateFromController,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'From',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
                  contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
                ),
                onChanged: (_) {
                  final from = _dateFromController.text.trim();
                  final to = _dateToController.text.trim();
                  if (from.isNotEmpty && to.isNotEmpty) {
                    _emit(UnifiedFilterDescriptor(
                      columnId: widget.descriptor.columnId,
                      operator: UnifiedFilterOperator.between,
                      value: from,
                      secondaryValue: to,
                      id: widget.descriptor.id,
                    ));
                  }
                },
              ),
            ),
            SizedBox(width: s.xs),
            Expanded(
              child: TextField(
                controller: _dateToController,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'To',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
                  contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
                ),
                onChanged: (_) {
                  final from = _dateFromController.text.trim();
                  final to = _dateToController.text.trim();
                  if (from.isNotEmpty && to.isNotEmpty) {
                    _emit(UnifiedFilterDescriptor(
                      columnId: widget.descriptor.columnId,
                      operator: UnifiedFilterOperator.between,
                      value: from,
                      secondaryValue: to,
                      id: widget.descriptor.id,
                    ));
                  }
                },
              ),
            ),
          ],
        ),
      ];
    }
    return [
      TextField(
        controller: _dateFromController,
        decoration: InputDecoration(
          isDense: true,
          labelText: 'Date',
          hintText: 'YYYY-MM-DD',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
          contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
        ),
        onChanged: (_) {
          final v = _dateFromController.text.trim();
          _emit(UnifiedFilterDescriptor(
            columnId: widget.descriptor.columnId,
            operator: widget.descriptor.operator,
            value: v.isEmpty ? null : v,
            id: widget.descriptor.id,
          ));
        },
      ),
    ];
  }
}

class _FiltersSection<T> extends StatelessWidget {
  const _FiltersSection({
    required this.controller,
    required this.fullList,
    required this.onStateChanged,
  });

  final UnifiedTableController<T> controller;
  final List<T> fullList;
  final VoidCallback onStateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final config = controller.config;
    final filters = controller.state.filters;
    final filterableColumns = config.columns.where((c) => c.filterable && c.valueGetter != null).toList();
    final filterableColumnIds = filterableColumns.map((c) => c.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (filters.isNotEmpty) ...[
          ...filters.map((f) {
            return _InlineFilterRow<T>(
              key: ValueKey(f.identity),
              descriptor: f,
              config: config,
              fullList: fullList,
              filterableColumnIds: filterableColumnIds,
              onChanged: (d) {
                if (d == null) {
                  controller.state = controller.state.removeFilter(columnId: f.columnId);
                } else {
                  controller.state = controller.state.addOrReplaceFilter(d);
                }
                onStateChanged();
              },
              onRemove: () {
                controller.state = controller.state.removeFilter(columnId: f.columnId);
                onStateChanged();
              },
            );
          }),
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: TextButton(
              onPressed: () {
                controller.state = controller.state.clearFilters();
                onStateChanged();
              },
              child: const Text('Clear all filters'),
            ),
          ),
        ],
        if (filterableColumns.isNotEmpty) ...[
          Text('Add condition', style: theme.textTheme.labelMedium),
          SizedBox(height: s.xxs),
          OutlinedButton.icon(
            onPressed: () {
              final first = filterableColumns.first;
              final mode = _effectiveFilterMode(first);
              controller.state = controller.state.addOrReplaceFilter(UnifiedFilterDescriptor(
                columnId: first.id,
                operator: _defaultOperator(mode),
              ));
              onStateChanged();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add condition'),
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
    final visibleOrdered = order.where((id) => visibleIds.contains(id)).toList();
    final hiddenIds = order.where((id) => !visibleIds.contains(id)).toList();
    final defaultOrder = config.defaultVisibleColumnIds ?? config.columns.map((c) => c.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Visible columns', style: theme.textTheme.labelMedium),
        SizedBox(height: s.xxs),
        if (visibleOrdered.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: s.sm),
            child: Text('No visible columns', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            itemCount: visibleOrdered.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final next = List<String>.from(visibleOrdered);
              final item = next.removeAt(oldIndex);
              next.insert(newIndex, item);
              final fullOrder = next + hiddenIds;
              controller.state = controller.state.copyWithAsCustom(
                columnOrder: fullOrder,
                visibleColumnIds: next,
              );
              onStateChanged();
            },
            itemBuilder: (context, i) {
              final columnId = visibleOrdered[i];
              final column = _columnById(config, columnId);
              if (column == null) return const SizedBox.shrink(key: ValueKey('col_null'));
              return Row(
                key: ValueKey(columnId),
                children: [
                  ReorderableDragStartListener(index: i, child: Icon(Icons.drag_handle, size: 20, color: theme.colorScheme.onSurfaceVariant)),
                  SizedBox(width: s.xxs),
                  SizedBox(
                    width: 28,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      onPressed: i > 0
                          ? () {
                              final next = List<String>.from(visibleOrdered);
                              next.insert(i - 1, next.removeAt(i));
                              controller.state = controller.state.copyWithAsCustom(
                                columnOrder: next + hiddenIds,
                                visibleColumnIds: next,
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
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      onPressed: i < visibleOrdered.length - 1
                          ? () {
                              final next = List<String>.from(visibleOrdered);
                              next.insert(i + 1, next.removeAt(i));
                              controller.state = controller.state.copyWithAsCustom(
                                columnOrder: next + hiddenIds,
                                visibleColumnIds: next,
                              );
                              onStateChanged();
                            }
                          : null,
                      style: IconButton.styleFrom(minimumSize: const Size(28, 28), padding: EdgeInsets.zero),
                    ),
                  ),
                  Checkbox(
                    value: true,
                    onChanged: column.hideable
                        ? (_) {
                            final next = visibleIds.where((id) => id != columnId).toSet();
                            if (next.isEmpty) return;
                            final visibleOrderedNew = order.where((id) => next.contains(id)).toList();
                            controller.state = controller.state.copyWithAsCustom(
                              visibleColumnIds: visibleOrderedNew,
                              columnOrder: order,
                            );
                            onStateChanged();
                          }
                        : null,
                  ),
                  Expanded(child: Text(column.label, style: theme.textTheme.bodySmall)),
                ],
              );
            },
          ),
        if (hiddenIds.isNotEmpty) ...[
          SizedBox(height: s.sm),
          Text('Hidden columns', style: theme.textTheme.labelMedium),
          SizedBox(height: s.xxs),
          ...hiddenIds.map((columnId) {
            final column = _columnById(config, columnId);
            if (column == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: s.xxs),
              child: Row(
                children: [
                  Icon(Icons.visibility_off, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  SizedBox(width: s.xs),
                  Expanded(child: Text(column.label, style: theme.textTheme.bodySmall)),
                  TextButton(
                    onPressed: () {
                      final next = Set<String>.from(visibleIds)..add(columnId);
                      final visibleOrderedNew = order.where((id) => next.contains(id)).toList();
                      controller.state = controller.state.copyWithAsCustom(
                        visibleColumnIds: visibleOrderedNew,
                        columnOrder: order,
                      );
                      onStateChanged();
                    },
                    child: const Text('Show'),
                  ),
                ],
              ),
            );
          }),
        ],
        SizedBox(height: s.sm),
        OutlinedButton(
          onPressed: () {
            controller.state = controller.state.copyWithAsCustom(
              visibleColumnIds: List.from(defaultOrder),
              columnOrder: List.from(defaultOrder),
            );
            onStateChanged();
          },
          child: const Text('Restore default columns'),
        ),
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
        if (sorts.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            itemCount: sorts.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final next = List<UnifiedSortDescriptor>.from(sorts);
              final item = next.removeAt(oldIndex);
              next.insert(newIndex, item);
              controller.state = controller.state.copyWithAsCustom(sorts: next);
              onStateChanged();
            },
            itemBuilder: (context, i) {
              final sort = sorts[i];
              final columnLabel = _columnLabel(config, sort.columnId);
              return Row(
                key: ValueKey('${sort.columnId}_$i'),
                children: [
                  ReorderableDragStartListener(
                    index: i,
                    child: Icon(Icons.drag_handle, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(width: s.xxs),
                  IconButton(
                    icon: Icon(sort.ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
                    onPressed: () {
                      final next = List<UnifiedSortDescriptor>.from(sorts);
                      next[i] = UnifiedSortDescriptor(columnId: sort.columnId, ascending: !sort.ascending);
                      controller.state = controller.state.copyWithAsCustom(sorts: next);
                      onStateChanged();
                    },
                  ),
                  Expanded(
                    child: Text('$columnLabel ${sort.ascending ? '↑' : '↓'}', style: theme.textTheme.bodySmall),
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
              );
            },
          ),
        if (sorts.isNotEmpty) SizedBox(height: s.sm),
        if (sortableColumns.isNotEmpty) ...[
          Text('Add sort rule', style: theme.textTheme.labelMedium),
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
    final effectiveSelected = selectedIds.isEmpty ? metrics.map((x) => x.id).toList() : selectedIds;
    final selectedOrdered = effectiveSelected.where((id) => metrics.any((m) => m.id == id)).toList();
    final availableIds = metrics.map((m) => m.id).where((id) => !selectedOrdered.contains(id)).toList();

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
        Text('Selected metrics', style: theme.textTheme.labelMedium),
        SizedBox(height: s.xxs),
        if (selectedOrdered.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: s.xs),
            child: Text('No metrics selected', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            itemCount: selectedOrdered.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final next = List<String>.from(selectedOrdered);
              final item = next.removeAt(oldIndex);
              next.insert(newIndex, item);
              controller.state = controller.state.copyWithAsCustom(selectedMetricIds: next);
              onStateChanged();
            },
            itemBuilder: (context, i) {
              final metricId = selectedOrdered[i];
              UnifiedStatsMetricDefinition<T>? m;
              for (final x in metrics) {
                if (x.id == metricId) { m = x; break; }
              }
              if (m == null) return const SizedBox.shrink(key: ValueKey('metric_null'));
              final metric = m;
              final valueStr = controller.formatMetricValue(metric.id, rawValues[metric.id] ?? 0);
              return Row(
                key: ValueKey(metric.id),
                children: [
                  ReorderableDragStartListener(
                    index: i,
                    child: Icon(Icons.drag_handle, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(width: s.xs),
                  Expanded(child: Text(metric.label, style: theme.textTheme.bodySmall)),
                  Text(valueStr, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  IconButton(
                    icon: const Icon(UiIcons.close, size: 18),
                    onPressed: () {
                      var next = List<String>.from(selectedOrdered)..remove(metric.id);
                      if (next.isEmpty) next = [metrics.first.id];
                      controller.state = controller.state.copyWithAsCustom(selectedMetricIds: next);
                      onStateChanged();
                    },
                    style: IconButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
                  ),
                ],
              );
            },
          ),
        if (availableIds.isNotEmpty) ...[
          SizedBox(height: s.sm),
          Text('Available metrics', style: theme.textTheme.labelMedium),
          SizedBox(height: s.xxs),
          ...availableIds.map((metricId) {
            UnifiedStatsMetricDefinition<T>? m;
            for (final x in metrics) {
              if (x.id == metricId) { m = x; break; }
            }
            if (m == null) return const SizedBox.shrink();
            final metric = m;
            return Padding(
              padding: EdgeInsets.only(bottom: s.xxs),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 18, color: theme.colorScheme.primary),
                  SizedBox(width: s.xs),
                  Expanded(child: Text(metric.label, style: theme.textTheme.bodySmall)),
                  TextButton(
                    onPressed: () {
                      final next = List<String>.from(selectedOrdered)..add(metric.id);
                      controller.state = controller.state.copyWithAsCustom(selectedMetricIds: next);
                      onStateChanged();
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
