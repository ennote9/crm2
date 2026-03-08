// Unified table toolbar for Table Platform v1. Search, Filters, View, extra actions, Show stats.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../icons/ui_icons.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import 'filter_state_summary.dart';

/// Toolbar: search field, Filters button, View (panel or dropdown), extra actions, optional Show stats toggle.
/// When [onViewPanelTap] is set, "View" opens the unified view panel and view dropdown + stats toggle are hidden.
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
    this.viewOptions = const [],
    this.currentViewId,
    this.onViewSelected,
    this.onReset,
    this.extraActions,
    this.statsVisible = false,
    this.onStatsVisibleChanged,
    this.onViewPanelTap,
  });

  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final VoidCallback onSearchSubmit;
  final VoidCallback onSearchClear;
  final String searchHint;
  final List<UnifiedFilterChipItem> filterChips;
  /// When [onViewPanelTap] is set, Filters button is hidden (filters are in View panel).
  final VoidCallback? onFiltersTap;
  final List<({String id, String label})> viewOptions;
  final String? currentViewId;
  final void Function(String? viewId)? onViewSelected;
  final VoidCallback? onReset;
  final Widget? extraActions;
  final bool statsVisible;
  final ValueChanged<bool>? onStatsVisibleChanged;
  /// When set, "View" button opens unified view panel; view dropdown and stats toggle are not shown.
  final VoidCallback? onViewPanelTap;

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
                  if (onViewPanelTap != null) ...[
                    FilledButton.tonal(
                      onPressed: onViewPanelTap,
                      style: FilledButton.styleFrom(
                        minimumSize: Size(0, density.buttonHeight),
                        padding: EdgeInsets.symmetric(horizontal: s.sm),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(UiIcons.view, size: 20),
                          SizedBox(width: 6),
                          Text('View'),
                        ],
                      ),
                    ),
                  ] else if (viewOptions.isNotEmpty && onViewSelected != null) ...[
                    _ViewDropdown(
                      options: viewOptions,
                      currentId: currentViewId,
                      onSelected: onViewSelected!,
                      buttonHeight: density.buttonHeight,
                    ),
                  ],
                  if (onReset != null) ...[
                    SizedBox(width: s.sm),
                    TextButton(
                      onPressed: onReset,
                      style: TextButton.styleFrom(
                        minimumSize: Size(0, density.buttonHeight),
                        padding: EdgeInsets.symmetric(horizontal: s.xs),
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                  if (extraActions != null) ...[
                    SizedBox(width: s.sm),
                    extraActions!,
                  ],
                  const Spacer(),
                  if (onViewPanelTap == null && onStatsVisibleChanged != null)
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

class _ViewDropdown extends StatelessWidget {
  const _ViewDropdown({
    required this.options,
    required this.currentId,
    required this.onSelected,
    required this.buttonHeight,
  });

  final List<({String id, String label})> options;
  final String? currentId;
  final void Function(String? id) onSelected;
  final double buttonHeight;

  @override
  Widget build(BuildContext context) {
    String currentLabel = 'All';
    if (currentId != null) {
      for (final o in options) {
        if (o.id == currentId) {
          currentLabel = o.label;
          break;
        }
      }
    }
    return PopupMenuButton<String?>(
      onSelected: onSelected,
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(value: null, child: Text('All')),
        ...options.map((o) => PopupMenuItem<String?>(value: o.id, child: Text(o.label))),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(UiIcons.view, size: 20),
            const SizedBox(width: 4),
            Text('View: $currentLabel'),
            const SizedBox(width: 4),
            const Icon(UiIcons.arrowDropDown, size: 20),
          ],
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
