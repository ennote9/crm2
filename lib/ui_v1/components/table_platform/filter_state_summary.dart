// Filter state summary for Table Platform v1. Shows active search, filters (from model or chips), view.

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'unified_filter_descriptor.dart';

/// One chip for the summary (e.g. "Status: Draft" with remove).
class UnifiedFilterChipItem {
  const UnifiedFilterChipItem({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;
}

/// Compact summary of active table state: search, filter chips (or built from descriptors), view name.
class UnifiedFilterStateSummary extends StatelessWidget {
  const UnifiedFilterStateSummary({
    super.key,
    this.searchQuery = '',
    this.filterChips = const [],
    this.filterDescriptors,
    this.getColumnLabel,
    this.onRemoveFilter,
    this.viewName,
    this.onClearSearch,
    this.style,
  }) : assert(
         (filterDescriptors == null) ||
             (getColumnLabel != null && onRemoveFilter != null),
         'When filterDescriptors is set, getColumnLabel and onRemoveFilter must be set',
       );

  final String searchQuery;
  /// Pre-built chips (used when filterDescriptors is null).
  final List<UnifiedFilterChipItem> filterChips;
  /// When set, chips are built as "columnLabel: valueDisplayString" per descriptor.
  final List<UnifiedFilterDescriptor>? filterDescriptors;
  final String Function(String columnId)? getColumnLabel;
  final void Function(String columnId)? onRemoveFilter;
  final String? viewName;
  final VoidCallback? onClearSearch;
  final TextStyle? style;

  List<UnifiedFilterChipItem> get _effectiveChips {
    if (filterDescriptors != null && getColumnLabel != null && onRemoveFilter != null) {
      return filterDescriptors!.map((d) {
        final columnLabel = getColumnLabel!(d.columnId);
        final valueStr = d.toHumanReadableValueString();
        final label = valueStr.isEmpty ? columnLabel : '$columnLabel: $valueStr';
        return UnifiedFilterChipItem(
          label: label,
          onRemove: () => onRemoveFilter!(d.columnId),
        );
      }).toList();
    }
    return filterChips;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final textStyle = style ?? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final chips = _effectiveChips;

    final parts = <Widget>[];
    if (searchQuery.isNotEmpty) {
      parts.add(Text('Search: ', style: textStyle));
      parts.add(Text(searchQuery, style: textStyle?.copyWith(fontWeight: FontWeight.w500)));
      if (onClearSearch != null) {
        parts.add(GestureDetector(
          onTap: onClearSearch,
          child: Padding(
            padding: EdgeInsets.only(left: s.xxs),
            child: Icon(Icons.close, size: 14, color: theme.colorScheme.onSurfaceVariant),
          ),
        ));
      }
    }
    if (chips.isNotEmpty) {
      if (parts.isNotEmpty) parts.add(SizedBox(width: s.sm));
      parts.add(Text('Filters: ', style: textStyle));
      parts.add(Wrap(
        spacing: s.xxs,
        runSpacing: s.xxs,
        children: chips.map((c) => InputChip(
          label: Text(c.label, style: textStyle),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: c.onRemove,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        )).toList(),
      ));
    }
    if (viewName != null && viewName!.isNotEmpty) {
      if (parts.isNotEmpty) parts.add(SizedBox(width: s.sm));
      parts.add(Text('View: $viewName', style: textStyle));
    }

    if (parts.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: s.xs,
      runSpacing: s.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: parts,
    );
  }
}
