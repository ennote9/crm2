// Command Toolbar v1 — Search | Filters | Chips | Views | More | Show statistics.
// Dense layout, tokens. Used by Orders Worklist.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../icons/ui_icons.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';

/// One applied filter chip (e.g. "Status: Packed"). Remove clears that filter.
class UiV1FilterChipItem {
  const UiV1FilterChipItem({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;
}

/// System view id. Custom means user modified filters after selecting a view.
class UiV1WorklistViewId {
  const UiV1WorklistViewId._(this.id);
  final String id;
  static const all = UiV1WorklistViewId._('all');
  static const onHold = UiV1WorklistViewId._('on_hold');
  static const shortage = UiV1WorklistViewId._('shortage');
  static const today = UiV1WorklistViewId._('today');
  static const custom = UiV1WorklistViewId._('custom');
}

/// Command toolbar for worklist: search, filters, chips, views, more, stats toggle.
class UiV1CommandToolbar extends StatelessWidget {
  const UiV1CommandToolbar({
    super.key,
    required this.searchController,
    this.searchFocusNode,
    required this.onSearchSubmit,
    required this.onSearchClear,
    required this.filterChips,
    required this.onFiltersTap,
    required this.currentViewId,
    required this.isCustomView,
    required this.onViewSelected,
    required this.onMoreReset,
    this.onDevStateSelected,
    required this.showStatistics,
    required this.onShowStatisticsChanged,
  });

  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final VoidCallback onSearchSubmit;
  final VoidCallback onSearchClear;
  final List<UiV1FilterChipItem> filterChips;
  final VoidCallback onFiltersTap;
  final UiV1WorklistViewId currentViewId;
  final bool isCustomView;
  final ValueChanged<UiV1WorklistViewId> onViewSelected;
  final VoidCallback onMoreReset;
  final void Function(String devStateId)? onDevStateSelected;
  final bool showStatistics;
  final ValueChanged<bool> onShowStatisticsChanged;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.escape): _ClearSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _ClearSearchIntent: CallbackAction<_ClearSearchIntent>(
            onInvoke: (_) {
              onSearchClear();
              return null;
            },
          ),
        },
        child: _CommandToolbarContent(
          searchController: searchController,
          searchFocusNode: searchFocusNode,
          onSearchSubmit: onSearchSubmit,
          onSearchClear: onSearchClear,
          filterChips: filterChips,
          onFiltersTap: onFiltersTap,
          currentViewId: currentViewId,
          isCustomView: isCustomView,
          onViewSelected: onViewSelected,
          onMoreReset: onMoreReset,
          onDevStateSelected: onDevStateSelected,
          showStatistics: showStatistics,
          onShowStatisticsChanged: onShowStatisticsChanged,
        ),
      ),
    );
  }
}

class _CommandToolbarContent extends StatelessWidget {
  const _CommandToolbarContent({
    required this.searchController,
    this.searchFocusNode,
    required this.onSearchSubmit,
    required this.onSearchClear,
    required this.filterChips,
    required this.onFiltersTap,
    required this.currentViewId,
    required this.isCustomView,
    required this.onViewSelected,
    required this.onMoreReset,
    this.onDevStateSelected,
    required this.showStatistics,
    required this.onShowStatisticsChanged,
  });

  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final VoidCallback onSearchSubmit;
  final VoidCallback onSearchClear;
  final List<UiV1FilterChipItem> filterChips;
  final VoidCallback onFiltersTap;
  final UiV1WorklistViewId currentViewId;
  final bool isCustomView;
  final ValueChanged<UiV1WorklistViewId> onViewSelected;
  final VoidCallback onMoreReset;
  final void Function(String devStateId)? onDevStateSelected;
  final bool showStatistics;
  final ValueChanged<bool> onShowStatisticsChanged;

  static const double _inputHeight = 32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final density = UiV1DensityTokens.dense;
    final tokens = Theme.of(context).brightness == Brightness.dark
        ? UiV1Tokens.dark
        : UiV1Tokens.light;
    final s = tokens.spacing;
    final r = tokens.radius;

    return Padding(
      padding: EdgeInsets.fromLTRB(s.xl, s.md, s.xl, s.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SearchField(
                controller: searchController,
                focusNode: searchFocusNode,
                onSubmit: onSearchSubmit,
                onClear: onSearchClear,
                height: _inputHeight,
                radius: r.sm,
              ),
                  SizedBox(width: s.sm),
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
                  SizedBox(width: s.sm),
                  _ViewSelector(
                    currentViewId: currentViewId,
                    isCustomView: isCustomView,
                    onSelected: onViewSelected,
                    buttonHeight: density.buttonHeight,
                  ),
                  SizedBox(width: s.sm),
                  PopupMenuButton<String>(
                    icon: const Icon(UiIcons.moreHoriz),
                    tooltip: 'More',
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'reset') {
                        onMoreReset();
                      } else if (value.startsWith('dev:') && onDevStateSelected != null) {
                        onDevStateSelected!(value.substring(4));
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'reset',
                        child: ListTile(
                          leading: Icon(UiIcons.refresh, size: 20),
                          title: Text('Reset'),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      if (onDevStateSelected != null) ...[
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          enabled: false,
                          child: Text('Dev', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                        const PopupMenuItem(value: 'dev:data', child: Text('Data')),
                        const PopupMenuItem(value: 'dev:loading', child: Text('Loading')),
                        const PopupMenuItem(value: 'dev:empty', child: Text('Empty')),
                        const PopupMenuItem(value: 'dev:error', child: Text('Error')),
                      ],
                    ],
                  ),
                  const Spacer(),
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
                        value: showStatistics,
                        onChanged: onShowStatisticsChanged,
                      ),
                    ],
                  ),
                ],
              ),
              if (filterChips.isNotEmpty) ...[
                SizedBox(height: s.xs),
                Wrap(
                  spacing: s.xs,
                  runSpacing: s.xxs,
                  children: filterChips.map((c) => _FilterChip(
                    label: c.label,
                    onRemove: c.onRemove,
                    colors: tokens.colors,
                  )).toList(),
                ),
              ],
            ],
          ),
        );
  }
}

class _ClearSearchIntent extends Intent {
  const _ClearSearchIntent();
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    this.focusNode,
    required this.onSubmit,
    required this.onClear,
    required this.height,
    required this.radius,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      height: height,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(
          hintText: 'Search…',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (_, _) => controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(UiIcons.close, size: 18),
                    onPressed: onClear,
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
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({
    required this.currentViewId,
    required this.isCustomView,
    required this.onSelected,
    required this.buttonHeight,
  });

  final UiV1WorklistViewId currentViewId;
  final bool isCustomView;
  final ValueChanged<UiV1WorklistViewId> onSelected;
  final double buttonHeight;

  String _label(UiV1WorklistViewId id) {
    if (isCustomView && id == UiV1WorklistViewId.custom) return 'Custom';
    switch (id) {
      case UiV1WorklistViewId.all: return 'All';
      case UiV1WorklistViewId.onHold: return 'On Hold';
      case UiV1WorklistViewId.shortage: return 'Shortage';
      case UiV1WorklistViewId.today: return 'Today';
      case UiV1WorklistViewId.custom: return 'Custom';
      default: return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayId = isCustomView ? UiV1WorklistViewId.custom : currentViewId;
    return PopupMenuButton<UiV1WorklistViewId>(
      onSelected: onSelected,
      itemBuilder: (context) => [
        _viewItem(UiV1WorklistViewId.all),
        _viewItem(UiV1WorklistViewId.onHold),
        _viewItem(UiV1WorklistViewId.shortage),
        _viewItem(UiV1WorklistViewId.today),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(UiIcons.view, size: 20),
            const SizedBox(width: 4),
            Text('View: ${_label(displayId)}'),
            const SizedBox(width: 4),
            const Icon(UiIcons.arrowDropDown, size: 20),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<UiV1WorklistViewId> _viewItem(UiV1WorklistViewId id) {
    return PopupMenuItem(
      value: id,
      child: Text(_label(id)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onRemove,
    required this.colors,
  });

  final String label;
  final VoidCallback onRemove;
  final UiV1ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputChip(
      label: Text(label, style: theme.textTheme.labelSmall),
      deleteIcon: const Icon(UiIcons.close, size: 16),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelPadding: EdgeInsets.zero,
    );
  }
}
