// Orders filters panel (MVP): Status multi, Warehouse single. Apply / Clear.

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// Result of applying filters in the panel.
class UiV1OrdersFiltersResult {
  const UiV1OrdersFiltersResult({
    required this.statuses,
    this.warehouse,
  });
  final Set<String> statuses;
  final String? warehouse;
}

/// Status options for Orders (matches mock data).
const List<String> kOrdersStatusOptions = [
  'Draft', 'Released', 'Allocating', 'Picking', 'Packing', 'Packed',
  'Shipped', 'Closed', 'On Hold', 'Shortage', 'Cancelled', 'Allocated',
];

/// Warehouse options.
const List<String> kOrdersWarehouseOptions = ['WH-A', 'WH-B', 'WH-C'];

/// Shows a dialog with Status (multi) and Warehouse (single).
/// On Apply returns result; on Clear returns empty result; Esc returns null.
Future<void> showUiV1OrdersFiltersPanel({
  required BuildContext context,
  required Set<String> initialStatuses,
  required String? initialWarehouse,
  required void Function(UiV1OrdersFiltersResult) onApply,
}) async {
  final theme = Theme.of(context);
  final tokens = Theme.of(context).brightness == Brightness.dark
      ? UiV1Tokens.dark
      : UiV1Tokens.light;
  final s = tokens.spacing;

  Set<String> statuses = Set.from(initialStatuses);
  String? warehouse = initialWarehouse;

  final result = await showDialog<UiV1OrdersFiltersResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Filters'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: s.xxs),
                  Wrap(
                    spacing: s.xs,
                    runSpacing: s.xxs,
                    children: kOrdersStatusOptions.map((status) {
                      final selected = statuses.contains(status);
                      return FilterChip(
                        label: Text(status),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              statuses.add(status);
                            } else {
                              statuses.remove(status);
                            }
                          });
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: s.md),
                  Text(
                    'Warehouse',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: s.xxs),
                  DropdownButtonFormField<String>(
                    value: warehouse,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: 6),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...kOrdersWarehouseOptions.map(
                        (w) => DropdownMenuItem(value: w, child: Text(w)),
                      ),
                    ],
                    onChanged: (v) => setState(() => warehouse = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                const UiV1OrdersFiltersResult(statuses: {}, warehouse: null),
              ),
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                UiV1OrdersFiltersResult(statuses: statuses, warehouse: warehouse),
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    ),
  );
  if (result != null) {
    onApply(result);
  }
}
