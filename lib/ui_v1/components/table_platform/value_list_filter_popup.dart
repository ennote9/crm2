// Value-list filter popup for Table Platform v1. Multi-select with search, Apply.

import 'package:flutter/material.dart';

import '../../icons/ui_icons.dart';
import '../../theme/tokens.dart';
import 'unified_table_column.dart';

/// Shows a popup to select multiple values for a column (e.g. Status, Warehouse).
/// On Apply: if [selected] is not empty creates UnifiedFilterDescriptor inList; if empty, [onApply] receives empty and caller should remove filter.
void showValueListFilterPopup<T>({
  required BuildContext context,
  required UnifiedTableColumn<T> column,
  required List<T> fullList,
  required List<dynamic> currentSelected,
  required void Function(List<dynamic> selected) onApply,
}) {
  if (column.valueGetter == null) return;
  final values = <String>{};
  for (final row in fullList) {
    final v = column.valueGetter!(row);
    if (v != null) values.add(v.toString());
  }
  final sortedValues = values.toList()..sort();
  if (sortedValues.isEmpty) return;

  var selected = Set<String>.from(currentSelected.map((e) => e.toString()));
  var searchQuery = '';

  showDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final tokens = Theme.of(ctx).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
      final s = tokens.spacing;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filtered = searchQuery.trim().isEmpty
              ? sortedValues
              : sortedValues
                  .where((v) => v.toLowerCase().contains(searchQuery.trim().toLowerCase()))
                  .toList();
          final allFilteredSelected = filtered.isNotEmpty && filtered.every((v) => selected.contains(v));

          return AlertDialog(
            title: Text('Filter: ${column.label}'),
            content: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search values…',
                      isDense: true,
                      prefixIcon: const Icon(UiIcons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radius.sm)),
                    ),
                    onChanged: (v) => setDialogState(() => searchQuery = v),
                  ),
                  SizedBox(height: s.sm),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setDialogState(() {
                          if (allFilteredSelected) {
                            selected = selected.difference(filtered.toSet());
                          } else {
                            selected = selected.union(filtered.toSet());
                          }
                        }),
                        child: Text(allFilteredSelected ? 'Deselect all' : 'Select all'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setDialogState(() => selected = {}),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  SizedBox(height: s.xs),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final value = filtered[i];
                          final isSelected = selected.contains(value);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) {
                              setDialogState(() {
                                if (isSelected) {
                                  selected = Set.from(selected)..remove(value);
                                } else {
                                  selected = Set.from(selected)..add(value);
                                }
                              });
                            },
                            title: Text(value, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onApply(selected.toList());
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}
