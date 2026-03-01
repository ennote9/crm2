import 'package:flutter/material.dart';

import '../icons/ui_icons.dart';
import '../utils/nav_item.dart';

List<Widget> _buildNavTiles(
  List<UiV1NavItem> items,
  bool collapsed,
  UiV1NavItem? currentNavId,
  ValueChanged<UiV1NavItem>? onNavSelected,
) {
  final hasPlayground = items.contains(UiV1NavItem.playground);
  final mainItems = hasPlayground
      ? items.where((e) => e != UiV1NavItem.playground).toList()
      : items;
  return [
    for (final item in mainItems)
      _NavTile(
        item: item,
        collapsed: collapsed,
        isActive: currentNavId == item,
        onTap: onNavSelected != null ? () => onNavSelected(item) : null,
      ),
    if (hasPlayground) ...[
      const Divider(height: 1),
      _NavTile(
        item: UiV1NavItem.playground,
        collapsed: collapsed,
        isActive: currentNavId == UiV1NavItem.playground,
        onTap: onNavSelected != null
            ? () => onNavSelected(UiV1NavItem.playground)
            : null,
      ),
    ],
  ];
}

/// Sidebar: nav items (icon + label when expanded, icon + tooltip when collapsed),
/// active indicator, collapse/expand button.
class UiV1Sidebar extends StatelessWidget {
  const UiV1Sidebar({
    super.key,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.currentNavId,
    required this.onNavSelected,
    this.navItems,
  });

  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final UiV1NavItem? currentNavId;
  final ValueChanged<UiV1NavItem>? onNavSelected;
  /// When null, uses [UiV1NavItem.all].
  final List<UiV1NavItem>? navItems;

  static const double widthExpanded = 220;
  static const double widthCollapsed = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sideWidth = collapsed ? widthCollapsed : widthExpanded;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: Container(
        width: sideWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                children: [
                  ..._buildNavTiles(
                    navItems ?? UiV1NavItem.all,
                    collapsed,
                    currentNavId,
                    onNavSelected,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _CollapseButton(
              collapsed: collapsed,
              onPressed: onToggleCollapsed,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.collapsed,
    required this.isActive,
    required this.onTap,
  });

  final UiV1NavItem item;
  final bool collapsed;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const padding = 12.0;
    const iconSize = 24.0;

    final iconData = UiIcons.iconForNavItem(item);
    final content = collapsed
        ? Icon(
            iconData,
            size: iconSize,
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconData,
                size: iconSize,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );

    final tile = Material(
      color: isActive ? colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
      child: InkWell(
        onTap: onTap,
        hoverColor: theme.hoverColor,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : padding,
            vertical: 10,
          ),
          alignment: collapsed ? Alignment.center : Alignment.centerLeft,
          child: collapsed
              ? Tooltip(
                  message: item.label,
                  child: content,
                )
              : content,
        ),
      ),
    );

    return Stack(
      children: [
        if (isActive)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              color: colorScheme.primary,
            ),
          ),
        tile,
      ],
    );
  }
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({
    required this.collapsed,
    required this.onPressed,
  });

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(collapsed ? UiIcons.collapseRight : UiIcons.collapseLeft),
      tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
    );
  }
}
