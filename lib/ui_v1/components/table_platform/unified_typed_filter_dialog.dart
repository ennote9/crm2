// Typed column filter dialog v1.1. One dialog, UI by column type (text / enum / date). Text supports bulk paste for One of / Not one of.

import 'package:flutter/material.dart';

import '../../icons/ui_icons.dart';
import '../../theme/tokens.dart';
import 'unified_filter_descriptor.dart';
import 'unified_table_column.dart';

/// Parses bulk-pasted text into a list of non-empty, trimmed, deduplicated values.
/// Supports separators: newline, comma, semicolon, tab. Order of first occurrence is preserved.
List<String> parseBulkPasteValues(String raw) {
  if (raw.trim().isEmpty) return [];
  final parts = raw
      .split(RegExp(r'[\n,;\t]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final seen = <String>{};
  final result = <String>[];
  for (final p in parts) {
    if (seen.add(p)) result.add(p);
  }
  return result;
}

/// Returns (parsedCount, uniqueCount) for bulk paste summary (parsed = non-empty parts, unique = after dedupe).
(int, int) bulkPasteCounts(String raw) {
  if (raw.trim().isEmpty) return (0, 0);
  final parts = raw
      .split(RegExp(r'[\n,;\t]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final unique = parts.toSet().length;
  return (parts.length, unique);
}

/// Filter type for dialog mode.
enum _FilterMode { text, enum_, date }

/// Opens the typed filter dialog. [currentFilter] for this column if any. [onApply] with descriptor or null to clear.
void showUnifiedTypedFilterDialog<T>({
  required BuildContext context,
  required UnifiedTableColumn<T> column,
  required List<T> fullList,
  required UnifiedFilterDescriptor? currentFilter,
  required void Function(UnifiedFilterDescriptor? descriptor) onApply,
}) {
  final filterType = _effectiveFilterType(column);
  showDialog<void>(
    context: context,
    builder: (ctx) => _TypedFilterDialog<T>(
      column: column,
      fullList: fullList,
      currentFilter: currentFilter,
      mode: filterType,
      onApply: onApply,
    ),
  );
}

_FilterMode _effectiveFilterType<T>(UnifiedTableColumn<T> column) {
  if (column.filterType == UnifiedColumnFilterType.enum_) return _FilterMode.enum_;
  if (column.filterType == UnifiedColumnFilterType.date) return _FilterMode.date;
  return _FilterMode.text;
}

class _TypedFilterDialog<T> extends StatefulWidget {
  const _TypedFilterDialog({
    required this.column,
    required this.fullList,
    required this.currentFilter,
    required this.mode,
    required this.onApply,
  });

  final UnifiedTableColumn<T> column;
  final List<T> fullList;
  final UnifiedFilterDescriptor? currentFilter;
  final _FilterMode mode;
  final void Function(UnifiedFilterDescriptor?) onApply;

  @override
  State<_TypedFilterDialog<T>> createState() => _TypedFilterDialogState<T>();
}

class _TypedFilterDialogState<T> extends State<_TypedFilterDialog<T>> {
  late UnifiedFilterOperator _op;
  late TextEditingController _textController;
  late TextEditingController _dateController;
  late TextEditingController _dateEndController;
  Set<String> _selectedValues = {};
  String _enumSearch = '';

  @override
  void initState() {
    super.initState();
    final f = widget.currentFilter;
    if (f != null) {
      _op = f.operator;
      final isTextBulk = widget.mode == _FilterMode.text &&
          (f.operator == UnifiedFilterOperator.inList || f.operator == UnifiedFilterOperator.notInList);
      if (isTextBulk && f.values != null && f.values!.isNotEmpty) {
        _textController = TextEditingController(text: f.values!.map((e) => e.toString()).join('\n'));
      } else {
        _textController = TextEditingController(text: f.value?.toString() ?? '');
      }
      _dateController = TextEditingController(text: f.value?.toString() ?? '');
      _dateEndController = TextEditingController(text: f.secondaryValue?.toString() ?? '');
      if (f.values != null && widget.mode == _FilterMode.enum_) {
        _selectedValues = f.values!.map((e) => e.toString()).toSet();
      } else {
        _selectedValues = {};
      }
    } else {
      _op = _defaultOperator(widget.mode);
      _textController = TextEditingController();
      _dateController = TextEditingController();
      _dateEndController = TextEditingController();
      _selectedValues = {};
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _dateController.dispose();
    _dateEndController.dispose();
    super.dispose();
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

  List<UnifiedFilterOperator> _operatorsForMode() {
    switch (widget.mode) {
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

  bool get _needsValue =>
      _op != UnifiedFilterOperator.isEmpty && _op != UnifiedFilterOperator.isNotEmpty;

  bool get _needsSecondaryValue => _op == UnifiedFilterOperator.between;

  /// Text mode with One of / Not one of: bulk paste textarea instead of single-line.
  bool get _isTextBulkPaste =>
      widget.mode == _FilterMode.text &&
      (_op == UnifiedFilterOperator.inList || _op == UnifiedFilterOperator.notInList);

  void _apply() {
    if (_op == UnifiedFilterOperator.isEmpty || _op == UnifiedFilterOperator.isNotEmpty) {
      widget.onApply(UnifiedFilterDescriptor(
        columnId: widget.column.id,
        operator: _op,
      ));
      return;
    }
    if (widget.mode == _FilterMode.enum_) {
      if (_op == UnifiedFilterOperator.equals || _op == UnifiedFilterOperator.notEquals) {
        if (_selectedValues.isEmpty) return;
        widget.onApply(UnifiedFilterDescriptor(
          columnId: widget.column.id,
          operator: _op,
          value: _selectedValues.single,
        ));
      } else {
        if (_selectedValues.isEmpty) {
          widget.onApply(null);
          return;
        }
        widget.onApply(UnifiedFilterDescriptor(
          columnId: widget.column.id,
          operator: _op,
          values: _selectedValues.toList(),
        ));
      }
      return;
    }
    if (widget.mode == _FilterMode.text) {
      if (_op == UnifiedFilterOperator.inList || _op == UnifiedFilterOperator.notInList) {
        final parsed = parseBulkPasteValues(_textController.text);
        if (parsed.isEmpty) return;
        widget.onApply(UnifiedFilterDescriptor(
          columnId: widget.column.id,
          operator: _op,
          values: parsed,
        ));
      } else {
        final v = _textController.text.trim();
        if (v.isEmpty && _needsValue) return;
        widget.onApply(UnifiedFilterDescriptor(
          columnId: widget.column.id,
          operator: _op,
          value: v.isEmpty ? null : v,
        ));
      }
      return;
    }
    if (widget.mode == _FilterMode.date) {
      final v = _dateController.text.trim();
      if ((v.isEmpty) && _needsValue) return;
      if (_op == UnifiedFilterOperator.between) {
        final vEnd = _dateEndController.text.trim();
        if (v.isEmpty || vEnd.isEmpty) return;
        widget.onApply(UnifiedFilterDescriptor(
          columnId: widget.column.id,
          operator: UnifiedFilterOperator.between,
          value: v,
          secondaryValue: vEnd,
        ));
      } else {
        widget.onApply(UnifiedFilterDescriptor(
          columnId: widget.column.id,
          operator: _op,
          value: v.isEmpty ? null : v,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;

    return AlertDialog(
      title: Text('Filter: ${widget.column.label}'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<UnifiedFilterOperator>(
              key: ValueKey(_op),
              initialValue: _op,
              decoration: InputDecoration(
                labelText: 'Operator',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
                contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
              ),
              items: _operatorsForMode().map((op) {
                return DropdownMenuItem(
                  value: op,
                  child: Text(_operatorLabel(op)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _op = v!),
            ),
            if (widget.mode == _FilterMode.text && _needsValue) ...[
              SizedBox(height: s.sm),
              if (_isTextBulkPaste) ...[
                TextField(
                  autofocus: true,
                  maxLines: 5,
                  minLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Values',
                    hintText: 'Paste one or multiple values',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
                    contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
                  ),
                  controller: _textController,
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: s.xs),
                Text(
                  'Paste one or multiple values. Supported separators: new line, comma, semicolon, tab.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: s.xxs),
                _BulkPasteSummary(raw: _textController.text),
              ] else ...[
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Value',
                    hintText: 'Enter text',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
                    contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
                  ),
                  controller: _textController,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
            if (widget.mode == _FilterMode.enum_) ...[
              SizedBox(height: s.sm),
              _EnumValueSelector<T>(
                column: widget.column,
                fullList: widget.fullList,
                operator: _op,
                selectedValues: _selectedValues,
                searchQuery: _enumSearch,
                onSearchChanged: (v) => setState(() => _enumSearch = v),
                onSelectionChanged: (v) => setState(() => _selectedValues = v),
              ),
            ],
            if (widget.mode == _FilterMode.date && _needsValue) ...[
              SizedBox(height: s.sm),
              TextField(
                decoration: InputDecoration(
                  labelText: _op == UnifiedFilterOperator.between ? 'From date' : 'Date',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
                  contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
                ),
                controller: _dateController,
                onChanged: (_) => setState(() {}),
              ),
              if (_needsSecondaryValue) ...[
                SizedBox(height: s.xs),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'To date',
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
                    contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
                  ),
                  controller: _dateEndController,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onApply(null);
            Navigator.of(context).pop();
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            _apply();
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  String _operatorLabel(UnifiedFilterOperator op) {
    switch (op) {
      case UnifiedFilterOperator.equals:
        return widget.mode == _FilterMode.date ? 'On date' : 'Equals';
      case UnifiedFilterOperator.notEquals:
        return 'Not equals';
      case UnifiedFilterOperator.contains:
        return 'Contains';
      case UnifiedFilterOperator.notContains:
        return 'Does not contain';
      case UnifiedFilterOperator.startsWith:
        return 'Starts with';
      case UnifiedFilterOperator.endsWith:
        return 'Ends with';
      case UnifiedFilterOperator.inList:
        return 'One of';
      case UnifiedFilterOperator.notInList:
        return 'Not one of';
      case UnifiedFilterOperator.greaterThan:
        return widget.mode == _FilterMode.date ? 'After' : 'Greater than';
      case UnifiedFilterOperator.lessThan:
        return widget.mode == _FilterMode.date ? 'Before' : 'Less than';
      case UnifiedFilterOperator.between:
        return 'Between';
      case UnifiedFilterOperator.isEmpty:
        return 'Is empty';
      case UnifiedFilterOperator.isNotEmpty:
        return 'Is not empty';
      default:
        return UnifiedFilterDescriptor.operatorLabel(op);
    }
  }
}

class _BulkPasteSummary extends StatelessWidget {
  const _BulkPasteSummary({required this.raw});

  final String raw;

  @override
  Widget build(BuildContext context) {
    final (parsedCount, uniqueCount) = bulkPasteCounts(raw);
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Text('Parsed: $parsedCount, Unique: $uniqueCount', style: style);
  }
}

class _EnumValueSelector<T> extends StatelessWidget {
  const _EnumValueSelector({
    required this.column,
    required this.fullList,
    required this.operator,
    required this.selectedValues,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSelectionChanged,
  });

  final UnifiedTableColumn<T> column;
  final List<T> fullList;
  final UnifiedFilterOperator operator;
  final Set<String> selectedValues;
  final String searchQuery;
  final void Function(String) onSearchChanged;
  final void Function(Set<String>) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (column.valueGetter == null) return const SizedBox.shrink();
    final values = <String>{};
    for (final row in fullList) {
      final v = column.valueGetter!(row);
      if (v != null) values.add(v.toString());
    }
    final sorted = values.toList()..sort();
    final filtered = searchQuery.trim().isEmpty
        ? sorted
        : sorted.where((v) => v.toLowerCase().contains(searchQuery.trim().toLowerCase())).toList();

    final singleSelect = operator == UnifiedFilterOperator.equals || operator == UnifiedFilterOperator.notEquals;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search values…',
            isDense: true,
            prefixIcon: const Icon(UiIcons.search, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: () => onSelectionChanged(filtered.toSet()),
              child: const Text('Select all'),
            ),
            TextButton(
              onPressed: () => onSelectionChanged({}),
              child: const Text('Clear'),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: singleSelect
              ? RadioGroup<String>(
                  groupValue: selectedValues.isEmpty ? null : selectedValues.single,
                  onChanged: (v) => onSelectionChanged(v != null ? {v} : {}),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final value = filtered[i];
                      return ListTile(
                        dense: true,
                        title: Text(value, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                        leading: Radio<String>(value: value),
                        onTap: () => onSelectionChanged(selectedValues.contains(value) ? {} : {value}),
                      );
                    },
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final value = filtered[i];
                    final selected = selectedValues.contains(value);
                    return ListTile(
                      dense: true,
                      title: Text(value, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                      leading: Checkbox(
                        value: selected,
                        onChanged: (v) {
                          final next = Set<String>.from(selectedValues);
                          if (v == true) {
                            next.add(value);
                          } else {
                            next.remove(value);
                          }
                          onSelectionChanged(next);
                        },
                      ),
                      onTap: () {
                        final next = Set<String>.from(selectedValues);
                        if (selected) {
                          next.remove(value);
                        } else {
                          next.add(value);
                        }
                        onSelectionChanged(next);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
