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
    barrierDismissible: true,
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
/// [currentUserId] and [currentUserDisplayName] used for Save/Save as/Delete and "Shared · Name — Owner".
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
    this.currentUserId,
    this.currentUserDisplayName,
  });

  final UnifiedTableController<T> controller;
  final List<T> fullList;
  final VoidCallback onStateChanged;
  final int initialTabIndex;
  final List<SavedTableView>? savedViews;
  final void Function(List<SavedTableView>)? onSavedViewsChanged;
  final VoidCallback? onClose;
  final String? currentUserId;
  final String? currentUserDisplayName;

  @override
  State<UnifiedViewPanelContent<T>> createState() => _UnifiedViewPanelContentState<T>();
}

class _UnifiedViewPanelContentState<T> extends State<UnifiedViewPanelContent<T>> {
  late int _selectedTabIndex;
  late UnifiedTableState _draftState;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 3);
    _draftState = widget.controller.state;
  }

  UnifiedTableConfig<T> get config => widget.controller.config;
  /// Draft state edited inside the panel; live table uses controller.state until Apply.
  UnifiedTableState get state => _draftState;
  List<SavedTableView> get _savedViews => widget.savedViews ?? config.savedViews;

  void _setDraft(UnifiedTableState next) {
    setState(() => _draftState = next);
  }

  void _applyAndClose() {
    widget.controller.state = _draftState;
    widget.onStateChanged();
    widget.onClose?.call();
  }

  void _reset() {
    if (state.activeViewId == null || state.activeViewId == SavedTableView.kStandardViewId) {
      _setDraft(config.initialState.copyWith(activeViewId: state.activeViewId));
    } else {
      final v = _currentView;
      if (v != null) {
        _setDraft(v.applyTo(config.initialState));
      } else {
        _setDraft(config.initialState.copyWith(activeViewId: null));
      }
    }
  }

  void _applyStandardView() {
    _setDraft(config.initialState.copyWith(activeViewId: SavedTableView.kStandardViewId));
  }

  SavedTableView? get _currentView {
    final id = state.activeViewId;
    if (id == null) return null;
    if (id == SavedTableView.kStandardViewId) return null;
    for (final v in _savedViews) {
      if (v.id == id) return v;
    }
    return null;
  }

  bool get _isCurrentUserView {
    final v = _currentView;
    if (v == null) return false;
    return v.ownerUserId == widget.currentUserId;
  }

  bool get _canSaveCurrentView =>
      _currentView != null && _isCurrentUserView && widget.onSavedViewsChanged != null;

  bool get _canDeleteCurrentView =>
      _currentView != null && _isCurrentUserView && widget.onSavedViewsChanged != null;

  void _saveCurrentView() {
    if (!_canSaveCurrentView || widget.onSavedViewsChanged == null) return;
    final v = _currentView!;
    final updated = SavedTableView.fromState(
      id: v.id,
      tableId: config.tableId,
      name: v.name,
      state: state,
      ownerUserId: v.ownerUserId,
      ownerDisplayName: v.ownerDisplayName,
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
    final result = await showDialog<({String name, bool shared})>(
      context: context,
      builder: (ctx) {
        final nameController = TextEditingController(text: _currentView?.name ?? '');
        bool shared = _currentView?.isShared ?? false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Save as new view'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Shared with others'),
                    value: shared,
                    onChanged: (v) => setDialogState(() => shared = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, (name: nameController.text.trim(), shared: shared)),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == null || result.name.isEmpty || widget.onSavedViewsChanged == null) return;
    final newId = 'view_${DateTime.now().millisecondsSinceEpoch}';
    final newView = SavedTableView.fromState(
      id: newId,
      tableId: config.tableId,
      name: result.name,
      state: state,
      ownerUserId: widget.currentUserId,
      ownerDisplayName: widget.currentUserDisplayName,
      sharedMode: result.shared ? SavedViewShareMode.shared : SavedViewShareMode.private_,
    );
    final next = List<SavedTableView>.from(_savedViews)..add(newView);
    widget.onSavedViewsChanged!(next);
    _setDraft(state.copyWith(activeViewId: newId));
  }

  void _deleteCurrentView() {
    if (!_canDeleteCurrentView || widget.onSavedViewsChanged == null) return;
    final v = _currentView!;
    final next = _savedViews.where((x) => x.id != v.id).toList();
    widget.onSavedViewsChanged!(next);
    _setDraft(config.initialState.copyWith(activeViewId: SavedTableView.kStandardViewId));
  }

  void _toggleShareCurrentView() {
    final v = _currentView;
    if (v == null || !_isCurrentUserView || widget.onSavedViewsChanged == null) return;
    final nextMode = v.sharedMode == SavedViewShareMode.shared ? SavedViewShareMode.private_ : SavedViewShareMode.shared;
    final updated = v.copyWith(sharedMode: nextMode, updatedAt: DateTime.now());
    final next = _savedViews.map((x) => x.id == v.id ? updated : x).toList();
    widget.onSavedViewsChanged!(next);
    widget.onStateChanged();
    setState(() {});
  }

  List<SavedTableView> get _myViews =>
      _savedViews.where((v) => v.ownerUserId == widget.currentUserId).toList();

  List<SavedTableView> get _sharedViewsFromOthers =>
      _savedViews.where((v) => v.isShared && v.ownerUserId != widget.currentUserId).toList();

  String _viewDisplayLabel(SavedTableView v) {
    if (v.ownerUserId == widget.currentUserId) {
      return v.isShared ? '${v.name} (Shared)' : v.name;
    }
    final owner = v.ownerDisplayName ?? v.ownerUserId ?? 'Unknown';
    return '${v.name} — $owner';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final hasCrud = widget.savedViews != null && widget.onSavedViewsChanged != null;
    final currentView = _currentView;
    final myViews = _myViews;
    final sharedOthers = _sharedViewsFromOthers;

    final viewDropdownItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem(value: null, child: Text('Custom')),
      DropdownMenuItem<String?>(
        value: SavedTableView.kStandardViewId,
        child: const Text('Standard (default)'),
      ),
      ...myViews.map((v) => DropdownMenuItem<String?>(value: v.id, child: Text(_viewDisplayLabel(v)))),
      ...sharedOthers.map((v) => DropdownMenuItem<String?>(value: v.id, child: Text(_viewDisplayLabel(v)))),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header: row1 = title + selector + close; row2 = actions
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(s.md, s.sm, s.xs, s.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.25))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'View',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(width: s.sm),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      key: ValueKey(state.activeViewId),
                      initialValue: state.activeViewId,
                      isDense: true,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      items: viewDropdownItems,
                      onChanged: (id) {
                        if (id == null) {
                          _setDraft(config.initialState.copyWith(activeViewId: null));
                        } else if (id == SavedTableView.kStandardViewId) {
                          _applyStandardView();
                        } else {
                          for (final v in _savedViews) {
                            if (v.id == id) {
                              _setDraft(v.applyTo(config.initialState));
                              break;
                            }
                          }
                        }
                      },
                    ),
                  ),
                  if (widget.onClose != null) ...[
                    SizedBox(width: s.xs),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close, size: 22),
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(40, 40),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasCrud) ...[
                SizedBox(height: s.sm),
                Row(
                  children: [
                    FilledButton.tonal(
                      onPressed: _canSaveCurrentView ? _saveCurrentView : null,
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 32), padding: EdgeInsets.symmetric(horizontal: s.sm)),
                      child: const Text('Save'),
                    ),
                    SizedBox(width: s.xs),
                    OutlinedButton(
                      onPressed: () => _saveAsNewView(),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32), padding: EdgeInsets.symmetric(horizontal: s.sm)),
                      child: const Text('Save as'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _canDeleteCurrentView ? _deleteCurrentView : null,
                      style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
                      child: const Text('Delete'),
                    ),
                    if (currentView != null && _isCurrentUserView)
                      TextButton(
                        onPressed: _toggleShareCurrentView,
                        style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
                        child: Text(currentView.isShared ? 'Shared' : 'Private'),
                      ),
                    TextButton(
                      onPressed: _reset,
                      style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(height: s.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _reset, child: const Text('Reset')),
                ),
              ],
            ],
          ),
        ),
        // Tab strip
        Container(
          padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
            border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              _sectionTab(0, 'Filters'),
              _sectionTab(1, 'Columns'),
              _sectionTab(2, 'Sort'),
              _sectionTab(3, 'Statistics'),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
            child: _buildCurrentTabContent(),
          ),
        ),
        // Bottom action bar: Cancel / Apply
        Container(
          padding: EdgeInsets.fromLTRB(s.md, s.sm, s.md, s.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onClose,
                style: TextButton.styleFrom(minimumSize: const Size(0, 36), padding: EdgeInsets.symmetric(horizontal: s.md)),
                child: const Text('Cancel'),
              ),
              SizedBox(width: s.sm),
              FilledButton(
                onPressed: _applyAndClose,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: EdgeInsets.symmetric(horizontal: s.md)),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTab(int index, String label) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final selected = _selectedTabIndex == index;
    return TextButton(
      onPressed: () => setState(() => _selectedTabIndex = index),
      style: TextButton.styleFrom(
        foregroundColor: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.xs),
        ),
      ),
      child: Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: selected ? FontWeight.w600 : null)),
    );
  }

  void _onDraftChanged(UnifiedTableState next) {
    _setDraft(next);
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _FiltersSection<T>(
          controller: widget.controller,
          fullList: widget.fullList,
          draftState: _draftState,
          onDraftChanged: _onDraftChanged,
        );
      case 1:
        return _ColumnsSection<T>(
          controller: widget.controller,
          draftState: _draftState,
          onDraftChanged: _onDraftChanged,
        );
      case 2:
        return _SortSection<T>(
          controller: widget.controller,
          draftState: _draftState,
          onDraftChanged: _onDraftChanged,
        );
      case 3:
        return _StatisticsSection<T>(
          controller: widget.controller,
          draftState: _draftState,
          onDraftChanged: _onDraftChanged,
        );
      default:
        return _FiltersSection<T>(
          controller: widget.controller,
          fullList: widget.fullList,
          draftState: _draftState,
          onDraftChanged: _onDraftChanged,
        );
    }
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
    if (mode == _FilterMode.enum_) {
      final isSingle = f.operator == UnifiedFilterOperator.equals ||
          f.operator == UnifiedFilterOperator.notEquals;
      if (isSingle) {
        _enumSelection = f.value != null ? {f.value.toString()} : {};
      } else {
        _enumSelection = f.values != null && f.values!.isNotEmpty
            ? f.values!.map((e) => e.toString()).toSet()
            : {};
      }
    } else {
      _enumSelection = {};
    }
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
      padding: EdgeInsets.all(s.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(tokens.radius.sm),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
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
                      id: widget.descriptor.id ?? widget.descriptor.columnId,
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
                    contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
                  ),
                  items: operators.map((op) {
                    return DropdownMenuItem(
                      value: op,
                      child: Text(_operatorLabel(op, mode)),
                    );
                  }).toList(),
                  onChanged: (op) {
                    if (op == null) return;
                    final isSingleOp = op == UnifiedFilterOperator.equals ||
                        op == UnifiedFilterOperator.notEquals;
                    if (mode == _FilterMode.enum_) {
                      if (isSingleOp) {
                        final v = widget.descriptor.values != null &&
                                widget.descriptor.values!.isNotEmpty
                            ? widget.descriptor.values!.first.toString()
                            : widget.descriptor.value?.toString();
                        _emit(UnifiedFilterDescriptor(
                          columnId: widget.descriptor.columnId,
                          operator: op,
                          value: v,
                          id: widget.descriptor.id ?? widget.descriptor.columnId,
                        ));
                      } else {
                        final list = widget.descriptor.values != null &&
                                widget.descriptor.values!.isNotEmpty
                            ? List<dynamic>.from(widget.descriptor.values!)
                            : (widget.descriptor.value != null
                                ? [widget.descriptor.value]
                                : <dynamic>[]);
                        _emit(UnifiedFilterDescriptor(
                          columnId: widget.descriptor.columnId,
                          operator: op,
                          values: list,
                          id: widget.descriptor.id ?? widget.descriptor.columnId,
                        ));
                      }
                    } else if (mode == _FilterMode.date && op != UnifiedFilterOperator.between) {
                      _emit(UnifiedFilterDescriptor(
                        columnId: widget.descriptor.columnId,
                        operator: op,
                        value: widget.descriptor.value,
                        id: widget.descriptor.id ?? widget.descriptor.columnId,
                      ));
                    } else {
                      _emit(UnifiedFilterDescriptor(
                        columnId: widget.descriptor.columnId,
                        operator: op,
                        value: widget.descriptor.value,
                        secondaryValue: widget.descriptor.secondaryValue,
                        values: widget.descriptor.values,
                        id: widget.descriptor.id ?? widget.descriptor.columnId,
                      ));
                    }
                  },
                ),
              ),
              SizedBox(width: s.xxs),
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
            SizedBox(height: s.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(s.sm, s.sm, s.sm, s.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(tokens.radius.xs),
                  bottomRight: Radius.circular(tokens.radius.xs),
                ),
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Value',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: s.xxs),
                  if (mode == _FilterMode.text) ..._buildTextValueEditor(tokens, theme),
                  if (mode == _FilterMode.enum_) ..._buildEnumValueEditor(tokens, theme),
                  if (mode == _FilterMode.date) ..._buildDateValueEditor(tokens, theme),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildTextValueEditor(UiV1Tokens tokens, ThemeData theme) {
    final s = tokens.spacing;
    if (_isTextBulk) {
      final (parsed, unique) = bulkPasteCounts(_textController.text);
      return [
        TextField(
          controller: _textController,
          maxLines: 3,
          minLines: 2,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'One value per line, or comma/semicolon separated',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.xs)),
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
                id: widget.descriptor.id ?? widget.descriptor.columnId,
              ));
            }
          },
        ),
        SizedBox(height: s.xxs),
        Text(
          'Parsed: $parsed · Unique: $unique',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
            id: widget.descriptor.id ?? widget.descriptor.columnId,
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
      final singleValue = _enumSelection.isEmpty ? null : _enumSelection.first;
      final dropdownItems = options.isEmpty && singleValue != null
          ? <DropdownMenuItem<String>>[DropdownMenuItem(value: singleValue, child: Text(singleValue))]
          : options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList();
      if (singleValue != null && !options.contains(singleValue) && options.isNotEmpty) {
        dropdownItems.insert(0, DropdownMenuItem(value: singleValue, child: Text(singleValue)));
      }
      return [
        DropdownButtonFormField<String>(
          initialValue: singleValue,
          decoration: InputDecoration(
            isDense: true,
            labelText: 'Value',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
            contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
          ),
          items: dropdownItems,
          onChanged: (v) {
            if (v == null) return;
            _enumSelection = {v};
            _emit(UnifiedFilterDescriptor(
              columnId: widget.descriptor.columnId,
              operator: widget.descriptor.operator,
              value: v,
              id: widget.descriptor.id ?? widget.descriptor.columnId,
            ));
          },
        ),
      ];
    }

    void selectAll() {
      final next = Set<String>.from(options);
      setState(() => _enumSelection = next);
      _emit(UnifiedFilterDescriptor(
        columnId: widget.descriptor.columnId,
        operator: widget.descriptor.operator,
        values: next.toList(),
        id: widget.descriptor.id ?? widget.descriptor.columnId,
      ));
    }

    void clearSelection() {
      setState(() => _enumSelection = {});
      _emit(UnifiedFilterDescriptor(
        columnId: widget.descriptor.columnId,
        operator: widget.descriptor.operator,
        values: [],
        id: widget.descriptor.id ?? widget.descriptor.columnId,
      ));
    }

    return [
      Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(tokens.radius.xs),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: ExpansionTile(
          title: Text(
            _enumSelection.isEmpty ? 'Select values' : '${_enumSelection.length} selected',
            style: theme.textTheme.bodySmall,
          ),
          initiallyExpanded: _enumSelection.isNotEmpty,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radius.xs)),
          childrenPadding: EdgeInsets.only(left: s.xs, right: s.xs, bottom: s.sm),
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search…',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.xs)),
                contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
              ),
              onChanged: (v) => setState(() => _enumSearch = v),
            ),
            SizedBox(height: s.xs),
            Row(
              children: [
                TextButton(
                  onPressed: options.isEmpty ? null : selectAll,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: EdgeInsets.symmetric(horizontal: s.xs),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text('Select all', style: theme.textTheme.labelSmall),
                ),
                TextButton(
                  onPressed: _enumSelection.isEmpty ? null : clearSelection,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: EdgeInsets.symmetric(horizontal: s.xs),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text('Clear', style: theme.textTheme.labelSmall),
                ),
              ],
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
                    contentPadding: EdgeInsets.zero,
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
                        id: widget.descriptor.id ?? widget.descriptor.columnId,
                      ));
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
                      id: widget.descriptor.id ?? widget.descriptor.columnId,
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
                      id: widget.descriptor.id ?? widget.descriptor.columnId,
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
            id: widget.descriptor.id ?? widget.descriptor.columnId,
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
    required this.draftState,
    required this.onDraftChanged,
  });

  final UnifiedTableController<T> controller;
  final List<T> fullList;
  final UnifiedTableState draftState;
  final void Function(UnifiedTableState) onDraftChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final radius = tokens.radius;
    final config = controller.config;
    final filters = draftState.filters;
    final filterableColumns = config.columns.where((c) => c.filterable && c.valueGetter != null).toList();
    final filterableColumnIds = filterableColumns.map((c) => c.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Filter conditions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: s.sm),
        if (filters.isEmpty && filterableColumns.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: s.sm, horizontal: s.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(radius.sm),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_list, size: 24, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                SizedBox(height: s.xs),
                Text(
                  'No filter conditions',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: s.xxs),
                Text(
                  'Add a condition below.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else if (filters.isNotEmpty) ...[
          ...filters.map((f) {
            return Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: _InlineFilterRow<T>(
                key: ValueKey(f.identity),
                descriptor: f,
                config: config,
                fullList: fullList,
                filterableColumnIds: filterableColumnIds,
                onChanged: (d) {
                  if (d == null) {
                    onDraftChanged(draftState.removeFilter(filterId: f.identity));
                  } else {
                    onDraftChanged(draftState.addOrReplaceFilter(d));
                  }
                },
                onRemove: () {
                  onDraftChanged(draftState.removeFilter(filterId: f.identity));
                },
              ),
            );
          }),
        ],
        if (filterableColumns.isNotEmpty) ...[
          SizedBox(height: s.sm),
          Container(
            padding: EdgeInsets.symmetric(vertical: s.xs, horizontal: s.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(radius.xs),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                if (filters.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      onDraftChanged(draftState.clearFilters());
                    },
                    style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
                    child: Text(
                      'Clear all filters',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                if (filters.isNotEmpty) SizedBox(width: s.sm),
                OutlinedButton.icon(
                  onPressed: () {
                    final first = filterableColumns.first;
                    final mode = _effectiveFilterMode(first);
                    onDraftChanged(draftState.addOrReplaceFilter(UnifiedFilterDescriptor(
                      columnId: first.id,
                      operator: _defaultOperator(mode),
                      id: 'f_${DateTime.now().millisecondsSinceEpoch}',
                    )));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add condition'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ColumnsSection<T> extends StatefulWidget {
  const _ColumnsSection({
    required this.controller,
    required this.draftState,
    required this.onDraftChanged,
  });

  final UnifiedTableController<T> controller;
  final UnifiedTableState draftState;
  final void Function(UnifiedTableState) onDraftChanged;

  @override
  State<_ColumnsSection<T>> createState() => _ColumnsSectionState<T>();
}

class _ColumnsSectionState<T> extends State<_ColumnsSection<T>> {
  String? _selectedColumnId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final config = widget.controller.config;
    final order = widget.draftState.columnOrder ?? config.columns.map((c) => c.id).toList();
    final visibleIds = widget.draftState.visibleColumnIds?.toSet() ?? config.columns.map((c) => c.id).toSet();
    final visibleOrdered = order.where((id) => visibleIds.contains(id)).toList();
    final hiddenIds = order.where((id) => !visibleIds.contains(id)).toList();
    final defaultOrder = config.defaultVisibleColumnIds ?? config.columns.map((c) => c.id).toList();
    final radius = tokens.radius;
    final selectedInVisible = _selectedColumnId != null && visibleIds.contains(_selectedColumnId);
    final selectedInHidden = _selectedColumnId != null && hiddenIds.contains(_selectedColumnId);
    final selectedIndex = selectedInVisible ? visibleOrdered.indexOf(_selectedColumnId!) : -1;

    void moveUp() {
      if (!selectedInVisible || selectedIndex <= 0) return;
      final next = List<String>.from(visibleOrdered);
      next.insert(selectedIndex - 1, next.removeAt(selectedIndex));
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(
        columnOrder: next + hiddenIds,
        visibleColumnIds: next,
      ));
      setState(() {});
    }

    void moveDown() {
      if (!selectedInVisible || selectedIndex < 0 || selectedIndex >= visibleOrdered.length - 1) return;
      final next = List<String>.from(visibleOrdered);
      next.insert(selectedIndex + 1, next.removeAt(selectedIndex));
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(
        columnOrder: next + hiddenIds,
        visibleColumnIds: next,
      ));
      setState(() {});
    }

    void hideSelected() {
      if (!selectedInVisible || _selectedColumnId == null) return;
      final col = _columnById(config, _selectedColumnId!);
      if (col != null && !col.hideable) return;
      final next = visibleIds.where((id) => id != _selectedColumnId).toSet();
      if (next.isEmpty) return;
      final visibleOrderedNew = order.where((id) => next.contains(id)).toList();
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(
        visibleColumnIds: visibleOrderedNew,
        columnOrder: order,
      ));
      setState(() => _selectedColumnId = null);
    }

    void showSelected() {
      if (!selectedInHidden || _selectedColumnId == null) return;
      final next = Set<String>.from(visibleIds)..add(_selectedColumnId!);
      final visibleOrderedNew = order.where((id) => next.contains(id)).toList();
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(
        visibleColumnIds: visibleOrderedNew,
        columnOrder: order,
      ));
      setState(() => _selectedColumnId = null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Visible columns',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: s.sm),
        if (visibleOrdered.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: s.sm, horizontal: s.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(radius.sm),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.view_column_outlined, size: 24, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                SizedBox(height: s.xs),
                Text(
                  'No visible columns',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < visibleOrdered.length; i++)
                _buildVisibleColumnRow(visibleOrdered[i], config, theme, s, radius),
            ],
          ),
        SizedBox(height: s.sm),
        Container(
          padding: EdgeInsets.symmetric(vertical: s.xs, horizontal: s.xs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(radius.xs),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Wrap(
            spacing: s.xs,
            runSpacing: s.xs,
            children: [
              TextButton.icon(
                onPressed: selectedInVisible && selectedIndex > 0 ? moveUp : null,
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: const Text('Move up'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
              TextButton.icon(
                onPressed: selectedInVisible && selectedIndex >= 0 && selectedIndex < visibleOrdered.length - 1 ? moveDown : null,
                icon: const Icon(Icons.arrow_downward, size: 18),
                label: const Text('Move down'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
              TextButton.icon(
                onPressed: selectedInVisible ? hideSelected : null,
                icon: const Icon(Icons.visibility_off, size: 18),
                label: const Text('Hide'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
              TextButton.icon(
                onPressed: selectedInHidden ? showSelected : null,
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Show'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
              TextButton(
                onPressed: () {
                  widget.onDraftChanged(widget.draftState.copyWithAsCustom(
                    visibleColumnIds: List.from(defaultOrder),
                    columnOrder: List.from(defaultOrder),
                  ));
                  setState(() => _selectedColumnId = null);
                },
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
                child: const Text('Restore default'),
              ),
            ],
          ),
        ),
        SizedBox(height: s.sm),
        Text(
          'Hidden columns',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: s.xs),
        if (hiddenIds.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: s.sm, horizontal: s.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(radius.sm),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_off, size: 24, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                SizedBox(height: s.xs),
                Text(
                  'No hidden columns',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final columnId in hiddenIds)
                _buildHiddenColumnRow(columnId, config, order, visibleIds, theme, s, radius),
            ],
          ),
      ],
    );
  }

  Widget _buildHiddenColumnRow(String columnId, UnifiedTableConfig<T> config, List<String> order, Set<String> visibleIds, ThemeData theme, UiV1SpacingTokens s, UiV1RadiusTokens radius) {
    final column = _columnById(config, columnId);
    if (column == null) return const SizedBox.shrink();
    final selected = _selectedColumnId == columnId;
    return InkWell(
      onTap: () => setState(() => _selectedColumnId = columnId),
      borderRadius: BorderRadius.circular(radius.xs),
      child: Container(
        margin: EdgeInsets.only(bottom: s.xs),
        padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
              : theme.colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(radius.xs),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.visibility_off,
              size: 20,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: s.sm),
            Expanded(
              child: Text(
                column.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w500 : null,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final next = Set<String>.from(visibleIds)..add(columnId);
                final visibleOrderedNew = order.where((id) => next.contains(id)).toList();
                widget.onDraftChanged(widget.draftState.copyWithAsCustom(
                  visibleColumnIds: visibleOrderedNew,
                  columnOrder: order,
                ));
                if (_selectedColumnId == columnId) _selectedColumnId = null;
                setState(() {});
              },
              style: TextButton.styleFrom(minimumSize: const Size(0, 28), padding: EdgeInsets.symmetric(horizontal: s.xs)),
              child: const Text('Show'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibleColumnRow(String columnId, UnifiedTableConfig<T> config, ThemeData theme, UiV1SpacingTokens s, UiV1RadiusTokens radius) {
    final column = _columnById(config, columnId);
    if (column == null) return const SizedBox.shrink();
    final selected = _selectedColumnId == columnId;
    return InkWell(
      onTap: () => setState(() => _selectedColumnId = columnId),
      borderRadius: BorderRadius.circular(radius.xs),
      child: Container(
        margin: EdgeInsets.only(bottom: s.xs),
        padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(radius.xs),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.view_column_outlined,
              size: 20,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: s.sm),
            Expanded(
              child: Text(
                column.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w500 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortSection<T> extends StatefulWidget {
  const _SortSection({
    required this.controller,
    required this.draftState,
    required this.onDraftChanged,
  });

  final UnifiedTableController<T> controller;
  final UnifiedTableState draftState;
  final void Function(UnifiedTableState) onDraftChanged;

  @override
  State<_SortSection<T>> createState() => _SortSectionState<T>();
}

class _SortSectionState<T> extends State<_SortSection<T>> {
  int? _selectedSortIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final config = widget.controller.config;
    final sorts = widget.draftState.sorts;
    final sortableColumns = config.columns.where((c) => c.sortable && c.valueGetter != null).toList();
    final radius = tokens.radius;
    final availableForSort = sortableColumns.where((c) => !sorts.any((x) => x.columnId == c.id)).toList();
    final hasSelection = _selectedSortIndex != null && _selectedSortIndex! >= 0 && _selectedSortIndex! < sorts.length;

    void addRule(String columnId) {
      if (sorts.any((x) => x.columnId == columnId)) return;
      final next = List<UnifiedSortDescriptor>.from(sorts)..add(UnifiedSortDescriptor(columnId: columnId, ascending: true));
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(sorts: next));
      setState(() {});
    }

    void removeSelected() {
      if (!hasSelection) return;
      final next = sorts.where((x) => x.columnId != sorts[_selectedSortIndex!].columnId).toList();
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(sorts: next));
      setState(() => _selectedSortIndex = null);
    }

    void moveUp() {
      if (!hasSelection || _selectedSortIndex! <= 0) return;
      final next = List<UnifiedSortDescriptor>.from(sorts);
      next.insert(_selectedSortIndex! - 1, next.removeAt(_selectedSortIndex!));
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(sorts: next));
      setState(() => _selectedSortIndex = _selectedSortIndex! - 1);
    }

    void moveDown() {
      if (!hasSelection || _selectedSortIndex! >= sorts.length - 1) return;
      final next = List<UnifiedSortDescriptor>.from(sorts);
      next.insert(_selectedSortIndex! + 1, next.removeAt(_selectedSortIndex!));
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(sorts: next));
      setState(() => _selectedSortIndex = _selectedSortIndex! + 1);
    }

    void toggleDirection() {
      if (!hasSelection) return;
      final next = List<UnifiedSortDescriptor>.from(sorts);
      final sort = next[_selectedSortIndex!];
      next[_selectedSortIndex!] = UnifiedSortDescriptor(columnId: sort.columnId, ascending: !sort.ascending);
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(sorts: next));
      setState(() {});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sort rules',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: s.sm),
        if (sorts.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: s.sm, horizontal: s.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(radius.sm),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 24, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                SizedBox(height: s.xs),
                Text(
                  'No sort rules',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: s.xxs),
                Text(
                  'Add a rule below.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < sorts.length; i++)
                _buildSortRuleRow(i, sorts[i], config, theme, s, radius),
            ],
          ),
        SizedBox(height: s.sm),
        Container(
          padding: EdgeInsets.symmetric(vertical: s.xs, horizontal: s.xs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(radius.xs),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Wrap(
            spacing: s.xs,
            runSpacing: s.xs,
            children: [
              if (sortableColumns.isNotEmpty && availableForSort.isNotEmpty)
                PopupMenuButton<String>(
                  offset: const Offset(0, 40),
                  itemBuilder: (ctx) => availableForSort.map((c) => PopupMenuItem(value: c.id, child: Text(c.label))).toList(),
                  onSelected: addRule,
                  child: FilledButton.tonal(
                    onPressed: () {},
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 32)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 6),
                        Text('Add rule'),
                      ],
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: hasSelection ? removeSelected : null,
                icon: const Icon(UiIcons.close, size: 18),
                label: const Text('Remove'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
              TextButton.icon(
                onPressed: hasSelection && _selectedSortIndex! > 0 ? moveUp : null,
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: const Text('Up'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
              TextButton.icon(
                onPressed: hasSelection && _selectedSortIndex! < sorts.length - 1 ? moveDown : null,
                icon: const Icon(Icons.arrow_downward, size: 18),
                label: const Text('Down'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
              TextButton.icon(
                onPressed: hasSelection ? toggleDirection : null,
                icon: Icon(sorts.isNotEmpty && hasSelection && sorts[_selectedSortIndex!].ascending ? Icons.arrow_downward : Icons.arrow_upward, size: 18),
                label: const Text('Toggle'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
            ],
          ),
        ),
        if (sorts.isNotEmpty && availableForSort.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: s.xs),
            child: Text(
              'All columns are in sort order',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _buildSortRuleRow(int i, UnifiedSortDescriptor sort, UnifiedTableConfig<T> config, ThemeData theme, UiV1SpacingTokens s, UiV1RadiusTokens radius) {
    final columnLabel = _columnLabel(config, sort.columnId);
    final selected = _selectedSortIndex == i;
    return InkWell(
      onTap: () => setState(() => _selectedSortIndex = i),
      borderRadius: BorderRadius.circular(radius.xs),
      child: Container(
        margin: EdgeInsets.only(bottom: s.xs),
        padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(radius.xs),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(radius.xs),
              ),
              child: Text('${i + 1}', style: theme.textTheme.labelSmall),
            ),
            SizedBox(width: s.sm),
            Expanded(
              child: Text(
                columnLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  overflow: TextOverflow.ellipsis,
                  fontWeight: selected ? FontWeight.w500 : null,
                ),
              ),
            ),
            SizedBox(width: s.sm),
            Text(
              sort.ascending ? 'Asc' : 'Desc',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsSection<T> extends StatefulWidget {
  const _StatisticsSection({
    required this.controller,
    required this.draftState,
    required this.onDraftChanged,
  });

  final UnifiedTableController<T> controller;
  final UnifiedTableState draftState;
  final void Function(UnifiedTableState) onDraftChanged;

  @override
  State<_StatisticsSection<T>> createState() => _StatisticsSectionState<T>();
}

class _StatisticsSectionState<T> extends State<_StatisticsSection<T>> {
  String? _selectedMetricId;
  String? _selectedAvailableMetricId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final config = widget.controller.config;
    final statsVisible = widget.draftState.statsVisible;
    final selectedIds = widget.draftState.selectedMetricIds;
    final metrics = config.availableMetrics;
    final effectiveSelected = selectedIds.isEmpty ? metrics.map((x) => x.id).toList() : selectedIds;
    final selectedOrdered = effectiveSelected.where((id) => metrics.any((m) => m.id == id)).toList();
    final availableIds = metrics.map((m) => m.id).where((id) => !selectedOrdered.contains(id)).toList();
    final radius = tokens.radius;
    final selectedIndex = _selectedMetricId != null ? selectedOrdered.indexOf(_selectedMetricId!) : -1;
    final hasSelection = selectedIndex >= 0;

    void moveUp() {
      if (!hasSelection || selectedIndex <= 0) return;
      final next = List<String>.from(selectedOrdered);
      next.insert(selectedIndex - 1, next.removeAt(selectedIndex));
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(selectedMetricIds: next));
      setState(() {});
    }

    void moveDown() {
      if (!hasSelection || selectedIndex >= selectedOrdered.length - 1) return;
      final next = List<String>.from(selectedOrdered);
      next.insert(selectedIndex + 1, next.removeAt(selectedIndex));
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(selectedMetricIds: next));
      setState(() {});
    }

    void removeSelected() {
      if (!hasSelection || _selectedMetricId == null) return;
      var next = List<String>.from(selectedOrdered)..remove(_selectedMetricId);
      if (next.isEmpty && metrics.isNotEmpty) next = [metrics.first.id];
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(selectedMetricIds: next));
      setState(() => _selectedMetricId = null);
    }

    void addSelectedAvailable() {
      if (_selectedAvailableMetricId == null || selectedOrdered.contains(_selectedAvailableMetricId)) return;
      final next = List<String>.from(selectedOrdered)..add(_selectedAvailableMetricId!);
      widget.onDraftChanged(widget.draftState.copyWithAsCustom(selectedMetricIds: next));
      setState(() => _selectedAvailableMetricId = null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Statistics',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: s.sm),
        Container(
          padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(radius.sm),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Text('Show statistics', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              const Spacer(),
              Switch(
                value: statsVisible,
                onChanged: (v) {
                  widget.onDraftChanged(widget.draftState.copyWithAsCustom(statsVisible: v));
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        SizedBox(height: s.sm),
        Text(
          'Selected metrics',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: s.xs),
        if (selectedOrdered.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: s.sm, horizontal: s.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(radius.sm),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_outlined, size: 24, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                SizedBox(height: s.xs),
                Text(
                  'No metrics selected',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < selectedOrdered.length; i++)
                _buildSelectedMetricRow(selectedOrdered[i], metrics, theme, s, radius),
            ],
          ),
        SizedBox(height: s.sm),
        Container(
          padding: EdgeInsets.symmetric(vertical: s.xs, horizontal: s.xs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(radius.xs),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Wrap(
            spacing: s.xs,
            runSpacing: s.xs,
            children: [
              TextButton.icon(
                onPressed: hasSelection && selectedIndex > 0 ? moveUp : null,
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: const Text('Move up'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
              TextButton.icon(
                onPressed: hasSelection && selectedIndex >= 0 && selectedIndex < selectedOrdered.length - 1 ? moveDown : null,
                icon: const Icon(Icons.arrow_downward, size: 18),
                label: const Text('Move down'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
              TextButton.icon(
                onPressed: hasSelection ? removeSelected : null,
                icon: const Icon(UiIcons.close, size: 18),
                label: const Text('Remove'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
            ],
          ),
        ),
        if (availableIds.isNotEmpty) ...[
          SizedBox(height: s.sm),
          Text(
            'Available metrics',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: s.xs),
          Container(
            padding: EdgeInsets.all(s.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(radius.sm),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: availableIds.map((metricId) {
                UnifiedStatsMetricDefinition<T>? m;
                for (final x in metrics) {
                  if (x.id == metricId) { m = x; break; }
                }
                return m != null ? _buildAvailableMetricRow(m, theme, s, radius) : const SizedBox.shrink();
              }).toList(),
            ),
          ),
          SizedBox(height: s.xs),
          Container(
            padding: EdgeInsets.symmetric(vertical: s.xs, horizontal: s.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(radius.xs),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _selectedAvailableMetricId != null ? addSelectedAvailable : null,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add to selected'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedMetricRow(String metricId, List<UnifiedStatsMetricDefinition<T>> metrics, ThemeData theme, UiV1SpacingTokens s, UiV1RadiusTokens radius) {
    UnifiedStatsMetricDefinition<T>? m;
    for (final x in metrics) {
      if (x.id == metricId) { m = x; break; }
    }
    if (m == null) return const SizedBox.shrink();
    final metric = m;
    final selected = _selectedMetricId == metric.id;
    return InkWell(
      onTap: () => setState(() => _selectedMetricId = metric.id),
      borderRadius: BorderRadius.circular(radius.xs),
      child: Container(
        margin: EdgeInsets.only(bottom: s.xs),
        padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(radius.xs),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 20,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: s.sm),
            Expanded(
              child: Text(
                metric.label,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: selected ? FontWeight.w500 : null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableMetricRow(UnifiedStatsMetricDefinition<T> metric, ThemeData theme, UiV1SpacingTokens s, UiV1RadiusTokens radius) {
    final selected = _selectedAvailableMetricId == metric.id;
    return InkWell(
      onTap: () => setState(() => _selectedAvailableMetricId = metric.id),
      borderRadius: BorderRadius.circular(radius.xs),
      child: Container(
        margin: EdgeInsets.only(bottom: s.xs),
        padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
              : theme.colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(radius.xs),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 20,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: s.sm),
            Expanded(
              child: Text(
                metric.label,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: selected ? FontWeight.w500 : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
