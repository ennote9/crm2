// Unified table toolbar for Table Platform v1. Search, Filters, extra actions, Show stats.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../icons/ui_icons.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import 'filter_state_summary.dart';

/// Toolbar: search field, Filters button, extra actions, optional Show stats toggle.
class UnifiedTableToolbar extends StatelessWidget {
  const UnifiedTableToolbar({
    super.key,
    required this.searchController,
    this.searchFocusNode,
    required this.onSearchSubmit,
    required this.onSearchClear,
    this.searchHint = 'Search…',
    required this.filterChips,
    this.onFiltersTap,
    this.extraActions,
    this.statsVisible = false,
    this.onStatsVisibleChanged,
  });

  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final VoidCallback onSearchSubmit;
  final VoidCallback onSearchClear;
  final String searchHint;
  final List<UnifiedFilterChipItem> filterChips;
  final VoidCallback? onFiltersTap;
  final Widget? extraActions;
  final bool statsVisible;
  final ValueChanged<bool>? onStatsVisibleChanged;

  static const double _inputHeight = 32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final density = UiV1DensityTokens.dense;
    final r = tokens.radius;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _ClearSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true): _FocusSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, meta: true): _FocusSearchIntent(),
      },
      child: Actions(
        actions: {
          _ClearSearchIntent: CallbackAction<_ClearSearchIntent>(
            onInvoke: (_) {
              onSearchClear();
              return null;
            },
          ),
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) {
              if (searchFocusNode != null) {
                FocusScope.of(context).requestFocus(searchFocusNode);
              }
              return null;
            },
          ),
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(s.xl, s.xs, s.xl, s.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: _inputHeight,
                    child: Material(
                      type: MaterialType.transparency,
                      child: TextField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        onSubmitted: (_) => onSearchSubmit(),
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: 6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(r.sm)),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          suffixIcon: ListenableBuilder(
                            listenable: searchController,
                            builder: (_, _) => searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(UiIcons.close, size: 18),
                                    onPressed: onSearchClear,
                                    style: IconButton.styleFrom(
                                      minimumSize: const Size(32, 32),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: s.sm),
                  if (onFiltersTap != null)
                    FilledButton.tonal(
                      onPressed: onFiltersTap,
                      style: FilledButton.styleFrom(
                        minimumSize: Size(0, density.buttonHeight),
                        padding: EdgeInsets.symmetric(horizontal: s.sm),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(UiIcons.filterList, size: 20),
                          SizedBox(width: 6),
                          Text('Filters'),
                        ],
                      ),
                    ),
                  if (onFiltersTap != null) SizedBox(width: s.sm),
                  if (extraActions != null) ...[
                    SizedBox(width: s.sm),
                    extraActions!,
                  ],
                  const Spacer(),
                  if (onStatsVisibleChanged != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Show statistics',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: s.xxs),
                        Switch(
                          value: statsVisible,
                          onChanged: onStatsVisibleChanged,
                        ),
                      ],
                    ),
                ],
              ),
              if (filterChips.isNotEmpty) ...[
                SizedBox(height: s.xxs),
                Wrap(
                  spacing: s.xxs,
                  runSpacing: s.xxs,
                  children: filterChips.map((c) => InputChip(
                    label: Text(c.label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 11)),
                    deleteIcon: const Icon(UiIcons.close, size: 12),
                    onDeleted: c.onRemove,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: s.xxs, vertical: 2),
                    labelPadding: EdgeInsets.zero,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ClearSearchIntent extends Intent {
  const _ClearSearchIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}
